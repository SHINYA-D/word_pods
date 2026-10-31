## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/presentation/auth/sign_up/sign_up_page.dart |
| 仕様書 | docs/detailed_design/legal_consent/legal_consent.md |
| クラス名 | SignUpPage |
| テスト対象メソッド | SignUpPage.build() |

仕様書 3.6 節（新規登録画面での同意。LGL-S01〜S36）と、既存の4件（初期表示・入力チェック）の Widget テスト。
新規登録の後にホーム画面へ移る・同意ダイアログが出る（S09〜S12, S24）ため、本物のルーターと
AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate を `MaterialApp.router` に組んだテスト用アプリ（lib/app.dart と同じ配線）で、
ログイン画面から新規登録画面を開いて検証する。手書き Fake（LegalRepository・AuthRepository・AccountDeletionRepository）と Mock Repository を使い、
WebView は legalWebViewBuilderProvider を Fake に差し替えて builder に渡った url を記録する。
SignUpViewModel・SignUpUseCase のロジック網羅は別の単体テスト（仕様書 4.2・6.3）が担当する。

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | 初期表示: 3 つのフォームフィールドとアカウント作成ボタンが揃っている | - | 正常系 | SignUpPage.build() | ✅ |
| 2 | メールアドレスが空のままアカウント作成するとバリデーションエラーが出る | - | 異常系 | SignUpPage.build() | ✅ |
| 3 | パスワードが 6 文字未満のときバリデーションエラーが出る | - | 異常系 | SignUpPage.build() | ✅ |
| 4 | パスワードと確認が一致しないときバリデーションエラーが出る | - | 異常系 | SignUpPage.build() | ✅ |
| 5 | 新規登録画面を開き規約の情報の読み取りが終わった場合、パスワード（確認）の下に4つの項目がこの順で表示され、2つとも未チェックで「アカウント作成」は無効になる [LGL-S01] | LGL-S01 #b5f2f4 | 正常系 | SignUpPage.build() | ✅ |
| 6 | 正しい入力をして「利用規約に同意する」だけをチェックした場合、「アカウント作成」は無効のままになる [LGL-S02] | LGL-S02 #b37b80 | 境界値 | SignUpPage.build() | ✅ |
| 7 | 正しい入力をして「プライバシーポリシーに同意する」だけをチェックした場合、「アカウント作成」は無効のままになる [LGL-S03] | LGL-S03 #9541ab | 境界値 | SignUpPage.build() | ✅ |
| 8 | 正しい入力をして2つのチェックボックスをチェックした場合、「アカウント作成」が有効になる [LGL-S04] | LGL-S04 #4b02dd | 正常系 | SignUpPage.build() | ✅ |
| 9 | 正しい入力をして2つチェックした後に「利用規約に同意する」のチェックを外した場合、「アカウント作成」が無効になる [LGL-S05] | LGL-S05 #ecde38 | 境界値 | SignUpPage.build() | ✅ |
| 10 | 「利用規約に同意する」の文言をタップした場合、「利用規約に同意する」がチェックされる [LGL-S06] | LGL-S06 #73de7d | 正常系 | SignUpPage.build() | ✅ |
| 11 | 「プライバシーポリシーに同意する」の文言をタップした場合、「プライバシーポリシーに同意する」がチェックされる [LGL-S07] | LGL-S07 #ffd687 | 正常系 | SignUpPage.build() | ✅ |
| 12 | 規約の情報の読み取りの応答を待っている間に正しい入力をして2つチェックした場合、「アカウント作成」は無効のままになる [LGL-S08] | LGL-S08 #6a018e | 境界値 | SignUpPage.build() | ✅ |
| 13 | 2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が accepted を返した場合、ホーム画面に移動し同意ダイアログは表示されず送信が画面の版数で1回呼ばれる [LGL-S09] | LGL-S09 #5f0067 | 正常系 | SignUpPage.build() | ✅ |
| 14 | 2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が UnknownFailure で失敗した場合、ホーム画面の上に2つの行がある同意ダイアログが表示されエラーの表示は出ない [LGL-S10] | LGL-S10 #37cdc8 | 異常系 | SignUpPage.build() | ✅ |
| 15 | 2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が NetworkFailure で失敗した場合、ホーム画面の上に同意ダイアログが表示され「通信エラー」ダイアログは表示されない [LGL-S11] | LGL-S11 #de22d0 | 異常系 | SignUpPage.build() | ✅ |
| 16 | 2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が outdated を返した場合、ホーム画面の上に同意ダイアログが表示される [LGL-S12] | LGL-S12 #8c702f | 異常系 | SignUpPage.build() | ✅ |
| 17 | 2つチェックして「アカウント作成」をタップし、作成が AuthFailure で失敗した場合、「このメールアドレスはすでに使用されています」が表示され新規登録画面のまま入力とチェックが残り送信は0回になる [LGL-S13] | LGL-S13 #9b4522 | 異常系 | SignUpPage.build() | ✅ |
| 18 | `app_config/legal` が無い状態で2つチェックして「アカウント作成」をタップし作成が成功した場合、同意の送信が既定値の版数で1回呼ばれる [LGL-S14] | LGL-S14 #2b5b55 | 異常系 | SignUpPage.build() | ✅ |
| 19 | 規約の情報の読み取りが NetworkFailure で失敗する状態で2つチェックして「アカウント作成」をタップし作成が成功した場合、同意の送信が既定値の版数で1回呼ばれ「通信エラー」ダイアログは表示されない [LGL-S15] | LGL-S15 #33ff63 | 異常系 | SignUpPage.build() | ✅ |
| 20 | 規約の情報の読み取りが UnknownFailure で失敗する状態で2つチェックして「アカウント作成」をタップし作成が成功した場合、同意の送信が既定値の版数で1回呼ばれる [LGL-S16] | LGL-S16 #6adead | 異常系 | SignUpPage.build() | ✅ |
| 21 | メールアドレスを入力して「利用規約に同意する」をチェックし「利用規約を読む」から閲覧画面を開いて戻るボタンで戻った場合、入力とチェックはそのまま残る [LGL-S17] | LGL-S17 #8cc289 | 正常系 | SignUpPage.build() | ✅ |
| 22 | 「プライバシーポリシーを読む」をタップした場合、閲覧画面が開き「プライバシーポリシー」の見出しで privacyUrl の読み込みが指示される [LGL-S18] | LGL-S18 #d1ee1e | 正常系 | SignUpPage.build() | ✅ |
| 23 | `app_config/legal` が無い状態で「利用規約を読む」をタップした場合、既定値の利用規約の URL の読み込みが指示される [LGL-S19] | LGL-S19 #a75402 | 異常系 | SignUpPage.build() | ✅ |
| 24 | メールアドレスを空のままパスワードを入力し2つチェックして「アカウント作成」をタップした場合、「メールアドレスを入力してください」が表示され作成と送信は0回になる [LGL-S20] | LGL-S20 #39240a | 異常系 | SignUpPage.build() | ✅ |
| 25 | 2つチェックして「アカウント作成」をタップし作成の応答を待っている間にもう一度タップした場合、アカウントの作成は1回だけ呼ばれる [LGL-S21] | LGL-S21 #d7c9cd | 境界値 | SignUpPage.build() | ✅ |
| 26 | 幅320・高さ480の端末で新規登録画面を開いた場合、はみ出しが起きずスクロールすると「アカウント作成」ボタンが表示される [LGL-S22] | LGL-S22 #7a3d52 | 境界値 | SignUpPage.build() | ✅ |
| 27 | 「プライバシーポリシーに同意する」をチェックして「プライバシーポリシーを読む」から閲覧画面を開き戻る操作をした場合、新規登録画面に戻りチェックはそのまま残る [LGL-S23] | LGL-S23 #bfac3d | 正常系 | SignUpPage.build() | ✅ |
| 28 | 2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が AuthFailure で失敗した場合、ホーム画面の上に同意ダイアログが表示され「通信エラー」ダイアログは表示されない [LGL-S24] | LGL-S24 #9fe183 | 異常系 | SignUpPage.build() | ✅ |
| 29 | 2つチェックして「アカウント作成」をタップし、作成が NetworkFailure で失敗した場合、「通信エラーが発生しました」が表示され新規登録画面のまま入力とチェックが残り送信は0回になる [LGL-S25] | LGL-S25 #c277a7 | 異常系 | SignUpPage.build() | ✅ |
| 30 | 2つチェックして「アカウント作成」をタップし、作成が UnknownFailure（メッセージ x）で失敗した場合、「エラーが発生しました: x」が表示され新規登録画面のままチェックが残り送信は0回になる [LGL-S26] | LGL-S26 #74002a | 異常系 | SignUpPage.build() | ✅ |
| 31 | `app_config/legal` が無い状態で「プライバシーポリシーを読む」をタップした場合、既定値のプライバシーポリシーの URL の読み込みが指示される [LGL-S27] | LGL-S27 #e0faa8 | 異常系 | SignUpPage.build() | ✅ |
| 32 | 規約の情報の読み取りが NetworkFailure で失敗する状態で「利用規約を読む」をタップした場合、既定値の利用規約の URL の読み込みが指示される [LGL-S28] | LGL-S28 #7d552a | 異常系 | SignUpPage.build() | ✅ |
| 33 | 「利用規約を読む」を素早く2回タップした場合、閲覧画面は1つだけ開き戻るボタン1回で新規登録画面が表示される [LGL-S29] | LGL-S29 #e23394 | 境界値 | SignUpPage.build() | ✅ |
| 34 | 規約の情報の読み取りの応答を待っている間に「利用規約を読む」をタップした場合、閲覧画面は開かない [LGL-S30] | LGL-S30 #938120 | 境界値 | SignUpPage.build() | ✅ |
| 35 | 「プライバシーポリシーに同意する」をチェックして閲覧画面を開き戻るボタンで戻った場合、新規登録画面に戻りチェックはそのまま残る [LGL-S31] | LGL-S31 #2f35ad | 正常系 | SignUpPage.build() | ✅ |
| 36 | 「利用規約に同意する」をチェックして閲覧画面を開き戻る操作をした場合、新規登録画面に戻りチェックはそのまま残る [LGL-S32] | LGL-S32 #7000d3 | 正常系 | SignUpPage.build() | ✅ |
| 37 | 正しい入力をして2つチェックした後に「プライバシーポリシーに同意する」のチェックを外した場合、「アカウント作成」が無効になる [LGL-S33] | LGL-S33 #d9503e | 境界値 | SignUpPage.build() | ✅ |
| 38 | 正しい入力をして「利用規約に同意する」だけをチェックし、無効の「アカウント作成」をタップした場合、作成と送信は0回で新規登録画面のままになる [LGL-S34] | LGL-S34 #bd7cd1 | 異常系 | SignUpPage.build() | ✅ |
| 39 | 正しい入力をして「プライバシーポリシーに同意する」だけをチェックし、無効の「アカウント作成」をタップした場合、作成と送信は0回になる [LGL-S35] | LGL-S35 #72fbac | 異常系 | SignUpPage.build() | ✅ |
| 40 | 幅320・高さ480・文字の拡大率2.0の端末で新規登録画面を開いた場合、はみ出しが起きない [LGL-S36] | LGL-S36 #33ac18 | 境界値 | SignUpPage.build() | ✅ |

