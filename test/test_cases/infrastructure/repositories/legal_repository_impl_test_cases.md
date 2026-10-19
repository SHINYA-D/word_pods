## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/infrastructure/repositories/legal_repository_impl.dart |
| クラス名 | LegalRepositoryImpl |
| テスト対象メソッド | fetchLegalConfig() / fetchConsents() / accept() |
| 仕様書 | docs/detailed_design/legal_consent/legal_consent.md |

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | app_config/legal に4項目がすべて文字列である場合、Right(LegalConfig) になる [LGL-R01] | LGL-R01 #b13ece | 正常系 | fetchLegalConfig() | ✅ |
| 2 | app_config/legal が無い場合、Left(NotFoundFailure) になる [LGL-R02] | LGL-R02 #3535cd | 異常系 | fetchLegalConfig() | ✅ |
| 3 | app_config/legal に termsVersion が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R03] | LGL-R03 #4a7b5d | 異常系 | fetchLegalConfig() | ✅ |
| 4 | app_config/legal に privacyVersion が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R04] | LGL-R04 #7318d6 | 異常系 | fetchLegalConfig() | ✅ |
| 5 | app_config/legal の termsVersion が数値の 20260101で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R05] | LGL-R05 #498c8d | 異常系 | fetchLegalConfig() | ✅ |
| 6 | app_config/legal に termsUrl が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R06] | LGL-R06 #61ca79 | 異常系 | fetchLegalConfig() | ✅ |
| 7 | app_config/legal に privacyUrl が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R07] | LGL-R07 #b7aa71 | 異常系 | fetchLegalConfig() | ✅ |
| 8 | 端末のキャッシュには app_config/legal があるがサーバーに接続できない場合、Left(NetworkFailure) になる [LGL-R08] | LGL-R08 #928a66 | 異常系 | fetchLegalConfig() | ✅ |
| 9 | 読み取りがエラーコード internal で失敗した場合、Left(UnknownFailure) になる [LGL-R09] | LGL-R09 #c5db2a | 異常系 | fetchLegalConfig() | ✅ |
| 10 | accounts/A の consents に terms 2026-01-01・privacy 2025-06-01 がある場合、Right(LegalConsents) にその版数が入る [LGL-R10] | LGL-R10 #488b30 | 正常系 | fetchConsents() | ✅ |
| 11 | accounts/A が無い場合、Right(LegalConsents) の2つの版数がどちらも null になる [LGL-R11] | LGL-R11 #a669e7 | 正常系 | fetchConsents() | ✅ |
| 12 | accounts/A に consents が無い場合、Right(LegalConsents) の2つの版数がどちらも null になる [LGL-R12] | LGL-R12 #be0b76 | 正常系 | fetchConsents() | ✅ |
| 13 | consents に terms だけがある場合、termsVersion だけが入り privacyVersion は null になる [LGL-R13] | LGL-R13 #439bb9 | 正常系 | fetchConsents() | ✅ |
| 14 | consents.terms.version が数値で privacy.version が文字列の場合、termsVersion は null で privacyVersion に版数が入る [LGL-R14] | LGL-R14 #4b668c | 境界値 | fetchConsents() | ✅ |
| 15 | 端末のキャッシュには accounts/A があるがサーバーに接続できない場合、Left(NetworkFailure) になる [LGL-R15] | LGL-R15 #59af32 | 異常系 | fetchConsents() | ✅ |
| 16 | consents の読み取りがエラーコード internal で失敗した場合、Left(UnknownFailure) になる [LGL-R16] | LGL-R16 #367953 | 異常系 | fetchConsents() | ✅ |
| 17 | terms と privacy の版数を渡して関数が成功した場合、Right(accepted) になり2つの版数が引数として渡される [LGL-R17] | LGL-R17 #b7db82 | 正常系 | accept() | ✅ |
| 18 | privacyVersion が null で関数が成功した場合、Right(accepted) になり terms だけが引数として渡される [LGL-R18] | LGL-R18 #5ad588 | 境界値 | accept() | ✅ |
| 19 | 関数がエラーコード failed-precondition を返した場合、Right(outdated) になる [LGL-R19] | LGL-R19 #946434 | 正常系 | accept() | ✅ |
| 20 | 関数がエラーコード unavailable を返した場合、Left(NetworkFailure) になる [LGL-R20] | LGL-R20 #e825c8 | 異常系 | accept() | ✅ |
| 21 | 関数がエラーコード deadline-exceeded を返した場合、Left(NetworkFailure) になる [LGL-R21] | LGL-R21 #931f60 | 異常系 | accept() | ✅ |
| 22 | 関数がエラーコード unauthenticated を返した場合、Left(AuthFailure) になる [LGL-R22] | LGL-R22 #c8c27b | 異常系 | accept() | ✅ |
| 23 | 関数がエラーコード internal を返した場合、Left(UnknownFailure) になる [LGL-R23] | LGL-R23 #06169b | 異常系 | accept() | ✅ |
| 24 | app_config/legal の privacyVersion が数値の 20260101で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R24] | LGL-R24 #97abfc | 異常系 | fetchLegalConfig() | ✅ |
| 25 | consents に privacy だけがある場合、privacyVersion だけが入り termsVersion は null になる [LGL-R25] | LGL-R25 #f88a00 | 正常系 | fetchConsents() | ✅ |
| 26 | termsVersion が null で関数が成功した場合、Right(accepted) になり privacy だけが引数として渡される [LGL-R26] | LGL-R26 #0fdda3 | 境界値 | accept() | ✅ |
| 27 | 読み取りがエラーコード permission-denied で失敗した場合、Left(UnknownFailure) になる [LGL-R27] | LGL-R27 #0a96b7 | 異常系 | fetchLegalConfig() | ✅ |
| 28 | consents の読み取りがエラーコード permission-denied で失敗した場合、Left(UnknownFailure) になる [LGL-R28] | LGL-R28 #9c26a2 | 異常系 | fetchConsents() | ✅ |
| 29 | app_config/legal の termsVersion が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R29] | LGL-R29 #b46098 | 境界値 | fetchLegalConfig() | ✅ |
| 30 | app_config/legal の termsVersion が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R30] | LGL-R30 #e698c7 | 境界値 | fetchLegalConfig() | ✅ |
| 31 | app_config/legal の privacyVersion が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R31] | LGL-R31 #e3accc | 境界値 | fetchLegalConfig() | ✅ |
| 32 | app_config/legal の termsUrl が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R32] | LGL-R32 #65917b | 境界値 | fetchLegalConfig() | ✅ |
| 33 | app_config/legal の privacyUrl が数値の 1で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R33] | LGL-R33 #34bbd4 | 異常系 | fetchLegalConfig() | ✅ |
| 34 | consents.terms に version が無く privacy.version がある場合、termsVersion は null で privacyVersion に版数が入る [LGL-R34] | LGL-R34 #811bc3 | 境界値 | fetchConsents() | ✅ |
| 35 | consents が Map でなく文字列 x の場合、Right(LegalConsents) の2つの版数がどちらも null になる [LGL-R35] | LGL-R35 #25436f | 境界値 | fetchConsents() | ✅ |
| 36 | 関数がエラーコード permission-denied を返した場合、Left(UnknownFailure) になる [LGL-R36] | LGL-R36 #712e68 | 異常系 | accept() | ✅ |
| 37 | 関数がエラーコード not-found を返した場合、Left(UnknownFailure) になる [LGL-R37] | LGL-R37 #d209d5 | 異常系 | accept() | ✅ |
| 38 | 関数がエラーコード invalid-argument を返した場合、Left(UnknownFailure) になる [LGL-R38] | LGL-R38 #65de3b | 異常系 | accept() | ✅ |
| 39 | 関数がエラーコード cancelled を返した場合、Left(UnknownFailure) になる [LGL-R39] | LGL-R39 #664a4b | 異常系 | accept() | ✅ |
| 40 | 関数の呼び出しが関数のエラー以外の例外で失敗した場合、Left(UnknownFailure) になる [LGL-R40] | LGL-R40 #5cca5a | 異常系 | accept() | ✅ |
| 41 | app_config/legal の privacyVersion が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R41] | LGL-R41 #6021c0 | 境界値 | fetchLegalConfig() | ✅ |
| 42 | app_config/legal の termsUrl が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R42] | LGL-R42 #e4f7f4 | 境界値 | fetchLegalConfig() | ✅ |
| 43 | app_config/legal の privacyUrl が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R43] | LGL-R43 #e6e731 | 境界値 | fetchLegalConfig() | ✅ |
| 44 | app_config/legal の privacyUrl が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R44] | LGL-R44 #f896f4 | 境界値 | fetchLegalConfig() | ✅ |
| 45 | app_config/legal の termsUrl が数値の 1で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R45] | LGL-R45 #72a888 | 異常系 | fetchLegalConfig() | ✅ |

