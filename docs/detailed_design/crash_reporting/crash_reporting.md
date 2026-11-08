---
feature: クラッシュ検知・Slack 通知・利用状況の分析
prefix: CRS
status: approved
targets:
  - lib/core/utils/crash_reporting.dart
  - lib/core/utils/screen_view_tracking.dart
  - lib/presentation/legal/legal_consent_view_model.dart
  - lib/domain/services/crash_reporter.dart
  - lib/domain/services/analytics_reporter.dart
  - functions/src/crash_alert.ts
kinds:
  I: アプリ側の収集（収集の有効・無効、エラーの報告、uid の付け外し）
  S: Slack 通知（Cloud Functions）
  F: 非致命的エラーの報告（Repository・同期処理）
  A: 利用状況の記録（Analytics）
updated: 2026-11-08
---

# クラッシュ検知・Slack 通知・利用状況の分析 振る舞い仕様書

## 1. 機能概要

アプリで受け止められなかったエラーを Firebase Crashlytics にクラッシュとして記録し、ログイン中のユーザーの uid を付ける。
Crashlytics が新しいクラッシュ・再発・急増と判定したら、Cloud Functions の関数が日本語の文面を作り、Slack の Incoming Webhook に投稿する。
Repository で `UnknownFailure` になったエラーと、裏で動く同期処理の想定外の失敗は、非致命的エラーとして記録する。
Firebase Analytics で、自動で集まる利用状況と、見た画面を記録する。
画面はない。

## 2. データ定義

### 2.1 報告用のインターフェース（CrashReporter）

アプリから Crashlytics への報告口。テストでは Fake に差し替え、呼ばれた回数と引数を観測する。
Mock モード（`USE_MOCKS=true`）では、何もしない実装を Provider から渡す。

| メソッド | 引数 | 説明 |
|---------|------|------|
| `setCollectionEnabled` | `bool enabled` | クラッシュ情報を集めるかを設定する |
| `recordError` | `Object error`、`StackTrace? stack`、`bool fatal` | エラーを記録する。`fatal: true` はクラッシュとして記録する |
| `setUserIdentifier` | `String id` | 以後の記録に付けるユーザーの識別子を設定する。空文字は「付けない」 |

### 2.1.1 利用状況の記録用のインターフェース（AnalyticsReporter）

アプリから Analytics への記録口。テストでは Fake に差し替え、呼ばれた回数と引数を観測する。
Mock モードでは、何もしない実装を Provider から渡す。ユーザーの識別子を設定するメソッドは持たない（uid を付けないため）。

| メソッド | 引数 | 説明 |
|---------|------|------|
| `setCollectionEnabled` | `bool enabled` | 利用状況を集めるかを設定する |
| `logScreenView` | `String screenName` | 画面を見たことを記録する |

### 2.2 入力ルール

該当なし（利用者が入力する項目はない）

### 2.3 収集の初期化

起動時に1回呼ぶ入口。引数は次の4つで、テストではこれらを指定して呼ぶ。

| 引数 | 型 | 説明 |
|-----|----|------|
| `isDebug` | bool | デバッグビルドか（アプリは `kDebugMode` を渡す） |
| `useMocks` | bool | Mock モードか（アプリは `USE_MOCKS` を渡す） |
| `reporter` | CrashReporter | 報告口 |
| `analytics` | AnalyticsReporter | 利用状況の記録口 |

- 「収集の対象のビルド」は `isDebug` と `useMocks` がともに `false` の場合を指す。Crashlytics と Analytics の両方に同じ判定を使う
- 収集の初期化は、収集の対象のビルドかどうかによらず、`setCollectionEnabled(false)` を呼ぶ（同意を確認できるまで送らない。2.3.4）
- 収集の対象のビルドの場合、Flutter の処理中のエラーを受ける `FlutterError.onError` と、Flutter の処理の外のエラーを受ける `PlatformDispatcher.instance.onError` を、報告する処理に置き換える

### 2.3.1 ユーザーの識別子の同期

- ログイン中のユーザー（`currentUserProvider` の値。`AppUser?`、未ログインは `null`）が変わるたびに、`reporter` の `setUserIdentifier` を呼ぶ処理。起動時は、その時点の値で1回呼ぶ
- テストでは、ログイン中のユーザーの値を Fake の認証状態で与え、Fake の `CrashReporter` への `setUserIdentifier` の呼び出しを観測する
- この処理は `isDebug`・`useMocks` を受け取らず、収集の有効・無効によらず同じ動作をする（無効の場合は SDK の側で送られない。Mock モードは何もしない実装を使う）

### 2.3.2 見た画面の記録

- 入口は「見た画面の記録の開始」。引数は `router`（アプリの GoRouter）と `analytics`（AnalyticsReporter）。テストでは、テスト用のルートを持つ GoRouter を渡し、`go`・`pop` で表示中のルートを変えて駆動する
- 開始した時点で、表示中のルートのパスのパターンで `logScreenView` を1回呼ぶ。その後は、GoRouter の表示中のルート（パスを持つルート）が変わるたびに呼ぶ
- 画面の名前は、表示中のルートのパスのパターン（GoRouter のルート定義の `path` をつないだもの。例: `/folder/:folderId`）
- 表示中のルートのパスのパターンが、直前の記録と同じ場合は記録しない（直前と比べるだけで、それより前の記録とは比べない）
- ダイアログ・ボトムシートは、Navigator に積まれてもパスを持たず、GoRouter の表示中のルートを変えないため、記録の対象にならない
- リダイレクトは、表示中のルートが決まる前に解決されるため、リダイレクトの後に表示されたルートだけが記録される
- この処理は `isDebug`・`useMocks` を受け取らない（無効の場合は SDK の側で送られない。Mock モードは何もしない実装を使う）

### 2.3.3 非致命的エラーの報告

- Repository の実装は、例外を受けて `Left(UnknownFailure)` を返すとき、その例外とスタックトレースで `recordError(例外, スタックトレース, fatal: false)` を1回呼ぶ。例外を受けずに `UnknownFailure` を返す場合は報告しない（8章 Q10）
- `NetworkFailure`・`AuthFailure`・`NotFoundFailure` を返すときは呼ばない
- 同期処理（`SyncService`）は、取得・送信が失敗したとき、原因の例外が「通信に関するもの」でなければ `recordError(例外, スタックトレース, fatal: false)` を1回呼ぶ。「通信に関するもの」は次のどれか
  - 時間切れ（`TimeoutException`）
  - 接続できない（`SocketException`）
  - Firestore の `FirebaseException` で、`code` が `unavailable` または `deadline-exceeded`
- 同期処理は、`FirebaseException` の `code` が次の場合も報告しない（8章 Q11）。それ以外の `code`（`permission-denied`・`not-found` 等）は報告する
  - `unauthenticated`（ログイン切れ。Repository の `AuthFailure` にあたる）
  - `aborted`・`resource-exhausted`・`cancelled`（一時的な失敗で、次の同期でやり直されるため）
- 1回の同期（取得または送信）は、最初の失敗で止まる（SYN-S14・SYN-P32）ため、報告は1回の同期につき最大1回
- Repository の実装と同期処理は `isDebug`・`useMocks` を受け取らず、常に報告を呼ぶ（収集が無効の場合は SDK の側で送られない。Mock モードは何もしない実装を使う）

### 2.3.4 同意と収集の開始

- 入口は「収集の切り替え」。引数は `isDebug`・`useMocks`・`consented`（同意済みと確認できているか）・`reporter`・`analytics`
- `isDebug` と `useMocks` がともに `false` で、`consented` が `true` の場合だけ、`setCollectionEnabled(true)` を呼ぶ。それ以外は `setCollectionEnabled(false)` を呼ぶ
- `consented` は `LegalConsentState` の項目で、初期値は `false`。アプリは値が変わるたびに収集の切り替えを呼ぶ
- `consented` は、ログイン中のユーザーが利用規約とプライバシーポリシーの**両方**の現行の版に同意済みと確認できている場合に `true` になる（プライバシーポリシー第5条が両方への同意を利用の条件にしているため。8章 Q13）
- `FlutterError.onError`・`PlatformDispatcher.instance.onError` の置き換えは `consented` によらない。`consented` が `false` の間に `recordError` が呼ばれた場合の扱いは SDK の動作（8章 Q16）

### 2.3.5 SQLite のエラーの報告

- 報告する `error` が sqflite の `DatabaseException` の場合は、そのまま渡さず、SQLite の結果コードだけを持つエラーに置き換えて `recordError` に渡す。置き換えは `CrashReporter` を呼ぶ前に行い、`CrashReporter` の Fake が受け取る引数で観測する
- 置き換えたエラーの文字列は `DatabaseException(resultCode: <結果コード>)`。結果コードが無い場合は `DatabaseException(resultCode: unknown)`
- 他のエラーは置き換えない。スタックトレースと `fatal` は置き換えの有無で変わらない

### 2.4 Crashlytics のアラート（関数が受け取るもの）

| 項目 | 型 | 説明 |
|------|----|------|
| `appId` | string | Firebase のアプリ ID。iOS は `:ios:`、Android は `:android:` を含む |
| `issue.title` | string | 発生箇所（ファイル名・関数名など）。本文の「発生箇所」に載せる（8章 Q12） |
| `issue.subtitle` | string | 問題の名前（例外の型・エラーのメッセージなど）。本文の「問題」に載せる（8章 Q12） |
| `issue.appVersion` | string | 問題が起きたアプリのバージョン |
| `resolveTime` | string（ISO8601） | 再発のみ。解決済みにした日時 |
| `crashCount` | number | 急増のみ。件数 |
| `crashPercentage` | number | 急増のみ。割合（%） |
| `firstVersion` | string | 急増のみ。最初に起きたバージョン |

### 2.5 Slack への投稿

- Secret Manager の `SLACK_WEBHOOK_URL` に、`Content-Type: application/json` で `{"text": "<本文>"}` を POST する
- Slack が HTTP 200〜299 を返したら成功、それ以外の状態コード・接続の失敗は失敗とする
- 本文は改行（`\n`）区切りの複数行
- Slack が 3xx を返した場合は、HTTP クライアントの標準どおりリダイレクト先に進み、最後の応答の状態コードで判定する
- 本文に入れるアラートの値は、次の順で加工する（8章 Q9）
  1. 値の中の改行（`\r\n`・`\n`・`\r`）を半角スペース1つに置き換える（行がずれないようにするため）
  2. `&` → `&amp;`、`<` → `&lt;`、`>` → `&gt;` に置き換える（`&` を最初に置き換える。Slack の書式で、リンクやチャンネル全員への呼び出しにならないようにするため）
  3. 値が無い、または加工後に空文字・空白だけ（半角・全角スペース）の値は「（不明）」と表示する。数値（`crashCount`・`crashPercentage`）が無い場合も「（不明）」と表示する
- `crashCount` は、桁区切りを付けずに整数で書く（`1234` は「1234」）
- `crashPercentage` は、小数第2位で四捨五入（ちょうど半分は切り上げ）して小数第1位までにし、末尾の「.0」は書かない（`1.5384…` は「1.5」、`2` は「2」、`0.0000001` は「0」）（8章 Q8）
- 解決済みにした日時（`resolveTime`）は、日本時間（UTC+9）に直して「YYYY/MM/DD HH:mm」で書く。秒は切り捨てる。値が無い、日時として読めない、タイムゾーン（`Z` や `+09:00`）が書かれていない場合は「不明」と書く（タイムゾーンの無い値は、動く環境によって解釈が変わるため）（8章 Q6）
- 本文の1行目の先頭に付ける環境の表示は、関数が動いているプロジェクト ID から決める

