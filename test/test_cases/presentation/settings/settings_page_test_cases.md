## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/presentation/settings/settings_page.dart |
| 仕様書 | docs/detailed_design/presentation/settings/settings_page.md |
| クラス名 | SettingsPage / AccountDeletionGate / AccountDeletionRetryDialog |
| テスト対象メソッド | build() / _withdraw() / _onAccountDeletionChanged() / confirmAccountDeletion() / AccountDeletionGate / AccountDeletionRetryDialog |

対象は SettingsPage の描画と退会の画面操作（Widget テスト）。退会は画面をまたぐため、本物のルーター（routerProvider）と
AccountDeletionGate を `MaterialApp.router` に組み、手書き Fake（退会用リポジトリ・認証）と Mock Repository で検証する。
ViewModel（AccountDeletionViewModel）のロジック網羅は `test/presentation/settings/account_deletion_view_model_test.dart`
（仕様書4章）が別に担当する（本項目書では扱わない）。1〜5 は仕様 ID の無い既存テスト。

他の端末での退会（仕様書 3.6 / ACD-W 系）は、app.dart と同じ配線（AccountDeletionGate の内側に WithdrawnElsewhereGate、起動時の initialize()→check()、復帰時の check()）の
テスト用アプリで検証する。退会済みの記録・端末内の uid・強制ログアウトの記録・監視（uid ごとの StreamController）・オフライン・削除とログアウトの結果は手書き Fake で表す。
ViewModel / UseCase の分岐網羅は `withdrawn_elsewhere_view_model_test.dart` が別に担当する。

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | ローディング中は CircularProgressIndicator が表示される |  | 正常系 | build() | ✅ |
| 2 | 設定が読み込まれるとダークモードスイッチが表示される |  | 正常系 | build() | ✅ |
| 3 | カラーテーマのドロップダウンが表示される |  | 正常系 | build() | ✅ |
| 4 | ログアウト項目が表示される |  | 正常系 | build() | ✅ |
| 5 | ログアウトをタップすると確認ダイアログが表示される |  | 正常系 | build() | ✅ |
| 6 | ログイン中で退会処理の記録が無い状態で設定画面を開いた場合、「アカウント」の下に「ログアウト」「退会」がこの順で表示され、「退会」はエラー色で Icons.person_remove が表示される [ACD-D01] | ACD-D01 ##eb9e8e | 正常系 | build() / AccountDeletionGate | ✅ |
| 7 | 退会処理の記録が無い状態でアプリを起動した場合、「退会処理が完了していません」ダイアログは表示されない [ACD-D02] | ACD-D02 ##130667 | 正常系 | build() / AccountDeletionGate | ✅ |
| 8 | ログイン中で記録が requested の状態でアプリを起動した場合、再開ダイアログに本文と「再試行」だけが表示される [ACD-D03] | ACD-D03 ##aa3418 | 正常系 | build() / AccountDeletionGate | ✅ |
| 9 | ログインしていない状態で記録が serverDone の状態でアプリを起動した場合、ログイン画面の上に再開ダイアログと「再試行」だけが表示される [ACD-D04] | ACD-D04 ##be316a | 正常系 | build() / AccountDeletionGate | ✅ |
| 10 | ログインしていない状態で記録が requested の状態でアプリを起動した場合、ログイン画面の上に再開ダイアログと「再試行」だけが表示される [ACD-D05] | ACD-D05 ##bb7649 | 正常系 | build() / AccountDeletionGate | ✅ |
| 11 | 再開ダイアログが表示されている状態（再試行の処理中ではない）でダイアログの外側をタップした場合、ダイアログは表示されたままで記録は変わらず関数は呼ばれない [ACD-D06] | ACD-D06 ##14936b | 正常系 | build() / AccountDeletionGate | ✅ |
| 12 | 再開ダイアログが表示されている状態（再試行の処理中ではない）で戻る操作をした場合、ダイアログは表示されたままで記録は変わらず関数は呼ばれない [ACD-D07] | ACD-D07 ##7d3ba0 | 正常系 | build() / AccountDeletionGate | ✅ |
| 13 | ログイン中で記録が serverDone の状態でアプリを起動した場合、再開ダイアログと「再試行」だけが表示される [ACD-D08] | ACD-D08 ##5784ad | 正常系 | build() / AccountDeletionGate | ✅ |
| 14 | 再開ダイアログが表示されている状態で背後のボトムナビ「設定」の位置をタップした場合、ダイアログは表示されたままで画面のパスは変わらない [ACD-D09] | ACD-D09 ##c55907 | 正常系 | build() / AccountDeletionGate | ✅ |
| 15 | 記録が requested で「再試行」をタップし応答を待っている間に戻る操作をした場合、再開ダイアログは表示されたままで記録は変わらない [ACD-D10] | ACD-D10 ##bdb72c | 正常系 | build() / AccountDeletionGate | ✅ |
| 16 | 記録が requested で「再試行」をタップし応答を待っている間にダイアログの外側をタップした場合、再開ダイアログは表示されたままで記録は変わらない [ACD-D11] | ACD-D11 ##3d086a | 正常系 | build() / AccountDeletionGate | ✅ |
| 17 | ログイン中の uid が B で記録が uid A の requested の状態でアプリを起動した場合、再開ダイアログと「再試行」だけが表示される [ACD-D12] | ACD-D12 ##d75c18 | 正常系 | build() / AccountDeletionGate | ✅ |
| 18 | ログイン中で記録が requested の状態で「再試行」をタップし応答を待っている間に背後のボトムナビ「ホーム」の位置をタップした場合、再開ダイアログは表示されたままで画面のパスは変わらない [ACD-D13] | ACD-D13 ##82df5f | 正常系 | build() / AccountDeletionGate | ✅ |
| 19 | ログインしていない状態で記録が serverDone で再開ダイアログが表示されている状態で背後の「ログイン」ボタンの位置をタップした場合、ダイアログは表示されたままで画面のパスは /login のままである [ACD-D14] | ACD-D14 ##a57e0e | 正常系 | build() / AccountDeletionGate | ✅ |
| 20 | 起動時の記録の読み取りが UnknownFailure で失敗した状態でアプリを起動した場合、再開ダイアログと「再試行」だけが表示される [ACD-D15] | ACD-D15 ##63dfba | 異常系 | build() / AccountDeletionGate | ✅ |
| 21 | ログイン中で起動時の記録の確認が終わっていない状態でアプリを起動した場合、スプラッシュ画面（/）が表示されたままでホーム画面に移動しない [ACD-D16] | ACD-D16 ##f6eff1 | 境界値 | build() / AccountDeletionGate | ✅ |
| 22 | 設定画面で「退会」をタップした場合、タイトル「退会」・本文・「キャンセル」「OK」がこの順で横に並ぶダイアログが表示される [ACD-X01] | ACD-X01 ##c0710b | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 23 | 確認ダイアログで「キャンセル」をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X02] | ACD-X02 ##8dc50a | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 24 | 確認ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X03] | ACD-X03 ##9cb4a5 | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 25 | 確認ダイアログで「OK」をタップした場合、最終確認ダイアログが表示され、「OK」はエラー色で関数は呼ばれない [ACD-X04] | ACD-X04 ##bfcdbf | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 26 | 最終確認ダイアログで「キャンセル」をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X05] | ACD-X05 ##7e1ca6 | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 27 | 最終確認ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X06] | ACD-X06 ##2c564f | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 28 | 最終確認ダイアログで「OK」をタップし関数の応答を待っている場合、最終確認ダイアログが閉じて「退会処理中です」とインジケーターが表示され、パスワード入力欄は表示されない [ACD-X07] | ACD-X07 ##50c65c | 境界値 | _withdraw() / confirmAccountDeletion() | ✅ |
| 29 | 退会処理中に戻る操作をした場合、「退会処理中です」とインジケーターが表示されたままで設定画面から移動しない [ACD-X08] | ACD-X08 ##9c58fb | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 30 | 退会処理中にローディングの下にある「退会」の位置をタップした場合、確認ダイアログは表示されず関数を呼ぶ回数は1回のままである [ACD-X09] | ACD-X09 ##1a9d45 | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 31 | 最終確認ダイアログで「OK」をタップし関数の呼び出しと端末内の削除がどちらも成功した場合、ログイン画面（/login）に移動し「退会が完了しました」と「OK」のダイアログが表示される [ACD-X10] | ACD-X10 ##355d23 | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 32 | 完了ダイアログで「OK」をタップした場合、ダイアログが閉じてログイン画面が表示されたままである [ACD-X11] | ACD-X11 ##3ffda1 | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 33 | 最終確認ダイアログで「OK」をタップし関数の呼び出しが NetworkFailure で失敗した場合、「退会処理中です」が消え「退会できませんでした」ダイアログが表示され、設定画面から移動せず通信エラーダイアログは表示されない [ACD-X12] | ACD-X12 ##a7f15e | 異常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 34 | 「退会できませんでした」ダイアログで「OK」をタップした場合、ダイアログが閉じて設定画面が表示される [ACD-X13] | ACD-X13 ##8f1e4b | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 35 | 最終確認ダイアログで「OK」をタップし関数の呼び出しが UnknownFailure で失敗した場合、「退会処理中です」が消え再開ダイアログと「再試行」が表示される [ACD-X14] | ACD-X14 ##d90368 | 異常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 36 | 最終確認ダイアログで「OK」をタップし関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、「退会処理中です」が消え再開ダイアログと「再試行」が表示される [ACD-X15] | ACD-X15 ##f7f1cf | 異常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 37 | 退会処理中にローディングの下にあるボトムナビ「ホーム」の位置をタップした場合、「退会処理中です」が表示されたままで画面のパスは設定画面のままである [ACD-X16] | ACD-X16 ##e9a617 | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 38 | 最終確認ダイアログで「OK」をタップし関数の呼び出しと端末内の削除が成功しログアウトが UnknownFailure で失敗した場合、ログイン画面（/login）に移動し「退会が完了しました」ダイアログが表示される [ACD-X17] | ACD-X17 ##37a3e5 | 異常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 39 | 退会処理中にローディングの下にある「ログアウト」の位置をタップした場合、ログアウトの確認ダイアログは表示されず signOut は0回のままである [ACD-X18] | ACD-X18 ##133159 | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 40 | 完了ダイアログの外側をタップした場合、ダイアログが閉じてログイン画面が表示されたままである [ACD-X19] | ACD-X19 ##430a5d | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 41 | 「退会できませんでした」ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示される [ACD-X20] | ACD-X20 ##eae32e | 正常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 42 | 最終確認ダイアログで「OK」をタップし記録の書き込み（markRequested）が UnknownFailure で失敗した場合、「退会できませんでした」ダイアログが表示され、設定画面から移動せず関数は呼ばれない [ACD-X21] | ACD-X21 ##0c8d8b | 異常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 43 | 最終確認ダイアログで「OK」をタップし関数の呼び出しが NetworkFailure で失敗し記録の削除（clearRequest）が UnknownFailure で失敗した場合、再開ダイアログと「再試行」が表示される [ACD-X22] | ACD-X22 ##f30498 | 異常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 44 | 最終確認ダイアログで「OK」をタップし関数の呼び出しは成功し記録の更新（markServerDone）が UnknownFailure で失敗し端末内の削除は成功した場合、ログイン画面（/login）に移動し「退会が完了しました」ダイアログが表示される [ACD-X23] | ACD-X23 ##af7957 | 異常系 | _withdraw() / confirmAccountDeletion() | ✅ |
| 45 | 最終確認ダイアログで「OK」をタップし関数の呼び出しが AuthFailure で失敗した場合、「退会できませんでした」ダイアログが表示され、設定画面から移動せず通信エラーダイアログは表示されない [ACD-E01] | ACD-E01 ##6e53e8 | 異常系 | _withdraw() / _onAccountDeletionChanged() | ✅ |
| 46 | ログイン中で記録が requested で「再試行」をタップし関数の呼び出しと端末内の削除がどちらも成功した場合、再開ダイアログが閉じログイン画面（/login）に「退会が完了しました」ダイアログが表示される [ACD-T01] | ACD-T01 ##de80f7 | 正常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 47 | 記録が serverDone で「再試行」をタップし端末内の削除が成功した場合、再開ダイアログが閉じログイン画面に「退会が完了しました」ダイアログが表示され、関数は呼ばれない [ACD-T02] | ACD-T02 ##0d6de7 | 正常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 48 | ログインしていない状態で記録が requested のまま「再試行」をタップし端末内の削除が成功した場合、ログイン画面に「退会が完了しました」ダイアログが表示され、関数は呼ばれない [ACD-T03] | ACD-T03 ##abf7dc | 正常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 49 | ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが AuthFailure で失敗し端末内の削除が成功した場合、ログイン画面に「退会が完了しました」ダイアログが表示される [ACD-T04] | ACD-T04 ##1fc238 | 異常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 50 | ログイン中で記録が requested で「再試行」をタップし関数の応答を待っている場合、再開ダイアログの「再試行」が無効になり「退会処理中です」とインジケーターが表示される [ACD-T05] | ACD-T05 ##c8e9b7 | 境界値 | AccountDeletionRetryDialog / retry() | ✅ |
| 51 | ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが NetworkFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T06] | ACD-T06 ##8c16ec | 異常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 52 | ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T07] | ACD-T07 ##3bc337 | 異常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 53 | 記録が serverDone で「再試行」をタップし端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T08] | ACD-T08 ##20d175 | 異常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 54 | 記録が serverDone で「再試行」をタップし端末内の削除の完了を待っている場合、再開ダイアログの「再試行」が無効になり「退会処理中です」とインジケーターが表示される [ACD-T09] | ACD-T09 ##3d23f2 | 境界値 | AccountDeletionRetryDialog / retry() | ✅ |
| 55 | ログイン中の uid が B で記録が uid A の requested で「再試行」をタップし端末内の削除が成功した場合、ログイン画面（/login）に「退会が完了しました」ダイアログが表示され、関数は呼ばれない [ACD-T10] | ACD-T10 ##888b3a | 正常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 56 | 記録が serverDone で「再試行」をタップし端末内の削除が成功しログアウトが UnknownFailure で失敗した場合、ログイン画面（/login）に「退会が完了しました」ダイアログが表示される [ACD-T11] | ACD-T11 ##98780d | 異常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 57 | ログイン中で記録が requested で「再試行」をタップし関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T12] | ACD-T12 ##a9d83d | 異常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 58 | ログインしていない状態で記録が requested のまま「再試行」をタップし端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T13] | ACD-T13 ##a90a52 | 異常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 59 | ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが AuthFailure で失敗し端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T14] | ACD-T14 ##965f1c | 異常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 60 | 起動時の記録の読み取りが失敗して再開ダイアログが表示されている状態で「再試行」をタップし記録の読み直しで記録が無かった場合、再開ダイアログが閉じ関数は呼ばれない [ACD-T15] | ACD-T15 ##1e6791 | 異常系 | AccountDeletionRetryDialog / retry() | ✅ |
| 61 | ログイン中（uid A）で端末内に A のデータがあり A が退会済みの状態でアプリを起動した場合、ホーム画面の上にお知らせダイアログ（「OK」だけ）が表示され、データの削除ダイアログは表示されない [ACD-W01] | ACD-W01 #12b48c | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 62 | ログインしていない状態で端末内に A のデータがあり A が退会済みの状態でアプリを起動した場合、ログイン画面が表示されダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W02] | ACD-W02 #20d40d | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 63 | ログイン中の uid が B で端末内に A と B のデータがあり A だけが退会済みの状態でアプリを起動した場合、ホーム画面が表示されダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W03] | ACD-W03 #d8a048 | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 64 | ログイン中で端末内に A のデータがあり A に退会済みの記録が無い状態でアプリを起動した場合、データの削除ダイアログは表示されずホーム画面が表示される [ACD-W04] | ACD-W04 #343e8d | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 65 | ログイン中で端末内に A のデータがあり A が退会済みの状態でオフラインでアプリを起動した場合、データの削除ダイアログは表示されずホーム画面が表示される [ACD-W05] | ACD-W05 #2c4402 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 66 | ログイン中で端末内に A のデータがあり退会済みの記録の確認が UnknownFailure で失敗する状態でアプリを起動した場合、データの削除ダイアログは表示されずホーム画面が表示される [ACD-W06] | ACD-W06 #d1de84 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 67 | ログインしていない状態で端末内に A のデータがあり A が退会済みの状態でオフラインでアプリを起動した場合、ダイアログは表示されずログイン画面が表示され deleteLocalDataOfUsers は0回である [ACD-W38] | ACD-W38 #5c6692 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 68 | ログイン中で端末内にデータが1件も無く A が退会済みの状態でアプリを起動した場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W24] | ACD-W24 #a684ce | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 69 | ログイン中で端末内に A のデータがあり退会処理の記録が無い状態で起動し退会済みの記録の確認の応答を待っている場合、ホーム画面が表示される [ACD-W25] | ACD-W25 #6bc074 | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 70 | ログインしていない状態で端末内に A のデータがある状態で起動し退会済みの記録の確認の応答を待っている場合、ログイン画面が表示される [ACD-W39] | ACD-W39 #b80343 | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 71 | お知らせダイアログの「OK」をタップしてログアウトが成功した場合、お知らせが閉じてログイン画面に移動し、その上にデータの削除ダイアログ（「OK」だけ）が表示される [ACD-W26] | ACD-W26 #f2adf8 | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 72 | お知らせダイアログの「OK」をタップし1回目のログアウトが UnknownFailure で失敗し2回目が成功した場合、お知らせが閉じてログイン画面に移動しデータの削除ダイアログが表示される [ACD-W27] | ACD-W27 #64552c | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 73 | お知らせダイアログが表示されている状態でダイアログの外側をタップした場合、お知らせは表示されたままで signOut は0回である [ACD-W28] | ACD-W28 #b081cc | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 74 | お知らせダイアログが表示されている状態で戻る操作をした場合、お知らせは表示されたままで signOut は0回である [ACD-W29] | ACD-W29 #95e07f | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 75 | お知らせダイアログの「OK」をタップしログアウトが2回とも UnknownFailure で失敗した場合、お知らせが閉じてログイン画面に移動しデータの削除ダイアログが表示される [ACD-W42] | ACD-W42 #fec342 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 76 | データの削除ダイアログの「OK」をタップし端末内の削除が成功した場合、ダイアログが閉じて画面のパスは /login のままである [ACD-W07] | ACD-W07 #fb99b6 | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 77 | データの削除ダイアログの「OK」をタップし端末内の削除の完了を待っている場合、ダイアログは表示されたまま「OK」が無効になりインジケーターが表示される [ACD-W08] | ACD-W08 #706ba6 | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 78 | データの削除ダイアログの「OK」をタップし端末内の削除が UnknownFailure で失敗した場合、データの削除ダイアログが閉じて失敗ダイアログ（「OK」だけ）が表示される [ACD-W09] | ACD-W09 #66b388 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 79 | 端末内の削除が UnknownFailure で失敗した後に失敗ダイアログの「OK」でやり直して削除が成功した場合、データの削除ダイアログが閉じ失敗ダイアログは表示されない [ACD-W10] | ACD-W10 #32742a | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 80 | データの削除ダイアログが表示されている状態（削除の処理中ではない）でダイアログの外側をタップした場合、ダイアログは表示されたままで deleteLocalDataOfUsers は0回である [ACD-W11] | ACD-W11 #b0f212 | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 81 | データの削除ダイアログが表示されている状態（削除の処理中ではない）で戻る操作をした場合、ダイアログは表示されたままで deleteLocalDataOfUsers は0回である [ACD-W12] | ACD-W12 #b7ad99 | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 82 | データの削除ダイアログの「OK」をタップし端末内の削除の完了を待っている間にダイアログの外側をタップした場合、ダイアログは表示されたままである [ACD-W13] | ACD-W13 #20060b | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 83 | データの削除ダイアログの「OK」をタップし端末内の削除の完了を待っている間に戻る操作をした場合、ダイアログは表示されたままである [ACD-W14] | ACD-W14 #b54d29 | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 84 | データの削除ダイアログが表示されている状態で A の退会済みの記録があるままアプリがフォアグラウンドに戻った場合、データの削除ダイアログは1つだけ表示されたままである [ACD-W19] | ACD-W19 #1985a7 | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 85 | 端末内の削除が UnknownFailure で失敗して失敗ダイアログが表示されている状態で「OK」をタップした場合、失敗ダイアログが閉じてデータの削除ダイアログが表示される [ACD-W33] | ACD-W33 #ee548e | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 86 | 失敗ダイアログが表示されている状態でダイアログの外側をタップした場合、失敗ダイアログは表示されたままでデータの削除ダイアログは表示されない [ACD-W34] | ACD-W34 #2b6245 | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 87 | 失敗ダイアログが表示されている状態で戻る操作をした場合、失敗ダイアログは表示されたままでデータの削除ダイアログは表示されない [ACD-W35] | ACD-W35 #77a9b8 | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 88 | 失敗ダイアログの「OK」でやり直した端末内の削除がもう一度 UnknownFailure で失敗した場合、データの削除ダイアログが閉じて失敗ダイアログが表示される [ACD-W41] | ACD-W41 #4f474a | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 89 | ログインしていない状態で A の退会処理の記録が requested で A が退会済みの状態でアプリを起動した場合、再開ダイアログが表示されデータの削除ダイアログは表示されない [ACD-W15] | ACD-W15 #49c681 | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 90 | ログインしていない状態で A の退会処理の記録が requested で C が退会済みの状態でアプリを起動した場合、再開ダイアログが表示されデータの削除ダイアログは表示されない [ACD-W16] | ACD-W16 #169d64 | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 91 | ログイン中で A の退会処理の記録が requested で A が退会済みの状態でアプリを起動した場合、再開ダイアログが表示されデータの削除ダイアログは表示されない [ACD-W21] | ACD-W21 #929819 | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 92 | ログイン中で起動時には A に退会済みの記録が無く、ホーム画面を表示している状態で記録ができアプリがフォアグラウンドに戻った場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W17] | ACD-W17 #cb96f0 | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 93 | ログインしていない状態で端末内に A と C のデータがあり両方が退会済みの状態でアプリを起動した場合、ダイアログは表示されず deleteLocalDataOfUsers が1回呼ばれ引数に A と C が含まれる [ACD-W18] | ACD-W18 #2e1d0c | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 94 | ログイン中で A が退会済みの状態でオフラインで起動してホーム画面を表示し、オンラインになってからアプリがフォアグラウンドに戻った場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W20] | ACD-W20 #c2d78e | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 95 | ログイン中の uid が B で端末内に A と B のデータがあり設定画面を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、設定画面のままダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W23] | ACD-W23 #cd7d5a | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 96 | ログインしていない状態で A の削除が1回目 UnknownFailure・2回目成功の状態で起動しその後アプリがフォアグラウンドに戻った場合、ログイン画面のままダイアログは出ず deleteLocalDataOfUsers([A]) が合計2回呼ばれる [ACD-W53] | ACD-W53 #3945b8 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 97 | 強制ログアウトの後にデータの削除ダイアログの「OK」で削除が成功しアプリがフォアグラウンドに戻った場合、画面のパスは /login のままでホーム画面に移動せずデータの削除ダイアログは表示されない [ACD-W43] | ACD-W43 #e122ec | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 98 | 退会の確認ダイアログ（タイトル「退会」）を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、確認ダイアログが閉じてお知らせダイアログが表示される [ACD-W30] | ACD-W30 #51c652 | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 99 | 最終確認ダイアログ（タイトル「最終確認」）を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、最終確認ダイアログが閉じてお知らせダイアログが表示される [ACD-W31] | ACD-W31 #d60a67 | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 100 | 「退会できませんでした」ダイアログを表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、そのダイアログが閉じてお知らせダイアログが表示される [ACD-W32] | ACD-W32 #ac5aeb | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 101 | 「ログアウト」をタップしてログアウトのダイアログ（本文「ログアウトしますか？」）を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、そのダイアログが閉じてお知らせダイアログが表示される [ACD-W36] | ACD-W36 #add26f | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 102 | お知らせの「OK」でログアウトが2回とも失敗し、データの削除ダイアログの「OK」を押さずに終了して Firebase 上は A のまま起動し直した場合、ログイン画面が表示されダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W37] | ACD-W37 #e53c69 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 103 | お知らせの「OK」でログアウトが2回とも失敗しデータの削除が成功した後、アプリを終了して Firebase 上は A のまま起動し直した場合、ログイン画面が表示されダイアログは出ない [ACD-W49] | ACD-W49 #fe9fa4 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 104 | Firebase 上のログイン中の uid が A で A の強制ログアウトの記録があり端末内に A のデータがある状態でオフラインで起動した場合、ログイン画面が表示されホーム画面に移動せず signOut は1回である [ACD-W47] | ACD-W47 #8ba927 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 105 | ログイン中で端末内に A と C のデータがあり両方が退会済みで、お知らせの「OK」でログアウトし、データの削除ダイアログの「OK」で削除が成功した場合、ダイアログが閉じて画面のパスは /login のままで、起動時に deleteLocalDataOfUsers([C]) が1回呼ばれている [ACD-W40] | ACD-W40 #bd7de5 | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 106 | ログインしていない状態で A が退会済みで端末内の削除が UnknownFailure で失敗する状態でアプリを起動した場合、ログイン画面が表示されダイアログは表示されない [ACD-W50] | ACD-W50 #ef11c9 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 107 | ログイン中で端末内に A と C のデータがあり両方が退会済みで C の端末内の削除が UnknownFailure で失敗する状態でアプリを起動した場合、ホーム画面の上にお知らせダイアログが表示され失敗を知らせる表示は無い [ACD-W51] | ACD-W51 #ccc861 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 108 | ログイン中の uid が B で端末内に A と B のデータがあり A だけが退会済みで端末内の削除が UnknownFailure で失敗する状態でアプリを起動した場合、ホーム画面が表示されダイアログは表示されない [ACD-W52] | ACD-W52 #b8ffa5 | 異常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 109 | ログイン中でホーム画面を表示している状態でアプリをフォアグラウンドにしたまま A に退会済みの記録ができた場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W44] | ACD-W44 #36022f | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 110 | ログイン中で設定画面を表示している状態でアプリをフォアグラウンドにしたまま A に退会済みの記録ができた場合、設定画面の上にお知らせダイアログが表示される [ACD-W45] | ACD-W45 #35e2bc | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 111 | 最終確認ダイアログの「OK」をタップして「退会処理中です」が表示されている状態で A に退会済みの記録ができた場合、お知らせダイアログは表示されず「退会処理中です」が表示されたままである [ACD-W46] | ACD-W46 #6aa639 | 境界値 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |
| 112 | 最終確認ダイアログ（タイトル「最終確認」）を表示している状態でアプリをフォアグラウンドにしたまま A に退会済みの記録ができた場合、最終確認ダイアログが閉じてお知らせダイアログが表示される [ACD-W48] | ACD-W48 #27bf0f | 正常系 | WithdrawnElsewhereGate / WithdrawnElsewhereViewModel | ✅ |

