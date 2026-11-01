import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/core/di/legal_providers.dart';
import 'package:word_pods/core/di/repository_providers.dart';
import 'package:word_pods/core/di/sync_status_providers.dart';
import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/presentation/legal/legal_consent_state.dart';
import 'package:word_pods/presentation/settings/account_deletion_state.dart';
import 'package:word_pods/presentation/settings/account_deletion_view_model.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_state.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_view_model.dart';

part 'legal_consent_view_model.g.dart';

/// 利用規約・プライバシーポリシーへの同意。
///
/// ログインしたとき・起動時・復帰時・オンラインに戻ったときに同意が必要かを判定し、必要なら同意ダイアログを出す状態にする。
/// ログイン直後は、ログインの処理（新規登録では同意の送信を含む）と初回の同期が終わってから判定する。
/// 退会関係のダイアログ（再開・他の端末での退会）を優先し、それらの間は判定しない。
/// ログアウト・他の端末での退会で待機に戻したら、それより前に始めた処理の結果は捨てる（[_generation]）。
@Riverpod(keepAlive: true)
class LegalConsentViewModel extends _$LegalConsentViewModel {
  /// 起動時の準備（強制ログアウトの記録の読み込み）が終わったか。終わるまではログインの変化で判定しない
  bool _started = false;

  /// 待機に戻すたびに増やす。処理の途中で変わっていたら、その結果は捨てる
  int _generation = 0;

  bool _acknowledging = false;

