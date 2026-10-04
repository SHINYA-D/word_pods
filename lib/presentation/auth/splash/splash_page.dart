import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_stock/core/di/auth_providers.dart';
import 'package:word_stock/core/router/router.dart';
import 'package:word_stock/presentation/settings/account_deletion_state.dart';
import 'package:word_stock/presentation/settings/account_deletion_view_model.dart';

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
    if (authState.hasError || authState.valueOrNull == null) {
      const LoginRoute().go(context);
    } else {
      const HomeRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, __) => _tryNavigate());
    ref.listen(accountDeletionViewModelProvider, (_, __) => _tryNavigate());

    return const Scaffold(
      backgroundColor: Color(0xFFF0F0F5),
      body: Center(
        child: Image(
          image: AssetImage('assets/images/splash.png'),
          width: 240,
        ),
      ),
    );
  }
}