## テストケース詳細

### テストケース1: 初期表示: 3 つのフォームフィールドとアカウント作成ボタンが揃っている
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 新規登録画面を開いた
- **操作手順**: 新規登録画面を開く → 上記の入力・チェック・タップを行う → pump
- **期待結果**: 新規登録画面の AppBar・メールアドレス欄のアイコン・パスワード欄のアイコン2つ・「アカウント作成」ボタンが揃っている

### テストケース2: メールアドレスが空のままアカウント作成するとバリデーションエラーが出る
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: メールアドレスを空のまま、2つのチェックボックスをチェックして「アカウント作成」をタップした
- **操作手順**: 新規登録画面を開く → 上記の入力・チェック・タップを行う → pump
- **期待結果**: 「メールアドレスを入力してください」が表示される

### テストケース3: パスワードが 6 文字未満のときバリデーションエラーが出る
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: メールアドレス `test@example.com`、パスワード `12345` を入力し、2つのチェックボックスをチェックして「アカウント作成」をタップした
- **操作手順**: 新規登録画面を開く → 上記の入力・チェック・タップを行う → pump
- **期待結果**: 「6文字以上で入力してください」が表示される

### テストケース4: パスワードと確認が一致しないときバリデーションエラーが出る
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: メールアドレス `test@example.com`、パスワード `password123`、確認 `different` を入力し、2つのチェックボックスをチェックして「アカウント作成」をタップした
- **操作手順**: 新規登録画面を開く → 上記の入力・チェック・タップを行う → pump
- **期待結果**: 「パスワードが一致しません」が表示される