## テストケース詳細

### テストケース1: ローディング中は CircularProgressIndicator が表示される
- **カテゴリ**: 正常系
- **対象メソッド**: build()
- **事前条件**: SettingsViewModel を override した SettingsPage 単体
- **入力値・テスト条件**: ローディング中は CircularProgressIndicator が表示される
- **操作手順**: ローディング中は CircularProgressIndicator が表示される（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ローディング中は CircularProgressIndicator が表示される

### テストケース2: 設定が読み込まれるとダークモードスイッチが表示される
- **カテゴリ**: 正常系
- **対象メソッド**: build()
- **事前条件**: SettingsViewModel を override した SettingsPage 単体
- **入力値・テスト条件**: 設定が読み込まれるとダークモードスイッチが表示される
- **操作手順**: 設定が読み込まれるとダークモードスイッチが表示される（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 設定が読み込まれるとダークモードスイッチが表示される

### テストケース3: カラーテーマのドロップダウンが表示される
- **カテゴリ**: 正常系
- **対象メソッド**: build()
- **事前条件**: SettingsViewModel を override した SettingsPage 単体
- **入力値・テスト条件**: カラーテーマのドロップダウンが表示される
- **操作手順**: カラーテーマのドロップダウンが表示される（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: カラーテーマのドロップダウンが表示される

