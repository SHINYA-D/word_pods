---
feature: 設定画面（外観・ログアウト）
prefix: APS
status: approved
targets:
  - lib/presentation/settings/settings_page.dart
  - lib/presentation/settings/settings_view_model.dart
  - lib/application/use_cases/auth/sign_out_use_case.dart
kinds:
  A: 外観の変更
  O: ログアウト
updated: 2026-11-16
---

# 設定画面（外観・ログアウト） 振る舞い仕様書

## 1. 機能概要

設定画面（`/settings`）のうち、外観（ダークモード・カラーテーマ）の変更とログアウトを定める。ボトムナビゲーションバーの「設定」で開く。

対象の概要設計書は `docs/high_level_design/app_settings.md`（根拠欄の `概要 §<見出し>`）。
設定画面の他の項目は、次の仕様書で定める。

| 項目 | 仕様書 |
|-----|-------|
| 退会・他の端末での退会 | `docs/detailed_design/presentation/settings/settings_page.md`（ACD） |
| 「このアプリについて」（利用規約・プライバシーポリシー） | `docs/detailed_design/legal_consent/legal_consent.md`（LGL-B） |
| アカウント情報画面 | `docs/detailed_design/presentation/account/account_page.md`（ACI） |
| 設定の保存・読み取りの結果 | `docs/detailed_design/online_offline/settings_repository.md`（STG） |
| ログアウト前の未送信の変更の送信 | `docs/detailed_design/online_offline/online_offline.md`（SYN-O） |

設定画面の仕様書（`settings_page.md`）はすでに退会を扱っているため、この仕様書は機能名のフォルダ（`app_settings/`）に置く。

ログイン中のユーザーは id が `u1` のユーザーとする。
特に書かない限り、`u1` の設定はダークモードがオフ、カラーテーマが「indigo」とする。

## 2. データ定義

### 2.1 UserSettings

| 項目 | 型 | 説明 |
|------|----|------|
| colorTheme | String | カラーテーマ。「indigo」「blue」「teal」「green」「orange」「pink」「purple」のどれか。既定は「indigo」 |
| darkMode | bool | ダークモード。既定は false |
| updatedAt | DateTime? | 更新日時 |

### 2.2 入力ルール

該当なし（スイッチとドロップダウンで選ぶだけで、決められた値以外は入力できない）。

---

## 3. 画面仕様（SettingsPage：外観・ログアウト）

### 3.1 表示

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| APS-D01 | `/settings` を開いた | AppBar に「設定」と表示される。「外観」「ダークモード」「カラーテーマ」「このアプリについて」「利用規約」「プライバシーポリシー」「アカウント」「アカウント情報」「ログアウト」「退会」がこの順で表示される。「ダークモード」のスイッチはオフ、「カラーテーマ」のドロップダウンに「indigo」が表示される | 概要 §画面構成, §外観 | 確定 |
| APS-D02 | `u1` の設定がダークモードがオン、カラーテーマが「teal」の状態で `/settings` を開いた | 「ダークモード」のスイッチがオン、「カラーテーマ」のドロップダウンに「teal」が表示される | 概要 §ダークモード, §カラーテーマ | 確定 |
| APS-D03 | `u1` の設定がまだ保存されていない状態で `/settings` を開いた | 「ダークモード」のスイッチがオフ、「カラーテーマ」のドロップダウンに「indigo」が表示される | 概要 §外観（まだ一度も変えていないユーザー） | 確定 |
| APS-D04 | `/settings` を開き、`getSettings` の応答を待っている | 画面の中央にローディングが表示される | 概要 §読み込み中・読み込みに失敗したとき | 確定 |
| APS-D05 | `getSettings` が `UnknownFailure` で失敗する状態で `/settings` を開いた | `ErrorScreen` に「設定の読み込みに失敗しました」と「再試行」ボタンが表示される | 概要 §読み込み中・読み込みに失敗したとき | 確定 |
| APS-D06 | APS-D05 の状態から、`getSettings` がダークモードがオフ・カラーテーマが「indigo」の設定を返すように変わり、「再試行」をタップした | `ErrorScreen` が表示されなくなり、「ダークモード」のスイッチと「カラーテーマ」の「indigo」が表示される | 概要 §読み込み中・読み込みに失敗したとき（8章 Q1）、ユーザー決定 2026-11-16 | 確定 |
| APS-D07 | 画面の大きさが幅 320・高さ 480 の端末で `/settings` を開いた | オーバーフローのエラーが起きない。縦にスクロールすると「退会」が表示される | 原則-10 | 確定 |
| APS-D08 | APS-D05 の状態で「再試行」をタップし、また `UnknownFailure` で失敗した | `ErrorScreen` に「設定の読み込みに失敗しました」と「再試行」ボタンが表示されたまま | 概要 §読み込み中・読み込みに失敗したとき（8章 Q1）、ユーザー決定 2026-11-16 | 確定 |
| APS-D09 | APS-D05 の状態で「再試行」をタップし、`getSettings` の応答を待っている | 画面の中央にローディングが表示され、「再試行」ボタンは表示されない | 原則-4, 原則-5（8章 Q1）、ユーザー決定 2026-11-16 | 確定 |

