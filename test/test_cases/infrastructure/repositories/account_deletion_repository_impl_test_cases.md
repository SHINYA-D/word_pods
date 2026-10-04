## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/infrastructure/repositories/account_deletion_repository_impl.dart |
| クラス名 | AccountDeletionRepositoryImpl |
| テスト対象メソッド | findPending() / markRequested() / markServerDone() / clearRequest() / deleteLocalData() / requestServerDeletion() |
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
