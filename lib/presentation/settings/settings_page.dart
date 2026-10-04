import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_stock/core/router/router.dart';
import 'package:word_stock/core/theme/app_theme.dart';
import 'package:word_stock/core/widgets/error_screen.dart';
import 'package:word_stock/core/di/auth_providers.dart';
import 'package:word_stock/presentation/settings/account_deletion_state.dart';
import 'package:word_stock/presentation/settings/account_deletion_view_model.dart';
import 'package:word_stock/presentation/settings/settings_view_model.dart';
import 'package:word_stock/presentation/settings/widgets/account_deletion_dialogs.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  /// 退会処理中の表示（再試行の処理中は再開ダイアログの中に出すので、ここでは出さない）
  Route<void>? _processingRoute;

  @override
  Widget build(BuildContext context) {
    ref.listen(accountDeletionViewModelProvider, _onAccountDeletionChanged);

    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';
    final state = ref.watch(settingsViewModelProvider(userId));
    final controller = ref.read(settingsViewModelProvider(userId).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorScreen(
          message: '設定の読み込みに失敗しました',
          onRetry: () {},
        ),
        data: (settings) => ListView(
          children: [
            const ListTile(
              title: Text('外観',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SwitchListTile(
              title: const Text('ダークモード'),
              value: settings.darkMode,
              onChanged: (v) => controller.updateSettings(settings.copyWith(darkMode: v)),
            ),
            ListTile(
              title: const Text('カラーテーマ'),
              trailing: DropdownButton<String>(
                value: settings.colorTheme,
                underline: const SizedBox(),
                items: AppTheme.colorThemes.keys.map((key) {
                  return DropdownMenuItem(
                    value: key,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppTheme.colorThemes[key],
                        ),
                        const SizedBox(width: 8),
                        Text(key),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) controller.updateSettings(settings.copyWith(colorTheme: v));
                },
              ),
            ),
            const Divider(),
            const ListTile(
              title: Text('アカウント',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('ログアウト'),
              leading: const Icon(Icons.logout),
              onTap: () => _showSignOutDialog(context, ref),
            ),
            ListTile(
              title: Text(
                '退会',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              leading: Icon(
                Icons.person_remove,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: _withdraw,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _withdraw() async {
    if (!await confirmAccountDeletion(context)) return;
    await ref.read(accountDeletionViewModelProvider.notifier).withdraw();
  }

  void _onAccountDeletionChanged(
    AccountDeletionState? previous,
    AccountDeletionState next,
  ) {
    final processing =
        next.phase == AccountDeletionPhase.processing && !next.isRetry;
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = _processingRoute;
    if (processing && route == null) {
      _processingRoute = accountDeletionProcessingRoute(navigator.context);
      navigator.push(_processingRoute!);
    } else if (!processing && route != null) {
      if (route.isActive) navigator.removeRoute(route);
      _processingRoute = null;
    }

    if (next.phase == AccountDeletionPhase.notSent &&
        previous?.phase != AccountDeletionPhase.notSent) {
      showAccountDeletionNotSentDialog(context).then((_) => ref
          .read(accountDeletionViewModelProvider.notifier)
          .acknowledgeNotSent());
    }
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(signOutUseCaseProvider).call();
              if (context.mounted) const LoginRoute().go(context);
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}
