import 'package:word_pods/domain/services/analytics_reporter.dart';
import 'package:word_pods/domain/services/crash_reporter.dart';

/// Mock モード（`USE_MOCKS=true`）用。何もしない。
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> recordError(Object error, StackTrace? stack, {required bool fatal}) async {}

  @override
  Future<void> setUserIdentifier(String id) async {}
}

/// Mock モード（`USE_MOCKS=true`）用。何もしない。
class NoopAnalyticsReporter implements AnalyticsReporter {
  const NoopAnalyticsReporter();

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> logScreenView(String screenName) async {}
}
