// Firebase Emulator（Firestore・Auth）上で実行する: npm run test:emulator
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { backfillAccounts } from "../src/backfill_accounts";
import { createAccountDoc } from "../src/create_account";

const app = initializeApp({ projectId: "demo-word-pods" }, "test-create-account");
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

  test("consents だけのドキュメントが既にある場合、isDeveloper: false と createdAt が補われ、consents は残る", async () => {
    await db.doc("accounts/A").set({ consents: { terms: { version: "2026-10-12" } } });

    await createAccountDoc("A", db);

    const snap = await db.doc("accounts/A").get();
    expect(snap.get("isDeveloper")).toBe(false);
    expect(snap.get("createdAt")).toBeInstanceOf(Timestamp);
    expect(snap.get("consents.terms.version")).toBe("2026-10-12");
  });

  test("作成日時を渡した場合、createdAt はその日時になる", async () => {
    const created = new Date("2026-10-18T02:10:26Z");

    await createAccountDoc("A", db, created);

    expect((await db.doc("accounts/A").get()).get("createdAt").toDate()).toEqual(created);
  });

  test("isDeveloper と createdAt が既にある場合、どちらも上書きされない", async () => {
    const old = Timestamp.fromDate(new Date("2026-01-01T00:00:00Z"));
    await db.doc("accounts/A").set({ isDeveloper: true, createdAt: old });

    await createAccountDoc("A", db, new Date("2026-10-18T00:00:00Z"));

    const snap = await db.doc("accounts/A").get();
    expect(snap.get("isDeveloper")).toBe(true);
    expect(snap.get("createdAt").isEqual(old)).toBe(true);
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

  test("consents だけのドキュメントがあるユーザーには、isDeveloper: false と Authentication の作成日時の createdAt が補われる", async () => {
    const user = await auth.createUser({ uid: "A" });
    await db.doc("accounts/A").set({ consents: { terms: { version: "2026-10-12" } } });

    await backfillAccounts(db, auth);

    const snap = await db.doc("accounts/A").get();
    expect(snap.get("isDeveloper")).toBe(false);
    expect(snap.get("createdAt").toDate()).toEqual(new Date(user.metadata.creationTime));
    expect(snap.get("consents.terms.version")).toBe("2026-10-12");
  });
});