| プロジェクト ID | 環境の表示 |
|---------------|----------|
| `word-pods-prod` | 「【本番】」 |
| `word-pods-dev` | 「【開発】」 |
| それ以外 | 「【<プロジェクト ID>】」 |
| 取得できない（値が無い・空文字） | 「【不明】」 |

- OS の表示は `appId` から決める

| `appId` | OS の表示 |
|---------|----------|
| `:ios:` を含む | 「iOS」 |
| `:android:` を含む | 「Android」 |
| どちらも含まない | 「不明」 |

---

## 3. 画面仕様

該当なし（画面はない）

---

## 4. 状態管理仕様

該当なし（ViewModel はない）

---

## 5. リポジトリ契約

該当なし（`CrashReporter` は `Either<Failure, T>` を返す Repository ではない。記録の失敗でアプリの動作を変えないため、戻り値を持たない。振る舞いは6章で定める）

## 6. ユースケース・処理

### 6.1 アプリ側の収集（CrashReporting）

観測点は、Fake の `CrashReporter` が呼ばれた回数と引数、`FlutterError.onError` と `PlatformDispatcher.instance.onError` に設定されている処理と、その戻り値。

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| CRS-I01 | `isDebug: false`・`useMocks: false` で収集を初期化した | `setCollectionEnabled(true)` が1回呼ばれる | 概要 §クラッシュ情報を集めるとき・集めないとき | 廃止（同意を確認するまで集めないことになったため。CRS-I23 に置き換え。8章 Q13） |
| CRS-I02 | `isDebug: true`・`useMocks: false` で収集を初期化した | `setCollectionEnabled(false)` が1回呼ばれる | 概要 §クラッシュ情報を集めるとき・集めないとき | 確定 |
| CRS-I03 | `isDebug: false`・`useMocks: true` で収集を初期化した | `setCollectionEnabled(false)` が1回呼ばれる | 概要 §クラッシュ情報を集めるとき・集めないとき | 確定 |
| CRS-I04 | `isDebug: true`・`useMocks: true` で収集を初期化した | `setCollectionEnabled(false)` が1回呼ばれる | 概要 §クラッシュ情報を集めるとき・集めないとき | 確定 |
| CRS-I05 | `isDebug: false`・`useMocks: false` で収集を初期化した後、`FlutterError.onError` にエラー E・スタックトレース S のエラー情報が渡された | `recordError(E, S, fatal: true)` が1回呼ばれる | 概要 §集めるもの | 確定 |
| CRS-I06 | `isDebug: false`・`useMocks: false` で収集を初期化した後、`PlatformDispatcher.instance.onError` にエラー E・スタックトレース S が渡された | `recordError(E, S, fatal: true)` が1回呼ばれる。`PlatformDispatcher.instance.onError` は `true`（処理済み）を返す | 概要 §集めるもの | 確定 |
| CRS-I07 | `FlutterError.onError` に処理 H が設定された状態で、`isDebug: true`・`useMocks: false` で収集を初期化した | `FlutterError.onError` は H のまま（エラーは今までどおりコンソールに出る）。`recordError` は0回 | 概要 §クラッシュ情報を集めるとき・集めないとき | 確定 |
| CRS-I08 | `PlatformDispatcher.instance.onError` に処理 P が設定された状態で、`isDebug: true`・`useMocks: false` で収集を初期化した | `PlatformDispatcher.instance.onError` は P のまま。`recordError` は0回 | 概要 §クラッシュ情報を集めるとき・集めないとき | 確定 |
| CRS-I09 | `FlutterError.onError` に処理 H が設定された状態で、`isDebug: false`・`useMocks: true` で収集を初期化した | `FlutterError.onError` は H のまま。`recordError` は0回 | 概要 §クラッシュ情報を集めるとき・集めないとき | 確定 |
| CRS-I10 | `PlatformDispatcher.instance.onError` に処理 P が設定された状態で、`isDebug: false`・`useMocks: true` で収集を初期化した | `PlatformDispatcher.instance.onError` は P のまま。`recordError` は0回 | 概要 §クラッシュ情報を集めるとき・集めないとき | 確定 |
| CRS-I11 | 未ログインの状態で起動した | `setUserIdentifier("")` が1回呼ばれる | 概要 §集めるもの | 確定 |
| CRS-I12 | 未ログインの状態から、uid が「u1」のユーザーでログイン済みになった | 最後に呼ばれた `setUserIdentifier` の引数が「u1」 | 概要 §集めるもの | 確定 |
| CRS-I13 | uid が「u1」のユーザーでログイン済みの状態から、ログアウトした | 最後に呼ばれた `setUserIdentifier` の引数が「」（空文字） | 概要 §集めるもの | 確定 |
| CRS-I14 | uid が「u1」のユーザーでログイン済みの状態から、ログアウトし、uid が「u2」のユーザーでログイン済みになった | 最後に呼ばれた `setUserIdentifier` の引数が「u2」 | 概要 §集めるもの | 確定 |
| CRS-I15 | uid が「u1」、メールアドレスが「a@example.com」、表示名が「Taro」のユーザーでログイン済みになった | `setUserIdentifier` の引数に「a@example.com」または「Taro」を含む呼び出しが0回 | 概要 §集めるもの（メールアドレス・表示名を送らない） | 確定 |
| CRS-I16 | uid が「u1」のユーザーでログイン済みの状態で、同じ「u1」のユーザー情報がもう一度届いた（メールアドレスの確認状態が変わった等） | 最後に呼ばれた `setUserIdentifier` の引数が「u1」 | 概要 §集めるもの | 確定 |
| CRS-I17 | uid が「u1」のユーザーでログイン済みのまま起動した | 最後に呼ばれた `setUserIdentifier` の引数が「u1」 | 概要 §集めるもの | 確定 |
| CRS-I18 | uid が「u1」でメールアドレスが未確認のユーザーで、ログイン済みになった | 最後に呼ばれた `setUserIdentifier` の引数が「u1」 | 概要 §集めるもの（確認待ちの間もログイン済みのため） | 確定 |
| CRS-I19 | `isDebug: false`・`useMocks: false` で収集を初期化し、`recordError` が例外を投げる状態で、`FlutterError.onError` にエラー情報が渡された | `FlutterError.onError` の呼び出しから例外が出ない | 原則-10、ユーザー決定 2026-11-08 | 確定 |
| CRS-I20 | `isDebug: false`・`useMocks: false` で収集を初期化し、`recordError` が例外を投げる状態で、`PlatformDispatcher.instance.onError` にエラーが渡された | `PlatformDispatcher.instance.onError` は例外を出さずに `true` を返す | 原則-10、ユーザー決定 2026-11-08 | 確定 |
| CRS-I21 | `setCollectionEnabled` が例外を投げる状態で、`isDebug: false`・`useMocks: false` で収集を初期化した | 初期化の呼び出しから例外が出ない（起動が続く）。`FlutterError.onError` と `PlatformDispatcher.instance.onError` は報告する処理に置き換わっている（クラッシュの記録は続く）。`analytics` の `setCollectionEnabled(false)` は1回呼ばれる | 原則-10、ユーザー決定 2026-11-08 | 確定 |
| CRS-I22 | 未ログインの状態で起動した後、`setUserIdentifier` が例外を投げる状態にして、uid が「u1」のユーザーでログイン済みになった | ユーザーの識別子の同期から例外が出ない | 原則-10、ユーザー決定 2026-11-08 | 確定 |
| CRS-I23 | `isDebug: false`・`useMocks: false` で収集を初期化した | `setCollectionEnabled(false)` が1回呼ばれる。`setCollectionEnabled(true)` は0回 | 2.3.4、8章 Q13、ユーザー決定 2026-11-08 | 確定 |
| CRS-I24 | `isDebug: false`・`useMocks: false`・`consented: true` で収集を切り替えた | `reporter` の `setCollectionEnabled(true)` が1回呼ばれる | 2.3.4、8章 Q13、ユーザー決定 2026-11-08 | 確定 |
| CRS-I25 | `isDebug: false`・`useMocks: false`・`consented: false` で収集を切り替えた | `reporter` の `setCollectionEnabled(false)` が1回呼ばれる | 2.3.4、8章 Q13、ユーザー決定 2026-11-08 | 確定 |
| CRS-I26 | `isDebug: true`・`useMocks: false`・`consented: true` で収集を切り替えた | `reporter` の `setCollectionEnabled(false)` が1回呼ばれる | 概要 §クラッシュ情報を集めるとき・集めないとき、2.3.4 | 確定 |
| CRS-I27 | `isDebug: false`・`useMocks: true`・`consented: true` で収集を切り替えた | `reporter` の `setCollectionEnabled(false)` が1回呼ばれる | 概要 §クラッシュ情報を集めるとき・集めないとき、2.3.4 | 確定 |
| CRS-I28 | `reporter` の `setCollectionEnabled` が例外を投げる状態で、`isDebug: false`・`useMocks: false`・`consented: true` で収集を切り替えた | 収集の切り替えから例外が出ない。`analytics` の `setCollectionEnabled(true)` は1回呼ばれる | 原則-10、8章 Q7 | 確定 |
| CRS-I29 | ログイン前の `LegalConsentViewModel` の状態を読んだ | `consented` は `false` | 2.3.4、8章 Q13 | 確定 |
| CRS-I30 | uid「u1」でログイン済みの状態で判定し、同意が不要（現行の版に同意済み）だった | `phase` は `idle`、`consented` は `true` | 2.3.4、8章 Q13 | 確定 |
| CRS-I31 | uid「u1」でログイン済みの状態で判定し、プライバシーポリシーへの同意が必要だった | `phase` は `required`、`consented` は `false` | 2.3.4、8章 Q13 | 確定 |
| CRS-I32 | 同意ダイアログの表示中に両方をチェックして「同意する」を呼び、`LegalAcceptResult.accepted` が返った | `phase` は `idle`、`consented` は `true` | 2.3.4、8章 Q13 | 確定 |
| CRS-I33 | 同意ダイアログの表示中に「同意する」を呼び、送信が `UnknownFailure` で失敗した | `phase` は `required`、`consented` は `false` | 2.3.4、8章 Q13 | 確定 |
| CRS-I34 | `consented` が `true` の状態で、判定が `UnknownFailure` で失敗した | `phase` は `idle`、`consented` は `true` のまま | 8章 Q15、ユーザー決定 2026-11-08 | 確定 |
| CRS-I35 | `consented` が `true` の状態で、もう一度判定し、改定によりプライバシーポリシーへの同意が必要だった | `phase` は `required`、`consented` は `false` | 2.3.4、概要（legal_consent）§同意が必要かの判定 | 確定 |
| CRS-I36 | `consented` が `true` の状態で、ログアウトした（ログイン中のユーザーが `null` になった） | `consented` は `false` | 2.3.4、8章 Q13 | 確定 |
| CRS-I37 | `consented` が `false` のまま、一度も同意済みと確認できていない状態で、判定が `UnknownFailure` で失敗した | `phase` は `idle`、`consented` は `false` のまま | 8章 Q15、ユーザー決定 2026-11-08 | 確定 |
| CRS-I38 | `isDebug: false`・`useMocks: false` で収集を初期化した後、`FlutterError.onError` に、SQL「INSERT INTO words」・引数「secret」・結果コード 1555 の `DatabaseException` のエラー情報が渡された | `recordError` が1回呼ばれる。第1引数の文字列は `DatabaseException(resultCode: 1555)` で、「INSERT」「secret」を含まない。第2引数は渡したスタックトレース。`fatal` は `true` | 概要 §集めるもの（単語などの入力内容を送らない）、2.3.5、8章 Q14 | 確定 |
| CRS-I39 | `isDebug: false`・`useMocks: false` で収集を初期化した後、`PlatformDispatcher.instance.onError` に、SQL「INSERT INTO words」・引数「secret」・結果コード 1555 の `DatabaseException` が渡された | `recordError` が1回呼ばれる。第1引数の文字列は `DatabaseException(resultCode: 1555)` で、「INSERT」「secret」を含まない。第2引数は渡したスタックトレース。`fatal` は `true` | 概要 §集めるもの（単語などの入力内容を送らない）、2.3.5、8章 Q14 | 確定 |
| CRS-I40 | uid「u1」でログイン済みの状態で判定し、利用規約への同意だけが必要だった | `phase` は `required`、`consented` は `false` | 2.3.4、8章 Q13 | 確定 |
| CRS-I41 | uid「u1」でログイン済みの状態で判定し、利用規約とプライバシーポリシーの両方への同意が必要だった | `phase` は `required`、`consented` は `false` | 2.3.4、8章 Q13 | 確定 |
| CRS-I42 | 利用規約だけの同意ダイアログの表示中にチェックして「同意する」を呼び、`LegalAcceptResult.accepted` が返った | `phase` は `idle`、`consented` は `true` | 2.3.4、LGL-V22 | 確定 |
| CRS-I43 | uid「u1」の判定中にログアウトし、その後に判定が「同意は不要」を返した | `consented` は `false` のまま | 原則-9、LGL-V34 | 確定 |
| CRS-I44 | uid「u1」の同意の送信中にログアウトし、その後に送信が `LegalAcceptResult.accepted` を返した | `consented` は `false` のまま | 原則-9、LGL-V41 | 確定 |
| CRS-I45 | uid「u1」で `consented` が `true` の状態からログアウトし、uid「u2」でログインして判定し、プライバシーポリシーへの同意が必要だった | `consented` は `false` | 原則-9、2.3.4 | 確定 |
| CRS-I46 | uid「u1」で `consented` が `true` の状態で、ログイン中のユーザーが `null` を挟まずに uid「u2」に変わった | 判定の結果が返る前の `consented` は `false` | 原則-9、LGL-V46 | 確定 |
| CRS-I47 | 同意ダイアログの表示中に「同意する」を呼び、送信が `NetworkFailure` で失敗した | `phase` は `networkError`、`consented` は `false` | 原則-11、LGL-V29 | 確定 |
| CRS-I48 | 同意ダイアログの表示中に「同意する」を呼び、送信が `AuthFailure` で失敗した | `phase` は `networkError`、`consented` は `false` | 原則-11、LGL-V30 | 確定 |
| CRS-I49 | 同意ダイアログの表示中に「同意する」を呼び、表示中に改定されていたことが返り、判定し直した結果もプライバシーポリシーへの同意が必要だった | `phase` は `required`、`consented` は `false` | LGL-V27、2.3.4 | 確定 |
| CRS-I50 | `consented` が `true` の状態で、もう一度判定を始め、結果を待っている | `phase` は `checking`、`consented` は `true` のまま | 2.3.4 | 確定 |
| CRS-I51 | `consented` が `true` の状態で、退会処理の記録があるときに判定を呼んだ | `phase` は `idle`、`consented` は `true` のまま | 8章 Q17、ユーザー決定 2026-11-08 | 確定 |
| CRS-I52 | `isDebug: true`・`useMocks: true`・`consented: true` で収集を切り替えた | `reporter` の `setCollectionEnabled(false)` が1回呼ばれる | 概要 §クラッシュ情報を集めるとき・集めないとき、2.3.4 | 確定 |
| CRS-I53 | 同意ダイアログの表示中に「同意する」を呼び、表示中に改定されていたことが返り、判定し直した結果は同意が不要だった | `phase` は `idle`、`consented` は `true` | 2.3.4、LGL-V55 | 確定 |
| CRS-I54 | 同意ダイアログの表示中に「同意する」を呼び、表示中に改定されていたことが返り、判定し直しが `NetworkFailure` で失敗した | `phase` は `idle`、`consented` は `false` のまま | 2.3.4、LGL-V54、8章 Q15、ユーザー決定 2026-11-08 | 確定 |
| CRS-I55 | uid「u1」の判定中に退会処理の記録が `requested` になり、その後に判定が「同意は不要」を返した | `consented` は `false` のまま | 2.3.4、LGL-V36 | 確定 |
| CRS-I56 | uid「u1」の同意の送信中に他の端末での退会の `phase` が `notifying` になり、その後に送信が `LegalAcceptResult.accepted` を返した | `consented` は `false` のまま | 2.3.4、LGL-V39 | 確定 |
| CRS-I57 | uid「u1」の判定中に、`null` を挟まずログイン中のユーザーが uid「u2」に変わり、その後に u1 の判定が「同意は不要」を返した | `consented` は `false` のまま | 原則-9、LGL-V46 | 確定 |
| CRS-I58 | uid「u1」の同意の送信中に、`null` を挟まずログイン中のユーザーが uid「u2」に変わり、その後に送信が `LegalAcceptResult.accepted` を返した | `consented` は `false` のまま | 原則-9、LGL-V46 | 確定 |

