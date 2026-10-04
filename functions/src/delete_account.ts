import { Auth } from "firebase-admin/auth";
import { Firestore } from "firebase-admin/firestore";

/**
 * ユーザーの Firestore のデータ（users/{uid} 配下すべてと accounts/{uid}）と Authentication のユーザーを削除する。
 *
 * - Firestore → Authentication の順に削除する（Authentication を先に消すと、
 *   途中で止まったときの再試行で本人確認ができなくなるため）
 * - 何度呼んでも同じ結果になる。すでに消えているデータ・ユーザーは飛ばす
 * - 次の書き込みが遅れて届き、削除の途中でデータが作り直される場合に備えて、
 *   Authentication の削除後にもう一度 Firestore を削除する
 *   - アプリの同期の書き込み（時間切れ後に届いたもの）→ users/{uid}
 *   - 新規登録トリガー（登録直後に退会した場合）→ accounts/{uid}
 */
export async function deleteUserAccount(
  uid: string,
  db: Firestore,
  auth: Auth,
): Promise<void> {
  await deleteFirestoreData(uid, db);
  try {
    await auth.deleteUser(uid);
  } catch (e) {
    if ((e as { code?: string }).code !== "auth/user-not-found") throw e;
  }
  await deleteFirestoreData(uid, db);
}

async function deleteFirestoreData(uid: string, db: Firestore): Promise<void> {
  await db.recursiveDelete(db.doc(`users/${uid}`));
  await db.recursiveDelete(db.doc(`accounts/${uid}`));
}
