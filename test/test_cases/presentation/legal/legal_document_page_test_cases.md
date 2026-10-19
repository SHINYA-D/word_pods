## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/presentation/legal/legal_document_page.dart |
| 仕様書 | docs/detailed_design/legal_consent/legal_consent.md |
| クラス名 | LegalDocumentPage / LegalConsentGate / LegalConsentDialog / LegalLinksSection |
| テスト対象メソッド | LegalDocumentPage.build() / LegalConsentGate / LegalConsentDialog / LegalLinksSection |

仕様書 3章（同意ダイアログ・閲覧画面・設定画面の「このアプリについて」）の Widget テスト。同意ダイアログは画面ではなくゲートなので、
本物のルーターと AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate を `MaterialApp.router` に組み（lib/app.dart と同じ配線。
起動時に withdrawn.initialize() → 認証状態の取得 → legalConsentViewModel.start() と withdrawn.check()、復帰時に withdrawn.check() と legalConsentViewModel.check()）、
手書き Fake（LegalRepository・AuthRepository・AccountDeletionRepository）と Mock Repository で検証する。
WebView は実物を使えないので legalWebViewBuilderProvider を差し替え、builder に渡った url と attempt を記録し、読み込みの通知（onFinished / onError。HTTP 404 も onError）をテストから呼ぶ。
ViewModel（LegalConsentViewModel）のロジック網羅は `legal_consent_view_model_test.dart`（仕様書4章）が別に担当する（本項目書では扱わない）。

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | 未同意の状態でアプリを起動した場合、ホーム画面の上に同意ダイアログが表示され、2つのチェックは未チェックで「同意する」は無効・「ログアウト」は有効になる [LGL-D01] | LGL-D01 #53ddab | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 2 | プライバシーポリシーだけ版数が古い状態でアプリを起動した場合、プライバシーポリシーの行だけの同意ダイアログが表示される [LGL-D02] | LGL-D02 #942bbb | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 3 | 利用規約だけ版数が古い状態でアプリを起動した場合、利用規約の行だけの同意ダイアログが表示される [LGL-D03] | LGL-D03 #b8b198 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 4 | 同意済みの版数が現行の版数と一致する状態でアプリを起動した場合、ホーム画面が表示され同意ダイアログは表示されない [LGL-D04] | LGL-D04 #1a889a | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 5 | 利用規約の記録だけがありプライバシーポリシーの記録が無い状態でアプリを起動した場合、プライバシーポリシーの行だけの同意ダイアログが表示される [LGL-D05] | LGL-D05 #3cfc31 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 6 | ログインしていない状態でメールアドレスとパスワードのログインが成功した場合、ホーム画面に移動し同意ダイアログが表示される [LGL-D07] | LGL-D07 #b9a0bc | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 7 | ログインしていない状態で Google のログインが成功した場合、ホーム画面に移動し同意ダイアログが表示される [LGL-D08] | LGL-D08 #1c95bd | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 8 | 未同意の状態でオフラインで起動し判定が NetworkFailure で失敗した場合、ホーム画面が表示され同意ダイアログは表示されない [LGL-D09] | LGL-D09 #294ee6 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 9 | 未同意の状態で現行の版数の読み取りが UnknownFailure で失敗した場合、ホーム画面が表示され同意ダイアログも失敗の表示も出ない [LGL-D10] | LGL-D10 #c4f86d | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 10 | ログインしていない状態でアプリを起動した場合、ログイン画面が表示され同意ダイアログは表示されず fetchLegalConfig は0回である [LGL-D11] | LGL-D11 #71de7d | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 11 | 未同意で退会処理の記録が requested の状態でアプリを起動した場合、「退会処理が完了していません」ダイアログが表示され同意ダイアログは表示されない [LGL-D12] | LGL-D12 #420a71 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 12 | 退会済みの記録があり accounts/A が無い状態でアプリを起動した場合、「アカウントが削除されました」ダイアログが表示され同意ダイアログは表示されない [LGL-D13] | LGL-D13 #e912d9 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 13 | 同意済みで起動してホーム画面を表示中に現行の termsVersion が変わり復帰した場合、利用規約の行だけの同意ダイアログがホーム画面の上に表示される [LGL-D14] | LGL-D14 #594d28 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 14 | 同意ダイアログの表示中に「利用規約に同意する」をチェックして復帰した場合、同意ダイアログは1つだけでチェックは残り fetchLegalConfig は起動時の1回だけである [LGL-D15] | LGL-D15 #f249f9 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 15 | 未同意でオフライン起動してホーム画面を表示し、バックグラウンドの間にオンラインに戻り、その後復帰した場合、同意ダイアログがホーム画面の上に1つ表示される [LGL-D16] | LGL-D16 #996998 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 16 | 同意ダイアログの表示中に退会済みの記録ができた場合、同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される [LGL-D17] | LGL-D17 #81734c | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 17 | 強制ログアウトの記録がある uid で Firebase 上はログイン中の未同意の状態で起動した場合、ログイン画面が表示され同意ダイアログは表示されず fetchLegalConfig は0回である [LGL-D18] | LGL-D18 #9932a4 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 18 | 未同意の状態で起動して判定の応答を待っている場合、ホーム画面が表示され同意ダイアログは表示されない [LGL-D19] | LGL-D19 #ec604d | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 19 | 幅320・高さ480の端末で未同意の状態で起動した場合、同意ダイアログが表示されはみ出しが起きず、スクロールすると「同意する」ボタンが表示される [LGL-D20] | LGL-D20 #ce3f05 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 20 | 同意ダイアログの表示中に Firebase のログイン状態が解除された場合、同意ダイアログが閉じログイン画面が表示される [LGL-D21] | LGL-D21 #f721c1 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 21 | 同意ダイアログの表示中は、「キャンセル」「同意しない」のボタンが表示されない [LGL-D22] | LGL-D22 #135203 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 22 | スプラッシュ画面を表示している間に判定が終わった場合、スプラッシュ画面の間は同意ダイアログが表示されず、ホーム画面に移動した後にその上に表示される [LGL-D23] | LGL-D23 #861bff | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 23 | 閲覧画面を開いている間に退会済みの記録ができた場合、閲覧画面と同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される [LGL-D24] | LGL-D24 #6ae417 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 24 | 閲覧画面を開いている間に Firebase のログイン状態が解除された場合、閲覧画面と同意ダイアログが閉じログイン画面が表示される [LGL-D25] | LGL-D25 #6e45ef | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 25 | 「利用規約に同意する」をチェックして閲覧画面を開いている間に復帰した場合、閲覧画面は表示されたままで、戻ると同意ダイアログが1つだけ表示されチェックは残り fetchLegalConfig は1回である [LGL-D26] | LGL-D26 #fc9764 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 26 | 未同意で退会処理の記録が serverDone の状態でアプリを起動した場合、「退会処理が完了していません」ダイアログが表示され同意ダイアログは表示されない [LGL-D27] | LGL-D27 #6e4d5c | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 27 | 退会処理の記録が requested で再開ダイアログの表示中に復帰した場合、再開ダイアログは表示されたままで同意ダイアログは表示されない [LGL-D28] | LGL-D28 #9543b4 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 28 | 未同意でログイン済みの状態でアプリを起動した場合、同意ダイアログが1つだけ表示され fetchLegalConfig は1回だけ呼ばれる [LGL-D29] | LGL-D29 #5f5c91 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 29 | 「同意する」をタップして送信の応答を待っている間に復帰した場合、同意ダイアログは1つだけでローディングが表示されたままで送信は1回だけ呼ばれる [LGL-D30] | LGL-D30 #aca061 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 30 | 「同意する」をタップして送信の応答を待っている間に退会済みの記録ができた場合、同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される [LGL-D31] | LGL-D31 #02598b | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 31 | uid A に強制ログアウトの記録がありログインしていない状態で uid B のログインが成功した場合、ホーム画面に移動し同意ダイアログが表示される [LGL-D32] | LGL-D32 #c0f15f | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 32 | 同意済みの uid のログインが成功した場合、ホーム画面に移動し同意ダイアログは表示されない [LGL-D33] | LGL-D33 #446a97 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 33 | 同意済みで起動してホーム画面を表示中に現行の privacyVersion が変わり復帰した場合、プライバシーポリシーの行だけの同意ダイアログが表示される [LGL-D34] | LGL-D34 #97e7f9 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 34 | 同意済みで設定画面を表示中に現行の termsVersion が変わり復帰した場合、設定画面の上に同意ダイアログが表示され画面のパスは /settings のままである [LGL-D35] | LGL-D35 #3c0688 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 35 | 幅320・高さ480・文字の拡大率2.0の端末で未同意の状態で起動した場合、同意ダイアログが表示されはみ出しが起きない [LGL-D36] | LGL-D36 #8be97d | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 36 | 判定の応答を待っている間に Firebase のログイン状態が解除され、その後に判定が同意が必要と返した場合、ログイン画面が表示され同意ダイアログは表示されない [LGL-D37] | LGL-D37 #07aee8 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 37 | 判定の応答を待っている間に退会済みの記録が見つかりお知らせが表示され、その後に判定が同意が必要と返した場合、お知らせダイアログは表示されたままで同意ダイアログは表示されない [LGL-D38] | LGL-D38 #51897c | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 38 | 判定の応答を待っている間に設定画面から退会を始めて退会処理の記録が requested になり、その後に判定が同意が必要と返した場合、同意ダイアログは表示されない [LGL-D39] | LGL-D39 #063e68 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 39 | 「アカウントが削除されました」ダイアログの表示中に復帰した場合、ダイアログは表示されたままで同意ダイアログは表示されず fetchLegalConfig の呼び出し回数は増えない [LGL-D40] | LGL-D40 #1f1fa4 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 40 | 「フォルダを作成」ダイアログに「英単語」を入力中に現行の termsVersion が変わり復帰した場合、その上に同意ダイアログが表示され、同意が成功すると「英単語」が入ったまま「フォルダを作成」ダイアログが表示される [LGL-D41] | LGL-D41 #ebc082 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 41 | 「ログアウト」の応答を待っている間に退会済みの記録ができた場合、同意ダイアログが閉じお知らせが表示され、その後にログアウトが UnknownFailure を返しても「ログアウトできませんでした。」は表示されない [LGL-D42] | LGL-D42 #7596dd | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 42 | 「ログアウト」の応答を待っている間に復帰した場合、同意ダイアログは1つだけでローディングが表示されたままで fetchLegalConfig の呼び出し回数は増えない [LGL-D43] | LGL-D43 #73c95b | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 43 | 設定画面の「利用規約」から閲覧画面を開いている間に現行の termsVersion が変わり復帰した場合、閲覧画面の上に利用規約の行だけの同意ダイアログが表示される [LGL-D44] | LGL-D44 #3e05e6 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 44 | 閲覧画面の上に表示された同意ダイアログで同意が成功した場合、同意ダイアログが閉じ閲覧画面が表示され、戻ると設定画面が表示される [LGL-D45] | LGL-D45 #bac8f0 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 45 | 設定画面の「利用規約」から閲覧画面を開いている間に退会済みの記録ができた場合、「アカウントが削除されました」ダイアログが表示され同意ダイアログは表示されない [LGL-D46] | LGL-D46 #43a3e5 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 46 | 設定画面の「利用規約」から閲覧画面を開いている間に Firebase のログイン状態が解除された場合、閲覧画面が閉じログイン画面が表示される [LGL-D47] | LGL-D47 #873e7e | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 47 | 「フォルダを作成」ダイアログの上に同意ダイアログが表示されている間に退会済みの記録ができた場合、同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される [LGL-D48] | LGL-D48 #17caa4 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 48 | 「フォルダを作成」ダイアログの上に同意ダイアログが表示されている間に Firebase のログイン状態が解除された場合、2つのダイアログが閉じログイン画面が表示される [LGL-D49] | LGL-D49 #06bcc7 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 49 | 未同意でオフライン起動してホーム画面を表示し、フォアグラウンドのままオンラインに戻った場合、同意ダイアログがホーム画面の上に表示される [LGL-D50] | LGL-D50 #c6ecdb | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 50 | app_config/legal が無く未同意の状態で起動した場合、ホーム画面の上に2つの行がある同意ダイアログが表示される [LGL-D51] | LGL-D51 #9e309b | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 51 | app_config/legal が無く同意済みの版数が既定値（2026-10-12）と同じ状態で起動した場合、ホーム画面が表示され同意ダイアログは表示されない [LGL-D52] | LGL-D52 #03fe6a | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 52 | app_config/legal が無く利用規約だけ既定値と同じ版数で同意済みの状態で起動した場合、プライバシーポリシーの行だけの同意ダイアログが表示される [LGL-D53] | LGL-D53 #3169fb | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 53 | メールアドレスとパスワードでログインして初回の同期の完了を待っている場合、同意ダイアログは表示されず fetchLegalConfig は0回である [LGL-D54] | LGL-D54 #07c7d7 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 54 | 新規登録画面で2つにチェックして「アカウント作成」をタップし、同意の送信の応答を待っている場合、同意ダイアログは表示されず fetchLegalConfig は新規登録画面を開いたときの1回だけである [LGL-D55] | LGL-D55 #0c1f5d | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 55 | 同意ダイアログの表示中に「利用規約に同意する」をチェックし、オフラインになってからオンラインに戻った場合、同意ダイアログは1つだけでチェックは残り fetchLegalConfig は起動時の1回だけである [LGL-D56] | LGL-D56 #f6dda1 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 56 | ログイン画面の表示中にオフラインになってからオンラインに戻った場合、同意ダイアログは表示されず fetchLegalConfig は0回である [LGL-D57] | LGL-D57 #bfbbbb | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 57 | 退会処理の記録が requested で再開ダイアログの表示中にオフラインになってからオンラインに戻った場合、同意ダイアログは表示されず再開ダイアログは表示されたままである [LGL-D58] | LGL-D58 #e61836 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 58 | Google でログインして初回の同期の完了を待っている場合、同意ダイアログは表示されず fetchLegalConfig は0回である [LGL-D59] | LGL-D59 #9e5315 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 59 | メールアドレスとパスワードでログインして初回の同期が失敗して終わった場合、ホーム画面に移動し同意ダイアログが表示される [LGL-D60] | LGL-D60 #b5ba8f | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 60 | 新規登録画面を開いて規約の情報の読み取りの応答を待っている場合、ローディングは表示されず「アカウント作成」ボタンは無効である [LGL-D61] | LGL-D61 #1dac48 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 61 | 「利用規約に同意する」のチェックボックスをタップした場合、利用規約だけがチェックされ「同意する」は無効のままである [LGL-A01] | LGL-A01 #a8791e | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 62 | 2つのチェックボックスをタップした場合、2つともチェックされ「同意する」が有効になる [LGL-A02] | LGL-A02 #65471b | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 63 | 2つチェックした後に「利用規約に同意する」をもう一度タップした場合、利用規約が未チェックになり「同意する」が無効になる [LGL-A03] | LGL-A03 #14d563 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 64 | プライバシーポリシーの行だけの同意ダイアログで「プライバシーポリシーに同意する」をタップした場合、「同意する」が有効になる [LGL-A04] | LGL-A04 #a76912 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 65 | 「利用規約に同意する」の文言をタップした場合、利用規約がチェックされる [LGL-A05] | LGL-A05 #73de7d | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 66 | 2つチェックして「同意する」をタップし送信が accepted を返した場合、同意ダイアログが閉じホーム画面が表示され送信が現行の版数で1回呼ばれる [LGL-A06] | LGL-A06 #440c76 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 67 | 利用規約の行だけの同意ダイアログで同意して送信が accepted を返した場合、同意ダイアログが閉じ送信が利用規約の版数とプライバシーポリシー null で1回呼ばれる [LGL-A07] | LGL-A07 #891803 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 68 | 「同意する」をタップして送信の応答を待っている場合、同意ダイアログのボタン・チェックボックス・リンクが無効になりローディングが表示される [LGL-A08] | LGL-A08 #974b2a | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 69 | 送信の応答を待っている間に「同意する」をもう一度タップした場合、送信は1回だけ呼ばれる [LGL-A09] | LGL-A09 #4c33f2 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 70 | 送信が UnknownFailure で失敗した場合、同意ダイアログが表示されたままチェックは残り「同意を送信できませんでした。」が表示され「同意する」は有効である [LGL-A10] | LGL-A10 #0bf32f | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 71 | 1回目の送信が UnknownFailure で失敗した後に「同意する」をもう一度タップし2回目が accepted を返した場合、同意ダイアログが閉じ送信は合計2回呼ばれる [LGL-A11] | LGL-A11 #7b7609 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 72 | 2つチェックした後に現行の termsVersion が変わり送信が outdated を返した場合、2つの行が未チェックで表示し直され「内容が更新されました。」が表示され「同意する」は無効である [LGL-A12] | LGL-A12 #c2f1f9 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 73 | outdated で表示し直された同意ダイアログで再度同意して2回目の送信が accepted を返した場合、同意ダイアログが閉じ2回目の送信は利用規約 2026-02-01・プライバシーポリシー 2026-01-01 で呼ばれる [LGL-A13] | LGL-A13 #5bfd11 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 74 | 送信の処理中ではない状態で同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままで送信は0回である [LGL-A14] | LGL-A14 #a656b8 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 75 | 送信の処理中ではない状態で戻る操作をした場合、同意ダイアログは表示されたままで画面のパスは /home のままで送信は0回である [LGL-A15] | LGL-A15 #fb8053 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 76 | 送信の応答を待っている間に同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままである [LGL-A16] | LGL-A16 #610925 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 77 | 送信の応答を待っている間に戻る操作をした場合、同意ダイアログは表示されたままである [LGL-A17] | LGL-A17 #2d1b41 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 78 | 「利用規約に同意する」だけをチェックした状態で無効の「同意する」をタップした場合、同意ダイアログは表示されたままで送信は0回である [LGL-A18] | LGL-A18 #184e75 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 79 | 同意して送信が accepted を返した後に復帰した場合、同意ダイアログは表示されない [LGL-A19] | LGL-A19 #35699e | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 80 | 「プライバシーポリシーに同意する」のチェックボックスをタップした場合、プライバシーポリシーだけがチェックされ「同意する」は無効のままである [LGL-A20] | LGL-A20 #ee1c6f | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 81 | 2つチェックした後に「プライバシーポリシーに同意する」をもう一度タップした場合、プライバシーポリシーが未チェックになり「同意する」が無効になる [LGL-A21] | LGL-A21 #15478b | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 82 | 「プライバシーポリシーに同意する」の文言をタップした場合、プライバシーポリシーがチェックされる [LGL-A22] | LGL-A22 #ffd687 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 83 | 「プライバシーポリシーに同意する」だけをチェックした状態で無効の「同意する」をタップした場合、同意ダイアログは表示されたままで送信は0回である [LGL-A23] | LGL-A23 #2baf10 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 84 | プライバシーポリシーの行だけの同意ダイアログで同意して送信が accepted を返した場合、同意ダイアログが閉じ送信が利用規約 null・プライバシーポリシーの版数で1回呼ばれる [LGL-A24] | LGL-A24 #6bde5b | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 85 | 2つチェックした後に現行の privacyVersion が変わり送信が outdated を返した場合、2つの行が未チェックで表示し直され「内容が更新されました。」が表示され「同意する」は無効である [LGL-A25] | LGL-A25 #8a34b3 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 86 | privacyVersion の改定で outdated になり再度同意して2回目の送信が accepted を返した場合、同意ダイアログが閉じ2回目の送信は利用規約 2026-01-01・プライバシーポリシー 2026-02-01 で呼ばれる [LGL-A26] | LGL-A26 #6b0f42 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 87 | 設定画面で表示された同意ダイアログで同意して送信が accepted を返した場合、同意ダイアログが閉じ画面のパスは /settings のままである [LGL-A27] | LGL-A27 #10eb04 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 88 | 送信の処理中ではない状態で同意ダイアログの背後のボトムナビ「設定」の位置をタップした場合、同意ダイアログは表示されたままで画面のパスは /home のままである [LGL-A28] | LGL-A28 #197844 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 89 | outdated の後の判定し直しが NetworkFailure で失敗した場合、同意ダイアログが閉じホーム画面が表示される [LGL-A29] | LGL-A29 #7f09f4 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 90 | 別の端末で現行の版数に同意済みになった状態で送信が outdated を返した場合、同意ダイアログが閉じホーム画面が表示される [LGL-A30] | LGL-A30 #8715d6 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 91 | 利用規約の行だけの同意ダイアログで privacyVersion が変わり送信が outdated を返した場合、2つの行が未チェックで表示し直される [LGL-A31] | LGL-A31 #f1e422 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 92 | 1回目の送信が失敗した後に「同意する」をもう一度タップして2回目の応答を待っている場合、「同意を送信できませんでした。」は表示されずローディングが表示される [LGL-A32] | LGL-A32 #78a7c9 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 93 | 送信の応答を待っている間にログイン状態が解除され、その後に送信が NetworkFailure で失敗した場合、ログイン画面が表示され「通信エラー」ダイアログも同意ダイアログも表示されない [LGL-A33] | LGL-A33 #221e3f | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 94 | outdated の後の判定し直しが UnknownFailure で失敗した場合、同意ダイアログが閉じホーム画面が表示される [LGL-A34] | LGL-A34 #6cdf00 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 95 | 送信の応答を待っている間にログイン状態が解除され、その後に送信が accepted を返した場合、ログイン画面が表示され同意ダイアログは表示されない [LGL-A36] | LGL-A36 #3f26e9 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 96 | outdated で表示し直された同意ダイアログで「利用規約に同意する」をチェックした場合、「内容が更新されました。」は表示されたままである [LGL-A37] | LGL-A37 #09e45a | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 97 | 「ログアウト」をタップしてログアウトが成功した場合、同意ダイアログが閉じログイン画面に移動し SignOutUseCase が1回呼ばれ確認ダイアログは表示されず送信は0回である [LGL-A38] | LGL-A38 #0d4d37 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 98 | 送信の応答を待っている間に「ログアウト」をタップした場合、SignOutUseCase は0回で同意ダイアログは表示されたままである [LGL-A39] | LGL-A39 #3401f8 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 99 | 「利用規約に同意する」をチェックして「ログアウト」が UnknownFailure で失敗した場合、「ログアウトできませんでした。」が表示されチェックは残り画面のパスは /home のままである [LGL-A40] | LGL-A40 #613500 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 100 | ログアウトの応答を待っている間に「ログアウト」をもう一度タップした場合、SignOutUseCase は1回だけ呼ばれる [LGL-A41] | LGL-A41 #f18917 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 101 | 「ログアウト」をタップしてログアウトの応答を待っている場合、ボタン・チェックボックス・リンクが無効になりローディングが表示される [LGL-A42] | LGL-A42 #e99bc7 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 102 | 送信が失敗して「同意を送信できませんでした。」が表示された後に「ログアウト」をタップして応答を待っている場合、「同意を送信できませんでした。」は表示されない [LGL-A43] | LGL-A43 #d68c2b | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 103 | ログアウトの応答を待っている間に同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままである [LGL-A44] | LGL-A44 #d6a0ad | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 104 | ログアウトの応答を待っている間に戻る操作をした場合、同意ダイアログは表示されたままである [LGL-A45] | LGL-A45 #01678e | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 105 | ログアウトが失敗して「ログアウトできませんでした。」が表示された後に「プライバシーポリシーに同意する」をチェックした場合、「ログアウトできませんでした。」は表示されたままである [LGL-A46] | LGL-A46 #3c85d6 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 106 | 送信が失敗して「同意を送信できませんでした。」が表示された後に「利用規約に同意する」のチェックを外した場合、「同意を送信できませんでした。」は表示されたままである [LGL-A47] | LGL-A47 #ecca7e | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 107 | ログアウトが失敗して「ログアウトできませんでした。」が表示された後に「同意する」をタップして応答を待っている場合、「ログアウトできませんでした。」は表示されない [LGL-A48] | LGL-A48 #2aee97 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 108 | ログアウトが失敗して「ログアウトできませんでした。」が表示された後に「ログアウト」をもう一度タップして応答を待っている場合、「ログアウトできませんでした。」は表示されない [LGL-A49] | LGL-A49 #82b738 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 109 | 「内容が更新されました。」が表示された後に「ログアウト」をタップして応答を待っている場合、「内容が更新されました。」は表示されない [LGL-A50] | LGL-A50 #0964c4 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 110 | 「内容が更新されました。」が表示された後に再度チェックして「同意する」をタップし2回目の応答を待っている場合、「内容が更新されました。」は表示されない [LGL-A51] | LGL-A51 #c95083 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 111 | 「ログアウト」が NetworkFailure で失敗した場合、「ログアウトできませんでした。」が表示され「通信エラー」ダイアログは表示されない [LGL-A52] | LGL-A52 #a7d8c1 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 112 | 「ログアウト」が AuthFailure で失敗した場合、「ログアウトできませんでした。」が表示され「通信エラー」ダイアログは表示されない [LGL-A53] | LGL-A53 #eb1189 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 113 | 「フォルダを作成」ダイアログの上の同意ダイアログで「ログアウト」が成功した場合、2つのダイアログが閉じログイン画面が表示される [LGL-A54] | LGL-A54 #22df45 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 114 | 「フォルダを作成」ダイアログの上の同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままで、同意すると「フォルダを作成」ダイアログが「英単語」が入ったまま残っている [LGL-A55] | LGL-A55 #85880b | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 115 | 「フォルダを作成」ダイアログの上の同意ダイアログで戻る操作をした場合、同意ダイアログは表示されたままで「フォルダを作成」ダイアログも閉じない [LGL-A56] | LGL-A56 #068794 | 境界値 | LegalConsentGate / LegalConsentDialog | ✅ |
| 116 | app_config/legal が無く未同意の状態で2つチェックして「同意する」をタップし送信が accepted を返した場合、同意ダイアログが閉じ送信が既定値の版数（2026-10-12）で1回呼ばれる [LGL-A57] | LGL-A57 #744cf0 | 正常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 117 | outdated の後の判定し直しで app_config/legal が無かった場合、同意ダイアログが2つの行が未チェックで表示し直され「内容が更新されました。」が表示される [LGL-A58] | LGL-A58 #b1ee76 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 118 | 「利用規約を読む」をタップした場合、閲覧画面にタイトル「利用規約」と戻るボタンが表示され WebView に利用規約の URL の読み込みが指示される [LGL-B01] | LGL-B01 #e14b14 | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 119 | 「プライバシーポリシーを読む」をタップした場合、閲覧画面にタイトル「プライバシーポリシー」と戻るボタンが表示され WebView にプライバシーポリシーの URL の読み込みが指示される [LGL-B02] | LGL-B02 #4bad04 | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 120 | 「利用規約を読む」をタップしてページの読み込みが終わっていない場合、閲覧画面にローディングが表示される [LGL-B03] | LGL-B03 #8aa85c | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 121 | 「利用規約を読む」のページの読み込みが通信の失敗で失敗した場合、閲覧画面にエラーの文言と「再読み込み」が表示され「通信エラー」ダイアログは表示されず閲覧画面は開いたままである [LGL-B04] | LGL-B04 #97b694 | 異常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 122 | 読み込みに失敗して「再読み込み」をタップし2回目の読み込みが終わっていない場合、エラーの文言と「再読み込み」が消えローディングが表示され WebView に利用規約の読み込みが合計2回指示される [LGL-B05] | LGL-B05 #b79a32 | 異常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 123 | 「利用規約に同意する」をチェックして閲覧画面を開き戻るボタンをタップした場合、閲覧画面が閉じ同意ダイアログで利用規約はチェックされたままプライバシーポリシーは未チェックのままである [LGL-B06] | LGL-B06 #397398 | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 124 | 「利用規約に同意する」をチェックして閲覧画面を開き戻る操作をした場合、閲覧画面が閉じ同意ダイアログで利用規約はチェックされたままである [LGL-B07] | LGL-B07 #bea13d | 境界値 | LegalDocumentPage / LegalConsentGate | ✅ |
| 125 | チェックをせずに閲覧画面を開いて戻るボタンをタップした場合、2つのチェックボックスは未チェックのままで「同意する」は無効のままである [LGL-B08] | LGL-B08 #0fdc47 | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 126 | 「利用規約を読む」で閲覧画面を開いて戻るボタンをタップした場合、画面のパスは /home のままで同意ダイアログは1つだけ表示されている [LGL-B09] | LGL-B09 #4c039a | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 127 | 「プライバシーポリシーを読む」をタップしてページの読み込みが終わっていない場合、閲覧画面にローディングが表示される [LGL-B10] | LGL-B10 #4248e2 | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 128 | 「プライバシーポリシーを読む」のページの読み込みが通信の失敗で失敗した場合、閲覧画面にエラーの文言と「再読み込み」が表示され「通信エラー」ダイアログは表示されず閲覧画面は開いたままである [LGL-B11] | LGL-B11 #7a5443 | 異常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 129 | プライバシーポリシーの読み込みに失敗して「再読み込み」をタップし2回目の読み込みが終わっていない場合、エラーの文言と「再読み込み」が消えローディングが表示され WebView にプライバシーポリシーの読み込みが合計2回指示される [LGL-B12] | LGL-B12 #65a169 | 異常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 130 | 「プライバシーポリシーに同意する」をチェックして閲覧画面を開き戻るボタンをタップした場合、閲覧画面が閉じプライバシーポリシーはチェックされたまま利用規約は未チェックのままである [LGL-B13] | LGL-B13 #aa08cd | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 131 | 「プライバシーポリシーに同意する」をチェックして閲覧画面を開き戻る操作をした場合、閲覧画面が閉じプライバシーポリシーはチェックされたままである [LGL-B14] | LGL-B14 #92c7cc | 境界値 | LegalDocumentPage / LegalConsentGate | ✅ |
| 132 | チェックをせずにプライバシーポリシーの閲覧画面を開いて戻るボタンをタップした場合、2つのチェックボックスは未チェックのままで「同意する」は無効のままである [LGL-B15] | LGL-B15 #345d84 | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 133 | 「プライバシーポリシーを読む」で閲覧画面を開いて戻るボタンをタップした場合、画面のパスは /home のままで同意ダイアログは1つだけ表示されている [LGL-B16] | LGL-B16 #de1bb5 | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 134 | 「利用規約を読む」を素早く2回タップした場合、閲覧画面は1つだけ開き、戻るボタンを1回タップすると同意ダイアログが表示される [LGL-B17] | LGL-B17 #e91e6e | 境界値 | LegalDocumentPage / LegalConsentGate | ✅ |
| 135 | 「利用規約を読む」のページが HTTP ステータス 404 を返した場合、閲覧画面にエラーの文言と「再読み込み」が表示される [LGL-B18] | LGL-B18 #7a0753 | 異常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 136 | 読み込みが失敗して「再読み込み」をタップした2回目の読み込みも失敗した場合、閲覧画面にエラーの文言と「再読み込み」が表示される [LGL-B19] | LGL-B19 #2df215 | 異常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 137 | 「利用規約を読む」をタップしてページの読み込みが終わる前に戻るボタンをタップした場合、閲覧画面が閉じ同意ダイアログが表示される [LGL-B20] | LGL-B20 #c62ffe | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 138 | WebView の中のリンクから別のページに移った後に戻るボタンをタップした場合、閲覧画面が閉じ同意ダイアログが表示される [LGL-B21] | LGL-B21 #595dcb | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 139 | WebView の中のリンクから別のページに移った後に戻る操作をした場合、閲覧画面が閉じ同意ダイアログが表示される [LGL-B22] | LGL-B22 #90747c | 境界値 | LegalDocumentPage / LegalConsentGate | ✅ |
| 140 | 現行の利用規約の URL が変わり outdated で表示し直された同意ダイアログで「利用規約を読む」をタップした場合、WebView に新しい URL の読み込みが指示される [LGL-B23] | LGL-B23 #6e1625 | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 141 | 読み込みに失敗して「再読み込み」を素早く2回タップした場合、WebView に利用規約の読み込みが合計2回指示される [LGL-B24] | LGL-B24 #15177b | 異常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 142 | 設定画面を開いた場合、「このアプリについて」「利用規約」「プライバシーポリシー」が「外観」の項目より下で「アカウント」より上にこの順で表示される [LGL-B25] | LGL-B25 #faf6d9 | 正常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 143 | 設定画面で「利用規約」をタップして読み取りが成功した場合、閲覧画面にタイトル「利用規約」と戻るボタンが表示され WebView に利用規約の URL の読み込みが指示される [LGL-B26] | LGL-B26 #e6015a | 正常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 144 | 設定画面で「プライバシーポリシー」をタップして読み取りが成功した場合、閲覧画面にタイトル「プライバシーポリシー」と戻るボタンが表示され WebView にプライバシーポリシーの URL の読み込みが指示される [LGL-B27] | LGL-B27 #f42ac0 | 正常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 145 | 設定画面で「利用規約」から閲覧画面を開いて戻るボタンをタップした場合、閲覧画面が閉じ設定画面が表示され同意ダイアログは表示されない [LGL-B28] | LGL-B28 #6ba404 | 正常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 146 | 設定画面で「プライバシーポリシー」から閲覧画面を開いて戻る操作をした場合、閲覧画面が閉じ設定画面が表示される [LGL-B29] | LGL-B29 #1bd712 | 境界値 | LegalLinksSection / LegalDocumentPage | ✅ |
| 147 | 設定画面で「利用規約」をタップして読み取りが UnknownFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され画面のパスは /settings のままである [LGL-B30] | LGL-B30 #f19b79 | 異常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 148 | 設定画面で「利用規約」をタップして読み取りが NetworkFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され「通信エラー」ダイアログは表示されない [LGL-B31] | LGL-B31 #9b20d0 | 異常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 149 | 設定画面で「利用規約」をタップして読み取りの応答を待っている間にもう一度タップした場合、読み取りが成功すると閲覧画面が1つだけ開き、戻るボタンを1回タップすると設定画面が表示される [LGL-B33] | LGL-B33 #ab1072 | 境界値 | LegalLinksSection / LegalDocumentPage | ✅ |
| 150 | 設定画面で「プライバシーポリシー」をタップして読み取りが UnknownFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され画面のパスは /settings のままである [LGL-B34] | LGL-B34 #f2c962 | 異常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 151 | 設定画面で「プライバシーポリシー」をタップして読み取りが NetworkFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され「通信エラー」ダイアログは表示されない [LGL-B36] | LGL-B36 #cec450 | 異常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 152 | 設定画面で「プライバシーポリシー」をタップして読み取りの応答を待っている間にもう一度タップした場合、読み取りが成功すると閲覧画面が1つだけ開き、戻るボタンを1回タップすると設定画面が表示される [LGL-B37] | LGL-B37 #d3c267 | 境界値 | LegalLinksSection / LegalDocumentPage | ✅ |
| 153 | 設定画面で「利用規約」から閲覧画面を開いて戻る操作をした場合、閲覧画面が閉じ設定画面が表示される [LGL-B38] | LGL-B38 #3f6ff0 | 境界値 | LegalLinksSection / LegalDocumentPage | ✅ |
| 154 | 設定画面で「プライバシーポリシー」から閲覧画面を開いて戻るボタンをタップした場合、閲覧画面が閉じ設定画面が表示され同意ダイアログは表示されない [LGL-B39] | LGL-B39 #ce58ea | 正常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 155 | 設定画面で「利用規約」をタップして読み取りの応答を待っている場合、「利用規約」の項目にローディングが表示される [LGL-B40] | LGL-B40 #e18d19 | 境界値 | LegalLinksSection / LegalDocumentPage | ✅ |
| 156 | 設定画面で「プライバシーポリシー」をタップして読み取りの応答を待っている場合、「プライバシーポリシー」の項目にローディングが表示される [LGL-B41] | LGL-B41 #09fbdb | 境界値 | LegalLinksSection / LegalDocumentPage | ✅ |
| 157 | app_config/legal が無い状態で設定画面の「利用規約」をタップした場合、閲覧画面が開き既定値の利用規約の URL の読み込みが指示されスナックバーは表示されない [LGL-B42] | LGL-B42 #3e21f4 | 正常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 158 | app_config/legal が無い状態で設定画面の「プライバシーポリシー」をタップした場合、閲覧画面が開き既定値のプライバシーポリシーの URL の読み込みが指示されスナックバーは表示されない [LGL-B43] | LGL-B43 #bd3d06 | 正常系 | LegalLinksSection / LegalDocumentPage | ✅ |
| 159 | app_config/legal が無く未同意の状態で起動し「利用規約を読む」をタップした場合、閲覧画面が開き既定値の利用規約の URL の読み込みが指示される [LGL-B44] | LGL-B44 #90334f | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 160 | app_config/legal が無く未同意の状態で起動し「プライバシーポリシーを読む」をタップした場合、閲覧画面が開き既定値のプライバシーポリシーの URL の読み込みが指示される [LGL-B45] | LGL-B45 #187613 | 正常系 | LegalDocumentPage / LegalConsentGate | ✅ |
| 161 | 設定画面で「利用規約」をタップして読み取りの応答を待っている間に「プライバシーポリシー」をタップした場合、読み取りが成功すると閲覧画面が1つだけ開きタイトルは「利用規約」である [LGL-B46] | LGL-B46 #767668 | 境界値 | LegalLinksSection / LegalDocumentPage | ✅ |
| 162 | 同意済みの版数の読み取りが NetworkFailure で失敗する状態で起動した場合、ホーム画面が表示され同意ダイアログも「通信エラー」ダイアログも表示されない [LGL-E02] | LGL-E02 #bd2ac1 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 163 | 同意済みの版数の読み取りが UnknownFailure で失敗する状態で起動した場合、ホーム画面が表示され同意ダイアログも失敗の表示も出ない [LGL-E03] | LGL-E03 #ddb05d | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 164 | 送信が NetworkFailure で失敗した場合、同意ダイアログが閉じタイトル「通信エラー」・本文・「OK」ボタンのダイアログが表示される [LGL-E04] | LGL-E04 #e6011b | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 165 | 送信が NetworkFailure で失敗した「通信エラー」ダイアログで「OK」をタップしてログアウトが成功した場合、ログイン画面に移動し同意ダイアログは表示されず SignOutUseCase が1回呼ばれる [LGL-E05] | LGL-E05 #ac90d5 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 166 | 送信が AuthFailure で失敗した場合、同意ダイアログが閉じタイトル「通信エラー」・本文・「OK」ボタンのダイアログが表示される [LGL-E06] | LGL-E06 #14181e | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 167 | 送信が AuthFailure で失敗した「通信エラー」ダイアログで「OK」をタップしてログアウトが成功した場合、ログイン画面に移動し同意ダイアログは表示されず SignOutUseCase が1回呼ばれる [LGL-E07] | LGL-E07 #5aa844 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 168 | 通信エラーでログイン画面に移動した後に同じ uid でもう一度ログインして未同意のままの場合、ホーム画面に移動し2つのチェックが未チェックの同意ダイアログが表示される [LGL-E08] | LGL-E08 #fea152 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 169 | 「通信エラー」ダイアログで「OK」をタップしてログアウトが UnknownFailure で失敗した場合、ホーム画面の上に未チェックの同意ダイアログが表示され「ログアウトできませんでした。」は表示されない [LGL-E09] | LGL-E09 #e14fbd | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 170 | 「通信エラー」ダイアログの表示中に復帰した場合、「通信エラー」ダイアログは1つだけ表示されたままで同意ダイアログは表示されない [LGL-E10] | LGL-E10 #4547ad | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |
| 171 | 「通信エラー」ダイアログの表示中に退会済みの記録ができた場合、「通信エラー」ダイアログが閉じ「アカウントが削除されました」ダイアログが表示され同意ダイアログは表示されず SignOutUseCase は0回である [LGL-E11] | LGL-E11 #d6f477 | 異常系 | LegalConsentGate / LegalConsentDialog | ✅ |

