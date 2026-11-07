import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/email_verification_repository.dart';

/// ログイン中のユーザーに確認メールを送る。
class SendEmailVerificationUseCase {
  const SendEmailVerificationUseCase(this._repository);

  final EmailVerificationRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.sendEmailVerification();
}
