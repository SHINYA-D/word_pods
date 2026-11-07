import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/presentation/auth/auth_state.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/core/di/sync_status_providers.dart';

part 'sign_up_view_model.g.dart';

@riverpod
class SignUpViewModel extends _$SignUpViewModel {
  @override
  AuthState build() => AuthState.initial();

  /// [termsVersion] / [privacyVersion] は、新規登録画面に表示して同意してもらった版数。
  ///
  /// アカウントを作れたら確認メールを送る。成功したら、送信完了ダイアログを閉じる（[closeVerificationDialog]）まで
  /// 画面の移動を止めたままにする（ダイアログの表示中に確認済みになっても、新規登録画面に置くため）。
  /// 仕様: docs/detailed_design/email_verification/email_verification.md 4.1
  Future<void> signUp({
    required String email,
    required String password,
    required String termsVersion,
    required String privacyVersion,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, isSuccess: false, errorMessage: null);
    ref.read(authSyncInProgressProvider.notifier).state = true;
    final result = await ref
        .read(signUpUseCaseProvider)
        .call(
          email: email,
          password: password,
          termsVersion: termsVersion,
          privacyVersion: privacyVersion,
        );
    if (result.isLeft()) {
      ref.read(authSyncInProgressProvider.notifier).state = false;
    }
    await result.fold(
      (failure) async => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.when(
          network: () => '通信エラーが発生しました',
          auth: () => 'このメールアドレスはすでに使用されています',
          notFound: () => 'エラーが発生しました',
          unknown: (msg) => 'エラーが発生しました: $msg',
          recentLoginRequired: () => 'エラーが発生しました',
          tooManyRequests: () => 'エラーが発生しました',
        ),
      ),
      (user) async {
        // 送信に失敗しても登録は成功として扱う（確認待ち画面の「確認メールを再送」で送り直せる）
        final sent = await ref.read(sendEmailVerificationUseCaseProvider).call();
        if (sent.isRight()) {
          ref
              .read(verificationEmailSentAtProvider.notifier)
              .record(userId: user.id, at: ref.read(clockProvider)());
        }
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          verificationEmailSent: sent.isRight(),
        );
      },
    );
  }

  /// 送信完了ダイアログを閉じた。確認状態を取り直してから、画面の移動の停止を解く
  /// （確認済みならホーム画面、未確認なら確認待ち画面へ移る）。取り直しの失敗は伝えない
  /// （確認待ち画面の表示時に、もう一度問い合わせるため）。
  Future<void> closeVerificationDialog() async {
    // 問い合わせの間は「アカウント作成」を押せないようにする
    state = state.copyWith(isLoading: true);
    await ref.read(reloadUserUseCaseProvider).call();
    ref.read(authSyncInProgressProvider.notifier).state = false;
    if (ref.mounted) state = state.copyWith(isLoading: false);
  }

  void resetState() => state = AuthState.initial();
}
