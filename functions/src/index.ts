import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
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
