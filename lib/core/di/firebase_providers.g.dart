// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firebaseAuth)
final firebaseAuthProvider = FirebaseAuthProvider._();

final class FirebaseAuthProvider
    extends $FunctionalProvider<FirebaseAuth, FirebaseAuth, FirebaseAuth>
    with $Provider<FirebaseAuth> {
  FirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuth> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'8c3e9d11b27110ca96130356b5ef4d5d34a5ffc2';

/// オフライン対応は SQLite と同期キューで自前で行うため、Firestore SDK のオフライン機能は使わない

@ProviderFor(firestore)
final firestoreProvider = FirestoreProvider._();

/// オフライン対応は SQLite と同期キューで自前で行うため、Firestore SDK のオフライン機能は使わない

final class FirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  /// オフライン対応は SQLite と同期キューで自前で行うため、Firestore SDK のオフライン機能は使わない
  FirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firestoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firestoreHash() => r'05d3b5fdb13af2444bcafa7fdfd877eed780dc2d';

/// 関数は東京リージョンに置く（functions/src/index.ts の region と合わせる）

@ProviderFor(firebaseFunctions)
final firebaseFunctionsProvider = FirebaseFunctionsProvider._();

/// 関数は東京リージョンに置く（functions/src/index.ts の region と合わせる）

final class FirebaseFunctionsProvider
    extends
        $FunctionalProvider<
          FirebaseFunctions,
          FirebaseFunctions,
          FirebaseFunctions
        >
    with $Provider<FirebaseFunctions> {
  /// 関数は東京リージョンに置く（functions/src/index.ts の region と合わせる）
  FirebaseFunctionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseFunctionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseFunctionsHash();

  @$internal
  @override
  $ProviderElement<FirebaseFunctions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFunctions create(Ref ref) {
    return firebaseFunctions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFunctions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFunctions>(value),
    );
  }
}

String _$firebaseFunctionsHash() => r'097fd9df60c1e156f273cabdfd9196deb30b9f18';

@ProviderFor(googleSignIn)
final googleSignInProvider = GoogleSignInProvider._();

final class GoogleSignInProvider
    extends $FunctionalProvider<GoogleSignIn, GoogleSignIn, GoogleSignIn>
    with $Provider<GoogleSignIn> {
  GoogleSignInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'googleSignInProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$googleSignInHash();

  @$internal
  @override
  $ProviderElement<GoogleSignIn> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoogleSignIn create(Ref ref) {
    return googleSignIn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoogleSignIn value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoogleSignIn>(value),
    );
  }
}

String _$googleSignInHash() => r'4df13ef226b172967e2ad6fef31c4648f6d52fd9';

@ProviderFor(firebaseAuthDataSource)
final firebaseAuthDataSourceProvider = FirebaseAuthDataSourceProvider._();

final class FirebaseAuthDataSourceProvider
    extends
        $FunctionalProvider<
          FirebaseAuthDataSource,
          FirebaseAuthDataSource,
          FirebaseAuthDataSource
        >
    with $Provider<FirebaseAuthDataSource> {
  FirebaseAuthDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthDataSourceHash();

  @$internal
  @override
  $ProviderElement<FirebaseAuthDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseAuthDataSource create(Ref ref) {
    return firebaseAuthDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseAuthDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseAuthDataSource>(value),
    );
  }
}

String _$firebaseAuthDataSourceHash() =>
    r'330ac279dce4b510044c395b703781d678c2e7ce';

@ProviderFor(reauthenticationRemoteDataSource)
final reauthenticationRemoteDataSourceProvider =
    ReauthenticationRemoteDataSourceProvider._();

final class ReauthenticationRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ReauthenticationRemoteDataSource,
          ReauthenticationRemoteDataSource,
          ReauthenticationRemoteDataSource
        >
    with $Provider<ReauthenticationRemoteDataSource> {
  ReauthenticationRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reauthenticationRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reauthenticationRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ReauthenticationRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReauthenticationRemoteDataSource create(Ref ref) {
    return reauthenticationRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReauthenticationRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReauthenticationRemoteDataSource>(
        value,
      ),
    );
  }
}

String _$reauthenticationRemoteDataSourceHash() =>
    r'54f4a4146aae3dc55ee998681486224f9cc3b649';

