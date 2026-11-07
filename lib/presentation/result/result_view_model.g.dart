// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'result_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ResultViewModel)
final resultViewModelProvider = ResultViewModelProvider._();

final class ResultViewModelProvider
    extends $AsyncNotifierProvider<ResultViewModel, List<FlashcardResult>> {
  ResultViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resultViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resultViewModelHash();

  @$internal
  @override
  ResultViewModel create() => ResultViewModel();
}

String _$resultViewModelHash() => r'9c7d3104d298e4aef48b43a0cbaf7b1ad173e978';

abstract class _$ResultViewModel extends $AsyncNotifier<List<FlashcardResult>> {
  FutureOr<List<FlashcardResult>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<FlashcardResult>>, List<FlashcardResult>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<FlashcardResult>>,
                List<FlashcardResult>
              >,
              AsyncValue<List<FlashcardResult>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(folderNames)
final folderNamesProvider = FolderNamesProvider._();

final class FolderNamesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $FutureProvider<Map<String, String>> {
  FolderNamesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderNamesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderNamesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String>> create(Ref ref) {
    return folderNames(ref);
  }
}

String _$folderNamesHash() => r'cefddf89746cdfb34e0748cc8a58ae099d632884';
