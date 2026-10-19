// すべてのユーザーの accounts/{uid} に isDeveloper（既定値 false）と createdAt をそろえる移行スクリプト。
// ドキュメントが無ければ作り、あれば足りないフィールドだけを補う。すでにある値は上書きしない。
//
// 実行方法（functions/ で）:
//   gcloud auth application-default login   # 初回のみ。対象プロジェクトの権限があるアカウントで
//   npm run build
//   node scripts/backfill_accounts.js <projectId>   # 例: word-stock-2026-test / word-stock-prod
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { backfillAccounts } = require("../lib/backfill_accounts");

async function main() {
  const projectId = process.argv[2];
  if (!projectId) {
    console.error("使い方: node scripts/backfill_accounts.js <projectId>");
    process.exit(1);
  }
  initializeApp({ projectId });
  const count = await backfillAccounts(getFirestore(), getAuth());
  console.log(`${projectId}: ${count} 人のユーザーを処理しました`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
