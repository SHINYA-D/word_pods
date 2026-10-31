import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/folder.dart';
import 'package:word_pods/domain/repositories/folder_repository.dart';

class UpdateFolderUseCase {
  const UpdateFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<Either<Failure, Folder>> call({
    required String userId,
    required String folderId,
    required String name,
  }) {
    return _repository.updateFolder(
      userId: userId,
      folderId: folderId,
      name: name,
    );
  }
}
