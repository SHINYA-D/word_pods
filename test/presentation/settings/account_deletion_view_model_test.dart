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

/// 仕様書（docs/detailed_design/presentation/settings/settings_page.md）4章の
/// 「ログイン中のユーザーは、特に書かない限り記録と同じ uid A」に合わせたテスト用ユーザー。
const _userA = AppUser(id: 'A', email: 'a@example.com');
const _userB = AppUser(id: 'B', email: 'b@example.com');

Failure get _network => const Failure.network();
Failure get _auth => const Failure.auth();
Failure get _unknown => const Failure.unknown('x');

AccountDeletionRequest _record(AccountDeletionStatus status) =>
    AccountDeletionRequest(
      userId: 'A',
      status: status,
      updatedAt: DateTime(2026, 10, 3),
    );

/// 3つの Fake が呼び出しを同じ [log] に積むことで、呼び出し順を検証できるようにする。
class _FakeAccountDeletionRepository implements AccountDeletionRepository {
  _FakeAccountDeletionRepository(this.log);

  final List<String> log;

  /// 端末内の記録（None 相当は null）。
  AccountDeletionRequest? record;

  Failure? findPendingFailure;
  Failure? markRequestedFailure;
  Failure? markServerDoneFailure;
  Failure? clearRequestFailure;
  Failure? requestFailure;
  Failure? deleteLocalFailure;

  /// 設定すると、その Completer が完了するまで応答を返さない。
  Completer<void>? requestGate;
  Completer<void>? deleteLocalGate;

  @override
  Future<Either<Failure, Option<AccountDeletionRequest>>> findPending() async {
    final f = findPendingFailure;
    if (f != null) return Left(f);
    return Right(optionOf(record));
  }

