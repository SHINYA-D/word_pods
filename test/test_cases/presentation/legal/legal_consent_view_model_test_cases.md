# LegalConsentViewModel テストケース

## 対象クラス / メソッド

| 項目 | 値 |
|------|-----|
| ファイルパス | lib/presentation/legal/legal_consent_view_model.dart |
| クラス名 | LegalConsentViewModel |
| テスト対象メソッド | check() / start() / setTermsChecked() / setPrivacyChecked() / accept() / signOut() / acknowledgeNetworkError() |
| 仕様書 | docs/detailed_design/legal_consent/legal_consent.md |

## テストケース一覧

| # | テスト名 | 仕様ID | カテゴリ | 対象メソッド | 状態 |
|---|---------|--------|---------|-----------|------|
| 1 | 未同意の状態で check を呼んだ場合、phase が required で両方の行が表示対象になり、チェックと message は初期値のままになる [LGL-V01] | LGL-V01 #f6ecda | 正常系 | check() | ✅ |
| 2 | 利用規約が最新でプライバシーポリシーが古い状態で check を呼んだ場合、プライバシーポリシーだけが表示対象になる [LGL-V02] | LGL-V02 #785fee | 正常系 | check() | ✅ |
| 3 | 利用規約が古くプライバシーポリシーが最新の状態で check を呼んだ場合、利用規約だけが表示対象になる [LGL-V03] | LGL-V03 #83e49b | 正常系 | check() | ✅ |
| 4 | 両方とも現行の版数に同意済みの状態で check を呼んだ場合、phase が idle のままで表示対象にならない [LGL-V04] | LGL-V04 #8df609 | 正常系 | check() | ✅ |
| 5 | 判定が NetworkFailure を返す状態で check を呼んだ場合、phase が idle のままで表示対象にならない [LGL-V05] | LGL-V05 #63e38b | 異常系 | check() | ✅ |
| 6 | 1回目の判定が NetworkFailure で2回目が成功する状態で check を2回呼んだ場合、1回目の後は idle で2回目の後は required になる [LGL-V06] | LGL-V06 #53bff9 | 異常系 | check() | ✅ |
| 7 | 判定が UnknownFailure を返す状態で check を呼んだ場合、phase が idle のままで表示対象にならない [LGL-V07] | LGL-V07 #aa9ee9 | 異常系 | check() | ✅ |
| 8 | ログインしていない状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V09] | LGL-V09 #7282f3 | 境界値 | check() | ✅ |
| 9 | uid A の退会処理の記録が requested の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V10] | LGL-V10 #636411 | 異常系 | check() | ✅ |
| 10 | 他の端末での退会の phase が notifying の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V11] | LGL-V11 #bd2827 | 異常系 | check() | ✅ |
| 11 | phase が required の後に他の端末での退会の phase が notifying に変わった場合、phase が idle になる [LGL-V12] | LGL-V12 #0979d7 | 正常系 | check() | ✅ |
| 12 | uid A に強制ログアウトの記録がある状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V13] | LGL-V13 #deb0c4 | 異常系 | check() | ✅ |
| 13 | phase が required で利用規約をチェックした後にもう一度 check を呼んだ場合、required と termsChecked が保たれ fetchLegalConfig は合計1回になる [LGL-V14] | LGL-V14 #4531a0 | 境界値 | check() | ✅ |
| 14 | uid A の退会処理の記録が serverDone の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V33] | LGL-V33 #22aa47 | 異常系 | check() | ✅ |
| 15 | 判定の応答を待っている間にログイン中の uid が null に変わり同意が必要という結果が返った場合、phase が idle のままで表示対象にならない [LGL-V34] | LGL-V34 #909399 | 異常系 | check() | ✅ |
| 16 | 判定の応答を待っている間に他の端末での退会の phase が notifying に変わり同意が必要という結果が返った場合、phase が idle のままで表示対象にならない [LGL-V35] | LGL-V35 #62eeb3 | 異常系 | check() | ✅ |
| 17 | 判定の応答を待っている間に退会処理の記録が requested になり同意が必要という結果が返った場合、phase が idle のままで表示対象にならない [LGL-V36] | LGL-V36 #3acd6d | 異常系 | check() | ✅ |
| 18 | 判定の応答を待っている間にもう一度 check を呼んだ場合、fetchLegalConfig は合計1回で phase が required になる [LGL-V37] | LGL-V37 #69d4e0 | 境界値 | check() | ✅ |
| 19 | phase が networkError の状態で check を呼んだ場合、phase が networkError のままで fetchLegalConfig の呼び出し回数が増えない [LGL-V44] | LGL-V44 #aa4d71 | 境界値 | check() | ✅ |
| 20 | 他の端末での退会の phase が confirming の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V62] | LGL-V62 #f41230 | 異常系 | check() | ✅ |
| 21 | phase が signingOut の状態で check を呼んだ場合、phase が signingOut のままで fetchLegalConfig の呼び出し回数が増えない [LGL-V72] | LGL-V72 #8e9dd3 | 境界値 | check() | ✅ |
| 22 | `app_config/legal` が無く未同意の状態で check を呼んだ場合、phase が required で両方の行が表示対象になり config は既定値になる [LGL-V82] | LGL-V82 #3ceb47 | 正常系 | check() | ✅ |
| 23 | `app_config/legal` が無く既定値と同じ版数に同意済みの状態で check を呼んだ場合、phase が idle のままになる [LGL-V83] | LGL-V83 #d8cb4b | 正常系 | check() | ✅ |
| 24 | 初回の同期の間にログイン中の uid が A で check を呼んだ場合、phase が idle のままで fetchLegalConfig は呼ばれない [LGL-V87] | LGL-V87 #8f8520 | 境界値 | check() | ✅ |
| 25 | start の後にログイン中の uid が null から A に変わった場合、fetchLegalConfig が1回呼ばれ phase が required になる [LGL-V15] | LGL-V15 #6eca3b | 正常系 | build()（uid の変化） | ✅ |
| 26 | phase が required で termsChecked が true の状態でログイン中の uid が null に変わった場合、State が初期値に戻る [LGL-V16] | LGL-V16 #8c7a94 | 正常系 | build()（uid の変化） | ✅ |
| 27 | phase が required で termsChecked が true の状態でログイン中の uid が A から B に変わった場合、B で判定し直し、チェックと message が初期値の required になる [LGL-V46] | LGL-V46 #1f9133 | 正常系 | build()（uid の変化） | ✅ |
| 28 | start の後にログイン中の uid が null から A に変わり A が現行の版数に同意済みの場合、phase が idle のままになる [LGL-V47] | LGL-V47 #0fcbc7 | 正常系 | build()（uid の変化） | ✅ |
| 29 | 初回の同期の間にログイン中の uid が null から A に変わった場合、phase が idle のままで fetchLegalConfig は呼ばれない [LGL-V85] | LGL-V85 #56d4ab | 境界値 | build()（uid の変化） | ✅ |
| 30 | 初回の同期の間に uid が null から A に変わった後で同期が終わった場合、fetchLegalConfig が1回呼ばれ phase が required になる [LGL-V86] | LGL-V86 #b92c80 | 正常系 | build()（uid の変化） | ✅ |
| 31 | 初回の同期の間に uid が null から A に変わり同期の終わる前に null に戻ってから同期が終わった場合、phase が idle のままで fetchLegalConfig は呼ばれない [LGL-V89] | LGL-V89 #4d965a | 境界値 | build()（uid の変化） | ✅ |
| 32 | phase が required の状態で初回の同期の終了（true から false）を受けた場合、phase が required のままで fetchLegalConfig の呼び出し回数が増えない [LGL-V90] | LGL-V90 #944017 | 境界値 | build()（uid の変化） | ✅ |
| 33 | 初回の同期の間に uid が null から A に変わり同期が失敗して終わった場合、fetchLegalConfig が1回呼ばれ phase が required になる [LGL-V91] | LGL-V91 #3f7694 | 異常系 | build()（uid の変化） | ✅ |
| 34 | phase が required の状態で setTermsChecked(true) を呼んだ場合、termsChecked だけが true になる [LGL-V17] | LGL-V17 #e5d463 | 正常系 | setTermsChecked() / setPrivacyChecked() | ✅ |
| 35 | phase が required の状態で setTermsChecked(true) と setPrivacyChecked(true) を呼んだ場合、両方が true になる [LGL-V18] | LGL-V18 #c5dc38 | 正常系 | setTermsChecked() / setPrivacyChecked() | ✅ |
| 36 | 両方チェックした状態で setTermsChecked(false) を呼んだ場合、termsChecked が false で privacyChecked は true のままになる [LGL-V19] | LGL-V19 #bbad47 | 正常系 | setTermsChecked() / setPrivacyChecked() | ✅ |
| 37 | プライバシーポリシーだけが表示対象の required の状態で setPrivacyChecked(true) を呼んだ場合、privacyChecked が true になる [LGL-V20] | LGL-V20 #d2f32d | 正常系 | setTermsChecked() / setPrivacyChecked() | ✅ |
| 38 | phase が required の状態で setPrivacyChecked(true) を呼んだ場合、privacyChecked だけが true になる [LGL-V48] | LGL-V48 #aa9efe | 正常系 | setTermsChecked() / setPrivacyChecked() | ✅ |
| 39 | 両方チェックした状態で setPrivacyChecked(false) を呼んだ場合、privacyChecked が false で termsChecked は true のままになる [LGL-V49] | LGL-V49 #a2ec8d | 正常系 | setTermsChecked() / setPrivacyChecked() | ✅ |
| 40 | message が outdated の required の状態で setTermsChecked(true) を呼んだ場合、termsChecked が true で message は outdated のままになる [LGL-V59] | LGL-V59 #f2d449 | 正常系 | setTermsChecked() / setPrivacyChecked() | ✅ |
| 41 | message が signOutFailed の required の状態で setPrivacyChecked(true) を呼んだ場合、message は signOutFailed のままになる [LGL-V74] | LGL-V74 #e47b08 | 正常系 | setTermsChecked() / setPrivacyChecked() | ✅ |
| 42 | message が sendFailed の required の状態で setTermsChecked(false) を呼んだ場合、message は sendFailed のままになる [LGL-V75] | LGL-V75 #29462b | 正常系 | setTermsChecked() / setPrivacyChecked() | ✅ |
| 43 | 両方チェックして accept を呼び送信が accepted を返した場合、phase が idle で message が null になり、現行の版数2つで送信が1回呼ばれる [LGL-V21] | LGL-V21 #87feea | 正常系 | accept() | ✅ |
| 44 | 利用規約だけが表示対象で termsChecked が true の状態で accept を呼び accepted が返った場合、phase が idle で利用規約の版数とプライバシーポリシー null で送信される [LGL-V22] | LGL-V22 #774a10 | 正常系 | accept() | ✅ |
| 45 | 両方チェックして accept を呼び送信の応答を待っている場合、phase が sending になる [LGL-V23] | LGL-V23 #12266a | 正常系 | accept() | ✅ |
| 46 | 送信の応答を待っている間にもう一度 accept を呼んだ場合、送信は1回だけ呼ばれる [LGL-V24] | LGL-V24 #8435b3 | 境界値 | accept() | ✅ |
| 47 | 両方チェックして accept を呼び送信が UnknownFailure で失敗した場合、phase が required でチェックは true のまま message が sendFailed になる [LGL-V25] | LGL-V25 #322110 | 異常系 | accept() | ✅ |
| 48 | 1回目の送信が UnknownFailure で2回目が accepted の状態で accept を2回呼んだ場合、2回目の後は phase が idle で message が null になり送信は合計2回になる [LGL-V26] | LGL-V26 #b2a2c6 | 正常系 | accept() | ✅ |
| 49 | 現行の termsVersion が変わって accept を呼び送信が outdated を返した場合、判定し直した結果で表示し直し、チェックが外れて message が outdated になる [LGL-V27] | LGL-V27 #d1c26c | 正常系 | accept() | ✅ |
| 50 | 現行の termsVersion が変わって1回目の送信が outdated を返した後に再度チェックして accept を呼び accepted が返った場合、phase が idle で2回目は新しい版数で送信される [LGL-V28] | LGL-V28 #8956b2 | 正常系 | accept() | ✅ |
| 51 | 両方チェックして accept を呼び送信が NetworkFailure で失敗した場合、phase が networkError になる [LGL-V29] | LGL-V29 #fda919 | 異常系 | accept() | ✅ |
| 52 | 両方チェックして accept を呼び送信が AuthFailure で失敗した場合、phase が networkError になる [LGL-V30] | LGL-V30 #bd315f | 異常系 | accept() | ✅ |
| 53 | termsChecked だけが true の状態で accept を呼んだ場合、送信は0回で phase は required のままになる [LGL-V32] | LGL-V32 #549b82 | 境界値 | accept() | ✅ |
| 54 | 送信の応答を待っている間に check を呼んだ場合、phase は sending のままで fetchLegalConfig は合計1回、送信は1回になる [LGL-V38] | LGL-V38 #596114 | 境界値 | accept() | ✅ |
| 55 | 送信の応答を待っている間に他の端末での退会の phase が notifying に変わった場合、phase が idle になる [LGL-V39] | LGL-V39 #b65f91 | 正常系 | accept() | ✅ |
| 56 | 送信の応答を待っている間にログイン中の uid が null に変わり送信が NetworkFailure で失敗した場合、phase が idle のままで SignOutUseCase は呼ばれない [LGL-V40] | LGL-V40 #d40cea | 異常系 | accept() | ✅ |
| 57 | 送信の応答を待っている間にログイン中の uid が null に変わり送信が accepted を返した場合、phase が idle のままで表示対象にならない [LGL-V41] | LGL-V41 #7c3cf2 | 異常系 | accept() | ✅ |
| 58 | プライバシーポリシーだけが表示対象で privacyChecked が true の状態で accept を呼び accepted が返った場合、phase が idle で利用規約 null とプライバシーポリシーの版数で送信される [LGL-V50] | LGL-V50 #957661 | 正常系 | accept() | ✅ |
| 59 | 現行の privacyVersion が変わって accept を呼び送信が outdated を返した場合、判定し直した結果で表示し直し、チェックが外れて message が outdated になる [LGL-V51] | LGL-V51 #5d10aa | 正常系 | accept() | ✅ |
| 60 | 現行の privacyVersion が変わって1回目の送信が outdated を返した後に再度チェックして accept を呼び accepted が返った場合、phase が idle で2回目は新しい版数で送信される [LGL-V52] | LGL-V52 #ad1c61 | 正常系 | accept() | ✅ |
| 61 | privacyChecked だけが true の状態で accept を呼んだ場合、送信は0回で phase は required のままになる [LGL-V53] | LGL-V53 #f5dd4e | 境界値 | accept() | ✅ |
| 62 | 送信が outdated を返し続く判定し直しが NetworkFailure を返した場合、phase が idle になる [LGL-V54] | LGL-V54 #957db0 | 異常系 | accept() | ✅ |
| 63 | 送信が outdated を返し続く判定し直しで同意済みの版数が現行の版数と一致していた場合、phase が idle で message が null になる [LGL-V55] | LGL-V55 #2c248d | 正常系 | accept() | ✅ |
| 64 | 利用規約だけが表示対象で現行の privacyVersion が変わり送信が outdated を返した場合、両方が表示対象になりチェックが外れる [LGL-V56] | LGL-V56 #b5e66d | 正常系 | accept() | ✅ |
| 65 | 現行の termsVersion と termsUrl が変わり送信が outdated を返した場合、config.termsUrl が新しい URL になる [LGL-V57] | LGL-V57 #b12fc9 | 正常系 | accept() | ✅ |
| 66 | 1回目の送信が UnknownFailure で失敗した後にもう一度 accept を呼び応答を待っている場合、phase が sending で message が null になる [LGL-V58] | LGL-V58 #d45397 | 正常系 | accept() | ✅ |
| 67 | 送信が outdated を返し続く判定し直しが UnknownFailure を返した場合、phase が idle になる [LGL-V60] | LGL-V60 #bdcfee | 異常系 | accept() | ✅ |
| 68 | phase が signingOut の状態で accept を呼んだ場合、送信は0回で phase は signingOut のままになる [LGL-V70] | LGL-V70 #a91438 | 境界値 | accept() | ✅ |
| 69 | message が signOutFailed で両方チェックして accept を呼び応答を待っている場合、message が null になる [LGL-V76] | LGL-V76 #381e7c | 正常系 | accept() | ✅ |
| 70 | message が outdated で両方チェックして accept を呼び応答を待っている場合、message が null になる [LGL-V79] | LGL-V79 #87953e | 正常系 | accept() | ✅ |
| 71 | 送信が outdated を返し続く判定し直しで `app_config/legal` が無かった場合、phase が required でチェックが外れ message が outdated になり config は既定値になる [LGL-V84] | LGL-V84 #3ea1a3 | 正常系 | accept() | ✅ |
| 72 | phase が required の状態で signOut を呼びログアウトの応答を待っている場合、phase が signingOut になる [LGL-V63] | LGL-V63 #83931c | 正常系 | signOut() | ✅ |
| 73 | phase が required の状態で signOut を呼びログアウトが成功した場合、SignOutUseCase が1回呼ばれ送信は0回になる [LGL-V64] | LGL-V64 #5278c6 | 正常系 | signOut() | ✅ |
| 74 | termsChecked が true の required の状態で signOut を呼びログアウトが UnknownFailure で失敗した場合、phase が required で termsChecked は true のまま message が signOutFailed になる [LGL-V65] | LGL-V65 #689dcb | 異常系 | signOut() | ✅ |
| 75 | phase が sending の状態で signOut を呼んだ場合、SignOutUseCase は呼ばれず phase は sending のままになる [LGL-V66] | LGL-V66 #b7b55b | 境界値 | signOut() | ✅ |
| 76 | ログアウトの応答を待っている間にもう一度 signOut を呼んだ場合、SignOutUseCase は1回だけ呼ばれる [LGL-V68] | LGL-V68 #2d7c62 | 境界値 | signOut() | ✅ |
| 77 | message が sendFailed の required の状態で signOut を呼び応答を待っている場合、message が null になる [LGL-V69] | LGL-V69 #87ac78 | 正常系 | signOut() | ✅ |
| 78 | signingOut の間に他の端末での退会の phase が notifying に変わりその後ログアウトが UnknownFailure を返した場合、phase が idle で message は null のままになる [LGL-V71] | LGL-V71 #2738c0 | 異常系 | signOut() | ✅ |
| 79 | signingOut の間にログイン中の uid が null に変わりその後ログアウトが UnknownFailure を返した場合、phase が idle で message は null のままになる [LGL-V73] | LGL-V73 #abc24f | 異常系 | signOut() | ✅ |
| 80 | message が signOutFailed の required の状態で signOut を呼び応答を待っている場合、message が null になる [LGL-V77] | LGL-V77 #bfeb49 | 正常系 | signOut() | ✅ |
| 81 | message が outdated の required の状態で signOut を呼び応答を待っている場合、message が null になる [LGL-V78] | LGL-V78 #6cea2c | 正常系 | signOut() | ✅ |
| 82 | phase が required の状態で signOut を呼びログアウトが NetworkFailure で失敗した場合、phase が required で message が signOutFailed になる [LGL-V80] | LGL-V80 #d8a0b6 | 異常系 | signOut() | ✅ |
| 83 | phase が required の状態で signOut を呼びログアウトが AuthFailure で失敗した場合、phase が required で message が signOutFailed になる [LGL-V81] | LGL-V81 #baabac | 異常系 | signOut() | ✅ |
| 84 | phase が networkError でログアウトが成功する状態で acknowledgeNetworkError を呼んだ場合、SignOutUseCase が1回呼ばれ phase が idle になる [LGL-V31] | LGL-V31 #1756bf | 正常系 | acknowledgeNetworkError() | ✅ |
| 85 | ログアウトの応答を待っている間にもう一度 acknowledgeNetworkError を呼んだ場合、SignOutUseCase は1回だけ呼ばれる [LGL-V42] | LGL-V42 #1105ef | 境界値 | acknowledgeNetworkError() | ✅ |
| 86 | phase が required の状態で acknowledgeNetworkError を呼んだ場合、SignOutUseCase は呼ばれず phase は required のままになる [LGL-V43] | LGL-V43 #98a856 | 境界値 | acknowledgeNetworkError() | ✅ |
| 87 | phase が networkError でログアウトが UnknownFailure で失敗し判定し直しで未同意と分かる場合、SignOutUseCase が1回呼ばれ phase が required でチェックと message は初期値になる [LGL-V45] | LGL-V45 #35ddd7 | 異常系 | acknowledgeNetworkError() | ✅ |
| 88 | phase が networkError の状態で他の端末での退会の phase が notifying に変わった場合、phase が idle になり SignOutUseCase は呼ばれない [LGL-V67] | LGL-V67 #991a71 | 異常系 | acknowledgeNetworkError() | ✅ |

