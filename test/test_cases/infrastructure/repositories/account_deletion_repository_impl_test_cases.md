## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/infrastructure/repositories/account_deletion_repository_impl.dart |
| クラス名 | AccountDeletionRepositoryImpl |
| テスト対象メソッド | findPending() / markRequested() / markServerDone() / clearRequest() / deleteLocalData() / requestServerDeletion() / findLocalUserIds() / isWithdrawnOnServer() / watchWithdrawn() / deleteLocalDataOfUsers() / markForcedSignOut() / findForcedSignOut() / clearForcedSignOut() |
| 仕様書 | docs/detailed_design/presentation/settings/settings_page.md |

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | 記録が無い場合、Right(None) を返す [ACD-R01] | ACD-R01 #a6283f | 境界値 | findPending() | ✅ |
| 2 | 記録が無い状態で markRequested(A) を呼んだ場合、Right(unit) になり findPending は Some(A, requested) を返す [ACD-R02] | ACD-R02 #38268c | 正常系 | markRequested() | ✅ |
| 3 | requested の記録がある状態で markRequested(A) を呼んだ場合、Right(unit) になり findPending は Some(A, requested) を返す [ACD-R25] | ACD-R25 #4337fe | 境界値 | markRequested() | ✅ |
| 4 | markRequested の後に markServerDone(A) を呼んだ場合、Right(unit) になり findPending は Some(A, serverDone)、updatedAt は前回より前にならない [ACD-R03] | ACD-R03 #630e5c | 正常系 | markServerDone() | ✅ |
| 5 | requested の記録がある状態で clearRequest(A) を呼んだ場合、Right(unit) になり findPending は Right(None) を返す [ACD-R04] | ACD-R04 #4bf7a5 | 正常系 | clearRequest() | ✅ |
| 6 | 記録が無い状態で clearRequest(A) を呼んだ場合、Right(unit) になり findPending は Right(None) を返す [ACD-R26] | ACD-R26 #bf28a1 | 境界値 | clearRequest() | ✅ |
| 7 | uid A と B のデータがあり A の記録が serverDone の状態で deleteLocalData(A) を呼んだ場合、A のデータだけが消え B は残り、記録は無くなる [ACD-R05] | ACD-R05 #04a6ff | 正常系 | deleteLocalData() | ✅ |
| 8 | A のフォルダ削除の後、記録の削除で SQLite の書き込みが失敗した場合、Left(UnknownFailure) になり件数は呼ぶ前と同じで記録も serverDone のまま残る [ACD-R06] | ACD-R06 #d94587 | 異常系 | deleteLocalData() | ✅ |
| 9 | A のデータも記録も無い状態で deleteLocalData(A) を呼んだ場合、Right(unit) を返す [ACD-R24] | ACD-R24 #0f0576 | 境界値 | deleteLocalData() | ✅ |
| 10 | オンラインで関数が成功を返した場合、Right(unit) になり関数は1回呼ばれる [ACD-R07] | ACD-R07 #5fcf93 | 正常系 | requestServerDeletion() | ✅ |
| 11 | オフラインの場合、Left(NetworkFailure) になり関数は0回呼ばれる [ACD-R08] | ACD-R08 #8bda8e | 異常系 | requestServerDeletion() | ✅ |
| 12 | オンラインで関数が unavailable で失敗した場合、Left(NetworkFailure) になる [ACD-R09] | ACD-R09 #9bbec9 | 異常系 | requestServerDeletion() | ✅ |
| 13 | オンラインで関数が deadline-exceeded で失敗した場合、Left(UnknownFailure) になる [ACD-R10] | ACD-R10 #8effed | 異常系 | requestServerDeletion() | ✅ |
| 14 | オンラインで関数が unauthenticated で失敗した場合、Left(AuthFailure) になる [ACD-R11] | ACD-R11 #85a05c | 異常系 | requestServerDeletion() | ✅ |
| 15 | オンラインで関数が internal で失敗した場合、Left(UnknownFailure) になる [ACD-R12] | ACD-R12 #2e751e | 異常系 | requestServerDeletion() | ✅ |
| 16 | オンラインで関数が FirebaseFunctionsException 以外の例外で失敗した場合、Left(UnknownFailure) になる [ACD-R27] | ACD-R27 #8dbb19 | 異常系 | requestServerDeletion() | ✅ |
| 17 | オンラインで requestServerDeletion を呼んだ場合、関数 deleteAccount の呼び出しに待ち時間の上限として60秒が指定される [ACD-R29] | ACD-R29 #a05ee7 | 正常系 | requestServerDeletion() | ✅ |
| 18 | A のフォルダと単語、B の sync_queue だけ、C の設定だけ、D の学習結果だけ、E の sync_meta だけがある状態で findLocalUserIds を呼んだ場合、A〜E が1回ずつ含まれる [ACD-R31] | ACD-R31 ##7fbec1 | 正常系 | findLocalUserIds() | ✅ |
| 19 | 端末内にどの uid のデータも無い状態で findLocalUserIds を呼んだ場合、Right([]) を返す [ACD-R32] | ACD-R32 ##939053 | 境界値 | findLocalUserIds() | ✅ |
| 20 | オンラインで A に退会済みの記録がある状態で isWithdrawnOnServer(A) を呼んだ場合、Right(true) を返す [ACD-R33] | ACD-R33 ##3f62f6 | 正常系 | isWithdrawnOnServer() | ✅ |
| 21 | オンラインで A に退会済みの記録が無い状態で isWithdrawnOnServer(A) を呼んだ場合、Right(false) を返す [ACD-R34] | ACD-R34 ##674cff | 正常系 | isWithdrawnOnServer() | ✅ |
| 22 | オフラインで isWithdrawnOnServer(A) を呼んだ場合、Left(NetworkFailure) になり記録の読み取りは0回になる [ACD-R35] | ACD-R35 ##fcb796 | 異常系 | isWithdrawnOnServer() | ✅ |
| 23 | オンラインで退会済みの記録の読み取りが例外を投げる状態で isWithdrawnOnServer(A) を呼んだ場合、Left(UnknownFailure) になる [ACD-R36] | ACD-R36 ##100856 | 異常系 | isWithdrawnOnServer() | ✅ |
| 24 | 端末内の読み取りが例外を投げる状態で findLocalUserIds を呼んだ場合、Left(UnknownFailure) になる [ACD-R37] | ACD-R37 ##71342c | 異常系 | findLocalUserIds() | ✅ |
| 25 | 記録が無く A・B・C のデータがある状態で deleteLocalDataOfUsers([A, C]) を呼んだ場合、A と C のデータだけが消え B は残る [ACD-R38] | ACD-R38 ##9767cc | 正常系 | deleteLocalDataOfUsers() | ✅ |
| 26 | A の行の削除の後、C の行の削除の前に SQLite の書き込みが失敗した場合、Left(UnknownFailure) になり A と C の件数は呼ぶ前と同じになる [ACD-R39] | ACD-R39 ##863870 | 異常系 | deleteLocalDataOfUsers() | ✅ |
| 27 | A のデータが1件も無い状態で deleteLocalDataOfUsers([A]) を呼んだ場合、Right(unit) を返す [ACD-R40] | ACD-R40 ##fc0bf4 | 境界値 | deleteLocalDataOfUsers() | ✅ |
| 28 | 強制ログアウトの記録が無い状態で markForcedSignOut(A) を呼んだ場合、Right(unit) になり findForcedSignOut は Some(A) を返す [ACD-R41] | ACD-R41 ##19d85f | 正常系 | markForcedSignOut() | ✅ |
| 29 | 強制ログアウトの記録が無い状態で findForcedSignOut を呼んだ場合、Right(None) を返す [ACD-R42] | ACD-R42 ##beca4a | 境界値 | findForcedSignOut() | ✅ |
| 30 | A のデータと A の強制ログアウトの記録がある状態で deleteLocalDataOfUsers([A]) を呼んだ場合、Right(unit) になり findForcedSignOut は Some(A) のままになる [ACD-R43] | ACD-R43 ##4775f1 | 正常系 | deleteLocalDataOfUsers() | ✅ |
| 31 | A の強制ログアウトの記録がある状態で clearForcedSignOut(A) を呼んだ場合、Right(unit) になり findForcedSignOut は Right(None) を返す [ACD-R44] | ACD-R44 ##57ca70 | 正常系 | clearForcedSignOut() | ✅ |
| 32 | オンラインで A の購読を始め、記録が無い状態から記録ができた場合、ストリームが Right(false)、Right(true) の順に通知する [ACD-R45] | ACD-R45 ##2aafdd | 正常系 | watchWithdrawn() | ✅ |
| 33 | オンラインで退会済みの記録の監視が例外を通知する状態で A の購読を始めた場合、ストリームが Left(UnknownFailure) を通知する [ACD-R46] | ACD-R46 ##12db21 | 異常系 | watchWithdrawn() | ✅ |
| 34 | ログイン中の uid A に強制ログアウトの記録があり未送信の変更が1件ある状態で syncAll を呼んだ場合、リモートへの送信・取得は0回で未送信の変更は1件のままになる [ACD-R47] | ACD-R47 ##801e31 | 正常系 | syncAll()（SyncService） | ✅ |
| 35 | オンラインで A に退会済みの記録がある状態で A の購読を始めた場合、ストリームの最初の通知が Right(true) になる [ACD-R48] | ACD-R48 ##8e1ffe | 正常系 | watchWithdrawn() | ✅ |
| 36 | ログイン中の uid A に強制ログアウトの記録があり未送信の変更が1件ある状態で pushPending を呼んだ場合、リモートへの送信は0回で未送信の変更は1件のままになる [ACD-R49] | ACD-R49 ##ffed08 | 正常系 | pushPending()（SyncService） | ✅ |
| 37 | ログイン中の uid A に強制ログアウトの記録があり前回の取得から5分以上たった状態で syncOnResumed を呼んだ場合、リモートからの取得は0回になる [ACD-R50] | ACD-R50 ##ad9d2b | 正常系 | syncOnResumed()（SyncService） | ✅ |
| 38 | オンラインで関数が failed-precondition で失敗した場合、Left(RecentLoginRequiredFailure) になる [ACD-R51] | ACD-R51 #11dead | 異常系 | requestServerDeletion() | ✅ |

