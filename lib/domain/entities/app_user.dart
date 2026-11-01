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
  }) = _AppUser;
}
