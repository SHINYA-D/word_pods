import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/sample.dart';
import 'package:word_pods/domain/repositories/sample_repository.dart';

class UpdateSampleUseCase {
  const UpdateSampleUseCase(this._repository);

  final SampleRepository _repository;

  Future<Either<Failure, Sample>> call({
    required String userId,
    required String sampleId,
    required String name,
  }) {
    return _repository.updateSample(
      userId: userId,
      sampleId: sampleId,
      name: name,
    );
  }
}