## テストケース詳細

### テストケース1: 未同意の状態で check を呼んだ場合、phase が required で両方の行が表示対象になり、チェックと message は初期値のままになる [LGL-V01]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsRequired` と `privacyRequired` は true、`termsChecked` と `privacyChecked` は false、`message` は null

### テストケース2: 利用規約が最新でプライバシーポリシーが古い状態で check を呼んだ場合、プライバシーポリシーだけが表示対象になる [LGL-V02]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2025-06-01` の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsRequired` は false、`privacyRequired` は true

### テストケース3: 利用規約が古くプライバシーポリシーが最新の状態で check を呼んだ場合、利用規約だけが表示対象になる [LGL-V03]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2025-06-01`・プライバシーポリシー `2026-01-01` の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsRequired` は true、`privacyRequired` は false

### テストケース4: 両方とも現行の版数に同意済みの状態で check を呼んだ場合、phase が idle のままで表示対象にならない [LGL-V04]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`termsRequired` と `privacyRequired` は false

### テストケース5: 判定が NetworkFailure を返す状態で check を呼んだ場合、phase が idle のままで表示対象にならない [LGL-V05]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 判定が `NetworkFailure` を返す状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`termsRequired` と `privacyRequired` は false

### テストケース6: 1回目の判定が NetworkFailure で2回目が成功する状態で check を2回呼んだ場合、1回目の後は idle で2回目の後は required になる [LGL-V06]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で、1回目の判定が `NetworkFailure`、2回目の判定が成功する状態で、`check` を2回呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: 1回目の後の `phase` は `idle`、2回目の後の `phase` は `required`、`termsRequired` と `privacyRequired` は true

