// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawn_elsewhere_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 他の端末での退会。起動時・復帰時の確認と、ログイン中の uid の退会済みの記録の監視を行う。
///
/// ログイン中のアカウントが退会済みなら、お知らせ → ログアウト → データの削除ダイアログの順に進める。
/// ログアウト済みのアカウントは、確認の中で何も表示せずに削除する（[WithdrawnElsewhereUseCase.check]）。

@ProviderFor(WithdrawnElsewhereViewModel)
final withdrawnElsewhereViewModelProvider =
    WithdrawnElsewhereViewModelProvider._();

/// 他の端末での退会。起動時・復帰時の確認と、ログイン中の uid の退会済みの記録の監視を行う。
///
/// ログイン中のアカウントが退会済みなら、お知らせ → ログアウト → データの削除ダイアログの順に進める。
/// ログアウト済みのアカウントは、確認の中で何も表示せずに削除する（[WithdrawnElsewhereUseCase.check]）。
final class WithdrawnElsewhereViewModelProvider
    extends
        $NotifierProvider<
          WithdrawnElsewhereViewModel,
          WithdrawnElsewhereState
        > {
  /// 他の端末での退会。起動時・復帰時の確認と、ログイン中の uid の退会済みの記録の監視を行う。
  ///
  /// ログイン中のアカウントが退会済みなら、お知らせ → ログアウト → データの削除ダイアログの順に進める。
  /// ログアウト済みのアカウントは、確認の中で何も表示せずに削除する（[WithdrawnElsewhereUseCase.check]）。
  WithdrawnElsewhereViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawnElsewhereViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawnElsewhereViewModelHash();

  @$internal
  @override
  WithdrawnElsewhereViewModel create() => WithdrawnElsewhereViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WithdrawnElsewhereState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WithdrawnElsewhereState>(value),
    );
  }
}

String _$withdrawnElsewhereViewModelHash() =>
    r'32398813f6ad747ab1e3bae7f9af6b712edb30fd';

/// 他の端末での退会。起動時・復帰時の確認と、ログイン中の uid の退会済みの記録の監視を行う。
///
/// ログイン中のアカウントが退会済みなら、お知らせ → ログアウト → データの削除ダイアログの順に進める。
/// ログアウト済みのアカウントは、確認の中で何も表示せずに削除する（[WithdrawnElsewhereUseCase.check]）。

abstract class _$WithdrawnElsewhereViewModel
    extends $Notifier<WithdrawnElsewhereState> {
  WithdrawnElsewhereState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<WithdrawnElsewhereState, WithdrawnElsewhereState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WithdrawnElsewhereState, WithdrawnElsewhereState>,
              WithdrawnElsewhereState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
