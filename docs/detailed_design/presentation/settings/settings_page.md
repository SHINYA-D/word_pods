---
feature: 設定画面（退会）
prefix: ACD
status: approved
targets:
  - lib/presentation/settings/settings_page.dart
  - lib/presentation/settings/account_deletion_view_model.dart
  - lib/presentation/auth/login/login_page.dart
  - lib/domain/repositories/account_deletion_repository.dart
  - lib/domain/repositories/sync_repository.dart
  - lib/application/use_cases/auth/delete_account_use_case.dart
  - lib/infrastructure/repositories/account_deletion_repository_impl.dart
  - lib/infrastructure/sync/sync_service.dart
kinds:
  T: 退会処理の再試行
updated: 2026-10-04
---

# 設定画面（退会） 振る舞い仕様書

## 1. 機能概要

設定画面（ボトムナビ「設定」タブ）の「退会」から、確認ダイアログ2回を経て退会する。
Firestore と Firebase Authentication の削除は Cloud Functions の関数 `deleteAccount` を1回呼んで行い、成功を受け取ってから端末内（SQLite）のそのユーザーのデータを削除する。
退会処理の進み具合を端末内に記録し、途中で止まった場合はアプリの起動時に再開ダイアログを表示して、再試行で最後まで終わらせる。

## 2. データ定義

### 2.1 退会処理の記録（AccountDeletionRequest）

端末内の専用テーブル `account_deletion` の1行。同期用のキュー（`sync_queue`）とは別のテーブルにする。

| 項目 | 型 | 説明 |
|------|----|------|
| userId | String | 退会処理中のユーザーの uid（主キー） |
| status | AccountDeletionStatus | `requested`（削除中: 関数の成功をまだ受け取っていない）／ `serverDone`（サーバー削除済み: 端末内の削除が終わっていない） |
| updatedAt | DateTime | 状態を記録した日時 |

記録が無いことは「退会処理をしていない、または退会処理がすべて終わった」を表す。

### 2.2 入力ルール

該当なし（入力欄が無い）。

---

## 3. 画面仕様

条件は「前提データ＋操作」、期待される動作は観測点で書く。
「関数を呼ぶ」は `AccountDeletionRepository.requestServerDeletion`、「端末内の削除」は `AccountDeletionRepository.deleteLocalData` を指す。
ログイン中のユーザーは、特に書かない限り記録と同じ uid `A` とする。

### 3.1 表示

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| ACD-D01 | ログイン中で、退会処理の記録が無い状態で設定画面を開いた | 「アカウント」の下に「ログアウト」、その下に「退会」がこの順で表示される。「退会」の文字色はテーマのエラー色で、`Icons.person_remove` が表示される | 概要 §画面構成 | 確定 |
| ACD-D02 | 退会処理の記録が無い状態でアプリを起動した | 「退会処理が完了していません」ダイアログは表示されない | 概要 §途中で止まった場合 | 確定 |
| ACD-D03 | ログイン中で、記録が `requested` の状態でアプリを起動した | 「退会処理が完了していません」ダイアログが表示される。本文「「再試行」を押して、退会処理を完了してください。」と「再試行」ボタンが表示され、ほかのボタンは表示されない | 概要 §退会処理の再開ダイアログ, 概要 §途中で止まった場合 | 確定 |
| ACD-D04 | ログインしていない状態で、記録が `serverDone` の状態でアプリを起動した | ログイン画面の上に「退会処理が完了していません」ダイアログが表示される。「再試行」ボタンだけが表示される | 概要 §途中で止まった場合 | 確定 |
| ACD-D05 | ログインしていない状態で、記録が `requested` の状態でアプリを起動した | ログイン画面の上に「退会処理が完了していません」ダイアログが表示される。「再試行」ボタンだけが表示される | 概要 §途中で止まった場合 | 確定 |
| ACD-D06 | 「退会処理が完了していません」ダイアログが表示されている（再試行の処理中ではない）状態で、ダイアログの外側をタップした | ダイアログは表示されたまま。記録の状態は変わらず、関数を呼ぶ回数は0回 | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-D07 | 「退会処理が完了していません」ダイアログが表示されている（再試行の処理中ではない）状態で、戻る操作をした | ダイアログは表示されたまま。記録の状態は変わらず、関数を呼ぶ回数は0回 | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-D08 | ログイン中で、記録が `serverDone` の状態でアプリを起動した | 「退会処理が完了していません」ダイアログが表示される。「再試行」ボタンだけが表示される | 概要 §途中で止まった場合 | 確定 |
| ACD-D09 | ログイン中で記録が `requested` の状態で起動し、再開ダイアログが表示されている状態で、ダイアログの背後のボトムナビ「設定」の位置をタップした | ダイアログは表示されたまま。表示中の画面のパスは変わらない | 概要 §途中で止まった場合（他の機能は使えない） | 確定 |
| ACD-D10 | 記録が `requested` の状態で「再試行」をタップし、処理の応答を待っている間に戻る操作をした | 再開ダイアログは表示されたまま。記録の状態は変わらない | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-D11 | 記録が `requested` の状態で「再試行」をタップし、処理の応答を待っている間にダイアログの外側をタップした | 再開ダイアログは表示されたまま。記録の状態は変わらない | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-D12 | ログイン中の uid が `B`、記録が uid `A` の `requested` の状態でアプリを起動した | 「退会処理が完了していません」ダイアログが表示される。「再試行」ボタンだけが表示される | 概要 §途中で止まった場合（ログイン中かどうかに関わらない） | 確定 |
| ACD-D13 | ログイン中で記録が `requested` の状態で「再試行」をタップし、処理の応答を待っている間に、ダイアログの背後のボトムナビ「ホーム」の位置をタップした | 再開ダイアログは表示されたまま。表示中の画面のパスは変わらない | 概要 §途中で止まった場合（他の機能は使えない） | 確定 |
| ACD-D14 | ログインしていない状態で記録が `serverDone` の状態で起動し、再開ダイアログが表示されている状態で、ダイアログの背後のログイン画面の「ログイン」ボタンの位置をタップした | ダイアログは表示されたまま。表示中の画面のパスは `/login` のまま | 概要 §途中で止まった場合（他の機能は使えない） | 確定 |
| ACD-D15 | 起動時の記録の読み取りが `UnknownFailure` で失敗した状態でアプリを起動した | 「退会処理が完了していません」ダイアログが表示される。「再試行」ボタンだけが表示される | ユーザー決定 2026-10-03（ACD-Q02） | 確定 |
| ACD-D16 | ログイン中で、起動時の記録の確認が終わっていない状態でアプリを起動した | スプラッシュ画面（`/`）が表示されたまま。ホーム画面に移動しない | ユーザー決定 2026-10-03（ACD-Q06） | 確定 |

