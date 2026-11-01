import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/app_lifecycle_observer.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/core/di/repository_providers.dart';
import 'package:word_pods/core/di/sync_providers.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/core/router/router.dart';
import 'package:word_pods/domain/entities/account_deletion_request.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/entities/user_settings.dart';
import 'package:word_pods/domain/repositories/account_deletion_repository.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/repositories/reauthentication_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_flashcard_result_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_folder_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_settings_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_sync_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_word_repository.dart';
import 'package:word_pods/presentation/settings/account_deletion_gate.dart';
import 'package:word_pods/presentation/settings/account_deletion_state.dart';
import 'package:word_pods/presentation/settings/account_deletion_view_model.dart';
import 'package:word_pods/presentation/settings/settings_page.dart';
import 'package:word_pods/presentation/settings/settings_view_model.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_gate.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_view_model.dart';

import '../../helpers/test_helpers.dart';

const _userId = 'mock-user-id';

/// 設定画面の項目が増えても「退会」等が表示範囲に入るよう、画面を縦に大きくする。
void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget buildSettingsPage({List<Override> extra = const []}) {
  return buildWithMockRepositories(child: const SettingsPage(), extra: extra);
}

void main() {
  group('SettingsPage', () {
    testWidgets('ローディング中は CircularProgressIndicator が表示される', (tester) async {
      _useTallView(tester);
      await tester.pumpWidget(buildSettingsPage(extra: [
        settingsViewModelProvider(_userId)
            .overrideWith(LoadingSettingsViewModel.new),
      ]));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('設定が読み込まれるとダークモードスイッチが表示される', (tester) async {
      _useTallView(tester);
      await tester.pumpWidget(buildSettingsPage(extra: [
        settingsViewModelProvider(_userId)
            .overrideWith(DataSettingsViewModel.new),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('ダークモード'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('カラーテーマのドロップダウンが表示される', (tester) async {
      _useTallView(tester);
      await tester.pumpWidget(buildSettingsPage(extra: [
        settingsViewModelProvider(_userId)
            .overrideWith(DataSettingsViewModel.new),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('カラーテーマ'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('ログアウト項目が表示される', (tester) async {
      _useTallView(tester);
      await tester.pumpWidget(buildSettingsPage(extra: [
        settingsViewModelProvider(_userId)
            .overrideWith(DataSettingsViewModel.new),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('ログアウト'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('ログアウトをタップすると確認ダイアログが表示される', (tester) async {
      _useTallView(tester);
      await tester.pumpWidget(buildSettingsPage(extra: [
        settingsViewModelProvider(_userId)
            .overrideWith(DataSettingsViewModel.new),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ログアウト'));
      await tester.pumpAndSettle();

      expect(find.text('ログアウトしますか？'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });
  });

  _withdrawalTests();
  _withdrawnElsewhereTests();
  _reauthenticationTests();
}

class LoadingSettingsViewModel extends SettingsViewModel {
  @override
  Future<UserSettings> build(String userId) =>
      Completer<UserSettings>().future;
}

class DataSettingsViewModel extends SettingsViewModel {
  @override
  Future<UserSettings> build(String userId) async =>
      const UserSettings(colorTheme: 'indigo', darkMode: false);
}

// ─── 退会（docs/detailed_design/presentation/settings/settings_page.md 3章） ───

const _userA = AppUser(id: 'A', email: 'a@example.com');
const _userB = AppUser(id: 'B', email: 'b@example.com');

/// メールアドレスとパスワードで登録したユーザー（hasPassword が true）
const _userAWithPassword =
    AppUser(id: 'A', email: 'a@example.com', hasPassword: true);

const Failure _network = Failure.network();
const Failure _auth = Failure.auth();
const Failure _unknown = Failure.unknown('x');
const Failure _recentLogin = Failure.recentLoginRequired();
const Failure _tooMany = Failure.tooManyRequests();

/// 退会用の手書き Fake。呼び出しを記録し、Failure の注入と Completer による応答待ちができる。
class _FakeAccountDeletionRepository implements AccountDeletionRepository {
  AccountDeletionRequest? record;

  Failure? findPendingFailure;
  Failure? markRequestedFailure;
  Failure? markServerDoneFailure;
  Failure? clearRequestFailure;
  Failure? requestFailure;

  /// requestServerDeletion の結果を呼び出し順に差し込む（尽きたら requestFailure）
  List<Failure?> requestResults = [];
  Failure? deleteLocalFailure;

  Completer<void>? findPendingGate;
  Completer<void>? requestGate;
  Completer<void>? deleteLocalGate;

  int requestCount = 0;
  int deleteLocalCount = 0;

  @override
  Future<Either<Failure, Option<AccountDeletionRequest>>> findPending() async {
    final gate = findPendingGate;
    if (gate != null) await gate.future;
    final f = findPendingFailure;
    if (f != null) return Left(f);
    return Right(optionOf(record));
  }

  @override
  Future<Either<Failure, Unit>> markRequested(String userId) async {
    final f = markRequestedFailure;
    if (f != null) return Left(f);
    record = AccountDeletionRequest(
      userId: userId,
      status: AccountDeletionStatus.requested,
      updatedAt: DateTime(2026, 10, 3),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> markServerDone(String userId) async {
    final f = markServerDoneFailure;
    if (f != null) return Left(f);
    record = AccountDeletionRequest(
      userId: userId,
      status: AccountDeletionStatus.serverDone,
      updatedAt: DateTime(2026, 10, 3),
    );
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> clearRequest(String userId) async {
    final f = clearRequestFailure;
    if (f != null) return Left(f);
    record = null;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> requestServerDeletion() async {
    final call = requestCount;
    requestCount++;
    final gate = requestGate;
    if (gate != null) await gate.future;
    final f = call < requestResults.length ? requestResults[call] : requestFailure;
    return f != null ? Left(f) : const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteLocalData(String userId) async {
    deleteLocalCount++;
    final gate = deleteLocalGate;
    if (gate != null) await gate.future;
    final f = deleteLocalFailure;
    if (f != null) return Left(f);
    record = null;
    return const Right(unit);
  }

  // 他の端末での退会（既定値は「退会済みの記録なし・強制ログアウトの記録なし・端末内の uid なし」）
  /// 退会済みの記録がある uid
  final Set<String> withdrawn = {};

  /// 端末内にデータがある uid
  List<String> localUserIds = [];

  /// 強制ログアウトの記録の uid
  String? forcedUid;

  /// オフライン（isWithdrawnOnServer が NetworkFailure になる）
  bool offline = false;
  Failure? isWithdrawnFailure;
  Completer<void>? isWithdrawnGate;

  /// deleteLocalDataOfUsers の呼び出し記録（引数のコピー）
  final List<List<String>> deleteOfUsersCalls = [];

  /// deleteLocalDataOfUsers の結果を呼び出し順に差し込む（尽きたら deleteOfUsersFailure）
  List<Failure?> deleteOfUsersResults = [];
  Failure? deleteOfUsersFailure;
  Completer<void>? deleteOfUsersGate;

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
  Future<Either<Failure, List<String>>> findLocalUserIds() async =>
      Right(List.of(localUserIds));

  @override
  Future<Either<Failure, bool>> isWithdrawnOnServer(String userId) async {
    final gate = isWithdrawnGate;
    if (gate != null) await gate.future;
    if (offline) return const Left(Failure.network());
    final f = isWithdrawnFailure;
    if (f != null) return Left(f);
    return Right(withdrawn.contains(userId));
  }

  @override
  Stream<Either<Failure, bool>> watchWithdrawn(String userId) =>
      _watcher(userId).stream;

  @override
  Future<Either<Failure, Unit>> deleteLocalDataOfUsers(
      List<String> userIds) async {
    final call = deleteOfUsersCalls.length;
    deleteOfUsersCalls.add(List.of(userIds));
    final gate = deleteOfUsersGate;
    if (gate != null) await gate.future;
    final f = call < deleteOfUsersResults.length
        ? deleteOfUsersResults[call]
        : deleteOfUsersFailure;
    if (f != null) return Left(f);
    localUserIds = [
      for (final id in localUserIds)
        if (!userIds.contains(id)) id,
    ];
    return const Right(unit);
  }

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

/// 本人確認用の手書き Fake。成功・キャンセル・Failure・応答待ちを設定でき、呼び出しの回数と引数を記録する。
/// 既定は「本人確認は成功する」（仕様書 3章冒頭）。
class _FakeReauthenticationRepository implements ReauthenticationRepository {
  Failure? passwordFailure;
  Failure? googleFailure;

  /// true なら Google の本人確認がキャンセルされる（`Right(false)`）
  bool googleCancelled = false;

  /// reauthenticateWithPassword の結果を呼び出し順に差し込む（尽きたら passwordFailure）
  List<Failure?> passwordResults = [];

  /// 設定すると、完了するまで応答しない
  Completer<void>? gate;

  /// reauthenticateWithPassword に渡されたパスワード（呼び出し順）
  final List<String> passwordCalls = [];
  int googleCount = 0;

  @override
  Future<Either<Failure, Unit>> reauthenticateWithPassword(
      String password) async {
    final call = passwordCalls.length;
    passwordCalls.add(password);
    final g = gate;
    if (g != null) await g.future;
    final f = call < passwordResults.length ? passwordResults[call] : passwordFailure;
    return f != null ? Left(f) : const Right(unit);
  }

  @override
  Future<Either<Failure, bool>> reauthenticateWithGoogle() async {
    googleCount++;
    final g = gate;
    if (g != null) await g.future;
    final f = googleFailure;
    if (f != null) return Left(f);
    return Right(!googleCancelled);
  }
}

/// ログイン状態を持つ Fake。signOut に成功するとログアウト状態（null）を流す。
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  AppUser? user;
  Failure? signOutFailure;

  /// signOut の結果を呼び出し順に差し込む（尽きたら signOutFailure）
  List<Failure?> signOutResults = [];
  int signOutCount = 0;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield user;
    yield* _controller.stream;
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    final call = signOutCount;
    signOutCount++;
    final f = call < signOutResults.length ? signOutResults[call] : signOutFailure;
    if (f != null) return Left(f);
    user = null;
    _controller.add(null);
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Env {
  _Env({
    AppUser? user = _userA,
    String recordUserId = 'A',
    AccountDeletionStatus? status,
  }) {
    auth = _FakeAuthRepository(user);
    reauth = _FakeReauthenticationRepository();
    repo = _FakeAccountDeletionRepository()
      ..record = status == null
          ? null
          : AccountDeletionRequest(
              userId: recordUserId,
              status: status,
              updatedAt: DateTime(2026, 10, 3),
            );
  }

  late final _FakeAuthRepository auth;
  late final _FakeAccountDeletionRepository repo;
  late final _FakeReauthenticationRepository reauth;
  late ProviderContainer container;

  String get path => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .path;
}

/// app.dart と同じ構成（本物のルーター + AccountDeletionGate）。
class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      routerConfig: router,
      builder: (context, child) =>
          AccountDeletionGate(router: router, child: child!),
    );
  }
}

/// ローディングの無限アニメーションがあっても進められるよう、pumpAndSettle の代わりに使う。
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// アプリを起動し、起動時の確認（checkPending）を始め、スプラッシュの最低表示時間（2秒）を進める。
Future<_Env> _launch(
  WidgetTester tester, {
  AppUser? user = _userA,
  String recordUserId = 'A',
  AccountDeletionStatus? status,
  void Function(_Env env)? configure,
}) async {
  _useTallView(tester);
  final env = _Env(user: user, recordUserId: recordUserId, status: status);
  configure?.call(env);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(env.auth),
      accountDeletionRepositoryProvider.overrideWithValue(env.repo),
      reauthenticationRepositoryProvider.overrideWithValue(env.reauth),
      folderRepositoryProvider.overrideWithValue(MockFolderRepository()),
      wordRepositoryProvider.overrideWithValue(MockWordRepository()),
      settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      flashcardResultRepositoryProvider
          .overrideWithValue(MockFlashcardResultRepository()),
      syncRepositoryProvider.overrideWithValue(MockSyncRepository()),
    ],
    child: const _TestApp(),
  ));
  env.container =
      ProviderScope.containerOf(tester.element(find.byType(_TestApp)));
  unawaited(
      env.container.read(accountDeletionViewModelProvider.notifier).checkPending());
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await _settle(tester);
  return env;
}

Finder _navLabel(String label) => find.descendant(
    of: find.byType(NavigationBar), matching: find.text(label));

Future<void> _openSettingsTab(WidgetTester tester) async {
  await tester.tap(_navLabel('設定'));
  await _settle(tester);
}

/// 設定画面で「退会」→ 確認 OK → 最終確認 OK まで進める。
Future<void> _withdrawToFinalOk(WidgetTester tester) async {
  await tester.tap(find.text('退会'));
  await _settle(tester);
  await tester.tap(find.text('OK'));
  await _settle(tester);
  await tester.tap(find.text('OK'));
  await _settle(tester);
}

/// ログイン中の設定画面を開く。
Future<_Env> _launchSettings(
  WidgetTester tester, {
  AppUser? user = _userA,
  void Function(_Env env)? configure,
}) async {
  final env = await _launch(tester, user: user, configure: configure);
  await _openSettingsTab(tester);
  return env;
}

final _retryTitle = find.text('退会処理が完了していません');
final _processingText = find.text('退会処理中です');
final _completedText = find.text('退会が完了しました');
final _retryFailedText = find.text('再試行に失敗しました。通信環境を確認して、もう一度お試しください。');
final _retryButton = find.widgetWithText(FilledButton, '再試行');

Finder get _dialogButtons => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));

void _expectRetryDialogWithOnlyRetryButton() {
  expect(_retryTitle, findsOneWidget);
  expect(_retryButton, findsOneWidget);
  expect(_dialogButtons, findsOneWidget);
}

void _expectRetryFailedAndEnabled(WidgetTester tester) {
  expect(_retryTitle, findsOneWidget);
  expect(_retryFailedText, findsOneWidget);
  expect(tester.widget<FilledButton>(_retryButton).onPressed, isNotNull);
}

void _expectRetryProcessingAndDisabled(WidgetTester tester) {
  expect(_retryTitle, findsOneWidget);
  final inDialog = find.byType(AlertDialog);
  expect(find.descendant(of: inDialog, matching: _processingText),
      findsOneWidget);
  expect(
      find.descendant(
          of: inDialog, matching: find.byType(CircularProgressIndicator)),
      findsOneWidget);
  expect(tester.widget<FilledButton>(_retryButton).onPressed, isNull);
}

void _expectCompletedOnLogin(_Env env) {
  expect(env.path, '/login');
  expect(_completedText, findsOneWidget);
  expect(find.text('OK'), findsOneWidget);
}

void _expectNotSentDialogOnSettings(_Env env) {
  expect(find.text('退会できませんでした'), findsOneWidget);
  expect(find.text('通信環境を確認して、もう一度お試しください。'), findsOneWidget);
  expect(find.text('OK'), findsOneWidget);
  expect(_processingText, findsNothing);
  expect(env.path, '/settings');
  expect(find.text('通信エラー'), findsNothing);
}

/// モーダルのバリア（ダイアログの外側）をタップする。
Future<void> _tapOutside(WidgetTester tester) async {
  await tester.tapAt(const Offset(5, 5));
  await _settle(tester);
}

Future<void> _tapBlocked(WidgetTester tester, Finder finder) async {
  await tester.tap(finder, warnIfMissed: false);
  await _settle(tester);
}

void _withdrawalTests() {
  group('SettingsPage 退会：表示', () {
    testWidgets(
        'ログイン中で退会処理の記録が無い状態で設定画面を開いた場合、「アカウント」の下に「ログアウト」「退会」がこの順で表示され、「退会」はエラー色で Icons.person_remove が表示される [ACD-D01]',
        (tester) async {
      await _launchSettings(tester);

      final account = tester.getTopLeft(find.text('アカウント')).dy;
      final logout = tester.getTopLeft(find.text('ログアウト')).dy;
      final withdraw = tester.getTopLeft(find.text('退会')).dy;
      expect(account < logout, isTrue);
      expect(logout < withdraw, isTrue);

      final error = Theme.of(tester.element(find.text('退会'))).colorScheme.error;
      expect(tester.widget<Text>(find.text('退会')).style?.color, error);
      expect(tester.widget<Icon>(find.byIcon(Icons.person_remove)).color, error);
    });

    testWidgets(
        '退会処理の記録が無い状態でアプリを起動した場合、「退会処理が完了していません」ダイアログは表示されない [ACD-D02]',
        (tester) async {
      await _launch(tester);

      expect(_retryTitle, findsNothing);
    });

    testWidgets(
        'ログイン中で記録が requested の状態でアプリを起動した場合、再開ダイアログに本文と「再試行」だけが表示される [ACD-D03]',
        (tester) async {
      await _launch(tester, status: AccountDeletionStatus.requested);

      _expectRetryDialogWithOnlyRetryButton();
      expect(find.text('「再試行」を押して、退会処理を完了してください。'), findsOneWidget);
    });

    testWidgets(
        'ログインしていない状態で記録が serverDone の状態でアプリを起動した場合、ログイン画面の上に再開ダイアログと「再試行」だけが表示される [ACD-D04]',
        (tester) async {
      final env = await _launch(tester,
          user: null, status: AccountDeletionStatus.serverDone);

      expect(env.path, '/login');
      _expectRetryDialogWithOnlyRetryButton();
    });

    testWidgets(
        'ログインしていない状態で記録が requested の状態でアプリを起動した場合、ログイン画面の上に再開ダイアログと「再試行」だけが表示される [ACD-D05]',
        (tester) async {
      final env = await _launch(tester,
          user: null, status: AccountDeletionStatus.requested);

      expect(env.path, '/login');
      _expectRetryDialogWithOnlyRetryButton();
    });

    testWidgets(
        '再開ダイアログが表示されている状態（再試行の処理中ではない）でダイアログの外側をタップした場合、ダイアログは表示されたままで記録は変わらず関数は呼ばれない [ACD-D06]',
        (tester) async {
      final env = await _launch(tester, status: AccountDeletionStatus.requested);

      await _tapOutside(tester);

      expect(_retryTitle, findsOneWidget);
      expect(env.repo.record?.status, AccountDeletionStatus.requested);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        '再開ダイアログが表示されている状態（再試行の処理中ではない）で戻る操作をした場合、ダイアログは表示されたままで記録は変わらず関数は呼ばれない [ACD-D07]',
        (tester) async {
      final env = await _launch(tester, status: AccountDeletionStatus.requested);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_retryTitle, findsOneWidget);
      expect(env.repo.record?.status, AccountDeletionStatus.requested);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        'ログイン中で記録が serverDone の状態でアプリを起動した場合、再開ダイアログと「再試行」だけが表示される [ACD-D08]',
        (tester) async {
      await _launch(tester, status: AccountDeletionStatus.serverDone);

      _expectRetryDialogWithOnlyRetryButton();
    });

    testWidgets(
        '再開ダイアログが表示されている状態で背後のボトムナビ「設定」の位置をタップした場合、ダイアログは表示されたままで画面のパスは変わらない [ACD-D09]',
        (tester) async {
      final env = await _launch(tester, status: AccountDeletionStatus.requested);
      final before = env.path;

      await _tapBlocked(tester, _navLabel('設定'));

      expect(_retryTitle, findsOneWidget);
      expect(before, '/home');
      expect(env.path, before);
    });

    testWidgets(
        '記録が requested で「再試行」をタップし応答を待っている間に戻る操作をした場合、再開ダイアログは表示されたままで記録は変わらない [ACD-D10]',
        (tester) async {
      final env = await _launch(tester,
          status: AccountDeletionStatus.requested,
          configure: (e) => e.repo.requestGate = Completer<void>());
      await tester.tap(find.text('再試行'));
      await _settle(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_retryTitle, findsOneWidget);
      expect(env.repo.record?.status, AccountDeletionStatus.requested);
    });

    testWidgets(
        '記録が requested で「再試行」をタップし応答を待っている間にダイアログの外側をタップした場合、再開ダイアログは表示されたままで記録は変わらない [ACD-D11]',
        (tester) async {
      final env = await _launch(tester,
          status: AccountDeletionStatus.requested,
          configure: (e) => e.repo.requestGate = Completer<void>());
      await tester.tap(find.text('再試行'));
      await _settle(tester);

      await _tapOutside(tester);

      expect(_retryTitle, findsOneWidget);
      expect(env.repo.record?.status, AccountDeletionStatus.requested);
    });

    testWidgets(
        'ログイン中の uid が B で記録が uid A の requested の状態でアプリを起動した場合、再開ダイアログと「再試行」だけが表示される [ACD-D12]',
        (tester) async {
      await _launch(tester,
          user: _userB, status: AccountDeletionStatus.requested);

      _expectRetryDialogWithOnlyRetryButton();
    });

    testWidgets(
        'ログイン中で記録が requested の状態で「再試行」をタップし応答を待っている間に背後のボトムナビ「ホーム」の位置をタップした場合、再開ダイアログは表示されたままで画面のパスは変わらない [ACD-D13]',
        (tester) async {
      final env = await _launch(tester,
          status: AccountDeletionStatus.requested,
          configure: (e) => e.repo.requestGate = Completer<void>());
      await tester.tap(find.text('再試行'));
      await _settle(tester);
      final before = env.path;

      await _tapBlocked(tester, _navLabel('ホーム'));

      expect(_retryTitle, findsOneWidget);
      expect(env.path, before);
    });

    testWidgets(
        'ログインしていない状態で記録が serverDone で再開ダイアログが表示されている状態で背後の「ログイン」ボタンの位置をタップした場合、ダイアログは表示されたままで画面のパスは /login のままである [ACD-D14]',
        (tester) async {
      final env = await _launch(tester,
          user: null, status: AccountDeletionStatus.serverDone);

      await _tapBlocked(tester, find.text('ログイン'));

      expect(_retryTitle, findsOneWidget);
      expect(env.path, '/login');
    });

    testWidgets(
        '起動時の記録の読み取りが UnknownFailure で失敗した状態でアプリを起動した場合、再開ダイアログと「再試行」だけが表示される [ACD-D15]',
        (tester) async {
      await _launch(tester, configure: (e) => e.repo.findPendingFailure = _unknown);

      _expectRetryDialogWithOnlyRetryButton();
    });

    testWidgets(
        'ログイン中で起動時の記録の確認が終わっていない状態でアプリを起動した場合、スプラッシュ画面（/）が表示されたままでホーム画面に移動しない [ACD-D16]',
        (tester) async {
      final gate = Completer<void>();
      final env = await _launch(tester,
          configure: (e) => e.repo.findPendingGate = gate);

      expect(env.path, '/');
      expect(find.byType(NavigationBar), findsNothing);

      gate.complete();
      await _settle(tester);
    });
  });

  group('SettingsPage 退会：退会の操作', () {
    testWidgets(
        '設定画面で「退会」をタップした場合、タイトル「退会」・本文・「キャンセル」「OK」がこの順で横に並ぶダイアログが表示される [ACD-X01]',
        (tester) async {
      await _launchSettings(tester);

      await tester.tap(find.text('退会'));
      await _settle(tester);

      expect(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.text('退会')),
          findsOneWidget);
      expect(find.text('このアプリから退会いたしますか？'), findsOneWidget);
      final cancel = tester.getCenter(find.text('キャンセル'));
      final ok = tester.getCenter(find.text('OK'));
      expect(cancel.dx < ok.dx, isTrue);
      expect((cancel.dy - ok.dy).abs() < 1, isTrue);
    });

    testWidgets(
        '確認ダイアログで「キャンセル」をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X02]',
        (tester) async {
      final env = await _launchSettings(tester);
      await tester.tap(find.text('退会'));
      await _settle(tester);

      await tester.tap(find.text('キャンセル'));
      await _settle(tester);

      expect(find.text('このアプリから退会いたしますか？'), findsNothing);
      expect(env.path, '/settings');
      expect(env.repo.requestCount, 0);
      expect(env.repo.record, isNull);
    });

    testWidgets(
        '確認ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X03]',
        (tester) async {
      final env = await _launchSettings(tester);
      await tester.tap(find.text('退会'));
      await _settle(tester);

      await _tapOutside(tester);

      expect(find.text('このアプリから退会いたしますか？'), findsNothing);
      expect(env.path, '/settings');
      expect(env.repo.requestCount, 0);
      expect(env.repo.record, isNull);
    });

    testWidgets(
        '確認ダイアログで「OK」をタップした場合、最終確認ダイアログが表示され、「OK」はエラー色で関数は呼ばれない [ACD-X04]',
        (tester) async {
      final env = await _launchSettings(tester);
      await tester.tap(find.text('退会'));
      await _settle(tester);

      await tester.tap(find.text('OK'));
      await _settle(tester);

      expect(find.text('このアプリから退会いたしますか？'), findsNothing);
      expect(find.text('最終確認'), findsOneWidget);
      expect(find.text('退会すると全てのデータが削除されます。それでも退会しますか？'), findsOneWidget);
      final cancel = tester.getCenter(find.text('キャンセル'));
      final ok = tester.getCenter(find.text('OK'));
      expect(cancel.dx < ok.dx, isTrue);
      expect((cancel.dy - ok.dy).abs() < 1, isTrue);
      final error = Theme.of(tester.element(find.text('OK'))).colorScheme.error;
      final okButton =
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'OK'));
      expect(okButton.style?.backgroundColor?.resolve({}), error);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        '最終確認ダイアログで「キャンセル」をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X05]',
        (tester) async {
      final env = await _launchSettings(tester);
      await tester.tap(find.text('退会'));
      await _settle(tester);
      await tester.tap(find.text('OK'));
      await _settle(tester);

      await tester.tap(find.text('キャンセル'));
      await _settle(tester);

      expect(find.text('最終確認'), findsNothing);
      expect(env.path, '/settings');
      expect(env.repo.requestCount, 0);
      expect(env.repo.record, isNull);
    });

    testWidgets(
        '最終確認ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X06]',
        (tester) async {
      final env = await _launchSettings(tester);
      await tester.tap(find.text('退会'));
      await _settle(tester);
      await tester.tap(find.text('OK'));
      await _settle(tester);

      await _tapOutside(tester);

      expect(find.text('最終確認'), findsNothing);
      expect(env.path, '/settings');
      expect(env.repo.requestCount, 0);
      expect(env.repo.record, isNull);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし関数の応答を待っている場合、最終確認ダイアログが閉じて「退会処理中です」とインジケーターが表示され、パスワード入力欄は表示されない [ACD-X07]',
        (tester) async {
      await _launchSettings(
          tester, configure: (e) => e.repo.requestGate = Completer<void>());

      await _withdrawToFinalOk(tester);

      expect(find.text('最終確認'), findsNothing);
      expect(_processingText, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets(
        '退会処理中に戻る操作をした場合、「退会処理中です」とインジケーターが表示されたままで設定画面から移動しない [ACD-X08]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.requestGate = Completer<void>());
      await _withdrawToFinalOk(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_processingText, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(env.path, '/settings');
    });

    testWidgets(
        '退会処理中にローディングの下にある「退会」の位置をタップした場合、確認ダイアログは表示されず関数を呼ぶ回数は1回のままである [ACD-X09]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.requestGate = Completer<void>());
      await _withdrawToFinalOk(tester);

      await _tapBlocked(tester, find.text('退会'));

      expect(find.text('このアプリから退会いたしますか？'), findsNothing);
      expect(env.repo.requestCount, 1);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし関数の呼び出しと端末内の削除がどちらも成功した場合、ログイン画面（/login）に移動し「退会が完了しました」と「OK」のダイアログが表示される [ACD-X10]',
        (tester) async {
      final env = await _launchSettings(tester);

      await _withdrawToFinalOk(tester);

      _expectCompletedOnLogin(env);
    });

    testWidgets(
        '完了ダイアログで「OK」をタップした場合、ダイアログが閉じてログイン画面が表示されたままである [ACD-X11]',
        (tester) async {
      final env = await _launchSettings(tester);
      await _withdrawToFinalOk(tester);

      await tester.tap(find.text('OK'));
      await _settle(tester);

      expect(_completedText, findsNothing);
      expect(env.path, '/login');
      expect(find.text('ログイン'), findsOneWidget);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし関数の呼び出しが NetworkFailure で失敗した場合、「退会処理中です」が消え「退会できませんでした」ダイアログが表示され、設定画面から移動せず通信エラーダイアログは表示されない [ACD-X12]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.requestFailure = _network);

      await _withdrawToFinalOk(tester);

      _expectNotSentDialogOnSettings(env);
    });

    testWidgets(
        '「退会できませんでした」ダイアログで「OK」をタップした場合、ダイアログが閉じて設定画面が表示される [ACD-X13]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.requestFailure = _network);
      await _withdrawToFinalOk(tester);

      await tester.tap(find.text('OK'));
      await _settle(tester);

      expect(find.text('退会できませんでした'), findsNothing);
      expect(env.path, '/settings');
      expect(find.text('アカウント'), findsOneWidget);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし関数の呼び出しが UnknownFailure で失敗した場合、「退会処理中です」が消え再開ダイアログと「再試行」が表示される [ACD-X14]',
        (tester) async {
      await _launchSettings(
          tester, configure: (e) => e.repo.requestFailure = _unknown);

      await _withdrawToFinalOk(tester);

      expect(_processingText, findsNothing);
      expect(_retryTitle, findsOneWidget);
      expect(_retryButton, findsOneWidget);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、「退会処理中です」が消え再開ダイアログと「再試行」が表示される [ACD-X15]',
        (tester) async {
      await _launchSettings(
          tester, configure: (e) => e.repo.deleteLocalFailure = _unknown);

      await _withdrawToFinalOk(tester);

      expect(_processingText, findsNothing);
      expect(_retryTitle, findsOneWidget);
      expect(_retryButton, findsOneWidget);
    });

    testWidgets(
        '退会処理中にローディングの下にあるボトムナビ「ホーム」の位置をタップした場合、「退会処理中です」が表示されたままで画面のパスは設定画面のままである [ACD-X16]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.requestGate = Completer<void>());
      await _withdrawToFinalOk(tester);

      await _tapBlocked(tester, _navLabel('ホーム'));

      expect(_processingText, findsOneWidget);
      expect(env.path, '/settings');
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし関数の呼び出しと端末内の削除が成功しログアウトが UnknownFailure で失敗した場合、ログイン画面（/login）に移動し「退会が完了しました」ダイアログが表示される [ACD-X17]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.auth.signOutFailure = _unknown);

      await _withdrawToFinalOk(tester);

      expect(env.path, '/login');
      expect(_completedText, findsOneWidget);
    });

    testWidgets(
        '退会処理中にローディングの下にある「ログアウト」の位置をタップした場合、ログアウトの確認ダイアログは表示されず signOut は0回のままである [ACD-X18]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.requestGate = Completer<void>());
      await _withdrawToFinalOk(tester);

      await _tapBlocked(tester, find.text('ログアウト'));

      expect(find.text('ログアウトしますか？'), findsNothing);
      expect(env.auth.signOutCount, 0);
    });

    testWidgets(
        '完了ダイアログの外側をタップした場合、ダイアログが閉じてログイン画面が表示されたままである [ACD-X19]',
        (tester) async {
      final env = await _launchSettings(tester);
      await _withdrawToFinalOk(tester);

      await _tapOutside(tester);

      expect(_completedText, findsNothing);
      expect(env.path, '/login');
    });

    testWidgets(
        '「退会できませんでした」ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示される [ACD-X20]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.requestFailure = _network);
      await _withdrawToFinalOk(tester);

      await _tapOutside(tester);

      expect(find.text('退会できませんでした'), findsNothing);
      expect(env.path, '/settings');
      expect(find.text('アカウント'), findsOneWidget);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし記録の書き込み（markRequested）が UnknownFailure で失敗した場合、「退会できませんでした」ダイアログが表示され、設定画面から移動せず関数は呼ばれない [ACD-X21]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.markRequestedFailure = _unknown);

      await _withdrawToFinalOk(tester);

      expect(find.text('退会できませんでした'), findsOneWidget);
      expect(env.path, '/settings');
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし関数の呼び出しが NetworkFailure で失敗し記録の削除（clearRequest）が UnknownFailure で失敗した場合、再開ダイアログと「再試行」が表示される [ACD-X22]',
        (tester) async {
      await _launchSettings(tester, configure: (e) {
        e.repo.requestFailure = _network;
        e.repo.clearRequestFailure = _unknown;
      });

      await _withdrawToFinalOk(tester);

      expect(_retryTitle, findsOneWidget);
      expect(_retryButton, findsOneWidget);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし関数の呼び出しは成功し記録の更新（markServerDone）が UnknownFailure で失敗し端末内の削除は成功した場合、ログイン画面（/login）に移動し「退会が完了しました」ダイアログが表示される [ACD-X23]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.markServerDoneFailure = _unknown);

      await _withdrawToFinalOk(tester);

      expect(env.path, '/login');
      expect(_completedText, findsOneWidget);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし関数の呼び出しが AuthFailure で失敗した場合、「退会できませんでした」ダイアログが表示され、設定画面から移動せず通信エラーダイアログは表示されない [ACD-E01]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.requestFailure = _auth);

      await _withdrawToFinalOk(tester);

      _expectNotSentDialogOnSettings(env);
    });
  });

  group('SettingsPage 退会：再試行', () {
    testWidgets(
        'ログイン中で記録が requested で「再試行」をタップし関数の呼び出しと端末内の削除がどちらも成功した場合、再開ダイアログが閉じログイン画面（/login）に「退会が完了しました」ダイアログが表示される [ACD-T01]',
        (tester) async {
      final env = await _launch(tester, status: AccountDeletionStatus.requested);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      expect(_retryTitle, findsNothing);
      _expectCompletedOnLogin(env);
    });

    testWidgets(
        '記録が serverDone で「再試行」をタップし端末内の削除が成功した場合、再開ダイアログが閉じログイン画面に「退会が完了しました」ダイアログが表示され、関数は呼ばれない [ACD-T02]',
        (tester) async {
      final env = await _launch(tester, status: AccountDeletionStatus.serverDone);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      expect(_retryTitle, findsNothing);
      _expectCompletedOnLogin(env);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        'ログインしていない状態で記録が requested のまま「再試行」をタップし端末内の削除が成功した場合、ログイン画面に「退会が完了しました」ダイアログが表示され、関数は呼ばれない [ACD-T03]',
        (tester) async {
      final env = await _launch(tester,
          user: null, status: AccountDeletionStatus.requested);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectCompletedOnLogin(env);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        'ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが AuthFailure で失敗し端末内の削除が成功した場合、ログイン画面に「退会が完了しました」ダイアログが表示される [ACD-T04]',
        (tester) async {
      final env = await _launch(tester,
          status: AccountDeletionStatus.requested,
          configure: (e) => e.repo.requestFailure = _auth);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectCompletedOnLogin(env);
    });

    testWidgets(
        'ログイン中で記録が requested で「再試行」をタップし関数の応答を待っている場合、再開ダイアログの「再試行」が無効になり「退会処理中です」とインジケーターが表示される [ACD-T05]',
        (tester) async {
      await _launch(tester,
          status: AccountDeletionStatus.requested,
          configure: (e) => e.repo.requestGate = Completer<void>());

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectRetryProcessingAndDisabled(tester);
    });

    testWidgets(
        'ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが NetworkFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T06]',
        (tester) async {
      await _launch(tester,
          status: AccountDeletionStatus.requested,
          configure: (e) => e.repo.requestFailure = _network);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectRetryFailedAndEnabled(tester);
    });

    testWidgets(
        'ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T07]',
        (tester) async {
      await _launch(tester,
          status: AccountDeletionStatus.requested,
          configure: (e) => e.repo.requestFailure = _unknown);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectRetryFailedAndEnabled(tester);
    });

    testWidgets(
        '記録が serverDone で「再試行」をタップし端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T08]',
        (tester) async {
      await _launch(tester,
          status: AccountDeletionStatus.serverDone,
          configure: (e) => e.repo.deleteLocalFailure = _unknown);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectRetryFailedAndEnabled(tester);
    });

    testWidgets(
        '記録が serverDone で「再試行」をタップし端末内の削除の完了を待っている場合、再開ダイアログの「再試行」が無効になり「退会処理中です」とインジケーターが表示される [ACD-T09]',
        (tester) async {
      await _launch(tester,
          status: AccountDeletionStatus.serverDone,
          configure: (e) => e.repo.deleteLocalGate = Completer<void>());

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectRetryProcessingAndDisabled(tester);
    });

    testWidgets(
        'ログイン中の uid が B で記録が uid A の requested で「再試行」をタップし端末内の削除が成功した場合、ログイン画面（/login）に「退会が完了しました」ダイアログが表示され、関数は呼ばれない [ACD-T10]',
        (tester) async {
      final env = await _launch(tester,
          user: _userB, status: AccountDeletionStatus.requested);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectCompletedOnLogin(env);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        '記録が serverDone で「再試行」をタップし端末内の削除が成功しログアウトが UnknownFailure で失敗した場合、ログイン画面（/login）に「退会が完了しました」ダイアログが表示される [ACD-T11]',
        (tester) async {
      final env = await _launch(tester,
          status: AccountDeletionStatus.serverDone,
          configure: (e) => e.auth.signOutFailure = _unknown);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectCompletedOnLogin(env);
    });

    testWidgets(
        'ログイン中で記録が requested で「再試行」をタップし関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T12]',
        (tester) async {
      await _launch(tester,
          status: AccountDeletionStatus.requested,
          configure: (e) => e.repo.deleteLocalFailure = _unknown);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectRetryFailedAndEnabled(tester);
    });

    testWidgets(
        'ログインしていない状態で記録が requested のまま「再試行」をタップし端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T13]',
        (tester) async {
      await _launch(tester,
          user: null,
          status: AccountDeletionStatus.requested,
          configure: (e) => e.repo.deleteLocalFailure = _unknown);

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectRetryFailedAndEnabled(tester);
    });

    testWidgets(
        'ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが AuthFailure で失敗し端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T14]',
        (tester) async {
      await _launch(tester,
          status: AccountDeletionStatus.requested,
          configure: (e) {
            e.repo.requestFailure = _auth;
            e.repo.deleteLocalFailure = _unknown;
          });

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      _expectRetryFailedAndEnabled(tester);
    });

    testWidgets(
        '起動時の記録の読み取りが失敗して再開ダイアログが表示されている状態で「再試行」をタップし記録の読み直しで記録が無かった場合、再開ダイアログが閉じ関数は呼ばれない [ACD-T15]',
        (tester) async {
      final env = await _launch(tester,
          configure: (e) => e.repo.findPendingFailure = _unknown);
      expect(_retryTitle, findsOneWidget);
      env.repo.findPendingFailure = null;

      await tester.tap(find.text('再試行'));
      await _settle(tester);

      expect(_retryTitle, findsNothing);
      expect(env.repo.requestCount, 0);
    });
  });
}

// ─── 他の端末での退会（仕様書 3.6 / ACD-W 系） ───

/// lib/app.dart の配線（Gate の重ね方・initialize→authState 待ち→check・resumed で check）と同じにしている。
/// app.dart を変えたらここも更新する。
class _WithdrawnTestApp extends ConsumerStatefulWidget {
  const _WithdrawnTestApp();

  @override
  ConsumerState<_WithdrawnTestApp> createState() => _WithdrawnTestAppState();
}

class _WithdrawnTestAppState extends ConsumerState<_WithdrawnTestApp> {
  AppLifecycleObserver? _observer;

  @override
  void initState() {
    super.initState();
    ref.read(accountDeletionViewModelProvider.notifier).checkPending();
    _check(initial: true);
    _observer = AppLifecycleObserver(onResumed: _check);
    WidgetsBinding.instance.addObserver(_observer!);
  }

  Future<void> _check({bool initial = false}) async {
    final viewModel = ref.read(withdrawnElsewhereViewModelProvider.notifier);
    if (initial) await viewModel.initialize();
    try {
      await ref.read(authStateProvider.future);
    } catch (_) {}
    if (!mounted) return;
    await viewModel.check();
  }

  @override
  void dispose() {
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
        child: WithdrawnElsewhereGate(router: router, child: child!),
      ),
    );
  }
}

/// 組み立て済みの環境でアプリ（_WithdrawnTestApp）を起動する。同じ環境で起動し直すこともできる。
Future<void> _startApp(WidgetTester tester, _Env env) async {
  _useTallView(tester);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(env.auth),
      accountDeletionRepositoryProvider.overrideWithValue(env.repo),
      reauthenticationRepositoryProvider.overrideWithValue(env.reauth),
      folderRepositoryProvider.overrideWithValue(MockFolderRepository()),
      wordRepositoryProvider.overrideWithValue(MockWordRepository()),
      settingsRepositoryProvider.overrideWithValue(MockSettingsRepository()),
      flashcardResultRepositoryProvider
          .overrideWithValue(MockFlashcardResultRepository()),
      syncRepositoryProvider.overrideWithValue(MockSyncRepository()),
    ],
    child: const _WithdrawnTestApp(),
  ));
  env.container = ProviderScope.containerOf(
      tester.element(find.byType(_WithdrawnTestApp)));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await _settle(tester);
}

Future<_Env> _launchW(
  WidgetTester tester, {
  AppUser? user = _userA,
  List<String> local = const [],
  Set<String> withdrawn = const {},
  AccountDeletionStatus? status,
  String recordUserId = 'A',
  void Function(_Env env)? configure,
}) async {
  final env = _Env(user: user, recordUserId: recordUserId, status: status);
  env.repo.localUserIds = List.of(local);
  env.repo.withdrawn.addAll(withdrawn);
  configure?.call(env);
  await _startApp(tester, env);
  return env;
}

/// アプリがフォアグラウンドに戻った（resumed）。
Future<void> _resume(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await _settle(tester);
}

final _noticeTitle = find.text('アカウントが削除されました');
final _noticeBody = find.text(
    'このアカウントは他の端末で退会されたため、ログアウトします。'
    '引き続きご利用になる場合は、新しいアカウントで登録してログインしてください。');
final _deleteTitle = find.text('データの削除');
final _deleteBody = find.text(
    'このアカウントは他の端末で退会済みです。'
    'この端末に残っている WordPods のデータをすべて削除します。');
final _failedTitle = find.text('削除に失敗しました');
final _failedBody = find.text('端末内のデータを削除できませんでした。もう一度お試しください。');

void _expectNoWithdrawnDialogs() {
  expect(_noticeTitle, findsNothing);
  expect(_deleteTitle, findsNothing);
  expect(_failedTitle, findsNothing);
}

void _expectNoticeWithOnlyOk() {
  expect(_noticeTitle, findsOneWidget);
  expect(_noticeBody, findsOneWidget);
  expect(find.text('OK'), findsOneWidget);
  expect(_dialogButtons, findsOneWidget);
}

void _expectDeleteDialogWithOnlyOk() {
  expect(_deleteTitle, findsOneWidget);
  expect(_deleteBody, findsOneWidget);
  expect(find.text('OK'), findsOneWidget);
  expect(_dialogButtons, findsOneWidget);
}

void _expectFailedDialogWithOnlyOk() {
  expect(_failedTitle, findsOneWidget);
  expect(_failedBody, findsOneWidget);
  expect(find.text('OK'), findsOneWidget);
  expect(_dialogButtons, findsOneWidget);
}

Future<void> _tapOk(WidgetTester tester) async {
  await tester.tap(find.text('OK'));
  await _settle(tester);
}

/// A が退会済みで起動し、お知らせの「OK」でログアウトして、データの削除ダイアログまで進める。
Future<_Env> _launchToDeleteDialog(
  WidgetTester tester, {
  void Function(_Env env)? configure,
}) async {
  final env = await _launchW(tester,
      local: ['A'], withdrawn: {'A'}, configure: configure);
  await _tapOk(tester);
  return env;
}

/// データの削除ダイアログの「OK」をタップして削除に失敗し、失敗ダイアログまで進める。
Future<_Env> _launchToFailedDialog(WidgetTester tester) async {
  final env = await _launchToDeleteDialog(tester,
      configure: (e) => e.repo.deleteOfUsersResults = [_unknown]);
  await _tapOk(tester);
  return env;
}

bool _okEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'OK')).onPressed !=
    null;

void _withdrawnElsewhereTests() {
  group('SettingsPage 他の端末での退会：起動時', () {
    testWidgets(
        'ログイン中（uid A）で端末内に A のデータがあり A が退会済みの状態でアプリを起動した場合、ホーム画面の上にお知らせダイアログ（「OK」だけ）が表示され、データの削除ダイアログは表示されない [ACD-W01]',
        (tester) async {
      final env = await _launchW(tester, local: ['A'], withdrawn: {'A'});

      expect(env.path, '/home');
      _expectNoticeWithOnlyOk();
      expect(_deleteTitle, findsNothing);
    });

    testWidgets(
        'ログインしていない状態で端末内に A のデータがあり A が退会済みの状態でアプリを起動した場合、ログイン画面が表示されダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W02]',
        (tester) async {
      final env = await _launchW(tester,
          user: null, local: ['A'], withdrawn: {'A'});

      expect(env.path, '/login');
      _expectNoWithdrawnDialogs();
      expect(env.repo.deleteOfUsersCalls, [
        ['A']
      ]);
    });

    testWidgets(
        'ログイン中の uid が B で端末内に A と B のデータがあり A だけが退会済みの状態でアプリを起動した場合、ホーム画面が表示されダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W03]',
        (tester) async {
      final env = await _launchW(tester,
          user: _userB, local: ['A', 'B'], withdrawn: {'A'});

      expect(env.path, '/home');
      _expectNoWithdrawnDialogs();
      expect(env.repo.deleteOfUsersCalls, [
        ['A']
      ]);
    });

    testWidgets(
        'ログイン中で端末内に A のデータがあり A に退会済みの記録が無い状態でアプリを起動した場合、データの削除ダイアログは表示されずホーム画面が表示される [ACD-W04]',
        (tester) async {
      final env = await _launchW(tester, local: ['A']);

      expect(_deleteTitle, findsNothing);
      expect(env.path, '/home');
    });

    testWidgets(
        'ログイン中で端末内に A のデータがあり A が退会済みの状態でオフラインでアプリを起動した場合、データの削除ダイアログは表示されずホーム画面が表示される [ACD-W05]',
        (tester) async {
      final env = await _launchW(tester,
          local: ['A'],
          withdrawn: {'A'},
          configure: (e) => e.repo.offline = true);

      expect(_deleteTitle, findsNothing);
      expect(env.path, '/home');
    });

    testWidgets(
        'ログイン中で端末内に A のデータがあり退会済みの記録の確認が UnknownFailure で失敗する状態でアプリを起動した場合、データの削除ダイアログは表示されずホーム画面が表示される [ACD-W06]',
        (tester) async {
      final env = await _launchW(tester,
          local: ['A'], configure: (e) => e.repo.isWithdrawnFailure = _unknown);

      expect(_deleteTitle, findsNothing);
      expect(env.path, '/home');
    });

    testWidgets(
        'ログインしていない状態で端末内に A のデータがあり A が退会済みの状態でオフラインでアプリを起動した場合、ダイアログは表示されずログイン画面が表示され deleteLocalDataOfUsers は0回である [ACD-W38]',
        (tester) async {
      final env = await _launchW(tester,
          user: null,
          local: ['A'],
          withdrawn: {'A'},
          configure: (e) => e.repo.offline = true);

      expect(_deleteTitle, findsNothing);
      expect(env.path, '/login');
      expect(env.repo.deleteOfUsersCalls, isEmpty);
    });

    testWidgets(
        'ログイン中で端末内にデータが1件も無く A が退会済みの状態でアプリを起動した場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W24]',
        (tester) async {
      final env = await _launchW(tester, withdrawn: {'A'});

      expect(env.path, '/home');
      expect(_noticeTitle, findsOneWidget);
    });

    testWidgets(
        'ログイン中で端末内に A のデータがあり退会処理の記録が無い状態で起動し退会済みの記録の確認の応答を待っている場合、ホーム画面が表示される [ACD-W25]',
        (tester) async {
      final gate = Completer<void>();
      final env = await _launchW(tester,
          local: ['A'], configure: (e) => e.repo.isWithdrawnGate = gate);

      expect(env.path, '/home');
      expect(find.byType(NavigationBar), findsOneWidget);

      gate.complete();
      await _settle(tester);
    });

    testWidgets(
        'ログインしていない状態で端末内に A のデータがある状態で起動し退会済みの記録の確認の応答を待っている場合、ログイン画面が表示される [ACD-W39]',
        (tester) async {
      final gate = Completer<void>();
      final env = await _launchW(tester,
          user: null,
          local: ['A'],
          configure: (e) => e.repo.isWithdrawnGate = gate);

      expect(env.path, '/login');
      expect(find.text('ログイン'), findsOneWidget);

      gate.complete();
      await _settle(tester);
    });
  });

  group('SettingsPage 他の端末での退会：お知らせとログアウト', () {
    testWidgets(
        'お知らせダイアログの「OK」をタップしてログアウトが成功した場合、お知らせが閉じてログイン画面に移動し、その上にデータの削除ダイアログ（「OK」だけ）が表示される [ACD-W26]',
        (tester) async {
      final env = await _launchW(tester, local: ['A'], withdrawn: {'A'});

      await _tapOk(tester);

      expect(_noticeTitle, findsNothing);
      expect(env.path, '/login');
      _expectDeleteDialogWithOnlyOk();
    });

    testWidgets(
        'お知らせダイアログの「OK」をタップし1回目のログアウトが UnknownFailure で失敗し2回目が成功した場合、お知らせが閉じてログイン画面に移動しデータの削除ダイアログが表示される [ACD-W27]',
        (tester) async {
      final env = await _launchW(tester,
          local: ['A'],
          withdrawn: {'A'},
          configure: (e) => e.auth.signOutResults = [_unknown]);

      await _tapOk(tester);

      expect(_noticeTitle, findsNothing);
      expect(env.path, '/login');
      expect(_deleteTitle, findsOneWidget);
      expect(env.auth.signOutCount, 2);
    });

    testWidgets(
        'お知らせダイアログが表示されている状態でダイアログの外側をタップした場合、お知らせは表示されたままで signOut は0回である [ACD-W28]',
        (tester) async {
      final env = await _launchW(tester, local: ['A'], withdrawn: {'A'});

      await _tapOutside(tester);

      expect(_noticeTitle, findsOneWidget);
      expect(env.auth.signOutCount, 0);
    });

    testWidgets(
        'お知らせダイアログが表示されている状態で戻る操作をした場合、お知らせは表示されたままで signOut は0回である [ACD-W29]',
        (tester) async {
      final env = await _launchW(tester, local: ['A'], withdrawn: {'A'});

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_noticeTitle, findsOneWidget);
      expect(env.auth.signOutCount, 0);
    });

    testWidgets(
        'お知らせダイアログの「OK」をタップしログアウトが2回とも UnknownFailure で失敗した場合、お知らせが閉じてログイン画面に移動しデータの削除ダイアログが表示される [ACD-W42]',
        (tester) async {
      final env = await _launchW(tester,
          local: ['A'],
          withdrawn: {'A'},
          configure: (e) => e.auth.signOutResults = [_unknown, _unknown]);

      await _tapOk(tester);

      expect(_noticeTitle, findsNothing);
      expect(env.path, '/login');
      expect(_deleteTitle, findsOneWidget);
    });
  });

  group('SettingsPage 他の端末での退会：データの削除ダイアログ', () {
    testWidgets(
        'データの削除ダイアログの「OK」をタップし端末内の削除が成功した場合、ダイアログが閉じて画面のパスは /login のままである [ACD-W07]',
        (tester) async {
      final env = await _launchToDeleteDialog(tester);

      await _tapOk(tester);

      expect(_deleteTitle, findsNothing);
      expect(env.path, '/login');
    });

    testWidgets(
        'データの削除ダイアログの「OK」をタップし端末内の削除の完了を待っている場合、ダイアログは表示されたまま「OK」が無効になりインジケーターが表示される [ACD-W08]',
        (tester) async {
      await _launchToDeleteDialog(tester,
          configure: (e) => e.repo.deleteOfUsersGate = Completer<void>());

      await _tapOk(tester);

      expect(_deleteTitle, findsOneWidget);
      expect(_okEnabled(tester), isFalse);
      expect(
          find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(CircularProgressIndicator)),
          findsOneWidget);
    });

    testWidgets(
        'データの削除ダイアログの「OK」をタップし端末内の削除が UnknownFailure で失敗した場合、データの削除ダイアログが閉じて失敗ダイアログ（「OK」だけ）が表示される [ACD-W09]',
        (tester) async {
      await _launchToFailedDialog(tester);

      expect(_deleteTitle, findsNothing);
      _expectFailedDialogWithOnlyOk();
    });

    testWidgets(
        '端末内の削除が UnknownFailure で失敗した後に失敗ダイアログの「OK」でやり直して削除が成功した場合、データの削除ダイアログが閉じ失敗ダイアログは表示されない [ACD-W10]',
        (tester) async {
      await _launchToFailedDialog(tester);
      await _tapOk(tester);
      expect(_deleteTitle, findsOneWidget);

      await _tapOk(tester);

      expect(_deleteTitle, findsNothing);
      expect(_failedTitle, findsNothing);
    });

    testWidgets(
        'データの削除ダイアログが表示されている状態（削除の処理中ではない）でダイアログの外側をタップした場合、ダイアログは表示されたままで deleteLocalDataOfUsers は0回である [ACD-W11]',
        (tester) async {
      final env = await _launchToDeleteDialog(tester);

      await _tapOutside(tester);

      expect(_deleteTitle, findsOneWidget);
      expect(env.repo.deleteOfUsersCalls, isEmpty);
    });

    testWidgets(
        'データの削除ダイアログが表示されている状態（削除の処理中ではない）で戻る操作をした場合、ダイアログは表示されたままで deleteLocalDataOfUsers は0回である [ACD-W12]',
        (tester) async {
      final env = await _launchToDeleteDialog(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_deleteTitle, findsOneWidget);
      expect(env.repo.deleteOfUsersCalls, isEmpty);
    });

    testWidgets(
        'データの削除ダイアログの「OK」をタップし端末内の削除の完了を待っている間にダイアログの外側をタップした場合、ダイアログは表示されたままである [ACD-W13]',
        (tester) async {
      await _launchToDeleteDialog(tester,
          configure: (e) => e.repo.deleteOfUsersGate = Completer<void>());
      await _tapOk(tester);

      await _tapOutside(tester);

      expect(_deleteTitle, findsOneWidget);
    });

    testWidgets(
        'データの削除ダイアログの「OK」をタップし端末内の削除の完了を待っている間に戻る操作をした場合、ダイアログは表示されたままである [ACD-W14]',
        (tester) async {
      await _launchToDeleteDialog(tester,
          configure: (e) => e.repo.deleteOfUsersGate = Completer<void>());
      await _tapOk(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_deleteTitle, findsOneWidget);
    });

    testWidgets(
        'データの削除ダイアログが表示されている状態で A の退会済みの記録があるままアプリがフォアグラウンドに戻った場合、データの削除ダイアログは1つだけ表示されたままである [ACD-W19]',
        (tester) async {
      await _launchToDeleteDialog(tester);

      await _resume(tester);

      expect(_deleteTitle, findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets(
        '端末内の削除が UnknownFailure で失敗して失敗ダイアログが表示されている状態で「OK」をタップした場合、失敗ダイアログが閉じてデータの削除ダイアログが表示される [ACD-W33]',
        (tester) async {
      await _launchToFailedDialog(tester);

      await _tapOk(tester);

      expect(_failedTitle, findsNothing);
      expect(_deleteTitle, findsOneWidget);
    });

    testWidgets(
        '失敗ダイアログが表示されている状態でダイアログの外側をタップした場合、失敗ダイアログは表示されたままでデータの削除ダイアログは表示されない [ACD-W34]',
        (tester) async {
      await _launchToFailedDialog(tester);

      await _tapOutside(tester);

      expect(_failedTitle, findsOneWidget);
      expect(_deleteTitle, findsNothing);
    });

    testWidgets(
        '失敗ダイアログが表示されている状態で戻る操作をした場合、失敗ダイアログは表示されたままでデータの削除ダイアログは表示されない [ACD-W35]',
        (tester) async {
      await _launchToFailedDialog(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_failedTitle, findsOneWidget);
      expect(_deleteTitle, findsNothing);
    });

    testWidgets(
        '失敗ダイアログの「OK」でやり直した端末内の削除がもう一度 UnknownFailure で失敗した場合、データの削除ダイアログが閉じて失敗ダイアログが表示される [ACD-W41]',
        (tester) async {
      await _launchToDeleteDialog(tester,
          configure: (e) => e.repo.deleteOfUsersResults = [_unknown, _unknown]);
      await _tapOk(tester);
      await _tapOk(tester);
      expect(_deleteTitle, findsOneWidget);

      await _tapOk(tester);

      expect(_deleteTitle, findsNothing);
      expect(_failedTitle, findsOneWidget);
    });
  });

  group('SettingsPage 他の端末での退会：再開ダイアログとの優先', () {
    testWidgets(
        'ログインしていない状態で A の退会処理の記録が requested で A が退会済みの状態でアプリを起動した場合、再開ダイアログが表示されデータの削除ダイアログは表示されない [ACD-W15]',
        (tester) async {
      await _launchW(tester,
          user: null,
          local: ['A'],
          withdrawn: {'A'},
          status: AccountDeletionStatus.requested);

      expect(_retryTitle, findsOneWidget);
      expect(_deleteTitle, findsNothing);
    });

    testWidgets(
        'ログインしていない状態で A の退会処理の記録が requested で C が退会済みの状態でアプリを起動した場合、再開ダイアログが表示されデータの削除ダイアログは表示されない [ACD-W16]',
        (tester) async {
      await _launchW(tester,
          user: null,
          local: ['A', 'C'],
          withdrawn: {'C'},
          status: AccountDeletionStatus.requested);

      expect(_retryTitle, findsOneWidget);
      expect(_deleteTitle, findsNothing);
    });

    testWidgets(
        'ログイン中で A の退会処理の記録が requested で A が退会済みの状態でアプリを起動した場合、再開ダイアログが表示されデータの削除ダイアログは表示されない [ACD-W21]',
        (tester) async {
      await _launchW(tester,
          local: ['A'],
          withdrawn: {'A'},
          status: AccountDeletionStatus.requested);

      expect(_retryTitle, findsOneWidget);
      expect(_deleteTitle, findsNothing);
    });
  });

  group('SettingsPage 他の端末での退会：復帰時の確認', () {
    testWidgets(
        'ログイン中で起動時には A に退会済みの記録が無く、ホーム画面を表示している状態で記録ができアプリがフォアグラウンドに戻った場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W17]',
        (tester) async {
      final env = await _launchW(tester, local: ['A']);
      expect(_noticeTitle, findsNothing);
      env.repo.withdrawn.add('A');

      await _resume(tester);

      expect(env.path, '/home');
      expect(_noticeTitle, findsOneWidget);
    });

    testWidgets(
        'ログインしていない状態で端末内に A と C のデータがあり両方が退会済みの状態でアプリを起動した場合、ダイアログは表示されず deleteLocalDataOfUsers が1回呼ばれ引数に A と C が含まれる [ACD-W18]',
        (tester) async {
      final env = await _launchW(tester,
          user: null, local: ['A', 'C'], withdrawn: {'A', 'C'});

      _expectNoWithdrawnDialogs();
      expect(env.repo.deleteOfUsersCalls.length, 1);
      expect(env.repo.deleteOfUsersCalls.single, containsAll(['A', 'C']));
    });

    testWidgets(
        'ログイン中で A が退会済みの状態でオフラインで起動してホーム画面を表示し、オンラインになってからアプリがフォアグラウンドに戻った場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W20]',
        (tester) async {
      final env = await _launchW(tester,
          local: ['A'],
          withdrawn: {'A'},
          configure: (e) => e.repo.offline = true);
      expect(env.path, '/home');
      expect(_noticeTitle, findsNothing);
      env.repo.offline = false;

      await _resume(tester);

      expect(env.path, '/home');
      expect(_noticeTitle, findsOneWidget);
    });

    testWidgets(
        'ログイン中の uid が B で端末内に A と B のデータがあり設定画面を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、設定画面のままダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W23]',
        (tester) async {
      final env = await _launchW(tester, user: _userB, local: ['A', 'B']);
      await _openSettingsTab(tester);
      env.repo.withdrawn.add('A');

      await _resume(tester);

      expect(env.path, '/settings');
      _expectNoWithdrawnDialogs();
      expect(env.repo.deleteOfUsersCalls, [
        ['A']
      ]);
    });

    testWidgets(
        'ログインしていない状態で A の削除が1回目 UnknownFailure・2回目成功の状態で起動しその後アプリがフォアグラウンドに戻った場合、ログイン画面のままダイアログは出ず deleteLocalDataOfUsers([A]) が合計2回呼ばれる [ACD-W53]',
        (tester) async {
      final env = await _launchW(tester,
          user: null,
          local: ['A'],
          withdrawn: {'A'},
          configure: (e) => e.repo.deleteOfUsersResults = [_unknown]);
      expect(env.repo.deleteOfUsersCalls.length, 1);

      await _resume(tester);

      expect(env.path, '/login');
      _expectNoWithdrawnDialogs();
      expect(env.repo.deleteOfUsersCalls, [
        ['A'],
        ['A']
      ]);
    });

    testWidgets(
        '強制ログアウトの後にデータの削除ダイアログの「OK」で削除が成功しアプリがフォアグラウンドに戻った場合、画面のパスは /login のままでホーム画面に移動せずデータの削除ダイアログは表示されない [ACD-W43]',
        (tester) async {
      final env = await _launchToDeleteDialog(tester,
          configure: (e) => e.auth.signOutResults = [_unknown, _unknown]);
      await _tapOk(tester);
      env.auth.signOutFailure = _unknown;

      await _resume(tester);

      expect(env.path, '/login');
      expect(find.byType(NavigationBar), findsNothing);
      expect(_deleteTitle, findsNothing);
      expect(env.auth.user?.id, 'A');
    });
  });

  group('SettingsPage 他の端末での退会：ほかのダイアログを閉じてお知らせを出す', () {
    testWidgets(
        '退会の確認ダイアログ（タイトル「退会」）を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、確認ダイアログが閉じてお知らせダイアログが表示される [ACD-W30]',
        (tester) async {
      final env = await _launchW(tester, local: ['A']);
      await _openSettingsTab(tester);
      await tester.tap(find.text('退会'));
      await _settle(tester);
      expect(find.text('このアプリから退会いたしますか？'), findsOneWidget);
      env.repo.withdrawn.add('A');

      await _resume(tester);

      expect(find.text('このアプリから退会いたしますか？'), findsNothing);
      expect(_noticeTitle, findsOneWidget);
    });

    testWidgets(
        '最終確認ダイアログ（タイトル「最終確認」）を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、最終確認ダイアログが閉じてお知らせダイアログが表示される [ACD-W31]',
        (tester) async {
      final env = await _launchW(tester, local: ['A']);
      await _openSettingsTab(tester);
      await tester.tap(find.text('退会'));
      await _settle(tester);
      await _tapOk(tester);
      expect(find.text('最終確認'), findsOneWidget);
      env.repo.withdrawn.add('A');

      await _resume(tester);

      expect(find.text('最終確認'), findsNothing);
      expect(_noticeTitle, findsOneWidget);
    });

    testWidgets(
        '「退会できませんでした」ダイアログを表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、そのダイアログが閉じてお知らせダイアログが表示される [ACD-W32]',
        (tester) async {
      final env = await _launchW(tester,
          local: ['A'], configure: (e) => e.repo.requestFailure = _network);
      await _openSettingsTab(tester);
      await _withdrawToFinalOk(tester);
      expect(find.text('退会できませんでした'), findsOneWidget);
      env.repo.withdrawn.add('A');

      await _resume(tester);

      expect(find.text('退会できませんでした'), findsNothing);
      expect(_noticeTitle, findsOneWidget);
    });

    testWidgets(
        '「ログアウト」をタップしてログアウトのダイアログ（本文「ログアウトしますか？」）を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、そのダイアログが閉じてお知らせダイアログが表示される [ACD-W36]',
        (tester) async {
      final env = await _launchW(tester, local: ['A']);
      await _openSettingsTab(tester);
      await tester.tap(find.text('ログアウト'));
      await _settle(tester);
      expect(find.text('ログアウトしますか？'), findsOneWidget);
      env.repo.withdrawn.add('A');

      await _resume(tester);

      expect(find.text('ログアウトしますか？'), findsNothing);
      expect(_noticeTitle, findsOneWidget);
    });
  });

  group('SettingsPage 他の端末での退会：強制ログアウト', () {
    testWidgets(
        'お知らせの「OK」でログアウトが2回とも失敗し、データの削除ダイアログの「OK」を押さずに終了して Firebase 上は A のまま起動し直した場合、ログイン画面が表示されダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W37]',
        (tester) async {
      final env = await _launchToDeleteDialog(tester,
          configure: (e) => e.auth.signOutResults = [_unknown, _unknown]);
      expect(_deleteTitle, findsOneWidget);
      expect(env.repo.forcedUid, 'A');
      expect(env.auth.user?.id, 'A');
      expect(env.repo.deleteOfUsersCalls, isEmpty);
      env.auth.signOutFailure = _unknown;

      await _startApp(tester, env);

      expect(env.auth.user?.id, 'A');
      expect(env.path, '/login');
      _expectNoWithdrawnDialogs();
      expect(env.repo.deleteOfUsersCalls, [
        ['A']
      ]);
    });

    testWidgets(
        'お知らせの「OK」でログアウトが2回とも失敗しデータの削除が成功した後、アプリを終了して Firebase 上は A のまま起動し直した場合、ログイン画面が表示されダイアログは出ない [ACD-W49]',
        (tester) async {
      final env = await _launchToDeleteDialog(tester,
          configure: (e) => e.auth.signOutResults = [_unknown, _unknown]);
      await _tapOk(tester);
      expect(_deleteTitle, findsNothing);
      env.auth.signOutFailure = _unknown;

      await _startApp(tester, env);

      expect(env.auth.user?.id, 'A');
      expect(env.path, '/login');
      _expectNoWithdrawnDialogs();
    });

    testWidgets(
        'Firebase 上のログイン中の uid が A で A の強制ログアウトの記録があり端末内に A のデータがある状態でオフラインで起動した場合、ログイン画面が表示されホーム画面に移動せず signOut は1回である [ACD-W47]',
        (tester) async {
      final env = await _launchW(tester, local: ['A'], configure: (e) {
        e.repo.forcedUid = 'A';
        e.repo.offline = true;
        e.auth.signOutFailure = _unknown;
      });

      expect(env.path, '/login');
      expect(find.byType(NavigationBar), findsNothing);
      expect(env.auth.signOutCount, 1);
      expect(env.auth.user?.id, 'A');
    });
  });

  group('SettingsPage 他の端末での退会：複数のアカウント・削除の失敗', () {
    testWidgets(
        'ログイン中で端末内に A と C のデータがあり両方が退会済みで、お知らせの「OK」でログアウトし、データの削除ダイアログの「OK」で削除が成功した場合、ダイアログが閉じて画面のパスは /login のままで、起動時に deleteLocalDataOfUsers([C]) が1回呼ばれている [ACD-W40]',
        (tester) async {
      final env = await _launchW(tester,
          local: ['A', 'C'], withdrawn: {'A', 'C'});
      expect(env.repo.deleteOfUsersCalls, [
        ['C']
      ]);
      await _tapOk(tester);
      expect(_deleteTitle, findsOneWidget);

      await _tapOk(tester);

      expect(_deleteTitle, findsNothing);
      expect(env.path, '/login');
      expect(env.repo.deleteOfUsersCalls.where((c) => c.length == 1 && c.first == 'C').length, 1);
    });

    testWidgets(
        'ログインしていない状態で A が退会済みで端末内の削除が UnknownFailure で失敗する状態でアプリを起動した場合、ログイン画面が表示されダイアログは表示されない [ACD-W50]',
        (tester) async {
      final env = await _launchW(tester,
          user: null,
          local: ['A'],
          withdrawn: {'A'},
          configure: (e) => e.repo.deleteOfUsersFailure = _unknown);

      expect(env.path, '/login');
      _expectNoWithdrawnDialogs();
    });

    testWidgets(
        'ログイン中で端末内に A と C のデータがあり両方が退会済みで C の端末内の削除が UnknownFailure で失敗する状態でアプリを起動した場合、ホーム画面の上にお知らせダイアログが表示され失敗を知らせる表示は無い [ACD-W51]',
        (tester) async {
      final env = await _launchW(tester,
          local: ['A', 'C'],
          withdrawn: {'A', 'C'},
          configure: (e) => e.repo.deleteOfUsersFailure = _unknown);

      expect(env.path, '/home');
      expect(_noticeTitle, findsOneWidget);
      expect(_failedTitle, findsNothing);
    });

    testWidgets(
        'ログイン中の uid が B で端末内に A と B のデータがあり A だけが退会済みで端末内の削除が UnknownFailure で失敗する状態でアプリを起動した場合、ホーム画面が表示されダイアログは表示されない [ACD-W52]',
        (tester) async {
      final env = await _launchW(tester,
          user: _userB,
          local: ['A', 'B'],
          withdrawn: {'A'},
          configure: (e) => e.repo.deleteOfUsersFailure = _unknown);

      expect(env.path, '/home');
      _expectNoWithdrawnDialogs();
    });
  });

  group('SettingsPage 他の端末での退会：リアルタイムの監視', () {
    testWidgets(
        'ログイン中でホーム画面を表示している状態でアプリをフォアグラウンドにしたまま A に退会済みの記録ができた場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W44]',
        (tester) async {
      final env = await _launchW(tester, local: ['A']);
      expect(env.path, '/home');

      env.repo.emitWithdrawn('A');
      await _settle(tester);

      expect(env.path, '/home');
      expect(_noticeTitle, findsOneWidget);
    });

    testWidgets(
        'ログイン中で設定画面を表示している状態でアプリをフォアグラウンドにしたまま A に退会済みの記録ができた場合、設定画面の上にお知らせダイアログが表示される [ACD-W45]',
        (tester) async {
      final env = await _launchW(tester, local: ['A']);
      await _openSettingsTab(tester);

      env.repo.emitWithdrawn('A');
      await _settle(tester);

      expect(env.path, '/settings');
      expect(_noticeTitle, findsOneWidget);
    });

    testWidgets(
        '最終確認ダイアログの「OK」をタップして「退会処理中です」が表示されている状態で A に退会済みの記録ができた場合、お知らせダイアログは表示されず「退会処理中です」が表示されたままである [ACD-W46]',
        (tester) async {
      final env = await _launchW(tester,
          local: ['A'], configure: (e) => e.repo.requestGate = Completer<void>());
      await _openSettingsTab(tester);
      await _withdrawToFinalOk(tester);
      expect(_processingText, findsOneWidget);

      env.repo.emitWithdrawn('A');
      await _settle(tester);

      expect(_noticeTitle, findsNothing);
      expect(_processingText, findsOneWidget);
    });

    testWidgets(
        '最終確認ダイアログ（タイトル「最終確認」）を表示している状態でアプリをフォアグラウンドにしたまま A に退会済みの記録ができた場合、最終確認ダイアログが閉じてお知らせダイアログが表示される [ACD-W48]',
        (tester) async {
      final env = await _launchW(tester, local: ['A']);
      await _openSettingsTab(tester);
      await tester.tap(find.text('退会'));
      await _settle(tester);
      await _tapOk(tester);
      expect(find.text('最終確認'), findsOneWidget);

      env.repo.emitWithdrawn('A');
      await _settle(tester);

      expect(find.text('最終確認'), findsNothing);
      expect(_noticeTitle, findsOneWidget);
    });
  });
}

// ─── 退会の前の本人確認（仕様書 3.2 ACD-X24〜X53 / 3.3 ACD-T16〜T41 / 3.4 ACD-E03・E04 / 3.6 ACD-W54・W55 / 2.2 ACD-N01・N02） ───

final _reauthTitle = find.text('本人確認');
final _reauthBody = find.text('退会するには、パスワードを入力してください。');
final _reauthRejectedTitle = find.text('本人確認できませんでした');
final _wrongPasswordText = find.text('パスワードが正しくありません。もう一度入力してください。');
final _notSentTitle = find.text('退会できませんでした');
final _guidancePassword = find.text('続けるには本人確認が必要です。パスワードを入力してください。');
final _guidanceGoogle =
    find.text('続けるには本人確認が必要です。「再試行」を押して、Google で本人確認してください。');
final _inlineRejectedText =
    find.text('本人確認できませんでした。パスワード（Google アカウント）を確認して、もう一度お試しください。');
final _tooManyText =
    find.text('本人確認の試行回数が上限を超えました。しばらく時間をおいて、もう一度お試しください。');

Finder get _dialogField => find.descendant(
    of: find.byType(AlertDialog), matching: find.byType(TextField));

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(_dialogField).controller!.text;

bool _retryEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_retryButton).onPressed != null;

Future<void> _enterPassword(WidgetTester tester, String value) async {
  await tester.enterText(_dialogField, value);
  await tester.pump();
}

Future<void> _tapDialogOk(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'OK'));
  await _settle(tester);
}

/// 本人確認ダイアログでパスワードを入力して「OK」をタップする。
Future<void> _enterPasswordAndOk(WidgetTester tester, String value) async {
  await _enterPassword(tester, value);
  await _tapDialogOk(tester);
}

/// メール登録のユーザーで、最終確認の「OK」まで進めて本人確認ダイアログを表示する。
Future<_Env> _launchToPasswordDialog(
  WidgetTester tester, {
  void Function(_Env env)? configure,
}) async {
  final env = await _launchSettings(tester,
      user: _userAWithPassword, configure: configure);
  await _withdrawToFinalOk(tester);
  return env;
}

/// Google のユーザーで、本人確認が AuthFailure で失敗して「本人確認できませんでした」ダイアログを表示する。
Future<_Env> _launchToRejectedDialog(WidgetTester tester) async {
  final env = await _launchSettings(tester,
      configure: (e) => e.reauth.googleFailure = _auth);
  await _withdrawToFinalOk(tester);
  return env;
}

/// 記録が requested で「再試行」をタップし、関数が RecentLoginRequiredFailure で失敗して本人確認の案内を表示する。
Future<_Env> _launchToGuidance(
  WidgetTester tester, {
  AppUser? user = _userA,
  void Function(_Env env)? configure,
}) async {
  final env = await _launch(tester,
      user: user,
      status: AccountDeletionStatus.requested,
      configure: (e) {
        e.repo.requestResults = [_recentLogin];
        configure?.call(e);
      });
  await tester.tap(find.text('再試行'));
  await _settle(tester);
  return env;
}

Future<void> _tapRetry(WidgetTester tester) async {
  await tester.tap(find.text('再試行'));
  await _settle(tester);
}

void _expectNotSent(_Env env) {
  expect(_processingText, findsNothing);
  expect(_notSentTitle, findsOneWidget);
  expect(env.repo.requestCount, 0);
  expect(env.repo.record, isNull);
}

void _reauthenticationTests() {
  group('SettingsPage 退会の前の本人確認：本人確認ダイアログ（メール登録のユーザー）', () {
    testWidgets(
        'メール登録のユーザーで最終確認ダイアログの「OK」をタップした場合、「本人確認」ダイアログに本文・パスワード欄・「キャンセル」「OK」が並び、欄は空で「OK」は無効、本人確認と関数は呼ばれない [ACD-X24]',
        (tester) async {
      final env = await _launchToPasswordDialog(tester);

      expect(find.text('最終確認'), findsNothing);
      expect(_reauthTitle, findsOneWidget);
      expect(_reauthBody, findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      final cancel = tester.getCenter(find.text('キャンセル'));
      final ok = tester.getCenter(find.text('OK'));
      expect(cancel.dx < ok.dx, isTrue);
      expect((cancel.dy - ok.dy).abs() < 1, isTrue);
      expect(_fieldText(tester), '');
      expect(_okEnabled(tester), isFalse);
      expect(env.reauth.passwordCalls, isEmpty);
      expect(env.reauth.googleCount, 0);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        '本人確認ダイアログでパスワード欄に「p」を入力した場合、「OK」が有効になり入力欄の文字は伏せ字で表示される [ACD-X25]',
        (tester) async {
      await _launchToPasswordDialog(tester);

      await _enterPassword(tester, 'p');

      expect(_okEnabled(tester), isTrue);
      expect(tester.widget<TextField>(_dialogField).obscureText, isTrue);
    });

    testWidgets(
        '本人確認ダイアログで「キャンセル」をタップした場合、ダイアログが閉じて設定画面が表示され、本人確認と関数は呼ばれず記録も無いままである [ACD-X26]',
        (tester) async {
      final env = await _launchToPasswordDialog(tester);

      await tester.tap(find.text('キャンセル'));
      await _settle(tester);

      expect(_reauthTitle, findsNothing);
      expect(env.path, '/settings');
      expect(find.text('アカウント'), findsOneWidget);
      expect(env.reauth.passwordCalls, isEmpty);
      expect(env.reauth.googleCount, 0);
      expect(env.repo.requestCount, 0);
      expect(env.repo.record, isNull);
    });

    testWidgets(
        '本人確認ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示され、本人確認と関数は呼ばれず記録も無いままである [ACD-X27]',
        (tester) async {
      final env = await _launchToPasswordDialog(tester);

      await _tapOutside(tester);

      expect(_reauthTitle, findsNothing);
      expect(env.path, '/settings');
      expect(find.text('アカウント'), findsOneWidget);
      expect(env.reauth.passwordCalls, isEmpty);
      expect(env.reauth.googleCount, 0);
      expect(env.repo.requestCount, 0);
      expect(env.repo.record, isNull);
    });

    testWidgets(
        'メール登録のユーザーで「pass1234」を入力して「OK」をタップし本人確認・関数・端末内の削除がすべて成功した場合、ログイン画面に「退会が完了しました」が表示され、パスワードで1回・Google で0回本人確認される [ACD-X28]',
        (tester) async {
      final env = await _launchToPasswordDialog(tester);

      await _enterPasswordAndOk(tester, 'pass1234');

      _expectCompletedOnLogin(env);
      expect(env.reauth.passwordCalls, ['pass1234']);
      expect(env.reauth.googleCount, 0);
    });

    testWidgets(
        'メール登録のユーザーでパスワードを入力して「OK」をタップし本人確認の応答を待っている場合、本人確認ダイアログが閉じて「退会処理中です」とインジケーターが表示され、関数は呼ばれない [ACD-X29]',
        (tester) async {
      final env = await _launchToPasswordDialog(
          tester, configure: (e) => e.reauth.gate = Completer<void>());

      await _enterPasswordAndOk(tester, 'pass1234');

      expect(_reauthTitle, findsNothing);
      expect(_processingText, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        'メール登録のユーザーで「pass1234」を入力して「OK」をタップし本人確認が AuthFailure で失敗した場合、本人確認ダイアログが入力を残したまま誤りの文言付きで開き直され、関数は呼ばれず記録も無い [ACD-X30]',
        (tester) async {
      final env = await _launchToPasswordDialog(
          tester, configure: (e) => e.reauth.passwordFailure = _auth);

      await _enterPasswordAndOk(tester, 'pass1234');

      expect(_processingText, findsNothing);
      expect(_reauthTitle, findsOneWidget);
      expect(_fieldText(tester), 'pass1234');
      expect(_fieldText(tester).length, 8);
      expect(_wrongPasswordText, findsOneWidget);
      expect(_okEnabled(tester), isTrue);
      expect(_reauthRejectedTitle, findsNothing);
      expect(env.repo.requestCount, 0);
      expect(env.repo.record, isNull);
    });

    testWidgets(
        '「本人確認できませんでした」ダイアログで「OK」をタップした場合、ダイアログが閉じて設定画面が表示される [ACD-X31]',
        (tester) async {
      final env = await _launchToRejectedDialog(tester);
      expect(_reauthRejectedTitle, findsOneWidget);

      await _tapOk(tester);

      expect(_reauthRejectedTitle, findsNothing);
      expect(env.path, '/settings');
      expect(find.text('アカウント'), findsOneWidget);
    });

    testWidgets(
        '「本人確認できませんでした」ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示される [ACD-X32]',
        (tester) async {
      final env = await _launchToRejectedDialog(tester);
      expect(_reauthRejectedTitle, findsOneWidget);

      await _tapOutside(tester);

      expect(_reauthRejectedTitle, findsNothing);
      expect(env.path, '/settings');
      expect(find.text('アカウント'), findsOneWidget);
    });

    testWidgets(
        'Google のユーザーで最終確認ダイアログの「OK」をタップした場合、本人確認ダイアログは表示されず Google で1回・パスワードで0回本人確認される [ACD-X33]',
        (tester) async {
      final env = await _launchSettings(tester);

      await _withdrawToFinalOk(tester);

      expect(_reauthTitle, findsNothing);
      expect(_dialogField, findsNothing);
      expect(env.reauth.googleCount, 1);
      expect(env.reauth.passwordCalls, isEmpty);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし Google の本人確認がキャンセルされた場合、「退会処理中です」が消えて設定画面が表示されダイアログは出ず、関数は呼ばれず記録も無い [ACD-X34]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.reauth.googleCancelled = true);

      await _withdrawToFinalOk(tester);

      expect(_processingText, findsNothing);
      expect(env.path, '/settings');
      expect(find.byType(AlertDialog), findsNothing);
      expect(env.repo.requestCount, 0);
      expect(env.repo.record, isNull);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし Google の本人確認が AuthFailure で失敗した場合、「退会処理中です」が消えて「本人確認できませんでした」ダイアログが表示され、関数は呼ばれない [ACD-X35]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.reauth.googleFailure = _auth);

      await _withdrawToFinalOk(tester);

      expect(_processingText, findsNothing);
      expect(_reauthRejectedTitle, findsOneWidget);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし本人確認が NetworkFailure で失敗した場合、「退会処理中です」が消えて「退会できませんでした」ダイアログが表示され、関数は呼ばれず記録も無い [ACD-X36]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.reauth.googleFailure = _network);

      await _withdrawToFinalOk(tester);

      _expectNotSent(env);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし本人確認は成功し関数の呼び出しが RecentLoginRequiredFailure で失敗した場合、「退会できませんでした」ダイアログが表示され、設定画面から移動せず記録も無い [ACD-X37]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.repo.requestFailure = _recentLogin);

      await _withdrawToFinalOk(tester);

      expect(_processingText, findsNothing);
      expect(_notSentTitle, findsOneWidget);
      expect(env.path, '/settings');
      expect(env.repo.record, isNull);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし Google の本人確認の応答を待っている場合、「退会処理中です」とインジケーターが表示され、関数は呼ばれない [ACD-X38]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.reauth.gate = Completer<void>());

      await _withdrawToFinalOk(tester);

      expect(_processingText, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        '本人確認の応答待ちに戻る操作をした場合、「退会処理中です」とインジケーターが表示されたままで設定画面から移動しない [ACD-X39]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.reauth.gate = Completer<void>());
      await _withdrawToFinalOk(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_processingText, findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(env.path, '/settings');
    });

    testWidgets(
        '本人確認の応答待ちにローディングの下にある「退会」の位置をタップした場合、確認ダイアログは表示されず本人確認は1回のままで関数は呼ばれない [ACD-X40]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.reauth.gate = Completer<void>());
      await _withdrawToFinalOk(tester);

      await _tapBlocked(tester, find.text('退会'));

      expect(find.text('このアプリから退会いたしますか？'), findsNothing);
      expect(env.reauth.googleCount, 1);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        '本人確認の応答待ちにローディングの下にあるボトムナビ「ホーム」の位置をタップした場合、「退会処理中です」が表示されたままで画面のパスは設定画面のままである [ACD-X41]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.reauth.gate = Completer<void>());
      await _withdrawToFinalOk(tester);

      await _tapBlocked(tester, _navLabel('ホーム'));

      expect(_processingText, findsOneWidget);
      expect(env.path, '/settings');
    });

    testWidgets(
        '本人確認の応答待ちにローディングの下にある「ログアウト」の位置をタップした場合、ログアウトの確認ダイアログは表示されず signOut は0回のままである [ACD-X42]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.reauth.gate = Completer<void>());
      await _withdrawToFinalOk(tester);

      await _tapBlocked(tester, find.text('ログアウト'));

      expect(find.text('ログアウトしますか？'), findsNothing);
      expect(env.auth.signOutCount, 0);
    });

    testWidgets(
        'メール登録のユーザーでパスワードを入力して「OK」をタップし本人確認が NetworkFailure で失敗した場合、「退会できませんでした」ダイアログが表示され、関数は呼ばれず記録も無い [ACD-X43]',
        (tester) async {
      final env = await _launchToPasswordDialog(
          tester, configure: (e) => e.reauth.passwordFailure = _network);

      await _enterPasswordAndOk(tester, 'pass1234');

      _expectNotSent(env);
    });

    testWidgets(
        '本人確認ダイアログでパスワード欄に「 」（半角スペース1文字）を入力した場合、「OK」が有効になる [ACD-X44]',
        (tester) async {
      await _launchToPasswordDialog(tester);

      await _enterPassword(tester, ' ');

      expect(_okEnabled(tester), isTrue);
    });

    testWidgets(
        'メール登録のユーザーで本人確認ダイアログに「 pass 」（前後に半角スペース）を入力して「OK」をタップした場合、空白を含んだまま1回本人確認される [ACD-X45]',
        (tester) async {
      final env = await _launchToPasswordDialog(tester);

      await _enterPasswordAndOk(tester, ' pass ');

      expect(env.reauth.passwordCalls, [' pass ']);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし本人確認は成功し関数の呼び出しが RecentLoginRequiredFailure で失敗し記録の削除（clearRequest）が UnknownFailure で失敗した場合、再開ダイアログと「再試行」が表示される [ACD-X46]',
        (tester) async {
      await _launchSettings(tester, configure: (e) {
        e.repo.requestFailure = _recentLogin;
        e.repo.clearRequestFailure = _unknown;
      });

      await _withdrawToFinalOk(tester);

      expect(_retryTitle, findsOneWidget);
      expect(_retryButton, findsOneWidget);
    });

    testWidgets(
        '本人確認ダイアログでパスワード欄に「p」を入力したあとその1文字を消した場合、「OK」が無効になる [ACD-X47]',
        (tester) async {
      await _launchToPasswordDialog(tester);
      await _enterPassword(tester, 'p');
      expect(_okEnabled(tester), isTrue);

      await _enterPassword(tester, '');

      expect(_okEnabled(tester), isFalse);
    });

    testWidgets(
        '本人確認ダイアログで「pass1234」を入力して「キャンセル」をタップしたあともう一度最終確認の「OK」まで進めた場合、パスワード欄は空で「OK」は無効である [ACD-X48]',
        (tester) async {
      await _launchToPasswordDialog(tester);
      await _enterPassword(tester, 'pass1234');
      await tester.tap(find.text('キャンセル'));
      await _settle(tester);

      await _withdrawToFinalOk(tester);

      expect(_reauthTitle, findsOneWidget);
      expect(_fieldText(tester), '');
      expect(_okEnabled(tester), isFalse);
    });

    testWidgets(
        'パスワード違いで本人確認ダイアログが開き直された状態でもう一度「OK」をタップし本人確認がまた AuthFailure で失敗した場合、入力を残したまま誤りの文言付きで開き直され、本人確認は「pass1234」で合計2回呼ばれる [ACD-X49]',
        (tester) async {
      final env = await _launchToPasswordDialog(tester,
          configure: (e) => e.reauth.passwordFailure = _auth);
      await _enterPasswordAndOk(tester, 'pass1234');

      await _tapDialogOk(tester);

      expect(_reauthTitle, findsOneWidget);
      expect(_fieldText(tester), 'pass1234');
      expect(_wrongPasswordText, findsOneWidget);
      expect(env.reauth.passwordCalls, ['pass1234', 'pass1234']);
    });

    testWidgets(
        'パスワード違いで本人確認ダイアログが開き直された状態で「キャンセル」をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X50]',
        (tester) async {
      final env = await _launchToPasswordDialog(tester,
          configure: (e) => e.reauth.passwordFailure = _auth);
      await _enterPasswordAndOk(tester, 'pass1234');

      await tester.tap(find.text('キャンセル'));
      await _settle(tester);

      expect(_reauthTitle, findsNothing);
      expect(env.path, '/settings');
      expect(find.text('アカウント'), findsOneWidget);
      expect(env.repo.requestCount, 0);
      expect(env.repo.record, isNull);
    });

    testWidgets(
        'パスワード違いで本人確認ダイアログが開き直された状態でパスワードを「pass5678」に直して「OK」をタップし本人確認・関数・端末内の削除がすべて成功した場合、ログイン画面に「退会が完了しました」が表示され、最後の本人確認は「pass5678」で呼ばれる [ACD-X51]',
        (tester) async {
      final env = await _launchToPasswordDialog(tester,
          configure: (e) => e.reauth.passwordResults = [_auth]);
      await _enterPasswordAndOk(tester, 'pass1234');

      await _enterPasswordAndOk(tester, 'pass5678');

      _expectCompletedOnLogin(env);
      expect(env.reauth.passwordCalls.last, 'pass5678');
    });

    testWidgets(
        'メール登録のユーザーでパスワードを入力して「OK」をタップし本人確認が TooManyRequestsFailure で失敗した場合、試行回数の上限を知らせる「本人確認できませんでした」ダイアログが表示され、本人確認ダイアログは出ず関数は呼ばれない [ACD-X52]',
        (tester) async {
      final env = await _launchToPasswordDialog(
          tester, configure: (e) => e.reauth.passwordFailure = _tooMany);

      await _enterPasswordAndOk(tester, 'pass1234');

      expect(_processingText, findsNothing);
      expect(_reauthRejectedTitle, findsOneWidget);
      expect(_tooManyText, findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(_reauthBody, findsNothing);
      expect(_dialogField, findsNothing);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし Google の本人確認が TooManyRequestsFailure で失敗した場合、試行回数の上限を知らせる「本人確認できませんでした」ダイアログが表示され、関数は呼ばれない [ACD-X53]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.reauth.googleFailure = _tooMany);

      await _withdrawToFinalOk(tester);

      expect(_processingText, findsNothing);
      expect(_reauthRejectedTitle, findsOneWidget);
      expect(_tooManyText, findsOneWidget);
      expect(env.repo.requestCount, 0);
    });

    testWidgets(
        '最終確認ダイアログで「OK」をタップし本人確認が UnknownFailure で失敗した場合、「退会処理中です」が消えて「退会できませんでした」ダイアログが表示され、関数は呼ばれない [ACD-E03]',
        (tester) async {
      final env = await _launchSettings(
          tester, configure: (e) => e.reauth.googleFailure = _unknown);

      await _withdrawToFinalOk(tester);

      _expectNotSent(env);
    });
  });

  group('SettingsPage 退会の前の本人確認：入力ルール（空白は除かず1文字以上）', () {
    const validValues = [
      ('p', '「p」'),
      (' ', '「 」（半角スペース1文字）'),
      ('　', '「　」（全角スペース1文字）'),
    ];
    for (final (value, label) in validValues) {
      testWidgets(
          '本人確認ダイアログのパスワード欄に$labelを入力した場合、「OK」が有効になる [ACD-N01]',
          (tester) async {
        await _launchToPasswordDialog(tester);

        await _enterPassword(tester, value);

        expect(_okEnabled(tester), isTrue);
      });
    }

    testWidgets(
        '本人確認ダイアログのパスワード欄が「」（空）の場合、「OK」が無効である [ACD-N01]',
        (tester) async {
      await _launchToPasswordDialog(tester);

      await _enterPassword(tester, '');

      expect(_okEnabled(tester), isFalse);
    });

    for (final (value, label) in validValues) {
      testWidgets(
          '再開ダイアログの本人確認の案内のパスワード欄に$labelを入力した場合、「再試行」が有効になる [ACD-N02]',
          (tester) async {
        await _launchToGuidance(tester, user: _userAWithPassword);

        await _enterPassword(tester, value);

        expect(_retryEnabled(tester), isTrue);
      });
    }

    testWidgets(
        '再開ダイアログの本人確認の案内のパスワード欄が「」（空）の場合、「再試行」が無効である [ACD-N02]',
        (tester) async {
      await _launchToGuidance(tester, user: _userAWithPassword);

      await _enterPassword(tester, '');

      expect(_retryEnabled(tester), isFalse);
    });
  });

  group('SettingsPage 退会の前の本人確認：再開ダイアログの本人確認の案内', () {
    testWidgets(
        'Google のユーザーで記録が requested で「再試行」をタップし関数の呼び出しが RecentLoginRequiredFailure で失敗した場合、Google 用の案内が表示され「再試行」が有効に戻り、パスワード欄・失敗文言は出ず端末内の削除は呼ばれない [ACD-T16]',
        (tester) async {
      final env = await _launchToGuidance(tester);

      expect(_retryTitle, findsOneWidget);
      expect(_guidanceGoogle, findsOneWidget);
      expect(_retryEnabled(tester), isTrue);
      expect(find.byType(TextField), findsNothing);
      expect(_retryFailedText, findsNothing);
      expect(env.repo.deleteLocalCount, 0);
    });

    testWidgets(
        'メール登録のユーザーで記録が requested で「再試行」をタップし関数の呼び出しが RecentLoginRequiredFailure で失敗した場合、パスワード用の案内と空のパスワード欄が表示され「再試行」は無効である [ACD-T17]',
        (tester) async {
      await _launchToGuidance(tester, user: _userAWithPassword);

      expect(_retryTitle, findsOneWidget);
      expect(_guidancePassword, findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(_fieldText(tester), '');
      expect(_retryEnabled(tester), isFalse);
    });

    testWidgets(
        '本人確認の案内のパスワード欄に「p」を入力した場合、「再試行」が有効になり入力欄の文字は伏せ字で表示される [ACD-T18]',
        (tester) async {
      await _launchToGuidance(tester, user: _userAWithPassword);

      await _enterPassword(tester, 'p');

      expect(_retryEnabled(tester), isTrue);
      expect(tester.widget<TextField>(_dialogField).obscureText, isTrue);
    });

    testWidgets(
        '本人確認の案内のパスワード欄に「pass1234」を入力して「再試行」をタップし本人確認・関数・端末内の削除がすべて成功した場合、再開ダイアログが閉じログイン画面に「退会が完了しました」が表示され、パスワード「pass1234」で1回本人確認される [ACD-T19]',
        (tester) async {
      final env = await _launchToGuidance(tester, user: _userAWithPassword);
      await _enterPassword(tester, 'pass1234');

      await _tapRetry(tester);

      expect(_retryTitle, findsNothing);
      _expectCompletedOnLogin(env);
      expect(env.reauth.passwordCalls, ['pass1234']);
    });

    testWidgets(
        'Google の本人確認の案内で「再試行」をタップし Google の本人確認・関数・端末内の削除がすべて成功した場合、再開ダイアログが閉じログイン画面に「退会が完了しました」が表示され、Google で1回本人確認される [ACD-T20]',
        (tester) async {
      final env = await _launchToGuidance(tester);

      await _tapRetry(tester);

      expect(_retryTitle, findsNothing);
      _expectCompletedOnLogin(env);
      expect(env.reauth.googleCount, 1);
    });

    testWidgets(
        'Google の本人確認の案内で「再試行」をタップし本人確認の応答を待っている場合、「再試行」が無効になり「退会処理中です」とインジケーターが表示される [ACD-T21]',
        (tester) async {
      final env = await _launchToGuidance(tester);
      env.reauth.gate = Completer<void>();

      await _tapRetry(tester);

      _expectRetryProcessingAndDisabled(tester);
    });

    testWidgets(
        'Google の本人確認の案内で「再試行」をタップし Google の本人確認がキャンセルされた場合、案内が表示されたまま「再試行」が有効に戻り、2種類の失敗文言は出ず関数を呼ぶ回数は増えない [ACD-T22]',
        (tester) async {
      final env = await _launchToGuidance(tester);
      env.reauth.googleCancelled = true;
      final before = env.repo.requestCount;

      await _tapRetry(tester);

      expect(_guidanceGoogle, findsOneWidget);
      expect(_retryEnabled(tester), isTrue);
      expect(_inlineRejectedText, findsNothing);
      expect(_retryFailedText, findsNothing);
      expect(env.repo.requestCount, before);
    });

    testWidgets(
        '本人確認の案内でパスワード「pass1234」を入力して「再試行」をタップし本人確認が AuthFailure で失敗した場合、案内と本人確認の失敗文言が表示され「再試行」が有効に戻り、入力（8文字）が残って関数を呼ぶ回数は増えない [ACD-T23]',
        (tester) async {
      final env = await _launchToGuidance(tester, user: _userAWithPassword);
      env.reauth.passwordFailure = _auth;
      await _enterPassword(tester, 'pass1234');
      final before = env.repo.requestCount;

      await _tapRetry(tester);

      expect(_guidancePassword, findsOneWidget);
      expect(_inlineRejectedText, findsOneWidget);
      expect(_retryEnabled(tester), isTrue);
      expect(_fieldText(tester).length, 8);
      expect(env.repo.requestCount, before);
    });

    testWidgets(
        '本人確認の案内でパスワード「pass1234」を入力して「再試行」をタップし本人確認が NetworkFailure で失敗した場合、案内と「再試行に失敗しました。」が表示され「再試行」が有効に戻り、入力（8文字）が残って関数を呼ぶ回数は増えない [ACD-T24]',
        (tester) async {
      final env = await _launchToGuidance(tester, user: _userAWithPassword);
      env.reauth.passwordFailure = _network;
      await _enterPassword(tester, 'pass1234');
      final before = env.repo.requestCount;

      await _tapRetry(tester);

      expect(_guidancePassword, findsOneWidget);
      expect(_retryFailedText, findsOneWidget);
      expect(_retryEnabled(tester), isTrue);
      expect(_fieldText(tester).length, 8);
      expect(env.repo.requestCount, before);
    });

    testWidgets(
        '本人確認の案内で「再試行」をタップし本人確認は成功し関数の呼び出しが UnknownFailure で失敗した場合、再開ダイアログが表示されたまま案内は消え「再試行に失敗しました。」が表示される [ACD-T25]',
        (tester) async {
      await _launchToGuidance(tester,
          configure: (e) => e.repo.requestResults = [_recentLogin, _unknown]);

      await _tapRetry(tester);

      expect(_retryTitle, findsOneWidget);
      expect(_guidanceGoogle, findsNothing);
      expect(_retryFailedText, findsOneWidget);
    });

    testWidgets(
        '本人確認の案内で戻る操作をした場合、再開ダイアログと本人確認の案内が表示されたままである [ACD-T26]',
        (tester) async {
      await _launchToGuidance(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_retryTitle, findsOneWidget);
      expect(_guidanceGoogle, findsOneWidget);
    });

    testWidgets(
        '本人確認の案内で「再試行」をタップし本人確認は成功し関数の呼び出しが NetworkFailure で失敗した場合、再開ダイアログが表示されたまま案内は消え「再試行に失敗しました。」が表示される [ACD-T27]',
        (tester) async {
      await _launchToGuidance(tester,
          configure: (e) => e.repo.requestResults = [_recentLogin, _network]);

      await _tapRetry(tester);

      expect(_retryTitle, findsOneWidget);
      expect(_guidanceGoogle, findsNothing);
      expect(_retryFailedText, findsOneWidget);
    });

    testWidgets(
        '本人確認の案内で「再試行」をタップし本人確認は成功し関数の呼び出しが AuthFailure で失敗し端末内の削除が成功した場合、再開ダイアログが閉じログイン画面に「退会が完了しました」が表示される [ACD-T28]',
        (tester) async {
      final env = await _launchToGuidance(tester,
          configure: (e) => e.repo.requestResults = [_recentLogin, _auth]);

      await _tapRetry(tester);

      expect(_retryTitle, findsNothing);
      _expectCompletedOnLogin(env);
    });

    testWidgets(
        '本人確認の案内で「再試行」をタップし本人確認と関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、再開ダイアログが表示されたまま案内は消え「再試行に失敗しました。」が表示される [ACD-T29]',
        (tester) async {
      await _launchToGuidance(tester,
          configure: (e) => e.repo.deleteLocalFailure = _unknown);

      await _tapRetry(tester);

      expect(_retryTitle, findsOneWidget);
      expect(_guidanceGoogle, findsNothing);
      expect(_retryFailedText, findsOneWidget);
    });

    testWidgets(
        '本人確認の案内でパスワード「pass1234」を入力して「再試行」をタップし本人確認は成功し関数の呼び出しがまた RecentLoginRequiredFailure で失敗した場合、案内が表示されたまま2種類の失敗文言は出ず、入力（8文字）が残って「再試行」は有効である [ACD-T30]',
        (tester) async {
      await _launchToGuidance(tester,
          user: _userAWithPassword,
          configure: (e) => e.repo.requestResults = [_recentLogin, _recentLogin]);
      await _enterPassword(tester, 'pass1234');

      await _tapRetry(tester);

      expect(_guidancePassword, findsOneWidget);
      expect(_inlineRejectedText, findsNothing);
      expect(_retryFailedText, findsNothing);
      expect(_fieldText(tester).length, 8);
      expect(_retryEnabled(tester), isTrue);
    });

    testWidgets(
        '本人確認の案内でダイアログの外側をタップした場合、再開ダイアログと本人確認の案内が表示されたままである [ACD-T31]',
        (tester) async {
      await _launchToGuidance(tester);

      await _tapOutside(tester);

      expect(_retryTitle, findsOneWidget);
      expect(_guidanceGoogle, findsOneWidget);
    });

    testWidgets(
        '本人確認の案内で「再試行」をタップし本人確認の応答を待っているときに戻る操作をした場合、再開ダイアログと「退会処理中です」が表示されたままで画面のパスは変わらない [ACD-T32]',
        (tester) async {
      final env = await _launchToGuidance(tester);
      env.reauth.gate = Completer<void>();
      await _tapRetry(tester);
      final before = env.path;

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_retryTitle, findsOneWidget);
      expect(_processingText, findsOneWidget);
      expect(env.path, before);
    });

    testWidgets(
        '本人確認の案内でパスワード「pass1234」を入力して「再試行」をタップし本人確認の応答を待っている場合、「再試行」が無効になり「退会処理中です」とインジケーターが表示され、入力（8文字）が残る [ACD-T33]',
        (tester) async {
      final env = await _launchToGuidance(tester, user: _userAWithPassword);
      env.reauth.gate = Completer<void>();
      await _enterPassword(tester, 'pass1234');

      await _tapRetry(tester);

      _expectRetryProcessingAndDisabled(tester);
      expect(_fieldText(tester).length, 8);
    });

    testWidgets(
        '本人確認の案内でパスワード「pass1234」を入力して「再試行」をタップし本人確認が AuthFailure で失敗したあともう一度「再試行」をタップした場合、本人確認の失敗文言が消え、本人確認は「pass1234」で合計2回呼ばれる [ACD-T34]',
        (tester) async {
      final env = await _launchToGuidance(tester, user: _userAWithPassword);
      env.reauth.passwordFailure = _auth;
      await _enterPassword(tester, 'pass1234');
      await _tapRetry(tester);
      expect(_inlineRejectedText, findsOneWidget);
      env.reauth.gate = Completer<void>();

      await _tapRetry(tester);

      expect(_inlineRejectedText, findsNothing);
      expect(env.reauth.passwordCalls, ['pass1234', 'pass1234']);
    });

    testWidgets(
        '本人確認の応答待ちでダイアログの外側をタップした場合、再開ダイアログと「退会処理中です」が表示されたままで本人確認と関数を呼ぶ回数は増えない [ACD-T35]',
        (tester) async {
      final env = await _launchToGuidance(tester);
      env.reauth.gate = Completer<void>();
      await _tapRetry(tester);
      final requests = env.repo.requestCount;

      await _tapOutside(tester);

      expect(_retryTitle, findsOneWidget);
      expect(_processingText, findsOneWidget);
      expect(env.reauth.googleCount, 1);
      expect(env.repo.requestCount, requests);
    });

    testWidgets(
        '本人確認の応答待ちでダイアログの下にあるボトムナビ「ホーム」の位置をタップした場合、再開ダイアログと「退会処理中です」が表示されたままで画面のパスは変わらない [ACD-T36]',
        (tester) async {
      final env = await _launchToGuidance(tester);
      env.reauth.gate = Completer<void>();
      await _tapRetry(tester);
      final before = env.path;

      await _tapBlocked(tester, _navLabel('ホーム'));

      expect(_retryTitle, findsOneWidget);
      expect(_processingText, findsOneWidget);
      expect(env.path, before);
    });

    testWidgets(
        '本人確認の案内を表示している間にダイアログの下にあるボトムナビ「ホーム」の位置をタップした場合、再開ダイアログと本人確認の案内が表示されたままで画面のパスは変わらない [ACD-T37]',
        (tester) async {
      final env = await _launchToGuidance(tester);
      final before = env.path;

      await _tapBlocked(tester, _navLabel('ホーム'));

      expect(_retryTitle, findsOneWidget);
      expect(_guidanceGoogle, findsOneWidget);
      expect(env.path, before);
    });

    testWidgets(
        'Google の本人確認の案内で「再試行」をタップし Google の本人確認が AuthFailure で失敗した場合、案内と本人確認の失敗文言が表示され「再試行」が有効に戻り、関数を呼ぶ回数は増えない [ACD-T38]',
        (tester) async {
      final env = await _launchToGuidance(tester);
      env.reauth.googleFailure = _auth;
      final before = env.repo.requestCount;

      await _tapRetry(tester);

      expect(_guidanceGoogle, findsOneWidget);
      expect(_inlineRejectedText, findsOneWidget);
      expect(_retryEnabled(tester), isTrue);
      expect(env.repo.requestCount, before);
    });

    testWidgets(
        '本人確認の案内のパスワード欄に「　」（全角スペース1文字）を入力した場合、「再試行」が有効になる [ACD-T39]',
        (tester) async {
      await _launchToGuidance(tester, user: _userAWithPassword);

      await _enterPassword(tester, '　');

      expect(_retryEnabled(tester), isTrue);
    });

    testWidgets(
        '本人確認の案内のパスワード欄に「 pass 」（前後に半角スペース）を入力して「再試行」をタップした場合、空白を含んだまま1回本人確認される [ACD-T40]',
        (tester) async {
      final env = await _launchToGuidance(tester, user: _userAWithPassword);
      await _enterPassword(tester, ' pass ');

      await _tapRetry(tester);

      expect(env.reauth.passwordCalls, [' pass ']);
    });

    testWidgets(
        'Google の本人確認の案内で「再試行」をタップし本人確認が TooManyRequestsFailure で失敗した場合、案内と試行回数の上限の文言が表示され「再試行」が有効に戻り、「再試行に失敗しました。」は出ず関数を呼ぶ回数は増えない [ACD-T41]',
        (tester) async {
      final env = await _launchToGuidance(tester);
      env.reauth.googleFailure = _tooMany;
      final before = env.repo.requestCount;

      await _tapRetry(tester);

      expect(_guidanceGoogle, findsOneWidget);
      expect(_tooManyText, findsOneWidget);
      expect(_retryEnabled(tester), isTrue);
      expect(_retryFailedText, findsNothing);
      expect(env.repo.requestCount, before);
    });

    testWidgets(
        '本人確認の案内で「再試行」をタップし本人確認が UnknownFailure で失敗した場合、案内が表示されたまま「再試行に失敗しました。」が表示される [ACD-E04]',
        (tester) async {
      final env = await _launchToGuidance(tester);
      env.reauth.googleFailure = _unknown;

      await _tapRetry(tester);

      expect(_guidanceGoogle, findsOneWidget);
      expect(_retryFailedText, findsOneWidget);
    });
  });

  group('SettingsPage 退会の前の本人確認：他の端末での退会', () {
    testWidgets(
        '「本人確認できませんでした」ダイアログを表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、そのダイアログが閉じてお知らせダイアログが表示され、退会の状態は待機に戻る [ACD-W54]',
        (tester) async {
      final env = await _launchW(tester,
          local: ['A'], configure: (e) => e.reauth.googleFailure = _auth);
      await _openSettingsTab(tester);
      await _withdrawToFinalOk(tester);
      expect(_reauthRejectedTitle, findsOneWidget);
      env.repo.withdrawn.add('A');

      await _resume(tester);

      expect(_reauthRejectedTitle, findsNothing);
      expect(_noticeTitle, findsOneWidget);
      expect(env.container.read(accountDeletionViewModelProvider).phase,
          AccountDeletionPhase.idle);
    });

    testWidgets(
        'メール登録のユーザーで設定画面の本人確認ダイアログを表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、本人確認ダイアログが閉じてお知らせダイアログが表示され、本人確認と関数は呼ばれない [ACD-W55]',
        (tester) async {
      final env = await _launchW(tester,
          user: _userAWithPassword, local: ['A']);
      await _openSettingsTab(tester);
      await _withdrawToFinalOk(tester);
      expect(_reauthTitle, findsOneWidget);
      env.repo.withdrawn.add('A');

      await _resume(tester);

      expect(_reauthTitle, findsNothing);
      expect(_reauthBody, findsNothing);
      expect(_noticeTitle, findsOneWidget);
      expect(env.reauth.passwordCalls, isEmpty);
      expect(env.reauth.googleCount, 0);
      expect(env.repo.requestCount, 0);
    });
  });
}