## テストケース詳細

### テストケース1: 記録が無い場合、Right(None) を返す [ACD-R01]
- **カテゴリ**: 境界値
- **対象メソッド**: findPending()
- **事前条件**: 仕様書 5.1 の ACD-R01 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R01 の期待される結果）

### テストケース2: 記録が無い状態で markRequested(A) を呼んだ場合、Right(unit) になり findPending は Some(A, requested) を返す [ACD-R02]
- **カテゴリ**: 正常系
- **対象メソッド**: markRequested()
- **事前条件**: 仕様書 5.1 の ACD-R02 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R02 の期待される結果）

### テストケース3: requested の記録がある状態で markRequested(A) を呼んだ場合、Right(unit) になり findPending は Some(A, requested) を返す [ACD-R25]
- **カテゴリ**: 境界値
- **対象メソッド**: markRequested()
- **事前条件**: 仕様書 5.1 の ACD-R25 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R25 の期待される結果）

### テストケース4: markRequested の後に markServerDone(A) を呼んだ場合、Right(unit) になり findPending は Some(A, serverDone)、updatedAt は前回より前にならない [ACD-R03]
- **カテゴリ**: 正常系
- **対象メソッド**: markServerDone()
- **事前条件**: 仕様書 5.1 の ACD-R03 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R03 の期待される結果）

