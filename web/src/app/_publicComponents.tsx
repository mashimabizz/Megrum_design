import Image from "next/image";
import Link from "next/link";
import type { ReactNode } from "react";

import { PrimaryCta } from "./_cta";
import {
  CONTACT_EMAIL,
  FOOTER_NAV,
  HEADER_NAV,
  OFFICE_ADDRESS_LINES,
  routeEnabled,
  SITE_URL,
} from "./_siteConfig";

// 既存ページ（robots/sitemap/operator/terms/privacy/support）の import 互換を維持。
// 実体は _siteConfig に集約し、ここからは再エクスポートする。
export { SITE_URL, CONTACT_EMAIL, OFFICE_ADDRESS_LINES };

export function SiteHeader() {
  const navItems = HEADER_NAV.filter((item) => item.enabled);
  return (
    <header className="absolute left-0 right-0 top-0 z-30">
      <div className="mx-auto flex w-full max-w-6xl items-center justify-between gap-4 px-5 py-5">
        <Link href="/" className="flex items-center gap-3 text-slate-950">
          <Image
            src="/site-assets/megrum-icon.png"
            alt="Megrum"
            width={44}
            height={44}
            className="h-11 w-11 rounded-xl shadow-[0_10px_28px_rgba(166,149,216,0.24)]"
            priority
          />
          <span className="font-[var(--font-inter-tight)] text-[22px] font-extrabold tracking-normal">
            Megrum
          </span>
        </Link>
        <div className="flex items-center gap-3">
          {navItems.length > 0 && (
            <nav className="hidden items-center gap-1 rounded-full border border-white/70 bg-white/80 px-2 py-2 shadow-[0_12px_36px_rgba(58,50,74,0.08)] backdrop-blur sm:flex">
              {navItems.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="rounded-full px-3 py-2 text-[12px] font-bold text-slate-700 transition hover:bg-megrum-lavender/10 hover:text-violet-700"
                >
                  {item.label}
                </Link>
              ))}
            </nav>
          )}
          {/* 主CTAはモバイルでも常に到達可能にする（notes/82 §5） */}
          <PrimaryCta placement="header" size="sm" />
        </div>
      </div>
    </header>
  );
}

export function SiteFooter() {
  const links = FOOTER_NAV.filter((item) => item.enabled);
  return (
    <footer className="border-t border-slate-200 bg-white">
      <div className="mx-auto grid w-full max-w-6xl gap-8 px-5 py-10 md:grid-cols-[1.2fr_1fr]">
        <div>
          <div className="flex items-center gap-3">
            <Image
              src="/site-assets/megrum-icon.png"
              alt=""
              width={40}
              height={40}
              className="h-10 w-10 rounded-xl"
            />
            <div>
              <p className="font-[var(--font-inter-tight)] text-[20px] font-extrabold">
                Megrum
              </p>
              <p className="mt-1 text-[12px] font-semibold text-slate-500">
                推し活グッズの交換アプリ（現地・郵送）
              </p>
            </div>
          </div>
          <p className="mt-5 max-w-xl text-[13px] font-medium leading-7 text-slate-600">
            Megrumは、マイグッズとほしいものの登録、譲・求のシェア画像づくり、打診、取引チャット、現地交換・郵送交換の合流支援を扱うiOSアプリです。
            問い合わせ、プライバシーに関する請求、通報相談はサポート窓口で受け付けます。
          </p>
        </div>
        <div className="grid grid-cols-2 gap-4 text-[13px] font-bold text-slate-700 sm:grid-cols-3 md:grid-cols-2">
          {links.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-lg border border-slate-200 px-3 py-3 transition hover:border-megrum-lavender/50 hover:text-violet-700"
            >
              {item.label}
            </Link>
          ))}
          <a
            href={`mailto:${CONTACT_EMAIL}`}
            className="rounded-lg border border-slate-200 px-3 py-3 transition hover:border-megrum-lavender/50 hover:text-violet-700"
          >
            {CONTACT_EMAIL}
          </a>
        </div>
      </div>
      <div className="border-t border-slate-100 px-5 py-4 text-center text-[11px] font-semibold text-slate-500">
        © 2026 Megrum. All rights reserved.
      </div>
    </footer>
  );
}

