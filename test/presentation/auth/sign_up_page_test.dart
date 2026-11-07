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
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/domain/repositories/account_deletion_repository.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/repositories/email_verification_repository.dart';
import 'package:word_pods/domain/repositories/legal_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_flashcard_result_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_folder_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_settings_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_sync_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_word_repository.dart';
import 'package:word_pods/presentation/auth/sign_up/sign_up_page.dart';
import 'package:word_pods/presentation/legal/legal_consent_gate.dart';
import 'package:word_pods/presentation/legal/legal_consent_view_model.dart';
import 'package:word_pods/presentation/legal/legal_document_page.dart';
import 'package:word_pods/presentation/settings/account_deletion_gate.dart';
import 'package:word_pods/presentation/settings/account_deletion_view_model.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_gate.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_view_model.dart';
import 'package:word_pods/core/di/provider_retry.dart';

/// 仕様書（docs/detailed_design/legal_consent/legal_consent.md）3.6 節
/// 「新規登録画面での同意（SignUpPage）」の Widget テスト。期待値は仕様書から作っている。
///
/// 新規登録の後にホーム画面へ移る・同意ダイアログが出る（S09〜S12, S24）ためには、
/// ルーターとゲートを含むアプリ全体の配線が要る。そのため lib/app.dart と同じ配線の
/// テスト用アプリ [_TestApp] で、ログイン画面から新規登録画面を開いて確かめる。
/// app.dart を変えたら [_TestApp] も更新する。

const _userA = AppUser(id: 'A', email: 'a@example.com');

const _config = LegalConfig(
  termsVersion: '2026-01-01',
  privacyVersion: '2026-01-01',
  termsUrl: 'https://example.com/terms',
  privacyUrl: 'https://example.com/privacy',
);

const Failure _network = Failure.network();
const Failure _auth = Failure.auth();
const Failure _notFound = Failure.notFound();
const Failure _unknown = Failure.unknown('x');

const _termsUrl = 'https://example.com/terms';
const _privacyUrl = 'https://example.com/privacy';
const _defaultTermsUrl = 'https://word-pods-web.web.app/terms';
const _defaultPrivacyUrl = 'https://word-pods-web.web.app/privacy';

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

  final acceptCalls = <({String? terms, String? privacy})>[];

  @override
  Future<Either<Failure, LegalConfig>> fetchLegalConfig() async {
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
    // accepted のときだけ、渡された版数を同意済みの版数として記録する（判定が送信より前に走れば同意ダイアログが出る）
    if (acceptResult.isRight() &&
        acceptResult.getOrElse((_) => LegalAcceptResult.outdated) ==
            LegalAcceptResult.accepted) {
      consents = Right(LegalConsents(
          termsVersion: termsVersion, privacyVersion: privacyVersion));
    }
    return acceptResult;
  }
}

/// ログイン状態を持つ Fake。新規登録の結果と応答待ちを制御でき、成功したら authStateChanges に流す。
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.user);

  AppUser? user;

  Failure? signUpFailure;
  Completer<void>? signUpGate;
  int signUpCount = 0;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get authStateChanges async* {
    yield user;
    yield* _controller.stream;
  }

  void emitUser(AppUser? next) {
    user = next;
    _controller.add(next);
  }

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    signUpCount++;
    final gate = signUpGate;
    if (gate != null) await gate.future;
    final f = signUpFailure;
    if (f != null) return Left(f);
    emitUser(_userA);
    return const Right(_userA);
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

/// 確認メールの送信と確認状態の問い合わせの Fake。送信は成功し、問い合わせはログイン中のユーザー
/// （[_userA] は確認済み）を返す。新規登録の後は送信完了ダイアログが出る
/// （docs/detailed_design/email_verification/email_verification.md）。
class _FakeEmailVerificationRepository implements EmailVerificationRepository {
  _FakeEmailVerificationRepository(this._auth);

  final _FakeAuthRepository _auth;

  @override
  Future<Either<Failure, AppUser>> reloadUser() async {
    final user = _auth.user;
    return user == null ? const Left(Failure.auth()) : Right(user);
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async =>
      const Right(unit);
}

class _Env {
  _Env(AppUser? user) : auth = _FakeAuthRepository(user) {
    emailVerification = _FakeEmailVerificationRepository(auth);
  }

