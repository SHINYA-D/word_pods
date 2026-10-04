---
feature: ボトムナビゲーションの表示条件（開発者判定）
prefix: SHL
status: approved
targets:
  - lib/presentation/shell/shell_page.dart
  - lib/presentation/shell/shell_view_model.dart
  - lib/core/router/router.dart
  - lib/domain/repositories/account_repository.dart
  - lib/infrastructure/repositories/account_repository_impl.dart
kinds:
  G: 表示条件（開発者判定）
updated: 2026-10-04
---

# ボトムナビゲーションの表示条件（開発者判定） 振る舞い仕様書

## 1. 機能概要

ログイン後の画面の下に出るボトムナビゲーション（`ShellPage`）のうち、「テスト」タブ（サンプル画面 `/sample`）を開発者だけに表示する。
開発者かどうかは Firestore の `accounts/{uid}.isDeveloper` で決まり、ログイン時に1回読む。開発者でないユーザーが `/sample` に遷移しようとすると、ホーム画面（`/home`）へ移動する。

対象の概要設計書は `docs/high_level_design/presentation/sample/high_sample_page.md` の「表示条件」節（根拠欄の `概要 §表示条件`）。
サンプル画面そのものの振る舞いは `docs/detailed_design/presentation/sample/sample_page.md`（SMP）で定める。

## 2. データ定義

### 2.1 accounts/{uid}

| 項目 | 型 | 説明 |
|------|----|------|
| isDeveloper | bool | 開発者フラグ。true（真偽値）のときだけ開発者。クライアントは読み取りのみ（`requirements.md` §8） |
| createdAt | timestamp | 新規登録時にドキュメントを作った時刻。開発者の判定には使わない |

### 2.2 入力ルール

該当なし（ユーザーが入力する項目はない）。

---

## 3. 画面仕様（ShellPage・ルーター）

ボトムナビゲーションバーは `ShellPage` が、`/sample` からの移動はルーターが担う。
条件の「開発者」は `fetchIsDeveloper` が `Right(true)` を返すユーザー、「開発者でない」は `Right(false)` を返すユーザーとする。
ログイン中のユーザーは、特に書かない限り id が `u1` のユーザーとする。

### 3.1 表示条件