### 6.2 Slack 通知（Cloud Functions：`functions/src/crash_alert.ts`）

前提（各行で特に書かない限り）: プロジェクト ID は `word-pods-prod`、`appId` は `1:707895340348:ios:450ada432e1ac1d5aac239`、
`SLACK_WEBHOOK_URL` は `https://hooks.slack.com/services/T/B/X`、Slack は HTTP 200 を返す。
アラートの値は、行で特に書かない限り `issue.title`「word_list_page.dart line 42」、`issue.subtitle`「StateError」、`issue.appVersion`「1.2.0 (5)」。
観測点は、Slack への POST の回数・宛先・ヘッダー・本文と、関数が正常に終わるかエラーで終わるか、エラーの内容。jest で検証する。

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| CRS-S01 | 新しいクラッシュのアラートを受けた | `https://hooks.slack.com/services/T/B/X` に1回 POST する。`Content-Type` は `application/json`、本文は `text` だけを持つ JSON。`text` は次の5行:<br>「【本番】新しいクラッシュが発生しました」<br>「問題: StateError」<br>「発生箇所: word_list_page.dart line 42」<br>「アプリ: iOS 1.2.0 (5)」<br>「詳細: https://console.firebase.google.com/project/word-pods-prod/crashlytics」<br>関数は正常に終わる | 概要 §通知する出来事・§文面 | 確定 |
| CRS-S02 | 再発のアラート（`issue.appVersion`「1.2.1 (6)」、`resolveTime`「2026-11-01T01:00:00Z」）を受けた | 1回 POST する。`text` は次の6行:<br>「【本番】解決済みのクラッシュが再発しました」<br>「問題: StateError」<br>「発生箇所: word_list_page.dart line 42」<br>「アプリ: iOS 1.2.1 (6)」<br>「解決済みにした日時: 2026/11/01 10:00（日本時間）」<br>「詳細: https://console.firebase.google.com/project/word-pods-prod/crashlytics」<br>関数は正常に終わる | 概要 §通知する出来事・§文面（解決日時を載せる）、8章 Q6、ユーザー決定 2026-11-08 | 確定 |
| CRS-S03 | 急増のアラート（`issue.appVersion`「1.2.1 (6)」、`crashCount` 120、`crashPercentage` 1.5、`firstVersion`「1.2.0 (5)」）を受けた | 1回 POST する。`text` は次の7行:<br>「【本番】クラッシュが急増しています」<br>「問題: StateError」<br>「発生箇所: word_list_page.dart line 42」<br>「アプリ: iOS 1.2.1 (6)」<br>「件数: 120件（1.5%）」<br>「最初に起きたバージョン: 1.2.0 (5)」<br>「詳細: https://console.firebase.google.com/project/word-pods-prod/crashlytics」<br>関数は正常に終わる | 概要 §通知する出来事・§文面 | 確定 |
| CRS-S04 | プロジェクト ID が `word-pods-dev` で、新しいクラッシュのアラートを受けた | `text` の1行目が「【開発】新しいクラッシュが発生しました」、5行目が「詳細: https://console.firebase.google.com/project/word-pods-dev/crashlytics」 | 概要 §文面・§開発と本番 | 確定 |
| CRS-S05 | プロジェクト ID が `demo-word-pods` で、新しいクラッシュのアラートを受けた | `text` の1行目が「【demo-word-pods】新しいクラッシュが発生しました」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S06 | `appId` が `1:707895340348:android:e60f090fcff338c8aac239` で、新しいクラッシュのアラートを受けた | `text` の4行目が「アプリ: Android 1.2.0 (5)」 | 概要 §文面 | 確定 |
| CRS-S07 | `appId` が `1:707895340348:web:abc` で、新しいクラッシュのアラートを受けた | `text` の4行目が「アプリ: 不明 1.2.0 (5)」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S08 | `issue.subtitle` が「a<b>&c」の新しいクラッシュのアラートを受けた | `text` の2行目が「問題: a&lt;b&gt;&amp;c」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S09 | `issue.title` が「<!channel>」の新しいクラッシュのアラートを受けた | `text` の3行目が「発生箇所: &lt;!channel&gt;」（チャンネル全員への呼び出しにならない） | 概要 §今回やらないこと（メンションしない）、8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S10 | 新しいクラッシュのアラートを受け、Slack が HTTP 500 を返した | POST は1回だけ。関数はエラーで終わる | 概要 §送信に失敗したとき | 確定 |
| CRS-S11 | 新しいクラッシュのアラートを受け、Slack への接続に失敗した（POST が例外を投げた） | POST は1回だけ。関数はエラーで終わる | 概要 §送信に失敗したとき | 確定 |
| CRS-S12 | `SLACK_WEBHOOK_URL` が空文字の状態で、新しいクラッシュのアラートを受けた | POST は0回。関数はエラーで終わる | 概要 §送り先の URL の管理 | 確定 |
| CRS-S13 | 再発のアラートを受け、Slack が HTTP 500 を返した | POST は1回だけ。関数はエラーで終わる | 概要 §送信に失敗したとき | 確定 |
| CRS-S14 | 急増のアラートを受け、Slack が HTTP 500 を返した | POST は1回だけ。関数はエラーで終わる | 概要 §送信に失敗したとき | 確定 |
| CRS-S15 | 新しい非致命的エラーのアラート（`issue.title`「settings_repository_impl.dart line 36」、`issue.subtitle`「FormatException」）を受けた | 1回 POST する。`text` は次の5行:<br>「【本番】新しい非致命的エラーが記録されました」<br>「問題: FormatException」<br>「発生箇所: settings_repository_impl.dart line 36」<br>「アプリ: iOS 1.2.0 (5)」<br>「詳細: https://console.firebase.google.com/project/word-pods-prod/crashlytics」 | 概要 §通知する出来事、ユーザー決定 2026-11-08 | 確定 |
| CRS-S16 | 再発のアラート（`resolveTime`「2026-11-01T15:30:59Z」）を受けた | `text` の5行目が「解決済みにした日時: 2026/11/02 00:30（日本時間）」 | 8章 Q6、ユーザー決定 2026-11-08 | 確定 |
| CRS-S17 | 再発のアラート（`resolveTime`「abc」）を受けた | `text` の5行目が「解決済みにした日時: 不明」。関数は正常に終わる | 8章 Q6、ユーザー決定 2026-11-08 | 確定 |
| CRS-S18 | 新しいクラッシュのアラートを受け、Slack が HTTP 404 を返した（Webhook が無効になった） | POST は1回だけ。関数はエラーで終わる | 概要 §送信に失敗したとき | 確定 |
| CRS-S19 | `SLACK_WEBHOOK_URL` が登録されていない（値が無い）状態で、新しいクラッシュのアラートを受けた | POST は0回。関数はエラーで終わる | 概要 §送り先の URL の管理 | 確定 |
| CRS-S20 | `issue.appVersion` が「1.0<b>」の新しいクラッシュのアラートを受けた | `text` の4行目が「アプリ: iOS 1.0&lt;b&gt;」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S21 | 急増のアラート（`firstVersion`「1.0<b>」）を受けた | `text` の6行目が「最初に起きたバージョン: 1.0&lt;b&gt;」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S22 | `issue.subtitle` が「&lt;」の新しいクラッシュのアラートを受けた | `text` の2行目が「問題: &amp;lt;」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S23 | `issue.subtitle` が「a\nb」（途中に改行を含む）の新しいクラッシュのアラートを受けた | `text` は5行のまま。2行目が「問題: a b」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S24 | `issue.title` が空文字の新しいクラッシュのアラートを受けた | `text` の3行目が「発生箇所: （不明）」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S25 | 急増のアラート（`crashCount` 120、`crashPercentage` 2）を受けた | `text` の5行目が「件数: 120件（2%）」 | 8章 Q8、ユーザー決定 2026-11-08 | 確定 |
| CRS-S26 | 急増のアラート（`crashCount` 1234、`crashPercentage` 1.5）を受けた | `text` の5行目が「件数: 1234件（1.5%）」 | 8章 Q8、ユーザー決定 2026-11-08 | 確定 |
| CRS-S27 | プロジェクト ID が無い（値が無い）状態で、新しいクラッシュのアラートを受けた | `text` の1行目が「【不明】新しいクラッシュが発生しました」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S28 | 新しい非致命的エラーのアラートを受け、Slack が HTTP 500 を返した | POST は1回だけ。関数はエラーで終わる | 概要 §送信に失敗したとき、ユーザー決定 2026-11-08 | 確定 |
| CRS-S29 | 新しいクラッシュのアラートを受け、Slack が HTTP 500 を返した | 関数が終わるときのエラーのメッセージに「https://hooks.slack.com/services/T/B/X」を含まない | 概要 §送り先の URL の管理（URL を知れば誰でも投稿できる） | 確定 |
| CRS-S30 | 新しいクラッシュのアラートを受け、POST がメッセージに「https://hooks.slack.com/services/T/B/X」を含む例外を投げた | 関数はエラーで終わり、そのエラーのメッセージに「https://hooks.slack.com/services/T/B/X」を含まない | 概要 §送り先の URL の管理（URL を知れば誰でも投稿できる） | 確定 |
| CRS-S31 | 急増のアラート（`crashCount` 120、`crashPercentage` 1.5384615384615385）を受けた | `text` の5行目が「件数: 120件（1.5%）」 | 8章 Q8、ユーザー決定 2026-11-08 | 確定 |
| CRS-S32 | 急増のアラート（`crashCount` 120、`crashPercentage` 0.0000001）を受けた | `text` の5行目が「件数: 120件（0%）」 | 8章 Q8、ユーザー決定 2026-11-08 | 確定 |
| CRS-S33 | プロジェクト ID が空文字の状態で、新しいクラッシュのアラートを受けた | `text` の1行目が「【不明】新しいクラッシュが発生しました」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S34 | `issue.subtitle` が無い（値が無い）新しいクラッシュのアラートを受けた | `text` の2行目が「問題: （不明）」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S35 | `issue.appVersion` が空文字の新しいクラッシュのアラートを受けた | `text` の4行目が「アプリ: iOS （不明）」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S36 | 再発のアラート（`resolveTime` が無い）を受けた | `text` の5行目が「解決済みにした日時: 不明」。関数は正常に終わる | 8章 Q6、ユーザー決定 2026-11-08 | 確定 |
| CRS-S37 | 再発のアラート（`resolveTime`「2026-11-01T01:00:00」。タイムゾーンなし）を受けた | `text` の5行目が「解決済みにした日時: 不明」 | 8章 Q6、ユーザー決定 2026-11-08 | 確定 |
| CRS-S38 | 再発のアラート（`resolveTime`「2026-11-01T10:00:00+09:00」）を受けた | `text` の5行目が「解決済みにした日時: 2026/11/01 10:00（日本時間）」 | 8章 Q6、ユーザー決定 2026-11-08 | 確定 |
| CRS-S39 | 新しいクラッシュのアラートを受け、Slack が HTTP 204 を返した | POST は1回。関数は正常に終わる | 2.5（200〜299 は成功） | 確定 |
| CRS-S40 | `issue.title` が無い（値が無い）新しいクラッシュのアラートを受けた | `text` の3行目が「発生箇所: （不明）」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S41 | `appId` が無い（値が無い）新しいクラッシュのアラートを受けた | `text` の4行目が「アプリ: 不明 1.2.0 (5)」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S42 | 急増のアラート（`firstVersion` が無い）を受けた | `text` の6行目が「最初に起きたバージョン: （不明）」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S43 | 急増のアラート（`crashCount`・`crashPercentage` がともに無い）を受けた | `text` の5行目が「件数: （不明）件（（不明）%）」 | 8章 Q8・Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S44 | `issue.subtitle` が「　 」（全角・半角スペースだけ）の新しいクラッシュのアラートを受けた | `text` の2行目が「問題: （不明）」 | 8章 Q9、ユーザー決定 2026-11-08 | 確定 |
| CRS-S45 | 急増のアラート（`crashCount` 120、`crashPercentage` 1.25）を受けた | `text` の5行目が「件数: 120件（1.3%）」 | 8章 Q8、ユーザー決定 2026-11-08 | 確定 |
| CRS-S46 | `issue.title` が「a\nb」（途中に改行を含む）の新しいクラッシュのアラートを受けた | `text` は5行のまま。3行目が「発生箇所: a b」 | 8章 Q9・Q12、ユーザー決定 2026-11-08 | 確定 |
| CRS-S47 | `issue.title` が「　 」（全角・半角スペースだけ）の新しいクラッシュのアラートを受けた | `text` の3行目が「発生箇所: （不明）」 | 8章 Q9・Q12、ユーザー決定 2026-11-08 | 確定 |

