import { Auth } from "firebase-admin/auth";
import { Firestore } from "firebase-admin/firestore";
import { createAccountDoc } from "./create_account";

/**
 * すべてのユーザーの accounts/{uid} に、isDeveloper（既定値 false）と createdAt をそろえる（移行用）。
 * ドキュメントが無ければ作り、あれば足りないフィールドだけを補う。すでにある値は上書きしない。
 * 実行は scripts/backfill_accounts.js から行う。
 *
 * @returns 処理したユーザー数（既にドキュメントがあった人も含む）
 */
export async function backfillAccounts(db: Firestore, auth: Auth): Promise<number> {
  let count = 0;
  let pageToken: string | undefined;
  do {
    const page = await auth.listUsers(1000, pageToken);
    await Promise.all(
      page.users.map((u) => createAccountDoc(u.uid, db, new Date(u.metadata.creationTime))),
    );
    count += page.users.length;
    pageToken = page.pageToken;
  } while (pageToken);
  return count;
}
