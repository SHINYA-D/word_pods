// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_consent_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$legalConsentViewModelHash() =>
    r'c13c8dba84fcdf9c8efea80aabe883c9db16b41b';

/// 利用規約・プライバシーポリシーへの同意。
///
/// ログインしたとき・起動時・復帰時・オンラインに戻ったときに同意が必要かを判定し、必要なら同意ダイアログを出す状態にする。
/// ログイン直後は、ログインの処理（新規登録では同意の送信を含む）と初回の同期が終わってから判定する。
/// 退会関係のダイアログ（再開・他の端末での退会）を優先し、それらの間は判定しない。
/// ログアウト・他の端末での退会で待機に戻したら、それより前に始めた処理の結果は捨てる（[_generation]）。
///
/// Copied from [LegalConsentViewModel].
@ProviderFor(LegalConsentViewModel)
final legalConsentViewModelProvider =
    NotifierProvider<LegalConsentViewModel, LegalConsentState>.internal(
  LegalConsentViewModel.new,
  name: r'legalConsentViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$legalConsentViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LegalConsentViewModel = Notifier<LegalConsentState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
