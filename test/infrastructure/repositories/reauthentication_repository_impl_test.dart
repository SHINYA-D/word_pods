import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/infrastructure/data_sources/remote/reauthentication_remote_data_source.dart';
import 'package:word_pods/infrastructure/repositories/reauthentication_repository_impl.dart';

class _FakeUser implements User {
  _FakeUser({this.email, this.error});

  @override
  final String? email;

  /// 本人確認で投げる例外。null なら成功
  final Object? error;

  final List<AuthCredential> credentials = [];

  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) async {
    credentials.add(credential);
    final e = error;
    if (e != null) throw e;
    throw _Success();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 本人確認の成功を表す（UserCredential を作れないため、例外で代用せず下の
/// _SuccessUser で成功を表現する）。
class _Success implements Exception {}

/// reauthenticateWithCredential が成功する User。
class _OkUser extends _FakeUser {
  _OkUser({super.email});

  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) async {
    credentials.add(credential);
    return _FakeUserCredential();
  }
}

class _FakeUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth implements FirebaseAuth {
  _FakeAuth(this.currentUser);

  @override
  final User? currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleAuthentication implements GoogleSignInAuthentication {
  @override
  String? get accessToken => 'access-token';

  @override
  String? get idToken => 'id-token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleAccount implements GoogleSignInAccount {
  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _FakeGoogleAuthentication();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleSignIn implements GoogleSignIn {
  _FakeGoogleSignIn({this.cancel = false});

  final bool cancel;
  int signInCalls = 0;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    signInCalls++;
    return cancel ? null : _FakeGoogleAccount();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FirebaseAuthException _authError(String code) =>
    FirebaseAuthException(code: code);

ReauthenticationRepositoryImpl _repo(User? user, GoogleSignIn google) =>
    ReauthenticationRepositoryImpl(ReauthenticationRemoteDataSource(
      firebaseAuth: _FakeAuth(user),
      googleSignIn: google,
    ));

void main() {
  Future<Either<Failure, Unit>> password(Object error) =>
      _repo(_FakeUser(email: 'a@example.com', error: error),
              _FakeGoogleSignIn())
          .reauthenticateWithPassword('pw');

  Future<Either<Failure, bool>> google(Object error) =>
      _repo(_FakeUser(email: 'a@example.com', error: error),
              _FakeGoogleSignIn())
          .reauthenticateWithGoogle();

  group('reauthenticateWithPassword', () {
    test('本人確認が成功した場合、Right(unit) が返り、本人確認に渡したパスワードは引数と同じ [ACD-R52]', () async {
      final user = _OkUser(email: 'a@example.com');
      final result =
          await _repo(user, _FakeGoogleSignIn()).reauthenticateWithPassword('pw-1');
      expect(result, const Right<Failure, Unit>(unit));
      expect(user.credentials.single.signInMethod, 'password');
      expect((user.credentials.single as dynamic).password, 'pw-1');
    });

    test('エラーコード wrong-password で失敗した場合、Left(AuthFailure) が返る [ACD-R53]', () async {
      expect(await password(_authError('wrong-password')),
          const Left<Failure, Unit>(Failure.auth()));
    });

    test('エラーコード invalid-credential で失敗した場合、Left(AuthFailure) が返る [ACD-R54]', () async {
      expect(await password(_authError('invalid-credential')),
          const Left<Failure, Unit>(Failure.auth()));
    });

    test('エラーコード network-request-failed で失敗した場合、Left(NetworkFailure) が返る [ACD-R55]', () async {
      expect(await password(_authError('network-request-failed')),
          const Left<Failure, Unit>(Failure.network()));
    });

    test('エラーコード too-many-requests で失敗した場合、Left(TooManyRequestsFailure) が返る [ACD-R56]', () async {
      expect(await password(_authError('too-many-requests')),
          const Left<Failure, Unit>(Failure.tooManyRequests()));
    });

    test('FirebaseAuthException 以外の例外で失敗した場合、Left(UnknownFailure) が返る [ACD-R57]', () async {
      final result = await password(StateError('boom'));
      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
    });

    test('エラーコード user-mismatch で失敗した場合、Left(AuthFailure) が返る [ACD-R65]', () async {
      expect(await password(_authError('user-mismatch')),
          const Left<Failure, Unit>(Failure.auth()));
    });

    test('エラーコード user-not-found で失敗した場合、Left(AuthFailure) が返る [ACD-R66]', () async {
      expect(await password(_authError('user-not-found')),
          const Left<Failure, Unit>(Failure.auth()));
    });

    test('ログインしていない場合、Left(UnknownFailure) が返り、本人確認は0回 [ACD-R67]', () async {
      final result =
          await _repo(null, _FakeGoogleSignIn()).reauthenticateWithPassword('pw');
      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
    });

    test('メールアドレス「a@example.com」のユーザーでログイン中に「pass1234」で呼んだ場合、本人確認にそのメールアドレスとパスワードが渡される [ACD-R68]', () async {
      final user = _OkUser(email: 'a@example.com');
      await _repo(user, _FakeGoogleSignIn()).reauthenticateWithPassword('pass1234');
      final cred = user.credentials.single as dynamic;
      expect(cred.email, 'a@example.com');
      expect(cred.password, 'pass1234');
    });

    test('エラーコード user-disabled で失敗した場合、Left(UnknownFailure) が返る [ACD-R75]', () async {
      final result = await password(_authError('user-disabled'));
      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
    });
  });

  group('reauthenticateWithGoogle', () {
    test('Google の本人確認が成功した場合、Right(true) が返る [ACD-R58]', () async {
      final result = await _repo(_OkUser(email: 'a@example.com'), _FakeGoogleSignIn())
          .reauthenticateWithGoogle();
      expect(result, const Right<Failure, bool>(true));
    });

    test('Google のアカウント選択がキャンセルされた場合、Right(false) が返る [ACD-R59]', () async {
      final user = _OkUser(email: 'a@example.com');
      final result = await _repo(user, _FakeGoogleSignIn(cancel: true))
          .reauthenticateWithGoogle();
      expect(result, const Right<Failure, bool>(false));
      expect(user.credentials, isEmpty);
    });

    test('エラーコード user-mismatch で失敗した場合、Left(AuthFailure) が返る [ACD-R60]', () async {
      expect(await google(_authError('user-mismatch')),
          const Left<Failure, bool>(Failure.auth()));
    });

    test('エラーコード network-request-failed で失敗した場合、Left(NetworkFailure) が返る [ACD-R61]', () async {
      expect(await google(_authError('network-request-failed')),
          const Left<Failure, bool>(Failure.network()));
    });

    test('FirebaseAuthException 以外の例外で失敗した場合、Left(UnknownFailure) が返る [ACD-R62]', () async {
      final result = await google(StateError('boom'));
      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
    });

    test('エラーコード invalid-credential で失敗した場合、Left(AuthFailure) が返る [ACD-R69]', () async {
      expect(await google(_authError('invalid-credential')),
          const Left<Failure, bool>(Failure.auth()));
    });

    test('ログインしていない場合、Left(UnknownFailure) が返り、Google のアカウント選択は表示されない [ACD-R70]', () async {
      final googleSignIn = _FakeGoogleSignIn();
      final result = await _repo(null, googleSignIn).reauthenticateWithGoogle();
      expect(result.isLeft(), isTrue);
      result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
      expect(googleSignIn.signInCalls, 0);
    });

    test('エラーコード user-not-found で失敗した場合、Left(AuthFailure) が返る [ACD-R73]', () async {
      expect(await google(_authError('user-not-found')),
          const Left<Failure, bool>(Failure.auth()));
    });

    test('エラーコード too-many-requests で失敗した場合、Left(TooManyRequestsFailure) が返る [ACD-R74]', () async {
      expect(await google(_authError('too-many-requests')),
          const Left<Failure, bool>(Failure.tooManyRequests()));
    });
  });
}