## テストケース詳細

### テストケース1: 未同意の状態でアプリを起動した場合、ホーム画面の上に同意ダイアログが表示され、2つのチェックは未チェックで「同意する」は無効・「ログアウト」は有効になる [LGL-D01]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが表示される。タイトル「同意のお願い」、本文「WordStock を利用するには、次の内容への同意が必要です。リンクから内容を確認し、チェックを入れてください。」、「利用規約を読む」「利用規約に同意する」「プライバシーポリシーを読む」「プライバシーポリシーに同意する」「同意する」「ログアウト」が表示される。2つのチェックボックスは未チェック。「同意する」ボタンは無効。「ログアウト」ボタンは有効

### テストケース2: プライバシーポリシーだけ版数が古い状態でアプリを起動した場合、プライバシーポリシーの行だけの同意ダイアログが表示される [LGL-D02]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2025-06-01` の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが表示される。「プライバシーポリシーを読む」「プライバシーポリシーに同意する」は表示され、「利用規約を読む」「利用規約に同意する」は表示されない。「同意する」「ログアウト」は表示される

### テストケース3: 利用規約だけ版数が古い状態でアプリを起動した場合、利用規約の行だけの同意ダイアログが表示される [LGL-D03]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2025-06-01`・プライバシーポリシー `2026-01-01` の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが表示される。「利用規約を読む」「利用規約に同意する」は表示され、「プライバシーポリシーを読む」「プライバシーポリシーに同意する」は表示されない。「同意する」「ログアウト」は表示される