### テストケース4: ログアウト項目が表示される
- **カテゴリ**: 正常系
- **対象メソッド**: build()
- **事前条件**: SettingsViewModel を override した SettingsPage 単体
- **入力値・テスト条件**: ログアウト項目が表示される
- **操作手順**: ログアウト項目が表示される（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログアウト項目が表示される

### テストケース5: ログアウトをタップすると確認ダイアログが表示される
- **カテゴリ**: 正常系
- **対象メソッド**: build()
- **事前条件**: SettingsViewModel を override した SettingsPage 単体
- **入力値・テスト条件**: ログアウトをタップすると確認ダイアログが表示される
- **操作手順**: ログアウトをタップすると確認ダイアログが表示される（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログアウトをタップすると確認ダイアログが表示される

### テストケース6: ログイン中で退会処理の記録が無い状態で設定画面を開いた場合、「アカウント」の下に「ログアウト」「退会」がこの順で表示され、「退会」はエラー色で Icons.person_remove が表示される [ACD-D01]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で退会処理の記録が無い状態で設定画面を開いた場合
- **操作手順**: ログイン中で退会処理の記録が無い状態で設定画面を開いた場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 「アカウント」の下に「ログアウト」「退会」がこの順で表示され、「退会」はエラー色で Icons.person_remove が表示される