@ProviderFor(firestoreDataSource)
final firestoreDataSourceProvider = FirestoreDataSourceProvider._();

final class FirestoreDataSourceProvider
    extends
        $FunctionalProvider<
          FirestoreDataSource,
          FirestoreDataSource,
          FirestoreDataSource
        >
    with $Provider<FirestoreDataSource> {
  FirestoreDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firestoreDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firestoreDataSourceHash();

  @$internal
  @override
  $ProviderElement<FirestoreDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirestoreDataSource create(Ref ref) {
    return firestoreDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirestoreDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirestoreDataSource>(value),
    );
  }
}

String _$firestoreDataSourceHash() =>
    r'57054aa72f7849231d78faeed8dd8510effb0a2a';

@ProviderFor(syncRemoteDataSource)
final syncRemoteDataSourceProvider = SyncRemoteDataSourceProvider._();

final class SyncRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          SyncRemoteDataSource,
          SyncRemoteDataSource,
          SyncRemoteDataSource
        >
    with $Provider<SyncRemoteDataSource> {
  SyncRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<SyncRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncRemoteDataSource create(Ref ref) {
    return syncRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncRemoteDataSource>(value),
    );
  }
}

String _$syncRemoteDataSourceHash() =>
    r'0b83e0322ea8a6d5b0843004ed41ba90b3b04b8e';

@ProviderFor(accountDeletionRemoteDataSource)
final accountDeletionRemoteDataSourceProvider =
    AccountDeletionRemoteDataSourceProvider._();

final class AccountDeletionRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          AccountDeletionRemoteDataSource,
          AccountDeletionRemoteDataSource,
          AccountDeletionRemoteDataSource
        >
    with $Provider<AccountDeletionRemoteDataSource> {
  AccountDeletionRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDeletionRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDeletionRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<AccountDeletionRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountDeletionRemoteDataSource create(Ref ref) {
    return accountDeletionRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountDeletionRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountDeletionRemoteDataSource>(
        value,
      ),
    );
  }
}

String _$accountDeletionRemoteDataSourceHash() =>
    r'0cb314246810c2b73e1cae322e34bfac55536588';

@ProviderFor(accountRemoteDataSource)
final accountRemoteDataSourceProvider = AccountRemoteDataSourceProvider._();

final class AccountRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          AccountRemoteDataSource,
          AccountRemoteDataSource,
          AccountRemoteDataSource
        >
    with $Provider<AccountRemoteDataSource> {
  AccountRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<AccountRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountRemoteDataSource create(Ref ref) {
    return accountRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountRemoteDataSource>(value),
    );
  }
}

String _$accountRemoteDataSourceHash() =>
    r'64c7b5954f3d119d97eb2c01744366c4357ef5f3';

@ProviderFor(withdrawnAccountRemoteDataSource)
final withdrawnAccountRemoteDataSourceProvider =
    WithdrawnAccountRemoteDataSourceProvider._();

final class WithdrawnAccountRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          WithdrawnAccountRemoteDataSource,
          WithdrawnAccountRemoteDataSource,
          WithdrawnAccountRemoteDataSource
        >
    with $Provider<WithdrawnAccountRemoteDataSource> {
  WithdrawnAccountRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawnAccountRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawnAccountRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<WithdrawnAccountRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WithdrawnAccountRemoteDataSource create(Ref ref) {
    return withdrawnAccountRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WithdrawnAccountRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WithdrawnAccountRemoteDataSource>(
        value,
      ),
    );
  }
}

String _$withdrawnAccountRemoteDataSourceHash() =>
    r'5164a874de6cb297abaeb63792365f2fd608b162';

@ProviderFor(legalRemoteDataSource)
final legalRemoteDataSourceProvider = LegalRemoteDataSourceProvider._();

final class LegalRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          LegalRemoteDataSource,
          LegalRemoteDataSource,
          LegalRemoteDataSource
        >
    with $Provider<LegalRemoteDataSource> {
  LegalRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'legalRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$legalRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<LegalRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LegalRemoteDataSource create(Ref ref) {
    return legalRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LegalRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LegalRemoteDataSource>(value),
    );
  }
}

String _$legalRemoteDataSourceHash() =>
    r'bad7785153d98d26c1b033ee6c0ca44afbfea491';
