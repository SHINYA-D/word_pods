import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/reauthentication_repository.dart';

/// 開発用。本人確認は常に成功する。
class MockReauthenticationRepository implements ReauthenticationRepository {
  @override
  Future<Either<Failure, Unit>> reauthenticateWithPassword(
    String password,
  ) async =>
      const Right(unit);

  @override
  Future<Either<Failure, bool>> reauthenticateWithGoogle() async =>
      const Right(true);
}