## テストケース詳細

### テストケース1: app_config/legal に4項目がすべて文字列である場合、Right(LegalConfig) になる [LGL-R01]
- **カテゴリ**: 正常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に termsVersion/privacyVersion=2026-01-01、termsUrl=https://example.com/terms、privacyUrl=https://example.com/privacy がある
- **入力値・テスト条件**: 4項目とも空でない文字列
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Right(LegalConfig(termsVersion: 2026-01-01, privacyVersion: 2026-01-01, termsUrl: https://example.com/terms, privacyUrl: https://example.com/privacy))

### テストケース2: app_config/legal が無い場合、Left(NotFoundFailure) になる [LGL-R02]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal が存在しない
- **入力値・テスト条件**: config=null
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース3: app_config/legal に termsVersion が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R03]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に termsVersion 以外の3項目が空でない文字列である
- **入力値・テスト条件**: termsVersion: 無い
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース4: app_config/legal に privacyVersion が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R04]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に privacyVersion 以外の3項目が空でない文字列である
- **入力値・テスト条件**: privacyVersion: 無い
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース5: app_config/legal の termsVersion が数値の 20260101で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R05]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に termsVersion 以外の3項目が空でない文字列である
- **入力値・テスト条件**: termsVersion: 数値 20260101
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース6: app_config/legal に termsUrl が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R06]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に termsUrl 以外の3項目が空でない文字列である
- **入力値・テスト条件**: termsUrl: 無い
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース7: app_config/legal に privacyUrl が無く他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R07]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に privacyUrl 以外の3項目が空でない文字列である
- **入力値・テスト条件**: privacyUrl: 無い
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース8: 端末のキャッシュには app_config/legal があるがサーバーに接続できない場合、Left(NetworkFailure) になる [LGL-R08]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: 接続状態がオフライン。app_config/legal は有効な値で用意されている
- **入力値・テスト条件**: オフライン
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NetworkFailure)

