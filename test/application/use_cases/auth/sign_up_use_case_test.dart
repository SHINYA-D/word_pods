// SYN-L07〜L09 の期待値: docs/detailed_design/online_offline/online_offline.md
// （接頭辞 SYN、6章「ユースケース」）。SignUpUseCase / SyncService の実装は
// 「どう呼ぶか」を知るためだけに読んでいる。
// LGL-T01〜T08 の期待値: docs/detailed_design/legal_consent/legal_consent.md
// （接頭辞 LGL、6.3 節 SignUpUseCase）。
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:word_pods/application/use_cases/auth/sign_up_use_case.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/domain/repositories/legal_repository.dart';
import 'package:word_pods/infrastructure/data_sources/local/database_helper.dart';
import 'package:word_pods/infrastructure/data_sources/local/flashcard_result_local_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/local/folder_local_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/local/sync_local_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/local/sync_queue_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/flashcard_result_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/folder_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/settings_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/sync_meta_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/sync_queue_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/word_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/word_local_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/remote/sync_remote_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/sync_record.dart';
import 'package:word_pods/infrastructure/repositories/folder_repository_impl.dart';
import 'package:word_pods/infrastructure/sync/sync_service.dart';

import '../../../helpers/fake_auth_use_case_repositories.dart';
import '../../../helpers/fake_infrastructure.dart';

/// SYN-L07〜L09 用の [SyncRemoteDataSource] の手書きフェイク（インメモリ）。
/// `test/application/use_cases/auth/sign_in_with_email_use_case_test.dart` の
/// `_FakeLoginSyncRemoteDataSource` と同じ最小構成（fetch のみ実データを返す・write は成功扱い）。
class _FakeSignUpSyncRemoteDataSource implements SyncRemoteDataSource {
  final Map<SyncEntity, Map<String, SyncRecord>> _store = {
    for (final e in SyncEntity.values) e: <String, SyncRecord>{},
  };

  bool failFetch = false;
  int fetchCallCount = 0;

  void seed(SyncRecord record) {
    _store[record.entity]![record.id] = SyncRecord(
      entity: record.entity,
      id: record.id,
      parentId: record.parentId,
      fields: record.fields,
      updatedAt: record.updatedAt,
      deletedAt: record.deletedAt,
      serverUpdatedAt: record.updatedAt,
    );
  }

  @override
  Future<List<SyncRecord>> fetchChanges(
    String userId,
    SyncEntity entity, {
    DateTime? since,
  }) async {
    fetchCallCount++;
    if (failFetch) throw Exception('fetch failed: ${entity.name}');
    return _store[entity]!.values.toList();
  }

  @override
  Future<SyncRecord?> writeIfNewer(String userId, SyncRecord record) async => null;
}

/// 呼ばれた順序を記録する共有ログ（LGL-T05 用）。
class _CallLog {
  final List<String> events = [];
}

/// [LegalRepository] の手書きフェイク。accept の呼び出し回数・引数・順序を記録する。
class _FakeLegalRepository implements LegalRepository {
  _FakeLegalRepository([this.log]);

  final _CallLog? log;
  Either<Failure, LegalAcceptResult> acceptResult = const Right(LegalAcceptResult.accepted);
  int acceptCallCount = 0;
  ({String? termsVersion, String? privacyVersion})? receivedAccept;

  @override
  Future<Either<Failure, LegalAcceptResult>> accept({
    String? termsVersion,
    String? privacyVersion,
  }) async {
    acceptCallCount++;
    receivedAccept = (termsVersion: termsVersion, privacyVersion: privacyVersion);
    log?.events.add('accept');
    return acceptResult;
  }

  @override
  Future<Either<Failure, LegalConfig>> fetchLegalConfig() => throw UnimplementedError();

  @override
  Future<Either<Failure, LegalConsents>> fetchConsents(String userId) => throw UnimplementedError();
}

/// 同期の呼び出しを共有ログへ記録する [FakeSyncServiceForLogin]。
class _OrderRecordingSyncService extends FakeSyncServiceForLogin {
  _OrderRecordingSyncService(this.log);