### テストケース5: requested の記録がある状態で clearRequest(A) を呼んだ場合、Right(unit) になり findPending は Right(None) を返す [ACD-R04]
- **カテゴリ**: 正常系
- **対象メソッド**: clearRequest()
- **事前条件**: 仕様書 5.1 の ACD-R04 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R04 の期待される結果）

### テストケース6: 記録が無い状態で clearRequest(A) を呼んだ場合、Right(unit) になり findPending は Right(None) を返す [ACD-R26]
- **カテゴリ**: 境界値
- **対象メソッド**: clearRequest()
- **事前条件**: 仕様書 5.1 の ACD-R26 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R26 の期待される結果）

### テストケース7: uid A と B のデータがあり A の記録が serverDone の状態で deleteLocalData(A) を呼んだ場合、A のデータだけが消え B は残り、記録は無くなる [ACD-R05]
- **カテゴリ**: 正常系
- **対象メソッド**: deleteLocalData()
- **事前条件**: uid A・B それぞれのフォルダ・単語・学習結果・設定・sync_queue・sync_meta（pullCursor/lastPulledAt）がある。A の記録は serverDone
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R05 の期待される結果）

### テストケース8: A のフォルダ削除の後、記録の削除で SQLite の書き込みが失敗した場合、Left(UnknownFailure) になり件数は呼ぶ前と同じで記録も serverDone のまま残る [ACD-R06]
- **カテゴリ**: 異常系
- **対象メソッド**: deleteLocalData()
- **事前条件**: uid A のデータと serverDone の記録がある。account_deletion の DELETE を失敗させるトリガーを設定している（データ削除の後、記録の削除で失敗する）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R06 の期待される結果）

