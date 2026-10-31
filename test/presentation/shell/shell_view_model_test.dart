import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/core/di/repository_providers.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/app_user.dart';
import 'package:word_pods/domain/repositories/account_repository.dart';
import 'package:word_pods/presentation/shell/shell_view_model.dart';

const _u1 = AppUser(id: 'u1', email: 'u1@example.com');
const _u2 = AppUser(id: 'u2', email: 'u2@example.com');

/// userId ごとに結果を決める Fake。[results] に値があれば即座に返し、無ければ
/// [complete] が呼ばれるまで応答しない（読み込み中）。
class _FakeAccountRepository implements AccountRepository {
  final calls = <String>[];
  final results = <String, Either<Failure, bool>>{};
  final _pending = <String, List<Completer<Either<Failure, bool>>>>{};

  @override
  Future<Either<Failure, bool>> fetchIsDeveloper(String userId) {
    calls.add(userId);
    final r = results[userId];
    if (r != null) return Future.value(r);
    final c = Completer<Either<Failure, bool>>();
    _pending.putIfAbsent(userId, () => []).add(c);
    return c.future;
  }

  void complete(String userId, Either<Failure, bool> result) {
    _pending[userId]!.firstWhere((c) => !c.isCompleted).complete(result);
  }

  int count(String userId) => calls.where((e) => e == userId).length;
}

final _userState = StateProvider<AppUser?>((ref) => null);

