import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/core/di/firebase_providers.dart';
import 'package:word_pods/core/di/local_data_source_providers.dart';
import 'package:word_pods/core/di/sync_providers.dart';
import 'package:word_pods/domain/repositories/account_deletion_repository.dart';
import 'package:word_pods/domain/repositories/account_repository.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/repositories/folder_repository.dart';
import 'package:word_pods/domain/repositories/legal_repository.dart';
import 'package:word_pods/domain/repositories/reauthentication_repository.dart';
import 'package:word_pods/domain/repositories/sample_repository.dart';
import 'package:word_pods/domain/repositories/settings_repository.dart';
import 'package:word_pods/domain/repositories/flashcard_result_repository.dart';
import 'package:word_pods/domain/repositories/word_repository.dart';
import 'package:word_pods/infrastructure/repositories/account_deletion_repository_impl.dart';
import 'package:word_pods/infrastructure/repositories/account_repository_impl.dart';
import 'package:word_pods/infrastructure/repositories/auth_repository_impl.dart';
import 'package:word_pods/infrastructure/repositories/folder_repository_impl.dart';
import 'package:word_pods/infrastructure/repositories/legal_repository_impl.dart';
import 'package:word_pods/infrastructure/repositories/reauthentication_repository_impl.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_account_deletion_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_account_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_auth_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_folder_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_legal_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_reauthentication_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_sample_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_settings_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_flashcard_result_repository.dart';
import 'package:word_pods/infrastructure/repositories/mock/mock_word_repository.dart';
import 'package:word_pods/infrastructure/repositories/settings_repository_impl.dart';
import 'package:word_pods/infrastructure/repositories/flashcard_result_repository_impl.dart';
import 'package:word_pods/infrastructure/repositories/word_repository_impl.dart';

part 'repository_providers.g.dart';

// ---------------------------------------------------------------
// モード切り替えフラグ
// ---------------------------------------------------------------
const kUseMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: false);

/// 登録・編集・削除の後に送信を依頼する
void Function() _onLocalChanged(Ref ref) =>
    () => ref.read(autoSyncServiceProvider).onLocalChanged();

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  if (kUseMocks) return MockAuthRepository();
  return AuthRepositoryImpl(ref.watch(firebaseAuthDataSourceProvider));
}

@Riverpod(keepAlive: true)
FolderRepository folderRepository(Ref ref) {
  if (kUseMocks) return MockFolderRepository();
  return FolderRepositoryImpl(
    localDataSource: ref.watch(folderLocalDataSourceProvider),
    wordLocalDataSource: ref.watch(wordLocalDataSourceProvider),
    flashcardResultLocalDataSource: ref.watch(flashcardResultLocalDataSourceProvider),
    syncQueueDataSource: ref.watch(syncQueueDataSourceProvider),
    dbHelper: ref.watch(databaseHelperProvider),
    onLocalChanged: _onLocalChanged(ref),
  );
}

@Riverpod(keepAlive: true)
WordRepository wordRepository(Ref ref) {
  if (kUseMocks) return MockWordRepository();
  return WordRepositoryImpl(
    localDataSource: ref.watch(wordLocalDataSourceProvider),
    folderLocalDataSource: ref.watch(folderLocalDataSourceProvider),
    syncQueueDataSource: ref.watch(syncQueueDataSourceProvider),
    dbHelper: ref.watch(databaseHelperProvider),
    onLocalChanged: _onLocalChanged(ref),
  );
}

@Riverpod(keepAlive: true)
FlashcardResultRepository flashcardResultRepository(Ref ref) {
  if (kUseMocks) return MockFlashcardResultRepository();
  return FlashcardResultRepositoryImpl(
    localDataSource: ref.watch(flashcardResultLocalDataSourceProvider),
    folderLocalDataSource: ref.watch(folderLocalDataSourceProvider),
    syncQueueDataSource: ref.watch(syncQueueDataSourceProvider),
    dbHelper: ref.watch(databaseHelperProvider),
    onLocalChanged: _onLocalChanged(ref),
  );
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  if (kUseMocks) return MockSettingsRepository();
  return SettingsRepositoryImpl(
    localDataSource: ref.watch(settingsLocalDataSourceProvider),
    syncQueueDataSource: ref.watch(syncQueueDataSourceProvider),
    dbHelper: ref.watch(databaseHelperProvider),
    onLocalChanged: _onLocalChanged(ref),
  );
}

@Riverpod(keepAlive: true)
AccountDeletionRepository accountDeletionRepository(Ref ref) {
  if (kUseMocks) return MockAccountDeletionRepository();
  return AccountDeletionRepositoryImpl(
    localDataSource: ref.watch(accountDeletionLocalDataSourceProvider),
    remoteDataSource: ref.watch(accountDeletionRemoteDataSourceProvider),
    withdrawnRemoteDataSource: ref.watch(withdrawnAccountRemoteDataSourceProvider),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
  );
}

@Riverpod(keepAlive: true)
ReauthenticationRepository reauthenticationRepository(Ref ref) {
  if (kUseMocks) return MockReauthenticationRepository();
  return ReauthenticationRepositoryImpl(
    ref.watch(reauthenticationRemoteDataSourceProvider),
  );
}

@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) {
  if (kUseMocks) return MockAccountRepository();
  return AccountRepositoryImpl(
    remoteDataSource: ref.watch(accountRemoteDataSourceProvider),
  );
}

@Riverpod(keepAlive: true)
LegalRepository legalRepository(Ref ref) {
  if (kUseMocks) return MockLegalRepository();
  return LegalRepositoryImpl(
    remoteDataSource: ref.watch(legalRemoteDataSourceProvider),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
  );
}

// テストパイプライン検証用。本実装を持たないため常に Mock を返す
@Riverpod(keepAlive: true)
SampleRepository sampleRepository(Ref ref) => MockSampleRepository();
