# TODO

後で対応する作業のチケット一覧。対応を始めるときはブランチを切り、完了したら該当のチケットを削除する（履歴は Git に残る）。

## fastlane

### TODO-001 iOS の TestFlight へのアップロードを CD に組み込む

- 背景: `ios/fastlane/Fastfile` の `beta` lane は、手元の Mac から `bundle exec fastlane beta` で実行する形でしか動かない。`.github/workflows/ci-cd.yml` は Firebase のデプロイだけで、iOS のビルドとアップロードは入っていない
- やること
  - `ci-cd.yml` に TestFlight 用のジョブを追加する（main への push で起動し、テストが通ったときだけ。無料プランの非公開リポジトリでは Environment の承認者を使えないため、承認を挟むなら GitHub Pro が要る）
  - `runs-on` を macOS の runner にする（iOS のビルドは Mac でしかできないため）
  - 署名の仕組みを用意する（手元では Xcode にログイン済みのアカウントで自動署名しているが、CI のマシンにはアカウントが無い。`match` を使うか、API キーで署名できるようにする）
  - Secrets を登録する（App Store Connect API キーの `ASC_KEY_ID`・`ASC_ISSUER_ID`・.p8 の中身、prod の `GoogleService-Info.plist`・`firebase_options_prod.dart`）
- 完了条件: main へのマージで、TestFlight の内部テストに新しいビルドが届く
- 補足: 非公開リポジトリでは、macOS の runner は無料枠の消費が Linux の 10 倍になる

### TODO-002 Info.plist の暗号化の申告が効くかを確かめる

- 背景: `ios/Runner/Info.plist` に `ITSAppUsesNonExemptEncryption = false` を加えた（暗号化は HTTPS 通信と認証のみで免除対象のため）。これで App Store Connect の輸出コンプライアンス（暗号化書類）の質問が、ビルドごとに出なくなるはず。ただし設定を加えたのはビルド 1 のアップロードより後なので、まだ確かめていない
- やること: 次のビルド（2 以降）を `fastlane beta` でアップロードし、TestFlight の画面で暗号化の質問が出ないかを見る
- 完了条件: 質問に答えずに、ビルドが「テスト可能」になる
- 補足: 端末に保存するデータを独自に暗号化するライブラリ（SQLCipher など）を入れたら、この申告を見直す

### TODO-003 Android の fastlane を動くようにする

- 済み: `android/fastlane/Fastfile` に `build`（aab を作るだけ）と `beta`（ビルド → 内部テストへアップロード。バージョンコードは自動で増やす）を作った。Play Console のデベロッパー登録も済んだ（2026-11-15）
- 済み（2026-11-15）: 初回の aab の手動アップロード、サービスアカウント（`fastlane-play-upload@word-pods-prod.iam.gserviceaccount.com`。Play Console のアプリの権限に「テストトラックにアプリをリリース」が要る）の招待、Play Integrity API への `word-pods-prod` のリンク、アプリ署名鍵の SHA-256・SHA-1 の Firebase（prod）への登録、App Check への Play Integrity の登録。`bundle exec fastlane beta` でバージョンコード 2 が内部テストに届いた
- 残り: 内部テストのビルドを実機に入れ、退会まで動くかを確かめる（`enforceAppCheck: true` の関数を Play Integrity で通せるかの確認）
- 完了条件: 内部テストのビルドで退会まで動く

## リリース

### TODO-004 本番の Cloud Functions・Firestore ルールと、ストアのアプリの公開時期のずれをどう扱うか決める

- 背景
  - TestFlight に配る版は `--flavor prod` でビルドされ、prod の Firebase につながる。関数・ルールを変えたリリースを TestFlight で確かめるには、配る前に prod へ出しておく必要がある
  - そのため、CI は `release/*`・`hotfix/*` への push でも prod にデプロイする（無料プランの非公開リポジトリでは Environment の承認者を使えないため、承認は挟まない）。push した時点から、ストアの古いアプリが新しい関数・ルールにつながる。審査が通るまで、また更新しない利用者はその後もずっと「古いアプリ × 新しい関数・ルール」になる