| ID | 条件 | 期待される動作 | 根拠 | 確定度 |
|----|------|----------------|------|--------|
| SHL-G01 | 開発者でログインし、ホーム画面（`/home`）を開いた | ボトムナビに「ホーム」「成績」「テスト」「設定」がこの順で表示される | 概要 §表示条件 | 確定 |
| SHL-G02 | 開発者でないユーザーでログインし、ホーム画面（`/home`）を開いた | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない。「ホーム」タブが選択状態になっている | 概要 §表示条件 | 確定 |
| SHL-G03 | ログインしてホーム画面（`/home`）を開き、開発者かどうかの読み込みが完了していない | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない | 概要 §表示条件（読み込み中は開発者でない） | 確定 |
| SHL-G04 | ログインしてホーム画面（`/home`）を開き、開発者かどうかの読み込みが完了していない状態から、`Right(true)` で完了した | ボトムナビに「ホーム」「成績」「テスト」「設定」がこの順で表示され、「ホーム」タブが選択状態のまま | 概要 §表示条件 | 確定 |
| SHL-G05 | ログインしてホーム画面（`/home`）を開き、開発者かどうかの読み込みが `UnknownFailure` で失敗した | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない。スナックバー・`NetworkErrorDialog`・`ErrorScreen` は表示されず、パスは `/home` のまま（ログイン画面へ移動しない）。`AuthRepository` の signOut は呼ばれない | 概要 §表示条件（失敗時は開発者でない・エラー表示とログアウトをしない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-G06 | サンプルが「A」の1件ある開発者でログインしてホーム画面（`/home`）を開き、ボトムナビの「テスト」をタップした | パスが `/sample` になり、AppBar に「サンプル」と表示され、「テスト」タブが選択状態になっている | 概要 §表示条件、概要 §画面構成 | 確定 |
| SHL-G07 | 開発者でないユーザーでログインして設定画面（`/settings`）を開き、ルーターに `/sample` への移動（`go`）を要求した | パスが `/home` になる。AppBar の「サンプル」は表示されない | 概要 §表示条件 | 確定 |
| SHL-G08 | ログインして設定画面（`/settings`）を開き、開発者かどうかの読み込みが完了していない状態で、ルーターに `/sample` への移動（`go`）を要求した | パスが `/home` になる。AppBar の「サンプル」は表示されない | 概要 §表示条件（読み込み中は開発者でない） | 確定 |
| SHL-G09 | ログインして設定画面（`/settings`）を開き、開発者かどうかの読み込みが `UnknownFailure` で失敗した状態で、ルーターに `/sample` への移動（`go`）を要求した | パスが `/home` になる。AppBar の「サンプル」は表示されない。スナックバー・`NetworkErrorDialog` は表示されない | 概要 §表示条件（失敗時は開発者でない・エラー表示をしない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-G10 | 開発者でないユーザーでログインしてホーム画面（`/home`）を開き、ボトムナビの「設定」をタップした | パスが `/settings` になり、「設定」タブが選択状態になっている | 概要 §表示条件（タブは「ホーム」「成績」「設定」の3つ） | 確定 |
| SHL-G11 | 開発者でないユーザーでログインしてホーム画面（`/home`）を開き、ボトムナビの「成績」をタップした | パスが `/results` になり、「成績」タブが選択状態になっている | 概要 §表示条件（タブは「ホーム」「成績」「設定」の3つ） | 確定 |
| SHL-G12 | 開発者のユーザー `u1` でログインし、ログアウトして、開発者でないユーザー `u2` でログインし直し、ホーム画面（`/home`）を開いた | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない | 概要 §表示条件（別のユーザーでログインし直すと読み直す） | 確定 |
| SHL-G13 | 開発者でないユーザー `u1` でログインし、ログアウトして、開発者のユーザー `u2` でログインし直し、ホーム画面（`/home`）を開いた | ボトムナビに「ホーム」「成績」「テスト」「設定」がこの順で表示される | 概要 §表示条件（別のユーザーでログインし直すと読み直す） | 確定 |
| SHL-G14 | 開発者でないユーザー `u1` でログインしてホーム画面（`/home`）を開き、その後 `fetchIsDeveloper` が `Right(true)` を返すように変わってから、ボトムナビの「成績」→「ホーム」の順にタップした | ボトムナビに「ホーム」「成績」「設定」が表示されたままで、「テスト」は表示されない | 概要 §表示条件（ログインし直すまで反映しない） | 確定 |
| SHL-G15 | 開発者でないユーザー `u1` でログインし、ログアウトして、`fetchIsDeveloper` が `Right(true)` を返すように変わってから、同じユーザー `u1` でログインし直し、ホーム画面（`/home`）を開いた | ボトムナビに「ホーム」「成績」「テスト」「設定」がこの順で表示される | 概要 §表示条件（ログインし直すまで反映しない＝ログインし直せば反映する） | 確定 |
| SHL-G16 | 開発者でログインしてホーム画面（`/home`）を開き、ボトムナビの「設定」をタップした | パスが `/settings` になり、「設定」タブが選択状態になっている | 概要 §表示条件（タブは「ホーム」「成績」「テスト」「設定」の4つ） | 確定 |
| SHL-G17 | 開発者でログインしてホーム画面（`/home`）を開き、ボトムナビの「成績」をタップした | パスが `/results` になり、「成績」タブが選択状態になっている | 概要 §表示条件（タブは「ホーム」「成績」「テスト」「設定」の4つ） | 確定 |
| SHL-G18 | 開発者でログインして設定画面（`/settings`）を開き、ボトムナビの「ホーム」をタップした | パスが `/home` になり、「ホーム」タブが選択状態になっている | 概要 §表示条件（タブは「ホーム」「成績」「テスト」「設定」の4つ） | 確定 |
| SHL-G19 | サンプルが「A」の1件ある開発者でログインして設定画面（`/settings`）を開き、ルーターに `/sample` への移動（`go`）を要求した | パスが `/sample` になり、AppBar に「サンプル」と表示される | 概要 §表示条件（開発者でないユーザーだけをホームへ移動させる） | 確定 |
| SHL-G20 | 開発者でないユーザーでログインして設定画面（`/settings`）を開いた | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない。「設定」タブが選択状態になっている | 概要 §表示条件 | 確定 |
| SHL-G21 | 開発者でログインして成績画面（`/results`）を開いた | ボトムナビに「ホーム」「成績」「テスト」「設定」がこの順で表示され、「成績」タブが選択状態になっている | 概要 §表示条件 | 確定 |
| SHL-G22 | ログインしてホーム画面（`/home`）を開き、開発者かどうかの読み込みが `NetworkFailure` で失敗した | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない。`NetworkErrorDialog`・スナックバーは表示されず、パスは `/home` のまま（ログイン画面へ移動しない）。`AuthRepository` の signOut は呼ばれない | 概要 §表示条件（失敗時は開発者でない・エラー表示とログアウトをしない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-G24 | ログインしてホーム画面（`/home`）を開き、開発者かどうかの読み込みが `AuthFailure` で失敗した | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない。`NetworkErrorDialog`・スナックバーは表示されず、パスは `/home` のまま（ログイン画面へ移動しない）。`AuthRepository` の signOut は呼ばれない | 概要 §表示条件（失敗時は開発者でない・エラー表示とログアウトをしない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-G25 | ログインしてホーム画面（`/home`）を開き、開発者かどうかの読み込みが `NotFoundFailure` で失敗した | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない。スナックバー・`ErrorScreen` は表示されず、パスは `/home` のまま。`AuthRepository` の signOut は呼ばれない | 概要 §表示条件（失敗時は開発者でない・エラー表示とログアウトをしない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-G26 | 開発者のユーザー `u1` でログインし、ログアウトして、ユーザー `u2` でログインし直してホーム画面（`/home`）を開き、`u2` の開発者かどうかの読み込みが完了していない | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない | 概要 §表示条件（読み込み中は開発者でない・別のユーザーでログインし直すと読み直す）、原則-9 | 確定 |
| SHL-G27 | ユーザー `u1` でログインし、`u1` の開発者かどうかの読み込みが完了していない間にログアウトして、開発者でないユーザー `u2` でログインし直してホーム画面（`/home`）を開き、`u2` の読み込みが `Right(false)` で完了した後で、`u1` の読み込みが `Right(true)` で完了した | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない | 原則-9 | 確定 |
| SHL-G28 | サンプルが「A」の1件ある開発者のユーザー `u1` でログインしてサンプル画面（`/sample`）を開き、ログアウトして、開発者でないユーザー `u2` でログインし直した | パスが `/home` になり、ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない。AppBar の「サンプル」は表示されない | 概要 §表示条件（開発者でないユーザーは `/sample` を開けない） | 確定 |
| SHL-G29 | 開発者のユーザー `u1` でログインし、ログアウトして、ユーザー `u2` でログインし直してホーム画面（`/home`）を開き、`u2` の開発者かどうかの読み込みが `UnknownFailure` で失敗した | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない | 概要 §表示条件（別のユーザーでログインし直すと読み直す・失敗時は開発者でない）、原則-9、ユーザー決定 2026-10-04 | 確定 |
| SHL-G30 | ユーザー `u1` でログインし、`u1` の開発者かどうかの読み込みが完了していない間にログアウトして、ユーザー `u2` でログインし直してホーム画面（`/home`）を開き、`u2` の読み込みが完了する前に `u1` の読み込みが `Right(true)` で完了した | ボトムナビに「ホーム」「成績」「設定」がこの順で表示され、「テスト」は表示されない | 原則-9、概要 §表示条件（読み込み中は開発者でない） | 確定 |
| SHL-G23 | ログインして設定画面（`/settings`）を開き、開発者かどうかの読み込みが完了していない状態でルーターに `/sample` への移動（`go`）を要求してパスが `/home` になった後、読み込みが `Right(true)` で完了した | パスは `/home` のまま。ボトムナビに「テスト」が表示される | 概要 §表示条件（読み込み中は開発者でない。完了後の自動遷移の定めなし）、ユーザー決定 2026-10-04 | 確定 |