### テストケース5: 新規登録画面を開き規約の情報の読み取りが終わった場合、パスワード（確認）の下に4つの項目がこの順で表示され、2つとも未チェックで「アカウント作成」は無効になる [LGL-S01]
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 新規登録画面を開き、現行の規約の情報の読み取りが終わった
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 「パスワード（確認）」の下、「アカウント作成」ボタンの上に、「利用規約を読む」「利用規約に同意する」「プライバシーポリシーを読む」「プライバシーポリシーに同意する」がこの順で表示される。2つのチェックボックスは未チェック。「アカウント作成」ボタンは無効

### テストケース6: 正しい入力をして「利用規約に同意する」だけをチェックした場合、「アカウント作成」は無効のままになる [LGL-S02]
- **カテゴリ**: 境界値
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、「利用規約に同意する」だけをチェックした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 「アカウント作成」ボタンは無効

### テストケース7: 正しい入力をして「プライバシーポリシーに同意する」だけをチェックした場合、「アカウント作成」は無効のままになる [LGL-S03]
- **カテゴリ**: 境界値
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、「プライバシーポリシーに同意する」だけをチェックした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 「アカウント作成」ボタンは無効

### テストケース8: 正しい入力をして2つのチェックボックスをチェックした場合、「アカウント作成」が有効になる [LGL-S04]
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 「アカウント作成」ボタンが有効になる

