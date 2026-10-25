// Firebase Emulator（Firestore）上で実行する: npm run test:emulator
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { acceptLegal, CONSENT_LOGS, DEFAULT_LEGAL_CONFIG } from "../src/accept_legal";

const app = initializeApp({ projectId: "demo-word-pods" }, "accept-legal-test");
const db = getFirestore(app);

async function logsOf(uid: string) {
  const snapshot = await db.collection(`${CONSENT_LOGS}/${uid}/logs`).get();
  return snapshot.docs.map((d) => d.data());
}

beforeEach(async () => {
  await db.recursiveDelete(db.collection("accounts"));
  await db.recursiveDelete(db.collection(CONSENT_LOGS));
  await db.recursiveDelete(db.collection("app_config"));
  await db.doc("app_config/legal").set({
    termsVersion: "2026-01-01",
    privacyVersion: "2026-01-01",
    termsUrl: "https://example.com/terms",
    privacyUrl: "https://example.com/privacy",
  });
});

afterAll(async () => {
  await deleteApp(app);
});

describe("acceptLegal", () => {
  test("現行の版数で2つの文書に同意した場合、accounts/{uid}.consents に版数とサーバー時刻が書かれる", async () => {
    await acceptLegal("A", { terms: "2026-01-01", privacy: "2026-01-01" }, db);

    const consents = (await db.doc("accounts/A").get()).data()?.consents;
    expect(consents.terms.version).toBe("2026-01-01");
    expect(consents.privacy.version).toBe("2026-01-01");
    expect(consents.terms.agreedAt).toBeInstanceOf(Timestamp);
    expect(consents.privacy.agreedAt).toBeInstanceOf(Timestamp);
  });

  test("現行の版数で2つの文書に同意した場合、履歴が文書ごとに1件ずつ追記される", async () => {
    await acceptLegal("A", { terms: "2026-01-01", privacy: "2026-01-01" }, db);

    const logs = await logsOf("A");
    expect(logs.map((l) => l.document).sort()).toEqual(["privacy", "terms"]);
    expect(logs.every((l) => l.version === "2026-01-01")).toBe(true);
    expect(logs.every((l) => l.agreedAt instanceof Timestamp)).toBe(true);
  });

  test("利用規約だけに同意した場合、consents には利用規約だけが書かれ、履歴も1件になる", async () => {
    await acceptLegal("A", { terms: "2026-01-01" }, db);

    const consents = (await db.doc("accounts/A").get()).data()?.consents;
    expect(consents.terms.version).toBe("2026-01-01");
    expect(consents.privacy).toBeUndefined();
    expect((await logsOf("A")).map((l) => l.document)).toEqual(["terms"]);
  });

  test("accounts/{uid} が無い場合、consents と一緒に isDeveloper: false と createdAt が書かれる", async () => {
    await acceptLegal("A", { terms: "2026-01-01", privacy: "2026-01-01" }, db);

    const data = (await db.doc("accounts/A").get()).data();
    expect(data?.isDeveloper).toBe(false);
    expect(data?.createdAt).toBeInstanceOf(Timestamp);
  });

  test("accounts/{uid} に createdAt がある場合、同意しても createdAt は変わらない", async () => {
    const old = Timestamp.fromDate(new Date("2026-01-01T00:00:00Z"));
    await db.doc("accounts/A").set({ isDeveloper: false, createdAt: old });

    await acceptLegal("A", { terms: "2026-01-01" }, db);

    expect((await db.doc("accounts/A").get()).get("createdAt").isEqual(old)).toBe(true);
  });

  test("accounts/{uid} に isDeveloper がある場合、同意しても isDeveloper は残る", async () => {
    await db.doc("accounts/A").set({ isDeveloper: true });

    await acceptLegal("A", { terms: "2026-01-01", privacy: "2026-01-01" }, db);

    const data = (await db.doc("accounts/A").get()).data();
    expect(data?.isDeveloper).toBe(true);
    expect(data?.consents.terms.version).toBe("2026-01-01");
  });

  test("プライバシーポリシーに同意済みで利用規約だけに同意した場合、プライバシーポリシーの記録は残る", async () => {
    await acceptLegal("A", { privacy: "2026-01-01" }, db);
    await acceptLegal("A", { terms: "2026-01-01" }, db);

    const consents = (await db.doc("accounts/A").get()).data()?.consents;
    expect(consents.privacy.version).toBe("2026-01-01");
    expect(consents.terms.version).toBe("2026-01-01");
  });

  test("同じ版数で2回呼んだ場合、最新の同意は同じ版数のままで、履歴は2回分になる", async () => {
    await acceptLegal("A", { terms: "2026-01-01" }, db);
    await acceptLegal("A", { terms: "2026-01-01" }, db);

    const consents = (await db.doc("accounts/A").get()).data()?.consents;
    expect(consents.terms.version).toBe("2026-01-01");
    expect(await logsOf("A")).toHaveLength(2);
  });

  test("送った利用規約の版数が現行と違う場合、failed-precondition で失敗し、何も書かれない", async () => {
    await expect(
      acceptLegal("A", { terms: "2025-06-01", privacy: "2026-01-01" }, db),
    ).rejects.toMatchObject({ code: "failed-precondition" });

    expect((await db.doc("accounts/A").get()).exists).toBe(false);
    expect(await logsOf("A")).toHaveLength(0);
  });

  test("送ったプライバシーポリシーの版数が現行と違う場合、failed-precondition で失敗する", async () => {
    await expect(
      acceptLegal("A", { privacy: "2025-06-01" }, db),
    ).rejects.toMatchObject({ code: "failed-precondition" });
  });

  test("app_config/legal が無い場合、既定値で作られ、既定値の版数での同意は記録される", async () => {
    await db.doc("app_config/legal").delete();

    await acceptLegal("A", { terms: "2026-10-12", privacy: "2026-10-12" }, db);

    expect((await db.doc("app_config/legal").get()).data()).toEqual(DEFAULT_LEGAL_CONFIG);
    const consents = (await db.doc("accounts/A").get()).data()?.consents;
    expect(consents.terms.version).toBe("2026-10-12");
    expect(consents.privacy.version).toBe("2026-10-12");
  });

  test("app_config/legal が無く、既定値と違う版数を送った場合、既定値で作られ、failed-precondition で失敗する", async () => {
    await db.doc("app_config/legal").delete();

    await expect(
      acceptLegal("A", { terms: "2026-01-01" }, db),
    ).rejects.toMatchObject({ code: "failed-precondition" });
    expect((await db.doc("app_config/legal").get()).data()).toEqual(DEFAULT_LEGAL_CONFIG);
    expect((await db.doc("accounts/A").get()).exists).toBe(false);
  });

  test("app_config/legal に項目が欠けている場合、既定値の版数で確かめ、ドキュメントは書き換えない", async () => {
    await db.doc("app_config/legal").set({ termsVersion: "2026-01-01" });

    await acceptLegal("A", { terms: "2026-10-12", privacy: "2026-10-12" }, db);

    expect((await db.doc("app_config/legal").get()).data()).toEqual({ termsVersion: "2026-01-01" });
    const consents = (await db.doc("accounts/A").get()).data()?.consents;
    expect(consents.terms.version).toBe("2026-10-12");
  });

  test("app_config/legal がある場合、既定値で上書きしない", async () => {
    await acceptLegal("A", { terms: "2026-01-01" }, db);

    expect((await db.doc("app_config/legal").get()).data()?.termsVersion).toBe("2026-01-01");
  });

  test("どちらの版数も送らない場合、invalid-argument で失敗する", async () => {
    await expect(acceptLegal("A", {}, db)).rejects.toMatchObject({ code: "invalid-argument" });
  });

  test("版数が文字列でない場合、invalid-argument で失敗する", async () => {
    await expect(
      acceptLegal("A", { terms: 20260101 }, db),
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  test("引数が null の場合、invalid-argument で失敗する", async () => {
    await expect(acceptLegal("A", null, db)).rejects.toMatchObject({ code: "invalid-argument" });
  });

  test("ほかのユーザーの記録がある場合、そのユーザーの記録は変わらない", async () => {
    await acceptLegal("B", { terms: "2026-01-01" }, db);

    await acceptLegal("A", { terms: "2026-01-01", privacy: "2026-01-01" }, db);

    const consentsB = (await db.doc("accounts/B").get()).data()?.consents;
    expect(consentsB.privacy).toBeUndefined();
    expect(await logsOf("B")).toHaveLength(1);
  });
});