### 3.2 状態遷移

該当なし（「テスト」タブの有無は開発者判定の値だけで決まり、3.1 の各行で定めている）。

---

## 4. 状態管理仕様（ShellViewModel）

3章の表示の元になる値。`isDeveloper`（`bool`）は、ログイン中のユーザーが開発者かどうかを表す。
観測点は `isDeveloper` の値と、`AccountRepository` の `fetchIsDeveloper` が呼ばれた回数と引数。

| ID | 条件 | 期待される状態 | 対応する画面仕様 | 根拠 | 確定度 |
|----|------|----------------|------------------|------|--------|
| SHL-V01 | ユーザー `u1` でログインし、`fetchIsDeveloper` が `Right(true)` を返した | `isDeveloper` は true。`fetchIsDeveloper` が userId `u1` で1回呼ばれる | SHL-G01, SHL-G06, SHL-G16〜G19, SHL-G21 | 概要 §表示条件、原則-9 | 確定 |
| SHL-V02 | ユーザー `u1` でログインし、`fetchIsDeveloper` が `Right(false)` を返した | `isDeveloper` は false | SHL-G02, SHL-G07, SHL-G10, SHL-G11, SHL-G20 | 概要 §表示条件 | 確定 |
| SHL-V03 | ユーザー `u1` でログインし、`fetchIsDeveloper` が完了していない | `isDeveloper` は false | SHL-G03, SHL-G08 | 概要 §表示条件（読み込み中は開発者でない） | 確定 |
| SHL-V04 | ユーザー `u1` でログインし、`fetchIsDeveloper` が `Left(UnknownFailure)` を返した | `isDeveloper` は false | SHL-G05, SHL-G09 | 概要 §表示条件（失敗時は開発者でない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-V05 | ログインしていない状態でアプリを起動した | `isDeveloper` は false。`fetchIsDeveloper` は呼ばれない | —（ログイン前はボトムナビを表示しないため、対応する画面仕様はない） | 概要 §表示条件 | 確定 |
| SHL-V06 | ユーザー `u1` でログインして `fetchIsDeveloper` が `Right(true)` を返し、ログアウトして、ユーザー `u2` でログインし直し、`fetchIsDeveloper` が `Right(false)` を返した | `isDeveloper` は false。`fetchIsDeveloper` は userId `u1` で1回、`u2` で1回呼ばれる | SHL-G12, SHL-G28 | 概要 §表示条件（別のユーザーでログインし直すと読み直す） | 確定 |
| SHL-V07 | ユーザー `u1` でログインして `fetchIsDeveloper` が `Right(false)` を返し、ログアウトして、ユーザー `u2` でログインし直し、`fetchIsDeveloper` が `Right(true)` を返した | `isDeveloper` は true | SHL-G13 | 概要 §表示条件（別のユーザーでログインし直すと読み直す） | 確定 |
| SHL-V08 | ユーザー `u1` でログインして `fetchIsDeveloper` が `Right(false)` を返した後、ログインし直さないまま `fetchIsDeveloper` が `Right(true)` を返すように変わった | `isDeveloper` は false のまま。`fetchIsDeveloper` は1回だけ呼ばれる | SHL-G14 | 概要 §表示条件（ログインし直すまで反映しない） | 確定 |
| SHL-V09 | ユーザー `u1` でログインし、`fetchIsDeveloper` が完了していない状態から `Right(true)` で完了した | `isDeveloper` は false から true に変わる | SHL-G04, SHL-G23 | 概要 §表示条件 | 確定 |
| SHL-V10 | ユーザー `u1` でログインして `fetchIsDeveloper` が `Right(false)` を返し、ログアウトして、同じユーザー `u1` でログインし直し、`fetchIsDeveloper` が `Right(true)` を返した | `isDeveloper` は true。`fetchIsDeveloper` は userId `u1` で2回呼ばれる | SHL-G15 | 概要 §表示条件（ログインし直すと読み直す） | 確定 |
| SHL-V11 | ユーザー `u1` でログインし、`fetchIsDeveloper` が `Left(NetworkFailure)` を返した | `isDeveloper` は false | SHL-G22 | 概要 §表示条件（失敗の種類によらず開発者でない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-V12 | ユーザー `u1` でログインし、`fetchIsDeveloper` が `Left(AuthFailure)` を返した | `isDeveloper` は false | SHL-G24 | 概要 §表示条件（失敗の種類によらず開発者でない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-V13 | ユーザー `u1` でログインし、`fetchIsDeveloper` が `Left(NotFoundFailure)` を返した | `isDeveloper` は false | SHL-G25 | 概要 §表示条件（失敗の種類によらず開発者でない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-V14 | ユーザー `u1` でログインして `fetchIsDeveloper` が `Right(true)` を返し、ログアウトして、ユーザー `u2` でログインし直し、`fetchIsDeveloper` が `Left(UnknownFailure)` を返した | `isDeveloper` は false | SHL-G29 | 概要 §表示条件（読み直す・失敗時は開発者でない）、原則-9 | 確定 |
| SHL-V15 | ユーザー `u1` でログインし、`u1` の `fetchIsDeveloper` が完了していない間にログアウトして、ユーザー `u2` でログインし直し、`u2` の `fetchIsDeveloper` が `Right(false)` を返した後で、`u1` の `fetchIsDeveloper` が `Right(true)` を返した | `isDeveloper` は false のまま | SHL-G27 | 原則-9 | 確定 |
| SHL-V16 | ユーザー `u1` でログインして `fetchIsDeveloper` が `Right(true)` を返し、ログアウトして、ユーザー `u2` でログインし直し、`u2` の `fetchIsDeveloper` が完了していない | `isDeveloper` は false | SHL-G26 | 概要 §表示条件（読み込み中は開発者でない）、原則-9 | 確定 |
| SHL-V18 | ユーザー `u1` でログインし、`u1` の `fetchIsDeveloper` が完了していない間にログアウトして、ユーザー `u2` でログインし直し、`u2` の `fetchIsDeveloper` が完了する前に `u1` の `fetchIsDeveloper` が `Right(true)` を返した | `isDeveloper` は false | SHL-G30 | 原則-9、概要 §表示条件（読み込み中は開発者でない） | 確定 |
| SHL-V17 | ユーザー `u1` でログインして `fetchIsDeveloper` が `Right(true)` を返し、ログアウトした | `isDeveloper` は false | —（ログアウト後はボトムナビを表示しないため、対応する画面仕様はない） | 原則-9 | 確定 |

