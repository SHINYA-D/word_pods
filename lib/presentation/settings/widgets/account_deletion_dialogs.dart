import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/presentation/settings/account_deletion_state.dart';
import 'package:word_pods/presentation/settings/account_deletion_view_model.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_state.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_view_model.dart';

/// 確認ダイアログと最終確認ダイアログを順に出し、両方で「OK」を押したら true を返す。
Future<bool> confirmAccountDeletion(BuildContext context) async {
  final first = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('退会'),
      content: const Text('このアプリから退会いたしますか？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  if (first != true || !context.mounted) return false;

  final second = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final colors = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: const Text('最終確認'),
        content: const Text('退会すると全てのデータが削除されます。それでも退会しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
  return second == true;
}

/// 退会処理中の表示。閉じられない（戻る操作・外側のタップを受け付けない）。
DialogRoute<void> accountDeletionProcessingRoute(BuildContext context) {
  return DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Expanded(child: Text('退会処理中です')),
          ],
        ),
      ),
    ),
  );
}

Future<void> showAccountDeletionNotSentDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('退会できませんでした'),
      content: const Text('通信環境を確認して、もう一度お試しください。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// 本人確認の試行回数の上限を超えたときの文言。
const accountDeletionTooManyAttemptsMessage =
    '本人確認の試行回数が上限を超えました。しばらく時間をおいて、もう一度お試しください。';

/// 退会の前の本人確認で、パスワードを入力してもらう。「OK」なら入力したパスワード、キャンセルなら null。
/// パスワードが違ったときは、[initialPassword] に前回の入力を、[error] にエラーの文言を渡して開き直す。
Future<String?> askPasswordForAccountDeletion(
  BuildContext context, {
  String initialPassword = '',
  String? error,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _PasswordDialog(initialPassword: initialPassword, error: error),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.initialPassword, this.error});

  final String initialPassword;
  final String? error;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  late final _password = TextEditingController(text: widget.initialPassword);

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('本人確認'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('退会するには、パスワードを入力してください。'),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'パスワード'),
            onChanged: (_) => setState(() {}),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _password.text.isEmpty
              ? null
              : () => Navigator.pop(context, _password.text),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// 本人確認できなかったときのダイアログ。[tooManyAttempts] なら試行回数の上限を超えた旨を出す。
Future<void> showAccountDeletionReauthRejectedDialog(
  BuildContext context, {
  required bool tooManyAttempts,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('本人確認できませんでした'),
      content: Text(tooManyAttempts
          ? accountDeletionTooManyAttemptsMessage
          : 'パスワード（Google アカウント）を確認して、もう一度お試しください。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> showAccountDeletionCompletedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      // タイトルが無いので、本文が上に寄らないよう上の余白を広げ、OK ボタンとの間を詰める
      contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      content: const Text('退会が完了しました'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// 退会処理の再開ダイアログ。「再試行」だけを置き、閉じられない。
///
/// 続きを行うのに本人確認のし直しが必要なときは、その案内を出し、「再試行」で本人確認をしてから続きを行う
/// （メールで登録したユーザーはダイアログの中でパスワードを入力し、Google のユーザーは Google で本人確認する）。
class AccountDeletionRetryDialog extends ConsumerStatefulWidget {
  const AccountDeletionRetryDialog({super.key});

  @override
  ConsumerState<AccountDeletionRetryDialog> createState() =>
      _AccountDeletionRetryDialogState();
}

class _AccountDeletionRetryDialogState
    extends ConsumerState<AccountDeletionRetryDialog> {
  final _password = TextEditingController();

  /// パスワードで本人確認を始めたか。応答を待つ間もパスワード欄を（入力できない状態で）残すために使う
  bool _sentPassword = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountDeletionViewModelProvider);
    final processing = state.phase == AccountDeletionPhase.processing;
    final needsReauth = state.phase == AccountDeletionPhase.reauthRequired;
    final hasPassword =
        ref.watch(currentUserProvider.select((u) => u?.hasPassword ?? false));
    final askPassword = needsReauth && hasPassword;
    final showPassword = askPassword || (processing && _sentPassword);
    final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error);
    final vm = ref.read(accountDeletionViewModelProvider.notifier);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('退会処理が完了していません'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('「再試行」を押して、退会処理を完了してください。'),
            if (needsReauth) ...[
              const SizedBox(height: 12),
              Text(hasPassword
                  ? '続けるには本人確認が必要です。パスワードを入力してください。'
                  : '続けるには本人確認が必要です。「再試行」を押して、Google で本人確認してください。'),
            ],
            if (showPassword) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _password,
                enabled: !processing,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'パスワード'),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (state.reauthRejected) ...[
              const SizedBox(height: 12),
              Text(
                '本人確認できませんでした。パスワード（Google アカウント）を確認して、もう一度お試しください。',
                style: errorStyle,
              ),
            ],
            if (state.tooManyAttempts) ...[
              const SizedBox(height: 12),
              Text(accountDeletionTooManyAttemptsMessage, style: errorStyle),
            ],
            if (state.retryFailed) ...[
              const SizedBox(height: 12),
              Text(
                '再試行に失敗しました。通信環境を確認して、もう一度お試しください。',
                style: errorStyle,
              ),
            ],
            if (processing) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text('退会処理中です')),
                ],
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: processing || (askPassword && _password.text.isEmpty)
                ? null
                : () {
                    setState(() => _sentPassword = askPassword);
                    if (!needsReauth) {
                      vm.retry();
                    } else {
                      vm.retryWithReauth(
                          password: hasPassword ? _password.text : null);
                    }
                  },
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }
}

/// 他の端末での退会: ログイン中のアカウントが退会済みのときのお知らせ。「OK」だけを置き、閉じられない。
class WithdrawnNoticeDialog extends ConsumerWidget {
  const WithdrawnNoticeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('アカウントが削除されました'),
        content: const Text(
          'このアカウントは他の端末で退会されたため、ログアウトします。'
          '引き続きご利用になる場合は、新しいアカウントで登録してログインしてください。',
        ),
        actions: [
          FilledButton(
            onPressed: () => ref
                .read(withdrawnElsewhereViewModelProvider.notifier)
                .confirmSignOut(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// 他の端末での退会: データの削除。「OK」だけを置き、閉じられない。削除中は OK を押せない。
class WithdrawnDeleteDialog extends ConsumerWidget {
  const WithdrawnDeleteDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleting = ref.watch(withdrawnElsewhereViewModelProvider
            .select((s) => s.phase)) ==
        WithdrawnElsewherePhase.deleting;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('データの削除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'このアカウントは他の端末で退会済みです。'
              'この端末に残っている WordPods のデータをすべて削除します。',
            ),
            if (deleting) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: deleting
                ? null
                : () => ref
                    .read(withdrawnElsewhereViewModelProvider.notifier)
                    .confirmDelete(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// 他の端末での退会: 端末内のデータの削除に失敗したとき。「OK」でデータの削除ダイアログに戻る。
class WithdrawnDeleteFailedDialog extends ConsumerWidget {
  const WithdrawnDeleteFailedDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('削除に失敗しました'),
        content: const Text('端末内のデータを削除できませんでした。もう一度お試しください。'),
        actions: [
          FilledButton(
            onPressed: () => ref
                .read(withdrawnElsewhereViewModelProvider.notifier)
                .acknowledgeFailure(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
