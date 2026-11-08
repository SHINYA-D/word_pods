import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/core/utils/crash_reporting.dart';
import 'package:word_pods/domain/entities/flashcard_result.dart';
import 'package:word_pods/domain/repositories/flashcard_result_repository.dart';
import 'package:word_pods/domain/services/crash_reporter.dart';
import 'package:word_pods/infrastructure/data_sources/local/database_helper.dart';
import 'package:word_pods/infrastructure/data_sources/local/flashcard_result_local_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/local/folder_local_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/local/sync_queue_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/local/tables/flashcard_result_table.dart';
import 'package:word_pods/infrastructure/sync/sync_service.dart';

/// 読み取りはローカルだけから行う。登録は、オンライン・オフラインに関係なく
/// ローカルへの保存とキューへの登録を同じトランザクションで行い、その後に送信を依頼する。
class FlashcardResultRepositoryImpl implements FlashcardResultRepository {
  FlashcardResultRepositoryImpl({
    required FlashcardResultLocalDataSource localDataSource,
    required FolderLocalDataSource folderLocalDataSource,
    required SyncQueueDataSource syncQueueDataSource,
    required this._dbHelper,
    required this._onLocalChanged,
    this._crashReporter,
  })  : _local = localDataSource,
        _folderLocal = folderLocalDataSource,
        _syncQueue = syncQueueDataSource;

  final FlashcardResultLocalDataSource _local;
  final FolderLocalDataSource _folderLocal;
  final SyncQueueDataSource _syncQueue;
  final DatabaseHelper _dbHelper;
  final void Function() _onLocalChanged;
  final CrashReporter? _crashReporter;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<FlashcardResult>>> getFlashcardResults({
    required String userId,
    String? folderId,
  }) async {
    try {
      final results = await _local.findByUserId(userId, folderId: folderId);
      return Right(results);
    } catch (e, stack) {
      return Left(reportUnknownFailure(_crashReporter, e, stack));
    }
  }

  @override
  Future<Either<Failure, FlashcardResult>> saveFlashcardResult({
    required String userId,
    required String folderId,
    required int totalCount,
    required int correctCount,
  }) async {
    try {
      final now = DateTime.now();
      final result = FlashcardResult(
        id: _uuid.v4(),
        folderId: folderId,
        totalCount: totalCount,
        correctCount: correctCount,
        date: now,
        updatedAt: now,
      );
      final db = await _dbHelper.database;
      final saved = await db.transaction((txn) async {
        if (await _folderLocal.findActive(txn, folderId, userId: userId) == null) {
          return false;
        }
        await _local.save(txn, result, userId: userId, syncStatus: 'pending');
        await _syncQueue.enqueueInTransaction(
          txn,
          operation: SyncService.operationFor(isDelete: false),
          tableName: FlashcardResultTable.tableName,
          recordId: result.id,
          userId: userId,
        );
        return true;
      });
      if (!saved) return const Left(Failure.notFound());
      _onLocalChanged();
      return Right(result);
    } catch (e, stack) {
      return Left(reportUnknownFailure(_crashReporter, e, stack));
    }
  }
}
