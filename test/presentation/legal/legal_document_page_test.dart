import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/app_lifecycle_observer.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/core/di/local_data_source_providers.dart';
import 'package:word_pods/core/di/repository_providers.dart';
import 'package:word_pods/core/di/sync_providers.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/core/router/router.dart';
import 'package:word_pods/domain/entities/account_deletion_request.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/domain/repositories/account_deletion_repository.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/repositories/legal_repository.dart';
import 'package:word_pods/domain/repositories/sync_repository.dart';
import 'package:word_pods/infrastructure/data_sources/network/connectivity_monitor.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_flashcard_result_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_folder_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_settings_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_word_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_reauthentication_repository.dart';
import 'package:word_pods/presentation/auth/login/login_page.dart';
import 'package:word_pods/presentation/auth/login/login_view_model.dart';
import 'package:word_pods/presentation/legal/legal_consent_gate.dart';
import 'package:word_pods/presentation/legal/legal_consent_view_model.dart';
import 'package:word_pods/presentation/legal/legal_document_page.dart';
import 'package:word_pods/presentation/settings/account_deletion_gate.dart';
import 'package:word_pods/presentation/settings/account_deletion_view_model.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_gate.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_view_model.dart';
import 'package:word_pods/core/di/provider_retry.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_email_verification_repository.dart';

/// 仕様書（docs/detailed_design/legal_consent/legal_consent.md）3章の
/// 同意ダイアログ・閲覧画面・設定画面の「このアプリについて」のテスト。期待値は仕様書から作っている。
///
/// 同意ダイアログは画面ではなくゲートなので、lib/app.dart と同じ配線（本物のルーター +
/// AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate、起動時の確認、復帰時の確認）の
/// テスト用アプリで確かめる。app.dart を変えたら [_TestApp] も更新する。

const _userA = AppUser(id: 'A', email: 'a@example.com');
const _userB = AppUser(id: 'B', email: 'b@example.com');

const _config = LegalConfig(
  termsVersion: '2026-01-01',
  privacyVersion: '2026-01-01',
  termsUrl: 'https://example.com/terms',
  privacyUrl: 'https://example.com/privacy',
);

const _matching = LegalConsents(
  termsVersion: '2026-01-01',
  privacyVersion: '2026-01-01',
);

const Failure _network = Failure.network();
const Failure _auth = Failure.auth();
const Failure _notFound = Failure.notFound();
const Failure _unknown = Failure.unknown('x');

const _termsUrl = 'https://example.com/terms';
const _privacyUrl = 'https://example.com/privacy';

/// 仕様 ID を付けたテスト。テスト名は「○○の場合、△△になる [ID]」。
void spec(String id, String name, Future<void> Function(WidgetTester tester) body) =>
    testWidgets('$name [$id]', body);

// ─── Fake ───

class _FakeLegalRepository implements LegalRepository {
  /// 現行の規約の情報
  LegalConfig cfg = _config;
  Failure? configFailure;
  Completer<void>? configGate;

  Either<Failure, LegalConsents> consents = const Right(LegalConsents());

  Either<Failure, LegalAcceptResult> acceptResult =
      const Right(LegalAcceptResult.accepted);
  final acceptQueue = <Either<Failure, LegalAcceptResult>>[];
  Completer<void>? acceptGate;

  int fetchConfigCalls = 0;
  final acceptCalls = <({String? terms, String? privacy})>[];

  @override
  Future<Either<Failure, LegalConfig>> fetchLegalConfig() async {
    fetchConfigCalls++;
    final gate = configGate;
    if (gate != null) await gate.future;
    final f = configFailure;
    return f != null ? Left(f) : Right(cfg);
  }

  @override
  Future<Either<Failure, LegalConsents>> fetchConsents(String userId) async =>
      consents;

  @override
  Future<Either<Failure, LegalAcceptResult>> accept({
    String? termsVersion,
    String? privacyVersion,
  }) async {
    acceptCalls.add((terms: termsVersion, privacy: privacyVersion));
    final gate = acceptGate;
    if (gate != null) await gate.future;
    if (acceptQueue.isNotEmpty) return acceptQueue.removeAt(0);
    return acceptResult;
  }
}

