import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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

void main() {
  const userId = 'user-1';
  const otherUser = 'user-2';

  late DatabaseHelper dbHelper;
  late AccountDeletionLocalDataSource dataSource;
  late DateTime now;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // DBファイルのロック競合を避けるため、このテストファイル専用の一時ディレクトリを使う。
    final tempDir = await Directory.systemTemp.createTemp(
      'account_deletion_local_data_source_test_',
    );
    await databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    for (final table in [
      AccountDeletionTable.tableName,
      WordTable.tableName,
      FolderTable.tableName,
      FlashcardResultTable.tableName,
      SettingsTable.tableName,
      SyncQueueTable.tableName,
      SyncMetaTable.tableName,
    ]) {
      await db.delete(table);
    }
    now = DateTime(2024, 5, 1, 10, 0);
    dataSource = AccountDeletionLocalDataSource(dbHelper, clock: () => now);
  });

  /// userId の各テーブルの行・キュー・同期の基準を1行ずつ入れる。
  Future<void> seedUser(String id) async {
    final db = await dbHelper.database;
    final ts = DateTime(2024, 1, 1).toUtc().toIso8601String();
    await db.insert(WordTable.tableName, {
      'id': 'word-$id',
      'front': 'f',
      'back': 'b',
      'folderId': 'folder-$id',
      'userId': id,
      'createdAt': ts,
      'updatedAt': ts,
    });
    await db.insert(FolderTable.tableName, {
      'id': 'folder-$id',
      'name': 'n',
      'userId': id,
      'createdAt': ts,
      'updatedAt': ts,
    });
    await db.insert(FlashcardResultTable.tableName, {
      'id': 'result-$id',
      'folderId': 'folder-$id',
      'totalCount': 1,
      'correctCount': 1,
      'date': ts,
      'userId': id,
      'updatedAt': ts,
    });
    await db.insert(SettingsTable.tableName, {
      'userId': id,
      'updatedAt': ts,
    });
    await db.insert(SyncQueueTable.tableName, {
      'operation': 'upsert',
      'table_name': 'folders',
      'record_id': 'folder-$id',
      'created_at': ts,
      'user_id': id,
    });
    await db.insert(SyncMetaTable.tableName,
        {'key': 'pullCursor:$id', 'value': 'c'});
    await db.insert(SyncMetaTable.tableName,
        {'key': 'lastPulledAt:$id', 'value': ts});
    await dataSource.markServerDone(id);
  }

  Future<int> countRows(String table) async {
    final db = await dbHelper.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'))!;
  }

  group('findAny', () {
    test('記録が1件も無い場合、nullが返る', () async {
      expect(await dataSource.findAny(), isNull);
    });

    test('記録が無い状態でmarkRequestedした場合、statusがrequestedでuserIdとupdatedAtがDateTimeとして読み戻せる', () async {
      await dataSource.markRequested(userId);

      final request = await dataSource.findAny();

      expect(
        request,
        AccountDeletionRequest(
          userId: userId,
          status: AccountDeletionStatus.requested,
          updatedAt: now,
        ),
      );
    });

    test('記録が無い状態でmarkServerDoneした場合、statusがserverDoneとして読み戻せる', () async {
      await dataSource.markServerDone(userId);

      final request = await dataSource.findAny();

      expect(request!.status, AccountDeletionStatus.serverDone);
    });

    test('markRequestedで記録した場合、updated_atがUTCのISO8601文字列(末尾Z)で保存される', () async {
      await dataSource.markRequested(userId);

      final db = await dbHelper.database;
      final rows = await db.query(AccountDeletionTable.tableName);

      expect(rows.single['updated_at'], endsWith('Z'));
      expect(rows.single['updated_at'], now.toUtc().toIso8601String());
    });
  });

  group('existsFor', () {
    test('そのユーザーの記録がある場合、trueが返る', () async {
      await dataSource.markRequested(userId);

      expect(await dataSource.existsFor(userId), isTrue);
    });

    test('他のユーザーの記録だけがある場合、falseが返る', () async {
      await dataSource.markRequested(otherUser);

      expect(await dataSource.existsFor(userId), isFalse);
    });

    test('記録が1件も無い場合、falseが返る', () async {
      expect(await dataSource.existsFor(userId), isFalse);
    });
  });

  group('markRequested / markServerDone', () {
    test('requestedの記録があるユーザーをmarkServerDoneした場合、1行のままstatusとupdatedAtが上書きされる',
        () async {
      await dataSource.markRequested(userId);
      now = DateTime(2024, 5, 2, 12, 30);

      await dataSource.markServerDone(userId);

      expect(await countRows(AccountDeletionTable.tableName), 1);
      final request = await dataSource.findAny();
      expect(request!.status, AccountDeletionStatus.serverDone);
      expect(request.updatedAt, DateTime(2024, 5, 2, 12, 30));
    });
  });

  group('clear', () {
    test('2人のユーザーの記録がある状態で一方をclearした場合、そのユーザーの記録だけが消え、他のユーザーの記録は残る', () async {
      await dataSource.markRequested(userId);
      await dataSource.markRequested(otherUser);

      await dataSource.clear(userId);

      expect(await dataSource.existsFor(userId), isFalse);
      expect(await dataSource.existsFor(otherUser), isTrue);
    });
  });

  group('deleteUserData', () {
    test('そのユーザーのデータと記録がある状態でdeleteUserDataした場合、そのユーザーのデータ・キュー・同期の基準・退会記録がすべて消える', () async {
      await seedUser(userId);

      await dataSource.deleteUserData(userId);

      for (final table in [
        WordTable.tableName,
        FolderTable.tableName,
        FlashcardResultTable.tableName,
        SettingsTable.tableName,
        SyncQueueTable.tableName,
        SyncMetaTable.tableName,
        AccountDeletionTable.tableName,
      ]) {
        expect(await countRows(table), 0, reason: table);
      }
    });

    test('他のユーザーの行がある場合、deleteUserDataしてもその行（記録・同期の基準を含む）は残る', () async {
      await seedUser(userId);
      await seedUser(otherUser);

      await dataSource.deleteUserData(userId);

      for (final table in [
        WordTable.tableName,
        FolderTable.tableName,
        FlashcardResultTable.tableName,
        SettingsTable.tableName,
        SyncQueueTable.tableName,
        AccountDeletionTable.tableName,
      ]) {
        expect(await countRows(table), 1, reason: table);
      }
      final db = await dbHelper.database;
      final metaKeys = (await db.query(SyncMetaTable.tableName))
          .map((r) => r['key'])
          .toSet();
      expect(metaKeys, {'pullCursor:$otherUser', 'lastPulledAt:$otherUser'});
    });

    test('sync_metaに当該2キー以外のキーがある場合、deleteUserDataしてもそのキーは残る', () async {
      await seedUser(userId);
      final db = await dbHelper.database;
      await db.insert(SyncMetaTable.tableName,
          {'key': 'lastSyncedAt', 'value': 'x'});

      await dataSource.deleteUserData(userId);

      final metaKeys = (await db.query(SyncMetaTable.tableName))
          .map((r) => r['key'])
          .toList();
      expect(metaKeys, ['lastSyncedAt']);
    });

    test('削除の途中で失敗した場合、それまでの削除も取り消され1つも消えない', () async {
      await seedUser(userId);
      final db = await dbHelper.database;
      // sync_meta の削除で失敗させる（それより前の削除が巻き戻ることを確認する）。
      await db.execute('ALTER TABLE sync_meta RENAME TO sync_meta_x');
      try {
        await expectLater(dataSource.deleteUserData(userId), throwsA(anything));
      } finally {
        await db.execute('ALTER TABLE sync_meta_x RENAME TO sync_meta');
      }

      for (final table in [
        WordTable.tableName,
        FolderTable.tableName,
        FlashcardResultTable.tableName,
        SettingsTable.tableName,
        SyncQueueTable.tableName,
        AccountDeletionTable.tableName,
      ]) {
        expect(await countRows(table), 1, reason: table);
      }
    });
  });
}