class _Env {
  _Env({AppUser? user}) {
    container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(repo),
        currentUserProvider.overrideWith((ref) => ref.watch(_userState)),
      ],
    );
    addTearDown(container.dispose);
    container.read(_userState.notifier).state = user;
    // keepAlive の isDeveloper を購読し続け、値の変化を記録する
    container.listen<bool>(isDeveloperProvider, (_, next) => history.add(next),
        fireImmediately: true);
  }

  final repo = _FakeAccountRepository();
  late final ProviderContainer container;
  final history = <bool>[];

  bool get isDeveloper => container.read(isDeveloperProvider);

  void login(AppUser? user) =>
      container.read(_userState.notifier).state = user;
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  group('isDeveloper', () {
    test('ユーザー u1 でログインし fetchIsDeveloper が Right(true) を返した場合、isDeveloper が true になり、u1 で1回呼ばれる [SHL-V01 #4b4144]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Right(true);
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, true);
      expect(env.repo.calls, ['u1']);
    });

    test('ユーザー u1 でログインし fetchIsDeveloper が Right(false) を返した場合、isDeveloper が false になる [SHL-V02 #cfda62]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Right(false);
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, false);
      expect(env.repo.count('u1'), 1);
    });

    test('ユーザー u1 でログインし fetchIsDeveloper が完了していない場合、isDeveloper が false になる [SHL-V03 #a6723d]',
        () async {
      final env = _Env();
      env.login(_u1);
      await _pump();
      expect(env.repo.count('u1'), 1);
      expect(env.isDeveloper, false);
    });

    test('ユーザー u1 でログインし fetchIsDeveloper が Left(UnknownFailure) を返した場合、isDeveloper が false になる [SHL-V04 #fcdaa8]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Left(Failure.unknown('x'));
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, false);
    });

    test('ログインしていない状態でアプリを起動した場合、isDeveloper が false で、fetchIsDeveloper は呼ばれない [SHL-V05 #452324]',
        () async {
      final env = _Env();
      await _pump();
      expect(env.isDeveloper, false);
      expect(env.repo.calls, isEmpty);
    });

    test('u1（開発者）でログインしてログアウトし u2 でログインし直して Right(false) を返した場合、isDeveloper が false で u1・u2 で1回ずつ呼ばれる [SHL-V06 #90373b]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Right(true);
      env.repo.results['u2'] = const Right(false);
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, true);
      env.login(null);
      await _pump();
      env.login(_u2);
      await _pump();
      expect(env.isDeveloper, false);
      expect(env.repo.calls, ['u1', 'u2']);
    });

    test('u1（開発者でない）でログインしてログアウトし u2 でログインし直して Right(true) を返した場合、isDeveloper が true になる [SHL-V07 #d81ed2]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Right(false);
      env.repo.results['u2'] = const Right(true);
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, false);
      env.login(null);
      await _pump();
      env.login(_u2);
      await _pump();
      expect(env.isDeveloper, true);
    });

    test('u1 で Right(false) を返した後ログインし直さず Right(true) を返すように変わった場合、isDeveloper は false のままで1回だけ呼ばれる [SHL-V08 #e32bb7]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Right(false);
      env.login(_u1);
      await _pump();
      env.repo.results['u1'] = const Right(true);
      await _pump();
      expect(env.isDeveloper, false);
      expect(env.repo.count('u1'), 1);
    });

    test('u1 の fetchIsDeveloper が完了していない状態から Right(true) で完了した場合、isDeveloper が false から true に変わる [SHL-V09 #c3e851]',
        () async {
      final env = _Env();
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, false);
      env.repo.complete('u1', const Right(true));
      await _pump();
      expect(env.isDeveloper, true);
      expect(env.history.last, true);
      expect(env.history.first, false);
    });

    test('u1 で Right(false) を返しログアウトして同じ u1 でログインし直し Right(true) を返した場合、isDeveloper が true で u1 で2回呼ばれる [SHL-V10 #26209b]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Right(false);
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, false);
      env.login(null);
      await _pump();
      env.repo.results['u1'] = const Right(true);
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, true);
      expect(env.repo.count('u1'), 2);
    });

    test('ユーザー u1 でログインし fetchIsDeveloper が Left(NetworkFailure) を返した場合、isDeveloper が false になる [SHL-V11 #7d5624]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Left(Failure.network());
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, false);
    });

    test('ユーザー u1 でログインし fetchIsDeveloper が Left(AuthFailure) を返した場合、isDeveloper が false になる [SHL-V12 #ff39b3]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Left(Failure.auth());
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, false);
    });

    test('ユーザー u1 でログインし fetchIsDeveloper が Left(NotFoundFailure) を返した場合、isDeveloper が false になる [SHL-V13 #55449f]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Left(Failure.notFound());
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, false);
    });

    test('u1（開発者）でログインしてログアウトし u2 でログインし直して Left(UnknownFailure) を返した場合、isDeveloper が false になる [SHL-V14 #ca9a4e]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Right(true);
      env.repo.results['u2'] = const Left(Failure.unknown('x'));
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, true);
      env.login(null);
      await _pump();
      env.login(_u2);
      await _pump();
      expect(env.isDeveloper, false);
    });

    test('u1 の読み込み中にログアウトして u2 でログインし直し、u2 が Right(false) を返した後に u1 が Right(true) を返した場合、isDeveloper は false のままになる [SHL-V15 #72515b]',
        () async {
      final env = _Env();
      env.login(_u1);
      await _pump();
      env.login(null);
      await _pump();
      env.login(_u2);
      await _pump();
      env.repo.complete('u2', const Right(false));
      await _pump();
      expect(env.isDeveloper, false);
      env.repo.complete('u1', const Right(true));
      await _pump();
      expect(env.isDeveloper, false);
    });

    test('u1（開発者）でログインしてログアウトし u2 でログインし直して u2 の fetchIsDeveloper が完了していない場合、isDeveloper が false になる [SHL-V16 #2534f3]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Right(true);
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, true);
      env.login(null);
      await _pump();
      env.login(_u2);
      await _pump();
      expect(env.repo.count('u2'), 1);
      expect(env.isDeveloper, false);
    });

    test('u1（開発者）でログインしてログアウトした場合、isDeveloper が false になる [SHL-V17 #49a973]',
        () async {
      final env = _Env();
      env.repo.results['u1'] = const Right(true);
      env.login(_u1);
      await _pump();
      expect(env.isDeveloper, true);
      env.login(null);
      await _pump();
      expect(env.isDeveloper, false);
    });

    test('u1 の読み込み中にログアウトして u2 でログインし直し、u2 の完了前に u1 が Right(true) を返した場合、isDeveloper が false になる [SHL-V18 #5e6ac6]',
        () async {
      final env = _Env();
      env.login(_u1);
      await _pump();
      env.login(null);
      await _pump();
      env.login(_u2);
      await _pump();
      env.repo.complete('u1', const Right(true));
      await _pump();
      expect(env.isDeveloper, false);
    });
  });
}
