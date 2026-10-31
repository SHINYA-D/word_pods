import 'dart:developer' show log;

import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/repositories/legal_repository.dart';
import 'package:word_pods/domain/repositories/sync_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._repository, this._syncService, this._legalRepository);

  final AuthRepository _repository;
  final SyncRepository _syncService;
  final LegalRepository _legalRepository;

  /// アカウントを作り、新規登録画面で同意した版数（[termsVersion] / [privacyVersion]）で同意を送信してから、
  /// 初回の同期を行う。同意の送信が失敗しても登録は成功として扱う（その後の判定で同意ダイアログが出る）。
  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
    required String termsVersion,
    required String privacyVersion,
  }) async {
    final result = await _repository.signUpWithEmail(
        email: email, password: password);
    await result.fold(
      (_) async {},
      (_) async {
        final accepted = await _legalRepository.accept(
          termsVersion: termsVersion,
          privacyVersion: privacyVersion,
        );
        accepted.fold(
          (failure) => log('acceptLegal on sign up failed: $failure'),
          (_) {},
        );
        try {
          await _syncService.syncRemoteToLocalOnLogin();
        } catch (e, stack) {
          log('syncRemoteToLocalOnLogin failed: $e\n$stack');
        }
      },
    );
    return result;
  }
}
