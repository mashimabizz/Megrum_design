/**
 * 公開サイトの単一設定ソース（notes/82 §6・§8）
 *
 * CTA の URL / ラベル / 公開フェーズ、ナビ、サイト定数、メタデータ生成を
 * ここに集約する。ページごとに App Store ID や公式X URL を直書きしない
 * （notes/82 §10「CTA URL・ラベル・フェーズが1設定に集約」）。
 */
import type { Metadata } from "next";
import type { AnalyticsEvent } from "./_analytics";

// ── サイト定数 ───────────────────────────────────────────────
export const SITE_URL = "https://megrum.jp";
export const CONTACT_EMAIL = "support@megrum.jp";
export const OFFICE_ADDRESS_LINES = [
  "〒530-0001",
  "大阪府大阪市北区梅田1丁目2番2号",
  "大阪駅前第2ビル12-12",
];

// ── 外部リンク（要オーナー確定：notes/82 §12） ─────────────────
// TODO(owner): 実際の公式Xハンドルへ差し替え。v1 の主CTA先。
export const X_URL = "https://x.com/megrum_jp"; // ⚠️ 仮ハンドル。確定まで本番デプロイしない
// TODO(owner): App Store 公開後に ID を設定（Smart App Banner / DLバッジで使用）。
export const APP_STORE_ID = ""; // 例: "1234567890"
export const APP_STORE_URL = APP_STORE_ID
  ? `https://apps.apple.com/jp/app/megrum/id${APP_STORE_ID}`
  : "";

// ── 公開フェーズ（notes/82 §6） ───────────────────────────────
// v1   : ソフトローンチ前。主CTA=公式Xフォローのみ
// v1_1 : ソフトローンチ後。主CTA=App Store DLバッジ
// v2   : 正式ローンチ。社会的証明を追加
export type LaunchPhase = "v1" | "v1_1" | "v2";
export const LAUNCH_PHASE: LaunchPhase = "v1";

// ── 主CTA（フェーズ連動・全ページ共通） ───────────────────────
export type CtaKind = "x_follow" | "app_store";
export interface CtaConfig {
  kind: CtaKind;
  label: string;
  sublabel: string;
  href: string;
  event: AnalyticsEvent;
  external: boolean;
}

/** 現在の公開フェーズに応じた主CTA。href 未確定なら空文字（CTA側で非表示）。 */
export function primaryCta(): CtaConfig {
  if (LAUNCH_PHASE === "v1") {
    return {
      kind: "x_follow",
      label: "公式Xをフォロー",
      sublabel: "リリース情報・安全な交換のコツを発信中",
      href: X_URL,
      event: "cta_x_follow_click",
      external: true,
    };
  }
  return {
    kind: "app_store",
    label: "App Store でダウンロード",
    sublabel: "iOS先行（Androidは検討中）",
    href: APP_STORE_URL,
    event: "cta_app_store_click",
    external: true,
  };
}

// ── ナビ（notes/82 §5・§4-9） ─────────────────────────────────
// enabled=false のページは未実装（T2〜で実装時に true にする）。
// 未実装ページへのリンク切れを避けるため、描画時に enabled のみ出す。
export interface NavItem {
  href: string;
  label: string;
  enabled: boolean;
}

export const HEADER_NAV: NavItem[] = [
  { href: "/features", label: "機能", enabled: false },
  { href: "/safety", label: "安全", enabled: false },
  { href: "/articles", label: "記事", enabled: false },
  { href: "/faq", label: "FAQ", enabled: false },
];

export const FOOTER_NAV: NavItem[] = [
  { href: "/features", label: "機能紹介", enabled: false },
  { href: "/articles", label: "記事", enabled: false },
  { href: "/safety", label: "安全への取り組み", enabled: false },
  { href: "/terms", label: "利用規約", enabled: true },
  { href: "/privacy", label: "プライバシーポリシー", enabled: true },
  { href: "/support", label: "サポート", enabled: true },
  { href: "/operator", label: "運営者情報", enabled: true },
];

// ── メタデータ生成（notes/82 §8） ─────────────────────────────
export interface PageMetaInput {
  title?: string; // 未指定なら layout の default/template を使う
  description: string;
  path: string; // 先頭 "/" 始まり。canonical/OG に使う
  ogImage?: string; // 未指定なら layout の既定OG画像
}

/** ページ固有の title/description/canonical/OG/Twitter を生成する。 */
export function buildMetadata({
  title,
  description,
  path,
  ogImage,
}: PageMetaInput): Metadata {
  const url = `${SITE_URL}${path}`;
  return {
    ...(title ? { title } : {}),
    description,
    alternates: { canonical: path },
    openGraph: {
      ...(title ? { title } : {}),
      description,
      url,
      type: "website",
      ...(ogImage ? { images: [{ url: ogImage }] } : {}),
    },
    twitter: {
      card: "summary_large_image",
      ...(title ? { title } : {}),
      description,
    },
  };
}

// ── 構造化データ（notes/82 §8） ───────────────────────────────
/**
 * SoftwareApplication（アプリ本体）。price=0 は「無料でダウンロードできる」意。
 * 有料機能（Megrum Plus）はアプリ内課金であり本スキーマの price とは別軸。
 */
export function softwareApplicationJsonLd(): Record<string, unknown> {
  return {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: "Megrum",
    applicationCategory: "LifestyleApplication",
    operatingSystem: "iOS",
    url: SITE_URL,
    description:
      "推し活グッズの交換アプリ。譲・求のシェア画像づくりから、条件の合う相手探し、現地交換・郵送交換までを支えます。",
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "JPY",
    },
  };
}
