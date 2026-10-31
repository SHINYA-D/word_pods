import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/account_repository.dart';

/// 開発用実装。モックモードは開発者が使うものなので、常に開発者として扱う。
class MockAccountRepository implements AccountRepository {
  @override
  Future<Either<Failure, bool>> fetchIsDeveloper(String userId) async =>
      const Right(true);
}
