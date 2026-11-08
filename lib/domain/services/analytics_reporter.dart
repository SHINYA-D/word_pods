/// 利用状況の記録口（Analytics）。uid を付けないため、ユーザーの識別子を設定するメソッドは持たない。
/// 仕様: docs/detailed_design/crash_reporting/crash_reporting.md 2.1.1
abstract class AnalyticsReporter {
  /// 利用状況を集めるかを設定する。
  Future<void> setCollectionEnabled(bool enabled);

  /// 画面を見たことを記録する。
  Future<void> logScreenView(String screenName);
}
