import 'dart:developer' show log;

import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/repositories/sync_repository.dart';

class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase(this._repository, this._syncService);

  final AuthRepository _repository;
  final SyncRepository _syncService;

  Future<Either<Failure, AppUser>> call() async {
    final result = await _repository.signInWithGoogle();
    await result.fold(
      (_) async {},
      (_) async {
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
