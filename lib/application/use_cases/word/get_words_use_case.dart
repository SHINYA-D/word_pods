import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/word.dart';
import 'package:word_pods/domain/repositories/word_repository.dart';

class GetWordsUseCase {
  const GetWordsUseCase(this._repository);

  final WordRepository _repository;

  Future<Either<Failure, List<Word>>> call({
    required String userId,
    required String folderId,
  }) {
    return _repository.getWords(userId: userId, folderId: folderId);
  }
}
