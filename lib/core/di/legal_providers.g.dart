// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getLegalConfigUseCase)
final getLegalConfigUseCaseProvider = GetLegalConfigUseCaseProvider._();

final class GetLegalConfigUseCaseProvider
    extends
        $FunctionalProvider<
          GetLegalConfigUseCase,
          GetLegalConfigUseCase,
          GetLegalConfigUseCase
        >
    with $Provider<GetLegalConfigUseCase> {
  GetLegalConfigUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getLegalConfigUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getLegalConfigUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetLegalConfigUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetLegalConfigUseCase create(Ref ref) {
    return getLegalConfigUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetLegalConfigUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetLegalConfigUseCase>(value),
    );
  }
}

String _$getLegalConfigUseCaseHash() =>
    r'646a26b2cac19c6b41db38af996db18facccf1f6';

@ProviderFor(checkLegalConsentUseCase)
final checkLegalConsentUseCaseProvider = CheckLegalConsentUseCaseProvider._();

final class CheckLegalConsentUseCaseProvider
    extends
        $FunctionalProvider<
          CheckLegalConsentUseCase,
          CheckLegalConsentUseCase,
          CheckLegalConsentUseCase
        >
    with $Provider<CheckLegalConsentUseCase> {
  CheckLegalConsentUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkLegalConsentUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkLegalConsentUseCaseHash();

  @$internal
  @override
  $ProviderElement<CheckLegalConsentUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckLegalConsentUseCase create(Ref ref) {
    return checkLegalConsentUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckLegalConsentUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckLegalConsentUseCase>(value),
    );
  }
}

String _$checkLegalConsentUseCaseHash() =>
    r'512f2d5b58a5a39ca61f8e987eede4f44417d344';

/// 新規登録画面に表示して、同意の送信に使う規約の情報。
/// 読めなかったとき（オフライン・読み取りの失敗）も既定値を使う（登録の後の判定で正しい版数に同意し直せるため）。

@ProviderFor(signUpLegalConfig)
final signUpLegalConfigProvider = SignUpLegalConfigProvider._();

/// 新規登録画面に表示して、同意の送信に使う規約の情報。
/// 読めなかったとき（オフライン・読み取りの失敗）も既定値を使う（登録の後の判定で正しい版数に同意し直せるため）。

final class SignUpLegalConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<LegalConfig>,
          LegalConfig,
          FutureOr<LegalConfig>
        >
    with $FutureModifier<LegalConfig>, $FutureProvider<LegalConfig> {
  /// 新規登録画面に表示して、同意の送信に使う規約の情報。
  /// 読めなかったとき（オフライン・読み取りの失敗）も既定値を使う（登録の後の判定で正しい版数に同意し直せるため）。
  SignUpLegalConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpLegalConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpLegalConfigHash();

  @$internal
  @override
  $FutureProviderElement<LegalConfig> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LegalConfig> create(Ref ref) {
    return signUpLegalConfig(ref);
  }
}

String _$signUpLegalConfigHash() => r'74b31770aec1919b51eaa11f4dd1e8e2225ed11a';