### テストケース9: 正しい入力をして2つチェックした後に「利用規約に同意する」のチェックを外した場合、「アカウント作成」が無効になる [LGL-S05]
- **カテゴリ**: 境界値
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックした後、「利用規約に同意する」のチェックを外した
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 「アカウント作成」ボタンが無効になる

### テストケース10: 「利用規約に同意する」の文言をタップした場合、「利用規約に同意する」がチェックされる [LGL-S06]
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 「利用規約に同意する」の文言をタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 「利用規約に同意する」がチェックされる

### テストケース11: 「プライバシーポリシーに同意する」の文言をタップした場合、「プライバシーポリシーに同意する」がチェックされる [LGL-S07]
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 「プライバシーポリシーに同意する」の文言をタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 「プライバシーポリシーに同意する」がチェックされる

### テストケース12: 規約の情報の読み取りの応答を待っている間に正しい入力をして2つチェックした場合、「アカウント作成」は無効のままになる [LGL-S08]
- **カテゴリ**: 境界値
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 新規登録画面を開き、現行の規約の情報の読み取りの応答を待っている間に、正しい入力をして2つのチェックボックスをチェックした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 「アカウント作成」ボタンは無効

### テストケース13: 2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が accepted を返した場合、ホーム画面に移動し同意ダイアログは表示されず送信が画面の版数で1回呼ばれる [LGL-S09]
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックして「アカウント作成」をタップし、アカウントの作成が成功し、同意の送信が `accepted` を返した（初回の同期の後の判定では、同意済みの版数が現行の版数と一致している）
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動する。同意ダイアログは表示されない。同意の送信が1回、利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` を引数に呼ばれる

### テストケース14: 2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が UnknownFailure で失敗した場合、ホーム画面の上に2つの行がある同意ダイアログが表示されエラーの表示は出ない [LGL-S10]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックして「アカウント作成」をタップし、アカウントの作成が成功し、同意の送信が `UnknownFailure` で失敗した（新しい uid は未同意のまま）
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動し、その上に同意ダイアログが表示される。「利用規約に同意する」「プライバシーポリシーに同意する」の両方が表示される。エラーのスナックバー・ダイアログは表示されない

### テストケース15: 2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が NetworkFailure で失敗した場合、ホーム画面の上に同意ダイアログが表示され「通信エラー」ダイアログは表示されない [LGL-S11]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックして「アカウント作成」をタップし、アカウントの作成が成功し、同意の送信が `NetworkFailure` で失敗した（新しい uid は未同意のまま。その後の判定は成功する）
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動し、その上に同意ダイアログが表示される。「通信エラー」ダイアログは表示されない

### テストケース16: 2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が outdated を返した場合、ホーム画面の上に同意ダイアログが表示される [LGL-S12]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックして「アカウント作成」をタップし、アカウントの作成が成功し、同意の送信が `outdated` を返した（新しい uid は未同意のまま）
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動し、その上に同意ダイアログが表示される

### テストケース17: 2つチェックして「アカウント作成」をタップし、作成が AuthFailure で失敗した場合、「このメールアドレスはすでに使用されています」が表示され新規登録画面のまま入力とチェックが残り送信は0回になる [LGL-S13]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックして「アカウント作成」をタップし、アカウントの作成が `AuthFailure` で失敗した
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: スナックバーに「このメールアドレスはすでに使用されています」が表示される。表示中の画面は新規登録画面のまま。「メールアドレス」は `a@example.com` のまま、2つのチェックボックスはチェックされたまま。同意の送信は0回

### テストケース18: `app_config/legal` が無い状態で2つチェックして「アカウント作成」をタップし作成が成功した場合、同意の送信が既定値の版数で1回呼ばれる [LGL-S14]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: `app_config/legal` が無い状態で新規登録画面を開き、正しい入力をして2つのチェックボックスをチェックし「アカウント作成」をタップし、アカウントの作成が成功した
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 同意の送信が1回、利用規約 `2026-10-12`・プライバシーポリシー `2026-10-12` を引数に呼ばれる

### テストケース19: 規約の情報の読み取りが NetworkFailure で失敗する状態で2つチェックして「アカウント作成」をタップし作成が成功した場合、同意の送信が既定値の版数で1回呼ばれ「通信エラー」ダイアログは表示されない [LGL-S15]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 現行の規約の情報の読み取りが `NetworkFailure` で失敗する状態で新規登録画面を開き、正しい入力をして2つのチェックボックスをチェックし「アカウント作成」をタップし、アカウントの作成が成功した
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 同意の送信が1回、利用規約 `2026-10-12`・プライバシーポリシー `2026-10-12` を引数に呼ばれる。「通信エラー」ダイアログは表示されない

### テストケース20: 規約の情報の読み取りが UnknownFailure で失敗する状態で2つチェックして「アカウント作成」をタップし作成が成功した場合、同意の送信が既定値の版数で1回呼ばれる [LGL-S16]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 現行の規約の情報の読み取りが `UnknownFailure` で失敗する状態で新規登録画面を開き、正しい入力をして2つのチェックボックスをチェックし「アカウント作成」をタップし、アカウントの作成が成功した
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 同意の送信が1回、利用規約 `2026-10-12`・プライバシーポリシー `2026-10-12` を引数に呼ばれる

### テストケース21: メールアドレスを入力して「利用規約に同意する」をチェックし「利用規約を読む」から閲覧画面を開いて戻るボタンで戻った場合、入力とチェックはそのまま残る [LGL-S17]
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 「メールアドレス」に `a@example.com` を入力し、「利用規約に同意する」をチェックした後、「利用規約を読む」をタップし、閲覧画面の戻るボタンをタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 閲覧画面（上部のバーに「利用規約」、WebView に `https://example.com/terms` の読み込みが指示される）が開き、戻るボタンで新規登録画面に戻る。「メールアドレス」は `a@example.com` のまま、「利用規約に同意する」はチェックされたまま