### テストケース7: 退会処理の記録が無い状態でアプリを起動した場合、「退会処理が完了していません」ダイアログは表示されない [ACD-D02]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 退会処理の記録が無い状態でアプリを起動した場合
- **操作手順**: 退会処理の記録が無い状態でアプリを起動した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 「退会処理が完了していません」ダイアログは表示されない

### テストケース8: ログイン中で記録が requested の状態でアプリを起動した場合、再開ダイアログに本文と「再試行」だけが表示される [ACD-D03]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で記録が requested の状態でアプリを起動した場合
- **操作手順**: ログイン中で記録が requested の状態でアプリを起動した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログに本文と「再試行」だけが表示される

### テストケース9: ログインしていない状態で記録が serverDone の状態でアプリを起動した場合、ログイン画面の上に再開ダイアログと「再試行」だけが表示される [ACD-D04]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で記録が serverDone の状態でアプリを起動した場合
- **操作手順**: ログインしていない状態で記録が serverDone の状態でアプリを起動した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログイン画面の上に再開ダイアログと「再試行」だけが表示される

### テストケース10: ログインしていない状態で記録が requested の状態でアプリを起動した場合、ログイン画面の上に再開ダイアログと「再試行」だけが表示される [ACD-D05]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で記録が requested の状態でアプリを起動した場合
- **操作手順**: ログインしていない状態で記録が requested の状態でアプリを起動した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログイン画面の上に再開ダイアログと「再試行」だけが表示される

### テストケース11: 再開ダイアログが表示されている状態（再試行の処理中ではない）でダイアログの外側をタップした場合、ダイアログは表示されたままで記録は変わらず関数は呼ばれない [ACD-D06]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 再開ダイアログが表示されている状態（再試行の処理中ではない）でダイアログの外側をタップした場合
- **操作手順**: 再開ダイアログが表示されている状態（再試行の処理中ではない）でダイアログの外側をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログは表示されたままで記録は変わらず関数は呼ばれない

### テストケース12: 再開ダイアログが表示されている状態（再試行の処理中ではない）で戻る操作をした場合、ダイアログは表示されたままで記録は変わらず関数は呼ばれない [ACD-D07]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 再開ダイアログが表示されている状態（再試行の処理中ではない）で戻る操作をした場合
- **操作手順**: 再開ダイアログが表示されている状態（再試行の処理中ではない）で戻る操作をした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログは表示されたままで記録は変わらず関数は呼ばれない

### テストケース13: ログイン中で記録が serverDone の状態でアプリを起動した場合、再開ダイアログと「再試行」だけが表示される [ACD-D08]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で記録が serverDone の状態でアプリを起動した場合
- **操作手順**: ログイン中で記録が serverDone の状態でアプリを起動した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログと「再試行」だけが表示される

### テストケース14: 再開ダイアログが表示されている状態で背後のボトムナビ「設定」の位置をタップした場合、ダイアログは表示されたままで画面のパスは変わらない [ACD-D09]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 再開ダイアログが表示されている状態で背後のボトムナビ「設定」の位置をタップした場合
- **操作手順**: 再開ダイアログが表示されている状態で背後のボトムナビ「設定」の位置をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログは表示されたままで画面のパスは変わらない

### テストケース15: 記録が requested で「再試行」をタップし応答を待っている間に戻る操作をした場合、再開ダイアログは表示されたままで記録は変わらない [ACD-D10]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 記録が requested で「再試行」をタップし応答を待っている間に戻る操作をした場合
- **操作手順**: 記録が requested で「再試行」をタップし応答を待っている間に戻る操作をした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログは表示されたままで記録は変わらない

### テストケース16: 記録が requested で「再試行」をタップし応答を待っている間にダイアログの外側をタップした場合、再開ダイアログは表示されたままで記録は変わらない [ACD-D11]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 記録が requested で「再試行」をタップし応答を待っている間にダイアログの外側をタップした場合
- **操作手順**: 記録が requested で「再試行」をタップし応答を待っている間にダイアログの外側をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログは表示されたままで記録は変わらない

### テストケース17: ログイン中の uid が B で記録が uid A の requested の状態でアプリを起動した場合、再開ダイアログと「再試行」だけが表示される [ACD-D12]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が B で記録が uid A の requested の状態でアプリを起動した場合
- **操作手順**: ログイン中の uid が B で記録が uid A の requested の状態でアプリを起動した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログと「再試行」だけが表示される

### テストケース18: ログイン中で記録が requested の状態で「再試行」をタップし応答を待っている間に背後のボトムナビ「ホーム」の位置をタップした場合、再開ダイアログは表示されたままで画面のパスは変わらない [ACD-D13]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で記録が requested の状態で「再試行」をタップし応答を待っている間に背後のボトムナビ「ホーム」の位置をタップした場合
- **操作手順**: ログイン中で記録が requested の状態で「再試行」をタップし応答を待っている間に背後のボトムナビ「ホーム」の位置をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログは表示されたままで画面のパスは変わらない

### テストケース19: ログインしていない状態で記録が serverDone で再開ダイアログが表示されている状態で背後の「ログイン」ボタンの位置をタップした場合、ダイアログは表示されたままで画面のパスは /login のままである [ACD-D14]
- **カテゴリ**: 正常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で記録が serverDone で再開ダイアログが表示されている状態で背後の「ログイン」ボタンの位置をタップした場合
- **操作手順**: ログインしていない状態で記録が serverDone で再開ダイアログが表示されている状態で背後の「ログイン」ボタンの位置をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログは表示されたままで画面のパスは /login のままである

### テストケース20: 起動時の記録の読み取りが UnknownFailure で失敗した状態でアプリを起動した場合、再開ダイアログと「再試行」だけが表示される [ACD-D15]
- **カテゴリ**: 異常系
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 起動時の記録の読み取りが UnknownFailure で失敗した状態でアプリを起動した場合
- **操作手順**: 起動時の記録の読み取りが UnknownFailure で失敗した状態でアプリを起動した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログと「再試行」だけが表示される

### テストケース21: ログイン中で起動時の記録の確認が終わっていない状態でアプリを起動した場合、スプラッシュ画面（/）が表示されたままでホーム画面に移動しない [ACD-D16]
- **カテゴリ**: 境界値
- **対象メソッド**: build() / AccountDeletionGate
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で起動時の記録の確認が終わっていない状態でアプリを起動した場合
- **操作手順**: ログイン中で起動時の記録の確認が終わっていない状態でアプリを起動した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: スプラッシュ画面（/）が表示されたままでホーム画面に移動しない

### テストケース22: 設定画面で「退会」をタップした場合、タイトル「退会」・本文・「キャンセル」「OK」がこの順で横に並ぶダイアログが表示される [ACD-X01]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 設定画面で「退会」をタップした場合
- **操作手順**: 設定画面で「退会」をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: タイトル「退会」・本文・「キャンセル」「OK」がこの順で横に並ぶダイアログが表示される

### テストケース23: 確認ダイアログで「キャンセル」をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X02]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 確認ダイアログで「キャンセル」をタップした場合
- **操作手順**: 確認ダイアログで「キャンセル」をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである

### テストケース24: 確認ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X03]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 確認ダイアログの外側をタップした場合
- **操作手順**: 確認ダイアログの外側をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである

### テストケース25: 確認ダイアログで「OK」をタップした場合、最終確認ダイアログが表示され、「OK」はエラー色で関数は呼ばれない [ACD-X04]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 確認ダイアログで「OK」をタップした場合
- **操作手順**: 確認ダイアログで「OK」をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 最終確認ダイアログが表示され、「OK」はエラー色で関数は呼ばれない

### テストケース26: 最終確認ダイアログで「キャンセル」をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X05]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「キャンセル」をタップした場合
- **操作手順**: 最終確認ダイアログで「キャンセル」をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである

### テストケース27: 最終確認ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである [ACD-X06]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログの外側をタップした場合
- **操作手順**: 最終確認ダイアログの外側をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログが閉じて設定画面が表示され、関数は呼ばれず記録も無いままである

