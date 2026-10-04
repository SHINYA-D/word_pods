// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shell_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$developerStatusHash() => r'377ea620afd7c56d1eb79b28557605a9dcd1298c';

/// ログイン中のユーザーの開発者フラグ。ユーザーが変わったとき（ログインし直したとき）だけ読み直す。
///
/// Copied from [developerStatus].
@ProviderFor(developerStatus)
final developerStatusProvider = FutureProvider<bool>.internal(
  developerStatus,
  name: r'developerStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$developerStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeveloperStatusRef = FutureProviderRef<bool>;
String _$isDeveloperHash() => r'99f0539ceb5d54aaa8bd7e8aa27d31a81d7c296d';

/// 開発者かどうか（「テスト」タブとサンプル画面を出すか）。
/// 読み込み中（別のユーザーへの切り替え中を含む）は、前のユーザーの値を使わず false にする。
///
/// Copied from [isDeveloper].
@ProviderFor(isDeveloper)
final isDeveloperProvider = Provider<bool>.internal(
  isDeveloper,
  name: r'isDeveloperProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isDeveloperHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsDeveloperRef = ProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
