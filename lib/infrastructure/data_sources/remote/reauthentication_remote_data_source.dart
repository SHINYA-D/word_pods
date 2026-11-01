import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication で、ログイン中のユーザーの本人確認をし直す。
class ReauthenticationRemoteDataSource {
  ReauthenticationRemoteDataSource({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

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
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false;
    final googleAuth = await googleUser.authentication;
    await user.reauthenticateWithCredential(GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    ));
    return true;
  }

  User _currentUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user');
    return user;
  }
}