---

## 5. リポジトリ契約（AccountRepository）

`fetchIsDeveloper(userId)` は Firestore の `accounts/{userId}` を読む。

| ID | メソッド | 条件 | 期待される結果 | 根拠 | 確定度 |
|----|----------|------|----------------|------|--------|
| SHL-R01 | fetchIsDeveloper | `accounts/u1` が `{isDeveloper: true}` | `fetchIsDeveloper(u1)` は `Right(true)` | 概要 §表示条件 | 確定 |
| SHL-R02 | fetchIsDeveloper | `accounts/u1` が `{isDeveloper: false}` | `fetchIsDeveloper(u1)` は `Right(false)` | 概要 §表示条件 | 確定 |
| SHL-R03 | fetchIsDeveloper | `accounts/u1` が存在しない | `fetchIsDeveloper(u1)` は `Right(false)` | 概要 §表示条件（`accounts/{uid}` が無いときは開発者でない） | 確定 |
| SHL-R04 | fetchIsDeveloper | `accounts/u1` はあるが `isDeveloper` が無い（`{createdAt: 作成時刻}`） | `fetchIsDeveloper(u1)` は `Right(false)` | 概要 §表示条件（`isDeveloper` が無いときは開発者でない） | 確定 |
| SHL-R05 | fetchIsDeveloper | `accounts/u1` が `{isDeveloper: "true"}`（文字列） | `fetchIsDeveloper(u1)` は `Right(false)` | 概要 §表示条件（true 以外の値は開発者でない） | 確定 |
| SHL-R06 | fetchIsDeveloper | `accounts/u2` が `{isDeveloper: true}` で、`accounts/u1` は存在しない | `fetchIsDeveloper(u1)` は `Right(false)` | 原則-9 | 確定 |
| SHL-R07 | fetchIsDeveloper | Firestore の読み取りが、コード `unavailable`（オフライン）の例外で失敗した | `fetchIsDeveloper(u1)` は `Left(UnknownFailure)` | 概要 §表示条件（失敗の種類で扱いを変えない・ログアウトしない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-R08 | fetchIsDeveloper | Firestore の読み取りが、コード `permission-denied` の例外で失敗した | `fetchIsDeveloper(u1)` は `Left(UnknownFailure)` | 概要 §表示条件（失敗の種類で扱いを変えない・ログアウトしない）、ユーザー決定 2026-10-04 | 確定 |
| SHL-R09 | fetchIsDeveloper | `accounts/u1` が `{isDeveloper: true}` で `fetchIsDeveloper(u1)` が `Right(true)` を返した後、2回目の読み取りがコード `unavailable` の例外で失敗した | 2回目の `fetchIsDeveloper(u1)` は `Left(UnknownFailure)`（前回の値を返さない） | 概要 §表示条件（オフラインで読めないときは開発者でない・SQLite に保存しない） | 確定 |
| SHL-R10 | fetchIsDeveloper | Firestore の読み取りが、コード `deadline-exceeded` の例外で失敗した | `fetchIsDeveloper(u1)` は `Left(UnknownFailure)` | 概要 §表示条件（失敗の種類で扱いを変えない）、CLAUDE.md（例外を UI に伝播させない） | 確定 |
| SHL-R11 | fetchIsDeveloper | Firestore の読み取りが、Firebase 以外の例外（`StateError`）で失敗した | `fetchIsDeveloper(u1)` は `Left(UnknownFailure)` | CLAUDE.md（例外を UI に伝播させない）、原則-10 | 確定 |
| SHL-R12 | fetchIsDeveloper | `accounts/u1` が `{isDeveloper: null}` | `fetchIsDeveloper(u1)` は `Right(false)` | 概要 §表示条件（true 以外の値は開発者でない） | 確定 |
| SHL-R13 | fetchIsDeveloper | `accounts/u1` が `{isDeveloper: 1}`（数値） | `fetchIsDeveloper(u1)` は `Right(false)` | 概要 §表示条件（true 以外の値は開発者でない） | 確定 |

