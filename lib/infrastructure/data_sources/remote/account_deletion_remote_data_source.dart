import 'package:cloud_functions/cloud_functions.dart';

/// Cloud Functions の関数 `deleteAccount` を呼ぶ。
/// サーバー側で、呼び出したユーザーの Firestore のデータと Authentication のユーザーを削除する。
class AccountDeletionRemoteDataSource {
  AccountDeletionRemoteDataSource(this._functions);

  final FirebaseFunctions _functions;

  static const functionName = 'deleteAccount';

  /// 応答をこの時間待って来なければ `deadline-exceeded` で失敗する（届いたか分からない扱い）。
  static const timeout = Duration(seconds: 60);

  Future<void> deleteAccount() async {
    await _functions
        .httpsCallable(
          functionName,
          options: HttpsCallableOptions(timeout: timeout),
        )
        .call<void>();
  }
}
