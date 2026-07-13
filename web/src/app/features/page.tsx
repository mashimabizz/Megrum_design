import type { Metadata } from "next";
import Link from "next/link";
import type { ReactNode } from "react";

import { PrimaryCtaBlock } from "../_cta";
import {
  AnchorSection,
  DetailLink,
  JsonLd,
  PublicPage,
  Screenshot,
  SectionHeading,
} from "../_publicComponents";
import { breadcrumbJsonLd, buildMetadata } from "../_siteConfig";

export const metadata: Metadata = buildMetadata({
  title: "機能紹介",
  description:
    "Megrumの機能。マイグッズ・ほしいもの・譲求シェア画像、候補と打診、現地交換・郵送交換の取引チャット、めぐり（マップ・グルーム・チャットルーム）、安全の仕組みを紹介します。",
  path: "/features",
});

const ANCHORS = [
  { href: "#share-image", label: "シェア画像" },
  { href: "#matching", label: "候補・打診" },
  { href: "#trade", label: "取引・交換" },
  { href: "#meguri", label: "めぐり" },
  { href: "#safety", label: "安全" },
];

export default function FeaturesPage() {
  return (
    <PublicPage>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "ホーム", path: "/" },
          { name: "機能紹介", path: "/features" },
        ])}
      />
      <FeaturesHero />
      <ShareImageSection />
      <MatchingSection />
      <TradeSection />
      <MeguriSection />
      <SafetySection />
      <PageEnd />
    </PublicPage>
  );
}