### テストケース22: 「プライバシーポリシーを読む」をタップした場合、閲覧画面が開き「プライバシーポリシー」の見出しで privacyUrl の読み込みが指示される [LGL-S18]
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 「プライバシーポリシーを読む」をタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 閲覧画面が開き、上部のバーに「プライバシーポリシー」が表示される。WebView に `https://example.com/privacy` の読み込みが指示される

### テストケース23: `app_config/legal` が無い状態で「利用規約を読む」をタップした場合、既定値の利用規約の URL の読み込みが指示される [LGL-S19]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: `app_config/legal` が無い状態で新規登録画面を開き、「利用規約を読む」をタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: WebView に `https://word-pods-web.web.app/terms` の読み込みが指示される

### テストケース24: メールアドレスを空のままパスワードを入力し2つチェックして「アカウント作成」をタップした場合、「メールアドレスを入力してください」が表示され作成と送信は0回になる [LGL-S20]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 「メールアドレス」を空のまま、パスワードとパスワード（確認）に `password1` を入力し、2つのチェックボックスをチェックして「アカウント作成」をタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 「メールアドレスを入力してください」が表示される。アカウントの作成は0回、同意の送信は0回

### テストケース25: 2つチェックして「アカウント作成」をタップし作成の応答を待っている間にもう一度タップした場合、アカウントの作成は1回だけ呼ばれる [LGL-S21]
- **カテゴリ**: 境界値
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックして「アカウント作成」をタップし、アカウントの作成の応答を待っている間に、もう一度「アカウント作成」をタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: アカウントの作成は1回だけ呼ばれる

