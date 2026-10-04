import { Auth } from "firebase-admin/auth";
import { Firestore } from "firebase-admin/firestore";
import { createAccountDoc } from "./create_account";

/**
 * 新規登録トリガーより前に登録したユーザーにも accounts/{uid}（isDeveloper: false）を作る（一回きりの移行用）。
 * 既にあるドキュメントは上書きしない。実行は scripts/backfill_accounts.js から行う。
 *
 * @returns 処理したユーザー数（既にドキュメントがあった人も含む）
 */
export async function backfillAccounts(db: Firestore, auth: Auth): Promise<number> {
  let count = 0;
  let pageToken: string | undefined;
  do {
    const page = await auth.listUsers(1000, pageToken);
    await Promise.all(page.users.map((u) => createAccountDoc(u.uid, db)));
    count += page.users.length;
    pageToken = page.pageToken;
  } while (pageToken);
  return count;
}
