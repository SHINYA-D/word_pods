import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/core/di/repository_providers.dart';
import 'package:word_pods/domain/services/analytics_reporter.dart';
import 'package:word_pods/domain/services/crash_reporter.dart';
import 'package:word_pods/infrastructure/reporting/firebase_analytics_reporter.dart';
import 'package:word_pods/infrastructure/reporting/firebase_crash_reporter.dart';
import 'package:word_pods/infrastructure/reporting/mock/noop_reporters.dart';

part 'reporting_providers.g.dart';

/// クラッシュ・非致命的エラーの報告口。Mock モードでは何もしない実装を渡す。
/// Firebase が初期化されていない場合（Widget テストでアプリ全体を組み立てた場合など）も、
/// 報告のためにアプリを止めないよう、何もしない実装を渡す。
@Riverpod(keepAlive: true)
CrashReporter crashReporter(Ref ref) {
  if (kUseMocks || Firebase.apps.isEmpty) return const NoopCrashReporter();
  return FirebaseCrashReporter(FirebaseCrashlytics.instance);
}

/// 利用状況の記録口。Mock モード・Firebase が初期化されていない場合は何もしない実装を渡す。
@Riverpod(keepAlive: true)
AnalyticsReporter analyticsReporter(Ref ref) {
  if (kUseMocks || Firebase.apps.isEmpty) return const NoopAnalyticsReporter();
  return FirebaseAnalyticsReporter(FirebaseAnalytics.instance);
}
