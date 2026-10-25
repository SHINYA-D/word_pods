import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/account_repository.dart';

class GetIsDeveloperUseCase {
  const GetIsDeveloperUseCase(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, bool>> call(String userId) =>
      _repository.fetchIsDeveloper(userId);
}
