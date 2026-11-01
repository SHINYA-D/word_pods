import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/account_deletion_request.dart';

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
  /// 最後の本人確認から時間が経っていて何も削除しなかったら `RecentLoginRequiredFailure`、
  /// 届いたか分からなければ `UnknownFailure` を返す。
  Future<Either<Failure, Unit>> requestServerDeletion();

  /// 端末内のそのユーザーのデータと退会処理の記録を、1つのトランザクションで削除する。
  Future<Either<Failure, Unit>> deleteLocalData(String userId);

  /// 端末内にデータがある uid の一覧（他の端末での退会の確認の対象）。
  Future<Either<Failure, List<String>>> findLocalUserIds();

  /// その uid に退会済みの記録（Firestore の `deleted_accounts/{uid}`）があるか。
  /// オフラインなら `NetworkFailure`。
  Future<Either<Failure, bool>> isWithdrawnOnServer(String userId);

  /// その uid の退会済みの記録をリアルタイムで監視する。
  Stream<Either<Failure, bool>> watchWithdrawn(String userId);

  /// 複数の uid の端末内のデータを、まとめて1つのトランザクションで削除する。
  Future<Either<Failure, Unit>> deleteLocalDataOfUsers(List<String> userIds);

  /// ログアウトが失敗した uid を、アプリではログアウトしたものとして扱うために記録する。
  Future<Either<Failure, Unit>> markForcedSignOut(String userId);

  /// 強制ログアウトの記録の uid。無ければ `None`。
  Future<Either<Failure, Option<String>>> findForcedSignOut();

  /// その uid の強制ログアウトの記録を消す。
  Future<Either<Failure, Unit>> clearForcedSignOut(String userId);
}
