import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_stock/application/use_cases/legal/check_legal_consent_use_case.dart';
import 'package:word_stock/application/use_cases/legal/get_legal_config_use_case.dart';
import 'package:word_stock/core/error/failure.dart';
import 'package:word_stock/domain/entities/legal_consent.dart';
import 'package:word_stock/domain/repositories/legal_repository.dart';

const _config = LegalConfig(
  termsVersion: '2026-01-01',
  privacyVersion: '2026-01-01',
  termsUrl: 'https://example.com/terms',
  privacyUrl: 'https://example.com/privacy',
);

class _FakeLegalRepository implements LegalRepository {
  _FakeLegalRepository({
    this.configResult = const Right(_config),
    this.consentsResult = const Right(LegalConsents()),
  });

  final Either<Failure, LegalConfig> configResult;
  final Either<Failure, LegalConsents> consentsResult;
  int fetchLegalConfigCalls = 0;
  final List<String> fetchConsentsArgs = [];

  @override
  Future<Either<Failure, LegalConfig>> fetchLegalConfig() async {
    fetchLegalConfigCalls++;
    return configResult;
  }

  @override
  Future<Either<Failure, LegalConsents>> fetchConsents(String userId) async {
    fetchConsentsArgs.add(userId);
    return consentsResult;
  }

  @override
  Future<Either<Failure, LegalAcceptResult>> accept({
    String? termsVersion,
    String? privacyVersion,
  }) async =>
      throw UnimplementedError();
}

Future<Either<Failure, LegalConsentRequirement>> _run(
  _FakeLegalRepository repo,
) =>
    _useCase(repo)('A');

CheckLegalConsentUseCase _useCase(_FakeLegalRepository repo) =>
    CheckLegalConsentUseCase(repo, GetLegalConfigUseCase(repo));

_FakeLegalRepository _withConsents(String? terms, String? privacy) => _FakeLegalRepository(
      consentsResult: Right(
        LegalConsents(termsVersion: terms, privacyVersion: privacy),
      ),
    );

