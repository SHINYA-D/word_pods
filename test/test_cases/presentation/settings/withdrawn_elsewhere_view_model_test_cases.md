# withdrawn_elsewhere_view_model_test_cases.md

## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/presentation/settings/withdrawn_elsewhere_view_model.dart |
| クラス名 | WithdrawnElsewhereViewModel |
| テスト対象メソッド | check() / confirmSignOut() / confirmDelete() / acknowledgeFailure() / 監視（watchWithdrawn） |
| 仕様書 | docs/detailed_design/presentation/settings/settings_page.md |

## 実行環境について

`ProviderContainer(overrides: [...])` で `accountDeletionRepositoryProvider` / `authRepositoryProvider` / `syncRepositoryProvider` を手書き Fake に差し替える。
`withdrawnElsewhereUseCaseProvider` は上書きせず、実物の `WithdrawnElsewhereUseCase` を通す（Widget は pump しない）。仕様書 6章のとおり、UseCase の分岐（確認の対象の選び方・ログアウト・削除の順序）はこの ViewModel のテストで検証する。
3つの Fake は同じ呼び出しログに記録するため、呼び出し順（waitUntilIdle → deleteLocalDataOfUsers など）はログの並びで確かめる。
ログイン中の uid は `currentUserProvider` を StateProvider 経由で上書きして与え、変化させるテストでは切り替える。
監視は uid ごとの `StreamController` で再現し、購読の解除は `hasListener` で確かめる。
V105 の「この端末の退会処理が completed」は `accountDeletionViewModelProvider` をテスト用サブクラスで上書きして表す。
ACD-V01〜V38 は AccountDeletionViewModel の仕様で、`account_deletion_view_model_test.dart` の担当。

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | ログイン中の uid A が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になり、signOut・削除は0回 [ACD-V39 #6706b7] | ACD-V39 #6706b7 | 正常系 | check() | ✅ |
| 2 | ログインしていない状態で端末内の uid A が退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-V40 #6a25bc] | ACD-V40 #6a25bc | 正常系 | check() | ✅ |
| 3 | ログイン中の uid が B で端末内の uid A だけが退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers([A]) が1回、isWithdrawnOnServer が A・B 各1回呼ばれる [ACD-V41 #67b288] | ACD-V41 #67b288 | 正常系 | check() | ✅ |
| 4 | ログイン中の uid A に退会済みの記録が無い状態で check を呼んだ場合、phase が idle になり signOut は0回 [ACD-V42 #834352] | ACD-V42 #834352 | 正常系 | check() | ✅ |
| 5 | isWithdrawnOnServer が NetworkFailure を返す状態で check を呼んだ場合、phase が idle になり signOut は0回 [ACD-V43 #271d8a] | ACD-V43 #271d8a | 異常系 | check() | ✅ |
| 6 | isWithdrawnOnServer が UnknownFailure を返す状態で check を呼んだ場合、phase が idle になり signOut は0回 [ACD-V44 #c80fd5] | ACD-V44 #c80fd5 | 異常系 | check() | ✅ |
| 7 | ログインしていない状態で findLocalUserIds が UnknownFailure を返す場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V45 #51bd65] | ACD-V45 #51bd65 | 異常系 | check() | ✅ |
| 8 | ログインしていない状態で uid A の確認が UnknownFailure、uid C が退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers([C]) が1回呼ばれる [ACD-V46 #9991b7] | ACD-V46 #9991b7 | 異常系 | check() | ✅ |
| 9 | 端末内にデータが1件も無く uid A が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になり signOut は0回 [ACD-V47 #170dbd] | ACD-V47 #170dbd | 正常系 | check() | ✅ |
| 10 | ログインしていない状態で uid A の退会処理の記録が requested のとき check を呼んだ場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V48 #334a64] | ACD-V48 #334a64 | 境界値 | check() | ✅ |
| 11 | ログインしていない状態で uid A の退会処理の記録が requested、uid C が退会済みのとき check を呼んだ場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V49 #65a9ae] | ACD-V49 #65a9ae | 境界値 | check() | ✅ |
| 12 | 退会処理の記録の読み取りが UnknownFailure で失敗する状態で check を呼んだ場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V50 #3bf74e] | ACD-V50 #3bf74e | 異常系 | check() | ✅ |
| 13 | isWithdrawnOnServer の応答を待っている場合、phase が checking になる [ACD-V51 #708809] | ACD-V51 #708809 | 境界値 | check() | ✅ |
| 14 | phase が checking の間にもう一度 check を呼んだ場合、isWithdrawnOnServer(A) は合計1回だけ呼ばれる [ACD-V61 #131520] | ACD-V61 #131520 | 境界値 | check() | ✅ |
| 15 | isWithdrawnOnServer(A) が1回目は UnknownFailure、2回目は退会済みの状態で check を2回呼んだ場合、1回目の後は idle、2回目の後は notifying、userIds が [A] になる [ACD-V65 #6869c1] | ACD-V65 #6869c1 | 異常系 | check() | ✅ |
| 16 | uid A の退会処理の記録が requested で退会済みの状態で check を呼んだ場合、phase が idle になり signOut・削除は0回 [ACD-V66 #2576b4] | ACD-V66 #2576b4 | 境界値 | check() | ✅ |
| 17 | uid A の退会処理の記録が serverDone で退会済みの状態で check を呼んだ場合、phase が idle になり signOut・削除は0回 [ACD-V67 #8be083] | ACD-V67 #8be083 | 境界値 | check() | ✅ |
| 18 | ログインしていない状態で uid A と uid C が退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers が A と C を含めて1回呼ばれる [ACD-V68 #34bcf5] | ACD-V68 #34bcf5 | 正常系 | check() | ✅ |
| 19 | ログイン中の uid A と端末内の uid C が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になり deleteLocalDataOfUsers([C]) が1回呼ばれる [ACD-V69 #80a028] | ACD-V69 #80a028 | 正常系 | check() | ✅ |
| 20 | isWithdrawnOnServer の応答を待つ間に退会処理の記録が requested になり退会済みが返った場合、phase が idle のままで notifying にならない [ACD-V71 #9737f1] | ACD-V71 #9737f1 | 異常系 | check() | ✅ |
| 21 | ログイン中の uid A で findLocalUserIds が UnknownFailure、uid A が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になる [ACD-V76 #e714da] | ACD-V76 #e714da | 異常系 | check() | ✅ |
| 22 | ログインしていない状態で uid C が退会済みで、1回目の check のときだけ uid A の記録が requested の場合、1回目の後は削除0回、2回目の後に deleteLocalDataOfUsers([C]) が1回呼ばれ、どちらも phase は idle [ACD-V77 #afc578] | ACD-V77 #afc578 | 正常系 | check() | ✅ |
| 23 | Firebase 上のログイン中の uid A に強制ログアウトの記録があり退会済みで signOut が失敗する状態で check を呼んだ場合、phase が idle、deleteLocalDataOfUsers([A]) が1回、signOut が1回、clearForcedSignOut は0回 [ACD-V87 #427f6e] | ACD-V87 #427f6e | 異常系 | check() | ✅ |
| 24 | 強制ログアウトの記録の uid A が退会済みのとき signOut が成功する状態で check を呼んだ場合、phase が idle、deleteLocalDataOfUsers([A]) が1回、signOut が1回、clearForcedSignOut(A) が1回呼ばれる [ACD-V88 #d6392f] | ACD-V88 #d6392f | 正常系 | check() | ✅ |
| 25 | 強制ログアウトの記録の uid A が退会済みで端末内にデータが無く signOut が失敗する状態で check を呼んだ場合、phase が idle、userIds が空で signOut は1回 [ACD-V98 #43cb3e] | ACD-V98 #43cb3e | 異常系 | check() | ✅ |
| 26 | 強制ログアウトの記録の uid A で isWithdrawnOnServer が NetworkFailure を返す状態で check を呼んだ場合、signOut は1回で phase は idle [ACD-V101 #a676cd] | ACD-V101 #a676cd | 異常系 | check() | ✅ |
| 27 | 監視が退会済みを通知した後に isWithdrawnOnServer が退会済みでないと返った場合、phase が notifying、userIds が [A] になる [ACD-V102 #64ccf2] | ACD-V102 #64ccf2 | 境界値 | check() | ✅ |
| 28 | 監視が退会済みを通知した後に isWithdrawnOnServer が UnknownFailure を返した場合、phase が notifying、userIds が [A] になる [ACD-V106 #75c8de] | ACD-V106 #75c8de | 異常系 | check() | ✅ |
| 29 | ログインしていない状態で deleteLocalDataOfUsers が UnknownFailure で失敗する場合、phase が idle のままで failed にならず userIds は空 [ACD-V107 #0d6de0] | ACD-V107 #0d6de0 | 異常系 | check() | ✅ |
| 30 | ログインしていない状態で1回目の deleteLocalDataOfUsers が失敗し2回目が成功する場合、check を2回呼ぶと deleteLocalDataOfUsers([A]) が合計2回呼ばれ、どちらの後も phase は idle [ACD-V108 #8f7e6e] | ACD-V108 #8f7e6e | 異常系 | check() | ✅ |
| 31 | ログイン中の uid A と uid C が退会済みで deleteLocalDataOfUsers([C]) が失敗する状態で check を呼んだ場合、phase が notifying、userIds が [A] になる [ACD-V109 #cbce0e] | ACD-V109 #cbce0e | 異常系 | check() | ✅ |
| 32 | ログイン中の uid が B で uid A だけが退会済みかつ deleteLocalDataOfUsers([A]) が失敗する状態で check を呼んだ場合、phase が idle、userIds が空で signOut は0回 [ACD-V110 #9147c5] | ACD-V110 #9147c5 | 異常系 | check() | ✅ |
| 33 | ログインしていない状態で uid A が退会済みのとき check を呼んだ場合、waitUntilIdle の完了後に deleteLocalDataOfUsers([A]) が呼ばれる [ACD-V111 #3d4be5] | ACD-V111 #3d4be5 | 正常系 | check() | ✅ |
| 34 | phase が confirming、userIds が [A] の状態で check を呼んだ場合、phase と userIds は変わらず isWithdrawnOnServer は0回 [ACD-V60 #fce9cf] | ACD-V60 #fce9cf | 境界値 | check() | ✅ |
| 35 | phase が deleting の間に check を呼んだ場合、phase は deleting のままで isWithdrawnOnServer は0回 [ACD-V70 #a54b0b] | ACD-V70 #a54b0b | 境界値 | check() | ✅ |
| 36 | phase が notifying、userIds が [A] の状態で check を呼んだ場合、phase と userIds は変わらず isWithdrawnOnServer は0回 [ACD-V73 #8f1e43] | ACD-V73 #8f1e43 | 境界値 | check() | ✅ |
| 37 | phase が failed、userIds が [A] の状態で check を呼んだ場合、phase と userIds は変わらず isWithdrawnOnServer は0回 [ACD-V75 #a9b821] | ACD-V75 #a9b821 | 境界値 | check() | ✅ |
| 38 | phase が notifying の状態で confirmSignOut を呼び1回目の signOut が失敗し2回目が成功した場合、phase が confirming、signOut は2回、markForcedSignOut・pushBeforeSignOut は0回 [ACD-V64 #331884] | ACD-V64 #331884 | 異常系 | confirmSignOut() | ✅ |
| 39 | phase が notifying の状態で confirmSignOut を呼び signOut が成功した場合、phase が confirming、signOut は1回、pushBeforeSignOut・削除は0回 [ACD-V72 #304283] | ACD-V72 #304283 | 境界値 | confirmSignOut() | ✅ |
| 40 | phase が notifying の状態で signOut の完了を待つ間にもう一度 confirmSignOut を呼んだ場合、signOut は合計1回で phase は confirming [ACD-V79 #f2b866] | ACD-V79 #f2b866 | 境界値 | confirmSignOut() | ✅ |
| 41 | phase が idle の状態で confirmSignOut を呼んだ場合、phase は idle のままで signOut は0回 [ACD-V80 #e7b24a] | ACD-V80 #e7b24a | 境界値 | confirmSignOut() | ✅ |
| 42 | phase が confirming の状態で confirmSignOut を呼んだ場合、phase は confirming のままで signOut は0回 [ACD-V85 #d532ee] | ACD-V85 #d532ee | 境界値 | confirmSignOut() | ✅ |
| 43 | phase が notifying の状態で confirmSignOut を呼び signOut が2回とも失敗した場合、phase が confirming、signOut は2回、markForcedSignOut(A) は1回、pushBeforeSignOut は0回 [ACD-V86 #679b20] | ACD-V86 #679b20 | 異常系 | confirmSignOut() | ✅ |
| 44 | ログイン中の uid A を監視している状態で confirmSignOut の signOut が2回とも失敗した場合、uid A の監視が止まる [ACD-V100 #27674b] | ACD-V100 #27674b | 異常系 | confirmSignOut() | ✅ |
| 45 | phase が confirming の状態で confirmDelete を呼び削除が成功した場合、phase が idle、userIds が空で、waitUntilIdle の完了後に deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-V52 #ca3436] | ACD-V52 #ca3436 | 正常系 | confirmDelete() | ✅ |
| 46 | phase が confirming の状態で confirmDelete を呼び削除の完了を待っている場合、phase が deleting になる [ACD-V53 #b2845b] | ACD-V53 #b2845b | 境界値 | confirmDelete() | ✅ |
| 47 | phase が confirming の状態で confirmDelete を呼び削除が UnknownFailure で失敗した場合、phase が failed、userIds が [A] になる [ACD-V54 #557fab] | ACD-V54 #557fab | 異常系 | confirmDelete() | ✅ |
| 48 | phase が deleting の間にもう一度 confirmDelete を呼んだ場合、deleteLocalDataOfUsers は合計1回だけ呼ばれる [ACD-V59 #f77a8c] | ACD-V59 #f77a8c | 境界値 | confirmDelete() | ✅ |
| 49 | phase が idle の状態で confirmDelete を呼んだ場合、phase は idle のままで deleteLocalDataOfUsers は0回 [ACD-V63 #a0ed7c] | ACD-V63 #a0ed7c | 境界値 | confirmDelete() | ✅ |
| 50 | phase が notifying の状態で confirmDelete を呼んだ場合、phase は notifying のままで deleteLocalDataOfUsers は0回 [ACD-V74 #2809bb] | ACD-V74 #2809bb | 境界値 | confirmDelete() | ✅ |
| 51 | phase が failed の状態で confirmDelete を呼んだ場合、phase は failed のままで deleteLocalDataOfUsers は0回 [ACD-V82 #6adba2] | ACD-V82 #6adba2 | 境界値 | confirmDelete() | ✅ |
| 52 | phase が failed、userIds が [A] の状態で acknowledgeFailure を呼んだ場合、phase が confirming、userIds が [A] になり deleteLocalDataOfUsers は呼ばれない [ACD-V55 #484aee] | ACD-V55 #484aee | 境界値 | acknowledgeFailure() | ✅ |
| 53 | acknowledgeFailure で confirming に戻った後に confirmDelete を呼び削除が成功した場合、phase が idle、userIds が空になる [ACD-V56 #f26dd6] | ACD-V56 #f26dd6 | 境界値 | acknowledgeFailure() | ✅ |
| 54 | phase が confirming の状態で acknowledgeFailure を呼んだ場合、phase は confirming のままで deleteLocalDataOfUsers は0回 [ACD-V81 #8c6e2e] | ACD-V81 #8c6e2e | 境界値 | acknowledgeFailure() | ✅ |
| 55 | acknowledgeFailure で confirming に戻った後に confirmDelete を呼び削除が再び失敗した場合、phase が failed、userIds が [A] になる [ACD-V84 #41aa7b] | ACD-V84 #41aa7b | 異常系 | acknowledgeFailure() | ✅ |
| 56 | ログイン中の uid A で phase が idle の状態で監視が退会済みを通知した場合、phase が notifying、userIds が [A] になり signOut は0回 [ACD-V89 #a17592] | ACD-V89 #a17592 | 正常系 | watchWithdrawn の監視 | ✅ |
| 57 | ログイン中の uid A で phase が idle の状態で監視が退会済みでないと通知した場合、phase は idle のまま [ACD-V90 #52aa14] | ACD-V90 #52aa14 | 境界値 | watchWithdrawn の監視 | ✅ |
| 58 | ログイン中の uid A で phase が idle の状態で監視が UnknownFailure を通知した場合、phase は idle のまま [ACD-V91 #0ae876] | ACD-V91 #0ae876 | 異常系 | watchWithdrawn の監視 | ✅ |
| 59 | uid A の退会処理の記録が requested の状態で監視が退会済みを通知した場合、phase は idle のままで signOut は0回 [ACD-V92 #643da0] | ACD-V92 #643da0 | 境界値 | watchWithdrawn の監視 | ✅ |
| 60 | ログイン中の uid A を監視した後にログアウトした場合、uid A の監視が止まり phase は idle のまま [ACD-V93 #eccb75] | ACD-V93 #eccb75 | 境界値 | watchWithdrawn の監視 | ✅ |
| 61 | ログイン中の uid A を監視した後にログイン中の uid が B に変わった場合、watchWithdrawn(B) が1回呼ばれ uid A の監視が止まる [ACD-V94 #df25d2] | ACD-V94 #df25d2 | 境界値 | watchWithdrawn の監視 | ✅ |
| 62 | phase が notifying、userIds が [A] の状態で監視が退会済みを通知した場合、phase は notifying、userIds は [A] のまま [ACD-V96 #c3cecc] | ACD-V96 #c3cecc | 境界値 | watchWithdrawn の監視 | ✅ |
| 63 | 強制ログアウトの記録の uid A がある状態でログイン中の uid が B に変わった場合、clearForcedSignOut(A) と watchWithdrawn(B) が各1回呼ばれる [ACD-V99 #f3ea77] | ACD-V99 #f3ea77 | 境界値 | watchWithdrawn の監視 | ✅ |
| 64 | uid A の退会処理の記録が serverDone の状態で監視が退会済みを通知した場合、phase は idle のままで signOut は0回 [ACD-V104 #fca9b2] | ACD-V104 #fca9b2 | 境界値 | watchWithdrawn の監視 | ✅ |
| 65 | この端末の退会処理が completed の状態で監視が退会済みを通知した場合、phase は idle のままで signOut は0回 [ACD-V105 #786d7c] | ACD-V105 #786d7c | 境界値 | watchWithdrawn の監視 | ✅ |

## テストケース詳細

### テストケース1: ログイン中の uid A が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になり、signOut・削除は0回 [ACD-V39 #6706b7]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying`、`userIds` は `[A]`。`AuthRepository.signOut` は0回、`deleteLocalDataOfUsers` は0回

### テストケース2: ログインしていない状態で端末内の uid A が退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-V40 #6a25bc]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`userIds` は空。`deleteLocalDataOfUsers([A])` が1回呼ばれる。`signOut` は0回

### テストケース3: ログイン中の uid が B で端末内の uid A だけが退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers([A]) が1回、isWithdrawnOnServer が A・B 各1回呼ばれる [ACD-V41 #67b288]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `B`、端末内に uid `A` と uid `B` のデータがあり、uid `A` にだけ退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`userIds` は空。`deleteLocalDataOfUsers([A])` が1回呼ばれる。`isWithdrawnOnServer` は `A`・`B` それぞれ1回、`signOut` は0回

### テストケース4: ログイン中の uid A に退会済みの記録が無い状態で check を呼んだ場合、phase が idle になり signOut は0回 [ACD-V42 #834352]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録が無い状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`userIds` は空。`signOut` は0回

### テストケース5: isWithdrawnOnServer が NetworkFailure を返す状態で check を呼んだ場合、phase が idle になり signOut は0回 [ACD-V43 #271d8a]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、`isWithdrawnOnServer` が `NetworkFailure` を返す状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`userIds` は空。`signOut` は0回

### テストケース6: isWithdrawnOnServer が UnknownFailure を返す状態で check を呼んだ場合、phase が idle になり signOut は0回 [ACD-V44 #c80fd5]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、`isWithdrawnOnServer` が `UnknownFailure` を返す状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`userIds` は空。`signOut` は0回

### テストケース7: ログインしていない状態で findLocalUserIds が UnknownFailure を返す場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V45 #51bd65]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で、`findLocalUserIds` が `UnknownFailure` を返す状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`isWithdrawnOnServer` は0回

### テストケース8: ログインしていない状態で uid A の確認が UnknownFailure、uid C が退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers([C]) が1回呼ばれる [ACD-V46 #9991b7]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` と uid `C` のデータがあり、`isWithdrawnOnServer(A)` が `UnknownFailure`、uid `C` に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`deleteLocalDataOfUsers([C])` が1回呼ばれる

### テストケース9: 端末内にデータが1件も無く uid A が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になり signOut は0回 [ACD-V47 #170dbd]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内にデータが1件も無く、uid `A` に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying`、`userIds` は `[A]`。`signOut` は0回

### テストケース10: ログインしていない状態で uid A の退会処理の記録が requested のとき check を呼んだ場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V48 #334a64]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがあり、uid `A` の退会処理の記録が `requested` で、uid `A` に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`isWithdrawnOnServer` は0回

### テストケース11: ログインしていない状態で uid A の退会処理の記録が requested、uid C が退会済みのとき check を呼んだ場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V49 #65a9ae]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` と uid `C` のデータがあり、uid `A` の退会処理の記録が `requested` で、uid `C` に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`isWithdrawnOnServer` は0回

### テストケース12: 退会処理の記録の読み取りが UnknownFailure で失敗する状態で check を呼んだ場合、phase が idle になり isWithdrawnOnServer は0回 [ACD-V50 #3bf74e]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: 退会処理の記録の読み取り（`findPending`）が `UnknownFailure` を返す状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`isWithdrawnOnServer` は0回

### テストケース13: isWithdrawnOnServer の応答を待っている場合、phase が checking になる [ACD-V51 #708809]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがある状態で `check` を呼び、`isWithdrawnOnServer` の応答を待っている
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `checking`

### テストケース14: phase が checking の間にもう一度 check を呼んだ場合、isWithdrawnOnServer(A) は合計1回だけ呼ばれる [ACD-V61 #131520]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `checking` の間に、もう一度 `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `isWithdrawnOnServer(A)` は合計1回だけ呼ばれる

### テストケース15: isWithdrawnOnServer(A) が1回目は UnknownFailure、2回目は退会済みの状態で check を2回呼んだ場合、1回目の後は idle、2回目の後は notifying、userIds が [A] になる [ACD-V65 #6869c1]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、`isWithdrawnOnServer(A)` が1回目は `UnknownFailure`、2回目は `Right(true)` を返す状態で、`check` を2回呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: 1回目の後の `phase` は `idle`。2回目の後の `phase` は `notifying`、`userIds` は `[A]`

### テストケース16: uid A の退会処理の記録が requested で退会済みの状態で check を呼んだ場合、phase が idle になり signOut・削除は0回 [ACD-V66 #2576b4]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` の退会処理の記録が `requested` で、uid `A` に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`signOut` は0回、`deleteLocalDataOfUsers` は0回

### テストケース17: uid A の退会処理の記録が serverDone で退会済みの状態で check を呼んだ場合、phase が idle になり signOut・削除は0回 [ACD-V67 #8be083]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがあり、uid `A` の退会処理の記録が `serverDone` で、uid `A` に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`signOut` は0回、`deleteLocalDataOfUsers` は0回

### テストケース18: ログインしていない状態で uid A と uid C が退会済みのとき check を呼んだ場合、phase が idle になり deleteLocalDataOfUsers が A と C を含めて1回呼ばれる [ACD-V68 #34bcf5]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` と uid `C` のデータがあり、両方に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`deleteLocalDataOfUsers` が1回呼ばれ、引数に `A` と `C` が1回ずつ含まれる

### テストケース19: ログイン中の uid A と端末内の uid C が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になり deleteLocalDataOfUsers([C]) が1回呼ばれる [ACD-V69 #80a028]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` と uid `C` のデータがあり、両方に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying`、`userIds` は `[A]`。`deleteLocalDataOfUsers([C])` が1回呼ばれる。`signOut` は0回。`isWithdrawnOnServer(A)` は1回

### テストケース20: isWithdrawnOnServer の応答を待つ間に退会処理の記録が requested になり退会済みが返った場合、phase が idle のままで notifying にならない [ACD-V71 #9737f1]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` のデータがある状態で `check` を呼び、`isWithdrawnOnServer(A)` の応答を待っている間に uid `A` の退会処理の記録が `requested` になり、その後 `Right(true)` が返った
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。お知らせダイアログ用の `notifying` にならない

### テストケース21: ログイン中の uid A で findLocalUserIds が UnknownFailure、uid A が退会済みの状態で check を呼んだ場合、phase が notifying、userIds が [A] になる [ACD-V76 #e714da]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、`findLocalUserIds` が `UnknownFailure` を返し、uid `A` に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying`、`userIds` は `[A]`

### テストケース22: ログインしていない状態で uid C が退会済みで、1回目の check のときだけ uid A の記録が requested の場合、1回目の後は削除0回、2回目の後に deleteLocalDataOfUsers([C]) が1回呼ばれ、どちらも phase は idle [ACD-V77 #afc578]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` と uid `C` のデータがあり、uid `C` に退会済みの記録があり、1回目の `check` のときは uid `A` の退会処理の記録が `requested`、2回目の `check` のときは記録が無い状態で、`check` を2回呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: 1回目の後は `deleteLocalDataOfUsers` は0回。2回目の後に `deleteLocalDataOfUsers([C])` が1回呼ばれる。どちらの後も `phase` は `idle`

### テストケース23: Firebase 上のログイン中の uid A に強制ログアウトの記録があり退会済みで signOut が失敗する状態で check を呼んだ場合、phase が idle、deleteLocalDataOfUsers([A]) が1回、signOut が1回、clearForcedSignOut は0回 [ACD-V87 #427f6e]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: Firebase 上のログイン中の uid が `A`、uid `A` の強制ログアウトの記録があり、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録があり、`signOut` が `UnknownFailure` で失敗する状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`userIds` は空。`deleteLocalDataOfUsers([A])` が1回呼ばれる。`signOut` は1回、`clearForcedSignOut` は0回

### テストケース24: 強制ログアウトの記録の uid A が退会済みのとき signOut が成功する状態で check を呼んだ場合、phase が idle、deleteLocalDataOfUsers([A]) が1回、signOut が1回、clearForcedSignOut(A) が1回呼ばれる [ACD-V88 #d6392f]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: Firebase 上のログイン中の uid が `A`、uid `A` の強制ログアウトの記録があり、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録があり、`signOut` が成功する状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`deleteLocalDataOfUsers([A])` が1回呼ばれる。`signOut` は1回、`clearForcedSignOut(A)` は1回

### テストケース25: 強制ログアウトの記録の uid A が退会済みで端末内にデータが無く signOut が失敗する状態で check を呼んだ場合、phase が idle、userIds が空で signOut は1回 [ACD-V98 #43cb3e]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: Firebase 上のログイン中の uid が `A`、uid `A` の強制ログアウトの記録があり、端末内にデータが1件も無く、uid `A` に退会済みの記録があり、`signOut` が `UnknownFailure` で失敗する状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`userIds` は空。`signOut` は1回

### テストケース26: 強制ログアウトの記録の uid A で isWithdrawnOnServer が NetworkFailure を返す状態で check を呼んだ場合、signOut は1回で phase は idle [ACD-V101 #a676cd]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: Firebase 上のログイン中の uid が `A`、uid `A` の強制ログアウトの記録があり、`isWithdrawnOnServer` が `NetworkFailure` を返す状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `signOut` は1回。`phase` は `idle`

### テストケース27: 監視が退会済みを通知した後に isWithdrawnOnServer が退会済みでないと返った場合、phase が notifying、userIds が [A] になる [ACD-V102 #64ccf2]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、`check` を呼んで `isWithdrawnOnServer(A)` の応答を待っている間に監視が `Right(true)` を通知し、その後 `isWithdrawnOnServer(A)` が `Right(false)` を返した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying`、`userIds` は `[A]`

### テストケース28: 監視が退会済みを通知した後に isWithdrawnOnServer が UnknownFailure を返した場合、phase が notifying、userIds が [A] になる [ACD-V106 #75c8de]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、`check` を呼んで `isWithdrawnOnServer(A)` の応答を待っている間に監視が `Right(true)` を通知し、その後 `isWithdrawnOnServer(A)` が `Left(UnknownFailure)` を返した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying`、`userIds` は `[A]`

### テストケース29: ログインしていない状態で deleteLocalDataOfUsers が UnknownFailure で失敗する場合、phase が idle のままで failed にならず userIds は空 [ACD-V107 #0d6de0]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録があり、`deleteLocalDataOfUsers` が `UnknownFailure` で失敗する状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`（`failed` にならない）、`userIds` は空

### テストケース30: ログインしていない状態で1回目の deleteLocalDataOfUsers が失敗し2回目が成功する場合、check を2回呼ぶと deleteLocalDataOfUsers([A]) が合計2回呼ばれ、どちらの後も phase は idle [ACD-V108 #8f7e6e]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録があり、1回目の `deleteLocalDataOfUsers` が `UnknownFailure`、2回目が成功する状態で、`check` を2回呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `deleteLocalDataOfUsers([A])` が合計2回呼ばれる。どちらの後も `phase` は `idle`

### テストケース31: ログイン中の uid A と uid C が退会済みで deleteLocalDataOfUsers([C]) が失敗する状態で check を呼んだ場合、phase が notifying、userIds が [A] になる [ACD-V109 #cbce0e]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、端末内に uid `A` と uid `C` のデータがあり、両方に退会済みの記録があり、`deleteLocalDataOfUsers([C])` が `UnknownFailure` で失敗する状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying`、`userIds` は `[A]`

### テストケース32: ログイン中の uid が B で uid A だけが退会済みかつ deleteLocalDataOfUsers([A]) が失敗する状態で check を呼んだ場合、phase が idle、userIds が空で signOut は0回 [ACD-V110 #9147c5]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `B`、端末内に uid `A` と uid `B` のデータがあり、uid `A` にだけ退会済みの記録があり、`deleteLocalDataOfUsers([A])` が `UnknownFailure` で失敗する状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`userIds` は空。`signOut` は0回

### テストケース33: ログインしていない状態で uid A が退会済みのとき check を呼んだ場合、waitUntilIdle の完了後に deleteLocalDataOfUsers([A]) が呼ばれる [ACD-V111 #3d4be5]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で、端末内に uid `A` のデータがあり、uid `A` に退会済みの記録がある状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `SyncRepository.waitUntilIdle` が1回呼ばれ、その完了後に `deleteLocalDataOfUsers([A])` が呼ばれる

### テストケース34: phase が confirming、userIds が [A] の状態で check を呼んだ場合、phase と userIds は変わらず isWithdrawnOnServer は0回 [ACD-V60 #fce9cf]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `confirming`、`userIds` が `[A]` の状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `confirming`、`userIds` は `[A]` のまま。`isWithdrawnOnServer` は0回

### テストケース35: phase が deleting の間に check を呼んだ場合、phase は deleting のままで isWithdrawnOnServer は0回 [ACD-V70 #a54b0b]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `deleting` の間に `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `deleting` のまま。`isWithdrawnOnServer` は0回

### テストケース36: phase が notifying、userIds が [A] の状態で check を呼んだ場合、phase と userIds は変わらず isWithdrawnOnServer は0回 [ACD-V73 #8f1e43]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `notifying`、`userIds` が `[A]` の状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying`、`userIds` は `[A]` のまま。`isWithdrawnOnServer` は0回

### テストケース37: phase が failed、userIds が [A] の状態で check を呼んだ場合、phase と userIds は変わらず isWithdrawnOnServer は0回 [ACD-V75 #a9b821]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `failed`、`userIds` が `[A]` の状態で `check` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `failed`、`userIds` は `[A]` のまま。`isWithdrawnOnServer` は0回

### テストケース38: phase が notifying の状態で confirmSignOut を呼び1回目の signOut が失敗し2回目が成功した場合、phase が confirming、signOut は2回、markForcedSignOut・pushBeforeSignOut は0回 [ACD-V64 #331884]
- **カテゴリ**: 異常系
- **対象メソッド**: confirmSignOut()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `notifying`、`userIds` が `[A]` の状態で `confirmSignOut` を呼び、1回目の `signOut` が `UnknownFailure` で失敗し、2回目の `signOut` が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `confirming`、`userIds` は `[A]`。`signOut` は2回、`markForcedSignOut` は0回、`pushBeforeSignOut` は0回

### テストケース39: phase が notifying の状態で confirmSignOut を呼び signOut が成功した場合、phase が confirming、signOut は1回、pushBeforeSignOut・削除は0回 [ACD-V72 #304283]
- **カテゴリ**: 境界値
- **対象メソッド**: confirmSignOut()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `notifying`、`userIds` が `[A]` の状態で `confirmSignOut` を呼び、`signOut` が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `confirming`、`userIds` は `[A]`。`AuthRepository.signOut` は1回、`SyncRepository.pushBeforeSignOut` は0回、`deleteLocalDataOfUsers` は0回

### テストケース40: phase が notifying の状態で signOut の完了を待つ間にもう一度 confirmSignOut を呼んだ場合、signOut は合計1回で phase は confirming [ACD-V79 #f2b866]
- **カテゴリ**: 境界値
- **対象メソッド**: confirmSignOut()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `notifying`、`userIds` が `[A]` の状態で `confirmSignOut` を呼び、`signOut` の完了を待っている間にもう一度 `confirmSignOut` を呼び、`signOut` が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `AuthRepository.signOut` は合計1回だけ呼ばれる。`phase` は `confirming`

### テストケース41: phase が idle の状態で confirmSignOut を呼んだ場合、phase は idle のままで signOut は0回 [ACD-V80 #e7b24a]
- **カテゴリ**: 境界値
- **対象メソッド**: confirmSignOut()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `idle` の状態で `confirmSignOut` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle` のまま。`signOut` は0回

### テストケース42: phase が confirming の状態で confirmSignOut を呼んだ場合、phase は confirming のままで signOut は0回 [ACD-V85 #d532ee]
- **カテゴリ**: 境界値
- **対象メソッド**: confirmSignOut()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `confirming`、`userIds` が `[A]` の状態で `confirmSignOut` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `confirming` のまま。`signOut` は0回

### テストケース43: phase が notifying の状態で confirmSignOut を呼び signOut が2回とも失敗した場合、phase が confirming、signOut は2回、markForcedSignOut(A) は1回、pushBeforeSignOut は0回 [ACD-V86 #679b20]
- **カテゴリ**: 異常系
- **対象メソッド**: confirmSignOut()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `notifying`、`userIds` が `[A]` の状態で `confirmSignOut` を呼び、`signOut` が2回とも `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `confirming`、`userIds` は `[A]`。`signOut` は2回、`markForcedSignOut(A)` は1回、`pushBeforeSignOut` は0回

### テストケース44: ログイン中の uid A を監視している状態で confirmSignOut の signOut が2回とも失敗した場合、uid A の監視が止まる [ACD-V100 #27674b]
- **カテゴリ**: 異常系
- **対象メソッド**: confirmSignOut()
- **事前条件**: なし
- **入力値・テスト条件**: Firebase 上のログイン中の uid が `A` で監視を始めた後に、`confirmSignOut` を呼び、`signOut` が2回とも `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: uid `A` の監視が止まる（`watchWithdrawn(A)` のストリームの購読が解除される）

### テストケース45: phase が confirming の状態で confirmDelete を呼び削除が成功した場合、phase が idle、userIds が空で、waitUntilIdle の完了後に deleteLocalDataOfUsers([A]) が1回呼ばれる [ACD-V52 #ca3436]
- **カテゴリ**: 正常系
- **対象メソッド**: confirmDelete()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `confirming`、`userIds` が `[A]` の状態で `confirmDelete` を呼び、端末内の削除が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`userIds` は空。`SyncRepository.waitUntilIdle` が1回呼ばれ、その完了後に `deleteLocalDataOfUsers([A])` が1回呼ばれる

### テストケース46: phase が confirming の状態で confirmDelete を呼び削除の完了を待っている場合、phase が deleting になる [ACD-V53 #b2845b]
- **カテゴリ**: 境界値
- **対象メソッド**: confirmDelete()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `confirming`、`userIds` が `[A]` の状態で `confirmDelete` を呼び、端末内の削除の完了を待っている
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `deleting`

### テストケース47: phase が confirming の状態で confirmDelete を呼び削除が UnknownFailure で失敗した場合、phase が failed、userIds が [A] になる [ACD-V54 #557fab]
- **カテゴリ**: 異常系
- **対象メソッド**: confirmDelete()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `confirming`、`userIds` が `[A]` の状態で `confirmDelete` を呼び、端末内の削除が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `failed`、`userIds` は `[A]`

### テストケース48: phase が deleting の間にもう一度 confirmDelete を呼んだ場合、deleteLocalDataOfUsers は合計1回だけ呼ばれる [ACD-V59 #f77a8c]
- **カテゴリ**: 境界値
- **対象メソッド**: confirmDelete()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `deleting` の間に、もう一度 `confirmDelete` を呼び、端末内の削除が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `deleteLocalDataOfUsers` は合計1回だけ呼ばれる

### テストケース49: phase が idle の状態で confirmDelete を呼んだ場合、phase は idle のままで deleteLocalDataOfUsers は0回 [ACD-V63 #a0ed7c]
- **カテゴリ**: 境界値
- **対象メソッド**: confirmDelete()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `idle` の状態で `confirmDelete` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle` のまま。`deleteLocalDataOfUsers` は0回

### テストケース50: phase が notifying の状態で confirmDelete を呼んだ場合、phase は notifying のままで deleteLocalDataOfUsers は0回 [ACD-V74 #2809bb]
- **カテゴリ**: 境界値
- **対象メソッド**: confirmDelete()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `notifying` の状態で `confirmDelete` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying` のまま。`deleteLocalDataOfUsers` は0回

### テストケース51: phase が failed の状態で confirmDelete を呼んだ場合、phase は failed のままで deleteLocalDataOfUsers は0回 [ACD-V82 #6adba2]
- **カテゴリ**: 境界値
- **対象メソッド**: confirmDelete()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `failed`、`userIds` が `[A]` の状態で `confirmDelete` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `failed` のまま。`deleteLocalDataOfUsers` は0回

### テストケース52: phase が failed、userIds が [A] の状態で acknowledgeFailure を呼んだ場合、phase が confirming、userIds が [A] になり deleteLocalDataOfUsers は呼ばれない [ACD-V55 #484aee]
- **カテゴリ**: 境界値
- **対象メソッド**: acknowledgeFailure()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `failed`、`userIds` が `[A]` の状態で `acknowledgeFailure` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `confirming`、`userIds` は `[A]`。`deleteLocalDataOfUsers` は呼ばれない

### テストケース53: acknowledgeFailure で confirming に戻った後に confirmDelete を呼び削除が成功した場合、phase が idle、userIds が空になる [ACD-V56 #f26dd6]
- **カテゴリ**: 境界値
- **対象メソッド**: acknowledgeFailure()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `failed`、`userIds` が `[A]` の状態で `acknowledgeFailure` を呼んで `phase` が `confirming` になった後、`confirmDelete` を呼び、端末内の削除が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`userIds` は空

### テストケース54: phase が confirming の状態で acknowledgeFailure を呼んだ場合、phase は confirming のままで deleteLocalDataOfUsers は0回 [ACD-V81 #8c6e2e]
- **カテゴリ**: 境界値
- **対象メソッド**: acknowledgeFailure()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `confirming`、`userIds` が `[A]` の状態で `acknowledgeFailure` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `confirming` のまま。`deleteLocalDataOfUsers` は0回

### テストケース55: acknowledgeFailure で confirming に戻った後に confirmDelete を呼び削除が再び失敗した場合、phase が failed、userIds が [A] になる [ACD-V84 #41aa7b]
- **カテゴリ**: 異常系
- **対象メソッド**: acknowledgeFailure()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `failed`、`userIds` が `[A]` の状態で `acknowledgeFailure` を呼んで `phase` が `confirming` になった後、`confirmDelete` を呼び、端末内の削除が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `failed`、`userIds` は `[A]`

### テストケース56: ログイン中の uid A で phase が idle の状態で監視が退会済みを通知した場合、phase が notifying、userIds が [A] になり signOut は0回 [ACD-V89 #a17592]
- **カテゴリ**: 正常系
- **対象メソッド**: watchWithdrawn の監視
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、`phase` が `idle` の状態で、監視が `Right(true)` を通知した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying`、`userIds` は `[A]`。`signOut` は0回

### テストケース57: ログイン中の uid A で phase が idle の状態で監視が退会済みでないと通知した場合、phase は idle のまま [ACD-V90 #52aa14]
- **カテゴリ**: 境界値
- **対象メソッド**: watchWithdrawn の監視
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、`phase` が `idle` の状態で、監視が `Right(false)` を通知した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle` のまま

### テストケース58: ログイン中の uid A で phase が idle の状態で監視が UnknownFailure を通知した場合、phase は idle のまま [ACD-V91 #0ae876]
- **カテゴリ**: 異常系
- **対象メソッド**: watchWithdrawn の監視
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、`phase` が `idle` の状態で、監視が `Left(UnknownFailure)` を通知した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle` のまま

### テストケース59: uid A の退会処理の記録が requested の状態で監視が退会済みを通知した場合、phase は idle のままで signOut は0回 [ACD-V92 #643da0]
- **カテゴリ**: 境界値
- **対象メソッド**: watchWithdrawn の監視
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、uid `A` の退会処理の記録が `requested`、`phase` が `idle` の状態で、監視が `Right(true)` を通知した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle` のまま。`signOut` は0回

### テストケース60: ログイン中の uid A を監視した後にログアウトした場合、uid A の監視が止まり phase は idle のまま [ACD-V93 #eccb75]
- **カテゴリ**: 境界値
- **対象メソッド**: watchWithdrawn の監視
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A` で監視を始めた後にログアウトし、ログイン中の uid が無くなった
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: uid `A` の監視が止まる（`watchWithdrawn(A)` のストリームの購読が解除される）。その後に `phase` は `idle` のまま

### テストケース61: ログイン中の uid A を監視した後にログイン中の uid が B に変わった場合、watchWithdrawn(B) が1回呼ばれ uid A の監視が止まる [ACD-V94 #df25d2]
- **カテゴリ**: 境界値
- **対象メソッド**: watchWithdrawn の監視
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A` で監視を始めた後に、ログイン中の uid が `B` に変わった
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `watchWithdrawn(B)` が1回呼ばれ、uid `A` の監視が止まる（`watchWithdrawn(A)` のストリームの購読が解除される）

### テストケース62: phase が notifying、userIds が [A] の状態で監視が退会済みを通知した場合、phase は notifying、userIds は [A] のまま [ACD-V96 #c3cecc]
- **カテゴリ**: 境界値
- **対象メソッド**: watchWithdrawn の監視
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、`phase` が `notifying`、`userIds` が `[A]` の状態で、監視が `Right(true)` を通知した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notifying`、`userIds` は `[A]` のまま

### テストケース63: 強制ログアウトの記録の uid A がある状態でログイン中の uid が B に変わった場合、clearForcedSignOut(A) と watchWithdrawn(B) が各1回呼ばれる [ACD-V99 #f3ea77]
- **カテゴリ**: 境界値
- **対象メソッド**: watchWithdrawn の監視
- **事前条件**: なし
- **入力値・テスト条件**: uid `A` の強制ログアウトの記録がある状態で、Firebase 上のログイン中の uid が `B` に変わった
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `clearForcedSignOut(A)` が1回呼ばれる。`watchWithdrawn(B)` が1回呼ばれる

### テストケース64: uid A の退会処理の記録が serverDone の状態で監視が退会済みを通知した場合、phase は idle のままで signOut は0回 [ACD-V104 #fca9b2]
- **カテゴリ**: 境界値
- **対象メソッド**: watchWithdrawn の監視
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、uid `A` の退会処理の記録が `serverDone`、`phase` が `idle` の状態で、監視が `Right(true)` を通知した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle` のまま。`signOut` は0回

### テストケース65: この端末の退会処理が completed の状態で監視が退会済みを通知した場合、phase は idle のままで signOut は0回 [ACD-V105 #786d7c]
- **カテゴリ**: 境界値
- **対象メソッド**: watchWithdrawn の監視
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `A`、`AccountDeletionViewModel` の `phase` が `completed`（この端末の退会処理が終わり、退会処理の記録は削除済みで、完了ダイアログをまだ表示していない）、`WithdrawnElsewhereViewModel` の `phase` が `idle` の状態で、監視が `Right(true)` を通知した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `WithdrawnElsewhereViewModel` の `phase` は `idle` のまま。`signOut` は0回（完了ダイアログの表示後は、ログイン中の uid が無くなり監視は止まっている）
