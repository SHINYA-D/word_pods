// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_reset_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PasswordResetViewModel)
final passwordResetViewModelProvider = PasswordResetViewModelProvider._();

final class PasswordResetViewModelProvider
    extends $NotifierProvider<PasswordResetViewModel, AuthState> {
  PasswordResetViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordResetViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordResetViewModelHash();

  @$internal
  @override
  PasswordResetViewModel create() => PasswordResetViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$passwordResetViewModelHash() =>
    r'57e60da2b7c6bafca167ee22c917ccc07eb89967';

abstract class _$PasswordResetViewModel extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
