// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getLegalConfigUseCaseHash() =>
    r'646a26b2cac19c6b41db38af996db18facccf1f6';

/// See also [getLegalConfigUseCase].
@ProviderFor(getLegalConfigUseCase)
final getLegalConfigUseCaseProvider = Provider<GetLegalConfigUseCase>.internal(
  getLegalConfigUseCase,
  name: r'getLegalConfigUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$getLegalConfigUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetLegalConfigUseCaseRef = ProviderRef<GetLegalConfigUseCase>;
String _$checkLegalConsentUseCaseHash() =>
    r'512f2d5b58a5a39ca61f8e987eede4f44417d344';

/// See also [checkLegalConsentUseCase].
@ProviderFor(checkLegalConsentUseCase)
final checkLegalConsentUseCaseProvider =
    Provider<CheckLegalConsentUseCase>.internal(
  checkLegalConsentUseCase,
  name: r'checkLegalConsentUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$checkLegalConsentUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CheckLegalConsentUseCaseRef = ProviderRef<CheckLegalConsentUseCase>;
String _$signUpLegalConfigHash() => r'74b31770aec1919b51eaa11f4dd1e8e2225ed11a';

/// 新規登録画面に表示して、同意の送信に使う規約の情報。
/// 読めなかったとき（オフライン・読み取りの失敗）も既定値を使う（登録の後の判定で正しい版数に同意し直せるため）。
///
/// Copied from [signUpLegalConfig].
@ProviderFor(signUpLegalConfig)
final signUpLegalConfigProvider =
    AutoDisposeFutureProvider<LegalConfig>.internal(
  signUpLegalConfig,
  name: r'signUpLegalConfigProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$signUpLegalConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SignUpLegalConfigRef = AutoDisposeFutureProviderRef<LegalConfig>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
