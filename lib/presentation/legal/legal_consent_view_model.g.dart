// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_consent_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 利用規約・プライバシーポリシーへの同意。
///
/// ログインしたとき・起動時・復帰時・オンラインに戻ったときに同意が必要かを判定し、必要なら同意ダイアログを出す状態にする。
/// ログイン直後は、ログインの処理（新規登録では同意の送信を含む）と初回の同期が終わってから判定する。
/// 退会関係のダイアログ（再開・他の端末での退会）を優先し、それらの間は判定しない。
/// ログアウト・他の端末での退会で待機に戻したら、それより前に始めた処理の結果は捨てる（[_generation]）。

@ProviderFor(LegalConsentViewModel)
final legalConsentViewModelProvider = LegalConsentViewModelProvider._();

/// 利用規約・プライバシーポリシーへの同意。
///
/// ログインしたとき・起動時・復帰時・オンラインに戻ったときに同意が必要かを判定し、必要なら同意ダイアログを出す状態にする。
/// ログイン直後は、ログインの処理（新規登録では同意の送信を含む）と初回の同期が終わってから判定する。
/// 退会関係のダイアログ（再開・他の端末での退会）を優先し、それらの間は判定しない。
/// ログアウト・他の端末での退会で待機に戻したら、それより前に始めた処理の結果は捨てる（[_generation]）。
final class LegalConsentViewModelProvider
    extends $NotifierProvider<LegalConsentViewModel, LegalConsentState> {
  /// 利用規約・プライバシーポリシーへの同意。
  ///
  /// ログインしたとき・起動時・復帰時・オンラインに戻ったときに同意が必要かを判定し、必要なら同意ダイアログを出す状態にする。
  /// ログイン直後は、ログインの処理（新規登録では同意の送信を含む）と初回の同期が終わってから判定する。
  /// 退会関係のダイアログ（再開・他の端末での退会）を優先し、それらの間は判定しない。
  /// ログアウト・他の端末での退会で待機に戻したら、それより前に始めた処理の結果は捨てる（[_generation]）。
  LegalConsentViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'legalConsentViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$legalConsentViewModelHash();

  @$internal
  @override
  LegalConsentViewModel create() => LegalConsentViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LegalConsentState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LegalConsentState>(value),
    );
  }
}

String _$legalConsentViewModelHash() =>
    r'4a264c1cd523be50ceab19e78d9e93599b851609';

/// 利用規約・プライバシーポリシーへの同意。
///
/// ログインしたとき・起動時・復帰時・オンラインに戻ったときに同意が必要かを判定し、必要なら同意ダイアログを出す状態にする。
/// ログイン直後は、ログインの処理（新規登録では同意の送信を含む）と初回の同期が終わってから判定する。
/// 退会関係のダイアログ（再開・他の端末での退会）を優先し、それらの間は判定しない。
/// ログアウト・他の端末での退会で待機に戻したら、それより前に始めた処理の結果は捨てる（[_generation]）。

abstract class _$LegalConsentViewModel extends $Notifier<LegalConsentState> {
  LegalConsentState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LegalConsentState, LegalConsentState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LegalConsentState, LegalConsentState>,
              LegalConsentState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