/// ログイン状態を持つ Fake。signOut の結果と応答待ちを制御でき、ログイン成功・解除を authStateChanges に流す。
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  AppUser? user;

  /// ログイン（メール・Google・新規登録）が成功したときのユーザー
  AppUser signInUser = _userA;

  Failure? signOutFailure;
  Completer<void>? signOutGate;
  int signOutCount = 0;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield user;
    yield* _controller.stream;
  }

  /// Firebase のログイン状態を変える（null は解除）。
  void emitUser(AppUser? next) {
    user = next;
    _controller.add(next);
  }

  Either<Failure, AppUser> _signedIn() {
    emitUser(signInUser);
    return Right(signInUser);
  }

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      _signedIn();

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
  }) async =>
      _signedIn();

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async => _signedIn();

  @override
  Future<Either<Failure, Unit>> signOut() async {
    signOutCount++;
    final gate = signOutGate;
    if (gate != null) await gate.future;
    final f = signOutFailure;
    if (f != null) return Left(f);
    emitUser(null);
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// 退会処理の記録・退会済みの記録・強制ログアウトの記録の Fake。
class _FakeAccountDeletionRepository implements AccountDeletionRepository {
  AccountDeletionRequest? record;
  Completer<void>? requestGate;

  /// 退会済みの記録がある uid
  final Set<String> withdrawn = {};

  /// 強制ログアウトの記録の uid
  String? forcedUid;

  final Map<String, StreamController<Either<Failure, bool>>> _watchers = {};

  StreamController<Either<Failure, bool>> _watcher(String userId) =>
      _watchers.putIfAbsent(
          userId, () => StreamController<Either<Failure, bool>>.broadcast());

  /// 監視に「退会済みになった」と通知する（記録も付ける）。
  void emitWithdrawn(String userId) {
    withdrawn.add(userId);
    _watcher(userId).add(const Right(true));
  }

  @override
  Future<Either<Failure, Option<AccountDeletionRequest>>> findPending() async =>
      Right(optionOf(record));

  @override
  Future<Either<Failure, Unit>> markRequested(String userId) async {
    record = AccountDeletionRequest(
      userId: userId,
      status: AccountDeletionStatus.requested,
      updatedAt: DateTime(2026, 10, 3),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> markServerDone(String userId) async {
    record = AccountDeletionRequest(
      userId: userId,
      status: AccountDeletionStatus.serverDone,
      updatedAt: DateTime(2026, 10, 3),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> clearRequest(String userId) async {
    record = null;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> requestServerDeletion() async {
    final gate = requestGate;
    if (gate != null) await gate.future;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteLocalData(String userId) async {
    record = null;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<String>>> findLocalUserIds() async =>
      const Right([]);

  @override
  Future<Either<Failure, bool>> isWithdrawnOnServer(String userId) async =>
      Right(withdrawn.contains(userId));

  @override
  Stream<Either<Failure, bool>> watchWithdrawn(String userId) =>
      _watcher(userId).stream;

  @override
  Future<Either<Failure, Unit>> deleteLocalDataOfUsers(
          List<String> userIds) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> markForcedSignOut(String userId) async {
    forcedUid = userId;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Option<String>>> findForcedSignOut() async =>
      Right(optionOf(forcedUid));

  @override
  Future<Either<Failure, Unit>> clearForcedSignOut(String userId) async {
    if (forcedUid == userId) forcedUid = null;
    return const Right(unit);
  }
}

/// WebView の差し替え。builder に渡った url と attempt を記録し、読み込みの通知をテストから呼べる。
class _FakeWebView {
  final loads = <({String url, int attempt})>[];
  LegalWebViewCallbacks? callbacks;

  Widget build({
    required String url,
    required int attempt,
    required LegalWebViewCallbacks callbacks,
  }) {
    if (!loads.any((l) => l.url == url && l.attempt == attempt)) {
      loads.add((url: url, attempt: attempt));
    }
    this.callbacks = callbacks;
    return SizedBox.expand(key: ValueKey('webview-$url-$attempt'));
  }

  /// その URL の読み込みが指示された回数（attempt ごとに1回）
  int loadCount(String url) => loads.where((l) => l.url == url).length;
}

/// 接続状態を流せる Fake。onStatusChanged に流した値を lib/app.dart と同じ監視が受け取る。
class _FakeConnectivity implements ConnectivityMonitor {
  final _controller = StreamController<bool>.broadcast();

  void emit(bool online) => _controller.add(online);

  @override
  Future<bool> isOnline() async => true;

  @override
  Stream<bool> onStatusChanged() => _controller.stream;
}

/// 初回の同期の Fake。syncGate で完了を止め、syncError で失敗させられる。
class _FakeSyncRepository implements SyncRepository {
  Completer<void>? syncGate;
  Object? syncError;

  @override
  Future<void> syncRemoteToLocalOnLogin() async {
    final gate = syncGate;
    if (gate != null) await gate.future;
    final e = syncError;
    if (e != null) throw e;
  }

  @override
  Future<int> pushBeforeSignOut() async => 0;

  @override
  Future<void> waitUntilIdle() async {}
}

class _Env {
  _Env(AppUser? user) : auth = _FakeAuthRepository(user);

  final _FakeAuthRepository auth;
  final deletion = _FakeAccountDeletionRepository();
  final legal = _FakeLegalRepository();
  final web = _FakeWebView();
  final connectivity = _FakeConnectivity();
  final sync = _FakeSyncRepository();
  late ProviderContainer container;

  String get path => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .path;

  /// 現行の規約の情報を改定する。
  void bump({String? terms, String? privacy, String? termsUrl}) {
    legal.cfg = LegalConfig(
      termsVersion: terms ?? legal.cfg.termsVersion,
      privacyVersion: privacy ?? legal.cfg.privacyVersion,
      termsUrl: termsUrl ?? legal.cfg.termsUrl,
      privacyUrl: legal.cfg.privacyUrl,
    );
  }
}

/// lib/app.dart と同じ構成（Gate の重ね方・起動時の確認・resumed の確認）のテスト用アプリ。
class _TestApp extends ConsumerStatefulWidget {
  const _TestApp();

  @override
  ConsumerState<_TestApp> createState() => _TestAppState();
}

class _TestAppState extends ConsumerState<_TestApp> {
  AppLifecycleObserver? _observer;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    ref.read(accountDeletionViewModelProvider.notifier).checkPending();
    _checkWithdrawnElsewhere(initial: true);
    _observer = AppLifecycleObserver(onResumed: () {
      _checkWithdrawnElsewhere();
      ref.read(legalConsentViewModelProvider.notifier).check();
    });
    WidgetsBinding.instance.addObserver(_observer!);

    // オフラインからオンラインに戻ったら判定する（lib/app.dart と同じ）
    bool? lastOnline;
    _connectivitySubscription =
        ref.read(connectivityMonitorProvider).onStatusChanged().listen((online) {
      final wasOnline = lastOnline;
      lastOnline = online;
      if (online && wasOnline == false) {
        ref.read(legalConsentViewModelProvider.notifier).check();
      }
    });
  }

  Future<void> _checkWithdrawnElsewhere({bool initial = false}) async {
    final viewModel = ref.read(withdrawnElsewhereViewModelProvider.notifier);
    if (initial) await viewModel.initialize();
    try {
      await ref.read(authStateProvider.future);
    } catch (_) {}
    if (!mounted) return;
    if (initial) {
      unawaited(ref.read(legalConsentViewModelProvider.notifier).start());
    }
    await viewModel.check();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(_observer!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
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

// ─── 操作・確認の道具 ───

/// ローディングの無限アニメーションがあっても進められるよう、pumpAndSettle の代わりに使う。
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

/// アプリがフォアグラウンドに戻った（resumed）。
Future<void> _resume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await _settle(tester);
}

/// アプリがバックグラウンドに移った。
Future<void> _background(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await _settle(tester);
}

/// オフラインになってからオンラインに戻った。
Future<void> _goOfflineThenOnline(WidgetTester tester, _Env env) async {
  env.connectivity.emit(false);
  await _settle(tester);
  env.connectivity.emit(true);
  await _settle(tester);
}

/// ログイン画面でメールアドレスとパスワードを入れて「ログイン」をタップする。
Future<void> _loginWithEmail(WidgetTester t) async {
  await t.enterText(find.byType(TextFormField).at(0), 'a@example.com');
  await t.enterText(find.byType(TextFormField).at(1), 'password1');
  await _tap(t, find.widgetWithText(FilledButton, 'ログイン'));
}

/// ログイン画面から Google でログインする。
/// 「Google でログイン」ボタンは App Store 審査対応（Guideline 4.8）で一時的に画面から外しているため
/// （docs/TODO.md の TODO-006）、ボタンが押されたときと同じく ViewModel の signInWithGoogle を呼ぶ。
/// ボタンを戻したら、`_tap(t, find.text('Google でログイン'))` に戻す。
Future<void> _signInWithGoogle(WidgetTester t) async {
  final container = ProviderScope.containerOf(t.element(find.byType(LoginPage)));
  unawaited(container.read(loginViewModelProvider.notifier).signInWithGoogle());
  await _settle(t);
}

/// 戻る操作（Android の戻るボタン相当）。
Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await _settle(tester);
}

/// ダイアログの外側（バリア）をタップする。
Future<void> _tapOutside(WidgetTester tester) async {
  await tester.tapAt(const Offset(5, 5));
  await _settle(tester);
}

/// アプリを起動する。スプラッシュの最低表示時間（2秒）を進めて、最初の画面まで進める。
Future<_Env> _launch(
  WidgetTester tester, {
  AppUser? user = _userA,
  void Function(_Env env)? configure,
  Size size = const Size(800, 2400),
  bool skipSplash = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final env = _Env(user);
  configure?.call(env);
  await tester.pumpWidget(ProviderScope(
    retry: noRetry,
    overrides: [
      authRepositoryProvider.overrideWithValue(env.auth),
      // 新規登録の後の確認メールの送信・確認状態の問い合わせは成功する
      emailVerificationRepositoryProvider
          .overrideWithValue(MockEmailVerificationRepository(env.auth)),
      accountDeletionRepositoryProvider.overrideWithValue(env.deletion),
      // 退会の前の本人確認は成功するものとする（退会を始めるテストのため）
      reauthenticationRepositoryProvider
          .overrideWithValue(MockReauthenticationRepository()),
      legalRepositoryProvider.overrideWithValue(env.legal),
      legalWebViewBuilderProvider.overrideWithValue(env.web.build),
      folderRepositoryProvider.overrideWithValue(MockFolderRepository()),
      wordRepositoryProvider.overrideWithValue(MockWordRepository()),
      settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      flashcardResultRepositoryProvider
          .overrideWithValue(MockFlashcardResultRepository()),
      syncRepositoryProvider.overrideWithValue(env.sync),
      connectivityMonitorProvider.overrideWithValue(env.connectivity),
    ],
    child: const _TestApp(),
  ));
  env.container =
      ProviderScope.containerOf(tester.element(find.byType(_TestApp)));
  await tester.pump();
  if (skipSplash) await tester.pump(const Duration(seconds: 2));
  await _settle(tester);
  return env;
}

/// 同意済みの版数が現行の版数と一致する状態にする。
void _matched(_Env e) => e.legal.consents = const Right(_matching);

AccountDeletionRequest _record(AccountDeletionStatus status) =>
    AccountDeletionRequest(
      userId: 'A',
      status: status,
      updatedAt: DateTime(2026, 10, 12),
    );

const _termsLabel = '利用規約に同意する';
const _privacyLabel = 'プライバシーポリシーに同意する';

final _title = find.text('同意のお願い');
final _body = find.text(
    'WordPods を利用するには、次の内容への同意が必要です。リンクから内容を確認し、チェックを入れてください。');
final _agree = find.widgetWithText(FilledButton, '同意する');
final _logout = find.widgetWithText(TextButton, 'ログアウト');
final _termsLink = find.widgetWithText(TextButton, '利用規約を読む');
final _privacyLink = find.widgetWithText(TextButton, 'プライバシーポリシーを読む');
final _msgSendFailed = find.text('同意を送信できませんでした。もう一度お試しください。');
final _msgOutdated = find.text('内容が更新されました。もう一度ご確認のうえ、同意してください。');
final _msgSignOutFailed = find.text('ログアウトできませんでした。もう一度お試しください。');
final _networkTitle = find.text('通信エラー');
final _networkBody = find.text('通信に失敗しました。\nログイン画面に戻ります。');
final _noticeTitle = find.text('アカウントが削除されました');
final _retryTitle = find.text('退会処理が完了していません');
final _document = find.byType(LegalDocumentPage);
final _spinner = find.byType(CircularProgressIndicator);
const _loadFailedText = 'ページを読み込めませんでした。通信環境を確認して、もう一度お試しください。';
const _openFailedText = 'ページを開けませんでした。通信環境を確認して、もう一度お試しください。';

Finder _row(String label) => find.widgetWithText(CheckboxListTile, label);
Finder _box(String label) =>
    find.descendant(of: _row(label), matching: find.byType(Checkbox));

bool _isChecked(WidgetTester t, String label) =>
    t.widget<Checkbox>(_box(label)).value ?? false;
bool _boxEnabled(WidgetTester t, String label) =>
    t.widget<Checkbox>(_box(label)).onChanged != null;
bool _agreeEnabled(WidgetTester t) =>
    t.widget<FilledButton>(_agree).onPressed != null;
bool _logoutEnabled(WidgetTester t) =>
    t.widget<TextButton>(_logout).onPressed != null;
bool _linkEnabled(WidgetTester t, Finder link) =>
    t.widget<TextButton>(link).onPressed != null;

Future<void> _check(WidgetTester t, String label) => _tap(t, _box(label));
Future<void> _checkBoth(WidgetTester t) async {
  await _check(t, _termsLabel);
  await _check(t, _privacyLabel);
}

Future<void> _tapAgree(WidgetTester t) => _tap(t, _agree);
Future<void> _tapLogout(WidgetTester t) => _tap(t, _logout);

void _expectBothRows() {
  expect(_termsLink, findsOneWidget);
  expect(_row(_termsLabel), findsOneWidget);
  expect(_privacyLink, findsOneWidget);
  expect(_row(_privacyLabel), findsOneWidget);
}

void _expectOnlyTerms() {
  expect(_termsLink, findsOneWidget);
  expect(_row(_termsLabel), findsOneWidget);
  expect(_privacyLink, findsNothing);
  expect(_row(_privacyLabel), findsNothing);
}

void _expectOnlyPrivacy() {
  expect(_privacyLink, findsOneWidget);
  expect(_row(_privacyLabel), findsOneWidget);
  expect(_termsLink, findsNothing);
  expect(_row(_termsLabel), findsNothing);
}

void _expectNoDialogs() {
  expect(_title, findsNothing);
  expect(_networkTitle, findsNothing);
  expect(find.byType(AlertDialog), findsNothing);
}

void _expectDocument(String title) {
  expect(_document, findsOneWidget);
  expect(find.descendant(of: _document, matching: find.text(title)),
      findsOneWidget);
  expect(find.descendant(of: _document, matching: find.byType(BackButton)),
      findsOneWidget);
}

Future<void> _tapDocBack(WidgetTester t) => _tap(
    t, find.descendant(of: _document, matching: find.byType(BackButton)));

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Future<void> _goSettings(WidgetTester t) => _tap(t, _navLabel('設定'));

/// 設定画面の「利用規約」「プライバシーポリシー」の項目
Finder _settingsItem(String label) => find.widgetWithText(ListTile, label);

/// 未同意の状態で起動して、ホーム画面の上に2つの行がある同意ダイアログが表示されている状態にする。
Future<_Env> _launchDialog(
  WidgetTester t, {
  void Function(_Env env)? configure,
}) async {
  final env = await _launch(t, configure: configure);
  expect(env.path, '/home', reason: '準備: ホーム画面');
  expect(_title, findsOneWidget, reason: '準備: 同意ダイアログ');
  return env;
}

/// 同意済みで起動し、ホーム画面の「フォルダを作成」ダイアログに「英単語」を入力して、
/// 現行の termsVersion の改定 + 復帰で同意ダイアログがその上に表示されている状態にする。
Future<_Env> _launchCreateDialogWithConsent(WidgetTester t) async {
  final env = await _launch(t, configure: _matched);
  await _tap(t, find.byType(FloatingActionButton));
  await t.enterText(find.byType(TextField), '英単語');
  await t.pump();
  env.bump(terms: '2026-02-01');
  await _resume(t);
  expect(_title, findsOneWidget, reason: '準備: 同意ダイアログ');
  return env;
}

/// 「フォルダを作成」ダイアログが「英単語」が入ったまま残っている。
void _expectCreateDialogWithText(WidgetTester t) {
  expect(
      find.descendant(
          of: find.byType(AlertDialog), matching: find.text('フォルダを作成')),
      findsOneWidget);
  expect(t.widget<TextField>(find.byType(TextField)).controller!.text, '英単語');
}

/// 同意済みで起動し、設定画面の「利用規約」から閲覧画面を開いている状態にする。
Future<_Env> _launchSettingsDocument(WidgetTester t) async {
  final env = await _launch(t, configure: _matched);
  await _goSettings(t);
  await _tap(t, _settingsItem('利用規約'));
  expect(_document, findsOneWidget, reason: '準備: 閲覧画面');
  return env;
}

void main() {
  _judgeTests();
  _operationTests();
  _browseTests();
  _errorTests();
}

// ─── 3.1 判定と表示 ───

void _judgeTests() {
  group('LegalConsentGate 判定と表示', () {
    spec('LGL-D01', '未同意の状態でアプリを起動した場合、ホーム画面の上に同意ダイアログが表示され、2つのチェックは未チェックで「同意する」は無効・「ログアウト」は有効になる',
        (t) async {
      final env = await _launch(t);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
      expect(_body, findsOneWidget);
      _expectBothRows();
      expect(_agree, findsOneWidget);
      expect(_logout, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_agreeEnabled(t), isFalse);
      expect(_logoutEnabled(t), isTrue);
    });

    spec('LGL-D02', 'プライバシーポリシーだけ版数が古い状態でアプリを起動した場合、プライバシーポリシーの行だけの同意ダイアログが表示される',
        (t) async {
      final env = await _launch(t,
          configure: (e) => e.legal.consents = const Right(LegalConsents(
              termsVersion: '2026-01-01', privacyVersion: '2025-06-01')));

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
      _expectOnlyPrivacy();
      expect(_agree, findsOneWidget);
      expect(_logout, findsOneWidget);
    });

    spec('LGL-D03', '利用規約だけ版数が古い状態でアプリを起動した場合、利用規約の行だけの同意ダイアログが表示される',
        (t) async {
      final env = await _launch(t,
          configure: (e) => e.legal.consents = const Right(LegalConsents(
              termsVersion: '2025-06-01', privacyVersion: '2026-01-01')));

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
      _expectOnlyTerms();
      expect(_agree, findsOneWidget);
      expect(_logout, findsOneWidget);
    });

    spec('LGL-D04', '同意済みの版数が現行の版数と一致する状態でアプリを起動した場合、ホーム画面が表示され同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: _matched);

      expect(env.path, '/home');
      _expectNoDialogs();
    });

    spec('LGL-D05', '利用規約の記録だけがありプライバシーポリシーの記録が無い状態でアプリを起動した場合、プライバシーポリシーの行だけの同意ダイアログが表示される',
        (t) async {
      final env = await _launch(t,
          configure: (e) => e.legal.consents =
              const Right(LegalConsents(termsVersion: '2026-01-01')));

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
      _expectOnlyPrivacy();
    });

    spec('LGL-D07', 'ログインしていない状態でメールアドレスとパスワードのログインが成功した場合、ホーム画面に移動し同意ダイアログが表示される',
        (t) async {
      final env = await _launch(t, user: null);
      expect(env.path, '/login');
      await t.enterText(find.byType(TextFormField).at(0), 'a@example.com');
      await t.enterText(find.byType(TextFormField).at(1), 'password1');
      await _tap(t, find.widgetWithText(FilledButton, 'ログイン'));

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
    });

    spec('LGL-D08', 'ログインしていない状態で Google のログインが成功した場合、ホーム画面に移動し同意ダイアログが表示される',
        (t) async {
      final env = await _launch(t, user: null);
      expect(env.path, '/login');
      await _signInWithGoogle(t);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
    });

    spec('LGL-D09', '未同意の状態でオフラインで起動し判定が NetworkFailure で失敗した場合、ホーム画面が表示され同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: (e) => e.legal.configFailure = _network);

      expect(env.path, '/home');
      _expectNoDialogs();
    });

    spec('LGL-D10', '未同意の状態で現行の版数の読み取りが UnknownFailure で失敗した場合、ホーム画面が表示され同意ダイアログも失敗の表示も出ない',
        (t) async {
      final env = await _launch(t, configure: (e) => e.legal.configFailure = _unknown);

      expect(env.path, '/home');
      _expectNoDialogs();
      expect(find.byType(SnackBar), findsNothing);
    });

    spec('LGL-D11', 'ログインしていない状態でアプリを起動した場合、ログイン画面が表示され同意ダイアログは表示されず fetchLegalConfig は0回である',
        (t) async {
      final env = await _launch(t, user: null);

      expect(env.path, '/login');
      _expectNoDialogs();
      expect(env.legal.fetchConfigCalls, 0);
    });

    spec('LGL-D12', '未同意で退会処理の記録が requested の状態でアプリを起動した場合、「退会処理が完了していません」ダイアログが表示され同意ダイアログは表示されない',
        (t) async {
      await _launch(t,
          configure: (e) =>
              e.deletion.record = _record(AccountDeletionStatus.requested));

      expect(_retryTitle, findsOneWidget);
      expect(_title, findsNothing);
    });

    spec('LGL-D13', '退会済みの記録があり accounts/A が無い状態でアプリを起動した場合、「アカウントが削除されました」ダイアログが表示され同意ダイアログは表示されない',
        (t) async {
      await _launch(t, configure: (e) => e.deletion.withdrawn.add('A'));

      expect(_noticeTitle, findsOneWidget);
      expect(_title, findsNothing);
    });

    spec('LGL-D14', '同意済みで起動してホーム画面を表示中に現行の termsVersion が変わり復帰した場合、利用規約の行だけの同意ダイアログがホーム画面の上に表示される',
        (t) async {
      final env = await _launch(t, configure: _matched);
      expect(_title, findsNothing);

      env.bump(terms: '2026-02-01');
      await _resume(t);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
      _expectOnlyTerms();
    });

    spec('LGL-D15', '同意ダイアログの表示中に「利用規約に同意する」をチェックして復帰した場合、同意ダイアログは1つだけでチェックは残り fetchLegalConfig は起動時の1回だけである',
        (t) async {
      final env = await _launchDialog(t);
      await _check(t, _termsLabel);

      await _resume(t);

      expect(_title, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isTrue);
      expect(env.legal.fetchConfigCalls, 1);
    });

    spec('LGL-D16', '未同意でオフライン起動してホーム画面を表示し、バックグラウンドの間にオンラインに戻り、その後復帰した場合、同意ダイアログがホーム画面の上に1つ表示される',
        (t) async {
      final env = await _launch(t, configure: (e) => e.legal.configFailure = _network);
      expect(env.path, '/home');
      expect(_title, findsNothing);

      await _background(t);
      env.legal.configFailure = null;
      await _goOfflineThenOnline(t, env);
      await _resume(t);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
    });

    spec('LGL-D17', '同意ダイアログの表示中に退会済みの記録ができた場合、同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される',
        (t) async {
      final env = await _launchDialog(t);

      env.deletion.emitWithdrawn('A');
      await _settle(t);

      expect(_title, findsNothing);
      expect(_noticeTitle, findsOneWidget);
    });

    spec('LGL-D18', '強制ログアウトの記録がある uid で Firebase 上はログイン中の未同意の状態で起動した場合、ログイン画面が表示され同意ダイアログは表示されず fetchLegalConfig は0回である',
        (t) async {
      final env = await _launch(t, configure: (e) => e.deletion.forcedUid = 'A');

      expect(env.path, '/login');
      _expectNoDialogs();
      expect(env.legal.fetchConfigCalls, 0);
    });

    spec('LGL-D19', '未同意の状態で起動して判定の応答を待っている場合、ホーム画面が表示され同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: (e) => e.legal.configGate = Completer());

      expect(env.path, '/home');
      _expectNoDialogs();
      env.legal.configGate!.complete();
    });

    spec('LGL-D20', '幅320・高さ480の端末で未同意の状態で起動した場合、同意ダイアログが表示されはみ出しが起きず、スクロールすると「同意する」ボタンが表示される',
        (t) async {
      await _launch(t, size: const Size(320, 480));

      expect(_title, findsOneWidget);
      await t.drag(
          find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(SingleChildScrollView)),
          const Offset(0, -300));
      await _settle(t);
      expect(_agree, findsOneWidget);
      expect(t.getRect(_agree).bottom, lessThanOrEqualTo(480));
      expect(t.takeException(), isNull);
    });

    spec('LGL-D21', '同意ダイアログの表示中に Firebase のログイン状態が解除された場合、同意ダイアログが閉じログイン画面が表示される',
        (t) async {
      final env = await _launchDialog(t);

      env.auth.emitUser(null);
      await _settle(t);

      expect(_title, findsNothing);
      expect(env.path, '/login');
    });

    spec('LGL-D22', '同意ダイアログの表示中は、「キャンセル」「同意しない」のボタンが表示されない',
        (t) async {
      await _launchDialog(t);

      expect(find.text('キャンセル'), findsNothing);
      expect(find.text('同意しない'), findsNothing);
    });

    spec('LGL-D23', 'スプラッシュ画面を表示している間に判定が終わった場合、スプラッシュ画面の間は同意ダイアログが表示されず、ホーム画面に移動した後にその上に表示される',
        (t) async {
      final env = await _launch(t, skipSplash: false);
      expect(env.path, '/');
      expect(_title, findsNothing);

      await t.pump(const Duration(seconds: 2));
      await _settle(t);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
    });

    spec('LGL-D24', '閲覧画面を開いている間に退会済みの記録ができた場合、閲覧画面と同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _termsLink);
      expect(_document, findsOneWidget);

      env.deletion.emitWithdrawn('A');
      await _settle(t);

      expect(_document, findsNothing);
      expect(_title, findsNothing);
      expect(_noticeTitle, findsOneWidget);
    });

    spec('LGL-D25', '閲覧画面を開いている間に Firebase のログイン状態が解除された場合、閲覧画面と同意ダイアログが閉じログイン画面が表示される',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _termsLink);
      expect(_document, findsOneWidget);

      env.auth.emitUser(null);
      await _settle(t);

      expect(_document, findsNothing);
      expect(_title, findsNothing);
      expect(env.path, '/login');
    });

    spec('LGL-D26', '「利用規約に同意する」をチェックして閲覧画面を開いている間に復帰した場合、閲覧画面は表示されたままで、戻ると同意ダイアログが1つだけ表示されチェックは残り fetchLegalConfig は1回である',
        (t) async {
      final env = await _launchDialog(t);
      await _check(t, _termsLabel);
      await _tap(t, _termsLink);

      await _resume(t);
      expect(_document, findsOneWidget);

      await _tapDocBack(t);
      expect(_document, findsNothing);
      expect(_title, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isTrue);
      expect(env.legal.fetchConfigCalls, 1);
    });

    spec('LGL-D27', '未同意で退会処理の記録が serverDone の状態でアプリを起動した場合、「退会処理が完了していません」ダイアログが表示され同意ダイアログは表示されない',
        (t) async {
      await _launch(t,
          configure: (e) =>
              e.deletion.record = _record(AccountDeletionStatus.serverDone));

      expect(_retryTitle, findsOneWidget);
      expect(_title, findsNothing);
    });

    spec('LGL-D28', '退会処理の記録が requested で再開ダイアログの表示中に復帰した場合、再開ダイアログは表示されたままで同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t,
          configure: (e) =>
              e.deletion.record = _record(AccountDeletionStatus.requested));
      expect(_retryTitle, findsOneWidget);

      await _resume(t);

      expect(_retryTitle, findsOneWidget);
      expect(_title, findsNothing);
      expect(env.legal.fetchConfigCalls, 0);
    });

    spec('LGL-D29', '未同意でログイン済みの状態でアプリを起動した場合、同意ダイアログが1つだけ表示され fetchLegalConfig は1回だけ呼ばれる',
        (t) async {
      final env = await _launch(t);

      expect(_title, findsOneWidget);
      expect(env.legal.fetchConfigCalls, 1);
    });

    spec('LGL-D30', '「同意する」をタップして送信の応答を待っている間に復帰した場合、同意ダイアログは1つだけでローディングが表示されたままで送信は1回だけ呼ばれる',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptGate = Completer());
      await _checkBoth(t);
      await _tapAgree(t);

      await _resume(t);

      expect(_title, findsOneWidget);
      expect(_spinner, findsOneWidget);
      expect(env.legal.acceptCalls.length, 1);
    });

    spec('LGL-D31', '「同意する」をタップして送信の応答を待っている間に退会済みの記録ができた場合、同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptGate = Completer());
      await _checkBoth(t);
      await _tapAgree(t);

      env.deletion.emitWithdrawn('A');
      await _settle(t);

      expect(_title, findsNothing);
      expect(_noticeTitle, findsOneWidget);
    });

    spec('LGL-D32', 'uid A に強制ログアウトの記録がありログインしていない状態で uid B のログインが成功した場合、ホーム画面に移動し同意ダイアログが表示される',
        (t) async {
      final env = await _launch(t, user: null, configure: (e) {
        e.deletion.forcedUid = 'A';
        e.auth.signInUser = _userB;
      });
      expect(env.path, '/login');
      await t.enterText(find.byType(TextFormField).at(0), 'b@example.com');
      await t.enterText(find.byType(TextFormField).at(1), 'password1');
      await _tap(t, find.widgetWithText(FilledButton, 'ログイン'));

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
    });

    spec('LGL-D33', '同意済みの uid のログインが成功した場合、ホーム画面に移動し同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, user: null, configure: _matched);
      expect(env.path, '/login');
      await t.enterText(find.byType(TextFormField).at(0), 'a@example.com');
      await t.enterText(find.byType(TextFormField).at(1), 'password1');
      await _tap(t, find.widgetWithText(FilledButton, 'ログイン'));

      expect(env.path, '/home');
      _expectNoDialogs();
    });

    spec('LGL-D34', '同意済みで起動してホーム画面を表示中に現行の privacyVersion が変わり復帰した場合、プライバシーポリシーの行だけの同意ダイアログが表示される',
        (t) async {
      final env = await _launch(t, configure: _matched);

      env.bump(privacy: '2026-02-01');
      await _resume(t);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
      _expectOnlyPrivacy();
    });

    spec('LGL-D35', '同意済みで設定画面を表示中に現行の termsVersion が変わり復帰した場合、設定画面の上に同意ダイアログが表示され画面のパスは /settings のままである',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      expect(env.path, '/settings');

      env.bump(terms: '2026-02-01');
      await _resume(t);

      expect(_title, findsOneWidget);
      expect(env.path, '/settings');
    });

    spec('LGL-D36', '幅320・高さ480・文字の拡大率2.0の端末で未同意の状態で起動した場合、同意ダイアログが表示されはみ出しが起きない',
        (t) async {
      t.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(t.platformDispatcher.clearAllTestValues);

      await _launch(t, size: const Size(320, 480));

      expect(_title, findsOneWidget);
      expect(t.takeException(), isNull);
    });

    spec('LGL-D37', '判定の応答を待っている間に Firebase のログイン状態が解除され、その後に判定が同意が必要と返した場合、ログイン画面が表示され同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: (e) => e.legal.configGate = Completer());

      env.auth.emitUser(null);
      await _settle(t);
      env.legal.configGate!.complete();
      await _settle(t);

      expect(env.path, '/login');
      expect(_title, findsNothing);
    });

    spec('LGL-D38', '判定の応答を待っている間に退会済みの記録が見つかりお知らせが表示され、その後に判定が同意が必要と返した場合、お知らせダイアログは表示されたままで同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: (e) => e.legal.configGate = Completer());

      env.deletion.emitWithdrawn('A');
      await _settle(t);
      expect(_noticeTitle, findsOneWidget);
      env.legal.configGate!.complete();
      await _settle(t);

      expect(_noticeTitle, findsOneWidget);
      expect(_title, findsNothing);
    });

    spec('LGL-D39', '判定の応答を待っている間に設定画面から退会を始めて退会処理の記録が requested になり、その後に判定が同意が必要と返した場合、同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: (e) {
        e.legal.configGate = Completer();
        e.deletion.requestGate = Completer();
      });
      await _goSettings(t);
      await _tap(t, find.text('退会'));
      await _tap(t, find.widgetWithText(FilledButton, 'OK'));
      await _tap(t, find.widgetWithText(FilledButton, 'OK'));
      expect(env.deletion.record?.status, AccountDeletionStatus.requested);

      env.legal.configGate!.complete();
      await _settle(t);

      expect(_title, findsNothing);
    });

    spec('LGL-D40', '「アカウントが削除されました」ダイアログの表示中に復帰した場合、ダイアログは表示されたままで同意ダイアログは表示されず fetchLegalConfig の呼び出し回数は増えない',
        (t) async {
      final env = await _launch(t, configure: (e) => e.deletion.withdrawn.add('A'));
      expect(_noticeTitle, findsOneWidget);
      final before = env.legal.fetchConfigCalls;

      await _resume(t);

      expect(_noticeTitle, findsOneWidget);
      expect(_title, findsNothing);
      expect(env.legal.fetchConfigCalls, before);
    });

    spec('LGL-D41', '「フォルダを作成」ダイアログに「英単語」を入力中に現行の termsVersion が変わり復帰した場合、その上に同意ダイアログが表示され、同意が成功すると「英単語」が入ったまま「フォルダを作成」ダイアログが表示される',
        (t) async {
      final env = await _launchCreateDialogWithConsent(t);
      expect(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.text('フォルダを作成')),
          findsOneWidget);

      await _check(t, _termsLabel);
      await _tapAgree(t);

      expect(env.legal.acceptCalls.length, 1);
      expect(_title, findsNothing);
      _expectCreateDialogWithText(t);
    });

    spec('LGL-D42', '「ログアウト」の応答を待っている間に退会済みの記録ができた場合、同意ダイアログが閉じお知らせが表示され、その後にログアウトが UnknownFailure を返しても「ログアウトできませんでした。」は表示されない',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.auth.signOutGate = Completer());
      await _tapLogout(t);

      env.deletion.emitWithdrawn('A');
      await _settle(t);
      expect(_title, findsNothing);
      expect(_noticeTitle, findsOneWidget);

      env.auth.signOutFailure = _unknown;
      env.auth.signOutGate!.complete();
      await _settle(t);
      expect(_msgSignOutFailed, findsNothing);
    });

    spec('LGL-D43', '「ログアウト」の応答を待っている間に復帰した場合、同意ダイアログは1つだけでローディングが表示されたままで fetchLegalConfig の呼び出し回数は増えない',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.auth.signOutGate = Completer());
      await _tapLogout(t);
      final before = env.legal.fetchConfigCalls;

      await _resume(t);

      expect(_title, findsOneWidget);
      expect(_spinner, findsOneWidget);
      expect(env.legal.fetchConfigCalls, before);
    });

    spec('LGL-D44', '設定画面の「利用規約」から閲覧画面を開いている間に現行の termsVersion が変わり復帰した場合、閲覧画面の上に利用規約の行だけの同意ダイアログが表示される',
        (t) async {
      final env = await _launchSettingsDocument(t);

      env.bump(terms: '2026-02-01');
      await _resume(t);

      expect(_title, findsOneWidget);
      _expectOnlyTerms();
      expect(_document, findsOneWidget);
    });

    spec('LGL-D45', '閲覧画面の上に表示された同意ダイアログで同意が成功した場合、同意ダイアログが閉じ閲覧画面が表示され、戻ると設定画面が表示される',
        (t) async {
      final env = await _launchSettingsDocument(t);
      env.bump(terms: '2026-02-01');
      await _resume(t);

      await _check(t, _termsLabel);
      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(_document, findsOneWidget);
      await _tapDocBack(t);
      expect(_document, findsNothing);
      expect(env.path, '/settings');
    });

    spec('LGL-D46', '設定画面の「利用規約」から閲覧画面を開いている間に退会済みの記録ができた場合、「アカウントが削除されました」ダイアログが表示され同意ダイアログは表示されない',
        (t) async {
      final env = await _launchSettingsDocument(t);

      env.deletion.emitWithdrawn('A');
      await _settle(t);

      expect(_noticeTitle, findsOneWidget);
      expect(_title, findsNothing);
    });

    spec('LGL-D47', '設定画面の「利用規約」から閲覧画面を開いている間に Firebase のログイン状態が解除された場合、閲覧画面が閉じログイン画面が表示される',
        (t) async {
      final env = await _launchSettingsDocument(t);

      env.auth.emitUser(null);
      await _settle(t);

      expect(_document, findsNothing);
      expect(env.path, '/login');
    });

    spec('LGL-D48', '「フォルダを作成」ダイアログの上に同意ダイアログが表示されている間に退会済みの記録ができた場合、同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される',
        (t) async {
      final env = await _launchCreateDialogWithConsent(t);

      env.deletion.emitWithdrawn('A');
      await _settle(t);

      expect(_title, findsNothing);
      expect(_noticeTitle, findsOneWidget);
    });

    spec('LGL-D49', '「フォルダを作成」ダイアログの上に同意ダイアログが表示されている間に Firebase のログイン状態が解除された場合、2つのダイアログが閉じログイン画面が表示される',
        (t) async {
      final env = await _launchCreateDialogWithConsent(t);

      env.auth.emitUser(null);
      await _settle(t);

      expect(_title, findsNothing);
      expect(find.text('フォルダを作成'), findsNothing);
      expect(env.path, '/login');
    });

    spec('LGL-D50', '未同意でオフライン起動してホーム画面を表示し、フォアグラウンドのままオンラインに戻った場合、同意ダイアログがホーム画面の上に表示される',
        (t) async {
      final env = await _launch(t, configure: (e) => e.legal.configFailure = _network);
      expect(env.path, '/home');
      expect(_title, findsNothing);

      env.legal.configFailure = null;
      await _goOfflineThenOnline(t, env);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
    });

    spec('LGL-D51', 'app_config/legal が無く未同意の状態で起動した場合、ホーム画面の上に2つの行がある同意ダイアログが表示される',
        (t) async {
      final env = await _launch(t, configure: (e) => e.legal.configFailure = _notFound);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
      _expectBothRows();
    });

    spec('LGL-D52', 'app_config/legal が無く同意済みの版数が既定値（2026-10-12）と同じ状態で起動した場合、ホーム画面が表示され同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: (e) {
        e.legal.configFailure = _notFound;
        e.legal.consents = const Right(
            LegalConsents(termsVersion: '2026-10-12', privacyVersion: '2026-10-12'));
      });

      expect(env.path, '/home');
      _expectNoDialogs();
    });

    spec('LGL-D53', 'app_config/legal が無く利用規約だけ既定値と同じ版数で同意済みの状態で起動した場合、プライバシーポリシーの行だけの同意ダイアログが表示される',
        (t) async {
      final env = await _launch(t, configure: (e) {
        e.legal.configFailure = _notFound;
        e.legal.consents = const Right(
            LegalConsents(termsVersion: '2026-10-12', privacyVersion: '2025-06-01'));
      });

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
      _expectOnlyPrivacy();
    });

    spec('LGL-D54', 'メールアドレスとパスワードでログインして初回の同期の完了を待っている場合、同意ダイアログは表示されず fetchLegalConfig は0回である',
        (t) async {
      final env = await _launch(t, user: null, configure: (e) => e.sync.syncGate = Completer());
      expect(env.path, '/login');

      await _loginWithEmail(t);

      expect(_title, findsNothing);
      expect(env.legal.fetchConfigCalls, 0);
      env.sync.syncGate!.complete();
    });

    spec('LGL-D55', '新規登録画面で2つにチェックして「アカウント作成」をタップし、同意の送信の応答を待っている場合、同意ダイアログは表示されず fetchLegalConfig は新規登録画面を開いたときの1回だけである',
        (t) async {
      final env = await _launch(t, user: null, configure: (e) => e.legal.acceptGate = Completer());
      expect(env.path, '/login');
      await _tap(t, find.text('新規登録'));
      expect(find.text('新規登録'), findsOneWidget, reason: '準備: 新規登録画面（AppBar）');
      expect(find.widgetWithText(FilledButton, 'アカウント作成'), findsOneWidget);
      await t.enterText(find.byType(TextFormField).at(0), 'a@example.com');
      await t.enterText(find.byType(TextFormField).at(1), 'password1');
      await t.enterText(find.byType(TextFormField).at(2), 'password1');
      await _checkBoth(t);

      await _tap(t, find.widgetWithText(FilledButton, 'アカウント作成'));

      expect(env.legal.acceptCalls.length, 1);
      expect(_title, findsNothing);
      expect(env.legal.fetchConfigCalls, 1);
      env.legal.acceptGate!.complete();
    });

    spec('LGL-D56', '同意ダイアログの表示中に「利用規約に同意する」をチェックし、オフラインになってからオンラインに戻った場合、同意ダイアログは1つだけでチェックは残り fetchLegalConfig は起動時の1回だけである',
        (t) async {
      final env = await _launchDialog(t);
      await _check(t, _termsLabel);

      await _goOfflineThenOnline(t, env);

      expect(_title, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isTrue);
      expect(env.legal.fetchConfigCalls, 1);
    });

    spec('LGL-D57', 'ログイン画面の表示中にオフラインになってからオンラインに戻った場合、同意ダイアログは表示されず fetchLegalConfig は0回である',
        (t) async {
      final env = await _launch(t, user: null);
      expect(env.path, '/login');

      await _goOfflineThenOnline(t, env);

      expect(_title, findsNothing);
      expect(env.legal.fetchConfigCalls, 0);
    });

    spec('LGL-D58', '退会処理の記録が requested で再開ダイアログの表示中にオフラインになってからオンラインに戻った場合、同意ダイアログは表示されず再開ダイアログは表示されたままである',
        (t) async {
      final env = await _launch(t,
          configure: (e) =>
              e.deletion.record = _record(AccountDeletionStatus.requested));
      expect(_retryTitle, findsOneWidget);

      await _goOfflineThenOnline(t, env);

      expect(_title, findsNothing);
      expect(_retryTitle, findsOneWidget);
    });

    spec('LGL-D59', 'Google でログインして初回の同期の完了を待っている場合、同意ダイアログは表示されず fetchLegalConfig は0回である',
        (t) async {
      final env = await _launch(t, user: null, configure: (e) => e.sync.syncGate = Completer());
      expect(env.path, '/login');

      await _signInWithGoogle(t);

      expect(_title, findsNothing);
      expect(env.legal.fetchConfigCalls, 0);
      env.sync.syncGate!.complete();
    });

    spec('LGL-D60', 'メールアドレスとパスワードでログインして初回の同期が失敗して終わった場合、ホーム画面に移動し同意ダイアログが表示される',
        (t) async {
      final env = await _launch(t, user: null, configure: (e) => e.sync.syncError = Exception('sync failed'));
      expect(env.path, '/login');

      await _loginWithEmail(t);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
    });

    spec('LGL-D61', '新規登録画面を開いて規約の情報の読み取りの応答を待っている場合、ローディングは表示されず「アカウント作成」ボタンは無効である',
        (t) async {
      final env = await _launch(t, user: null);
      expect(env.path, '/login');
      env.legal.configGate = Completer();

      await _tap(t, find.text('新規登録'));

      expect(find.text('新規登録'), findsOneWidget, reason: '準備: 新規登録画面（AppBar）');
      expect(find.widgetWithText(FilledButton, 'アカウント作成'), findsOneWidget);
      expect(_spinner, findsNothing);
      expect(
          t.widget<FilledButton>(find.widgetWithText(FilledButton, 'アカウント作成')).onPressed,
          isNull);
      env.legal.configGate!.complete();
    });
  });
}