void main() {
  group('CheckLegalConsentUseCase.call', () {
    test('同意済みの版数が両方とも現行と一致する場合、どちらも同意不要になる [LGL-K01]', () async {
      final r = (await _run(_withConsents('2026-01-01', '2026-01-01'))).getOrElse((_) => throw StateError('Left'));
      expect(r.termsRequired, false);
      expect(r.privacyRequired, false);
    });

    test('利用規約だけ版数が違う場合、利用規約だけ同意が必要になる [LGL-K02]', () async {
      final r = (await _run(_withConsents('2025-06-01', '2026-01-01'))).getOrElse((_) => throw StateError('Left'));
      expect(r.termsRequired, true);
      expect(r.privacyRequired, false);
    });

    test('プライバシーポリシーだけ版数が違う場合、プライバシーポリシーだけ同意が必要になる [LGL-K03]', () async {
      final r = (await _run(_withConsents('2026-01-01', '2025-06-01'))).getOrElse((_) => throw StateError('Left'));
      expect(r.termsRequired, false);
      expect(r.privacyRequired, true);
    });

    test('同意の記録が両方とも無い場合、どちらも同意が必要になる [LGL-K04]', () async {
      final r = (await _run(_withConsents(null, null))).getOrElse((_) => throw StateError('Left'));
      expect(r.termsRequired, true);
      expect(r.privacyRequired, true);
    });

    test('同意済みの利用規約の版数が現行より新しい日付の場合、文字列が違うので同意が必要になる [LGL-K05]', () async {
      final r = (await _run(_withConsents('2026-02-01', '2026-01-01'))).getOrElse((_) => throw StateError('Left'));
      expect(r.termsRequired, true);
      expect(r.privacyRequired, false);
    });

    test('同意済みの利用規約の版数が 2026-1-1 の場合、文字列が違うので同意が必要になる [LGL-K06]', () async {
      final r = (await _run(_withConsents('2026-1-1', '2026-01-01'))).getOrElse((_) => throw StateError('Left'));
      expect(r.termsRequired, true);
    });

    test('判定に成功した場合、結果の config が読み取った現行の規約の情報と等しくなる [LGL-K07]', () async {
      final r = (await _run(_withConsents('2026-01-01', '2025-06-01'))).getOrElse((_) => throw StateError('Left'));
      expect(r.config, _config);
    });

    for (final entry in <String, (Failure, String)>{
      'LGL-K09': (const Failure.network(), 'NetworkFailure'),
      'LGL-K10': (const Failure.unknown('x'), 'UnknownFailure'),
    }.entries) {
      test('現行の規約の情報の取得が ${entry.value.$2} で失敗した場合、Left(${entry.value.$2}) になり同意済みの版数は読まれない [${entry.key}]', () async {
        final repo = _FakeLegalRepository(configResult: Left(entry.value.$1));
        final result = await _run(repo);
        expect(result, Left<Failure, LegalConsentRequirement>(entry.value.$1));
        expect(repo.fetchConsentsArgs, isEmpty);
      });
    }

    test('同意済みの版数の取得が NetworkFailure で失敗した場合、Left(NetworkFailure) になる [LGL-K11]', () async {
      final repo = _FakeLegalRepository(consentsResult: const Left(Failure.network()));
      expect(await _run(repo), const Left<Failure, LegalConsentRequirement>(Failure.network()));
    });

    test('同意済みの版数の取得が UnknownFailure で失敗した場合、Left(UnknownFailure) になる [LGL-K12]', () async {
      final repo = _FakeLegalRepository(consentsResult: const Left(Failure.unknown('x')));
      expect(await _run(repo), const Left<Failure, LegalConsentRequirement>(Failure.unknown('x')));
    });

    test("call('A') を呼んだ場合、fetchConsents が1回 'A' を引数に呼ばれる [LGL-K13]", () async {
      final repo = _withConsents(null, null);
      await _useCase(repo)('A');
      expect(repo.fetchConsentsArgs, ['A']);
    });

    const defaultConfig = LegalConfig(
      termsVersion: '2026-10-12',
      privacyVersion: '2026-10-12',
      termsUrl: 'https://word-stock-web.web.app/terms',
      privacyUrl: 'https://word-stock-web.web.app/privacy',
    );

    _FakeLegalRepository notFoundWith(String? terms, String? privacy) => _FakeLegalRepository(
          configResult: const Left(Failure.notFound()),
          consentsResult: Right(
            LegalConsents(termsVersion: terms, privacyVersion: privacy),
          ),
        );

    test('現行の規約の情報が無く同意の記録も無い場合、どちらも同意が必要になり config は既定値になる [LGL-K14]', () async {
      final r = (await _run(notFoundWith(null, null))).getOrElse((_) => throw StateError('Left'));
      expect(r.termsRequired, true);
      expect(r.privacyRequired, true);
      expect(r.config, defaultConfig);
    });

    test('現行の規約の情報が無く同意済みの版数が既定値の 2026-10-12 と一致する場合、どちらも同意不要になる [LGL-K15]', () async {
      final r = (await _run(notFoundWith('2026-10-12', '2026-10-12'))).getOrElse((_) => throw StateError('Left'));
      expect(r.termsRequired, false);
      expect(r.privacyRequired, false);
    });

    test("現行の規約の情報が無い状態で call('A') を呼んだ場合、fetchConsents が1回 'A' を引数に呼ばれる [LGL-K16]", () async {
      final repo = notFoundWith(null, null);
      await _useCase(repo)('A');
      expect(repo.fetchConsentsArgs, ['A']);
    });

    test('現行の規約の情報の一部の項目が欠けている場合、config は4項目すべて既定値になる [LGL-K17]', () async {
      final r = (await _run(notFoundWith(null, null))).getOrElse((_) => throw StateError('Left'));
      expect(r.config.termsVersion, '2026-10-12');
      expect(r.config.privacyVersion, '2026-10-12');
      expect(r.config.termsUrl, 'https://word-stock-web.web.app/terms');
      expect(r.config.privacyUrl, 'https://word-stock-web.web.app/privacy');
    });
  });
}
