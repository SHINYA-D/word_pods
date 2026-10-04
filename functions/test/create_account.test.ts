// Firebase Emulator（Firestore・Auth）上で実行する: npm run test:emulator
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { backfillAccounts } from "../src/backfill_accounts";
import { createAccountDoc } from "../src/create_account";

const app = initializeApp({ projectId: "demo-word-stock" }, "test-create-account");
const db = getFirestore(app);
const auth = getAuth(app);

beforeEach(async () => {
  await db.recursiveDelete(db.collection("accounts"));
  const { users } = await auth.listUsers();
  await Promise.all(users.map((u) => auth.deleteUser(u.uid)));
});

afterAll(async () => {
  await deleteApp(app);
});

describe("createAccountDoc", () => {
  test("ドキュメントが無い場合、isDeveloper: false と作成時刻で作られる", async () => {
    await createAccountDoc("A", db);

    const snap = await db.doc("accounts/A").get();
    expect(snap.get("isDeveloper")).toBe(false);
    expect(snap.get("createdAt")).toBeDefined();
  });

  test("isDeveloper: true のドキュメントが既にある場合、上書きされずエラーにもならない", async () => {
    await db.doc("accounts/A").set({ isDeveloper: true });

    await expect(createAccountDoc("A", db)).resolves.toBeUndefined();
    expect((await db.doc("accounts/A").get()).get("isDeveloper")).toBe(true);
  });
});

describe("backfillAccounts", () => {
  test("ドキュメントが無いユーザーにだけ isDeveloper: false で作られ、既存のドキュメントは上書きされない", async () => {
    await auth.createUser({ uid: "A" });
    await auth.createUser({ uid: "B" });
    await db.doc("accounts/B").set({ isDeveloper: true });

    const count = await backfillAccounts(db, auth);

    expect(count).toBe(2);
    expect((await db.doc("accounts/A").get()).get("isDeveloper")).toBe(false);
    expect((await db.doc("accounts/B").get()).get("isDeveloper")).toBe(true);
  });
});
