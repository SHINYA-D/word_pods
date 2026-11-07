// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(syncService)
final syncServiceProvider = SyncServiceProvider._();

final class SyncServiceProvider
    extends $FunctionalProvider<SyncService, SyncService, SyncService>
    with $Provider<SyncService> {
  SyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncServiceHash();

  @$internal
  @override
  $ProviderElement<SyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncService create(Ref ref) {
    return syncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncService>(value),
    );
  }
}

String _$syncServiceHash() => r'aa39a9c997fda18ea8b9321efda87e7a9d64b038';

@ProviderFor(syncRepository)
final syncRepositoryProvider = SyncRepositoryProvider._();

final class SyncRepositoryProvider
    extends $FunctionalProvider<SyncRepository, SyncRepository, SyncRepository>
    with $Provider<SyncRepository> {
  SyncRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncRepositoryHash();

  @$internal
  @override
  $ProviderElement<SyncRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncRepository create(Ref ref) {
    return syncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncRepository>(value),
    );
  }
}

String _$syncRepositoryHash() => r'21d1fb9e5177b8939e56e079e9f6aa6ac002572d';

@ProviderFor(autoSyncService)
final autoSyncServiceProvider = AutoSyncServiceProvider._();

final class AutoSyncServiceProvider
    extends
        $FunctionalProvider<AutoSyncService, AutoSyncService, AutoSyncService>
    with $Provider<AutoSyncService> {
  AutoSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoSyncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoSyncServiceHash();

  @$internal
  @override
  $ProviderElement<AutoSyncService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AutoSyncService create(Ref ref) {
    return autoSyncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoSyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoSyncService>(value),
    );
  }
}

String _$autoSyncServiceHash() => r'33ea95fd36e5920e55e4bf8b07758dc5f695272c';
