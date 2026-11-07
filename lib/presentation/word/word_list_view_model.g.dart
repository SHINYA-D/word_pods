// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_list_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WordListViewModel)
final wordListViewModelProvider = WordListViewModelFamily._();

final class WordListViewModelProvider
    extends $AsyncNotifierProvider<WordListViewModel, List<Word>> {
  WordListViewModelProvider._({
    required WordListViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'wordListViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$wordListViewModelHash();

  @override
  String toString() {
    return r'wordListViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WordListViewModel create() => WordListViewModel();

  @override
  bool operator ==(Object other) {
    return other is WordListViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$wordListViewModelHash() => r'd1518e65274186b547b6f6a0fe3bb7aaecae31c7';

final class WordListViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          WordListViewModel,
          AsyncValue<List<Word>>,
          List<Word>,
          FutureOr<List<Word>>,
          String
        > {
  WordListViewModelFamily._()
    : super(
        retry: null,
        name: r'wordListViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WordListViewModelProvider call(String folderId) =>
      WordListViewModelProvider._(argument: folderId, from: this);

  @override
  String toString() => r'wordListViewModelProvider';
}

abstract class _$WordListViewModel extends $AsyncNotifier<List<Word>> {
  late final _$args = ref.$arg as String;
  String get folderId => _$args;

  FutureOr<List<Word>> build(String folderId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Word>>, List<Word>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Word>>, List<Word>>,
              AsyncValue<List<Word>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
