import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_pods/application/use_cases/auth/delete_account_use_case.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/account_deletion_request.dart';
import 'package:word_pods/domain/repositories/account_deletion_repository.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/repositories/sync_repository.dart';
import 'package:word_pods/domain/entities/app_user.dart';

/// 呼び出し順を全 Fake で共有して記録する。
class _Log {
  final List<String> calls = [];
  int count(String name) => calls.where((c) => c == name).length;
}

class _FakeDeletionRepository implements AccountDeletionRepository {
  _FakeDeletionRepository(this.log);

  final _Log log;
  Either<Failure, Option<AccountDeletionRequest>> findResult =
      const Right(None());
  Either<Failure, Unit> markRequestedResult = const Right(unit);
  Either<Failure, Unit> markServerDoneResult = const Right(unit);
  Either<Failure, Unit> clearResult = const Right(unit);
  Either<Failure, Unit> serverResult = const Right(unit);
  Either<Failure, Unit> deleteLocalResult = const Right(unit);

  @override
  Future<Either<Failure, Option<AccountDeletionRequest>>> findPending() async {
    log.calls.add('findPending');
    return findResult;
  }

  @override
  Future<Either<Failure, Unit>> markRequested(String userId) async {
    log.calls.add('markRequested');
    return markRequestedResult;
  }

  @override
  Future<Either<Failure, Unit>> markServerDone(String userId) async {
    log.calls.add('markServerDone');
    return markServerDoneResult;
  }

  @override
  Future<Either<Failure, Unit>> clearRequest(String userId) async {
    log.calls.add('clearRequest');
    return clearResult;
  }

  @override
  Future<Either<Failure, Unit>> requestServerDeletion() async {
    log.calls.add('requestServerDeletion');
    return serverResult;
  }

  @override
  Future<Either<Failure, Unit>> deleteLocalData(String userId) async {
    log.calls.add('deleteLocalData');
    return deleteLocalResult;
  }

  // 他の端末での退会（このテストでは使わない）
  @override
  Future<Either<Failure, List<String>>> findLocalUserIds() async =>
      const Right([]);

  @override
  Future<Either<Failure, bool>> isWithdrawnOnServer(String userId) async =>
      const Right(false);

  @override
  Stream<Either<Failure, bool>> watchWithdrawn(String userId) =>
      const Stream.empty();

  @override
  Future<Either<Failure, Unit>> deleteLocalDataOfUsers(
          List<String> userIds) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> markForcedSignOut(String userId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Option<String>>> findForcedSignOut() async =>
      const Right(None());

  @override
  Future<Either<Failure, Unit>> clearForcedSignOut(String userId) async =>
      const Right(unit);
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.log);

  final _Log log;

