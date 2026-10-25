## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/application/use_cases/legal/get_legal_config_use_case.dart |
| クラス名 | GetLegalConfigUseCase |
| テスト対象メソッド | call() |
| 仕様書 | docs/detailed_design/legal_consent/legal_consent.md |

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | fetchLegalConfig が Right(LegalConfig) を返す場合、同じ LegalConfig の Right になる [LGL-G01] | LGL-G01 #421ada | 正常系 | call() | ✅ |
| 2 | fetchLegalConfig が Left(NotFoundFailure) を返す場合、既定値の LegalConfig の Right になる [LGL-G02] | LGL-G02 #31acd3 | 異常系 | call() | ✅ |
| 3 | fetchLegalConfig が Left(NetworkFailure) を返す場合、Left(NetworkFailure) になる [LGL-G03] | LGL-G03 #780a52 | 異常系 | call() | ✅ |
| 4 | fetchLegalConfig が Left(UnknownFailure) を返す場合、Left(UnknownFailure) になる [LGL-G04] | LGL-G04 #390879 | 異常系 | call() | ✅ |
| 5 | privacyUrl だけが欠けて fetchLegalConfig が Left(NotFoundFailure) を返す場合、4項目すべて既定値の Right になる [LGL-G05] | LGL-G05 #a87123 | 境界値 | call() | ✅ |

## テストケース詳細

### テストケース1: fetchLegalConfig が Right(LegalConfig) を返す場合、同じ LegalConfig の Right になる [LGL-G01]
- **カテゴリ**: 正常系
- **対象メソッド**: call()
- **事前条件**: fetchLegalConfig の戻り値を差し替えられる Fake
- **入力値・テスト条件**: 仕様書 6.2 節 LGL-G01 の条件
- **操作手順**: `call() を呼ぶ`
- **期待結果**: 仕様書 6.2 節 LGL-G01 の期待される結果

### テストケース2: fetchLegalConfig が Left(NotFoundFailure) を返す場合、既定値の LegalConfig の Right になる [LGL-G02]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: fetchLegalConfig の戻り値を差し替えられる Fake
- **入力値・テスト条件**: 仕様書 6.2 節 LGL-G02 の条件
- **操作手順**: `call() を呼ぶ`
- **期待結果**: 仕様書 6.2 節 LGL-G02 の期待される結果

### テストケース3: fetchLegalConfig が Left(NetworkFailure) を返す場合、Left(NetworkFailure) になる [LGL-G03]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: fetchLegalConfig の戻り値を差し替えられる Fake
- **入力値・テスト条件**: 仕様書 6.2 節 LGL-G03 の条件
- **操作手順**: `call() を呼ぶ`
- **期待結果**: 仕様書 6.2 節 LGL-G03 の期待される結果

### テストケース4: fetchLegalConfig が Left(UnknownFailure) を返す場合、Left(UnknownFailure) になる [LGL-G04]
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: fetchLegalConfig の戻り値を差し替えられる Fake
- **入力値・テスト条件**: 仕様書 6.2 節 LGL-G04 の条件
- **操作手順**: `call() を呼ぶ`
- **期待結果**: 仕様書 6.2 節 LGL-G04 の期待される結果

### テストケース5: privacyUrl だけが欠けて fetchLegalConfig が Left(NotFoundFailure) を返す場合、4項目すべて既定値の Right になる [LGL-G05]
- **カテゴリ**: 境界値
- **対象メソッド**: call()
- **事前条件**: fetchLegalConfig の戻り値を差し替えられる Fake
- **入力値・テスト条件**: 仕様書 6.2 節 LGL-G05 の条件
- **操作手順**: `call() を呼ぶ`
- **期待結果**: 仕様書 6.2 節 LGL-G05 の期待される結果

## 検証の範囲（補足）

- LGL-G05：Fake の LegalRepository からは「項目の一部が欠けている」を作れないため、入力は G02（`Left(NotFoundFailure)`）と同じになる。項目が欠けたときに `NotFoundFailure` を返すことは Repository 実装側（LGL-R03〜R07, R24, R29〜R33, R41〜R45）で確かめている。このテストでは、置き換え後の4項目すべてが既定値になることを確かめる
