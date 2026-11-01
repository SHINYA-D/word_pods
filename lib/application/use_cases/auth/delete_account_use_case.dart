import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/account_deletion_request.dart';
import 'package:word_pods/domain/repositories/account_deletion_repository.dart';
import 'package:word_pods/domain/repositories/auth_repository.dart';
import 'package:word_pods/domain/repositories/sync_repository.dart';

/// 退会処理の結果。
enum AccountDeletionOutcome {
  /// 退会処理をしていない（記録が無い）
  none,

  /// サーバー・端末内ともに削除が終わった
  completed,

  /// 関数に届かず、何も削除していない
  notSent,

  /// 途中で止まっている（再試行で続きを行う）
  pending,

  /// 途中で止まっていて、続きを行うには本人確認のし直しが必要（記録は残っている）
  reauthRequired,
}

/// 退会する。
///
/// 1. 記録を `requested` にし、実行中の同期が終わるのを待つ（記録がある間は同期しない）
/// 2. 関数 `deleteAccount` を呼ぶ（サーバー側で Firestore → Authentication の順に削除）
/// 3. 成功したら記録を `serverDone` にし、端末内のデータと記録を削除してログアウトする
///
/// 途中で止まったら記録が残り、[resume] で続きから行う。
class DeleteAccountUseCase {
  const DeleteAccountUseCase(
    this._repository,
    this._authRepository,
    this._syncRepository,
  );

  final AccountDeletionRepository _repository;
  final AuthRepository _authRepository;
  final SyncRepository _syncRepository;

  /// 起動時の確認。記録を読めなければ、途中かもしれないので [AccountDeletionOutcome.pending] にする。
  Future<AccountDeletionOutcome> checkPending() async {
    final result = await _repository.findPending();
    return result.fold(
      (_) => AccountDeletionOutcome.pending,
      (request) => request.isSome()
          ? AccountDeletionOutcome.pending
          : AccountDeletionOutcome.none,
    );
  }

  /// 確認ダイアログ2回のあとの退会処理。
  Future<AccountDeletionOutcome> withdraw(String userId) async {
    final marked = await _repository.markRequested(userId);
    if (marked.isLeft()) return AccountDeletionOutcome.notSent;
    await _syncRepository.waitUntilIdle();

    final failure =
        (await _repository.requestServerDeletion()).getLeft().toNullable();
    if (failure == null) return _finishLocal(userId, serverConfirmed: true);
    // 届いたか分からなければ、記録を残して再試行で続きを行う。
    // 本人確認の期限切れは、関数が何も削除せずに返すので、届かなかったときと同じに扱う
    if (failure is! NetworkFailure &&
        failure is! AuthFailure &&
        failure is! RecentLoginRequiredFailure) {
      return AccountDeletionOutcome.pending;
    }
    // 何も削除していないので記録を消す。消せなければ記録が残るので再試行で退会を進める
    final cleared = await _repository.clearRequest(userId);
    return cleared.isRight()
        ? AccountDeletionOutcome.notSent
        : AccountDeletionOutcome.pending;
  }

  /// 途中で止まった退会処理の続き。[currentUserId] はログイン中のユーザー（いなければ null）。
  ///
  /// 記録が残っている間は同期が止まっているため、[withdraw] と違って同期の完了を待たない。
  Future<AccountDeletionOutcome> resume(String? currentUserId) async {
    final found = await _repository.findPending();
    if (found.isLeft()) return AccountDeletionOutcome.pending;
    final request = found.toNullable()?.toNullable();
    if (request == null) return AccountDeletionOutcome.none;

    final userId = request.userId;
    if (request.status == AccountDeletionStatus.serverDone) {
      return _finishLocal(userId);
    }
    if (currentUserId == null) {
      // ログインしていない＝サーバー側でユーザーまで削除が終わっている
      return _finishLocal(userId);
    }
    if (currentUserId != userId) {
      // 関数を呼ぶとログイン中の別のユーザーを削除してしまうため、ログアウトしてから端末内を削除する
      await _authRepository.signOut();
      return _finishLocal(userId);
    }

    final failure =
        (await _repository.requestServerDeletion()).getLeft().toNullable();
    if (failure == null) return _finishLocal(userId, serverConfirmed: true);
    // ログイン情報が無効＝サーバー側でユーザーまで削除が終わっている
    if (failure is AuthFailure) return _finishLocal(userId);
    // 本人確認の期限切れ＝関数は何も削除していない。本人確認をし直してから呼び直す
    if (failure is RecentLoginRequiredFailure) {
      return AccountDeletionOutcome.reauthRequired;
    }
    return AccountDeletionOutcome.pending;
  }

  /// サーバー側の削除が終わったあとの処理。
  ///
  /// 関数の成功を受け取ったとき（[serverConfirmed]）だけ記録を `serverDone` にする。
  /// ログインしていない・ログイン情報が無効といった推定の経路では記録を変えない
  /// （次の再試行も同じ経路を通り、関数を呼ばずに端末内を削除する）。
  Future<AccountDeletionOutcome> _finishLocal(
    String userId, {
    bool serverConfirmed = false,
  }) async {
    if (serverConfirmed) {
      // 記録を更新できなくても、端末内の削除で記録ごと消えるので続ける
      await _repository.markServerDone(userId);
    }
    final deleted = await _repository.deleteLocalData(userId);
    if (deleted.isLeft()) return AccountDeletionOutcome.pending;
    // サーバー側のユーザーは削除済みなので、ログアウトに失敗しても完了とする
    await _authRepository.signOut();
    return AccountDeletionOutcome.completed;
  }
}