// ─── 3.2 同意の操作 ───

void _operationTests() {
  group('LegalConsentGate 同意の操作', () {
    spec('LGL-A01', '「利用規約に同意する」のチェックボックスをタップした場合、利用規約だけがチェックされ「同意する」は無効のままである',
        (t) async {
      await _launchDialog(t);

      await _check(t, _termsLabel);

      expect(_isChecked(t, _termsLabel), isTrue);
      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_agreeEnabled(t), isFalse);
    });

    spec('LGL-A02', '2つのチェックボックスをタップした場合、2つともチェックされ「同意する」が有効になる',
        (t) async {
      await _launchDialog(t);

      await _checkBoth(t);

      expect(_isChecked(t, _termsLabel), isTrue);
      expect(_isChecked(t, _privacyLabel), isTrue);
      expect(_agreeEnabled(t), isTrue);
    });

    spec('LGL-A03', '2つチェックした後に「利用規約に同意する」をもう一度タップした場合、利用規約が未チェックになり「同意する」が無効になる',
        (t) async {
      await _launchDialog(t);
      await _checkBoth(t);

      await _check(t, _termsLabel);

      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_agreeEnabled(t), isFalse);
    });

    spec('LGL-A04', 'プライバシーポリシーの行だけの同意ダイアログで「プライバシーポリシーに同意する」をタップした場合、「同意する」が有効になる',
        (t) async {
      await _launchDialog(t,
          configure: (e) => e.legal.consents = const Right(LegalConsents(
              termsVersion: '2026-01-01', privacyVersion: '2025-06-01')));
      _expectOnlyPrivacy();

      await _check(t, _privacyLabel);

      expect(_agreeEnabled(t), isTrue);
    });

    spec('LGL-A05', '「利用規約に同意する」の文言をタップした場合、利用規約がチェックされる',
        (t) async {
      await _launchDialog(t);

      await _tap(t, find.text(_termsLabel));

      expect(_isChecked(t, _termsLabel), isTrue);
    });

    spec('LGL-A06', '2つチェックして「同意する」をタップし送信が accepted を返した場合、同意ダイアログが閉じホーム画面が表示され送信が現行の版数で1回呼ばれる',
        (t) async {
      final env = await _launchDialog(t);
      await _checkBoth(t);

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.path, '/home');
      expect(env.legal.acceptCalls, [(terms: '2026-01-01', privacy: '2026-01-01')]);
    });

    spec('LGL-A07', '利用規約の行だけの同意ダイアログで同意して送信が accepted を返した場合、同意ダイアログが閉じ送信が利用規約の版数とプライバシーポリシー null で1回呼ばれる',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.consents = const Right(LegalConsents(
              termsVersion: '2025-06-01', privacyVersion: '2026-01-01')));
      await _check(t, _termsLabel);

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.legal.acceptCalls, [(terms: '2026-01-01', privacy: null)]);
    });

    spec('LGL-A08', '「同意する」をタップして送信の応答を待っている場合、同意ダイアログのボタン・チェックボックス・リンクが無効になりローディングが表示される',
        (t) async {
      await _launchDialog(t, configure: (e) => e.legal.acceptGate = Completer());
      await _checkBoth(t);

      await _tapAgree(t);

      expect(_title, findsOneWidget);
      expect(_agreeEnabled(t), isFalse);
      expect(_logoutEnabled(t), isFalse);
      expect(_boxEnabled(t, _termsLabel), isFalse);
      expect(_boxEnabled(t, _privacyLabel), isFalse);
      expect(_linkEnabled(t, _termsLink), isFalse);
      expect(_linkEnabled(t, _privacyLink), isFalse);
      expect(find.descendant(of: find.byType(AlertDialog), matching: _spinner),
          findsOneWidget);
    });

    spec('LGL-A09', '送信の応答を待っている間に「同意する」をもう一度タップした場合、送信は1回だけ呼ばれる',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptGate = Completer());
      await _checkBoth(t);
      await _tapAgree(t);

      await t.tap(_agree, warnIfMissed: false);
      await _settle(t);

      expect(env.legal.acceptCalls.length, 1);
    });

    spec('LGL-A10', '送信が UnknownFailure で失敗した場合、同意ダイアログが表示されたままチェックは残り「同意を送信できませんでした。」が表示され「同意する」は有効である',
        (t) async {
      await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_unknown));
      await _checkBoth(t);

      await _tapAgree(t);

      expect(_title, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isTrue);
      expect(_isChecked(t, _privacyLabel), isTrue);
      expect(_msgSendFailed, findsOneWidget);
      expect(_agreeEnabled(t), isTrue);
    });

    spec('LGL-A11', '1回目の送信が UnknownFailure で失敗した後に「同意する」をもう一度タップし2回目が accepted を返した場合、同意ダイアログが閉じ送信は合計2回呼ばれる',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Left(_unknown)));
      await _checkBoth(t);
      await _tapAgree(t);
      expect(_msgSendFailed, findsOneWidget);

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.legal.acceptCalls.length, 2);
    });

    spec('LGL-A12', '2つチェックした後に現行の termsVersion が変わり送信が outdated を返した場合、2つの行が未チェックで表示し直され「内容が更新されました。」が表示され「同意する」は無効である',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(terms: '2026-02-01');

      await _tapAgree(t);

      expect(_title, findsOneWidget);
      _expectBothRows();
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_msgOutdated, findsOneWidget);
      expect(_agreeEnabled(t), isFalse);
    });

    spec('LGL-A13', 'outdated で表示し直された同意ダイアログで再度同意して2回目の送信が accepted を返した場合、同意ダイアログが閉じ2回目の送信は利用規約 2026-02-01・プライバシーポリシー 2026-01-01 で呼ばれる',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(terms: '2026-02-01');
      await _tapAgree(t);
      await _checkBoth(t);

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.legal.acceptCalls.length, 2);
      expect(env.legal.acceptCalls[1], (terms: '2026-02-01', privacy: '2026-01-01'));
    });

    spec('LGL-A14', '送信の処理中ではない状態で同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままで送信は0回である',
        (t) async {
      final env = await _launchDialog(t);

      await _tapOutside(t);

      expect(_title, findsOneWidget);
      expect(env.legal.acceptCalls, isEmpty);
    });

    spec('LGL-A15', '送信の処理中ではない状態で戻る操作をした場合、同意ダイアログは表示されたままで画面のパスは /home のままで送信は0回である',
        (t) async {
      final env = await _launchDialog(t);

      await _back(t);

      expect(_title, findsOneWidget);
      expect(env.path, '/home');
      expect(env.legal.acceptCalls, isEmpty);
    });

    spec('LGL-A16', '送信の応答を待っている間に同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままである',
        (t) async {
      await _launchDialog(t, configure: (e) => e.legal.acceptGate = Completer());
      await _checkBoth(t);
      await _tapAgree(t);

      await _tapOutside(t);

      expect(_title, findsOneWidget);
    });

    spec('LGL-A17', '送信の応答を待っている間に戻る操作をした場合、同意ダイアログは表示されたままである',
        (t) async {
      await _launchDialog(t, configure: (e) => e.legal.acceptGate = Completer());
      await _checkBoth(t);
      await _tapAgree(t);

      await _back(t);

      expect(_title, findsOneWidget);
    });

    spec('LGL-A18', '「利用規約に同意する」だけをチェックした状態で無効の「同意する」をタップした場合、同意ダイアログは表示されたままで送信は0回である',
        (t) async {
      final env = await _launchDialog(t);
      await _check(t, _termsLabel);

      await t.tap(_agree, warnIfMissed: false);
      await _settle(t);

      expect(_title, findsOneWidget);
      expect(env.legal.acceptCalls, isEmpty);
    });

    spec('LGL-A19', '同意して送信が accepted を返した後に復帰した場合、同意ダイアログは表示されない',
        (t) async {
      final env = await _launchDialog(t);
      await _checkBoth(t);
      await _tapAgree(t);
      env.legal.consents = const Right(_matching);

      await _resume(t);

      expect(_title, findsNothing);
    });

    spec('LGL-A20', '「プライバシーポリシーに同意する」のチェックボックスをタップした場合、プライバシーポリシーだけがチェックされ「同意する」は無効のままである',
        (t) async {
      await _launchDialog(t);

      await _check(t, _privacyLabel);

      expect(_isChecked(t, _privacyLabel), isTrue);
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_agreeEnabled(t), isFalse);
    });

    spec('LGL-A21', '2つチェックした後に「プライバシーポリシーに同意する」をもう一度タップした場合、プライバシーポリシーが未チェックになり「同意する」が無効になる',
        (t) async {
      await _launchDialog(t);
      await _checkBoth(t);

      await _check(t, _privacyLabel);

      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_agreeEnabled(t), isFalse);
    });

    spec('LGL-A22', '「プライバシーポリシーに同意する」の文言をタップした場合、プライバシーポリシーがチェックされる',
        (t) async {
      await _launchDialog(t);

      await _tap(t, find.text(_privacyLabel));

      expect(_isChecked(t, _privacyLabel), isTrue);
    });

    spec('LGL-A23', '「プライバシーポリシーに同意する」だけをチェックした状態で無効の「同意する」をタップした場合、同意ダイアログは表示されたままで送信は0回である',
        (t) async {
      final env = await _launchDialog(t);
      await _check(t, _privacyLabel);

      await t.tap(_agree, warnIfMissed: false);
      await _settle(t);

      expect(_title, findsOneWidget);
      expect(env.legal.acceptCalls, isEmpty);
    });

    spec('LGL-A24', 'プライバシーポリシーの行だけの同意ダイアログで同意して送信が accepted を返した場合、同意ダイアログが閉じ送信が利用規約 null・プライバシーポリシーの版数で1回呼ばれる',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.consents = const Right(LegalConsents(
              termsVersion: '2026-01-01', privacyVersion: '2025-06-01')));
      await _check(t, _privacyLabel);

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.legal.acceptCalls, [(terms: null, privacy: '2026-01-01')]);
    });

    spec('LGL-A25', '2つチェックした後に現行の privacyVersion が変わり送信が outdated を返した場合、2つの行が未チェックで表示し直され「内容が更新されました。」が表示され「同意する」は無効である',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(privacy: '2026-02-01');

      await _tapAgree(t);

      expect(_title, findsOneWidget);
      _expectBothRows();
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_msgOutdated, findsOneWidget);
      expect(_agreeEnabled(t), isFalse);
    });

    spec('LGL-A26', 'privacyVersion の改定で outdated になり再度同意して2回目の送信が accepted を返した場合、同意ダイアログが閉じ2回目の送信は利用規約 2026-01-01・プライバシーポリシー 2026-02-01 で呼ばれる',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(privacy: '2026-02-01');
      await _tapAgree(t);
      await _checkBoth(t);

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.legal.acceptCalls[1], (terms: '2026-01-01', privacy: '2026-02-01'));
    });

    spec('LGL-A27', '設定画面で表示された同意ダイアログで同意して送信が accepted を返した場合、同意ダイアログが閉じ画面のパスは /settings のままである',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      env.bump(terms: '2026-02-01');
      await _resume(t);
      expect(_title, findsOneWidget);

      await _check(t, _termsLabel);
      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.path, '/settings');
    });

    spec('LGL-A28', '送信の処理中ではない状態で同意ダイアログの背後のボトムナビ「設定」の位置をタップした場合、同意ダイアログは表示されたままで画面のパスは /home のままである',
        (t) async {
      final env = await _launchDialog(t);

      await t.tap(_navLabel('設定'), warnIfMissed: false);
      await _settle(t);

      expect(_title, findsOneWidget);
      expect(env.path, '/home');
    });

    spec('LGL-A29', 'outdated の後の判定し直しが NetworkFailure で失敗した場合、同意ダイアログが閉じホーム画面が表示される',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(terms: '2026-02-01');
      env.legal.configFailure = _network;

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.path, '/home');
    });

    spec('LGL-A30', '別の端末で現行の版数に同意済みになった状態で送信が outdated を返した場合、同意ダイアログが閉じホーム画面が表示される',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(terms: '2026-02-01');
      env.legal.consents = const Right(
          LegalConsents(termsVersion: '2026-02-01', privacyVersion: '2026-01-01'));

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.path, '/home');
    });

    spec('LGL-A31', '利用規約の行だけの同意ダイアログで privacyVersion が変わり送信が outdated を返した場合、2つの行が未チェックで表示し直される',
        (t) async {
      final env = await _launchDialog(t, configure: (e) {
        e.legal.consents = const Right(
            LegalConsents(termsVersion: '2025-06-01', privacyVersion: '2026-01-01'));
        e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated));
      });
      _expectOnlyTerms();
      await _check(t, _termsLabel);
      env.bump(privacy: '2026-02-01');

      await _tapAgree(t);

      expect(_title, findsOneWidget);
      _expectBothRows();
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_isChecked(t, _privacyLabel), isFalse);
    });

    spec('LGL-A32', '1回目の送信が失敗した後に「同意する」をもう一度タップして2回目の応答を待っている場合、「同意を送信できませんでした。」は表示されずローディングが表示される',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Left(_unknown)));
      await _checkBoth(t);
      await _tapAgree(t);
      expect(_msgSendFailed, findsOneWidget);
      env.legal.acceptGate = Completer();

      await _tapAgree(t);

      expect(_msgSendFailed, findsNothing);
      expect(_spinner, findsOneWidget);
    });

    spec('LGL-A33', '送信の応答を待っている間にログイン状態が解除され、その後に送信が NetworkFailure で失敗した場合、ログイン画面が表示され「通信エラー」ダイアログも同意ダイアログも表示されない',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptGate = Completer());
      await _checkBoth(t);
      await _tapAgree(t);

      env.auth.emitUser(null);
      await _settle(t);
      env.legal.acceptResult = const Left(_network);
      env.legal.acceptGate!.complete();
      await _settle(t);

      expect(env.path, '/login');
      expect(_networkTitle, findsNothing);
      expect(_title, findsNothing);
    });

    spec('LGL-A34', 'outdated の後の判定し直しが UnknownFailure で失敗した場合、同意ダイアログが閉じホーム画面が表示される',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(terms: '2026-02-01');
      env.legal.configFailure = _unknown;

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.path, '/home');
    });

    spec('LGL-A36', '送信の応答を待っている間にログイン状態が解除され、その後に送信が accepted を返した場合、ログイン画面が表示され同意ダイアログは表示されない',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptGate = Completer());
      await _checkBoth(t);
      await _tapAgree(t);

      env.auth.emitUser(null);
      await _settle(t);
      env.legal.acceptGate!.complete();
      await _settle(t);

      expect(env.path, '/login');
      expect(_title, findsNothing);
    });

    spec('LGL-A37', 'outdated で表示し直された同意ダイアログで「利用規約に同意する」をチェックした場合、「内容が更新されました。」は表示されたままである',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(terms: '2026-02-01');
      await _tapAgree(t);
      expect(_msgOutdated, findsOneWidget);

      await _check(t, _termsLabel);

      expect(_msgOutdated, findsOneWidget);
    });

    spec('LGL-A38', '「ログアウト」をタップしてログアウトが成功した場合、同意ダイアログが閉じログイン画面に移動し SignOutUseCase が1回呼ばれ確認ダイアログは表示されず送信は0回である',
        (t) async {
      final env = await _launchDialog(t);

      await _tapLogout(t);

      expect(_title, findsNothing);
      expect(env.path, '/login');
      expect(env.auth.signOutCount, 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(env.legal.acceptCalls, isEmpty);
    });

    spec('LGL-A39', '送信の応答を待っている間に「ログアウト」をタップした場合、SignOutUseCase は0回で同意ダイアログは表示されたままである',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptGate = Completer());
      await _checkBoth(t);
      await _tapAgree(t);

      await t.tap(_logout, warnIfMissed: false);
      await _settle(t);

      expect(env.auth.signOutCount, 0);
      expect(_title, findsOneWidget);
    });

    spec('LGL-A40', '「利用規約に同意する」をチェックして「ログアウト」が UnknownFailure で失敗した場合、「ログアウトできませんでした。」が表示されチェックは残り画面のパスは /home のままである',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.auth.signOutFailure = _unknown);
      await _check(t, _termsLabel);

      await _tapLogout(t);

      expect(_title, findsOneWidget);
      expect(_msgSignOutFailed, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isTrue);
      expect(env.path, '/home');
    });

    spec('LGL-A41', 'ログアウトの応答を待っている間に「ログアウト」をもう一度タップした場合、SignOutUseCase は1回だけ呼ばれる',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.auth.signOutGate = Completer());
      await _tapLogout(t);

      await t.tap(_logout, warnIfMissed: false);
      await _settle(t);

      expect(env.auth.signOutCount, 1);
    });

    spec('LGL-A42', '「ログアウト」をタップしてログアウトの応答を待っている場合、ボタン・チェックボックス・リンクが無効になりローディングが表示される',
        (t) async {
      await _launchDialog(t, configure: (e) => e.auth.signOutGate = Completer());

      await _tapLogout(t);

      expect(_logoutEnabled(t), isFalse);
      expect(_agreeEnabled(t), isFalse);
      expect(_boxEnabled(t, _termsLabel), isFalse);
      expect(_boxEnabled(t, _privacyLabel), isFalse);
      expect(_linkEnabled(t, _termsLink), isFalse);
      expect(_linkEnabled(t, _privacyLink), isFalse);
      expect(find.descendant(of: find.byType(AlertDialog), matching: _spinner),
          findsOneWidget);
    });

    spec('LGL-A43', '送信が失敗して「同意を送信できませんでした。」が表示された後に「ログアウト」をタップして応答を待っている場合、「同意を送信できませんでした。」は表示されない',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_unknown));
      await _checkBoth(t);
      await _tapAgree(t);
      expect(_msgSendFailed, findsOneWidget);
      env.auth.signOutGate = Completer();

      await _tapLogout(t);

      expect(_msgSendFailed, findsNothing);
    });

    spec('LGL-A44', 'ログアウトの応答を待っている間に同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままである',
        (t) async {
      await _launchDialog(t, configure: (e) => e.auth.signOutGate = Completer());
      await _tapLogout(t);

      await _tapOutside(t);

      expect(_title, findsOneWidget);
    });

    spec('LGL-A45', 'ログアウトの応答を待っている間に戻る操作をした場合、同意ダイアログは表示されたままである',
        (t) async {
      await _launchDialog(t, configure: (e) => e.auth.signOutGate = Completer());
      await _tapLogout(t);

      await _back(t);

      expect(_title, findsOneWidget);
    });

    spec('LGL-A46', 'ログアウトが失敗して「ログアウトできませんでした。」が表示された後に「プライバシーポリシーに同意する」をチェックした場合、「ログアウトできませんでした。」は表示されたままである',
        (t) async {
      await _launchDialog(t, configure: (e) => e.auth.signOutFailure = _unknown);
      await _check(t, _termsLabel);
      await _tapLogout(t);
      expect(_msgSignOutFailed, findsOneWidget);

      await _check(t, _privacyLabel);

      expect(_msgSignOutFailed, findsOneWidget);
    });

    spec('LGL-A47', '送信が失敗して「同意を送信できませんでした。」が表示された後に「利用規約に同意する」のチェックを外した場合、「同意を送信できませんでした。」は表示されたままである',
        (t) async {
      await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_unknown));
      await _checkBoth(t);
      await _tapAgree(t);
      expect(_msgSendFailed, findsOneWidget);

      await _check(t, _termsLabel);

      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_msgSendFailed, findsOneWidget);
    });

    spec('LGL-A48', 'ログアウトが失敗して「ログアウトできませんでした。」が表示された後に「同意する」をタップして応答を待っている場合、「ログアウトできませんでした。」は表示されない',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.auth.signOutFailure = _unknown);
      await _checkBoth(t);
      await _tapLogout(t);
      expect(_msgSignOutFailed, findsOneWidget);
      env.legal.acceptGate = Completer();

      await _tapAgree(t);

      expect(_msgSignOutFailed, findsNothing);
    });

    spec('LGL-A49', 'ログアウトが失敗して「ログアウトできませんでした。」が表示された後に「ログアウト」をもう一度タップして応答を待っている場合、「ログアウトできませんでした。」は表示されない',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.auth.signOutFailure = _unknown);
      await _tapLogout(t);
      expect(_msgSignOutFailed, findsOneWidget);
      env.auth.signOutGate = Completer();

      await _tapLogout(t);

      expect(_msgSignOutFailed, findsNothing);
    });

    spec('LGL-A50', '「内容が更新されました。」が表示された後に「ログアウト」をタップして応答を待っている場合、「内容が更新されました。」は表示されない',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(terms: '2026-02-01');
      await _tapAgree(t);
      expect(_msgOutdated, findsOneWidget);
      env.auth.signOutGate = Completer();

      await _tapLogout(t);

      expect(_msgOutdated, findsNothing);
    });

    spec('LGL-A51', '「内容が更新されました。」が表示された後に再度チェックして「同意する」をタップし2回目の応答を待っている場合、「内容が更新されました。」は表示されない',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(terms: '2026-02-01');
      await _tapAgree(t);
      expect(_msgOutdated, findsOneWidget);
      await _checkBoth(t);
      env.legal.acceptGate = Completer();

      await _tapAgree(t);

      expect(_msgOutdated, findsNothing);
    });

    spec('LGL-A52', '「ログアウト」が NetworkFailure で失敗した場合、「ログアウトできませんでした。」が表示され「通信エラー」ダイアログは表示されない',
        (t) async {
      await _launchDialog(t, configure: (e) => e.auth.signOutFailure = _network);

      await _tapLogout(t);

      expect(_title, findsOneWidget);
      expect(_msgSignOutFailed, findsOneWidget);
      expect(_networkTitle, findsNothing);
    });

    spec('LGL-A53', '「ログアウト」が AuthFailure で失敗した場合、「ログアウトできませんでした。」が表示され「通信エラー」ダイアログは表示されない',
        (t) async {
      await _launchDialog(t, configure: (e) => e.auth.signOutFailure = _auth);

      await _tapLogout(t);

      expect(_title, findsOneWidget);
      expect(_msgSignOutFailed, findsOneWidget);
      expect(_networkTitle, findsNothing);
    });

    spec('LGL-A54', '「フォルダを作成」ダイアログの上の同意ダイアログで「ログアウト」が成功した場合、2つのダイアログが閉じログイン画面が表示される',
        (t) async {
      final env = await _launchCreateDialogWithConsent(t);

      await _tapLogout(t);

      expect(_title, findsNothing);
      expect(find.text('フォルダを作成'), findsNothing);
      expect(env.path, '/login');
    });

    spec('LGL-A55', '「フォルダを作成」ダイアログの上の同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままで、同意すると「フォルダを作成」ダイアログが「英単語」が入ったまま残っている',
        (t) async {
      await _launchCreateDialogWithConsent(t);

      await _tapOutside(t);
      expect(_title, findsOneWidget);

      await _check(t, _termsLabel);
      await _tapAgree(t);
      expect(_title, findsNothing);
      _expectCreateDialogWithText(t);
    });

    spec('LGL-A56', '「フォルダを作成」ダイアログの上の同意ダイアログで戻る操作をした場合、同意ダイアログは表示されたままで「フォルダを作成」ダイアログも閉じない',
        (t) async {
      await _launchCreateDialogWithConsent(t);

      await _back(t);

      expect(_title, findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.text('フォルダを作成')),
          findsOneWidget);
    });

    spec('LGL-A57', 'app_config/legal が無く未同意の状態で2つチェックして「同意する」をタップし送信が accepted を返した場合、同意ダイアログが閉じ送信が既定値の版数（2026-10-12）で1回呼ばれる',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.configFailure = _notFound);
      await _checkBoth(t);

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(env.legal.acceptCalls, [(terms: '2026-10-12', privacy: '2026-10-12')]);
    });

    spec('LGL-A58', 'outdated の後の判定し直しで app_config/legal が無かった場合、同意ダイアログが2つの行が未チェックで表示し直され「内容が更新されました。」が表示される',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(terms: '2026-02-01');
      env.legal.configFailure = _notFound;

      await _tapAgree(t);

      expect(_title, findsOneWidget);
      _expectBothRows();
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_msgOutdated, findsOneWidget);
    });
  });
}

