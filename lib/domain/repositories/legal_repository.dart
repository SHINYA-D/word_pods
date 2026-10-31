import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';

/// 利用規約・プライバシーポリシーへの同意（Firestore の `app_config/legal`・`accounts/{uid}.consents`、
/// Cloud Functions の `acceptLegal`）。同期の対象外のため、SQLite を通さずサーバーと直接やり取りする。
abstract class LegalRepository {
  /// 現行の規約の情報をサーバーから読む（端末のキャッシュは使わない）。
  /// ドキュメントが無い・4項目のどれかが無い・文字列でない・空白だけなら `NotFoundFailure`。
  /// 接続できなければ `NetworkFailure`、それ以外の失敗は `UnknownFailure`。
  Future<Either<Failure, LegalConfig>> fetchLegalConfig();

  /// 同意済みの版数をサーバーから読む。記録が無い・文字列でない文書は null。
  /// 接続できなければ `NetworkFailure`、それ以外の失敗は `UnknownFailure`。
  Future<Either<Failure, LegalConsents>> fetchConsents(String userId);

  /// 同意を送信する。null の文書は送らない。
  /// 版数が現行と違えば `Right(LegalAcceptResult.outdated)`。
  /// 届かなかった・時間切れは `NetworkFailure`、ログイン情報が無効なら `AuthFailure`、それ以外は `UnknownFailure`。
  Future<Either<Failure, LegalAcceptResult>> accept({
    String? termsVersion,
    String? privacyVersion,
  });
}
