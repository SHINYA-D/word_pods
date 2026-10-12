# account_deletion_local_data_source_test_cases.md

## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/infrastructure/data_sources/local/account_deletion_local_data_source.dart |
| クラス名 | AccountDeletionLocalDataSource |
| テスト対象メソッド | findAny() / existsFor() / markRequested() / markServerDone() / clear() / deleteUserData() / deleteUsersData() / findUserIds() / markForcedSignOut() / findForcedSignOut() / isForcedSignOut() / clearForcedSignOut() / shouldSkipSync() |

## 実行環境について

`sqflite_common_ffi` を使い、テストファイルごとの一時ディレクトリ上の実 SQLite で検証する（`DatabaseHelper` は実クラス、時刻は `clock` 注入）。

このファイル単体が担当する仕様書の仕様 ID は無い（Repository 契約は account_deletion_repository_impl_test、同期停止は sync_service_test で検証済み）。
期待値は `docs/detailed_design/presentation/settings/settings_page.md` の 2.1・5章の意味（記録の状態・他ユーザーの行を残す・1トランザクション）から設計している。
追加分（#14〜）は ACD-R31・R32・R38〜R44 と「同期の停止」の意味に合わせている。


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
| 14 | 2人のユーザーのデータがある状態で2人分をdeleteUsersDataした場合、両方のデータ・キュー・同期の基準・退会記録がすべて消える | 正常系 | deleteUsersData() | ✅ |
| 15 | 3人のユーザーのデータがある状態で2人分をdeleteUsersDataした場合、指定していないユーザーの行は残る | 正常系 | deleteUsersData() | ✅ |
| 16 | 複数ユーザーの削除の途中で失敗した場合、先に削除した分も取り消され1つも消えない | 異常系 | deleteUsersData() | ✅ |
| 17 | 端末内にデータが無いユーザーをdeleteUsersDataした場合、例外なく成功する | 境界値 | deleteUsersData() | ✅ |
| 18 | 空のリストをdeleteUsersDataした場合、例外なく成功し他のデータは残る | 境界値 | deleteUsersData() | ✅ |
| 19 | 強制ログアウトの記録がある状態でdeleteUsersDataした場合、その記録は消えずに残る | 正常系 | deleteUsersData() | ✅ |
| 20 | 端末内にデータが1件も無い場合、空のリストが返る | 境界値 | findUserIds() | ✅ |
| 21 | フォルダ・単語・学習結果・設定・sync_queue・sync_metaのどれか1つだけにあるuidを持つ場合、すべてのuidが返る | 正常系 | findUserIds() | ✅ |
| 22 | 1人のユーザーが複数のテーブルにデータを持つ場合、そのuidは重複せず1件だけ返る | 境界値 | findUserIds() | ✅ |
| 23 | 同期の基準以外のsync_metaのキー（lastSyncedAt・強制ログアウトの記録）だけがある場合、uidとして返らない | 境界値 | findUserIds() | ✅ |
| 24 | uidが空文字の行しか無い場合、空文字は返らない | 境界値 | findUserIds() | ✅ |
| 25 | 記録が無い場合、findForcedSignOutはnullを返しisForcedSignOutはfalseを返す | 境界値 | findForcedSignOut() / isForcedSignOut() | ✅ |
| 26 | markForcedSignOutした場合、findForcedSignOutでそのuidが読み戻せ、isForcedSignOutはtrueを返す | 正常系 | markForcedSignOut() / findForcedSignOut() / isForcedSignOut() | ✅ |
| 27 | 別のuidの記録がある場合、isForcedSignOutはfalseを返す | 境界値 | isForcedSignOut() | ✅ |
| 28 | 記録がある状態で別のuidをmarkForcedSignOutした場合、記録は1つのまま新しいuidに置き換わる | 正常系 | markForcedSignOut() | ✅ |
| 29 | 同じuidでclearForcedSignOutした場合、記録が消える | 正常系 | clearForcedSignOut() | ✅ |
| 30 | 別のuidでclearForcedSignOutした場合、記録は消えない | 境界値 | clearForcedSignOut() | ✅ |
| 31 | 退会処理の記録があるuidの場合、trueが返る | 正常系 | shouldSkipSync() | ✅ |
| 32 | 強制ログアウトの記録があるuidの場合、trueが返る | 正常系 | shouldSkipSync() | ✅ |
| 33 | どちらの記録も無いuidの場合、falseが返る | 境界値 | shouldSkipSync() | ✅ |
| 34 | 別のuidの退会処理の記録と強制ログアウトの記録だけがある場合、falseが返る | 境界値 | shouldSkipSync() | ✅ |

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

