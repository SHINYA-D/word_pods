import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/core/error/failure.dart';

part 'verify_email_view_model.freezed.dart';
part 'verify_email_view_model.g.dart';

/// 確認待ち画面でスナックバーに出すメッセージ
enum VerifyEmailMessage {
  /// 「確認しました」を押したが、まだ確認されていない
  notVerified,

  /// 確認メールを再送した
  resent,

  /// 通信エラー（ログアウトはしない）
  network,

  /// 短時間に何度も送信した
  tooManyRequests,

  /// そのほかのエラー
  unknown,

  /// ログアウトに失敗した
  signOutFailed,
}

@freezed
abstract class VerifyEmailState with _$VerifyEmailState {
  const factory VerifyEmailState({
    /// 「確認しました」の問い合わせ中
    @Default(false) bool isChecking,

    /// 確認メールの再送中
    @Default(false) bool isResending,

    /// 「ログイン画面へ」のログアウト中
    @Default(false) bool isSigningOut,

    /// スナックバーに出すメッセージ。画面が表示したら [VerifyEmailViewModel.clearMessage] で消す
    VerifyEmailMessage? message,
  }) = _VerifyEmailState;
}

/// 確認待ち画面。確認済みになったときの画面の移動はルーター（`authRedirect`）が行う。
/// 仕様: docs/detailed_design/email_verification/email_verification.md 4.2
@riverpod
class VerifyEmailViewModel extends _$VerifyEmailViewModel {
  /// 確認メールの送信に成功してから、再送できるようになるまでの時間
  static const resendCooldown = Duration(seconds: 60);

  bool _autoChecking = false;

  @override
  VerifyEmailState build() => const VerifyEmailState();

  bool get _isBusy => state.isChecking || state.isResending || state.isSigningOut;

  /// 画面の表示時・アプリが前面に戻ったときの確認。未確認・失敗でも何も表示しない。
  /// アカウントが無い・無効・ログイン情報の期限切れ（[AuthFailure]）ならログアウトする
  Future<void> checkAutomatically() async {
    if (_autoChecking || _isBusy) return;
    _autoChecking = true;
    final result = await ref.read(reloadUserUseCaseProvider).call();
    _autoChecking = false;
    if (!ref.mounted) return;
    if (_isAuthFailure(result)) await _signOutSilently();
  }

  /// 「確認しました」
  Future<void> confirm() async {
    if (_isBusy) return;
    state = state.copyWith(isChecking: true, message: null);
    final result = await ref.read(reloadUserUseCaseProvider).call();
    if (!ref.mounted) return;
    if (_isAuthFailure(result)) {
      state = state.copyWith(isChecking: false);
      return _signOutSilently();
    }
    state = state.copyWith(
      isChecking: false,
      message: result.fold(
        _messageOf,
        (user) => user.emailVerified ? null : VerifyEmailMessage.notVerified,
      ),
    );
  }

  /// 「確認メールを再送」。送信に成功してから [resendCooldown] の間は送らない
  Future<void> resend() async {
    if (_isBusy || resendCooldownSeconds() > 0) return;
    state = state.copyWith(isResending: true, message: null);
    final result = await ref.read(sendEmailVerificationUseCaseProvider).call();
    if (!ref.mounted) return;
    if (_isAuthFailure(result)) {
      state = state.copyWith(isResending: false);
      return _signOutSilently();
    }
    final userId = ref.read(currentUserProvider)?.id;
    if (result.isRight() && userId != null) {
      ref
          .read(verificationEmailSentAtProvider.notifier)
          .record(userId: userId, at: ref.read(clockProvider)());
    }
    state = state.copyWith(
      isResending: false,
      message: result.fold(_messageOf, (_) => VerifyEmailMessage.resent),
    );
  }

  /// 「ログイン画面へ」。ログアウトするとルーターがログイン画面へ移す
  Future<void> signOut() async {
    if (_isBusy) return;
    state = state.copyWith(isSigningOut: true, message: null);
    final result = await ref.read(signOutUseCaseProvider).call();
    if (!ref.mounted) return;
    state = state.copyWith(
      isSigningOut: false,
      message: result.isLeft() ? VerifyEmailMessage.signOutFailed : null,
    );
  }

  /// 再送できるようになるまでの残り秒数（切り上げ）。再送できるなら 0。
  /// ログイン中のユーザーが送信に成功した時刻から数える（別のユーザーの送信は数えない）
  int resendCooldownSeconds() {
    final sent = ref.read(verificationEmailSentAtProvider);
    if (sent == null || sent.userId != ref.read(currentUserProvider)?.id) return 0;
    final remaining = resendCooldown - ref.read(clockProvider)().difference(sent.at);
    if (remaining <= Duration.zero) return 0;
    return (remaining.inMilliseconds / 1000).ceil();
  }

  void clearMessage() => state = state.copyWith(message: null);

  /// アカウントが無い・無効・ログイン情報の期限切れのときのログアウト。失敗したときだけ伝える
  Future<void> _signOutSilently() async {
    final result = await ref.read(signOutUseCaseProvider).call();
    if (!ref.mounted || result.isRight()) return;
    state = state.copyWith(message: VerifyEmailMessage.signOutFailed);
  }

  static bool _isAuthFailure<T>(Either<Failure, T> result) =>
      result.fold((failure) => failure is AuthFailure, (_) => false);

  static VerifyEmailMessage _messageOf(Failure failure) => switch (failure) {
        NetworkFailure() => VerifyEmailMessage.network,
        TooManyRequestsFailure() => VerifyEmailMessage.tooManyRequests,
        _ => VerifyEmailMessage.unknown,
      };
}
