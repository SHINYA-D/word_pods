import { Auth } from "firebase-admin/auth";
import { FieldValue, Firestore } from "firebase-admin/firestore";

/** 退会済みの記録のコレクション。ドキュメント ID が退会したユーザーの uid。退会後も削除しない。 */
export const DELETED_ACCOUNTS = "deleted_accounts";

/**
 * ユーザーの Firestore のデータ（users/{uid} 配下すべてと accounts/{uid}）と Authentication のユーザーを削除する。
 *
 * - 最初に退会済みの記録（deleted_accounts/{uid}）を作る。Firestore のルールが、この記録がある uid の
 *   users/{uid} 配下への書き込みを拒否するため、削除の途中から他の端末の同期による書き込みが止まる。
 *   他の端末は、この記録で退会済みであることを知り、端末内のデータを削除する
 * - 退会済みの記録は退会日時とメールアドレスを持つ。メールアドレスは、退会後のトラブルのときに
 *   規約への同意の履歴（consent_logs/{uid}）と本人を結びつけるため。Authentication のユーザーから取る
 *   （メールアドレスの無いユーザーは持たない）
 * - Firestore → Authentication の順に削除する（Authentication を先に消すと、
 *   途中で止まったときの再試行で本人確認ができなくなるため）
 * - 何度呼んでも同じ結果になる。すでに消えているデータ・ユーザーは飛ばす。退会済みの記録は上書きで1つのまま。
 *   Authentication のユーザーが消えた後の再試行では、前回書いたメールアドレスを残す（merge で書く）
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
  const email = await findEmail(uid, auth);
  await db.doc(`${DELETED_ACCOUNTS}/${uid}`).set(
    {
      deletedAt: FieldValue.serverTimestamp(),
      ...(email ? { email } : {}),
    },
    { merge: true },
  );
  await deleteFirestoreData(uid, db);
  try {
    await auth.deleteUser(uid);
  } catch (e) {
    if (!isUserNotFound(e)) throw e;
  }
  await deleteFirestoreData(uid, db);
}

/** Authentication のユーザーのメールアドレス。ユーザーが消えている・メールアドレスが無いときは undefined。 */
async function findEmail(uid: string, auth: Auth): Promise<string | undefined> {
  try {
    return (await auth.getUser(uid)).email;
  } catch (e) {
    if (isUserNotFound(e)) return undefined;
    throw e;
  }
}

function isUserNotFound(e: unknown): boolean {
  return (e as { code?: string }).code === "auth/user-not-found";
}

async function deleteFirestoreData(uid: string, db: Firestore): Promise<void> {
  await db.recursiveDelete(db.doc(`users/${uid}`));
  await db.recursiveDelete(db.doc(`accounts/${uid}`));
}