### テストケース9: A のデータも記録も無い状態で deleteLocalData(A) を呼んだ場合、Right(unit) を返す [ACD-R24]
- **カテゴリ**: 境界値
- **対象メソッド**: deleteLocalData()
- **事前条件**: 仕様書 5.1 の ACD-R24 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R24 の期待される結果）

### テストケース10: オンラインで関数が成功を返した場合、Right(unit) になり関数は1回呼ばれる [ACD-R07]
- **カテゴリ**: 正常系
- **対象メソッド**: requestServerDeletion()
- **事前条件**: 仕様書 5.1 の ACD-R07 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R07 の期待される結果）

### テストケース11: オフラインの場合、Left(NetworkFailure) になり関数は0回呼ばれる [ACD-R08]
- **カテゴリ**: 異常系
- **対象メソッド**: requestServerDeletion()
- **事前条件**: 接続状態がオフライン
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R08 の期待される結果）

### テストケース12: オンラインで関数が unavailable で失敗した場合、Left(NetworkFailure) になる [ACD-R09]
- **カテゴリ**: 異常系
- **対象メソッド**: requestServerDeletion()
- **事前条件**: 仕様書 5.1 の ACD-R09 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R09 の期待される結果）

### テストケース13: オンラインで関数が deadline-exceeded で失敗した場合、Left(UnknownFailure) になる [ACD-R10]
- **カテゴリ**: 異常系
- **対象メソッド**: requestServerDeletion()
- **事前条件**: 仕様書 5.1 の ACD-R10 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R10 の期待される結果）

### テストケース14: オンラインで関数が unauthenticated で失敗した場合、Left(AuthFailure) になる [ACD-R11]
- **カテゴリ**: 異常系
- **対象メソッド**: requestServerDeletion()
- **事前条件**: 仕様書 5.1 の ACD-R11 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R11 の期待される結果）

### テストケース15: オンラインで関数が internal で失敗した場合、Left(UnknownFailure) になる [ACD-R12]
- **カテゴリ**: 異常系
- **対象メソッド**: requestServerDeletion()
- **事前条件**: 仕様書 5.1 の ACD-R12 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R12 の期待される結果）

### テストケース16: オンラインで関数が FirebaseFunctionsException 以外の例外で失敗した場合、Left(UnknownFailure) になる [ACD-R27]
- **カテゴリ**: 異常系
- **対象メソッド**: requestServerDeletion()
- **事前条件**: 仕様書 5.1 の ACD-R27 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R27 の期待される結果）

### テストケース17: オンラインで requestServerDeletion を呼んだ場合、関数 deleteAccount の呼び出しに待ち時間の上限として60秒が指定される [ACD-R29]
- **カテゴリ**: 正常系
- **対象メソッド**: requestServerDeletion()
- **事前条件**: AccountDeletionRemoteDataSource に FirebaseFunctions の手書きフェイクを渡す。オンライン
- **入力値・テスト条件**: userId=A
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R29 の期待される結果）