### テストケース7: 判定が UnknownFailure を返す状態で check を呼んだ場合、phase が idle のままで表示対象にならない [LGL-V07]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 判定が `UnknownFailure` を返す状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`termsRequired` と `privacyRequired` は false

### テストケース8: ログインしていない状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V09]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: ログインしていない状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`fetchLegalConfig` と `fetchConsents` は0回

### テストケース9: uid A の退会処理の記録が requested の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V10]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: uid `A` の退会処理の記録が `requested` の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`fetchLegalConfig` と `fetchConsents` は0回

### テストケース10: 他の端末での退会の phase が notifying の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V11]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 他の端末での退会の `phase` が `notifying` の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`fetchLegalConfig` と `fetchConsents` は0回

### テストケース11: phase が required の後に他の端末での退会の phase が notifying に変わった場合、phase が idle になる [LGL-V12]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意の状態で `check` を呼んで `phase` が `required` になった後、他の端末での退会の `phase` が `notifying` に変わった
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`

### テストケース12: uid A に強制ログアウトの記録がある状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V13]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: Firebase 上は uid `A` でログイン中だが、uid `A` に強制ログアウトの記録がある状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`fetchLegalConfig` と `fetchConsents` は0回

### テストケース13: phase が required で利用規約をチェックした後にもう一度 check を呼んだ場合、required と termsChecked が保たれ fetchLegalConfig は合計1回になる [LGL-V14]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意の状態で `check` を呼んで `phase` が `required` になり、`setTermsChecked(true)` を呼んだ後、もう一度 `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsChecked` は true のまま。`fetchLegalConfig` は合計1回

### テストケース14: uid A の退会処理の記録が serverDone の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V33]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: uid `A` の退会処理の記録が `serverDone` の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`fetchLegalConfig` と `fetchConsents` は0回

### テストケース15: 判定の応答を待っている間にログイン中の uid が null に変わり同意が必要という結果が返った場合、phase が idle のままで表示対象にならない [LGL-V34]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `check` を呼び、判定の応答を待っている間にログイン中の uid が null に変わり、その後に判定が同意が必要という結果を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`termsRequired` と `privacyRequired` は false

### テストケース16: 判定の応答を待っている間に他の端末での退会の phase が notifying に変わり同意が必要という結果が返った場合、phase が idle のままで表示対象にならない [LGL-V35]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `check` を呼び、判定の応答を待っている間に他の端末での退会の `phase` が `notifying` に変わり、その後に判定が同意が必要という結果を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`termsRequired` と `privacyRequired` は false

### テストケース17: 判定の応答を待っている間に退会処理の記録が requested になり同意が必要という結果が返った場合、phase が idle のままで表示対象にならない [LGL-V36]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `check` を呼び、判定の応答を待っている間に uid `A` の退会処理の記録が `requested` になり、その後に判定が同意が必要という結果を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`termsRequired` と `privacyRequired` は false

### テストケース18: 判定の応答を待っている間にもう一度 check を呼んだ場合、fetchLegalConfig は合計1回で phase が required になる [LGL-V37]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `check` を呼び、判定の応答を待っている間にもう一度 `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `fetchLegalConfig` は合計1回。`phase` は `required`