### テストケース4: 同意済みの版数が現行の版数と一致する状態でアプリを起動した場合、ホーム画面が表示され同意ダイアログは表示されない [LGL-D04]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）が表示される。同意ダイアログは表示されない

### テストケース5: 利用規約の記録だけがありプライバシーポリシーの記録が無い状態でアプリを起動した場合、プライバシーポリシーの行だけの同意ダイアログが表示される [LGL-D05]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: `consents` に利用規約 `2026-01-01` だけがあり、プライバシーポリシーの記録が無い状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが表示される。「プライバシーポリシーに同意する」は表示され、「利用規約に同意する」は表示されない

### テストケース6: ログインしていない状態でメールアドレスとパスワードのログインが成功した場合、ホーム画面に移動し同意ダイアログが表示される [LGL-D07]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ログインしていない状態でログイン画面（`/login`）からメールアドレスとパスワードでログインし、ログインが成功した（その uid は未同意）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動し、その上に同意ダイアログが表示される

### テストケース7: ログインしていない状態で Google のログインが成功した場合、ホーム画面に移動し同意ダイアログが表示される [LGL-D08]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ログインしていない状態でログイン画面（`/login`）から Google でログインし、ログインが成功した（その uid は未同意）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動し、その上に同意ダイアログが表示される

