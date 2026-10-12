// Firebase Emulator（Firestore）上で実行する: npm run test:emulator
// firebase/firestore.rules のうち、退会に関わるルールを確かめる。
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, getDocs, setDoc, collection } from "firebase/firestore";
import { readFileSync } from "fs";
import { resolve } from "path";

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-word-stock",
    firestore: {
      rules: readFileSync(resolve(__dirname, "../../firebase/firestore.rules"), "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
});

afterAll(async () => {
  await env.cleanup();
});

/** 管理者として（ルールを通さずに）退会済みの記録を作る。 */
async function markWithdrawn(uid: string): Promise<void> {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `deleted_accounts/${uid}`), { deletedAt: new Date() });
  });
}

describe("users/{uid} への書き込み", () => {
  test("退会済みの記録が無い本人の場合、書き込める", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertSucceeds(setDoc(doc(db, "users/A/folders/f1"), { name: "英単語" }));
  });

  test("退会済みの記録がある本人の場合、書き込めない", async () => {
    await markWithdrawn("A");
    const db = env.authenticatedContext("A").firestore();
    await assertFails(setDoc(doc(db, "users/A/folders/f1"), { name: "英単語" }));
  });

  test("別のユーザーが退会済みの場合、自分の users/{uid} には書き込める", async () => {
    await markWithdrawn("B");
    const db = env.authenticatedContext("A").firestore();
    await assertSucceeds(setDoc(doc(db, "users/A/folders/f1"), { name: "英単語" }));
  });

  test("退会済みの記録がある本人の場合でも、読み取りはできる", async () => {
    await markWithdrawn("A");
    const db = env.authenticatedContext("A").firestore();
    await assertSucceeds(getDoc(doc(db, "users/A/folders/f1")));
  });
});

describe("deleted_accounts/{uid}", () => {
  test("ログインしていない場合、1件を読める", async () => {
    await markWithdrawn("A");
    const db = env.unauthenticatedContext().firestore();
    const snapshot = await assertSucceeds(getDoc(doc(db, "deleted_accounts/A")));
    expect(snapshot.exists()).toBe(true);
  });

  test("記録が無い uid の場合、ログインしていなくても読め、存在しない結果になる", async () => {
    const db = env.unauthenticatedContext().firestore();
    const snapshot = await assertSucceeds(getDoc(doc(db, "deleted_accounts/A")));
    expect(snapshot.exists()).toBe(false);
  });

  test("一覧の読み取りはできない", async () => {
    await markWithdrawn("A");
    const db = env.authenticatedContext("A").firestore();
    await assertFails(getDocs(collection(db, "deleted_accounts")));
  });

  test("本人であっても書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertFails(setDoc(doc(db, "deleted_accounts/A"), { deletedAt: new Date() }));
  });
});