## 6. ユースケース

委譲のみ。仕様項目なし（`GetIsDeveloperUseCase` は `AccountRepository.fetchIsDeveloper` への委譲のみ。動作は4章・5章で検証する）。

---

## 7. 対象外

- 開発者判定の `NotFoundFailure`: `accounts/{uid}` が無いときは `Right(false)` を返す契約（SHL-R03）のため発生しない
- 開発者判定の `NetworkFailure` / `AuthFailure` を `AccountRepository` が返すこと: 読み取りの失敗は種類によらず `UnknownFailure` を返す契約（SHL-R07, SHL-R08, SHL-R10, SHL-R11）のため発生しない。ただし上の層は、どの Failure が来ても開発者でないとして扱う（SHL-V11〜V13, SHL-G22）
- 開発者判定の読み込み中のローディング表示（原則-5）: 読み込み中は「テスト」タブを出さないだけで、ほかのタブはそのまま使えるため表示しない（概要 §表示条件：開発者でない利用者には何も起きていないのと同じにする）
- ログイン中に `isDeveloper` が変わったときの即時反映: 概要 §表示条件で、ログインし直すまで反映しないと定めている（SHL-G14 で反映しないことを確かめる）
- 開発者がサンプル画面を開いている間に開発者でなくなる場合: 判定はログインし直すまで変わらないため起きない。ログアウトするとルーターがログイン画面へ移動させる
- モックモード（`USE_MOCKS=true`）で開発者として扱うこと（`MockAccountRepository` が常に `Right(true)` を返す）: 定数を返すだけのモック実装で、テストする価値のあるロジックがない（CLAUDE.md の無価値テスト禁止）
- Firestore のセキュリティルール（`accounts/{uid}` は本人だけが読め、書き込めない）・新規登録時の作成・退会時の削除: Firebase 側（`firebase/firestore.rules`、`functions/`）の仕様で、Flutter のテストの対象外
- 「テスト」タブのタップ・`/sample` への遷移要求の Failure 4種類: Repository を呼ばない操作のため発生しない
- 開発者フラグを SQLite・`sync_queue` に読み書きしないこと: `AccountRepository` は SQLite に依存しない（端末に保存しない）。観測できる振る舞いとしては、前回の値を持ち越さないこと（SHL-R09）で確かめる
- モックモードで `accountRepository` が `MockAccountRepository` に切り替わる配線: 他の Repository と同じ `kUseMocks` の分岐で、ビルド時の定数のためテストでは切り替えられない
- 開発者判定の読み込みが失敗した後の自動での読み直し: 概要 §表示条件が「ログイン時に1回読む」と定めているため行わない。ログインし直せば読み直す（SHL-G15, SHL-V10）
- Firestore のオフラインキャッシュの値を返すこと: `online_offline §目的と前提` が「Firestore SDK のオフライン機能（persistence）は無効にする」と定めているため、キャッシュは持たず返らない（オフラインの読み取りは失敗になり、SHL-R07 で扱う）
- `isDeveloper` の境界値として、`"True"`・`"false"` などの別の文字列、配列・マップ: 型ごとの代表（真偽値 SHL-R01/R02、文字列 SHL-R05、null SHL-R12、数値 SHL-R13）で「true（真偽値）以外は開発者でない」を確かめており、同じ型の別の値は判定が変わらないため扱わない
- `/sample` 配下のサブパス: 存在しない。サンプル画面から遷移する `/folder/...` は単語一覧画面のパスで、サンプル画面の仕様ではない
- 「テスト」タブの二重タップ: データを変更しない遷移で、同じパスへの移動を繰り返すだけのため扱わない（原則-4 はデータを変更する操作が対象）