### テストケース19: phase が networkError の状態で check を呼んだ場合、phase が networkError のままで fetchLegalConfig の呼び出し回数が増えない [LGL-V44]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `phase` が `networkError` の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `networkError` のまま。`check` を呼ぶ前後で `fetchLegalConfig` の呼び出し回数が増えない

### テストケース20: 他の端末での退会の phase が confirming の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない [LGL-V62]
- **カテゴリ**: 異常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 他の端末での退会の `phase` が `confirming`（データの削除ダイアログを表示している）の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`fetchLegalConfig` と `fetchConsents` は0回

### テストケース21: phase が signingOut の状態で check を呼んだ場合、phase が signingOut のままで fetchLegalConfig の呼び出し回数が増えない [LGL-V72]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `signingOut` の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `signingOut` のまま。`check` を呼ぶ前後で `fetchLegalConfig` の呼び出し回数が増えない

### テストケース22: `app_config/legal` が無く未同意の状態で check を呼んだ場合、phase が required で両方の行が表示対象になり config は既定値になる [LGL-V82]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `app_config/legal` が無く（`fetchLegalConfig` が `NotFoundFailure`）、未同意の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsRequired` と `privacyRequired` は true、`config` は既定値（`2026-10-12`・`2026-10-12`・`https://word-stock-web.web.app/terms`・`https://word-stock-web.web.app/privacy`）

