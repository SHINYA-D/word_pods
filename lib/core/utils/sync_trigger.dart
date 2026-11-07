import 'package:word_pods/domain/entities/app_user.dart';

/// 仕様: docs/detailed_design/email_verification/email_verification.md 4.4
///
/// ログイン中のユーザーが [previous] から [next] に変わったときに、同期を始めるか。
/// 確認済みのユーザーになったとき（ログインした・別のユーザーに変わった・確認済みに変わった）だけ始める。
/// 未確認の間は Firestore を読み書きできないため始めない
bool shouldStartSync(AppUser? previous, AppUser? next) {
  if (next == null || !next.emailVerified) return false;
  if (previous == null || previous.id != next.id) return true;
  return !previous.emailVerified;
}

/// 同期の対象にするユーザーの uid。ログインしていない・メールアドレスが未確認なら null（同期しない）
String? syncUserId({required String? uid, required bool emailVerified}) {
  if (uid == null || !emailVerified) return null;
  return uid;
}
