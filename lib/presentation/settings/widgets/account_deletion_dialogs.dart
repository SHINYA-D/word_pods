import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_stock/presentation/settings/account_deletion_state.dart';
import 'package:word_stock/presentation/settings/account_deletion_view_model.dart';
import 'package:word_stock/presentation/settings/withdrawn_elsewhere_state.dart';
import 'package:word_stock/presentation/settings/withdrawn_elsewhere_view_model.dart';

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

Future<void> showAccountDeletionCompletedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
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
class AccountDeletionRetryDialog extends ConsumerWidget {
  const AccountDeletionRetryDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountDeletionViewModelProvider);
    final processing = state.phase == AccountDeletionPhase.processing;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('退会処理が完了していません'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('「再試行」を押して、退会処理を完了してください。'),
            if (state.retryFailed) ...[
              const SizedBox(height: 12),
              Text(
                '再試行に失敗しました。通信環境を確認して、もう一度お試しください。',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
            onPressed: processing
                ? null
                : () =>
                    ref.read(accountDeletionViewModelProvider.notifier).retry(),
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
              'この端末に残っている WordStock のデータをすべて削除します。',
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
