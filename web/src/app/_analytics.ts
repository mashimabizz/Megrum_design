/**
 * 計測境界（notes/82 §6-1）
 *
 * ⚠️ Vercel Analytics 本体はまだ配線しない。プライバシーポリシーへ
 * 「アクセス解析を利用する」旨を追記し、外部サービス台帳へ記載してから
 * 有効化する（notes/82 §8・§12-3、notes/63 の「未説明の外部解析」No-Go）。
 *
 * それまで `track()` は本番では何もしない。ページ側は先にこの境界を
 * 呼んでおき、配線が済んだ時点で本ファイルだけを差し替える。
 */

/** 固定イベント名（notes/82 §6-1）。ここ以外で文字列を直書きしない。 */
export type AnalyticsEvent =
  | "cta_app_store_click"
  | "cta_x_follow_click"
  | "feature_detail_click"
  | "article_open"
  | "article_related_click"
  | "article_cta_click";

/** イベントに添えるプロパティ（placement / page_path / campaign など）。 */
export type AnalyticsProps = Record<string, string>;

/**
 * 計測イベントの唯一の入口。
 * TODO(§12-3): Privacy 追記＋外部サービス台帳への記載が済んだら、ここから
 * `@vercel/analytics` の `track()` を呼ぶよう差し替える（依存追加もそのとき）。
 */
export function track(event: AnalyticsEvent, props: AnalyticsProps = {}): void {
  if (process.env.NODE_ENV !== "production") {
    console.debug("[analytics:noop]", event, props);
  }
  // 本番では意図的に no-op（外部解析タグを未説明のまま読み込まないため）。
}

/**
 * ストア/外部URL へ流入元識別トークンを付与する（notes/82 §6-1）。
 * X・記事・PR・店舗QR・トップ・機能ページを区別できるようにする。
 * href が空文字なら空文字のまま返す（未確定URLの安全側フォールバック）。
 */
export function withCampaign(
  href: string,
  params: { source: string; campaign?: string },
): string {
  if (!href) return href;
  try {
    const url = new URL(href);
    url.searchParams.set("utm_source", params.source);
    if (params.campaign) url.searchParams.set("utm_campaign", params.campaign);
    return url.toString();
  } catch {
    return href;
  }
}
