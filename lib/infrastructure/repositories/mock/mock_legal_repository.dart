import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/domain/repositories/legal_repository.dart';

/// 開発用実装。最初は未同意で、同意すると起動している間だけ同意済みになる（同意ダイアログを確かめられるように）。
class MockLegalRepository implements LegalRepository {
  static const _config = LegalConfig(
    termsVersion: '2026-01-01',
    privacyVersion: '2026-01-01',
    termsUrl: 'https://word-pods-web.web.app/terms',
    privacyUrl: 'https://word-pods-web.web.app/privacy',
  );

  LegalConsents _consents = const LegalConsents();

  @override
  Future<Either<Failure, LegalConfig>> fetchLegalConfig() async =>
      const Right(_config);

  @override
  Future<Either<Failure, LegalConsents>> fetchConsents(String userId) async =>
      Right(_consents);

  @override
  Future<Either<Failure, LegalAcceptResult>> accept({
    String? termsVersion,
    String? privacyVersion,
  }) async {
    _consents = LegalConsents(
      termsVersion: termsVersion ?? _consents.termsVersion,
      privacyVersion: privacyVersion ?? _consents.privacyVersion,
    );
    return const Right(LegalAcceptResult.accepted);
  }
}
