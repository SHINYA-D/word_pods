import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/domain/repositories/legal_repository.dart';

/// 現行の規約の情報。`app_config/legal` が無い（項目が欠けている）ときは既定値を返す
/// （設定データが無いことで同意を素通りさせないため）。
class GetLegalConfigUseCase {
  const GetLegalConfigUseCase(this._repository);

  final LegalRepository _repository;

  Future<Either<Failure, LegalConfig>> call() async =>
      (await _repository.fetchLegalConfig()).fold(
        (failure) => failure is NotFoundFailure
            ? const Right(LegalConfig.defaults)
            : Left(failure),
        Right.new,
      );
}
