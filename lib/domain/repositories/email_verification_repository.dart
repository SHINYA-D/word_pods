import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/app_user.dart';

/// メールアドレスの確認（確認メールの送信と、確認状態の問い合わせ）。
/// 仕様: docs/detailed_design/email_verification/email_verification.md 5.1
abstract class EmailVerificationRepository {
  /// ログイン中のユーザーの最新の状態（確認済みか）を Firebase に問い合わせる。
  /// 確認済みなら、Firestore への読み書きに使うログイン情報も確認済みのものに更新する。
  Future<Either<Failure, AppUser>> reloadUser();

  /// ログイン中のユーザーのメールアドレスに、確認メールを日本語で送る。
  Future<Either<Failure, Unit>> sendEmailVerification();
}
