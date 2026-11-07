// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, Stream<AppUser?>>
    with $FutureModifier<AppUser?>, $StreamProvider<AppUser?> {
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AppUser?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'322d1d24acdb2986167edc960917365000e0d820';

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

final class CurrentUserProvider
    extends $FunctionalProvider<AppUser?, AppUser?, AppUser?>
    with $Provider<AppUser?> {
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppUser? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUser? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUser?>(value),
    );
  }
}

String _$currentUserHash() => r'e847c442bf06dd95e98daa78092b57243a8221cd';

@ProviderFor(signInWithEmailUseCase)
final signInWithEmailUseCaseProvider = SignInWithEmailUseCaseProvider._();

final class SignInWithEmailUseCaseProvider
    extends
        $FunctionalProvider<
          SignInWithEmailUseCase,
          SignInWithEmailUseCase,
          SignInWithEmailUseCase
        >
    with $Provider<SignInWithEmailUseCase> {
  SignInWithEmailUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInWithEmailUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInWithEmailUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignInWithEmailUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SignInWithEmailUseCase create(Ref ref) {
    return signInWithEmailUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInWithEmailUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInWithEmailUseCase>(value),
    );
  }
}

String _$signInWithEmailUseCaseHash() =>
    r'933efedbe31aaf0ba5a07953250bb27ca5db7415';

@ProviderFor(signUpUseCase)
final signUpUseCaseProvider = SignUpUseCaseProvider._();

final class SignUpUseCaseProvider
    extends $FunctionalProvider<SignUpUseCase, SignUpUseCase, SignUpUseCase>
    with $Provider<SignUpUseCase> {
  SignUpUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignUpUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignUpUseCase create(Ref ref) {
    return signUpUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignUpUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignUpUseCase>(value),
    );
  }
}

String _$signUpUseCaseHash() => r'0d89b91db81fa0969c9a22e1fbd89e2c08dfd762';

@ProviderFor(signInWithGoogleUseCase)
final signInWithGoogleUseCaseProvider = SignInWithGoogleUseCaseProvider._();

final class SignInWithGoogleUseCaseProvider
    extends
        $FunctionalProvider<
          SignInWithGoogleUseCase,
          SignInWithGoogleUseCase,
          SignInWithGoogleUseCase
        >
    with $Provider<SignInWithGoogleUseCase> {
  SignInWithGoogleUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInWithGoogleUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInWithGoogleUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignInWithGoogleUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SignInWithGoogleUseCase create(Ref ref) {
    return signInWithGoogleUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInWithGoogleUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInWithGoogleUseCase>(value),
    );
  }
}

String _$signInWithGoogleUseCaseHash() =>
    r'90789a2d7c98156d5f79d3f503e8cbe00f780594';

@ProviderFor(signOutUseCase)
final signOutUseCaseProvider = SignOutUseCaseProvider._();

final class SignOutUseCaseProvider
    extends $FunctionalProvider<SignOutUseCase, SignOutUseCase, SignOutUseCase>
    with $Provider<SignOutUseCase> {
  SignOutUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signOutUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signOutUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignOutUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignOutUseCase create(Ref ref) {
    return signOutUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignOutUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignOutUseCase>(value),
    );
  }
}

String _$signOutUseCaseHash() => r'0f3b8d96db38125057aabad192372a78dfc498d2';

@ProviderFor(resetPasswordUseCase)
final resetPasswordUseCaseProvider = ResetPasswordUseCaseProvider._();

final class ResetPasswordUseCaseProvider
    extends
        $FunctionalProvider<
          ResetPasswordUseCase,
          ResetPasswordUseCase,
          ResetPasswordUseCase
        >
    with $Provider<ResetPasswordUseCase> {
  ResetPasswordUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resetPasswordUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resetPasswordUseCaseHash();

  @$internal
  @override
  $ProviderElement<ResetPasswordUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ResetPasswordUseCase create(Ref ref) {
    return resetPasswordUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResetPasswordUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResetPasswordUseCase>(value),
    );
  }
}

String _$resetPasswordUseCaseHash() =>
    r'be0faeedfe83b966031bcde9d535f5b93e5e8d1f';

@ProviderFor(deleteAccountUseCase)
final deleteAccountUseCaseProvider = DeleteAccountUseCaseProvider._();

final class DeleteAccountUseCaseProvider
    extends
        $FunctionalProvider<
          DeleteAccountUseCase,
          DeleteAccountUseCase,
          DeleteAccountUseCase
        >
    with $Provider<DeleteAccountUseCase> {
  DeleteAccountUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAccountUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAccountUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteAccountUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteAccountUseCase create(Ref ref) {
    return deleteAccountUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteAccountUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteAccountUseCase>(value),
    );
  }
}

String _$deleteAccountUseCaseHash() =>
    r'5b05b7e3278afac417acf801bc832c8b6bf58584';

@ProviderFor(reauthenticateUseCase)
final reauthenticateUseCaseProvider = ReauthenticateUseCaseProvider._();

final class ReauthenticateUseCaseProvider
    extends
        $FunctionalProvider<
          ReauthenticateUseCase,
          ReauthenticateUseCase,
          ReauthenticateUseCase
        >
    with $Provider<ReauthenticateUseCase> {
  ReauthenticateUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reauthenticateUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reauthenticateUseCaseHash();

  @$internal
  @override
  $ProviderElement<ReauthenticateUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReauthenticateUseCase create(Ref ref) {
    return reauthenticateUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReauthenticateUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReauthenticateUseCase>(value),
    );
  }
}

