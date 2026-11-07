import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication で、ログイン中のユーザーの本人確認をし直す。
class ReauthenticationRemoteDataSource {
  ReauthenticationRemoteDataSource({
    required this._firebaseAuth,
    required this._googleSignIn,
  });

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  Future<void> reauthenticateWithPassword(String password) async {
    final user = _currentUser();
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email ?? '', password: password),
    );
  }

  /// キャンセルされたら false。
  Future<bool> reauthenticateWithGoogle() async {
    final user = _currentUser();
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
    await user.reauthenticateWithCredential(GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    ));
    return true;
  }

  User _currentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user');
    return user;
  }
}
