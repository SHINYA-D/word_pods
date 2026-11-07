// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_data_source_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(databaseHelper)
final databaseHelperProvider = DatabaseHelperProvider._();

final class DatabaseHelperProvider
    extends $FunctionalProvider<DatabaseHelper, DatabaseHelper, DatabaseHelper>
    with $Provider<DatabaseHelper> {
  DatabaseHelperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseHelperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHelperHash();

  @$internal
  @override
  $ProviderElement<DatabaseHelper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DatabaseHelper create(Ref ref) {
    return databaseHelper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatabaseHelper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatabaseHelper>(value),
    );
  }
}

String _$databaseHelperHash() => r'56231951807b413a0f538db07832460ed8f48d1d';

@ProviderFor(connectivityMonitor)
final connectivityMonitorProvider = ConnectivityMonitorProvider._();

final class ConnectivityMonitorProvider
    extends
        $FunctionalProvider<
          ConnectivityMonitor,
          ConnectivityMonitor,
          ConnectivityMonitor
        >
    with $Provider<ConnectivityMonitor> {
  ConnectivityMonitorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityMonitorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityMonitorHash();

  @$internal
  @override
  $ProviderElement<ConnectivityMonitor> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConnectivityMonitor create(Ref ref) {
    return connectivityMonitor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectivityMonitor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectivityMonitor>(value),
    );
  }
}

String _$connectivityMonitorHash() =>
    r'9ddfeb22b951e5557669cfe5bda111603fb70243';

@ProviderFor(syncQueueDataSource)
final syncQueueDataSourceProvider = SyncQueueDataSourceProvider._();

final class SyncQueueDataSourceProvider
    extends
        $FunctionalProvider<
          SyncQueueDataSource,
          SyncQueueDataSource,
          SyncQueueDataSource
        >
    with $Provider<SyncQueueDataSource> {
  SyncQueueDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncQueueDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncQueueDataSourceHash();

  @$internal
  @override
  $ProviderElement<SyncQueueDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncQueueDataSource create(Ref ref) {
    return syncQueueDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncQueueDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncQueueDataSource>(value),
    );
  }
}

String _$syncQueueDataSourceHash() =>
    r'4ea08607a67aa0755c6c0816abb1412efdfca58c';

@ProviderFor(folderLocalDataSource)
final folderLocalDataSourceProvider = FolderLocalDataSourceProvider._();

final class FolderLocalDataSourceProvider
    extends
        $FunctionalProvider<
          FolderLocalDataSource,
          FolderLocalDataSource,
          FolderLocalDataSource
        >
    with $Provider<FolderLocalDataSource> {
  FolderLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<FolderLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FolderLocalDataSource create(Ref ref) {
    return folderLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FolderLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FolderLocalDataSource>(value),
    );
  }
}

String _$folderLocalDataSourceHash() =>
    r'0da2a26d9bbdcec2dc1b3ca8b2fcd98323b76fde';

@ProviderFor(wordLocalDataSource)
final wordLocalDataSourceProvider = WordLocalDataSourceProvider._();

final class WordLocalDataSourceProvider
    extends
        $FunctionalProvider<
          WordLocalDataSource,
          WordLocalDataSource,
          WordLocalDataSource
        >
    with $Provider<WordLocalDataSource> {
  WordLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wordLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wordLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<WordLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WordLocalDataSource create(Ref ref) {
    return wordLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WordLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WordLocalDataSource>(value),
    );
  }
}

String _$wordLocalDataSourceHash() =>
    r'4a8911581545d0589ad7303aad433477825604b0';

@ProviderFor(flashcardResultLocalDataSource)
final flashcardResultLocalDataSourceProvider =
    FlashcardResultLocalDataSourceProvider._();

final class FlashcardResultLocalDataSourceProvider
    extends
        $FunctionalProvider<
          FlashcardResultLocalDataSource,
          FlashcardResultLocalDataSource,
          FlashcardResultLocalDataSource
        >
    with $Provider<FlashcardResultLocalDataSource> {
  FlashcardResultLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flashcardResultLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flashcardResultLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<FlashcardResultLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlashcardResultLocalDataSource create(Ref ref) {
    return flashcardResultLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlashcardResultLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlashcardResultLocalDataSource>(
        value,
      ),
    );
  }
}

String _$flashcardResultLocalDataSourceHash() =>
    r'f2ed1741549f7b2e7e9cc38ff072ad76e327a2d7';

@ProviderFor(settingsLocalDataSource)
final settingsLocalDataSourceProvider = SettingsLocalDataSourceProvider._();

final class SettingsLocalDataSourceProvider
    extends
        $FunctionalProvider<
          SettingsLocalDataSource,
          SettingsLocalDataSource,
          SettingsLocalDataSource
        >
    with $Provider<SettingsLocalDataSource> {
  SettingsLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<SettingsLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsLocalDataSource create(Ref ref) {
    return settingsLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsLocalDataSource>(value),
    );
  }
}

String _$settingsLocalDataSourceHash() =>
    r'995acde96095c83ea330a36423159e76d92d8020';

@ProviderFor(syncLocalDataSource)
final syncLocalDataSourceProvider = SyncLocalDataSourceProvider._();

final class SyncLocalDataSourceProvider
    extends
        $FunctionalProvider<
          SyncLocalDataSource,
          SyncLocalDataSource,
          SyncLocalDataSource
        >
    with $Provider<SyncLocalDataSource> {
  SyncLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<SyncLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncLocalDataSource create(Ref ref) {
    return syncLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncLocalDataSource>(value),
    );
  }
}

String _$syncLocalDataSourceHash() =>
    r'75673578fa781cf766cf70a95336ba3c049d720e';

@ProviderFor(accountDeletionLocalDataSource)
final accountDeletionLocalDataSourceProvider =
    AccountDeletionLocalDataSourceProvider._();

final class AccountDeletionLocalDataSourceProvider
    extends
        $FunctionalProvider<
          AccountDeletionLocalDataSource,
          AccountDeletionLocalDataSource,
          AccountDeletionLocalDataSource
        >
    with $Provider<AccountDeletionLocalDataSource> {
  AccountDeletionLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDeletionLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDeletionLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<AccountDeletionLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountDeletionLocalDataSource create(Ref ref) {
    return accountDeletionLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountDeletionLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountDeletionLocalDataSource>(
        value,
      ),
    );
  }
}

String _$accountDeletionLocalDataSourceHash() =>
    r'1ed13792c707fd8619884d463a819df799ecdd72';