### テストケース23: `app_config/legal` が無く既定値と同じ版数に同意済みの状態で check を呼んだ場合、phase が idle のままになる [LGL-V83]
- **カテゴリ**: 正常系
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `app_config/legal` が無く、同意済みの版数が利用規約 `2026-10-12`・プライバシーポリシー `2026-10-12` の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`

### テストケース24: 初回の同期の間にログイン中の uid が A で check を呼んだ場合、phase が idle のままで fetchLegalConfig は呼ばれない [LGL-V87]
- **カテゴリ**: 境界値
- **対象メソッド**: check()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: ログイン中の uid が `A`（未同意）で、`authSyncInProgressProvider` が true の状態で `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`fetchLegalConfig` は0回

### テストケース25: start の後にログイン中の uid が null から A に変わった場合、fetchLegalConfig が1回呼ばれ phase が required になる [LGL-V15]
- **カテゴリ**: 正常系
- **対象メソッド**: build()（uid の変化）
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: ログイン中の uid が null の状態から `A` に変わった（uid `A` は未同意）
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `fetchLegalConfig` が1回呼ばれ、`phase` は `required`

### テストケース26: phase が required で termsChecked が true の状態でログイン中の uid が null に変わった場合、State が初期値に戻る [LGL-V16]
- **カテゴリ**: 正常系
- **対象メソッド**: build()（uid の変化）
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `phase` が `required` で `termsChecked` が true の状態で、ログイン中の uid が null に変わった
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`termsRequired`・`privacyRequired`・`termsChecked`・`privacyChecked` はすべて false、`config` と `message` は null

### テストケース27: phase が required で termsChecked が true の状態でログイン中の uid が A から B に変わった場合、B で判定し直し、チェックと message が初期値の required になる [LGL-V46]
- **カテゴリ**: 正常系
- **対象メソッド**: build()（uid の変化）
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `required`、`termsChecked` が true の状態で、ログイン中の uid が `A` から `B` に変わった（uid `B` も未同意）
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `fetchConsents` が `'B'` を引数に1回呼ばれる。`phase` は `required`、`termsChecked` と `privacyChecked` は false、`message` は null

### テストケース28: start の後にログイン中の uid が null から A に変わり A が現行の版数に同意済みの場合、phase が idle のままになる [LGL-V47]
- **カテゴリ**: 正常系
- **対象メソッド**: build()（uid の変化）
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: ログイン中の uid が null の状態から `A` に変わった（uid `A` の同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01`）
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`

### テストケース29: 初回の同期の間にログイン中の uid が null から A に変わった場合、phase が idle のままで fetchLegalConfig は呼ばれない [LGL-V85]
- **カテゴリ**: 境界値
- **対象メソッド**: build()（uid の変化）
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `start` の後、初回の同期の間（`authSyncInProgressProvider` が true）にログイン中の uid が null から `A`（未同意）に変わった
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`fetchLegalConfig` は0回

### テストケース30: 初回の同期の間に uid が null から A に変わった後で同期が終わった場合、fetchLegalConfig が1回呼ばれ phase が required になる [LGL-V86]
- **カテゴリ**: 正常系
- **対象メソッド**: build()（uid の変化）
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 初回の同期の間に uid が null から `A`（未同意）に変わった後、`authSyncInProgressProvider` が false に変わった
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `fetchLegalConfig` が1回呼ばれ、`phase` は `required`

### テストケース31: 初回の同期の間に uid が null から A に変わり同期の終わる前に null に戻ってから同期が終わった場合、phase が idle のままで fetchLegalConfig は呼ばれない [LGL-V89]
- **カテゴリ**: 境界値
- **対象メソッド**: build()（uid の変化）
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 初回の同期の間に uid が null から `A` に変わり、同期の終わる前に null に戻ってから、`authSyncInProgressProvider` が false に変わった
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`fetchLegalConfig` は0回

### テストケース32: phase が required の状態で初回の同期の終了（true から false）を受けた場合、phase が required のままで fetchLegalConfig の呼び出し回数が増えない [LGL-V90]
- **カテゴリ**: 境界値
- **対象メソッド**: build()（uid の変化）
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `phase` が `required` の状態で、`authSyncInProgressProvider` が true から false に変わった
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required` のまま。`fetchLegalConfig` の呼び出し回数は増えない

### テストケース33: 初回の同期の間に uid が null から A に変わり同期が失敗して終わった場合、fetchLegalConfig が1回呼ばれ phase が required になる [LGL-V91]
- **カテゴリ**: 異常系
- **対象メソッド**: build()（uid の変化）
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 初回の同期の間に uid が null から `A`（未同意）に変わり、同期が失敗して `authSyncInProgressProvider` が false に変わった
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `fetchLegalConfig` が1回呼ばれ、`phase` は `required`

### テストケース34: phase が required の状態で setTermsChecked(true) を呼んだ場合、termsChecked だけが true になる [LGL-V17]
- **カテゴリ**: 正常系
- **対象メソッド**: setTermsChecked() / setPrivacyChecked()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `required` の状態で `setTermsChecked(true)` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `termsChecked` は true、`privacyChecked` は false

### テストケース35: phase が required の状態で setTermsChecked(true) と setPrivacyChecked(true) を呼んだ場合、両方が true になる [LGL-V18]
- **カテゴリ**: 正常系
- **対象メソッド**: setTermsChecked() / setPrivacyChecked()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `required` の状態で `setTermsChecked(true)` と `setPrivacyChecked(true)` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `termsChecked` と `privacyChecked` は true

### テストケース36: 両方チェックした状態で setTermsChecked(false) を呼んだ場合、termsChecked が false で privacyChecked は true のままになる [LGL-V19]
- **カテゴリ**: 正常系
- **対象メソッド**: setTermsChecked() / setPrivacyChecked()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `setTermsChecked(false)` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `termsChecked` は false、`privacyChecked` は true

### テストケース37: プライバシーポリシーだけが表示対象の required の状態で setPrivacyChecked(true) を呼んだ場合、privacyChecked が true になる [LGL-V20]
- **カテゴリ**: 正常系
- **対象メソッド**: setTermsChecked() / setPrivacyChecked()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2025-06-01` で `phase` が `required` の状態で `setPrivacyChecked(true)` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `privacyChecked` は true