### 6.3 非致命的エラーの報告（各 Repository の実装・SyncService）

観測点は、Fake の `CrashReporter` への `recordError` の呼び出しの回数と引数。

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| CRS-F01 | `FolderRepositoryImpl.getFolders` で、ローカルのデータソースが例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F02 | `WordRepositoryImpl.getWords` で、ローカルのデータソースが例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F03 | `SettingsRepositoryImpl.getSettings` で、ローカルのデータソースが例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F04 | `FlashcardResultRepositoryImpl.getFlashcardResults` で、ローカルのデータソースが例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F05 | `AccountRepositoryImpl.fetchIsDeveloper` で、データソースが例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F06 | `AuthRepositoryImpl.signInWithEmail` で、データソースが `FirebaseAuthException` 以外の例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F07 | `AuthRepositoryImpl.sendPasswordResetEmail` で、データソースが `code` が「internal-error」の `FirebaseAuthException` を投げた（`UnknownFailure` になる） | `recordError` が1回呼ばれ、第1引数はその `FirebaseAuthException`、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F08 | `EmailVerificationRepositoryImpl.reloadUser` で、データソースが例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F09 | `LegalRepositoryImpl.fetchLegalConfig` で、データソースが例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F10 | `ReauthenticationRepositoryImpl.reauthenticateWithPassword` で、データソースが `FirebaseAuthException` 以外の例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F11 | `AccountDeletionRepositoryImpl.requestServerDeletion` で、データソースが例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F12 | `FolderRepositoryImpl.updateFolder` で、対象のフォルダが存在せず `NotFoundFailure` を返した | `recordError` は0回 | 概要 §非致命的エラー | 確定 |
| CRS-F13 | `EmailVerificationRepositoryImpl.reloadUser` で、取り直しが `code`「network-request-failed」の `FirebaseAuthException` で失敗した（`NetworkFailure` になる） | `recordError` は0回 | 概要 §非致命的エラー、EMV-R04 | 確定 |
| CRS-F14 | `EmailVerificationRepositoryImpl.reloadUser` で、取り直しが `code`「user-token-expired」の `FirebaseAuthException` で失敗した（`AuthFailure` になる） | `recordError` は0回 | 概要 §非致命的エラー、EMV-R07 | 確定 |
| CRS-F15 | `FolderRepositoryImpl.getFolders` が成功した | `recordError` は0回 | 概要 §非致命的エラー | 確定 |
| CRS-F16 | ログイン済み・オンラインで同期（取得）を始め、リモートのデータソースが例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F17 | ログイン済み・オンラインで同期（送信）を始め、リモートのデータソースが例外 `StateError('x')` を投げた | `recordError` が1回呼ばれる。第1引数は `StateError('x')`、第2引数（スタックトレース）は `null` でない、`fatal` は `false` | 概要 §非致命的エラー | 確定 |
| CRS-F18 | ログイン済み・オンラインで同期（取得）を始め、リモートの呼び出しが時間切れ（`TimeoutException`）になった | `recordError` は0回 | 概要 §非致命的エラー | 確定 |
| CRS-F19 | ログイン済み・オンラインで同期（取得）を始め、リモートのデータソースが `SocketException` を投げた | `recordError` は0回 | 概要 §非致命的エラー | 確定 |
| CRS-F20 | ログイン済み・オンラインで同期（取得）を始め、リモートのデータソースが `code` が「unavailable」の `FirebaseException` を投げた | `recordError` は0回 | 概要 §非致命的エラー | 確定 |
| CRS-F21 | ログイン済み・オンラインで同期（取得）を始め、リモートのデータソースが `code` が「deadline-exceeded」の `FirebaseException` を投げた | `recordError` は0回 | 概要 §非致命的エラー | 確定 |
| CRS-F22 | ログイン済み・オンラインで同期（取得）を始め、リモートのデータソースが `code` が「permission-denied」の `FirebaseException` を投げた | `recordError` が1回呼ばれ、第1引数はその `FirebaseException`、`fatal` は `false` | 概要 §非致命的エラー（通信に関するもの以外） | 確定 |
| CRS-F23 | ログイン済み・オンラインで同期（取得）が成功した | `recordError` は0回 | 概要 §非致命的エラー | 確定 |
| CRS-F24 | `recordError` が例外を投げる状態で、`FolderRepositoryImpl.getFolders` のローカルのデータソースが例外 `StateError('x')` を投げた | `getFolders` は例外を出さずに `Left(UnknownFailure)` を返す | 原則-10、8章 Q7、ユーザー決定 2026-11-08 | 確定 |
| CRS-F25 | `recordError` が例外を投げる状態で、ログイン済み・オンラインで同期（取得）を始め、リモートのデータソースが例外 `StateError('x')` を投げた | 同期の呼び出しから例外が出ない | 原則-10、8章 Q7、ユーザー決定 2026-11-08 | 確定 |
| CRS-F26 | ログイン済み・オンラインで同期（取得）を始め、リモートのデータソースが `code` が「unauthenticated」の `FirebaseException` を投げた | `recordError` は0回 | 概要 §非致命的エラー、8章 Q11、ユーザー決定 2026-11-08 | 確定 |
| CRS-F27 | `FolderRepositoryImpl` が、例外を受けずに `Left(UnknownFailure('x'))` を返した | `recordError` は0回 | 2.3.3、8章 Q10、ユーザー決定 2026-11-08 | 確定 |
| CRS-F28 | ログイン済み・オンラインで同期（取得）を始め、リモートのデータソースが `code` が「aborted」の `FirebaseException` を投げた | `recordError` は0回 | 2.3.3、8章 Q11、ユーザー決定 2026-11-08 | 確定 |
| CRS-F29 | キューにフォルダ F の登録、単語 W の登録がこの順で積まれ、F の書き込みでリモートのデータソースが例外 `StateError('x')` を投げる状態で、送信した | `recordError` は1回だけ呼ばれる（W の書き込みは行われないため） | 2.3.3、SYN-S14 | 確定 |
| CRS-F30 | `WordRepositoryImpl.getWords` で、ローカルのデータソースが SQL「SELECT * FROM words」・引数「secret」・結果コード 1555 の `DatabaseException` を投げた | `recordError` が1回呼ばれる。第1引数の文字列は `DatabaseException(resultCode: 1555)` で、「SELECT」「secret」を含まない。第2引数は `null` でない。`fatal` は `false` | 概要 §集めるもの（単語などの入力内容を送らない）、2.3.5、8章 Q14 | 確定 |
| CRS-F31 | ログイン済み・オンラインで同期（送信）を始め、SQL「UPDATE words」・引数「secret」・結果コード 1555 の `DatabaseException` が投げられた | `recordError` が1回呼ばれる。第1引数の文字列は `DatabaseException(resultCode: 1555)` で、「UPDATE」「secret」を含まない。第2引数は `null` でない。`fatal` は `false` | 概要 §集めるもの（単語などの入力内容を送らない）、2.3.5、8章 Q14 | 確定 |
| CRS-F32 | `WordRepositoryImpl.getWords` で、ローカルのデータソースが結果コードを持たない `DatabaseException` を投げた | `recordError` が1回呼ばれる。第1引数の文字列は `DatabaseException(resultCode: unknown)` | 2.3.5、8章 Q14 | 確定 |

