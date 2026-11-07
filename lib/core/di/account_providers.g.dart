// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getIsDeveloperUseCase)
final getIsDeveloperUseCaseProvider = GetIsDeveloperUseCaseProvider._();

final class GetIsDeveloperUseCaseProvider
    extends
        $FunctionalProvider<
          GetIsDeveloperUseCase,
          GetIsDeveloperUseCase,
          GetIsDeveloperUseCase
        >
    with $Provider<GetIsDeveloperUseCase> {
  GetIsDeveloperUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getIsDeveloperUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getIsDeveloperUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetIsDeveloperUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetIsDeveloperUseCase create(Ref ref) {
    return getIsDeveloperUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetIsDeveloperUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetIsDeveloperUseCase>(value),
    );
  }
}

String _$getIsDeveloperUseCaseHash() =>
    r'52e598327d3a287b2e985540d2b76a65e5db5467';