### テストケース38: phase が required の状態で setPrivacyChecked(true) を呼んだ場合、privacyChecked だけが true になる [LGL-V48]
- **カテゴリ**: 正常系
- **対象メソッド**: setTermsChecked() / setPrivacyChecked()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `required` の状態で `setPrivacyChecked(true)` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `privacyChecked` は true、`termsChecked` は false

### テストケース39: 両方チェックした状態で setPrivacyChecked(false) を呼んだ場合、privacyChecked が false で termsChecked は true のままになる [LGL-V49]
- **カテゴリ**: 正常系
- **対象メソッド**: setTermsChecked() / setPrivacyChecked()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `setPrivacyChecked(false)` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `privacyChecked` は false、`termsChecked` は true

### テストケース40: message が outdated の required の状態で setTermsChecked(true) を呼んだ場合、termsChecked が true で message は outdated のままになる [LGL-V59]
- **カテゴリ**: 正常系
- **対象メソッド**: setTermsChecked() / setPrivacyChecked()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `message` が `outdated`、`phase` が `required` の状態で `setTermsChecked(true)` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `termsChecked` は true、`message` は `outdated` のまま

### テストケース41: message が signOutFailed の required の状態で setPrivacyChecked(true) を呼んだ場合、message は signOutFailed のままになる [LGL-V74]
- **カテゴリ**: 正常系
- **対象メソッド**: setTermsChecked() / setPrivacyChecked()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `message` が `signOutFailed`、`phase` が `required` の状態で `setPrivacyChecked(true)` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `message` は `signOutFailed` のまま

### テストケース42: message が sendFailed の required の状態で setTermsChecked(false) を呼んだ場合、message は sendFailed のままになる [LGL-V75]
- **カテゴリ**: 正常系
- **対象メソッド**: setTermsChecked() / setPrivacyChecked()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `message` が `sendFailed`、`phase` が `required` の状態で `setTermsChecked(false)` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `message` は `sendFailed` のまま

### テストケース43: 両方チェックして accept を呼び送信が accepted を返した場合、phase が idle で message が null になり、現行の版数2つで送信が1回呼ばれる [LGL-V21]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信が `accepted` を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`message` は null。送信が1回、利用規約 `2026-01-01`・プライバシーポリシー `2026-01-01` を引数に呼ばれる

### テストケース44: 利用規約だけが表示対象で termsChecked が true の状態で accept を呼び accepted が返った場合、phase が idle で利用規約の版数とプライバシーポリシー null で送信される [LGL-V22]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2025-06-01`・プライバシーポリシー `2026-01-01` で `termsChecked` が true の状態で `accept` を呼び、送信が `accepted` を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。送信が1回、利用規約 `2026-01-01`・プライバシーポリシー null を引数に呼ばれる

### テストケース45: 両方チェックして accept を呼び送信の応答を待っている場合、phase が sending になる [LGL-V23]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信の応答を待っている
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `sending`

### テストケース46: 送信の応答を待っている間にもう一度 accept を呼んだ場合、送信は1回だけ呼ばれる [LGL-V24]
- **カテゴリ**: 境界値
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信の応答を待っている間にもう一度 `accept` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: 送信は1回だけ呼ばれる

### テストケース47: 両方チェックして accept を呼び送信が UnknownFailure で失敗した場合、phase が required でチェックは true のまま message が sendFailed になる [LGL-V25]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信が `UnknownFailure` で失敗した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsChecked` と `privacyChecked` は true、`message` は `sendFailed`

### テストケース48: 1回目の送信が UnknownFailure で2回目が accepted の状態で accept を2回呼んだ場合、2回目の後は phase が idle で message が null になり送信は合計2回になる [LGL-V26]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で、1回目の送信が `UnknownFailure`、2回目の送信が `accepted` を返すようにして `accept` を2回呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: 2回目の後の `phase` は `idle`、`message` は null。送信は合計2回

### テストケース49: 現行の termsVersion が変わって accept を呼び送信が outdated を返した場合、判定し直した結果で表示し直し、チェックが外れて message が outdated になる [LGL-V27]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で、現行の `termsVersion` を `2026-02-01` に変えて `accept` を呼び、送信が `outdated` を返した（判定し直しは成功する）
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsRequired` と `privacyRequired` は true、`termsChecked` と `privacyChecked` は false、`message` は `outdated`、`config.termsVersion` は `2026-02-01`。`fetchLegalConfig` は合計2回

### テストケース50: 現行の termsVersion が変わって1回目の送信が outdated を返した後に再度チェックして accept を呼び accepted が返った場合、phase が idle で2回目は新しい版数で送信される [LGL-V28]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で、現行の `termsVersion` を `2026-02-01` に変えて `accept` を呼び、1回目の送信が `outdated` を返した後、`setTermsChecked(true)` と `setPrivacyChecked(true)` を呼んで `accept` を呼び、2回目の送信が `accepted` を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。2回目の送信の引数は利用規約 `2026-02-01`・プライバシーポリシー `2026-01-01`

### テストケース51: 両方チェックして accept を呼び送信が NetworkFailure で失敗した場合、phase が networkError になる [LGL-V29]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信が `NetworkFailure` で失敗した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `networkError`

### テストケース52: 両方チェックして accept を呼び送信が AuthFailure で失敗した場合、phase が networkError になる [LGL-V30]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信が `AuthFailure` で失敗した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `networkError`

### テストケース53: termsChecked だけが true の状態で accept を呼んだ場合、送信は0回で phase は required のままになる [LGL-V32]
- **カテゴリ**: 境界値
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` が true、`privacyChecked` が false の状態で `accept` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: 送信は0回。`phase` は `required`

### テストケース54: 送信の応答を待っている間に check を呼んだ場合、phase は sending のままで fetchLegalConfig は合計1回、送信は1回になる [LGL-V38]
- **カテゴリ**: 境界値
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信の応答を待っている間に `check` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `sending` のまま。`fetchLegalConfig` は合計1回、送信は1回

