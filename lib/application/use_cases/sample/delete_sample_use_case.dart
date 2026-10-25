import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/sample_repository.dart';

class DeleteSampleUseCase {
  const DeleteSampleUseCase(this._repository);

  final SampleRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String userId,
    required String sampleId,
  }) {
    return _repository.deleteSample(userId: userId, sampleId: sampleId);
  }
}