### 3.2 退会

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| ACD-X01 | 設定画面で「退会」をタップした | ダイアログが表示される。タイトル「退会」、本文「このアプリから退会いたしますか？」、「キャンセル」「OK」ボタンがこの順で横に並ぶ | 概要 §確認ダイアログ, ユーザー決定 2026-10-03 | 確定 |
| ACD-X02 | 確認ダイアログで「キャンセル」をタップした | ダイアログが閉じ、設定画面が表示される。関数を呼ぶ回数は0回。退会処理の記録は無いまま | 概要 §確認ダイアログ, 原則-7 | 確定 |
| ACD-X03 | 確認ダイアログの外側をタップした | ダイアログが閉じ、設定画面が表示される。関数を呼ぶ回数は0回。退会処理の記録は無いまま | 概要 §確認ダイアログ, 原則-7 | 確定 |
| ACD-X04 | 確認ダイアログで「OK」をタップした | 確認ダイアログが閉じ、最終確認ダイアログが表示される。タイトル「最終確認」、本文「退会すると全てのデータが削除されます。それでも退会しますか？」、「キャンセル」「OK」ボタンがこの順で横に並ぶ。「OK」ボタンの色はテーマのエラー色。関数を呼ぶ回数は0回 | 概要 §最終確認ダイアログ, ユーザー決定 2026-10-03 | 確定 |
| ACD-X05 | 最終確認ダイアログで「キャンセル」をタップした | ダイアログが閉じ、設定画面が表示される。関数を呼ぶ回数は0回。退会処理の記録は無いまま | 概要 §最終確認ダイアログ, 原則-7 | 確定 |
| ACD-X06 | 最終確認ダイアログの外側をタップした | ダイアログが閉じ、設定画面が表示される。関数を呼ぶ回数は0回。退会処理の記録は無いまま | 概要 §最終確認ダイアログ, 原則-7 | 確定 |
| ACD-X07 | 最終確認ダイアログで「OK」をタップし、関数の応答を待っている | 最終確認ダイアログが閉じ、「退会処理中です」とローディングのインジケーターが表示される。パスワードの入力欄は表示されない | 概要 §処理中の表示, 概要 §削除の方式, 原則-5 | 確定 |
| ACD-X08 | 退会処理中（ACD-X07 の状態）に戻る操作をした | 「退会処理中です」とインジケーターが表示されたまま。設定画面から移動しない | 概要 §処理中の表示 | 確定 |
| ACD-X09 | 退会処理中（ACD-X07 の状態）に、ローディングの下にある「退会」の位置をタップした | 確認ダイアログは表示されない。関数を呼ぶ回数は1回のまま | 概要 §処理中の表示, 原則-4 | 確定 |
| ACD-X10 | 最終確認ダイアログで「OK」をタップし、関数の呼び出しと端末内の削除がどちらも成功した | ログイン画面（`/login`）に移動し、その上に本文「退会が完了しました」と「OK」ボタンのダイアログが表示される | 概要 §退会の流れ, 概要 §完了ダイアログ | 確定 |
| ACD-X11 | 完了ダイアログで「OK」をタップした | ダイアログが閉じ、ログイン画面が表示されたまま | 概要 §完了ダイアログ | 確定 |
| ACD-X12 | 最終確認ダイアログで「OK」をタップし、関数の呼び出しが `NetworkFailure` で失敗した | 「退会処理中です」が消え、タイトル「退会できませんでした」、本文「通信環境を確認して、もう一度お試しください。」、「OK」ボタンのダイアログが表示される。設定画面から移動しない。通信エラーダイアログは表示されない | 概要 §操作が失敗したとき, 概要 §退会できなかったときのダイアログ | 確定 |
| ACD-X13 | 「退会できませんでした」ダイアログで「OK」をタップした | ダイアログが閉じ、設定画面が表示される | 概要 §退会できなかったときのダイアログ | 確定 |
| ACD-X14 | 最終確認ダイアログで「OK」をタップし、関数の呼び出しが `UnknownFailure` で失敗した | 「退会処理中です」が消え、「退会処理が完了していません」ダイアログと「再試行」ボタンが表示される | 概要 §操作が失敗したとき | 確定 |
| ACD-X15 | 最終確認ダイアログで「OK」をタップし、関数の呼び出しは成功し、端末内の削除が `UnknownFailure` で失敗した | 「退会処理中です」が消え、「退会処理が完了していません」ダイアログと「再試行」ボタンが表示される | 概要 §操作が失敗したとき | 確定 |
| ACD-X16 | 退会処理中（ACD-X07 の状態）に、ローディングの下にあるボトムナビ「ホーム」の位置をタップした | 「退会処理中です」が表示されたまま。表示中の画面のパスは設定画面のまま | 概要 §処理中の表示 | 確定 |
| ACD-X17 | 最終確認ダイアログで「OK」をタップし、関数の呼び出しと端末内の削除が成功し、ログアウトが `UnknownFailure` で失敗した | ログイン画面（`/login`）に移動し、「退会が完了しました」ダイアログが表示される | 概要 §退会の流れ 4 | 確定 |
| ACD-X18 | 退会処理中（ACD-X07 の状態）に、ローディングの下にある「ログアウト」の位置をタップした | ログアウトの確認ダイアログは表示されない。`AuthRepository.signOut` は0回のまま | 概要 §処理中の表示 | 確定 |
| ACD-X19 | 完了ダイアログの外側をタップした | ダイアログが閉じ、ログイン画面が表示されたまま | ユーザー決定 2026-10-03（ACD-Q03） | 確定 |
| ACD-X20 | 「退会できませんでした」ダイアログの外側をタップした | ダイアログが閉じ、設定画面が表示される | ユーザー決定 2026-10-03（ACD-Q03） | 確定 |
| ACD-X21 | 最終確認ダイアログで「OK」をタップし、記録の書き込み（`markRequested`）が `UnknownFailure` で失敗した | 「退会できませんでした」ダイアログが表示される。設定画面から移動しない。関数を呼ぶ回数は0回 | ユーザー決定 2026-10-03（ACD-Q05） | 確定 |
| ACD-X22 | 最終確認ダイアログで「OK」をタップし、関数の呼び出しが `NetworkFailure` で失敗し、記録の削除（`clearRequest`）が `UnknownFailure` で失敗した | 「退会処理が完了していません」ダイアログと「再試行」ボタンが表示される | ユーザー決定 2026-10-03（ACD-Q05） | 確定 |
| ACD-X23 | 最終確認ダイアログで「OK」をタップし、関数の呼び出しは成功し、記録の更新（`markServerDone`）が `UnknownFailure` で失敗し、端末内の削除は成功した | ログイン画面（`/login`）に移動し、「退会が完了しました」ダイアログが表示される | ユーザー決定 2026-10-03（ACD-Q05） | 確定 |

