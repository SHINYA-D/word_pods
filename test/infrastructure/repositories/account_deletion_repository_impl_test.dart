import 'dart:async';

// 仕様書: docs/detailed_design/presentation/settings/settings_page.md（接頭辞 ACD、5.1）
//
// 期待値はすべて上記仕様書から作った。実装は「どう呼ぶか」を知るためだけに読んでいる。
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/account_deletion_request.dart';
import 'package:word_pods/infrastructure/data_sources/local/account_deletion_local_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/local/database_helper.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/account_deletion_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/flashcard_result_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/folder_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/settings_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/sync_meta_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/sync_queue_table.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/word_table.dart';
import 'package:word_pods/infrastructure/data_sources/remote/account_deletion_remote_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/local/sync_local_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/local/sync_queue_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/remote/sync_remote_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/remote/withdrawn_account_remote_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/sync_record.dart';
import 'package:word_pods/infrastructure/sync/sync_service.dart';
import 'package:word_pods/infrastructure/repositories/account_deletion_repository_impl.dart';

import '../../helpers/fake_infrastructure.dart';

/// [AccountDeletionRemoteDataSource] の手書きフェイク。呼び出し回数を記録し、指定した例外を投げる。
class FakeAccountDeletionRemoteDataSource
    implements AccountDeletionRemoteDataSource {
  int callCount = 0;
  Object? error;

  @override
  Future<void> deleteAccount() async {
    callCount++;
    if (error != null) throw error!;
  }
}

/// [WithdrawnAccountRemoteDataSource] の手書きフェイク。退会済みの記録を [withdrawn] で持つ。
class FakeWithdrawnAccountRemoteDataSource
    implements WithdrawnAccountRemoteDataSource {
  final Set<String> withdrawn = {};
  Object? error;
  final StreamController<bool> watchController = StreamController<bool>();
  int isWithdrawnCallCount = 0;

  /// true のとき、購読開始時に [withdrawn] の現在の状態を最初の通知として流す。
  bool emitCurrentOnWatch = false;

  @override
  Future<bool> isWithdrawn(String userId) async {
    isWithdrawnCallCount++;
    if (error != null) throw error!;
    return withdrawn.contains(userId);
  }

  @override
  Stream<bool> watch(String userId) async* {
    if (emitCurrentOnWatch) yield withdrawn.contains(userId);
    yield* watchController.stream;
  }
}

/// 呼び出しを記録するだけの [SyncRemoteDataSource]（送信・取得の回数を確かめる用）。
class _CountingSyncRemoteDataSource implements SyncRemoteDataSource {
  final List<String> calls = [];

  @override
  Future<List<SyncRecord>> fetchChanges(
    String userId,
    SyncEntity entity, {
    DateTime? since,
  }) async {
    calls.add('fetch:${entity.name}');
    return [];
  }

  @override
  Future<SyncRecord?> writeIfNewer(String userId, SyncRecord record) async {
    calls.add('write:${record.entity.name}:${record.id}');
    return null;
  }
}

class _FakeHttpsCallable implements HttpsCallable {
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    throw StateError('fake: 結果は使わない');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// `httpsCallable` に渡された名前とオプションを記録する [FirebaseFunctions] のフェイク。
class _FakeFirebaseFunctions implements FirebaseFunctions {
  String? name;
  HttpsCallableOptions? options;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    this.name = name;
    this.options = options;
    return _FakeHttpsCallable();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const userA = 'A';
  const userB = 'B';