### テストケース28: 最終確認ダイアログで「OK」をタップし関数の応答を待っている場合、最終確認ダイアログが閉じて「退会処理中です」とインジケーターが表示され、パスワード入力欄は表示されない [ACD-X07]
- **カテゴリ**: 境界値
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「OK」をタップし関数の応答を待っている場合
- **操作手順**: 最終確認ダイアログで「OK」をタップし関数の応答を待っている場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 最終確認ダイアログが閉じて「退会処理中です」とインジケーターが表示され、パスワード入力欄は表示されない

### テストケース29: 退会処理中に戻る操作をした場合、「退会処理中です」とインジケーターが表示されたままで設定画面から移動しない [ACD-X08]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 退会処理中に戻る操作をした場合
- **操作手順**: 退会処理中に戻る操作をした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 「退会処理中です」とインジケーターが表示されたままで設定画面から移動しない

### テストケース30: 退会処理中にローディングの下にある「退会」の位置をタップした場合、確認ダイアログは表示されず関数を呼ぶ回数は1回のままである [ACD-X09]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 退会処理中にローディングの下にある「退会」の位置をタップした場合
- **操作手順**: 退会処理中にローディングの下にある「退会」の位置をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 確認ダイアログは表示されず関数を呼ぶ回数は1回のままである

### テストケース31: 最終確認ダイアログで「OK」をタップし関数の呼び出しと端末内の削除がどちらも成功した場合、ログイン画面（/login）に移動し「退会が完了しました」と「OK」のダイアログが表示される [ACD-X10]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「OK」をタップし関数の呼び出しと端末内の削除がどちらも成功した場合
- **操作手順**: 最終確認ダイアログで「OK」をタップし関数の呼び出しと端末内の削除がどちらも成功した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログイン画面（/login）に移動し「退会が完了しました」と「OK」のダイアログが表示される

### テストケース32: 完了ダイアログで「OK」をタップした場合、ダイアログが閉じてログイン画面が表示されたままである [ACD-X11]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 完了ダイアログで「OK」をタップした場合
- **操作手順**: 完了ダイアログで「OK」をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログが閉じてログイン画面が表示されたままである

### テストケース33: 最終確認ダイアログで「OK」をタップし関数の呼び出しが NetworkFailure で失敗した場合、「退会処理中です」が消え「退会できませんでした」ダイアログが表示され、設定画面から移動せず通信エラーダイアログは表示されない [ACD-X12]
- **カテゴリ**: 異常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「OK」をタップし関数の呼び出しが NetworkFailure で失敗した場合
- **操作手順**: 最終確認ダイアログで「OK」をタップし関数の呼び出しが NetworkFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 「退会処理中です」が消え「退会できませんでした」ダイアログが表示され、設定画面から移動せず通信エラーダイアログは表示されない

### テストケース34: 「退会できませんでした」ダイアログで「OK」をタップした場合、ダイアログが閉じて設定画面が表示される [ACD-X13]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 「退会できませんでした」ダイアログで「OK」をタップした場合
- **操作手順**: 「退会できませんでした」ダイアログで「OK」をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログが閉じて設定画面が表示される

### テストケース35: 最終確認ダイアログで「OK」をタップし関数の呼び出しが UnknownFailure で失敗した場合、「退会処理中です」が消え再開ダイアログと「再試行」が表示される [ACD-X14]
- **カテゴリ**: 異常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「OK」をタップし関数の呼び出しが UnknownFailure で失敗した場合
- **操作手順**: 最終確認ダイアログで「OK」をタップし関数の呼び出しが UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 「退会処理中です」が消え再開ダイアログと「再試行」が表示される

### テストケース36: 最終確認ダイアログで「OK」をタップし関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、「退会処理中です」が消え再開ダイアログと「再試行」が表示される [ACD-X15]
- **カテゴリ**: 異常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「OK」をタップし関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合
- **操作手順**: 最終確認ダイアログで「OK」をタップし関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 「退会処理中です」が消え再開ダイアログと「再試行」が表示される

### テストケース37: 退会処理中にローディングの下にあるボトムナビ「ホーム」の位置をタップした場合、「退会処理中です」が表示されたままで画面のパスは設定画面のままである [ACD-X16]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 退会処理中にローディングの下にあるボトムナビ「ホーム」の位置をタップした場合
- **操作手順**: 退会処理中にローディングの下にあるボトムナビ「ホーム」の位置をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 「退会処理中です」が表示されたままで画面のパスは設定画面のままである

### テストケース38: 最終確認ダイアログで「OK」をタップし関数の呼び出しと端末内の削除が成功しログアウトが UnknownFailure で失敗した場合、ログイン画面（/login）に移動し「退会が完了しました」ダイアログが表示される [ACD-X17]
- **カテゴリ**: 異常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「OK」をタップし関数の呼び出しと端末内の削除が成功しログアウトが UnknownFailure で失敗した場合
- **操作手順**: 最終確認ダイアログで「OK」をタップし関数の呼び出しと端末内の削除が成功しログアウトが UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログイン画面（/login）に移動し「退会が完了しました」ダイアログが表示される

### テストケース39: 退会処理中にローディングの下にある「ログアウト」の位置をタップした場合、ログアウトの確認ダイアログは表示されず signOut は0回のままである [ACD-X18]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 退会処理中にローディングの下にある「ログアウト」の位置をタップした場合
- **操作手順**: 退会処理中にローディングの下にある「ログアウト」の位置をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログアウトの確認ダイアログは表示されず signOut は0回のままである

### テストケース40: 完了ダイアログの外側をタップした場合、ダイアログが閉じてログイン画面が表示されたままである [ACD-X19]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 完了ダイアログの外側をタップした場合
- **操作手順**: 完了ダイアログの外側をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログが閉じてログイン画面が表示されたままである

### テストケース41: 「退会できませんでした」ダイアログの外側をタップした場合、ダイアログが閉じて設定画面が表示される [ACD-X20]
- **カテゴリ**: 正常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 「退会できませんでした」ダイアログの外側をタップした場合
- **操作手順**: 「退会できませんでした」ダイアログの外側をタップした場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ダイアログが閉じて設定画面が表示される

### テストケース42: 最終確認ダイアログで「OK」をタップし記録の書き込み（markRequested）が UnknownFailure で失敗した場合、「退会できませんでした」ダイアログが表示され、設定画面から移動せず関数は呼ばれない [ACD-X21]
- **カテゴリ**: 異常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「OK」をタップし記録の書き込み（markRequested）が UnknownFailure で失敗した場合
- **操作手順**: 最終確認ダイアログで「OK」をタップし記録の書き込み（markRequested）が UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 「退会できませんでした」ダイアログが表示され、設定画面から移動せず関数は呼ばれない

### テストケース43: 最終確認ダイアログで「OK」をタップし関数の呼び出しが NetworkFailure で失敗し記録の削除（clearRequest）が UnknownFailure で失敗した場合、再開ダイアログと「再試行」が表示される [ACD-X22]
- **カテゴリ**: 異常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「OK」をタップし関数の呼び出しが NetworkFailure で失敗し記録の削除（clearRequest）が UnknownFailure で失敗した場合
- **操作手順**: 最終確認ダイアログで「OK」をタップし関数の呼び出しが NetworkFailure で失敗し記録の削除（clearRequest）が UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログと「再試行」が表示される

### テストケース44: 最終確認ダイアログで「OK」をタップし関数の呼び出しは成功し記録の更新（markServerDone）が UnknownFailure で失敗し端末内の削除は成功した場合、ログイン画面（/login）に移動し「退会が完了しました」ダイアログが表示される [ACD-X23]
- **カテゴリ**: 異常系
- **対象メソッド**: _withdraw() / confirmAccountDeletion()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「OK」をタップし関数の呼び出しは成功し記録の更新（markServerDone）が UnknownFailure で失敗し端末内の削除は成功した場合
- **操作手順**: 最終確認ダイアログで「OK」をタップし関数の呼び出しは成功し記録の更新（markServerDone）が UnknownFailure で失敗し端末内の削除は成功した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログイン画面（/login）に移動し「退会が完了しました」ダイアログが表示される

### テストケース45: 最終確認ダイアログで「OK」をタップし関数の呼び出しが AuthFailure で失敗した場合、「退会できませんでした」ダイアログが表示され、設定画面から移動せず通信エラーダイアログは表示されない [ACD-E01]
- **カテゴリ**: 異常系
- **対象メソッド**: _withdraw() / _onAccountDeletionChanged()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 最終確認ダイアログで「OK」をタップし関数の呼び出しが AuthFailure で失敗した場合
- **操作手順**: 最終確認ダイアログで「OK」をタップし関数の呼び出しが AuthFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 「退会できませんでした」ダイアログが表示され、設定画面から移動せず通信エラーダイアログは表示されない

### テストケース46: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しと端末内の削除がどちらも成功した場合、再開ダイアログが閉じログイン画面（/login）に「退会が完了しました」ダイアログが表示される [ACD-T01]
- **カテゴリ**: 正常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しと端末内の削除がどちらも成功した場合
- **操作手順**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しと端末内の削除がどちらも成功した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログが閉じログイン画面（/login）に「退会が完了しました」ダイアログが表示される

### テストケース47: 記録が serverDone で「再試行」をタップし端末内の削除が成功した場合、再開ダイアログが閉じログイン画面に「退会が完了しました」ダイアログが表示され、関数は呼ばれない [ACD-T02]
- **カテゴリ**: 正常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 記録が serverDone で「再試行」をタップし端末内の削除が成功した場合
- **操作手順**: 記録が serverDone で「再試行」をタップし端末内の削除が成功した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログが閉じログイン画面に「退会が完了しました」ダイアログが表示され、関数は呼ばれない

