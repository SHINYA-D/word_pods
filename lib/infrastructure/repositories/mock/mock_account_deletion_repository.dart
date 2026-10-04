import 'package:fpdart/fpdart.dart';
import 'package:word_stock/core/error/failure.dart';
import 'package:word_stock/domain/entities/account_deletion_request.dart';
import 'package:word_stock/domain/repositories/account_deletion_repository.dart';

/// 開発用インメモリ実装。サーバー・端末内の削除は常に成功する。
class MockAccountDeletionRepository implements AccountDeletionRepository {
  AccountDeletionRequest? _request;

  @override
  Future<Either<Failure, Option<AccountDeletionRequest>>> findPending() async =>
      Right(Option.fromNullable(_request));

  @override
  Future<Either<Failure, Unit>> markRequested(String userId) async {
    _request = AccountDeletionRequest(
      userId: userId,
      status: AccountDeletionStatus.requested,
      updatedAt: DateTime.now(),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> markServerDone(String userId) async {
    _request = AccountDeletionRequest(
      userId: userId,
      status: AccountDeletionStatus.serverDone,
      updatedAt: DateTime.now(),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> clearRequest(String userId) async {
    _request = null;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> requestServerDeletion() async {
    await Future.delayed(const Duration(seconds: 1));
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteLocalData(String userId) async {
    _request = null;
    return const Right(unit);
  }
}
