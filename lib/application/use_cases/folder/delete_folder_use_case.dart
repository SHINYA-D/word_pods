import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/folder_repository.dart';

class DeleteFolderUseCase {
  const DeleteFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String userId,
    required String folderId,
  }) {
    return _repository.deleteFolder(userId: userId, folderId: folderId);
  }
}