### 3.3 退会処理の再試行

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| ACD-T01 | ログイン中で記録が `requested` の状態で「再試行」をタップし、関数の呼び出しと端末内の削除がどちらも成功した | 再開ダイアログが閉じ、ログイン画面（`/login`）に移動し、「退会が完了しました」ダイアログが表示される | 概要 §途中で止まった場合 | 確定 |
| ACD-T02 | 記録が `serverDone` の状態で「再試行」をタップし、端末内の削除が成功した | 再開ダイアログが閉じ、ログイン画面（`/login`）に「退会が完了しました」ダイアログが表示される。関数を呼ぶ回数は0回 | 概要 §途中で止まった場合 | 確定 |
| ACD-T03 | ログインしていない状態で記録が `requested` のまま「再試行」をタップし、端末内の削除が成功した | ログイン画面に「退会が完了しました」ダイアログが表示される。関数を呼ぶ回数は0回 | 概要 §途中で止まった場合 | 確定 |
| ACD-T04 | ログイン中で記録が `requested` の状態で「再試行」をタップし、関数の呼び出しが `AuthFailure` で失敗し、端末内の削除が成功した | ログイン画面に「退会が完了しました」ダイアログが表示される | 概要 §途中で止まった場合 | 確定 |
| ACD-T05 | ログイン中で記録が `requested` の状態で「再試行」をタップし、関数の応答を待っている | 再開ダイアログの中で「再試行」ボタンが無効になり、「退会処理中です」とローディングのインジケーターが表示される | 概要 §退会処理の再開ダイアログ, 概要 §処理中の表示, 原則-4, 原則-5 | 確定 |
| ACD-T06 | ログイン中で記録が `requested` の状態で「再試行」をタップし、関数の呼び出しが `NetworkFailure` で失敗した | 再開ダイアログが表示されたまま、「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され、「再試行」ボタンが有効に戻る | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-T07 | ログイン中で記録が `requested` の状態で「再試行」をタップし、関数の呼び出しが `UnknownFailure` で失敗した | 再開ダイアログが表示されたまま、「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され、「再試行」ボタンが有効に戻る | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-T08 | 記録が `serverDone` の状態で「再試行」をタップし、端末内の削除が `UnknownFailure` で失敗した | 再開ダイアログが表示されたまま、「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され、「再試行」ボタンが有効に戻る | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-T09 | 記録が `serverDone` の状態で「再試行」をタップし、端末内の削除の完了を待っている | 再開ダイアログの中で「再試行」ボタンが無効になり、「退会処理中です」とローディングのインジケーターが表示される | 概要 §退会処理の再開ダイアログ, 概要 §処理中の表示, 原則-4, 原則-5 | 確定 |
| ACD-T10 | ログイン中の uid が `B`、記録が uid `A` の `requested` の状態で「再試行」をタップし、端末内の削除が成功した | ログイン画面（`/login`）に「退会が完了しました」ダイアログが表示される。関数を呼ぶ回数は0回 | ユーザー決定 2026-10-03（ACD-Q04） | 確定 |
| ACD-T11 | 記録が `serverDone` の状態で「再試行」をタップし、端末内の削除が成功し、ログアウトが `UnknownFailure` で失敗した | ログイン画面（`/login`）に「退会が完了しました」ダイアログが表示される | 概要 §退会の流れ 4 | 確定 |
| ACD-T12 | ログイン中で記録が `requested` の状態で「再試行」をタップし、関数の呼び出しは成功し、端末内の削除が `UnknownFailure` で失敗した | 再開ダイアログが表示されたまま、「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され、「再試行」ボタンが有効に戻る | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-T13 | ログインしていない状態で記録が `requested` のまま「再試行」をタップし、端末内の削除が `UnknownFailure` で失敗した | 再開ダイアログが表示されたまま、「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され、「再試行」ボタンが有効に戻る | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-T14 | ログイン中で記録が `requested` の状態で「再試行」をタップし、関数の呼び出しが `AuthFailure` で失敗し、端末内の削除が `UnknownFailure` で失敗した | 再開ダイアログが表示されたまま、「再試行に失敗しました。通信環境を確認して、もう一度お試しください。」が表示され、「再試行」ボタンが有効に戻る | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-T15 | 起動時の記録の読み取りが失敗して再開ダイアログが表示されている状態で「再試行」をタップし、記録の読み直しで記録が無かった | 再開ダイアログが閉じる。関数を呼ぶ回数は0回 | ユーザー決定 2026-10-03（ACD-Q02） | 確定 |

### 3.4 エラー種別ごとの扱い

3.2・3.3 で書いた Failure 以外を書く。

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| ACD-E01 | 最終確認ダイアログで「OK」をタップし、関数の呼び出しが `AuthFailure` で失敗した | 「退会処理中です」が消え、タイトル「退会できませんでした」、本文「通信環境を確認して、もう一度お試しください。」、「OK」ボタンのダイアログが表示される。設定画面から移動しない。通信エラーダイアログは表示されない | ユーザー決定 2026-10-03（ACD-Q01） | 確定 |
| ACD-E02 | （廃止）最終確認ダイアログで「OK」をタップし、端末内の削除が `NetworkFailure` で失敗した | 端末内の削除は通信を使わず `NetworkFailure` は発生しないため廃止（7章） | — | 廃止 |

### 3.5 状態遷移

状態は 4章の `phase` で書く。

| 現在の状態 | 操作・イベント | 次の状態 | ID |
|-----------|---------------|---------|----|
| `checking` | 起動時の確認（記録なし） | `idle` | ACD-V01 |
| `checking` | 起動時の確認（読み取り失敗） | `pendingRetry` | ACD-V33 |
| `checking` | 起動時の確認（記録 `requested`） | `pendingRetry` | ACD-V02 |
| `checking` | 起動時の確認（記録 `serverDone`） | `pendingRetry` | ACD-V03 |
| 記録なし・`idle` | 最終確認で OK | 記録 `requested`・`processing` | ACD-V04 |
| 記録 `requested`・`processing` | 関数 `NetworkFailure` | 記録なし・`notSent` | ACD-V06 |
| 記録 `requested`・`processing` | 関数 `AuthFailure` | 記録なし・`notSent` | ACD-V11 |
| `notSent` | 「退会できませんでした」で OK | 記録なし・`idle` | ACD-V22 |
| 記録 `requested`・`processing` | 関数 `UnknownFailure` | 記録 `requested`・`pendingRetry` | ACD-V07 |
| 記録 `requested`・`processing` | 関数成功 | 記録 `serverDone`・`processing` | ACD-V05 |
| 記録 `serverDone`・`processing` | 端末内の削除成功 | 記録なし・`completed` | ACD-V05 |
| 記録 `serverDone`・`processing` | 端末内の削除 `UnknownFailure` | 記録 `serverDone`・`pendingRetry` | ACD-V08 |
| 記録 `requested`・`pendingRetry` | 再試行 | 記録 `requested`・`processing` | ACD-V19 |
| 記録 `serverDone`・`pendingRetry` | 再試行 | 記録 `serverDone`・`processing` | ACD-V25 |
| `pendingRetry`（`retryFailed` true） | 再試行 | `processing`（`retryFailed` false） | ACD-V23 |
| 記録 `requested`・`processing`（再試行） | 関数成功・削除成功 | 記録なし・`completed` | ACD-V12 |
| 記録 `requested`・`processing`（再試行・ログインしていない） | 削除成功 | 記録なし・`completed` | ACD-V14 |
| 記録 `requested`・`processing`（再試行） | 関数 `AuthFailure`・削除成功 | 記録なし・`completed` | ACD-V15 |
| 記録 `serverDone`・`processing`（再試行） | 削除成功 | 記録なし・`completed` | ACD-V13 |
| `processing`（再試行） | 再試行が失敗 | `pendingRetry`（`retryFailed` true） | ACD-V16, ACD-V17, ACD-V18, ACD-V29, ACD-V30, ACD-V31 |
| 記録 `requested`・`pendingRetry`（ログイン中の uid が記録と違う） | 再試行（削除成功） | 記録なし・`completed` | ACD-V26 |
| `completed` | 完了ダイアログを表示した | `idle` | ACD-V21 |

---

## 4. 状態管理仕様（AccountDeletionViewModel）

State の項目:

- `phase`: `checking`（起動時の記録の確認が終わっていない）／ `idle`（待機）／ `processing`（退会処理中）／ `completed`（完了。完了ダイアログをまだ表示していない）／ `notSent`（関数に届かず、何も削除していない）／ `pendingRetry`（再開待ち）
- `retryFailed`: 再開待ちで、直前の再試行が失敗したか（bool）

ログイン中のユーザーは、特に書かない限り uid `A` とする。