/* ── ヒーロー ─────────────────────────────────────────────── */
function FeaturesHero() {
  return (
    <section className="relative isolate overflow-hidden px-5 pb-10 pt-32 md:pt-36">
      <div className="absolute left-0 right-0 top-0 -z-10 h-56 bg-[radial-gradient(circle_at_32%_0%,rgba(166,149,216,0.20),transparent_58%),radial-gradient(circle_at_68%_8%,rgba(168,212,230,0.18),transparent_48%)]" />
      <div className="mx-auto w-full max-w-6xl">
        <nav aria-label="パンくず" className="text-[12px] font-bold text-slate-500">
          <Link href="/" className="transition hover:text-violet-700">
            ホーム
          </Link>
          <span className="mx-2 text-slate-300">/</span>
          <span className="text-slate-700">機能紹介</span>
        </nav>
        <h1 className="mt-5 max-w-3xl text-[34px] font-black leading-[1.16] tracking-tight text-slate-950 md:text-[48px]">
          Megrumでできること。
        </h1>
        <p className="mt-5 max-w-2xl text-[15px] font-medium leading-8 text-slate-600 md:text-[16px]">
          譲・求の整理からシェア画像づくり、条件の合う相手探し、現地交換・郵送交換、そして「めぐり」まで。推し活グッズの交換を、安心して進めるための機能を紹介します。
        </p>
        <div className="mt-8 flex flex-wrap gap-2">
          {ANCHORS.map((anchor) => (
            <a
              key={anchor.href}
              href={anchor.href}
              className="rounded-full border border-slate-200 bg-white px-4 py-2 text-[12px] font-bold text-slate-700 transition hover:border-megrum-lavender/50 hover:text-violet-700"
            >
              {anchor.label}
            </a>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── 4B-1 シェア画像 ─────────────────────────────────────── */
function ShareImageSection() {
  return (
    <AnchorSection id="share-image">
      <FeatureBlock
        index="01"
        eyebrow="マイグッズ・ほしいもの"
        title="スマホの中に、自分の譲・求リストがいつでも。"
        body={
          <>
            <p>
              グッズを登録すれば、譲れるもの（マイグッズ）と求めているもの（ほしいもの）が整理されます。そのまま、Xに載せられる譲・求のシェア画像をすぐに作れます。
            </p>
            <p className="mt-3">
              「この2枚セットで」といった個別の条件も登録できます。探すのはMegrum、告知はXへ。
            </p>
          </>
        }
        screenshots={[
          { label: "譲・求のシェア画像（SS-2・納品待ち）" },
          { label: "登録画面（SS-6・納品待ち）" },
        ]}
      />
    </AnchorSection>
  );
}

/* ── 4B-2 候補と打診 ─────────────────────────────────────── */
function MatchingSection() {
  return (
    <AnchorSection id="matching" tone="white">
      <FeatureBlock
        index="02"
        eyebrow="候補と打診"
        title="検索と個別の声かけの往復を、減らす。"
        reverse
        body={
          <>
            <p>
              登録した譲・求の条件が合う相手が、候補として並びます。気になる相手には、提示物・受け取る物・待ち合わせ条件まで含めて打診できます。
            </p>
            <p className="mt-3 font-bold text-slate-800">
              打診したあとも、合意の前にチャットで条件を調整できます。いきなり確定せず、納得してから合意へ。
            </p>
          </>
        }
        screenshots={[{ label: "候補シート（SS-3・納品待ち）" }]}
      />
    </AnchorSection>
  );
}

/* ── 4B-3 取引チャット（現地/郵送） ──────────────────────── */
function TradeSection() {
  return (
    <AnchorSection id="trade">
      <SectionHeading
        eyebrow="取引チャット"
        title="現地でも郵送でも、住所の扱いを分けて。"
      />
      <div className="mt-10 grid gap-4 md:grid-cols-2">
        <TradeCard title="現地交換">
          <p>
            合意の前に、待ち合わせ場所・時間を確定してから成立します。当日は到着状況の共有や、任意の現在地共有、服装写真で合流をサポートします。
          </p>
          <p className="mt-3 font-bold text-slate-800">
            会って直接だから、住所を教える必要がありません。送料ゼロ・実物を確認してから交換できます。
          </p>
          <p className="mt-4 rounded-xl bg-slate-50 px-3 py-2 text-[12px] font-semibold leading-6 text-slate-500">
            正確な現在地は表示されません。
          </p>
          <DetailLink href="/guide/local" label="現地交換のマナーを見る" className="mt-4" />
        </TradeCard>
        <TradeCard title="郵送交換">
          <p>
            住所は取引成立後に、グッズを送る相手にだけ・アプリ内でのみ表示されます。外部SNSの個別連絡に住所を残しません。
          </p>
          <p className="mt-3">
            追跡番号を記録すれば、発送状況を確認しやすくなります。高額な取引では、追跡ありの配送がおすすめです。
          </p>
          <DetailLink href="/guide/mail" label="郵送交換ガイドを見る" className="mt-4" />
        </TradeCard>
      </div>
      <div className="mt-4 grid grid-cols-2 gap-4 md:max-w-md">
        <Screenshot
          placeholderLabel="現地チャット（SS-4・納品待ち）"
          alt="現地交換の取引チャット"
          ratio="300 / 640"
        />
        <Screenshot
          placeholderLabel="郵送交換（SS-5・納品待ち）"
          alt="郵送交換の画面"
          ratio="300 / 640"
        />
      </div>
    </AnchorSection>
  );
}

function TradeCard({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-[0_10px_30px_rgba(58,50,74,0.05)]">
      <p className="text-[16px] font-black text-slate-900">{title}</p>
      <div className="mt-3 text-[14px] font-medium leading-7 text-slate-600">
        {children}
      </div>
    </div>
  );
}

/* ── 4B-4 めぐり ─────────────────────────────────────────── */
function MeguriSection() {
  const items = [
    {
      t: "めぐりマップ",
      d: "会場や街で、周辺のグルームやチャットルームが地図に浮かびます。「いま、この現場に同じ界隈の人がいる」空気感。",
    },
    {
      t: "グルーム",
      d: "写真中心のスナップ投稿。現場の雰囲気・戦利品・デコの共有。閲覧は現在地から約1km圏内です。",
    },
    {
      t: "チャットルーム",
      d: "列状況・物販在庫・落とし物など「現場のいま」をやりとり。無料では同じ都道府県または現在地から約1km圏内で閲覧・参加でき、より広い範囲はMegrumプレミアムで見られます。",
    },
    {
      t: "めぐりあった人",
      d: "すれ違った同じ界隈の人が記録され、めぐり広場で振り返れます。",
    },
  ];
  return (
    <AnchorSection id="meguri" tone="white">
      <SectionHeading
        eyebrow="めぐり"
        title="現場が、もっと楽しくなる。"
        description="交換だけじゃない。同じ推し・同じ界隈の人と、会場や街でめぐりあう体験です。"
      />
      <div className="mt-10 grid gap-4 sm:grid-cols-2">
        {items.map((item) => (
          <div
            key={item.t}
            className="rounded-2xl border border-slate-200 bg-white p-6"
          >
            <p className="text-[16px] font-black text-slate-900">{item.t}</p>
            <p className="mt-2 text-[14px] font-medium leading-7 text-slate-600">
              {item.d}
            </p>
          </div>
        ))}
      </div>
      <p className="mt-5 max-w-2xl rounded-xl border border-megrum-sky/40 bg-megrum-sky/[0.08] px-4 py-3 text-[12px] font-semibold leading-6 text-slate-600">
        正確な現在地は表示されません。グルームは現在地から約1km以内、チャットルームは約1km以内または同じ都道府県で見られます。
      </p>
      <div className="mt-6 grid grid-cols-3 gap-3 md:max-w-lg">
        <Screenshot placeholderLabel="めぐりマップ（SS-7）" alt="めぐりマップ" ratio="240 / 520" />
        <Screenshot placeholderLabel="グルーム（SS-8）" alt="グルーム" ratio="240 / 520" />
        <Screenshot placeholderLabel="チャットルーム（SS-9）" alt="チャットルーム" ratio="240 / 520" />
      </div>
    </AnchorSection>
  );
}

/* ── 4B-5 安全 ───────────────────────────────────────────── */
function SafetySection() {
  const points = [
    "取引には証跡が残ります",
    "相互評価で相手の実績が分かります",
    "通報とブロックの仕組みがあります",
    "合意の前に待ち合わせを確定します",
  ];
  return (
    <AnchorSection id="safety">
      <SectionHeading
        eyebrow="安全"
        title="「晒して自衛」から「仕組みで予防」へ。"
      />
      <ul className="mt-8 grid gap-3 sm:grid-cols-2">
        {points.map((point) => (
          <li
            key={point}
            className="flex items-start gap-3 rounded-2xl border border-slate-200 bg-white p-5 text-[14px] font-bold text-slate-800"
          >
            <span
              aria-hidden="true"
              className="mt-0.5 grid size-5 shrink-0 place-items-center rounded-full bg-megrum-ok/20 text-[11px] text-megrum-ok"
            >
              ✓
            </span>
            {point}
          </li>
        ))}
      </ul>
      <DetailLink
        href="/safety"
        label="安全への取り組みを詳しく"
        className="mt-6"
      />
    </AnchorSection>
  );
}

/* ── 4B-6 ページ末尾 ─────────────────────────────────────── */
function PageEnd() {
  return (
    <section className="px-5 pb-24 pt-6">
      <div className="mx-auto w-full max-w-6xl overflow-hidden rounded-[28px] border border-white/70 bg-gradient-to-br from-megrum-lavender/15 via-megrum-sky/10 to-megrum-pink/15 px-6 py-12 md:px-12 md:py-14">
        <h2 className="max-w-2xl text-[24px] font-black leading-tight tracking-tight text-slate-950 md:text-[32px]">
          まずは公式Xで、最新情報を。
        </h2>
        <div className="mt-7 flex flex-wrap items-center gap-4">
          <PrimaryCtaBlock placement="features_end" />
          <Link
            href="/"
            className="text-[13px] font-bold text-violet-700 underline decoration-megrum-lavender/40 underline-offset-4 transition hover:text-violet-900"
          >
            トップへ戻る
          </Link>
        </div>
      </div>
    </section>
  );
}

/* ── 共通レイアウト ──────────────────────────────────────── */
function FeatureBlock({
  index,
  eyebrow,
  title,
  body,
  screenshots,
  reverse = false,
}: {
  index: string;
  eyebrow: string;
  title: string;
  body: ReactNode;
  screenshots: { src?: string; label: string }[];
  reverse?: boolean;
}) {
  return (
    <div
      className={`grid items-center gap-10 md:grid-cols-2 ${
        reverse ? "md:[&>*:first-child]:order-2" : ""
      }`}
    >
      <div>
        <div className="flex items-baseline gap-3">
          <span className="font-[var(--font-inter-tight)] text-[15px] font-black text-megrum-lavender">
            {index}
          </span>
          <p className="text-[12px] font-black uppercase tracking-normal text-violet-700">
            {eyebrow}
          </p>
        </div>
        <h2 className="mt-3 text-[24px] font-black leading-tight tracking-tight text-slate-950 md:text-[32px]">
          {title}
        </h2>
        <div className="mt-4 max-w-xl text-[14px] font-medium leading-7 text-slate-600 md:text-[15px]">
          {body}
        </div>
      </div>
      <div
        className={`grid gap-4 ${
          screenshots.length > 1 ? "grid-cols-2" : "mx-auto max-w-[300px]"
        }`}
      >
        {screenshots.map((shot) => (
          <Screenshot
            key={shot.label}
            src={shot.src}
            alt={shot.label}
            placeholderLabel={shot.label}
          />
        ))}
      </div>
    </div>
  );
}