### テストケース8: 未同意の状態でオフラインで起動し判定が NetworkFailure で失敗した場合、ホーム画面が表示され同意ダイアログは表示されない [LGL-D09]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で、オフラインでアプリを起動した（判定が `NetworkFailure` で失敗する）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）が表示される。同意ダイアログは表示されない

### テストケース9: 未同意の状態で現行の版数の読み取りが UnknownFailure で失敗した場合、ホーム画面が表示され同意ダイアログも失敗の表示も出ない [LGL-D10]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で、現行の版数の読み取りが `UnknownFailure` で失敗する状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）が表示される。同意ダイアログは表示されない。失敗を知らせる表示（スナックバー・ダイアログ）も出ない

### テストケース10: ログインしていない状態でアプリを起動した場合、ログイン画面が表示され同意ダイアログは表示されず fetchLegalConfig は0回である [LGL-D11]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ログインしていない状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される。同意ダイアログは表示されない。`LegalRepository.fetchLegalConfig` は0回

### テストケース11: 未同意で退会処理の記録が requested の状態でアプリを起動した場合、「退会処理が完了していません」ダイアログが表示され同意ダイアログは表示されない [LGL-D12]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意で、uid `A` の退会処理の記録が `requested` の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「退会処理が完了していません」ダイアログが表示される。同意ダイアログは表示されない

### テストケース12: 退会済みの記録があり accounts/A が無い状態でアプリを起動した場合、「アカウントが削除されました」ダイアログが表示され同意ダイアログは表示されない [LGL-D13]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: uid `A` に退会済みの記録があり、`accounts/A` が無い（未同意として読まれる）状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「アカウントが削除されました」ダイアログが表示される。同意ダイアログは表示されない

### テストケース13: 同意済みで起動してホーム画面を表示中に現行の termsVersion が変わり復帰した場合、利用規約の行だけの同意ダイアログがホーム画面の上に表示される [LGL-D14]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` の状態で起動し、ホーム画面（`/home`）を表示している間に現行の `termsVersion` が `2026-02-01` に変わり、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが表示される。「利用規約に同意する」は表示され、「プライバシーポリシーに同意する」は表示されない

### テストケース14: 同意ダイアログの表示中に「利用規約に同意する」をチェックして復帰した場合、同意ダイアログは1つだけでチェックは残り fetchLegalConfig は起動時の1回だけである [LGL-D15]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して同意ダイアログが表示され、「利用規約に同意する」をチェックした後、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが1つだけ表示されたまま。「利用規約に同意する」はチェックされたまま。`fetchLegalConfig` は起動時の1回だけ

### テストケース15: 未同意でオフライン起動してホーム画面を表示し、バックグラウンドの間にオンラインに戻り、その後復帰した場合、同意ダイアログがホーム画面の上に1つ表示される [LGL-D16]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で、オフラインでアプリを起動してホーム画面（`/home`）を表示し、アプリをバックグラウンドに移している間にオンラインに戻り、その後アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが1つ表示される

### テストケース16: 同意ダイアログの表示中に退会済みの記録ができた場合、同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される [LGL-D17]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して同意ダイアログが表示されている間に、uid `A` の退会済みの記録ができた（監視で通知された）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、「アカウントが削除されました」ダイアログが表示される

### テストケース17: 強制ログアウトの記録がある uid で Firebase 上はログイン中の未同意の状態で起動した場合、ログイン画面が表示され同意ダイアログは表示されず fetchLegalConfig は0回である [LGL-D18]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: Firebase 上は uid `A` でログイン中だが、uid `A` に強制ログアウトの記録があり、未同意の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される。同意ダイアログは表示されない。`fetchLegalConfig` は0回

### テストケース18: 未同意の状態で起動して判定の応答を待っている場合、ホーム画面が表示され同意ダイアログは表示されない [LGL-D19]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態でアプリを起動し、判定の応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）が表示される。同意ダイアログは表示されない

### テストケース19: 幅320・高さ480の端末で未同意の状態で起動した場合、同意ダイアログが表示されはみ出しが起きず、スクロールすると「同意する」ボタンが表示される [LGL-D20]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 画面の大きさが幅 320・高さ 480 の端末で、未同意の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示され、表示のはみ出し（オーバーフロー）が起きない。ダイアログの中をスクロールすると「同意する」ボタンが表示される

### テストケース20: 同意ダイアログの表示中に Firebase のログイン状態が解除された場合、同意ダイアログが閉じログイン画面が表示される [LGL-D21]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して同意ダイアログが表示されている間に、Firebase のログイン状態が解除された
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、ログイン画面（`/login`）が表示される

### テストケース21: 同意ダイアログの表示中は、「キャンセル」「同意しない」のボタンが表示されない [LGL-D22]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して同意ダイアログが表示されている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「キャンセル」「同意しない」のボタンは表示されない

### テストケース22: スプラッシュ画面を表示している間に判定が終わった場合、スプラッシュ画面の間は同意ダイアログが表示されず、ホーム画面に移動した後にその上に表示される [LGL-D23]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動し、スプラッシュ画面（`/`）を表示している間に判定が終わった
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: スプラッシュ画面（`/`）の間は同意ダイアログが表示されず、ホーム画面（`/home`）に移動した後にその上に表示される

### テストケース23: 閲覧画面を開いている間に退会済みの記録ができた場合、閲覧画面と同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される [LGL-D24]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して同意ダイアログが表示され、「利用規約を読む」をタップして閲覧画面を開いている間に、uid `A` の退会済みの記録ができた（監視で通知された）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面と同意ダイアログが閉じ、「アカウントが削除されました」ダイアログが表示される

### テストケース24: 閲覧画面を開いている間に Firebase のログイン状態が解除された場合、閲覧画面と同意ダイアログが閉じログイン画面が表示される [LGL-D25]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して同意ダイアログが表示され、「利用規約を読む」をタップして閲覧画面を開いている間に、Firebase のログイン状態が解除された
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面と同意ダイアログが閉じ、ログイン画面（`/login`）が表示される

### テストケース25: 「利用規約に同意する」をチェックして閲覧画面を開いている間に復帰した場合、閲覧画面は表示されたままで、戻ると同意ダイアログが1つだけ表示されチェックは残り fetchLegalConfig は1回である [LGL-D26]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して同意ダイアログが表示され、「利用規約に同意する」をチェックし、「利用規約を読む」をタップして閲覧画面を開いている間に、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が表示されたまま。閲覧画面の戻るボタンをタップすると同意ダイアログが1つだけ表示され、「利用規約に同意する」はチェックされたまま。`fetchLegalConfig` は起動時の1回だけ

### テストケース26: 未同意で退会処理の記録が serverDone の状態でアプリを起動した場合、「退会処理が完了していません」ダイアログが表示され同意ダイアログは表示されない [LGL-D27]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意で、uid `A` の退会処理の記録が `serverDone` の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「退会処理が完了していません」ダイアログが表示される。同意ダイアログは表示されない

### テストケース27: 退会処理の記録が requested で再開ダイアログの表示中に復帰した場合、再開ダイアログは表示されたままで同意ダイアログは表示されない [LGL-D28]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意で、uid `A` の退会処理の記録が `requested` の状態でアプリを起動し、「退会処理が完了していません」ダイアログが表示されている間に、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「退会処理が完了していません」ダイアログが表示されたまま。同意ダイアログは表示されない

### テストケース28: 未同意でログイン済みの状態でアプリを起動した場合、同意ダイアログが1つだけ表示され fetchLegalConfig は1回だけ呼ばれる [LGL-D29]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意で、ログイン済みの状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが1つだけ表示される。`fetchLegalConfig` は1回だけ呼ばれる

### テストケース29: 「同意する」をタップして送信の応答を待っている間に復帰した場合、同意ダイアログは1つだけでローディングが表示されたままで送信は1回だけ呼ばれる [LGL-D30]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動し、2つのチェックボックスをチェックして「同意する」をタップし、送信の応答を待っている間に、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが1つだけ表示されたまま、ローディングのインジケーターが表示されたまま。送信は1回だけ呼ばれる

### テストケース30: 「同意する」をタップして送信の応答を待っている間に退会済みの記録ができた場合、同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される [LGL-D31]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動し、2つのチェックボックスをチェックして「同意する」をタップし、送信の応答を待っている間に、uid `A` の退会済みの記録ができた（監視で通知された）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、「アカウントが削除されました」ダイアログが表示される

### テストケース31: uid A に強制ログアウトの記録がありログインしていない状態で uid B のログインが成功した場合、ホーム画面に移動し同意ダイアログが表示される [LGL-D32]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: uid `A` に強制ログアウトの記録があり、ログインしていない状態でログイン画面（`/login`）からメールアドレスとパスワードで uid `B` にログインし、ログインが成功した（uid `B` は未同意）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動し、その上に同意ダイアログが表示される

### テストケース32: 同意済みの uid のログインが成功した場合、ホーム画面に移動し同意ダイアログは表示されない [LGL-D33]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ログインしていない状態でログイン画面（`/login`）からメールアドレスとパスワードでログインし、ログインが成功した（その uid の同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01`）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動する。同意ダイアログは表示されない

### テストケース33: 同意済みで起動してホーム画面を表示中に現行の privacyVersion が変わり復帰した場合、プライバシーポリシーの行だけの同意ダイアログが表示される [LGL-D34]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` の状態で起動し、ホーム画面（`/home`）を表示している間に現行の `privacyVersion` が `2026-02-01` に変わり、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが表示される。「プライバシーポリシーに同意する」は表示され、「利用規約に同意する」は表示されない

### テストケース34: 同意済みで設定画面を表示中に現行の termsVersion が変わり復帰した場合、設定画面の上に同意ダイアログが表示され画面のパスは /settings のままである [LGL-D35]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` の状態で起動し、設定画面（`/settings`）を表示している間に現行の `termsVersion` が `2026-02-01` に変わり、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 設定画面（`/settings`）の上に同意ダイアログが表示される。表示中の画面のパスは `/settings` のまま

### テストケース35: 幅320・高さ480・文字の拡大率2.0の端末で未同意の状態で起動した場合、同意ダイアログが表示されはみ出しが起きない [LGL-D36]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 画面の大きさが幅 320・高さ 480、文字の拡大率が 2.0 の端末で、未同意の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示され、表示のはみ出し（オーバーフロー）が起きない

### テストケース36: 判定の応答を待っている間に Firebase のログイン状態が解除され、その後に判定が同意が必要と返した場合、ログイン画面が表示され同意ダイアログは表示されない [LGL-D37]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態でアプリを起動し、判定の応答を待っている間に Firebase のログイン状態が解除され、その後に判定が同意が必要という結果を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される。同意ダイアログは表示されない

### テストケース37: 判定の応答を待っている間に退会済みの記録が見つかりお知らせが表示され、その後に判定が同意が必要と返した場合、お知らせダイアログは表示されたままで同意ダイアログは表示されない [LGL-D38]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態でアプリを起動し、判定の応答を待っている間に uid `A` の退会済みの記録が見つかって「アカウントが削除されました」ダイアログが表示され、その後に判定が同意が必要という結果を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「アカウントが削除されました」ダイアログが表示されたまま。同意ダイアログは表示されない

### テストケース38: 判定の応答を待っている間に設定画面から退会を始めて退会処理の記録が requested になり、その後に判定が同意が必要と返した場合、同意ダイアログは表示されない [LGL-D39]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態でアプリを起動し、判定の応答を待っている間に設定画面（`/settings`）から退会を始めて退会処理の記録が `requested` になり、その後に判定が同意が必要という結果を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されない

### テストケース39: 「アカウントが削除されました」ダイアログの表示中に復帰した場合、ダイアログは表示されたままで同意ダイアログは表示されず fetchLegalConfig の呼び出し回数は増えない [LGL-D40]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: uid `A` に退会済みの記録があり、「アカウントが削除されました」ダイアログが表示されている間に、アプリがフォアグラウンドに戻った（`accounts/A` は無い）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「アカウントが削除されました」ダイアログが表示されたまま。同意ダイアログは表示されない。resumed の前後で `fetchLegalConfig` の呼び出し回数が増えない

### テストケース40: 「フォルダを作成」ダイアログに「英単語」を入力中に現行の termsVersion が変わり復帰した場合、その上に同意ダイアログが表示され、同意が成功すると「英単語」が入ったまま「フォルダを作成」ダイアログが表示される [LGL-D41]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` の状態で起動し、ホーム画面（`/home`）で「フォルダを作成」ダイアログを開いて「フォルダ名」に「英単語」を入力している間に、現行の `termsVersion` が `2026-02-01` に変わり、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「フォルダを作成」ダイアログの上に同意ダイアログが表示される。「利用規約に同意する」をチェックして「同意する」をタップし、送信が `accepted` を返すと、同意ダイアログが閉じ、「フォルダを作成」ダイアログが「フォルダ名」に「英単語」が入ったまま表示される

### テストケース41: 「ログアウト」の応答を待っている間に退会済みの記録ができた場合、同意ダイアログが閉じお知らせが表示され、その後にログアウトが UnknownFailure を返しても「ログアウトできませんでした。」は表示されない [LGL-D42]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して同意ダイアログが表示され、「ログアウト」をタップしてログアウトの応答を待っている間に、uid `A` の退会済みの記録ができた（監視で通知された）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、「アカウントが削除されました」ダイアログが表示される。その後にログアウトが `UnknownFailure` を返しても、「ログアウトできませんでした。もう一度お試しください。」は表示されない

