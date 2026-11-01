import 'package:word_pods/core/error/failure.dart';
import 'package:word_pods/domain/repositories/reauthentication_repository.dart';

/// 本人確認の結果。
enum ReauthenticationOutcome {
  /// 本人確認できた
  succeeded,

  /// Google の本人確認をキャンセルした
  cancelled,

  /// パスワードが違う、またはログイン中と別のアカウントを選んだ
  rejected,

  /// 試行回数の上限を超えた（時間をおけば通る）
  tooManyAttempts,

  /// 通信できない・その他のエラーで、本人確認できたか分からない
  failed,
}

/// 退会の前の本人確認。[password] があればパスワードで、無ければ Google で行う。
class ReauthenticateUseCase {
  const ReauthenticateUseCase(this._repository);

  final ReauthenticationRepository _repository;

  Future<ReauthenticationOutcome> call({String? password}) async {
    if (password != null) {
      final result = await _repository.reauthenticateWithPassword(password);
      return result.fold(_outcomeOf, (_) => ReauthenticationOutcome.succeeded);
    }
    final result = await _repository.reauthenticateWithGoogle();
    return result.fold(
      _outcomeOf,
      (done) => done
          ? ReauthenticationOutcome.succeeded
          : ReauthenticationOutcome.cancelled,
    );
  }

  ReauthenticationOutcome _outcomeOf(Failure failure) => switch (failure) {
        AuthFailure() => ReauthenticationOutcome.rejected,
        TooManyRequestsFailure() => ReauthenticationOutcome.tooManyAttempts,
        _ => ReauthenticationOutcome.failed,
      };
}
