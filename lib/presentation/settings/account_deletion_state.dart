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

  /// 途中で止まっていて、続きを行うには本人確認のし直しが必要
  reauthRequired,

  /// 退会の前の本人確認で、パスワードが違う（別のアカウントを選んだ）・試行回数の上限を超えた。
  /// 何も削除していない
  reauthRejected,
}

@freezed
abstract class AccountDeletionState with _$AccountDeletionState {
  const factory AccountDeletionState({
    required AccountDeletionPhase phase,

    /// 再開待ちで、直前の再試行が失敗したか
    @Default(false) bool retryFailed,

    /// 再開ダイアログからの処理か（処理中の表示を再開ダイアログの中に出すため）
    @Default(false) bool isRetry,

    /// 本人確認のし直しを待っていて、直前の本人確認でパスワードが違った（別のアカウントを選んだ）か
    @Default(false) bool reauthRejected,

    /// 直前の本人確認が、試行回数の上限を超えて失敗したか
    @Default(false) bool tooManyAttempts,
  }) = _AccountDeletionState;
}
