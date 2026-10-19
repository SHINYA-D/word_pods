// Firebase Emulator（Firestore・Auth）上で実行する: npm run test:emulator
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { deleteUserAccount } from "../src/delete_account";

const app = initializeApp({ projectId: "demo-word-stock" }, "test");
const db = getFirestore(app);
const auth = getAuth(app);

async function seed(uid: string): Promise<void> {
  await db.doc(`users/${uid}/folders/f1`).set({ name: "英単語" });
  await db.doc(`users/${uid}/folders/f1/words/w1`).set({ front: "apple" });
  await db.doc(`users/${uid}/folders/f2`).set({ name: "削除済み", deletedAt: "x" });
  await db.doc(`users/${uid}/folders/f2/words/w2`).set({ front: "banana" });
  await db.doc(`users/${uid}/flashcard_results/r1`).set({ correct: 1 });
  await db.doc(`users/${uid}/settings/config`).set({ darkMode: true });
  await db.doc(`accounts/${uid}`).set({ isDeveloper: true });
}

async function countDocs(uid: string): Promise<number> {
  const snapshots = await Promise.all([
    db.collection(`users/${uid}/folders`).get(),
    db.collectionGroup("words").get(),
    db.collection(`users/${uid}/flashcard_results`).get(),
    db.collection(`users/${uid}/settings`).get(),
  ]);
  const [folders, words, results, settings] = snapshots;
  const ownWords = words.docs.filter((d) => d.ref.path.startsWith(`users/${uid}/`));
  const account = (await db.doc(`accounts/${uid}`).get()).exists ? 1 : 0;
  return folders.size + ownWords.length + results.size + settings.size + account;
}

beforeEach(async () => {
  await db.recursiveDelete(db.collection("users"));
  await db.recursiveDelete(db.collection("accounts"));
  await db.recursiveDelete(db.collection("deleted_accounts"));
  await db.recursiveDelete(db.collection("consent_logs"));
  const { users } = await auth.listUsers();
  await Promise.all(users.map((u) => auth.deleteUser(u.uid)));
});

afterAll(async () => {
  await deleteApp(app);
});

describe("deleteUserAccount", () => {
  test("データとユーザーがある場合、users/{uid} 配下のすべてのデータと accounts/{uid} とユーザーが削除される", async () => {
    await auth.createUser({ uid: "A" });
    await seed("A");

    await deleteUserAccount("A", db, auth);

    expect(await countDocs("A")).toBe(0);
    await expect(auth.getUser("A")).rejects.toMatchObject({ code: "auth/user-not-found" });
  });

  test("他のユーザーのデータがある場合、他のユーザーのデータとユーザーは残る", async () => {
    await auth.createUser({ uid: "A" });
    await auth.createUser({ uid: "B" });
    await seed("A");
    await seed("B");

    await deleteUserAccount("A", db, auth);

    expect(await countDocs("B")).toBe(7);
    await expect(auth.getUser("B")).resolves.toMatchObject({ uid: "B" });
  });

  test("2回続けて呼んだ場合、2回目もエラーにならない", async () => {
    await auth.createUser({ uid: "A" });
    await seed("A");

    await deleteUserAccount("A", db, auth);
    await expect(deleteUserAccount("A", db, auth)).resolves.toBeUndefined();
  });

  test("ユーザーが既に無くデータだけ残っている場合、データが削除されエラーにならない", async () => {
    await seed("A");

    await expect(deleteUserAccount("A", db, auth)).resolves.toBeUndefined();
    expect(await countDocs("A")).toBe(0);
  });

  test("accounts/{uid} が無い場合でも、users/{uid} 配下とユーザーが削除されエラーにならない", async () => {
    await auth.createUser({ uid: "A" });
    await seed("A");
    await db.doc("accounts/A").delete();

    await expect(deleteUserAccount("A", db, auth)).resolves.toBeUndefined();
    expect(await countDocs("A")).toBe(0);
    await expect(auth.getUser("A")).rejects.toMatchObject({ code: "auth/user-not-found" });
  });

  test("退会した場合、deleted_accounts/{uid} が退会日時だけを持って残る", async () => {
    await auth.createUser({ uid: "A", email: "a@example.com" });
    await seed("A");

    await deleteUserAccount("A", db, auth);

    const record = await db.doc("deleted_accounts/A").get();
    expect(record.exists).toBe(true);
    expect(Object.keys(record.data() ?? {})).toEqual(["deletedAt"]);
  });

  test("他のユーザーが退会した場合、deleted_accounts に自分の記録は作られない", async () => {
    await auth.createUser({ uid: "A" });
    await auth.createUser({ uid: "B" });

    await deleteUserAccount("A", db, auth);

    expect((await db.doc("deleted_accounts/B").get()).exists).toBe(false);
  });

  test("2回続けて呼んだ場合、deleted_accounts/{uid} は1つのまま残る", async () => {
    await auth.createUser({ uid: "A" });

    await deleteUserAccount("A", db, auth);
    await deleteUserAccount("A", db, auth);

    const all = await db.collection("deleted_accounts").get();
    expect(all.docs.map((d) => d.id)).toEqual(["A"]);
  });

  test("規約への同意の履歴がある場合、退会しても consent_logs/{uid} の履歴は残る", async () => {
    await auth.createUser({ uid: "A" });
    await seed("A");
    await db.doc("consent_logs/A/logs/l1").set({ document: "terms", version: "2026-01-01" });

    await deleteUserAccount("A", db, auth);

    const logs = await db.collection("consent_logs/A/logs").get();
    expect(logs.docs.map((d) => d.data().version)).toEqual(["2026-01-01"]);
  });
});
