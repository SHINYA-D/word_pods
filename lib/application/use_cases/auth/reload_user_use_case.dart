import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/repositories/email_verification_repository.dart';

/// ログイン中のユーザーの最新の状態（メールアドレスが確認済みか）を問い合わせる。
class ReloadUserUseCase {
  const ReloadUserUseCase(this._repository);

  final EmailVerificationRepository _repository;

  Future<Either<Failure, AppUser>> call() => _repository.reloadUser();
}
