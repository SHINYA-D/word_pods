# ブランチ運用とリリース手順（WordPods）

## このドキュメントについて

ブランチの切り方・マージの向き・リリース時のタグの付け方をまとめる。
`main` を「ストアに出しているもの」と常に一致させ、どのバージョンのコードでもすぐに取り出せる状態を保つのが目的。

## 全体像

```
feature/xxx ──▶ develop ──▶ release/1.2.0 ──▶ main（タグ v1.2.0）
                   ▲                            │
                   └──── main の内容を戻す ◀────┘
                                                │
                       hotfix/1.2.1 ◀───────────┘ ──▶ main（タグ v1.2.1）→ develop にも戻す
```

| ブランチ | 役割 | 切る元 | マージ先 |
|---------|------|-------|---------|
| `main` | ストアに出しているコード。直接コミットしない | ― | ― |
| `develop` | 次のリリースに向けて開発中のコード。直接コミットしない | `main`（最初の1回だけ） | ― |
| `feat/*` `fix/*` `docs/*` `chore/*` など | 日々の作業 | `develop` | `develop` |
| `release/x.y.z` | リリース準備（バージョン番号の更新・TestFlight での確認・審査で指摘された修正） | `develop` | `main` |
| `hotfix/x.y.z` | ストアに出ているバージョンの緊急修正 | `main`（またはタグ） | `main` |

作業ブランチの頭は、コミットのプレフィックス（`feat` / `fix` / `docs` / `style` / `refactor` / `test` / `chore`）に揃える。

## 日々の開発

```bash
git switch develop
git pull
git switch -c feat/word-search      # develop から作業ブランチを切る
# ……実装・コミット……
git push -u origin feat/word-search
```

GitHub で **`develop` 向け**に PR を出してマージする。マージ方法はどれでもよい（作業ブランチの細かいコミットをまとめたいなら Squash で構わない）。

`develop` に入った時点で、CI が Firebase の dev 環境に Firestore ルールと Cloud Functions をデプロイする
（`.github/workflows/ci-cd.yml` の `deploy-dev`）。

| push 先 | テスト（analyze・test） | デプロイ |
|--------|---------------------|---------|
| 作業ブランチ | する | しない |
| `develop` | する | dev |
| `release/*` `hotfix/*` | する | prod（テストが通れば自動） |
| `main` | する | prod（テストが通れば自動） |

デプロイはテスト（`flutter`・`functions` の両ジョブ）が成功したときだけ動く（`needs`）。テストが落ちたコミットは、どの環境にも出ない。

prod へのデプロイに**承認はない**。GitHub の無料プランの非公開リポジトリでは、Environment の承認者（Required reviewers）が使えないため。

## リリース手順

### 流れ

```
develop ──▶ release/1.2.0 を切る
              │ 1. pubspec.yaml の version を 1.2.0 に上げて push
              │ 2. CI が関数・ルールを prod に自動でデプロイする            ← prod に出るのはここ
              │ 3. fastlane で prod 版を配布し、TestFlight で確かめる
              │    （不具合はこのブランチで直して push → 2 → 3 をやり直す）
              ▼ 4. main にマージ（prod へのデプロイがもう一度走るが中身は同じ）
            main ──▶ 5. タグ v1.2.0 ──▶ 6. 審査に提出 ──▶ 7. main を develop に戻す
```

TestFlight に配る版は `--flavor prod` でビルドされ、**prod の Firebase につながる**（`ios/fastlane/Fastfile` の `beta` lane。
接続先はビルドモードやブランチではなくフレーバーで決まる。`lib/main.dart` の `_firebaseOptions`）。
そのため、release ブランチへの push で関数・ルールを prod に出し、「新しいアプリ × 新しい関数」で確かめられるようにしている。

> **関数とルールは、古いアプリでも壊れないように変える（後方互換）。**
> release ブランチを push した瞬間から、ストアに出ている古いアプリが新しい関数・ルールにつながる。
> 審査が通るまで、また更新しない利用者はその後もずっと、古いアプリのまま使い続ける。
> 後方互換を保てない変更が必要になったときの扱いは未決（`docs/TODO.md` の TODO-004）。

### 1. release ブランチを切り、バージョン番号を上げる

```bash
git switch develop
git pull
git switch -c release/1.2.0
```

`pubspec.yaml` の `version` の `x.y.z`（表示上のバージョン）を更新してコミットし、push する。

```yaml
version: 1.2.0+1   # x.y.z が表示上のバージョン、+ の後ろがビルド番号
```

