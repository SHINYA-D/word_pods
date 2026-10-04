## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/presentation/shell/shell_view_model.dart |
| クラス名 | developerStatusProvider / isDeveloperProvider |
| テスト対象メソッド | isDeveloper（isDeveloperProvider の値） |
| 仕様書 | docs/detailed_design/presentation/shell/shell_page.md |

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | ユーザー u1 でログインし fetchIsDeveloper が Right(true) を返した場合、isDeveloper が true になり、u1 で1回呼ばれる [SHL-V01] | SHL-V01 #4b4144 | 正常系 | isDeveloper | ✅ |
| 2 | ユーザー u1 でログインし fetchIsDeveloper が Right(false) を返した場合、isDeveloper が false になる [SHL-V02] | SHL-V02 #cfda62 | 正常系 | isDeveloper | ✅ |
| 3 | ユーザー u1 でログインし fetchIsDeveloper が完了していない場合、isDeveloper が false になる [SHL-V03] | SHL-V03 #a6723d | 境界値 | isDeveloper | ✅ |
| 4 | ユーザー u1 でログインし fetchIsDeveloper が Left(UnknownFailure) を返した場合、isDeveloper が false になる [SHL-V04] | SHL-V04 #fcdaa8 | 異常系 | isDeveloper | ✅ |
| 5 | ログインしていない状態でアプリを起動した場合、isDeveloper が false で、fetchIsDeveloper は呼ばれない [SHL-V05] | SHL-V05 #452324 | 境界値 | isDeveloper | ✅ |
| 6 | u1（開発者）でログインしてログアウトし u2 でログインし直して Right(false) を返した場合、isDeveloper が false で u1・u2 で1回ずつ呼ばれる [SHL-V06] | SHL-V06 #90373b | 正常系 | isDeveloper | ✅ |
| 7 | u1（開発者でない）でログインしてログアウトし u2 でログインし直して Right(true) を返した場合、isDeveloper が true になる [SHL-V07] | SHL-V07 #d81ed2 | 正常系 | isDeveloper | ✅ |
| 8 | u1 で Right(false) を返した後ログインし直さず Right(true) を返すように変わった場合、isDeveloper は false のままで1回だけ呼ばれる [SHL-V08] | SHL-V08 #e32bb7 | 境界値 | isDeveloper | ✅ |
| 9 | u1 の fetchIsDeveloper が完了していない状態から Right(true) で完了した場合、isDeveloper が false から true に変わる [SHL-V09] | SHL-V09 #c3e851 | 正常系 | isDeveloper | ✅ |
| 10 | u1 で Right(false) を返しログアウトして同じ u1 でログインし直し Right(true) を返した場合、isDeveloper が true で u1 で2回呼ばれる [SHL-V10] | SHL-V10 #26209b | 正常系 | isDeveloper | ✅ |
| 11 | ユーザー u1 でログインし fetchIsDeveloper が Left(NetworkFailure) を返した場合、isDeveloper が false になる [SHL-V11] | SHL-V11 #7d5624 | 異常系 | isDeveloper | ✅ |
| 12 | ユーザー u1 でログインし fetchIsDeveloper が Left(AuthFailure) を返した場合、isDeveloper が false になる [SHL-V12] | SHL-V12 #ff39b3 | 異常系 | isDeveloper | ✅ |
| 13 | ユーザー u1 でログインし fetchIsDeveloper が Left(NotFoundFailure) を返した場合、isDeveloper が false になる [SHL-V13] | SHL-V13 #55449f | 異常系 | isDeveloper | ✅ |
| 14 | u1（開発者）でログインしてログアウトし u2 でログインし直して Left(UnknownFailure) を返した場合、isDeveloper が false になる [SHL-V14] | SHL-V14 #ca9a4e | 異常系 | isDeveloper | ✅ |
| 15 | u1 の読み込み中にログアウトして u2 でログインし直し、u2 が Right(false) を返した後に u1 が Right(true) を返した場合、isDeveloper は false のままになる [SHL-V15] | SHL-V15 #72515b | 境界値 | isDeveloper | ✅ |
| 16 | u1（開発者）でログインしてログアウトし u2 でログインし直して u2 の fetchIsDeveloper が完了していない場合、isDeveloper が false になる [SHL-V16] | SHL-V16 #2534f3 | 境界値 | isDeveloper | ✅ |
| 17 | u1（開発者）でログインしてログアウトした場合、isDeveloper が false になる [SHL-V17] | SHL-V17 #49a973 | 境界値 | isDeveloper | ✅ |
| 18 | u1 の読み込み中にログアウトして u2 でログインし直し、u2 の完了前に u1 が Right(true) を返した場合、isDeveloper が false になる [SHL-V18] | SHL-V18 #5e6ac6 | 境界値 | isDeveloper | ✅ |

## テストケース詳細

### テストケース1: ユーザー u1 でログインし fetchIsDeveloper が Right(true) を返した場合、isDeveloper が true になり、u1 で1回呼ばれる [SHL-V01]
- **カテゴリ**: 正常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V01 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: ユーザー u1 でログインし fetchIsDeveloper が Right(true) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が true になり、u1 で1回呼ばれる

### テストケース2: ユーザー u1 でログインし fetchIsDeveloper が Right(false) を返した場合、isDeveloper が false になる [SHL-V02]
- **カテゴリ**: 正常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V02 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: ユーザー u1 でログインし fetchIsDeveloper が Right(false) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false になる

