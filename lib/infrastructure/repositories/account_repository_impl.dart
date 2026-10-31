import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/account_repository.dart';
import 'package:word_pods/infrastructure/data_sources/remote/account_remote_data_source.dart';

/// 開発者フラグは同期の対象外のため、SQLite を通さず Firestore から直接読む。
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({required AccountRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final AccountRemoteDataSource _remote;

  /// 失敗しても開発者でないとして扱うだけなので、失敗の種類は分けない
  /// （オフラインで読めなかっただけでログアウトさせないため、`NetworkFailure` にしない）。
  @override
  Future<Either<Failure, bool>> fetchIsDeveloper(String userId) async {
    try {
      return Right(await _remote.fetchIsDeveloper(userId));
    } catch (e) {
      return Left(Failure.unknown(e.toString()));
    }
  }
}
