# account_deletion_local_data_source_test_cases.md

## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/infrastructure/data_sources/local/account_deletion_local_data_source.dart |
| クラス名 | AccountDeletionLocalDataSource |
| テスト対象メソッド | findAny() / existsFor() / markRequested() / markServerDone() / clear() / deleteUserData() |

## 実行環境について

`sqflite_common_ffi` を使い、テストファイルごとの一時ディレクトリ上の実 SQLite で検証する（`DatabaseHelper` は実クラス、時刻は `clock` 注入）。

このファイル単体が担当する仕様書の仕様 ID は無い（Repository 契約は account_deletion_repository_impl_test、同期停止は sync_service_test で検証済み）。
期待値は `docs/detailed_design/presentation/settings/settings_page.md` の 2.1・5章の意味（記録の状態・他ユーザーの行を残す・1トランザクション）から設計している。

## テストケース一覧

| # | テスト名 | カテゴリ | 対象メソッド | 状態 |
|---|---------|---------|-----------|------|
| 1 | 記録が1件も無い場合、nullが返る | 境界値 | findAny() | ✅ |
| 2 | 記録が無い状態でmarkRequestedした場合、statusがrequestedでuserIdとupdatedAtがDateTimeとして読み戻せる | 正常系 | findAny() | ✅ |
| 3 | 記録が無い状態でmarkServerDoneした場合、statusがserverDoneとして読み戻せる | 正常系 | findAny() | ✅ |
| 4 | markRequestedで記録した場合、updated_atがUTCのISO8601文字列(末尾Z)で保存される | 正常系 | markRequested() | ✅ |
| 5 | そのユーザーの記録がある場合、trueが返る | 正常系 | existsFor() | ✅ |
| 6 | 他のユーザーの記録だけがある場合、falseが返る | 境界値 | existsFor() | ✅ |
| 7 | 記録が1件も無い場合、falseが返る | 境界値 | existsFor() | ✅ |
| 8 | requestedの記録があるユーザーをmarkServerDoneした場合、1行のままstatusとupdatedAtが上書きされる | 正常系 | markServerDone() | ✅ |
| 9 | 2人のユーザーの記録がある状態で一方をclearした場合、そのユーザーの記録だけが消え、他のユーザーの記録は残る | 正常系 | clear() | ✅ |
| 10 | そのユーザーのデータと記録がある状態でdeleteUserDataした場合、そのユーザーのデータ・キュー・同期の基準・退会記録がすべて消える | 正常系 | deleteUserData() | ✅ |
| 11 | 他のユーザーの行がある場合、deleteUserDataしてもその行（記録・同期の基準を含む）は残る | 正常系 | deleteUserData() | ✅ |
| 12 | sync_metaに当該2キー以外のキーがある場合、deleteUserDataしてもそのキーは残る | 境界値 | deleteUserData() | ✅ |
| 13 | 削除の途中で失敗した場合、それまでの削除も取り消され1つも消えない | 異常系 | deleteUserData() | ✅ |

## テストケース詳細

### テストケース1: 記録が1件も無い場合、nullが返る
- **カテゴリ**: 境界値
- **対象メソッド**: findAny()
- **事前条件**: account_deletion が空
- **入力値・テスト条件**: 記録なし
- **操作手順**: findAny() を呼ぶ
- **期待結果**: null が返る

### テストケース2: 記録が無い状態でmarkRequestedした場合、statusがrequestedでuserIdとupdatedAtがDateTimeとして読み戻せる
- **カテゴリ**: 正常系
- **対象メソッド**: findAny()
- **事前条件**: account_deletion が空
- **入力値・テスト条件**: clock=2024-05-01 10:00 / userId='user-1'
- **操作手順**: markRequested -> findAny
- **期待結果**: userId・status=requested・updatedAt=clock の時刻 の AccountDeletionRequest が返る

### テストケース3: 記録が無い状態でmarkServerDoneした場合、statusがserverDoneとして読み戻せる
- **カテゴリ**: 正常系
- **対象メソッド**: findAny()
- **事前条件**: account_deletion が空
- **入力値・テスト条件**: userId='user-1'
- **操作手順**: markServerDone -> findAny
- **期待結果**: status が serverDone