## 8. 要確認事項

仕様を決めてから「確定」に変更する。決まった行は削除せず「決定」列に記録する。

| ID | 論点 | 案 | 推奨 | 決定 |
|----|------|----|------|------|
| SHL-G05, SHL-G09, SHL-G22, SHL-G24, SHL-G25, SHL-G29, SHL-V04, SHL-V11〜V14, SHL-R07, SHL-R08 | 開発者判定の読み込みに失敗したとき、原則-2（失敗は必ず伝える）・原則-11（`NetworkFailure` / `AuthFailure` は `NetworkErrorDialog` → ログアウト）に従うか。概要 §表示条件は「エラーの表示もログアウトもしない」と定めている | A: 概要どおり、エラーを表示せずログアウトもしない（開発者でないとして扱うだけ） ／ B: 原則どおり、`NetworkErrorDialog` を表示してログアウトする | A（ユーザーの操作ではない裏側の読み込みで、開発者でない利用者には関係がない。オフラインで起動しただけでログアウトさせると、オフライン対応と矛盾する） | 決定: 案A（2026-10-04。ユーザー決定） |
| SHL-G23 | 読み込み中に `/sample` を要求してホームへ移動した後、読み込みが `Right(true)` で完了したとき、`/sample` へ自動で移動するか | A: 移動しない（`/home` のまま。「テスト」タブが現れるので、タップすれば開ける） ／ B: 要求した `/sample` へ自動で移動する | A（要求を覚えておく仕組みが要らず単純。開発者向けの画面なので、タブから開き直せば足りる） | 決定: 案A（2026-10-04。ユーザー決定） |

