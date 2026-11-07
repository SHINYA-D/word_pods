import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/repositories/email_verification_repository.dart';
import 'package:word_pods/infrastructure/data_sources/firebase_auth_data_source.dart';
import 'package:word_pods/infrastructure/repositories/auth_repository_impl.dart';

class EmailVerificationRepositoryImpl implements EmailVerificationRepository {
  EmailVerificationRepositoryImpl(this._dataSource);

  final FirebaseAuthDataSource _dataSource;

  @override
  Future<Either<Failure, AppUser>> reloadUser() async {
    try {
      final user = await _dataSource.reloadCurrentUser();
      if (user == null) return const Left(Failure.auth());
      return Right(appUserFromFirebase(user));
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(Failure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async {
    if (!_dataSource.isSignedIn) return const Left(Failure.auth());
    try {
      await _dataSource.setLanguageCode('ja');
      await _dataSource.sendEmailVerification();
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthException(e));
    } catch (e) {
      return Left(Failure.unknown(e.toString()));
    }
  }

  /// アカウントが無い・無効・ログイン情報の期限切れは [AuthFailure]（ログアウトしてログイン画面へ戻す）
  Failure _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return const Failure.network();
      case 'too-many-requests':
        return const Failure.tooManyRequests();
      case 'user-not-found':
      case 'user-disabled':
      case 'user-token-expired':
        return const Failure.auth();
      default:
        return Failure.unknown(e.message ?? e.code);
    }
  }
}