### テストケース42: 「ログアウト」の応答を待っている間に復帰した場合、同意ダイアログは1つだけでローディングが表示されたままで fetchLegalConfig の呼び出し回数は増えない [LGL-D43]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して同意ダイアログが表示され、「ログアウト」をタップしてログアウトの応答を待っている間に、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが1つだけ表示されたまま、ローディングのインジケーターが表示されたまま。resumed の前後で `fetchLegalConfig` の呼び出し回数が増えない

### テストケース43: 設定画面の「利用規約」から閲覧画面を開いている間に現行の termsVersion が変わり復帰した場合、閲覧画面の上に利用規約の行だけの同意ダイアログが表示される [LGL-D44]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` の状態で起動し、設定画面（`/settings`）の「利用規約」から閲覧画面を開いている間に、現行の `termsVersion` が `2026-02-01` に変わり、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面の上に同意ダイアログが表示される。「利用規約に同意する」は表示され、「プライバシーポリシーに同意する」は表示されない

### テストケース44: 閲覧画面の上に表示された同意ダイアログで同意が成功した場合、同意ダイアログが閉じ閲覧画面が表示され、戻ると設定画面が表示される [LGL-D45]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` の状態で起動し、設定画面（`/settings`）の「利用規約」から閲覧画面を開いている間に、現行の `termsVersion` が `2026-02-01` に変わってアプリがフォアグラウンドに戻り、表示された同意ダイアログで「利用規約に同意する」をチェックして「同意する」をタップし、送信が `accepted` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、閲覧画面が表示される。閲覧画面の戻るボタンをタップすると設定画面（`/settings`）が表示される

### テストケース45: 設定画面の「利用規約」から閲覧画面を開いている間に退会済みの記録ができた場合、「アカウントが削除されました」ダイアログが表示され同意ダイアログは表示されない [LGL-D46]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 設定画面（`/settings`）の「利用規約」から閲覧画面を開いている間に、uid `A` の退会済みの記録ができた（監視で通知された）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「アカウントが削除されました」ダイアログが表示される。同意ダイアログは表示されない

### テストケース46: 設定画面の「利用規約」から閲覧画面を開いている間に Firebase のログイン状態が解除された場合、閲覧画面が閉じログイン画面が表示される [LGL-D47]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 設定画面（`/settings`）の「利用規約」から閲覧画面を開いている間に、Firebase のログイン状態が解除された
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、ログイン画面（`/login`）が表示される

### テストケース47: 「フォルダを作成」ダイアログの上に同意ダイアログが表示されている間に退会済みの記録ができた場合、同意ダイアログが閉じ「アカウントが削除されました」ダイアログが表示される [LGL-D48]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ホーム画面（`/home`）の「フォルダを作成」ダイアログの上に同意ダイアログが表示されている間に、uid `A` の退会済みの記録ができた（監視で通知された）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、「アカウントが削除されました」ダイアログが表示される

### テストケース48: 「フォルダを作成」ダイアログの上に同意ダイアログが表示されている間に Firebase のログイン状態が解除された場合、2つのダイアログが閉じログイン画面が表示される [LGL-D49]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ホーム画面（`/home`）の「フォルダを作成」ダイアログの上に同意ダイアログが表示されている間に、Firebase のログイン状態が解除された
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログと「フォルダを作成」ダイアログが閉じ、ログイン画面（`/login`）が表示される

### テストケース49: 未同意でオフライン起動してホーム画面を表示し、フォアグラウンドのままオンラインに戻った場合、同意ダイアログがホーム画面の上に表示される [LGL-D50]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で、オフラインでアプリを起動してホーム画面（`/home`）を表示し、アプリをフォアグラウンドに置いたまま、オンラインに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが表示される

### テストケース50: app_config/legal が無く未同意の状態で起動した場合、ホーム画面の上に2つの行がある同意ダイアログが表示される [LGL-D51]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: `app_config/legal` が無く、未同意の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが表示される。「利用規約に同意する」「プライバシーポリシーに同意する」の両方が表示される

### テストケース51: app_config/legal が無く同意済みの版数が既定値（2026-10-12）と同じ状態で起動した場合、ホーム画面が表示され同意ダイアログは表示されない [LGL-D52]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: `app_config/legal` が無く、同意済みの版数が利用規約 `2026-10-12`・プライバシーポリシー `2026-10-12`（既定値と同じ）の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）が表示される。同意ダイアログは表示されない

### テストケース52: app_config/legal が無く利用規約だけ既定値と同じ版数で同意済みの状態で起動した場合、プライバシーポリシーの行だけの同意ダイアログが表示される [LGL-D53]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: `app_config/legal` が無く、同意済みの版数が利用規約 `2026-10-12`・プライバシーポリシー `2025-06-01` の状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが表示される。「プライバシーポリシーに同意する」は表示され、「利用規約に同意する」は表示されない

### テストケース53: メールアドレスとパスワードでログインして初回の同期の完了を待っている場合、同意ダイアログは表示されず fetchLegalConfig は0回である [LGL-D54]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ログインしていない状態でログイン画面（`/login`）からメールアドレスとパスワードでログインし（その uid は未同意）、初回の同期の完了を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されない。`fetchLegalConfig` は0回

### テストケース54: 新規登録画面で2つにチェックして「アカウント作成」をタップし、同意の送信の応答を待っている場合、同意ダイアログは表示されず fetchLegalConfig は新規登録画面を開いたときの1回だけである [LGL-D55]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ログインしていない状態で新規登録画面（`/sign-up`）から、正しい入力をし2つのチェックボックスをチェックして「アカウント作成」をタップし、アカウントの作成が成功して同意の送信の応答を待っている（新しい uid は未同意）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されない。`fetchLegalConfig` は新規登録画面を開いたときの1回だけ（判定のための読み取りは0回）

### テストケース55: 同意ダイアログの表示中に「利用規約に同意する」をチェックし、オフラインになってからオンラインに戻った場合、同意ダイアログは1つだけでチェックは残り fetchLegalConfig は起動時の1回だけである [LGL-D56]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して同意ダイアログが表示され、「利用規約に同意する」をチェックした後、オフラインになってからオンラインに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが1つだけ表示されたまま。「利用規約に同意する」はチェックされたまま。`fetchLegalConfig` は起動時の1回だけ

### テストケース56: ログイン画面の表示中にオフラインになってからオンラインに戻った場合、同意ダイアログは表示されず fetchLegalConfig は0回である [LGL-D57]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ログインしていない状態でログイン画面（`/login`）を表示している間に、オフラインになってからオンラインに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されない。`fetchLegalConfig` は0回

### テストケース57: 退会処理の記録が requested で再開ダイアログの表示中にオフラインになってからオンラインに戻った場合、同意ダイアログは表示されず再開ダイアログは表示されたままである [LGL-D58]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意で、uid `A` の退会処理の記録が `requested` の状態でアプリを起動し、「退会処理が完了していません」ダイアログが表示されている間に、オフラインになってからオンラインに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されない。「退会処理が完了していません」ダイアログが表示されたまま

### テストケース58: Google でログインして初回の同期の完了を待っている場合、同意ダイアログは表示されず fetchLegalConfig は0回である [LGL-D59]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ログインしていない状態でログイン画面（`/login`）から Google でログインし（その uid は未同意）、初回の同期の完了を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されない。`fetchLegalConfig` は0回

### テストケース59: メールアドレスとパスワードでログインして初回の同期が失敗して終わった場合、ホーム画面に移動し同意ダイアログが表示される [LGL-D60]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ログインしていない状態でログイン画面（`/login`）からメールアドレスとパスワードでログインし（その uid は未同意）、初回の同期が失敗して終わった
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動し、その上に同意ダイアログが表示される

### テストケース60: 新規登録画面を開いて規約の情報の読み取りの応答を待っている場合、ローディングは表示されず「アカウント作成」ボタンは無効である [LGL-D61]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 新規登録画面（`/sign-up`）を開き、現行の規約の情報の読み取りの応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 新規登録画面にローディングのインジケーターは表示されない。「アカウント作成」ボタンは無効

### テストケース61: 「利用規約に同意する」のチェックボックスをタップした場合、利用規約だけがチェックされ「同意する」は無効のままである [LGL-A01]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約に同意する」のチェックボックスをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「利用規約に同意する」がチェックされる。「プライバシーポリシーに同意する」は未チェックのまま。「同意する」ボタンは無効のまま

### テストケース62: 2つのチェックボックスをタップした場合、2つともチェックされ「同意する」が有効になる [LGL-A02]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約に同意する」と「プライバシーポリシーに同意する」のチェックボックスをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 2つともチェックされ、「同意する」ボタンが有効になる

### テストケース63: 2つチェックした後に「利用規約に同意する」をもう一度タップした場合、利用規約が未チェックになり「同意する」が無効になる [LGL-A03]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、「利用規約に同意する」のチェックボックスをもう一度タップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「利用規約に同意する」が未チェックになり、「同意する」ボタンが無効になる

### テストケース64: プライバシーポリシーの行だけの同意ダイアログで「プライバシーポリシーに同意する」をタップした場合、「同意する」が有効になる [LGL-A04]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2025-06-01` の状態で起動し、プライバシーポリシーの行だけの同意ダイアログで「プライバシーポリシーに同意する」のチェックボックスをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「同意する」ボタンが有効になる

### テストケース65: 「利用規約に同意する」の文言をタップした場合、利用規約がチェックされる [LGL-A05]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約に同意する」の文言をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「利用規約に同意する」がチェックされる

### テストケース66: 2つチェックして「同意する」をタップし送信が accepted を返した場合、同意ダイアログが閉じホーム画面が表示され送信が現行の版数で1回呼ばれる [LGL-A06]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信が `accepted` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、ホーム画面（`/home`）が表示される。送信が1回、利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` を引数に呼ばれる

### テストケース67: 利用規約の行だけの同意ダイアログで同意して送信が accepted を返した場合、同意ダイアログが閉じ送信が利用規約の版数とプライバシーポリシー null で1回呼ばれる [LGL-A07]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2025-06-01`・プライバシーポリシー `2026-01-01` の状態で起動し、利用規約の行だけの同意ダイアログで「利用規約に同意する」をチェックして「同意する」をタップし、送信が `accepted` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じる。送信が1回、利用規約 `2026-01-01`・プライバシーポリシー null を引数に呼ばれる

### テストケース68: 「同意する」をタップして送信の応答を待っている場合、同意ダイアログのボタン・チェックボックス・リンクが無効になりローディングが表示される [LGL-A08]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信の応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示されたまま、「同意する」ボタン・「ログアウト」ボタン・2つのチェックボックス・「利用規約を読む」「プライバシーポリシーを読む」が無効になり、ダイアログの中にローディングのインジケーターが表示される

### テストケース69: 送信の応答を待っている間に「同意する」をもう一度タップした場合、送信は1回だけ呼ばれる [LGL-A09]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信の応答を待っている間に「同意する」をもう一度タップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 送信は1回だけ呼ばれる

### テストケース70: 送信が UnknownFailure で失敗した場合、同意ダイアログが表示されたままチェックは残り「同意を送信できませんでした。」が表示され「同意する」は有効である [LGL-A10]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信が `UnknownFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示されたまま、2つのチェックボックスはチェックされたまま、「同意を送信できませんでした。もう一度お試しください。」が表示される。「同意する」ボタンは有効

### テストケース71: 1回目の送信が UnknownFailure で失敗した後に「同意する」をもう一度タップし2回目が accepted を返した場合、同意ダイアログが閉じ送信は合計2回呼ばれる [LGL-A11]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、1回目の送信が `UnknownFailure` で失敗して「同意を送信できませんでした。もう一度お試しください。」が表示された後、「同意する」をもう一度タップし、2回目の送信が `accepted` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じる。送信は合計2回呼ばれる

### テストケース72: 2つチェックした後に現行の termsVersion が変わり送信が outdated を返した場合、2つの行が未チェックで表示し直され「内容が更新されました。」が表示され「同意する」は無効である [LGL-A12]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `termsVersion` が `2026-02-01` に変わり、「同意する」をタップして送信が `outdated` を返した（判定し直しは成功する）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示されたまま、「利用規約に同意する」「プライバシーポリシーに同意する」が表示され、2つとも未チェックになり、「内容が更新されました。もう一度ご確認のうえ、同意してください。」が表示される。「同意する」ボタンは無効

### テストケース73: outdated で表示し直された同意ダイアログで再度同意して2回目の送信が accepted を返した場合、同意ダイアログが閉じ2回目の送信は利用規約 2026-02-01・プライバシーポリシー 2026-01-01 で呼ばれる [LGL-A13]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `termsVersion` が `2026-02-01` に変わり、「同意する」をタップして1回目の送信が `outdated` を返し、表示し直された同意ダイアログで2つのチェックボックスをチェックして「同意する」をタップし、2回目の送信が `accepted` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じる。2回目の送信の引数は利用規約 `2026-02-01`・プライバシーポリシー `2026-01-01`

### テストケース74: 送信の処理中ではない状態で同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままで送信は0回である [LGL-A14]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 送信の処理中ではない状態で、同意ダイアログの外側をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま。送信は0回

### テストケース75: 送信の処理中ではない状態で戻る操作をした場合、同意ダイアログは表示されたままで画面のパスは /home のままで送信は0回である [LGL-A15]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 送信の処理中ではない状態で、戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま。表示中の画面のパスは `/home` のまま。送信は0回

### テストケース76: 送信の応答を待っている間に同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままである [LGL-A16]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信の応答を待っている間に、同意ダイアログの外側をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま

### テストケース77: 送信の応答を待っている間に戻る操作をした場合、同意ダイアログは表示されたままである [LGL-A17]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信の応答を待っている間に、戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま

### テストケース78: 「利用規約に同意する」だけをチェックした状態で無効の「同意する」をタップした場合、同意ダイアログは表示されたままで送信は0回である [LGL-A18]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約に同意する」だけをチェックした状態で、無効の「同意する」ボタンをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま。送信は0回

