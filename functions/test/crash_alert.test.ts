// 仕様: docs/detailed_design/crash_reporting/crash_reporting.md 6.2（CRS-S01〜S45）
// Slack には実際には送らず、POST を差し替えて回数・宛先・本文を確かめる。
import { CrashAlertInput, FetchLike, notifyCrashAlert } from "../src/crash_alert";

const URL = "https://hooks.slack.com/services/T/B/X";
const IOS_APP = "1:707895340348:ios:450ada432e1ac1d5aac239";
const ISSUE = {
  title: "StateError",
  subtitle: "word_list_page.dart line 42",
  appVersion: "1.2.0 (5)",
};

interface Call {
  url: string;
  init: { method: string; headers: Record<string, string>; body: string };
}

/** 状態コード [status] を返す POST。呼び出しを記録する。 */
function fakeFetch(status = 200): { fetch: FetchLike; calls: Call[] } {
  const calls: Call[] = [];
  return {
    calls,
    fetch: async (url, init) => {
      calls.push({ url, init });
      return { status };
    },
  };
}

function input(overrides: Partial<CrashAlertInput> = {}): CrashAlertInput {
  return {
    kind: "newFatal",
    projectId: "word-pods-prod",
    appId: IOS_APP,
    issue: { ...ISSUE },
    ...overrides,
  };
}

/** 送信に成功させ、送った本文の行を返す。 */
async function sentLines(alert: CrashAlertInput): Promise<string[]> {
  const { fetch, calls } = fakeFetch();
  await notifyCrashAlert(alert, URL, fetch);
  expect(calls).toHaveLength(1);
  return (JSON.parse(calls[0].init.body) as { text: string }).text.split("\n");
}

const PROD_LINK = "詳細: https://console.firebase.google.com/project/word-pods-prod/crashlytics";

