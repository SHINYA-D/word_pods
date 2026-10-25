import { FieldValue, Firestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { ensureAccountDefaultsIn } from "./create_account";

/** 同意の履歴のコレクション。ドキュメント ID が uid。退会後も削除しない（accounts とは別に置く）。 */
export const CONSENT_LOGS = "consent_logs";

/** アプリが送る同意の内容。同意ダイアログに表示した文書の版数だけを送る。 */
export interface AcceptLegalInput {
  terms?: string;
  privacy?: string;
}

/** app_config/legal が無い（項目が欠けている）ときの既定値。アプリの LegalConfig.defaults と同じ値にする。 */
export const DEFAULT_LEGAL_CONFIG = {
  termsVersion: "2026-10-12",
  privacyVersion: "2026-10-12",
  termsUrl: "https://word-pods-web.web.app/terms",
  privacyUrl: "https://word-pods-web.web.app/privacy",
} as const;

/** Firestore の ALREADY_EXISTS（gRPC のステータスコード 6） */
const ALREADY_EXISTS = 6;

const DOCUMENTS = ["terms", "privacy"] as const;
type LegalDocument = (typeof DOCUMENTS)[number];

/**
 * 利用規約・プライバシーポリシーへの同意を記録する。
 *
 * - app_config/legal が無ければ既定値で作る（すでにあれば書き換えない）。項目が欠けていれば既定値で確かめる
 *   （アプリと同じ扱いにして、版数違いが返り続けないようにする）
 * - 送られた版数が現行の版数と一致しなければ、同意は書かずに failed-precondition で失敗する
 *   （同意ダイアログを表示している間に改定された場合。アプリは判定し直して表示し直す）
 * - accounts/{uid}.consents に最新の同意を、consent_logs/{uid}/logs に履歴を、1つのトランザクションで書く
 * - 時刻はサーバー時刻（端末時刻ではなく、証跡として改ざんできないようにするため）
 * - accounts/{uid} は merge で consents を書き、他のフィールド（isDeveloper など）を壊さない。
 *   isDeveloper（既定値 false）と createdAt が無ければ一緒に補う（新規登録の直後に、新規登録のトリガーより先に届いた場合）
 * - 同じ版数で何度呼んでも、最新の同意は同じ内容になる（履歴は呼んだ回数だけ増える）
 */
export async function acceptLegal(
  uid: string,
  input: unknown,
  db: Firestore,
): Promise<void> {
  const versions = parseInput(input);
  const config = await currentConfig(db);
  const current: Record<LegalDocument, unknown> = {
    terms: config.termsVersion,
    privacy: config.privacyVersion,
  };
  const accepted = DOCUMENTS.filter((d) => versions[d] !== undefined);
  if (accepted.some((d) => versions[d] !== current[d])) {
    throw new HttpsError("failed-precondition", "規約の版数が現行の版数と違います");
  }

  const agreedAt = FieldValue.serverTimestamp();
  await db.runTransaction(async (tx) => {
    const defaults = await ensureAccountDefaultsIn(tx, uid, db);
    const consents: Record<string, { version: string; agreedAt: FieldValue }> = {};
    for (const document of accepted) {
      const version = versions[document] as string;
      consents[document] = { version, agreedAt };
      tx.create(db.collection(`${CONSENT_LOGS}/${uid}/logs`).doc(), {
        document,
        version,
        agreedAt,
      });
    }
    tx.set(db.doc(`accounts/${uid}`), { ...defaults, consents }, { merge: true });
  });
}

/** 現行の規約の情報。無ければ既定値で作り、4項目のどれかが欠けていれば既定値を使う。 */
async function currentConfig(db: Firestore): Promise<Record<string, unknown>> {
  const ref = db.doc("app_config/legal");
  const data = (await ref.get()).data();
  if (data === undefined) {
    try {
      await ref.create({ ...DEFAULT_LEGAL_CONFIG });
    } catch (e) {
      // 同時に作られた場合はその値を読み直す
      if ((e as { code?: number }).code !== ALREADY_EXISTS) throw e;
      return complete((await ref.get()).data());
    }
    return { ...DEFAULT_LEGAL_CONFIG };
  }
  return complete(data);
}

function complete(data: Record<string, unknown> | undefined): Record<string, unknown> {
  const keys = Object.keys(DEFAULT_LEGAL_CONFIG);
  const ok = data !== undefined &&
    keys.every((k) => typeof data[k] === "string" && (data[k] as string).trim() !== "");
  return ok ? data : { ...DEFAULT_LEGAL_CONFIG };
}

/** terms・privacy のどちらか1つ以上が、空白だけでない文字列であること。 */
function parseInput(input: unknown): AcceptLegalInput {
  if (typeof input !== "object" || input === null) {
    throw new HttpsError("invalid-argument", "同意する文書の版数が必要です");
  }
  const raw = input as Record<string, unknown>;
  const versions: AcceptLegalInput = {};
  for (const document of DOCUMENTS) {
    const value = raw[document];
    if (value === undefined) continue;
    if (typeof value !== "string" || value.trim() === "") {
      throw new HttpsError("invalid-argument", `${document} の版数が不正です`);
    }
    versions[document] = value;
  }
  if (versions.terms === undefined && versions.privacy === undefined) {
    throw new HttpsError("invalid-argument", "同意する文書の版数が必要です");
  }
  return versions;
}
