import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    required this._firebaseAuth,
    required this._googleSignIn,
  });

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// [reloadCurrentUser] で取り直したユーザー。
  /// `userChanges()` が取り直しを流さない環境でも、確認済みになったことを画面の振り分けに伝えるために流す
  final _reloaded = StreamController<User?>.broadcast();

  /// ログイン状態と、ユーザーの情報（確認済みかどうか等）の変化。
  /// `authStateChanges()` は確認済みに変わったことを流さないため、`userChanges()` を使う
  Stream<User?> get authStateChanges {
    StreamSubscription<User?>? changes;
    StreamSubscription<User?>? reloaded;
    late final StreamController<User?> controller;
    controller = StreamController<User?>(
      onListen: () {
        changes = _firebaseAuth.userChanges().listen(
              controller.add,
              onError: controller.addError,
            );
        reloaded = _reloaded.stream.listen(controller.add);
      },
      onCancel: () async {
        await changes?.cancel();
        await reloaded?.cancel();
      },
    );
    return controller.stream;
  }

  bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// ログイン中のユーザーの最新の状態を取り直す。ログインしていなければ null。
  /// 先にログイン情報（ID トークン）を取り直す。確認済みになっていれば、トークンの
  /// `email_verified` も true になり、Firestore のルールで読み書きが通るようになる。
  /// その後でユーザーを取り直すので、確認済みが画面に伝わった時点で、同期に使うトークンも新しい
  Future<User?> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    await user.getIdToken(true);
    await user.reload();
    final refreshed = _firebaseAuth.currentUser;
    _reloaded.add(refreshed);
    return refreshed;
  }

  /// Firebase が送るメール（確認メール等）の言語
  Future<void> setLanguageCode(String languageCode) =>
      _firebaseAuth.setLanguageCode(languageCode);

  /// ログイン中のユーザーに確認メールを送る。ログインしていなければ何もしない
  Future<void> sendEmailVerification() async {
    await _firebaseAuth.currentUser?.sendEmailVerification();
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) rethrow;
      throw FirebaseAuthException(
        code: 'sign_in_cancelled',
        message: 'Google sign in was cancelled.',
      );
    }
    final credential = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
