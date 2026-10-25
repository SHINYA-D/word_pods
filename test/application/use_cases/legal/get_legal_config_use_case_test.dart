import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_pods/application/use_cases/legal/get_legal_config_use_case.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/domain/repositories/legal_repository.dart';

const _config = LegalConfig(
  termsVersion: '2026-01-01',
  privacyVersion: '2026-01-01',
  termsUrl: 'https://example.com/terms',
  privacyUrl: 'https://example.com/privacy',
);

// 仕様書 2.1 節の既定値（LegalConfig.defaults は使わず具体値で書く）
const _specDefaults = LegalConfig(
  termsVersion: '2026-10-12',
  privacyVersion: '2026-10-12',
  termsUrl: 'https://word-pods-web.web.app/terms',
  privacyUrl: 'https://word-pods-web.web.app/privacy',
);

class _FakeLegalRepository implements LegalRepository {
  _FakeLegalRepository(this.configResult);

  final Either<Failure, LegalConfig> configResult;

  @override
  Future<Either<Failure, LegalConfig>> fetchLegalConfig() async => configResult;

  @override
  Future<Either<Failure, LegalConsents>> fetchConsents(String userId) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LegalAcceptResult>> accept({
    String? termsVersion,
    String? privacyVersion,
  }) async =>
      throw UnimplementedError();
}

Future<Either<Failure, LegalConfig>> _run(Either<Failure, LegalConfig> result) =>
    GetLegalConfigUseCase(_FakeLegalRepository(result))();

void main() {
  group('GetLegalConfigUseCase.call', () {
    test('fetchLegalConfig が Right(LegalConfig) を返す場合、同じ LegalConfig の Right になる [LGL-G01]', () async {
      expect(await _run(const Right(_config)), const Right<Failure, LegalConfig>(_config));
    });

    test('fetchLegalConfig が Left(NotFoundFailure) を返す場合、既定値の LegalConfig の Right になる [LGL-G02]', () async {
      expect(await _run(const Left(Failure.notFound())), const Right<Failure, LegalConfig>(_specDefaults));
    });

    test('fetchLegalConfig が Left(NetworkFailure) を返す場合、Left(NetworkFailure) になる [LGL-G03]', () async {
      expect(await _run(const Left(Failure.network())), const Left<Failure, LegalConfig>(Failure.network()));
    });

    test('fetchLegalConfig が Left(UnknownFailure) を返す場合、Left(UnknownFailure) になる [LGL-G04]', () async {
      final r = await _run(const Left(Failure.unknown('x')));
      expect(r.isLeft(), isTrue);
      expect(r.getLeft().toNullable(), isA<UnknownFailure>());
    });

    test('privacyUrl だけが欠けて fetchLegalConfig が Left(NotFoundFailure) を返す場合、4項目すべて既定値の Right になる [LGL-G05]', () async {
      final r = (await _run(const Left(Failure.notFound()))).getOrElse((_) => throw StateError('Left'));
      expect(r.termsVersion, '2026-10-12');
      expect(r.privacyVersion, '2026-10-12');
      expect(r.termsUrl, 'https://word-pods-web.web.app/terms');
      expect(r.privacyUrl, 'https://word-pods-web.web.app/privacy');
    });
  });
}
