import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/application/use_cases/auth/delete_account_use_case.dart';
import 'package:word_pods/application/use_cases/auth/reauthenticate_use_case.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/presentation/settings/account_deletion_state.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_state.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_view_model.dart';

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

  /// 確認ダイアログ2回のあとの退会処理。最初に本人確認をし直す
  /// （[password] があればパスワードで、無ければ Google で）。
  Future<void> withdraw({String? password}) async {
    if (state.phase != AccountDeletionPhase.idle) return;
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    state = const AccountDeletionState(phase: AccountDeletionPhase.processing);
    final reauth =
        await ref.read(reauthenticateUseCaseProvider).call(password: password);
    // 本人確認の間に他の端末での退会が見つかった（お知らせ以降のダイアログを表示中、または
    // ログアウトしてログイン中のユーザーが変わった）なら、お知らせを優先し、結果に関わらず何もしない
    if (_withdrawnElsewhereShown() ||
        ref.read(currentUserProvider)?.id != userId) {
      state = const AccountDeletionState(phase: AccountDeletionPhase.idle);
      return;
    }
    switch (reauth) {
      case ReauthenticationOutcome.succeeded:
        break;
      case ReauthenticationOutcome.cancelled:
        state = const AccountDeletionState(phase: AccountDeletionPhase.idle);
        return;
      case ReauthenticationOutcome.rejected:
        state = const AccountDeletionState(
            phase: AccountDeletionPhase.reauthRejected);
        return;
      case ReauthenticationOutcome.tooManyAttempts:
        state = const AccountDeletionState(
          phase: AccountDeletionPhase.reauthRejected,
          tooManyAttempts: true,
        );
        return;
      case ReauthenticationOutcome.failed:
        state = const AccountDeletionState(phase: AccountDeletionPhase.notSent);
        return;
    }
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

  /// 再開ダイアログで、本人確認をし直してから「再試行」する。
  Future<void> retryWithReauth({String? password}) async {
    if (state.phase != AccountDeletionPhase.reauthRequired) return;
    state = const AccountDeletionState(
      phase: AccountDeletionPhase.processing,
      isRetry: true,
    );
    final reauth =
        await ref.read(reauthenticateUseCaseProvider).call(password: password);
    switch (reauth) {
      case ReauthenticationOutcome.succeeded:
        break;
      case ReauthenticationOutcome.cancelled:
        state = const AccountDeletionState(
            phase: AccountDeletionPhase.reauthRequired);
        return;
      case ReauthenticationOutcome.rejected:
        state = const AccountDeletionState(
          phase: AccountDeletionPhase.reauthRequired,
          reauthRejected: true,
        );
        return;
      case ReauthenticationOutcome.tooManyAttempts:
        state = const AccountDeletionState(
          phase: AccountDeletionPhase.reauthRequired,
          tooManyAttempts: true,
        );
        return;
      case ReauthenticationOutcome.failed:
        state = const AccountDeletionState(
          phase: AccountDeletionPhase.reauthRequired,
          retryFailed: true,
        );
        return;
    }
    final outcome = await ref
        .read(deleteAccountUseCaseProvider)
        .resume(ref.read(currentUserProvider)?.id);
    state = AccountDeletionState(
      phase: _phaseOf(outcome),
      retryFailed: outcome == AccountDeletionOutcome.pending,
    );
  }

  /// 「本人確認できませんでした」ダイアログを閉じた。
  void acknowledgeReauthRejected() {
    if (state.phase != AccountDeletionPhase.reauthRejected) return;
    state = const AccountDeletionState(phase: AccountDeletionPhase.idle);
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

  bool _withdrawnElsewhereShown() {
    final phase = ref.read(withdrawnElsewhereViewModelProvider).phase;
    return phase != WithdrawnElsewherePhase.idle &&
        phase != WithdrawnElsewherePhase.checking;
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
      case AccountDeletionOutcome.reauthRequired:
        return AccountDeletionPhase.reauthRequired;
    }
  }
}