### テストケース3: ユーザー u1 でログインし fetchIsDeveloper が完了していない場合、isDeveloper が false になる [SHL-V03]
- **カテゴリ**: 境界値
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V03 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: ユーザー u1 でログインし fetchIsDeveloper が完了していない場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false になる

### テストケース4: ユーザー u1 でログインし fetchIsDeveloper が Left(UnknownFailure) を返した場合、isDeveloper が false になる [SHL-V04]
- **カテゴリ**: 異常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V04 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: ユーザー u1 でログインし fetchIsDeveloper が Left(UnknownFailure) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false になる

### テストケース5: ログインしていない状態でアプリを起動した場合、isDeveloper が false で、fetchIsDeveloper は呼ばれない [SHL-V05]
- **カテゴリ**: 境界値
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V05 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: ログインしていない状態でアプリを起動した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false で、fetchIsDeveloper は呼ばれない

### テストケース6: u1（開発者）でログインしてログアウトし u2 でログインし直して Right(false) を返した場合、isDeveloper が false で u1・u2 で1回ずつ呼ばれる [SHL-V06]
- **カテゴリ**: 正常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V06 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: u1（開発者）でログインしてログアウトし u2 でログインし直して Right(false) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false で u1・u2 で1回ずつ呼ばれる

### テストケース7: u1（開発者でない）でログインしてログアウトし u2 でログインし直して Right(true) を返した場合、isDeveloper が true になる [SHL-V07]
- **カテゴリ**: 正常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V07 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: u1（開発者でない）でログインしてログアウトし u2 でログインし直して Right(true) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が true になる

### テストケース8: u1 で Right(false) を返した後ログインし直さず Right(true) を返すように変わった場合、isDeveloper は false のままで1回だけ呼ばれる [SHL-V08]
- **カテゴリ**: 境界値
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V08 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: u1 で Right(false) を返した後ログインし直さず Right(true) を返すように変わった場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper は false のままで1回だけ呼ばれる

### テストケース9: u1 の fetchIsDeveloper が完了していない状態から Right(true) で完了した場合、isDeveloper が false から true に変わる [SHL-V09]
- **カテゴリ**: 正常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V09 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: u1 の fetchIsDeveloper が完了していない状態から Right(true) で完了した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false から true に変わる

### テストケース10: u1 で Right(false) を返しログアウトして同じ u1 でログインし直し Right(true) を返した場合、isDeveloper が true で u1 で2回呼ばれる [SHL-V10]
- **カテゴリ**: 正常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V10 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: u1 で Right(false) を返しログアウトして同じ u1 でログインし直し Right(true) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が true で u1 で2回呼ばれる

### テストケース11: ユーザー u1 でログインし fetchIsDeveloper が Left(NetworkFailure) を返した場合、isDeveloper が false になる [SHL-V11]
- **カテゴリ**: 異常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V11 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: ユーザー u1 でログインし fetchIsDeveloper が Left(NetworkFailure) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false になる

### テストケース12: ユーザー u1 でログインし fetchIsDeveloper が Left(AuthFailure) を返した場合、isDeveloper が false になる [SHL-V12]
- **カテゴリ**: 異常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V12 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: ユーザー u1 でログインし fetchIsDeveloper が Left(AuthFailure) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false になる

### テストケース13: ユーザー u1 でログインし fetchIsDeveloper が Left(NotFoundFailure) を返した場合、isDeveloper が false になる [SHL-V13]
- **カテゴリ**: 異常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V13 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: ユーザー u1 でログインし fetchIsDeveloper が Left(NotFoundFailure) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false になる

### テストケース14: u1（開発者）でログインしてログアウトし u2 でログインし直して Left(UnknownFailure) を返した場合、isDeveloper が false になる [SHL-V14]
- **カテゴリ**: 異常系
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V14 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: u1（開発者）でログインしてログアウトし u2 でログインし直して Left(UnknownFailure) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false になる

### テストケース15: u1 の読み込み中にログアウトして u2 でログインし直し、u2 が Right(false) を返した後に u1 が Right(true) を返した場合、isDeveloper は false のままになる [SHL-V15]
- **カテゴリ**: 境界値
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V15 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: u1 の読み込み中にログアウトして u2 でログインし直し、u2 が Right(false) を返した後に u1 が Right(true) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper は false のままになる

### テストケース16: u1（開発者）でログインしてログアウトし u2 でログインし直して u2 の fetchIsDeveloper が完了していない場合、isDeveloper が false になる [SHL-V16]
- **カテゴリ**: 境界値
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V16 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: u1（開発者）でログインしてログアウトし u2 でログインし直して u2 の fetchIsDeveloper が完了していない場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false になる

### テストケース17: u1（開発者）でログインしてログアウトした場合、isDeveloper が false になる [SHL-V17]
- **カテゴリ**: 境界値
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V17 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: u1（開発者）でログインしてログアウトした場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false になる

### テストケース18: u1 の読み込み中にログアウトして u2 でログインし直し、u2 の完了前に u1 が Right(true) を返した場合、isDeveloper が false になる [SHL-V18]
- **カテゴリ**: 境界値
- **対象メソッド**: isDeveloper
- **事前条件**: 仕様書 SHL-V18 の条件のとおり（currentUser を差し替え、AccountRepository を Fake で差し替える）
- **入力値・テスト条件**: u1 の読み込み中にログアウトして u2 でログインし直し、u2 の完了前に u1 が Right(true) を返した場合
- **操作手順**: ログイン・ログアウトを再現し、fetchIsDeveloper の応答を制御して isDeveloperProvider を読む
- **期待結果**: isDeveloper が false になる

