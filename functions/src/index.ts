import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import * as functionsV1 from "firebase-functions/v1";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { createAccountDoc } from "./create_account";
import { deleteUserAccount } from "./delete_account";

initializeApp();

/**
 * 退会。呼び出したユーザー本人（ログイン情報の uid）のデータとアカウントを削除する。
 * アプリ側のリージョン指定（lib/core/di/firebase_providers.dart）と合わせる。
 */
export const deleteAccount = onCall(
  { region: "asia-northeast1", timeoutSeconds: 300 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "ログインが必要です");
    }
    await deleteUserAccount(uid, getFirestore(), getAuth());
    return { ok: true };
  },
);

/**
 * 新規登録。Authentication にユーザーが作られたら accounts/{uid} を isDeveloper: false で作る。
 * メール登録・Google 登録のどちらでも動く。
 * v2 の beforeUserCreated は Identity Platform へのアップグレードが要るため、v1 のトリガーを使う。
 */
export const onAuthUserCreated = functionsV1
  .region("asia-northeast1")
  .auth.user()
  .onCreate(async (user) => {
    await createAccountDoc(user.uid, getFirestore());
  });