### テストケース4: markRequestedで記録した場合、updated_atがUTCのISO8601文字列(末尾Z)で保存される
- **カテゴリ**: 正常系
- **対象メソッド**: markRequested()
- **事前条件**: account_deletion が空
- **入力値・テスト条件**: clock=2024-05-01 10:00
- **操作手順**: markRequested -> 生の行を query
- **期待結果**: updated_at が末尾 Z で clock の UTC ISO8601 と一致

### テストケース5: そのユーザーの記録がある場合、trueが返る
- **カテゴリ**: 正常系
- **対象メソッド**: existsFor()
- **事前条件**: user-1 の記録あり
- **入力値・テスト条件**: userId='user-1'
- **操作手順**: existsFor('user-1')
- **期待結果**: true

### テストケース6: 他のユーザーの記録だけがある場合、falseが返る
- **カテゴリ**: 境界値
- **対象メソッド**: existsFor()
- **事前条件**: user-2 の記録のみ
- **入力値・テスト条件**: userId='user-1'
- **操作手順**: existsFor('user-1')
- **期待結果**: false

### テストケース7: 記録が1件も無い場合、falseが返る
- **カテゴリ**: 境界値
- **対象メソッド**: existsFor()
- **事前条件**: account_deletion が空
- **入力値・テスト条件**: userId='user-1'
- **操作手順**: existsFor('user-1')
- **期待結果**: false

### テストケース8: requestedの記録があるユーザーをmarkServerDoneした場合、1行のままstatusとupdatedAtが上書きされる
- **カテゴリ**: 正常系
- **対象メソッド**: markServerDone()
- **事前条件**: user-1 が requested で記録済み
- **入力値・テスト条件**: clock を 2024-05-02 12:30 に進める
- **操作手順**: markServerDone('user-1')
- **期待結果**: 行数は1のまま、status=serverDone、updatedAt=2024-05-02 12:30

### テストケース9: 2人のユーザーの記録がある状態で一方をclearした場合、そのユーザーの記録だけが消え、他のユーザーの記録は残る
- **カテゴリ**: 正常系
- **対象メソッド**: clear()
- **事前条件**: user-1・user-2 の記録あり
- **入力値・テスト条件**: userId='user-1'
- **操作手順**: clear('user-1')
- **期待結果**: user-1 は無し、user-2 は有り

### テストケース10: そのユーザーのデータと記録がある状態でdeleteUserDataした場合、そのユーザーのデータ・キュー・同期の基準・退会記録がすべて消える
- **カテゴリ**: 正常系
- **対象メソッド**: deleteUserData()
- **事前条件**: user-1 の words/folders/results/settings/sync_queue/sync_meta 2キー/退会記録が各1行
- **入力値・テスト条件**: userId='user-1'
- **操作手順**: deleteUserData('user-1')
- **期待結果**: 7テーブルすべて0行

### テストケース11: 他のユーザーの行がある場合、deleteUserDataしてもその行（記録・同期の基準を含む）は残る
- **カテゴリ**: 正常系
- **対象メソッド**: deleteUserData()
- **事前条件**: user-1・user-2 の各データを投入
- **入力値・テスト条件**: userId='user-1'
- **操作手順**: deleteUserData('user-1')
- **期待結果**: user-2 の行が各テーブルに1行ずつ残り、sync_meta は user-2 の2キーのみ

### テストケース12: sync_metaに当該2キー以外のキーがある場合、deleteUserDataしてもそのキーは残る
- **カテゴリ**: 境界値
- **対象メソッド**: deleteUserData()
- **事前条件**: user-1 のデータと sync_meta の 'lastSyncedAt' を投入
- **入力値・テスト条件**: userId='user-1'
- **操作手順**: deleteUserData('user-1')
- **期待結果**: sync_meta には 'lastSyncedAt' だけが残る

### テストケース13: 削除の途中で失敗した場合、それまでの削除も取り消され1つも消えない
- **カテゴリ**: 異常系
- **対象メソッド**: deleteUserData()
- **事前条件**: user-1 のデータ投入。sync_meta テーブルを一時的に改名して削除を失敗させる
- **入力値・テスト条件**: userId='user-1'
- **操作手順**: deleteUserData('user-1') を呼ぶ（例外発生）-> テーブル名を戻す
- **期待結果**: 例外が投げられ、words/folders/results/settings/sync_queue/退会記録が各1行のまま（1トランザクション）