// ─── 3.3 規約の閲覧 ───

void _browseTests() {
  group('LegalDocumentPage 規約の閲覧', () {
    spec('LGL-B01', '「利用規約を読む」をタップした場合、閲覧画面にタイトル「利用規約」と戻るボタンが表示され WebView に利用規約の URL の読み込みが指示される',
        (t) async {
      final env = await _launchDialog(t);

      await _tap(t, _termsLink);

      _expectDocument('利用規約');
      expect(env.web.loadCount(_termsUrl), 1);
    });

    spec('LGL-B02', '「プライバシーポリシーを読む」をタップした場合、閲覧画面にタイトル「プライバシーポリシー」と戻るボタンが表示され WebView にプライバシーポリシーの URL の読み込みが指示される',
        (t) async {
      final env = await _launchDialog(t);

      await _tap(t, _privacyLink);

      _expectDocument('プライバシーポリシー');
      expect(env.web.loadCount(_privacyUrl), 1);
    });

    spec('LGL-B03', '「利用規約を読む」をタップしてページの読み込みが終わっていない場合、閲覧画面にローディングが表示される',
        (t) async {
      await _launchDialog(t);

      await _tap(t, _termsLink);

      expect(find.descendant(of: _document, matching: _spinner), findsOneWidget);
    });

    spec('LGL-B04', '「利用規約を読む」のページの読み込みが通信の失敗で失敗した場合、閲覧画面にエラーの文言と「再読み込み」が表示され「通信エラー」ダイアログは表示されず閲覧画面は開いたままである',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _termsLink);

      env.web.callbacks!.onError();
      await _settle(t);

      expect(find.text(_loadFailedText), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
      expect(_networkTitle, findsNothing);
      expect(_document, findsOneWidget);
    });

    spec('LGL-B05', '読み込みに失敗して「再読み込み」をタップし2回目の読み込みが終わっていない場合、エラーの文言と「再読み込み」が消えローディングが表示され WebView に利用規約の読み込みが合計2回指示される',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _termsLink);
      env.web.callbacks!.onError();
      await _settle(t);

      await _tap(t, find.text('再読み込み'));

      expect(find.text(_loadFailedText), findsNothing);
      expect(find.text('再読み込み'), findsNothing);
      expect(find.descendant(of: _document, matching: _spinner), findsOneWidget);
      expect(env.web.loadCount(_termsUrl), 2);
    });

    spec('LGL-B06', '「利用規約に同意する」をチェックして閲覧画面を開き戻るボタンをタップした場合、閲覧画面が閉じ同意ダイアログで利用規約はチェックされたままプライバシーポリシーは未チェックのままである',
        (t) async {
      await _launchDialog(t);
      await _check(t, _termsLabel);
      await _tap(t, _termsLink);

      await _tapDocBack(t);

      expect(_document, findsNothing);
      expect(_title, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isTrue);
      expect(_isChecked(t, _privacyLabel), isFalse);
    });

    spec('LGL-B07', '「利用規約に同意する」をチェックして閲覧画面を開き戻る操作をした場合、閲覧画面が閉じ同意ダイアログで利用規約はチェックされたままである',
        (t) async {
      await _launchDialog(t);
      await _check(t, _termsLabel);
      await _tap(t, _termsLink);

      await _back(t);

      expect(_document, findsNothing);
      expect(_title, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isTrue);
    });

    spec('LGL-B08', 'チェックをせずに閲覧画面を開いて戻るボタンをタップした場合、2つのチェックボックスは未チェックのままで「同意する」は無効のままである',
        (t) async {
      await _launchDialog(t);
      await _tap(t, _termsLink);

      await _tapDocBack(t);

      expect(_title, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_agreeEnabled(t), isFalse);
    });

    spec('LGL-B09', '「利用規約を読む」で閲覧画面を開いて戻るボタンをタップした場合、画面のパスは /home のままで同意ダイアログは1つだけ表示されている',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _termsLink);

      await _tapDocBack(t);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
    });

    spec('LGL-B10', '「プライバシーポリシーを読む」をタップしてページの読み込みが終わっていない場合、閲覧画面にローディングが表示される',
        (t) async {
      await _launchDialog(t);

      await _tap(t, _privacyLink);

      expect(find.descendant(of: _document, matching: _spinner), findsOneWidget);
    });

    spec('LGL-B11', '「プライバシーポリシーを読む」のページの読み込みが通信の失敗で失敗した場合、閲覧画面にエラーの文言と「再読み込み」が表示され「通信エラー」ダイアログは表示されず閲覧画面は開いたままである',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _privacyLink);

      env.web.callbacks!.onError();
      await _settle(t);

      expect(find.text(_loadFailedText), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
      expect(_networkTitle, findsNothing);
      expect(_document, findsOneWidget);
    });

    spec('LGL-B12', 'プライバシーポリシーの読み込みに失敗して「再読み込み」をタップし2回目の読み込みが終わっていない場合、エラーの文言と「再読み込み」が消えローディングが表示され WebView にプライバシーポリシーの読み込みが合計2回指示される',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _privacyLink);
      env.web.callbacks!.onError();
      await _settle(t);

      await _tap(t, find.text('再読み込み'));

      expect(find.text(_loadFailedText), findsNothing);
      expect(find.text('再読み込み'), findsNothing);
      expect(find.descendant(of: _document, matching: _spinner), findsOneWidget);
      expect(env.web.loadCount(_privacyUrl), 2);
    });

    spec('LGL-B13', '「プライバシーポリシーに同意する」をチェックして閲覧画面を開き戻るボタンをタップした場合、閲覧画面が閉じプライバシーポリシーはチェックされたまま利用規約は未チェックのままである',
        (t) async {
      await _launchDialog(t);
      await _check(t, _privacyLabel);
      await _tap(t, _privacyLink);

      await _tapDocBack(t);

      expect(_document, findsNothing);
      expect(_title, findsOneWidget);
      expect(_isChecked(t, _privacyLabel), isTrue);
      expect(_isChecked(t, _termsLabel), isFalse);
    });

    spec('LGL-B14', '「プライバシーポリシーに同意する」をチェックして閲覧画面を開き戻る操作をした場合、閲覧画面が閉じプライバシーポリシーはチェックされたままである',
        (t) async {
      await _launchDialog(t);
      await _check(t, _privacyLabel);
      await _tap(t, _privacyLink);

      await _back(t);

      expect(_document, findsNothing);
      expect(_title, findsOneWidget);
      expect(_isChecked(t, _privacyLabel), isTrue);
    });

    spec('LGL-B15', 'チェックをせずにプライバシーポリシーの閲覧画面を開いて戻るボタンをタップした場合、2つのチェックボックスは未チェックのままで「同意する」は無効のままである',
        (t) async {
      await _launchDialog(t);
      await _tap(t, _privacyLink);

      await _tapDocBack(t);

      expect(_title, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_agreeEnabled(t), isFalse);
    });

    spec('LGL-B16', '「プライバシーポリシーを読む」で閲覧画面を開いて戻るボタンをタップした場合、画面のパスは /home のままで同意ダイアログは1つだけ表示されている',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _privacyLink);

      await _tapDocBack(t);

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
    });

    spec('LGL-B17', '「利用規約を読む」を素早く2回タップした場合、閲覧画面は1つだけ開き、戻るボタンを1回タップすると同意ダイアログが表示される',
        (t) async {
      await _launchDialog(t);

      await t.tap(_termsLink);
      await t.tap(_termsLink, warnIfMissed: false);
      await _settle(t);
      expect(_document, findsOneWidget);

      await _tapDocBack(t);

      expect(_document, findsNothing);
      expect(_title, findsOneWidget);
    });

    spec('LGL-B18', '「利用規約を読む」のページが HTTP ステータス 404 を返した場合、閲覧画面にエラーの文言と「再読み込み」が表示される',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _termsLink);

      // HTTP エラー（404）も WebView からは onError として通知される
      env.web.callbacks!.onError();
      await _settle(t);

      expect(find.text(_loadFailedText), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
    });

    spec('LGL-B19', '読み込みが失敗して「再読み込み」をタップした2回目の読み込みも失敗した場合、閲覧画面にエラーの文言と「再読み込み」が表示される',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _termsLink);
      env.web.callbacks!.onError();
      await _settle(t);
      await _tap(t, find.text('再読み込み'));

      env.web.callbacks!.onError();
      await _settle(t);

      expect(find.text(_loadFailedText), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);
    });

    spec('LGL-B20', '「利用規約を読む」をタップしてページの読み込みが終わる前に戻るボタンをタップした場合、閲覧画面が閉じ同意ダイアログが表示される',
        (t) async {
      await _launchDialog(t);
      await _tap(t, _termsLink);

      await _tapDocBack(t);

      expect(_document, findsNothing);
      expect(_title, findsOneWidget);
    });

    spec('LGL-B21', 'WebView の中のリンクから別のページに移った後に戻るボタンをタップした場合、閲覧画面が閉じ同意ダイアログが表示される',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _termsLink);
      // ページの中で別のページに移り、読み込みが終わった
      env.web.callbacks!.onFinished();
      await _settle(t);

      await _tapDocBack(t);

      expect(_document, findsNothing);
      expect(_title, findsOneWidget);
    });

    spec('LGL-B22', 'WebView の中のリンクから別のページに移った後に戻る操作をした場合、閲覧画面が閉じ同意ダイアログが表示される',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _termsLink);
      env.web.callbacks!.onFinished();
      await _settle(t);

      await _back(t);

      expect(_document, findsNothing);
      expect(_title, findsOneWidget);
    });

    spec('LGL-B23', '現行の利用規約の URL が変わり outdated で表示し直された同意ダイアログで「利用規約を読む」をタップした場合、WebView に新しい URL の読み込みが指示される',
        (t) async {
      final env = await _launchDialog(t,
          configure: (e) => e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated)));
      await _checkBoth(t);
      env.bump(terms: '2026-02-01', termsUrl: 'https://example.com/terms-v2');
      await _tapAgree(t);

      await _tap(t, _termsLink);

      expect(env.web.loadCount('https://example.com/terms-v2'), 1);
    });

    spec('LGL-B24', '読み込みに失敗して「再読み込み」を素早く2回タップした場合、WebView に利用規約の読み込みが合計2回指示される',
        (t) async {
      final env = await _launchDialog(t);
      await _tap(t, _termsLink);
      env.web.callbacks!.onError();
      await _settle(t);

      await t.tap(find.text('再読み込み'));
      await t.tap(find.text('再読み込み'), warnIfMissed: false);
      await _settle(t);

      expect(env.web.loadCount(_termsUrl), 2);
    });

    spec('LGL-B25', '設定画面を開いた場合、「このアプリについて」「利用規約」「プライバシーポリシー」が「外観」の項目より下で「アカウント」より上にこの順で表示される',
        (t) async {
      await _launch(t, configure: _matched);
      await _goSettings(t);

      double top(String text) => t.getTopLeft(find.text(text)).dy;
      expect(find.text('このアプリについて'), findsOneWidget);
      expect(top('外観'), lessThan(top('ダークモード')));
      expect(top('ダークモード'), lessThan(top('カラーテーマ')));
      expect(top('カラーテーマ'), lessThan(top('このアプリについて')));
      expect(top('このアプリについて'), lessThan(top('利用規約')));
      expect(top('利用規約'), lessThan(top('プライバシーポリシー')));
      expect(top('プライバシーポリシー'), lessThan(top('アカウント')));
    });

    spec('LGL-B26', '設定画面で「利用規約」をタップして読み取りが成功した場合、閲覧画面にタイトル「利用規約」と戻るボタンが表示され WebView に利用規約の URL の読み込みが指示される',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);

      await _tap(t, _settingsItem('利用規約'));

      _expectDocument('利用規約');
      expect(env.web.loadCount(_termsUrl), 1);
    });

    spec('LGL-B27', '設定画面で「プライバシーポリシー」をタップして読み取りが成功した場合、閲覧画面にタイトル「プライバシーポリシー」と戻るボタンが表示され WebView にプライバシーポリシーの URL の読み込みが指示される',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);

      await _tap(t, _settingsItem('プライバシーポリシー'));

      _expectDocument('プライバシーポリシー');
      expect(env.web.loadCount(_privacyUrl), 1);
    });

    spec('LGL-B28', '設定画面で「利用規約」から閲覧画面を開いて戻るボタンをタップした場合、閲覧画面が閉じ設定画面が表示され同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      await _tap(t, _settingsItem('利用規約'));

      await _tapDocBack(t);

      expect(_document, findsNothing);
      expect(env.path, '/settings');
      expect(find.text('このアプリについて'), findsOneWidget);
      expect(_title, findsNothing);
    });

    spec('LGL-B29', '設定画面で「プライバシーポリシー」から閲覧画面を開いて戻る操作をした場合、閲覧画面が閉じ設定画面が表示される',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      await _tap(t, _settingsItem('プライバシーポリシー'));

      await _back(t);

      expect(_document, findsNothing);
      expect(env.path, '/settings');
      expect(find.text('このアプリについて'), findsOneWidget);
    });

    spec('LGL-B30', '設定画面で「利用規約」をタップして読み取りが UnknownFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され画面のパスは /settings のままである',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      env.legal.configFailure = _unknown;

      await _tap(t, _settingsItem('利用規約'));

      expect(_document, findsNothing);
      expect(find.text(_openFailedText), findsOneWidget);
      expect(env.path, '/settings');
    });

    spec('LGL-B31', '設定画面で「利用規約」をタップして読み取りが NetworkFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され「通信エラー」ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      env.legal.configFailure = _network;

      await _tap(t, _settingsItem('利用規約'));

      expect(_document, findsNothing);
      expect(find.text(_openFailedText), findsOneWidget);
      expect(_networkTitle, findsNothing);
      expect(env.path, '/settings');
    });

    spec('LGL-B33', '設定画面で「利用規約」をタップして読み取りの応答を待っている間にもう一度タップした場合、読み取りが成功すると閲覧画面が1つだけ開き、戻るボタンを1回タップすると設定画面が表示される',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      env.legal.configGate = Completer();

      await t.tap(_settingsItem('利用規約'));
      await t.tap(_settingsItem('利用規約'));
      await _settle(t);
      env.legal.configGate!.complete();
      await _settle(t);
      expect(_document, findsOneWidget);

      await _tapDocBack(t);
      expect(_document, findsNothing);
      expect(env.path, '/settings');
    });

    spec('LGL-B34', '設定画面で「プライバシーポリシー」をタップして読み取りが UnknownFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され画面のパスは /settings のままである',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      env.legal.configFailure = _unknown;

      await _tap(t, _settingsItem('プライバシーポリシー'));

      expect(_document, findsNothing);
      expect(find.text(_openFailedText), findsOneWidget);
      expect(env.path, '/settings');
    });

    spec('LGL-B36', '設定画面で「プライバシーポリシー」をタップして読み取りが NetworkFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され「通信エラー」ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      env.legal.configFailure = _network;

      await _tap(t, _settingsItem('プライバシーポリシー'));

      expect(_document, findsNothing);
      expect(find.text(_openFailedText), findsOneWidget);
      expect(_networkTitle, findsNothing);
      expect(env.path, '/settings');
    });

    spec('LGL-B37', '設定画面で「プライバシーポリシー」をタップして読み取りの応答を待っている間にもう一度タップした場合、読み取りが成功すると閲覧画面が1つだけ開き、戻るボタンを1回タップすると設定画面が表示される',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      env.legal.configGate = Completer();

      await t.tap(_settingsItem('プライバシーポリシー'));
      await t.tap(_settingsItem('プライバシーポリシー'));
      await _settle(t);
      env.legal.configGate!.complete();
      await _settle(t);
      expect(_document, findsOneWidget);

      await _tapDocBack(t);
      expect(_document, findsNothing);
      expect(env.path, '/settings');
    });

    spec('LGL-B38', '設定画面で「利用規約」から閲覧画面を開いて戻る操作をした場合、閲覧画面が閉じ設定画面が表示される',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      await _tap(t, _settingsItem('利用規約'));

      await _back(t);

      expect(_document, findsNothing);
      expect(env.path, '/settings');
      expect(find.text('このアプリについて'), findsOneWidget);
    });

    spec('LGL-B39', '設定画面で「プライバシーポリシー」から閲覧画面を開いて戻るボタンをタップした場合、閲覧画面が閉じ設定画面が表示され同意ダイアログは表示されない',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      await _tap(t, _settingsItem('プライバシーポリシー'));

      await _tapDocBack(t);

      expect(_document, findsNothing);
      expect(env.path, '/settings');
      expect(_title, findsNothing);
    });

    spec('LGL-B40', '設定画面で「利用規約」をタップして読み取りの応答を待っている場合、「利用規約」の項目にローディングが表示される',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      env.legal.configGate = Completer();

      await _tap(t, _settingsItem('利用規約'));

      expect(
          find.descendant(of: _settingsItem('利用規約'), matching: _spinner),
          findsOneWidget);
    });

    spec('LGL-B41', '設定画面で「プライバシーポリシー」をタップして読み取りの応答を待っている場合、「プライバシーポリシー」の項目にローディングが表示される',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      env.legal.configGate = Completer();

      await _tap(t, _settingsItem('プライバシーポリシー'));

      expect(
          find.descendant(
              of: _settingsItem('プライバシーポリシー'), matching: _spinner),
          findsOneWidget);
    });

    spec('LGL-B42', 'app_config/legal が無い状態で設定画面の「利用規約」をタップした場合、閲覧画面が開き既定値の利用規約の URL の読み込みが指示されスナックバーは表示されない',
        (t) async {
      final env = await _launch(t, configure: (e) {
        e.legal.configFailure = _notFound;
        e.legal.consents = const Right(
            LegalConsents(termsVersion: '2026-10-12', privacyVersion: '2026-10-12'));
      });
      await _goSettings(t);

      await _tap(t, _settingsItem('利用規約'));

      _expectDocument('利用規約');
      expect(env.web.loadCount('https://word-pods-web.web.app/terms'), 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    spec('LGL-B43', 'app_config/legal が無い状態で設定画面の「プライバシーポリシー」をタップした場合、閲覧画面が開き既定値のプライバシーポリシーの URL の読み込みが指示されスナックバーは表示されない',
        (t) async {
      final env = await _launch(t, configure: (e) {
        e.legal.configFailure = _notFound;
        e.legal.consents = const Right(
            LegalConsents(termsVersion: '2026-10-12', privacyVersion: '2026-10-12'));
      });
      await _goSettings(t);

      await _tap(t, _settingsItem('プライバシーポリシー'));

      _expectDocument('プライバシーポリシー');
      expect(env.web.loadCount('https://word-pods-web.web.app/privacy'), 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    spec('LGL-B44', 'app_config/legal が無く未同意の状態で起動し「利用規約を読む」をタップした場合、閲覧画面が開き既定値の利用規約の URL の読み込みが指示される',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.configFailure = _notFound);

      await _tap(t, _termsLink);

      expect(_document, findsOneWidget);
      expect(env.web.loadCount('https://word-pods-web.web.app/terms'), 1);
    });

    spec('LGL-B45', 'app_config/legal が無く未同意の状態で起動し「プライバシーポリシーを読む」をタップした場合、閲覧画面が開き既定値のプライバシーポリシーの URL の読み込みが指示される',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.configFailure = _notFound);

      await _tap(t, _privacyLink);

      expect(_document, findsOneWidget);
      expect(env.web.loadCount('https://word-pods-web.web.app/privacy'), 1);
    });

    spec('LGL-B46', '設定画面で「利用規約」をタップして読み取りの応答を待っている間に「プライバシーポリシー」をタップした場合、読み取りが成功すると閲覧画面が1つだけ開きタイトルは「利用規約」である',
        (t) async {
      final env = await _launch(t, configure: _matched);
      await _goSettings(t);
      env.legal.configGate = Completer();

      await t.tap(_settingsItem('利用規約'));
      await t.tap(_settingsItem('プライバシーポリシー'));
      await _settle(t);
      env.legal.configGate!.complete();
      await _settle(t);

      _expectDocument('利用規約');
      expect(
          find.descendant(of: _document, matching: find.text('プライバシーポリシー')),
          findsNothing);
    });
  });
}

