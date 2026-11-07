import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:word_pods/core/di/legal_providers.dart';
import 'package:word_pods/domain/entities/legal_consent.dart';
import 'package:word_pods/presentation/auth/auth_state.dart';
import 'package:word_pods/presentation/auth/sign_up/sign_up_view_model.dart';
import 'package:word_pods/presentation/legal/legal_document_page.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  /// 新規登録画面で、利用規約・プライバシーポリシーに同意したか（2つともチェックしないと登録できない）
  bool _termsChecked = false;
  bool _privacyChecked = false;

  /// 閲覧画面を開いている（素早く2回押しても1つだけ開く）
  bool _documentOpen = false;

  Future<void> _openDocument(String title, String url) async {
    if (_documentOpen) return;
    _documentOpen = true;
    await Navigator.of(context).push(LegalDocumentPage.route(title: title, url: url));
    _documentOpen = false;
  }

  /// 確認メールの送信完了ダイアログ。「閉じる」でだけ閉じる（外側の押下・戻る操作では閉じない）。
  /// 閉じたら確認状態を取り直し、画面の移動の停止を解く。
  /// 仕様: docs/detailed_design/email_verification/email_verification.md 3.1
  Future<void> _showVerificationDialog({
    required String email,
    required bool sent,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(sent ? '確認メールを送信しました' : 'アカウントを作成しました'),
          content: Text(
            sent
                ? '$email に本人確認用のメールを送信しました。メール内のリンクを押して、登録を完了してください。'
                : '確認メールを送信できませんでした。次の画面の「確認メールを再送」から、もう一度送信してください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    await ref.read(signUpViewModelProvider.notifier).closeVerificationDialog();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpViewModelProvider);
    final vm = ref.read(signUpViewModelProvider.notifier);

    ref.listen<AuthState>(signUpViewModelProvider, (previous, next) {
      if (next.isSuccess && previous?.isSuccess != true) {
        // 移動先（確認済みならホーム画面、未確認なら確認待ち画面）はルーターが決める
        _showVerificationDialog(
          email: _emailController.text.trim(),
          sent: next.verificationEmailSent,
        );
        return;
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        vm.resetState();
      }
    });

    final isLoading = state.isLoading;
    // 読み込んでいる間は null（ボタンとリンクを押せない）
    final LegalConfig? legalConfig = ref.watch(signUpLegalConfigProvider).value;
    final canSubmit =
        !isLoading && legalConfig != null && _termsChecked && _privacyChecked;

    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'メールアドレスを入力してください' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'パスワード（6文字以上）',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'パスワードを入力してください';
                    if (v.length < 6) return '6文字以上で入力してください';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    labelText: 'パスワード（確認）',
                    prefixIcon: Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'パスワードが一致しません';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _LegalRow(
                  linkLabel: '利用規約を読む',
                  checkLabel: '利用規約に同意する',
                  checked: _termsChecked,
                  onOpen: legalConfig == null
                      ? null
                      : () => _openDocument('利用規約', legalConfig.termsUrl),
                  onChanged: (v) => setState(() => _termsChecked = v),
                ),
                const SizedBox(height: 12),
                _LegalRow(
                  linkLabel: 'プライバシーポリシーを読む',
                  checkLabel: 'プライバシーポリシーに同意する',
                  checked: _privacyChecked,
                  onOpen: legalConfig == null
                      ? null
                      : () => _openDocument(
                          'プライバシーポリシー', legalConfig.privacyUrl),
                  onChanged: (v) => setState(() => _privacyChecked = v),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: !canSubmit
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            vm.signUp(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                              termsVersion: legalConfig.termsVersion,
                              privacyVersion: legalConfig.privacyVersion,
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('アカウント作成'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 同意ダイアログと同じ、リンクとチェックボックスの行。
class _LegalRow extends StatelessWidget {
  const _LegalRow({
    required this.linkLabel,
    required this.checkLabel,
    required this.checked,
    required this.onOpen,
    required this.onChanged,
  });

  final String linkLabel;
  final String checkLabel;
  final bool checked;

  /// null なら押せない（規約の情報を読み込んでいる間）
  final VoidCallback? onOpen;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // リンクとチェック欄が同じ文書の組だと分かるよう、間の余白を詰める
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onOpen,
            child: Text(linkLabel),
          ),
        ),
        CheckboxListTile(
          visualDensity: VisualDensity.compact,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: checked,
          title: Text(checkLabel),
          onChanged: (value) => onChanged(value ?? false),
        ),
      ],
    );
  }
}
