import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/core/di/sync_status_providers.dart';
import 'package:word_pods/core/utils/auth_redirect.dart';
import 'package:word_pods/domain/entities/word.dart';
import 'package:word_pods/presentation/account/account_page.dart';
import 'package:word_pods/presentation/auth/login/login_page.dart';
import 'package:word_pods/presentation/auth/password_reset/password_reset_page.dart';
import 'package:word_pods/presentation/auth/sign_up/sign_up_page.dart';
import 'package:word_pods/presentation/auth/splash/splash_page.dart';
import 'package:word_pods/presentation/auth/verify_email/verify_email_page.dart';
import 'package:word_pods/presentation/home/home_page.dart';
import 'package:word_pods/presentation/result/result_page.dart';
import 'package:word_pods/presentation/sample/sample_page.dart';
import 'package:word_pods/presentation/settings/account_deletion_state.dart';
import 'package:word_pods/presentation/settings/account_deletion_view_model.dart';
import 'package:word_pods/presentation/settings/settings_page.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_view_model.dart';
import 'package:word_pods/presentation/shell/shell_page.dart';
import 'package:word_pods/presentation/shell/shell_view_model.dart';
import 'package:word_pods/presentation/flashcard_mode/flashcard_mode_page.dart';
import 'package:word_pods/presentation/flashcard_mode/flashcard_mode_result_page.dart';
import 'package:word_pods/presentation/flashcard_mode/flashcard_mode_settings_page.dart';
import 'package:word_pods/presentation/word/word_create_page.dart';
import 'package:word_pods/presentation/word/word_edit_page.dart';
import 'package:word_pods/presentation/word/word_list_page.dart';

part 'router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final goRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;
      // 強制ログアウトした uid は、Firebase 上でログイン中でもログインしていないものとして扱う
      final user = authState.value;
      final forced = ref.read(withdrawnElsewhereViewModelProvider).forcedUserId;
      final loc = state.matchedLocation;
      final target = authRedirect(
        isLoggedIn: user != null && user.id != forced,
        isEmailVerified: user?.emailVerified ?? false,
        location: loc,
        // ログイン直後の初回同期中・確認メールの送信完了ダイアログの表示中は、ログイン前の画面から移さない
        isHolding: ref.read(authSyncInProgressProvider),
        isWithdrawn: ref.read(accountDeletionViewModelProvider).phase ==
            AccountDeletionPhase.completed,
      );
      if (target != null) return target;
      // サンプル画面は開発者だけ。判定の読み込み中・失敗時も開発者でないとして扱う
      if (loc == '/sample' && !ref.read(isDeveloperProvider)) return '/home';
      return null;
    },
    routes: $appRoutes,
  );

  // 認証状態・同期状態が変わったら redirect を再評価させる
  ref.listen(authStateProvider, (_, _) => goRouter.refresh());
  ref.listen(authSyncInProgressProvider, (_, _) => goRouter.refresh());
  ref.listen(isDeveloperProvider, (_, _) => goRouter.refresh());
  ref.listen(
    withdrawnElsewhereViewModelProvider.select((s) => s.forcedUserId),
    (_, _) => goRouter.refresh(),
  );

  return goRouter;
}

class FlashcardModeRouteExtra {
  const FlashcardModeRouteExtra({
    required this.words,
    required this.shuffle,
    required this.folderName,
    required this.userId,
  });

  final List<Word> words;
  final bool shuffle;
  final String folderName;
  final String userId;
}

// ─── Auth / スプラッシュ ──────────────────────────────────────────

@immutable
@TypedGoRoute<SplashRoute>(path: '/')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SplashPage();
}

@immutable
@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginPage();
}

@immutable
@TypedGoRoute<SignUpRoute>(path: '/sign-up')
class SignUpRoute extends GoRouteData with $SignUpRoute {
  const SignUpRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SignUpPage();
}

@immutable
@TypedGoRoute<PasswordResetRoute>(path: '/password-reset')
class PasswordResetRoute extends GoRouteData with $PasswordResetRoute {
  const PasswordResetRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const PasswordResetPage();
}

