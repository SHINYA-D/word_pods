// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_mode_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FlashcardModeViewModel)
final flashcardModeViewModelProvider = FlashcardModeViewModelProvider._();

final class FlashcardModeViewModelProvider
    extends $NotifierProvider<FlashcardModeViewModel, FlashcardModeState> {
  FlashcardModeViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flashcardModeViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flashcardModeViewModelHash();

  @$internal
  @override
  FlashcardModeViewModel create() => FlashcardModeViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlashcardModeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlashcardModeState>(value),
    );
  }
}

String _$flashcardModeViewModelHash() =>
    r'38a120c50a7e2d06ac4588363345766f5c476255';

abstract class _$FlashcardModeViewModel extends $Notifier<FlashcardModeState> {
  FlashcardModeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FlashcardModeState, FlashcardModeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FlashcardModeState, FlashcardModeState>,
              FlashcardModeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
