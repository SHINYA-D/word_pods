// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_deletion_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 退会処理の状態。退会後のログイン画面への移動や、起動時の再開をまたぐため keepAlive にする。

@ProviderFor(AccountDeletionViewModel)
final accountDeletionViewModelProvider = AccountDeletionViewModelProvider._();

/// 退会処理の状態。退会後のログイン画面への移動や、起動時の再開をまたぐため keepAlive にする。
final class AccountDeletionViewModelProvider
    extends $NotifierProvider<AccountDeletionViewModel, AccountDeletionState> {
  /// 退会処理の状態。退会後のログイン画面への移動や、起動時の再開をまたぐため keepAlive にする。
  AccountDeletionViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDeletionViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDeletionViewModelHash();

  @$internal
  @override
  AccountDeletionViewModel create() => AccountDeletionViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountDeletionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountDeletionState>(value),
    );
  }
}

String _$accountDeletionViewModelHash() =>
    r'4ea634aeed00a27dff6ccf181375bb2d159b1ce6';

/// 退会処理の状態。退会後のログイン画面への移動や、起動時の再開をまたぐため keepAlive にする。

abstract class _$AccountDeletionViewModel
    extends $Notifier<AccountDeletionState> {
  AccountDeletionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AccountDeletionState, AccountDeletionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AccountDeletionState, AccountDeletionState>,
              AccountDeletionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