@immutable
@TypedGoRoute<VerifyEmailRoute>(path: '/verify-email')
class VerifyEmailRoute extends GoRouteData with $VerifyEmailRoute {
  const VerifyEmailRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const VerifyEmailPage();
}

// ─── 設定から開く画面（BottomNav なし）─────────────────────────────

@immutable
@TypedGoRoute<AccountRoute>(path: '/account')
class AccountRoute extends GoRouteData with $AccountRoute {
  const AccountRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const AccountPage();
}

// ─── テスト関連（BottomNav なし）───────────────────────────────────

@immutable
@TypedGoRoute<FlashcardModeSettingsRoute>(path: '/test-settings/:folderId')
class FlashcardModeSettingsRoute extends GoRouteData with $FlashcardModeSettingsRoute {
  const FlashcardModeSettingsRoute({required this.folderId, this.$extra});

  final String folderId;
  final String? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return FlashcardModeSettingsPage(folderId: folderId, folderName: $extra ?? '');
  }
}

@immutable
@TypedGoRoute<FlashcardModeRoute>(path: '/test/:folderId')
class FlashcardModeRoute extends GoRouteData with $FlashcardModeRoute {
  const FlashcardModeRoute({required this.folderId, required this.$extra});

  final String folderId;
  final FlashcardModeRouteExtra $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return FlashcardModePage(
      folderId: folderId,
      words: $extra.words,
      shuffle: $extra.shuffle,
      folderName: $extra.folderName,
      userId: $extra.userId,
    );
  }
}

@immutable
@TypedGoRoute<WordEditRoute>(path: '/word-edit/:folderId')
class WordEditRoute extends GoRouteData with $WordEditRoute {
  const WordEditRoute({required this.folderId, required this.$extra});

  final String folderId;
  final Word $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return WordEditPage(folderId: folderId, word: $extra);
  }
}

@immutable
@TypedGoRoute<WordCreateRoute>(path: '/word-create/:folderId')
class WordCreateRoute extends GoRouteData with $WordCreateRoute {
  const WordCreateRoute({required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return WordCreatePage(folderId: folderId);
  }
}

@immutable
@TypedGoRoute<FlashcardModeResultRoute>(path: '/flashcard-result')
class FlashcardModeResultRoute extends GoRouteData with $FlashcardModeResultRoute {
  const FlashcardModeResultRoute({required this.correctCount, required this.total});

  final int correctCount;
  final int total;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return FlashcardModeResultPage(correctCount: correctCount, total: total);
  }
}

// ─── BottomNav シェル ──────────────────────────────────────────────

@immutable
@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<HomeRoute>(path: '/home'),
    TypedGoRoute<FolderRoute>(path: '/folder/:folderId'),
    TypedGoRoute<ResultsRoute>(path: '/results'),
    TypedGoRoute<SampleRoute>(path: '/sample'),
    TypedGoRoute<SettingsRoute>(path: '/settings'),
  ],
)
class AppShellRoute extends ShellRouteData {
  const AppShellRoute();

  static final GlobalKey<NavigatorState> $navigatorKey = _shellNavigatorKey;

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    Widget navigator,
  ) {
    return Consumer(
      builder: (context, ref, _) => ShellPage(
        showSampleTab: ref.watch(isDeveloperProvider),
        child: navigator,
      ),
    );
  }
}

@immutable
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

@immutable
class FolderRoute extends GoRouteData with $FolderRoute {
  const FolderRoute({required this.folderId, this.$extra});

  final String folderId;
  final String? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return WordListPage(folderId: folderId, folderName: $extra ?? '');
  }
}

@immutable
class ResultsRoute extends GoRouteData with $ResultsRoute {
  const ResultsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ResultPage();
}

@immutable
class SampleRoute extends GoRouteData with $SampleRoute {
  const SampleRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SamplePage();
}

@immutable
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SettingsPage();
}
