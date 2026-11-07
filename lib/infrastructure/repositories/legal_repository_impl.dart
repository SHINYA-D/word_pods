import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/domain/repositories/legal_repository.dart';
import 'package:word_pods/infrastructure/data_sources/network/connectivity_monitor.dart';
import 'package:word_pods/infrastructure/data_sources/remote/legal_remote_data_source.dart';

/// 規約への同意は同期の対象外のため、SQLite を通さず Firestore・Cloud Functions と直接やり取りする。
class LegalRepositoryImpl implements LegalRepository {
  LegalRepositoryImpl({
    required LegalRemoteDataSource remoteDataSource,
    required ConnectivityMonitor connectivityMonitor,
  })  : _remote = remoteDataSource,
        _connectivity = connectivityMonitor;

  final LegalRemoteDataSource _remote;
  final ConnectivityMonitor _connectivity;

  @override
  Future<Either<Failure, LegalConfig>> fetchLegalConfig() => _read(() async {
        final data = await _remote.fetchConfig();
        if (data == null) return const Left(Failure.notFound());
        final termsVersion = _text(data['termsVersion']);
        final privacyVersion = _text(data['privacyVersion']);
        final termsUrl = _text(data['termsUrl']);
        final privacyUrl = _text(data['privacyUrl']);
        if (termsVersion == null ||
            privacyVersion == null ||
            termsUrl == null ||
            privacyUrl == null) {
          return const Left(Failure.notFound());
        }
        return Right(LegalConfig(
          termsVersion: termsVersion,
          privacyVersion: privacyVersion,
          termsUrl: termsUrl,
          privacyUrl: privacyUrl,
        ));
      });

  @override
  Future<Either<Failure, LegalConsents>> fetchConsents(String userId) =>
      _read(() async {
        final consents = await _remote.fetchConsents(userId);
        return Right(LegalConsents(
          termsVersion: _version(consents, 'terms'),
          privacyVersion: _version(consents, 'privacy'),
        ));
      });

  @override
  Future<Either<Failure, LegalAcceptResult>> accept({
    String? termsVersion,
    String? privacyVersion,
  }) async {
    try {
      await _remote.accept({
        'terms': ?termsVersion,
        'privacy': ?privacyVersion,
      });
      return const Right(LegalAcceptResult.accepted);
    } on FirebaseFunctionsException catch (e) {
      switch (e.code) {
        case 'failed-precondition':
          return const Right(LegalAcceptResult.outdated);
        // 送り直しても記録は同じになる（関数は何度呼んでも同じ結果）ので、時間切れも通信エラーとして扱う
        case 'unavailable':
        case 'deadline-exceeded':
          return const Left(Failure.network());
        case 'unauthenticated':
          return const Left(Failure.auth());
        default:
          return Left(Failure.unknown(e.message ?? e.code));
      }
    } catch (e) {
      return Left(Failure.unknown(e.toString()));
    }
  }

  /// 接続できなければ `NetworkFailure`、それ以外の失敗は種類によらず `UnknownFailure`。
  Future<Either<Failure, T>> _read<T>(
      Future<Either<Failure, T>> Function() body) async {
    if (!await _connectivity.isOnline()) return const Left(Failure.network());
    try {
      return await body();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') return const Left(Failure.network());
      return Left(Failure.unknown(e.message ?? e.code));
    } catch (e) {
      return Left(Failure.unknown(e.toString()));
    }
  }

  /// 空白だけでない文字列なら、その値。
  String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  /// `consents.<document>.version` が文字列なら、その値。
  String? _version(Object? consents, String document) {
    if (consents is! Map) return null;
    final entry = consents[document];
    if (entry is! Map) return null;
    final version = entry['version'];
    return version is String ? version : null;
  }
}
