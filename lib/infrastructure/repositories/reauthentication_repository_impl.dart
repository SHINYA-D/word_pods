import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/reauthentication_repository.dart';
import 'package:word_pods/infrastructure/data_sources/remote/reauthentication_remote_data_source.dart';

class ReauthenticationRepositoryImpl implements ReauthenticationRepository {
  ReauthenticationRepositoryImpl(this._remote);

  final ReauthenticationRemoteDataSource _remote;

  @override
  Future<Either<Failure, Unit>> reauthenticateWithPassword(
    String password,
  ) =>
      _guard(() async {
        await _remote.reauthenticateWithPassword(password);
        return unit;
      });

  @override
  Future<Either<Failure, bool>> reauthenticateWithGoogle() =>
      _guard(_remote.reauthenticateWithGoogle);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on FirebaseAuthException catch (e) {
      return Left(_map(e));
    } catch (e) {
      return Left(Failure.unknown(e.toString()));
    }
  }

  Failure _map(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return const Failure.network();
      case 'too-many-requests':
        return const Failure.tooManyRequests();
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-mismatch':
      case 'user-not-found':
        return const Failure.auth();
      default:
        return Failure.unknown(e.message ?? e.code);
    }
  }
}
