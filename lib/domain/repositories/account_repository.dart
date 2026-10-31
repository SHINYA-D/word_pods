import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';

/// アカウント情報（Firestore の `accounts/{uid}`。クライアントは読み取りのみ）。
abstract class AccountRepository {
  /// 開発者かどうかを返す。`isDeveloper` が true（真偽値）のときだけ true。
  /// ドキュメントやフィールドが無い・true 以外の値なら false。
  /// 読み取りに失敗したら、種類によらず `UnknownFailure` を返す。
  Future<Either<Failure, bool>> fetchIsDeveloper(String userId);
}
