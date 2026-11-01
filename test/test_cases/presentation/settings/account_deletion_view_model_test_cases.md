# account_deletion_view_model_test_cases.md

## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/presentation/settings/account_deletion_view_model.dart |
| クラス名 | AccountDeletionViewModel |
| テスト対象メソッド | build() / checkPending() / withdraw() / retry() / retryWithReauth() / acknowledgeCompleted() / acknowledgeNotSent() / acknowledgeReauthRejected() |
| 仕様書 | docs/detailed_design/presentation/settings/settings_page.md |

## 実行環境について

`ProviderContainer(overrides: [...])` で `accountDeletionRepositoryProvider` / `authRepositoryProvider` / `syncRepositoryProvider` / `currentUserProvider` を手書き Fake に差し替える。
`deleteAccountUseCaseProvider` は上書きせず、実物の `DeleteAccountUseCase` を通す（Widget は pump しない）。
`reauthenticationRepositoryProvider`（手書き Fake。成功・キャンセル・各 Failure・Completer による応答待ちを設定でき、呼び出しと引数を記録する）と `withdrawnElsewhereViewModelProvider`（phase を外から設定できるサブクラス）も差し替える。ログイン中のユーザーは途中で null にできる Provider 経由（ACD-V146）。
仕様書 4章冒頭の「`withdraw` は特に書かない限り引数なし（Google で本人確認する）で呼び、本人確認は成功するものとする」に従い、既定の本人確認 Fake は成功を返す。
4つの Fake は同じ呼び出しログに記録するため、呼び出し順（ACD-V04・V05・V12・V26）はログの並びで確かめる。
関数・端末内の削除・同期の応答待ちは Fake 内の `Completer` で止める（ACD-V04・V09・V19・V20・V23・V25）。
仕様書 4章の「ログイン中のユーザーは、特に書かない限り記録と同じ uid A」に合わせ、既定のログインユーザーは uid `A`。

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | ViewModelを作成した直後（checkPending の完了前）の場合、phase が checking になる [ACD-V38 #1fc7e1] | ACD-V38 #1fc7e1 | 境界値 | build() | ✅ |
| 2 | 記録が無い状態で起動時の確認をした場合、phase が idle になる [ACD-V01 #ed5294] | ACD-V01 #ed5294 | 正常系 | checkPending() | ✅ |
| 3 | uid A の記録が requested の状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V02 #37e832] | ACD-V02 #37e832 | 正常系 | checkPending() | ✅ |
| 4 | uid A の記録が serverDone の状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V03 #c620c9] | ACD-V03 #c620c9 | 正常系 | checkPending() | ✅ |
| 5 | ログイン中の uid が B、記録が uid A の requested の状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V28 #810398] | ACD-V28 #810398 | 正常系 | checkPending() | ✅ |
| 6 | 記録の読み取りが UnknownFailure で失敗する状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V33 #286851] | ACD-V33 #286851 | 異常系 | checkPending() | ✅ |
| 7 | 記録が無い状態で withdraw を呼び関数の応答を待っている場合、phase が processing、記録が requested で、waitUntilIdle の完了後に requestServerDeletion が1回呼ばれる [ACD-V04 #5d474d] | ACD-V04 #5d474d | 境界値 | withdraw() | ✅ |
| 8 | 記録が無い状態で withdraw を呼び関数の呼び出しと端末内の削除がどちらも成功した場合、phase が completed になり、markRequested・requestServerDeletion・markServerDone・deleteLocalData・signOut がこの順に1回ずつ呼ばれる [ACD-V05 #7735f6] | ACD-V05 #7735f6 | 正常系 | withdraw() | ✅ |
| 9 | 記録が無い状態で withdraw を呼び関数の呼び出しが NetworkFailure で失敗した場合、phase が notSent になり、clearRequest(A) が1回呼ばれ記録は無く、markServerDone・deleteLocalData・signOut は0回 [ACD-V06 #7cc1c8] | ACD-V06 #7cc1c8 | 異常系 | withdraw() | ✅ |
| 10 | 記録が無い状態で withdraw を呼び関数の呼び出しが UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false で、記録は requested のまま、clearRequest・deleteLocalData・signOut は0回 [ACD-V07 #ce393b] | ACD-V07 #ce393b | 異常系 | withdraw() | ✅ |
| 11 | 記録が無い状態で withdraw を呼び関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false で、記録は serverDone、signOut は0回 [ACD-V08 #d10e09] | ACD-V08 #d10e09 | 異常系 | withdraw() | ✅ |
| 12 | phase が processing の間にもう一度 withdraw を呼んだ場合、requestServerDeletion は合計1回だけ呼ばれる [ACD-V09 #a68a80] | ACD-V09 #a68a80 | 境界値 | withdraw() | ✅ |
| 13 | 記録が無い状態で withdraw を呼び関数の呼び出しが AuthFailure で失敗した場合、phase が notSent になり、clearRequest(A) が1回呼ばれ記録は無く、deleteLocalData・signOut は0回 [ACD-V11 #76228d] | ACD-V11 #76228d | 異常系 | withdraw() | ✅ |
| 14 | 記録が無い状態で withdraw を呼び関数・端末内の削除が成功し signOut が UnknownFailure で失敗した場合、phase が completed になる [ACD-V24 #bf80d9] | ACD-V24 #bf80d9 | 異常系 | withdraw() | ✅ |
| 15 | phase が pendingRetry の状態で withdraw を呼んだ場合、phase は pendingRetry のままで、markRequested・requestServerDeletion は0回 [ACD-V32 #34d262] | ACD-V32 #34d262 | 境界値 | withdraw() | ✅ |
| 16 | 記録が無い状態で withdraw を呼び markRequested が UnknownFailure で失敗した場合、phase が notSent になり、requestServerDeletion は0回 [ACD-V35 #235d99] | ACD-V35 #235d99 | 異常系 | withdraw() | ✅ |
| 17 | 記録が無い状態で withdraw を呼び関数が NetworkFailure で失敗し clearRequest が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false になる [ACD-V36 #75999d] | ACD-V36 #75999d | 異常系 | withdraw() | ✅ |
| 18 | 記録が無い状態で withdraw を呼び関数は成功し markServerDone が UnknownFailure で失敗し端末内の削除が成功した場合、phase が completed になり、deleteLocalData(A) が1回呼ばれる [ACD-V37 #1f5756] | ACD-V37 #1f5756 | 異常系 | withdraw() | ✅ |
| 19 | ログイン中で uid A の記録が requested の状態で retry を呼び関数・端末内の削除が成功した場合、phase が completed になり、requestServerDeletion・markServerDone(A)・deleteLocalData(A)・signOut がこの順に1回ずつ呼ばれる [ACD-V12 #8c6c4b] | ACD-V12 #8c6c4b | 正常系 | retry() | ✅ |
| 20 | uid A の記録が serverDone の状態で retry を呼び端末内の削除が成功した場合、phase が completed になり、requestServerDeletion は0回、deleteLocalData(A) は1回、signOut は1回 [ACD-V13 #7badb4] | ACD-V13 #7badb4 | 正常系 | retry() | ✅ |
| 21 | ログインしていない状態で uid A の記録が requested のまま retry を呼び端末内の削除が成功した場合、phase が completed になり、requestServerDeletion は0回、deleteLocalData(A) は1回、signOut は1回 [ACD-V14 #ef3249] | ACD-V14 #ef3249 | 正常系 | retry() | ✅ |
| 22 | ログイン中で uid A の記録が requested の状態で retry を呼び関数が AuthFailure で失敗し端末内の削除が成功した場合、phase が completed になり、deleteLocalData(A) は1回、signOut は1回 [ACD-V15 #ea056e] | ACD-V15 #ea056e | 異常系 | retry() | ✅ |
| 23 | ログイン中で uid A の記録が requested の状態で retry を呼び関数が NetworkFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、deleteLocalData は0回 [ACD-V16 #5df076] | ACD-V16 #5df076 | 異常系 | retry() | ✅ |
| 24 | ログイン中で uid A の記録が requested の状態で retry を呼び関数が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、deleteLocalData は0回 [ACD-V17 #b8b268] | ACD-V17 #b8b268 | 異常系 | retry() | ✅ |
| 25 | uid A の記録が serverDone の状態で retry を呼び端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は serverDone のまま [ACD-V18 #723164] | ACD-V18 #723164 | 異常系 | retry() | ✅ |
| 26 | ログイン中で uid A の記録が requested の状態で retry を呼び関数の応答を待っている場合、phase が processing になる [ACD-V19 #d810ba] | ACD-V19 #d810ba | 境界値 | retry() | ✅ |
| 27 | ログイン中で uid A の記録が requested の状態で retry の処理中にもう一度 retry を呼び関数・端末内の削除が成功した場合、requestServerDeletion は合計1回、deleteLocalData(A) は合計1回呼ばれる [ACD-V20 #07c1f5] | ACD-V20 #07c1f5 | 境界値 | retry() | ✅ |
| 28 | phase が pendingRetry、retryFailed が true の状態で retry を呼び関数の応答を待っている場合、phase が processing、retryFailed が false になる [ACD-V23 #a34a49] | ACD-V23 #a34a49 | 境界値 | retry() | ✅ |
| 29 | uid A の記録が serverDone の状態で retry を呼び端末内の削除の完了を待っている場合、phase が processing になる [ACD-V25 #cf5e64] | ACD-V25 #cf5e64 | 境界値 | retry() | ✅ |
| 30 | ログイン中の uid が B、記録が uid A の requested の状態で retry を呼び端末内の削除が成功した場合、phase が completed になり、requestServerDeletion は0回、signOut が deleteLocalData(A) より先に呼ばれ、deleteLocalData(B) は0回 [ACD-V26 #8b7f12] | ACD-V26 #8b7f12 | 正常系 | retry() | ✅ |
| 31 | uid A の記録が serverDone の状態で retry を呼び端末内の削除が成功し signOut が UnknownFailure で失敗した場合、phase が completed になる [ACD-V27 #a901f8] | ACD-V27 #a901f8 | 異常系 | retry() | ✅ |
| 32 | ログイン中で uid A の記録が requested の状態で retry を呼び関数は成功し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は serverDone、signOut は0回 [ACD-V29 #4d44fc] | ACD-V29 #4d44fc | 異常系 | retry() | ✅ |
| 33 | ログインしていない状態で uid A の記録が requested のまま retry を呼び端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、signOut は0回 [ACD-V30 #23a844] | ACD-V30 #23a844 | 異常系 | retry() | ✅ |
| 34 | ログイン中で uid A の記録が requested の状態で retry を呼び関数が AuthFailure で失敗し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、signOut は0回 [ACD-V31 #b6565f] | ACD-V31 #b6565f | 異常系 | retry() | ✅ |
| 35 | phase が pendingRetry で findPending が None を返す状態で retry を呼んだ場合、phase が idle になり、requestServerDeletion・deleteLocalData は0回 [ACD-V34 #851f75] | ACD-V34 #851f75 | 境界値 | retry() | ✅ |
| 36 | phase が completed の状態で acknowledgeCompleted を呼んだ場合、phase が idle になる [ACD-V21 #70d905] | ACD-V21 #70d905 | 正常系 | acknowledgeCompleted() | ✅ |
| 37 | phase が notSent の状態で acknowledgeNotSent を呼んだ場合、phase が idle になる [ACD-V22 #12c47a] | ACD-V22 #12c47a | 正常系 | acknowledgeNotSent() | ✅ |
| 38 | 記録が無い状態で withdraw(password: pass1234) を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、phase が completed になり、パスワードでの本人確認が1回呼ばれその後に markRequested(A) が呼ばれ、Google での本人確認は0回 [ACD-V112 #bb071f] | ACD-V112 ##bb071f | 正常系 | withdraw() | ✅ |
| 39 | 記録が無い状態で withdraw() を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、phase が completed になり、Google での本人確認が1回呼ばれその後に markRequested(A) が呼ばれ、パスワードでの本人確認は0回 [ACD-V113 #cff476] | ACD-V113 ##cff476 | 正常系 | withdraw() | ✅ |
| 40 | 記録が無い状態で withdraw を呼び本人確認の応答を待っている場合、phase が processing になり、markRequested・requestServerDeletion は0回 [ACD-V114 #772eb7] | ACD-V114 ##772eb7 | 境界値 | withdraw() | ✅ |
| 41 | 記録が無い状態で withdraw() を呼び Google の本人確認がキャンセルされた（Right(false)）場合、phase が idle になり、markRequested・requestServerDeletion は0回 [ACD-V115 #084914] | ACD-V115 ##084914 | 境界値 | withdraw() | ✅ |
| 42 | 記録が無い状態で withdraw を呼び本人確認が AuthFailure で失敗した場合、phase が reauthRejected になり、markRequested・requestServerDeletion は0回 [ACD-V116 #6b81f2] | ACD-V116 ##6b81f2 | 異常系 | withdraw() | ✅ |
| 43 | 記録が無い状態で withdraw を呼び本人確認が NetworkFailure で失敗した場合、phase が notSent になり、markRequested・requestServerDeletion は0回 [ACD-V117 #055409] | ACD-V117 ##055409 | 異常系 | withdraw() | ✅ |
| 44 | 記録が無い状態で withdraw を呼び本人確認が UnknownFailure で失敗した場合、phase が notSent になり、markRequested・requestServerDeletion は0回 [ACD-V118 #c267a8] | ACD-V118 ##c267a8 | 異常系 | withdraw() | ✅ |
| 45 | 記録が無い状態で withdraw を呼び本人確認は成功し関数の呼び出しが RecentLoginRequiredFailure で失敗した場合、phase が notSent になり、clearRequest(A) が1回呼ばれ記録は無く、deleteLocalData・signOut は0回 [ACD-V119 #fed568] | ACD-V119 ##fed568 | 異常系 | withdraw() | ✅ |
| 46 | 記録が無い状態で withdraw を呼び本人確認の処理中にもう一度 withdraw を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、本人確認は合計1回、requestServerDeletion は合計1回呼ばれる [ACD-V133 #3a65ad] | ACD-V133 ##3a65ad | 境界値 | retryWithReauth() | ✅ |
| 47 | 記録が無い状態で withdraw を呼び本人確認は成功し関数の呼び出しが RecentLoginRequiredFailure で失敗し clearRequest が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false で、記録は requested のまま [ACD-V142 #5bb0c8] | ACD-V142 ##5bb0c8 | 異常系 | withdraw() | ✅ |
| 48 | 記録が無い状態で withdraw を呼び本人確認が TooManyRequestsFailure で失敗した場合、phase が reauthRejected、tooManyAttempts が true になり、markRequested・requestServerDeletion は0回 [ACD-V143 #9501bc] | ACD-V143 ##9501bc | 異常系 | withdraw() | ✅ |
| 49 | 記録が無い状態で withdraw を呼び本人確認の応答を待っている間に WithdrawnElsewhereViewModel の phase が notifying になりその後に本人確認が成功した場合、phase が idle になり、markRequested・requestServerDeletion は0回 [ACD-V145 #e1a7a8] | ACD-V145 ##e1a7a8 | 境界値 | withdraw() | ✅ |
| 50 | 記録が無い状態で withdraw を呼び本人確認の応答を待っている間にログアウトしてログイン中のユーザーがいなくなりその後に本人確認が成功した場合、phase が idle になり、markRequested・requestServerDeletion は0回 [ACD-V146 #11389e] | ACD-V146 ##11389e | 境界値 | withdraw() | ✅ |
| 51 | 記録が無い状態で withdraw を呼び本人確認の応答を待っている間に WithdrawnElsewhereViewModel の phase が notifying になりその後に本人確認が AuthFailure で失敗した場合、phase が idle になる（reauthRejected にならない） [ACD-V147 #617724] | ACD-V147 ##617724 | 境界値 | withdraw() | ✅ |
| 52 | phase が reauthRejected の状態で withdraw を呼んだ場合、phase は reauthRejected のままで、本人確認・markRequested は0回 [ACD-V141 #1d2547] | ACD-V141 ##1d2547 | 境界値 | withdraw() | ✅ |
| 53 | phase が reauthRejected の状態で acknowledgeReauthRejected を呼んだ場合、phase が idle になる [ACD-V120 #ea5006] | ACD-V120 ##ea5006 | 正常系 | acknowledgeReauthRejected() | ✅ |
| 54 | ログイン中で uid A の記録が requested の状態で retry を呼び関数の呼び出しが RecentLoginRequiredFailure で失敗した場合、phase が reauthRequired、retryFailed と reauthRejected が false で、記録は requested のまま、deleteLocalData・signOut は0回 [ACD-V121 #8ac353] | ACD-V121 ##8ac353 | 異常系 | retry() | ✅ |
| 55 | phase が reauthRequired の状態で retry を呼んだ場合、phase は reauthRequired のままで、本人確認・requestServerDeletion は0回 [ACD-V140 #41d65a] | ACD-V140 ##41d65a | 境界値 | retry() | ✅ |
| 56 | phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth(password: pass1234) を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、phase が completed になり、パスワードでの本人確認が1回呼ばれその後に requestServerDeletion が1回呼ばれる [ACD-V122 #9eace4] | ACD-V122 ##9eace4 | 正常系 | retryWithReauth() | ✅ |
| 57 | phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth() を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、phase が completed になり、Google での本人確認が1回呼ばれその後に requestServerDeletion が1回呼ばれる [ACD-V123 #2abec5] | ACD-V123 ##2abec5 | 正常系 | retryWithReauth() | ✅ |
| 58 | phase が reauthRequired の状態で retryWithReauth を呼び本人確認の応答を待っている場合、phase が processing、isRetry が true で、requestServerDeletion は呼ばれていない [ACD-V124 #c1ed04] | ACD-V124 ##c1ed04 | 境界値 | retryWithReauth() | ✅ |
| 59 | phase が reauthRequired の状態で retryWithReauth() を呼び Google の本人確認がキャンセルされた（Right(false)）場合、phase が reauthRequired、retryFailed と reauthRejected が false で、requestServerDeletion は呼ばれない [ACD-V125 #90bfe8] | ACD-V125 ##90bfe8 | 境界値 | retryWithReauth() | ✅ |
| 60 | phase が reauthRequired の状態で retryWithReauth を呼び本人確認が AuthFailure で失敗した場合、phase が reauthRequired、reauthRejected が true、retryFailed が false で、requestServerDeletion は呼ばれない [ACD-V126 #aa8f1f] | ACD-V126 ##aa8f1f | 異常系 | retryWithReauth() | ✅ |
| 61 | phase が reauthRequired の状態で retryWithReauth を呼び本人確認が NetworkFailure で失敗した場合、phase が reauthRequired、retryFailed が true、reauthRejected が false で、requestServerDeletion は呼ばれない [ACD-V127 #f69a83] | ACD-V127 ##f69a83 | 異常系 | retryWithReauth() | ✅ |
| 62 | phase が reauthRequired の状態で retryWithReauth を呼び本人確認が UnknownFailure で失敗した場合、phase が reauthRequired、retryFailed が true、reauthRejected が false で、requestServerDeletion は呼ばれない [ACD-V128 #c036fd] | ACD-V128 ##c036fd | 異常系 | retryWithReauth() | ✅ |
| 63 | phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しが UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま [ACD-V129 #0c0655] | ACD-V129 ##0c0655 | 異常系 | retryWithReauth() | ✅ |
| 64 | phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しがまた RecentLoginRequiredFailure で失敗した場合、phase が reauthRequired で、記録は requested のまま [ACD-V130 #69b67f] | ACD-V130 ##69b67f | 異常系 | retryWithReauth() | ✅ |
| 65 | phase が pendingRetry の状態で retryWithReauth を呼んだ場合、phase は pendingRetry のままで、本人確認・requestServerDeletion は0回 [ACD-V131 #ad22e0] | ACD-V131 ##ad22e0 | 境界値 | retryWithReauth() | ✅ |
| 66 | phase が reauthRequired の状態で retryWithReauth を呼びその処理中にもう一度 retryWithReauth を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、本人確認は合計1回、requestServerDeletion は合計1回呼ばれる [ACD-V132 #8fef57] | ACD-V132 ##8fef57 | 境界値 | retryWithReauth() | ✅ |
| 67 | phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しが NetworkFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま [ACD-V134 #0307dc] | ACD-V134 ##0307dc | 異常系 | retryWithReauth() | ✅ |
| 68 | phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しが AuthFailure で失敗し端末内の削除が成功した場合、phase が completed になり、deleteLocalData(A) は1回、signOut は1回 [ACD-V135 #832eca] | ACD-V135 ##832eca | 異常系 | retryWithReauth() | ✅ |
| 69 | phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は serverDone、signOut は0回 [ACD-V136 #e2c563] | ACD-V136 ##e2c563 | 異常系 | retryWithReauth() | ✅ |
| 70 | phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しが AuthFailure で失敗し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、signOut は0回 [ACD-V137 #64e2e0] | ACD-V137 ##64e2e0 | 異常系 | retryWithReauth() | ✅ |
| 71 | phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認・関数の呼び出し・端末内の削除が成功し signOut が UnknownFailure で失敗した場合、phase が completed になる [ACD-V138 #86360b] | ACD-V138 ##86360b | 異常系 | retryWithReauth() | ✅ |
| 72 | phase が reauthRequired、reauthRejected が true の状態で retryWithReauth を呼び本人確認の応答を待っている場合、phase が processing、reauthRejected と retryFailed が false になる [ACD-V139 #5537c4] | ACD-V139 ##5537c4 | 境界値 | retryWithReauth() | ✅ |
| 73 | phase が reauthRequired の状態で retryWithReauth を呼び本人確認が TooManyRequestsFailure で失敗した場合、phase が reauthRequired、tooManyAttempts が true、retryFailed と reauthRejected が false で、requestServerDeletion は呼ばれない [ACD-V144 #d4576a] | ACD-V144 ##d4576a | 異常系 | retryWithReauth() | ✅ |

## テストケース詳細

### テストケース1: ViewModelを作成した直後（checkPending の完了前）の場合、phase が checking になる [ACD-V38 #1fc7e1]
- **カテゴリ**: 境界値
- **対象メソッド**: build()
- **事前条件**: なし
- **入力値・テスト条件**: ViewModel を作成した直後（`checkPending` の完了前）
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `checking`

### テストケース2: 記録が無い状態で起動時の確認をした場合、phase が idle になる [ACD-V01 #ed5294]
- **カテゴリ**: 正常系
- **対象メソッド**: checkPending()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で起動時の確認（`checkPending`）をした
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`

### テストケース3: uid A の記録が requested の状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V02 #37e832]
- **カテゴリ**: 正常系
- **対象メソッド**: checkPending()
- **事前条件**: なし
- **入力値・テスト条件**: uid `A` の記録が `requested` の状態で `checkPending` をした
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は false

### テストケース4: uid A の記録が serverDone の状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V03 #c620c9]
- **カテゴリ**: 正常系
- **対象メソッド**: checkPending()
- **事前条件**: なし
- **入力値・テスト条件**: uid `A` の記録が `serverDone` の状態で `checkPending` をした
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は false

### テストケース5: ログイン中の uid が B、記録が uid A の requested の状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V28 #810398]
- **カテゴリ**: 正常系
- **対象メソッド**: checkPending()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `B`、記録が uid `A` の `requested` の状態で `checkPending` をした
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は false

### テストケース6: 記録の読み取りが UnknownFailure で失敗する状態で起動時の確認をした場合、phase が pendingRetry、retryFailed が false になる [ACD-V33 #286851]
- **カテゴリ**: 異常系
- **対象メソッド**: checkPending()
- **事前条件**: なし
- **入力値・テスト条件**: 記録の読み取り（`findPending`）が `UnknownFailure` で失敗する状態で `checkPending` をした
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は false

### テストケース7: 記録が無い状態で withdraw を呼び関数の応答を待っている場合、phase が processing、記録が requested で、waitUntilIdle の完了後に requestServerDeletion が1回呼ばれる [ACD-V04 #5d474d]
- **カテゴリ**: 境界値
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、関数の応答を待っている
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `processing`。uid `A` の記録は `requested`。`SyncRepository.waitUntilIdle` が1回呼ばれ、その完了後に `requestServerDeletion` が1回呼ばれる

### テストケース8: 記録が無い状態で withdraw を呼び関数の呼び出しと端末内の削除がどちらも成功した場合、phase が completed になり、markRequested・requestServerDeletion・markServerDone・deleteLocalData・signOut がこの順に1回ずつ呼ばれる [ACD-V05 #7735f6]
- **カテゴリ**: 正常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、関数の呼び出しと端末内の削除がどちらも成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`markRequested(A)`・`requestServerDeletion`・`markServerDone(A)`・`deleteLocalData(A)`・`AuthRepository.signOut` がこの順に1回ずつ呼ばれる

### テストケース9: 記録が無い状態で withdraw を呼び関数の呼び出しが NetworkFailure で失敗した場合、phase が notSent になり、clearRequest(A) が1回呼ばれ記録は無く、markServerDone・deleteLocalData・signOut は0回 [ACD-V06 #7cc1c8]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、関数の呼び出しが `NetworkFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notSent`。`clearRequest(A)` が1回呼ばれ、uid `A` の記録は無い。`markServerDone`・`deleteLocalData`・`signOut` は0回

### テストケース10: 記録が無い状態で withdraw を呼び関数の呼び出しが UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false で、記録は requested のまま、clearRequest・deleteLocalData・signOut は0回 [ACD-V07 #ce393b]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、関数の呼び出しが `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は false。uid `A` の記録は `requested` のまま。`clearRequest`・`deleteLocalData`・`signOut` は0回

### テストケース11: 記録が無い状態で withdraw を呼び関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false で、記録は serverDone、signOut は0回 [ACD-V08 #d10e09]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、関数の呼び出しは成功し、端末内の削除が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は false。uid `A` の記録は `serverDone`。`signOut` は0回

### テストケース12: phase が processing の間にもう一度 withdraw を呼んだ場合、requestServerDeletion は合計1回だけ呼ばれる [ACD-V09 #a68a80]
- **カテゴリ**: 境界値
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `processing` の間に、もう一度 `withdraw` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `requestServerDeletion` は合計1回だけ呼ばれる

### テストケース13: 記録が無い状態で withdraw を呼び関数の呼び出しが AuthFailure で失敗した場合、phase が notSent になり、clearRequest(A) が1回呼ばれ記録は無く、deleteLocalData・signOut は0回 [ACD-V11 #76228d]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、関数の呼び出しが `AuthFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notSent`。`clearRequest(A)` が1回呼ばれ、uid `A` の記録は無い。`deleteLocalData`・`signOut` は0回

### テストケース14: 記録が無い状態で withdraw を呼び関数・端末内の削除が成功し signOut が UnknownFailure で失敗した場合、phase が completed になる [ACD-V24 #bf80d9]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、関数の呼び出しと端末内の削除が成功し、`signOut` が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`

### テストケース15: phase が pendingRetry の状態で withdraw を呼んだ場合、phase は pendingRetry のままで、markRequested・requestServerDeletion は0回 [ACD-V32 #34d262]
- **カテゴリ**: 境界値
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `pendingRetry` の状態で `withdraw` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry` のまま。`markRequested`・`requestServerDeletion` は0回

### テストケース16: 記録が無い状態で withdraw を呼び markRequested が UnknownFailure で失敗した場合、phase が notSent になり、requestServerDeletion は0回 [ACD-V35 #235d99]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、`markRequested` が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notSent`。`requestServerDeletion` は0回

### テストケース17: 記録が無い状態で withdraw を呼び関数が NetworkFailure で失敗し clearRequest が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false になる [ACD-V36 #75999d]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、関数の呼び出しが `NetworkFailure` で失敗し、`clearRequest` が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は false

### テストケース18: 記録が無い状態で withdraw を呼び関数は成功し markServerDone が UnknownFailure で失敗し端末内の削除が成功した場合、phase が completed になり、deleteLocalData(A) が1回呼ばれる [ACD-V37 #1f5756]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、関数の呼び出しは成功し、`markServerDone` が `UnknownFailure` で失敗し、端末内の削除は成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`deleteLocalData(A)` は1回

### テストケース19: ログイン中で uid A の記録が requested の状態で retry を呼び関数・端末内の削除が成功した場合、phase が completed になり、requestServerDeletion・markServerDone(A)・deleteLocalData(A)・signOut がこの順に1回ずつ呼ばれる [ACD-V12 #8c6c4b]
- **カテゴリ**: 正常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しと端末内の削除がどちらも成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`requestServerDeletion`・`markServerDone(A)`・`deleteLocalData(A)`・`signOut` がこの順に1回ずつ呼ばれる

### テストケース20: uid A の記録が serverDone の状態で retry を呼び端末内の削除が成功した場合、phase が completed になり、requestServerDeletion は0回、deleteLocalData(A) は1回、signOut は1回 [ACD-V13 #7badb4]
- **カテゴリ**: 正常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: uid `A` の記録が `serverDone` の状態で `retry` を呼び、端末内の削除が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`requestServerDeletion` は0回、`deleteLocalData(A)` は1回、`signOut` は1回

### テストケース21: ログインしていない状態で uid A の記録が requested のまま retry を呼び端末内の削除が成功した場合、phase が completed になり、requestServerDeletion は0回、deleteLocalData(A) は1回、signOut は1回 [ACD-V14 #ef3249]
- **カテゴリ**: 正常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で uid `A` の記録が `requested` のまま `retry` を呼び、端末内の削除が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`requestServerDeletion` は0回、`deleteLocalData(A)` は1回、`signOut` は1回

### テストケース22: ログイン中で uid A の記録が requested の状態で retry を呼び関数が AuthFailure で失敗し端末内の削除が成功した場合、phase が completed になり、deleteLocalData(A) は1回、signOut は1回 [ACD-V15 #ea056e]
- **カテゴリ**: 異常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しが `AuthFailure` で失敗し、端末内の削除が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`deleteLocalData(A)` は1回、`signOut` は1回

### テストケース23: ログイン中で uid A の記録が requested の状態で retry を呼び関数が NetworkFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、deleteLocalData は0回 [ACD-V16 #5df076]
- **カテゴリ**: 異常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しが `NetworkFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま。`deleteLocalData` は0回

### テストケース24: ログイン中で uid A の記録が requested の状態で retry を呼び関数が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、deleteLocalData は0回 [ACD-V17 #b8b268]
- **カテゴリ**: 異常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しが `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま。`deleteLocalData` は0回

### テストケース25: uid A の記録が serverDone の状態で retry を呼び端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は serverDone のまま [ACD-V18 #723164]
- **カテゴリ**: 異常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: uid `A` の記録が `serverDone` の状態で `retry` を呼び、端末内の削除が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `serverDone` のまま

### テストケース26: ログイン中で uid A の記録が requested の状態で retry を呼び関数の応答を待っている場合、phase が processing になる [ACD-V19 #d810ba]
- **カテゴリ**: 境界値
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の応答を待っている
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `processing`

### テストケース27: ログイン中で uid A の記録が requested の状態で retry の処理中にもう一度 retry を呼び関数・端末内の削除が成功した場合、requestServerDeletion は合計1回、deleteLocalData(A) は合計1回呼ばれる [ACD-V20 #07c1f5]
- **カテゴリ**: 境界値
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、その処理中にもう一度 `retry` を呼び、関数の呼び出しと端末内の削除がどちらも成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `requestServerDeletion` は合計1回、`deleteLocalData(A)` は合計1回呼ばれる

### テストケース28: phase が pendingRetry、retryFailed が true の状態で retry を呼び関数の応答を待っている場合、phase が processing、retryFailed が false になる [ACD-V23 #a34a49]
- **カテゴリ**: 境界値
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `pendingRetry`、`retryFailed` が true の状態で `retry` を呼び、関数の応答を待っている
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `processing`、`retryFailed` は false

### テストケース29: uid A の記録が serverDone の状態で retry を呼び端末内の削除の完了を待っている場合、phase が processing になる [ACD-V25 #cf5e64]
- **カテゴリ**: 境界値
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: uid `A` の記録が `serverDone` の状態で `retry` を呼び、端末内の削除の完了を待っている
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `processing`

### テストケース30: ログイン中の uid が B、記録が uid A の requested の状態で retry を呼び端末内の削除が成功した場合、phase が completed になり、requestServerDeletion は0回、signOut が deleteLocalData(A) より先に呼ばれ、deleteLocalData(B) は0回 [ACD-V26 #8b7f12]
- **カテゴリ**: 正常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中の uid が `B`、記録が uid `A` の `requested` の状態で `retry` を呼び、端末内の削除が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`requestServerDeletion` は0回。`signOut` が `deleteLocalData(A)` より先に呼ばれる。`deleteLocalData(B)` は0回

### テストケース31: uid A の記録が serverDone の状態で retry を呼び端末内の削除が成功し signOut が UnknownFailure で失敗した場合、phase が completed になる [ACD-V27 #a901f8]
- **カテゴリ**: 異常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: uid `A` の記録が `serverDone` の状態で `retry` を呼び、端末内の削除が成功し、`signOut` が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`

### テストケース32: ログイン中で uid A の記録が requested の状態で retry を呼び関数は成功し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は serverDone、signOut は0回 [ACD-V29 #4d44fc]
- **カテゴリ**: 異常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しは成功し、端末内の削除が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `serverDone`。`signOut` は0回

### テストケース33: ログインしていない状態で uid A の記録が requested のまま retry を呼び端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、signOut は0回 [ACD-V30 #23a844]
- **カテゴリ**: 異常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログインしていない状態で uid `A` の記録が `requested` のまま `retry` を呼び、端末内の削除が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま。`signOut` は0回

### テストケース34: ログイン中で uid A の記録が requested の状態で retry を呼び関数が AuthFailure で失敗し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、signOut は0回 [ACD-V31 #b6565f]
- **カテゴリ**: 異常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しが `AuthFailure` で失敗し、端末内の削除が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま。`signOut` は0回

### テストケース35: phase が pendingRetry で findPending が None を返す状態で retry を呼んだ場合、phase が idle になり、requestServerDeletion・deleteLocalData は0回 [ACD-V34 #851f75]
- **カテゴリ**: 境界値
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `pendingRetry` で、`findPending` が `Right(None)` を返す状態で `retry` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`requestServerDeletion`・`deleteLocalData` は0回

### テストケース36: phase が completed の状態で acknowledgeCompleted を呼んだ場合、phase が idle になる [ACD-V21 #70d905]
- **カテゴリ**: 正常系
- **対象メソッド**: acknowledgeCompleted()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `completed` の状態で `acknowledgeCompleted` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`

### テストケース37: phase が notSent の状態で acknowledgeNotSent を呼んだ場合、phase が idle になる [ACD-V22 #12c47a]
- **カテゴリ**: 正常系
- **対象メソッド**: acknowledgeNotSent()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `notSent` の状態で `acknowledgeNotSent` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`

### テストケース38: 記録が無い状態で withdraw(password: pass1234) を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、phase が completed になり、パスワードでの本人確認が1回呼ばれその後に markRequested(A) が呼ばれ、Google での本人確認は0回 [ACD-V112 #bb071f]
- **カテゴリ**: 正常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw(password: 'pass1234')` を呼び、本人確認・関数の呼び出し・端末内の削除がすべて成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`reauthenticateWithPassword('pass1234')` が1回呼ばれ、その後に `markRequested(A)` が呼ばれる。`reauthenticateWithGoogle` は0回

### テストケース39: 記録が無い状態で withdraw() を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、phase が completed になり、Google での本人確認が1回呼ばれその後に markRequested(A) が呼ばれ、パスワードでの本人確認は0回 [ACD-V113 #cff476]
- **カテゴリ**: 正常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw()` を呼び、本人確認・関数の呼び出し・端末内の削除がすべて成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`reauthenticateWithGoogle` が1回呼ばれ、その後に `markRequested(A)` が呼ばれる。`reauthenticateWithPassword` は0回

### テストケース40: 記録が無い状態で withdraw を呼び本人確認の応答を待っている場合、phase が processing になり、markRequested・requestServerDeletion は0回 [ACD-V114 #772eb7]
- **カテゴリ**: 境界値
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認の応答を待っている
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `processing`。`markRequested`・`requestServerDeletion` は0回

### テストケース41: 記録が無い状態で withdraw() を呼び Google の本人確認がキャンセルされた（Right(false)）場合、phase が idle になり、markRequested・requestServerDeletion は0回 [ACD-V115 #084914]
- **カテゴリ**: 境界値
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw()` を呼び、Google の本人確認がキャンセルされた（`Right(false)`）
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`markRequested`・`requestServerDeletion` は0回

### テストケース42: 記録が無い状態で withdraw を呼び本人確認が AuthFailure で失敗した場合、phase が reauthRejected になり、markRequested・requestServerDeletion は0回 [ACD-V116 #6b81f2]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認が `AuthFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRejected`。`markRequested`・`requestServerDeletion` は0回

### テストケース43: 記録が無い状態で withdraw を呼び本人確認が NetworkFailure で失敗した場合、phase が notSent になり、markRequested・requestServerDeletion は0回 [ACD-V117 #055409]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認が `NetworkFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notSent`。`markRequested`・`requestServerDeletion` は0回

### テストケース44: 記録が無い状態で withdraw を呼び本人確認が UnknownFailure で失敗した場合、phase が notSent になり、markRequested・requestServerDeletion は0回 [ACD-V118 #c267a8]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notSent`。`markRequested`・`requestServerDeletion` は0回

### テストケース45: 記録が無い状態で withdraw を呼び本人確認は成功し関数の呼び出しが RecentLoginRequiredFailure で失敗した場合、phase が notSent になり、clearRequest(A) が1回呼ばれ記録は無く、deleteLocalData・signOut は0回 [ACD-V119 #fed568]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認は成功し、関数の呼び出しが `RecentLoginRequiredFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `notSent`。`clearRequest(A)` が1回呼ばれ、uid `A` の記録は無い。`deleteLocalData`・`signOut` は0回

### テストケース46: 記録が無い状態で withdraw を呼び本人確認の処理中にもう一度 withdraw を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、本人確認は合計1回、requestServerDeletion は合計1回呼ばれる [ACD-V133 #3a65ad]
- **カテゴリ**: 境界値
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認の処理中にもう一度 `withdraw` を呼び、本人確認・関数の呼び出し・端末内の削除がすべて成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: 本人確認は合計1回、`requestServerDeletion` は合計1回呼ばれる

### テストケース47: 記録が無い状態で withdraw を呼び本人確認は成功し関数の呼び出しが RecentLoginRequiredFailure で失敗し clearRequest が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が false で、記録は requested のまま [ACD-V142 #5bb0c8]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認は成功し、関数の呼び出しが `RecentLoginRequiredFailure` で失敗し、`clearRequest` が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は false。uid `A` の記録は `requested` のまま

### テストケース48: 記録が無い状態で withdraw を呼び本人確認が TooManyRequestsFailure で失敗した場合、phase が reauthRejected、tooManyAttempts が true になり、markRequested・requestServerDeletion は0回 [ACD-V143 #9501bc]
- **カテゴリ**: 異常系
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認が `TooManyRequestsFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRejected`、`tooManyAttempts` は true。`markRequested`・`requestServerDeletion` は0回

### テストケース49: 記録が無い状態で withdraw を呼び本人確認の応答を待っている間に WithdrawnElsewhereViewModel の phase が notifying になりその後に本人確認が成功した場合、phase が idle になり、markRequested・requestServerDeletion は0回 [ACD-V145 #e1a7a8]
- **カテゴリ**: 境界値
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認の応答を待っている間に `WithdrawnElsewhereViewModel` の `phase` が `notifying` になり、その後に本人確認が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`markRequested`・`requestServerDeletion` は0回

### テストケース50: 記録が無い状態で withdraw を呼び本人確認の応答を待っている間にログアウトしてログイン中のユーザーがいなくなりその後に本人確認が成功した場合、phase が idle になり、markRequested・requestServerDeletion は0回 [ACD-V146 #11389e]
- **カテゴリ**: 境界値
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認の応答を待っている間にログアウトしてログイン中のユーザーがいなくなり、その後に本人確認が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`markRequested`・`requestServerDeletion` は0回

### テストケース51: 記録が無い状態で withdraw を呼び本人確認の応答を待っている間に WithdrawnElsewhereViewModel の phase が notifying になりその後に本人確認が AuthFailure で失敗した場合、phase が idle になる（reauthRejected にならない） [ACD-V147 #617724]
- **カテゴリ**: 境界値
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: 記録が無い状態で `withdraw` を呼び、本人確認の応答を待っている間に `WithdrawnElsewhereViewModel` の `phase` が `notifying` になり、その後に本人確認が `AuthFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`（`reauthRejected` にならない）

### テストケース52: phase が reauthRejected の状態で withdraw を呼んだ場合、phase は reauthRejected のままで、本人確認・markRequested は0回 [ACD-V141 #1d2547]
- **カテゴリ**: 境界値
- **対象メソッド**: withdraw()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRejected` の状態で `withdraw` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRejected` のまま。本人確認・`markRequested` は0回

### テストケース53: phase が reauthRejected の状態で acknowledgeReauthRejected を呼んだ場合、phase が idle になる [ACD-V120 #ea5006]
- **カテゴリ**: 正常系
- **対象メソッド**: acknowledgeReauthRejected()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRejected` の状態で `acknowledgeReauthRejected` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`

### テストケース54: ログイン中で uid A の記録が requested の状態で retry を呼び関数の呼び出しが RecentLoginRequiredFailure で失敗した場合、phase が reauthRequired、retryFailed と reauthRejected が false で、記録は requested のまま、deleteLocalData・signOut は0回 [ACD-V121 #8ac353]
- **カテゴリ**: 異常系
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: ログイン中で uid `A` の記録が `requested` の状態で `retry` を呼び、関数の呼び出しが `RecentLoginRequiredFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRequired`、`retryFailed` は false、`reauthRejected` は false。uid `A` の記録は `requested` のまま。`deleteLocalData`・`signOut` は0回

### テストケース55: phase が reauthRequired の状態で retry を呼んだ場合、phase は reauthRequired のままで、本人確認・requestServerDeletion は0回 [ACD-V140 #41d65a]
- **カテゴリ**: 境界値
- **対象メソッド**: retry()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired` の状態で `retry` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRequired` のまま。本人確認・`requestServerDeletion` は0回

### テストケース56: phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth(password: pass1234) を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、phase が completed になり、パスワードでの本人確認が1回呼ばれその後に requestServerDeletion が1回呼ばれる [ACD-V122 #9eace4]
- **カテゴリ**: 正常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired`、uid `A` の記録が `requested` の状態で `retryWithReauth(password: 'pass1234')` を呼び、本人確認・関数の呼び出し・端末内の削除がすべて成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`reauthenticateWithPassword('pass1234')` が1回呼ばれ、その後に `requestServerDeletion` が1回呼ばれる

### テストケース57: phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth() を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、phase が completed になり、Google での本人確認が1回呼ばれその後に requestServerDeletion が1回呼ばれる [ACD-V123 #2abec5]
- **カテゴリ**: 正常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired`、uid `A` の記録が `requested` の状態で `retryWithReauth()` を呼び、本人確認・関数の呼び出し・端末内の削除がすべて成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`reauthenticateWithGoogle` が1回呼ばれ、その後に `requestServerDeletion` が1回呼ばれる

### テストケース58: phase が reauthRequired の状態で retryWithReauth を呼び本人確認の応答を待っている場合、phase が processing、isRetry が true で、requestServerDeletion は呼ばれていない [ACD-V124 #c1ed04]
- **カテゴリ**: 境界値
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired` の状態で `retryWithReauth` を呼び、本人確認の応答を待っている
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `processing`、`isRetry` は true。`requestServerDeletion` は呼ばれていない

### テストケース59: phase が reauthRequired の状態で retryWithReauth() を呼び Google の本人確認がキャンセルされた（Right(false)）場合、phase が reauthRequired、retryFailed と reauthRejected が false で、requestServerDeletion は呼ばれない [ACD-V125 #90bfe8]
- **カテゴリ**: 境界値
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired` の状態で `retryWithReauth()` を呼び、Google の本人確認がキャンセルされた（`Right(false)`）
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRequired`、`retryFailed` は false、`reauthRejected` は false。`requestServerDeletion` は呼ばれない

### テストケース60: phase が reauthRequired の状態で retryWithReauth を呼び本人確認が AuthFailure で失敗した場合、phase が reauthRequired、reauthRejected が true、retryFailed が false で、requestServerDeletion は呼ばれない [ACD-V126 #aa8f1f]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired` の状態で `retryWithReauth` を呼び、本人確認が `AuthFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRequired`、`reauthRejected` は true、`retryFailed` は false。`requestServerDeletion` は呼ばれない

### テストケース61: phase が reauthRequired の状態で retryWithReauth を呼び本人確認が NetworkFailure で失敗した場合、phase が reauthRequired、retryFailed が true、reauthRejected が false で、requestServerDeletion は呼ばれない [ACD-V127 #f69a83]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired` の状態で `retryWithReauth` を呼び、本人確認が `NetworkFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRequired`、`retryFailed` は true、`reauthRejected` は false。`requestServerDeletion` は呼ばれない

### テストケース62: phase が reauthRequired の状態で retryWithReauth を呼び本人確認が UnknownFailure で失敗した場合、phase が reauthRequired、retryFailed が true、reauthRejected が false で、requestServerDeletion は呼ばれない [ACD-V128 #c036fd]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired` の状態で `retryWithReauth` を呼び、本人確認が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRequired`、`retryFailed` は true、`reauthRejected` は false。`requestServerDeletion` は呼ばれない

### テストケース63: phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しが UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま [ACD-V129 #0c0655]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired`、uid `A` の記録が `requested` の状態で `retryWithReauth` を呼び、本人確認は成功し、関数の呼び出しが `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま

### テストケース64: phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しがまた RecentLoginRequiredFailure で失敗した場合、phase が reauthRequired で、記録は requested のまま [ACD-V130 #69b67f]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired`、uid `A` の記録が `requested` の状態で `retryWithReauth` を呼び、本人確認は成功し、関数の呼び出しがまた `RecentLoginRequiredFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRequired`。uid `A` の記録は `requested` のまま

### テストケース65: phase が pendingRetry の状態で retryWithReauth を呼んだ場合、phase は pendingRetry のままで、本人確認・requestServerDeletion は0回 [ACD-V131 #ad22e0]
- **カテゴリ**: 境界値
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `pendingRetry` の状態で `retryWithReauth` を呼んだ
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry` のまま。本人確認・`requestServerDeletion` は0回

### テストケース66: phase が reauthRequired の状態で retryWithReauth を呼びその処理中にもう一度 retryWithReauth を呼び本人確認・関数の呼び出し・端末内の削除がすべて成功した場合、本人確認は合計1回、requestServerDeletion は合計1回呼ばれる [ACD-V132 #8fef57]
- **カテゴリ**: 境界値
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired` の状態で `retryWithReauth` を呼び、その処理中にもう一度 `retryWithReauth` を呼び、本人確認・関数の呼び出し・端末内の削除がすべて成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: 本人確認は合計1回、`requestServerDeletion` は合計1回呼ばれる

### テストケース67: phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しが NetworkFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま [ACD-V134 #0307dc]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired`、uid `A` の記録が `requested` の状態で `retryWithReauth` を呼び、本人確認は成功し、関数の呼び出しが `NetworkFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま

### テストケース68: phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しが AuthFailure で失敗し端末内の削除が成功した場合、phase が completed になり、deleteLocalData(A) は1回、signOut は1回 [ACD-V135 #832eca]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired`、uid `A` の記録が `requested` の状態で `retryWithReauth` を呼び、本人確認は成功し、関数の呼び出しが `AuthFailure` で失敗し、端末内の削除が成功した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`。`deleteLocalData(A)` は1回、`signOut` は1回

### テストケース69: phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しは成功し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は serverDone、signOut は0回 [ACD-V136 #e2c563]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired`、uid `A` の記録が `requested` の状態で `retryWithReauth` を呼び、本人確認は成功し、関数の呼び出しは成功し、端末内の削除が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `serverDone`。`signOut` は0回

### テストケース70: phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認は成功し関数の呼び出しが AuthFailure で失敗し端末内の削除が UnknownFailure で失敗した場合、phase が pendingRetry、retryFailed が true で、記録は requested のまま、signOut は0回 [ACD-V137 #64e2e0]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired`、uid `A` の記録が `requested` の状態で `retryWithReauth` を呼び、本人確認は成功し、関数の呼び出しが `AuthFailure` で失敗し、端末内の削除が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `pendingRetry`、`retryFailed` は true。uid `A` の記録は `requested` のまま。`signOut` は0回

### テストケース71: phase が reauthRequired、uid A の記録が requested の状態で retryWithReauth を呼び本人確認・関数の呼び出し・端末内の削除が成功し signOut が UnknownFailure で失敗した場合、phase が completed になる [ACD-V138 #86360b]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired`、uid `A` の記録が `requested` の状態で `retryWithReauth` を呼び、本人確認・関数の呼び出し・端末内の削除が成功し、`signOut` が `UnknownFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `completed`

### テストケース72: phase が reauthRequired、reauthRejected が true の状態で retryWithReauth を呼び本人確認の応答を待っている場合、phase が processing、reauthRejected と retryFailed が false になる [ACD-V139 #5537c4]
- **カテゴリ**: 境界値
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired`、`reauthRejected` が true の状態で `retryWithReauth` を呼び、本人確認の応答を待っている
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `processing`、`reauthRejected` は false、`retryFailed` は false

### テストケース73: phase が reauthRequired の状態で retryWithReauth を呼び本人確認が TooManyRequestsFailure で失敗した場合、phase が reauthRequired、tooManyAttempts が true、retryFailed と reauthRejected が false で、requestServerDeletion は呼ばれない [ACD-V144 #d4576a]
- **カテゴリ**: 異常系
- **対象メソッド**: retryWithReauth()
- **事前条件**: なし
- **入力値・テスト条件**: `phase` が `reauthRequired` の状態で `retryWithReauth` を呼び、本人確認が `TooManyRequestsFailure` で失敗した
- **操作手順**: 条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `reauthRequired`、`tooManyAttempts` は true、`retryFailed` は false、`reauthRejected` は false。`requestServerDeletion` は呼ばれない
