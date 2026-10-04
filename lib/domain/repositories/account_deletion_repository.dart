import 'package:fpdart/fpdart.dart';
import 'package:word_stock/core/error/failure.dart';
import 'package:word_stock/domain/entities/account_deletion_request.dart';

/// 退会処理（サーバー側の削除の依頼・端末内の削除・進み具合の記録）。
abstract class AccountDeletionRepository {
  /// 端末に残っている退会処理の記録を返す。無ければ `None`。
  Future<Either<Failure, Option<AccountDeletionRequest>>> findPending();

  /// 退会処理を始めたことを記録する（状態は `requested`）。
  Future<Either<Failure, Unit>> markRequested(String userId);

  /// サーバー側の削除が終わったことを記録する（状態は `serverDone`）。
  Future<Either<Failure, Unit>> markServerDone(String userId);

  /// 退会処理の記録を消す（関数に届かず、何も削除していないとき）。
  Future<Either<Failure, Unit>> clearRequest(String userId);

  /// Firestore と Authentication の削除をサーバーに依頼する。
  ///
  /// 届かなかったことが確かなら `NetworkFailure`、ログイン情報が無効なら `AuthFailure`、
  /// 届いたか分からなければ `UnknownFailure` を返す。
  Future<Either<Failure, Unit>> requestServerDeletion();

  /// 端末内のそのユーザーのデータと退会処理の記録を、1つのトランザクションで削除する。
  Future<Either<Failure, Unit>> deleteLocalData(String userId);
}