### テストケース9: 読み取りがエラーコード internal で失敗した場合、Left(UnknownFailure) になる [LGL-R09]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: 読み取りが FirebaseException(code: internal) を投げる
- **入力値・テスト条件**: code=internal
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(UnknownFailure)

### テストケース10: accounts/A の consents に terms 2026-01-01・privacy 2025-06-01 がある場合、Right(LegalConsents) にその版数が入る [LGL-R10]
- **カテゴリ**: 正常系
- **対象メソッド**: fetchConsents()
- **事前条件**: accounts/A の consents に terms.version=2026-01-01、privacy.version=2025-06-01 がある
- **入力値・テスト条件**: consents 両方あり
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Right(LegalConsents(termsVersion: 2026-01-01, privacyVersion: 2025-06-01))

### テストケース11: accounts/A が無い場合、Right(LegalConsents) の2つの版数がどちらも null になる [LGL-R11]
- **カテゴリ**: 正常系
- **対象メソッド**: fetchConsents()
- **事前条件**: accounts/A が存在しない
- **入力値・テスト条件**: consents 取得結果 null
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Right(LegalConsents(termsVersion: null, privacyVersion: null))

### テストケース12: accounts/A に consents が無い場合、Right(LegalConsents) の2つの版数がどちらも null になる [LGL-R12]
- **カテゴリ**: 正常系
- **対象メソッド**: fetchConsents()
- **事前条件**: accounts/A に isDeveloper だけがあり consents が無い
- **入力値・テスト条件**: consents 取得結果 null
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Right(LegalConsents(termsVersion: null, privacyVersion: null))