### 3.2 外観の変更

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| APS-A01 | `/settings` で「ダークモード」のスイッチをタップし、保存が成功した | スイッチがオンになる。アプリの配色が暗い配色になる（`Theme.of(context).brightness` が `Brightness.dark`）。`updateSettings` が1回、darkMode true・colorTheme `indigo` で呼ばれる | 概要 §ダークモード | 確定 |
| APS-A02 | ダークモードがオンの状態で `/settings` を開き、「ダークモード」のスイッチをタップし、保存が成功した | スイッチがオフになる。アプリの配色が明るい配色になる（`Theme.of(context).brightness` が `Brightness.light`）。`updateSettings` が1回、darkMode false で呼ばれる | 概要 §ダークモード | 確定 |
| APS-A03 | `/settings` で「カラーテーマ」のドロップダウンをタップした | 「indigo」「blue」「teal」「green」「orange」「pink」「purple」がこの順で表示される | 概要 §カラーテーマ | 確定 |
| APS-A04 | APS-A03 の後、「teal」をタップし、保存が成功した | ドロップダウンに「teal」が表示される。`updateSettings` が1回、colorTheme `teal`・darkMode false で呼ばれる。アプリの配色の `colorScheme.primary` が、「indigo」のときと違う色になる | 概要 §カラーテーマ | 確定 |
| APS-A05 | APS-A03 の後、今と同じ「indigo」をタップした | ドロップダウンに「indigo」が表示されたまま。アプリの配色の `colorScheme.primary` が変わらない | 概要 §カラーテーマ（同じ色を選んでも何も変わらない） | 確定 |
| APS-A06 | APS-A03 の後、ドロップダウンの外側をタップした | 一覧が閉じ、ドロップダウンに「indigo」が表示されたまま。`updateSettings` は呼ばれない | 原則-7 | 確定 |
| APS-A07 | `/settings` で「ダークモード」のスイッチをタップし、保存が `UnknownFailure` で失敗した | 設定画面の表示が残り（`ErrorScreen` は表示されない）、スイッチはオフのまま。スナックバーに「設定の保存に失敗しました」と表示される | 原則-1, 原則-2（8章 Q2）、ユーザー決定 2026-11-16 | 確定 |
| APS-A08 | APS-A03 の後、「teal」をタップし、保存が `UnknownFailure` で失敗した | 設定画面の表示が残り（`ErrorScreen` は表示されない）、ドロップダウンに「indigo」が表示されたまま。スナックバーに「設定の保存に失敗しました」と表示される | 原則-1, 原則-2（8章 Q2）、ユーザー決定 2026-11-16 | 確定 |
| APS-A09 | `/settings` で「ダークモード」のスイッチを、1回目の保存が終わる前に続けて2回タップした | 2回目の保存が終わった後、スイッチがオフ（元の値）になっている。最後に `updateSettings` に渡された darkMode が false | 原則-4（8章 Q3）、ユーザー決定 2026-11-16 | 確定 |
| APS-A10 | uid `u1` の設定がダークモードがオン、uid `u2` の設定がまだ保存されていない状態で、`u2` でログインして `/settings` を開いた | 「ダークモード」のスイッチがオフ、「カラーテーマ」のドロップダウンに「indigo」が表示される | 概要 §外観（ユーザーごとに保存する）、原則-9 | 確定 |
| APS-A11 | ダークモードがオンの状態で `/settings` を開き、カラーテーマで「teal」を選び、保存が成功した | `updateSettings` が1回、colorTheme `teal`・darkMode true で呼ばれる | 概要 §カラーテーマ（選ぶと設定を保存する） | 確定 |
| APS-A12 | カラーテーマが「teal」の状態で `/settings` を開き、「ダークモード」のスイッチをタップし、保存が成功した | `updateSettings` が1回、colorTheme `teal`・darkMode true で呼ばれる | 概要 §ダークモード（切り替えると設定を保存する） | 確定 |
| APS-A13 | uid `u1`（ダークモードがオン）でログインしてアプリの配色が暗い状態から、ログアウトし、uid `u2`（設定がまだ保存されていない）でログインした | アプリの配色が明るい配色になる（`Theme.of(context).brightness` が `Brightness.light`） | 概要 §外観（別のアカウントにログインすると、そのアカウントの設定で表示する） | 確定 |
| APS-A14 | APS-A07 と同じ失敗をした | アプリの配色が明るいまま（`Theme.of(context).brightness` が `Brightness.light`） | 原則-1（8章 Q2）、ユーザー決定 2026-11-16 | 確定 |
| APS-A15 | APS-A08 と同じ失敗をした | アプリの配色の `colorScheme.primary` が、保存前（indigo）の色のまま | 原則-1（8章 Q2）、ユーザー決定 2026-11-16 | 確定 |
| APS-A16 | uid `u1`（カラーテーマが「teal」）でログインしている状態から、ログアウトし、uid `u2`（設定がまだ保存されていない）でログインした | アプリの配色の `colorScheme.primary` が、indigo の配色の色になる | 概要 §外観（別のアカウントにログインすると、そのアカウントの設定で表示する） | 確定 |