String _$reauthenticateUseCaseHash() =>
    r'7d378db9fa14d3f1145b6939fe731a0e9f8d3a83';

@ProviderFor(reloadUserUseCase)
final reloadUserUseCaseProvider = ReloadUserUseCaseProvider._();

final class ReloadUserUseCaseProvider
    extends
        $FunctionalProvider<
          ReloadUserUseCase,
          ReloadUserUseCase,
          ReloadUserUseCase
        >
    with $Provider<ReloadUserUseCase> {
  ReloadUserUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reloadUserUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reloadUserUseCaseHash();

  @$internal
  @override
  $ProviderElement<ReloadUserUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReloadUserUseCase create(Ref ref) {
    return reloadUserUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReloadUserUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReloadUserUseCase>(value),
    );
  }
}

String _$reloadUserUseCaseHash() => r'97b2e638fac313baae5c3244b1819d22ccea25ac';

@ProviderFor(sendEmailVerificationUseCase)
final sendEmailVerificationUseCaseProvider =
    SendEmailVerificationUseCaseProvider._();

final class SendEmailVerificationUseCaseProvider
    extends
        $FunctionalProvider<
          SendEmailVerificationUseCase,
          SendEmailVerificationUseCase,
          SendEmailVerificationUseCase
        >
    with $Provider<SendEmailVerificationUseCase> {
  SendEmailVerificationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendEmailVerificationUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendEmailVerificationUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendEmailVerificationUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SendEmailVerificationUseCase create(Ref ref) {
    return sendEmailVerificationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendEmailVerificationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendEmailVerificationUseCase>(value),
    );
  }
}

String _$sendEmailVerificationUseCaseHash() =>
    r'46a757fb81ab6b1e46d4043e2d9836c8d3971a0c';

/// 今の時刻。テストで時刻を固定できるよう Provider 経由で読む

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// 今の時刻。テストで時刻を固定できるよう Provider 経由で読む

final class ClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// 今の時刻。テストで時刻を固定できるよう Provider 経由で読む
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$clockHash() => r'3f65ad34ac6fcd532de9004042bdf2ed2bd85b13';

/// 最後に確認メールの送信に成功したユーザーと時刻（アプリの起動中だけ覚える）。
/// 再送ボタンの60秒の待ち時間を、新規登録のときの送信からも数えるため、画面をまたいで持つ。
/// 別のアカウントに切り替えたら、そのアカウントの待ち時間は無い（ユーザーごとに数える）

@ProviderFor(VerificationEmailSentAt)
final verificationEmailSentAtProvider = VerificationEmailSentAtProvider._();

/// 最後に確認メールの送信に成功したユーザーと時刻（アプリの起動中だけ覚える）。
/// 再送ボタンの60秒の待ち時間を、新規登録のときの送信からも数えるため、画面をまたいで持つ。
/// 別のアカウントに切り替えたら、そのアカウントの待ち時間は無い（ユーザーごとに数える）
final class VerificationEmailSentAtProvider
    extends
        $NotifierProvider<
          VerificationEmailSentAt,
          ({DateTime at, String userId})?
        > {
  /// 最後に確認メールの送信に成功したユーザーと時刻（アプリの起動中だけ覚える）。
  /// 再送ボタンの60秒の待ち時間を、新規登録のときの送信からも数えるため、画面をまたいで持つ。
  /// 別のアカウントに切り替えたら、そのアカウントの待ち時間は無い（ユーザーごとに数える）
  VerificationEmailSentAtProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verificationEmailSentAtProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verificationEmailSentAtHash();

  @$internal
  @override
  VerificationEmailSentAt create() => VerificationEmailSentAt();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({DateTime at, String userId})? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({DateTime at, String userId})?>(
        value,
      ),
    );
  }
}

String _$verificationEmailSentAtHash() =>
    r'c53b49b391eccea4cb2898f891bea76b15e8ee36';

/// 最後に確認メールの送信に成功したユーザーと時刻（アプリの起動中だけ覚える）。
/// 再送ボタンの60秒の待ち時間を、新規登録のときの送信からも数えるため、画面をまたいで持つ。
/// 別のアカウントに切り替えたら、そのアカウントの待ち時間は無い（ユーザーごとに数える）

abstract class _$VerificationEmailSentAt
    extends $Notifier<({DateTime at, String userId})?> {
  ({DateTime at, String userId})? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({DateTime at, String userId})?,
              ({DateTime at, String userId})?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({DateTime at, String userId})?,
                ({DateTime at, String userId})?
              >,
              ({DateTime at, String userId})?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(withdrawnElsewhereUseCase)
final withdrawnElsewhereUseCaseProvider = WithdrawnElsewhereUseCaseProvider._();

final class WithdrawnElsewhereUseCaseProvider
    extends
        $FunctionalProvider<
          WithdrawnElsewhereUseCase,
          WithdrawnElsewhereUseCase,
          WithdrawnElsewhereUseCase
        >
    with $Provider<WithdrawnElsewhereUseCase> {
  WithdrawnElsewhereUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawnElsewhereUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawnElsewhereUseCaseHash();

  @$internal
  @override
  $ProviderElement<WithdrawnElsewhereUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WithdrawnElsewhereUseCase create(Ref ref) {
    return withdrawnElsewhereUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WithdrawnElsewhereUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WithdrawnElsewhereUseCase>(value),
    );
  }
}

String _$withdrawnElsewhereUseCaseHash() =>
    r'f55d03f03a2dcfb3115b13bbd52f49d53db7619b';
