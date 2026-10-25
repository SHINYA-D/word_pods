import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/repositories/sync_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this._repository, this._syncRepository);

  final AuthRepository _repository;
  final SyncRepository _syncRepository;

  /// 未送信の変更を送信してからログアウトする。
  /// 送信しきれなかった変更はローカルに残し、同じユーザーが次にログインしたときに送信する。
  Future<Either<Failure, Unit>> call() async {
    await _syncRepository.pushBeforeSignOut();
    return _repository.signOut();
  }
}
