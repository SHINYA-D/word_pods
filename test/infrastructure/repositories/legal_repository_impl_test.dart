// 仕様書: docs/detailed_design/legal_consent/legal_consent.md（接頭辞 LGL、5章 LGL-R01〜R45）
//
// 期待値はすべて上記仕様書から作った。実装は「どう呼ぶか」を知るためだけに読んでいる。
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_stock/core/error/failure.dart';
import 'package:word_stock/domain/entities/legal_consent.dart';
import 'package:word_stock/infrastructure/data_sources/remote/legal_remote_data_source.dart';
import 'package:word_stock/infrastructure/repositories/legal_repository_impl.dart';

import '../../helpers/fake_infrastructure.dart';

/// [LegalRemoteDataSource] の手書きフェイク。読み取り結果・例外を設定し、関数に渡した引数を記録する。
class _FakeLegalRemoteDataSource implements LegalRemoteDataSource {
  Map<String, dynamic>? config;
  Object? consents;

  /// 設定すると読み取り（fetchConfig / fetchConsents）がこの例外を投げる。
  Object? readError;

  /// 設定すると accept がこの例外を投げる。
  Object? acceptError;

  final List<Map<String, String>> acceptCalls = [];

  @override
  Future<Map<String, dynamic>?> fetchConfig() async {
    if (readError != null) throw readError!;
    return config;
  }

  @override
  Future<Object?> fetchConsents(String userId) async {
    if (readError != null) throw readError!;
    return consents;
  }

  @override
  Future<void> accept(Map<String, String> versions) async {
    acceptCalls.add(Map.of(versions));
    if (acceptError != null) throw acceptError!;
  }
}

Map<String, dynamic> validConfig() => <String, dynamic>{
      'termsVersion': '2026-01-01',
      'privacyVersion': '2026-01-01',
      'termsUrl': 'https://example.com/terms',
      'privacyUrl': 'https://example.com/privacy',
    };

const validLegalConfig = LegalConfig(
  termsVersion: '2026-01-01',
  privacyVersion: '2026-01-01',
  termsUrl: 'https://example.com/terms',
  privacyUrl: 'https://example.com/privacy',
);

/// 結果が Left で、失敗の型が [F] であること。
void expectLeft<R, F extends Failure>(Either<Failure, R> result) {
  expect(result.isLeft(), isTrue);
  result.match((f) => expect(f, isA<F>()), (_) => fail('Right が返った'));
}