| ID | 条件 | 期待される状態 | 対応する画面仕様 | 根拠 | 確定度 |
|----|------|----------------|------------------|------|--------|
| ACD-V01 | 記録が無い状態で起動時の確認（`checkPending`）をした | `phase` は `idle` | ACD-D02 | 概要 §途中で止まった場合 | 確定 |
| ACD-V02 | uid `A` の記録が `requested` の状態で `checkPending` をした | `phase` は `pendingRetry`、`retryFailed` は false | ACD-D03, ACD-D05 | 概要 §途中で止まった場合 | 確定 |
| ACD-V03 | uid `A` の記録が `serverDone` の状態で `checkPending` をした | `phase` は `pendingRetry`、`retryFailed` は false | ACD-D04, ACD-D08 | 概要 §途中で止まった場合 | 確定 |
| ACD-V04 | 記録が無い状態で `withdraw` を呼び、関数の応答を待っている | `phase` は `processing`。uid `A` の記録は `requested`。`SyncRepository.waitUntilIdle` が1回呼ばれ、その完了後に `requestServerDeletion` が1回呼ばれる | ACD-X07 | 概要 §退会処理の状態の記録 | 確定 |
| ACD-V05 | 記録が無い状態で `withdraw` を呼び、関数の呼び出しと端末内の削除がどちらも成功した | `phase` は `completed`。`markRequested(A)`・`requestServerDeletion`・`markServerDone(A)`・`deleteLocalData(A)`・`AuthRepository.signOut` がこの順に1回ずつ呼ばれる | ACD-X10 | 概要 §退会処理の状態の記録, 概要 §退会の流れ | 確定 |
| ACD-V06 | 記録が無い状態で `withdraw` を呼び、関数の呼び出しが `NetworkFailure` で失敗した | `phase` は `notSent`。`clearRequest(A)` が1回呼ばれ、uid `A` の記録は無い。`markServerDone`・`deleteLocalData`・`signOut` は0回 | ACD-X12 | 概要 §操作が失敗したとき | 確定 |
| ACD-V07 | 記録が無い状態で `withdraw` を呼び、関数の呼び出しが `UnknownFailure` で失敗した | `phase` は `pendingRetry`、`retryFailed` は false。uid `A` の記録は `requested` のまま。`clearRequest`・`deleteLocalData`・`signOut` は0回 | ACD-X14 | 概要 §操作が失敗したとき | 確定 |
| ACD-V08 | 記録が無い状態で `withdraw` を呼び、関数の呼び出しは成功し、端末内の削除が `UnknownFailure` で失敗した | `phase` は `pendingRetry`、`retryFailed` は false。uid `A` の記録は `serverDone`。`signOut` は0回 | ACD-X15 | 概要 §操作が失敗したとき | 確定 |
| ACD-V09 | `phase` が `processing` の間に、もう一度 `withdraw` を呼んだ | `requestServerDeletion` は合計1回だけ呼ばれる | ACD-X09 | 原則-4 | 確定 |
| ACD-V10 | （廃止）端末内の削除が `NetworkFailure` で失敗した | 端末内の削除は通信を使わず `NetworkFailure` は発生しないため廃止（7章） | — | — | 廃止 |
| ACD-V11 | 記録が無い状態で `withdraw` を呼び、関数の呼び出しが `AuthFailure` で失敗した | `phase` は `notSent`。`clearRequest(A)` が1回呼ばれ、uid `A` の記録は無い。`deleteLocalData`・`signOut` は0回 | ACD-E01 | ユーザー決定 2026-10-03（ACD-Q01） | 確定 |
| ACD-V12 | ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しと端末内の削除がどちらも成功した | `phase` は `completed`。`requestServerDeletion`・`markServerDone(A)`・`deleteLocalData(A)`・`signOut` がこの順に1回ずつ呼ばれる | ACD-T01 | 概要 §途中で止まった場合 | 確定 |
| ACD-V13 | uid `A` の記録が `serverDone` の状態で `retry` を呼び、端末内の削除が成功した | `phase` は `completed`。`requestServerDeletion` は0回、`deleteLocalData(A)` は1回、`signOut` は1回 | ACD-T02 | 概要 §途中で止まった場合 | 確定 |
| ACD-V14 | ログインしていない状態で uid `A` の記録が `requested` のまま `retry` を呼び、端末内の削除が成功した | `phase` は `completed`。`requestServerDeletion` は0回、`deleteLocalData(A)` は1回、`signOut` は1回 | ACD-T03 | 概要 §途中で止まった場合 | 確定 |
| ACD-V15 | ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しが `AuthFailure` で失敗し、端末内の削除が成功した | `phase` は `completed`。`deleteLocalData(A)` は1回、`signOut` は1回 | ACD-T04 | 概要 §途中で止まった場合 | 確定 |
| ACD-V16 | ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しが `NetworkFailure` で失敗した | `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま。`deleteLocalData` は0回 | ACD-T06 | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-V17 | ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しが `UnknownFailure` で失敗した | `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま。`deleteLocalData` は0回 | ACD-T07 | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-V18 | uid `A` の記録が `serverDone` の状態で `retry` を呼び、端末内の削除が `UnknownFailure` で失敗した | `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `serverDone` のまま | ACD-T08 | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-V19 | ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の応答を待っている | `phase` は `processing` | ACD-T05 | 原則-5 | 確定 |
| ACD-V20 | ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、その処理中にもう一度 `retry` を呼び、関数の呼び出しと端末内の削除がどちらも成功した | `requestServerDeletion` は合計1回、`deleteLocalData(A)` は合計1回呼ばれる | ACD-T05 | 原則-4 | 確定 |
| ACD-V21 | `phase` が `completed` の状態で `acknowledgeCompleted` を呼んだ | `phase` は `idle` | ACD-X11 | 概要 §完了ダイアログ | 確定 |
| ACD-V22 | `phase` が `notSent` の状態で `acknowledgeNotSent` を呼んだ | `phase` は `idle` | ACD-X13 | 概要 §退会できなかったときのダイアログ | 確定 |
| ACD-V23 | `phase` が `pendingRetry`、`retryFailed` が true の状態で `retry` を呼び、関数の応答を待っている | `phase` は `processing`、`retryFailed` は false | ACD-T05 | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-V24 | 記録が無い状態で `withdraw` を呼び、関数の呼び出しと端末内の削除が成功し、`signOut` が `UnknownFailure` で失敗した | `phase` は `completed` | ACD-X17 | 概要 §退会の流れ（サーバー側でユーザーは削除済み） | 確定 |
| ACD-V25 | uid `A` の記録が `serverDone` の状態で `retry` を呼び、端末内の削除の完了を待っている | `phase` は `processing` | ACD-T09 | 原則-5 | 確定 |
| ACD-V26 | ログイン中の uid が `B`、記録が uid `A` の `requested` の状態で `retry` を呼び、端末内の削除が成功した | `phase` は `completed`。`requestServerDeletion` は0回。`signOut` が `deleteLocalData(A)` より先に呼ばれる。`deleteLocalData(B)` は0回 | ACD-T10 | ユーザー決定 2026-10-03（ACD-Q04） | 確定 |
| ACD-V27 | uid `A` の記録が `serverDone` の状態で `retry` を呼び、端末内の削除が成功し、`signOut` が `UnknownFailure` で失敗した | `phase` は `completed` | ACD-T11 | 概要 §退会の流れ 4 | 確定 |
| ACD-V28 | ログイン中の uid が `B`、記録が uid `A` の `requested` の状態で `checkPending` をした | `phase` は `pendingRetry`、`retryFailed` は false | ACD-D12 | 概要 §途中で止まった場合 | 確定 |
| ACD-V29 | ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しは成功し、端末内の削除が `UnknownFailure` で失敗した | `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `serverDone`。`signOut` は0回 | ACD-T12 | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-V30 | ログインしていない状態で uid `A` の記録が `requested` のまま `retry` を呼び、端末内の削除が `UnknownFailure` で失敗した | `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま。`signOut` は0回 | ACD-T13 | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-V31 | ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しが `AuthFailure` で失敗し、端末内の削除が `UnknownFailure` で失敗した | `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま。`signOut` は0回 | ACD-T14 | 概要 §退会処理の再開ダイアログ | 確定 |
| ACD-V32 | `phase` が `pendingRetry` の状態で `withdraw` を呼んだ | `phase` は `pendingRetry` のまま。`markRequested`・`requestServerDeletion` は0回 | ACD-D09 | 概要 §途中で止まった場合（他の機能は使えない） | 確定 |
| ACD-V33 | 記録の読み取り（`findPending`）が `UnknownFailure` で失敗する状態で `checkPending` をした | `phase` は `pendingRetry`、`retryFailed` は false | ACD-D15 | ユーザー決定 2026-10-03（ACD-Q02） | 確定 |
| ACD-V34 | `phase` が `pendingRetry` で、`findPending` が `Right(None)` を返す状態で `retry` を呼んだ | `phase` は `idle`。`requestServerDeletion`・`deleteLocalData` は0回 | ACD-T15 | ユーザー決定 2026-10-03（ACD-Q02） | 確定 |
| ACD-V35 | 記録が無い状態で `withdraw` を呼び、`markRequested` が `UnknownFailure` で失敗した | `phase` は `notSent`。`requestServerDeletion` は0回 | ACD-X21 | ユーザー決定 2026-10-03（ACD-Q05） | 確定 |
| ACD-V36 | 記録が無い状態で `withdraw` を呼び、関数の呼び出しが `NetworkFailure` で失敗し、`clearRequest` が `UnknownFailure` で失敗した | `phase` は `pendingRetry`、`retryFailed` は false | ACD-X22 | ユーザー決定 2026-10-03（ACD-Q05） | 確定 |
| ACD-V37 | 記録が無い状態で `withdraw` を呼び、関数の呼び出しは成功し、`markServerDone` が `UnknownFailure` で失敗し、端末内の削除は成功した | `phase` は `completed`。`deleteLocalData(A)` は1回 | ACD-X23 | ユーザー決定 2026-10-03（ACD-Q05） | 確定 |
| ACD-V38 | ViewModel を作成した直後（`checkPending` の完了前） | `phase` は `checking` | ACD-D16 | ユーザー決定 2026-10-03（ACD-Q06） | 確定 |