### テストケース26: 幅320・高さ480の端末で新規登録画面を開いた場合、はみ出しが起きずスクロールすると「アカウント作成」ボタンが表示される [LGL-S22]
- **カテゴリ**: 境界値
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 画面の大きさが幅 320・高さ 480 の端末で、新規登録画面を開いた
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 表示のはみ出し（オーバーフロー）が起きない。スクロールすると「アカウント作成」ボタンが表示される

### テストケース27: 「プライバシーポリシーに同意する」をチェックして「プライバシーポリシーを読む」から閲覧画面を開き戻る操作をした場合、新規登録画面に戻りチェックはそのまま残る [LGL-S23]
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 「プライバシーポリシーに同意する」をチェックした後、「プライバシーポリシーを読む」をタップし、閲覧画面で戻る操作をした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 新規登録画面に戻り、「プライバシーポリシーに同意する」はチェックされたまま

### テストケース28: 2つチェックして「アカウント作成」をタップし、作成が成功して同意の送信が AuthFailure で失敗した場合、ホーム画面の上に同意ダイアログが表示され「通信エラー」ダイアログは表示されない [LGL-S24]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックして「アカウント作成」をタップし、アカウントの作成が成功し、同意の送信が `AuthFailure` で失敗した（新しい uid は未同意のまま。その後の判定は成功する）
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動し、その上に同意ダイアログが表示される。「通信エラー」ダイアログは表示されない

### テストケース29: 2つチェックして「アカウント作成」をタップし、作成が NetworkFailure で失敗した場合、「通信エラーが発生しました」が表示され新規登録画面のまま入力とチェックが残り送信は0回になる [LGL-S25]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックして「アカウント作成」をタップし、アカウントの作成が `NetworkFailure` で失敗した
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: スナックバーに「通信エラーが発生しました」が表示される。表示中の画面は新規登録画面のまま。「メールアドレス」は `a@example.com` のまま、2つのチェックボックスはチェックされたまま。同意の送信は0回

### テストケース30: 2つチェックして「アカウント作成」をタップし、作成が UnknownFailure（メッセージ x）で失敗した場合、「エラーが発生しました: x」が表示され新規登録画面のままチェックが残り送信は0回になる [LGL-S26]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックして「アカウント作成」をタップし、アカウントの作成が `UnknownFailure`（メッセージ `x`）で失敗した
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: スナックバーに「エラーが発生しました: x」が表示される。表示中の画面は新規登録画面のまま。2つのチェックボックスはチェックされたまま。同意の送信は0回

### テストケース31: `app_config/legal` が無い状態で「プライバシーポリシーを読む」をタップした場合、既定値のプライバシーポリシーの URL の読み込みが指示される [LGL-S27]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: `app_config/legal` が無い状態で新規登録画面を開き、「プライバシーポリシーを読む」をタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: WebView に `https://word-pods-web.web.app/privacy` の読み込みが指示される

### テストケース32: 規約の情報の読み取りが NetworkFailure で失敗する状態で「利用規約を読む」をタップした場合、既定値の利用規約の URL の読み込みが指示される [LGL-S28]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 現行の規約の情報の読み取りが `NetworkFailure` で失敗する状態で新規登録画面を開き、「利用規約を読む」をタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: WebView に `https://word-pods-web.web.app/terms` の読み込みが指示される

