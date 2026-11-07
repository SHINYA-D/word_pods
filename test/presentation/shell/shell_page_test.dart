import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:word_pods/core/di/repository_providers.dart';
import 'package:word_pods/core/di/sync_providers.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/core/router/router.dart';
import 'package:word_pods/core/widgets/error_screen.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/entities/sample.dart';
import 'package:word_pods/domain/repositories/account_repository.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_flashcard_result_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_folder_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_settings_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_sync_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_word_repository.dart';
import 'package:word_pods/presentation/shell/shell_page.dart';

import '../../helpers/fake_infrastructure.dart';
import 'package:word_pods/core/di/provider_retry.dart';

const _u1 = AppUser(id: 'u1', email: 'u1@example.com');
const _u2 = AppUser(id: 'u2', email: 'u2@example.com');

final _sampleA = Sample(
  id: 'sample-a',
  name: 'A',
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

const _tabs3 = ['ホーム', '成績', '設定'];
const _tabs4 = ['ホーム', '成績', 'テスト', '設定'];

/// userId ごとに結果を決める Fake。[results] に値があれば即座に返し、無ければ
/// [complete] が呼ばれるまで応答しない（読み込み中）。
class _FakeAccountRepository implements AccountRepository {
  final results = <String, Either<Failure, bool>>{};
  final _pending = <String, List<Completer<Either<Failure, bool>>>>{};

  @override
  Future<Either<Failure, bool>> fetchIsDeveloper(String userId) {
    final r = results[userId];
    if (r != null) return Future.value(r);
    final c = Completer<Either<Failure, bool>>();
    _pending.putIfAbsent(userId, () => []).add(c);
    return c.future;
  }

  void complete(String userId, Either<Failure, bool> result) {
    _pending[userId]!.firstWhere((c) => !c.isCompleted).complete(result);
  }
}

/// ログイン状態を持つ Fake。signOut の回数を数える。
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  AppUser? user;
  int signOutCount = 0;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield user;
    yield* _controller.stream;
  }

  /// アプリ外で起きたログアウト・ログインを再現する。
  void emit(AppUser? next) {
    user = next;
    _controller.add(next);
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    signOutCount++;
    emit(null);
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Env {
  final auth = _FakeAuthRepository(_u1);
  final accounts = _FakeAccountRepository();
  final samples = FakeSampleRepository(initial: [_sampleA]);
  late ProviderContainer container;

  GoRouter get router => container.read(routerProvider);

  String get path => router.routerDelegate.currentConfiguration.uri.path;
}

class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      MaterialApp.router(routerConfig: ref.watch(routerProvider));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 本物のルーターでアプリを起動し、[start] の画面を開く。
/// [configure] で開発者判定の結果を先に仕込める。
Future<_Env> _launch(
  WidgetTester tester, {
  String start = '/home',
  void Function(_Env env)? configure,
}) async {
  final env = _Env();
  configure?.call(env);
  await tester.pumpWidget(ProviderScope(
    retry: noRetry,
    overrides: [
      authRepositoryProvider.overrideWithValue(env.auth),
      accountRepositoryProvider.overrideWithValue(env.accounts),
      sampleRepositoryProvider.overrideWithValue(env.samples),
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  env.router.go(start);
  // スプラッシュの最低表示時間（2秒）のタイマーを消化する
  await tester.pump(const Duration(seconds: 2));
  await _settle(tester);
  return env;
}

Future<void> _go(WidgetTester tester, _Env env, String path) async {
  env.router.go(path);
  await _settle(tester);
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(_navLabel(label));
  await _settle(tester);
}

Future<void> _logout(WidgetTester tester, _Env env) async {
  env.auth.emit(null);
  await _settle(tester);
}

Future<void> _login(WidgetTester tester, _Env env, AppUser user) async {
  env.auth.emit(user);
  await _settle(tester);
}

Finder _navLabel(String label) => find.descendant(
    of: find.byType(NavigationBar), matching: find.text(label));

List<String> _tabLabels(WidgetTester tester) => tester
    .widgetList<NavigationDestination>(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byType(NavigationDestination)))
    .map((d) => d.label)
    .toList();

void _expectTabs(WidgetTester tester, List<String> expected) {
  expect(_tabLabels(tester), expected);
  expect(find.byType(NavigationBar), findsOneWidget);
}

void _expectSelected(WidgetTester tester, String label) {
  final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
  expect(_tabLabels(tester)[bar.selectedIndex], label);
}

void _expectSamplePageNotShown() {
  expect(find.widgetWithText(AppBar, 'サンプル'), findsNothing);
}

void _expectNoErrorDisplay(_Env env) {
  expect(find.byType(SnackBar), findsNothing);
  expect(find.text('通信エラー'), findsNothing);
  expect(find.byType(ErrorScreen), findsNothing);
  expect(env.auth.signOutCount, 0);
  expect(env.path, '/home');
}

const _right = Right<Failure, bool>.new;

void main() {
  testWidgets(
      '開発者でログインしホーム画面（/home）を開いた場合、ボトムナビに「ホーム」「成績」「テスト」「設定」がこの順で表示される [SHL-G01]',
      (tester) async {
    await _launch(tester, configure: (e) => e.accounts.results['u1'] = _right(true));

    _expectTabs(tester, _tabs4);
  });

  testWidgets(
      '開発者でないユーザーでログインしホーム画面（/home）を開いた場合、ボトムナビに「ホーム」「成績」「設定」がこの順で表示され「テスト」は表示されず「ホーム」が選択状態になる [SHL-G02]',
      (tester) async {
    await _launch(tester, configure: (e) => e.accounts.results['u1'] = _right(false));

    _expectTabs(tester, _tabs3);
    _expectSelected(tester, 'ホーム');
  });

  testWidgets(
      'ログインしてホーム画面（/home）を開き開発者かどうかの読み込みが完了していない場合、ボトムナビに「ホーム」「成績」「設定」がこの順で表示され「テスト」は表示されない [SHL-G03]',
      (tester) async {
    await _launch(tester);

    _expectTabs(tester, _tabs3);
  });

  testWidgets(
      '読み込みが完了していない状態から Right(true) で完了した場合、ボトムナビに「ホーム」「成績」「テスト」「設定」がこの順で表示され「ホーム」が選択状態のままになる [SHL-G04]',
      (tester) async {
    final env = await _launch(tester);
    _expectTabs(tester, _tabs3);

    env.accounts.complete('u1', _right(true));
    await _settle(tester);

    _expectTabs(tester, _tabs4);
    _expectSelected(tester, 'ホーム');
  });

  testWidgets(
      '開発者かどうかの読み込みが UnknownFailure で失敗した場合、「テスト」は表示されず、エラー表示もログアウトもせずパスは /home のままである [SHL-G05]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = const Left(Failure.unknown('x')));

    _expectTabs(tester, _tabs3);
    _expectNoErrorDisplay(env);
  });

  testWidgets(
      'サンプルが「A」の1件ある開発者でホーム画面を開き「テスト」をタップした場合、パスが /sample になり AppBar に「サンプル」と表示され「テスト」が選択状態になる [SHL-G06]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = _right(true));

    await _tapTab(tester, 'テスト');

    expect(env.path, '/sample');
    expect(find.widgetWithText(AppBar, 'サンプル'), findsOneWidget);
    _expectSelected(tester, 'テスト');
  });

  testWidgets(
      '開発者でないユーザーで設定画面（/settings）を開き /sample への移動を要求した場合、パスが /home になり AppBar の「サンプル」は表示されない [SHL-G07]',
      (tester) async {
    final env = await _launch(tester,
        start: '/settings',
        configure: (e) => e.accounts.results['u1'] = _right(false));

    await _go(tester, env, '/sample');

    expect(env.path, '/home');
    _expectSamplePageNotShown();
  });

  testWidgets(
      '開発者かどうかの読み込みが完了していない状態で設定画面から /sample への移動を要求した場合、パスが /home になり AppBar の「サンプル」は表示されない [SHL-G08]',
      (tester) async {
    final env = await _launch(tester, start: '/settings');

    await _go(tester, env, '/sample');

    expect(env.path, '/home');
    _expectSamplePageNotShown();
  });

  testWidgets(
      '開発者かどうかの読み込みが UnknownFailure で失敗した状態で設定画面から /sample への移動を要求した場合、パスが /home になり「サンプル」・スナックバー・通信エラーダイアログは表示されない [SHL-G09]',
      (tester) async {
    final env = await _launch(tester,
        start: '/settings',
        configure: (e) => e.accounts.results['u1'] = const Left(Failure.unknown('x')));

    await _go(tester, env, '/sample');

    expect(env.path, '/home');
    _expectSamplePageNotShown();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('通信エラー'), findsNothing);
  });

  testWidgets(
      '開発者でないユーザーでホーム画面を開き「設定」をタップした場合、パスが /settings になり「設定」が選択状態になる [SHL-G10]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = _right(false));

    await _tapTab(tester, '設定');

    expect(env.path, '/settings');
    _expectSelected(tester, '設定');
  });

  testWidgets(
      '開発者でないユーザーでホーム画面を開き「成績」をタップした場合、パスが /results になり「成績」が選択状態になる [SHL-G11]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = _right(false));

    await _tapTab(tester, '成績');

    expect(env.path, '/results');
    _expectSelected(tester, '成績');
  });

  testWidgets(
      '開発者の u1 でログインしログアウトして開発者でない u2 でログインし直しホーム画面を開いた場合、ボトムナビに「ホーム」「成績」「設定」がこの順で表示され「テスト」は表示されない [SHL-G12]',
      (tester) async {
    final env = await _launch(tester, configure: (e) {
      e.accounts.results['u1'] = _right(true);
      e.accounts.results['u2'] = _right(false);
    });
    _expectTabs(tester, _tabs4);

    await _logout(tester, env);
    await _login(tester, env, _u2);

    expect(env.path, '/home');
    _expectTabs(tester, _tabs3);
  });

  testWidgets(
      '開発者でない u1 でログインしログアウトして開発者の u2 でログインし直しホーム画面を開いた場合、ボトムナビに「ホーム」「成績」「テスト」「設定」がこの順で表示される [SHL-G13]',
      (tester) async {
    final env = await _launch(tester, configure: (e) {
      e.accounts.results['u1'] = _right(false);
      e.accounts.results['u2'] = _right(true);
    });
    _expectTabs(tester, _tabs3);

    await _logout(tester, env);
    await _login(tester, env, _u2);

    expect(env.path, '/home');
    _expectTabs(tester, _tabs4);
  });

  testWidgets(
      '開発者でない u1 でホーム画面を開いた後 Right(true) を返すように変わり「成績」「ホーム」の順にタップした場合、ボトムナビは「ホーム」「成績」「設定」のままで「テスト」は表示されない [SHL-G14]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = _right(false));
    env.accounts.results['u1'] = _right(true);

    await _tapTab(tester, '成績');
    await _tapTab(tester, 'ホーム');

    _expectTabs(tester, _tabs3);
  });

  testWidgets(
      '開発者でない u1 でログインしログアウトして Right(true) を返すように変わってから同じ u1 でログインし直した場合、ボトムナビに「ホーム」「成績」「テスト」「設定」がこの順で表示される [SHL-G15]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = _right(false));
    await _logout(tester, env);
    env.accounts.results['u1'] = _right(true);

    await _login(tester, env, _u1);

    expect(env.path, '/home');
    _expectTabs(tester, _tabs4);
  });

  testWidgets(
      '開発者でホーム画面を開き「設定」をタップした場合、パスが /settings になり「設定」が選択状態になる [SHL-G16]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = _right(true));

    await _tapTab(tester, '設定');

    expect(env.path, '/settings');
    _expectSelected(tester, '設定');
  });

  testWidgets(
      '開発者でホーム画面を開き「成績」をタップした場合、パスが /results になり「成績」が選択状態になる [SHL-G17]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = _right(true));

    await _tapTab(tester, '成績');

    expect(env.path, '/results');
    _expectSelected(tester, '成績');
  });

  testWidgets(
      '開発者で設定画面を開き「ホーム」をタップした場合、パスが /home になり「ホーム」が選択状態になる [SHL-G18]',
      (tester) async {
    final env = await _launch(tester,
        start: '/settings',
        configure: (e) => e.accounts.results['u1'] = _right(true));

    await _tapTab(tester, 'ホーム');

    expect(env.path, '/home');
    _expectSelected(tester, 'ホーム');
  });

  testWidgets(
      'サンプルが「A」の1件ある開発者で設定画面を開き /sample への移動を要求した場合、パスが /sample になり AppBar に「サンプル」と表示される [SHL-G19]',
      (tester) async {
    final env = await _launch(tester,
        start: '/settings',
        configure: (e) => e.accounts.results['u1'] = _right(true));

    await _go(tester, env, '/sample');

    expect(env.path, '/sample');
    expect(find.widgetWithText(AppBar, 'サンプル'), findsOneWidget);
  });

  testWidgets(
      '開発者でないユーザーで設定画面を開いた場合、ボトムナビに「ホーム」「成績」「設定」がこの順で表示され「テスト」は表示されず「設定」が選択状態になる [SHL-G20]',
      (tester) async {
    await _launch(tester,
        start: '/settings',
        configure: (e) => e.accounts.results['u1'] = _right(false));

    _expectTabs(tester, _tabs3);
    _expectSelected(tester, '設定');
  });

  testWidgets(
      '開発者で成績画面（/results）を開いた場合、ボトムナビに「ホーム」「成績」「テスト」「設定」がこの順で表示され「成績」が選択状態になる [SHL-G21]',
      (tester) async {
    await _launch(tester,
        start: '/results',
        configure: (e) => e.accounts.results['u1'] = _right(true));

    _expectTabs(tester, _tabs4);
    _expectSelected(tester, '成績');
  });

  testWidgets(
      '開発者かどうかの読み込みが NetworkFailure で失敗した場合、「テスト」は表示されず、通信エラーダイアログ・スナックバーは表示されずログアウトもせずパスは /home のままである [SHL-G22]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = const Left(Failure.network()));

    _expectTabs(tester, _tabs3);
    _expectNoErrorDisplay(env);
  });

  testWidgets(
      '設定画面で /sample への移動を要求してパスが /home になった後に読み込みが Right(true) で完了した場合、パスは /home のままで「テスト」が表示される [SHL-G23]',
      (tester) async {
    final env = await _launch(tester, start: '/settings');
    await _go(tester, env, '/sample');
    expect(env.path, '/home');

    env.accounts.complete('u1', _right(true));
    await _settle(tester);

    expect(env.path, '/home');
    _expectTabs(tester, _tabs4);
  });

  testWidgets(
      '開発者かどうかの読み込みが AuthFailure で失敗した場合、「テスト」は表示されず、通信エラーダイアログ・スナックバーは表示されずログアウトもせずパスは /home のままである [SHL-G24]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = const Left(Failure.auth()));

    _expectTabs(tester, _tabs3);
    _expectNoErrorDisplay(env);
  });

  testWidgets(
      '開発者かどうかの読み込みが NotFoundFailure で失敗した場合、「テスト」は表示されず、エラー画面・スナックバーは表示されずログアウトもせずパスは /home のままである [SHL-G25]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = const Left(Failure.notFound()));

    _expectTabs(tester, _tabs3);
    _expectNoErrorDisplay(env);
  });

  testWidgets(
      '開発者の u1 でログインしログアウトして u2 でログインし直し u2 の読み込みが完了していない場合、ボトムナビに「ホーム」「成績」「設定」がこの順で表示され「テスト」は表示されない [SHL-G26]',
      (tester) async {
    final env = await _launch(tester,
        configure: (e) => e.accounts.results['u1'] = _right(true));
    _expectTabs(tester, _tabs4);

    await _logout(tester, env);
    await _login(tester, env, _u2);

    expect(env.path, '/home');
    _expectTabs(tester, _tabs3);
  });

  testWidgets(
      'u1 の読み込み中にログアウトして開発者でない u2 でログインし直し u2 が Right(false) で完了した後に u1 が Right(true) で完了した場合、ボトムナビに「ホーム」「成績」「設定」がこの順で表示され「テスト」は表示されない [SHL-G27]',
      (tester) async {
    final env = await _launch(tester);
    await _logout(tester, env);
    env.accounts.results['u2'] = _right(false);
    await _login(tester, env, _u2);

    env.accounts.complete('u1', _right(true));
    await _settle(tester);

    expect(env.path, '/home');
    _expectTabs(tester, _tabs3);
  });

  testWidgets(
      'サンプルが「A」の1件ある開発者の u1 でサンプル画面を開きログアウトして開発者でない u2 でログインし直した場合、パスが /home になり「テスト」と AppBar の「サンプル」は表示されない [SHL-G28]',
      (tester) async {
    final env = await _launch(tester, configure: (e) {
      e.accounts.results['u1'] = _right(true);
      e.accounts.results['u2'] = _right(false);
    });
    await _go(tester, env, '/sample');
    expect(env.path, '/sample');
    expect(find.widgetWithText(AppBar, 'サンプル'), findsOneWidget);

    await _logout(tester, env);
    await _login(tester, env, _u2);

    expect(env.path, '/home');
    _expectTabs(tester, _tabs3);
    _expectSamplePageNotShown();
  });

  testWidgets(
      '開発者の u1 でログインしログアウトして u2 でログインし直し u2 の読み込みが UnknownFailure で失敗した場合、ボトムナビに「ホーム」「成績」「設定」がこの順で表示され「テスト」は表示されない [SHL-G29]',
      (tester) async {
    final env = await _launch(tester, configure: (e) {
      e.accounts.results['u1'] = _right(true);
      e.accounts.results['u2'] = const Left(Failure.unknown('x'));
    });
    _expectTabs(tester, _tabs4);

    await _logout(tester, env);
    await _login(tester, env, _u2);

    expect(env.path, '/home');
    _expectTabs(tester, _tabs3);
  });

  testWidgets(
      'u1 の読み込み中にログアウトして u2 でログインし直し u2 の完了前に u1 が Right(true) で完了した場合、ボトムナビに「ホーム」「成績」「設定」がこの順で表示され「テスト」は表示されない [SHL-G30]',
      (tester) async {
    final env = await _launch(tester);
    await _logout(tester, env);
    await _login(tester, env, _u2);

    env.accounts.complete('u1', _right(true));
    await _settle(tester);

    expect(env.path, '/home');
    _expectTabs(tester, _tabs3);
  });

  // ─── 仕様書に ID の無い観点（ShellPage 単体の選択状態の判定） ───

  testWidgets(
      '/folder/:id のようなホーム配下のサブパスを開いた場合、ホームタブが選択状態になる',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/folder/folder-1',
      routes: [
        ShellRoute(
          builder: (context, state, navigator) =>
              ShellPage(showSampleTab: true, child: navigator),
          routes: [
            GoRoute(
              path: '/folder/:folderId',
              builder: (context, state) => const Text('folder-screen'),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    _expectSelected(tester, 'ホーム');
    expect(find.text('folder-screen'), findsOneWidget);
  });
}
