import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:word_stock/domain/entities/legal_consent.dart';

part 'legal_consent_state.freezed.dart';

enum LegalConsentPhase {
  /// 待機（ダイアログなし）
  idle,

  /// 同意が必要かを判定している
  checking,

  /// 同意ダイアログを表示している
  required,

  /// 同意を送信している
  sending,

  /// 同意ダイアログの「ログアウト」でログアウトしている
  signingOut,

  /// 「通信エラー」ダイアログを表示している（OK でログアウトする）
  networkError,
}

/// 同意ダイアログに表示する文言。次に「同意する」か「ログアウト」を押すまで残す。
enum LegalConsentMessage {
  /// 「同意を送信できませんでした。もう一度お試しください。」
  sendFailed,

  /// 「内容が更新されました。もう一度ご確認のうえ、同意してください。」
  outdated,

  /// 「ログアウトできませんでした。もう一度お試しください。」
  signOutFailed,
}

@freezed
abstract class LegalConsentState with _$LegalConsentState {
  const LegalConsentState._();

  const factory LegalConsentState({
    @Default(LegalConsentPhase.idle) LegalConsentPhase phase,

    /// その文書の行を表示するか
    @Default(false) bool termsRequired,
    @Default(false) bool privacyRequired,

    /// その文書のチェックボックスがチェックされているか
    @Default(false) bool termsChecked,
    @Default(false) bool privacyChecked,

    /// 判定に使った現行の規約の情報（送信する版数と閲覧画面の URL）
    LegalConfig? config,
    LegalConsentMessage? message,
  }) = _LegalConsentState;

  /// 表示しているチェックボックスがすべてチェックされているか
  bool get allChecked =>
      (!termsRequired || termsChecked) && (!privacyRequired || privacyChecked);
}
