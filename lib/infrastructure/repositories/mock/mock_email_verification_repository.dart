import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/repositories/email_verification_repository.dart';

/// 開発用。Mock のユーザーは最初から確認済みなので、送信も問い合わせも成功を返す。
class MockEmailVerificationRepository implements EmailVerificationRepository {
  MockEmailVerificationRepository(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<Either<Failure, AppUser>> reloadUser() async {
    final user = await _authRepository.authStateChanges.first;
    if (user == null) return const Left(Failure.auth());
    return Right(user);
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async =>
      const Right(unit);
}
