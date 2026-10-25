import 'package:freezed_annotation/freezed_annotation.dart';

part 'legal_consent.freezed.dart';

/// 現行の規約の情報（Firestore の `app_config/legal`）。版数は改定日（`YYYY-MM-DD`）。
@freezed
abstract class LegalConfig with _$LegalConfig {
  /// `app_config/legal` が無い（項目が欠けている）ときに使う既定値。
  /// 関数 `acceptLegal`（functions/src/accept_legal.ts）の既定値と同じ値にする。
  /// 規約を改定したら、`app_config/legal` と一緒に次のリリースで揃える。
  static const defaults = LegalConfig(
    termsVersion: '2026-10-12',
    privacyVersion: '2026-10-12',
    termsUrl: 'https://word-pods-web.web.app/terms',
    privacyUrl: 'https://word-pods-web.web.app/privacy',
  );

  const factory LegalConfig({
    required String termsVersion,
    required String privacyVersion,
    required String termsUrl,
    required String privacyUrl,
  }) = _LegalConfig;
}

/// 同意済みの版数（Firestore の `accounts/{uid}.consents`）。記録が無ければ null。
@freezed
abstract class LegalConsents with _$LegalConsents {
  const factory LegalConsents({
    String? termsVersion,
    String? privacyVersion,
  }) = _LegalConsents;
}

/// 同意が必要かの判定結果。
@freezed
abstract class LegalConsentRequirement with _$LegalConsentRequirement {
  const LegalConsentRequirement._();

  const factory LegalConsentRequirement({
    required bool termsRequired,
    required bool privacyRequired,

    /// 判定に使った現行の規約の情報（送信する版数と、閲覧画面の URL に使う）
    required LegalConfig config,
  }) = _LegalConsentRequirement;

  bool get isRequired => termsRequired || privacyRequired;
}

/// 同意の送信の結果。
enum LegalAcceptResult {
  /// 同意が記録された
  accepted,

  /// 送った版数が現行の版数と違ったため、記録されなかった
  outdated,
}
