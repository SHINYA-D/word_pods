import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    required bool isLoading,
    required bool isSuccess,
    String? errorMessage,

    /// 新規登録で、確認メールの送信に成功したか（送信完了ダイアログの文言を切り替える）
    @Default(false) bool verificationEmailSent,
  }) = _AuthState;

  factory AuthState.initial() => const AuthState(
        isLoading: false,
        isSuccess: false,
      );
}