### テストケース79: 同意して送信が accepted を返した後に復帰した場合、同意ダイアログは表示されない [LGL-A19]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信が `accepted` を返した後、アプリがフォアグラウンドに戻った（同意済みの版数が現行の版数と一致している）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されない

### テストケース80: 「プライバシーポリシーに同意する」のチェックボックスをタップした場合、プライバシーポリシーだけがチェックされ「同意する」は無効のままである [LGL-A20]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーに同意する」のチェックボックスをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「プライバシーポリシーに同意する」がチェックされる。「利用規約に同意する」は未チェックのまま。「同意する」ボタンは無効のまま

### テストケース81: 2つチェックした後に「プライバシーポリシーに同意する」をもう一度タップした場合、プライバシーポリシーが未チェックになり「同意する」が無効になる [LGL-A21]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、「プライバシーポリシーに同意する」のチェックボックスをもう一度タップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「プライバシーポリシーに同意する」が未チェックになり、「同意する」ボタンが無効になる

### テストケース82: 「プライバシーポリシーに同意する」の文言をタップした場合、プライバシーポリシーがチェックされる [LGL-A22]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーに同意する」の文言をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「プライバシーポリシーに同意する」がチェックされる

### テストケース83: 「プライバシーポリシーに同意する」だけをチェックした状態で無効の「同意する」をタップした場合、同意ダイアログは表示されたままで送信は0回である [LGL-A23]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーに同意する」だけをチェックした状態で、無効の「同意する」ボタンをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま。送信は0回

### テストケース84: プライバシーポリシーの行だけの同意ダイアログで同意して送信が accepted を返した場合、同意ダイアログが閉じ送信が利用規約 null・プライバシーポリシーの版数で1回呼ばれる [LGL-A24]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2025-06-01` の状態で起動し、プライバシーポリシーの行だけの同意ダイアログで「プライバシーポリシーに同意する」をチェックして「同意する」をタップし、送信が `accepted` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じる。送信が1回、利用規約 null・プライバシーポリシー `2026-01-01` を引数に呼ばれる

### テストケース85: 2つチェックした後に現行の privacyVersion が変わり送信が outdated を返した場合、2つの行が未チェックで表示し直され「内容が更新されました。」が表示され「同意する」は無効である [LGL-A25]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `privacyVersion` が `2026-02-01` に変わり、「同意する」をタップして送信が `outdated` を返した（判定し直しは成功する）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示されたまま、「利用規約に同意する」「プライバシーポリシーに同意する」が表示され、2つとも未チェックになり、「内容が更新されました。もう一度ご確認のうえ、同意してください。」が表示される。「同意する」ボタンは無効

### テストケース86: privacyVersion の改定で outdated になり再度同意して2回目の送信が accepted を返した場合、同意ダイアログが閉じ2回目の送信は利用規約 2026-01-01・プライバシーポリシー 2026-02-01 で呼ばれる [LGL-A26]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `privacyVersion` が `2026-02-01` に変わり、「同意する」をタップして1回目の送信が `outdated` を返し、表示し直された同意ダイアログで2つのチェックボックスをチェックして「同意する」をタップし、2回目の送信が `accepted` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じる。2回目の送信の引数は利用規約 `2026-01-01`・プライバシーポリシー `2026-02-01`

### テストケース87: 設定画面で表示された同意ダイアログで同意して送信が accepted を返した場合、同意ダイアログが閉じ画面のパスは /settings のままである [LGL-A27]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` の状態で起動し、設定画面（`/settings`）を表示している間に現行の `termsVersion` が `2026-02-01` に変わり、アプリがフォアグラウンドに戻って表示された同意ダイアログで「利用規約に同意する」をチェックして「同意する」をタップし、送信が `accepted` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じる。表示中の画面のパスは `/settings` のまま

### テストケース88: 送信の処理中ではない状態で同意ダイアログの背後のボトムナビ「設定」の位置をタップした場合、同意ダイアログは表示されたままで画面のパスは /home のままである [LGL-A28]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 送信の処理中ではない状態で、同意ダイアログの背後に見えているボトムナビの「設定」の位置をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま。表示中の画面のパスは `/home` のまま

### テストケース89: outdated の後の判定し直しが NetworkFailure で失敗した場合、同意ダイアログが閉じホーム画面が表示される [LGL-A29]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `termsVersion` が `2026-02-01` に変わり、「同意する」をタップして送信が `outdated` を返し、続く判定し直しが `NetworkFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、ホーム画面（`/home`）が表示される

### テストケース90: 別の端末で現行の版数に同意済みになった状態で送信が outdated を返した場合、同意ダイアログが閉じホーム画面が表示される [LGL-A30]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、別の端末で同じ uid が現行の版数に同意済みになり（同意済みの版数が利用規約 `2026-02-01`・プライバシーポリシー `2026-01-01`）、現行の `termsVersion` が `2026-02-01` に変わった状態で「同意する」をタップし、送信が `outdated` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、ホーム画面（`/home`）が表示される

### テストケース91: 利用規約の行だけの同意ダイアログで privacyVersion が変わり送信が outdated を返した場合、2つの行が未チェックで表示し直される [LGL-A31]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2025-06-01`・プライバシーポリシー `2026-01-01` の状態で起動し、利用規約の行だけの同意ダイアログで「利用規約に同意する」をチェックした後、現行の `privacyVersion` が `2026-02-01` に変わり、「同意する」をタップして送信が `outdated` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示されたまま、「利用規約に同意する」と「プライバシーポリシーに同意する」の2つが表示され、2つとも未チェックになる

### テストケース92: 1回目の送信が失敗した後に「同意する」をもう一度タップして2回目の応答を待っている場合、「同意を送信できませんでした。」は表示されずローディングが表示される [LGL-A32]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、1回目の送信が `UnknownFailure` で失敗して「同意を送信できませんでした。もう一度お試しください。」が表示された後、「同意する」をもう一度タップし、2回目の送信の応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「同意を送信できませんでした。もう一度お試しください。」は表示されない。ローディングのインジケーターが表示される

### テストケース93: 送信の応答を待っている間にログイン状態が解除され、その後に送信が NetworkFailure で失敗した場合、ログイン画面が表示され「通信エラー」ダイアログも同意ダイアログも表示されない [LGL-A33]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信の応答を待っている間に Firebase のログイン状態が解除され、その後に送信が `NetworkFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される。「通信エラー」ダイアログは表示されない。同意ダイアログは表示されない

### テストケース94: outdated の後の判定し直しが UnknownFailure で失敗した場合、同意ダイアログが閉じホーム画面が表示される [LGL-A34]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `termsVersion` が `2026-02-01` に変わり、「同意する」をタップして送信が `outdated` を返し、続く判定し直しが `UnknownFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、ホーム画面（`/home`）が表示される

### テストケース95: 送信の応答を待っている間にログイン状態が解除され、その後に送信が accepted を返した場合、ログイン画面が表示され同意ダイアログは表示されない [LGL-A36]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信の応答を待っている間に Firebase のログイン状態が解除され、その後に送信が `accepted` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される。同意ダイアログは表示されない

### テストケース96: outdated で表示し直された同意ダイアログで「利用規約に同意する」をチェックした場合、「内容が更新されました。」は表示されたままである [LGL-A37]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `termsVersion` が `2026-02-01` に変わり、「同意する」をタップして送信が `outdated` を返し、表示し直された同意ダイアログで「利用規約に同意する」をチェックした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「内容が更新されました。もう一度ご確認のうえ、同意してください。」は表示されたまま

### テストケース97: 「ログアウト」をタップしてログアウトが成功した場合、同意ダイアログが閉じログイン画面に移動し SignOutUseCase が1回呼ばれ確認ダイアログは表示されず送信は0回である [LGL-A38]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 送信の処理中ではない状態で「ログアウト」をタップし、ログアウトが成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、ログイン画面（`/login`）に移動する。`SignOutUseCase` が1回呼ばれる。確認のダイアログは表示されない。送信は0回

### テストケース98: 送信の応答を待っている間に「ログアウト」をタップした場合、SignOutUseCase は0回で同意ダイアログは表示されたままである [LGL-A39]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信の応答を待っている間に「ログアウト」をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: `SignOutUseCase` は0回。同意ダイアログは表示されたまま

### テストケース99: 「利用規約に同意する」をチェックして「ログアウト」が UnknownFailure で失敗した場合、「ログアウトできませんでした。」が表示されチェックは残り画面のパスは /home のままである [LGL-A40]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約に同意する」をチェックした後、「ログアウト」をタップし、ログアウトが `UnknownFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示されたまま、「ログアウトできませんでした。もう一度お試しください。」が表示される。「利用規約に同意する」はチェックされたまま。表示中の画面のパスは `/home` のまま

### テストケース100: ログアウトの応答を待っている間に「ログアウト」をもう一度タップした場合、SignOutUseCase は1回だけ呼ばれる [LGL-A41]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「ログアウト」をタップし、ログアウトの応答を待っている間に「ログアウト」をもう一度タップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: `SignOutUseCase` は1回だけ呼ばれる

### テストケース101: 「ログアウト」をタップしてログアウトの応答を待っている場合、ボタン・チェックボックス・リンクが無効になりローディングが表示される [LGL-A42]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「ログアウト」をタップし、ログアウトの応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「ログアウト」ボタン・「同意する」ボタン・2つのチェックボックス・2つのリンクが無効になり、ダイアログの中にローディングのインジケーターが表示される

### テストケース102: 送信が失敗して「同意を送信できませんでした。」が表示された後に「ログアウト」をタップして応答を待っている場合、「同意を送信できませんでした。」は表示されない [LGL-A43]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信が `UnknownFailure` で失敗して「同意を送信できませんでした。もう一度お試しください。」が表示された後、「ログアウト」をタップし、ログアウトの応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「同意を送信できませんでした。もう一度お試しください。」は表示されない

### テストケース103: ログアウトの応答を待っている間に同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままである [LGL-A44]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「ログアウト」をタップし、ログアウトの応答を待っている間に、同意ダイアログの外側をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま

### テストケース104: ログアウトの応答を待っている間に戻る操作をした場合、同意ダイアログは表示されたままである [LGL-A45]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「ログアウト」をタップし、ログアウトの応答を待っている間に、戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま

### テストケース105: ログアウトが失敗して「ログアウトできませんでした。」が表示された後に「プライバシーポリシーに同意する」をチェックした場合、「ログアウトできませんでした。」は表示されたままである [LGL-A46]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約に同意する」をチェックした後、「ログアウト」をタップしてログアウトが `UnknownFailure` で失敗し、「ログアウトできませんでした。もう一度お試しください。」が表示された後、「プライバシーポリシーに同意する」をチェックした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「ログアウトできませんでした。もう一度お試しください。」は表示されたまま

### テストケース106: 送信が失敗して「同意を送信できませんでした。」が表示された後に「利用規約に同意する」のチェックを外した場合、「同意を送信できませんでした。」は表示されたままである [LGL-A47]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約に同意する」をチェックした後、「プライバシーポリシーに同意する」をチェックして「同意する」をタップし、送信が `UnknownFailure` で失敗して「同意を送信できませんでした。もう一度お試しください。」が表示された後、「利用規約に同意する」のチェックを外した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「同意を送信できませんでした。もう一度お試しください。」は表示されたまま

### テストケース107: ログアウトが失敗して「ログアウトできませんでした。」が表示された後に「同意する」をタップして応答を待っている場合、「ログアウトできませんでした。」は表示されない [LGL-A48]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、「ログアウト」をタップしてログアウトが `UnknownFailure` で失敗し、「ログアウトできませんでした。もう一度お試しください。」が表示された後、「同意する」をタップし、送信の応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「ログアウトできませんでした。もう一度お試しください。」は表示されない

### テストケース108: ログアウトが失敗して「ログアウトできませんでした。」が表示された後に「ログアウト」をもう一度タップして応答を待っている場合、「ログアウトできませんでした。」は表示されない [LGL-A49]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「ログアウト」をタップしてログアウトが `UnknownFailure` で失敗し、「ログアウトできませんでした。もう一度お試しください。」が表示された後、「ログアウト」をもう一度タップし、ログアウトの応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「ログアウトできませんでした。もう一度お試しください。」は表示されない

### テストケース109: 「内容が更新されました。」が表示された後に「ログアウト」をタップして応答を待っている場合、「内容が更新されました。」は表示されない [LGL-A50]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `termsVersion` が `2026-02-01` に変わり、「同意する」をタップして送信が `outdated` を返し、「内容が更新されました。もう一度ご確認のうえ、同意してください。」が表示された後、「ログアウト」をタップし、ログアウトの応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「内容が更新されました。もう一度ご確認のうえ、同意してください。」は表示されない

### テストケース110: 「内容が更新されました。」が表示された後に再度チェックして「同意する」をタップし2回目の応答を待っている場合、「内容が更新されました。」は表示されない [LGL-A51]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `termsVersion` が `2026-02-01` に変わり、「同意する」をタップして送信が `outdated` を返し、「内容が更新されました。もう一度ご確認のうえ、同意してください。」が表示された後、2つのチェックボックスをチェックして「同意する」をタップし、2回目の送信の応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「内容が更新されました。もう一度ご確認のうえ、同意してください。」は表示されない

### テストケース111: 「ログアウト」が NetworkFailure で失敗した場合、「ログアウトできませんでした。」が表示され「通信エラー」ダイアログは表示されない [LGL-A52]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「ログアウト」をタップし、ログアウトが `NetworkFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示されたまま、「ログアウトできませんでした。もう一度お試しください。」が表示される。「通信エラー」ダイアログは表示されない

### テストケース112: 「ログアウト」が AuthFailure で失敗した場合、「ログアウトできませんでした。」が表示され「通信エラー」ダイアログは表示されない [LGL-A53]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「ログアウト」をタップし、ログアウトが `AuthFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示されたまま、「ログアウトできませんでした。もう一度お試しください。」が表示される。「通信エラー」ダイアログは表示されない