### テストケース14: 2人のユーザーのデータがある状態で2人分をdeleteUsersDataした場合、両方のデータ・キュー・同期の基準・退会記録がすべて消える
- **カテゴリ**: 正常系
- **対象メソッド**: deleteUsersData()
- **事前条件**: user-1・user-2 の各データを投入
- **入力値・テスト条件**: [user-1, user-2]（ACD-R38 #9767cc）
- **操作手順**: deleteUsersData を呼ぶ
- **期待結果**: 7テーブルすべて0行

### テストケース15: 3人のユーザーのデータがある状態で2人分をdeleteUsersDataした場合、指定していないユーザーの行は残る
- **カテゴリ**: 正常系
- **対象メソッド**: deleteUsersData()
- **事前条件**: user-1・user-2・user-3 の各データを投入
- **入力値・テスト条件**: [user-1, user-2]（ACD-R39 #863870）
- **操作手順**: deleteUsersData を呼ぶ -> findUserIds
- **期待結果**: user-3 の行が各テーブルに1行ずつ残り、findUserIds は ['user-3']

### テストケース16: 複数ユーザーの削除の途中で失敗した場合、先に削除した分も取り消され1つも消えない
- **カテゴリ**: 異常系
- **対象メソッド**: deleteUsersData()
- **事前条件**: user-1・user-2 のデータ投入。sync_meta テーブルを一時的に改名して失敗させる
- **入力値・テスト条件**: [user-1, user-2]（ACD-R39 #863870）
- **操作手順**: deleteUsersData を呼ぶ（例外発生）-> テーブル名を戻す
- **期待結果**: 例外が投げられ、各テーブルが2行のまま（1トランザクション）

### テストケース17: 端末内にデータが無いユーザーをdeleteUsersDataした場合、例外なく成功する
- **カテゴリ**: 境界値
- **対象メソッド**: deleteUsersData()
- **事前条件**: 全テーブルが空
- **入力値・テスト条件**: [user-1]（ACD-R40 #fc0bf4）
- **操作手順**: deleteUsersData を呼ぶ -> findUserIds
- **期待結果**: 例外なく完了し、findUserIds は空

### テストケース18: 空のリストをdeleteUsersDataした場合、例外なく成功し他のデータは残る
- **カテゴリ**: 境界値
- **対象メソッド**: deleteUsersData()
- **事前条件**: user-1 のデータ投入
- **入力値・テスト条件**: 空リスト（ACD-R40 #fc0bf4）
- **操作手順**: deleteUsersData([]) を呼ぶ
- **期待結果**: 例外なく完了し、user-1 のデータは残る

### テストケース19: 強制ログアウトの記録がある状態でdeleteUsersDataした場合、その記録は消えずに残る
- **カテゴリ**: 正常系
- **対象メソッド**: deleteUsersData()
- **事前条件**: user-1 のデータと強制ログアウトの記録（user-1）
- **入力値・テスト条件**: [user-1]（ACD-R41 #19d85f）
- **操作手順**: deleteUsersData を呼ぶ -> findForcedSignOut
- **期待結果**: findForcedSignOut が 'user-1' を返す

### テストケース20: 端末内にデータが1件も無い場合、空のリストが返る
- **カテゴリ**: 境界値
- **対象メソッド**: findUserIds()
- **事前条件**: 全テーブルが空
- **入力値・テスト条件**: なし（ACD-R31 #7fbec1）
- **操作手順**: findUserIds を呼ぶ
- **期待結果**: 空のリスト

### テストケース21: フォルダ・単語・学習結果・設定・sync_queue・sync_metaのどれか1つだけにあるuidを持つ場合、すべてのuidが返る
- **カテゴリ**: 正常系
- **対象メソッド**: findUserIds()
- **事前条件**: 6種類の保存先に別々の uid を1件ずつ投入（sync_meta は pullCursor と lastPulledAt）
- **入力値・テスト条件**: 7つの uid（ACD-R31 #7fbec1）
- **操作手順**: findUserIds を呼ぶ
- **期待結果**: 7つの uid がすべて含まれる

### テストケース22: 1人のユーザーが複数のテーブルにデータを持つ場合、そのuidは重複せず1件だけ返る
- **カテゴリ**: 境界値
- **対象メソッド**: findUserIds()
- **事前条件**: user-1 が全テーブルにデータを持つ
- **入力値・テスト条件**: user-1（ACD-R32 #939053）
- **操作手順**: findUserIds を呼ぶ
- **期待結果**: ['user-1'] のみ

