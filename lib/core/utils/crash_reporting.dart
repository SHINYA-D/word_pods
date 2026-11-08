import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/services/analytics_reporter.dart';
import 'package:word_pods/domain/services/crash_reporter.dart';

/// 仕様: docs/detailed_design/crash_reporting/crash_reporting.md 2.3・2.3.1・2.3.3・6.1・6.3
///
/// 報告口の呼び出しは、失敗しても例外を外に出さない（記録の失敗でアプリを落とさない。8章 Q7）。

/// 収集の初期化。起動時に1回呼ぶ。
/// 同意を確認できるまでは送らないよう、収集は無効にする（有効にするのは [updateReportingCollection]）。
/// デバッグビルドでも Mock モードでもないときだけ、受け止められなかったエラーをクラッシュとして記録する。
/// そうでないときは、エラーの処理を置き換えない（今までどおりコンソールに出る）。
void initCrashReporting({
  required bool isDebug,
  required bool useMocks,
  required CrashReporter reporter,
  required AnalyticsReporter analytics,
}) {
  _guard(() => reporter.setCollectionEnabled(false));
  _guard(() => analytics.setCollectionEnabled(false));
  if (isDebug || useMocks) return;

  FlutterError.onError = (details) {
    _guard(() => reporter.recordError(
          _withoutUserData(details.exception),
          details.stack,
          fatal: true,
        ));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _guard(() => reporter.recordError(_withoutUserData(error), stack, fatal: true));
    return true;
  };
}

/// 同意の確認結果 [consented] に合わせて、クラッシュ情報・利用状況を集めるかを切り替える。
/// デバッグビルドと Mock モードでは、同意していても集めない。
void updateReportingCollection({
  required bool isDebug,
  required bool useMocks,
  required bool consented,
  required CrashReporter reporter,
  required AnalyticsReporter analytics,
}) {
  final enabled = !isDebug && !useMocks && consented;
  _guard(() => reporter.setCollectionEnabled(enabled));
  _guard(() => analytics.setCollectionEnabled(enabled));
}

/// SQLite のエラーの代わりに報告するエラー。SQLite の結果コードだけを持つ。
///
/// sqflite のエラー文には SQL と引数（登録した単語など）が入るため、そのまま報告しない。
@visibleForTesting
class ReportedDatabaseError implements Exception {
  const ReportedDatabaseError(this.resultCode);

  final int? resultCode;

  @override
  String toString() => 'DatabaseException(resultCode: ${resultCode ?? 'unknown'})';
}

/// 報告するエラーから、利用者のデータが入りうる内容を取り除く。
Object _withoutUserData(Object error) =>
    error is DatabaseException ? ReportedDatabaseError(error.getResultCode()) : error;

/// ログイン中のユーザー [user] を、以後の記録に付ける識別子にする。未ログインなら付けない（空文字）。
/// メールアドレス・表示名は付けない。
void updateCrashUserIdentifier(CrashReporter reporter, AppUser? user) {
  _guard(() => reporter.setUserIdentifier(user?.id ?? ''));
}

/// 想定外の例外 [error] を非致命的エラーとして報告し、`UnknownFailure` にして返す。
/// Repository が例外を `UnknownFailure` に変えるときは、必ずこれを通す（報告の足し忘れを防ぐため）。
Failure reportUnknownFailure(
  CrashReporter? reporter,
  Object error,
  StackTrace stack, {
  String? message,
}) {
  reportNonFatal(reporter, error, stack);
  return Failure.unknown(message ?? error.toString());
}

/// 想定外の例外 [error] を非致命的エラーとして報告する。
void reportNonFatal(CrashReporter? reporter, Object error, StackTrace stack) {
  if (reporter == null) return;
  _guard(() => reporter.recordError(_withoutUserData(error), stack, fatal: false));
}

/// 同期の失敗のうち、報告しない（想定内の）ものか。
/// 通信に関するもの（時間切れ・接続できない・Firestore が一時的に使えない）、ログイン切れ、
/// 混雑や中断による一時的な失敗は、次の同期でやり直されるため報告しない。
bool isExpectedSyncError(Object error) {
  if (error is TimeoutException || error is SocketException) return true;
  if (error is FirebaseException) return _expectedFirestoreCodes.contains(error.code);
  return false;
}

const _expectedFirestoreCodes = {
  'unavailable',
  'deadline-exceeded',
  'unauthenticated',
  'aborted',
  'resource-exhausted',
  'cancelled',
};

/// 報告口の呼び出しを、同期・非同期どちらの失敗も外に出さずに行う。
void _guard(Future<void> Function() call) {
  try {
    unawaited(call().catchError((Object _) {}));
  } catch (_) {
    // 記録の失敗は無視する（8章 Q7）
  }
}