### 3.3 ログアウト

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| APS-O01 | `/settings` で「ログアウト」をタップした | ダイアログが表示され、タイトル「ログアウト」、本文「ログアウトしますか？」、「キャンセル」「ログアウト」ボタンがこの順で表示される | 概要 §ログアウトの確認ダイアログ | 確定 |
| APS-O02 | APS-O01 のダイアログで「ログアウト」をタップし、ログアウトが成功した | ダイアログが閉じ、パスが `/login` になる。`pushBeforeSignOut` が1回呼ばれた後に、`signOut` が1回呼ばれる | 概要 §ログアウトの処理 | 確定 |
| APS-O03 | APS-O01 のダイアログで「キャンセル」をタップした | ダイアログが閉じ、パスは `/settings` のまま。`pushBeforeSignOut`・`signOut` は呼ばれない | 概要 §ログアウトの確認ダイアログ、原則-7 | 確定 |
| APS-O04 | APS-O01 のダイアログで、ダイアログの外側をタップした | ダイアログが閉じ、パスは `/settings` のまま。`signOut` は呼ばれない | 概要 §ログアウトの確認ダイアログ、原則-7 | 確定 |
| APS-O05 | APS-O01 のダイアログで、戻る操作をした | ダイアログが閉じ、パスは `/settings` のまま。`signOut` は呼ばれない | 概要 §ログアウトの確認ダイアログ、原則-7 | 確定 |
| APS-O06 | APS-O01 のダイアログで「ログアウト」を素早く2回タップした | `signOut` が1回だけ呼ばれる | 原則-4 | 確定 |
| APS-O07 | APS-O01 のダイアログで「ログアウト」をタップし、`pushBeforeSignOut` の応答を待っている | 画面全体にローディングが表示され、ボトムナビ・設定の項目をタップしても反応しない | 原則-5（8章 Q4）、ユーザー決定 2026-11-16 | 確定 |
| APS-O08 | APS-O01 のダイアログで「ログアウト」をタップし、`signOut` が `UnknownFailure` で失敗した | パスは `/settings` のまま。スナックバーに「ログアウトに失敗しました」と表示される | 原則-2（8章 Q4）、ユーザー決定 2026-11-16 | 確定 |
| APS-O11 | APS-O08 の後、もう一度「ログアウト」→ ダイアログの「ログアウト」をタップし、ログアウトが成功した | パスが `/login` になる | 原則-3（8章 Q4）、ユーザー決定 2026-11-16 | 確定 |

### 3.4 エラー種別ごとの扱い