---

## 5. リポジトリ契約

### 5.1 AccountDeletionRepository

| ID | メソッド | 条件 | 期待される結果 | 根拠 | 確定度 |
|----|----------|------|----------------|------|--------|
| ACD-R01 | findPending | 記録が無い | `Right(None)` | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R02 | markRequested | 記録が無い状態で `markRequested(A)` を呼んだ | `Right(unit)`。その後の `findPending` は `Right(Some(userId: A, status: requested))` | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R03 | markServerDone | 記録が無い状態で `markRequested(A)` を呼んで記録の updatedAt を取得し、その後に `markServerDone(A)` を呼んだ | `Right(unit)`。その後の `findPending` は `Right(Some(userId: A, status: serverDone))`。updatedAt は `markRequested` のときの updatedAt より前にならない | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R04 | clearRequest | uid `A` の記録が `requested` の状態で `clearRequest(A)` を呼んだ | `Right(unit)`。その後の `findPending` は `Right(None)` | 概要 §操作が失敗したとき | 確定 |
| ACD-R05 | deleteLocalData | uid `A` と uid `B` それぞれのフォルダ・単語・学習結果・設定・`sync_queue`・`sync_meta`（`pullCursor:<uid>`・`lastPulledAt:<uid>`）があり、uid `A` の記録が `serverDone` の状態で `deleteLocalData(A)` を呼んだ | `Right(unit)`。uid `A` のフォルダ・単語・学習結果・設定・`sync_queue` の行・`sync_meta` のキーは0件。uid `B` の行とキーはすべて残る。その後の `findPending` は `Right(None)` | 概要 §目的, 概要 §退会処理の状態の記録 | 確定 |
| ACD-R06 | deleteLocalData | uid `A` のデータと `serverDone` の記録がある状態で `deleteLocalData(A)` を呼び、uid `A` のフォルダを削除した後、記録を削除する前に SQLite の書き込みが失敗した | `Left(UnknownFailure)`。uid `A` のフォルダ・単語・学習結果・設定・`sync_queue`・`sync_meta` は呼ぶ前と同じ件数。`findPending` は `Right(Some(userId: A, status: serverDone))` | 概要 §退会処理の状態の記録（1つのトランザクション） | 確定 |
| ACD-R07 | requestServerDeletion | オンラインで、関数 `deleteAccount` が成功を返した | `Right(unit)`。関数 `deleteAccount` は1回呼ばれる | 概要 §削除の方式 | 確定 |
| ACD-R08 | requestServerDeletion | オフライン（接続状態の確認がオフラインを返す） | `Left(NetworkFailure)`。関数 `deleteAccount` は0回 | 概要 §操作が失敗したとき | 確定 |
| ACD-R09 | requestServerDeletion | オンラインで、関数の呼び出しがエラーコード `unavailable` で失敗した | `Left(NetworkFailure)` | 概要 §操作が失敗したとき（関数に届かなかった） | 確定 |
| ACD-R10 | requestServerDeletion | オンラインで、関数の呼び出しがエラーコード `deadline-exceeded` で失敗した（応答が時間内に来ない） | `Left(UnknownFailure)` | 概要 §操作が失敗したとき（届いたか分からない） | 確定 |
| ACD-R11 | requestServerDeletion | オンラインで、関数の呼び出しがエラーコード `unauthenticated` で失敗した | `Left(AuthFailure)` | 概要 §途中で止まった場合 | 確定 |
| ACD-R12 | requestServerDeletion | オンラインで、関数の呼び出しがエラーコード `internal` で失敗した | `Left(UnknownFailure)` | 概要 §操作が失敗したとき（その他のエラー） | 確定 |
| ACD-R24 | deleteLocalData | uid `A` のデータが1件も無く、記録も無い状態で `deleteLocalData(A)` を呼んだ | `Right(unit)` | 概要 §削除の方式（何度でも同じ結果） | 確定 |
| ACD-R25 | markRequested | uid `A` の記録が `requested` の状態で `markRequested(A)` を呼んだ | `Right(unit)`。その後の `findPending` は `Right(Some(userId: A, status: requested))` | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R26 | clearRequest | 記録が無い状態で `clearRequest(A)` を呼んだ | `Right(unit)`。その後の `findPending` は `Right(None)` | 概要 §操作が失敗したとき | 確定 |
| ACD-R27 | requestServerDeletion | オンラインで、関数の呼び出しが `FirebaseFunctionsException` 以外の例外で失敗した | `Left(UnknownFailure)` | 概要 §操作が失敗したとき（その他のエラー）, 原則-10 | 確定 |
| ACD-R29 | requestServerDeletion | オンラインで `requestServerDeletion` を呼んだ | 関数 `deleteAccount` の呼び出しに、応答の待ち時間の上限として60秒が指定される | ユーザー決定 2026-10-03（ACD-Q07） | 確定 |

### 5.2 SyncRepository（退会処理中の同期の停止）

