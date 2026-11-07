import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_pods/core/app_lifecycle_observer.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/presentation/auth/verify_email/verify_email_view_model.dart';

/// メールアドレスの確認待ち画面（`/verify-email`）。
/// 確認済みになったらルーターがホーム画面へ、ログアウトしたらログイン画面へ移す。
/// 仕様: docs/detailed_design/email_verification/email_verification.md 3.2〜3.6
class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  late final AppLifecycleObserver _lifecycleObserver;

  /// 再送の待ち時間の残り秒数を、1秒ごとに描き直す（待ち時間がある間だけ動かす）
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // リンクを押してからアプリに戻ったときに、確認済みになったかを問い合わせる
    _lifecycleObserver = AppLifecycleObserver(
      onResumed: () =>
          ref.read(verifyEmailViewModelProvider.notifier).checkAutomatically(),
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    // 表示したときにも問い合わせる（リンクを押した後にアプリを起動し直した場合）。構築後に始める
    Future.microtask(() {
      if (!mounted) return;
      ref.read(verifyEmailViewModelProvider.notifier).checkAutomatically();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _keepTickingWhile(int cooldownSeconds) {
    if (cooldownSeconds <= 0) {
      _cooldownTimer?.cancel();
      _cooldownTimer = null;
      return;
    }
    _cooldownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  static String _textOf(VerifyEmailMessage message) => switch (message) {
        VerifyEmailMessage.notVerified =>
          'まだ確認が完了していません。メール内のリンクを押してください。',
        VerifyEmailMessage.resent => '確認メールを再送しました',
        VerifyEmailMessage.network =>
          '通信エラーが発生しました。電波の良い場所で再度お試しください。',
        VerifyEmailMessage.tooManyRequests =>
          '短時間に何度も送信されました。しばらく時間をおいてから再度お試しください。',
        VerifyEmailMessage.unknown => 'エラーが発生しました。時間をおいて再度お試しください。',
        VerifyEmailMessage.signOutFailed =>
          'ログアウトに失敗しました。時間をおいて再度お試しください。',
      };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verifyEmailViewModelProvider);
    final vm = ref.read(verifyEmailViewModelProvider.notifier);
    // 送信した時刻が変わったら（再送した）待ち時間を描き直す
    ref.watch(verificationEmailSentAtProvider);
    final email = ref.watch(currentUserProvider)?.email ?? '';

    ref.listen<VerifyEmailState>(verifyEmailViewModelProvider, (_, next) {
      final message = next.message;
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_textOf(message))));
      vm.clearMessage();
    });

    final cooldown = vm.resendCooldownSeconds();
    _keepTickingWhile(cooldown);
    final isBusy = state.isChecking || state.isResending || state.isSigningOut;

    return Scaffold(
      appBar: AppBar(
        title: const Text('メールアドレスの確認'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: isBusy ? null : vm.signOut,
            child: const Text('ログイン画面へ'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 64),
              const SizedBox(height: 24),
              Text(
                '$email に確認メールを送信しました。メール内のリンクを押して、登録を完了してください。',
              ),
              const SizedBox(height: 12),
              const Text('メールが届かない場合は、迷惑メールフォルダもご確認ください。'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: isBusy ? null : vm.confirm,
                child: state.isChecking
                    ? const _Progress()
                    : const Text('確認しました'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isBusy || cooldown > 0 ? null : vm.resend,
                child: state.isResending
                    ? const _Progress()
                    : Text(cooldown > 0 ? '確認メールを再送（あと$cooldown秒）' : '確認メールを再送'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}