ビルド番号（`+` の後ろ）は、ストアごとに扱いが違う。どちらも同じ番号は二度アップロードできない。

| | 表示上のバージョン | ビルド番号 |
|---|---|---|
| iOS | `pubspec.yaml` の値 | `fastlane beta` が「TestFlight の最新の番号 + 1」を自動で付ける（`pubspec.yaml` の値は使われない） |
| Android | `pubspec.yaml` の値 | `pubspec.yaml` の値。アップロードのたびに手で増やす（`docs/TODO.md` の TODO-003 で自動化予定） |

### 2. 関数・ルールが prod に出たことを確かめる

release ブランチへの push のたびに、テストが通れば CI が関数・ルールを prod にデプロイする（`.github/workflows/ci-cd.yml` の `deploy-prod`）。
関数・ルールを変えていないリリースでも動くが、出る中身は今の prod と同じなので何も変わらない。

前回のリリースから関数・ルールを変えたかは、push する前に次で確かめ、変えていたら後方互換かを見直す。

```bash
git diff --stat v1.1.0 -- functions/src firebase/firestore.rules
```

変えていた場合は、GitHub の Actions でその push の実行を開き、「デプロイ（prod）」が成功したのを確かめてから手順 3 に進む。

### 3. 配布して確かめる

```bash
cd ios && bundle exec fastlane beta
```

TestFlight で実機の動作を確かめる。不具合や審査で指摘された点はこのブランチで直して push し、
関数・ルールを直したなら手順 2 でデプロイの成功を確かめてから、配布し直す。

**最後に配った版と、`main` にマージするコードを同じにする**（タグのコードとストアのアプリを一致させるため）。
直したら必ず配り直して確かめてからマージする。

### 4. main にマージする

GitHub で `release/1.2.0` → `main` の PR を出し、**「Create a merge commit」**でマージする。

- **「Squash and merge」は使わない。** コミットが作り直されて `main` と `develop` の履歴がつながらなくなり、次のリリースで衝突しやすくなる
- **PR の画面でテストが ✅ になっているのを確かめてからマージする。** ブランチ保護が使えないため（後述）、❌ でもマージボタンが押せてしまう
- `main` に入ると prod へのデプロイがもう一度走る。手順 2 で出した内容と同じなので何も変わらない

### 5. タグを付ける

マージしたあとの `main` の最新コミット（マージコミット）にタグを付ける。

```bash
git switch main
git pull
git tag -a v1.2.0 -m "v1.2.0 リリース"
git push origin v1.2.0
```

GitHub の「Releases」→「Draft a new release」で、対象を `main` にしてタグ `v1.2.0` を作ってもよい。

### 6. 審査に提出する

手順 3 で最後に配った TestFlight のビルドを、App Store Connect から審査に提出する。

### 7. develop に戻す

`main` から戻すための一時ブランチを作り、それを `develop` 向けに PR を出してマージする（「Create a merge commit」）。

```bash
git switch main
git pull
git switch -c chore/back-merge-1.2.0
git push -u origin chore/back-merge-1.2.0
```

- release ブランチは `main` にマージした時点で自動削除される（後述）ため、`main` の内容から戻す。中身は同じなので結果は変わらない
- `main` → `develop` の PR を直接出さない。マージすると自動削除で `main` そのものが消える（後述）。一時ブランチなら消えるのは一時ブランチだけ

### リリースを取りやめたとき

手順 2 で prod に出したあとに取りやめた場合、prod には `main` に入っていない関数・ルールが残る。
GitHub の Actions で、**`main` の最新の実行**を開き、「デプロイ（prod）」を「Re-run」する。
`main` のコードで出し直され、prod が `main` と揃う。

## 緊急修正（hotfix）

ストアに出ているバージョンに急ぎの修正が要るときは、`develop` ではなく `main` から切る。

```bash
git switch main
git pull
git switch -c hotfix/1.2.1
# ……修正・pubspec.yaml の version を 1.2.1 に上げる……
```

その後はリリース手順の 2〜7（prod へのデプロイを確かめる → 配布して確かめる → `main` にマージ → タグ `v1.2.1` → 審査 → `main` を `develop` に戻す）と同じ。

hotfix は `develop` を通らないため、関数・ルールの変更は dev 環境で試されないまま prod に出る。
関数・ルールを変える hotfix は、push する前に、手元のエミュレーター（`npm --prefix functions run test:emulator`）で確かめる（push すると prod に出るため）。

## タグ

