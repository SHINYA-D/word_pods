import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_deletion_state.freezed.dart';

enum AccountDeletionPhase {
  /// 起動時の記録の確認が終わっていない
  checking,

  /// 待機
  idle,

  /// 退会処理中（再試行を含む）
  processing,

  /// 完了。完了ダイアログをまだ表示していない
  completed,

  /// 関数に届かず、何も削除していない
  notSent,

  /// 途中で止まっていて、再試行を待っている
  pendingRetry,
}

@freezed
abstract class AccountDeletionState with _$AccountDeletionState {
  const factory AccountDeletionState({
    required AccountDeletionPhase phase,

    /// 再開待ちで、直前の再試行が失敗したか
    @Default(false) bool retryFailed,

    /// 再開ダイアログからの処理か（処理中の表示を再開ダイアログの中に出すため）
    @Default(false) bool isRetry,
  }) = _AccountDeletionState;
}
