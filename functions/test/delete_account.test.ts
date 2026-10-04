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
  return folders.size + ownWords.length + results.size + settings.size;
}

beforeEach(async () => {
  await db.recursiveDelete(db.collection("users"));
  const { users } = await auth.listUsers();
  await Promise.all(users.map((u) => auth.deleteUser(u.uid)));
});

afterAll(async () => {
  await deleteApp(app);
});

describe("deleteUserAccount", () => {
  test("データとユーザーがある場合、users/{uid} 配下のすべてのデータとユーザーが削除される", async () => {
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

    expect(await countDocs("B")).toBe(6);
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
});
