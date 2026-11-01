## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/infrastructure/repositories/reauthentication_repository_impl.dart |
| クラス名 | ReauthenticationRepositoryImpl |
| テスト対象メソッド | reauthenticateWithPassword() / reauthenticateWithGoogle() |
| 仕様書 | docs/detailed_design/presentation/settings/settings_page.md |

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | 本人確認が成功した場合、Right(unit) が返り、本人確認に渡したパスワードは引数と同じ [ACD-R52] | ACD-R52 #c25ea5 | 正常系 | reauthenticateWithPassword() | ✅ |
| 2 | エラーコード wrong-password で失敗した場合、Left(AuthFailure) が返る [ACD-R53] | ACD-R53 #011572 | 異常系 | reauthenticateWithPassword() | ✅ |
| 3 | エラーコード invalid-credential で失敗した場合、Left(AuthFailure) が返る [ACD-R54] | ACD-R54 #aa4b90 | 異常系 | reauthenticateWithPassword() | ✅ |
| 4 | エラーコード network-request-failed で失敗した場合、Left(NetworkFailure) が返る [ACD-R55] | ACD-R55 #77b3ea | 異常系 | reauthenticateWithPassword() | ✅ |
| 5 | エラーコード too-many-requests で失敗した場合、Left(TooManyRequestsFailure) が返る [ACD-R56] | ACD-R56 #1db7db | 異常系 | reauthenticateWithPassword() | ✅ |
| 6 | FirebaseAuthException 以外の例外で失敗した場合、Left(UnknownFailure) が返る [ACD-R57] | ACD-R57 #78a316 | 異常系 | reauthenticateWithPassword() | ✅ |
| 7 | エラーコード user-mismatch で失敗した場合、Left(AuthFailure) が返る [ACD-R65] | ACD-R65 #c20d6e | 異常系 | reauthenticateWithPassword() | ✅ |
| 8 | エラーコード user-not-found で失敗した場合、Left(AuthFailure) が返る [ACD-R66] | ACD-R66 #5bdec5 | 異常系 | reauthenticateWithPassword() | ✅ |
| 9 | ログインしていない場合、Left(UnknownFailure) が返り、本人確認は0回 [ACD-R67] | ACD-R67 #cc8d38 | 異常系 | reauthenticateWithPassword() | ✅ |
| 10 | メールアドレス「a@example.com」のユーザーでログイン中に「pass1234」で呼んだ場合、本人確認にそのメールアドレスとパスワードが渡される [ACD-R68] | ACD-R68 #7c2599 | 正常系 | reauthenticateWithPassword() | ✅ |
| 11 | エラーコード user-disabled で失敗した場合、Left(UnknownFailure) が返る [ACD-R75] | ACD-R75 #3e0727 | 異常系 | reauthenticateWithPassword() | ✅ |
| 12 | Google の本人確認が成功した場合、Right(true) が返る [ACD-R58] | ACD-R58 #21e96f | 正常系 | reauthenticateWithGoogle() | ✅ |
| 13 | Google のアカウント選択がキャンセルされた場合、Right(false) が返る [ACD-R59] | ACD-R59 #1cbdc2 | 正常系 | reauthenticateWithGoogle() | ✅ |
| 14 | エラーコード user-mismatch で失敗した場合、Left(AuthFailure) が返る [ACD-R60] | ACD-R60 #798bbe | 異常系 | reauthenticateWithGoogle() | ✅ |
| 15 | エラーコード network-request-failed で失敗した場合、Left(NetworkFailure) が返る [ACD-R61] | ACD-R61 #915749 | 異常系 | reauthenticateWithGoogle() | ✅ |
| 16 | FirebaseAuthException 以外の例外で失敗した場合、Left(UnknownFailure) が返る [ACD-R62] | ACD-R62 #38088e | 異常系 | reauthenticateWithGoogle() | ✅ |
| 17 | エラーコード invalid-credential で失敗した場合、Left(AuthFailure) が返る [ACD-R69] | ACD-R69 #c76515 | 異常系 | reauthenticateWithGoogle() | ✅ |
| 18 | ログインしていない場合、Left(UnknownFailure) が返り、Google のアカウント選択は表示されない [ACD-R70] | ACD-R70 #38d1eb | 異常系 | reauthenticateWithGoogle() | ✅ |
| 19 | エラーコード user-not-found で失敗した場合、Left(AuthFailure) が返る [ACD-R73] | ACD-R73 #83b28e | 異常系 | reauthenticateWithGoogle() | ✅ |
| 20 | エラーコード too-many-requests で失敗した場合、Left(TooManyRequestsFailure) が返る [ACD-R74] | ACD-R74 #cb340a | 異常系 | reauthenticateWithGoogle() | ✅ |

## テストケース詳細

### テストケース1: 本人確認が成功した場合、Right(unit) が返り、本人確認に渡したパスワードは引数と同じ [ACD-R52]
- **カテゴリ**: 正常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: Firebase Authentication の本人確認が成功した
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: `Right(unit)`。本人確認に渡したパスワードは引数と同じ

### テストケース2: エラーコード wrong-password で失敗した場合、Left(AuthFailure) が返る [ACD-R53]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `wrong-password` で失敗した
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: `Left(AuthFailure)`

### テストケース3: エラーコード invalid-credential で失敗した場合、Left(AuthFailure) が返る [ACD-R54]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `invalid-credential` で失敗した
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: `Left(AuthFailure)`