### 6.4 利用状況の記録（Analytics）

観測点は、Fake の `AnalyticsReporter` が呼ばれた回数と引数。CRS-A06〜A11・A13〜A15 は、見た画面の記録を開始した後の状態を前提にする（開始時の1回の記録を含めて数える）。

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| CRS-A01 | `isDebug: false`・`useMocks: false` で収集を初期化した | `analytics` の `setCollectionEnabled(true)` が1回呼ばれる | 概要 §利用状況（Firebase Analytics） | 廃止（同意を確認するまで集めないことになったため。CRS-A17 に置き換え。8章 Q13） |
| CRS-A02 | `isDebug: true`・`useMocks: false` で収集を初期化した | `analytics` の `setCollectionEnabled(false)` が1回呼ばれる | 概要 §利用状況（Firebase Analytics） | 確定 |
| CRS-A03 | `isDebug: false`・`useMocks: true` で収集を初期化した | `analytics` の `setCollectionEnabled(false)` が1回呼ばれる | 概要 §利用状況（Firebase Analytics） | 確定 |
| CRS-A04 | `isDebug: true`・`useMocks: true` で収集を初期化した | `analytics` の `setCollectionEnabled(false)` が1回呼ばれる | 概要 §利用状況（Firebase Analytics） | 確定 |
| CRS-A05 | `analytics` の `setCollectionEnabled` が例外を投げる状態で、`isDebug: false`・`useMocks: false` で収集を初期化した | 初期化の呼び出しから例外が出ない。`reporter` の `setCollectionEnabled(false)` は1回呼ばれる | 原則-10、8章 Q7、ユーザー決定 2026-11-08 | 確定 |
| CRS-A06 | `/login` を表示している状態から `/home` を表示した | 最後に呼ばれた `logScreenView` の引数が「/home」 | 概要 §利用状況（Firebase Analytics）（見た画面） | 確定 |
| CRS-A07 | `/home` を表示している状態から、フォルダの ID が「abc123」のフォルダ画面（`/folder/abc123`）を表示した | 最後に呼ばれた `logScreenView` の引数が「/folder/:folderId」。引数に「abc123」を含む呼び出しが0回 | 概要 §利用状況（Firebase Analytics）（ID などの値を入れない） | 確定 |
| CRS-A08 | `/home` を表示している状態から、ボトムナビゲーションで `/settings` に切り替えた | 最後に呼ばれた `logScreenView` の引数が「/settings」 | 概要 §利用状況（Firebase Analytics）（見た画面） | 確定 |
| CRS-A09 | `/folder/abc123` を表示している状態から、別のフォルダの `/folder/def456` を表示した | `logScreenView` の呼び出しが増えない（パスのパターンが同じ「/folder/:folderId」のため） | 概要 §利用状況（Firebase Analytics）、2.3.2 | 確定 |
| CRS-A10 | `/home` を表示している状態で、ダイアログを開いて閉じた | `logScreenView` の呼び出しが増えない | 概要 §利用状況（Firebase Analytics）（ダイアログは画面として記録しない） | 確定 |
| CRS-A11 | `/home` を表示している状態で、`logScreenView` が例外を投げる状態にして `/settings` に切り替えた | 画面の切り替えから例外が出ない | 原則-10、8章 Q7、ユーザー決定 2026-11-08 | 確定 |
| CRS-A12 | `/login` を表示している状態で、見た画面の記録を開始した | `logScreenView("/login")` が1回呼ばれる | 概要 §利用状況（Firebase Analytics）（見た画面）、2.3.2 | 確定 |
| CRS-A13 | `/home` から `/folder/abc123` を表示した後、戻る操作で `/home` に戻った | 最後に呼ばれた `logScreenView` の引数が「/home」 | 概要 §利用状況（Firebase Analytics）（見た画面） | 確定 |
| CRS-A14 | `/home` を表示している状態で記録を開始し、`/settings`、`/home` の順に切り替えた | `logScreenView` が3回呼ばれ、引数は順に「/home」「/settings」「/home」 | 2.3.2（直前の記録とだけ比べる） | 確定 |
| CRS-A15 | `/home` を表示している状態で、ボトムシートを開いて閉じた | `logScreenView` の呼び出しが増えない | 概要 §利用状況（Firebase Analytics）（ボトムシートは画面として記録しない） | 確定 |
| CRS-A16 | `logScreenView` が例外を投げる状態で、`/login` を表示している状態から見た画面の記録を開始した | 記録の開始から例外が出ない | 原則-10、8章 Q7、ユーザー決定 2026-11-08 | 確定 |
| CRS-A17 | `isDebug: false`・`useMocks: false` で収集を初期化した | `analytics` の `setCollectionEnabled(false)` が1回呼ばれる。`setCollectionEnabled(true)` は0回 | 2.3.4、8章 Q13、ユーザー決定 2026-11-08 | 確定 |
| CRS-A18 | `isDebug: false`・`useMocks: false`・`consented: true` で収集を切り替えた | `analytics` の `setCollectionEnabled(true)` が1回呼ばれる | 2.3.4、8章 Q13、ユーザー決定 2026-11-08 | 確定 |
| CRS-A19 | `isDebug: false`・`useMocks: false`・`consented: false` で収集を切り替えた | `analytics` の `setCollectionEnabled(false)` が1回呼ばれる | 2.3.4、8章 Q13、ユーザー決定 2026-11-08 | 確定 |
| CRS-A20 | `isDebug: true`・`useMocks: false`・`consented: true` で収集を切り替えた | `analytics` の `setCollectionEnabled(false)` が1回呼ばれる | 概要 §利用状況（Firebase Analytics）、2.3.4 | 確定 |
| CRS-A21 | `isDebug: false`・`useMocks: true`・`consented: true` で収集を切り替えた | `analytics` の `setCollectionEnabled(false)` が1回呼ばれる | 概要 §利用状況（Firebase Analytics）、2.3.4 | 確定 |
| CRS-A22 | `analytics` の `setCollectionEnabled` が例外を投げる状態で、`isDebug: false`・`useMocks: false`・`consented: true` で収集を切り替えた | 収集の切り替えから例外が出ない。`reporter` の `setCollectionEnabled(true)` は1回呼ばれる | 原則-10、8章 Q7 | 確定 |
| CRS-A23 | `isDebug: true`・`useMocks: true`・`consented: true` で収集を切り替えた | `analytics` の `setCollectionEnabled(false)` が1回呼ばれる | 概要 §利用状況（Firebase Analytics）、2.3.4 | 確定 |


---

## 7. 対象外