// ─── 3.4 エラー種別ごとの扱い ───

void _errorTests() {
  group('LegalConsentGate エラー種別ごとの扱い', () {
    spec('LGL-E02', '同意済みの版数の読み取りが NetworkFailure で失敗する状態で起動した場合、ホーム画面が表示され同意ダイアログも「通信エラー」ダイアログも表示されない',
        (t) async {
      final env = await _launch(t,
          configure: (e) => e.legal.consents = const Left(_network));

      expect(env.path, '/home');
      _expectNoDialogs();
    });

    spec('LGL-E03', '同意済みの版数の読み取りが UnknownFailure で失敗する状態で起動した場合、ホーム画面が表示され同意ダイアログも失敗の表示も出ない',
        (t) async {
      final env = await _launch(t,
          configure: (e) => e.legal.consents = const Left(_unknown));

      expect(env.path, '/home');
      _expectNoDialogs();
      expect(find.byType(SnackBar), findsNothing);
    });

    spec('LGL-E04', '送信が NetworkFailure で失敗した場合、同意ダイアログが閉じタイトル「通信エラー」・本文・「OK」ボタンのダイアログが表示される',
        (t) async {
      await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_network));
      await _checkBoth(t);

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(_networkTitle, findsOneWidget);
      expect(_networkBody, findsOneWidget);
      expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);
    });

    spec('LGL-E05', '送信が NetworkFailure で失敗した「通信エラー」ダイアログで「OK」をタップしてログアウトが成功した場合、ログイン画面に移動し同意ダイアログは表示されず SignOutUseCase が1回呼ばれる',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_network));
      await _checkBoth(t);
      await _tapAgree(t);

      await _tap(t, find.widgetWithText(TextButton, 'OK'));

      expect(env.path, '/login');
      expect(_title, findsNothing);
      expect(env.auth.signOutCount, 1);
    });

    spec('LGL-E06', '送信が AuthFailure で失敗した場合、同意ダイアログが閉じタイトル「通信エラー」・本文・「OK」ボタンのダイアログが表示される',
        (t) async {
      await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_auth));
      await _checkBoth(t);

      await _tapAgree(t);

      expect(_title, findsNothing);
      expect(_networkTitle, findsOneWidget);
      expect(_networkBody, findsOneWidget);
      expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);
    });

    spec('LGL-E07', '送信が AuthFailure で失敗した「通信エラー」ダイアログで「OK」をタップしてログアウトが成功した場合、ログイン画面に移動し同意ダイアログは表示されず SignOutUseCase が1回呼ばれる',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_auth));
      await _checkBoth(t);
      await _tapAgree(t);

      await _tap(t, find.widgetWithText(TextButton, 'OK'));

      expect(env.path, '/login');
      expect(_title, findsNothing);
      expect(env.auth.signOutCount, 1);
    });

    spec('LGL-E08', '通信エラーでログイン画面に移動した後に同じ uid でもう一度ログインして未同意のままの場合、ホーム画面に移動し2つのチェックが未チェックの同意ダイアログが表示される',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_network));
      await _checkBoth(t);
      await _tapAgree(t);
      await _tap(t, find.widgetWithText(TextButton, 'OK'));
      expect(env.path, '/login');
      env.legal.acceptResult = const Right(LegalAcceptResult.accepted);

      await t.enterText(find.byType(TextFormField).at(0), 'a@example.com');
      await t.enterText(find.byType(TextFormField).at(1), 'password1');
      await _tap(t, find.widgetWithText(FilledButton, 'ログイン'));

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
      _expectBothRows();
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_isChecked(t, _privacyLabel), isFalse);
    });

    spec('LGL-E09', '「通信エラー」ダイアログで「OK」をタップしてログアウトが UnknownFailure で失敗した場合、ホーム画面の上に未チェックの同意ダイアログが表示され「ログアウトできませんでした。」は表示されない',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_network));
      await _checkBoth(t);
      await _tapAgree(t);
      env.auth.signOutFailure = _unknown;

      await _tap(t, find.widgetWithText(TextButton, 'OK'));

      expect(env.path, '/home');
      expect(_title, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_msgSignOutFailed, findsNothing);
    });

    spec('LGL-E10', '「通信エラー」ダイアログの表示中に復帰した場合、「通信エラー」ダイアログは1つだけ表示されたままで同意ダイアログは表示されない',
        (t) async {
      await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_network));
      await _checkBoth(t);
      await _tapAgree(t);
      expect(_networkTitle, findsOneWidget);

      await _resume(t);

      expect(_networkTitle, findsOneWidget);
      expect(_title, findsNothing);
    });

    spec('LGL-E11', '「通信エラー」ダイアログの表示中に退会済みの記録ができた場合、「通信エラー」ダイアログが閉じ「アカウントが削除されました」ダイアログが表示され同意ダイアログは表示されず SignOutUseCase は0回である',
        (t) async {
      final env = await _launchDialog(t, configure: (e) => e.legal.acceptResult = const Left(_network));
      await _checkBoth(t);
      await _tapAgree(t);
      expect(_networkTitle, findsOneWidget);

      env.deletion.emitWithdrawn('A');
      await _settle(t);

      expect(_networkTitle, findsNothing);
      expect(_noticeTitle, findsOneWidget);
      expect(_title, findsNothing);
      expect(env.auth.signOutCount, 0);
    });
  });
}