### テストケース55: 送信の応答を待っている間に他の端末での退会の phase が notifying に変わった場合、phase が idle になる [LGL-V39]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信の応答を待っている間に他の端末での退会の `phase` が `notifying` に変わった
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`

### テストケース56: 送信の応答を待っている間にログイン中の uid が null に変わり送信が NetworkFailure で失敗した場合、phase が idle のままで SignOutUseCase は呼ばれない [LGL-V40]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信の応答を待っている間にログイン中の uid が null に変わり、その後に送信が `NetworkFailure` で失敗した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`SignOutUseCase` は0回

### テストケース57: 送信の応答を待っている間にログイン中の uid が null に変わり送信が accepted を返した場合、phase が idle のままで表示対象にならない [LGL-V41]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信の応答を待っている間にログイン中の uid が null に変わり、その後に送信が `accepted` を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`termsRequired` と `privacyRequired` は false

### テストケース58: プライバシーポリシーだけが表示対象で privacyChecked が true の状態で accept を呼び accepted が返った場合、phase が idle で利用規約 null とプライバシーポリシーの版数で送信される [LGL-V50]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2026-01-01`・プライバシーポリシー `2025-06-01` で `privacyChecked` が true の状態で `accept` を呼び、送信が `accepted` を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。送信が1回、利用規約 null・プライバシーポリシー `2026-01-01` を引数に呼ばれる

### テストケース59: 現行の privacyVersion が変わって accept を呼び送信が outdated を返した場合、判定し直した結果で表示し直し、チェックが外れて message が outdated になる [LGL-V51]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で、現行の `privacyVersion` を `2026-02-01` に変えて `accept` を呼び、送信が `outdated` を返した（判定し直しは成功する）
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsRequired` と `privacyRequired` は true、`termsChecked` と `privacyChecked` は false、`message` は `outdated`、`config.privacyVersion` は `2026-02-01`

### テストケース60: 現行の privacyVersion が変わって1回目の送信が outdated を返した後に再度チェックして accept を呼び accepted が返った場合、phase が idle で2回目は新しい版数で送信される [LGL-V52]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で、現行の `privacyVersion` を `2026-02-01` に変えて `accept` を呼び、1回目の送信が `outdated` を返した後、`setTermsChecked(true)` と `setPrivacyChecked(true)` を呼んで `accept` を呼び、2回目の送信が `accepted` を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。2回目の送信の引数は利用規約 `2026-01-01`・プライバシーポリシー `2026-02-01`

### テストケース61: privacyChecked だけが true の状態で accept を呼んだ場合、送信は0回で phase は required のままになる [LGL-V53]
- **カテゴリ**: 境界値
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` が false、`privacyChecked` が true の状態で `accept` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: 送信は0回。`phase` は `required`

### テストケース62: 送信が outdated を返し続く判定し直しが NetworkFailure を返した場合、phase が idle になる [LGL-V54]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信が `outdated` を返し、続く判定し直しが `NetworkFailure` を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`

### テストケース63: 送信が outdated を返し続く判定し直しで同意済みの版数が現行の版数と一致していた場合、phase が idle で message が null になる [LGL-V55]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信が `outdated` を返し、続く判定し直しで同意済みの版数が現行の版数と一致していた
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`message` は null

### テストケース64: 利用規約だけが表示対象で現行の privacyVersion が変わり送信が outdated を返した場合、両方が表示対象になりチェックが外れる [LGL-V56]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 同意済みの版数が利用規約 `2025-06-01`・プライバシーポリシー `2026-01-01` で `termsChecked` が true の状態で、現行の `privacyVersion` を `2026-02-01` に変えて `accept` を呼び、送信が `outdated` を返した（判定し直しは成功する）
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsRequired` と `privacyRequired` は true、`termsChecked` と `privacyChecked` は false

### テストケース65: 現行の termsVersion と termsUrl が変わり送信が outdated を返した場合、config.termsUrl が新しい URL になる [LGL-V57]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で、現行の `termsVersion` を `2026-02-01`、`termsUrl` を `https://example.com/terms-v2` に変えて `accept` を呼び、送信が `outdated` を返した（判定し直しは成功する）
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `config.termsUrl` は `https://example.com/terms-v2`

### テストケース66: 1回目の送信が UnknownFailure で失敗した後にもう一度 accept を呼び応答を待っている場合、phase が sending で message が null になる [LGL-V58]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で、1回目の送信が `UnknownFailure` で失敗して `message` が `sendFailed` になった後、もう一度 `accept` を呼び、2回目の送信の応答を待っている
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `sending`、`message` は null

### テストケース67: 送信が outdated を返し続く判定し直しが UnknownFailure を返した場合、phase が idle になる [LGL-V60]
- **カテゴリ**: 異常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信が `outdated` を返し、続く判定し直しが `UnknownFailure` を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`

### テストケース68: phase が signingOut の状態で accept を呼んだ場合、送信は0回で phase は signingOut のままになる [LGL-V70]
- **カテゴリ**: 境界値
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true、`phase` が `signingOut` の状態で `accept` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: 送信は0回。`phase` は `signingOut` のまま

### テストケース69: message が signOutFailed で両方チェックして accept を呼び応答を待っている場合、message が null になる [LGL-V76]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `message` が `signOutFailed`、`termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信の応答を待っている
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `message` は null

### テストケース70: message が outdated で両方チェックして accept を呼び応答を待っている場合、message が null になる [LGL-V79]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `message` が `outdated`、`termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信の応答を待っている
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `message` は null

### テストケース71: 送信が outdated を返し続く判定し直しで `app_config/legal` が無かった場合、phase が required でチェックが外れ message が outdated になり config は既定値になる [LGL-V84]
- **カテゴリ**: 正常系
- **対象メソッド**: accept()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` と `privacyChecked` が true の状態で `accept` を呼び、送信が `outdated` を返し、続く判定し直しで `app_config/legal` が無かった
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsChecked` と `privacyChecked` は false、`message` は `outdated`、`config.termsVersion` は `2026-10-12`

### テストケース72: phase が required の状態で signOut を呼びログアウトの応答を待っている場合、phase が signingOut になる [LGL-V63]
- **カテゴリ**: 正常系
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `required` の状態で `signOut` を呼び、ログアウトの応答を待っている
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `signingOut`

### テストケース73: phase が required の状態で signOut を呼びログアウトが成功した場合、SignOutUseCase が1回呼ばれ送信は0回になる [LGL-V64]
- **カテゴリ**: 正常系
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `required` の状態で `signOut` を呼び、ログアウトが成功した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `SignOutUseCase` が1回呼ばれる。送信は0回