タグは特定のコミットに付ける「動かない名札」。ブランチは新しいコミットのたびに先へ進むが、タグは付けたコミットを指し続ける。
ブランチではなくリポジトリ全体に属するので、どのブランチにいても参照できる。

| やりたいこと | コマンド |
|------------|---------|
| タグの一覧を見る | `git tag` |
| v1.2.0 のコードを見る | `git checkout v1.2.0`（見るだけの状態になる） |
| v1.2.0 から修正を始める | `git switch -c hotfix/1.2.1 v1.2.0` |
| v1.2.0 と今の差分を見る | `git diff v1.2.0 main` |
| v1.2.0〜v1.3.0 の変更一覧を見る | `git log v1.2.0..v1.3.0 --oneline` |

- タグ名は `v` + `pubspec.yaml` の `x.y.z`（ビルド番号は含めない）
- `git push` だけではタグは送られない。`git push origin <タグ名>` で個別に送る
- 一度 push したタグは付け直さない（ストアに出したバイナリとの対応が崩れる）。間違えたら次のバージョンで出し直す

## GitHub の設定

### マージ後のブランチ自動削除

Settings → General → Pull Requests の「Automatically delete head branches」が有効だと、PR をマージしたときに**マージ元**のブランチが削除される（マージ先とタグは消えない）。

| PR | 消えるブランチ |
|----|-------------|
| `feat/*` → `develop` | `feat/*`（消えてよい） |
| `release/*` → `main` | `release/*`（だから develop へは `main` の内容から戻す） |
| `chore/back-merge-*` → `develop` | 一時ブランチ（消えてよい） |
| `main` → `develop`（**出さない**） | `main` そのものが消えるおそれがある（ブランチ保護が使えないため） |

万一 `main` が消えた場合は、タグから作り直す（`git push origin v1.2.0^{commit}:refs/heads/main`）。

### デフォルトブランチ（`develop` にする）

Settings → General → Default branch を `develop` にする。デフォルトブランチは「リポジトリの代表のブランチ」で、次のものがこれに従う。

| 影響するもの | `develop` にしたときの動き |
|------------|------------------------|
| PR を作るときの向き先の初期値 | `develop` になる（誤って `main` に出しにくくなる） |
| Dependabot の PR の向き先 | `develop` になる（依存の更新が `develop` で試されてから `main` に入る） |
| `git clone` で最初に取り出されるブランチ | `develop` になる（リリース版が要るときは `git switch main`） |
| リポジトリのトップページに表示されるファイル・README | `develop` の内容になる |
| `schedule`（cron）で起動するワークフロー | `develop` のコードで動く（`security.yml` の週1回の脆弱性チェックは `develop` を見る） |
| Dependabot の脆弱性アラート | `develop` の依存パッケージが対象になる |
| PR 本文の `Fixes #12` で Issue を自動で閉じる | `develop` へのマージで閉じる |

### ブランチ保護・承認が使えないこと

このリポジトリは非公開で GitHub の無料プランのため、次の機能が**使えない**（Settings → Rules → Rulesets に
「won't be enforced on this private repository」と出る。既存のルールセット `wordstock2026-up` も効いていない）。

| 使えない機能 | 使えれば防げたこと | 代わりにしていること |
|------------|-----------------|------------------|
| ブランチ保護（削除・直接 push・`--force` の禁止） | `main`・`develop` の削除や、PR を通らない変更 | 直接 push しない運用（`CLAUDE.md` のブランチ運用） |
| 必須チェック（テストが ✅ でないとマージできない） | テストが落ちたコードの `develop`・`main` へのマージ | **PR の画面で ✅ を確かめてからマージする** |
| Environment の承認者（Required reviewers） | 人が確かめる前の prod へのデプロイ | なし（release・hotfix・main への push で、テストが通れば prod に出る） |

テストが落ちたコードがマージされても、デプロイのジョブはテストの成功を条件にしている（`needs`）ので、どの環境にも出ない。
ただし直すまでのあいだ、そのブランチからのデプロイは止まる。

GitHub Pro（個人向けの有料プラン）にすると使えるようになる。そのときは、`main`・`develop` に削除・`--force` の禁止と
必須チェック（`Flutter（analyze・test）`・`Cloud Functions・Firestore ルール（build・test）`。デプロイのジョブは作業ブランチで
動かないため必須にしない）を、Environment「prod」に承認者を設定する。

### Environment「prod」

Settings → Environments → prod の「Deployment branches and tags」で、`main`・`release/*`・`hotfix/*` を許可している。
`main` だけに絞ると、release・hotfix からのデプロイが拒否される。