- **Crashlytics への記録そのものが失敗した後の扱い**（記録できなかったエラーを別の手段で残すこと）: Crashlytics の SDK が端末に保存して後で送るため、アプリ側では扱わない（CLAUDE.md「過剰なエラーハンドリングより、シンプルさを優先する」）。報告口の呼び出しから例外が漏れないことだけは CRS-I19〜I22 で定める
- **ユーザーの識別子の同期が、収集の有効・無効で変わらないこと**: 同期の処理は `isDebug`・`useMocks` を受け取らない（2.3.1）ため、有効・無効で動作が分かれる余地がない
- **退会・通信エラーによる強制ログアウトでの uid の取り外し**: どちらもログイン中のユーザーが `null` になる変化で、CRS-I13 と同じ処理を通る
- **Slack の 3xx（リダイレクト）**: HTTP クライアントの標準の動作（2.5）で、関数の独自の分岐がない
- **リリースビルドでのコンソール出力**: 利用者の端末ではコンソールを見られないため、出すかどうかを定めない
- **`CrashReporter` の Crashlytics 実装・Mock 実装**（SDK に渡すだけ・何もしない、の薄い実装）: 独自の分岐がないため単体テストしない。Crashlytics 実装は実機の確認（概要 §テスト）で確かめる
- **Provider 経由で渡すこと**（概要 §設計上の決まり）: 構造の規約で、振る舞いではない。`architecture-guard` のレビューで確かめる
- **`recordError` に渡すエラーの中身に入力内容が含まれないこと**: SQLite のエラーは置き換える（CRS-I38・I39・F30〜F32）。それ以外のエラーの中身は、エラーを起こしたコードが作るもので、この機能では加工しない
- **起動時に SDK が既定で集めないこと**（`Info.plist` の `FirebaseCrashlyticsCollectionEnabled`・`FIREBASE_ANALYTICS_COLLECTION_ENABLED`、`AndroidManifest.xml` の `firebase_crashlytics_collection_enabled`・`firebase_analytics_collection_enabled`）: ビルドの設定で、実機の確認で確かめる
- **同意前に端末に保存されたクラッシュ情報の扱い**: SDK の動作（8章 Q16）
- **判定の失敗の種類ごとの網羅**: `checkLegalConsentUseCase` の Failure は種類によらず同じ処理を通るため、`UnknownFailure` で代表する（CRS-I34・I37）
- **同意の送信の `NotFoundFailure`**: 送信の失敗のうち `NetworkFailure`・`AuthFailure` 以外は同じ扱いのため、`UnknownFailure`（CRS-I33）で代表する
- **`consented` の変化と収集の切り替えをつなぐこと**: アプリ全体を組み立てる `App` の配線で、切り替えの判定（CRS-I24〜I27・A18〜A21）と `consented` の値（CRS-I29〜I37・I40〜I51・I53〜I58）は別々に確かめる。つながっていることは実機の確認で確かめる
- **同意を確認した時点で表示中の画面の記録**: 見た画面の記録はルートが変わったときに呼ばれ（2.3.2）、同意の確認では呼ばれない。同意の前に呼ばれた記録は SDK の側で送られないため、同意を確認した時点の画面は、次にルートが変わるまで記録されない
- **「戻し」の切り替えで報告口が例外を投げる場合**: `true` への切り替え（CRS-I28・A22）と同じ処理を通る
- **結果コードの取り出しの失敗**: `getResultCode` はエラー文の解析で、読めない場合は結果コードなしを返す（CRS-F32）
- **既存の行 CRS-I02〜I04・I21・A05 の書き方**: 仕様の改訂で既存の行を作り直さない（spec-authoring「承認後の改訂」）。呼び出し先は 2.3 と観測点の節で決まる
- **同意ダイアログの「ログアウト」・強制ログアウトでの `consented` の取り消し**: どちらもログイン中のユーザーが `null` になる変化で、CRS-I36 と同じ処理を通る
- **端末の機種・OS・アプリのバージョンの付与、ネイティブのクラッシュの収集、次の起動時に送ること**: Crashlytics の SDK の動作
- **アラートが出る条件**（同じ原因を1つの問題にまとめること、何を「新しい問題」「再発」「急増」とするか）: Crashlytics 側の判定で、アプリ・関数からは変えられない
- **アプリが Cloud Functions を直接呼ばないこと**: アプリと関数をつなぐコードを作らないことで満たす。テストする振る舞いがない
- **Firebase コンソール標準の Slack 連携を使わないこと**: 設定しないことで満たす
- **PagerDuty・Jira・Google Play 向けの申告**: 作らないことで満たす（概要 §今回やらないこと）
- **開発と本番の送り先の違い**: 関数は同じコードで、送り先の違いは各プロジェクトに登録する `SLACK_WEBHOOK_URL` の値で決まる（8章 Q3）
- **開発・本番のプロジェクトの切り替え**: `firebase_options` の切り替え（`lib/main.dart`）で決まり、この機能では変えない
- **ネイティブの設定**（Android の Gradle プラグイン・iOS の `uploadDebugSymbols`・難読化を使わないこと）: ビルドの設定で、実機の確認で確かめる
- **`SLACK_WEBHOOK_URL` の登録と、関数がその名前の秘密情報を使うこと**: 登録は手作業（概要 §Firebase コンソール・Slack での設定）。名前の食い違いはデプロイ時に「未登録の秘密情報」として失敗するため、そこで分かる
- **Cloud Logging へのエラーの記録**: 関数がエラーで終わると、Cloud Functions の基盤が自動で記録する。仕様では「関数がエラーで終わること」を観測点にする
- **Slack への再送**: 送信に失敗しても再送しない（概要 §送信に失敗したとき）。関数の再試行の設定を使わないため、POST が1回だけであること（CRS-S10 等）で確かめる
- **アラートの種類ごとの観点の代表**: 文面の加工（改行・特殊文字・空文字）、環境・OS の表示、接続の失敗、404、URL 未登録は、どのアラートでも同じ組み立て・送信の処理を通る。そのため、新しいクラッシュのアラートで代表して確かめる。各アラートの受け口が送信の失敗をエラーとして返すことは、受け口ごとに HTTP 500 の1件（CRS-S10・S13・S14・S28）で確かめる。種類ごとにだけある値（`resolveTime`・`crashCount`・`crashPercentage`・`firstVersion`）の加工は、その種類で確かめる
- **HTTP 429 などの、500・404 以外の失敗の状態コード**: 2.5 のとおり 200〜299 以外はすべて同じ扱いのため、500 と 404 で代表する
- **文面の長さの上限**: Slack の本文の上限（40,000 文字）に対し、アラートの値は Crashlytics が短く切ったものが届くため、上限に届かない
- **Failure 4種類（Unknown / NotFound / Network / Auth）の扱い**: この機能のどの処理も `Either<Failure, T>` を返さない（アプリ側は報告口、関数側は Slack への送信）。関数側の失敗の扱いは CRS-S10〜S14・S18・S19・S28〜S30 で定める
- **App Store Connect の申告・プライバシーポリシーの本文の更新・実機での確認・Firebase コンソールと Slack での設定**: コードの外の手作業
- **Analytics が自動で集めるもの**（起動・利用時間など）: SDK の動作で、アプリのコードの分岐がない
- **広告 ID を集めない設定・Google Analytics の連携**: ビルドの設定（`AndroidManifest.xml`、iOS は環境変数 `FIREBASE_ANALYTICS_WITHOUT_ADID` による `FirebaseAnalyticsCore` の構成）と Firebase コンソールの設定で、配布の手順（fastlane の `beta`）と実機の確認で確かめる
- **Analytics に uid を付けないこと**: `AnalyticsReporter` が識別子を設定するメソッドを持たない（2.1.1）ため、テストする振る舞いがない
- **独自の操作の記録**（「単語を追加した」等）: 今回は集めない（概要 §利用状況）
- **非致命的エラーの報告の、Repository のメソッドごとの網羅**: 各 Repository につき、`UnknownFailure` を返すメソッドの1つを代表にして確かめる（CRS-F01〜F11）。報告しない Failure（`NotFoundFailure`・`NetworkFailure`・`AuthFailure`）は、それが起きる Repository の1つで代表する（CRS-F12〜F14）。同じ Repository の他のメソッドは、それぞれの Repository の仕様書のテストで `UnknownFailure` を返すことを確かめているため、報告の呼び出しはテスト工程の網羅性レビューで確かめる
- **非致命的エラーの報告の足し忘れ（残るリスク）**: 上の代表の方針では、代表にしなかったメソッドで報告の呼び出しを足し忘れても、テストでは検出できない。実装では `UnknownFailure` を作る箇所で必ず報告する形にそろえ、test-loop の網羅性レビュー（`test-fidelity-reviewer`）とコードレビューで確かめる
- **非致命的エラー・見た画面の記録の、収集の有効・無効による違い**: Repository・同期処理・見た画面の記録は `isDebug`・`useMocks` を受け取らない（2.3.2・2.3.3）ため、有効・無効で動作が分かれる余地がない
- **リダイレクトされた画面の記録**: リダイレクトは表示前に解決されるため（2.3.2）、表示されたルートの記録（CRS-A06 等）と同じ処理を通る
- **自動同期（`AutoSyncService`）・同期の各段階（取得・送信・競合の解決・キューの処理）の失敗**: どれも `SyncService` の取得・送信の中で起き、同じ報告の処理を通るため、取得（CRS-F16）と送信（CRS-F17）で代表する
- **同期の `FirebaseException` の `code` ごとの網羅**: 報告しない `code` は `unavailable`・`deadline-exceeded`・`unauthenticated`・`aborted` を確かめ（CRS-F20・F21・F26・F28）、同じ一時的な失敗の `resource-exhausted`・`cancelled` は `aborted` で代表し、報告する `code` は `permission-denied`（CRS-F22）で代表する
- **Mock の Repository の報告**: Mock は `UnknownFailure` を作らないため、報告もしない
- **同期を始める前の、退会処理の途中かどうかの確認の失敗**: 同期を見送るだけで、次の同期で確認し直すため、報告しない
- **同期でのオフライン・未ログイン**: 同期を始めないため、報告する失敗が起きない

## 8. 要確認事項

