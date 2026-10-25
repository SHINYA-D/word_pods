import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/word.dart';
import 'package:word_pods/domain/repositories/word_repository.dart';

class UpdateWordUseCase {
  const UpdateWordUseCase(this._repository);

  final WordRepository _repository;

  Future<Either<Failure, Word>> call({
    required String userId,
    required String folderId,
    required String wordId,
    required String front,
    required String back,
  }) {
    return _repository.updateWord(
      userId: userId,
      folderId: folderId,
      wordId: wordId,
      front: front,
      back: back,
    );
  }
}
