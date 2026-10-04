import 'package:sqflite/sqflite.dart';

/// 退会処理の進み具合の記録。同期用のキュー（sync_queue）とは別に持つ（同期処理に読ませないため）。
class AccountDeletionTable {
  static const String tableName = 'account_deletion';

  static Future<void> onCreate(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        user_id TEXT PRIMARY KEY,
        status TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }
}
