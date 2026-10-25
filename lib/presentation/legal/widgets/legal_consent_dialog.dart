import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_pods/presentation/legal/legal_consent_state.dart';
import 'package:word_pods/presentation/legal/legal_consent_view_model.dart';

/// 同意ダイアログ。閉じられない（外側タップ・戻る操作では閉じない）。
///
/// [onOpenDocument] でリンクの閲覧画面を開く（開いた画面はゲートが管理する）。
class LegalConsentDialog extends ConsumerWidget {
  const LegalConsentDialog({super.key, required this.onOpenDocument});

  final void Function({required String title, required String url})
      onOpenDocument;

  static String messageText(LegalConsentMessage message) => switch (message) {
        LegalConsentMessage.sendFailed => '同意を送信できませんでした。もう一度お試しください。',
        LegalConsentMessage.outdated => '内容が更新されました。もう一度ご確認のうえ、同意してください。',
        LegalConsentMessage.signOutFailed => 'ログアウトできませんでした。もう一度お試しください。',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(legalConsentViewModelProvider);
    final controller = ref.read(legalConsentViewModelProvider.notifier);
    final busy = state.phase == LegalConsentPhase.sending ||
        state.phase == LegalConsentPhase.signingOut;
    final config = state.config;
    final message = state.message;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        scrollable: true,
        title: const Text('同意のお願い'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WordPods を利用するには、次の内容への同意が必要です。リンクから内容を確認し、チェックを入れてください。',
            ),
            if (state.termsRequired && config != null)
              _DocumentRow(
                linkLabel: '利用規約を読む',
                checkLabel: '利用規約に同意する',
                checked: state.termsChecked,
                enabled: !busy,
                onOpen: () =>
                    onOpenDocument(title: '利用規約', url: config.termsUrl),
                onChanged: controller.setTermsChecked,
              ),
            if (state.privacyRequired && config != null)
              _DocumentRow(
                linkLabel: 'プライバシーポリシーを読む',
                checkLabel: 'プライバシーポリシーに同意する',
                checked: state.privacyChecked,
                enabled: !busy,
                onOpen: () => onOpenDocument(
                    title: 'プライバシーポリシー', url: config.privacyUrl),
                onChanged: controller.setPrivacyChecked,
              ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  messageText(message),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : controller.signOut,
            child: const Text('ログアウト'),
          ),
          FilledButton(
            onPressed: !busy && state.allChecked ? controller.accept : null,
            child: const Text('同意する'),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.linkLabel,
    required this.checkLabel,
    required this.checked,
    required this.enabled,
    required this.onOpen,
    required this.onChanged,
  });

  final String linkLabel;
  final String checkLabel;
  final bool checked;
  final bool enabled;
  final VoidCallback onOpen;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextButton(
          onPressed: enabled ? onOpen : null,
          child: Text(linkLabel),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: checked,
          enabled: enabled,
          title: Text(checkLabel),
          onChanged: (value) => onChanged(value ?? false),
        ),
      ],
    );
  }
}
