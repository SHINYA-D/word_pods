## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/infrastructure/repositories/account_repository_impl.dart |
| クラス名 | AccountRepositoryImpl |
| テスト対象メソッド | fetchIsDeveloper() |
| 仕様書 | docs/detailed_design/presentation/shell/shell_page.md |

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | accounts/u1 が {isDeveloper: true} の場合、Right(true) になる [SHL-R01] | SHL-R01 #120624 | 正常系 | fetchIsDeveloper() | ✅ |
| 2 | accounts/u1 が {isDeveloper: false} の場合、Right(false) になる [SHL-R02] | SHL-R02 #4186be | 正常系 | fetchIsDeveloper() | ✅ |
| 3 | accounts/u1 が存在しない場合、Right(false) になる [SHL-R03] | SHL-R03 #7caf12 | 正常系 | fetchIsDeveloper() | ✅ |
| 4 | accounts/u1 はあるが isDeveloper が無い場合、Right(false) になる [SHL-R04] | SHL-R04 #c832b8 | 境界値 | fetchIsDeveloper() | ✅ |
| 5 | accounts/u1 が {isDeveloper: "true"}（文字列）の場合、Right(false) になる [SHL-R05] | SHL-R05 #570ab6 | 境界値 | fetchIsDeveloper() | ✅ |
| 6 | accounts/u2 が {isDeveloper: true} で accounts/u1 は存在しない場合、fetchIsDeveloper(u1) は Right(false) になる [SHL-R06] | SHL-R06 #d0c34d | 正常系 | fetchIsDeveloper() | ✅ |
| 7 | Firestore の読み取りがコード unavailable の例外で失敗した場合、Left(UnknownFailure) になる [SHL-R07] | SHL-R07 #ba530f | 異常系 | fetchIsDeveloper() | ✅ |
| 8 | Firestore の読み取りがコード permission-denied の例外で失敗した場合、Left(UnknownFailure) になる [SHL-R08] | SHL-R08 #f9d981 | 異常系 | fetchIsDeveloper() | ✅ |
| 9 | 1回目が Right(true) で2回目の読み取りが unavailable で失敗した場合、2回目は Left(UnknownFailure) になり前回の値を返さない [SHL-R09] | SHL-R09 #5fcbc2 | 異常系 | fetchIsDeveloper() | ✅ |
| 10 | Firestore の読み取りがコード deadline-exceeded の例外で失敗した場合、Left(UnknownFailure) になる [SHL-R10] | SHL-R10 #8cbee2 | 異常系 | fetchIsDeveloper() | ✅ |
| 11 | Firestore の読み取りが Firebase 以外の例外（StateError）で失敗した場合、Left(UnknownFailure) になる [SHL-R11] | SHL-R11 #46da83 | 異常系 | fetchIsDeveloper() | ✅ |
| 12 | accounts/u1 が {isDeveloper: null} の場合、Right(false) になる [SHL-R12] | SHL-R12 #931982 | 境界値 | fetchIsDeveloper() | ✅ |
| 13 | accounts/u1 が {isDeveloper: 1}（数値）の場合、Right(false) になる [SHL-R13] | SHL-R13 #7a14c6 | 境界値 | fetchIsDeveloper() | ✅ |

## テストケース詳細

### テストケース1: accounts/u1 が {isDeveloper: true} の場合、Right(true) になる [SHL-R01]
- **カテゴリ**: 正常系
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: accounts/u1 が {isDeveloper: true}
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Right(true)

### テストケース2: accounts/u1 が {isDeveloper: false} の場合、Right(false) になる [SHL-R02]
- **カテゴリ**: 正常系
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: accounts/u1 が {isDeveloper: false}
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Right(false)

### テストケース3: accounts/u1 が存在しない場合、Right(false) になる [SHL-R03]
- **カテゴリ**: 正常系
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: accounts/u1 が存在しない
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Right(false)

### テストケース4: accounts/u1 はあるが isDeveloper が無い場合、Right(false) になる [SHL-R04]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: accounts/u1 はあるが isDeveloper が無い
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Right(false)

### テストケース5: accounts/u1 が {isDeveloper: "true"}（文字列）の場合、Right(false) になる [SHL-R05]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: accounts/u1 が {isDeveloper: "true"}（文字列）
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Right(false)

### テストケース6: accounts/u2 が {isDeveloper: true} で accounts/u1 は存在しない場合、fetchIsDeveloper(u1) は Right(false) になる [SHL-R06]
- **カテゴリ**: 正常系
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: accounts/u2 が {isDeveloper: true} で accounts/u1 は存在しない
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Right(false)

### テストケース7: Firestore の読み取りがコード unavailable の例外で失敗した場合、Left(UnknownFailure) になる [SHL-R07]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: 読み取りが unavailable で失敗する
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Left(UnknownFailure)

### テストケース8: Firestore の読み取りがコード permission-denied の例外で失敗した場合、Left(UnknownFailure) になる [SHL-R08]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: 読み取りが permission-denied で失敗する
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Left(UnknownFailure)

### テストケース9: 1回目が Right(true) で2回目の読み取りが unavailable で失敗した場合、2回目は Left(UnknownFailure) になり前回の値を返さない [SHL-R09]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: 1回目は成功(true)、2回目は unavailable で失敗する
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: 1回目 Right(true)、2回目 Left(UnknownFailure)（前回の値を返さない）

### テストケース10: Firestore の読み取りがコード deadline-exceeded の例外で失敗した場合、Left(UnknownFailure) になる [SHL-R10]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: 読み取りが deadline-exceeded で失敗する
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Left(UnknownFailure)

### テストケース11: Firestore の読み取りが Firebase 以外の例外（StateError）で失敗した場合、Left(UnknownFailure) になる [SHL-R11]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: 読み取りが StateError で失敗する
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Left(UnknownFailure)

### テストケース12: accounts/u1 が {isDeveloper: null} の場合、Right(false) になる [SHL-R12]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: accounts/u1 が {isDeveloper: null}
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Right(false)

### テストケース13: accounts/u1 が {isDeveloper: 1}（数値）の場合、Right(false) になる [SHL-R13]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchIsDeveloper()
- **事前条件**: accounts/u1 が {isDeveloper: 1}（数値）
- **入力値・テスト条件**: userId=u1
- **操作手順**: `fetchIsDeveloper(u1)` を呼ぶ
- **期待結果**: Right(false)
