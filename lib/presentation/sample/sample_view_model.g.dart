// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sample_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SampleViewModel)
final sampleViewModelProvider = SampleViewModelProvider._();

final class SampleViewModelProvider
    extends $NotifierProvider<SampleViewModel, SampleState> {
  SampleViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sampleViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sampleViewModelHash();

  @$internal
  @override
  SampleViewModel create() => SampleViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SampleState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SampleState>(value),
    );
  }
}

String _$sampleViewModelHash() => r'2e0abd4d45070bee017619a863cb42feeb8bf250';

abstract class _$SampleViewModel extends $Notifier<SampleState> {
  SampleState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SampleState, SampleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SampleState, SampleState>,
              SampleState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