describe("新しいクラッシュのアラート", () => {
  it("CRS-S01 新しいクラッシュのアラートを受けた場合、5行の本文を JSON で1回 POST して正常に終わる", async () => {
    const { fetch, calls } = fakeFetch();
    await expect(notifyCrashAlert(input(), URL, fetch)).resolves.toBeUndefined();
    expect(calls).toHaveLength(1);
    expect(calls[0].url).toBe(URL);
    expect(calls[0].init.method).toBe("POST");
    expect(calls[0].init.headers["Content-Type"]).toBe("application/json");
    const body = JSON.parse(calls[0].init.body);
    expect(Object.keys(body)).toEqual(["text"]);
    expect(body.text.split("\n")).toEqual([
      "【本番】新しいクラッシュが発生しました",
      "問題: StateError",
      "発生箇所: word_list_page.dart line 42",
      "アプリ: iOS 1.2.0 (5)",
      PROD_LINK,
    ]);
  });

  it("CRS-S04 プロジェクトが word-pods-dev の場合、1行目が【開発】で詳細のリンクが開発のプロジェクトになる", async () => {
    const lines = await sentLines(input({ projectId: "word-pods-dev" }));
    expect(lines[0]).toBe("【開発】新しいクラッシュが発生しました");
    expect(lines[4]).toBe(
      "詳細: https://console.firebase.google.com/project/word-pods-dev/crashlytics",
    );
  });

  it("CRS-S05 知らないプロジェクト ID の場合、1行目にそのプロジェクト ID が【】付きで入る", async () => {
    const lines = await sentLines(input({ projectId: "demo-word-pods" }));
    expect(lines[0]).toBe("【demo-word-pods】新しいクラッシュが発生しました");
  });

  it("CRS-S27 プロジェクト ID が無い場合、1行目が【不明】になる", async () => {
    const lines = await sentLines(input({ projectId: undefined }));
    expect(lines[0]).toBe("【不明】新しいクラッシュが発生しました");
  });

  it("CRS-S33 プロジェクト ID が空文字の場合、1行目が【不明】になる", async () => {
    const lines = await sentLines(input({ projectId: "" }));
    expect(lines[0]).toBe("【不明】新しいクラッシュが発生しました");
  });

  it("CRS-S06 Android のアプリ ID の場合、4行目の OS が Android になる", async () => {
    const lines = await sentLines(
      input({ appId: "1:707895340348:android:e60f090fcff338c8aac239" }),
    );
    expect(lines[3]).toBe("アプリ: Android 1.2.0 (5)");
  });

  it("CRS-S07 iOS でも Android でもないアプリ ID の場合、4行目の OS が不明になる", async () => {
    const lines = await sentLines(input({ appId: "1:707895340348:web:abc" }));
    expect(lines[3]).toBe("アプリ: 不明 1.2.0 (5)");
  });

  it("CRS-S41 アプリ ID が無い場合、4行目の OS が不明になる", async () => {
    const lines = await sentLines(input({ appId: undefined }));
    expect(lines[3]).toBe("アプリ: 不明 1.2.0 (5)");
  });

  it("CRS-S08 問題名に < > & を含む場合、Slack の書式の記号に置き換わる", async () => {
    const lines = await sentLines(input({ issue: { ...ISSUE, title: "a<b>&c" } }));
    expect(lines[1]).toBe("問題: a&lt;b&gt;&amp;c");
  });

  it("CRS-S09 発生箇所が <!channel> の場合、チャンネル全員への呼び出しにならない文字に置き換わる", async () => {
    const lines = await sentLines(input({ issue: { ...ISSUE, subtitle: "<!channel>" } }));
    expect(lines[2]).toBe("発生箇所: &lt;!channel&gt;");
  });

  it("CRS-S20 アプリのバージョンに < > を含む場合、置き換わる", async () => {
    const lines = await sentLines(input({ issue: { ...ISSUE, appVersion: "1.0<b>" } }));
    expect(lines[3]).toBe("アプリ: iOS 1.0&lt;b&gt;");
  });

  it("CRS-S22 問題名が &lt; の場合、& が二重に置き換わり &amp;lt; になる", async () => {
    const lines = await sentLines(input({ issue: { ...ISSUE, title: "&lt;" } }));
    expect(lines[1]).toBe("問題: &amp;lt;");
  });

  it("CRS-S23 問題名の途中に改行を含む場合、本文は5行のままで改行が空白になる", async () => {
    const lines = await sentLines(input({ issue: { ...ISSUE, title: "a\nb" } }));
    expect(lines).toHaveLength(5);
    expect(lines[1]).toBe("問題: a b");
  });

  it("CRS-S24 発生箇所が空文字の場合、（不明）になる", async () => {
    const lines = await sentLines(input({ issue: { ...ISSUE, subtitle: "" } }));
    expect(lines[2]).toBe("発生箇所: （不明）");
  });

  it("CRS-S34 問題名が無い場合、（不明）になる", async () => {
    const lines = await sentLines(input({ issue: { ...ISSUE, title: undefined } }));
    expect(lines[1]).toBe("問題: （不明）");
  });

  it("CRS-S35 アプリのバージョンが空文字の場合、（不明）になる", async () => {
    const lines = await sentLines(input({ issue: { ...ISSUE, appVersion: "" } }));
    expect(lines[3]).toBe("アプリ: iOS （不明）");
  });

  it("CRS-S40 発生箇所が無い場合、（不明）になる", async () => {
    const lines = await sentLines(input({ issue: { ...ISSUE, subtitle: undefined } }));
    expect(lines[2]).toBe("発生箇所: （不明）");
  });

  it("CRS-S44 問題名が全角・半角スペースだけの場合、（不明）になる", async () => {
    const lines = await sentLines(input({ issue: { ...ISSUE, title: "　 " } }));
    expect(lines[1]).toBe("問題: （不明）");
  });

  it("CRS-S39 Slack が HTTP 204 を返した場合、POST は1回で正常に終わる", async () => {
    const { fetch, calls } = fakeFetch(204);
    await expect(notifyCrashAlert(input(), URL, fetch)).resolves.toBeUndefined();
    expect(calls).toHaveLength(1);
  });

  it("CRS-S10 Slack が HTTP 500 を返した場合、POST は1回だけでエラーで終わる", async () => {
    const { fetch, calls } = fakeFetch(500);
    await expect(notifyCrashAlert(input(), URL, fetch)).rejects.toThrow();
    expect(calls).toHaveLength(1);
  });

  it("CRS-S18 Slack が HTTP 404 を返した場合、POST は1回だけでエラーで終わる", async () => {
    const { fetch, calls } = fakeFetch(404);
    await expect(notifyCrashAlert(input(), URL, fetch)).rejects.toThrow();
    expect(calls).toHaveLength(1);
  });

  it("CRS-S11 Slack への接続に失敗した場合、POST は1回だけでエラーで終わる", async () => {
    let count = 0;
    const fetch: FetchLike = async () => {
      count++;
      throw new Error("connect ECONNREFUSED");
    };
    await expect(notifyCrashAlert(input(), URL, fetch)).rejects.toThrow();
    expect(count).toBe(1);
  });

  it("CRS-S12 Webhook URL が空文字の場合、POST せずにエラーで終わる", async () => {
    const { fetch, calls } = fakeFetch();
    await expect(notifyCrashAlert(input(), "", fetch)).rejects.toThrow();
    expect(calls).toHaveLength(0);
  });

  it("CRS-S19 Webhook URL が登録されていない場合、POST せずにエラーで終わる", async () => {
    const { fetch, calls } = fakeFetch();
    await expect(notifyCrashAlert(input(), undefined, fetch)).rejects.toThrow();
    expect(calls).toHaveLength(0);
  });

  it("CRS-S29 Slack が HTTP 500 を返した場合、エラーのメッセージに Webhook URL を含まない", async () => {
    const { fetch } = fakeFetch(500);
    const error = await notifyCrashAlert(input(), URL, fetch).catch((e: Error) => e);
    expect(error).toBeInstanceOf(Error);
    expect((error as Error).message).not.toContain(URL);
  });

  it("CRS-S30 接続の例外のメッセージに Webhook URL が含まれていても、関数のエラーには含まない", async () => {
    const fetch: FetchLike = async () => {
      throw new Error(`request to ${URL} failed`);
    };
    const error = await notifyCrashAlert(input(), URL, fetch).catch((e: Error) => e);
    expect(error).toBeInstanceOf(Error);
    expect((error as Error).message).not.toContain(URL);
  });
});

