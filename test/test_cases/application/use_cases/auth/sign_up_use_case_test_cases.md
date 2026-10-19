# sign_up_use_case_test_cases.md

## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/application/use_cases/auth/sign_up_use_case.dart |
| クラス名 | SignUpUseCase |
| テスト対象メソッド | call() |
| 仕様書 | docs/detailed_design/legal_consent/legal_consent.md |

## 実行環境について

`SignUpUseCase` は `AuthRepository`・`SyncService`（登録成功時の同期）・`LegalRepository`（登録成功時の同意の送信）に依存する。

- **LegalRepository**: テストファイル内の手書きフェイク `_FakeLegalRepository`（`accept` の呼び出し回数・引数・順序を記録）を使用する。LGL-T01〜T08 は仕様書 6.3 節の期待値。

- **AuthRepository**: `test/helpers/fake_auth_use_case_repositories.dart` の `FakeAuthRepository` を使用する。
- **SyncService**: 具象クラスのため、テストケース1〜4は `test/helpers/fake_auth_use_case_repositories.dart` の
  `FakeSyncServiceForLogin`（`syncRemoteToLocalOnLogin()` のみオーバーライド）を使用する。
  実際の Firestore/SQLite 通信は発生しない。
- **テストケース5〜7（SYN-L07〜L09）**: `docs/detailed_design/online_offline/online_offline.md`
  （接頭辞 SYN、6章「ユースケース」）の期待値を、本物の `SyncService` + 手書きフェイク
  `SyncRemoteDataSource`（`_FakeSignUpSyncRemoteDataSource`）+ 本物の SQLite（`sqflite_common_ffi`、
  このテストファイル専用の一時ディレクトリ）で確かめる。`FolderRepositoryImpl` 経由で
  `getFolders` の戻り値を検証する。`SignUpUseCase` / `SyncService` の実装は「どう呼ぶか」を
  知るためだけに読み、期待値は仕様書だけから作った。

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | email/passwordを指定して呼び出した場合、Repositoryに同じ値で委譲される | - | 正常系 | call() | ✅ |
| 2 | 登録に成功した場合、Right(AppUser)がそのまま返り、ログイン時同期が1回実行される | - | 正常系 | call() | ✅ |
| 3 | 登録に失敗した場合、Left(Failure)がそのまま返り、ログイン時同期は実行されない | - | 異常系 | call() | ✅ |
| 4 | 登録成功後の同期処理で例外が発生した場合、例外は握りつぶされ登録結果はそのまま返る | - | 異常系 | call() | ✅ |
| 5 | 新規登録に成功した（リモートにデータなし）場合、戻り値がRight(AppUser)になり、getFoldersの戻り値が空になる [SYN-L07] | SYN-L07 | 正常系 | call() | ✅ |
| 6 | 新規登録に成功し、その後の取得がリモートの失敗で失敗した場合、戻り値がRight(AppUser)になる [SYN-L08] | SYN-L08 | 異常系 | call() | ✅ |
| 7 | 新規登録がAuthFailureで失敗した場合、戻り値がLeft(AuthFailure)になり、リモートへのデータの読み取りが呼ばれない [SYN-L09] | SYN-L09 | 異常系 | call() | ✅ |
| 8 | アカウント作成と送信が成功した場合、Right(AppUser A)が返り、送信が規約・ポリシー2026-01-01で1回、初回の同期が1回呼ばれる [LGL-T01] | LGL-T01 #8aa17d | 正常系 | call() | ✅ |
| 9 | アカウント作成がLeft(AuthFailure)の場合、Left(AuthFailure)が返り、送信は0回、初回の同期は0回 [LGL-T02] | LGL-T02 #7946f8 | 異常系 | call() | ✅ |
| 10 | 送信がLeft(UnknownFailure)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T03] | LGL-T03 #4bb0be | 異常系 | call() | ✅ |
| 11 | 送信がRight(outdated)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T04] | LGL-T04 #eb2e4d | 異常系 | call() | ✅ |
| 12 | 送信が成功する場合、送信は初回の同期より先に呼ばれる [LGL-T05] | LGL-T05 #e3dc1f | 正常系 | call() | ✅ |
| 13 | 送信がLeft(NetworkFailure)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T06] | LGL-T06 #731770 | 異常系 | call() | ✅ |
| 14 | 送信がLeft(AuthFailure)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T07] | LGL-T07 #9d57c5 | 異常系 | call() | ✅ |
| 15 | アカウント作成がLeft(NetworkFailure)の場合、Left(NetworkFailure)が返り、送信は0回、初回の同期は0回 [LGL-T08] | LGL-T08 #4d0bf9 | 異常系 | call() | ✅ |

