import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_pods/core/di/legal_providers.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/presentation/legal/legal_document_page.dart';

enum _Document { terms, privacy }

/// 設定画面の「このアプリについて」。押下すると `app_config/legal` から URL を読み、閲覧画面を開く。
///
/// `app_config/legal` が無ければ既定値の URL で開く。読めなければスナックバーで伝える。読んでいるだけなので、通信エラーでもログアウトさせない。
class LegalLinksSection extends ConsumerStatefulWidget {
  const LegalLinksSection({super.key});

  @override
  ConsumerState<LegalLinksSection> createState() => _LegalLinksSectionState();
}

class _LegalLinksSectionState extends ConsumerState<LegalLinksSection> {
  _Document? _loading;

  Future<void> _open(_Document document) async {
    if (_loading != null) return;
    setState(() => _loading = document);
    // `app_config/legal` が無ければ既定値の URL で開く
    final result = await ref.read(getLegalConfigUseCaseProvider).call();
    if (!mounted) return;
    setState(() => _loading = null);
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ページを開けませんでした。通信環境を確認して、もう一度お試しください。'),
      )),
      (config) => Navigator.of(context, rootNavigator: true)
          .push(_routeOf(document, config)),
    );
  }

  Route<void> _routeOf(_Document document, LegalConfig config) =>
      switch (document) {
        _Document.terms =>
          LegalDocumentPage.route(title: '利用規約', url: config.termsUrl),
        _Document.privacy => LegalDocumentPage.route(
            title: 'プライバシーポリシー', url: config.privacyUrl),
      };

  Widget? _trailing(_Document document) => _loading == document
      ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : null;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(
          title: Text('このアプリについて',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ListTile(
          title: const Text('利用規約'),
          leading: const Icon(Icons.description_outlined),
          trailing: _trailing(_Document.terms),
          onTap: () => _open(_Document.terms),
        ),
        ListTile(
          title: const Text('プライバシーポリシー'),
          leading: const Icon(Icons.privacy_tip_outlined),
          trailing: _trailing(_Document.privacy),
          onTap: () => _open(_Document.privacy),
        ),
      ],
    );
  }
}