### テストケース48: ログインしていない状態で記録が requested のまま「再試行」をタップし端末内の削除が成功した場合、ログイン画面に「退会が完了しました」ダイアログが表示され、関数は呼ばれない [ACD-T03]
- **カテゴリ**: 正常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で記録が requested のまま「再試行」をタップし端末内の削除が成功した場合
- **操作手順**: ログインしていない状態で記録が requested のまま「再試行」をタップし端末内の削除が成功した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログイン画面に「退会が完了しました」ダイアログが表示され、関数は呼ばれない

### テストケース49: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが AuthFailure で失敗し端末内の削除が成功した場合、ログイン画面に「退会が完了しました」ダイアログが表示される [ACD-T04]
- **カテゴリ**: 異常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが AuthFailure で失敗し端末内の削除が成功した場合
- **操作手順**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが AuthFailure で失敗し端末内の削除が成功した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログイン画面に「退会が完了しました」ダイアログが表示される

### テストケース50: ログイン中で記録が requested で「再試行」をタップし関数の応答を待っている場合、再開ダイアログの「再試行」が無効になり「退会処理中です」とインジケーターが表示される [ACD-T05]
- **カテゴリ**: 境界値
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で記録が requested で「再試行」をタップし関数の応答を待っている場合
- **操作手順**: ログイン中で記録が requested で「再試行」をタップし関数の応答を待っている場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログの「再試行」が無効になり「退会処理中です」とインジケーターが表示される

### テストケース51: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが NetworkFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T06]
- **カテゴリ**: 異常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが NetworkFailure で失敗した場合
- **操作手順**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが NetworkFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る

### テストケース52: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T07]
- **カテゴリ**: 異常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが UnknownFailure で失敗した場合
- **操作手順**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る

### テストケース53: 記録が serverDone で「再試行」をタップし端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T08]
- **カテゴリ**: 異常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 記録が serverDone で「再試行」をタップし端末内の削除が UnknownFailure で失敗した場合
- **操作手順**: 記録が serverDone で「再試行」をタップし端末内の削除が UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る

### テストケース54: 記録が serverDone で「再試行」をタップし端末内の削除の完了を待っている場合、再開ダイアログの「再試行」が無効になり「退会処理中です」とインジケーターが表示される [ACD-T09]
- **カテゴリ**: 境界値
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 記録が serverDone で「再試行」をタップし端末内の削除の完了を待っている場合
- **操作手順**: 記録が serverDone で「再試行」をタップし端末内の削除の完了を待っている場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログの「再試行」が無効になり「退会処理中です」とインジケーターが表示される

### テストケース55: ログイン中の uid が B で記録が uid A の requested で「再試行」をタップし端末内の削除が成功した場合、ログイン画面（/login）に「退会が完了しました」ダイアログが表示され、関数は呼ばれない [ACD-T10]
- **カテゴリ**: 正常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が B で記録が uid A の requested で「再試行」をタップし端末内の削除が成功した場合
- **操作手順**: ログイン中の uid が B で記録が uid A の requested で「再試行」をタップし端末内の削除が成功した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログイン画面（/login）に「退会が完了しました」ダイアログが表示され、関数は呼ばれない

### テストケース56: 記録が serverDone で「再試行」をタップし端末内の削除が成功しログアウトが UnknownFailure で失敗した場合、ログイン画面（/login）に「退会が完了しました」ダイアログが表示される [ACD-T11]
- **カテゴリ**: 異常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 記録が serverDone で「再試行」をタップし端末内の削除が成功しログアウトが UnknownFailure で失敗した場合
- **操作手順**: 記録が serverDone で「再試行」をタップし端末内の削除が成功しログアウトが UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: ログイン画面（/login）に「退会が完了しました」ダイアログが表示される

### テストケース57: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T12]
- **カテゴリ**: 異常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合
- **操作手順**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る

### テストケース58: ログインしていない状態で記録が requested のまま「再試行」をタップし端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T13]
- **カテゴリ**: 異常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で記録が requested のまま「再試行」をタップし端末内の削除が UnknownFailure で失敗した場合
- **操作手順**: ログインしていない状態で記録が requested のまま「再試行」をタップし端末内の削除が UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る

### テストケース59: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが AuthFailure で失敗し端末内の削除が UnknownFailure で失敗した場合、再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る [ACD-T14]
- **カテゴリ**: 異常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが AuthFailure で失敗し端末内の削除が UnknownFailure で失敗した場合
- **操作手順**: ログイン中で記録が requested で「再試行」をタップし関数の呼び出しが AuthFailure で失敗し端末内の削除が UnknownFailure で失敗した場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログに「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され「再試行」が有効に戻る

### テストケース60: 起動時の記録の読み取りが失敗して再開ダイアログが表示されている状態で「再試行」をタップし記録の読み直しで記録が無かった場合、再開ダイアログが閉じ関数は呼ばれない [ACD-T15]
- **カテゴリ**: 異常系
- **対象メソッド**: AccountDeletionRetryDialog / retry()
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: 起動時の記録の読み取りが失敗して再開ダイアログが表示されている状態で「再試行」をタップし記録の読み直しで記録が無かった場合
- **操作手順**: 起動時の記録の読み取りが失敗して再開ダイアログが表示されている状態で「再試行」をタップし記録の読み直しで記録が無かった場合（タップ・戻る操作・スプラッシュの2秒経過を pump で進める）
- **期待結果**: 再開ダイアログが閉じ関数は呼ばれない

### テストケース61: ログイン中（uid A）で端末内に A のデータがあり A が退会済みの状態でアプリを起動した場合、ホーム画面の上にお知らせダイアログ（「OK」だけ）が表示され、データの削除ダイアログは表示されない [ACD-W01]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上に、タイトル「アカウントが削除されました」、本文「このアカウントは他の端末で退会されたため、ログアウトします。引き続きご利用になる場合は、新しいアカウントで登録してログインしてください。」、「OK」ボタンのダイアログが表示される。ほかのボタンは表示されない。データの削除ダイアログは表示されない

### テストケース62: ログインしていない状態で端末内に A のデータがあり A が退会済みの状態でアプリを起動した場合、ログイン画面が表示されダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W02]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される。データの削除ダイアログもお知らせダイアログも表示されない。`deleteLocalDataOfUsers([A])` が1回呼ばれる

### テストケース63: ログイン中の uid が B で端末内に A と B のデータがあり A だけが退会済みの状態でアプリを起動した場合、ホーム画面が表示されダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W03]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `B`、端末内に uid `A` と uid `B` のデータがあり、uid `A` にだけ退会済みの記録がある状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ホーム画面（`/home`）が表示される。データの削除ダイアログもお知らせダイアログも表示されない。`deleteLocalDataOfUsers([A])` が1回呼ばれる

### テストケース64: ログイン中で端末内に A のデータがあり A に退会済みの記録が無い状態でアプリを起動した場合、データの削除ダイアログは表示されずホーム画面が表示される [ACD-W04]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録が無い状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログは表示されない。ホーム画面（`/home`）が表示される

### テストケース65: ログイン中で端末内に A のデータがあり A が退会済みの状態でオフラインでアプリを起動した場合、データの削除ダイアログは表示されずホーム画面が表示される [ACD-W05]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で、オフラインでアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログは表示されない。ホーム画面（`/home`）が表示される

### テストケース66: ログイン中で端末内に A のデータがあり退会済みの記録の確認が UnknownFailure で失敗する状態でアプリを起動した場合、データの削除ダイアログは表示されずホーム画面が表示される [ACD-W06]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、退会済みの記録の確認が `UnknownFailure` で失敗する状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログは表示されない。ホーム画面（`/home`）が表示される

### テストケース67: ログインしていない状態で端末内に A のデータがあり A が退会済みの状態でオフラインでアプリを起動した場合、ダイアログは表示されずログイン画面が表示され deleteLocalDataOfUsers は0回である [ACD-W38]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で、オフラインでアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログは表示されない。ログイン画面（`/login`）が表示される。`deleteLocalDataOfUsers` は0回

### テストケース68: ログイン中で端末内にデータが1件も無く A が退会済みの状態でアプリを起動した場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W24]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内にデータが1件も無く、uid `A` に退会済みの記録がある状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上にお知らせダイアログが表示される

### テストケース69: ログイン中で端末内に A のデータがあり退会処理の記録が無い状態で起動し退会済みの記録の確認の応答を待っている場合、ホーム画面が表示される [ACD-W25]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、退会処理の記録が無い状態でアプリを起動し、退会済みの記録の確認の応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ホーム画面（`/home`）が表示される

### テストケース70: ログインしていない状態で端末内に A のデータがある状態で起動し退会済みの記録の確認の応答を待っている場合、ログイン画面が表示される [ACD-W39]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがある状態でアプリを起動し、退会済みの記録の確認の応答を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される

### テストケース71: お知らせダイアログの「OK」をタップしてログアウトが成功した場合、お知らせが閉じてログイン画面に移動し、その上にデータの削除ダイアログ（「OK」だけ）が表示される [ACD-W26]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、ホーム画面（`/home`）の上にお知らせダイアログが表示されている状態で、「OK」をタップし、ログアウトが成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: お知らせダイアログが閉じ、ログイン画面（`/login`）に移動し、その上にタイトル「データの削除」、本文「このアカウントは他の端末で退会済みです。この端末に残っている WordStock のデータをすべて削除します。」、「OK」ボタンのダイアログが表示される。ほかのボタンは表示されない

