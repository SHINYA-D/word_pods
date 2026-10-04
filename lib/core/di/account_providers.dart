import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_stock/application/use_cases/account/get_is_developer_use_case.dart';
import 'package:word_stock/core/di/repository_providers.dart';

part 'account_providers.g.dart';

@Riverpod(keepAlive: true)
GetIsDeveloperUseCase getIsDeveloperUseCase(Ref ref) =>
    GetIsDeveloperUseCase(ref.watch(accountRepositoryProvider));