| ID | 論点 | 案 | 推奨 | 決定 |
|----|------|----|------|------|
| Q1 | 落ちていない想定外のエラー（非致命的エラー）を、今回 Crashlytics に送るか | A: 今回は送らない（受け止められなかったエラーだけ）。別の作業で、Repository の `UnknownFailure` を送る ／ B: 今回、Repository の `UnknownFailure` も送る（約10ファイルの Repository とそのテストを変える） | A（今回の変更を小さく保ち、クラッシュの検知を先に動かすため） | 決定: 案B（2026-11-08）。送る範囲は別途決める |
| Q2 | 新しい非致命的エラーのアラートを Slack に送るか（CRS-S15・S28） | A: 送る（Q1 で送らない場合は、アラート自体が出ないので害はない） ／ B: 送らない | A（Q1 を後で入れたときに、関数を変えずに済むため） | 決定: 案A（2026-11-08） |
| Q3 | 開発のプロジェクトの通知の送り先 | A: 本番とは別のチャンネル（`#wordpods-alerts-dev`）に送る ／ B: 本番と同じチャンネルに、「【開発】」付きで送る | A（開発中の確認で、本番のチャンネルが埋もれないようにするため） | 決定: 案A（2026-11-08）。チャンネルは `#word-pods-app-alert-dev`・`#word-pods-app-alert-prod` |
| Q4 | Firebase Analytics を今回入れるか | A: 入れない ／ B: 入れる（広告 ID を集めない設定にする） | A（クラッシュ検知だけで目的を満たし、申告の変更も小さく済むため） | 決定: 案B（2026-11-08）。集める内容は別途決める |
| Q5 | プライバシーポリシーの改訂に合わせて、規約の版数を上げるか | A: 上げる（全利用者に同意し直しのダイアログが出る） ／ B: 上げない（本文の更新だけ） | 概要設計で決める（利用者は現在開発者1名のため、どちらでも影響は小さい） | 決定: このブランチではプライバシーポリシーを修正しない（2026-11-08） |
| Q6 | 再発の通知に載せる「解決済みにした日時」の書き方（CRS-S02・S16・S17・S36〜S38） | A: 日本時間・「YYYY/MM/DD HH:mm（日本時間）」。値が無い・読めない・タイムゾーンが無い場合は「不明」 ／ B: 日時を載せない | A（再発までの期間が分かると、直し方が正しかったかの判断に役立つため） | 決定: 案A（2026-11-08。書き方は Claude に一任） |
| Q7 | 報告口（`recordError`・`setCollectionEnabled`・`setUserIdentifier`）自体が例外を投げたとき（CRS-I19〜I22） | A: 例外を外に出さない（握りつぶす） ／ B: 何もしない（例外が外に出る。起動時なら起動できなくなり、エラーの処理の中なら異常終了の原因が分かりにくくなる恐れがある） | A（原則-10「落ちない」に沿い、追加は数行で済むため） | 決定: 案A（2026-11-08） |
| Q8 | 急増の通知の数値の書き方（CRS-S25・S26・S31・S32・S43・S45） | A: 件数は桁区切りなしの整数、割合は小数第1位まで（第2位で四捨五入・ちょうど半分は切り上げ、末尾の「.0」は書かない）、無い場合は「（不明）」 ／ B: 件数に桁区切りを付ける（「1,234件」）、割合は同じ | A（利用者が少ないうちは件数が小さく、桁区切りの必要が薄いため） | 決定: 割合は小数第1位まで（2026-11-08）。件数の書き方は案A |
| Q9 | 文面に入れる値の加工（2.5。CRS-S05・S07〜S09・S20〜S24・S27・S33〜S35・S40〜S44・S46・S47） | A: 2.5 のとおり（改行を空白に、`& < >` を置き換え、値が無い・空・空白だけは「（不明）」、知らないプロジェクトは「【プロジェクト ID】」、ID も無ければ「【不明】」、知らない OS は「不明」） ／ B: 加工せずにそのまま載せる（行がずれる・意図しないリンクや呼び出しになる恐れがある） | A（通知の見た目が崩れず、`<!channel>` などで全員を呼び出す事故を防げるため） | 決定: 案A（2026-11-08） |
| Q10 | Repository が、例外を受けずに `UnknownFailure` を返したとき、報告するか（CRS-F27） | A: 報告しない（スタックトレースが無く、原因を調べる手がかりが少ないため） ／ B: `UnknownFailure` のメッセージで報告用のエラーを作って報告する | A（シンプルさを優先。例外を経由する場合はすべて報告されるため） | 決定: 案A（2026-11-08） |
| Q11 | 同期の失敗のうち、報告しない `FirebaseException` の `code`（CRS-F20・F21・F26・F28） | A: `unavailable`・`deadline-exceeded`・`unauthenticated`・`aborted`・`resource-exhausted`・`cancelled` は報告しない（一時的な失敗・ログイン切れ） ／ B: `unavailable`・`deadline-exceeded` だけ報告しない | A（次の同期でやり直される失敗で通知が埋もれないようにするため） | 決定: 案A（2026-11-08） |
| Q12 | Crashlytics のアラートの `issue.title`・`issue.subtitle` を、本文のどの見出しに載せるか（2.4。CRS-S01〜S03・S08・S09・S15・S22〜S24・S34・S40・S44・S46・S47） | A: `issue.subtitle`（例外の型・エラーのメッセージ）を「問題」、`issue.title`（ファイル名・関数名）を「発生箇所」に載せる ／ B: `issue.title` を「問題」、`issue.subtitle` を「発生箇所」に載せる | A（実機で受けたアラートでは、`issue.title` に発生箇所、`issue.subtitle` にエラーの内容が入っていたため） | 決定: 案A（2026-11-08） |
| Q13 | クラッシュ情報・利用状況の送信を、利用規約・プライバシーポリシーへの同意の前から始めるか（CRS-I23〜I33・I35・I36・I40〜I50・I52・I53・I55〜I58・A17〜A23） | A: 同意済みと確認できてから始める ／ B: 同意の前から送り、プライバシーポリシーにその旨を書く | A（プライバシーポリシー第5条の「同意した場合にのみ利用できる」に合わせるため） | 決定: 案A（2026-11-08） |
| Q14 | SQLite のエラー文（SQL と引数を含む）の扱い（CRS-I38・I39・F30〜F32） | A: 結果コードだけのエラーに置き換えて送る ／ B: そのまま送る | A（単語などの入力内容が Crashlytics・Slack に渡らないようにするため） | 決定: 案A（2026-11-08） |
| Q15 | 同意の判定が失敗したとき（オフライン等）の収集（CRS-I34・I37・I54） | A: 判定の前の状態を保つ（確認済みなら続ける、未確認なら始めない） ／ B: 判定に失敗したら止める | A（同意済みと確認できた利用者が圏外に入るだけで収集が止まらないようにするため） | 決定: 案A（2026-11-08） |
| Q16 | 同意の前に端末に保存されたクラッシュ情報を、同意の後に送ってよいか | A: 送ってよい（SDK の標準の動作。送信自体は同意の後） ／ B: 送らない（同意時に未送信の情報を削除する。同意前の不具合は分からなくなる） | A（追加の処理が要らず、送信は同意の後になるため） | 決定: 案A（2026-11-08） |
| Q17 | 同意済みの利用者の退会処理の記録がある間、収集を続けるか（CRS-I51） | A: 続ける（判定を行わないので、直前の状態を保つ） ／ B: 止める | A（退会が完了すると、ログアウトで `consented` が `false` に戻るため） | 決定: 案A（2026-11-08） |

---

## 9. 網羅表

### 9.1 概要設計書との対応

| 概要設計書（§見出し：要点） | 仕様 ID ／ 振り分け |
|---------------------------|--------------------|
| §目的：クラッシュに気づけるようにする | CRS-I05, CRS-I06, CRS-S01 |
| §目的：どの端末・バージョン・箇所かを調べられる | CRS-S01（バージョン・発生箇所）。端末の情報は 7章（SDK の動作） |
| §目的：新しいクラッシュ・再発・急増を日本語で知らせる | CRS-S01, CRS-S02, CRS-S03 |
| §方式：アプリは Cloud Functions を直接呼ばない | 7章（アプリが Cloud Functions を直接呼ばないこと） |
| §方式：コンソール標準の Slack 連携は使わない | 7章（Firebase コンソール標準の Slack 連携を使わないこと） |
| §全体の流れ：次の起動時に送る | 7章（SDK の動作） |
| §全体の流れ：同じ原因は1つの問題にまとめ、通知は3種類のときだけ | 7章（アラートが出る条件） |
| §全体の流れ：通知まで遅れがある | 7章（SDK の動作） |
| §今回やらないこと：プライバシーポリシーの本文の修正 | 7章（コードの外の手作業） |
| §今回やらないこと：メンションしない | CRS-S09。値の置き換えの規則は CRS-S08, CRS-S20, CRS-S21, CRS-S22（8章 Q9） |
| §今回やらないこと：PagerDuty・Jira・Google Play | 7章（PagerDuty・Jira・Google Play 向けの申告） |
| §集めるとき・集めないとき：リリースビルドは集める | CRS-I24, CRS-I05, CRS-I06（同意の後。8章 Q13） |
| 8章 Q13：同意を確認するまで集めない | CRS-I23〜I33, CRS-I35, CRS-I36, CRS-I40〜I50, CRS-I52, CRS-I53, CRS-I55〜I58, CRS-A17〜A23 |
| 8章 Q15：判定の失敗で状態を保つ | CRS-I34, CRS-I37, CRS-I54 |
| 8章 Q16：同意の前に保存された情報 | 7章（同意前に端末に保存されたクラッシュ情報の扱い） |
| 8章 Q17：退会処理の記録がある間の収集 | CRS-I51 |
| §集めるとき・集めないとき：デバッグビルドは集めない | CRS-I02, CRS-I04, CRS-I07, CRS-I08 |
| §集めるとき・集めないとき：デバッグビルドのエラーは今までどおりコンソールに出す | CRS-I07 |
| §集めるとき・集めないとき：Mock モードは集めない | CRS-I03, CRS-I04, CRS-I09, CRS-I10 |
| §集めるとき・集めないとき：dev / prod でプロジェクトが分かれる | 7章（開発・本番のプロジェクトの切り替え） |
| §集めるもの：描画などのエラーをクラッシュとして記録 | CRS-I05 |
| §集めるもの：それ以外の受け止められなかったエラー | CRS-I06 |
| §集めるもの：ネイティブのクラッシュ | 7章（SDK の動作） |
| §集めるもの：ログイン中の uid、ログアウトで外す | CRS-I11, CRS-I12, CRS-I13, CRS-I14, CRS-I16, CRS-I17, CRS-I18。設定の失敗は CRS-I22（8章 Q7） |
| §集めるもの：メールアドレス・表示名を送らない | CRS-I15 |
| §集めるもの：単語などの入力内容を送らない | CRS-I38, CRS-I39, CRS-F30, CRS-F31, CRS-F32。それ以外のエラーは 7章（`recordError` に渡すエラーの中身） |
| §集めるもの：機種・OS・バージョンは自動 | 7章（SDK の動作） |
| §設計上の決まり：domain のインターフェース経由・Provider で渡す | 7章（Provider 経由で渡すこと） |
| §設計上の決まり：Fake で検証 | 6.1 の観測点 |
| §ネイティブの設定：Android の Gradle プラグイン | 7章（ネイティブの設定） |
| §ネイティブの設定：iOS の `uploadDebugSymbols` | 7章（ネイティブの設定） |
| §ネイティブの設定：難読化なし | 7章（ネイティブの設定） |
| §通知する出来事：新しいクラッシュ | CRS-S01 |
| §通知する出来事：再発 | CRS-S02 |
| §通知する出来事：急増 | CRS-S03 |
| §通知する出来事：新しい非致命的エラー | CRS-S15, CRS-S28（8章 Q2） |
| §文面：日本語 | CRS-S01, CRS-S02, CRS-S03 |
| §文面：先頭に開発・本番 | CRS-S01, CRS-S04。知らない・無いプロジェクト ID は CRS-S05, CRS-S27, CRS-S33（8章 Q9） |
| §文面：種類・名前・発生箇所・OS とバージョン・リンク | CRS-S01, CRS-S06。不明な OS・改行・空・値が無いは CRS-S07, CRS-S23, CRS-S24, CRS-S34, CRS-S35, CRS-S40, CRS-S41, CRS-S44, CRS-S46, CRS-S47（8章 Q9） |
| §文面：再発は解決日時 | CRS-S02, CRS-S16, CRS-S17, CRS-S36, CRS-S37, CRS-S38（8章 Q6） |
| §文面：急増は件数・割合・最初のバージョン | CRS-S03。数値の書き方は CRS-S25, CRS-S26, CRS-S31, CRS-S32, CRS-S43, CRS-S45（8章 Q8）。最初のバージョンが無いは CRS-S42 |
| §開発と本番：関数は両方で動く | CRS-S04 |
| §開発と本番：開発の送り先 | 8章 Q3、7章（開発と本番の送り先の違い） |
| §送り先の URL の管理：コードや Git に書かない | CRS-S29, CRS-S30。登録は 7章（`SLACK_WEBHOOK_URL` の登録） |
| §送り先の URL の管理：Secret Manager に保管し実行時に読む | CRS-S12, CRS-S19 |
| §送信に失敗したとき：エラーで終わる | CRS-S10, CRS-S11, CRS-S13, CRS-S14, CRS-S18, CRS-S28。成功の境界は CRS-S39 |
| §送信に失敗したとき：Cloud Logging に残る | 7章（Cloud Logging へのエラーの記録） |
| §送信に失敗したとき：再送しない | CRS-S10, CRS-S13, CRS-S14, CRS-S18（POST は1回だけ） |
| §プライバシーの申告：App Store Connect・ポリシー本文 | 7章（コードの外の手作業） |
| §プライバシーの申告：規約の版数を上げるか | 8章 Q5 |
| §テスト：アプリ側は Fake で単体テスト | 6.1 |
| §テスト：関数側は jest | 6.2 |
| §テスト：実機での確認 | 7章（コードの外の手作業） |
| §Firebase コンソール・Slack での設定 | 7章（コードの外の手作業） |
| §目的：非致命的エラーにも気づける | CRS-F01〜F11, CRS-F16, CRS-F17 |
| §目的：利用状況を知る | CRS-A18, CRS-A06 |
| §方式：Analytics が利用状況を集める | CRS-A17〜A21, CRS-A23。自動で集めるものは 7章（Analytics が自動で集めるもの） |
| §非致命的エラー：Repository の `UnknownFailure` を送る | CRS-F01〜F11。例外を受けない場合は CRS-F27（8章 Q10）。メソッドごとの網羅は 7章（非致命的エラーの報告の、Repository のメソッドごとの網羅） |
| §非致命的エラー：Network・Auth・NotFound は送らない | CRS-F12, CRS-F13, CRS-F14 |
| §非致命的エラー：同期の失敗のうち通信以外は送る | CRS-F16, CRS-F17, CRS-F22。1回の同期で1回は CRS-F29 |
| §非致命的エラー：同期の通信の失敗は送らない | CRS-F18, CRS-F19, CRS-F20, CRS-F21。ログイン切れ・一時的な失敗は CRS-F26, CRS-F28（8章 Q11） |
| §非致命的エラー：集めるとき・集めないときはクラッシュと同じ | CRS-I23〜I27（同じ `setCollectionEnabled` で決まる）。7章（収集の有効・無効による違い） |
| §非致命的エラー：Provider 経由で渡す | 7章（Provider 経由で渡すこと） |
| §利用状況：自動で集めるもの | 7章（Analytics が自動で集めるもの） |
| §利用状況：見た画面・パスの形・ID を入れない | CRS-A06, CRS-A07, CRS-A08, CRS-A09, CRS-A12, CRS-A13, CRS-A14 |
| §利用状況：独自の操作は集めない | 7章（独自の操作の記録） |
| §利用状況：広告 ID を集めない | 7章（広告 ID を集めない設定） |
| §利用状況：uid を付けない | 7章（Analytics に uid を付けないこと） |
| §利用状況：デバッグ・Mock では集めない | CRS-A02, CRS-A03, CRS-A04 |
| §利用状況：ダイアログ・ボトムシートは記録しない | CRS-A10, CRS-A15 |
| §利用状況：Fake で検証 | 6.4 の観測点 |
| §プライバシーの申告：「製品の操作」の申告 | 7章（コードの外の手作業） |