代表の `UnknownFailure` は APS-D05・APS-A07・APS-A08・APS-O08 で定める。ほかの Failure は発生しない（7章）。

---

## 4. 状態管理仕様（SettingsViewModel）

| ID | 条件 | 期待される状態 | 対応する画面仕様 | 根拠 | 確定度 |
|----|------|----------------|------------------|------|--------|
| APS-V01 | userId `u1` の ViewModel を作り、`getSettings` の応答を待っている | 状態が `AsyncLoading` | APS-D04 | 概要 §読み込み中・読み込みに失敗したとき | 確定 |
| APS-V02 | userId `u1` の ViewModel を作り、`getSettings` が `Right(UserSettings(colorTheme: 'teal', darkMode: true))` を返した | 状態が `AsyncData(UserSettings(colorTheme: 'teal', darkMode: true))`。`GetSettingsUseCase` が1回、userId `u1` で呼ばれる | APS-D02 | 概要 §外観、原則-9 | 確定 |
| APS-V03 | userId `u1` の ViewModel を作り、`getSettings` が `Left(UnknownFailure)` を返した | 状態が `AsyncError(UnknownFailure)` | APS-D05 | 概要 §読み込み中・読み込みに失敗したとき | 確定 |
| APS-V04 | 状態が `AsyncData(UserSettings(colorTheme: 'indigo', darkMode: false))` で `updateSettings(UserSettings(colorTheme: 'indigo', darkMode: true))` を呼び、UseCase が `Right` を返した | 状態が `AsyncData(UserSettings(colorTheme: 'indigo', darkMode: true))`。`UpdateSettingsUseCase` が1回、userId `u1` と渡した設定で呼ばれる | APS-A01 | 概要 §ダークモード | 確定 |
| APS-V05 | 状態が `AsyncData(UserSettings(colorTheme: 'indigo', darkMode: false))` で `updateSettings(UserSettings(colorTheme: 'teal', darkMode: false))` を呼び、UseCase が `Right` を返した | 状態が `AsyncData(UserSettings(colorTheme: 'teal', darkMode: false))` | APS-A04 | 概要 §カラーテーマ | 確定 |
| APS-V06 | 状態が `AsyncData(UserSettings(colorTheme: 'indigo', darkMode: false))` で `updateSettings(UserSettings(colorTheme: 'indigo', darkMode: true))` を呼び、UseCase が `Left(UnknownFailure)` を返した | 状態が `AsyncData(UserSettings(colorTheme: 'indigo', darkMode: false))` のまま。失敗を画面に伝える State の項目は8章 Q2 で決める | APS-A07, APS-A08 | 原則-1（8章 Q2）、ユーザー決定 2026-11-16 | 確定 |
| APS-V07 | userId `u2` の ViewModel を作った | `GetSettingsUseCase` が userId `u2` で呼ばれる | APS-A10 | 概要 §外観（ユーザーごと）、原則-9 | 確定 |

---

## 5. リポジトリ契約

`SettingsRepository` の契約は STG で、ログアウトの `AuthRepository.signOut` は Firebase Authentication に委ねる。この仕様書では項目を作らない。

## 6. ユースケース

| ID | 対象 | 条件 | 期待される結果 | 根拠 | 確定度 |
|----|------|------|----------------|------|--------|
| APS-O09 | `SignOutUseCase` | 呼んだ | `SyncRepository.pushBeforeSignOut` が1回呼ばれ、それが終わった後に `AuthRepository.signOut` が1回呼ばれる。戻り値は `signOut` の戻り値と同じ | 概要 §ログアウトの処理、SYN-O | 確定 |
| APS-O10 | `SignOutUseCase` | `pushBeforeSignOut` が終わり、`signOut` が `Left(UnknownFailure)` を返した | 戻り値が `Left(UnknownFailure)` | 概要 §ログアウトの処理 | 確定 |
| APS-O12 | `SignOutUseCase` | `pushBeforeSignOut` が未送信の変更を2件残して終わった（戻り値 2） | `AuthRepository.signOut` が1回呼ばれる。戻り値は `signOut` の戻り値と同じ | 概要 §ログアウトの処理（送信しきれなかった変更は端末に残す） | 確定 |
| APS-O13 | `SignOutUseCase` | `pushBeforeSignOut` が例外を投げた | `AuthRepository.signOut` が1回呼ばれる。例外は呼び出し元に伝わらない | 概要 §ログアウトの処理（8章 Q5）、ユーザー決定 2026-11-16 | 確定 |

