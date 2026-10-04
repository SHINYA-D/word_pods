import { Auth } from "firebase-admin/auth";
import { Firestore } from "firebase-admin/firestore";

/**
 * ユーザーの Firestore のデータ（users/{uid} 配下すべて）と Authentication のユーザーを削除する。
 *
 * - Firestore → Authentication の順に削除する（Authentication を先に消すと、
 *   途中で止まったときの再試行で本人確認ができなくなるため）
 * - 何度呼んでも同じ結果になる。すでに消えているデータ・ユーザーは飛ばす
 * - アプリの同期の書き込みが時間切れ後に遅れて届き、削除の途中でデータが作り直される場合に備えて、
 *   Authentication の削除後にもう一度 Firestore を削除する
 */
export async function deleteUserAccount(
  uid: string,
  db: Firestore,
  auth: Auth,
): Promise<void> {
  await db.recursiveDelete(db.doc(`users/${uid}`));
  try {
    await auth.deleteUser(uid);
  } catch (e) {
    if ((e as { code?: string }).code !== "auth/user-not-found") throw e;
  }
  await db.recursiveDelete(db.doc(`users/${uid}`));
}