| ID | メソッド | 条件 | 期待される結果 | 根拠 | 確定度 |
|----|----------|------|----------------|------|--------|
| ACD-R13 | syncAll | ログイン中の uid `A` に未送信の変更が1件あり、uid `A` の記録が `requested` の状態で `syncAll` を呼んだ | リモートへの送信・取得は0回。未送信の変更は1件のまま | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R14 | pushPending | ログイン中の uid `A` に未送信の変更が1件あり、uid `A` の記録が `serverDone` の状態で `pushPending` を呼んだ | リモートへの送信は0回。未送信の変更は1件のまま | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R15 | syncAll | ログイン中の uid `A` に未送信の変更が1件あり、uid `B` の記録だけがある状態で `syncAll` を呼んだ | uid `A` の変更がリモートに1回送信される | 概要 §退会処理の状態の記録（そのユーザーの同期を止める） | 確定 |
| ACD-R16 | waitUntilIdle | 送信の処理が実行中の状態で `waitUntilIdle` を呼んだ | 実行中の送信が終わった後に完了する | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R17 | waitUntilIdle | 実行中の同期が無い状態で `waitUntilIdle` を呼んだ | すぐに完了する | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R18 | syncAll | uid `A` の記録が `requested` だった状態から `clearRequest(A)` で記録を消した後に、未送信の変更が1件ある状態で `syncAll` を呼んだ | uid `A` の変更がリモートに1回送信される | 概要 §操作が失敗したとき（同期を元に戻す） | 確定 |
| ACD-R19 | waitUntilIdle | 取得の処理が実行中の状態で `waitUntilIdle` を呼んだ | 実行中の取得が終わった後に完了する | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R20 | waitUntilIdle | 実行中の送信で、リモートへの書き込みが例外を投げて送信が失敗して終わる状態で `waitUntilIdle` を呼んだ | 送信が失敗で終わった後に完了する（エラーにならない） | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R21 | syncAll | ログイン中の uid `A` に未送信の変更が1件あり、uid `A` の記録が `serverDone` の状態で `syncAll` を呼んだ | リモートへの送信・取得は0回。未送信の変更は1件のまま | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R22 | pushPending | ログイン中の uid `A` に未送信の変更が1件あり、uid `A` の記録が `requested` の状態で `pushPending` を呼んだ | リモートへの送信は0回。未送信の変更は1件のまま | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R23 | syncOnResumed | ログイン中の uid `A` の前回の取得から5分以上たち、uid `A` の記録が `requested` の状態で `syncOnResumed` を呼んだ | リモートからの取得は0回 | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R28 | syncOnResumed | ログイン中の uid `A` の前回の取得から5分以上たち、uid `A` の記録が `serverDone` の状態で `syncOnResumed` を呼んだ | リモートからの取得は0回 | 概要 §退会処理の状態の記録 | 確定 |
| ACD-R30 | syncAll | ログイン中の uid `A` に未送信の変更が1件あり、記録の読み取りが失敗する状態で `syncAll` を呼んだ | リモートへの送信・取得は0回。未送信の変更は1件のまま | ユーザー決定 2026-10-03（ACD-Q02） | 確定 |

## 6. ユースケース

DeleteAccountUseCase は、手順の順序と分岐（記録の状態・Failure の種類による分岐）を持つ。これらは4章で ViewModel を通して検証する（ViewModel は UseCase を呼ぶだけで、独自の分岐を持たない）。UseCase 単体の仕様項目は作らない。

---

## 7. 対象外

- **関数 `deleteAccount` の中の動作**（Firestore の `users/{uid}` 配下と `accounts/{uid}` の削除、Authentication のユーザーの削除、何度呼んでも成功すること、すでにユーザーがいないときに成功すること）: Cloud Functions 側（`functions/`）のテストで、Firebase Emulator を使って検証する。Flutter のテストの対象外
- **`requestServerDeletion` / `deleteLocalData` の `NotFoundFailure`**: 関数は対象が無くても成功を返し、端末内の削除は対象の行が無くても成功する（ACD-R24）ため、発生しない
- **`deleteLocalData` の `NetworkFailure` / `AuthFailure`**: 端末内の削除は通信も認証も使わないため、発生しない（ACD-E02・ACD-V10 はこの理由で廃止）
- **確認ダイアログ・最終確認ダイアログ・完了ダイアログ・「退会できませんでした」ダイアログでの二重操作**: ボタンをタップするとダイアログが閉じるため、同じボタンを2回押せない
- **同じ端末で複数の uid の記録が同時にある状態**: 再開ダイアログで退会を終えるまで他の機能が使えず、別のアカウントで退会を始められないため、起こらない
- **起動直後の画面ごとの再開ダイアログの表示**: 起動直後の画面はログイン状態だけで決まる（ログイン中ならホーム、そうでなければログイン画面）ため、ログイン中（ACD-D03・ACD-D08・ACD-D12）とログインしていない（ACD-D04・ACD-D05）で網羅している
- **自動同期の契機ごとの停止**（接続復帰・ログイン済み・登録や編集の直後）: どの契機も `syncAll` / `pushPending` / `syncOnResumed` を呼ぶため、ACD-R13・R14・R21・R22・R23・R28 で網羅している
- **`waitUntilIdle` の待ち時間の上限**: 同期のリモート通信には1回ごとに時間の上限があり（online_offline §オンライン・オフラインの判定）、待ちは必ず終わる
- **設定画面のダークモード・カラーテーマ・ログアウト**: この仕様書の範囲外（退会だけを扱う）
- **共通原則-11（`NetworkFailure` / `AuthFailure` → 通信エラーダイアログ → ログアウト）**: 退会処理の失敗には適用しない（概要 §操作が失敗したとき）。初回の `AuthFailure` も「退会できませんでした」とする（ACD-E01）
- **原則-10（画面が崩れない）**: 表示する文言はすべて固定で、長い文字列や多数のデータを表示しないため、個別の仕様項目を作らない

## 8. 要確認事項