`GetSettingsUseCase`・`UpdateSettingsUseCase` は委譲のみ（Repository を呼ぶだけ）。

---

## 7. 対象外

- **外観の読み取り・保存の `NotFoundFailure` / `NetworkFailure` / `AuthFailure`**: 端末内のデータベースだけを使い、設定がなければ既定値を返すため発生しない（STG 7章）
- **ログアウトの `NotFoundFailure` / `NetworkFailure` / `AuthFailure`**: Firebase Authentication のログアウトは端末内の処理で通信しないため、この3種類は返らない。失敗は `UnknownFailure` だけを扱う（APS-O08）
- **未送信の変更の送信の中身・端末内のデータを削除しないこと**: SYN-O で定める
- **退会・「このアプリについて」・アカウント情報**: 1章の表の仕様書で定める
- **ドロップダウンの色の丸の色**: Widget テストで観測しないため、項目を作らない
- **ボトムナビゲーションバー**: SHL で定める

## 8. 要確認事項

| ID | 論点 | 案 | 推奨 | 決定 |
|----|------|----|------|------|
| Q1（APS-D06, D08, D09） | 設定の読み込みに失敗したときの `ErrorScreen` の「再試行」を押したときの動作。概要設計書では未決 | A: 設定を読み直す（他の画面の「再試行」と同じ） ／ B: 何もしない | A（ホーム画面・単語一覧画面・成績表画面とそろえる） | 決定: 案A（2026-11-16） |
| Q2（APS-A07, A08, A14, A15, V06） | 外観の保存が失敗したときの表示。概要設計書では未決 | A: 設定画面の表示を残し、スイッチ・ドロップダウンは保存前の値のまま、スナックバー「設定の保存に失敗しました」を表示する。State に失敗の通知の項目を足す ／ B: 設定画面を `ErrorScreen` に置き換える | A（原則-1・原則-2） | 決定: 案A（2026-11-16） |
| Q3（APS-A09） | ダークモードのスイッチを、保存が終わる前に続けて切り替えたときの動作 | A: 最後に表示した値（2回切り替えたら元の値）で保存されるようにする ／ B: 保存中はスイッチを押せないようにする | A（原則-4・原則-7。ユーザーが最後に見た値と保存した値を一致させる。APS-A09 はこの案で書いている） | 決定: 案A（2026-11-16） |
| Q4（APS-O07, O08, O11） | ログアウトの処理中の表示と、ログアウトに失敗したときの表示。概要設計書では未決 | A: ログアウトの処理の全体（未送信の変更の送信とログアウト）の間は、画面全体にローディングを表示して操作を止める。ログアウトに失敗したら設定画面のまま、スナックバー「ログアウトに失敗しました」を表示する ／ B: 表示せず、失敗してもログイン画面へ移動する | A（原則-2・原則-5） | 決定: 案A（2026-11-16） |
| Q5（APS-O13） | ログアウト前の未送信の変更の送信が、端末内のデータベースのエラーなどで例外になったときの動作。概要設計書に記載がない | A: 送信できなかった変更は端末に残したまま、ログアウトを続ける ／ B: ログアウトをやめて、失敗を伝える | A（未送信の変更は次のログイン時に送信されるため、ログアウトを妨げない） | 決定: 案A（2026-11-16） |

---

## 9. 網羅表

### 9.1 概要設計書との対応