### テストケース72: お知らせダイアログの「OK」をタップし1回目のログアウトが UnknownFailure で失敗し2回目が成功した場合、お知らせが閉じてログイン画面に移動しデータの削除ダイアログが表示される [ACD-W27]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、ホーム画面（`/home`）の上にお知らせダイアログが表示されている状態で、「OK」をタップし、1回目のログアウトが `UnknownFailure` で失敗し、2回目のログアウトが成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: お知らせダイアログが閉じ、ログイン画面（`/login`）に移動し、その上にデータの削除ダイアログが表示される

### テストケース73: お知らせダイアログが表示されている状態でダイアログの外側をタップした場合、お知らせは表示されたままで signOut は0回である [ACD-W28]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、ホーム画面（`/home`）の上にお知らせダイアログが表示されている状態で、ダイアログの外側をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: お知らせダイアログは表示されたまま。`AuthRepository.signOut` は0回

### テストケース74: お知らせダイアログが表示されている状態で戻る操作をした場合、お知らせは表示されたままで signOut は0回である [ACD-W29]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、ホーム画面（`/home`）の上にお知らせダイアログが表示されている状態で、戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: お知らせダイアログは表示されたまま。`AuthRepository.signOut` は0回

### テストケース75: お知らせダイアログの「OK」をタップしログアウトが2回とも UnknownFailure で失敗した場合、お知らせが閉じてログイン画面に移動しデータの削除ダイアログが表示される [ACD-W42]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、ホーム画面（`/home`）の上にお知らせダイアログが表示されている状態で、「OK」をタップし、ログアウトが2回とも `UnknownFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: お知らせダイアログが閉じ、ログイン画面（`/login`）に移動し、その上にデータの削除ダイアログが表示される

### テストケース76: データの削除ダイアログの「OK」をタップし端末内の削除が成功した場合、ダイアログが閉じて画面のパスは /login のままである [ACD-W07]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で、「OK」をタップし、端末内の削除が成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログが閉じる。表示中の画面のパスは `/login` のまま

### テストケース77: データの削除ダイアログの「OK」をタップし端末内の削除の完了を待っている場合、ダイアログは表示されたまま「OK」が無効になりインジケーターが表示される [ACD-W08]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で、「OK」をタップし、端末内の削除の完了を待っている
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログが表示されたまま、「OK」ボタンが無効になり、ダイアログの中にローディングのインジケーターが表示される

### テストケース78: データの削除ダイアログの「OK」をタップし端末内の削除が UnknownFailure で失敗した場合、データの削除ダイアログが閉じて失敗ダイアログ（「OK」だけ）が表示される [ACD-W09]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で、「OK」をタップし、端末内の削除が `UnknownFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログが閉じ、タイトル「削除に失敗しました」、本文「端末内のデータを削除できませんでした。もう一度お試しください。」、「OK」ボタンのダイアログが表示される。ほかのボタンは表示されない

### テストケース79: 端末内の削除が UnknownFailure で失敗した後に失敗ダイアログの「OK」でやり直して削除が成功した場合、データの削除ダイアログが閉じ失敗ダイアログは表示されない [ACD-W10]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で、「OK」をタップし、端末内の削除が `UnknownFailure` で失敗して失敗ダイアログが表示されている状態で「OK」をタップしてデータの削除ダイアログがもう一度表示された後、その「OK」をタップし、端末内の削除が成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログが閉じる。失敗ダイアログは表示されない

### テストケース80: データの削除ダイアログが表示されている状態（削除の処理中ではない）でダイアログの外側をタップした場合、ダイアログは表示されたままで deleteLocalDataOfUsers は0回である [ACD-W11]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で（削除の処理中ではない）、ダイアログの外側をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログは表示されたまま。`deleteLocalDataOfUsers` は0回

### テストケース81: データの削除ダイアログが表示されている状態（削除の処理中ではない）で戻る操作をした場合、ダイアログは表示されたままで deleteLocalDataOfUsers は0回である [ACD-W12]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で（削除の処理中ではない）、戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログは表示されたまま。`deleteLocalDataOfUsers` は0回

### テストケース82: データの削除ダイアログの「OK」をタップし端末内の削除の完了を待っている間にダイアログの外側をタップした場合、ダイアログは表示されたままである [ACD-W13]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で、「OK」をタップし、端末内の削除の完了を待っている間に、ダイアログの外側をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログは表示されたまま

### テストケース83: データの削除ダイアログの「OK」をタップし端末内の削除の完了を待っている間に戻る操作をした場合、ダイアログは表示されたままである [ACD-W14]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で、「OK」をタップし、端末内の削除の完了を待っている間に、戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログは表示されたまま

### テストケース84: データの削除ダイアログが表示されている状態で A の退会済みの記録があるままアプリがフォアグラウンドに戻った場合、データの削除ダイアログは1つだけ表示されたままである [ACD-W19]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で（uid `A` の退会済みの記録はあるまま）、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログが1つだけ表示されたまま

### テストケース85: 端末内の削除が UnknownFailure で失敗して失敗ダイアログが表示されている状態で「OK」をタップした場合、失敗ダイアログが閉じてデータの削除ダイアログが表示される [ACD-W33]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で、「OK」をタップし、端末内の削除が `UnknownFailure` で失敗して失敗ダイアログが表示されている状態で「OK」をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 失敗ダイアログが閉じ、データの削除ダイアログが表示される

### テストケース86: 失敗ダイアログが表示されている状態でダイアログの外側をタップした場合、失敗ダイアログは表示されたままでデータの削除ダイアログは表示されない [ACD-W34]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で、「OK」をタップし、端末内の削除が `UnknownFailure` で失敗して失敗ダイアログが表示されている状態で失敗ダイアログの外側をタップした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 失敗ダイアログは表示されたまま。データの削除ダイアログは表示されない

### テストケース87: 失敗ダイアログが表示されている状態で戻る操作をした場合、失敗ダイアログは表示されたままでデータの削除ダイアログは表示されない [ACD-W35]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で、「OK」をタップし、端末内の削除が `UnknownFailure` で失敗して失敗ダイアログが表示されている状態で戻る操作をした
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 失敗ダイアログは表示されたまま。データの削除ダイアログは表示されない

### テストケース88: 失敗ダイアログの「OK」でやり直した端末内の削除がもう一度 UnknownFailure で失敗した場合、データの削除ダイアログが閉じて失敗ダイアログが表示される [ACD-W41]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）の上にデータの削除ダイアログが表示されている状態で、「OK」をタップし、端末内の削除が `UnknownFailure` で失敗して失敗ダイアログが表示されている状態で「OK」をタップしてデータの削除ダイアログがもう一度表示された後、その「OK」をタップし、端末内の削除がもう一度 `UnknownFailure` で失敗した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログが閉じ、失敗ダイアログが表示される

### テストケース89: ログインしていない状態で A の退会処理の記録が requested で A が退会済みの状態でアプリを起動した場合、再開ダイアログが表示されデータの削除ダイアログは表示されない [ACD-W15]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがあり、uid `A` の退会処理の記録が `requested` で、uid `A` に退会済みの記録がある状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 「退会処理が完了していません」ダイアログが表示される。データの削除ダイアログは表示されない

### テストケース90: ログインしていない状態で A の退会処理の記録が requested で C が退会済みの状態でアプリを起動した場合、再開ダイアログが表示されデータの削除ダイアログは表示されない [ACD-W16]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` と uid `C` のデータがあり、uid `A` の退会処理の記録が `requested` で、uid `C` に退会済みの記録がある状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 「退会処理が完了していません」ダイアログが表示される。データの削除ダイアログは表示されない

### テストケース91: ログイン中で A の退会処理の記録が requested で A が退会済みの状態でアプリを起動した場合、再開ダイアログが表示されデータの削除ダイアログは表示されない [ACD-W21]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` の退会処理の記録が `requested` で、uid `A` に退会済みの記録がある状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 「退会処理が完了していません」ダイアログが表示される。データの削除ダイアログは表示されない

### テストケース92: ログイン中で起動時には A に退会済みの記録が無く、ホーム画面を表示している状態で記録ができアプリがフォアグラウンドに戻った場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W17]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、起動時には uid `A` に退会済みの記録が無く、ホーム画面（`/home`）を表示している状態で記録ができ、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上にお知らせダイアログが表示される

### テストケース93: ログインしていない状態で端末内に A と C のデータがあり両方が退会済みの状態でアプリを起動した場合、ダイアログは表示されず deleteLocalDataOfUsers が1回呼ばれ引数に A と C が含まれる [ACD-W18]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` と uid `C` のデータがあり、両方に退会済みの記録がある状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ダイアログは表示されない。`deleteLocalDataOfUsers` が1回呼ばれ、引数に `A` と `C` が含まれる

### テストケース94: ログイン中で A が退会済みの状態でオフラインで起動してホーム画面を表示し、オンラインになってからアプリがフォアグラウンドに戻った場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W20]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で、オフラインでアプリを起動してホーム画面（`/home`）を表示し、オンラインになってからアプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上にお知らせダイアログが表示される

### テストケース95: ログイン中の uid が B で端末内に A と B のデータがあり設定画面を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、設定画面のままダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W23]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `B`、端末内に uid `A` と uid `B` のデータがあり、設定画面（`/settings`）を表示している状態で uid `A` に退会済みの記録ができ、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 表示中の画面のパスは `/settings` のまま。ダイアログは表示されない。`deleteLocalDataOfUsers([A])` が1回呼ばれる

