// 仕様書: docs/detailed_design/presentation/settings/settings_page.md（接頭辞 ACD、5.1）
//
// 期待値はすべて上記仕様書から作った。実装は「どう呼ぶか」を知るためだけに読んでいる。
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:word_stock/core/error/failure.dart';
import 'package:word_stock/domain/entities/account_deletion_request.dart';
import 'package:word_stock/infrastructure/data_sources/local/account_deletion_local_data_source.dart';
import 'package:word_stock/infrastructure/data_sources/local/database_helper.dart';
import 'package:word_stock/infrastructure/data_sources/local/tables/account_deletion_table.dart';
import 'package:word_stock/infrastructure/data_sources/local/tables/flashcard_result_table.dart';
import 'package:word_stock/infrastructure/data_sources/local/tables/folder_table.dart';
import 'package:word_stock/infrastructure/data_sources/local/tables/settings_table.dart';
import 'package:word_stock/infrastructure/data_sources/local/tables/sync_meta_table.dart';
import 'package:word_stock/infrastructure/data_sources/local/tables/sync_queue_table.dart';
import 'package:word_stock/infrastructure/data_sources/local/tables/word_table.dart';
import 'package:word_stock/infrastructure/data_sources/remote/account_deletion_remote_data_source.dart';
import 'package:word_stock/infrastructure/repositories/account_deletion_repository_impl.dart';

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
        connectivityMonitor: connectivity,
      );

      await repoWithReal.requestServerDeletion();

      expect(functions.name, 'deleteAccount');
      expect(functions.options?.timeout, const Duration(seconds: 60));
    });
  });
}