## テストケース詳細

### テストケース1: email/passwordを指定して呼び出した場合、Repositoryに同じ値で委譲される
- **カテゴリ**: 正常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository` / `FakeSyncServiceForLogin` を注入した `SignUpUseCase` を生成
- **入力値・テスト条件**: `email: 'new@example.com'`, `password: 'password123'`
- **操作手順**: `useCase.call(email: ..., password: ...)` を呼ぶ
- **期待結果**: `FakeAuthRepository.signUpWithEmailCallCount` が1になり、`receivedSignUpWithEmail` が指定した値と一致する

### テストケース2: 登録に成功した場合、Right(AppUser)がそのまま返り、ログイン時同期が1回実行される
- **カテゴリ**: 正常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository.signUpWithEmailResult` に `Right(AppUser)` を設定
- **入力値・テスト条件**: 有効な email/password
- **操作手順**: `useCase.call(...)` を呼ぶ
- **期待結果**: 戻り値が設定した `Right(AppUser)` と一致し、`syncRemoteToLocalOnLoginCallCount` が1になる

### テストケース3: 登録に失敗した場合、Left(Failure)がそのまま返り、ログイン時同期は実行されない
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository.signUpWithEmailResult` に `Left(Failure.unknown('already exists'))` を設定
- **入力値・テスト条件**: 既に使われているメールアドレス
- **操作手順**: `useCase.call(...)` を呼ぶ
- **期待結果**: 戻り値が `Left(Failure.unknown('already exists'))` と一致し、`syncRemoteToLocalOnLoginCallCount` は0のまま

### テストケース4: 登録成功後の同期処理で例外が発生した場合、例外は握りつぶされ登録結果はそのまま返る
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository.signUpWithEmailResult` に `Right(AppUser)`、
  `FakeSyncServiceForLogin.exceptionToThrow` に `Exception('sync failed')` を設定
- **入力値・テスト条件**: 有効な email/password
- **操作手順**: `useCase.call(...)` を呼ぶ
- **期待結果**: `useCase.call()` は例外を投げず、戻り値は設定した `Right(AppUser)` のまま。`syncRemoteToLocalOnLoginCallCount` は1

### テストケース5: 新規登録に成功した（リモートにデータなし）場合、戻り値がRight(AppUser)になり、getFoldersの戻り値が空になる [SYN-L07]
- **カテゴリ**: 正常系
- **対象メソッド**: call()
- **事前条件**: 本物の `SyncService` + `_FakeSignUpSyncRemoteDataSource`（リモートにデータを seed しない）+
  本物の SQLite（一時ディレクトリ）。`FakeAuthRepository.signUpWithEmailResult` に `Right(AppUser)` を設定
- **入力値・テスト条件**: 有効な email/password。リモートにフォルダ・単語のデータなし
- **操作手順**: `realUseCase.call(email: ..., password: ...)` を呼ぶ
- **期待結果**: 戻り値が `Right(AppUser)` になり、`FolderRepositoryImpl.getFolders(userId: userId)` の戻り値が空になる

### テストケース6: 新規登録に成功し、その後の取得がリモートの失敗で失敗した場合、戻り値がRight(AppUser)になる [SYN-L08]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: 本物の `SyncService` + `_FakeSignUpSyncRemoteDataSource`（`failFetch = true`）。
  `FakeAuthRepository.signUpWithEmailResult` に `Right(AppUser)` を設定
- **入力値・テスト条件**: 有効な email/password。リモートの `fetchChanges` が例外を投げる
- **操作手順**: `realUseCase.call(email: ..., password: ...)` を呼ぶ
- **期待結果**: 戻り値が `Right(AppUser)` になる（同期の失敗が登録結果に影響しない）

### テストケース7: 新規登録がAuthFailureで失敗した場合、戻り値がLeft(AuthFailure)になり、リモートへのデータの読み取りが呼ばれない [SYN-L09]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository.signUpWithEmailResult` に `Left(Failure.auth())` を設定。
  リモートにフォルダFを seed 済み