### テストケース23: 同期の基準以外のsync_metaのキー（lastSyncedAt・強制ログアウトの記録）だけがある場合、uidとして返らない
- **カテゴリ**: 境界値
- **対象メソッド**: findUserIds()
- **事前条件**: sync_meta に lastSyncedAt と forcedSignOut のみ
- **入力値・テスト条件**: なし（ACD-R32 #939053）
- **操作手順**: findUserIds を呼ぶ
- **期待結果**: 空のリスト

### テストケース24: uidが空文字の行しか無い場合、空文字は返らない
- **カテゴリ**: 境界値
- **対象メソッド**: findUserIds()
- **事前条件**: userId='' のフォルダ1行
- **入力値・テスト条件**: なし（ACD-R32 #939053）
- **操作手順**: findUserIds を呼ぶ
- **期待結果**: 空のリスト

### テストケース25: 記録が無い場合、findForcedSignOutはnullを返しisForcedSignOutはfalseを返す
- **カテゴリ**: 境界値
- **対象メソッド**: findForcedSignOut() / isForcedSignOut()
- **事前条件**: 記録なし
- **入力値・テスト条件**: user-1（ACD-R42 #beca4a）
- **操作手順**: 両メソッドを呼ぶ
- **期待結果**: null / false

### テストケース26: markForcedSignOutした場合、findForcedSignOutでそのuidが読み戻せ、isForcedSignOutはtrueを返す
- **カテゴリ**: 正常系
- **対象メソッド**: markForcedSignOut() / findForcedSignOut() / isForcedSignOut()
- **事前条件**: 記録なし
- **入力値・テスト条件**: user-1（ACD-R42 #beca4a）
- **操作手順**: markForcedSignOut -> find / is
- **期待結果**: 'user-1' / true

### テストケース27: 別のuidの記録がある場合、isForcedSignOutはfalseを返す
- **カテゴリ**: 境界値
- **対象メソッド**: isForcedSignOut()
- **事前条件**: user-2 の記録あり
- **入力値・テスト条件**: user-1（ACD-R42 #beca4a）
- **操作手順**: isForcedSignOut('user-1')
- **期待結果**: false

### テストケース28: 記録がある状態で別のuidをmarkForcedSignOutした場合、記録は1つのまま新しいuidに置き換わる
- **カテゴリ**: 正常系
- **対象メソッド**: markForcedSignOut()
- **事前条件**: user-1 の記録あり
- **入力値・テスト条件**: user-2（ACD-R43 #4775f1）
- **操作手順**: markForcedSignOut('user-2')
- **期待結果**: find は 'user-2'、isForcedSignOut('user-1') は false

### テストケース29: 同じuidでclearForcedSignOutした場合、記録が消える
- **カテゴリ**: 正常系
- **対象メソッド**: clearForcedSignOut()
- **事前条件**: user-1 の記録あり
- **入力値・テスト条件**: user-1（ACD-R44 #57ca70）
- **操作手順**: clearForcedSignOut('user-1')
- **期待結果**: findForcedSignOut が null

### テストケース30: 別のuidでclearForcedSignOutした場合、記録は消えない
- **カテゴリ**: 境界値
- **対象メソッド**: clearForcedSignOut()
- **事前条件**: user-1 の記録あり
- **入力値・テスト条件**: user-2（ACD-R44 #57ca70）
- **操作手順**: clearForcedSignOut('user-2')
- **期待結果**: findForcedSignOut が 'user-1'

### テストケース31: 退会処理の記録があるuidの場合、trueが返る
- **カテゴリ**: 正常系
- **対象メソッド**: shouldSkipSync()
- **事前条件**: user-1 の退会処理の記録あり
- **入力値・テスト条件**: user-1（同期の停止）
- **操作手順**: shouldSkipSync('user-1')
- **期待結果**: true

### テストケース32: 強制ログアウトの記録があるuidの場合、trueが返る
- **カテゴリ**: 正常系
- **対象メソッド**: shouldSkipSync()
- **事前条件**: user-1 の強制ログアウトの記録あり
- **入力値・テスト条件**: user-1（同期の停止）
- **操作手順**: shouldSkipSync('user-1')
- **期待結果**: true

### テストケース33: どちらの記録も無いuidの場合、falseが返る
- **カテゴリ**: 境界値
- **対象メソッド**: shouldSkipSync()
- **事前条件**: 記録なし
- **入力値・テスト条件**: user-1（同期の停止）
- **操作手順**: shouldSkipSync('user-1')
- **期待結果**: false

### テストケース34: 別のuidの退会処理の記録と強制ログアウトの記録だけがある場合、falseが返る
- **カテゴリ**: 境界値
- **対象メソッド**: shouldSkipSync()
- **事前条件**: user-2 の両方の記録あり
- **入力値・テスト条件**: user-1（同期の停止）
- **操作手順**: shouldSkipSync('user-1')
- **期待結果**: false
