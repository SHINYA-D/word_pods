import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:word_pods/core/firebase/firestore_path.dart';

/// Firestore の `accounts/{uid}` を読む。書き込みはサーバー（Cloud Functions・コンソール）だけが行う。
class AccountRemoteDataSource {
  AccountRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  /// `isDeveloper` が true（真偽値）のときだけ true を返す。
  Future<bool> fetchIsDeveloper(String userId) async {
    final snapshot = await _firestore.doc(FirestorePath.account(userId)).get();
    return snapshot.data()?['isDeveloper'] == true;
  }
}
