// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shell_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ログイン中のユーザーの開発者フラグ。ユーザーが変わったとき（ログインし直したとき）だけ読み直す。

@ProviderFor(developerStatus)
final developerStatusProvider = DeveloperStatusProvider._();

/// ログイン中のユーザーの開発者フラグ。ユーザーが変わったとき（ログインし直したとき）だけ読み直す。

final class DeveloperStatusProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// ログイン中のユーザーの開発者フラグ。ユーザーが変わったとき（ログインし直したとき）だけ読み直す。
  DeveloperStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'developerStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$developerStatusHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return developerStatus(ref);
  }
}

String _$developerStatusHash() => r'377ea620afd7c56d1eb79b28557605a9dcd1298c';

/// 開発者かどうか（「テスト」タブとサンプル画面を出すか）。
/// 読み込み中（別のユーザーへの切り替え中を含む）は、前のユーザーの値を使わず false にする。

@ProviderFor(isDeveloper)
final isDeveloperProvider = IsDeveloperProvider._();

/// 開発者かどうか（「テスト」タブとサンプル画面を出すか）。
/// 読み込み中（別のユーザーへの切り替え中を含む）は、前のユーザーの値を使わず false にする。

final class IsDeveloperProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 開発者かどうか（「テスト」タブとサンプル画面を出すか）。
  /// 読み込み中（別のユーザーへの切り替え中を含む）は、前のユーザーの値を使わず false にする。
  IsDeveloperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isDeveloperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isDeveloperHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isDeveloper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isDeveloperHash() => r'e3b9443c819bd558d1bf0b2f5ccdd6e565e96645';
