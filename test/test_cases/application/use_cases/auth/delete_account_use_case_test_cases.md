# delete_account_use_case_test_cases.md

## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/application/use_cases/auth/delete_account_use_case.dart |
| クラス名 | DeleteAccountUseCase |
| テスト対象メソッド | checkPending() / withdraw() / resume() |

## 実行環境について

6章に UseCase 単体の仕様項目は無く、手順の順序と分岐は ViewModel のテスト（account_deletion_view_model_test.dart）が検証済みである。
このファイルでは重複を避け、戻り値 `AccountDeletionOutcome`（none / completed / notSent / pending）の分岐だけを確かめる。
仕様ID列は期待値の根拠にした 4章の ID（指紋なし）。記録の状態は観測しない。
`AccountDeletionRepository` / `AuthRepository` / `SyncRepository` はテストファイル内の手書き Fake で、呼び出し順を共有ログに記録する。

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | 記録が無い場合、none が返る [ACD-V01] | ACD-V01 | 境界値 | checkPending() | ✅ |
| 2 | 記録が残っている場合、pending が返る [ACD-V02] | ACD-V02 | 正常系 | checkPending() | ✅ |
| 3 | 記録の読み取りに失敗した場合、pending が返る [ACD-V33] | ACD-V33 | 異常系 | checkPending() | ✅ |
| 4 | 関数と端末内の削除が成功した場合、同期の完了を待って順に処理し completed が返る [ACD-V05] | ACD-V05 | 正常系 | withdraw() | ✅ |
| 5 | 記録の作成に失敗した場合、関数を呼ばず notSent が返る [ACD-V35] | ACD-V35 | 異常系 | withdraw() | ✅ |
| 6 | 関数が NetworkFailure の場合、記録を消して notSent が返る [ACD-V06] | ACD-V06 | 異常系 | withdraw() | ✅ |
| 7 | 関数が AuthFailure の場合、記録を消して notSent が返る [ACD-V11] | ACD-V11 | 異常系 | withdraw() | ✅ |
| 8 | 関数が UnknownFailure の場合、記録を消さず pending が返る [ACD-V07] | ACD-V07 | 異常系 | withdraw() | ✅ |
| 9 | 関数が NetworkFailure で記録を消せなかった場合、pending が返る [ACD-V36] | ACD-V36 | 異常系 | withdraw() | ✅ |
| 10 | 端末内の削除に失敗した場合、ログアウトせず pending が返る [ACD-V08] | ACD-V08 | 異常系 | withdraw() | ✅ |
| 11 | 記録が無い場合、何も削除せず none が返る [ACD-V34] | ACD-V34 | 境界値 | resume() | ✅ |
| 12 | 記録が serverDone の場合、関数を呼ばず端末内を削除して completed が返る [ACD-V13] | ACD-V13 | 正常系 | resume() | ✅ |
| 13 | ログインしていない場合、関数を呼ばず端末内を削除して completed が返る [ACD-V14] | ACD-V14 | 境界値 | resume() | ✅ |
| 14 | ログイン中のユーザーが記録と違う場合、先にログアウトして関数を呼ばず completed が返る [ACD-V26] | ACD-V26 | 境界値 | resume() | ✅ |
| 15 | 同じユーザーで関数が成功した場合、同期を待たず completed が返る [ACD-V12] | ACD-V12 | 正常系 | resume() | ✅ |
| 16 | 関数が AuthFailure の場合、削除済みとして端末内を削除し completed が返る [ACD-V15] | ACD-V15 | 異常系 | resume() | ✅ |
| 17 | 関数が UnknownFailure の場合、端末内を削除せず pending が返る [ACD-V17] | ACD-V17 | 異常系 | resume() | ✅ |

## テストケース詳細

### テストケース1: 記録が無い場合、none が返る [ACD-V01]
- **カテゴリ**: 境界値
- **対象メソッド**: checkPending()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V01）
- **操作手順**: `useCase.checkPending(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース2: 記録が残っている場合、pending が返る [ACD-V02]
- **カテゴリ**: 正常系
- **対象メソッド**: checkPending()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V02）
- **操作手順**: `useCase.checkPending(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース3: 記録の読み取りに失敗した場合、pending が返る [ACD-V33]
- **カテゴリ**: 異常系
- **対象メソッド**: checkPending()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V33）
- **操作手順**: `useCase.checkPending(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース4: 関数と端末内の削除が成功した場合、同期の完了を待って順に処理し completed が返る [ACD-V05]
- **カテゴリ**: 正常系
- **対象メソッド**: withdraw()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V05）
- **操作手順**: `useCase.withdraw(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース5: 記録の作成に失敗した場合、関数を呼ばず notSent が返る [ACD-V35]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V35）
- **操作手順**: `useCase.withdraw(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース6: 関数が NetworkFailure の場合、記録を消して notSent が返る [ACD-V06]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V06）
- **操作手順**: `useCase.withdraw(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース7: 関数が AuthFailure の場合、記録を消して notSent が返る [ACD-V11]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V11）
- **操作手順**: `useCase.withdraw(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース8: 関数が UnknownFailure の場合、記録を消さず pending が返る [ACD-V07]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V07）
- **操作手順**: `useCase.withdraw(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース9: 関数が NetworkFailure で記録を消せなかった場合、pending が返る [ACD-V36]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V36）
- **操作手順**: `useCase.withdraw(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース10: 端末内の削除に失敗した場合、ログアウトせず pending が返る [ACD-V08]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V08）
- **操作手順**: `useCase.withdraw(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース11: 記録が無い場合、何も削除せず none が返る [ACD-V34]
- **カテゴリ**: 境界値
- **対象メソッド**: resume()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V34）
- **操作手順**: `useCase.resume(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース12: 記録が serverDone の場合、関数を呼ばず端末内を削除して completed が返る [ACD-V13]
- **カテゴリ**: 正常系
- **対象メソッド**: resume()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V13）
- **操作手順**: `useCase.resume(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース13: ログインしていない場合、関数を呼ばず端末内を削除して completed が返る [ACD-V14]
- **カテゴリ**: 境界値
- **対象メソッド**: resume()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V14）
- **操作手順**: `useCase.resume(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース14: ログイン中のユーザーが記録と違う場合、先にログアウトして関数を呼ばず completed が返る [ACD-V26]
- **カテゴリ**: 境界値
- **対象メソッド**: resume()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V26）
- **操作手順**: `useCase.resume(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース15: 同じユーザーで関数が成功した場合、同期を待たず completed が返る [ACD-V12]
- **カテゴリ**: 正常系
- **対象メソッド**: resume()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V12）
- **操作手順**: `useCase.resume(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース16: 関数が AuthFailure の場合、削除済みとして端末内を削除し completed が返る [ACD-V15]
- **カテゴリ**: 異常系
- **対象メソッド**: resume()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V15）
- **操作手順**: `useCase.resume(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす

### テストケース17: 関数が UnknownFailure の場合、端末内を削除せず pending が返る [ACD-V17]
- **カテゴリ**: 異常系
- **対象メソッド**: resume()
- **事前条件**: Fake の各 Repository を注入した `DeleteAccountUseCase` を生成し、テスト名の条件になるよう Fake の戻り値を設定
- **入力値・テスト条件**: テスト名のとおり（根拠: ACD-V17）
- **操作手順**: `useCase.resume(...)` を呼ぶ
- **期待結果**: テスト名のとおりの `AccountDeletionOutcome` が返り、Fake の呼び出し記録が条件を満たす
