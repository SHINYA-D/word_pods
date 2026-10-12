import 'package:sqflite/sqflite.dart';
import 'package:word_stock/domain/entities/account_deletion_request.dart';
import 'database_helper.dart';
import 'local_date.dart';
import 'tables/account_deletion_table.dart';
import 'tables/flashcard_result_table.dart';
import 'tables/folder_table.dart';
import 'tables/settings_table.dart';
import 'tables/sync_meta_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/word_table.dart';

/// 退会処理の記録の読み書きと、端末内のユーザーのデータの削除。
class AccountDeletionLocalDataSource {
  AccountDeletionLocalDataSource(this._dbHelper, {DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  final DatabaseHelper _dbHelper;
  final DateTime Function() _now;

  static const _statusRequested = 'requested';
  static const _statusServerDone = 'server_done';

  /// 端末に残っている記録を1件返す（同時に複数の記録は作られない）。
  Future<AccountDeletionRequest?> findAny() async {
    final db = await _dbHelper.database;
    final rows = await db.query(AccountDeletionTable.tableName, limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// そのユーザーの同期を止めるか。退会処理の途中と、強制ログアウトした uid
  /// （アプリではログアウトしたものとして扱う）は同期しない。
  Future<bool> shouldSkipSync(String userId) async =>
      await existsFor(userId) || await isForcedSignOut(userId);

  /// そのユーザーの記録があるか。
  Future<bool> existsFor(String userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      AccountDeletionTable.tableName,
      columns: ['user_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.isNotEmpty;
  }

  Future<void> markRequested(String userId) =>
      _write(userId, _statusRequested);

  Future<void> markServerDone(String userId) =>
      _write(userId, _statusServerDone);

  Future<void> clear(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      AccountDeletionTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// そのユーザーのデータ・キュー・同期の基準と、退会処理の記録を1つのトランザクションで削除する。
  /// 他のユーザーの行は残す。
  Future<void> deleteUserData(String userId) => deleteUsersData([userId]);

  /// 複数のユーザーのデータ・キュー・同期の基準と、退会処理の記録を1つのトランザクションで削除する。
  /// 途中で失敗したら、どのユーザーの行も削除されない。強制ログアウトの記録は残す。
  Future<void> deleteUsersData(List<String> userIds) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final userId in userIds) {
        for (final table in [
          WordTable.tableName,
          FlashcardResultTable.tableName,
          FolderTable.tableName,
          SettingsTable.tableName,
        ]) {
          await txn.delete(table, where: 'userId = ?', whereArgs: [userId]);
        }
        await txn.delete(
          SyncQueueTable.tableName,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        await txn.delete(
          SyncMetaTable.tableName,
          where: 'key IN (?, ?)',
          whereArgs: ['pullCursor:$userId', 'lastPulledAt:$userId'],
        );
        await txn.delete(
          AccountDeletionTable.tableName,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }
    });
  }

  /// 端末内にデータ（データ・キュー・同期の基準のどれか）がある uid の一覧（重複なし）。
  Future<List<String>> findUserIds() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT userId AS uid FROM ${FolderTable.tableName}
      UNION SELECT userId FROM ${WordTable.tableName}
      UNION SELECT userId FROM ${FlashcardResultTable.tableName}
      UNION SELECT userId FROM ${SettingsTable.tableName}
      UNION SELECT user_id FROM ${SyncQueueTable.tableName}
      UNION SELECT substr(key, instr(key, ':') + 1) FROM ${SyncMetaTable.tableName}
        WHERE key LIKE 'pullCursor:%' OR key LIKE 'lastPulledAt:%'
    ''');
    return [
      for (final row in rows)
        if (row['uid'] case final String uid when uid.isNotEmpty) uid,
    ];
  }

  /// ログアウトが失敗したため、アプリではログアウトしたものとして扱う uid を記録する（1つだけ持つ）。
  Future<void> markForcedSignOut(String userId) async {
    final db = await _dbHelper.database;
    await db.insert(
      SyncMetaTable.tableName,
      {'key': _forcedSignOutKey, 'value': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 強制ログアウトの記録の uid。無ければ null。
  Future<String?> findForcedSignOut() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      SyncMetaTable.tableName,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_forcedSignOutKey],
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  /// その uid の強制ログアウトの記録があるか。
  Future<bool> isForcedSignOut(String userId) async =>
      await findForcedSignOut() == userId;

  /// その uid の強制ログアウトの記録を消す。
  Future<void> clearForcedSignOut(String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      SyncMetaTable.tableName,
      where: 'key = ? AND value = ?',
      whereArgs: [_forcedSignOutKey, userId],
    );
  }

  static const _forcedSignOutKey = 'forcedSignOut';

  Future<void> _write(String userId, String status) async {
    final db = await _dbHelper.database;
    await db.insert(
      AccountDeletionTable.tableName,
      {
        'user_id': userId,
        'status': status,
        'updated_at': toDateColumn(_now()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  AccountDeletionRequest _fromRow(Map<String, Object?> row) {
    return AccountDeletionRequest(
      userId: row['user_id']! as String,
      status: row['status'] == _statusServerDone
          ? AccountDeletionStatus.serverDone
          : AccountDeletionStatus.requested,
      updatedAt: fromDateColumn(row['updated_at']),
    );
  }
}
