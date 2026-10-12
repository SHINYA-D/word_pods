import 'package:freezed_annotation/freezed_annotation.dart';

part 'withdrawn_elsewhere_state.freezed.dart';

enum WithdrawnElsewherePhase {
  /// 待機
  idle,

  /// 退会済みの記録を確認している
  checking,

  /// お知らせダイアログを表示している（ログイン中のアカウントが退会済み）
  notifying,

  /// データの削除ダイアログを表示している
  confirming,

  /// 端末内のデータを削除している
  deleting,

  /// 失敗ダイアログを表示している
  failed,
}

@freezed
abstract class WithdrawnElsewhereState with _$WithdrawnElsewhereState {
  const factory WithdrawnElsewhereState({
    @Default(WithdrawnElsewherePhase.idle) WithdrawnElsewherePhase phase,

    /// データの削除ダイアログで削除する uid（ログイン中に退会済みと分かった uid）
    @Default(<String>[]) List<String> userIds,

    /// 強制ログアウトの記録の uid。Firebase 上でログイン中でも、アプリではログアウトしたものとして扱う
    String? forcedUserId,

    /// 強制ログアウトの記録を読み終えたか（読み終えるまでスプラッシュ画面から移動しない）
    @Default(false) bool forcedLoaded,
  }) = _WithdrawnElsewhereState;
}