### テストケース18: A のフォルダと単語、B の sync_queue だけ、C の設定だけ、D の学習結果だけ、E の sync_meta だけがある状態で findLocalUserIds を呼んだ場合、A〜E が1回ずつ含まれる [ACD-R31]
- **カテゴリ**: 正常系
- **対象メソッド**: findLocalUserIds()
- **事前条件**: 仕様書 5.3 の ACD-R31 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R31 の期待される結果）

### テストケース19: 端末内にどの uid のデータも無い状態で findLocalUserIds を呼んだ場合、Right([]) を返す [ACD-R32]
- **カテゴリ**: 境界値
- **対象メソッド**: findLocalUserIds()
- **事前条件**: 仕様書 5.3 の ACD-R32 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R32 の期待される結果）

### テストケース20: オンラインで A に退会済みの記録がある状態で isWithdrawnOnServer(A) を呼んだ場合、Right(true) を返す [ACD-R33]
- **カテゴリ**: 正常系
- **対象メソッド**: isWithdrawnOnServer()
- **事前条件**: 仕様書 5.3 の ACD-R33 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R33 の期待される結果）

### テストケース21: オンラインで A に退会済みの記録が無い状態で isWithdrawnOnServer(A) を呼んだ場合、Right(false) を返す [ACD-R34]
- **カテゴリ**: 正常系
- **対象メソッド**: isWithdrawnOnServer()
- **事前条件**: 仕様書 5.3 の ACD-R34 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R34 の期待される結果）

### テストケース22: オフラインで isWithdrawnOnServer(A) を呼んだ場合、Left(NetworkFailure) になり記録の読み取りは0回になる [ACD-R35]
- **カテゴリ**: 異常系
- **対象メソッド**: isWithdrawnOnServer()
- **事前条件**: 仕様書 5.3 の ACD-R35 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R35 の期待される結果）

### テストケース23: オンラインで退会済みの記録の読み取りが例外を投げる状態で isWithdrawnOnServer(A) を呼んだ場合、Left(UnknownFailure) になる [ACD-R36]
- **カテゴリ**: 異常系
- **対象メソッド**: isWithdrawnOnServer()
- **事前条件**: 仕様書 5.3 の ACD-R36 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R36 の期待される結果）

### テストケース24: 端末内の読み取りが例外を投げる状態で findLocalUserIds を呼んだ場合、Left(UnknownFailure) になる [ACD-R37]
- **カテゴリ**: 異常系
- **対象メソッド**: findLocalUserIds()
- **事前条件**: 仕様書 5.3 の ACD-R37 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R37 の期待される結果）

### テストケース25: 記録が無く A・B・C のデータがある状態で deleteLocalDataOfUsers([A, C]) を呼んだ場合、A と C のデータだけが消え B は残る [ACD-R38]
- **カテゴリ**: 正常系
- **対象メソッド**: deleteLocalDataOfUsers()
- **事前条件**: 仕様書 5.3 の ACD-R38 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R38 の期待される結果）

### テストケース26: A の行の削除の後、C の行の削除の前に SQLite の書き込みが失敗した場合、Left(UnknownFailure) になり A と C の件数は呼ぶ前と同じになる [ACD-R39]
- **カテゴリ**: 異常系
- **対象メソッド**: deleteLocalDataOfUsers()
- **事前条件**: 仕様書 5.3 の ACD-R39 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R39 の期待される結果）

### テストケース27: A のデータが1件も無い状態で deleteLocalDataOfUsers([A]) を呼んだ場合、Right(unit) を返す [ACD-R40]
- **カテゴリ**: 境界値
- **対象メソッド**: deleteLocalDataOfUsers()
- **事前条件**: 仕様書 5.3 の ACD-R40 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R40 の期待される結果）

### テストケース28: 強制ログアウトの記録が無い状態で markForcedSignOut(A) を呼んだ場合、Right(unit) になり findForcedSignOut は Some(A) を返す [ACD-R41]
- **カテゴリ**: 正常系
- **対象メソッド**: markForcedSignOut()
- **事前条件**: 仕様書 5.3 の ACD-R41 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R41 の期待される結果）