### テストケース4: エラーコード network-request-failed で失敗した場合、Left(NetworkFailure) が返る [ACD-R55]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `network-request-failed` で失敗した
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: `Left(NetworkFailure)`

### テストケース5: エラーコード too-many-requests で失敗した場合、Left(TooManyRequestsFailure) が返る [ACD-R56]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `too-many-requests` で失敗した
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: `Left(TooManyRequestsFailure)`

### テストケース6: FirebaseAuthException 以外の例外で失敗した場合、Left(UnknownFailure) が返る [ACD-R57]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認が `FirebaseAuthException` 以外の例外で失敗した
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: `Left(UnknownFailure)`

### テストケース7: エラーコード user-mismatch で失敗した場合、Left(AuthFailure) が返る [ACD-R65]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `user-mismatch` で失敗した
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: `Left(AuthFailure)`

### テストケース8: エラーコード user-not-found で失敗した場合、Left(AuthFailure) が返る [ACD-R66]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `user-not-found` で失敗した
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: `Left(AuthFailure)`

### テストケース9: ログインしていない場合、Left(UnknownFailure) が返り、本人確認は0回 [ACD-R67]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: ログインしていない（現在のユーザーが無い）状態で呼んだ
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: `Left(UnknownFailure)`。本人確認は0回

### テストケース10: メールアドレス「a@example.com」のユーザーでログイン中に「pass1234」で呼んだ場合、本人確認にそのメールアドレスとパスワードが渡される [ACD-R68]
- **カテゴリ**: 正常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: メールアドレス「a@example.com」のユーザーでログイン中に「pass1234」で呼んだ
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: 本人確認に、メールアドレス「a@example.com」とパスワード「pass1234」が渡される

### テストケース11: エラーコード user-disabled で失敗した場合、Left(UnknownFailure) が返る [ACD-R75]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithPassword()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `user-disabled` で失敗した
- **操作手順**: `reauthenticateWithPassword()` を呼ぶ
- **期待結果**: `Left(UnknownFailure)`

### テストケース12: Google の本人確認が成功した場合、Right(true) が返る [ACD-R58]
- **カテゴリ**: 正常系
- **対象メソッド**: reauthenticateWithGoogle()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: Google の本人確認が成功した
- **操作手順**: `reauthenticateWithGoogle()` を呼ぶ
- **期待結果**: `Right(true)`

### テストケース13: Google のアカウント選択がキャンセルされた場合、Right(false) が返る [ACD-R59]
- **カテゴリ**: 正常系
- **対象メソッド**: reauthenticateWithGoogle()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: Google のアカウント選択がキャンセルされた
- **操作手順**: `reauthenticateWithGoogle()` を呼ぶ
- **期待結果**: `Right(false)`

### テストケース14: エラーコード user-mismatch で失敗した場合、Left(AuthFailure) が返る [ACD-R60]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithGoogle()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `user-mismatch` で失敗した（ログイン中と別のアカウントを選んだ）
- **操作手順**: `reauthenticateWithGoogle()` を呼ぶ
- **期待結果**: `Left(AuthFailure)`

### テストケース15: エラーコード network-request-failed で失敗した場合、Left(NetworkFailure) が返る [ACD-R61]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithGoogle()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `network-request-failed` で失敗した
- **操作手順**: `reauthenticateWithGoogle()` を呼ぶ
- **期待結果**: `Left(NetworkFailure)`

### テストケース16: FirebaseAuthException 以外の例外で失敗した場合、Left(UnknownFailure) が返る [ACD-R62]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithGoogle()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認が `FirebaseAuthException` 以外の例外で失敗した
- **操作手順**: `reauthenticateWithGoogle()` を呼ぶ
- **期待結果**: `Left(UnknownFailure)`

### テストケース17: エラーコード invalid-credential で失敗した場合、Left(AuthFailure) が返る [ACD-R69]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithGoogle()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `invalid-credential` で失敗した
- **操作手順**: `reauthenticateWithGoogle()` を呼ぶ
- **期待結果**: `Left(AuthFailure)`

### テストケース18: ログインしていない場合、Left(UnknownFailure) が返り、Google のアカウント選択は表示されない [ACD-R70]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithGoogle()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: ログインしていない（現在のユーザーが無い）状態で呼んだ
- **操作手順**: `reauthenticateWithGoogle()` を呼ぶ
- **期待結果**: `Left(UnknownFailure)`。Google のアカウント選択は表示されない

### テストケース19: エラーコード user-not-found で失敗した場合、Left(AuthFailure) が返る [ACD-R73]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithGoogle()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `user-not-found` で失敗した
- **操作手順**: `reauthenticateWithGoogle()` を呼ぶ
- **期待結果**: `Left(AuthFailure)`

### テストケース20: エラーコード too-many-requests で失敗した場合、Left(TooManyRequestsFailure) が返る [ACD-R74]
- **カテゴリ**: 異常系
- **対象メソッド**: reauthenticateWithGoogle()
- **事前条件**: 手書き Fake の FirebaseAuth / User / GoogleSignIn を本物の ReauthenticationRemoteDataSource に渡した Repository
- **入力値・テスト条件**: 本人確認がエラーコード `too-many-requests` で失敗した
- **操作手順**: `reauthenticateWithGoogle()` を呼ぶ
- **期待結果**: `Left(TooManyRequestsFailure)`