### テストケース96: ログインしていない状態で A の削除が1回目 UnknownFailure・2回目成功の状態で起動しその後アプリがフォアグラウンドに戻った場合、ログイン画面のままダイアログは出ず deleteLocalDataOfUsers([A]) が合計2回呼ばれる [ACD-W53]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録があり、1回目の端末内の削除が `UnknownFailure`、2回目が成功する状態でアプリを起動し、その後アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示されたまま、ダイアログは表示されない。`deleteLocalDataOfUsers([A])` が合計2回呼ばれる

### テストケース97: 強制ログアウトの後にデータの削除ダイアログの「OK」で削除が成功しアプリがフォアグラウンドに戻った場合、画面のパスは /login のままでホーム画面に移動せずデータの削除ダイアログは表示されない [ACD-W43]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップし、ログアウトが2回とも `UnknownFailure` で失敗した後、データの削除ダイアログの「OK」をタップして端末内の削除が成功し、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 表示中の画面のパスは `/login` のまま。ホーム画面に移動しない。データの削除ダイアログは表示されない

### テストケース98: 退会の確認ダイアログ（タイトル「退会」）を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、確認ダイアログが閉じてお知らせダイアログが表示される [ACD-W30]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、設定画面で退会の確認ダイアログ（タイトル「退会」）を表示している状態で、uid `A` に退会済みの記録ができ、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 退会の確認ダイアログが閉じ、お知らせダイアログが表示される

### テストケース99: 最終確認ダイアログ（タイトル「最終確認」）を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、最終確認ダイアログが閉じてお知らせダイアログが表示される [ACD-W31]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、設定画面で最終確認ダイアログ（タイトル「最終確認」）を表示している状態で、uid `A` に退会済みの記録ができ、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 最終確認ダイアログが閉じ、お知らせダイアログが表示される

### テストケース100: 「退会できませんでした」ダイアログを表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、そのダイアログが閉じてお知らせダイアログが表示される [ACD-W32]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、設定画面で「退会できませんでした」ダイアログを表示している状態で、uid `A` に退会済みの記録ができ、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 「退会できませんでした」ダイアログが閉じ、お知らせダイアログが表示される

### テストケース101: 「ログアウト」をタップしてログアウトのダイアログ（本文「ログアウトしますか？」）を表示している状態で A に退会済みの記録ができアプリがフォアグラウンドに戻った場合、そのダイアログが閉じてお知らせダイアログが表示される [ACD-W36]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、設定画面で「ログアウト」をタップして、タイトル「ログアウト」、本文「ログアウトしますか？」のダイアログを表示している状態で、uid `A` に退会済みの記録ができ、アプリがフォアグラウンドに戻った
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: タイトル「ログアウト」のダイアログが閉じ、お知らせダイアログが表示される

### テストケース102: お知らせの「OK」でログアウトが2回とも失敗し、データの削除ダイアログの「OK」を押さずに終了して Firebase 上は A のまま起動し直した場合、ログイン画面が表示されダイアログは出ず deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-W37]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップし、ログアウトが2回とも `UnknownFailure` で失敗した後、データの削除ダイアログの「OK」をタップせずにアプリを終了し、Firebase 上ではログイン中の uid が `A` のまま、もう一度アプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される。データの削除ダイアログもお知らせダイアログも表示されない。`deleteLocalDataOfUsers([A])` が1回呼ばれる

### テストケース103: お知らせの「OK」でログアウトが2回とも失敗しデータの削除が成功した後、アプリを終了して Firebase 上は A のまま起動し直した場合、ログイン画面が表示されダイアログは出ない [ACD-W49]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップし、ログアウトが2回とも `UnknownFailure` で失敗した後、データの削除ダイアログの「OK」をタップして端末内の削除が成功し、アプリを終了して、Firebase 上ではログイン中の uid が `A` のまま、もう一度アプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される。データの削除ダイアログもお知らせダイアログも表示されない

### テストケース104: Firebase 上のログイン中の uid が A で A の強制ログアウトの記録があり端末内に A のデータがある状態でオフラインで起動した場合、ログイン画面が表示されホーム画面に移動せず signOut は1回である [ACD-W47]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: Firebase 上のログイン中の uid が `A`、uid `A` の強制ログアウトの記録があり、端末内に uid `A` のデータがある状態で、オフラインでアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される。ホーム画面に移動しない。`AuthRepository.signOut` は1回

### テストケース105: ログイン中で端末内に A と C のデータがあり両方が退会済みで、お知らせの「OK」でログアウトし、データの削除ダイアログの「OK」で削除が成功した場合、ダイアログが閉じて画面のパスは /login のままで、起動時に deleteLocalDataOfUsers([C]) が1回呼ばれている [ACD-W40]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` と uid `C` のデータがあり、両方に退会済みの記録がある状態で起動し、お知らせダイアログの「OK」をタップしてログアウトが成功し、ログイン画面（`/login`）に表示されたデータの削除ダイアログの「OK」をタップし、端末内の削除が成功した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: データの削除ダイアログが閉じる。表示中の画面のパスは `/login` のまま。起動時の確認で `deleteLocalDataOfUsers([C])` が1回呼ばれている

### テストケース106: ログインしていない状態で A が退会済みで端末内の削除が UnknownFailure で失敗する状態でアプリを起動した場合、ログイン画面が表示されダイアログは表示されない [ACD-W50]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録があり、端末内の削除が `UnknownFailure` で失敗する状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ログイン画面（`/login`）が表示される。ダイアログは表示されない

### テストケース107: ログイン中で端末内に A と C のデータがあり両方が退会済みで C の端末内の削除が UnknownFailure で失敗する状態でアプリを起動した場合、ホーム画面の上にお知らせダイアログが表示され失敗を知らせる表示は無い [ACD-W51]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` と uid `C` のデータがあり、両方に退会済みの記録があり、uid `C` の端末内の削除が `UnknownFailure` で失敗する状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上にお知らせダイアログが表示される。失敗を知らせる表示は無い

### テストケース108: ログイン中の uid が B で端末内に A と B のデータがあり A だけが退会済みで端末内の削除が UnknownFailure で失敗する状態でアプリを起動した場合、ホーム画面が表示されダイアログは表示されない [ACD-W52]
- **カテゴリ**: 異常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `B`、端末内に uid `A` と uid `B` のデータがあり、uid `A` にだけ退会済みの記録があり、端末内の削除が `UnknownFailure` で失敗する状態でアプリを起動した
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ホーム画面（`/home`）が表示される。ダイアログは表示されない

### テストケース109: ログイン中でホーム画面を表示している状態でアプリをフォアグラウンドにしたまま A に退会済みの記録ができた場合、ホーム画面の上にお知らせダイアログが表示される [ACD-W44]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、ホーム画面（`/home`）を表示している状態で、アプリをフォアグラウンドにしたまま uid `A` に退会済みの記録ができた
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: ホーム画面（`/home`）の上にお知らせダイアログが表示される

### テストケース110: ログイン中で設定画面を表示している状態でアプリをフォアグラウンドにしたまま A に退会済みの記録ができた場合、設定画面の上にお知らせダイアログが表示される [ACD-W45]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、設定画面（`/settings`）を表示している状態で、アプリをフォアグラウンドにしたまま uid `A` に退会済みの記録ができた
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 設定画面（`/settings`）の上にお知らせダイアログが表示される

### テストケース111: 最終確認ダイアログの「OK」をタップして「退会処理中です」が表示されている状態で A に退会済みの記録ができた場合、お知らせダイアログは表示されず「退会処理中です」が表示されたままである [ACD-W46]
- **カテゴリ**: 境界値
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、設定画面で最終確認ダイアログの「OK」をタップして「退会処理中です」が表示されている状態で、uid `A` に退会済みの記録ができた
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: お知らせダイアログは表示されない。「退会処理中です」が表示されたまま

### テストケース112: 最終確認ダイアログ（タイトル「最終確認」）を表示している状態でアプリをフォアグラウンドにしたまま A に退会済みの記録ができた場合、最終確認ダイアログが閉じてお知らせダイアログが表示される [ACD-W48]
- **カテゴリ**: 正常系
- **対象メソッド**: WithdrawnElsewhereGate / WithdrawnElsewhereViewModel
- **事前条件**: 本物のルーター（routerProvider）+ AccountDeletionGate + WithdrawnElsewhereGate（app.dart と同じ配線。起動時の initialize()→check()、復帰時の check()）で起動し、手書き Fake（退会用リポジトリ・認証）と Mock Repository を注入
- **入力値・テスト条件**: ログイン中の uid が `A`、設定画面で最終確認ダイアログ（タイトル「最終確認」）を表示している状態で、アプリをフォアグラウンドにしたまま uid `A` に退会済みの記録ができた
- **操作手順**: 上記の条件を Fake の状態（ログイン中の uid・端末内の uid・退会済みの記録・強制ログアウトの記録・削除/ログアウトの結果・オフライン）で作り、タップ・戻る操作・アプリの復帰（resumed）・監視の通知を pump で進める
- **期待結果**: 最終確認ダイアログが閉じ、お知らせダイアログが表示される

## 対象外

- 起動時の確認を呼び出す `lib/app.dart` の `App.initState`（`checkPending()` の呼び出し）：`App` は Firebase の初期化と自動同期の開始を含み Widget テストで組めないため、テストでは `checkPending()` をテスト側から呼んで同じ状態を作る（ACD-D02〜D16, T15）。`App.initState` の呼び出し自体は対象外
