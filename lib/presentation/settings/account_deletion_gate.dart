import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:word_pods/core/router/router.dart';
import 'package:word_pods/presentation/settings/account_deletion_state.dart';
import 'package:word_pods/presentation/settings/account_deletion_view_model.dart';
import 'package:word_pods/presentation/settings/widgets/account_deletion_dialogs.dart';

/// 退会処理が途中で止まっている間、どの画面の上にも再開ダイアログを出し続ける。
///
/// 画面が切り替わる（ログアウトでログイン画面へ移る等）とダイアログも一緒に消えるため、
/// 画面が切り替わるたびに出し直す。スプラッシュ画面の間は、移動先の画面が決まってから出す。
class AccountDeletionGate extends ConsumerStatefulWidget {
  const AccountDeletionGate({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<AccountDeletionGate> createState() =>
      _AccountDeletionGateState();
}

class _AccountDeletionGateState extends ConsumerState<AccountDeletionGate> {
  Route<void>? _retryRoute;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_scheduleUpdate);
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_scheduleUpdate);
    super.dispose();
  }

  void _scheduleUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!mounted) return;
    final navigator = widget.router.routerDelegate.navigatorKey.currentState;
    if (navigator == null) return;
    final state = ref.read(accountDeletionViewModelProvider);
    final location = widget.router.routerDelegate.currentConfiguration.uri.path;
    final show = location != const SplashRoute().location &&
        (state.phase == AccountDeletionPhase.pendingRetry ||
            (state.phase == AccountDeletionPhase.processing && state.isRetry));
    final route = _retryRoute;
    final isShowing = route != null && route.isActive;

    if (show && !isShowing) {
      _retryRoute = DialogRoute<void>(
        context: navigator.context,
        barrierDismissible: false,
        builder: (_) => const AccountDeletionRetryDialog(),
      );
      navigator.push(_retryRoute!);
    } else if (!show && isShowing) {
      navigator.removeRoute(route);
      _retryRoute = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(accountDeletionViewModelProvider, (previous, next) {
      // 退会が完了したらログイン画面へ移る（完了ダイアログはログイン画面が出す）。
      // ログアウトの成功による自動の転送だけに頼ると、ログアウトに失敗したときに移動しないため
      if (next.phase == AccountDeletionPhase.completed &&
          previous?.phase != AccountDeletionPhase.completed) {
        widget.router.go(const LoginRoute().location);
      }
      _scheduleUpdate();
    });
    return widget.child;
  }
}
