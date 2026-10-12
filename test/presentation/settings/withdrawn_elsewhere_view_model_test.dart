import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_stock/core/di/auth_providers.dart';
import 'package:word_stock/core/di/repository_providers.dart';
import 'package:word_stock/core/di/sync_providers.dart';
import 'package:word_stock/core/error/failure.dart';
import 'package:word_stock/domain/entities/account_deletion_request.dart';
import 'package:word_stock/domain/entities/app_user.dart';
import 'package:word_stock/domain/repositories/account_deletion_repository.dart';
import 'package:word_stock/domain/repositories/auth_repository.dart';
import 'package:word_stock/domain/repositories/sync_repository.dart';
import 'package:word_stock/presentation/settings/account_deletion_state.dart';
import 'package:word_stock/presentation/settings/account_deletion_view_model.dart';
import 'package:word_stock/presentation/settings/withdrawn_elsewhere_state.dart';
import 'package:word_stock/presentation/settings/withdrawn_elsewhere_view_model.dart';

/// 仕様書（docs/detailed_design/presentation/settings/settings_page.md）4.2 の
/// WithdrawnElsewhereViewModel のテスト。期待値は仕様書から作っている。
const _userA = AppUser(id: 'A', email: 'a@example.com');
const _userB = AppUser(id: 'B', email: 'b@example.com');

Failure get _network => const Failure.network();
Failure get _unknown => const Failure.unknown('x');

AccountDeletionRequest _record(AccountDeletionStatus status) =>
    AccountDeletionRequest(
      userId: 'A',
      status: status,
      updatedAt: DateTime(2026, 10, 12),
    );

typedef _W = WithdrawnElsewherePhase;

/// ログイン中のユーザーを切り替えられるようにするための Provider。
final _userState = StateProvider<AppUser?>((ref) => null);

/// この端末の退会処理が完了直後（completed）の状態を差し込むための ViewModel。
class _CompletedDeletionViewModel extends AccountDeletionViewModel {
  @override
  AccountDeletionState build() =>
      const AccountDeletionState(phase: AccountDeletionPhase.completed);
}

/// 3つの Fake が呼び出しを同じ [log] に積むことで、呼び出し順を検証できるようにする。
class _FakeAccountDeletionRepository implements AccountDeletionRepository {
  _FakeAccountDeletionRepository(this.log);

  final List<String> log;

  AccountDeletionRequest? record;
  Failure? findPendingFailure;
  Either<Failure, List<String>> localIds = const Right([]);

  /// uid ごとの退会済みの記録（既定は退会済みでない）。
  final withdrawn = <String, Either<Failure, bool>>{};

  /// uid ごとの応答の順番待ち（先頭から1回ずつ使い、尽きたら [withdrawn]）。
  final withdrawnQueue = <String, List<Either<Failure, bool>>>{};
  final withdrawnGate = <String, Completer<void>>{};

  /// deleteLocalDataOfUsers の失敗の順番待ち（null は成功。尽きたら成功）。
  final deleteQueue = <Failure?>[];
  Completer<void>? deleteGate;
  final deleteCalls = <List<String>>[];
  String? forced;
  final controllers = <String, StreamController<Either<Failure, bool>>>{};

  @override
  Future<Either<Failure, Option<AccountDeletionRequest>>> findPending() async {
    final f = findPendingFailure;
    if (f != null) return Left(f);
    return Right(optionOf(record));
  }

  @override
  Future<Either<Failure, List<String>>> findLocalUserIds() async => localIds;

  @override
  Future<Either<Failure, bool>> isWithdrawnOnServer(String userId) async {
    log.add('isWithdrawnOnServer($userId)');
    final gate = withdrawnGate[userId];
    if (gate != null) await gate.future;
    final queue = withdrawnQueue[userId];
    if (queue != null && queue.isNotEmpty) return queue.removeAt(0);
    return withdrawn[userId] ?? const Right(false);
  }

  @override
  Stream<Either<Failure, bool>> watchWithdrawn(String userId) {
    log.add('watchWithdrawn($userId)');
    final controller = StreamController<Either<Failure, bool>>();
    controllers[userId] = controller;
    return controller.stream;
  }

