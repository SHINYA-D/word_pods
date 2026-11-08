import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import * as functionsV1 from "firebase-functions/v1";
import {
  CrashlyticsEvent,
  onNewFatalIssuePublished,
  onNewNonfatalIssuePublished,
  onRegressionAlertPublished,
  onVelocityAlertPublished,
} from "firebase-functions/v2/alerts/crashlytics";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { acceptLegal as recordLegalConsent } from "./accept_legal";
import { CrashAlertInput, notifyCrashAlert } from "./crash_alert";
import { createAccountDoc } from "./create_account";
import { deleteUserAccount, isRecentLogin } from "./delete_account";

initializeApp();

/**
 * 退会。呼び出したユーザー本人（ログイン情報の uid）のデータとアカウントを削除する。
 * 最後にログイン（本人確認）してから5分を超えていたら、何も削除せずに failed-precondition で失敗する
 * （アプリは本人確認をし直して呼び直す）。
 * アプリ側のリージョン指定（lib/core/di/firebase_providers.dart）と合わせる。
 * App Check の証明が無い呼び出し（アプリ以外からの呼び出し）は、関数に届く前に断られる（lib/main.dart）。
 */
export const deleteAccount = onCall(
  { region: "asia-northeast1", timeoutSeconds: 300, enforceAppCheck: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "ログインが必要です");
    }
    if (!isRecentLogin(request.auth?.token.auth_time, Date.now())) {
      throw new HttpsError("failed-precondition", "本人確認をし直してください");
    }
    await deleteUserAccount(uid, getFirestore(), getAuth());
    return { ok: true };
  },
);

/**
 * 利用規約・プライバシーポリシーへの同意。呼び出したユーザー本人（ログイン情報の uid）の同意を記録する。
 * 版数が現行と違えば failed-precondition で失敗する（docs/high_level_design/legal_consent.md）。
 * App Check の証明が無い呼び出しは、関数に届く前に断られる。
 */
export const acceptLegal = onCall(
  { region: "asia-northeast1", enforceAppCheck: true },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "ログインが必要です");
    }
    await recordLegalConsent(uid, request.data, getFirestore());
    return { ok: true };
  },
);

/**
 * 新規登録。Authentication にユーザーが作られたら accounts/{uid} に isDeveloper: false と createdAt（ユーザーの作成日時）をそろえる。
 * 同意の関数が先にドキュメントを作っていても、足りないフィールドだけを補う。
 * メール登録・Google 登録のどちらでも動く。
 * v2 の beforeUserCreated は Identity Platform へのアップグレードが要るため、v1 のトリガーを使う。
 */
export const onAuthUserCreated = functionsV1
  .region("asia-northeast1")
  .auth.user()
  .onCreate(async (user) => {
    await createAccountDoc(user.uid, getFirestore(), new Date(user.metadata.creationTime));
  });

/**
 * Crashlytics のアラート（新しいクラッシュ・新しい非致命的エラー・再発・急増）を Slack に送る
 * （docs/high_level_design/crash_reporting.md）。
 * 送り先の Webhook URL は Secret Manager の SLACK_WEBHOOK_URL に、開発・本番のプロジェクトごとに登録する
 * （開発は #word-pods-app-alert-dev、本番は #word-pods-app-alert-prod）。
 * 送信に失敗したら関数をエラーで終わらせる（Cloud Logging に残る）。再送はしない。
 */
const slackWebhookUrl = defineSecret("SLACK_WEBHOOK_URL");

const sendCrashAlert = (
  event: CrashlyticsEvent<unknown>,
  input: Omit<CrashAlertInput, "projectId" | "appId">,
) =>
  notifyCrashAlert(
    { ...input, projectId: process.env.GCLOUD_PROJECT, appId: event.appId },
    slackWebhookUrl.value(),
    (url, init) => fetch(url, init),
  );

export const notifyNewFatalIssue = onNewFatalIssuePublished(
  { region: "asia-northeast1", secrets: [slackWebhookUrl] },
  (event) =>
    sendCrashAlert(event, { kind: "newFatal", issue: event.data.payload.issue }),
);

export const notifyNewNonfatalIssue = onNewNonfatalIssuePublished(
  { region: "asia-northeast1", secrets: [slackWebhookUrl] },
  (event) =>
    sendCrashAlert(event, { kind: "newNonfatal", issue: event.data.payload.issue }),
);

export const notifyRegression = onRegressionAlertPublished(
  { region: "asia-northeast1", secrets: [slackWebhookUrl] },
  (event) =>
    sendCrashAlert(event, {
      kind: "regression",
      issue: event.data.payload.issue,
      resolveTime: event.data.payload.resolveTime,
    }),
);

export const notifyVelocity = onVelocityAlertPublished(
  { region: "asia-northeast1", secrets: [slackWebhookUrl] },
  (event) =>
    sendCrashAlert(event, {
      kind: "velocity",
      issue: event.data.payload.issue,
      crashCount: event.data.payload.crashCount,
      crashPercentage: event.data.payload.crashPercentage,
      firstVersion: event.data.payload.firstVersion,
    }),
);