describe("再発のアラート", () => {
  const regression = (resolveTime?: string) =>
    input({ kind: "regression", issue: { ...ISSUE, appVersion: "1.2.1 (6)" }, resolveTime });

  it("CRS-S02 再発のアラートを受けた場合、解決済みにした日時を日本時間で入れた6行を送る", async () => {
    const lines = await sentLines(regression("2026-11-01T01:00:00Z"));
    expect(lines).toEqual([
      "【本番】解決済みのクラッシュが再発しました",
      "問題: StateError",
      "発生箇所: word_list_page.dart line 42",
      "アプリ: iOS 1.2.1 (6)",
      "解決済みにした日時: 2026/11/01 10:00（日本時間）",
      PROD_LINK,
    ]);
  });

  it("CRS-S16 日本時間で日付が変わる日時の場合、翌日の日付になり秒は切り捨てる", async () => {
    const lines = await sentLines(regression("2026-11-01T15:30:59Z"));
    expect(lines[4]).toBe("解決済みにした日時: 2026/11/02 00:30（日本時間）");
  });

  it("CRS-S17 日時として読めない値の場合、不明になり正常に終わる", async () => {
    const lines = await sentLines(regression("abc"));
    expect(lines[4]).toBe("解決済みにした日時: 不明");
  });

  it("CRS-S36 日時が無い場合、不明になり正常に終わる", async () => {
    const lines = await sentLines(regression(undefined));
    expect(lines[4]).toBe("解決済みにした日時: 不明");
  });

  it("CRS-S37 タイムゾーンの無い日時の場合、不明になる", async () => {
    const lines = await sentLines(regression("2026-11-01T01:00:00"));
    expect(lines[4]).toBe("解決済みにした日時: 不明");
  });

  it("CRS-S38 +09:00 付きの日時の場合、そのまま日本時間で入る", async () => {
    const lines = await sentLines(regression("2026-11-01T10:00:00+09:00"));
    expect(lines[4]).toBe("解決済みにした日時: 2026/11/01 10:00（日本時間）");
  });

  it("CRS-S13 再発のアラートで Slack が HTTP 500 を返した場合、POST は1回だけでエラーで終わる", async () => {
    const { fetch, calls } = fakeFetch(500);
    await expect(notifyCrashAlert(regression("2026-11-01T01:00:00Z"), URL, fetch)).rejects.toThrow();
    expect(calls).toHaveLength(1);
  });
});

