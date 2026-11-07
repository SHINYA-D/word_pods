import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
    String? displayName,

    /// メールアドレスとパスワードでログインできるか（本人確認でパスワードを求めるか）。
    /// false なら Google で本人確認する
    @Default(false) bool hasPassword,

    /// メールアドレスが確認済みか（確認メールのリンクを押したか）。未確認の間は確認待ち画面から先に進めず、同期もしない。
    /// Google でログインしたユーザーは最初から true。Firebase のユーザーから作るときは必ず値を写す
    /// （既定値の true は、テストや Mock で確認済みのユーザーを簡単に作るため）
    @Default(true) bool emailVerified,
  }) = _AppUser;
}