### テストケース113: 「フォルダを作成」ダイアログの上の同意ダイアログで「ログアウト」が成功した場合、2つのダイアログが閉じログイン画面が表示される [LGL-A54]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ホーム画面（`/home`）の「フォルダを作成」ダイアログの上に同意ダイアログが表示されている状態で、「ログアウト」をタップし、ログアウトが成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログと「フォルダを作成」ダイアログが閉じ、ログイン画面（`/login`）が表示される

### テストケース114: 「フォルダを作成」ダイアログの上の同意ダイアログの外側をタップした場合、同意ダイアログは表示されたままで、同意すると「フォルダを作成」ダイアログが「英単語」が入ったまま残っている [LGL-A55]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ホーム画面（`/home`）の「フォルダを作成」ダイアログで「フォルダ名」に「英単語」を入力し、その上に同意ダイアログが表示されている状態で、同意ダイアログの外側をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま。同意ダイアログを閉じると「フォルダを作成」ダイアログが「英単語」が入ったまま残っている（同意ダイアログの「同意する」で閉じて確かめる）

### テストケース115: 「フォルダを作成」ダイアログの上の同意ダイアログで戻る操作をした場合、同意ダイアログは表示されたままで「フォルダを作成」ダイアログも閉じない [LGL-A56]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: ホーム画面（`/home`）の「フォルダを作成」ダイアログで「フォルダ名」に「英単語」を入力し、その上に同意ダイアログが表示されている状態で、戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログは表示されたまま。「フォルダを作成」ダイアログも閉じない

### テストケース116: app_config/legal が無く未同意の状態で2つチェックして「同意する」をタップし送信が accepted を返した場合、同意ダイアログが閉じ送信が既定値の版数（2026-10-12）で1回呼ばれる [LGL-A57]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: `app_config/legal` が無く未同意の状態で起動し、2つのチェックボックスをチェックして「同意する」をタップし、送信が `accepted` を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じる。送信が1回、利用規約 `2026-10-12`・プライバシーポリシー `2026-10-12` を引数に呼ばれる

### テストケース117: outdated の後の判定し直しで app_config/legal が無かった場合、同意ダイアログが2つの行が未チェックで表示し直され「内容が更新されました。」が表示される [LGL-A58]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `termsVersion` が `2026-02-01` に変わり、「同意する」をタップして送信が `outdated` を返し、続く判定し直しで `app_config/legal` が無かった（未同意のまま）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示されたまま、「利用規約に同意する」「プライバシーポリシーに同意する」が表示され、2つとも未チェックになり、「内容が更新されました。もう一度ご確認のうえ、同意してください。」が表示される

### テストケース118: 「利用規約を読む」をタップした場合、閲覧画面にタイトル「利用規約」と戻るボタンが表示され WebView に利用規約の URL の読み込みが指示される [LGL-B01]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が開き、上部のバーに「利用規約」と戻るボタンが表示される。WebView に `https://example.com/terms` の読み込みが指示される

### テストケース119: 「プライバシーポリシーを読む」をタップした場合、閲覧画面にタイトル「プライバシーポリシー」と戻るボタンが表示され WebView にプライバシーポリシーの URL の読み込みが指示される [LGL-B02]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーを読む」をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が開き、上部のバーに「プライバシーポリシー」と戻るボタンが表示される。WebView に `https://example.com/privacy` の読み込みが指示される

### テストケース120: 「利用規約を読む」をタップしてページの読み込みが終わっていない場合、閲覧画面にローディングが表示される [LGL-B03]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、ページの読み込みが終わっていない
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面にローディングのインジケーターが表示される

### テストケース121: 「利用規約を読む」のページの読み込みが通信の失敗で失敗した場合、閲覧画面にエラーの文言と「再読み込み」が表示され「通信エラー」ダイアログは表示されず閲覧画面は開いたままである [LGL-B04]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、ページの読み込みが通信の失敗で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面に「ページを読み込めませんでした。通信環境を確認して、もう一度お試しください。」と「再読み込み」ボタンが表示される。「通信エラー」ダイアログは表示されない。閲覧画面は開いたまま

### テストケース122: 読み込みに失敗して「再読み込み」をタップし2回目の読み込みが終わっていない場合、エラーの文言と「再読み込み」が消えローディングが表示され WebView に利用規約の読み込みが合計2回指示される [LGL-B05]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、ページの読み込みが通信の失敗で失敗して「再読み込み」ボタンが表示された後、「再読み込み」をタップし、2回目の読み込みが終わっていない
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「ページを読み込めませんでした。通信環境を確認して、もう一度お試しください。」と「再読み込み」ボタンが消え、ローディングのインジケーターが表示される。WebView に `https://example.com/terms` の読み込みが合計2回指示される

### テストケース123: 「利用規約に同意する」をチェックして閲覧画面を開き戻るボタンをタップした場合、閲覧画面が閉じ同意ダイアログで利用規約はチェックされたままプライバシーポリシーは未チェックのままである [LGL-B06]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約に同意する」をチェックした後、「利用規約を読む」をタップし、閲覧画面の戻るボタンをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、同意ダイアログが表示される。「利用規約に同意する」はチェックされたまま、「プライバシーポリシーに同意する」は未チェックのまま

### テストケース124: 「利用規約に同意する」をチェックして閲覧画面を開き戻る操作をした場合、閲覧画面が閉じ同意ダイアログで利用規約はチェックされたままである [LGL-B07]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約に同意する」をチェックした後、「利用規約を読む」をタップし、閲覧画面で戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、同意ダイアログが表示される。「利用規約に同意する」はチェックされたまま

### テストケース125: チェックをせずに閲覧画面を開いて戻るボタンをタップした場合、2つのチェックボックスは未チェックのままで「同意する」は無効のままである [LGL-B08]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、閲覧画面の戻るボタンをタップした（チェックは1つもしていない）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示され、2つのチェックボックスは未チェックのまま。「同意する」ボタンは無効のまま

### テストケース126: 「利用規約を読む」で閲覧画面を開いて戻るボタンをタップした場合、画面のパスは /home のままで同意ダイアログは1つだけ表示されている [LGL-B09]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、閲覧画面の戻るボタンをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 表示中の画面のパスは `/home` のまま。同意ダイアログは1つだけ表示されている

### テストケース127: 「プライバシーポリシーを読む」をタップしてページの読み込みが終わっていない場合、閲覧画面にローディングが表示される [LGL-B10]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーを読む」をタップし、ページの読み込みが終わっていない
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面にローディングのインジケーターが表示される

### テストケース128: 「プライバシーポリシーを読む」のページの読み込みが通信の失敗で失敗した場合、閲覧画面にエラーの文言と「再読み込み」が表示され「通信エラー」ダイアログは表示されず閲覧画面は開いたままである [LGL-B11]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーを読む」をタップし、ページの読み込みが通信の失敗で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面に「ページを読み込めませんでした。通信環境を確認して、もう一度お試しください。」と「再読み込み」ボタンが表示される。「通信エラー」ダイアログは表示されない。閲覧画面は開いたまま

### テストケース129: プライバシーポリシーの読み込みに失敗して「再読み込み」をタップし2回目の読み込みが終わっていない場合、エラーの文言と「再読み込み」が消えローディングが表示され WebView にプライバシーポリシーの読み込みが合計2回指示される [LGL-B12]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーを読む」をタップし、ページの読み込みが通信の失敗で失敗して「再読み込み」ボタンが表示された後、「再読み込み」をタップし、2回目の読み込みが終わっていない
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「ページを読み込めませんでした。通信環境を確認して、もう一度お試しください。」と「再読み込み」ボタンが消え、ローディングのインジケーターが表示される。WebView に `https://example.com/privacy` の読み込みが合計2回指示される

### テストケース130: 「プライバシーポリシーに同意する」をチェックして閲覧画面を開き戻るボタンをタップした場合、閲覧画面が閉じプライバシーポリシーはチェックされたまま利用規約は未チェックのままである [LGL-B13]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーに同意する」をチェックした後、「プライバシーポリシーを読む」をタップし、閲覧画面の戻るボタンをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、同意ダイアログが表示される。「プライバシーポリシーに同意する」はチェックされたまま、「利用規約に同意する」は未チェックのまま

### テストケース131: 「プライバシーポリシーに同意する」をチェックして閲覧画面を開き戻る操作をした場合、閲覧画面が閉じプライバシーポリシーはチェックされたままである [LGL-B14]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーに同意する」をチェックした後、「プライバシーポリシーを読む」をタップし、閲覧画面で戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、同意ダイアログが表示される。「プライバシーポリシーに同意する」はチェックされたまま

### テストケース132: チェックをせずにプライバシーポリシーの閲覧画面を開いて戻るボタンをタップした場合、2つのチェックボックスは未チェックのままで「同意する」は無効のままである [LGL-B15]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーを読む」をタップし、閲覧画面の戻るボタンをタップした（チェックは1つもしていない）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが表示され、2つのチェックボックスは未チェックのまま。「同意する」ボタンは無効のまま

### テストケース133: 「プライバシーポリシーを読む」で閲覧画面を開いて戻るボタンをタップした場合、画面のパスは /home のままで同意ダイアログは1つだけ表示されている [LGL-B16]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「プライバシーポリシーを読む」をタップし、閲覧画面の戻るボタンをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 表示中の画面のパスは `/home` のまま。同意ダイアログは1つだけ表示されている

### テストケース134: 「利用規約を読む」を素早く2回タップした場合、閲覧画面は1つだけ開き、戻るボタンを1回タップすると同意ダイアログが表示される [LGL-B17]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」を素早く2回タップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面は1つだけ開く。閲覧画面の戻るボタンを1回タップすると同意ダイアログが表示される

### テストケース135: 「利用規約を読む」のページが HTTP ステータス 404 を返した場合、閲覧画面にエラーの文言と「再読み込み」が表示される [LGL-B18]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、ページが HTTP ステータス 404 を返した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面に「ページを読み込めませんでした。通信環境を確認して、もう一度お試しください。」と「再読み込み」ボタンが表示される

### テストケース136: 読み込みが失敗して「再読み込み」をタップした2回目の読み込みも失敗した場合、閲覧画面にエラーの文言と「再読み込み」が表示される [LGL-B19]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、ページの読み込みが通信の失敗で失敗して「再読み込み」をタップし、2回目の読み込みも通信の失敗で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面に「ページを読み込めませんでした。通信環境を確認して、もう一度お試しください。」と「再読み込み」ボタンが表示される

### テストケース137: 「利用規約を読む」をタップしてページの読み込みが終わる前に戻るボタンをタップした場合、閲覧画面が閉じ同意ダイアログが表示される [LGL-B20]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、ページの読み込みが終わる前に閲覧画面の戻るボタンをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、同意ダイアログが表示される

### テストケース138: WebView の中のリンクから別のページに移った後に戻るボタンをタップした場合、閲覧画面が閉じ同意ダイアログが表示される [LGL-B21]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、WebView の中のリンクから別のページに移った後、閲覧画面の戻るボタンをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、同意ダイアログが表示される

### テストケース139: WebView の中のリンクから別のページに移った後に戻る操作をした場合、閲覧画面が閉じ同意ダイアログが表示される [LGL-B22]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、WebView の中のリンクから別のページに移った後、戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、同意ダイアログが表示される

### テストケース140: 現行の利用規約の URL が変わり outdated で表示し直された同意ダイアログで「利用規約を読む」をタップした場合、WebView に新しい URL の読み込みが指示される [LGL-B23]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックした後、現行の `termsVersion` が `2026-02-01`、`termsUrl` が `https://example.com/terms-v2` に変わり、「同意する」をタップして送信が `outdated` を返し、表示し直された同意ダイアログで「利用規約を読む」をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: WebView に `https://example.com/terms-v2` の読み込みが指示される

### テストケース141: 読み込みに失敗して「再読み込み」を素早く2回タップした場合、WebView に利用規約の読み込みが合計2回指示される [LGL-B24]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 「利用規約を読む」をタップし、ページの読み込みが通信の失敗で失敗して「再読み込み」ボタンが表示された後、「再読み込み」を素早く2回タップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: WebView に `https://example.com/terms` の読み込みが合計2回（最初の1回と再読み込みの1回）指示される

### テストケース142: 設定画面を開いた場合、「このアプリについて」「利用規約」「プライバシーポリシー」が「外観」の項目より下で「アカウント」より上にこの順で表示される [LGL-B25]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: ログイン中で、同意済みの版数が現行の版数と一致している状態で、設定画面（`/settings`）を開いた
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 見出し「このアプリについて」と、項目「利用規約」「プライバシーポリシー」がこの順で表示される。これらは見出し「外観」の項目（「ダークモード」「カラーテーマ」）より下、見出し「アカウント」より上にある

### テストケース143: 設定画面で「利用規約」をタップして読み取りが成功した場合、閲覧画面にタイトル「利用規約」と戻るボタンが表示され WebView に利用規約の URL の読み込みが指示される [LGL-B26]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「利用規約」をタップし、現行の規約の情報の読み取りが成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が開き、上部のバーに「利用規約」と戻るボタンが表示される。WebView に `https://example.com/terms` の読み込みが指示される

### テストケース144: 設定画面で「プライバシーポリシー」をタップして読み取りが成功した場合、閲覧画面にタイトル「プライバシーポリシー」と戻るボタンが表示され WebView にプライバシーポリシーの URL の読み込みが指示される [LGL-B27]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「プライバシーポリシー」をタップし、現行の規約の情報の読み取りが成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が開き、上部のバーに「プライバシーポリシー」と戻るボタンが表示される。WebView に `https://example.com/privacy` の読み込みが指示される

### テストケース145: 設定画面で「利用規約」から閲覧画面を開いて戻るボタンをタップした場合、閲覧画面が閉じ設定画面が表示され同意ダイアログは表示されない [LGL-B28]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「利用規約」をタップして閲覧画面を開き、閲覧画面の戻るボタンをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、設定画面（`/settings`）が表示される。同意ダイアログは表示されない

