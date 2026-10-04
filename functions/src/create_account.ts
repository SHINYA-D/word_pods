import { FieldValue, Firestore } from "firebase-admin/firestore";

/** Firestore の ALREADY_EXISTS（gRPC のステータスコード 6） */
const ALREADY_EXISTS = 6;

/**
 * 新規登録したユーザーの accounts/{uid} を開発者でない状態（isDeveloper: false）で作る。
 *
 * - 既にドキュメントがあれば何もしない（コンソールで true にした値を上書きしないため）
 * - 何度呼んでも同じ結果になる
 */
export async function createAccountDoc(uid: string, db: Firestore): Promise<void> {
  try {
    await db.doc(`accounts/${uid}`).create({
      isDeveloper: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    if ((e as { code?: number }).code !== ALREADY_EXISTS) throw e;
  }
}