  @override
  Future<Either<Failure, Unit>> deleteLocalDataOfUsers(
      List<String> userIds) async {
    log.add('deleteLocalDataOfUsers(${userIds.join(',')})');
    deleteCalls.add(userIds);
    final gate = deleteGate;
    if (gate != null) await gate.future;
    final f = deleteQueue.isNotEmpty ? deleteQueue.removeAt(0) : null;
    return f != null ? Left(f) : const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> markForcedSignOut(String userId) async {
    log.add('markForcedSignOut($userId)');
    forced = userId;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Option<String>>> findForcedSignOut() async =>
      Right(optionOf(forced));

  @override
  Future<Either<Failure, Unit>> clearForcedSignOut(String userId) async {
    log.add('clearForcedSignOut($userId)');
    forced = null;
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.log);

  final List<String> log;

  /// signOut の失敗の順番待ち（null は成功）。尽きたら [signOutFailure]。
  final signOutQueue = <Failure?>[];
  Failure? signOutFailure;
  Completer<void>? signOutGate;

  @override
  Future<Either<Failure, Unit>> signOut() async {
    log.add('signOut');
    final gate = signOutGate;
    if (gate != null) await gate.future;
    final f = signOutQueue.isNotEmpty ? signOutQueue.removeAt(0) : signOutFailure;
    return f != null ? Left(f) : const Right(unit);
  }

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeSyncRepository implements SyncRepository {
  _FakeSyncRepository(this.log);

  final List<String> log;

  @override
  Future<void> waitUntilIdle() async => log.add('waitUntilIdle');

  @override
  Future<void> syncRemoteToLocalOnLogin() async {}

  @override
  Future<int> pushBeforeSignOut() async {
    log.add('pushBeforeSignOut');
    return 0;
  }
}

class _Env {
  _Env({AppUser? user = _userA, bool deletionCompleted = false}) {
    repo = _FakeAccountDeletionRepository(log);
    auth = _FakeAuthRepository(log);
    sync = _FakeSyncRepository(log);
    container = ProviderContainer(
      overrides: [
        accountDeletionRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(auth),
        syncRepositoryProvider.overrideWithValue(sync),
        _userState.overrideWith((ref) => user),
        currentUserProvider.overrideWith((ref) => ref.watch(_userState)),
        if (deletionCompleted)
          accountDeletionViewModelProvider
              .overrideWith(_CompletedDeletionViewModel.new),
      ],
    );
    addTearDown(container.dispose);
    vm = container.read(withdrawnElsewhereViewModelProvider.notifier);
  }

  final log = <String>[];
  late final _FakeAccountDeletionRepository repo;
  late final _FakeAuthRepository auth;
  late final _FakeSyncRepository sync;
  late final ProviderContainer container;
  late final WithdrawnElsewhereViewModel vm;

  WithdrawnElsewhereState get state =>
      container.read(withdrawnElsewhereViewModelProvider);

  int count(String entry) => log.where((e) => e == entry).length;
  int countPrefix(String prefix) =>
      log.where((e) => e.startsWith(prefix)).length;

  void setUser(AppUser? user) =>
      container.read(_userState.notifier).state = user;

  /// 端末内に [ids] のデータがあり、[withdrawnIds] に退会済みの記録がある状態にする。
  void setup({List<String> ids = const [], List<String> withdrawnIds = const []}) {
    repo.localIds = Right(ids);
    for (final id in withdrawnIds) {
      repo.withdrawn[id] = const Right(true);
    }
  }

  /// ログイン中の uid A が退会済みで、check の結果 notifying（userIds は [A]）にする。
  Future<void> toNotifying() async {
    setup(ids: ['A'], withdrawnIds: ['A']);
    await vm.check();
    expect(state.phase, _W.notifying);
  }

  Future<void> toConfirming() async {
    await toNotifying();
    await vm.confirmSignOut();
    expect(state.phase, _W.confirming);
  }

  /// confirming から削除に失敗させて failed にする。
  Future<void> toFailed() async {
    await toConfirming();
    repo.deleteQueue.add(_unknown);
    await vm.confirmDelete();
    expect(state.phase, _W.failed);
  }
}

/// 非同期処理を1周進める。
Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  group('check', () {
    test('ログイン中の uid A が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になり、signOut・削除は0回 [ACD-V39 #6706b7]', () async {
      final env = _Env()..setup(ids: ['A'], withdrawnIds: ['A']);
      await env.vm.check();
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
      expect(env.count('signOut'), 0);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 0);
    });

    test('ログインしていない状態で端末内の uid A が退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-V40 #6a25bc]', () async {
      final env = _Env(user: null)..setup(ids: ['A'], withdrawnIds: ['A']);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
      expect(env.count('deleteLocalDataOfUsers(A)'), 1);
      expect(env.count('signOut'), 0);
    });

    test('ログイン中の uid が B で端末内の uid A だけが退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers([A]) が1回、isWithdrawnOnServer が A・B 各1回呼ばれる [ACD-V41 #67b288]', () async {
      final env = _Env(user: _userB)
        ..setup(ids: ['A', 'B'], withdrawnIds: ['A']);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
      expect(env.count('deleteLocalDataOfUsers(A)'), 1);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 1);
      expect(env.count('isWithdrawnOnServer(A)'), 1);
      expect(env.count('isWithdrawnOnServer(B)'), 1);
      expect(env.count('signOut'), 0);
    });

    test('ログイン中の uid A に退会済みの記録が無い状態で check を呼んだ場合、phase が idle になり signOut は0回 [ACD-V42 #834352]', () async {
      final env = _Env()..setup(ids: ['A']);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
      expect(env.count('signOut'), 0);
    });

    test('isWithdrawnOnServer が NetworkFailure を返す状態で check を呼んだ場合、phase が idle になり signOut は0回 [ACD-V43 #271d8a]', () async {
      final env = _Env()..setup(ids: ['A']);
      env.repo.withdrawn['A'] = Left(_network);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
      expect(env.count('signOut'), 0);
    });

    test('isWithdrawnOnServer が UnknownFailure を返す状態で check を呼んだ場合、phase が idle になり signOut は0回 [ACD-V44 #c80fd5]', () async {
      final env = _Env()..setup(ids: ['A']);
      env.repo.withdrawn['A'] = Left(_unknown);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
      expect(env.count('signOut'), 0);
    });

    test('ログインしていない状態で findLocalUserIds が UnknownFailure を返す場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V45 #51bd65]', () async {
      final env = _Env(user: null);
      env.repo.localIds = Left(_unknown);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.countPrefix('isWithdrawnOnServer'), 0);
    });

    test('ログインしていない状態で uid A の確認が UnknownFailure、uid C が退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers([C]) が1回呼ばれる [ACD-V46 #9991b7]', () async {
      final env = _Env(user: null)..setup(ids: ['A', 'C'], withdrawnIds: ['C']);
      env.repo.withdrawn['A'] = Left(_unknown);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.count('deleteLocalDataOfUsers(C)'), 1);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 1);
    });

    test('端末内にデータが1件も無く uid A が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になり signOut は0回 [ACD-V47 #170dbd]', () async {
      final env = _Env()..setup(withdrawnIds: ['A']);
      await env.vm.check();
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
      expect(env.count('signOut'), 0);
    });

    test('ログインしていない状態で uid A の退会処理の記録が requested のとき check を呼んだ場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V48 #334a64]', () async {
      final env = _Env(user: null)..setup(ids: ['A'], withdrawnIds: ['A']);
      env.repo.record = _record(AccountDeletionStatus.requested);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.countPrefix('isWithdrawnOnServer'), 0);
    });

    test('ログインしていない状態で uid A の退会処理の記録が requested、uid C が退会済みのとき check を呼んだ場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V49 #65a9ae]', () async {
      final env = _Env(user: null)
        ..setup(ids: ['A', 'C'], withdrawnIds: ['C']);
      env.repo.record = _record(AccountDeletionStatus.requested);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.countPrefix('isWithdrawnOnServer'), 0);
    });

    test('退会処理の記録の読み取りが UnknownFailure で失敗する状態で check を呼んだ場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V50 #3bf74e]', () async {
      final env = _Env()..setup(ids: ['A'], withdrawnIds: ['A']);
      env.repo.findPendingFailure = _unknown;
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.countPrefix('isWithdrawnOnServer'), 0);
    });

    test('isWithdrawnOnServer の応答を待っている場合、phase が checking になる [ACD-V51 #708809]', () async {
      final env = _Env()..setup(ids: ['A'], withdrawnIds: ['A']);
      final gate = env.repo.withdrawnGate['A'] = Completer<void>();
      final future = env.vm.check();
      await _pump();
      expect(env.state.phase, _W.checking);
      gate.complete();
      await future;
    });

    test('phase が checking の間にもう一度 check を呼んだ場合、isWithdrawnOnServer(A) は合計1回だけ呼ばれる [ACD-V61 #131520]', () async {
      final env = _Env()..setup(ids: ['A'], withdrawnIds: ['A']);
      final gate = env.repo.withdrawnGate['A'] = Completer<void>();
      final first = env.vm.check();
      await _pump();
      await env.vm.check();
      gate.complete();
      await first;
      expect(env.count('isWithdrawnOnServer(A)'), 1);
    });

    test('isWithdrawnOnServer(A) が1回目は UnknownFailure、2回目は退会済みの状態で check を2回呼んだ場合、1回目の後は idle、2回目の後は notifying、userIds が [A] になる [ACD-V65 #6869c1]', () async {
      final env = _Env()..setup(ids: ['A']);
      env.repo.withdrawnQueue['A'] = [Left(_unknown), const Right(true)];
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      await env.vm.check();
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
    });

    test('uid A の退会処理の記録が requested で退会済みの状態で check を呼んだ場合、phase が idle になり signOut・削除は0回 [ACD-V66 #2576b4]', () async {
      final env = _Env()..setup(ids: ['A'], withdrawnIds: ['A']);
      env.repo.record = _record(AccountDeletionStatus.requested);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.count('signOut'), 0);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 0);
    });

    test('uid A の退会処理の記録が serverDone で退会済みの状態で check を呼んだ場合、phase が idle になり signOut・削除は0回 [ACD-V67 #8be083]', () async {
      final env = _Env()..setup(ids: ['A'], withdrawnIds: ['A']);
      env.repo.record = _record(AccountDeletionStatus.serverDone);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.count('signOut'), 0);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 0);
    });

    test('ログインしていない状態で uid A と uid C が退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers が A と C を含めて1回呼ばれる [ACD-V68 #34bcf5]', () async {
      final env = _Env(user: null)
        ..setup(ids: ['A', 'C'], withdrawnIds: ['A', 'C']);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.repo.deleteCalls, hasLength(1));
      expect(env.repo.deleteCalls.single, unorderedEquals(['A', 'C']));
    });

    test('ログイン中の uid A と端末内の uid C が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になり deleteLocalDataOfUsers([C]) が1回呼ばれる [ACD-V69 #80a028]', () async {
      final env = _Env()..setup(ids: ['A', 'C'], withdrawnIds: ['A', 'C']);
      await env.vm.check();
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
      expect(env.count('deleteLocalDataOfUsers(C)'), 1);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 1);
      expect(env.count('signOut'), 0);
      expect(env.count('isWithdrawnOnServer(A)'), 1);
    });

    test('isWithdrawnOnServer の応答を待つ間に退会処理の記録が requested になり退会済みが返った場合、phase が idle のままで notifying にならない [ACD-V71 #9737f1]', () async {
      final env = _Env()..setup(ids: ['A'], withdrawnIds: ['A']);
      final gate = env.repo.withdrawnGate['A'] = Completer<void>();
      final future = env.vm.check();
      await _pump();
      env.repo.record = _record(AccountDeletionStatus.requested);
      gate.complete();
      await future;
      expect(env.state.phase, _W.idle);
    });

    test('ログイン中の uid A で findLocalUserIds が UnknownFailure、uid A が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になる [ACD-V76 #e714da]', () async {
      final env = _Env()..setup(withdrawnIds: ['A']);
      env.repo.localIds = Left(_unknown);
      await env.vm.check();
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
    });

    test('ログインしていない状態で uid C が退会済みで、1回目の check のときだけ uid A の記録が requested の場合、1回目の後は削除0回、2回目の後に deleteLocalDataOfUsers([C]) が1回呼ばれ、どちらも phase は idle [ACD-V77 #afc578]', () async {
      final env = _Env(user: null)
        ..setup(ids: ['A', 'C'], withdrawnIds: ['C']);
      env.repo.record = _record(AccountDeletionStatus.requested);
      await env.vm.check();
      expect(env.countPrefix('deleteLocalDataOfUsers'), 0);
      expect(env.state.phase, _W.idle);
      env.repo.record = null;
      await env.vm.check();
      expect(env.count('deleteLocalDataOfUsers(C)'), 1);
      expect(env.state.phase, _W.idle);
    });

    test('Firebase 上のログイン中の uid A に強制ログアウトの記録があり退会済みで signOut が失敗する状態で check を呼んだ場合、phase が idle、deleteLocalDataOfUsers([A]) が1回、signOut が1回、clearForcedSignOut は0回 [ACD-V87 #427f6e]', () async {
      final env = _Env()..setup(ids: ['A'], withdrawnIds: ['A']);
      env.repo.forced = 'A';
      env.auth.signOutFailure = _unknown;
      await env.vm.initialize();
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
      expect(env.count('deleteLocalDataOfUsers(A)'), 1);
      expect(env.count('signOut'), 1);
      expect(env.countPrefix('clearForcedSignOut'), 0);
    });

    test('強制ログアウトの記録の uid A が退会済みのとき signOut が成功する状態で check を呼んだ場合、phase が idle、deleteLocalDataOfUsers([A]) が1回、signOut が1回、clearForcedSignOut(A) が1回呼ばれる [ACD-V88 #d6392f]', () async {
      final env = _Env()..setup(ids: ['A'], withdrawnIds: ['A']);
      env.repo.forced = 'A';
      await env.vm.initialize();
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.count('deleteLocalDataOfUsers(A)'), 1);
      expect(env.count('signOut'), 1);
      expect(env.count('clearForcedSignOut(A)'), 1);
    });

    test('強制ログアウトの記録の uid A が退会済みで端末内にデータが無く signOut が失敗する状態で check を呼んだ場合、phase が idle、userIds が空で signOut は1回 [ACD-V98 #43cb3e]', () async {
      final env = _Env()..setup(withdrawnIds: ['A']);
      env.repo.forced = 'A';
      env.auth.signOutFailure = _unknown;
      await env.vm.initialize();
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
      expect(env.count('signOut'), 1);
    });

    test('強制ログアウトの記録の uid A で isWithdrawnOnServer が NetworkFailure を返す状態で check を呼んだ場合、signOut は1回で phase は idle [ACD-V101 #a676cd]', () async {
      final env = _Env()..setup(ids: ['A']);
      env.repo.forced = 'A';
      env.repo.withdrawn['A'] = Left(_network);
      await env.vm.initialize();
      await env.vm.check();
      expect(env.count('signOut'), 1);
      expect(env.state.phase, _W.idle);
    });

    test('監視が退会済みを通知した後に isWithdrawnOnServer が退会済みでないと返った場合、phase が notifying、userIds が [A] になる [ACD-V102 #64ccf2]', () async {
      final env = _Env()..setup(ids: ['A']);
      await env.vm.initialize();
      final gate = env.repo.withdrawnGate['A'] = Completer<void>();
      final future = env.vm.check();
      await _pump();
      env.repo.controllers['A']!.add(const Right(true));
      await _pump();
      gate.complete();
      await future;
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
    });

    test('監視が退会済みを通知した後に isWithdrawnOnServer が UnknownFailure を返した場合、phase が notifying、userIds が [A] になる [ACD-V106 #75c8de]', () async {
      final env = _Env()..setup(ids: ['A']);
      env.repo.withdrawn['A'] = Left(_unknown);
      await env.vm.initialize();
      final gate = env.repo.withdrawnGate['A'] = Completer<void>();
      final future = env.vm.check();
      await _pump();
      env.repo.controllers['A']!.add(const Right(true));
      await _pump();
      gate.complete();
      await future;
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
    });

    test('ログインしていない状態で deleteLocalDataOfUsers が UnknownFailure で失敗する場合、phase が idle のままで failed にならず userIds は空 [ACD-V107 #0d6de0]', () async {
      final env = _Env(user: null)..setup(ids: ['A'], withdrawnIds: ['A']);
      env.repo.deleteQueue.add(_unknown);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
    });

    test('ログインしていない状態で1回目の deleteLocalDataOfUsers が失敗し2回目が成功する場合、check を2回呼ぶと deleteLocalDataOfUsers([A]) が合計2回呼ばれ、どちらの後も phase は idle [ACD-V108 #8f7e6e]', () async {
      final env = _Env(user: null)..setup(ids: ['A'], withdrawnIds: ['A']);
      env.repo.deleteQueue.add(_unknown);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.count('deleteLocalDataOfUsers(A)'), 2);
    });

    test('ログイン中の uid A と uid C が退会済みで deleteLocalDataOfUsers([C]) が失敗する状態で check を呼んだ場合、phase が notifying、userIds が [A] になる [ACD-V109 #cbce0e]', () async {
      final env = _Env()..setup(ids: ['A', 'C'], withdrawnIds: ['A', 'C']);
      env.repo.deleteQueue.add(_unknown);
      await env.vm.check();
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
    });

    test('ログイン中の uid が B で uid A だけが退会済みかつ deleteLocalDataOfUsers([A]) が失敗する状態で check を呼んだ場合、phase が idle、userIds が空で signOut は0回 [ACD-V110 #9147c5]', () async {
      final env = _Env(user: _userB)
        ..setup(ids: ['A', 'B'], withdrawnIds: ['A']);
      env.repo.deleteQueue.add(_unknown);
      await env.vm.check();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
      expect(env.count('signOut'), 0);
    });

    test('ログインしていない状態で uid A が退会済みのとき check を呼んだ場合、waitUntilIdle の完了後に deleteLocalDataOfUsers([A]) が呼ばれる [ACD-V111 #3d4be5]', () async {
      final env = _Env(user: null)..setup(ids: ['A'], withdrawnIds: ['A']);
      await env.vm.check();
      final wait = env.log.indexOf('waitUntilIdle');
      final delete = env.log.indexOf('deleteLocalDataOfUsers(A)');
      expect(env.count('waitUntilIdle'), 1);
      expect(wait, isNonNegative);
      expect(delete, greaterThan(wait));
    });

    test('phase が confirming、userIds が [A] の状態で check を呼んだ場合、phase と userIds は変わらず isWithdrawnOnServer は0回 [ACD-V60 #fce9cf]', () async {
      final env = _Env();
      await env.toConfirming();
      env.log.clear();
      await env.vm.check();
      expect(env.state.phase, _W.confirming);
      expect(env.state.userIds, ['A']);
      expect(env.countPrefix('isWithdrawnOnServer'), 0);
    });

    test('phase が deleting の間に check を呼んだ場合、phase は deleting のままで isWithdrawnOnServer は0回 [ACD-V70 #a54b0b]', () async {
      final env = _Env();
      await env.toConfirming();
      env.log.clear();
      final gate = env.repo.deleteGate = Completer<void>();
      final future = env.vm.confirmDelete();
      await _pump();
      await env.vm.check();
      expect(env.state.phase, _W.deleting);
      expect(env.countPrefix('isWithdrawnOnServer'), 0);
      gate.complete();
      await future;
    });

    test('phase が notifying、userIds が [A] の状態で check を呼んだ場合、phase と userIds は変わらず isWithdrawnOnServer は0回 [ACD-V73 #8f1e43]', () async {
      final env = _Env();
      await env.toNotifying();
      env.log.clear();
      await env.vm.check();
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
      expect(env.countPrefix('isWithdrawnOnServer'), 0);
    });

    test('phase が failed、userIds が [A] の状態で check を呼んだ場合、phase と userIds は変わらず isWithdrawnOnServer は0回 [ACD-V75 #a9b821]', () async {
      final env = _Env();
      await env.toFailed();
      env.log.clear();
      await env.vm.check();
      expect(env.state.phase, _W.failed);
      expect(env.state.userIds, ['A']);
      expect(env.countPrefix('isWithdrawnOnServer'), 0);
    });
  });

  group('confirmSignOut', () {
    test('phase が notifying の状態で confirmSignOut を呼び1回目の signOut が失敗し2回目が成功した場合、phase が confirming、signOut は2回、markForcedSignOut・pushBeforeSignOut は0回 [ACD-V64 #331884]', () async {
      final env = _Env();
      await env.toNotifying();
      env.auth.signOutQueue.addAll([_unknown, null]);
      await env.vm.confirmSignOut();
      expect(env.state.phase, _W.confirming);
      expect(env.state.userIds, ['A']);
      expect(env.count('signOut'), 2);
      expect(env.countPrefix('markForcedSignOut'), 0);
      expect(env.count('pushBeforeSignOut'), 0);
    });

    test('phase が notifying の状態で confirmSignOut を呼び signOut が成功した場合、phase が confirming、signOut は1回、pushBeforeSignOut・削除は0回 [ACD-V72 #304283]', () async {
      final env = _Env();
      await env.toNotifying();
      await env.vm.confirmSignOut();
      expect(env.state.phase, _W.confirming);
      expect(env.state.userIds, ['A']);
      expect(env.count('signOut'), 1);
      expect(env.count('pushBeforeSignOut'), 0);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 0);
    });

    test('phase が notifying の状態で signOut の完了を待つ間にもう一度 confirmSignOut を呼んだ場合、signOut は合計1回で phase は confirming [ACD-V79 #f2b866]', () async {
      final env = _Env();
      await env.toNotifying();
      final gate = env.auth.signOutGate = Completer<void>();
      final first = env.vm.confirmSignOut();
      await _pump();
      final second = env.vm.confirmSignOut();
      gate.complete();
      await first;
      await second;
      expect(env.count('signOut'), 1);
      expect(env.state.phase, _W.confirming);
    });

    test('phase が idle の状態で confirmSignOut を呼んだ場合、phase は idle のままで signOut は0回 [ACD-V80 #e7b24a]', () async {
      final env = _Env();
      await env.vm.confirmSignOut();
      expect(env.state.phase, _W.idle);
      expect(env.count('signOut'), 0);
    });

    test('phase が confirming の状態で confirmSignOut を呼んだ場合、phase は confirming のままで signOut は0回 [ACD-V85 #d532ee]', () async {
      final env = _Env();
      await env.toConfirming();
      env.log.clear();
      await env.vm.confirmSignOut();
      expect(env.state.phase, _W.confirming);
      expect(env.count('signOut'), 0);
    });

    test('phase が notifying の状態で confirmSignOut を呼び signOut が2回とも失敗した場合、phase が confirming、signOut は2回、markForcedSignOut(A) は1回、pushBeforeSignOut は0回 [ACD-V86 #679b20]', () async {
      final env = _Env();
      await env.toNotifying();
      env.auth.signOutFailure = _unknown;
      await env.vm.confirmSignOut();
      expect(env.state.phase, _W.confirming);
      expect(env.state.userIds, ['A']);
      expect(env.count('signOut'), 2);
      expect(env.count('markForcedSignOut(A)'), 1);
      expect(env.count('pushBeforeSignOut'), 0);
    });

    test('ログイン中の uid A を監視している状態で confirmSignOut の signOut が2回とも失敗した場合、uid A の監視が止まる [ACD-V100 #27674b]', () async {
      final env = _Env()..setup(ids: ['A'], withdrawnIds: ['A']);
      await env.vm.initialize();
      expect(env.repo.controllers['A']!.hasListener, isTrue);
      await env.vm.check();
      env.auth.signOutFailure = _unknown;
      await env.vm.confirmSignOut();
      expect(env.repo.controllers['A']!.hasListener, isFalse);
    });
  });

  group('confirmDelete', () {
    test('phase が confirming の状態で confirmDelete を呼び削除が成功した場合、phase が idle、userIds が空で、waitUntilIdle の完了後に deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-V52 #ca3436]', () async {
      final env = _Env();
      await env.toConfirming();
      env.log.clear();
      await env.vm.confirmDelete();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
      expect(env.log, ['waitUntilIdle', 'deleteLocalDataOfUsers(A)']);
    });

    test('phase が confirming の状態で confirmDelete を呼び削除の完了を待っている場合、phase が deleting になる [ACD-V53 #b2845b]', () async {
      final env = _Env();
      await env.toConfirming();
      final gate = env.repo.deleteGate = Completer<void>();
      final future = env.vm.confirmDelete();
      await _pump();
      expect(env.state.phase, _W.deleting);
      gate.complete();
      await future;
    });

    test('phase が confirming の状態で confirmDelete を呼び削除が UnknownFailure で失敗した場合、phase が failed、userIds が [A] になる [ACD-V54 #557fab]', () async {
      final env = _Env();
      await env.toConfirming();
      env.repo.deleteQueue.add(_unknown);
      await env.vm.confirmDelete();
      expect(env.state.phase, _W.failed);
      expect(env.state.userIds, ['A']);
    });

    test('phase が deleting の間にもう一度 confirmDelete を呼んだ場合、deleteLocalDataOfUsers は合計1回だけ呼ばれる [ACD-V59 #f77a8c]', () async {
      final env = _Env();
      await env.toConfirming();
      final gate = env.repo.deleteGate = Completer<void>();
      final first = env.vm.confirmDelete();
      await _pump();
      await env.vm.confirmDelete();
      gate.complete();
      await first;
      expect(env.countPrefix('deleteLocalDataOfUsers'), 1);
    });

    test('phase が idle の状態で confirmDelete を呼んだ場合、phase は idle のままで deleteLocalDataOfUsers は0回 [ACD-V63 #a0ed7c]', () async {
      final env = _Env();
      await env.vm.confirmDelete();
      expect(env.state.phase, _W.idle);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 0);
    });

    test('phase が notifying の状態で confirmDelete を呼んだ場合、phase は notifying のままで deleteLocalDataOfUsers は0回 [ACD-V74 #2809bb]', () async {
      final env = _Env();
      await env.toNotifying();
      await env.vm.confirmDelete();
      expect(env.state.phase, _W.notifying);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 0);
    });

    test('phase が failed の状態で confirmDelete を呼んだ場合、phase は failed のままで deleteLocalDataOfUsers は0回 [ACD-V82 #6adba2]', () async {
      final env = _Env();
      await env.toFailed();
      env.log.clear();
      await env.vm.confirmDelete();
      expect(env.state.phase, _W.failed);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 0);
    });
  });

  group('acknowledgeFailure', () {
    test('phase が failed、userIds が [A] の状態で acknowledgeFailure を呼んだ場合、phase が confirming、userIds が [A] になり deleteLocalDataOfUsers は呼ばれない [ACD-V55 #484aee]', () async {
      final env = _Env();
      await env.toFailed();
      env.log.clear();
      env.vm.acknowledgeFailure();
      expect(env.state.phase, _W.confirming);
      expect(env.state.userIds, ['A']);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 0);
    });

    test('acknowledgeFailure で confirming に戻った後に confirmDelete を呼び削除が成功した場合、phase が idle、userIds が空になる [ACD-V56 #f26dd6]', () async {
      final env = _Env();
      await env.toFailed();
      env.vm.acknowledgeFailure();
      await env.vm.confirmDelete();
      expect(env.state.phase, _W.idle);
      expect(env.state.userIds, isEmpty);
    });

    test('phase が confirming の状態で acknowledgeFailure を呼んだ場合、phase は confirming のままで deleteLocalDataOfUsers は0回 [ACD-V81 #8c6e2e]', () async {
      final env = _Env();
      await env.toConfirming();
      env.log.clear();
      env.vm.acknowledgeFailure();
      expect(env.state.phase, _W.confirming);
      expect(env.countPrefix('deleteLocalDataOfUsers'), 0);
    });

    test('acknowledgeFailure で confirming に戻った後に confirmDelete を呼び削除が再び失敗した場合、phase が failed、userIds が [A] になる [ACD-V84 #41aa7b]', () async {
      final env = _Env();
      await env.toFailed();
      env.vm.acknowledgeFailure();
      env.repo.deleteQueue.add(_unknown);
      await env.vm.confirmDelete();
      expect(env.state.phase, _W.failed);
      expect(env.state.userIds, ['A']);
    });
  });

  group('監視', () {
    test('ログイン中の uid A で phase が idle の状態で監視が退会済みを通知した場合、phase が notifying、userIds が [A] になり signOut は0回 [ACD-V89 #a17592]', () async {
      final env = _Env();
      await env.vm.initialize();
      env.repo.controllers['A']!.add(const Right(true));
      await _pump();
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
      expect(env.count('signOut'), 0);
    });

    test('ログイン中の uid A で phase が idle の状態で監視が退会済みでないと通知した場合、phase は idle のまま [ACD-V90 #52aa14]', () async {
      final env = _Env();
      await env.vm.initialize();
      env.repo.controllers['A']!.add(const Right(false));
      await _pump();
      expect(env.state.phase, _W.idle);
    });

    test('ログイン中の uid A で phase が idle の状態で監視が UnknownFailure を通知した場合、phase は idle のまま [ACD-V91 #0ae876]', () async {
      final env = _Env();
      await env.vm.initialize();
      env.repo.controllers['A']!.add(Left(_unknown));
      await _pump();
      expect(env.state.phase, _W.idle);
    });

    test('uid A の退会処理の記録が requested の状態で監視が退会済みを通知した場合、phase は idle のままで signOut は0回 [ACD-V92 #643da0]', () async {
      final env = _Env();
      env.repo.record = _record(AccountDeletionStatus.requested);
      await env.vm.initialize();
      env.repo.controllers['A']!.add(const Right(true));
      await _pump();
      expect(env.state.phase, _W.idle);
      expect(env.count('signOut'), 0);
    });

    test('ログイン中の uid A を監視した後にログアウトした場合、uid A の監視が止まり phase は idle のまま [ACD-V93 #eccb75]', () async {
      final env = _Env();
      await env.vm.initialize();
      final controller = env.repo.controllers['A']!;
      expect(controller.hasListener, isTrue);
      env.setUser(null);
      await _pump();
      expect(controller.hasListener, isFalse);
      expect(env.state.phase, _W.idle);
    });

    test('ログイン中の uid A を監視した後にログイン中の uid が B に変わった場合、watchWithdrawn(B) が1回呼ばれ uid A の監視が止まる [ACD-V94 #df25d2]', () async {
      final env = _Env();
      await env.vm.initialize();
      final controllerA = env.repo.controllers['A']!;
      env.setUser(_userB);
      await _pump();
      expect(env.count('watchWithdrawn(B)'), 1);
      expect(controllerA.hasListener, isFalse);
      expect(env.repo.controllers['B']!.hasListener, isTrue);
    });

    test('phase が notifying、userIds が [A] の状態で監視が退会済みを通知した場合、phase は notifying、userIds は [A] のまま [ACD-V96 #c3cecc]', () async {
      final env = _Env();
      await env.vm.initialize();
      await env.toNotifying();
      env.repo.controllers['A']!.add(const Right(true));
      await _pump();
      expect(env.state.phase, _W.notifying);
      expect(env.state.userIds, ['A']);
    });

    test('強制ログアウトの記録の uid A がある状態でログイン中の uid が B に変わった場合、clearForcedSignOut(A) と watchWithdrawn(B) が各1回呼ばれる [ACD-V99 #f3ea77]', () async {
      final env = _Env();
      env.repo.forced = 'A';
      await env.vm.initialize();
      env.setUser(_userB);
      await _pump();
      expect(env.count('clearForcedSignOut(A)'), 1);
      expect(env.count('watchWithdrawn(B)'), 1);
    });

    test('uid A の退会処理の記録が serverDone の状態で監視が退会済みを通知した場合、phase は idle のままで signOut は0回 [ACD-V104 #fca9b2]', () async {
      final env = _Env();
      env.repo.record = _record(AccountDeletionStatus.serverDone);
      await env.vm.initialize();
      env.repo.controllers['A']!.add(const Right(true));
      await _pump();
      expect(env.state.phase, _W.idle);
      expect(env.count('signOut'), 0);
    });

    test('この端末の退会処理が completed の状態で監視が退会済みを通知した場合、phase は idle のままで signOut は0回 [ACD-V105 #786d7c]', () async {
      final env = _Env(deletionCompleted: true);
      await env.vm.initialize();
      env.repo.controllers['A']!.add(const Right(true));
      await _pump();
      expect(env.state.phase, _W.idle);
      expect(env.count('signOut'), 0);
    });
  });
}
