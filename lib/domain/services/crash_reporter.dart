/// クラッシュ・非致命的エラーの報告口（Crashlytics）。
/// 仕様: docs/detailed_design/crash_reporting/crash_reporting.md 2.1
abstract class CrashReporter {
  /// クラッシュ情報を集めるかを設定する。
  Future<void> setCollectionEnabled(bool enabled);

  /// エラーを記録する。[fatal] が true ならクラッシュとして記録する。
  Future<void> recordError(Object error, StackTrace? stack, {required bool fatal});

  /// 以後の記録に付けるユーザーの識別子を設定する。空文字は「付けない」。
  Future<void> setUserIdentifier(String id);
}