  @override
  LegalConsentState build() {
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.id == next?.id) return;
      _reset();
      if (next != null && _started) check();
    });
    // 初回の同期が終わったら（成功・失敗によらず）判定する
    ref.listen(authSyncInProgressProvider, (previous, next) {
      if (previous == true && !next && _started) check();
    });
    ref.listen(
      withdrawnElsewhereViewModelProvider.select((s) => s.phase),
      (_, phase) {
        if (_isWithdrawnDialog(phase)) _reset();
      },
    );
    return const LegalConsentState();
  }

  /// 起動時に、強制ログアウトの記録を読み終えてから呼ぶ。以後はログインの変化でも判定する。
  Future<void> start() async {
    _started = true;
    await check();
  }

  /// 同意が必要かを判定する（起動時・ログインしたとき・復帰時・オンラインに戻ったとき）。
  /// ダイアログの表示中・初回の同期の間などは何もしない。
  Future<void> check() async {
    if (state.phase != LegalConsentPhase.idle) return;
    if (ref.read(authSyncInProgressProvider)) return;
    final userId = _signedInUserId();
    if (userId == null || await _isBlocked()) return;
    if (state.phase != LegalConsentPhase.idle) return;

    final generation = _generation;
    state = state.copyWith(phase: LegalConsentPhase.checking);
    final result = await ref.read(checkLegalConsentUseCaseProvider).call(userId);
    if (generation != _generation) return;
    if (_signedInUserId() != userId || await _isBlocked()) return _reset();
    if (generation != _generation) return;
    _apply(result, message: null);
  }

  void setTermsChecked(bool value) {
    if (state.phase != LegalConsentPhase.required) return;
    state = state.copyWith(termsChecked: value);
  }

  void setPrivacyChecked(bool value) {
    if (state.phase != LegalConsentPhase.required) return;
    state = state.copyWith(privacyChecked: value);
  }

  /// 「同意する」。表示している文書の版数を送る。
  Future<void> accept() async {
    final config = state.config;
    if (state.phase != LegalConsentPhase.required ||
        !state.allChecked ||
        config == null) {
      return;
    }
    final userId = _signedInUserId();
    if (userId == null) return;

    final generation = _generation;
    state = state.copyWith(phase: LegalConsentPhase.sending, message: null);
    final result = await ref.read(legalRepositoryProvider).accept(
          termsVersion: state.termsRequired ? config.termsVersion : null,
          privacyVersion: state.privacyRequired ? config.privacyVersion : null,
        );
    if (generation != _generation) return;

    await result.fold(
      (failure) async {
        state = failure is NetworkFailure || failure is AuthFailure
            ? state.copyWith(phase: LegalConsentPhase.networkError)
            : state.copyWith(
                phase: LegalConsentPhase.required,
                message: LegalConsentMessage.sendFailed,
              );
      },
      (accepted) async {
        if (accepted == LegalAcceptResult.accepted) return _reset();
        // 表示中に改定された。判定し直した結果で表示し直す
        final recheck =
            await ref.read(checkLegalConsentUseCaseProvider).call(userId);
        if (generation != _generation) return;
        _apply(recheck, message: LegalConsentMessage.outdated);
      },
    );
  }

  /// 同意ダイアログの「ログアウト」。
  Future<void> signOut() async {
    if (state.phase != LegalConsentPhase.required) return;
    final generation = _generation;
    state = state.copyWith(phase: LegalConsentPhase.signingOut, message: null);
    final result = await ref.read(signOutUseCaseProvider).call();
    if (generation != _generation) return;
    // 失敗の種類は区別しない（通信エラーでログアウトを促すと循環するため）
    result.fold(
      (_) => state = state.copyWith(
        phase: LegalConsentPhase.required,
        message: LegalConsentMessage.signOutFailed,
      ),
      (_) => _reset(),
    );
  }

  /// 「通信エラー」ダイアログの OK。ログアウトする。失敗したら判定し直す（同意しないまま使わせない）。
  Future<void> acknowledgeNetworkError() async {
    if (state.phase != LegalConsentPhase.networkError || _acknowledging) return;
    _acknowledging = true;
    final generation = _generation;
    final result = await ref.read(signOutUseCaseProvider).call();
    _acknowledging = false;
    if (generation != _generation) return;
    _reset();
    if (result.isLeft()) await check();
  }

  void _apply(
    Either<Failure, LegalConsentRequirement> result, {
    required LegalConsentMessage? message,
  }) {
    result.fold(
      // 判定の失敗は伝えない（裏の確認のため）。次のきっかけでもう一度判定する
      (_) => _reset(),
      (requirement) {
        if (!requirement.isRequired) return _reset();
        state = LegalConsentState(
          phase: LegalConsentPhase.required,
          termsRequired: requirement.termsRequired,
          privacyRequired: requirement.privacyRequired,
          config: requirement.config,
          message: message,
        );
      },
    );
  }

  void _reset() {
    _generation++;
    _acknowledging = false;
    state = const LegalConsentState();
  }

  /// ログイン中の uid。強制ログアウトの記録がある uid は、ログインしていないものとして扱う。
  String? _signedInUserId() {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return null;
    if (userId == ref.read(withdrawnElsewhereViewModelProvider).forcedUserId) {
      return null;
    }
    return userId;
  }

  /// 退会関係のダイアログを優先する。退会処理の記録がある間は、`accounts/{uid}` が先に消えて
  /// 未同意と誤って判定するため、判定しない。
  Future<bool> _isBlocked() async {
    if (_isWithdrawnDialog(ref.read(withdrawnElsewhereViewModelProvider).phase)) {
      return true;
    }
    switch (ref.read(accountDeletionViewModelProvider).phase) {
      case AccountDeletionPhase.processing:
      case AccountDeletionPhase.completed:
      case AccountDeletionPhase.pendingRetry:
      case AccountDeletionPhase.reauthRequired:
        return true;
      case AccountDeletionPhase.checking:
      case AccountDeletionPhase.idle:
      case AccountDeletionPhase.notSent:
      case AccountDeletionPhase.reauthRejected:
        break;
    }
    try {
      return await ref.read(withdrawnElsewhereUseCaseProvider).isDeletionPending();
    } catch (_) {
      // 依存の生成（Firebase の初期化など）に失敗したら、途中かもしれないので判定しない
      return true;
    }
  }

  static bool _isWithdrawnDialog(WithdrawnElsewherePhase phase) =>
      phase == WithdrawnElsewherePhase.notifying ||
      phase == WithdrawnElsewherePhase.confirming ||
      phase == WithdrawnElsewherePhase.deleting ||
      phase == WithdrawnElsewherePhase.failed;
}