| ID | 論点 | 案 | 推奨 | 決定 |
|----|------|----|------|------|
| ACD-Q01 | 最終確認で OK を押したとき、関数の呼び出しが `AuthFailure`（ログイン情報が無効）で失敗した場合の扱い（ACD-E01 / ACD-V11）。初回の呼び出しで `AuthFailure` になるのは、サーバーが本人を確認できず何も削除していない場合 | A: 記録を消し、「退会できませんでした」ダイアログを表示して設定画面に留まる ／ B: 記録を消し、共通原則-11 どおり通信エラーダイアログ → ログアウト → ログイン画面 ／ C: 再試行と同じく、削除済みとみなして端末内を削除し、完了にする | A（概要設計書の「退会処理では強制ログアウトしない」と揃う。何も削除していないので、もう一度ログインし直してから退会すればよい。C はサーバーにデータが残ったまま完了と表示する恐れがある） | 決定: 案A（2026-10-03） |
| ACD-Q02 | 起動時に退会処理の記録を読み取れなかった（SQLite の読み取りが `UnknownFailure` で失敗）場合の扱い | A: 記録が無いものとして通常どおり起動する ／ B: 再開ダイアログを表示し、再試行で記録を読み直す | B（記録がある間は同期しない、という保証を崩さないため。端末内の読み取りが失敗するのはまれ）。B に決まったら、読み直しの再試行（成功して記録なし → ダイアログを閉じる）と、読み取り失敗時の ViewModel の状態の ID を追加する | 決定: 案B（2026-10-03） |
| ACD-Q03 | 完了ダイアログ・「退会できませんでした」ダイアログの外側をタップした場合の扱い | A: ダイアログを閉じる（OK と同じ） ／ B: 閉じない（OK でだけ閉じる） | A（どちらも結果を伝えるだけのダイアログで、閉じても状態は変わらないため） | 決定: 案A（2026-10-03） |
| ACD-Q04 | 記録の uid（`A`）とログイン中の uid（`B`）が違う状態で再試行した場合（ACD-T10）。通常は起こらない（再開ダイアログで他の操作ができないため）が、関数を呼ぶと `B` のアカウントを削除してしまう | A: 関数は呼ばず、`A` の端末内のデータだけを削除して完了にする ／ B: `B` をログアウトさせ、再開ダイアログを出したままにする ／ C: 再開ダイアログのまま何もせず、「ログイン中のアカウントが退会処理中のアカウントと異なります」と表示する ／ D: `B` をログアウトさせ（`B` のデータは消さない）、ログインしていない状態の再試行（ACD-T03 と同じ経路）にする | D（`B` を誤って削除しない。C はユーザーが先に進めなくなる。A・D とも `A` のサーバー側が削除済みか分からないまま完了と表示する点は同じだが、D はログイン状態を正しく解除する。通常は起こらない前提の安全策） | 決定: 案D（2026-10-03） |
| ACD-Q05 | 記録の読み書き（`markRequested` / `markServerDone` / `clearRequest`）が `UnknownFailure` で失敗した場合の扱い | `markRequested` の失敗: A: 関数を呼ばず「退会できませんでした」を表示 ／ `markServerDone` の失敗: A: そのまま端末内の削除へ進む（削除で記録も消える。削除も失敗すれば記録は `requested` のまま再開ダイアログ → 再試行で関数をもう一度呼ぶ）／ `clearRequest` の失敗: A: 再開ダイアログを表示する（記録が残り、再試行で退会が進む。ユーザーは2回同意済み）、B: 「退会できませんでした」を表示する（次の起動時に再開ダイアログが出て、退会が進む） | すべて A。`markServerDone` の失敗後に端末内の削除も失敗した場合、記録は `requested` のまま再開ダイアログになり、再試行はサーバー側でユーザーが削除済みのため関数が `unauthenticated` を返し、ACD-T04 と同じ経路（端末内を削除して完了）になる。決定後に、各失敗の ID を 3章・4章・5章に追加する | 決定: 案すべて A（2026-10-03） |
| ACD-Q06 | 起動時の記録の確認が終わるまでの間の表示（同期の開始・ホームへの移動・設定の「退会」のタップを許すか） | A: 確認が終わるまでスプラッシュ画面のままにし、同期も始めない ／ B: 通常どおり起動し、確認が終わり次第ダイアログを出す | A（確認前に同期が始まると、削除中のデータが送り返される恐れがあるため） | 決定: 案A（2026-10-03） |
| ACD-Q07 | 関数の呼び出しを「応答が時間内に来ない」とみなす時間 | A: 60秒 ／ B: 120秒 | A（サーバー側の処理が長引いても、時間切れは「届いたか分からない」扱いで再開ダイアログになり、再試行で完了できるため、長くする必要がない）。決定後に「時間内に応答が来ない → `Left(UnknownFailure)`」の ID を ACD-R10 とは別に追加する | 決定: 案A（60秒）（2026-10-03） |

---

## 9. 網羅表

### 9.1 概要設計書との対応

| 概要設計書（§見出し：要点） | 仕様 ID ／ 振り分け |
|---------------------------|--------------------|
| §目的：Authentication のユーザーを削除 | 7章（関数の中の動作） |
| §目的：Firestore のそのユーザーのデータを削除 | 7章（関数の中の動作） |
| §目的：Firestore のそのユーザーのアカウント情報（`accounts/{uid}`）を削除 | 7章（関数の中の動作。`functions/test/delete_account.test.ts` で検証） |
| §目的：端末内のそのユーザーのデータを削除、他のアカウントは残す | ACD-R05 |
| §削除の方式：関数を1回呼ぶだけ | ACD-V05, ACD-R07 |
| §削除の方式：本人のデータだけ・Firestore → Authentication の順 | 7章（関数の中の動作）, ACD-T10, ACD-V26 |
| §削除の方式：何度呼んでも同じ結果 | 7章（関数の中の動作）, ACD-R24, ACD-R25, ACD-R26 |
| §削除の方式：関数の成功を受け取ってから端末内を削除 | ACD-V05, ACD-V06, ACD-V07 |
| §削除の方式：パスワードの再入力は求めない | ACD-X07 |
| §画面構成：「ログアウト」の下に「退会」 | ACD-D01 |
| §画面構成：赤色・人の削除のアイコン | ACD-D01 |
| §退会の流れ：1. 退会で確認ダイアログ | ACD-X01 |
| §退会の流れ：2. OK で最終確認ダイアログ | ACD-X04 |
| §退会の流れ：3. OK で処理開始・ローディング | ACD-X07 |
| §退会の流れ：3. 他の操作（戻る操作を含む）をできない | ACD-X08, ACD-X09, ACD-X16, ACD-X18 |
| §退会の流れ：4. 成功でログアウト・ログイン画面・完了ダイアログ | ACD-X10, ACD-V05, ACD-V12, ACD-V13 |
| §退会の流れ：4. ログアウトに失敗しても成功扱い | ACD-X17, ACD-T11, ACD-V24, ACD-V27 |
| §確認ダイアログ：構成（タイトル・本文・ボタン並び） | ACD-X01 |
| §確認ダイアログ：キャンセル | ACD-X02 |
| §確認ダイアログ：外側タップ | ACD-X03 |
| §確認ダイアログ：OK | ACD-X04 |
| §最終確認ダイアログ：構成 | ACD-X04 |
| §最終確認ダイアログ：OK は赤色 | ACD-X04 |
| §最終確認ダイアログ：キャンセル | ACD-X05 |
| §最終確認ダイアログ：外側タップ | ACD-X06 |
| §最終確認ダイアログ：OK | ACD-X07 |
| §処理中の表示：「退会処理中です」 | ACD-X07 |
| §処理中の表示：タップを受け付けない | ACD-X09, ACD-X16 |
| §処理中の表示：戻る操作を受け付けない | ACD-X08 |
| §完了ダイアログ：ログイン画面の上・構成 | ACD-X10 |
| §完了ダイアログ：OK | ACD-X11 |
| §完了ダイアログ：外側タップ | ACD-X19 |
| §退会できなかったときのダイアログ：構成 | ACD-X12 |
| §退会できなかったときのダイアログ：OK | ACD-X13, ACD-V22 |
| §退会できなかったときのダイアログ：外側タップ | ACD-X20 |
| §退会処理の再開ダイアログ：構成・ボタンは1つだけ | ACD-D03 |
| §退会処理の再開ダイアログ：再試行・処理中は押せない・ローディング | ACD-T05, ACD-T09 |
| §退会処理の再開ダイアログ：再試行が成功 | ACD-T01, ACD-T02, ACD-T03, ACD-T04 |
| §退会処理の再開ダイアログ：再試行が失敗 | ACD-T06, ACD-T07, ACD-T08, ACD-T12, ACD-T13, ACD-T14 |
| §退会処理の再開ダイアログ：外側タップ | ACD-D06, ACD-D11 |
| §退会処理の再開ダイアログ：戻る操作 | ACD-D07, ACD-D10 |
| §退会処理の状態の記録：状態（削除中・サーバー削除済み・記録なし） | ACD-R01, ACD-R02, ACD-R03 |
| §退会処理の状態の記録：関数を呼ぶ前に「削除中」 | ACD-V04, ACD-V05 |
| §退会処理の状態の記録：成功で「サーバー削除済み」 | ACD-V05 |
| §退会処理の状態の記録：端末内の削除と記録の削除を1トランザクション | ACD-R05, ACD-R06 |
| §退会処理の状態の記録：記録がある間は同期しない | ACD-R13, ACD-R14, ACD-R15, ACD-R21, ACD-R22, ACD-R23, ACD-R28 |
| §退会処理の状態の記録：実行中の同期が終わってから関数を呼ぶ | ACD-V04, ACD-R16, ACD-R17, ACD-R19, ACD-R20 |
| §途中で止まった場合：起動時に記録があれば再開ダイアログ（ログイン中） | ACD-D03, ACD-D08, ACD-D12 |
| §途中で止まった場合：起動時に記録があれば再開ダイアログ（ログインしていない） | ACD-D04, ACD-D05 |
| §途中で止まった場合：記録が無ければ表示しない | ACD-D02 |
| §途中で止まった場合：退会を終えるまで他の機能は使えない | ACD-D06, ACD-D07, ACD-D09, ACD-D13, ACD-D14, ACD-D16 |
| §途中で止まった場合：削除中 → 関数をもう一度呼ぶ | ACD-T01, ACD-V12 |
| §途中で止まった場合：削除中（ログインしていない） → 関数を呼ばずに端末内を削除 | ACD-T03, ACD-V14 |
| §途中で止まった場合：削除中（ログイン情報が無効と返された） → 端末内を削除 | ACD-T04, ACD-V15, ACD-R11 |
| §途中で止まった場合：サーバー削除済み → 端末内を削除 | ACD-T02, ACD-V13 |
| §操作が失敗したとき：通信エラー → 記録を消し同期を戻し「退会できませんでした」 | ACD-X12, ACD-V06, ACD-R08, ACD-R09, ACD-R18 |
| §操作が失敗したとき：届いたか分からない → 「削除中」のまま再開ダイアログ | ACD-X14, ACD-V07, ACD-R10, ACD-R12, ACD-R27, ACD-R29 |
| §操作が失敗したとき：端末内の削除に失敗 → 「サーバー削除済み」のまま再開ダイアログ | ACD-X15, ACD-V08 |
| §操作が失敗したとき：通信エラーダイアログ・強制ログアウトをしない | ACD-X12（通信エラーダイアログが表示されない） |
| §画面遷移：成功でログイン画面 | ACD-X10, ACD-T01 |
| §画面遷移：「退会できませんでした」で OK → 設定画面のまま | ACD-X13 |