### テストケース146: 設定画面で「プライバシーポリシー」から閲覧画面を開いて戻る操作をした場合、閲覧画面が閉じ設定画面が表示される [LGL-B29]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「プライバシーポリシー」をタップして閲覧画面を開き、戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、設定画面（`/settings`）が表示される

### テストケース147: 設定画面で「利用規約」をタップして読み取りが UnknownFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され画面のパスは /settings のままである [LGL-B30]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「利用規約」をタップし、現行の規約の情報の読み取りが `UnknownFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面は開かず、スナックバーに「ページを開けませんでした。通信環境を確認して、もう一度お試しください。」が表示される。表示中の画面のパスは `/settings` のまま

### テストケース148: 設定画面で「利用規約」をタップして読み取りが NetworkFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され「通信エラー」ダイアログは表示されない [LGL-B31]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「利用規約」をタップし、現行の規約の情報の読み取りが `NetworkFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面は開かず、スナックバーに「ページを開けませんでした。通信環境を確認して、もう一度お試しください。」が表示される。「通信エラー」ダイアログは表示されない。表示中の画面のパスは `/settings` のまま

### テストケース149: 設定画面で「利用規約」をタップして読み取りの応答を待っている間にもう一度タップした場合、読み取りが成功すると閲覧画面が1つだけ開き、戻るボタンを1回タップすると設定画面が表示される [LGL-B33]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「利用規約」をタップし、現行の規約の情報の読み取りの応答を待っている間に「利用規約」をもう一度タップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 読み取りが成功すると、閲覧画面が1つだけ開く。閲覧画面の戻るボタンを1回タップすると設定画面（`/settings`）が表示される

### テストケース150: 設定画面で「プライバシーポリシー」をタップして読み取りが UnknownFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され画面のパスは /settings のままである [LGL-B34]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「プライバシーポリシー」をタップし、現行の規約の情報の読み取りが `UnknownFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面は開かず、スナックバーに「ページを開けませんでした。通信環境を確認して、もう一度お試しください。」が表示される。表示中の画面のパスは `/settings` のまま

### テストケース151: 設定画面で「プライバシーポリシー」をタップして読み取りが NetworkFailure で失敗した場合、閲覧画面は開かずスナックバーにエラーの文言が表示され「通信エラー」ダイアログは表示されない [LGL-B36]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「プライバシーポリシー」をタップし、現行の規約の情報の読み取りが `NetworkFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面は開かず、スナックバーに「ページを開けませんでした。通信環境を確認して、もう一度お試しください。」が表示される。「通信エラー」ダイアログは表示されない。表示中の画面のパスは `/settings` のまま

### テストケース152: 設定画面で「プライバシーポリシー」をタップして読み取りの応答を待っている間にもう一度タップした場合、読み取りが成功すると閲覧画面が1つだけ開き、戻るボタンを1回タップすると設定画面が表示される [LGL-B37]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「プライバシーポリシー」をタップし、現行の規約の情報の読み取りの応答を待っている間に「プライバシーポリシー」をもう一度タップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 読み取りが成功すると、閲覧画面が1つだけ開く。閲覧画面の戻るボタンを1回タップすると設定画面（`/settings`）が表示される

### テストケース153: 設定画面で「利用規約」から閲覧画面を開いて戻る操作をした場合、閲覧画面が閉じ設定画面が表示される [LGL-B38]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「利用規約」をタップして閲覧画面を開き、戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、設定画面（`/settings`）が表示される

### テストケース154: 設定画面で「プライバシーポリシー」から閲覧画面を開いて戻るボタンをタップした場合、閲覧画面が閉じ設定画面が表示され同意ダイアログは表示されない [LGL-B39]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「プライバシーポリシー」をタップして閲覧画面を開き、閲覧画面の戻るボタンをタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が閉じ、設定画面（`/settings`）が表示される。同意ダイアログは表示されない

### テストケース155: 設定画面で「利用規約」をタップして読み取りの応答を待っている場合、「利用規約」の項目にローディングが表示される [LGL-B40]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「利用規約」をタップし、現行の規約の情報の読み取りの応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「利用規約」の項目にローディングのインジケーターが表示される

### テストケース156: 設定画面で「プライバシーポリシー」をタップして読み取りの応答を待っている場合、「プライバシーポリシー」の項目にローディングが表示される [LGL-B41]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。ログイン中の uid は A、同意済みの版数は現行の版数と一致、設定画面（/settings）を開く
- **入力値・テスト条件**: 設定画面（`/settings`）で「プライバシーポリシー」をタップし、現行の規約の情報の読み取りの応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「プライバシーポリシー」の項目にローディングのインジケーターが表示される

### テストケース157: app_config/legal が無い状態で設定画面の「利用規約」をタップした場合、閲覧画面が開き既定値の利用規約の URL の読み込みが指示されスナックバーは表示されない [LGL-B42]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: `app_config/legal` が無い状態で、設定画面（`/settings`）で「利用規約」をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が開き、上部のバーに「利用規約」が表示される。WebView に `https://word-stock-web.web.app/terms` の読み込みが指示される。スナックバーは表示されない

### テストケース158: app_config/legal が無い状態で設定画面の「プライバシーポリシー」をタップした場合、閲覧画面が開き既定値のプライバシーポリシーの URL の読み込みが指示されスナックバーは表示されない [LGL-B43]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: `app_config/legal` が無い状態で、設定画面（`/settings`）で「プライバシーポリシー」をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が開き、上部のバーに「プライバシーポリシー」が表示される。WebView に `https://word-stock-web.web.app/privacy` の読み込みが指示される。スナックバーは表示されない

### テストケース159: app_config/legal が無く未同意の状態で起動し「利用規約を読む」をタップした場合、閲覧画面が開き既定値の利用規約の URL の読み込みが指示される [LGL-B44]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: `app_config/legal` が無く未同意の状態で起動し、同意ダイアログの「利用規約を読む」をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が開き、WebView に `https://word-stock-web.web.app/terms` の読み込みが指示される

### テストケース160: app_config/legal が無く未同意の状態で起動し「プライバシーポリシーを読む」をタップした場合、閲覧画面が開き既定値のプライバシーポリシーの URL の読み込みが指示される [LGL-B45]
- **カテゴリ**: 正常系
- **対象メソッド**: LegalDocumentPage / LegalConsentGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: `app_config/legal` が無く未同意の状態で起動し、同意ダイアログの「プライバシーポリシーを読む」をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 閲覧画面が開き、WebView に `https://word-stock-web.web.app/privacy` の読み込みが指示される

### テストケース161: 設定画面で「利用規約」をタップして読み取りの応答を待っている間に「プライバシーポリシー」をタップした場合、読み取りが成功すると閲覧画面が1つだけ開きタイトルは「利用規約」である [LGL-B46]
- **カテゴリ**: 境界値
- **対象メソッド**: LegalLinksSection / LegalDocumentPage
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 設定画面（`/settings`）で「利用規約」をタップし、現行の規約の情報の読み取りの応答を待っている間に「プライバシーポリシー」をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 読み取りが成功すると、閲覧画面が1つだけ開き、上部のバーに「利用規約」が表示される

### テストケース162: 同意済みの版数の読み取りが NetworkFailure で失敗する状態で起動した場合、ホーム画面が表示され同意ダイアログも「通信エラー」ダイアログも表示されない [LGL-E02]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 現行の版数の読み取りは成功し、同意済みの版数の読み取りが `NetworkFailure` で失敗する状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）が表示される。同意ダイアログは表示されない。「通信エラー」ダイアログは表示されない

### テストケース163: 同意済みの版数の読み取りが UnknownFailure で失敗する状態で起動した場合、ホーム画面が表示され同意ダイアログも失敗の表示も出ない [LGL-E03]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 現行の版数の読み取りは成功し、同意済みの版数の読み取りが `UnknownFailure` で失敗する状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）が表示される。同意ダイアログは表示されない。失敗を知らせる表示も出ない

### テストケース164: 送信が NetworkFailure で失敗した場合、同意ダイアログが閉じタイトル「通信エラー」・本文・「OK」ボタンのダイアログが表示される [LGL-E04]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信が `NetworkFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、タイトル「通信エラー」、本文「通信に失敗しました。\nログイン画面に戻ります。」、「OK」ボタンのダイアログが表示される

### テストケース165: 送信が NetworkFailure で失敗した「通信エラー」ダイアログで「OK」をタップしてログアウトが成功した場合、ログイン画面に移動し同意ダイアログは表示されず SignOutUseCase が1回呼ばれる [LGL-E05]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して2つのチェックボックスをチェックして「同意する」をタップし、送信が `NetworkFailure` で失敗して表示された「通信エラー」ダイアログで「OK」をタップし、ログアウトが成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ログイン画面（`/login`）に移動する。同意ダイアログは表示されない。`SignOutUseCase` が1回呼ばれる

### テストケース166: 送信が AuthFailure で失敗した場合、同意ダイアログが閉じタイトル「通信エラー」・本文・「OK」ボタンのダイアログが表示される [LGL-E06]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信が `AuthFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 同意ダイアログが閉じ、タイトル「通信エラー」、本文「通信に失敗しました。\nログイン画面に戻ります。」、「OK」ボタンのダイアログが表示される

### テストケース167: 送信が AuthFailure で失敗した「通信エラー」ダイアログで「OK」をタップしてログアウトが成功した場合、ログイン画面に移動し同意ダイアログは表示されず SignOutUseCase が1回呼ばれる [LGL-E07]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して2つのチェックボックスをチェックして「同意する」をタップし、送信が `AuthFailure` で失敗して表示された「通信エラー」ダイアログで「OK」をタップし、ログアウトが成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ログイン画面（`/login`）に移動する。同意ダイアログは表示されない。`SignOutUseCase` が1回呼ばれる

### テストケース168: 通信エラーでログイン画面に移動した後に同じ uid でもう一度ログインして未同意のままの場合、ホーム画面に移動し2つのチェックが未チェックの同意ダイアログが表示される [LGL-E08]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: uid `A` が未同意の状態で起動して2つのチェックボックスをチェックして「同意する」をタップし、送信が `NetworkFailure` で失敗して「通信エラー」ダイアログの「OK」でログイン画面（`/login`）に移動した後、メールアドレスとパスワードで uid `A` にもう一度ログインし、ログインが成功した（uid `A` は未同意のまま）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）に移動し、その上に同意ダイアログが表示される。2つのチェックボックスは未チェック

### テストケース169: 「通信エラー」ダイアログで「OK」をタップしてログアウトが UnknownFailure で失敗した場合、ホーム画面の上に未チェックの同意ダイアログが表示され「ログアウトできませんでした。」は表示されない [LGL-E09]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 未同意の状態で起動して2つのチェックボックスをチェックして「同意する」をタップし、送信が `NetworkFailure` で失敗して表示された「通信エラー」ダイアログで「OK」をタップし、ログアウトが `UnknownFailure` で失敗した（判定し直しは成功し、まだ未同意）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に同意ダイアログが表示される。2つのチェックボックスは未チェック。「ログアウトできませんでした。もう一度お試しください。」は表示されない

### テストケース170: 「通信エラー」ダイアログの表示中に復帰した場合、「通信エラー」ダイアログは1つだけ表示されたままで同意ダイアログは表示されない [LGL-E10]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信が `NetworkFailure` で失敗して「通信エラー」ダイアログが表示されている間に、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「通信エラー」ダイアログが1つだけ表示されたまま。同意ダイアログは表示されない

### テストケース171: 「通信エラー」ダイアログの表示中に退会済みの記録ができた場合、「通信エラー」ダイアログが閉じ「アカウントが削除されました」ダイアログが表示され同意ダイアログは表示されず SignOutUseCase は0回である [LGL-E11]
- **カテゴリ**: 異常系
- **対象メソッド**: LegalConsentGate / LegalConsentDialog
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate → WithdrawnElsewhereGate → LegalConsentGate（app.dart と同じ配線。起動時の確認、復帰時の確認）で起動し、手書き Fake（LegalRepository・認証・退会用リポジトリ）・Mock Repository・WebView の Fake（legalWebViewBuilderProvider）を注入。既定の現行の版数は 2026-01-01、URL は https://example.com/terms・https://example.com/privacy、ログイン中の uid は A
- **入力値・テスト条件**: 2つのチェックボックスをチェックして「同意する」をタップし、送信が `NetworkFailure` で失敗して「通信エラー」ダイアログが表示されている間に、uid `A` の退会済みの記録ができた（監視で通知された）
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・同意済みの版数・現行の版数と URL・送信/ログアウトの結果と応答待ち・退会処理の記録・退会済みの記録・強制ログアウトの記録）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知・WebView の読み込み通知を pump で進める
- **期待結果**: 「通信エラー」ダイアログが閉じ、「アカウントが削除されました」ダイアログが表示される。同意ダイアログは表示されない。`SignOutUseCase` は0回（同意の機能からは呼ばない）

## 対象外

- L28-29：legalWebViewBuilderProvider の既定の builder（実物の WebView を作る）。テストでは WebView（プラットフォームの画面）を使えないため、legalWebViewBuilderProvider を Fake に差し替えて確かめる
- L115, L125-126, L143, L145-146, L149, L151-153, L157-158：_LegalWebView / _LegalWebViewState（実物の WebViewController・NavigationDelegate）。プラットフォームの WebView は Widget テストで動かせないため対象外。読み込み完了・失敗（HTTP 404 を含む）の通知は callbacks.onFinished / onError をテストから呼んで確かめる

## 検証の範囲（補足）

- LGL-B18：HTTP 404 は Fake の WebView から callbacks.onError を呼んで代用している。本物の WebView の onHttpError（ステータス 400 以上で onError にする変換、legal_document_page.dart の _LegalWebView）は、プラットフォームの WebView を Widget テストで動かせないため未検証
- LGL-B21・B22：「WebView の中のリンクから別のページに移った」は Fake の callbacks.onFinished を呼んで代用している。ページの遷移そのものは Fake では再現できない。確かめているのは「戻るボタン・戻る操作で、WebView の履歴ではなく閲覧画面を閉じる」ことだけ