### テストケース33: 「利用規約を読む」を素早く2回タップした場合、閲覧画面は1つだけ開き戻るボタン1回で新規登録画面が表示される [LGL-S29]
- **カテゴリ**: 境界値
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 「利用規約を読む」を素早く2回タップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 閲覧画面は1つだけ開く。閲覧画面の戻るボタンを1回タップすると新規登録画面が表示される

### テストケース34: 規約の情報の読み取りの応答を待っている間に「利用規約を読む」をタップした場合、閲覧画面は開かない [LGL-S30]
- **カテゴリ**: 境界値
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 新規登録画面を開き、現行の規約の情報の読み取りの応答を待っている間に、「利用規約を読む」をタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 閲覧画面は開かない

### テストケース35: 「プライバシーポリシーに同意する」をチェックして閲覧画面を開き戻るボタンで戻った場合、新規登録画面に戻りチェックはそのまま残る [LGL-S31]
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 「プライバシーポリシーに同意する」をチェックした後、「プライバシーポリシーを読む」をタップし、閲覧画面の戻るボタンをタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 新規登録画面に戻り、「プライバシーポリシーに同意する」はチェックされたまま

### テストケース36: 「利用規約に同意する」をチェックして閲覧画面を開き戻る操作をした場合、新規登録画面に戻りチェックはそのまま残る [LGL-S32]
- **カテゴリ**: 正常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 「利用規約に同意する」をチェックした後、「利用規約を読む」をタップし、閲覧画面で戻る操作をした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 新規登録画面に戻り、「利用規約に同意する」はチェックされたまま

### テストケース37: 正しい入力をして2つチェックした後に「プライバシーポリシーに同意する」のチェックを外した場合、「アカウント作成」が無効になる [LGL-S33]
- **カテゴリ**: 境界値
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、2つのチェックボックスをチェックした後、「プライバシーポリシーに同意する」のチェックを外した
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 「アカウント作成」ボタンが無効になる

### テストケース38: 正しい入力をして「利用規約に同意する」だけをチェックし、無効の「アカウント作成」をタップした場合、作成と送信は0回で新規登録画面のままになる [LGL-S34]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、「利用規約に同意する」だけをチェックした状態で、無効の「アカウント作成」ボタンをタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: アカウントの作成は0回、同意の送信は0回。表示中の画面は新規登録画面のまま

### テストケース39: 正しい入力をして「プライバシーポリシーに同意する」だけをチェックし、無効の「アカウント作成」をタップした場合、作成と送信は0回になる [LGL-S35]
- **カテゴリ**: 異常系
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 正しい入力をし、「プライバシーポリシーに同意する」だけをチェックした状態で、無効の「アカウント作成」ボタンをタップした
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: アカウントの作成は0回、同意の送信は0回

### テストケース40: 幅320・高さ480・文字の拡大率2.0の端末で新規登録画面を開いた場合、はみ出しが起きない [LGL-S36]
- **カテゴリ**: 境界値
- **対象メソッド**: SignUpPage.build()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）のテスト用アプリを、ログインしていない状態で起動し、ログイン画面（/login）の「新規登録」から新規登録画面（/sign-up）を開く。手書き Fake（LegalRepository・AuthRepository・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、規約の情報の読み取りは成功
- **入力値・テスト条件**: 画面の大きさが幅 320・高さ 480、文字の拡大率が 2.0 の端末で、新規登録画面を開いた
- **操作手順**: Fake の状態（規約の情報の読み取り結果と応答待ち・同意済みの版数・新規登録と同意の送信の結果）を作り、入力・チェック・タップ・戻る操作を pump で進める
- **期待結果**: 表示のはみ出し（オーバーフロー）が起きない

## 検証の範囲（補足）

- LGL-S01 の並び順は、各項目の画面上の縦位置（パスワード（確認）→ 利用規約を読む → 利用規約に同意する → プライバシーポリシーを読む → プライバシーポリシーに同意する → アカウント作成）で確かめている
- LGL-S22・S36 は、新規登録画面を開いた後に画面の大きさ（S36 は文字の拡大率も）を変えてからはみ出し（`takeException`）を確かめている
