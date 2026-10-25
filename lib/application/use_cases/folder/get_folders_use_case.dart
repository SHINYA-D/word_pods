import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/folder.dart';
import 'package:word_pods/domain/repositories/folder_repository.dart';

class GetFoldersUseCase {
  const GetFoldersUseCase(this._repository);

  final FolderRepository _repository;

  Future<Either<Failure, List<Folder>>> call({
    required String userId,
  }) {
    return _repository.getFolders(
      userId: userId,
    );
  }
}