### 9.2 操作 × 観点

| 操作 | 成功 | Unknown | NotFound | Network | Auth | キャンセル | 外側タップ | 処理中（無効化） | 二重操作 | 対象の不在 | 同じ値 | 入力の境界 |
|-----|-----|---------|----------|---------|------|-----------|-----------|----------------|---------|-----------|--------|-----------|
| 設定画面の表示 | ACD-D01 | — 設定の読み込みは範囲外（7章） | — 範囲外 | — 範囲外 | — 範囲外 | — 操作なし | — 操作なし | — 処理なし | — 操作なし | — 対象なし | — 値なし | — 入力なし |
| 起動時の確認 | ACD-D02, ACD-D03, ACD-D04, ACD-D05, ACD-D08, ACD-V01〜V03 | ACD-D15, ACD-V33 | — 記録が無いのは ACD-D02 | — 端末内の読み取りのみで通信なし | — 認証を使わない | — 操作なし | — 操作なし | ACD-D16, ACD-V38 | — 起動時に1回だけ | ACD-D02（記録なし） | — 値なし | — 入力なし |
| 「退会」タップ（確認ダイアログ） | ACD-X04 | — 通信なし | — 通信なし | — 通信なし | — 通信なし | ACD-X02 | ACD-X03 | — 処理なし | 7章（ダイアログが閉じる） | — 対象は自分 | — 値なし | — 入力なし |
| 最終確認で OK（退会処理） | ACD-X10, ACD-V05, ACD-V24 | ACD-X14, ACD-V07, ACD-X15, ACD-V08 | 7章（発生しない） | ACD-X12, ACD-V06 | ACD-E01, ACD-V11 | ACD-X05 | ACD-X06 | ACD-X07, ACD-X08, ACD-X16, ACD-X18 | ACD-X09, ACD-V09 | — 対象は自分 | — 値なし | — 入力なし |
| 完了ダイアログの OK | ACD-X11, ACD-V21 | — 通信なし | — 通信なし | — 通信なし | — 通信なし | — OK のみ | ACD-X19 | — 処理なし | 7章（ダイアログが閉じる） | — 対象なし | — 値なし | — 入力なし |
| 「退会できませんでした」の OK | ACD-X13, ACD-V22 | — 通信なし | — 通信なし | — 通信なし | — 通信なし | — OK のみ | ACD-X20 | — 処理なし | 7章（ダイアログが閉じる） | — 対象なし | — 値なし | — 入力なし |
| 再試行 | ACD-T01, ACD-T02, ACD-T03, ACD-T04 | ACD-T07, ACD-V17, ACD-T08, ACD-V18, ACD-T12, ACD-T13, ACD-T14, ACD-V29〜V31 | 7章（発生しない） | ACD-T06, ACD-V16 | ACD-T04, ACD-V15（成功扱い） | — 再試行のみ | ACD-D06, ACD-D11 | ACD-T05, ACD-T09, ACD-V19, ACD-V25, ACD-D10, ACD-D13 | ACD-V20 | 7章（記録が無ければ再開ダイアログは出ない） | — 値なし | — 入力なし |
| 記録の読み書き（markRequested / markServerDone / clearRequest） | ACD-R02, ACD-R03, ACD-R04 | ACD-X21, ACD-X22, ACD-X23, ACD-V35〜V37 | ACD-R26（記録が無くても成功） | — 通信なし | — 認証を使わない | — 操作なし | — 操作なし | — 画面操作なし | ACD-R25 | ACD-R26 | ACD-R25 | — 入力なし |

### 9.3 操作 × 共通原則

| 操作 | 原則-1 | 原則-2 | 原則-3 | 原則-4 | 原則-5 | 原則-6 | 原則-7 | 原則-8 | 原則-9 | 原則-10 | 原則-11 |
|-----|-------|-------|-------|-------|-------|-------|-------|-------|-------|--------|--------|
| 「退会」タップ | — 失敗しない | — 失敗しない | — 入力なし | — 処理なし | — 処理なし | ACD-X01, ACD-X04（確認2回） | ACD-X02, ACD-X03, ACD-X05, ACD-X06 | — 入力なし | — 自分の操作のみ | 7章（固定文言のみ） | — 通信なし |
| 最終確認で OK | ACD-X12（設定画面に留まる）, ACD-V07（記録を残す）, ACD-R06（失敗時は端末内のデータが消えない） | ACD-X12, ACD-X14, ACD-X15 | — 入力なし | ACD-X09, ACD-X16, ACD-V09 | ACD-X07 | ACD-X04 | ACD-X05, ACD-X06 | — 入力なし | ACD-R05（他の uid は残す）, ACD-R15, ACD-T10 | 7章（固定文言のみ）, ACD-R27 | 7章（適用しない）, ACD-E01 |
| 再試行 | ACD-T06, ACD-T07, ACD-T08（再開ダイアログを残す） | ACD-T06, ACD-T07, ACD-T08 | — 入力なし | ACD-T05, ACD-T09, ACD-V20 | ACD-T05, ACD-T09 | — すでに同意済み | ACD-D06, ACD-D07, ACD-D10, ACD-D11（閉じる操作をしても記録は変わらない） | — 入力なし | ACD-R05, ACD-T10 | 7章（固定文言のみ） | 7章（適用しない） |
| 起動時の確認 | — 表示中のデータなし | ACD-D15 | — 入力なし | — 起動時に1回だけ | ACD-D16 | — 削除を始めない | — キャンセルなし | — 入力なし | — 自分の端末の記録のみ | 7章（固定文言のみ） | — 通信なし |