  final _CallLog log;

  @override
  Future<void> syncRemoteToLocalOnLogin() {
    log.events.add('sync');
    return super.syncRemoteToLocalOnLogin();
  }
}

void main() {
  late FakeAuthRepository fakeRepository;
  late FakeSyncServiceForLogin fakeSyncService;
  late _FakeLegalRepository fakeLegal;
  late SignUpUseCase useCase;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    fakeSyncService = FakeSyncServiceForLogin();
    fakeLegal = _FakeLegalRepository();
    useCase = SignUpUseCase(fakeRepository, fakeSyncService, fakeLegal);
  });

  group('SignUpUseCase.call', () {
    test('email/passwordを指定して呼び出した場合、Repositoryに同じ値で委譲される', () async {
      await useCase.call(
          email: 'new@example.com', password: 'password123', termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expect(fakeRepository.signUpWithEmailCallCount, 1);
      expect(
        fakeRepository.receivedSignUpWithEmail,
        (email: 'new@example.com', password: 'password123'),
      );
    });

    test('登録に成功した場合、Right(AppUser)がそのまま返り、ログイン時同期が1回実行される', () async {
      const user = AppUser(id: 'u1', email: 'new@example.com');
      fakeRepository.signUpWithEmailResult = const Right(user);

      final result = await useCase.call(
          email: 'new@example.com', password: 'password123', termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expect(result, const Right<Failure, AppUser>(user));
      expect(fakeSyncService.syncRemoteToLocalOnLoginCallCount, 1);
    });

    test('登録に失敗した場合、Left(Failure)がそのまま返り、ログイン時同期は実行されない', () async {
      fakeRepository.signUpWithEmailResult = const Left(Failure.unknown('already exists'));

      final result = await useCase.call(
          email: 'new@example.com', password: 'password123', termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expect(
        result,
        const Left<Failure, AppUser>(Failure.unknown('already exists')),
      );
      expect(fakeSyncService.syncRemoteToLocalOnLoginCallCount, 0);
    });

    test('登録成功後の同期処理で例外が発生した場合、例外は握りつぶされ登録結果はそのまま返る', () async {
      const user = AppUser(id: 'u1', email: 'new@example.com');
      fakeRepository.signUpWithEmailResult = const Right(user);
      fakeSyncService.exceptionToThrow = Exception('sync failed');

      final result = await useCase.call(
          email: 'new@example.com', password: 'password123', termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expect(result, const Right<Failure, AppUser>(user));
      expect(fakeSyncService.syncRemoteToLocalOnLoginCallCount, 1);
    });
  });

  // ---------------------------------------------------------------
  // LGL-T01〜T08: 新規登録の処理（docs/detailed_design/legal_consent/legal_consent.md 6.3 節）
  // ---------------------------------------------------------------
  group('SignUpUseCase.call（同意の送信 LGL-T）', () {
    const userA = AppUser(id: 'A', email: 'new@example.com');

    Future<Either<Failure, AppUser>> callUseCase(SignUpUseCase uc) => uc.call(
          email: 'new@example.com',
          password: 'password123',
          termsVersion: '2026-01-01',
          privacyVersion: '2026-01-01',
        );

    test('アカウント作成と送信が成功した場合、Right(AppUser A)が返り、送信が規約・ポリシー2026-01-01で1回、初回の同期が1回呼ばれる [LGL-T01]', () async {
      fakeRepository.signUpWithEmailResult = const Right(userA);
      fakeLegal.acceptResult = const Right(LegalAcceptResult.accepted);

      final result = await callUseCase(useCase);

      expect(result, const Right<Failure, AppUser>(userA));
      expect(fakeLegal.acceptCallCount, 1);
      expect(fakeLegal.receivedAccept, (termsVersion: '2026-01-01', privacyVersion: '2026-01-01'));
      expect(fakeSyncService.syncRemoteToLocalOnLoginCallCount, 1);
    });

    test('アカウント作成がLeft(AuthFailure)の場合、Left(AuthFailure)が返り、送信は0回、初回の同期は0回 [LGL-T02]', () async {
      fakeRepository.signUpWithEmailResult = const Left(Failure.auth());

      final result = await callUseCase(useCase);

      expect(result, const Left<Failure, AppUser>(Failure.auth()));
      expect(fakeLegal.acceptCallCount, 0);
      expect(fakeSyncService.syncRemoteToLocalOnLoginCallCount, 0);
    });

    test('送信がLeft(UnknownFailure)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T03]', () async {
      fakeRepository.signUpWithEmailResult = const Right(userA);
      fakeLegal.acceptResult = const Left(Failure.unknown('failed'));

      final result = await callUseCase(useCase);

      expect(result, const Right<Failure, AppUser>(userA));
      expect(fakeLegal.acceptCallCount, 1);
      expect(fakeSyncService.syncRemoteToLocalOnLoginCallCount, 1);
    });

    test('送信がRight(outdated)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T04]', () async {
      fakeRepository.signUpWithEmailResult = const Right(userA);
      fakeLegal.acceptResult = const Right(LegalAcceptResult.outdated);

      final result = await callUseCase(useCase);

      expect(result, const Right<Failure, AppUser>(userA));
      expect(fakeLegal.acceptCallCount, 1);
      expect(fakeSyncService.syncRemoteToLocalOnLoginCallCount, 1);
    });

    test('送信が成功する場合、送信は初回の同期より先に呼ばれる [LGL-T05]', () async {
      final log = _CallLog();
      final legal = _FakeLegalRepository(log);
      final uc = SignUpUseCase(
        fakeRepository..signUpWithEmailResult = const Right(userA),
        _OrderRecordingSyncService(log),
        legal,
      );

      await callUseCase(uc);

      expect(log.events, ['accept', 'sync']);
    });

    test('送信がLeft(NetworkFailure)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T06]', () async {
      fakeRepository.signUpWithEmailResult = const Right(userA);
      fakeLegal.acceptResult = const Left(Failure.network());

      final result = await callUseCase(useCase);

      expect(result, const Right<Failure, AppUser>(userA));
      expect(fakeLegal.acceptCallCount, 1);
      expect(fakeSyncService.syncRemoteToLocalOnLoginCallCount, 1);
    });

    test('送信がLeft(AuthFailure)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T07]', () async {
      fakeRepository.signUpWithEmailResult = const Right(userA);
      fakeLegal.acceptResult = const Left(Failure.auth());

      final result = await callUseCase(useCase);

      expect(result, const Right<Failure, AppUser>(userA));
      expect(fakeLegal.acceptCallCount, 1);
      expect(fakeSyncService.syncRemoteToLocalOnLoginCallCount, 1);
    });

    test('アカウント作成がLeft(NetworkFailure)の場合、Left(NetworkFailure)が返り、送信は0回、初回の同期は0回 [LGL-T08]', () async {
      fakeRepository.signUpWithEmailResult = const Left(Failure.network());

      final result = await callUseCase(useCase);

      expect(result, const Left<Failure, AppUser>(Failure.network()));
      expect(fakeLegal.acceptCallCount, 0);
      expect(fakeSyncService.syncRemoteToLocalOnLoginCallCount, 0);
    });
  });

  // ---------------------------------------------------------------
  // SYN-L07〜L09: 本物の SyncService + SQLite（sqflite_common_ffi）で確かめる。
  // ---------------------------------------------------------------
  group('SignUpUseCase.call（本物のSyncServiceを使う同期の確認）', () {
    const userId = 'u1';
    const user = AppUser(id: userId, email: 'new@example.com');
    final now = DateTime.utc(2024, 6, 1, 12);

    late DatabaseHelper dbHelper;
    late FolderLocalDataSource folderLocal;
    late WordLocalDataSource wordLocal;
    late FlashcardResultLocalDataSource flashcardResultLocal;
    late SyncQueueDataSource syncQueue;
    late SyncLocalDataSource syncLocal;
    late _FakeSignUpSyncRemoteDataSource fakeRemote;
    late FakeConnectivityMonitor fakeConnectivity;
    late SyncService realSyncService;
    late FolderRepositoryImpl folderRepo;
    late FakeAuthRepository authRepository;
    late SignUpUseCase realUseCase;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final tempDir = await Directory.systemTemp.createTemp('sign_up_use_case_test_');
      await databaseFactory.setDatabasesPath(tempDir.path);
    });

    setUp(() async {
      dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      await db.delete(FolderTable.tableName);
      await db.delete(WordTable.tableName);
      await db.delete(FlashcardResultTable.tableName);
      await db.delete(SettingsTable.tableName);
      await db.delete(SyncQueueTable.tableName);
      await db.delete(SyncMetaTable.tableName);

      folderLocal = FolderLocalDataSource(dbHelper);
      wordLocal = WordLocalDataSource(dbHelper);
      flashcardResultLocal = FlashcardResultLocalDataSource(dbHelper);
      syncQueue = SyncQueueDataSource(dbHelper);
      syncLocal = SyncLocalDataSource(dbHelper);
      fakeRemote = _FakeSignUpSyncRemoteDataSource();
      fakeConnectivity = FakeConnectivityMonitor(online: true);

      realSyncService = SyncService(
        localDataSource: syncLocal,
        syncQueueDataSource: syncQueue,
        remoteDataSource: fakeRemote,
        connectivityMonitor: fakeConnectivity,
        getCurrentUserId: () => userId,
        clock: () => now,
      );

      folderRepo = FolderRepositoryImpl(
        localDataSource: folderLocal,
        wordLocalDataSource: wordLocal,
        flashcardResultLocalDataSource: flashcardResultLocal,
        syncQueueDataSource: syncQueue,
        dbHelper: dbHelper,
        onLocalChanged: () {},
      );

      authRepository = FakeAuthRepository();
      authRepository.signUpWithEmailResult = const Right(user);
      realUseCase = SignUpUseCase(authRepository, realSyncService, _FakeLegalRepository());
    });

    test(
        '新規登録に成功した（リモートにデータなし）場合、戻り値がRight(AppUser)になり、'
        'getFoldersの戻り値が空になる [SYN-L07]', () async {
      final result = await realUseCase.call(
        email: 'new@example.com',
        password: 'password123',
        termsVersion: '2026-01-01',
        privacyVersion: '2026-01-01',
      );

      expect(result, const Right<Failure, AppUser>(user));
      final folders = await folderRepo
          .getFolders(userId: userId)
          .then((r) => r.match((_) => throw Exception('unexpected Left'), (v) => v));
      expect(folders, isEmpty);
    });

    test('新規登録に成功し、その後の取得がリモートの失敗で失敗した場合、戻り値がRight(AppUser)になる [SYN-L08]', () async {
      fakeRemote.failFetch = true;

      final result = await realUseCase.call(
        email: 'new@example.com',
        password: 'password123',
        termsVersion: '2026-01-01',
        privacyVersion: '2026-01-01',
      );

      expect(result, const Right<Failure, AppUser>(user));
    });

    test(
        '新規登録がAuthFailureで失敗した場合、戻り値がLeft(AuthFailure)になり、'
        'リモートへのデータの読み取りが呼ばれない [SYN-L09]', () async {
      authRepository.signUpWithEmailResult = const Left(Failure.auth());
      fakeRemote.seed(SyncRecord(
        entity: SyncEntity.folder,
        id: 'F',
        fields: const {'name': 'F', 'parentFolderId': null},
        updatedAt: now,
      ));

      final result = await realUseCase.call(
        email: 'new@example.com',
        password: 'password123',
        termsVersion: '2026-01-01',
        privacyVersion: '2026-01-01',
      );

      expect(result, const Left<Failure, AppUser>(Failure.auth()));
      final folders = await folderRepo
          .getFolders(userId: userId)
          .then((r) => r.match((_) => throw Exception('unexpected Left'), (v) => v));
      expect(folders, isEmpty);
      expect(fakeRemote.fetchCallCount, 0);
    });
  });
}
