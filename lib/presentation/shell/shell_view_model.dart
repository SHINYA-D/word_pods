import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/core/di/account_providers.dart';
import 'package:word_pods/core/di/auth_providers.dart';

part 'shell_view_model.g.dart';

/// ログイン中のユーザーの開発者フラグ。ユーザーが変わったとき（ログインし直したとき）だけ読み直す。
@Riverpod(keepAlive: true)
Future<bool> developerStatus(Ref ref) async {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return false;
  final result = await ref.watch(getIsDeveloperUseCaseProvider)(userId);
  // 失敗の種類によらず開発者でないとして扱い、エラー表示もログアウトもしない
  return result.getOrElse((_) => false);
}

/// 開発者かどうか（「テスト」タブとサンプル画面を出すか）。
/// 読み込み中（別のユーザーへの切り替え中を含む）は、前のユーザーの値を使わず false にする。
@Riverpod(keepAlive: true)
bool isDeveloper(Ref ref) {
  final status = ref.watch(developerStatusProvider);
  return !status.isLoading && (status.value ?? false);
}