| 概要設計書（§見出し：要点） | 仕様 ID ／ 振り分け |
|---------------------------|--------------------|
| §画面への入り方：ボトムナビ | 7章（SHL） |
| §画面構成：AppBar「設定」・項目の並び | APS-D01 |
| §画面構成：このアプリについて・アカウント情報・退会 | 7章（LGL・ACI・ACD） |
| §読み込み中 | APS-D04, APS-V01 |
| §読み込みに失敗：ErrorScreen | APS-D05, APS-V03 |
| §読み込みに失敗：再試行 | 8章（決定済み）Q1（APS-D06, D08, D09） |
| §読み込み：通信・認証エラーは起きない | 7章 |
| §外観：ユーザーごとに保存・アカウントを変えるとその設定で表示 | APS-A10, APS-A13, APS-A16, APS-V07 |
| §外観：既定はオフ・indigo | APS-D03 |
| §ダークモード：今の設定を表示 | APS-D01, APS-D02, APS-V02 |
| §ダークモード：切り替えで保存・配色をすぐ変える | APS-A01, APS-A02, APS-A12, APS-V04 |
| §カラーテーマ：今の色を表示 | APS-D01, APS-D02 |
| §カラーテーマ：7色をこの順で | APS-A03 |
| §カラーテーマ：選ぶと保存・配色をすぐ変える | APS-A04, APS-A11, APS-V05 |
| §カラーテーマ：同じ色では何も変わらない | APS-A05 |
| §保存に失敗したとき | 8章（決定済み）Q2（APS-A07, A08, A14, A15, V06） |
| §ログアウト：確認ダイアログの構成 | APS-O01 |
| §ログアウトの確認ダイアログ：ログアウト・キャンセル・外側・戻る | APS-O02, APS-O03, APS-O04, APS-O05 |
| §ログアウトの処理：未送信の変更を送信してからログアウト | APS-O02, APS-O09 |
| §ログアウトの処理：送信しきれなかった変更は端末に残す | APS-O12、送信の失敗は 8章（決定済み）Q5（APS-O13） |
| §ログアウトの処理：ログイン画面へ | APS-O02 |
| §ログアウトの処理：端末内のデータを削除しない | 7章（SYN-O） |
| §ログアウトの処理：処理中・失敗の表示 | 8章（決定済み）Q4（APS-O07, O08, O11） |
| §画面遷移 | APS-O02、アカウント情報は 7章（ACD-D17） |

### 9.2 操作 × 観点

| 操作 | 成功 | Unknown | NotFound | Network | Auth | キャンセル | 外側タップ | 処理中（無効化） | 二重操作 | 対象の不在 | 同じ値 | 入力の境界 |
|-----|-----|---------|----------|---------|------|-----------|-----------|----------------|---------|-----------|--------|-----------|
| 初期読み込み | APS-D01〜D03, V02 | APS-D05, D06, D08, V03 | 7章 | 7章 | 7章 | — 操作なし | — | APS-D04, V01 | — | APS-D03（未保存は既定値） | — | — |
| ダークモードの切り替え | APS-A01, A02, A12, A13, V04 | APS-A07, A14, V06 | 7章 | 7章 | 7章 | — 確認なし | — | 8章（決定済み）Q3 | APS-A09 | — | — オン・オフしかない | — 入力なし |
| カラーテーマの選択 | APS-A04, A11, A16, V05 | APS-A08, A15, V06 | 7章 | 7章 | 7章 | APS-A06 | APS-A06 | — 選ぶと一覧が閉じる | — 一覧が閉じるため続けて選べない | — | APS-A05 | — 決められた7色だけ |
| ログアウト | APS-O02, O09, O12 | APS-O08, O10, O11, O13 | 7章 | 7章 | 7章 | APS-O03, O05 | APS-O04 | APS-O07 | APS-O06 | — | — | — 入力なし |

### 9.3 操作 × 共通原則

| 操作 | 原則-1 | 原則-2 | 原則-3 | 原則-4 | 原則-5 | 原則-6 | 原則-7 | 原則-8 | 原則-9 | 原則-10 | 原則-11 |
|-----|-------|-------|-------|-------|-------|-------|-------|-------|-------|--------|--------|
| 初期読み込み | — 初期読み込みは ErrorScreen（APS-D05） | APS-D05 | — | — | APS-D04 | — | — | — | APS-V02, V07 | APS-D07 | 7章 |
| ダークモードの切り替え | APS-A07 | APS-A07 | — 入力なし（元の値を保つのは APS-A07） | APS-A09 | — 端末内の書き込みで瞬時のため表示しない | — 取り消せる操作 | — 確認なし | — 決められた値だけ | APS-A10 | — | 7章 |
| カラーテーマの選択 | APS-A08 | APS-A08 | — | — 一覧が閉じる | — 同上 | — 取り消せる操作 | APS-A06 | — 決められた値だけ | APS-A10 | — | 7章 |
| ログアウト | — 画面を移る操作 | APS-O08 | — 入力なし | APS-O06 | APS-O07 | APS-O01（確認ダイアログ） | APS-O03〜O05 | — | — | — | 7章（通信エラーは起きない） |
