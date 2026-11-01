import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 閲覧画面の WebView の読み込みの通知先。
class LegalWebViewCallbacks {
  const LegalWebViewCallbacks({
    required this.onFinished,
    required this.onError,
  });

  /// ページの読み込みが終わった
  final VoidCallback onFinished;

  /// 通信の失敗、または HTTP エラー（ステータス 400 以上）で読み込めなかった
  final VoidCallback onError;
}

/// [url] を読み込む WebView を作る。[attempt] が変わるたびに読み込み直す（再読み込み）。
typedef LegalWebViewBuilder = Widget Function({
  required String url,
  required int attempt,
  required LegalWebViewCallbacks callbacks,
});

/// テストでは WebView（プラットフォームの画面）を差し替える。
final legalWebViewBuilderProvider = Provider<LegalWebViewBuilder>(
  (ref) => ({required url, required attempt, required callbacks}) =>
      _LegalWebView(url: url, attempt: attempt, callbacks: callbacks),
);

/// 利用規約・プライバシーポリシーの WEB ページを表示する全画面の閲覧画面。
/// 戻るボタン・戻る操作では、WebView の中の履歴ではなく、閲覧画面を閉じる。
class LegalDocumentPage extends ConsumerStatefulWidget {
  const LegalDocumentPage({super.key, required this.title, required this.url});

  final String title;
  final String url;

  static Route<void> route({required String title, required String url}) =>
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentPage(title: title, url: url),
      );

  @override
  ConsumerState<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

enum _LoadStatus { loading, loaded, failed }

class _LegalDocumentPageState extends ConsumerState<LegalDocumentPage> {
  int _attempt = 0;
  _LoadStatus _status = _LoadStatus.loading;

  void _reload() {
    setState(() {
      _attempt++;
      _status = _LoadStatus.loading;
    });
  }

  /// 再読み込みの前に届いた古い通知は無視する
  void _onStatus(int attempt, _LoadStatus status) {
    if (!mounted || attempt != _attempt || _status == _LoadStatus.failed) {
      return;
    }
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;
    final webView = ref.watch(legalWebViewBuilderProvider)(
      url: widget.url,
      attempt: attempt,
      callbacks: LegalWebViewCallbacks(
        onFinished: () => _onStatus(attempt, _LoadStatus.loaded),
        onError: () => _onStatus(attempt, _LoadStatus.failed),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _status == _LoadStatus.failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ページを読み込めませんでした。通信環境を確認して、もう一度お試しください。',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                webView,
                if (_status == _LoadStatus.loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}

class _LegalWebView extends StatefulWidget {
  const _LegalWebView({
    required this.url,
    required this.attempt,
    required this.callbacks,
  });

  final String url;
  final int attempt;
  final LegalWebViewCallbacks callbacks;

  @override
  State<_LegalWebView> createState() => _LegalWebViewState();
}

class _LegalWebViewState extends State<_LegalWebView> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(NavigationDelegate(
      // 文書と別のサイトへは移動しない（アプリの中の WebView で外部のサイトを開かせないため）
      onNavigationRequest: (request) => _isSameSite(request.url)
          ? NavigationDecision.navigate
          : NavigationDecision.prevent,
      onPageFinished: (_) => widget.callbacks.onFinished(),
      onWebResourceError: (error) {
        if (error.isForMainFrame ?? true) widget.callbacks.onError();
      },
      onHttpError: (error) {
        final status = error.response?.statusCode ?? 0;
        if (status >= 400) widget.callbacks.onError();
      },
    ));

  bool _isSameSite(String url) {
    final document = Uri.parse(widget.url);
    final target = Uri.tryParse(url);
    return target != null &&
        target.scheme == document.scheme &&
        target.host == document.host;
  }

  @override
  void initState() {
    super.initState();
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  void didUpdateWidget(covariant _LegalWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attempt != widget.attempt || oldWidget.url != widget.url) {
      _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
