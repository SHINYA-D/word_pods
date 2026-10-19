import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:word_stock/core/firebase/firestore_path.dart';

/// 規約の現行の版数（`app_config/legal`）・同意済みの版数（`accounts/{uid}.consents`）を読み、
/// Cloud Functions の関数 `acceptLegal` で同意を送る。値の解釈は Repository が行う。
class LegalRemoteDataSource {
  LegalRemoteDataSource(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const functionName = 'acceptLegal';
  static const timeout = Duration(seconds: 30);

  /// `app_config/legal` の中身。ドキュメントが無ければ null。キャッシュではなくサーバーから読む。
  Future<Map<String, dynamic>?> fetchConfig() async {
    final snapshot = await _firestore
        .doc(FirestorePath.legalConfig)
        .get(const GetOptions(source: Source.server));
    return snapshot.data();
  }

  /// `accounts/{uid}.consents` の値（型は確かめない）。ドキュメントが無ければ null。
  Future<Object?> fetchConsents(String userId) async {
    final snapshot = await _firestore
        .doc(FirestorePath.account(userId))
        .get(const GetOptions(source: Source.server));
    return snapshot.data()?['consents'];
  }

  /// [versions] は `{ terms?: 版数, privacy?: 版数 }`。
  Future<void> accept(Map<String, String> versions) async {
    await _functions
        .httpsCallable(
          functionName,
          options: HttpsCallableOptions(timeout: timeout),
        )
        .call<void>(versions);
  }
}