### テストケース13: consents に terms だけがある場合、termsVersion だけが入り privacyVersion は null になる [LGL-R13]
- **カテゴリ**: 正常系
- **対象メソッド**: fetchConsents()
- **事前条件**: consents に terms: { version: 2026-01-01 } だけがある
- **入力値・テスト条件**: terms のみ
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Right(LegalConsents(termsVersion: 2026-01-01, privacyVersion: null))

### テストケース14: consents.terms.version が数値で privacy.version が文字列の場合、termsVersion は null で privacyVersion に版数が入る [LGL-R14]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchConsents()
- **事前条件**: consents.terms.version が数値 20260101、consents.privacy.version が 2026-01-01
- **入力値・テスト条件**: terms.version=数値
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Right(LegalConsents(termsVersion: null, privacyVersion: 2026-01-01))

### テストケース15: 端末のキャッシュには accounts/A があるがサーバーに接続できない場合、Left(NetworkFailure) になる [LGL-R15]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchConsents()
- **事前条件**: 接続状態がオフライン。accounts/A の consents は用意されている
- **入力値・テスト条件**: オフライン
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Left(NetworkFailure)

### テストケース16: consents の読み取りがエラーコード internal で失敗した場合、Left(UnknownFailure) になる [LGL-R16]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchConsents()
- **事前条件**: 読み取りが FirebaseException(code: internal) を投げる
- **入力値・テスト条件**: code=internal
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Left(UnknownFailure)

### テストケース17: terms と privacy の版数を渡して関数が成功した場合、Right(accepted) になり2つの版数が引数として渡される [LGL-R17]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal が成功を返す
- **入力値・テスト条件**: termsVersion=2026-01-01, privacyVersion=2026-01-01
- **操作手順**: `accept(termsVersion: 2026-01-01, privacyVersion: 2026-01-01) を呼ぶ`
- **期待結果**: Right(LegalAcceptResult.accepted)。関数が1回、{ terms: '2026-01-01', privacy: '2026-01-01' } を引数に呼ばれる

### テストケース18: privacyVersion が null で関数が成功した場合、Right(accepted) になり terms だけが引数として渡される [LGL-R18]
- **カテゴリ**: 境界値
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal が成功を返す
- **入力値・テスト条件**: termsVersion=2026-01-01, privacyVersion=None
- **操作手順**: `accept(termsVersion: 2026-01-01, privacyVersion: None) を呼ぶ`
- **期待結果**: Right(LegalAcceptResult.accepted)。関数が1回、{ terms: '2026-01-01' }（privacy のキーは無い） を引数に呼ばれる

### テストケース19: 関数がエラーコード failed-precondition を返した場合、Right(outdated) になる [LGL-R19]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal がエラーコード failed-precondition を返す
- **入力値・テスト条件**: code=failed-precondition
- **操作手順**: `accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01') を呼ぶ`
- **期待結果**: Right(LegalAcceptResult.outdated)

### テストケース20: 関数がエラーコード unavailable を返した場合、Left(NetworkFailure) になる [LGL-R20]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal がエラーコード unavailable を返す
- **入力値・テスト条件**: code=unavailable
- **操作手順**: `accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01') を呼ぶ`
- **期待結果**: Left(NetworkFailure)

### テストケース21: 関数がエラーコード deadline-exceeded を返した場合、Left(NetworkFailure) になる [LGL-R21]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal がエラーコード deadline-exceeded を返す
- **入力値・テスト条件**: code=deadline-exceeded
- **操作手順**: `accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01') を呼ぶ`
- **期待結果**: Left(NetworkFailure)

