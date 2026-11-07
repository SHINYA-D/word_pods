// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettingsViewModel)
final settingsViewModelProvider = SettingsViewModelFamily._();

final class SettingsViewModelProvider
    extends $AsyncNotifierProvider<SettingsViewModel, UserSettings> {
  SettingsViewModelProvider._({
    required SettingsViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'settingsViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$settingsViewModelHash();

  @override
  String toString() {
    return r'settingsViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SettingsViewModel create() => SettingsViewModel();

  @override
  bool operator ==(Object other) {
    return other is SettingsViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$settingsViewModelHash() => r'a6bb8199e1769dd60f5ebe77bee7da539098f840';

final class SettingsViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SettingsViewModel,
          AsyncValue<UserSettings>,
          UserSettings,
          FutureOr<UserSettings>,
          String
        > {
  SettingsViewModelFamily._()
    : super(
        retry: null,
        name: r'settingsViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SettingsViewModelProvider call(String userId) =>
      SettingsViewModelProvider._(argument: userId, from: this);

  @override
  String toString() => r'settingsViewModelProvider';
}

abstract class _$SettingsViewModel extends $AsyncNotifier<UserSettings> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  FutureOr<UserSettings> build(String userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserSettings>, UserSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserSettings>, UserSettings>,
              AsyncValue<UserSettings>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