export function PublicPage({ children }: { children: ReactNode }) {
  return (
    <main className="min-h-screen flex-1 bg-[#fbf9fc] text-slate-950">
      <SiteHeader />
      {children}
      <SiteFooter />
    </main>
  );
}

/** eyebrow + 見出し + 説明の共通ヘッダーブロック（Section と単体の両方で使う）。 */
export function SectionHeading({
  eyebrow,
  title,
  description,
  as: Heading = "h2",
}: {
  eyebrow?: string;
  title: string;
  description?: string;
  as?: "h2" | "h3";
}) {
  const titleClass =
    Heading === "h2"
      ? "mt-3 text-[30px] font-black leading-tight tracking-normal text-slate-950 md:text-[42px]"
      : "mt-3 text-[22px] font-black leading-tight tracking-normal text-slate-950 md:text-[28px]";
  return (
    <div className="max-w-3xl">
      {eyebrow && (
        <p className="text-[12px] font-black uppercase tracking-normal text-violet-700">
          {eyebrow}
        </p>
      )}
      <Heading className={titleClass}>{title}</Heading>
      {description && (
        <p className="mt-4 text-[15px] font-medium leading-8 text-slate-600 md:text-[16px]">
          {description}
        </p>
      )}
    </div>
  );
}

export function Section({
  id,
  eyebrow,
  title,
  description,
  children,
}: {
  id?: string;
  eyebrow?: string;
  title: string;
  description?: string;
  children: ReactNode;
}) {
  return (
    <section id={id} className="scroll-mt-24 px-5 py-16 md:py-20">
      <div className="mx-auto w-full max-w-6xl">
        <SectionHeading eyebrow={eyebrow} title={title} description={description} />
        {children}
      </div>
    </section>
  );
}

/** アンカー付きの汎用セクション枠（見出しは中で自由に組む）。tone="white" で白背景。 */
export function AnchorSection({
  id,
  tone = "default",
  children,
}: {
  id: string;
  tone?: "default" | "white";
  children: ReactNode;
}) {
  return (
    <section
      id={id}
      className={`scroll-mt-24 px-5 py-16 md:py-20 ${
        tone === "white" ? "bg-white" : ""
      }`}
    >
      <div className="mx-auto w-full max-w-6xl">{children}</div>
    </section>
  );
}

/**
 * アプリのスクショ枠（notes/82 §5・§7）。端末モック枠は自作せず角丸＋影のみ。
 * src 未指定なら納品前プレースホルダ（アスペクト比を保った箱）を出す。
 */
export function Screenshot({
  src,
  alt,
  width = 390,
  height = 844,
  priority = false,
  placeholderLabel,
  ratio = "390 / 844",
  className = "",
}: {
  src?: string;
  alt: string;
  width?: number;
  height?: number;
  priority?: boolean;
  placeholderLabel?: string;
  ratio?: string;
  className?: string;
}) {
  const frame =
    "overflow-hidden rounded-[28px] border border-white/70 bg-white shadow-[0_28px_80px_rgba(58,50,74,0.18)]";
  if (src) {
    return (
      <div className={[frame, className].filter(Boolean).join(" ")}>
        <Image
          src={src}
          alt={alt}
          width={width}
          height={height}
          priority={priority}
          className="h-auto w-full"
        />
      </div>
    );
  }
  return (
    <div
      role="img"
      aria-label={alt}
      style={{ aspectRatio: ratio }}
      className={[
        frame,
        "grid place-items-center bg-gradient-to-b from-megrum-lavender/10 to-megrum-sky/10",
        className,
      ]
        .filter(Boolean)
        .join(" ")}
    >
      <span className="px-6 text-center text-[12px] font-bold text-slate-400">
        {placeholderLabel ?? "スクリーンショット（納品待ち）"}
      </span>
    </div>
  );
}

