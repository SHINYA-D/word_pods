// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $splashRoute,
  $loginRoute,
  $signUpRoute,
  $passwordResetRoute,
  $verifyEmailRoute,
  $accountRoute,
  $flashcardModeSettingsRoute,
  $flashcardModeRoute,
  $wordEditRoute,
  $wordCreateRoute,
  $flashcardModeResultRoute,
  $appShellRoute,
];

RouteBase get $splashRoute => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $SplashRoute._fromState,
);

mixin $SplashRoute on GoRouteData {
  static SplashRoute _fromState(GoRouterState state) => const SplashRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $loginRoute => GoRouteData.$route(
  path: '/login',
  hasOverriddenOnExit: false,
  factory: $LoginRoute._fromState,
);

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location('/login');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $signUpRoute => GoRouteData.$route(
  path: '/sign-up',
  hasOverriddenOnExit: false,
  factory: $SignUpRoute._fromState,
);

mixin $SignUpRoute on GoRouteData {
  static SignUpRoute _fromState(GoRouterState state) => const SignUpRoute();

  @override
  String get location => GoRouteData.$location('/sign-up');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $passwordResetRoute => GoRouteData.$route(
  path: '/password-reset',
  hasOverriddenOnExit: false,
  factory: $PasswordResetRoute._fromState,
);

mixin $PasswordResetRoute on GoRouteData {
  static PasswordResetRoute _fromState(GoRouterState state) =>
      const PasswordResetRoute();

  @override
  String get location => GoRouteData.$location('/password-reset');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $verifyEmailRoute => GoRouteData.$route(
  path: '/verify-email',
  hasOverriddenOnExit: false,
  factory: $VerifyEmailRoute._fromState,
);

mixin $VerifyEmailRoute on GoRouteData {
  static VerifyEmailRoute _fromState(GoRouterState state) =>
      const VerifyEmailRoute();

  @override
  String get location => GoRouteData.$location('/verify-email');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $accountRoute => GoRouteData.$route(
  path: '/account',
  hasOverriddenOnExit: false,
  factory: $AccountRoute._fromState,
);

mixin $AccountRoute on GoRouteData {
  static AccountRoute _fromState(GoRouterState state) => const AccountRoute();

  @override
  String get location => GoRouteData.$location('/account');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $flashcardModeSettingsRoute => GoRouteData.$route(
  path: '/test-settings/:folderId',
  hasOverriddenOnExit: false,
  factory: $FlashcardModeSettingsRoute._fromState,
);

mixin $FlashcardModeSettingsRoute on GoRouteData {
  static FlashcardModeSettingsRoute _fromState(GoRouterState state) =>
      FlashcardModeSettingsRoute(
        folderId: state.pathParameters['folderId']!,
        $extra: state.extra as String?,
      );

  FlashcardModeSettingsRoute get _self => this as FlashcardModeSettingsRoute;

  @override
  String get location => GoRouteData.$location(
    '/test-settings/${Uri.encodeComponent(_self.folderId)}',
  );

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $flashcardModeRoute => GoRouteData.$route(
  path: '/test/:folderId',
  hasOverriddenOnExit: false,
  factory: $FlashcardModeRoute._fromState,
);

mixin $FlashcardModeRoute on GoRouteData {
  static FlashcardModeRoute _fromState(GoRouterState state) =>
      FlashcardModeRoute(
        folderId: state.pathParameters['folderId']!,
        $extra: state.extra as FlashcardModeRouteExtra,
      );

  FlashcardModeRoute get _self => this as FlashcardModeRoute;

  @override
  String get location =>
      GoRouteData.$location('/test/${Uri.encodeComponent(_self.folderId)}');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $wordEditRoute => GoRouteData.$route(
  path: '/word-edit/:folderId',
  hasOverriddenOnExit: false,
  factory: $WordEditRoute._fromState,
);

mixin $WordEditRoute on GoRouteData {
  static WordEditRoute _fromState(GoRouterState state) => WordEditRoute(
    folderId: state.pathParameters['folderId']!,
    $extra: state.extra as Word,
  );

  WordEditRoute get _self => this as WordEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/word-edit/${Uri.encodeComponent(_self.folderId)}',
  );

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $wordCreateRoute => GoRouteData.$route(
  path: '/word-create/:folderId',
  hasOverriddenOnExit: false,
  factory: $WordCreateRoute._fromState,
);

mixin $WordCreateRoute on GoRouteData {
  static WordCreateRoute _fromState(GoRouterState state) =>
      WordCreateRoute(folderId: state.pathParameters['folderId']!);

  WordCreateRoute get _self => this as WordCreateRoute;

  @override
  String get location => GoRouteData.$location(
    '/word-create/${Uri.encodeComponent(_self.folderId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $flashcardModeResultRoute => GoRouteData.$route(
  path: '/flashcard-result',
  hasOverriddenOnExit: false,
  factory: $FlashcardModeResultRoute._fromState,
);

mixin $FlashcardModeResultRoute on GoRouteData {
  static FlashcardModeResultRoute _fromState(GoRouterState state) =>
      FlashcardModeResultRoute(
        correctCount: int.parse(state.uri.queryParameters['correct-count']!),
        total: int.parse(state.uri.queryParameters['total']!),
      );

  FlashcardModeResultRoute get _self => this as FlashcardModeResultRoute;

  @override
  String get location => GoRouteData.$location(
    '/flashcard-result',
    queryParams: {
      'correct-count': _self.correctCount.toString(),
      'total': _self.total.toString(),
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $appShellRoute => ShellRouteData.$route(
  navigatorKey: AppShellRoute.$navigatorKey,
  factory: $AppShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/home',
      hasOverriddenOnExit: false,
      factory: $HomeRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/folder/:folderId',
      hasOverriddenOnExit: false,
      factory: $FolderRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/results',
      hasOverriddenOnExit: false,
      factory: $ResultsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/sample',
      hasOverriddenOnExit: false,
      factory: $SampleRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings',
      hasOverriddenOnExit: false,
      factory: $SettingsRoute._fromState,
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/home');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FolderRoute on GoRouteData {
  static FolderRoute _fromState(GoRouterState state) => FolderRoute(
    folderId: state.pathParameters['folderId']!,
    $extra: state.extra as String?,
  );

  FolderRoute get _self => this as FolderRoute;

  @override
  String get location =>
      GoRouteData.$location('/folder/${Uri.encodeComponent(_self.folderId)}');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

mixin $ResultsRoute on GoRouteData {
  static ResultsRoute _fromState(GoRouterState state) => const ResultsRoute();

  @override
  String get location => GoRouteData.$location('/results');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SampleRoute on GoRouteData {
  static SampleRoute _fromState(GoRouterState state) => const SampleRoute();

  @override
  String get location => GoRouteData.$location('/sample');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(router)
final routerProvider = RouterProvider._();

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'0dfcc5a60f6955f93404edb043064c57b81948e3';
