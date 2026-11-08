import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:word_pods/domain/services/analytics_reporter.dart';

/// [AnalyticsReporter] の Firebase Analytics 実装。SDK に渡すだけ。
class FirebaseAnalyticsReporter implements AnalyticsReporter {
  FirebaseAnalyticsReporter(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _analytics.setAnalyticsCollectionEnabled(enabled);

  @override
  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);
}
