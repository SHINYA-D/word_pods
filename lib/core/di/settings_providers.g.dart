// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getSettingsUseCase)
final getSettingsUseCaseProvider = GetSettingsUseCaseProvider._();

final class GetSettingsUseCaseProvider
    extends
        $FunctionalProvider<
          GetSettingsUseCase,
          GetSettingsUseCase,
          GetSettingsUseCase
        >
    with $Provider<GetSettingsUseCase> {
  GetSettingsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getSettingsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getSettingsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetSettingsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetSettingsUseCase create(Ref ref) {
    return getSettingsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetSettingsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetSettingsUseCase>(value),
    );
  }
}

String _$getSettingsUseCaseHash() =>
    r'72c2e2e007b98991ed914e2c9b700d3ee02f515a';

@ProviderFor(updateSettingsUseCase)
final updateSettingsUseCaseProvider = UpdateSettingsUseCaseProvider._();

final class UpdateSettingsUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateSettingsUseCase,
          UpdateSettingsUseCase,
          UpdateSettingsUseCase
        >
    with $Provider<UpdateSettingsUseCase> {
  UpdateSettingsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateSettingsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateSettingsUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateSettingsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateSettingsUseCase create(Ref ref) {
    return updateSettingsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateSettingsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateSettingsUseCase>(value),
    );
  }
}

String _$updateSettingsUseCaseHash() =>
    r'77f444c82e7416103c21c74b378591c0d444b7cd';