/** よくある質問（native details＝ゼロJS・アクセシブル・SSG向き）。 */
export function FaqList({
  items,
}: {
  items: { q: string; a: ReactNode }[];
}) {
  return (
    <div className="mt-8 overflow-hidden rounded-2xl border border-slate-200 bg-white">
      {items.map((item, index) => (
        <details
          key={index}
          className="group border-t border-slate-100 first:border-t-0 open:bg-megrum-lavender/[0.04]"
        >
          <summary className="flex cursor-pointer list-none items-center justify-between gap-4 px-5 py-4 text-[15px] font-bold text-slate-900 [&::-webkit-details-marker]:hidden">
            <span>{item.q}</span>
            <span
              aria-hidden="true"
              className="grid size-6 shrink-0 place-items-center rounded-full border border-slate-300 text-slate-500 transition group-open:rotate-45 group-open:border-megrum-lavender group-open:text-violet-700"
            >
              +
            </span>
          </summary>
          <div className="px-5 pb-5 text-[14px] font-medium leading-7 text-slate-600">
            {item.a}
          </div>
        </details>
      ))}
    </div>
  );
}

/**
 * JSON-LD 構造化データ（Next 16 公式パターン）。
 * XSS 対策で "<" を < へ置換してから埋め込む。
 */
export function JsonLd({ data }: { data: Record<string, unknown> }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{
        __html: JSON.stringify(data).replace(/</g, "\\u003c"),
      }}
    />
  );
}

export function LegalShell({
  eyebrow,
  title,
  updated,
  intro,
  children,
}: {
  eyebrow: string;
  title: string;
  updated: string;
  intro: string;
  children: ReactNode;
}) {
  return (
    <PublicPage>
      <section className="px-5 pb-10 pt-32">
        <div className="mx-auto w-full max-w-4xl">
          <p className="text-[12px] font-black uppercase tracking-normal text-violet-700">
            {eyebrow}
          </p>
          <h1 className="mt-3 text-[34px] font-black leading-tight tracking-normal text-slate-950 md:text-[48px]">
            {title}
          </h1>
          <p className="mt-4 text-[13px] font-bold text-slate-500">
            制定日：2026年5月31日 / 最終更新日：{updated}
          </p>
          <p className="mt-6 text-[15px] font-medium leading-8 text-slate-600">
            {intro}
          </p>
        </div>
      </section>
      <section className="px-5 pb-20">
        <article className="mx-auto w-full max-w-4xl space-y-8 rounded-lg border border-slate-200 bg-white px-5 py-6 shadow-[0_16px_40px_rgba(58,50,74,0.06)] md:px-8 md:py-8">
          {children}
        </article>
      </section>
    </PublicPage>
  );
}

export function LegalSection({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <section>
      <h2 className="text-[20px] font-black tracking-normal text-slate-950">
        {title}
      </h2>
      <div className="mt-4 space-y-3 text-[14px] font-medium leading-8 text-slate-700">
        {children}
      </div>
    </section>
  );
}

export function BulletList({ items }: { items: string[] }) {
  return (
    <ul className="list-disc space-y-2 pl-5">
      {items.map((item) => (
        <li key={item}>{item}</li>
      ))}
    </ul>
  );
}

export function TextLink({
  href,
  children,
}: {
  href: string;
  children: ReactNode;
}) {
  return (
    <Link
      href={href}
      className="font-black text-violet-700 underline decoration-megrum-lavender/35 underline-offset-4 transition hover:text-violet-900"
    >
      {children}
    </Link>
  );
}

/**
 * 「詳しく見る →」リンク。遷移先ページが実装済みのときだけ描画する
 * （未実装ページ＝NAV enabled:false へのリンク切れを回避。notes/82 §9）。
 * 同一ページ内アンカー（#始まり）は常に描画する。
 */
export function DetailLink({
  href,
  label = "詳しく見る",
  className = "",
}: {
  href: string;
  label?: string;
  className?: string;
}) {
  const isAnchor = href.startsWith("#");
  if (!isAnchor && !routeEnabled(href)) return null;
  const classes = [
    "inline-flex items-center gap-1 text-[13px] font-black text-violet-700 transition hover:text-violet-900",
    className,
  ]
    .filter(Boolean)
    .join(" ");
  const content = (
    <>
      {label}
      <span aria-hidden="true">→</span>
    </>
  );
  // 同一ページ内アンカーは <a>、内部ページ遷移は next/link を使う。
  return isAnchor ? (
    <a href={href} className={classes}>
      {content}
    </a>
  ) : (
    <Link href={href} className={classes}>
      {content}
    </Link>
  );
}