### テストケース29: 強制ログアウトの記録が無い状態で findForcedSignOut を呼んだ場合、Right(None) を返す [ACD-R42]
- **カテゴリ**: 境界値
- **対象メソッド**: findForcedSignOut()
- **事前条件**: 仕様書 5.3 の ACD-R42 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R42 の期待される結果）

### テストケース30: A のデータと A の強制ログアウトの記録がある状態で deleteLocalDataOfUsers([A]) を呼んだ場合、Right(unit) になり findForcedSignOut は Some(A) のままになる [ACD-R43]
- **カテゴリ**: 正常系
- **対象メソッド**: deleteLocalDataOfUsers()
- **事前条件**: 仕様書 5.3 の ACD-R43 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R43 の期待される結果）

### テストケース31: A の強制ログアウトの記録がある状態で clearForcedSignOut(A) を呼んだ場合、Right(unit) になり findForcedSignOut は Right(None) を返す [ACD-R44]
- **カテゴリ**: 正常系
- **対象メソッド**: clearForcedSignOut()
- **事前条件**: 仕様書 5.3 の ACD-R44 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R44 の期待される結果）

### テストケース32: オンラインで A の購読を始め、記録が無い状態から記録ができた場合、ストリームが Right(false)、Right(true) の順に通知する [ACD-R45]
- **カテゴリ**: 正常系
- **対象メソッド**: watchWithdrawn()
- **事前条件**: 仕様書 5.3 の ACD-R45 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R45 の期待される結果）

### テストケース33: オンラインで退会済みの記録の監視が例外を通知する状態で A の購読を始めた場合、ストリームが Left(UnknownFailure) を通知する [ACD-R46]
- **カテゴリ**: 異常系
- **対象メソッド**: watchWithdrawn()
- **事前条件**: 仕様書 5.3 の ACD-R46 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R46 の期待される結果）

### テストケース34: ログイン中の uid A に強制ログアウトの記録があり未送信の変更が1件ある状態で syncAll を呼んだ場合、リモートへの送信・取得は0回で未送信の変更は1件のままになる [ACD-R47]
- **カテゴリ**: 正常系
- **対象メソッド**: syncAll()（SyncService）
- **事前条件**: 仕様書 5.3 の ACD-R47 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R47 の期待される結果）

### テストケース35: オンラインで A に退会済みの記録がある状態で A の購読を始めた場合、ストリームの最初の通知が Right(true) になる [ACD-R48]
- **カテゴリ**: 正常系
- **対象メソッド**: watchWithdrawn()
- **事前条件**: 仕様書 5.3 の ACD-R48 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R48 の期待される結果）

### テストケース36: ログイン中の uid A に強制ログアウトの記録があり未送信の変更が1件ある状態で pushPending を呼んだ場合、リモートへの送信は0回で未送信の変更は1件のままになる [ACD-R49]
- **カテゴリ**: 正常系
- **対象メソッド**: pushPending()（SyncService）
- **事前条件**: 仕様書 5.3 の ACD-R49 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R49 の期待される結果）

### テストケース37: ログイン中の uid A に強制ログアウトの記録があり前回の取得から5分以上たった状態で syncOnResumed を呼んだ場合、リモートからの取得は0回になる [ACD-R50]
- **カテゴリ**: 正常系
- **対象メソッド**: syncOnResumed()（SyncService）
- **事前条件**: 仕様書 5.3 の ACD-R50 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: userId=A（ほか仕様書の条件のとおり）
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.3 の ACD-R50 の期待される結果）

### テストケース38: オンラインで関数が failed-precondition で失敗した場合、Left(RecentLoginRequiredFailure) になる [ACD-R51]
- **カテゴリ**: 異常系
- **対象メソッド**: requestServerDeletion()
- **事前条件**: 仕様書 5.1 の ACD-R51 の条件のとおり（実SQLite（sqflite_common_ffi）と手書きFakeのリモート・接続状態）
- **入力値・テスト条件**: 関数がエラーコード failed-precondition で失敗する
- **操作手順**: 上記のメソッドを呼ぶ
- **期待結果**: テスト名のとおり（仕様書 5.1 の ACD-R51 の期待される結果）
