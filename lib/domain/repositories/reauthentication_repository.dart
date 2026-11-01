import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';

/// ログイン中のユーザーの本人確認のし直し（退会の前に行う）。
abstract class ReauthenticationRepository {
  /// パスワードで本人確認する。
  /// パスワードが違えば `AuthFailure`、通信できなければ `NetworkFailure`、
  /// 試行回数の上限を超えていれば `TooManyRequestsFailure`。
  Future<Either<Failure, Unit>> reauthenticateWithPassword(String password);

  /// Google で本人確認する。キャンセルされたら `Right(false)`。
  /// ログイン中と別の Google アカウントを選んだら `AuthFailure`、通信できなければ `NetworkFailure`。
  Future<Either<Failure, bool>> reauthenticateWithGoogle();
}
