import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/application/use_cases/account/get_is_developer_use_case.dart';
import 'package:word_pods/core/di/repository_providers.dart';

part 'account_providers.g.dart';

@Riverpod(keepAlive: true)
GetIsDeveloperUseCase getIsDeveloperUseCase(Ref ref) =>
    GetIsDeveloperUseCase(ref.watch(accountRepositoryProvider));