describe("急増のアラート", () => {
  const velocity = (overrides: Partial<CrashAlertInput> = {}) =>
    input({
      kind: "velocity",
      issue: { ...ISSUE, appVersion: "1.2.1 (6)" },
      crashCount: 120,
      crashPercentage: 1.5,
      firstVersion: "1.2.0 (5)",
      ...overrides,
    });

  it("CRS-S03 急増のアラートを受けた場合、件数・割合・最初のバージョンを入れた7行を送る", async () => {
    const lines = await sentLines(velocity());
    expect(lines).toEqual([
      "【本番】クラッシュが急増しています",
      "問題: StateError",
      "発生箇所: word_list_page.dart line 42",
      "アプリ: iOS 1.2.1 (6)",
      "件数: 120件（1.5%）",
      "最初に起きたバージョン: 1.2.0 (5)",
      PROD_LINK,
    ]);
  });

  it("CRS-S21 最初のバージョンに < > を含む場合、置き換わる", async () => {
    const lines = await sentLines(velocity({ firstVersion: "1.0<b>" }));
    expect(lines[5]).toBe("最初に起きたバージョン: 1.0&lt;b&gt;");
  });

  it("CRS-S25 割合が整数の場合、末尾の .0 を書かない", async () => {
    const lines = await sentLines(velocity({ crashPercentage: 2 }));
    expect(lines[4]).toBe("件数: 120件（2%）");
  });

  it("CRS-S26 件数が4桁の場合、桁区切りを付けない", async () => {
    const lines = await sentLines(velocity({ crashCount: 1234 }));
    expect(lines[4]).toBe("件数: 1234件（1.5%）");
  });

  it("CRS-S31 割合の小数が長い場合、小数第1位までにする", async () => {
    const lines = await sentLines(velocity({ crashPercentage: 1.5384615384615385 }));
    expect(lines[4]).toBe("件数: 120件（1.5%）");
  });

  it("CRS-S32 割合がとても小さい場合、0 になる", async () => {
    const lines = await sentLines(velocity({ crashPercentage: 0.0000001 }));
    expect(lines[4]).toBe("件数: 120件（0%）");
  });

  it("CRS-S45 割合の小数第2位がちょうど5の場合、切り上げる", async () => {
    const lines = await sentLines(velocity({ crashPercentage: 1.25 }));
    expect(lines[4]).toBe("件数: 120件（1.3%）");
  });

  it("CRS-S42 最初のバージョンが無い場合、（不明）になる", async () => {
    const lines = await sentLines(velocity({ firstVersion: undefined }));
    expect(lines[5]).toBe("最初に起きたバージョン: （不明）");
  });

  it("CRS-S43 件数と割合が無い場合、どちらも（不明）になる", async () => {
    const lines = await sentLines(
      velocity({ crashCount: undefined, crashPercentage: undefined }),
    );
    expect(lines[4]).toBe("件数: （不明）件（（不明）%）");
  });

  it("CRS-S14 急増のアラートで Slack が HTTP 500 を返した場合、POST は1回だけでエラーで終わる", async () => {
    const { fetch, calls } = fakeFetch(500);
    await expect(notifyCrashAlert(velocity(), URL, fetch)).rejects.toThrow();
    expect(calls).toHaveLength(1);
  });
});

describe("新しい非致命的エラーのアラート", () => {
  const nonfatal = () =>
    input({
      kind: "newNonfatal",
      issue: {
        title: "FormatException",
        subtitle: "settings_repository_impl.dart line 36",
        appVersion: "1.2.0 (5)",
      },
    });

  it("CRS-S15 新しい非致命的エラーのアラートを受けた場合、5行の本文を1回 POST する", async () => {
    const lines = await sentLines(nonfatal());
    expect(lines).toEqual([
      "【本番】新しい非致命的エラーが記録されました",
      "問題: FormatException",
      "発生箇所: settings_repository_impl.dart line 36",
      "アプリ: iOS 1.2.0 (5)",
      PROD_LINK,
    ]);
  });

  it("CRS-S28 新しい非致命的エラーのアラートで Slack が HTTP 500 を返した場合、POST は1回だけでエラーで終わる", async () => {
    const { fetch, calls } = fakeFetch(500);
    await expect(notifyCrashAlert(nonfatal(), URL, fetch)).rejects.toThrow();
    expect(calls).toHaveLength(1);
  });
});
