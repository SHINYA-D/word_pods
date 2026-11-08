import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/core/utils/crash_reporting.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/services/crash_reporter.dart';
import 'package:word_pods/infrastructure/data_sources/firebase_auth_data_source.dart';

/// Firebase のユーザーを [AppUser] にする（[AuthRepositoryImpl] と `EmailVerificationRepositoryImpl` で共通）
AppUser appUserFromFirebase(User user) {
  return AppUser(
    id: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    hasPassword: user.providerData.any((p) => p.providerId == 'password'),
    emailVerified: user.emailVerified,
  );
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource, {this._crashReporter});

  final FirebaseAuthDataSource _dataSource;
  final CrashReporter? _crashReporter;

  @override
  Stream<AppUser?> get authStateChanges {
    return _dataSource.authStateChanges.map(
      (user) => user == null ? null : _toAppUser(user),
    );
  }

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(_toAppUser(result.user!));
    } on FirebaseAuthException catch (e, stack) {
      return Left(_mapFirebaseAuthException(e, stack));
    } catch (e, stack) {
      return Left(reportUnknownFailure(_crashReporter, e, stack));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _dataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      return Right(_toAppUser(result.user!));
    } on FirebaseAuthException catch (e, stack) {
      return Left(_mapFirebaseAuthException(e, stack));
    } catch (e, stack) {
      return Left(reportUnknownFailure(_crashReporter, e, stack));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async {
    try {
      final result = await _dataSource.signInWithGoogle();
      return Right(_toAppUser(result.user!));
    } on FirebaseAuthException catch (e, stack) {
      return Left(_mapFirebaseAuthException(e, stack));
    } catch (e, stack) {
      return Left(reportUnknownFailure(_crashReporter, e, stack));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(unit);
    } on FirebaseAuthException catch (e, stack) {
      return Left(_mapFirebaseAuthException(e, stack));
    } catch (e, stack) {
      return Left(reportUnknownFailure(_crashReporter, e, stack));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _dataSource.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on FirebaseAuthException catch (e, stack) {
      return Left(_mapFirebaseAuthException(e, stack));
    } catch (e, stack) {
      return Left(reportUnknownFailure(_crashReporter, e, stack));
    }
  }

  AppUser _toAppUser(User user) => appUserFromFirebase(user);

  Failure _mapFirebaseAuthException(FirebaseAuthException e, StackTrace stack) {
    switch (e.code) {
      case 'network-request-failed':
        return const Failure.network();
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'email-already-in-use':
        return const Failure.auth();
      default:
        return reportUnknownFailure(_crashReporter, e, stack,
            message: e.message ?? e.code);
    }
  }
}