  @override
  Future<Either<Failure, Unit>> signOut() async {
    log.calls.add('signOut');
    return const Right(unit);
  }

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeSyncRepository implements SyncRepository {
  _FakeSyncRepository(this.log);

  final _Log log;

  @override
  Future<void> waitUntilIdle() async {
    log.calls.add('waitUntilIdle');
  }

  @override
  Future<void> syncRemoteToLocalOnLogin() async {}

  @override
  Future<int> pushBeforeSignOut() async => 0;
}

AccountDeletionRequest _request(AccountDeletionStatus status,
        {String userId = 'A'}) =>
    AccountDeletionRequest(
      userId: userId,
      status: status,
      updatedAt: DateTime(2026, 10, 4),
    );

void main() {
  late _Log log;
  late _FakeDeletionRepository repo;
  late DeleteAccountUseCase useCase;

  setUp(() {
    log = _Log();
    repo = _FakeDeletionRepository(log);
    useCase = DeleteAccountUseCase(
      repo,
      _FakeAuthRepository(log),
      _FakeSyncRepository(log),
    );
  });

  group('DeleteAccountUseCase.checkPending', () {
    test('記録が無い場合、none が返る [ACD-V01]', () async {
      repo.findResult = const Right(None());

      expect(await useCase.checkPending(), AccountDeletionOutcome.none);
    });

    test('記録が残っている場合、pending が返る [ACD-V02]', () async {
      repo.findResult =
          Right(Some(_request(AccountDeletionStatus.requested)));

      expect(await useCase.checkPending(), AccountDeletionOutcome.pending);
    });

    test('記録の読み取りに失敗した場合、pending が返る [ACD-V33]', () async {
      repo.findResult = const Left(Failure.unknown('x'));

      expect(await useCase.checkPending(), AccountDeletionOutcome.pending);
    });
  });

  group('DeleteAccountUseCase.withdraw', () {
    test('関数と端末内の削除が成功した場合、同期の完了を待って順に処理し completed が返る [ACD-V05]',
        () async {
      final outcome = await useCase.withdraw('A');

      expect(outcome, AccountDeletionOutcome.completed);
      expect(log.calls, [
        'markRequested',
        'waitUntilIdle',
        'requestServerDeletion',
        'markServerDone',
        'deleteLocalData',
        'signOut',
      ]);
    });

    test('記録の作成に失敗した場合、関数を呼ばず notSent が返る [ACD-V35]', () async {
      repo.markRequestedResult = const Left(Failure.unknown('x'));

      final outcome = await useCase.withdraw('A');

      expect(outcome, AccountDeletionOutcome.notSent);
      expect(log.count('requestServerDeletion'), 0);
    });

    test('関数が NetworkFailure の場合、記録を消して notSent が返る [ACD-V06]', () async {
      repo.serverResult = const Left(Failure.network());

      final outcome = await useCase.withdraw('A');

      expect(outcome, AccountDeletionOutcome.notSent);
      expect(log.count('clearRequest'), 1);
      expect(log.count('deleteLocalData'), 0);
    });

    test('関数が AuthFailure の場合、記録を消して notSent が返る [ACD-V11]', () async {
      repo.serverResult = const Left(Failure.auth());

      final outcome = await useCase.withdraw('A');

      expect(outcome, AccountDeletionOutcome.notSent);
      expect(log.count('clearRequest'), 1);
    });

    test('関数が UnknownFailure の場合、記録を消さず pending が返る [ACD-V07]', () async {
      repo.serverResult = const Left(Failure.unknown('x'));

      final outcome = await useCase.withdraw('A');

      expect(outcome, AccountDeletionOutcome.pending);
      expect(log.count('clearRequest'), 0);
      expect(log.count('deleteLocalData'), 0);
    });

    test('関数が NetworkFailure で記録を消せなかった場合、pending が返る [ACD-V36]', () async {
      repo.serverResult = const Left(Failure.network());
      repo.clearResult = const Left(Failure.unknown('x'));

      expect(await useCase.withdraw('A'), AccountDeletionOutcome.pending);
    });

    test('端末内の削除に失敗した場合、ログアウトせず pending が返る [ACD-V08]', () async {
      repo.deleteLocalResult = const Left(Failure.unknown('x'));

      final outcome = await useCase.withdraw('A');

      expect(outcome, AccountDeletionOutcome.pending);
      expect(log.count('signOut'), 0);
    });
  });

  group('DeleteAccountUseCase.resume', () {
    test('記録が無い場合、何も削除せず none が返る [ACD-V34]', () async {
      repo.findResult = const Right(None());

      final outcome = await useCase.resume('A');

      expect(outcome, AccountDeletionOutcome.none);
      expect(log.count('requestServerDeletion'), 0);
      expect(log.count('deleteLocalData'), 0);
    });

    test('記録が serverDone の場合、関数を呼ばず端末内を削除して completed が返る [ACD-V13]',
        () async {
      repo.findResult =
          Right(Some(_request(AccountDeletionStatus.serverDone)));

      final outcome = await useCase.resume('A');

      expect(outcome, AccountDeletionOutcome.completed);
      expect(log.count('requestServerDeletion'), 0);
      expect(log.count('deleteLocalData'), 1);
    });

    test('ログインしていない場合、関数を呼ばず端末内を削除して completed が返る [ACD-V14]', () async {
      repo.findResult =
          Right(Some(_request(AccountDeletionStatus.requested)));

      final outcome = await useCase.resume(null);

      expect(outcome, AccountDeletionOutcome.completed);
      expect(log.count('requestServerDeletion'), 0);
      expect(log.count('deleteLocalData'), 1);
    });

    test('ログイン中のユーザーが記録と違う場合、先にログアウトして関数を呼ばず completed が返る [ACD-V26]',
        () async {
      repo.findResult =
          Right(Some(_request(AccountDeletionStatus.requested)));

      final outcome = await useCase.resume('B');

      expect(outcome, AccountDeletionOutcome.completed);
      expect(log.count('requestServerDeletion'), 0);
      expect(log.calls.indexOf('signOut'),
          lessThan(log.calls.indexOf('deleteLocalData')));
    });

    test('同じユーザーで関数が成功した場合、同期を待たず completed が返る [ACD-V12]', () async {
      repo.findResult =
          Right(Some(_request(AccountDeletionStatus.requested)));

      final outcome = await useCase.resume('A');

      expect(outcome, AccountDeletionOutcome.completed);
      expect(log.count('requestServerDeletion'), 1);
      expect(log.count('waitUntilIdle'), 0);
    });

    test('関数が AuthFailure の場合、削除済みとして端末内を削除し completed が返る [ACD-V15]',
        () async {
      repo.findResult =
          Right(Some(_request(AccountDeletionStatus.requested)));
      repo.serverResult = const Left(Failure.auth());

      final outcome = await useCase.resume('A');

      expect(outcome, AccountDeletionOutcome.completed);
      expect(log.count('deleteLocalData'), 1);
    });

    test('関数が UnknownFailure の場合、端末内を削除せず pending が返る [ACD-V17]', () async {
      repo.findResult =
          Right(Some(_request(AccountDeletionStatus.requested)));
      repo.serverResult = const Left(Failure.unknown('x'));

      final outcome = await useCase.resume('A');

      expect(outcome, AccountDeletionOutcome.pending);
      expect(log.count('deleteLocalData'), 0);
    });
  });
}
