// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_result_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getFlashcardResultsUseCase)
final getFlashcardResultsUseCaseProvider =
    GetFlashcardResultsUseCaseProvider._();

final class GetFlashcardResultsUseCaseProvider
    extends
        $FunctionalProvider<
          GetFlashcardResultsUseCase,
          GetFlashcardResultsUseCase,
          GetFlashcardResultsUseCase
        >
    with $Provider<GetFlashcardResultsUseCase> {
  GetFlashcardResultsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getFlashcardResultsUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getFlashcardResultsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetFlashcardResultsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetFlashcardResultsUseCase create(Ref ref) {
    return getFlashcardResultsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetFlashcardResultsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetFlashcardResultsUseCase>(value),
    );
  }
}

String _$getFlashcardResultsUseCaseHash() =>
    r'9b8a5324c7572fa11d3a30286ea070922f085858';

@ProviderFor(saveFlashcardResultUseCase)
final saveFlashcardResultUseCaseProvider =
    SaveFlashcardResultUseCaseProvider._();

final class SaveFlashcardResultUseCaseProvider
    extends
        $FunctionalProvider<
          SaveFlashcardResultUseCase,
          SaveFlashcardResultUseCase,
          SaveFlashcardResultUseCase
        >
    with $Provider<SaveFlashcardResultUseCase> {
  SaveFlashcardResultUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveFlashcardResultUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveFlashcardResultUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveFlashcardResultUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveFlashcardResultUseCase create(Ref ref) {
    return saveFlashcardResultUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveFlashcardResultUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveFlashcardResultUseCase>(value),
    );
  }
}

String _$saveFlashcardResultUseCaseHash() =>
    r'a28c3e42e288725c974c844a44b20e3ffc3e4c77';