---

## 9. 網羅表

仕様項目の洗い出しの結果（「仕様項目の洗い出し方」）。空欄を残さない。セルには ID か、ID を作らない理由を書く。
この章はテストケースにならない（ハーネスは ID として数えない）。

### 9.1 概要設計書との対応

| 概要設計書（§見出し：要点） | 仕様 ID ／ 振り分け |
|---------------------------|--------------------|
| §表示条件：開発者のときだけ「テスト」タブを表示する | SHL-G01, SHL-G04, SHL-G06, SHL-G16〜G19, SHL-G21 |
| §表示条件：開発者でなければ「テスト」タブを表示せず、タブは「ホーム」「成績」「設定」の3つ | SHL-G02, SHL-G10, SHL-G11, SHL-G20 |
| §表示条件：開発者でないユーザーが `/sample` に遷移しようとしたらホームへ移動 | SHL-G07, SHL-G08, SHL-G09, SHL-G28（開発者は移動しない SHL-G19。読み込み完了後は 8章 SHL-G23） |
| §表示条件：ログイン時に Firestore から1回読み、実行中は覚えておく | SHL-V01, SHL-V08 |
| §表示条件：別のユーザーでログインし直すと読み直す | SHL-G12, SHL-G13, SHL-G26〜G30, SHL-V06, SHL-V07, SHL-V14〜V16, SHL-V18 |
| §表示条件：ログイン中に変えても、ログインし直すまで反映しない | SHL-G14, SHL-V08（ログインし直せば反映 SHL-G15, SHL-V10） |
| §表示条件：読み込み中は開発者でない | SHL-G03, SHL-G08, SHL-V03, SHL-V16 |
| §表示条件：読み込みに失敗したとき（オフラインを含む）は開発者でない | SHL-G05, SHL-G09, SHL-G22, SHL-G24, SHL-G25, SHL-G29, SHL-V04, SHL-V11〜V14, SHL-R07, SHL-R08, SHL-R09〜R11 |
| §表示条件：`accounts/{uid}` や `isDeveloper` が無いときは開発者でない | SHL-R03, SHL-R04 |
| §表示条件：`isDeveloper` が true 以外の値のときは開発者でない | SHL-R02, SHL-R05, SHL-R12, SHL-R13 |
| §表示条件：読み込みに失敗してもエラー表示・ログアウトをしない | SHL-G05, SHL-G09, SHL-G22（原則-2・原則-11 との食い違いは 8章） |
| §表示条件：Firestore から直接読む（SQLite の例外） | SHL-R01〜R06、SHL-R09（前回の値を持ち越さない）。SQLite に依存しないことは 7章 |
| §表示条件：モックモードでは開発者として扱う | 7章（定数を返すだけのモック実装・ビルド時の定数） |

### 9.2 操作 × 観点

