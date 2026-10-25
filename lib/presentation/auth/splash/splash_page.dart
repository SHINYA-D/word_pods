import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_pods/core/di/auth_providers.dart';
import 'package:word_pods/core/router/router.dart';
import 'package:word_pods/presentation/settings/account_deletion_state.dart';
import 'package:word_pods/presentation/settings/account_deletion_view_model.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_view_model.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _minDelayDone = false;

  @override
  void initState() {
    super.initState();
    // 強制ログアウトの記録を読む（読み終えるまで移動しない）。画面の構築中に状態を変えないよう、構築後に始める
    Future.microtask(
        () => ref.read(withdrawnElsewhereViewModelProvider.notifier).initialize());
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _minDelayDone = true);
      _tryNavigate();
    });
  }

  void _tryNavigate() {
    if (!_minDelayDone || !mounted) return;
    final authState = ref.read(authStateProvider);
    if (authState.isLoading) return;
    // 退会処理の記録の確認が終わるまで移動しない（途中なら移動先で再開ダイアログを出すため）
    final deletion = ref.read(accountDeletionViewModelProvider);
    if (deletion.phase == AccountDeletionPhase.checking) return;
    // 強制ログアウトの記録を読み終えるまで移動しない（記録の uid はログイン画面から始めるため）
    final withdrawn = ref.read(withdrawnElsewhereViewModelProvider);
    if (!withdrawn.forcedLoaded) return;
    final user = authState.valueOrNull;
    if (authState.hasError || user == null || user.id == withdrawn.forcedUserId) {
      const LoginRoute().go(context);
    } else {
      const HomeRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, __) => _tryNavigate());
    ref.listen(accountDeletionViewModelProvider, (_, __) => _tryNavigate());
    ref.listen(withdrawnElsewhereViewModelProvider, (_, __) => _tryNavigate());

    return const Scaffold(
      backgroundColor: Color(0xFF15203B),
      body: Center(
        child: Image(
          image: AssetImage('assets/images/android/android_icon_foreground_1024.png'),
          width: 256,
        ),
      ),
    );
  }
}