  late DatabaseHelper dbHelper;
  late AccountDeletionLocalDataSource local;
  late FakeAccountDeletionRemoteDataSource remote;
  late FakeConnectivityMonitor connectivity;
  late AccountDeletionRepositoryImpl repo;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final tempDir =
        await Directory.systemTemp.createTemp('account_deletion_repo_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    await db.execute('DROP TRIGGER IF EXISTS fail_clear');
    await db.execute('DROP TRIGGER IF EXISTS fail_folder_of_c');
    for (final table in [
      FolderTable.tableName,
      WordTable.tableName,
      FlashcardResultTable.tableName,
      SettingsTable.tableName,
      SyncQueueTable.tableName,
      SyncMetaTable.tableName,
      AccountDeletionTable.tableName,
    ]) {
      await db.delete(table);
    }
    local = AccountDeletionLocalDataSource(dbHelper);
    remote = FakeAccountDeletionRemoteDataSource();
    connectivity = FakeConnectivityMonitor(online: true);
    repo = AccountDeletionRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      withdrawnRemoteDataSource: FakeWithdrawnAccountRemoteDataSource(),
      connectivityMonitor: connectivity,
    );
  });

  Future<AccountDeletionRequest?> pending() async =>
      (await repo.findPending()).getOrElse((_) => const None()).toNullable();

  Future<void> seedUser(String uid) async {
    final db = await dbHelper.database;
    const ts = '2024-06-01T00:00:00.000Z';
    await db.insert(FolderTable.tableName, {
      'id': 'folder-$uid',
      'name': 'f',
      'userId': uid,
      'createdAt': ts,
      'updatedAt': ts,
    });
    await db.insert(WordTable.tableName, {
      'id': 'word-$uid',
      'front': 'a',
      'back': 'b',
      'folderId': 'folder-$uid',
      'userId': uid,
      'createdAt': ts,
      'updatedAt': ts,
    });
    await db.insert(FlashcardResultTable.tableName, {
      'id': 'result-$uid',
      'folderId': 'folder-$uid',
      'totalCount': 1,
      'correctCount': 1,
      'date': ts,
      'userId': uid,
      'updatedAt': ts,
    });
    await db.insert(SettingsTable.tableName, {
      'userId': uid,
      'updatedAt': ts,
    });
    await db.insert(SyncQueueTable.tableName, {
      'operation': 'create',
      'table_name': 'folders',
      'record_id': 'folder-$uid',
      'created_at': ts,
      'user_id': uid,
    });
    await db.insert(SyncMetaTable.tableName,
        {'key': 'pullCursor:$uid', 'value': ts});
    await db.insert(SyncMetaTable.tableName,
        {'key': 'lastPulledAt:$uid', 'value': ts});
  }

  /// uid ごとの (folders, words, results, settings, queue, meta) の件数。
  Future<List<int>> counts(String uid) async {
    final db = await dbHelper.database;
    Future<int> c(String table, String col, String v) async =>
        (await db.query(table, where: '$col = ?', whereArgs: [v])).length;
    final meta = await db.query(
      SyncMetaTable.tableName,
      where: 'key IN (?, ?)',
      whereArgs: ['pullCursor:$uid', 'lastPulledAt:$uid'],
    );
    return [
      await c(FolderTable.tableName, 'userId', uid),
      await c(WordTable.tableName, 'userId', uid),
      await c(FlashcardResultTable.tableName, 'userId', uid),
      await c(SettingsTable.tableName, 'userId', uid),
      await c(SyncQueueTable.tableName, 'user_id', uid),
      meta.length,
    ];
  }

  group('findPending', () {
    test('記録が無い場合、Right(None) を返す [ACD-R01]', () async {
      final result = await repo.findPending();

      expect(result, const Right<Failure, Option<AccountDeletionRequest>>(None()));
    });
  });

  group('markRequested', () {
    test('記録が無い状態で markRequested(A) を呼んだ場合、Right(unit) になり findPending は Some(A, requested) を返す [ACD-R02]',
        () async {
      final result = await repo.markRequested(userA);

      expect(result, const Right<Failure, Unit>(unit));
      final p = await pending();
      expect(p?.userId, userA);
      expect(p?.status, AccountDeletionStatus.requested);
    });

    test('requested の記録がある状態で markRequested(A) を呼んだ場合、Right(unit) になり findPending は Some(A, requested) を返す [ACD-R25]',
        () async {
      await repo.markRequested(userA);

      final result = await repo.markRequested(userA);

      expect(result, const Right<Failure, Unit>(unit));
      final p = await pending();
      expect(p?.userId, userA);
      expect(p?.status, AccountDeletionStatus.requested);
    });
  });

  group('markServerDone', () {
    test('markRequested の後に markServerDone(A) を呼んだ場合、Right(unit) になり findPending は Some(A, serverDone)、updatedAt は前回より前にならない [ACD-R03]',
        () async {
      await repo.markRequested(userA);
      final before = (await pending())!.updatedAt;

      final result = await repo.markServerDone(userA);

      expect(result, const Right<Failure, Unit>(unit));
      final p = await pending();
      expect(p?.userId, userA);
      expect(p?.status, AccountDeletionStatus.serverDone);
      expect(p!.updatedAt.isBefore(before), isFalse);
    });
  });

  group('clearRequest', () {
    test('requested の記録がある状態で clearRequest(A) を呼んだ場合、Right(unit) になり findPending は Right(None) を返す [ACD-R04]',
        () async {
      await repo.markRequested(userA);

      final result = await repo.clearRequest(userA);

      expect(result, const Right<Failure, Unit>(unit));
      expect(await pending(), isNull);
    });

    test('記録が無い状態で clearRequest(A) を呼んだ場合、Right(unit) になり findPending は Right(None) を返す [ACD-R26]',
        () async {
      final result = await repo.clearRequest(userA);

      expect(result, const Right<Failure, Unit>(unit));
      expect(await pending(), isNull);
    });
  });

  group('deleteLocalData', () {
    test('uid A と B のデータがあり A の記録が serverDone の状態で deleteLocalData(A) を呼んだ場合、A のデータだけが消え B は残り、記録は無くなる [ACD-R05]',
        () async {
      await seedUser(userA);
      await seedUser(userB);
      await repo.markServerDone(userA);

      final result = await repo.deleteLocalData(userA);

      expect(result, const Right<Failure, Unit>(unit));
      expect(await counts(userA), [0, 0, 0, 0, 0, 0]);
      expect(await counts(userB), [1, 1, 1, 1, 1, 2]);
      expect(await pending(), isNull);
    });

    test('A のフォルダ削除の後、記録の削除で SQLite の書き込みが失敗した場合、Left(UnknownFailure) になり件数は呼ぶ前と同じで記録も serverDone のまま残る [ACD-R06]',
        () async {
      await seedUser(userA);
      await repo.markServerDone(userA);
      final db = await dbHelper.database;
      await db.execute('''
        CREATE TRIGGER fail_clear BEFORE DELETE ON ${AccountDeletionTable.tableName}
        BEGIN SELECT RAISE(ABORT, 'forced failure'); END
      ''');
      addTearDown(() async => db.execute('DROP TRIGGER IF EXISTS fail_clear'));

      final result = await repo.deleteLocalData(userA);

      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
      expect(await counts(userA), [1, 1, 1, 1, 1, 2]);
      final p = await pending();
      expect(p?.userId, userA);
      expect(p?.status, AccountDeletionStatus.serverDone);
    });

    test('A のデータも記録も無い状態で deleteLocalData(A) を呼んだ場合、Right(unit) を返す [ACD-R24]',
        () async {
      final result = await repo.deleteLocalData(userA);

      expect(result, const Right<Failure, Unit>(unit));
    });
  });

  group('requestServerDeletion', () {
    test('オンラインで関数が成功を返した場合、Right(unit) になり関数は1回呼ばれる [ACD-R07]',
        () async {
      final result = await repo.requestServerDeletion();

      expect(result, const Right<Failure, Unit>(unit));
      expect(remote.callCount, 1);
    });

    test('オフラインの場合、Left(NetworkFailure) になり関数は0回呼ばれる [ACD-R08]',
        () async {
      connectivity.setOnline(false);

      final result = await repo.requestServerDeletion();

      expect(result, const Left<Failure, Unit>(Failure.network()));
      expect(remote.callCount, 0);
    });

    test('オンラインで関数が unavailable で失敗した場合、Left(NetworkFailure) になる [ACD-R09]',
        () async {
      remote.error =
          FirebaseFunctionsException(code: 'unavailable', message: 'm');

      final result = await repo.requestServerDeletion();

      expect(result, const Left<Failure, Unit>(Failure.network()));
    });

    test('オンラインで関数が deadline-exceeded で失敗した場合、Left(UnknownFailure) になる [ACD-R10]',
        () async {
      remote.error =
          FirebaseFunctionsException(code: 'deadline-exceeded', message: 'm');

      final result = await repo.requestServerDeletion();

      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
    });

    test('オンラインで関数が unauthenticated で失敗した場合、Left(AuthFailure) になる [ACD-R11]',
        () async {
      remote.error =
          FirebaseFunctionsException(code: 'unauthenticated', message: 'm');

      final result = await repo.requestServerDeletion();

      expect(result, const Left<Failure, Unit>(Failure.auth()));
    });

    test('オンラインで関数が failed-precondition で失敗した場合、Left(RecentLoginRequiredFailure) になる [ACD-R51]',
        () async {
      remote.error = FirebaseFunctionsException(
          code: 'failed-precondition', message: 'm');

      final result = await repo.requestServerDeletion();

      expect(result,
          const Left<Failure, Unit>(Failure.recentLoginRequired()));
    });

    test('オンラインで関数が internal で失敗した場合、Left(UnknownFailure) になる [ACD-R12]',
        () async {
      remote.error = FirebaseFunctionsException(code: 'internal', message: 'm');

      final result = await repo.requestServerDeletion();

      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
    });

    test('オンラインで関数が FirebaseFunctionsException 以外の例外で失敗した場合、Left(UnknownFailure) になる [ACD-R27]',
        () async {
      remote.error = Exception('boom');

      final result = await repo.requestServerDeletion();

      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
    });

    test('オンラインで requestServerDeletion を呼んだ場合、関数 deleteAccount の呼び出しに待ち時間の上限として60秒が指定される [ACD-R29]',
        () async {
      final functions = _FakeFirebaseFunctions();
      final realRemote = AccountDeletionRemoteDataSource(functions);
      final repoWithReal = AccountDeletionRepositoryImpl(
        localDataSource: local,
        remoteDataSource: realRemote,
        withdrawnRemoteDataSource: FakeWithdrawnAccountRemoteDataSource(),
        connectivityMonitor: connectivity,
      );

      await repoWithReal.requestServerDeletion();

      expect(functions.name, 'deleteAccount');
      expect(functions.options?.timeout, const Duration(seconds: 60));
    });
  });

  // ---- 5.3 他の端末での退会の確認・強制ログアウト・監視 ----

  AccountDeletionRepositoryImpl buildRepo(
          FakeWithdrawnAccountRemoteDataSource withdrawnRemote) =>
      AccountDeletionRepositoryImpl(
        localDataSource: local,
        remoteDataSource: remote,
        withdrawnRemoteDataSource: withdrawnRemote,
        connectivityMonitor: connectivity,
      );

  group('findLocalUserIds', () {
    test('A のフォルダと単語、B の sync_queue だけ、C の設定だけ、D の学習結果だけ、E の sync_meta だけがある状態で findLocalUserIds を呼んだ場合、A〜E が1回ずつ含まれる [ACD-R31]',
        () async {
      final db = await dbHelper.database;
      const ts = '2024-06-01T00:00:00.000Z';
      await db.insert(FolderTable.tableName, {
        'id': 'folder-A',
        'name': 'f',
        'userId': 'A',
        'createdAt': ts,
        'updatedAt': ts,
      });
      await db.insert(WordTable.tableName, {
        'id': 'word-A',
        'front': 'a',
        'back': 'b',
        'folderId': 'folder-A',
        'userId': 'A',
        'createdAt': ts,
        'updatedAt': ts,
      });
      await db.insert(SyncQueueTable.tableName, {
        'operation': 'create',
        'table_name': 'folders',
        'record_id': 'x',
        'created_at': ts,
        'user_id': 'B',
      });
      await db.insert(SettingsTable.tableName, {'userId': 'C', 'updatedAt': ts});
      await db.insert(FlashcardResultTable.tableName, {
        'id': 'result-D',
        'folderId': 'folder-D',
        'totalCount': 1,
        'correctCount': 1,
        'date': ts,
        'userId': 'D',
        'updatedAt': ts,
      });
      await db.insert(SyncMetaTable.tableName,
          {'key': 'pullCursor:E', 'value': ts});

      final result = await repo.findLocalUserIds();

      final ids = result.getOrElse((_) => []);
      expect(result.isRight(), isTrue);
      expect(ids, unorderedEquals(['A', 'B', 'C', 'D', 'E']));
    });

    test('端末内にどの uid のデータも無い状態で findLocalUserIds を呼んだ場合、Right([]) を返す [ACD-R32]',
        () async {
      final result = await repo.findLocalUserIds();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => ['x']), isEmpty);
    });

    test('端末内の読み取りが例外を投げる状態で findLocalUserIds を呼んだ場合、Left(UnknownFailure) になる [ACD-R37]',
        () async {
      final db = await dbHelper.database;
      await db.execute('ALTER TABLE ${FolderTable.tableName} RENAME TO folders_bak');
      addTearDown(() async => db.execute(
          'ALTER TABLE folders_bak RENAME TO ${FolderTable.tableName}'));

      final result = await repo.findLocalUserIds();

      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
    });
  });

  group('isWithdrawnOnServer', () {
    test('オンラインで A に退会済みの記録がある状態で isWithdrawnOnServer(A) を呼んだ場合、Right(true) を返す [ACD-R33]',
        () async {
      final w = FakeWithdrawnAccountRemoteDataSource()..withdrawn.add(userA);

      final result = await buildRepo(w).isWithdrawnOnServer(userA);

      expect(result, const Right<Failure, bool>(true));
    });

    test('オンラインで A に退会済みの記録が無い状態で isWithdrawnOnServer(A) を呼んだ場合、Right(false) を返す [ACD-R34]',
        () async {
      final w = FakeWithdrawnAccountRemoteDataSource();

      final result = await buildRepo(w).isWithdrawnOnServer(userA);

      expect(result, const Right<Failure, bool>(false));
    });

    test('オフラインで isWithdrawnOnServer(A) を呼んだ場合、Left(NetworkFailure) になり記録の読み取りは0回になる [ACD-R35]',
        () async {
      final w = FakeWithdrawnAccountRemoteDataSource()..withdrawn.add(userA);
      connectivity.setOnline(false);

      final result = await buildRepo(w).isWithdrawnOnServer(userA);

      expect(result, const Left<Failure, bool>(Failure.network()));
      expect(w.isWithdrawnCallCount, 0);
    });

    test('オンラインで退会済みの記録の読み取りが例外を投げる状態で isWithdrawnOnServer(A) を呼んだ場合、Left(UnknownFailure) になる [ACD-R36]',
        () async {
      final w = FakeWithdrawnAccountRemoteDataSource()
        ..error = Exception('read failed');

      final result = await buildRepo(w).isWithdrawnOnServer(userA);

      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
    });
  });

  group('deleteLocalDataOfUsers', () {
    test('記録が無く A・B・C のデータがある状態で deleteLocalDataOfUsers([A, C]) を呼んだ場合、A と C のデータだけが消え B は残る [ACD-R38]',
        () async {
      await seedUser(userA);
      await seedUser(userB);
      await seedUser('C');

      final result = await repo.deleteLocalDataOfUsers([userA, 'C']);

      expect(result, const Right<Failure, Unit>(unit));
      expect(await counts(userA), [0, 0, 0, 0, 0, 0]);
      expect(await counts('C'), [0, 0, 0, 0, 0, 0]);
      expect(await counts(userB), [1, 1, 1, 1, 1, 2]);
    });

    test('A の行の削除の後、C の行の削除の前に SQLite の書き込みが失敗した場合、Left(UnknownFailure) になり A と C の件数は呼ぶ前と同じになる [ACD-R39]',
        () async {
      await seedUser(userA);
      await seedUser('C');
      final db = await dbHelper.database;
      await db.execute('''
        CREATE TRIGGER fail_folder_of_c BEFORE DELETE ON ${FolderTable.tableName}
        WHEN OLD.userId = 'C'
        BEGIN SELECT RAISE(ABORT, 'forced failure'); END
      ''');
      addTearDown(
          () async => db.execute('DROP TRIGGER IF EXISTS fail_folder_of_c'));

      final result = await repo.deleteLocalDataOfUsers([userA, 'C']);

      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
      expect(await counts(userA), [1, 1, 1, 1, 1, 2]);
      expect(await counts('C'), [1, 1, 1, 1, 1, 2]);
    });

    test('A のデータが1件も無い状態で deleteLocalDataOfUsers([A]) を呼んだ場合、Right(unit) を返す [ACD-R40]',
        () async {
      final result = await repo.deleteLocalDataOfUsers([userA]);

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('A のデータと A の強制ログアウトの記録がある状態で deleteLocalDataOfUsers([A]) を呼んだ場合、Right(unit) になり findForcedSignOut は Some(A) のままになる [ACD-R43]',
        () async {
      await seedUser(userA);
      await repo.markForcedSignOut(userA);

      final result = await repo.deleteLocalDataOfUsers([userA]);

      expect(result, const Right<Failure, Unit>(unit));
      expect(await repo.findForcedSignOut(),
          const Right<Failure, Option<String>>(Some(userA)));
    });
  });

  group('強制ログアウトの記録', () {
    test('強制ログアウトの記録が無い状態で markForcedSignOut(A) を呼んだ場合、Right(unit) になり findForcedSignOut は Some(A) を返す [ACD-R41]',
        () async {
      final result = await repo.markForcedSignOut(userA);

      expect(result, const Right<Failure, Unit>(unit));
      expect(await repo.findForcedSignOut(),
          const Right<Failure, Option<String>>(Some(userA)));
    });

    test('強制ログアウトの記録が無い状態で findForcedSignOut を呼んだ場合、Right(None) を返す [ACD-R42]',
        () async {
      final result = await repo.findForcedSignOut();

      expect(result, const Right<Failure, Option<String>>(None()));
    });

    test('A の強制ログアウトの記録がある状態で clearForcedSignOut(A) を呼んだ場合、Right(unit) になり findForcedSignOut は Right(None) を返す [ACD-R44]',
        () async {
      await repo.markForcedSignOut(userA);

      final result = await repo.clearForcedSignOut(userA);

      expect(result, const Right<Failure, Unit>(unit));
      expect(await repo.findForcedSignOut(),
          const Right<Failure, Option<String>>(None()));
    });
  });

  group('watchWithdrawn', () {
    test('オンラインで A の購読を始め、記録が無い状態から記録ができた場合、ストリームが Right(false)、Right(true) の順に通知する [ACD-R45]',
        () async {
      final w = FakeWithdrawnAccountRemoteDataSource()
        ..emitCurrentOnWatch = true;
      final events = <Either<Failure, bool>>[];
      final sub = buildRepo(w).watchWithdrawn(userA).listen(events.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);

      w.watchController.add(true);
      await Future<void>.delayed(Duration.zero);

      expect(events, [
        const Right<Failure, bool>(false),
        const Right<Failure, bool>(true),
      ]);
    });

    test('オンラインで退会済みの記録の監視が例外を通知する状態で A の購読を始めた場合、ストリームが Left(UnknownFailure) を通知する [ACD-R46]',
        () async {
      final w = FakeWithdrawnAccountRemoteDataSource();
      final events = <Either<Failure, bool>>[];
      final sub = buildRepo(w).watchWithdrawn(userA).listen(events.add);
      addTearDown(sub.cancel);
      await Future<void>.delayed(Duration.zero);

      w.watchController.addError(Exception('watch failed'));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      events.single
          .match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
    });

    test('オンラインで A に退会済みの記録がある状態で A の購読を始めた場合、ストリームの最初の通知が Right(true) になる [ACD-R48]',
        () async {
      final w = FakeWithdrawnAccountRemoteDataSource()
        ..withdrawn.add(userA)
        ..emitCurrentOnWatch = true;

      final first = await buildRepo(w).watchWithdrawn(userA).first;

      expect(first, const Right<Failure, bool>(true));
    });
  });

  group('強制ログアウトした uid の同期の停止（SyncRepository の契約）', () {
    late _CountingSyncRemoteDataSource syncRemote;
    late SyncQueueDataSource syncQueue;
    late SyncLocalDataSource syncLocal;
    late SyncService service;

    setUp(() async {
      syncRemote = _CountingSyncRemoteDataSource();
      syncQueue = SyncQueueDataSource(dbHelper);
      syncLocal = SyncLocalDataSource(dbHelper);
      service = SyncService(
        localDataSource: syncLocal,
        syncQueueDataSource: syncQueue,
        remoteDataSource: syncRemote,
        connectivityMonitor: connectivity,
        getCurrentUserId: () => userA,
        isAccountDeletionPending: local.shouldSkipSync,
        clock: () => DateTime.utc(2024, 6, 2),
      );
      await seedUser(userA);
      await repo.markForcedSignOut(userA);
    });

    test('ログイン中の uid A に強制ログアウトの記録があり未送信の変更が1件ある状態で syncAll を呼んだ場合、リモートへの送信・取得は0回で未送信の変更は1件のままになる [ACD-R47]',
        () async {
      await service.syncAll();

      expect(syncRemote.calls, isEmpty);
      expect(await syncQueue.countByUser(userA), 1);
    });

    test('ログイン中の uid A に強制ログアウトの記録があり未送信の変更が1件ある状態で pushPending を呼んだ場合、リモートへの送信は0回で未送信の変更は1件のままになる [ACD-R49]',
        () async {
      await service.pushPending();

      expect(syncRemote.calls, isEmpty);
      expect(await syncQueue.countByUser(userA), 1);
    });

    test('ログイン中の uid A に強制ログアウトの記録があり前回の取得から5分以上たった状態で syncOnResumed を呼んだ場合、リモートからの取得は0回になる [ACD-R50]',
        () async {
      await syncLocal.writeMetaDate('lastPulledAt:$userA', DateTime.utc(2024, 6, 1));

      await service.syncOnResumed();

      expect(syncRemote.calls.where((c) => c.startsWith('fetch:')), isEmpty);
    });
  });
}
