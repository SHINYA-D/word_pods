// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawn_elsewhere_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$withdrawnElsewhereViewModelHash() =>
    r'32398813f6ad747ab1e3bae7f9af6b712edb30fd';

/// 他の端末での退会。起動時・復帰時の確認と、ログイン中の uid の退会済みの記録の監視を行う。
///
/// ログイン中のアカウントが退会済みなら、お知らせ → ログアウト → データの削除ダイアログの順に進める。
/// ログアウト済みのアカウントは、確認の中で何も表示せずに削除する（[WithdrawnElsewhereUseCase.check]）。
///
/// Copied from [WithdrawnElsewhereViewModel].
@ProviderFor(WithdrawnElsewhereViewModel)
final withdrawnElsewhereViewModelProvider = NotifierProvider<
    WithdrawnElsewhereViewModel, WithdrawnElsewhereState>.internal(
  WithdrawnElsewhereViewModel.new,
  name: r'withdrawnElsewhereViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$withdrawnElsewhereViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WithdrawnElsewhereViewModel = Notifier<WithdrawnElsewhereState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
