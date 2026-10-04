import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_stock/core/di/repository_providers.dart';
import 'package:word_stock/core/di/sync_providers.dart';
import 'package:word_stock/core/error/failure.dart';
import 'package:word_stock/core/router/router.dart';
import 'package:word_stock/domain/entities/account_deletion_request.dart';
import 'package:word_stock/domain/entities/app_user.dart';
import 'package:word_stock/domain/entities/user_settings.dart';
import 'package:word_stock/domain/repositories/account_deletion_repository.dart';
import 'package:word_stock/domain/repositories/auth_repository.dart';
import 'package:word_stock/infrastructure/repositories/mock/mock_flashcard_result_repository.dart';
import 'package:word_stock/infrastructure/repositories/mock/mock_folder_repository.dart';
import 'package:word_stock/infrastructure/repositories/mock/mock_settings_repository.dart';
import 'package:word_stock/infrastructure/repositories/mock/mock_sync_repository.dart';
import 'package:word_stock/infrastructure/repositories/mock/mock_word_repository.dart';
import 'package:word_stock/presentation/settings/account_deletion_gate.dart';
import 'package:word_stock/presentation/settings/account_deletion_view_model.dart';
import 'package:word_stock/presentation/settings/settings_page.dart';
import 'package:word_stock/presentation/settings/settings_view_model.dart';

import '../../helpers/test_helpers.dart';

const _userId = 'mock-user-id';

Widget buildSettingsPage({List<Override> extra = const []}) {
  return buildWithMockRepositories(child: const SettingsPage(), extra: extra);
}

void main() {
  group('SettingsPage', () {
    testWidgets('ローディング中は CircularProgressIndicator が表示される', (tester) async {
      await tester.pumpWidget(buildSettingsPage(extra: [
        settingsViewModelProvider(_userId)
            .overrideWith(LoadingSettingsViewModel.new),
      ]));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('設定が読み込まれるとダークモードスイッチが表示される', (tester) async {
      await tester.pumpWidget(buildSettingsPage(extra: [
        settingsViewModelProvider(_userId)
            .overrideWith(DataSettingsViewModel.new),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('ダークモード'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('カラーテーマのドロップダウンが表示される', (tester) async {
      await tester.pumpWidget(buildSettingsPage(extra: [
        settingsViewModelProvider(_userId)
            .overrideWith(DataSettingsViewModel.new),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('カラーテーマ'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('ログアウト項目が表示される', (tester) async {
      await tester.pumpWidget(buildSettingsPage(extra: [
        settingsViewModelProvider(_userId)
            .overrideWith(DataSettingsViewModel.new),
      ]));
      await tester.pumpAndSettle();

      expect(find.text('ログアウト'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('ログアウトをタップすると確認ダイアログが表示される', (tester) async {
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

const Failure _network = Failure.network();
const Failure _auth = Failure.auth();
const Failure _unknown = Failure.unknown('x');

/// 退会用の手書き Fake。呼び出しを記録し、Failure の注入と Completer による応答待ちができる。
class _FakeAccountDeletionRepository implements AccountDeletionRepository {
  AccountDeletionRequest? record;

  Failure? findPendingFailure;
  Failure? markRequestedFailure;
  Failure? markServerDoneFailure;
  Failure? clearRequestFailure;
  Failure? requestFailure;
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
    requestCount++;
    final gate = requestGate;
    if (gate != null) await gate.future;
    final f = requestFailure;
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
}

/// ログイン状態を持つ Fake。signOut に成功するとログアウト状態（null）を流す。
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  AppUser? user;
  Failure? signOutFailure;
  int signOutCount = 0;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield user;
    yield* _controller.stream;
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    signOutCount++;
    final f = signOutFailure;
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
  final env = _Env(user: user, recordUserId: recordUserId, status: status);
  configure?.call(env);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(env.auth),
      accountDeletionRepositoryProvider.overrideWithValue(env.repo),
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
  void Function(_Env env)? configure,
}) async {
  final env = await _launch(tester, configure: configure);
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
