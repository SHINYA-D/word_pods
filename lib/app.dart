import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_pods/core/app_lifecycle_observer.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/core/di/local_data_source_providers.dart';
import 'package:word_pods/core/di/sync_providers.dart';
import 'package:word_pods/core/router/router.dart';
import 'package:word_pods/core/theme/app_theme.dart';
import 'package:word_pods/core/utils/sync_trigger.dart';
import 'package:word_pods/presentation/legal/legal_consent_gate.dart';
import 'package:word_pods/presentation/legal/legal_consent_view_model.dart';
import 'package:word_pods/presentation/settings/account_deletion_gate.dart';
import 'package:word_pods/presentation/settings/account_deletion_view_model.dart';
import 'package:word_pods/presentation/settings/settings_view_model.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_gate.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_view_model.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  AppLifecycleObserver? _lifecycleObserver;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // 退会処理が途中で止まっていないか確認する（途中なら再開ダイアログを出す）
    ref.read(accountDeletionViewModelProvider.notifier).checkPending();
    // 他の端末で退会したアカウントがないか確認する（応答を待たずに起動する）
    _checkWithdrawnElsewhere(initial: true);

    final autoSync = ref.read(autoSyncServiceProvider);
    // オンライン復帰時に同期する
    autoSync.start();

    // 確認済みのユーザーでログイン済みになったら同期する（起動時にログイン済みだった場合・
    // メールアドレスが確認済みに変わった場合を含む）
    ref.listenManual(currentUserProvider, (previous, next) {
      if (shouldStartSync(previous, next)) autoSync.onSignedIn();
    }, fireImmediately: true);

    // resumed 時に同期する（前回の取得から5分以上たっていれば）
    _lifecycleObserver = AppLifecycleObserver(onResumed: () {
      autoSync.onResumed();
      _checkWithdrawnElsewhere();
      ref.read(legalConsentViewModelProvider.notifier).check();
    });
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    // オフラインからオンラインに戻ったら、規約への同意を判定する（オフラインの間は出さない）
    bool? lastOnline;
    try {
      _connectivitySubscription =
          ref.read(connectivityMonitorProvider).onStatusChanged().listen((online) {
        final wasOnline = lastOnline;
        lastOnline = online;
        if (online && wasOnline == false) {
          ref.read(legalConsentViewModelProvider.notifier).check();
        }
      });
    } catch (_) {
      // 接続状態を監視できなくても、起動時・復帰時の判定で補う
    }
  }

  Future<void> _checkWithdrawnElsewhere({bool initial = false}) async {
    final viewModel = ref.read(withdrawnElsewhereViewModelProvider.notifier);
    if (initial) await viewModel.initialize();
    try {
      await ref.read(authStateProvider.future);
    } catch (_) {
      // ログイン状態を読めなくても、ログアウト済みのアカウントの確認は行う
    }
    if (!mounted) return;
    // 規約への同意の判定は、強制ログアウトの記録を読み終えてから始める（退会の確認とは並行して行う）
    if (initial) {
      unawaited(ref.read(legalConsentViewModelProvider.notifier).start());
    }
    await viewModel.check();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    if (_lifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver!);
    }
    ref.read(autoSyncServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final user = ref.watch(currentUserProvider);
    final settingsAsync =
        user != null ? ref.watch(settingsViewModelProvider(user.id)) : null;
    final settings = settingsAsync?.value;
    final seedColor =
        AppTheme.colorThemes[settings?.colorTheme ?? 'indigo'] ??
            AppTheme.colorThemes['indigo']!;
    final isDark = settings?.darkMode ?? false;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'WordPods',
      theme: AppTheme.light(seedColor: seedColor),
      darkTheme: AppTheme.dark(seedColor: seedColor),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => AccountDeletionGate(
        router: router,
        child: WithdrawnElsewhereGate(
          router: router,
          child: LegalConsentGate(
            router: router,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
