import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/application/use_cases/auth/withdrawn_elsewhere_use_case.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/presentation/settings/account_deletion_state.dart';
import 'package:word_pods/presentation/settings/account_deletion_view_model.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_state.dart';

part 'withdrawn_elsewhere_view_model.g.dart';

/// 他の端末での退会。起動時・復帰時の確認と、ログイン中の uid の退会済みの記録の監視を行う。
///
/// ログイン中のアカウントが退会済みなら、お知らせ → ログアウト → データの削除ダイアログの順に進める。
/// ログアウト済みのアカウントは、確認の中で何も表示せずに削除する（[WithdrawnElsewhereUseCase.check]）。
@Riverpod(keepAlive: true)
class WithdrawnElsewhereViewModel extends _$WithdrawnElsewhereViewModel {
  StreamSubscription<Either<Failure, bool>>? _watch;
  String? _watchingUserId;

  /// 確認の途中に監視が退会済みを通知した uid（確認の結果が出た後に反映する）
  String? _notifiedWhileChecking;
  bool _signingOut = false;
  Future<void>? _initializing;

  WithdrawnElsewhereUseCase get _useCase =>
      ref.read(withdrawnElsewhereUseCaseProvider);

  @override
  WithdrawnElsewhereState build() {
    ref.onDispose(() => _watch?.cancel());
    ref.listen(currentUserProvider, (_, next) {
      if (state.forcedLoaded) _onUserChanged(next?.id);
    });
    return const WithdrawnElsewhereState();
  }

  /// 起動時に呼ぶ（何度呼んでも読み込みは1回）。強制ログアウトの記録を読み、ログイン中の uid の監視を始める。
  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    String? forced;
    try {
      forced = await _useCase.findForcedSignOut();
    } catch (_) {
      // 依存の生成（Firebase の初期化など）に失敗しても起動を止めず、記録は無いものとして起動する
    }
    state = state.copyWith(forcedUserId: forced, forcedLoaded: true);
    _onUserChanged(ref.read(currentUserProvider)?.id);
  }

  /// 起動時・復帰時の確認。
  Future<void> check() async {
    if (state.phase != WithdrawnElsewherePhase.idle) return;
    state = state.copyWith(phase: WithdrawnElsewherePhase.checking);
    _notifiedWhileChecking = null;

    final result = await _useCase.check(
      signedInUserId: ref.read(currentUserProvider)?.id,
      forcedUserId: state.forcedUserId,
    );

    var notify = result.signedInWithdrawn;
    final pending = _notifiedWhileChecking;
    _notifiedWhileChecking = null;
    if (notify == null && pending != null && await _canNotify(pending)) {
      notify = pending;
    }
    state = state.copyWith(
      phase: notify != null
          ? WithdrawnElsewherePhase.notifying
          : WithdrawnElsewherePhase.idle,
      userIds: notify != null ? [notify] : const [],
      forcedUserId: result.forcedSignOutCleared ? null : state.forcedUserId,
    );
  }

  /// お知らせダイアログの OK。ログアウトして（失敗したら強制ログアウト）、データの削除ダイアログへ進める。
  Future<void> confirmSignOut() async {
    if (state.phase != WithdrawnElsewherePhase.notifying || _signingOut) return;
    _signingOut = true;
    final userId = state.userIds.first;
    final outcome = await _useCase.signOut(userId);
    _signingOut = false;
    if (outcome == WithdrawnSignOutOutcome.forced) {
      _stopWatching();
      state = state.copyWith(forcedUserId: userId);
    }
    state = state.copyWith(phase: WithdrawnElsewherePhase.confirming);
  }

  /// データの削除ダイアログの OK。
  Future<void> confirmDelete() async {
    if (state.phase != WithdrawnElsewherePhase.confirming) return;
    state = state.copyWith(phase: WithdrawnElsewherePhase.deleting);
    final result = await _useCase.deleteLocal(state.userIds);
    state = result.isRight()
        ? state.copyWith(phase: WithdrawnElsewherePhase.idle, userIds: const [])
        : state.copyWith(phase: WithdrawnElsewherePhase.failed);
  }

  /// 失敗ダイアログの OK。データの削除ダイアログに戻す。
  void acknowledgeFailure() {
    if (state.phase != WithdrawnElsewherePhase.failed) return;
    state = state.copyWith(phase: WithdrawnElsewherePhase.confirming);
  }

  /// ログイン中の uid が変わったら、監視の対象を切り替える。
  /// 強制ログアウトの記録と違う uid でログインしたら、記録を消す。
  void _onUserChanged(String? userId) {
    final forced = state.forcedUserId;
    if (forced != null && userId != null && userId != forced) {
      unawaited(_clearForcedSignOut(forced));
    }
    final target = userId == state.forcedUserId ? null : userId;
    if (target == _watchingUserId) return;
    _stopWatching();
    if (target == null) return;
    try {
      _watch = _useCase
          .watchWithdrawn(target)
          .listen((result) => _onWatched(target, result));
      _watchingUserId = target;
    } catch (_) {
      // 依存の生成（Firebase の初期化など）に失敗して監視を始められなければ、起動時・復帰時の確認で補う
    }
  }

  /// 記録を消せたときだけ、ログアウト扱いを解く（消せなければ、次の起動時に記録の uid として扱う）。
  Future<void> _clearForcedSignOut(String userId) async {
    final result = await _useCase.clearForcedSignOut(userId);
    result.fold((_) {}, (_) {
      if (state.forcedUserId == userId) {
        state = state.copyWith(forcedUserId: null);
      }
    });
  }

  void _stopWatching() {
    _watch?.cancel();
    _watch = null;
    _watchingUserId = null;
  }

  Future<void> _onWatched(String userId, Either<Failure, bool> result) async {
    // 監視の失敗は表示しない（起動時・復帰時の確認で補う）
    final withdrawn = result.fold((_) => false, (value) => value);
    if (!withdrawn || userId != _watchingUserId) return;
    if (state.phase == WithdrawnElsewherePhase.checking) {
      _notifiedWhileChecking = userId;
      return;
    }
    if (state.phase != WithdrawnElsewherePhase.idle) return;
    if (!await _canNotify(userId)) return;
    if (state.phase != WithdrawnElsewherePhase.idle) return;
    state = state.copyWith(
      phase: WithdrawnElsewherePhase.notifying,
      userIds: [userId],
    );
  }

  /// この端末の退会処理（途中・完了直後）を優先し、その間はお知らせを出さない。
  Future<bool> _canNotify(String userId) async {
    if (userId != _watchingUserId) return false;
    final deletion = ref.read(accountDeletionViewModelProvider).phase;
    if (deletion == AccountDeletionPhase.processing ||
        deletion == AccountDeletionPhase.completed) {
      return false;
    }
    return !await _useCase.isDeletionPending();
  }
}
