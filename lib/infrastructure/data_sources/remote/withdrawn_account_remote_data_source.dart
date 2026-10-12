import 'package:cloud_firestore/cloud_firestore.dart';

/// 退会済みの記録（Firestore の `deleted_accounts/{uid}`）を読む。
///
/// 記録は関数 `deleteAccount` が退会時に作り、退会後も残る。ログインしていなくても1件ずつ読める。
class WithdrawnAccountRemoteDataSource {
  WithdrawnAccountRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const collection = 'deleted_accounts';

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection(collection).doc(userId);

  /// その uid に退会済みの記録があるか。キャッシュではなくサーバーから読む。
  Future<bool> isWithdrawn(String userId) async {
    final snapshot =
        await _doc(userId).get(const GetOptions(source: Source.server));
    return snapshot.exists;
  }

  /// その uid の退会済みの記録をリアルタイムで監視する。記録の有無が変わるたびに通知する。
  Stream<bool> watch(String userId) =>
      _doc(userId).snapshots().map((snapshot) => snapshot.exists);
}
