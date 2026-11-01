import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const factory Failure.network() = NetworkFailure;
  const factory Failure.auth() = AuthFailure;
  const factory Failure.notFound() = NotFoundFailure;
  const factory Failure.unknown(String message) = UnknownFailure;

  /// 最後にログイン（本人確認）してから時間が経っていて、本人確認のし直しが必要（退会の関数）
  const factory Failure.recentLoginRequired() = RecentLoginRequiredFailure;

  /// 試行回数の上限を超えた（本人確認）。時間をおけば通る
  const factory Failure.tooManyRequests() = TooManyRequestsFailure;
}
