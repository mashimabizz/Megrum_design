import Image from "next/image";
import Link from "next/link";
import type { ReactNode } from "react";

export const SITE_URL = "https://megrum.jp";
export const CONTACT_EMAIL = "support@megrum.jp";
export const OFFICE_ADDRESS_LINES = [
  "〒530-0001",
  "大阪府大阪市北区梅田1丁目2番2号",
  "大阪駅前第2ビル12-12",
];

const navItems = [
  { href: "/", label: "Megrum" },
  { href: "/operator", label: "運営者情報" },
  { href: "/privacy", label: "プライバシー" },
  { href: "/support", label: "サポート" },
  { href: "/terms", label: "利用規約" },
];

export function SiteHeader() {
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
        <nav className="hidden items-center gap-1 rounded-full border border-white/70 bg-white/80 px-2 py-2 shadow-[0_12px_36px_rgba(58,50,74,0.08)] backdrop-blur sm:flex">
          {navItems.slice(1).map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-full px-3 py-2 text-[12px] font-bold text-slate-700 transition hover:bg-megrum-lavender/10 hover:text-violet-700"
            >
              {item.label}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}

export function SiteFooter() {
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
                推し活グッズの現地交換アプリ
              </p>
            </div>
          </div>
          <p className="mt-5 max-w-xl text-[13px] font-medium leading-7 text-slate-600">
            Megrumは、グッズ登録、wish、打診、取引チャット、現地交換の合流支援を扱うiOSアプリです。
            サービスに関する問い合わせ、プライバシーに関する請求、通報相談はサポート窓口で受け付けます。
          </p>
        </div>
        <div className="grid grid-cols-2 gap-4 text-[13px] font-bold text-slate-700 sm:grid-cols-4 md:grid-cols-2">
          {navItems.map((item) => (
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
    <section id={id} className="px-5 py-16 md:py-20">
      <div className="mx-auto w-full max-w-6xl">
        <div className="max-w-3xl">
          {eyebrow && (
            <p className="text-[12px] font-black uppercase tracking-normal text-violet-700">
              {eyebrow}
            </p>
          )}
          <h2 className="mt-3 text-[30px] font-black leading-tight tracking-normal text-slate-950 md:text-[42px]">
            {title}
          </h2>
          {description && (
            <p className="mt-4 text-[15px] font-medium leading-8 text-slate-600 md:text-[16px]">
              {description}
            </p>
          )}
        </div>
        {children}
      </div>
    </section>
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