### テストケース22: 関数がエラーコード unauthenticated を返した場合、Left(AuthFailure) になる [LGL-R22]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal がエラーコード unauthenticated を返す
- **入力値・テスト条件**: code=unauthenticated
- **操作手順**: `accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01') を呼ぶ`
- **期待結果**: Left(AuthFailure)

### テストケース23: 関数がエラーコード internal を返した場合、Left(UnknownFailure) になる [LGL-R23]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal がエラーコード internal を返す
- **入力値・テスト条件**: code=internal
- **操作手順**: `accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01') を呼ぶ`
- **期待結果**: Left(UnknownFailure)

### テストケース24: app_config/legal の privacyVersion が数値の 20260101で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R24]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に privacyVersion 以外の3項目が空でない文字列である
- **入力値・テスト条件**: privacyVersion: 数値 20260101
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース25: consents に privacy だけがある場合、privacyVersion だけが入り termsVersion は null になる [LGL-R25]
- **カテゴリ**: 正常系
- **対象メソッド**: fetchConsents()
- **事前条件**: consents に privacy: { version: 2026-01-01 } だけがある
- **入力値・テスト条件**: privacy のみ
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Right(LegalConsents(termsVersion: null, privacyVersion: 2026-01-01))

### テストケース26: termsVersion が null で関数が成功した場合、Right(accepted) になり privacy だけが引数として渡される [LGL-R26]
- **カテゴリ**: 境界値
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal が成功を返す
- **入力値・テスト条件**: termsVersion=None, privacyVersion=2026-01-01
- **操作手順**: `accept(termsVersion: None, privacyVersion: 2026-01-01) を呼ぶ`
- **期待結果**: Right(LegalAcceptResult.accepted)。関数が1回、{ privacy: '2026-01-01' }（terms のキーは無い） を引数に呼ばれる

### テストケース27: 読み取りがエラーコード permission-denied で失敗した場合、Left(UnknownFailure) になる [LGL-R27]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: 読み取りが FirebaseException(code: permission-denied) を投げる
- **入力値・テスト条件**: code=permission-denied
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(UnknownFailure)

### テストケース28: consents の読み取りがエラーコード permission-denied で失敗した場合、Left(UnknownFailure) になる [LGL-R28]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchConsents()
- **事前条件**: 読み取りが FirebaseException(code: permission-denied) を投げる
- **入力値・テスト条件**: code=permission-denied
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Left(UnknownFailure)

### テストケース29: app_config/legal の termsVersion が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R29]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に termsVersion 以外の3項目が空でない文字列である
- **入力値・テスト条件**: termsVersion: 空文字 ''
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース30: app_config/legal の termsVersion が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R30]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に termsVersion 以外の3項目が空でない文字列である
- **入力値・テスト条件**: termsVersion: 半角スペース3つ '   '
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース31: app_config/legal の privacyVersion が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R31]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に privacyVersion 以外の3項目が空でない文字列である
- **入力値・テスト条件**: privacyVersion: 空文字 ''
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース32: app_config/legal の termsUrl が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R32]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に termsUrl 以外の3項目が空でない文字列である
- **入力値・テスト条件**: termsUrl: 空文字 ''
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース33: app_config/legal の privacyUrl が数値の 1で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R33]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に privacyUrl 以外の3項目が空でない文字列である
- **入力値・テスト条件**: privacyUrl: 数値 1
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース34: consents.terms に version が無く privacy.version がある場合、termsVersion は null で privacyVersion に版数が入る [LGL-R34]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchConsents()
- **事前条件**: consents に terms: {}（version が無い）と privacy: { version: 2026-01-01 } がある
- **入力値・テスト条件**: terms.version 無し
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Right(LegalConsents(termsVersion: null, privacyVersion: 2026-01-01))

### テストケース35: consents が Map でなく文字列 x の場合、Right(LegalConsents) の2つの版数がどちらも null になる [LGL-R35]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchConsents()
- **事前条件**: consents が文字列 x
- **入力値・テスト条件**: consents=文字列 x
- **操作手順**: `fetchConsents('A') を呼ぶ`
- **期待結果**: Right(LegalConsents(termsVersion: null, privacyVersion: null))

