# get_is_developer_use_case_test_cases.md

## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/application/use_cases/account/get_is_developer_use_case.dart |
| クラス名 | GetIsDeveloperUseCase |
| テスト対象メソッド | call() |

## 実行環境について

`GetIsDeveloperUseCase` は `AccountRepository`（インターフェース）へ単純に委譲するだけで、
分岐や加工ロジックを持たない。手書きの `_FakeAccountRepository`（`implements AccountRepository`）
に差し込む戻り値を切り替え、引数がそのまま渡ること・戻り値がそのまま返ることのみを検証する。
仕様書（shell_page.md 6章）は「委譲のみ。仕様項目なし」のため仕様 ID は無い。

## テストケース一覧

| # | テスト名 | カテゴリ | 対象メソッド | 状態 |
|---|---------|---------|-----------|------|
| 1 | Repositoryが Right(true) を返す場合、userId がそのまま渡り Right(true) が返る | 正常系 | call() | ✅ |
| 2 | Repositoryが失敗を返した場合、Leftがそのまま返る | 異常系 | call() | ✅ |

## テストケース詳細

### テストケース1: Repositoryが Right(true) を返す場合、userId がそのまま渡り Right(true) が返る
- **カテゴリ**: 正常系
- **対象メソッド**: call()
- **事前条件**: `_FakeAccountRepository.fetchIsDeveloperResult` に `Right(true)` を設定。
- **入力値・テスト条件**: `userId: 'u1'`
- **操作手順**: `GetIsDeveloperUseCase(repository)('u1')` を呼び出す。
- **期待結果**: `repository.capturedUserId` が `'u1'` であり、戻り値が `Right(true)` とそのまま等しい。

### テストケース2: Repositoryが失敗を返した場合、Leftがそのまま返る
- **カテゴリ**: 異常系
- **対象メソッド**: call()
- **事前条件**: `_FakeAccountRepository.fetchIsDeveloperResult` に `Left(Failure.unknown('error'))` を設定。
- **入力値・テスト条件**: `userId: 'u1'`
- **操作手順**: `GetIsDeveloperUseCase(repository)('u1')` を呼び出す。
- **期待結果**: 戻り値が `Left(Failure.unknown('error'))` とそのまま等しい。

## 対象外

分岐・加工ロジックが無いため対象外行なし（全行がテスト済み）。
