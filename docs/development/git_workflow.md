# ブランチ運用とリリース手順（WordPods）

## このドキュメントについて

ブランチの切り方・マージの向き・リリース時のタグの付け方をまとめる。
`main` を「ストアに出しているもの」と常に一致させ、どのバージョンのコードでもすぐに取り出せる状態を保つのが目的。

## 全体像

```
feature/xxx ──▶ develop ──▶ release/1.2.0 ──▶ main（タグ v1.2.0）
                   ▲                            │
                   └──────── main → develop ◀───┘
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
| `release/*` `hotfix/*` | する | prod（Environment の承認が必要。承認しなければ出ない） |
| `main` | する | prod（Environment の承認が必要） |

## リリース手順

### 流れ

```
develop ──▶ release/1.2.0 を切る
              │ 1. pubspec.yaml の version を 1.2.0 に上げて push
              │ 2. 関数・ルールを変えたリリースなら、デプロイ（prod）を承認する   ← prod に出るのはここ
              │ 3. fastlane で prod 版を配布し、TestFlight で確かめる
              │    （不具合はこのブランチで直して push → 必要なら 2 → 3 をやり直す）
              ▼ 4. main にマージ（デプロイ（prod）がもう一度走るが中身は同じ）
            main ──▶ 5. タグ v1.2.0 ──▶ 6. 審査に提出 ──▶ 7. main を develop に戻す
```

TestFlight に配る版は `--flavor prod` でビルドされ、**prod の Firebase につながる**（`ios/fastlane/Fastfile` の `beta` lane。
接続先はビルドモードやブランチではなくフレーバーで決まる。`lib/main.dart` の `_firebaseOptions`）。
そのため、関数・ルールを変えたリリースは、配る前に prod へ出しておかないと「新しいアプリ × 古い関数」で確かめることになる。

> **関数とルールは、古いアプリでも壊れないように変える（後方互換）。**
> 手順 2 で承認した瞬間から、ストアに出ている古いアプリが新しい関数・ルールにつながる。
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

### 2. 関数・ルールを prod に出す（変えたリリースのときだけ）

release ブランチへの push のたびに、CI の「デプロイ（prod）」が承認待ちになる（`.github/workflows/ci-cd.yml` の `deploy-prod`）。

前回のリリースから関数・ルールを変えたかは、次で確かめる。

```bash
git diff --stat v1.1.0 -- functions/src firebase/firestore.rules
```

- 変えている → GitHub の Actions で、その push の実行を開いて「Review deployments」から承認する
- 変えていない → 同じ画面で「Reject」する（出しても中身は同じなので不要。承認待ちを残すと、`deploy-prod` は同時に1つしか動かない設定のため、後のデプロイが順番待ちになることがある）

### 3. 配布して確かめる

```bash
cd ios && bundle exec fastlane beta
```

TestFlight で実機の動作を確かめる。不具合や審査で指摘された点はこのブランチで直して push し、
関数・ルールを直したなら手順 2 で承認してから、配布し直す。

**最後に配った版と、`main` にマージするコードを同じにする**（タグのコードとストアのアプリを一致させるため）。
直したら必ず配り直して確かめてからマージする。

### 4. main にマージする

GitHub で `release/1.2.0` → `main` の PR を出し、**「Create a merge commit」**でマージする。

- **「Squash and merge」は使わない。** コミットが作り直されて `main` と `develop` の履歴がつながらなくなり、次のリリースで衝突しやすくなる
- `main` に入ると「デプロイ（prod）」がもう一度承認待ちになる。手順 2 で出した内容と同じなので、承認して prod を `main` と揃えておく

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

GitHub で **`main` → `develop`** の PR を出してマージする（「Create a merge commit」）。

release ブランチは `main` にマージした時点で自動削除される（後述）ため、release ではなく `main` から戻す。
中身は同じなので結果は変わらない。

### リリースを取りやめたとき

手順 2 で prod に出したあとに取りやめた場合、prod には `main` に入っていない関数・ルールが残る。
GitHub の Actions で、**`main` の最新の実行**を開き、「デプロイ（prod）」を「Re-run」して承認する。
`main` のコードで出し直され、prod が `main` と揃う。

## 緊急修正（hotfix）

ストアに出ているバージョンに急ぎの修正が要るときは、`develop` ではなく `main` から切る。

```bash
git switch main
git pull
git switch -c hotfix/1.2.1
# ……修正・pubspec.yaml の version を 1.2.1 に上げる……
```

その後はリリース手順の 2〜7（関数・ルールを変えたなら承認 → 配布して確かめる → `main` にマージ → タグ `v1.2.1` → 審査 → `main` を `develop` に戻す）と同じ。

hotfix は `develop` を通らないため、関数・ルールの変更は dev 環境で試されないまま prod に出る。
関数・ルールを変える hotfix は、手順 2 で承認する前に、手元のエミュレーター（`npm --prefix functions run test:emulator`）で確かめる。

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
| `release/*` → `main` | `release/*`（だから develop へは `main` から戻す） |
| `main` → `develop` | `main` ← 保護していれば消えない |

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

### ブランチ保護と必須チェック

Settings → Branches → Add branch ruleset（または Add rule）で、`main` と `develop` にそれぞれ次を設定する。

| 設定 | 値 | 効果 |
|-----|----|-----|
| Restrict deletions | オン | ブランチを削除できなくなる。マージ後の自動削除の対象からも外れる（`main` → `develop` の PR で `main` が消えない） |
| Require a pull request before merging | オン | 直接 push できなくなり、PR 経由でしか変更できない |
| ↳ Required approvals | 0 | 1人開発では自分の PR を自分で承認できないため、1 以上にするとマージできなくなる |
| Require status checks to pass | オン | 下の必須チェックが成功していない PR は、マージボタンが押せない |
| ↳ 必須にするチェック | `Flutter（analyze・test）` と `Cloud Functions・Firestore ルール（build・test）` | `ci-cd.yml` のジョブ名。一度 CI が動いたあとでないと候補に出てこない |
| Block force pushes | オン | 履歴の書き換え（`git push --force`）を禁止する |

必須チェックにしなくても CI は動き、PR の画面に結果も出る。必須にしない場合は、テストが赤でもマージボタンが押せてしまい、
そのまま `develop`（dev 環境）や `main`（本番）にデプロイされる。必須にすると、赤のあいだはマージボタンが押せない。

- `デプロイ（dev）` / `デプロイ（prod）` は必須にしない（作業ブランチでは動かないため、いつまでも「待ち」になってマージできなくなる）
- 管理者は保護を無視してマージできる設定が初期値のことがある。緊急時の抜け道として残すか、Bypass list を空にして自分も縛るかを決める

### Environment「prod」

Settings → Environments → prod で次を確かめる。

| 設定 | 値 | 理由 |
|-----|----|-----|
| Required reviewers | 自分 | 承認しない限り prod に出ないようにする（手順 2 の「承認」はこれ） |
| Deployment branches and tags | `main`・`release/*`・`hotfix/*` を許可（または制限なし） | `main` だけに絞っていると、release・hotfix からのデプロイが拒否される |
