import { Auth } from "firebase-admin/auth";
import { FieldValue, Firestore } from "firebase-admin/firestore";
import { CONSENT_LOGS } from "./accept_legal";

/** 退会済みの記録のコレクション。ドキュメント ID が退会したユーザーの uid。退会後も削除しない。 */
export const DELETED_ACCOUNTS = "deleted_accounts";

/** 退会に必要な、最後にログイン（本人確認）してからの時間の上限（秒）。 */
export const RECENT_LOGIN_MAX_AGE_SECONDS = 5 * 60;

/**
 * 最後にログイン（本人確認）した時刻 [authTime]（ID トークンの auth_time。秒）が、[nowMillis] から
 * [RECENT_LOGIN_MAX_AGE_SECONDS] 以内か。盗まれたログイン情報（最大1時間有効）だけで退会させられないようにするため。
 */
export function isRecentLogin(authTime: unknown, nowMillis: number): boolean {
  if (typeof authTime !== "number") return false;
  return nowMillis / 1000 - authTime <= RECENT_LOGIN_MAX_AGE_SECONDS;
}

/**
 * ユーザーの Firestore のデータ（users/{uid} 配下すべてと accounts/{uid}）と Authentication のユーザーを削除する。
 *
 * - 最初に退会済みの記録（deleted_accounts/{uid}）を作る。Firestore のルールが、この記録がある uid の
 *   users/{uid} 配下への書き込みを拒否するため、削除の途中から他の端末の同期による書き込みが止まる。
 *   他の端末は、この記録で退会済みであることを知り、端末内のデータを削除する
 * - 退会済みの記録は退会日時だけを持つ（ログインしていない端末からも読めるため、個人情報を置かない）
 * - メールアドレスは、規約への同意の履歴（consent_logs/{uid}。サーバーしか読めない）のドキュメントに書く。
 *   退会後のトラブルのときに、同意の履歴と本人を結びつけるため。Authentication のユーザーから取る
 *   （メールアドレスの無いユーザーは書かない）
 * - Firestore → Authentication の順に削除する（Authentication を先に消すと、
 *   途中で止まったときの再試行で本人確認ができなくなるため）
 * - 何度呼んでも同じ結果になる。すでに消えているデータ・ユーザーは飛ばす。退会済みの記録は上書きで1つのまま。
 *   Authentication のユーザーが消えた後の再試行では、前回書いたメールアドレスを残す（メールアドレスが取れたときだけ merge で書く）
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
  const batch = db.batch();
  batch.set(
    db.doc(`${DELETED_ACCOUNTS}/${uid}`),
    { deletedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  if (email) {
    batch.set(db.doc(`${CONSENT_LOGS}/${uid}`), { email }, { merge: true });
  }
  await batch.commit();
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