  @override
  Future<Either<Failure, Unit>> markRequested(String userId) async {
    log.add('markRequested($userId)');
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
    log.add('markServerDone($userId)');
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
    log.add('clearRequest($userId)');
    final f = clearRequestFailure;
    if (f != null) return Left(f);
    record = null;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> requestServerDeletion() async {
    log.add('requestServerDeletion');
    final gate = requestGate;
    if (gate != null) await gate.future;
    final f = requestFailure;
    return f != null ? Left(f) : const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteLocalData(String userId) async {
    log.add('deleteLocalData($userId)');
    final gate = deleteLocalGate;
    if (gate != null) await gate.future;
    final f = deleteLocalFailure;
    if (f != null) return Left(f);
    record = null;
    return const Right(unit);
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.log);

  final List<String> log;
  Failure? signOutFailure;

  @override
  Future<Either<Failure, Unit>> signOut() async {
    log.add('signOut');
    final f = signOutFailure;
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
  Completer<void>? idleGate;

  @override
  Future<void> waitUntilIdle() async {
    log.add('waitUntilIdle');
    final gate = idleGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> syncRemoteToLocalOnLogin() async {}

  @override
  Future<int> pushBeforeSignOut() async => 0;
}

class _Env {
  _Env._(this.user, AccountDeletionRequest? initial) {
    repo = _FakeAccountDeletionRepository(log)..record = initial;
    auth = _FakeAuthRepository(log);
    sync = _FakeSyncRepository(log);
    container = ProviderContainer(
      overrides: [
        accountDeletionRepositoryProvider.overrideWithValue(repo),
        authRepositoryProvider.overrideWithValue(auth),
        syncRepositoryProvider.overrideWithValue(sync),
        currentUserProvider.overrideWithValue(user),
      ],
    );
    addTearDown(container.dispose);
    vm = container.read(accountDeletionViewModelProvider.notifier);
  }

  /// [initial] が記録の初期値。[user] がログイン中のユーザー（null はログインしていない）。
  factory _Env({
    AppUser? user = _userA,
    AccountDeletionRequest? initial,
  }) =>
      _Env._(user, initial);

  final AppUser? user;
  final log = <String>[];
  late final _FakeAccountDeletionRepository repo;
  late final _FakeAuthRepository auth;
  late final _FakeSyncRepository sync;
  late final ProviderContainer container;
  late final AccountDeletionViewModel vm;

  AccountDeletionState get state =>
      container.read(accountDeletionViewModelProvider);

  int count(String entry) => log.where((e) => e == entry).length;

  /// 起動時の確認まで済ませる。記録が無ければ idle、あれば pendingRetry になる。
  Future<void> boot() => vm.checkPending();
}

/// 非同期処理を1周進める。
Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  group('checkPending', () {
    test('ViewModelを作成した直後（checkPending の完了前）の場合、phase が checking になる [ACD-V38 #1fc7e1]', () {
      final env = _Env();
      expect(env.state.phase, AccountDeletionPhase.checking);
    });

    test('記録が無い状態で起動時の確認をした場合、phase が idle になる [ACD-V01 #ed5294]', () async {
      final env = _Env();
      await env.boot();
      expect(env.state.phase, AccountDeletionPhase.idle);
    });

    test(
        'uid A の記録が requested の状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V02 #37e832]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, false);
    });

    test(
        'uid A の記録が serverDone の状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V03 #c620c9]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.serverDone));
      await env.boot();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, false);
    });

    test(
        'ログイン中の uid が B、記録が uid A の requested の状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V28 #810398]',
        () async {
      final env = _Env(
        user: _userB,
        initial: _record(AccountDeletionStatus.requested),
      );
      await env.boot();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, false);
    });

    test(
        '記録の読み取りが UnknownFailure で失敗する状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V33 #286851]',
        () async {
      final env = _Env();
      env.repo.findPendingFailure = _unknown;
      await env.boot();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, false);
    });
  });

  group('withdraw', () {
    test(
        '記録が無い状態で withdraw を呼び関数の応答を待っている場合、phase が processing、記録が requested で、waitUntilIdle の完了後に requestServerDeletion が1回呼ばれる [ACD-V04 #5d474d]',
        () async {
      final env = _Env();
      await env.boot();
      env.sync.idleGate = Completer<void>();
      env.repo.requestGate = Completer<void>();

      final future = env.vm.withdraw();
      await _pump();

      expect(env.state.phase, AccountDeletionPhase.processing);
      expect(env.repo.record?.userId, 'A');
      expect(env.repo.record?.status, AccountDeletionStatus.requested);
      expect(env.count('waitUntilIdle'), 1);
      // 同期の完了前は関数を呼んでいない
      expect(env.count('requestServerDeletion'), 0);

      env.sync.idleGate!.complete();
      await _pump();
      expect(env.count('requestServerDeletion'), 1);
      expect(
        env.log.indexOf('waitUntilIdle') <
            env.log.indexOf('requestServerDeletion'),
        true,
      );

      env.repo.requestGate!.complete();
      await future;
    });

    test(
        '記録が無い状態で withdraw を呼び関数の呼び出しと端末内の削除がどちらも成功した場合、phase が completed になり、markRequested・requestServerDeletion・markServerDone・deleteLocalData・signOut がこの順に1回ずつ呼ばれる [ACD-V05 #7735f6]',
        () async {
      final env = _Env();
      await env.boot();
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.completed);
      expect(env.log.where((e) => e != 'waitUntilIdle').toList(), [
        'markRequested(A)',
        'requestServerDeletion',
        'markServerDone(A)',
        'deleteLocalData(A)',
        'signOut',
      ]);
    });

    test(
        '記録が無い状態で withdraw を呼び関数の呼び出しが NetworkFailure で失敗した場合、phase が notSent になり、clearRequest(A) が1回呼ばれ記録は無く、markServerDone・deleteLocalData・signOut は0回 [ACD-V06 #7cc1c8]',
        () async {
      final env = _Env();
      await env.boot();
      env.repo.requestFailure = _network;
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.notSent);
      expect(env.count('clearRequest(A)'), 1);
      expect(env.repo.record, isNull);
      expect(env.count('markServerDone(A)'), 0);
      expect(env.count('deleteLocalData(A)'), 0);
      expect(env.count('signOut'), 0);
    });

    test(
        '記録が無い状態で withdraw を呼び関数の呼び出しが UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false で、記録は requested のまま、clearRequest・deleteLocalData・signOut は0回 [ACD-V07 #ce393b]',
        () async {
      final env = _Env();
      await env.boot();
      env.repo.requestFailure = _unknown;
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, false);
      expect(env.repo.record?.status, AccountDeletionStatus.requested);
      expect(env.count('clearRequest(A)'), 0);
      expect(env.count('deleteLocalData(A)'), 0);
      expect(env.count('signOut'), 0);
    });

    test(
        '記録が無い状態で withdraw を呼び関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false で、記録は serverDone、signOut は0回 [ACD-V08 #d10e09]',
        () async {
      final env = _Env();
      await env.boot();
      env.repo.deleteLocalFailure = _unknown;
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, false);
      expect(env.repo.record?.status, AccountDeletionStatus.serverDone);
      expect(env.count('signOut'), 0);
    });

    test('phase が processing の間にもう一度 withdraw を呼んだ場合、requestServerDeletion は合計1回だけ呼ばれる [ACD-V09 #a68a80]',
        () async {
      final env = _Env();
      await env.boot();
      env.repo.requestGate = Completer<void>();

      final first = env.vm.withdraw();
      await _pump();
      expect(env.state.phase, AccountDeletionPhase.processing);
      await env.vm.withdraw();
      env.repo.requestGate!.complete();
      await first;

      expect(env.count('requestServerDeletion'), 1);
    });

    test(
        '記録が無い状態で withdraw を呼び関数の呼び出しが AuthFailure で失敗した場合、phase が notSent になり、clearRequest(A) が1回呼ばれ記録は無く、deleteLocalData・signOut は0回 [ACD-V11 #76228d]',
        () async {
      final env = _Env();
      await env.boot();
      env.repo.requestFailure = _auth;
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.notSent);
      expect(env.count('clearRequest(A)'), 1);
      expect(env.repo.record, isNull);
      expect(env.count('deleteLocalData(A)'), 0);
      expect(env.count('signOut'), 0);
    });

    test(
        '記録が無い状態で withdraw を呼び関数・端末内の削除が成功し signOut が UnknownFailure で失敗した場合、phase が completed になる [ACD-V24 #bf80d9]',
        () async {
      final env = _Env();
      await env.boot();
      env.auth.signOutFailure = _unknown;
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.completed);
    });

    test(
        'phase が pendingRetry の状態で withdraw を呼んだ場合、phase は pendingRetry のままで、markRequested・requestServerDeletion は0回 [ACD-V32 #34d262]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.log.where((e) => e.startsWith('markRequested')), isEmpty);
      expect(env.count('requestServerDeletion'), 0);
    });

    test(
        '記録が無い状態で withdraw を呼び markRequested が UnknownFailure で失敗した場合、phase が notSent になり、requestServerDeletion は0回 [ACD-V35 #235d99]',
        () async {
      final env = _Env();
      await env.boot();
      env.repo.markRequestedFailure = _unknown;
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.notSent);
      expect(env.count('requestServerDeletion'), 0);
    });

    test(
        '記録が無い状態で withdraw を呼び関数が NetworkFailure で失敗し clearRequest が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false になる [ACD-V36 #75999d]',
        () async {
      final env = _Env();
      await env.boot();
      env.repo.requestFailure = _network;
      env.repo.clearRequestFailure = _unknown;
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, false);
    });

    test(
        '記録が無い状態で withdraw を呼び関数は成功し markServerDone が UnknownFailure で失敗し端末内の削除が成功した場合、phase が completed になり、deleteLocalData(A) が1回呼ばれる [ACD-V37 #1f5756]',
        () async {
      final env = _Env();
      await env.boot();
      env.repo.markServerDoneFailure = _unknown;
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.completed);
      expect(env.count('deleteLocalData(A)'), 1);
    });
  });

  group('retry', () {
    test(
        'ログイン中で uid A の記録が requested の状態で retry を呼び関数・端末内の削除が成功した場合、phase が completed になり、requestServerDeletion・markServerDone(A)・deleteLocalData(A)・signOut がこの順に1回ずつ呼ばれる [ACD-V12 #8c6c4b]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.completed);
      expect(env.log, [
        'requestServerDeletion',
        'markServerDone(A)',
        'deleteLocalData(A)',
        'signOut',
      ]);
    });

    test(
        'uid A の記録が serverDone の状態で retry を呼び端末内の削除が成功した場合、phase が completed になり、requestServerDeletion は0回、deleteLocalData(A) は1回、signOut は1回 [ACD-V13 #7badb4]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.serverDone));
      await env.boot();
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.completed);
      expect(env.count('requestServerDeletion'), 0);
      expect(env.count('deleteLocalData(A)'), 1);
      expect(env.count('signOut'), 1);
    });

    test(
        'ログインしていない状態で uid A の記録が requested のまま retry を呼び端末内の削除が成功した場合、phase が completed になり、requestServerDeletion は0回、deleteLocalData(A) は1回、signOut は1回 [ACD-V14 #ef3249]',
        () async {
      final env = _Env(
        user: null,
        initial: _record(AccountDeletionStatus.requested),
      );
      await env.boot();
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.completed);
      expect(env.count('requestServerDeletion'), 0);
      expect(env.count('deleteLocalData(A)'), 1);
      expect(env.count('signOut'), 1);
    });

    test(
        'ログイン中で uid A の記録が requested の状態で retry を呼び関数が AuthFailure で失敗し端末内の削除が成功した場合、phase が completed になり、deleteLocalData(A) は1回、signOut は1回 [ACD-V15 #ea056e]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      env.repo.requestFailure = _auth;
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.completed);
      expect(env.count('deleteLocalData(A)'), 1);
      expect(env.count('signOut'), 1);
    });

    test(
        'ログイン中で uid A の記録が requested の状態で retry を呼び関数が NetworkFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、deleteLocalData は0回 [ACD-V16 #5df076]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      env.repo.requestFailure = _network;
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, true);
      expect(env.repo.record?.status, AccountDeletionStatus.requested);
      expect(env.log.where((e) => e.startsWith('deleteLocalData')), isEmpty);
    });

    test(
        'ログイン中で uid A の記録が requested の状態で retry を呼び関数が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、deleteLocalData は0回 [ACD-V17 #b8b268]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      env.repo.requestFailure = _unknown;
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, true);
      expect(env.repo.record?.status, AccountDeletionStatus.requested);
      expect(env.log.where((e) => e.startsWith('deleteLocalData')), isEmpty);
    });

    test(
        'uid A の記録が serverDone の状態で retry を呼び端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は serverDone のまま [ACD-V18 #723164]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.serverDone));
      await env.boot();
      env.repo.deleteLocalFailure = _unknown;
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, true);
      expect(env.repo.record?.status, AccountDeletionStatus.serverDone);
    });

    test(
        'ログイン中で uid A の記録が requested の状態で retry を呼び関数の応答を待っている場合、phase が processing になる [ACD-V19 #d810ba]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      env.repo.requestGate = Completer<void>();
      final future = env.vm.retry();
      await _pump();
      expect(env.state.phase, AccountDeletionPhase.processing);
      env.repo.requestGate!.complete();
      await future;
    });

    test(
        'ログイン中で uid A の記録が requested の状態で retry の処理中にもう一度 retry を呼び関数・端末内の削除が成功した場合、requestServerDeletion は合計1回、deleteLocalData(A) は合計1回呼ばれる [ACD-V20 #07c1f5]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      env.repo.requestGate = Completer<void>();
      final first = env.vm.retry();
      await _pump();
      await env.vm.retry();
      env.repo.requestGate!.complete();
      await first;
      expect(env.count('requestServerDeletion'), 1);
      expect(env.count('deleteLocalData(A)'), 1);
    });

    test(
        'phase が pendingRetry、retryFailed が true の状態で retry を呼び関数の応答を待っている場合、phase が processing、retryFailed が false になる [ACD-V23 #a34a49]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      env.repo.requestFailure = _unknown;
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, true);

      env.repo.requestFailure = null;
      env.repo.requestGate = Completer<void>();
      final future = env.vm.retry();
      await _pump();
      expect(env.state.phase, AccountDeletionPhase.processing);
      expect(env.state.retryFailed, false);
      env.repo.requestGate!.complete();
      await future;
    });

    test(
        'uid A の記録が serverDone の状態で retry を呼び端末内の削除の完了を待っている場合、phase が processing になる [ACD-V25 #cf5e64]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.serverDone));
      await env.boot();
      env.repo.deleteLocalGate = Completer<void>();
      final future = env.vm.retry();
      await _pump();
      expect(env.state.phase, AccountDeletionPhase.processing);
      env.repo.deleteLocalGate!.complete();
      await future;
    });

    test(
        'ログイン中の uid が B、記録が uid A の requested の状態で retry を呼び端末内の削除が成功した場合、phase が completed になり、requestServerDeletion は0回、signOut が deleteLocalData(A) より先に呼ばれ、deleteLocalData(B) は0回 [ACD-V26 #8b7f12]',
        () async {
      final env = _Env(
        user: _userB,
        initial: _record(AccountDeletionStatus.requested),
      );
      await env.boot();
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.completed);
      expect(env.count('requestServerDeletion'), 0);
      expect(env.count('deleteLocalData(A)'), 1);
      expect(env.count('signOut'), greaterThanOrEqualTo(1));
      expect(
        env.log.indexOf('signOut') < env.log.indexOf('deleteLocalData(A)'),
        true,
      );
      expect(env.count('deleteLocalData(B)'), 0);
    });

    test(
        'uid A の記録が serverDone の状態で retry を呼び端末内の削除が成功し signOut が UnknownFailure で失敗した場合、phase が completed になる [ACD-V27 #a901f8]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.serverDone));
      await env.boot();
      env.auth.signOutFailure = _unknown;
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.completed);
    });

    test(
        'ログイン中で uid A の記録が requested の状態で retry を呼び関数は成功し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は serverDone、signOut は0回 [ACD-V29 #4d44fc]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      env.repo.deleteLocalFailure = _unknown;
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, true);
      expect(env.repo.record?.status, AccountDeletionStatus.serverDone);
      expect(env.count('signOut'), 0);
    });

    test(
        'ログインしていない状態で uid A の記録が requested のまま retry を呼び端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、signOut は0回 [ACD-V30 #23a844]',
        () async {
      final env = _Env(
        user: null,
        initial: _record(AccountDeletionStatus.requested),
      );
      await env.boot();
      env.repo.deleteLocalFailure = _unknown;
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, true);
      expect(env.repo.record?.status, AccountDeletionStatus.requested);
      expect(env.count('signOut'), 0);
    });

    test(
        'ログイン中で uid A の記録が requested の状態で retry を呼び関数が AuthFailure で失敗し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、signOut は0回 [ACD-V31 #b6565f]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      env.repo.requestFailure = _auth;
      env.repo.deleteLocalFailure = _unknown;
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      expect(env.state.retryFailed, true);
      expect(env.repo.record?.status, AccountDeletionStatus.requested);
      expect(env.count('signOut'), 0);
    });

    test(
        'phase が pendingRetry で findPending が None を返す状態で retry を呼んだ場合、phase が idle になり、requestServerDeletion・deleteLocalData は0回 [ACD-V34 #851f75]',
        () async {
      final env = _Env(initial: _record(AccountDeletionStatus.requested));
      await env.boot();
      expect(env.state.phase, AccountDeletionPhase.pendingRetry);
      env.repo.record = null;
      await env.vm.retry();
      expect(env.state.phase, AccountDeletionPhase.idle);
      expect(env.count('requestServerDeletion'), 0);
      expect(env.log.where((e) => e.startsWith('deleteLocalData')), isEmpty);
    });
  });

  group('acknowledge', () {
    test('phase が completed の状態で acknowledgeCompleted を呼んだ場合、phase が idle になる [ACD-V21 #70d905]',
        () async {
      final env = _Env();
      await env.boot();
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.completed);
      env.vm.acknowledgeCompleted();
      expect(env.state.phase, AccountDeletionPhase.idle);
    });

    test('phase が notSent の状態で acknowledgeNotSent を呼んだ場合、phase が idle になる [ACD-V22 #12c47a]',
        () async {
      final env = _Env();
      await env.boot();
      env.repo.requestFailure = _network;
      await env.vm.withdraw();
      expect(env.state.phase, AccountDeletionPhase.notSent);
      env.vm.acknowledgeNotSent();
      expect(env.state.phase, AccountDeletionPhase.idle);
    });
  });
}
