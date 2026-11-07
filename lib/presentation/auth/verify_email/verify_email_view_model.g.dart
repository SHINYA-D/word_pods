// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_email_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 確認待ち画面。確認済みになったときの画面の移動はルーター（`authRedirect`）が行う。
/// 仕様: docs/detailed_design/email_verification/email_verification.md 4.2

@ProviderFor(VerifyEmailViewModel)
final verifyEmailViewModelProvider = VerifyEmailViewModelProvider._();

/// 確認待ち画面。確認済みになったときの画面の移動はルーター（`authRedirect`）が行う。
/// 仕様: docs/detailed_design/email_verification/email_verification.md 4.2
final class VerifyEmailViewModelProvider
    extends $NotifierProvider<VerifyEmailViewModel, VerifyEmailState> {
  /// 確認待ち画面。確認済みになったときの画面の移動はルーター（`authRedirect`）が行う。
  /// 仕様: docs/detailed_design/email_verification/email_verification.md 4.2
  VerifyEmailViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifyEmailViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifyEmailViewModelHash();

  @$internal
  @override
  VerifyEmailViewModel create() => VerifyEmailViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerifyEmailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerifyEmailState>(value),
    );
  }
}

String _$verifyEmailViewModelHash() =>
    r'674bd3c56ba93253326058aefb304328caac1409';

/// 確認待ち画面。確認済みになったときの画面の移動はルーター（`authRedirect`）が行う。
/// 仕様: docs/detailed_design/email_verification/email_verification.md 4.2

abstract class _$VerifyEmailViewModel extends $Notifier<VerifyEmailState> {
  VerifyEmailState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VerifyEmailState, VerifyEmailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VerifyEmailState, VerifyEmailState>,
              VerifyEmailState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
