import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:word_pods/domain/services/analytics_reporter.dart';

/// 仕様: docs/detailed_design/crash_reporting/crash_reporting.md 2.3.2・6.4
///
/// 見た画面の記録を開始する。開始した時点の画面を1回記録し、その後は表示中のルートが変わるたびに記録する。
/// 画面の名前はルートのパスのパターン（例: `/folder/:folderId`）で、ID などの値は入れない。
/// 直前の記録と同じ名前なら記録しない。ダイアログ・ボトムシートはパスを持たないため記録されない。
/// 戻り値を呼ぶと記録をやめる。
VoidCallback startScreenViewTracking(GoRouter router, AnalyticsReporter analytics) {
  String? last;
  void record() {
    final name = screenNameOf(router.routerDelegate.currentConfiguration);
    if (name.isEmpty || name == last) return;
    last = name;
    try {
      unawaited(analytics.logScreenView(name).catchError((Object _) {}));
    } catch (_) {
      // 記録の失敗で画面の切り替えを止めない（8章 Q7）
    }
  }

  record();
  router.routerDelegate.addListener(record);
  return () => router.routerDelegate.removeListener(record);
}

/// 表示中のルートのパスのパターン。`push` で積んだ画面が一番上にあれば、その画面のパターン。
@visibleForTesting
String screenNameOf(RouteMatchList configuration) {
  if (configuration.matches.isEmpty) return '';
  // シェル（ボトムナビ）の中で push した画面は、シェルの子の一番上に積まれる
  RouteMatchBase top = configuration.matches.last;
  while (top is ShellRouteMatch && top.matches.isNotEmpty) {
    top = top.matches.last;
  }
  if (top is ImperativeRouteMatch) return screenNameOf(top.matches);
  return configuration.fullPath;
}