### 9.2 操作 × 観点

この機能の「操作」は、利用者の操作ではなく、初期化・エラー・ログイン状態の変化・アラートの受信。
関数側の Failure の列は、Slack の応答に読み替える（Unknown＝HTTP 500、NotFound＝HTTP 404、Network＝接続の失敗、Auth＝URL が無い）。

| 操作 | 成功 | Unknown | NotFound | Network | Auth | キャンセル | 外側タップ | 処理中（無効化） | 二重操作 | 対象の不在 | 同じ値 | 入力の境界 |
|-----|-----|---------|----------|---------|------|-----------|-----------|----------------|---------|-----------|--------|-----------|
| 収集の切り替え（同意の確認結果） | CRS-I24〜I27, I52, A18〜A21, A23 | 設定の失敗 CRS-I28, A22 | — Failure を返さない | — 同左 | — 同左 | — 操作なし | — 画面なし | — 画面なし | — 呼び出しごとに設定するだけ | — 対象なし | — 7章（`consented` の変化と収集の切り替えをつなぐこと） | — 入力なし |
| 同意の判定・送信（`consented`） | CRS-I29〜I32, I35, I36, I40〜I42, I50 | 判定の失敗 CRS-I34, I37、送信の失敗 CRS-I33 | 判定は 7章（判定の失敗の種類ごとの網羅）、送信は 7章（同意の送信の `NotFoundFailure`） | 送信 CRS-I47、判定は 7章（同左） | 送信 CRS-I48、判定は 7章（同左） | — 同意ダイアログの閉じ方は legal_consent の仕様 | — 閉じられないダイアログ（legal_consent の仕様） | — 判定中 CRS-I50 | — 二重送信は LGL-V38 | 改定 CRS-I49, I53, I54、別ユーザー CRS-I43〜I46, I57, I58、退会処理 CRS-I51, I55, I56 | — 同意済みの再判定 CRS-I30 | — 入力なし |
| SQLite のエラーの報告 | CRS-I38, I39, F30, F31 | 結果コードなし CRS-F32 | — Failure を返さない | — 同左 | — 同左 | — 操作なし | — 画面なし | — 画面なし | — | — 対象なし | — | 7章（結果コードの取り出しの失敗） |
| 収集の初期化 | CRS-I23, I02〜I04, I07〜I10 | 設定の失敗 CRS-I21 | — 同左 | — 同左 | — 同左 | — 操作なし | — 画面なし | — 画面なし | — 起動時に1回 | — 対象なし | — | — 入力なし |
| Flutter の処理中のエラー | CRS-I05 | 記録の失敗 CRS-I19 | — Failure を返さない | — 同左 | — 同左 | — 操作なし | — 画面なし | — 画面なし | — | — 対象なし | — | — 入力なし |
| Flutter の処理の外のエラー | CRS-I06 | 記録の失敗 CRS-I20 | — Failure を返さない | — 同左 | — 同左 | — 操作なし | — 画面なし | — 画面なし | — | — 対象なし | — | — 入力なし |
| ログイン状態の変化 | CRS-I11〜I14, I17, I18 | 設定の失敗 CRS-I22 | — 同左 | — 同左 | — 同左 | — 操作なし | — 画面なし | — 画面なし | — | — | CRS-I16 | CRS-I15（送らない値） |
| 新しいクラッシュのアラート | CRS-S01, S04〜S07, S27, S33, S39 | CRS-S10, S29 | CRS-S18 | CRS-S11, S30 | CRS-S12, S19 | — 操作なし | — 画面なし | — 画面なし | — 再送しない（7章） | — | — | CRS-S08, S09, S20, S22, S23, S24, S34, S35, S40, S41, S44, S46, S47 |
| 再発のアラート | CRS-S02 | CRS-S13 | 7章（アラートの種類ごとの観点の代表） | 7章（同左） | 7章（同左） | — 操作なし | — 画面なし | — 画面なし | — 再送しない | — | — | CRS-S16, S17, S36, S37, S38 |
| 急増のアラート | CRS-S03 | CRS-S14 | 7章（アラートの種類ごとの観点の代表） | 7章（同左） | 7章（同左） | — 操作なし | — 画面なし | — 画面なし | — 再送しない | — | — | CRS-S21, S25, S26, S31, S32, S42, S43, S45 |
| Repository が `UnknownFailure` を返す | CRS-F01〜F11 | 報告の失敗 CRS-F24 | 報告しない CRS-F12 | 報告しない CRS-F13 | 報告しない CRS-F14 | — 操作なし | — 画面なし | — 画面なし | — | — | — | — |
| Repository が例外を受けずに `UnknownFailure` を返す | CRS-F27 | — | — | — | — | — | — | — | — | — | — | — |
| Repository が成功する | CRS-F15 | — | — | — | — | — | — | — | — | — | — | — |
| 同期の失敗 | CRS-F16, F17, F22, F23（成功）, F29（複数件） | 報告の失敗 CRS-F25 | — 同期は Failure を返さない | 報告しない CRS-F18〜F21, F28 | 報告しない CRS-F26 | — 操作なし | — 画面なし | — 画面なし | — 同期は直列化済み | 7章（オフライン・未ログイン） | — | — |
| Analytics の初期化 | CRS-A17, A02〜A04 | 設定の失敗 CRS-A05 | — Failure を返さない | — 同左 | — 同左 | — 操作なし | — 画面なし | — 画面なし | — 起動時に1回 | — | — | — |
| 画面の切り替え | CRS-A06, A07, A08, A12, A13, A14 | 記録の失敗 CRS-A11, A16 | — Failure を返さない | — 同左 | — 同左 | — | ダイアログ CRS-A10・ボトムシート CRS-A15 | — | — | — | 同じパターン CRS-A09 | ID を含むパス CRS-A07 |
| 新しい非致命的エラーのアラート | CRS-S15 | CRS-S28 | 7章（アラートの種類ごとの観点の代表） | 7章（同左） | 7章（同左） | — 操作なし | — 画面なし | — 画面なし | — 再送しない | — | — | 7章（同左） |

### 9.3 操作 × 共通原則

画面のない機能のため、画面の操作を前提にした原則（原則-2〜8）は当てはまらない。

| 操作 | 原則-1 | 原則-2〜8 | 原則-9 | 原則-10 | 原則-11 |
|-----|-------|----------|-------|--------|--------|
| 収集の初期化 | — 表示中のデータに触れない | — 画面の操作でない | — データを扱わない | CRS-I21（設定の失敗で起動を止めない） | — Failure を返さない |
| 収集の切り替え | — 表示中のデータに触れない | — 画面の操作でない | — データを扱わない | CRS-I28, CRS-A22 | — Failure を返さない |
| 同意の判定・送信（`consented`） | — 表示中のデータに触れない | — 画面の操作は legal_consent の仕様 | CRS-I43〜I46, I57, I58（別ユーザーの結果を持ち越さない） | CRS-I34, I37（判定の失敗で収集の状態を壊さない） | CRS-I47, I48（送信の Network・Auth） |
| SQLite のエラーの報告 | — | — 画面の操作でない | CRS-I38, I39, F30, F31（利用者のデータを渡さない） | 7章（結果コードの取り出しの失敗） | — Failure を返さない |
| Flutter の処理中・処理の外のエラー | — | — 画面の操作でない | — | CRS-I19, CRS-I20（記録の失敗で新たな例外を出さない） | — |
| ログイン状態の変化 | — | — 画面の操作でない | CRS-I12, CRS-I14, CRS-I17（ログイン中の本人の uid だけを付ける） | CRS-I22（設定の失敗で例外を出さない） | — |
| アラートの受信（関数） | — 画面なし | — 画面なし | — 利用者のデータを扱わない | — アプリの外の処理 | — 関数の処理 |
| Repository の非致命的エラーの報告 | — Repository の戻り値は変えない（CRS-F24） | — 画面の操作でない | — | CRS-F24（報告の失敗で例外を出さない） | CRS-F13, CRS-F14（Network・Auth は報告せず、従来の扱いのまま） |
| 同期の非致命的エラーの報告 | — | — 画面の操作でない | — | CRS-F25 | — 同期は画面に出さない |
| Analytics の初期化・画面の記録 | — | — 画面の操作でない | — 利用者のデータを扱わない（CRS-A07 で ID を入れない） | CRS-A05, CRS-A11 | — |
