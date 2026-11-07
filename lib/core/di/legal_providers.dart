import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/application/use_cases/legal/check_legal_consent_use_case.dart';
import 'package:word_pods/application/use_cases/legal/get_legal_config_use_case.dart';
import 'package:word_pods/core/di/repository_providers.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';

part 'legal_providers.g.dart';

@Riverpod(keepAlive: true)
GetLegalConfigUseCase getLegalConfigUseCase(Ref ref) =>
    GetLegalConfigUseCase(ref.watch(legalRepositoryProvider));

@Riverpod(keepAlive: true)
CheckLegalConsentUseCase checkLegalConsentUseCase(Ref ref) =>
    CheckLegalConsentUseCase(
      ref.watch(legalRepositoryProvider),
      ref.watch(getLegalConfigUseCaseProvider),
    );

/// 新規登録画面に表示して、同意の送信に使う規約の情報。
/// 読めなかったとき（オフライン・読み取りの失敗）も既定値を使う（登録の後の判定で正しい版数に同意し直せるため）。
@riverpod
Future<LegalConfig> signUpLegalConfig(Ref ref) async =>
    (await ref.read(getLegalConfigUseCaseProvider).call())
        .getOrElse((_) => LegalConfig.defaults);