- **入力値・テスト条件**: 有効な email/password（登録が AuthFailure で失敗する状況）
- **操作手順**: `realUseCase.call(email: ..., password: ...)` を呼ぶ
- **期待結果**: 戻り値が `Left(Failure.auth())` になり、`getFolders` の戻り値は空のまま、
  `_FakeSignUpSyncRemoteDataSource.fetchCallCount` は0のまま（リモートへのデータの読み取りが呼ばれない）

### テストケース8: アカウント作成と送信が成功した場合、Right(AppUser A)が返り、送信が規約・ポリシー2026-01-01で1回、初回の同期が1回呼ばれる [LGL-T01]
- **カテゴリ**: 正常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository` / `FakeSyncServiceForLogin` / `_FakeLegalRepository` の戻り値を差し替える
- **入力値・テスト条件**: 仕様書 6.3 節 LGL-T01 の条件
- **操作手順**: `call(email, password, termsVersion, privacyVersion)` を呼ぶ
- **期待結果**: 仕様書 6.3 節 LGL-T01 の期待される結果

### テストケース9: アカウント作成がLeft(AuthFailure)の場合、Left(AuthFailure)が返り、送信は0回、初回の同期は0回 [LGL-T02]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository` / `FakeSyncServiceForLogin` / `_FakeLegalRepository` の戻り値を差し替える
- **入力値・テスト条件**: 仕様書 6.3 節 LGL-T02 の条件
- **操作手順**: `call(email, password, termsVersion, privacyVersion)` を呼ぶ
- **期待結果**: 仕様書 6.3 節 LGL-T02 の期待される結果

### テストケース10: 送信がLeft(UnknownFailure)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T03]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository` / `FakeSyncServiceForLogin` / `_FakeLegalRepository` の戻り値を差し替える
- **入力値・テスト条件**: 仕様書 6.3 節 LGL-T03 の条件
- **操作手順**: `call(email, password, termsVersion, privacyVersion)` を呼ぶ
- **期待結果**: 仕様書 6.3 節 LGL-T03 の期待される結果

### テストケース11: 送信がRight(outdated)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T04]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository` / `FakeSyncServiceForLogin` / `_FakeLegalRepository` の戻り値を差し替える
- **入力値・テスト条件**: 仕様書 6.3 節 LGL-T04 の条件
- **操作手順**: `call(email, password, termsVersion, privacyVersion)` を呼ぶ
- **期待結果**: 仕様書 6.3 節 LGL-T04 の期待される結果

### テストケース12: 送信が成功する場合、送信は初回の同期より先に呼ばれる [LGL-T05]
- **カテゴリ**: 正常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository` / `FakeSyncServiceForLogin` / `_FakeLegalRepository` の戻り値を差し替える
- **入力値・テスト条件**: 仕様書 6.3 節 LGL-T05 の条件
- **操作手順**: `call(email, password, termsVersion, privacyVersion)` を呼ぶ
- **期待結果**: 仕様書 6.3 節 LGL-T05 の期待される結果

### テストケース13: 送信がLeft(NetworkFailure)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T06]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository` / `FakeSyncServiceForLogin` / `_FakeLegalRepository` の戻り値を差し替える
- **入力値・テスト条件**: 仕様書 6.3 節 LGL-T06 の条件
- **操作手順**: `call(email, password, termsVersion, privacyVersion)` を呼ぶ
- **期待結果**: 仕様書 6.3 節 LGL-T06 の期待される結果

### テストケース14: 送信がLeft(AuthFailure)の場合、Right(AppUser A)が返り、初回の同期が1回呼ばれる [LGL-T07]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository` / `FakeSyncServiceForLogin` / `_FakeLegalRepository` の戻り値を差し替える
- **入力値・テスト条件**: 仕様書 6.3 節 LGL-T07 の条件
- **操作手順**: `call(email, password, termsVersion, privacyVersion)` を呼ぶ
- **期待結果**: 仕様書 6.3 節 LGL-T07 の期待される結果

### テストケース15: アカウント作成がLeft(NetworkFailure)の場合、Left(NetworkFailure)が返り、送信は0回、初回の同期は0回 [LGL-T08]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: `FakeAuthRepository` / `FakeSyncServiceForLogin` / `_FakeLegalRepository` の戻り値を差し替える
- **入力値・テスト条件**: 仕様書 6.3 節 LGL-T08 の条件
- **操作手順**: `call(email, password, termsVersion, privacyVersion)` を呼ぶ
- **期待結果**: 仕様書 6.3 節 LGL-T08 の期待される結果
