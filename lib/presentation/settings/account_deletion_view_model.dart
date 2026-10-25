import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/application/use_cases/auth/delete_account_use_case.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/presentation/settings/account_deletion_state.dart';

part 'account_deletion_view_model.g.dart';

/// 退会処理の状態。退会後のログイン画面への移動や、起動時の再開をまたぐため keepAlive にする。
@Riverpod(keepAlive: true)
class AccountDeletionViewModel extends _$AccountDeletionViewModel {
  @override
  AccountDeletionState build() =>
      const AccountDeletionState(phase: AccountDeletionPhase.checking);

  /// 起動時の確認。記録があれば（読めなければ）再開待ちにする。
  Future<void> checkPending() async {
    final outcome = await ref.read(deleteAccountUseCaseProvider).checkPending();
    state = AccountDeletionState(
      phase: outcome == AccountDeletionOutcome.pending
          ? AccountDeletionPhase.pendingRetry
          : AccountDeletionPhase.idle,
    );
  }

  /// 確認ダイアログ2回のあとの退会処理。
  Future<void> withdraw() async {
    if (state.phase != AccountDeletionPhase.idle) return;
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    state = const AccountDeletionState(phase: AccountDeletionPhase.processing);
    final outcome =
        await ref.read(deleteAccountUseCaseProvider).withdraw(userId);
    state = AccountDeletionState(phase: _phaseOf(outcome));
  }

  /// 再開ダイアログの「再試行」。
  Future<void> retry() async {
    if (state.phase != AccountDeletionPhase.pendingRetry) return;
    state = const AccountDeletionState(
      phase: AccountDeletionPhase.processing,
      isRetry: true,
    );
    final outcome = await ref
        .read(deleteAccountUseCaseProvider)
        .resume(ref.read(currentUserProvider)?.id);
    state = AccountDeletionState(
      phase: _phaseOf(outcome),
      retryFailed: outcome == AccountDeletionOutcome.pending,
    );
  }

  /// 完了ダイアログを表示した。
  void acknowledgeCompleted() {
    if (state.phase != AccountDeletionPhase.completed) return;
    state = const AccountDeletionState(phase: AccountDeletionPhase.idle);
  }

  /// 「退会できませんでした」ダイアログを閉じた。
  void acknowledgeNotSent() {
    if (state.phase != AccountDeletionPhase.notSent) return;
    state = const AccountDeletionState(phase: AccountDeletionPhase.idle);
  }

  AccountDeletionPhase _phaseOf(AccountDeletionOutcome outcome) {
    switch (outcome) {
      case AccountDeletionOutcome.none:
        return AccountDeletionPhase.idle;
      case AccountDeletionOutcome.completed:
        return AccountDeletionPhase.completed;
      case AccountDeletionOutcome.notSent:
        return AccountDeletionPhase.notSent;
      case AccountDeletionOutcome.pending:
        return AccountDeletionPhase.pendingRetry;
    }
  }
}
