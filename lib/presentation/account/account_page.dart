import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_pods/core/di/auth_providers.dart';

/// ログイン中のアカウントの情報（メールアドレス）を表示する。設定画面の「アカウント情報」から開く。
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('アカウント情報')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('メールアドレス'),
            subtitle: Text(email),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'メールアドレスをコピー',
              onPressed: () => _copy(context, email),
            ),
          ),
          // Google でログインしているユーザーにはパスワードが無く、変更の手順も使えないため出さない
          if (user?.hasPassword ?? false)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('パスワード変更'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPasswordChangeDialog(context),
            ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('メールアドレスをコピーしました')),
      );
  }

  /// パスワードはログイン画面の「パスワードを忘れた方」（再設定のメール）で変更してもらう
  Future<void> _showPasswordChangeDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パスワードの変更'),
        content: const Text(
          'パスワードは、ログイン画面から変更できます。\n'
          '\n'
          '1. ログアウトする\n'
          '2. ログイン画面の「パスワードを忘れた方」を押す\n'
          '3. このアカウントのメールアドレスを入力して送信する\n'
          '4. 届いたメールのリンクから、新しいパスワードを設定する',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