  final _FakeAuthRepository auth;
  late final _FakeEmailVerificationRepository emailVerification;
  final deletion = _FakeAccountDeletionRepository();
  final legal = _FakeLegalRepository();
  final web = _FakeWebView();
  late ProviderContainer container;

  String get path => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .path;
}

/// lib/app.dart と同じ構成（Gate の重ね方・起動時の確認・resumed の確認）のテスト用アプリ。
class _TestApp extends ConsumerStatefulWidget {
  const _TestApp();

  @override
  ConsumerState<_TestApp> createState() => _TestAppState();
}

class _TestAppState extends ConsumerState<_TestApp> {
  AppLifecycleObserver? _observer;

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

/// アプリを起動する。スプラッシュの最低表示時間（2秒）を進めて、最初の画面まで進める。
Future<_Env> _launch(
  WidgetTester tester, {
  AppUser? user,
  void Function(_Env env)? configure,
  Size size = const Size(800, 2400),
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
      emailVerificationRepositoryProvider
          .overrideWithValue(env.emailVerification),
      accountDeletionRepositoryProvider.overrideWithValue(env.deletion),
      legalRepositoryProvider.overrideWithValue(env.legal),
      legalWebViewBuilderProvider.overrideWithValue(env.web.build),
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
  await tester.pump(const Duration(seconds: 2));
  await _settle(tester);
  return env;
}

/// ログインしていない状態で、ログイン画面（/login）から新規登録画面（/sign-up）を開く。
Future<_Env> _openSignUp(
  WidgetTester tester, {
  void Function(_Env env)? configure,
}) async {
  final env = await _launch(tester, configure: configure);
  expect(env.path, '/login', reason: '準備: ログイン画面');
  await _tap(tester, find.text('新規登録'));
  expect(find.byType(SignUpPage), findsOneWidget, reason: '準備: 新規登録画面');
  return env;
}

// ─── 確認の道具 ───

const _termsLabel = '利用規約に同意する';
const _privacyLabel = 'プライバシーポリシーに同意する';

final _signUpPage = find.byType(SignUpPage);
Finder _inPage(Finder f) => find.descendant(of: _signUpPage, matching: f);

final _submit = _inPage(find.byType(FilledButton));
final _termsLink = _inPage(find.widgetWithText(TextButton, '利用規約を読む'));
final _privacyLink = _inPage(find.widgetWithText(TextButton, 'プライバシーポリシーを読む'));
final _document = find.byType(LegalDocumentPage);
final _dialogTitle = find.text('同意のお願い');
final _networkTitle = find.text('通信エラー');

Finder _row(String label) =>
    _inPage(find.widgetWithText(CheckboxListTile, label));
Finder _box(String label) =>
    find.descendant(of: _row(label), matching: find.byType(Checkbox));
bool _isChecked(WidgetTester t, String label) =>
    t.widget<Checkbox>(_box(label)).value ?? false;
bool _submitEnabled(WidgetTester t) =>
    t.widget<FilledButton>(_submit).onPressed != null;

Future<void> _check(WidgetTester t, String label) => _tap(t, _box(label));
Future<void> _checkBoth(WidgetTester t) async {
  await _check(t, _termsLabel);
  await _check(t, _privacyLabel);
}

/// 正しい入力（a@example.com / password1 / password1）
Future<void> _fillValid(WidgetTester t) async {
  final fields = _inPage(find.byType(TextFormField));
  await t.enterText(fields.at(0), 'a@example.com');
  await t.enterText(fields.at(1), 'password1');
  await t.enterText(fields.at(2), 'password1');
  await t.pump();
}

Future<void> _tapSubmit(WidgetTester t) => _tap(t, _submit);

String _emailText(WidgetTester t) =>
    t.widget<TextFormField>(_inPage(find.byType(TextFormField)).at(0)).controller!.text;

void _expectDocument(String title) {
  expect(_document, findsOneWidget);
  expect(find.descendant(of: _document, matching: find.text(title)),
      findsOneWidget);
  expect(find.descendant(of: _document, matching: find.byType(BackButton)),
      findsOneWidget);
}

Future<void> _tapDocBack(WidgetTester t) => _tap(
    t, find.descendant(of: _document, matching: find.byType(BackButton)));

/// 正しい入力と2つのチェックで「アカウント作成」をタップする。
/// 作成に成功したら確認メールの送信完了ダイアログが出るので、「閉じる」で閉じる
/// （確認済みのユーザーならホーム画面へ移る。docs/detailed_design/email_verification/email_verification.md EMV-A07）。
Future<void> _signUpWithValid(WidgetTester t) async {
  await _fillValid(t);
  await _checkBoth(t);
  await _tapSubmit(t);
  final close = find.widgetWithText(TextButton, '閉じる');
  if (close.evaluate().isNotEmpty) await _tap(t, close);
}

void _expectDialogWithBothRows() {
  expect(_dialogTitle, findsOneWidget);
  expect(find.widgetWithText(CheckboxListTile, _termsLabel), findsOneWidget);
  expect(find.widgetWithText(CheckboxListTile, _privacyLabel), findsOneWidget);
}

void main() {
  _existingTests();
  _specTests();
}

// ─── 既存のテスト（仕様 ID なし。バリデーションと初期表示） ───

void _existingTests() {
  group('SignUpPage 既存', () {
    testWidgets('初期表示: 3 つのフォームフィールドとアカウント作成ボタンが揃っている', (t) async {
      await _openSignUp(t);

      expect(_inPage(find.text('新規登録')), findsOneWidget);
      expect(_inPage(find.byIcon(Icons.email_outlined)), findsOneWidget);
      expect(_inPage(find.byIcon(Icons.lock_outlined)), findsNWidgets(2));
      expect(_inPage(find.text('アカウント作成')), findsOneWidget);
    });

    testWidgets('メールアドレスが空のままアカウント作成するとバリデーションエラーが出る', (t) async {
      await _openSignUp(t);

      await _checkBoth(t);
      await _tapSubmit(t);

      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
    });

    testWidgets('パスワードが 6 文字未満のときバリデーションエラーが出る', (t) async {
      await _openSignUp(t);

      final fields = _inPage(find.byType(TextFormField));
      await t.enterText(fields.at(0), 'test@example.com');
      await t.enterText(fields.at(1), '12345');
      await _checkBoth(t);
      await _tapSubmit(t);

      expect(find.text('6文字以上で入力してください'), findsOneWidget);
    });

    testWidgets('パスワードと確認が一致しないときバリデーションエラーが出る', (t) async {
      await _openSignUp(t);

      final fields = _inPage(find.byType(TextFormField));
      await t.enterText(fields.at(0), 'test@example.com');
      await t.enterText(fields.at(1), 'password123');
      await t.enterText(fields.at(2), 'different');
      await _checkBoth(t);
      await _tapSubmit(t);

      expect(find.text('パスワードが一致しません'), findsOneWidget);
    });
  });
}

// ─── 3.6 新規登録画面での同意 ───

void _specTests() {
  group('SignUpPage 新規登録画面での同意', () {
    spec('LGL-S01', '新規登録画面を開き規約の情報の読み取りが終わった場合、パスワード（確認）の下に4つの項目がこの順で表示され、2つとも未チェックで「アカウント作成」は無効になる',
        (t) async {
      await _openSignUp(t);

      final confirm = t.getRect(find.text('パスワード（確認）').first);
      final ys = [
        t.getRect(_termsLink).top,
        t.getRect(_row(_termsLabel)).top,
        t.getRect(_privacyLink).top,
        t.getRect(_row(_privacyLabel)).top,
        t.getRect(_submit).top,
      ];
      expect(ys.first, greaterThan(confirm.bottom - 1));
      for (var i = 0; i < ys.length - 1; i++) {
        expect(ys[i], lessThan(ys[i + 1]), reason: '$i 番目の項目の並び');
      }
      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_submitEnabled(t), isFalse);
    });

    spec('LGL-S02', '正しい入力をして「利用規約に同意する」だけをチェックした場合、「アカウント作成」は無効のままになる',
        (t) async {
      await _openSignUp(t);

      await _fillValid(t);
      await _check(t, _termsLabel);

      expect(_isChecked(t, _termsLabel), isTrue);
      expect(_submitEnabled(t), isFalse);
    });

    spec('LGL-S03', '正しい入力をして「プライバシーポリシーに同意する」だけをチェックした場合、「アカウント作成」は無効のままになる',
        (t) async {
      await _openSignUp(t);

      await _fillValid(t);
      await _check(t, _privacyLabel);

      expect(_isChecked(t, _privacyLabel), isTrue);
      expect(_submitEnabled(t), isFalse);
    });

    spec('LGL-S04', '正しい入力をして2つのチェックボックスをチェックした場合、「アカウント作成」が有効になる',
        (t) async {
      await _openSignUp(t);

      await _fillValid(t);
      await _checkBoth(t);

      expect(_submitEnabled(t), isTrue);
    });

    spec('LGL-S05', '正しい入力をして2つチェックした後に「利用規約に同意する」のチェックを外した場合、「アカウント作成」が無効になる',
        (t) async {
      await _openSignUp(t);

      await _fillValid(t);
      await _checkBoth(t);
      expect(_submitEnabled(t), isTrue, reason: '準備');
      await _check(t, _termsLabel);

      expect(_isChecked(t, _termsLabel), isFalse);
      expect(_submitEnabled(t), isFalse);
    });

    spec('LGL-S06', '「利用規約に同意する」の文言をタップした場合、「利用規約に同意する」がチェックされる',
        (t) async {
      await _openSignUp(t);

      await _tap(t, _inPage(find.text(_termsLabel)));

      expect(_isChecked(t, _termsLabel), isTrue);
      expect(_isChecked(t, _privacyLabel), isFalse);
    });

    spec('LGL-S07', '「プライバシーポリシーに同意する」の文言をタップした場合、「プライバシーポリシーに同意する」がチェックされる',
        (t) async {
      await _openSignUp(t);

      await _tap(t, _inPage(find.text(_privacyLabel)));

      expect(_isChecked(t, _privacyLabel), isTrue);
      expect(_isChecked(t, _termsLabel), isFalse);
    });

    spec('LGL-S08', '規約の情報の読み取りの応答を待っている間に正しい入力をして2つチェックした場合、「アカウント作成」は無効のままになる',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.configGate = Completer<void>();
      });

      await _fillValid(t);
      await _checkBoth(t);

      expect(_isChecked(t, _termsLabel), isTrue);
      expect(_isChecked(t, _privacyLabel), isTrue);
      expect(_submitEnabled(t), isFalse);
      env.legal.configGate!.complete();
      await _settle(t);
      expect(_submitEnabled(t), isTrue, reason: '読み取りが終われば押せる');
    });

