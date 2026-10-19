import { DocumentData, FieldValue, Firestore, Timestamp, Transaction } from "firebase-admin/firestore";

/**
 * accounts/{uid} に必ず置くフィールドのうち、[current]（今のドキュメントの中身。無ければ undefined）に
 * 無いものだけを返す。
 *
 * - isDeveloper: 既定値 false。開発者かどうかに関わらず必ず置く
 * - createdAt: アカウントを作った時刻。[createdAt]（Authentication のユーザーの作成日時）があればそれ、
 *   無ければ書き込んだ時刻（サーバー時刻）
 * - すでにある値は返さない（コンソールで true にした isDeveloper を上書きしないため）
 */
export function missingAccountDefaults(
  current: DocumentData | undefined,
  createdAt?: Date,
): Record<string, unknown> {
  const patch: Record<string, unknown> = {};
  if (current?.isDeveloper === undefined) patch.isDeveloper = false;
  if (current?.createdAt === undefined) {
    patch.createdAt = createdAt ? Timestamp.fromDate(createdAt) : FieldValue.serverTimestamp();
  }
  return patch;
}

/** トランザクションの中で、accounts/{uid} に無いフィールド（isDeveloper・createdAt）だけを補う。 */
export async function ensureAccountDefaultsIn(
  tx: Transaction,
  uid: string,
  db: Firestore,
  createdAt?: Date,
): Promise<Record<string, unknown>> {
  const snapshot = await tx.get(db.doc(`accounts/${uid}`));
  return missingAccountDefaults(snapshot.data(), createdAt);
}

/**
 * 新規登録したユーザーの accounts/{uid} に、isDeveloper（既定値 false）と createdAt をそろえる。
 *
 * - 無いフィールドだけを補い、すでにある値は上書きしない（コンソールで true にした isDeveloper を守るため）
 * - 新規登録の直後は、同意の関数（acceptLegal）が先に consents だけのドキュメントを作ることがある。
 *   その場合も、足りない isDeveloper・createdAt を補う
 * - [createdAt] には Authentication のユーザーの作成日時を渡す（補完スクリプトで後から補うときも、登録した時刻になる）
 * - 何度呼んでも同じ結果になる
 */
export async function createAccountDoc(
  uid: string,
  db: Firestore,
  createdAt?: Date,
): Promise<void> {
  const ref = db.doc(`accounts/${uid}`);
  await db.runTransaction(async (tx) => {
    const patch = await ensureAccountDefaultsIn(tx, uid, db, createdAt);
    if (Object.keys(patch).length > 0) tx.set(ref, patch, { merge: true });
  });
}