void main() {
  late _FakeLegalRemoteDataSource remote;
  late FakeConnectivityMonitor connectivity;
  late LegalRepositoryImpl repo;

  setUp(() {
    remote = _FakeLegalRemoteDataSource();
    connectivity = FakeConnectivityMonitor();
    repo = LegalRepositoryImpl(remoteDataSource: remote, connectivityMonitor: connectivity);
  });

  group('fetchLegalConfig', () {
    test('app_config/legal に4項目がすべて文字列である場合、Right(LegalConfig) になる [LGL-R01]', () async {
      remote.config = validConfig();
      expect(await repo.fetchLegalConfig(), const Right<Failure, LegalConfig>(validLegalConfig));
    });

    test('app_config/legal が無い場合、Left(NotFoundFailure) になる [LGL-R02]', () async {
      remote.config = null;
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal に termsVersion が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R03]', () async {
      remote.config = validConfig()..remove('termsVersion');
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal に privacyVersion が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R04]', () async {
      remote.config = validConfig()..remove('privacyVersion');
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の termsVersion が数値の 20260101で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R05]', () async {
      remote.config = validConfig()..['termsVersion'] = 20260101;
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal に termsUrl が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R06]', () async {
      remote.config = validConfig()..remove('termsUrl');
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal に privacyUrl が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R07]', () async {
      remote.config = validConfig()..remove('privacyUrl');
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('端末のキャッシュには app_config/legal があるがサーバーに接続できない場合、Left(NetworkFailure) になる [LGL-R08]', () async {
      remote.config = validConfig();
      connectivity.setOnline(false);
      expectLeft<LegalConfig, NetworkFailure>(await repo.fetchLegalConfig());
    });

    test('読み取りがエラーコード internal で失敗した場合、Left(UnknownFailure) になる [LGL-R09]', () async {
      remote.readError = FirebaseException(plugin: 'cloud_firestore', code: 'internal');
      expectLeft<LegalConfig, UnknownFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の privacyVersion が数値の 20260101で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R24]', () async {
      remote.config = validConfig()..['privacyVersion'] = 20260101;
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('読み取りがエラーコード permission-denied で失敗した場合、Left(UnknownFailure) になる [LGL-R27]', () async {
      remote.readError = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      expectLeft<LegalConfig, UnknownFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の termsVersion が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R29]', () async {
      remote.config = validConfig()..['termsVersion'] = '';
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の termsVersion が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R30]', () async {
      remote.config = validConfig()..['termsVersion'] = '   ';
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の privacyVersion が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R31]', () async {
      remote.config = validConfig()..['privacyVersion'] = '';
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の termsUrl が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R32]', () async {
      remote.config = validConfig()..['termsUrl'] = '';
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の privacyUrl が数値の 1で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R33]', () async {
      remote.config = validConfig()..['privacyUrl'] = 1;
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の privacyVersion が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R41]', () async {
      remote.config = validConfig()..['privacyVersion'] = '   ';
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の termsUrl が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R42]', () async {
      remote.config = validConfig()..['termsUrl'] = '   ';
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の privacyUrl が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R43]', () async {
      remote.config = validConfig()..['privacyUrl'] = '';
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の privacyUrl が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R44]', () async {
      remote.config = validConfig()..['privacyUrl'] = '   ';
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });

    test('app_config/legal の termsUrl が数値の 1で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R45]', () async {
      remote.config = validConfig()..['termsUrl'] = 1;
      expectLeft<LegalConfig, NotFoundFailure>(await repo.fetchLegalConfig());
    });
  });

  group('fetchConsents', () {
    test('accounts/A の consents に terms 2026-01-01・privacy 2025-06-01 がある場合、Right(LegalConsents) にその版数が入る [LGL-R10]',
        () async {
      remote.consents = {
        'terms': {'version': '2026-01-01'},
        'privacy': {'version': '2025-06-01'}
      };
      expect(await repo.fetchConsents('A'),
          const Right<Failure, LegalConsents>(LegalConsents(termsVersion: '2026-01-01', privacyVersion: '2025-06-01')));
    });

    test('accounts/A が無い場合、Right(LegalConsents) の2つの版数がどちらも null になる [LGL-R11]', () async {
      remote.consents = null;
      expect(await repo.fetchConsents('A'),
          const Right<Failure, LegalConsents>(LegalConsents(termsVersion: null, privacyVersion: null)));
    });

    test('accounts/A に consents が無い場合、Right(LegalConsents) の2つの版数がどちらも null になる [LGL-R12]', () async {
      remote.consents = null;
      expect(await repo.fetchConsents('A'),
          const Right<Failure, LegalConsents>(LegalConsents(termsVersion: null, privacyVersion: null)));
    });

    test('consents に terms だけがある場合、termsVersion だけが入り privacyVersion は null になる [LGL-R13]', () async {
      remote.consents = {
        'terms': {'version': '2026-01-01'}
      };
      expect(await repo.fetchConsents('A'),
          const Right<Failure, LegalConsents>(LegalConsents(termsVersion: '2026-01-01', privacyVersion: null)));
    });

    test('consents.terms.version が数値で privacy.version が文字列の場合、termsVersion は null で privacyVersion に版数が入る [LGL-R14]',
        () async {
      remote.consents = {
        'terms': {'version': 20260101},
        'privacy': {'version': '2026-01-01'}
      };
      expect(await repo.fetchConsents('A'),
          const Right<Failure, LegalConsents>(LegalConsents(termsVersion: null, privacyVersion: '2026-01-01')));
    });

    test('端末のキャッシュには accounts/A があるがサーバーに接続できない場合、Left(NetworkFailure) になる [LGL-R15]', () async {
      remote.consents = {
        'terms': {'version': '2026-01-01'}
      };
      connectivity.setOnline(false);
      expectLeft<LegalConsents, NetworkFailure>(await repo.fetchConsents('A'));
    });

    test('consents の読み取りがエラーコード internal で失敗した場合、Left(UnknownFailure) になる [LGL-R16]', () async {
      remote.readError = FirebaseException(plugin: 'cloud_firestore', code: 'internal');
      expectLeft<LegalConsents, UnknownFailure>(await repo.fetchConsents('A'));
    });

    test('consents に privacy だけがある場合、privacyVersion だけが入り termsVersion は null になる [LGL-R25]', () async {
      remote.consents = {
        'privacy': {'version': '2026-01-01'}
      };
      expect(await repo.fetchConsents('A'),
          const Right<Failure, LegalConsents>(LegalConsents(termsVersion: null, privacyVersion: '2026-01-01')));
    });

    test('consents の読み取りがエラーコード permission-denied で失敗した場合、Left(UnknownFailure) になる [LGL-R28]', () async {
      remote.readError = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      expectLeft<LegalConsents, UnknownFailure>(await repo.fetchConsents('A'));
    });

    test('consents.terms に version が無く privacy.version がある場合、termsVersion は null で privacyVersion に版数が入る [LGL-R34]',
        () async {
      remote.consents = {
        'terms': <String, Object?>{},
        'privacy': {'version': '2026-01-01'}
      };
      expect(await repo.fetchConsents('A'),
          const Right<Failure, LegalConsents>(LegalConsents(termsVersion: null, privacyVersion: '2026-01-01')));
    });

    test('consents が Map でなく文字列 x の場合、Right(LegalConsents) の2つの版数がどちらも null になる [LGL-R35]', () async {
      remote.consents = 'x';
      expect(await repo.fetchConsents('A'),
          const Right<Failure, LegalConsents>(LegalConsents(termsVersion: null, privacyVersion: null)));
    });
  });

  group('accept', () {
    test('terms と privacy の版数を渡して関数が成功した場合、Right(accepted) になり2つの版数が引数として渡される [LGL-R17]', () async {
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expect(result, const Right<Failure, LegalAcceptResult>(LegalAcceptResult.accepted));
      expect(remote.acceptCalls, [
        {'terms': '2026-01-01', 'privacy': '2026-01-01'}
      ]);
    });

    test('privacyVersion が null で関数が成功した場合、Right(accepted) になり terms だけが引数として渡される [LGL-R18]', () async {
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: null);

      expect(result, const Right<Failure, LegalAcceptResult>(LegalAcceptResult.accepted));
      expect(remote.acceptCalls, [
        {'terms': '2026-01-01'}
      ]);
    });

    test('関数がエラーコード failed-precondition を返した場合、Right(outdated) になる [LGL-R19]', () async {
      remote.acceptError = FirebaseFunctionsException(message: 'x', code: 'failed-precondition');
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expect(result, const Right<Failure, LegalAcceptResult>(LegalAcceptResult.outdated));
    });

    test('関数がエラーコード unavailable を返した場合、Left(NetworkFailure) になる [LGL-R20]', () async {
      remote.acceptError = FirebaseFunctionsException(message: 'x', code: 'unavailable');
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expectLeft<LegalAcceptResult, NetworkFailure>(result);
    });

    test('関数がエラーコード deadline-exceeded を返した場合、Left(NetworkFailure) になる [LGL-R21]', () async {
      remote.acceptError = FirebaseFunctionsException(message: 'x', code: 'deadline-exceeded');
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expectLeft<LegalAcceptResult, NetworkFailure>(result);
    });

    test('関数がエラーコード unauthenticated を返した場合、Left(AuthFailure) になる [LGL-R22]', () async {
      remote.acceptError = FirebaseFunctionsException(message: 'x', code: 'unauthenticated');
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expectLeft<LegalAcceptResult, AuthFailure>(result);
    });

    test('関数がエラーコード internal を返した場合、Left(UnknownFailure) になる [LGL-R23]', () async {
      remote.acceptError = FirebaseFunctionsException(message: 'x', code: 'internal');
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expectLeft<LegalAcceptResult, UnknownFailure>(result);
    });

    test('termsVersion が null で関数が成功した場合、Right(accepted) になり privacy だけが引数として渡される [LGL-R26]', () async {
      final result = await repo.accept(termsVersion: null, privacyVersion: '2026-01-01');

      expect(result, const Right<Failure, LegalAcceptResult>(LegalAcceptResult.accepted));
      expect(remote.acceptCalls, [
        {'privacy': '2026-01-01'}
      ]);
    });

    test('関数がエラーコード permission-denied を返した場合、Left(UnknownFailure) になる [LGL-R36]', () async {
      remote.acceptError = FirebaseFunctionsException(message: 'x', code: 'permission-denied');
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expectLeft<LegalAcceptResult, UnknownFailure>(result);
    });

    test('関数がエラーコード not-found を返した場合、Left(UnknownFailure) になる [LGL-R37]', () async {
      remote.acceptError = FirebaseFunctionsException(message: 'x', code: 'not-found');
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expectLeft<LegalAcceptResult, UnknownFailure>(result);
    });

    test('関数がエラーコード invalid-argument を返した場合、Left(UnknownFailure) になる [LGL-R38]', () async {
      remote.acceptError = FirebaseFunctionsException(message: 'x', code: 'invalid-argument');
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expectLeft<LegalAcceptResult, UnknownFailure>(result);
    });

    test('関数がエラーコード cancelled を返した場合、Left(UnknownFailure) になる [LGL-R39]', () async {
      remote.acceptError = FirebaseFunctionsException(message: 'x', code: 'cancelled');
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expectLeft<LegalAcceptResult, UnknownFailure>(result);
    });

    test('関数の呼び出しが関数のエラー以外の例外で失敗した場合、Left(UnknownFailure) になる [LGL-R40]', () async {
      remote.acceptError = StateError('boom');
      final result = await repo.accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01');

      expectLeft<LegalAcceptResult, UnknownFailure>(result);
    });
  });
}
