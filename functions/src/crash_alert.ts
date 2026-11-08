/**
 * Crashlytics のアラートを、日本語の文面で Slack に送る。
 * 仕様: docs/detailed_design/crash_reporting/crash_reporting.md 2.4・2.5・6.2
 */

/** アラートの種類。 */
export type CrashAlertKind = "newFatal" | "newNonfatal" | "regression" | "velocity";

/** 関数が受け取るアラートの値（Crashlytics のアラートの payload から取り出したもの）。 */
export interface CrashAlertInput {
  kind: CrashAlertKind;
  /** 関数が動いているプロジェクト ID */
  projectId?: string;
  /** Firebase のアプリ ID（iOS は `:ios:`、Android は `:android:` を含む） */
  appId?: string;
  issue?: { title?: string; subtitle?: string; appVersion?: string };
  /** 再発のみ。解決済みにした日時（ISO8601） */
  resolveTime?: string;
  /** 急増のみ */
  crashCount?: number;
  crashPercentage?: number;
  firstVersion?: string;
}

/** Slack への POST。テストでは差し替える。 */
export type FetchLike = (
  url: string,
  init: { method: string; headers: Record<string, string>; body: string },
) => Promise<{ status: number }>;

const UNKNOWN = "（不明）";

const HEADLINES: Record<CrashAlertKind, string> = {
  newFatal: "新しいクラッシュが発生しました",
  newNonfatal: "新しい非致命的エラーが記録されました",
  regression: "解決済みのクラッシュが再発しました",
  velocity: "クラッシュが急増しています",
};

const ENVIRONMENTS: Record<string, string> = {
  "word-pods-prod": "本番",
  "word-pods-dev": "開発",
};

/**
 * 文面に入れる値の加工。改行を半角スペースにし、Slack の書式の記号（`& < >`）を置き換える。
 * 値が無い・空・空白だけなら「（不明）」。
 */
export function sanitize(value: unknown): string {
  if (value === undefined || value === null) return UNKNOWN;
  const text = String(value)
    .replace(/\r\n|\n|\r/g, " ")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
  return text.trim() === "" ? UNKNOWN : text;
}

/** 環境の表示（「【本番】」など）。 */
export function environmentLabel(projectId: string | undefined): string {
  if (!projectId) return "【不明】";
  return `【${ENVIRONMENTS[projectId] ?? sanitize(projectId)}】`;
}

/** OS の表示。 */
export function platformLabel(appId: string | undefined): string {
  if (appId?.includes(":ios:")) return "iOS";
  if (appId?.includes(":android:")) return "Android";
  return "不明";
}

/** 割合を小数第1位まで（第2位で四捨五入・ちょうど半分は切り上げ）にし、末尾の「.0」は書かない。 */
export function formatPercentage(value: number | undefined): string {
  if (typeof value !== "number" || !Number.isFinite(value)) return UNKNOWN;
  // 2進数の誤差で 1.15 が 1.1 に丸められないよう、10進の文字列で桁をずらしてから丸める
  const rounded = Math.round(Number(`${value.toFixed(10)}e1`));
  return String(Number(`${rounded}e-1`));
}

/** 件数を桁区切りなしで書く。 */
export function formatCount(value: number | undefined): string {
  if (typeof value !== "number" || !Number.isFinite(value)) return UNKNOWN;
  return String(value);
}

/**
 * 解決済みにした日時を、日本時間の「YYYY/MM/DD HH:mm（日本時間）」にする（秒は切り捨て）。
 * 値が無い・読めない・タイムゾーンが書かれていない場合は「不明」（動く環境で解釈が変わるため）。
 */
export function formatResolveTime(value: string | undefined): string {
  if (!value || !/(Z|[+-]\d{2}:?\d{2})$/i.test(value)) return "不明";
  const time = Date.parse(value);
  if (Number.isNaN(time)) return "不明";
  const jst = new Date(time + 9 * 60 * 60 * 1000);
  const pad = (n: number) => String(n).padStart(2, "0");
  return (
    `${jst.getUTCFullYear()}/${pad(jst.getUTCMonth() + 1)}/${pad(jst.getUTCDate())} ` +
    `${pad(jst.getUTCHours())}:${pad(jst.getUTCMinutes())}（日本時間）`
  );
}

/** Slack に送る本文を組み立てる。 */
export function buildSlackText(input: CrashAlertInput): string {
  const issue = input.issue ?? {};
  const lines = [
    `${environmentLabel(input.projectId)}${HEADLINES[input.kind]}`,
    `問題: ${sanitize(issue.title)}`,
    `発生箇所: ${sanitize(issue.subtitle)}`,
    `アプリ: ${platformLabel(input.appId)} ${sanitize(issue.appVersion)}`,
  ];
  if (input.kind === "regression") {
    lines.push(`解決済みにした日時: ${formatResolveTime(input.resolveTime)}`);
  }
  if (input.kind === "velocity") {
    lines.push(
      `件数: ${formatCount(input.crashCount)}件（${formatPercentage(input.crashPercentage)}%）`,
    );
    lines.push(`最初に起きたバージョン: ${sanitize(input.firstVersion)}`);
  }
  const link = input.projectId
    ? `https://console.firebase.google.com/project/${input.projectId}/crashlytics`
    : UNKNOWN;
  lines.push(`詳細: ${link}`);
  return lines.join("\n");
}

/**
 * 本文 [text] を Slack の Incoming Webhook [webhookUrl] に1回だけ POST する。
 * 200〜299 以外・接続の失敗はエラーにする。Webhook URL は秘密情報のため、エラーの内容に含めない。
 */
export async function postToSlack(
  webhookUrl: string | undefined,
  text: string,
  fetchFn: FetchLike,
): Promise<void> {
  if (!webhookUrl) {
    throw new Error("SLACK_WEBHOOK_URL が登録されていません");
  }
  let status: number;
  try {
    ({ status } = await fetchFn(webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text }),
    }));
  } catch {
    // 接続の例外のメッセージには URL が含まれることがあるため、元のメッセージは載せない
    throw new Error("Slack への接続に失敗しました");
  }
  if (status < 200 || status > 299) {
    throw new Error(`Slack への送信に失敗しました（HTTP ${status}）`);
  }
}

/** アラートを Slack に送る。 */
export async function notifyCrashAlert(
  input: CrashAlertInput,
  webhookUrl: string | undefined,
  fetchFn: FetchLike,
): Promise<void> {
  await postToSlack(webhookUrl, buildSlackText(input), fetchFn);
}