### テストケース74: termsChecked が true の required の状態で signOut を呼びログアウトが UnknownFailure で失敗した場合、phase が required で termsChecked は true のまま message が signOutFailed になる [LGL-V65]
- **カテゴリ**: 異常系
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `termsChecked` が true、`phase` が `required` の状態で `signOut` を呼び、ログアウトが `UnknownFailure` で失敗した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`termsChecked` は true、`message` は `signOutFailed`

### テストケース75: phase が sending の状態で signOut を呼んだ場合、SignOutUseCase は呼ばれず phase は sending のままになる [LGL-V66]
- **カテゴリ**: 境界値
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `sending` の状態で `signOut` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `SignOutUseCase` は0回。`phase` は `sending` のまま

### テストケース76: ログアウトの応答を待っている間にもう一度 signOut を呼んだ場合、SignOutUseCase は1回だけ呼ばれる [LGL-V68]
- **カテゴリ**: 境界値
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `required` の状態で `signOut` を呼び、ログアウトの応答を待っている間にもう一度 `signOut` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `SignOutUseCase` は1回だけ呼ばれる

### テストケース77: message が sendFailed の required の状態で signOut を呼び応答を待っている場合、message が null になる [LGL-V69]
- **カテゴリ**: 正常系
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `message` が `sendFailed`、`phase` が `required` の状態で `signOut` を呼び、ログアウトの応答を待っている
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `message` は null

### テストケース78: signingOut の間に他の端末での退会の phase が notifying に変わりその後ログアウトが UnknownFailure を返した場合、phase が idle で message は null のままになる [LGL-V71]
- **カテゴリ**: 異常系
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `signingOut` の状態で、他の端末での退会の `phase` が `notifying` に変わり、その後にログアウトが `UnknownFailure` を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`message` は null

### テストケース79: signingOut の間にログイン中の uid が null に変わりその後ログアウトが UnknownFailure を返した場合、phase が idle で message は null のままになる [LGL-V73]
- **カテゴリ**: 異常系
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `signingOut` の状態で、ログイン中の uid が null に変わり、その後にログアウトが `UnknownFailure` を返した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`、`message` は null

### テストケース80: message が signOutFailed の required の状態で signOut を呼び応答を待っている場合、message が null になる [LGL-V77]
- **カテゴリ**: 正常系
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `message` が `signOutFailed`、`phase` が `required` の状態で `signOut` を呼び、ログアウトの応答を待っている
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `message` は null

### テストケース81: message が outdated の required の状態で signOut を呼び応答を待っている場合、message が null になる [LGL-V78]
- **カテゴリ**: 正常系
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `message` が `outdated`、`phase` が `required` の状態で `signOut` を呼び、ログアウトの応答を待っている
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `message` は null

### テストケース82: phase が required の状態で signOut を呼びログアウトが NetworkFailure で失敗した場合、phase が required で message が signOutFailed になる [LGL-V80]
- **カテゴリ**: 異常系
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `required` の状態で `signOut` を呼び、ログアウトが `NetworkFailure` で失敗した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`message` は `signOutFailed`

### テストケース83: phase が required の状態で signOut を呼びログアウトが AuthFailure で失敗した場合、phase が required で message が signOutFailed になる [LGL-V81]
- **カテゴリ**: 異常系
- **対象メソッド**: signOut()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: 未同意で `phase` が `required` の状態で `signOut` を呼び、ログアウトが `AuthFailure` で失敗した
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `required`、`message` は `signOutFailed`

### テストケース84: phase が networkError でログアウトが成功する状態で acknowledgeNetworkError を呼んだ場合、SignOutUseCase が1回呼ばれ phase が idle になる [LGL-V31]
- **カテゴリ**: 正常系
- **対象メソッド**: acknowledgeNetworkError()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `phase` が `networkError` で、ログアウトが成功する状態で `acknowledgeNetworkError` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `SignOutUseCase` が1回呼ばれる。`phase` は `idle`

### テストケース85: ログアウトの応答を待っている間にもう一度 acknowledgeNetworkError を呼んだ場合、SignOutUseCase は1回だけ呼ばれる [LGL-V42]
- **カテゴリ**: 境界値
- **対象メソッド**: acknowledgeNetworkError()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `phase` が `networkError` で、ログアウトの応答を待っている間にもう一度 `acknowledgeNetworkError` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `SignOutUseCase` は1回だけ呼ばれる

### テストケース86: phase が required の状態で acknowledgeNetworkError を呼んだ場合、SignOutUseCase は呼ばれず phase は required のままになる [LGL-V43]
- **カテゴリ**: 境界値
- **対象メソッド**: acknowledgeNetworkError()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `phase` が `required` の状態で `acknowledgeNetworkError` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `SignOutUseCase` は0回。`phase` は `required` のまま

### テストケース87: phase が networkError でログアウトが UnknownFailure で失敗し判定し直しで未同意と分かる場合、SignOutUseCase が1回呼ばれ phase が required でチェックと message は初期値になる [LGL-V45]
- **カテゴリ**: 異常系
- **対象メソッド**: acknowledgeNetworkError()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `phase` が `networkError` で、ログアウトが `UnknownFailure` で失敗し、判定し直しで未同意と分かる状態で `acknowledgeNetworkError` を呼んだ
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `SignOutUseCase` が1回呼ばれる。`phase` は `required`、`termsChecked` と `privacyChecked` は false、`message` は null

### テストケース88: phase が networkError の状態で他の端末での退会の phase が notifying に変わった場合、phase が idle になり SignOutUseCase は呼ばれない [LGL-V67]
- **カテゴリ**: 異常系
- **対象メソッド**: acknowledgeNetworkError()
- **事前条件**: オンライン、ログイン中の uid は A、現行の版数は 2026-01-01、退会処理の記録・退会済みの記録・強制ログアウトの記録は無く、他の端末での退会の phase は idle
- **入力値・テスト条件**: `phase` が `networkError` の状態で、他の端末での退会の `phase` が `notifying` に変わった
- **操作手順**: ProviderContainer に Fake を差し込み、上記条件どおりに ViewModel を操作する
- **期待結果**: `phase` は `idle`。`SignOutUseCase` は0回

## 対象外

- L203-204：依存の生成（Firebase の初期化など）に失敗したら判定しない防御的な catch。仕様書に記載なし（仕様書への追記候補）

## 検証の範囲（補足）

- LGL-V91：ViewModel が見るのは `authSyncInProgressProvider` が false に戻ることだけで、同期の成功・失敗を区別しない（仕様書3章冒頭の「初回の同期」の定義）。そのため操作は LGL-V86 と同じになる。同期が失敗しても判定が走ることを、ID として明示的に残すためのケース
