import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:word_stock/core/router/router.dart';
import 'package:word_stock/core/widgets/network_error_dialog.dart';
import 'package:word_stock/presentation/legal/legal_consent_state.dart';
import 'package:word_stock/presentation/legal/legal_consent_view_model.dart';
import 'package:word_stock/presentation/legal/legal_document_page.dart';
import 'package:word_stock/presentation/legal/widgets/legal_consent_dialog.dart';

enum _DialogKind { consent, networkError }

/// 同意ダイアログと、送信が通信エラーで失敗したときの「通信エラー」ダイアログを、状態に合わせて出し続ける。
///
/// - どの画面の上にも出す。ほかのダイアログ（フォルダの作成など）は閉じずに、その上に重ねる
/// - スプラッシュ画面・ログイン関連の画面の間は出さず、移動先の画面が決まってから出す
/// - 待機に戻ったら、同意ダイアログから開いた閲覧画面も一緒に閉じる
/// - 画面が切り替わるとダイアログも一緒に消えるため、画面が切り替わるたびに出し直す
///   （[WithdrawnElsewhereGate] と同じ作り）
class LegalConsentGate extends ConsumerStatefulWidget {
  const LegalConsentGate({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<LegalConsentGate> createState() => _LegalConsentGateState();
}

class _LegalConsentGateState extends ConsumerState<LegalConsentGate> {
  Route<void>? _route;
  _DialogKind? _kind;

  /// 同意ダイアログのリンクから開いた閲覧画面
  Route<void>? _documentRoute;

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
    // スプラッシュ画面と、ログイン直後の初回同期を待っているログイン関連の画面では出さない
    if (location == const SplashRoute().location ||
        location == const LoginRoute().location ||
        location == const SignUpRoute().location ||
        location == const PasswordResetRoute().location) {
      return null;
    }
    switch (ref.read(legalConsentViewModelProvider).phase) {
      case LegalConsentPhase.required:
      case LegalConsentPhase.sending:
      case LegalConsentPhase.signingOut:
        return _DialogKind.consent;
      case LegalConsentPhase.networkError:
        return _DialogKind.networkError;
      case LegalConsentPhase.idle:
      case LegalConsentPhase.checking:
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

    final document = _documentRoute;
    if (document != null && document.isActive) navigator.removeRoute(document);
    _documentRoute = null;
    if (isShowing) navigator.removeRoute(route);
    _route = null;
    _kind = null;
    if (kind == null) return;

    _kind = kind;
    _route = DialogRoute<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => switch (kind) {
        _DialogKind.consent => LegalConsentDialog(onOpenDocument: _openDocument),
        _DialogKind.networkError => PopScope(
            canPop: false,
            child: NetworkErrorDialog(
              onOk: ref
                  .read(legalConsentViewModelProvider.notifier)
                  .acknowledgeNetworkError,
            ),
          ),
      },
    );
    navigator.push(_route!);
  }

  void _openDocument({required String title, required String url}) {
    final navigator = widget.router.routerDelegate.navigatorKey.currentState;
    final opened = _documentRoute;
    // 素早く2回押しても1つだけ開く
    if (navigator == null || (opened != null && opened.isActive)) return;
    _documentRoute = LegalDocumentPage.route(title: title, url: url);
    navigator.push(_documentRoute!);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      legalConsentViewModelProvider.select((s) => s.phase),
      (_, __) => _scheduleUpdate(),
    );
    return widget.child;
  }
}
