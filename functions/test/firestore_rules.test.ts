// Firebase Emulator（Firestore）上で実行する: npm run test:emulator
// firebase/firestore.rules を確かめる（退会・同意・users/ 配下へ書き込めるデータの形）。
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  Timestamp,
} from "firebase/firestore";
import { readFileSync } from "fs";
import { resolve } from "path";

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-word-pods",
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

/** アプリの同期（FirestoreSyncRemoteDataSource）が書くフォルダの形。 */
function folder(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    name: "英単語",
    parentFolderId: null,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
    deletedAt: null,
    serverUpdatedAt: serverTimestamp(),
    ...overrides,
  };
}

describe("users/{uid} への書き込み", () => {
  test("退会済みの記録が無い本人の場合、書き込める", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertSucceeds(setDoc(doc(db, "users/A/folders/f1"), folder()));
  });

  test("退会済みの記録がある本人の場合、書き込めない", async () => {
    await markWithdrawn("A");
    const db = env.authenticatedContext("A").firestore();
    await assertFails(setDoc(doc(db, "users/A/folders/f1"), folder()));
  });

  test("別のユーザーが退会済みの場合、自分の users/{uid} には書き込める", async () => {
    await markWithdrawn("B");
    const db = env.authenticatedContext("A").firestore();
    await assertSucceeds(setDoc(doc(db, "users/A/folders/f1"), folder()));
  });

  test("退会済みの記録がある本人の場合でも、読み取りはできる", async () => {
    await markWithdrawn("A");
    const db = env.authenticatedContext("A").firestore();
    await assertSucceeds(getDoc(doc(db, "users/A/folders/f1")));
  });
});

describe("users/{uid} 配下へ書き込めるデータの形", () => {
  const now = () => Timestamp.now();

  test("同期が書く形のフォルダ・単語・結果・設定の場合、書き込める", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertSucceeds(setDoc(doc(db, "users/A/folders/f1"), folder()));
    await assertSucceeds(
      setDoc(doc(db, "users/A/folders/f1/words/w1"), {
        front: "apple",
        back: "りんご",
        createdAt: now(),
        updatedAt: now(),
        deletedAt: null,
        serverUpdatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, "users/A/flashcard_results/r1"), {
        folderId: "f1",
        totalCount: 10,
        correctCount: 7,
        date: now(),
        updatedAt: now(),
        deletedAt: null,
        serverUpdatedAt: serverTimestamp(),
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, "users/A/settings/config"), {
        colorTheme: "indigo",
        darkMode: true,
        updatedAt: now(),
        serverUpdatedAt: serverTimestamp(),
      }),
    );
  });

  test("決められていない項目を含む場合、書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertFails(setDoc(doc(db, "users/A/folders/f1"), folder({ extra: "x" })));
  });

  test("フォルダ名が100文字の場合は書き込め、101文字の場合は書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertSucceeds(setDoc(doc(db, "users/A/folders/f1"), folder({ name: "a".repeat(100) })));
    await assertFails(setDoc(doc(db, "users/A/folders/f2"), folder({ name: "a".repeat(101) })));
  });

  test("単語の表面が1001文字の場合、書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertFails(
      setDoc(doc(db, "users/A/folders/f1/words/w1"), {
        front: "a".repeat(1001),
        back: "b",
        updatedAt: now(),
        serverUpdatedAt: serverTimestamp(),
      }),
    );
  });

  test("項目の型が違う場合、書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertFails(
      setDoc(doc(db, "users/A/settings/config"), {
        colorTheme: "indigo",
        darkMode: "yes",
        updatedAt: now(),
        serverUpdatedAt: serverTimestamp(),
      }),
    );
  });

  test("serverUpdatedAt に端末の時刻を書く場合、書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertFails(setDoc(doc(db, "users/A/folders/f1"), folder({ serverUpdatedAt: now() })));
  });

  test("決められていないコレクションの場合、書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertFails(setDoc(doc(db, "users/A/others/x"), { a: 1 }));
  });

  test("設定の config 以外のドキュメントの場合、書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertFails(
      setDoc(doc(db, "users/A/settings/other"), {
        colorTheme: "indigo",
        darkMode: false,
        updatedAt: now(),
        serverUpdatedAt: serverTimestamp(),
      }),
    );
  });

  test("本人の場合、削除できる", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertSucceeds(deleteDoc(doc(db, "users/A/folders/f1")));
  });

  test("別のユーザーの場合、正しい形でも書き込めない", async () => {
    const db = env.authenticatedContext("B").firestore();
    await assertFails(setDoc(doc(db, "users/A/folders/f1"), folder()));
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

describe("consent_logs/{uid}（規約への同意の履歴）", () => {
  async function seedLog(uid: string): Promise<void> {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `consent_logs/${uid}/logs/l1`), {
        document: "terms",
        version: "2026-01-01",
      });
    });
  }

  test("本人の場合でも、履歴を読めない", async () => {
    await seedLog("A");
    const db = env.authenticatedContext("A").firestore();
    await assertFails(getDoc(doc(db, "consent_logs/A/logs/l1")));
  });

  test("本人の場合でも、履歴を書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertFails(
      setDoc(doc(db, "consent_logs/A/logs/l2"), { document: "terms", version: "2026-01-01" }),
    );
  });

  test("ログインしていない場合、退会者のメールアドレスを持つ consent_logs/{uid} を読めない", async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "consent_logs/A"), { email: "a@example.com" });
    });
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, "consent_logs/A")));
  });

  test("本人の場合でも、履歴の一覧を読めない", async () => {
    await seedLog("A");
    const db = env.authenticatedContext("A").firestore();
    await assertFails(getDocs(collection(db, "consent_logs/A/logs")));
  });
});

describe("app_config/legal（規約の現行の版数）", () => {
  test("ログインしていない場合でも読める", async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(db, "app_config/legal")));
  });

  test("ログインしている本人でも書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertFails(setDoc(doc(db, "app_config/legal"), { termsVersion: "2026-01-01" }));
  });
});

describe("accounts/{uid}（規約への同意の最新の記録）", () => {
  test("本人の場合でも、consents を書き込めない", async () => {
    const db = env.authenticatedContext("A").firestore();
    await assertFails(
      setDoc(doc(db, "accounts/A"), { consents: { terms: { version: "2026-01-01" } } }, { merge: true }),
    );
  });
});