### テストケース36: 関数がエラーコード permission-denied を返した場合、Left(UnknownFailure) になる [LGL-R36]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal がエラーコード permission-denied を返す
- **入力値・テスト条件**: code=permission-denied
- **操作手順**: `accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01') を呼ぶ`
- **期待結果**: Left(UnknownFailure)

### テストケース37: 関数がエラーコード not-found を返した場合、Left(UnknownFailure) になる [LGL-R37]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal がエラーコード not-found を返す
- **入力値・テスト条件**: code=not-found
- **操作手順**: `accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01') を呼ぶ`
- **期待結果**: Left(UnknownFailure)

### テストケース38: 関数がエラーコード invalid-argument を返した場合、Left(UnknownFailure) になる [LGL-R38]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal がエラーコード invalid-argument を返す
- **入力値・テスト条件**: code=invalid-argument
- **操作手順**: `accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01') を呼ぶ`
- **期待結果**: Left(UnknownFailure)

### テストケース39: 関数がエラーコード cancelled を返した場合、Left(UnknownFailure) になる [LGL-R39]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: 関数 acceptLegal がエラーコード cancelled を返す
- **入力値・テスト条件**: code=cancelled
- **操作手順**: `accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01') を呼ぶ`
- **期待結果**: Left(UnknownFailure)

### テストケース40: 関数の呼び出しが関数のエラー以外の例外で失敗した場合、Left(UnknownFailure) になる [LGL-R40]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: 関数の呼び出しが StateError を投げる
- **入力値・テスト条件**: StateError
- **操作手順**: `accept(termsVersion: '2026-01-01', privacyVersion: '2026-01-01') を呼ぶ`
- **期待結果**: Left(UnknownFailure)

### テストケース41: app_config/legal の privacyVersion が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R41]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に privacyVersion 以外の3項目が空でない文字列である
- **入力値・テスト条件**: privacyVersion: 半角スペース3つ '   '
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース42: app_config/legal の termsUrl が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R42]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に termsUrl 以外の3項目が空でない文字列である
- **入力値・テスト条件**: termsUrl: 半角スペース3つ '   '
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース43: app_config/legal の privacyUrl が空文字で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R43]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に privacyUrl 以外の3項目が空でない文字列である
- **入力値・テスト条件**: privacyUrl: 空文字 ''
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース44: app_config/legal の privacyUrl が半角スペース3つで他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R44]
- **カテゴリ**: 境界値
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に privacyUrl 以外の3項目が空でない文字列である
- **入力値・テスト条件**: privacyUrl: 半角スペース3つ '   '
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

### テストケース45: app_config/legal の termsUrl が数値の 1で他の3項目はある場合、Left(NotFoundFailure) になる [LGL-R45]
- **カテゴリ**: 異常系
- **対象メソッド**: fetchLegalConfig()
- **事前条件**: app_config/legal に termsUrl 以外の3項目が空でない文字列である
- **入力値・テスト条件**: termsUrl: 数値 1
- **操作手順**: `fetchLegalConfig() を呼ぶ`
- **期待結果**: Left(NotFoundFailure)

## 対象外

- L92：読み取り(_read)の FirebaseException 以外の例外 → UnknownFailure への変換。仕様書に記載なし（仕様書への追記候補）

## 検証の範囲（補足）

- LGL-R08・R15：「端末のキャッシュにはあるがサーバーに接続できない」は、接続状態をオフラインにして代用している。データソースがキャッシュではなくサーバーから読む指定（`Source.server`）をしていることは、データソースの内側のため未検証
- LGL-R12：Fake のデータソースは `consents` の値だけを返すため、リポジトリ層への入力は R11（`accounts/A` が無い）と同じ null になる。`isDeveloper` だけがあるドキュメントから `consents` を取り出す処理は、データソースの内側のため未検証
