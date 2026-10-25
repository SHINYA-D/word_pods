import 'package:fpdart/fpdart.dart';
import 'package:word_pods/application/use_cases/legal/get_legal_config_use_case.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/domain/repositories/legal_repository.dart';

/// 同意が必要かを判定する。現行の版数（`app_config/legal` が無ければ既定値）と同意済みの版数を、
/// 文書ごとに文字列の一致で比べる（日付の新旧は比べない）。
class CheckLegalConsentUseCase {
  const CheckLegalConsentUseCase(this._repository, this._getLegalConfig);

  final LegalRepository _repository;
  final GetLegalConfigUseCase _getLegalConfig;

  Future<Either<Failure, LegalConsentRequirement>> call(String userId) async {
    final configResult = await _getLegalConfig();
    return configResult.fold(Left.new, (config) async {
      final consentsResult = await _repository.fetchConsents(userId);
      return consentsResult.map(
        (consents) => LegalConsentRequirement(
          termsRequired: consents.termsVersion != config.termsVersion,
          privacyRequired: consents.privacyVersion != config.privacyVersion,
          config: config,
        ),
      );
    });
  }
}
