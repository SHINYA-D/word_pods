import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/application/use_cases/auth/delete_account_use_case.dart';
import 'package:word_pods/application/use_cases/auth/reauthenticate_use_case.dart';
import 'package:word_pods/application/use_cases/auth/reload_user_use_case.dart';
import 'package:word_pods/application/use_cases/auth/reset_password_use_case.dart';
import 'package:word_pods/application/use_cases/auth/send_email_verification_use_case.dart';
import 'package:word_pods/application/use_cases/auth/sign_in_with_email_use_case.dart';
import 'package:word_pods/application/use_cases/auth/sign_in_with_google_use_case.dart';
import 'package:word_pods/application/use_cases/auth/sign_out_use_case.dart';
import 'package:word_pods/application/use_cases/auth/sign_up_use_case.dart';
import 'package:word_pods/application/use_cases/auth/withdrawn_elsewhere_use_case.dart';
import 'package:word_pods/core/di/repository_providers.dart';
import 'package:word_pods/core/di/sync_providers.dart';
import 'package:word_pods/domain/entities/app_user.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<AppUser?> authState(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges;

@Riverpod(keepAlive: true)
AppUser? currentUser(Ref ref) => ref.watch(authStateProvider).value;

@Riverpod(keepAlive: true)
SignInWithEmailUseCase signInWithEmailUseCase(Ref ref) =>
    SignInWithEmailUseCase(
      ref.watch(authRepositoryProvider),
      ref.watch(syncRepositoryProvider),
    );

@Riverpod(keepAlive: true)
SignUpUseCase signUpUseCase(Ref ref) => SignUpUseCase(
      ref.watch(authRepositoryProvider),
      ref.watch(syncRepositoryProvider),
      ref.watch(legalRepositoryProvider),
    );

@Riverpod(keepAlive: true)
SignInWithGoogleUseCase signInWithGoogleUseCase(Ref ref) =>
    SignInWithGoogleUseCase(
      ref.watch(authRepositoryProvider),
      ref.watch(syncRepositoryProvider),
    );

@Riverpod(keepAlive: true)
SignOutUseCase signOutUseCase(Ref ref) =>
    SignOutUseCase(
      ref.watch(authRepositoryProvider),
      ref.watch(syncRepositoryProvider),
    );

@Riverpod(keepAlive: true)
ResetPasswordUseCase resetPasswordUseCase(Ref ref) =>
    ResetPasswordUseCase(ref.watch(authRepositoryProvider));

@Riverpod(keepAlive: true)
DeleteAccountUseCase deleteAccountUseCase(Ref ref) => DeleteAccountUseCase(
      ref.watch(accountDeletionRepositoryProvider),
      ref.watch(authRepositoryProvider),
      ref.watch(syncRepositoryProvider),
    );

@Riverpod(keepAlive: true)
ReauthenticateUseCase reauthenticateUseCase(Ref ref) =>
    ReauthenticateUseCase(ref.watch(reauthenticationRepositoryProvider));

@Riverpod(keepAlive: true)
ReloadUserUseCase reloadUserUseCase(Ref ref) =>
    ReloadUserUseCase(ref.watch(emailVerificationRepositoryProvider));

@Riverpod(keepAlive: true)
SendEmailVerificationUseCase sendEmailVerificationUseCase(Ref ref) =>
    SendEmailVerificationUseCase(ref.watch(emailVerificationRepositoryProvider));

/// 今の時刻。テストで時刻を固定できるよう Provider 経由で読む
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;

/// 最後に確認メールの送信に成功したユーザーと時刻（アプリの起動中だけ覚える）。
/// 再送ボタンの60秒の待ち時間を、新規登録のときの送信からも数えるため、画面をまたいで持つ。
/// 別のアカウントに切り替えたら、そのアカウントの待ち時間は無い（ユーザーごとに数える）
@Riverpod(keepAlive: true)
class VerificationEmailSentAt extends _$VerificationEmailSentAt {
  @override
  ({String userId, DateTime at})? build() => null;

  void record({required String userId, required DateTime at}) =>
      state = (userId: userId, at: at);
}

@Riverpod(keepAlive: true)
WithdrawnElsewhereUseCase withdrawnElsewhereUseCase(Ref ref) =>
    WithdrawnElsewhereUseCase(
      ref.watch(accountDeletionRepositoryProvider),
      ref.watch(authRepositoryProvider),
      ref.watch(syncRepositoryProvider),
    );