| 操作 | 成功 | Unknown | NotFound | Network | Auth | キャンセル | 外側タップ | 処理中（無効化） | 二重操作 | 対象の不在 | 同じ値 | 入力の境界 |
|-----|-----|---------|----------|---------|------|-----------|-----------|----------------|---------|-----------|--------|-----------|
| 開発者判定の読み込み（ログイン時） | SHL-G01, SHL-G02, SHL-G04, SHL-V01, SHL-V02, SHL-V09, SHL-R01〜R06 | SHL-G05, SHL-V04, SHL-R07, SHL-R08, SHL-R09〜R11 | 7章（無ければ `Right(false)`）。上の層は SHL-V13, SHL-G25 | 7章（UnknownFailure に一本化）。上の層は SHL-V11, SHL-G22 | 7章（UnknownFailure に一本化）。上の層は SHL-V12, SHL-G24 | — ユーザー操作なし | — ダイアログなし | SHL-G03, SHL-V03（ローディング表示は 7章） | SHL-V08（同じユーザーでは読み直さない） | SHL-R03, SHL-R04 | SHL-V08 | SHL-R02, SHL-R05, SHL-R12, SHL-R13（true 以外の値） |
| 開発者判定の読み直し（ログインし直す） | SHL-G12, SHL-G13, SHL-G15, SHL-V06, SHL-V07, SHL-V10 | SHL-V14, SHL-G29 | 7章（無ければ `Right(false)`） | 7章（UnknownFailure に一本化） | 7章（UnknownFailure に一本化） | — ユーザー操作なし | — ダイアログなし | SHL-V16, SHL-G26 | SHL-V15, SHL-V18, SHL-G27, SHL-G30（前のユーザーの読み込みが後から終わる） | — ログイン中のユーザーを読むだけ | — 入力なし | — 入力なし |
| 「テスト」タブのタップ | SHL-G06（二重タップは 7章） | 7章（Repository を呼ばない） | 7章（Repository を呼ばない） | 7章（Repository を呼ばない） | 7章（Repository を呼ばない） | — ダイアログなし | — ダイアログなし | — 処理なし | 7章（データを変更しない） | — | — 入力なし | — 入力なし |
| 「テスト」以外のタブのタップ（開発者・開発者でない） | SHL-G10, SHL-G11, SHL-G16〜G18 | 7章（Repository を呼ばない） | 7章（Repository を呼ばない） | 7章（Repository を呼ばない） | 7章（Repository を呼ばない） | — ダイアログなし | — ダイアログなし | — 処理なし | 7章（データを変更しない） | — | — 入力なし | — 入力なし |
| `/sample` への遷移要求 | SHL-G07, SHL-G08, SHL-G09, SHL-G19, SHL-G28（読み込み完了後は 8章 SHL-G23） | 7章（Repository を呼ばない） | 7章（Repository を呼ばない） | 7章（Repository を呼ばない） | 7章（Repository を呼ばない） | — ダイアログなし | — ダイアログなし | — 処理なし | 7章（データを変更しない） | — | — 入力なし | — 入力なし |

`—` はその観点が操作に存在しないことを表す（短い理由を添える）。

### 9.3 操作 × 共通原則

| 操作 | 原則-1 | 原則-2 | 原則-3 | 原則-4 | 原則-5 | 原則-6 | 原則-7 | 原則-8 | 原則-9 | 原則-10 | 原則-11 |
|-----|-------|-------|-------|-------|-------|-------|-------|-------|-------|--------|--------|
| 開発者判定の読み込み・読み直し | — 表示中のデータを消さない（タブの数が変わるだけ） | 8章（概要 §表示条件は失敗を伝えないと定めており、原則と食い違う）。SHL-G05, SHL-G22, SHL-G24, SHL-G25, SHL-G29 | — 入力なし | — ユーザー操作なし。同じユーザーで読み直さない（SHL-V08） | 7章（ローディング表示を出さない） | — 読み取りのみ | — キャンセルなし | — 入力なし | SHL-V01, SHL-V06, SHL-V15, SHL-V16, SHL-V18, SHL-G26, SHL-G27, SHL-G30, SHL-R06 | SHL-G05, SHL-R11（例外が漏れず落ちない） | 8章（概要 §表示条件はログアウトしないと定めており、原則と食い違う）。SHL-G22, SHL-V11, SHL-V12 |
| 「テスト」タブのタップ・開発者でないときのタブのタップ | — 失敗しない | — 失敗しない | — 入力なし | — データを変更しない | — 処理なし | — 遷移は戻れる | — キャンセルなし | — 入力なし | — Repository を呼ばない | — 固定の文言だけ | — 失敗しない |
| `/sample` への遷移要求 | — 失敗しない | — 失敗しない | — 入力なし | — データを変更しない | — 処理なし | — 遷移しないだけ | — キャンセルなし | — 入力なし | SHL-V15, SHL-V16, SHL-G28（判定はログイン中のユーザーのもの） | — 固定の画面へ移動するだけ | — 失敗しない |
