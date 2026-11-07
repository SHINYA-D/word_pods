import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/application/use_cases/flashcard_result/get_flashcard_results_use_case.dart';
import 'package:word_pods/application/use_cases/flashcard_result/save_flashcard_result_use_case.dart';
import 'package:word_pods/core/di/repository_providers.dart';

part 'flashcard_result_providers.g.dart';

@Riverpod(keepAlive: true)
GetFlashcardResultsUseCase getFlashcardResultsUseCase(Ref ref) =>
    GetFlashcardResultsUseCase(ref.watch(flashcardResultRepositoryProvider));

@Riverpod(keepAlive: true)
SaveFlashcardResultUseCase saveFlashcardResultUseCase(Ref ref) =>
    SaveFlashcardResultUseCase(ref.watch(flashcardResultRepositoryProvider));