    spec('LGL-S09', '2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が accepted を返した場合、ホーム画面に移動し同意ダイアログは表示されず送信が画面の版数で1回呼ばれる',
        (t) async {
      final env = await _openSignUp(t);

      await _signUpWithValid(t);

      expect(env.path, '/home');
      expect(_dialogTitle, findsNothing);
      expect(env.legal.acceptCalls.length, 1);
      expect(env.legal.acceptCalls.single.terms, '2026-01-01');
      expect(env.legal.acceptCalls.single.privacy, '2026-01-01');
    });

    spec('LGL-S10', '2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が UnknownFailure で失敗した場合、ホーム画面の上に2つの行がある同意ダイアログが表示されエラーの表示は出ない',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.acceptResult = const Left(_unknown);
      });

      await _signUpWithValid(t);

      expect(env.legal.acceptCalls.length, 1);
      expect(env.path, '/home');
      _expectDialogWithBothRows();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('エラーが発生しました'), findsNothing);
    });

    spec('LGL-S11', '2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が NetworkFailure で失敗した場合、ホーム画面の上に同意ダイアログが表示され「通信エラー」ダイアログは表示されない',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.acceptResult = const Left(_network);
      });

      await _signUpWithValid(t);

      expect(env.legal.acceptCalls.length, 1);
      expect(env.path, '/home');
      expect(_dialogTitle, findsOneWidget);
      expect(_networkTitle, findsNothing);
    });

    spec('LGL-S12', '2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が outdated を返した場合、ホーム画面の上に同意ダイアログが表示される',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      });

      await _signUpWithValid(t);

      expect(env.legal.acceptCalls.length, 1);
      expect(env.path, '/home');
      expect(_dialogTitle, findsOneWidget);
    });

    spec('LGL-S13', '2つチェックして「アカウント作成」をタップし、作成が AuthFailure で失敗した場合、「このメールアドレスはすでに使用されています」が表示され新規登録画面のまま入力とチェックが残り送信は0回になる',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.auth.signUpFailure = _auth;
      });

      await _signUpWithValid(t);

      expect(find.text('このメールアドレスはすでに使用されています'), findsOneWidget);
      expect(_signUpPage, findsOneWidget);
      expect(_emailText(t), 'a@example.com');
      expect(_isChecked(t, _termsLabel), isTrue);
      expect(_isChecked(t, _privacyLabel), isTrue);
      expect(env.legal.acceptCalls, isEmpty);
    });

    spec('LGL-S14', '`app_config/legal` が無い状態で2つチェックして「アカウント作成」をタップし作成が成功した場合、同意の送信が既定値の版数で1回呼ばれる',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.configFailure = _notFound;
      });

      await _signUpWithValid(t);

      expect(env.legal.acceptCalls.length, 1);
      expect(env.legal.acceptCalls.single.terms, '2026-10-12');
      expect(env.legal.acceptCalls.single.privacy, '2026-10-12');
    });

    spec('LGL-S15', '規約の情報の読み取りが NetworkFailure で失敗する状態で2つチェックして「アカウント作成」をタップし作成が成功した場合、同意の送信が既定値の版数で1回呼ばれ「通信エラー」ダイアログは表示されない',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.configFailure = _network;
      });

      await _signUpWithValid(t);

      expect(env.legal.acceptCalls.length, 1);
      expect(env.legal.acceptCalls.single.terms, '2026-10-12');
      expect(env.legal.acceptCalls.single.privacy, '2026-10-12');
      expect(_networkTitle, findsNothing);
    });

    spec('LGL-S16', '規約の情報の読み取りが UnknownFailure で失敗する状態で2つチェックして「アカウント作成」をタップし作成が成功した場合、同意の送信が既定値の版数で1回呼ばれる',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.configFailure = _unknown;
      });

      await _signUpWithValid(t);

      expect(env.legal.acceptCalls.length, 1);
      expect(env.legal.acceptCalls.single.terms, '2026-10-12');
      expect(env.legal.acceptCalls.single.privacy, '2026-10-12');
    });

    spec('LGL-S17', 'メールアドレスを入力して「利用規約に同意する」をチェックし「利用規約を読む」から閲覧画面を開いて戻るボタンで戻った場合、入力とチェックはそのまま残る',
        (t) async {
      final env = await _openSignUp(t);

      await t.enterText(_inPage(find.byType(TextFormField)).at(0), 'a@example.com');
      await _check(t, _termsLabel);
      await _tap(t, _termsLink);
      _expectDocument('利用規約');
      expect(env.web.loadCount(_termsUrl), 1);
      await _tapDocBack(t);

      expect(_document, findsNothing);
      expect(_signUpPage, findsOneWidget);
      expect(_emailText(t), 'a@example.com');
      expect(_isChecked(t, _termsLabel), isTrue);
    });

    spec('LGL-S18', '「プライバシーポリシーを読む」をタップした場合、閲覧画面が開き「プライバシーポリシー」の見出しで privacyUrl の読み込みが指示される',
        (t) async {
      final env = await _openSignUp(t);

      await _tap(t, _privacyLink);

      _expectDocument('プライバシーポリシー');
      expect(env.web.loadCount(_privacyUrl), 1);
    });

    spec('LGL-S19', '`app_config/legal` が無い状態で「利用規約を読む」をタップした場合、既定値の利用規約の URL の読み込みが指示される',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.configFailure = _notFound;
      });

      await _tap(t, _termsLink);

      expect(env.web.loadCount(_defaultTermsUrl), 1);
    });

    spec('LGL-S20', 'メールアドレスを空のままパスワードを入力し2つチェックして「アカウント作成」をタップした場合、「メールアドレスを入力してください」が表示され作成と送信は0回になる',
        (t) async {
      final env = await _openSignUp(t);

      final fields = _inPage(find.byType(TextFormField));
      await t.enterText(fields.at(1), 'password1');
      await t.enterText(fields.at(2), 'password1');
      await _checkBoth(t);
      await _tapSubmit(t);

      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(env.auth.signUpCount, 0);
      expect(env.legal.acceptCalls, isEmpty);
    });

    spec('LGL-S21', '2つチェックして「アカウント作成」をタップし作成の応答を待っている間にもう一度タップした場合、アカウントの作成は1回だけ呼ばれる',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.auth.signUpGate = Completer<void>();
      });

      await _fillValid(t);
      await _checkBoth(t);
      await _tapSubmit(t);
      await t.tap(_submit, warnIfMissed: false);
      await _settle(t);
      expect(env.auth.signUpCount, 1);
      env.auth.signUpGate!.complete();
      await _settle(t);

      expect(env.auth.signUpCount, 1);
    });

    spec('LGL-S22', '幅320・高さ480の端末で新規登録画面を開いた場合、はみ出しが起きずスクロールすると「アカウント作成」ボタンが表示される',
        (t) async {
      await _openSignUp(t);

      t.view.physicalSize = const Size(320, 480);
      await _settle(t);
      expect(t.takeException(), isNull);
      await t.drag(
          _inPage(find.byType(SingleChildScrollView)), const Offset(0, -2000));
      await _settle(t);

      expect(_submit, findsOneWidget);
      expect(t.getRect(_submit).bottom, lessThanOrEqualTo(480));
      expect(t.takeException(), isNull);
    });

    spec('LGL-S23', '「プライバシーポリシーに同意する」をチェックして「プライバシーポリシーを読む」から閲覧画面を開き戻る操作をした場合、新規登録画面に戻りチェックはそのまま残る',
        (t) async {
      await _openSignUp(t);

      await _check(t, _privacyLabel);
      await _tap(t, _privacyLink);
      expect(_document, findsOneWidget, reason: '準備: 閲覧画面');
      await t.binding.handlePopRoute();
      await _settle(t);

      expect(_document, findsNothing);
      expect(_signUpPage, findsOneWidget);
      expect(_isChecked(t, _privacyLabel), isTrue);
    });

    spec('LGL-S24', '2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が AuthFailure で失敗した場合、ホーム画面の上に同意ダイアログが表示され「通信エラー」ダイアログは表示されない',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.acceptResult = const Left(_auth);
      });

      await _signUpWithValid(t);

      expect(env.legal.acceptCalls.length, 1);
      expect(env.path, '/home');
      expect(_dialogTitle, findsOneWidget);
      expect(_networkTitle, findsNothing);
    });

    spec('LGL-S25', '2つチェックして「アカウント作成」をタップし、作成が NetworkFailure で失敗した場合、「通信エラーが発生しました」が表示され新規登録画面のまま入力とチェックが残り送信は0回になる',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.auth.signUpFailure = _network;
      });

      await _signUpWithValid(t);

      expect(find.text('通信エラーが発生しました'), findsOneWidget);
      expect(_signUpPage, findsOneWidget);
      expect(_emailText(t), 'a@example.com');
      expect(_isChecked(t, _termsLabel), isTrue);
      expect(_isChecked(t, _privacyLabel), isTrue);
      expect(env.legal.acceptCalls, isEmpty);
    });

    spec('LGL-S26', '2つチェックして「アカウント作成」をタップし、作成が UnknownFailure（メッセージ x）で失敗した場合、「エラーが発生しました: x」が表示され新規登録画面のままチェックが残り送信は0回になる',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.auth.signUpFailure = _unknown;
      });

      await _signUpWithValid(t);

      expect(find.text('エラーが発生しました: x'), findsOneWidget);
      expect(_signUpPage, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isTrue);
      expect(_isChecked(t, _privacyLabel), isTrue);
      expect(env.legal.acceptCalls, isEmpty);
    });

    spec('LGL-S27', '`app_config/legal` が無い状態で「プライバシーポリシーを読む」をタップした場合、既定値のプライバシーポリシーの URL の読み込みが指示される',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.configFailure = _notFound;
      });

      await _tap(t, _privacyLink);

      expect(env.web.loadCount(_defaultPrivacyUrl), 1);
    });

    spec('LGL-S28', '規約の情報の読み取りが NetworkFailure で失敗する状態で「利用規約を読む」をタップした場合、既定値の利用規約の URL の読み込みが指示される',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.configFailure = _network;
      });

      await _tap(t, _termsLink);

      expect(env.web.loadCount(_defaultTermsUrl), 1);
    });

    spec('LGL-S29', '「利用規約を読む」を素早く2回タップした場合、閲覧画面は1つだけ開き戻るボタン1回で新規登録画面が表示される',
        (t) async {
      await _openSignUp(t);

      await t.tap(_termsLink);
      await t.tap(_termsLink, warnIfMissed: false);
      await _settle(t);
      expect(_document, findsOneWidget);
      await _tapDocBack(t);

      expect(_document, findsNothing);
      expect(_signUpPage, findsOneWidget);
    });

    spec('LGL-S30', '規約の情報の読み取りの応答を待っている間に「利用規約を読む」をタップした場合、閲覧画面は開かない',
        (t) async {
      final env = await _openSignUp(t, configure: (e) {
        e.legal.configGate = Completer<void>();
      });

      await t.tap(_termsLink, warnIfMissed: false);
      await _settle(t);

      expect(_document, findsNothing);
      expect(_signUpPage, findsOneWidget);
      env.legal.configGate!.complete();
      await _settle(t);
    });

    spec('LGL-S31', '「プライバシーポリシーに同意する」をチェックして閲覧画面を開き戻るボタンで戻った場合、新規登録画面に戻りチェックはそのまま残る',
        (t) async {
      await _openSignUp(t);

      await _check(t, _privacyLabel);
      await _tap(t, _privacyLink);
      await _tapDocBack(t);

      expect(_document, findsNothing);
      expect(_signUpPage, findsOneWidget);
      expect(_isChecked(t, _privacyLabel), isTrue);
    });

    spec('LGL-S32', '「利用規約に同意する」をチェックして閲覧画面を開き戻る操作をした場合、新規登録画面に戻りチェックはそのまま残る',
        (t) async {
      await _openSignUp(t);

      await _check(t, _termsLabel);
      await _tap(t, _termsLink);
      expect(_document, findsOneWidget, reason: '準備: 閲覧画面');
      await t.binding.handlePopRoute();
      await _settle(t);

      expect(_document, findsNothing);
      expect(_signUpPage, findsOneWidget);
      expect(_isChecked(t, _termsLabel), isTrue);
    });

    spec('LGL-S33', '正しい入力をして2つチェックした後に「プライバシーポリシーに同意する」のチェックを外した場合、「アカウント作成」が無効になる',
        (t) async {
      await _openSignUp(t);

      await _fillValid(t);
      await _checkBoth(t);
      expect(_submitEnabled(t), isTrue, reason: '準備');
      await _check(t, _privacyLabel);

      expect(_isChecked(t, _privacyLabel), isFalse);
      expect(_submitEnabled(t), isFalse);
    });

    spec('LGL-S34', '正しい入力をして「利用規約に同意する」だけをチェックし、無効の「アカウント作成」をタップした場合、作成と送信は0回で新規登録画面のままになる',
        (t) async {
      final env = await _openSignUp(t);

      await _fillValid(t);
      await _check(t, _termsLabel);
      await t.tap(_submit, warnIfMissed: false);
      await _settle(t);

      expect(env.auth.signUpCount, 0);
      expect(env.legal.acceptCalls, isEmpty);
      expect(_signUpPage, findsOneWidget);
    });

    spec('LGL-S35', '正しい入力をして「プライバシーポリシーに同意する」だけをチェックし、無効の「アカウント作成」をタップした場合、作成と送信は0回になる',
        (t) async {
      final env = await _openSignUp(t);

      await _fillValid(t);
      await _check(t, _privacyLabel);
      await t.tap(_submit, warnIfMissed: false);
      await _settle(t);

      expect(env.auth.signUpCount, 0);
      expect(env.legal.acceptCalls, isEmpty);
      expect(_signUpPage, findsOneWidget);
    });

    spec('LGL-S36', '幅320・高さ480・文字の拡大率2.0の端末で新規登録画面を開いた場合、はみ出しが起きない',
        (t) async {
      await _openSignUp(t);

      t.view.physicalSize = const Size(320, 480);
      t.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await _settle(t);

      expect(_signUpPage, findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
