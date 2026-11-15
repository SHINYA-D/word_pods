# TODO

後で対応する作業のチケット一覧。対応を始めるときはブランチを切り、完了したら該当のチケットを削除する（履歴は Git に残る）。

## fastlane

### TODO-001 iOS の TestFlight へのアップロードを CD に組み込む

- 背景: `ios/fastlane/Fastfile` の `beta` lane は、手元の Mac から `bundle exec fastlane beta` で実行する形でしか動かない。`.github/workflows/ci-cd.yml` は Firebase のデプロイだけで、iOS のビルドとアップロードは入っていない
- やること
  - `ci-cd.yml` に TestFlight 用のジョブを追加する（main への push で起動し、テストが通ったときだけ。`deploy-prod` と同じく Environment の承認を挟む）
  - `runs-on` を macOS の runner にする（iOS のビルドは Mac でしかできないため）
  - 署名の仕組みを用意する（手元では Xcode にログイン済みのアカウントで自動署名しているが、CI のマシンにはアカウントが無い。`match` を使うか、API キーで署名できるようにする）
  - Secrets を登録する（App Store Connect API キーの `ASC_KEY_ID`・`ASC_ISSUER_ID`・.p8 の中身、prod の `GoogleService-Info.plist`・`firebase_options_prod.dart`）
- 完了条件: main へのマージ（と承認）で、TestFlight の内部テストに新しいビルドが届く
- 補足: 非公開リポジトリでは、macOS の runner は無料枠の消費が Linux の 10 倍になる

### TODO-002 Info.plist の暗号化の申告が効くかを確かめる

- 背景: `ios/Runner/Info.plist` に `ITSAppUsesNonExemptEncryption = false` を加えた（暗号化は HTTPS 通信と認証のみで免除対象のため）。これで App Store Connect の輸出コンプライアンス（暗号化書類）の質問が、ビルドごとに出なくなるはず。ただし設定を加えたのはビルド 1 のアップロードより後なので、まだ確かめていない
- やること: 次のビルド（2 以降）を `fastlane beta` でアップロードし、TestFlight の画面で暗号化の質問が出ないかを見る
- 完了条件: 質問に答えずに、ビルドが「テスト可能」になる
- 補足: 端末に保存するデータを独自に暗号化するライブラリ（SQLCipher など）を入れたら、この申告を見直す

### TODO-003 Android の fastlane を動くようにする

- 背景: `android/fastlane/` は `fastlane init` の雛形のままで動かない
  - `beta` lane が、提供の終わった Crashlytics Beta にアップロードする内容になっている
  - flavor（prod）を指定していない
  - `Appfile` の `json_key_file`（Google Play の API キー）が空
- 前提: Google Play Console のデベロッパー登録が完了していること（現在は登録が失敗していて、Play Console に入れない）
- やること
  - iOS の `beta` lane と同じ形にする（`fvm flutter build appbundle --flavor prod` → 内部テストのトラックにアップロード。バージョンコードは自動で増やす）
  - Play Console でサービスアカウントの JSON キーを発行し、環境変数で渡す（リポジトリには置かない）
  - 初回の aab は Play Console から手でアップロードする（API でアップロードできるのは2回目以降のため）
- 完了条件: `bundle exec fastlane beta` で、Play Console の内部テストに新しいビルドが届く
