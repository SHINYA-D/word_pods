import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/account_deletion_request.dart';
import 'package:word_pods/domain/repositories/account_deletion_repository.dart';
import 'package:word_pods/infrastructure/data_sources/local/account_deletion_local_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/network/connectivity_monitor.dart';
import 'package:word_pods/infrastructure/data_sources/remote/account_deletion_remote_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/remote/withdrawn_account_remote_data_source.dart';

class AccountDeletionRepositoryImpl implements AccountDeletionRepository {
  AccountDeletionRepositoryImpl({
    required AccountDeletionLocalDataSource localDataSource,
    required AccountDeletionRemoteDataSource remoteDataSource,
    required WithdrawnAccountRemoteDataSource withdrawnRemoteDataSource,
    required ConnectivityMonitor connectivityMonitor,
  })  : _local = localDataSource,
        _remote = remoteDataSource,
        _withdrawn = withdrawnRemoteDataSource,
        _connectivity = connectivityMonitor;

  final AccountDeletionLocalDataSource _local;
  final AccountDeletionRemoteDataSource _remote;
  final WithdrawnAccountRemoteDataSource _withdrawn;
  final ConnectivityMonitor _connectivity;

  @override
  Future<Either<Failure, Option<AccountDeletionRequest>>> findPending() =>
      _guard(() async => Option.fromNullable(await _local.findAny()));

  @override
  Future<Either<Failure, Unit>> markRequested(String userId) =>
      _guard(() async => _unit(await _local.markRequested(userId)));

  @override
  Future<Either<Failure, Unit>> markServerDone(String userId) =>
      _guard(() async => _unit(await _local.markServerDone(userId)));

  @override
  Future<Either<Failure, Unit>> clearRequest(String userId) =>
      _guard(() async => _unit(await _local.clear(userId)));

  @override
  Future<Either<Failure, Unit>> deleteLocalData(String userId) =>
      _guard(() async => _unit(await _local.deleteUserData(userId)));

  @override
  Future<Either<Failure, Unit>> requestServerDeletion() async {
    if (!await _connectivity.isOnline()) return const Left(Failure.network());
    try {
      await _remote.deleteAccount();
      return const Right(unit);
    } on FirebaseFunctionsException catch (e) {
      return Left(_mapFunctionsException(e));
    } catch (e) {
      return Left(Failure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> findLocalUserIds() =>
      _guard(_local.findUserIds);

  @override
  Future<Either<Failure, bool>> isWithdrawnOnServer(String userId) async {
    if (!await _connectivity.isOnline()) return const Left(Failure.network());
    return _guard(() => _withdrawn.isWithdrawn(userId));
  }

  @override
  Stream<Either<Failure, bool>> watchWithdrawn(String userId) => _withdrawn
      .watch(userId)
      .map<Either<Failure, bool>>((withdrawn) => Right(withdrawn))
      .transform(_toFailure());

  @override
  Future<Either<Failure, Unit>> deleteLocalDataOfUsers(List<String> userIds) =>
      _guard(() async => _unit(await _local.deleteUsersData(userIds)));

  @override
  Future<Either<Failure, Unit>> markForcedSignOut(String userId) =>
      _guard(() async => _unit(await _local.markForcedSignOut(userId)));

  @override
  Future<Either<Failure, Option<String>>> findForcedSignOut() =>
      _guard(() async => Option.fromNullable(await _local.findForcedSignOut()));

  @override
  Future<Either<Failure, Unit>> clearForcedSignOut(String userId) =>
      _guard(() async => _unit(await _local.clearForcedSignOut(userId)));

  /// ストリームのエラーを `Left(UnknownFailure)` の通知に変える（ストリームは止めない）。
  StreamTransformer<Either<Failure, bool>, Either<Failure, bool>> _toFailure() =>
      StreamTransformer.fromHandlers(
        handleError: (error, _, sink) =>
            sink.add(Left(Failure.unknown(error.toString()))),
      );

  /// `unavailable` は関数に届かなかったことが確か。それ以外（時間切れを含む）は届いたか分からない。
  Failure _mapFunctionsException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unavailable':
        return const Failure.network();
      case 'unauthenticated':
        return const Failure.auth();
      case 'failed-precondition':
        return const Failure.recentLoginRequired();
      default:
        return Failure.unknown(e.message ?? e.code);
    }
  }

  Unit _unit(void _) => unit;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } catch (e) {
      return Left(Failure.unknown(e.toString()));
    }
  }
}
