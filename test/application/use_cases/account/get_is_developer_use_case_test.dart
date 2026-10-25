import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_pods/application/use_cases/account/get_is_developer_use_case.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/account_repository.dart';

class _FakeAccountRepository implements AccountRepository {
  _FakeAccountRepository({required this.fetchIsDeveloperResult});

  final Either<Failure, bool> fetchIsDeveloperResult;

  String? capturedUserId;

  @override
  Future<Either<Failure, bool>> fetchIsDeveloper(String userId) async {
    capturedUserId = userId;
    return fetchIsDeveloperResult;
  }
}

void main() {
  group('GetIsDeveloperUseCase.call', () {
    test('Repositoryが Right(true) を返す場合、userId がそのまま渡り Right(true) が返る', () async {
      final repository = _FakeAccountRepository(
        fetchIsDeveloperResult: const Right<Failure, bool>(true),
      );
      final useCase = GetIsDeveloperUseCase(repository);

      final result = await useCase('u1');

      expect(repository.capturedUserId, 'u1');
      expect(result, equals(const Right<Failure, bool>(true)));
    });

    test('Repositoryが失敗を返した場合、Leftがそのまま返る', () async {
      final repository = _FakeAccountRepository(
        fetchIsDeveloperResult: const Left<Failure, bool>(
          Failure.unknown('error'),
        ),
      );
      final useCase = GetIsDeveloperUseCase(repository);

      final result = await useCase('u1');

      expect(
        result,
        equals(const Left<Failure, bool>(Failure.unknown('error'))),
      );
    });
  });
}
