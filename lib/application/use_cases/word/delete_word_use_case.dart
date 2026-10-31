import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/word_repository.dart';

class DeleteWordUseCase {
  const DeleteWordUseCase(this._repository);

  final WordRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String userId,
    required String folderId,
    required String wordId,
  }) {
    return _repository.deleteWord(
      userId: userId,
      folderId: folderId,
      wordId: wordId,
    );
  }
}
