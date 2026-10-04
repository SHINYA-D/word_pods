// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_deletion_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$accountDeletionViewModelHash() =>
    r'c33afa51f5d14b4f7ab46410a3a782b8477126bb';

/// 退会処理の状態。退会後のログイン画面への移動や、起動時の再開をまたぐため keepAlive にする。
///
/// Copied from [AccountDeletionViewModel].
@ProviderFor(AccountDeletionViewModel)
final accountDeletionViewModelProvider =
    NotifierProvider<AccountDeletionViewModel, AccountDeletionState>.internal(
  AccountDeletionViewModel.new,
  name: r'accountDeletionViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$accountDeletionViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AccountDeletionViewModel = Notifier<AccountDeletionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
