// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_up_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignUpViewModel)
final signUpViewModelProvider = SignUpViewModelProvider._();

final class SignUpViewModelProvider
    extends $NotifierProvider<SignUpViewModel, AuthState> {
  SignUpViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpViewModelHash();

  @$internal
  @override
  SignUpViewModel create() => SignUpViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$signUpViewModelHash() => r'363da1c5601c375eabb124c047829c50bc0cb6b1';

abstract class _$SignUpViewModel extends $Notifier<AuthState> {
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
