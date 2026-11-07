/// ログイン前に開ける画面
const authRoutes = {'/login', '/sign-up', '/password-reset'};

/// メールアドレスの確認待ち画面
const verifyEmailRoute = '/verify-email';

/// ログイン状態・メールアドレスの確認状態から、ルーターの移動先を決める。移動しないときは null。
/// 仕様: docs/detailed_design/email_verification/email_verification.md 4.3
///
/// - [isLoggedIn]: ログイン中か（強制ログアウトした uid はログインしていないものとして渡す）
/// - [isEmailVerified]: メールアドレスが確認済みか
/// - [location]: 今のパス
/// - [isHolding]: 画面の移動を止めているか（ログイン直後の初回同期中・確認メールの送信完了ダイアログの表示中）
/// - [isWithdrawn]: 退会が完了したか（ログアウトに失敗してログイン状態が残っていてもログイン画面に置く）
String? authRedirect({
  required bool isLoggedIn,
  required bool isEmailVerified,
  required String location,
  required bool isHolding,
  required bool isWithdrawn,
}) {
  final isAuthRoute = authRoutes.contains(location);
  if (!isLoggedIn) {
    return (isAuthRoute || location == '/') ? null : '/login';
  }
  if (isAuthRoute) {
    if (isHolding || isWithdrawn) return null;
    return isEmailVerified ? '/home' : verifyEmailRoute;
  }
  // スプラッシュはログイン状態を見て自分で移動する
  if (location == '/') return null;
  if (!isEmailVerified) {
    return location == verifyEmailRoute ? null : verifyEmailRoute;
  }
  if (location == verifyEmailRoute) return '/home';
  return null;
}
