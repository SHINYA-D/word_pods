import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:word_pods/core/router/router.dart';
import 'package:word_pods/presentation/settings/widgets/account_deletion_dialogs.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_state.dart';
import 'package:word_pods/presentation/settings/withdrawn_elsewhere_view_model.dart';

enum _DialogKind { notice, delete, failed }

/// 他の端末での退会のダイアログを、状態に合わせて出し続ける。
///
/// - お知らせ: どの画面の上にも出す。ほかのダイアログを表示していれば、閉じてから出す
/// - データの削除・失敗: ログアウト後のログイン画面の上に出す
///
/// 画面が切り替わる（ログアウトでログイン画面へ移る等）とダイアログも一緒に消えるため、
/// 画面が切り替わるたびに出し直す（[AccountDeletionGate] と同じ作り）。
class WithdrawnElsewhereGate extends ConsumerStatefulWidget {
  const WithdrawnElsewhereGate({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<WithdrawnElsewhereGate> createState() =>
      _WithdrawnElsewhereGateState();
}

class _WithdrawnElsewhereGateState
    extends ConsumerState<WithdrawnElsewhereGate> {
  Route<void>? _route;
  _DialogKind? _kind;

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

  _DialogKind? _desiredKind(String location) {
    if (location == const SplashRoute().location) return null;
    final onLogin = location == const LoginRoute().location;
    switch (ref.read(withdrawnElsewhereViewModelProvider).phase) {
      case WithdrawnElsewherePhase.notifying:
        return _DialogKind.notice;
      case WithdrawnElsewherePhase.confirming:
      case WithdrawnElsewherePhase.deleting:
        return onLogin ? _DialogKind.delete : null;
      case WithdrawnElsewherePhase.failed:
        return onLogin ? _DialogKind.failed : null;
      case WithdrawnElsewherePhase.idle:
      case WithdrawnElsewherePhase.checking:
        return null;
    }
  }

  void _update() {
    if (!mounted) return;
    final navigator = widget.router.routerDelegate.navigatorKey.currentState;
    if (navigator == null) return;
    final location = widget.router.routerDelegate.currentConfiguration.uri.path;
    final kind = _desiredKind(location);
    final route = _route;
    final isShowing = route != null && route.isActive;
    if (isShowing && kind == _kind) return;

    if (isShowing) navigator.removeRoute(route);
    _route = null;
    _kind = null;
    if (kind == null) return;

    if (kind == _DialogKind.notice) {
      // 退会の確認ダイアログなど、ほかのダイアログを閉じてから出す
      navigator.popUntil((r) => r is! PopupRoute);
    }
    _kind = kind;
    _route = DialogRoute<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => switch (kind) {
        _DialogKind.notice => const WithdrawnNoticeDialog(),
        _DialogKind.delete => const WithdrawnDeleteDialog(),
        _DialogKind.failed => const WithdrawnDeleteFailedDialog(),
      },
    );
    navigator.push(_route!);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      withdrawnElsewhereViewModelProvider.select((s) => s.phase),
      (_, __) => _scheduleUpdate(),
    );
    return widget.child;
  }
}
