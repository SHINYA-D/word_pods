import 'package:fpdart/fpdart.dart';
import 'package:word_stock/core/error/failure.dart';
import 'package:word_stock/domain/repositories/account_deletion_repository.dart';
import 'package:word_stock/domain/repositories/auth_repository.dart';
import 'package:word_stock/domain/repositories/sync_repository.dart';

/// 他の端末での退会の確認の結果。
class WithdrawnCheckResult {
  const WithdrawnCheckResult({
    this.signedInWithdrawn,
    this.forcedSignOutCleared = false,
  });

  /// ログイン中の uid が退会済みなら、その uid（お知らせダイアログを出す）。
  final String? signedInWithdrawn;

  /// 強制ログアウトの記録の uid のログアウトをやり直して成功し、記録を消したか。
  final bool forcedSignOutCleared;
}

/// お知らせダイアログの OK でのログアウトの結果。
enum WithdrawnSignOutOutcome {
  /// ログアウトした
  signedOut,

  /// 2回とも失敗したため、強制ログアウトの記録を残した（アプリではログアウトしたものとして扱う）
  forced,
}

/// 他の端末で退会したアカウントを見つけ、端末内のデータを削除する。
///
/// - ログイン中のアカウントが退会済み: お知らせ → ログアウト → データの削除ダイアログの OK で削除
/// - ログアウト済みのアカウント（強制ログアウト済みを含む）が退会済み: 何も表示せずに削除
/// - この端末で退会処理をしている間（退会処理の記録がある間）は確認しない
class WithdrawnElsewhereUseCase {
  const WithdrawnElsewhereUseCase(
    this._repository,
    this._authRepository,
    this._syncRepository,
  );

  final AccountDeletionRepository _repository;
  final AuthRepository _authRepository;
  final SyncRepository _syncRepository;

  /// 強制ログアウトの記録の uid（無ければ null）。読めなければ null とする。
  Future<String?> findForcedSignOut() async =>
      (await _repository.findForcedSignOut())
          .fold((_) => null, (uid) => uid.toNullable());

  Future<Either<Failure, Unit>> clearForcedSignOut(String userId) =>
      _repository.clearForcedSignOut(userId);

  /// 退会処理の記録があるか。読めなければ、途中かもしれないので「ある」とする。
  Future<bool> isDeletionPending() async =>
      (await _repository.findPending()).fold((_) => true, (r) => r.isSome());

  Stream<Either<Failure, bool>> watchWithdrawn(String userId) =>
      _repository.watchWithdrawn(userId);

  /// 起動時・復帰時の確認。
  ///
  /// [signedInUserId] は Firebase 上のログイン中の uid、[forcedUserId] は強制ログアウトの記録の uid。
  /// 強制ログアウトの記録がある uid は、ログアウト済みとして扱い、ログアウトをやり直す。
  Future<WithdrawnCheckResult> check({
    required String? signedInUserId,
    required String? forcedUserId,
  }) async {
    if (await isDeletionPending()) return const WithdrawnCheckResult();

    var forcedSignOutCleared = false;
    String? signedIn = signedInUserId;
    if (forcedUserId != null && signedInUserId == forcedUserId) {
      signedIn = null;
      if ((await _authRepository.signOut()).isRight()) {
        await _repository.clearForcedSignOut(forcedUserId);
        forcedSignOutCleared = true;
      }
    }

    final localIds = (await _repository.findLocalUserIds())
        .getOrElse((_) => const <String>[]);
    final targets = <String>{...localIds, if (signedIn != null) signedIn};
    final withdrawn = <String>[];
    for (final userId in targets) {
      final result = await _repository.isWithdrawnOnServer(userId);
      if (result.getOrElse((_) => false)) withdrawn.add(userId);
    }

    // 確認している間に、この端末で退会処理が始まった場合は何もしない
    if (withdrawn.isNotEmpty && await isDeletionPending()) {
      return WithdrawnCheckResult(forcedSignOutCleared: forcedSignOutCleared);
    }

    final silent = [
      for (final userId in withdrawn)
        if (userId != signedIn) userId,
    ];
    if (silent.isNotEmpty) {
      // 失敗しても表示せず、次のきっかけでやり直す
      await _syncRepository.waitUntilIdle();
      // 同期を待つ間に、この端末で退会処理が始まっていたら削除しない（退会処理の記録を消さないため）
      if (!await isDeletionPending()) {
        await _repository.deleteLocalDataOfUsers(silent);
      }
    }

    return WithdrawnCheckResult(
      signedInWithdrawn:
          signedIn != null && withdrawn.contains(signedIn) ? signedIn : null,
      forcedSignOutCleared: forcedSignOutCleared,
    );
  }

  /// お知らせダイアログの OK。未送信の変更は送らずにログアウトする。
  /// 失敗したらもう一度ログアウトし、それでも失敗したら強制ログアウトの記録を残す。
  Future<WithdrawnSignOutOutcome> signOut(String userId) async {
    if ((await _authRepository.signOut()).isRight()) {
      return WithdrawnSignOutOutcome.signedOut;
    }
    if ((await _authRepository.signOut()).isRight()) {
      return WithdrawnSignOutOutcome.signedOut;
    }
    await _repository.markForcedSignOut(userId);
    return WithdrawnSignOutOutcome.forced;
  }

  /// データの削除ダイアログの OK。実行中の同期が終わるのを待ってから、まとめて削除する。
  Future<Either<Failure, Unit>> deleteLocal(List<String> userIds) async {
    await _syncRepository.waitUntilIdle();
    return _repository.deleteLocalDataOfUsers(userIds);
  }
}