- 暫定の方針（`docs/development/git_workflow.md` の「リリース手順」に書いた）
  - 関数とルールは、古いアプリでも壊れないように変える（後方互換）
  - 関数・ルールを変えたリリースだけ、release ブランチの段階で prod に出し、TestFlight（prod 版）で確かめる
  - リリースを取りやめたら、`main` の「デプロイ（prod）」を Re-run して prod を `main` に戻す
- 議論したいこと
  - 後方互換を保てない変更（Firestore のデータ構造を変える等）が必要になったとき、どう出すか（強制アップデートの仕組みを入れる／新旧両方の形式を一定期間受け付け、何回かのリリースに分けて移す（expand／contract） 等）
  - 強制アップデート（最低バージョンを Remote Config などで配り、古いアプリに更新を促す）を入れるか
  - 機能フラグ（Remote Config）で「アプリを出す」と「機能を有効にする」を分け、公開と関数のデプロイの順番を気にしなくて済むようにするか
  - prod に触らずに確かめる方法へ移るか（dev 版を TestFlight／Firebase App Distribution で配って確かめ、`main` にマージしてから prod 版を軽く確かめる／検証用の stg 環境を作る）。dev 版はバンドル ID が `.dev` で別アプリ扱いのため、配る場所と fastlane の lane が要る
  - 後方互換を CI やテストで確かめる方法はあるか
- 完了条件: 方針を決めて `docs/development/git_workflow.md` に書き、必要な仕組みのチケットを切る

### TODO-006 Sign in with Apple を追加し、Google ログインを戻す

- 背景: 初回の iOS 審査で Guideline 4.8（Login Services）により却下された。Google などの第三者ログインを置くアプリは、メールアドレスを隠して登録できるログイン（事実上 Sign in with Apple）も同等に用意しなければならない。リリースを優先し、ログイン画面の「Google でログイン」ボタンだけを外した（2026-11-15）
- 残してあるもの（使われていないが消していない）: `LoginViewModel.signInWithGoogle`、`SignInWithGoogleUseCase`、`AuthRepository.signInWithGoogle`、`ReauthenticationRepository.reauthenticateWithGoogle`、アカウント画面・退会の Google ユーザー向け分岐、それぞれのテスト、Firebase の Google ログイン設定、Info.plist の URL スキーム
- やること
  - Apple Developer の App ID で Sign in with Apple を有効にし、Xcode の Runner に Capability を追加する
  - Firebase（dev・prod）で Apple のログインを有効にし、Apple の Private Email Relay Service にメール送信元のドメインを登録する
  - `sign_in_with_apple` を入れ、Google と同じ形（UseCase → Repository → Firebase）でログインと退会前の再認証を作る
  - 退会時に Apple のトークンを無効にする（Guideline 5.1.1(v)。`FirebaseAuth.revokeTokenWithAuthorizationCode`）
  - ログイン画面に Apple と Google のボタンを同じ大きさ・同じ目立ち方で置く（`login_page_test.dart` の `findsNothing` を戻す。`legal_document_page_test.dart` の `_signInWithGoogle` を、ボタンをタップする形に戻す）
  - メールアドレスを隠したユーザーの表示を見直す（`account_page.md` の ACI-Q01）。プライバシーポリシーにログイン方法を加える
- 完了条件: Apple と Google の両方でログイン・退会ができ、iOS の審査を通る
- 注意: Google だけを先に戻すと、同じ理由でまた却下される。必ず Apple と同じリリースで戻す

## CI/CD

### TODO-005 CI で Android（と iOS）のビルドを確かめる

- 背景: `.github/workflows/ci-cd.yml` は analyze とテストだけで、アプリのビルドをしない。依存パッケージの衝突などでビルドが壊れても CI は緑のまま通る（Firebase 5 系と google_sign_in 7 の衝突で実際に起きた。`.github/dependabot.yml` のコメント参照）
- やること
  - Android: `flutter build apk --debug --flavor dev` などのビルドだけのジョブを追加する（ubuntu で動くので費用は小さい。署名は不要）
  - iOS: `flutter build ios --no-codesign` のジョブを追加するか決める（macOS の runner は無料枠の消費が Linux の 10 倍。TODO-001 で macOS のジョブを作るなら、そこに相乗りできる）
  - （GitHub Pro にしてブランチ保護が使えるようになったら）追加したジョブを必須チェックに加える
- 完了条件: ビルドが壊れる変更を push すると CI が赤になる
