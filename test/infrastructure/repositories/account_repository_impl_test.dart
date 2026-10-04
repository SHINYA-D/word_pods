// 仕様書: docs/detailed_design/presentation/shell/shell_page.md（接頭辞 SHL、5章 SHL-R01〜R13）
//
// 期待値はすべて上記仕様書から作った。実装は「どう呼ぶか」を知るためだけに読んでいる。
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_stock/core/error/failure.dart';
import 'package:word_stock/infrastructure/data_sources/remote/account_remote_data_source.dart';
import 'package:word_stock/infrastructure/repositories/account_repository_impl.dart';

/// [AccountRemoteDataSource] の手書きフェイク。結果を順に返し、例外が指定されていれば投げる。
class _FakeAccountRemoteDataSource implements AccountRemoteDataSource {
  _FakeAccountRemoteDataSource(this.steps);

  /// 呼び出しごとに先頭から消費する。bool は戻り値、それ以外は投げる例外。
  final List<Object> steps;

  @override
  Future<bool> fetchIsDeveloper(String userId) async {
    final step = steps.removeAt(0);
    if (step is bool) return step;
    throw step;
  }
}

void main() {
  const u1 = 'u1';

  late FakeFirebaseFirestore firestore;
  late AccountRepositoryImpl repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = AccountRepositoryImpl(
        remoteDataSource: AccountRemoteDataSource(firestore));
  });

  AccountRepositoryImpl repoWith(List<Object> steps) => AccountRepositoryImpl(
      remoteDataSource: _FakeAccountRemoteDataSource(steps));

  void expectUnknown(Either<Failure, bool> result) {
    expect(result.isLeft(), isTrue);
    result.match((f) => expect(f, isA<UnknownFailure>()), (_) => fail('Right'));
  }

  group('fetchIsDeveloper', () {
    test('accounts/u1 が {isDeveloper: true} の場合、Right(true) になる [SHL-R01]',
        () async {
      await firestore.doc('accounts/u1').set({'isDeveloper': true});

      expect(await repo.fetchIsDeveloper(u1), const Right<Failure, bool>(true));
    });

    test('accounts/u1 が {isDeveloper: false} の場合、Right(false) になる [SHL-R02]',
        () async {
      await firestore.doc('accounts/u1').set({'isDeveloper': false});

      expect(
          await repo.fetchIsDeveloper(u1), const Right<Failure, bool>(false));
    });

    test('accounts/u1 が存在しない場合、Right(false) になる [SHL-R03]', () async {
      expect(
          await repo.fetchIsDeveloper(u1), const Right<Failure, bool>(false));
    });

    test('accounts/u1 はあるが isDeveloper が無い場合、Right(false) になる [SHL-R04]',
        () async {
      await firestore
          .doc('accounts/u1')
          .set({'createdAt': Timestamp.fromDate(DateTime(2024, 6, 1))});

      expect(
          await repo.fetchIsDeveloper(u1), const Right<Failure, bool>(false));
    });

    test('accounts/u1 が {isDeveloper: "true"}（文字列）の場合、Right(false) になる [SHL-R05]',
        () async {
      await firestore.doc('accounts/u1').set({'isDeveloper': 'true'});

      expect(
          await repo.fetchIsDeveloper(u1), const Right<Failure, bool>(false));
    });

    test('accounts/u2 が {isDeveloper: true} で accounts/u1 は存在しない場合、fetchIsDeveloper(u1) は Right(false) になる [SHL-R06]',
        () async {
      await firestore.doc('accounts/u2').set({'isDeveloper': true});

      expect(
          await repo.fetchIsDeveloper(u1), const Right<Failure, bool>(false));
    });

    test('Firestore の読み取りがコード unavailable の例外で失敗した場合、Left(UnknownFailure) になる [SHL-R07]',
        () async {
      final r = repoWith([
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable')
      ]);

      expectUnknown(await r.fetchIsDeveloper(u1));
    });

    test('Firestore の読み取りがコード permission-denied の例外で失敗した場合、Left(UnknownFailure) になる [SHL-R08]',
        () async {
      final r = repoWith([
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied')
      ]);

      expectUnknown(await r.fetchIsDeveloper(u1));
    });

    test('1回目が Right(true) で2回目の読み取りが unavailable で失敗した場合、2回目は Left(UnknownFailure) になり前回の値を返さない [SHL-R09]',
        () async {
      final r = repoWith([
        true,
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      ]);

      expect(await r.fetchIsDeveloper(u1), const Right<Failure, bool>(true));
      expectUnknown(await r.fetchIsDeveloper(u1));
    });

    test('Firestore の読み取りがコード deadline-exceeded の例外で失敗した場合、Left(UnknownFailure) になる [SHL-R10]',
        () async {
      final r = repoWith([
        FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded')
      ]);

      expectUnknown(await r.fetchIsDeveloper(u1));
    });

    test('Firestore の読み取りが Firebase 以外の例外（StateError）で失敗した場合、Left(UnknownFailure) になる [SHL-R11]',
        () async {
      final r = repoWith([StateError('boom')]);

      expectUnknown(await r.fetchIsDeveloper(u1));
    });

    test('accounts/u1 が {isDeveloper: null} の場合、Right(false) になる [SHL-R12]',
        () async {
      await firestore.doc('accounts/u1').set({'isDeveloper': null});

      expect(
          await repo.fetchIsDeveloper(u1), const Right<Failure, bool>(false));
    });

    test('accounts/u1 が {isDeveloper: 1}（数値）の場合、Right(false) になる [SHL-R13]',
        () async {
      await firestore.doc('accounts/u1').set({'isDeveloper': 1});

      expect(
          await repo.fetchIsDeveloper(u1), const Right<Failure, bool>(false));
    });
  });
}
