import 'package:flutter/material.dart';

Future<void> showNetworkErrorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        NetworkErrorDialog(onOk: () => Navigator.of(context).pop()),
  );
}

/// 通信エラー・認証エラーのダイアログ（原則-11）。OK の後にログアウトしてログイン画面へ移る。
class NetworkErrorDialog extends StatelessWidget {
  const NetworkErrorDialog({super.key, required this.onOk});

  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('通信エラー'),
      content: const Text('通信に失敗しました。\nログイン画面に戻ります。'),
      actions: [
        TextButton(onPressed: onOk, child: const Text('OK')),
      ],
    );
  }
}
