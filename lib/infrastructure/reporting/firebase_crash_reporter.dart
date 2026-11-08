import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:word_pods/domain/services/crash_reporter.dart';

/// [CrashReporter] の Crashlytics 実装。SDK に渡すだけ。
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);

  @override
  Future<void> recordError(Object error, StackTrace? stack, {required bool fatal}) =>
      _crashlytics.recordError(error, stack, fatal: fatal);

  @override
  Future<void> setUserIdentifier(String id) => _crashlytics.setUserIdentifier(id);
}
