import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_deletion_request.freezed.dart';

/// 退会処理がどこまで進んだか。
enum AccountDeletionStatus {
  /// 関数 `deleteAccount` を呼んだが、成功をまだ受け取っていない
  requested,

  /// 関数の成功を受け取った。端末内のデータの削除が終わっていない
  serverDone,
}

/// 端末に残っている退会処理の記録。記録が無いことは、退会処理をしていないか、すべて終わったことを表す。
@freezed
abstract class AccountDeletionRequest with _$AccountDeletionRequest {
  const factory AccountDeletionRequest({
    required String userId,
    required AccountDeletionStatus status,
    required DateTime updatedAt,
  }) = _AccountDeletionRequest;
}
