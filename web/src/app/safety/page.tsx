import type { Metadata } from "next";
import Link from "next/link";
import type { ReactNode } from "react";

import { PrimaryCtaBlock } from "../_cta";
import {
  AnchorSection,
  Callout,
  DetailLink,
  JsonLd,
  PublicPage,
  SectionHeading,
  TextLink,
} from "../_publicComponents";
import { breadcrumbJsonLd, buildMetadata } from "../_siteConfig";

export const metadata: Metadata = buildMetadata({
  title: "安全への取り組み",
  description:
    "Megrumの安全への取り組み。位置情報の扱い（正確な現在地は表示されません）、郵送の住所の扱い、証跡・相互評価・通報・ブロックの仕組み、未成年の利用についてを説明します。",
  path: "/safety",
});

const ANCHORS = [
  { href: "#location", label: "位置情報" },
  { href: "#address", label: "住所" },
  { href: "#trust", label: "通報・評価" },
  { href: "#minors", label: "未成年" },
];

export default function SafetyPage() {
  return (
    <PublicPage>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "ホーム", path: "/" },
          { name: "安全への取り組み", path: "/safety" },
        ])}
      />
      <SafetyHero />
      <LocationSection />
      <AddressSection />
      <TrustSection />
      <MinorsSection />
      <PageEnd />
    </PublicPage>
  );
}

/* ── ヒーロー ─────────────────────────────────────────────── */
function SafetyHero() {
  return (
    <section className="relative isolate overflow-hidden px-5 pb-10 pt-32 md:pt-36">
      <div className="absolute left-0 right-0 top-0 -z-10 h-56 bg-[radial-gradient(circle_at_32%_0%,rgba(166,149,216,0.20),transparent_58%),radial-gradient(circle_at_68%_8%,rgba(107,179,154,0.14),transparent_48%)]" />
      <div className="mx-auto w-full max-w-6xl">
        <nav aria-label="パンくず" className="text-[12px] font-bold text-slate-500">
          <Link href="/" className="transition hover:text-violet-700">
            ホーム
          </Link>
          <span className="mx-2 text-slate-300">/</span>
          <span className="text-slate-700">安全への取り組み</span>
        </nav>
        <h1 className="mt-5 max-w-3xl text-[34px] font-black leading-[1.16] tracking-tight text-slate-950 md:text-[48px]">
          「怪しくない」を、仕組みで。
        </h1>
        <p className="mt-5 max-w-2xl text-[15px] font-medium leading-8 text-slate-600 md:text-[16px]">
          位置情報・住所・トラブル対策・未成年の利用について、Megrumがどう扱い、何をおすすめするかを正直に説明します。
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

/* ── 位置情報 ─────────────────────────────────────────────── */
function LocationSection() {
  return (
    <AnchorSection id="location">
      <SectionHeading
        eyebrow="位置情報の扱い"
        title="正確な現在地は、表示しません。"
      />
      <div className="mt-8 grid gap-4 md:grid-cols-2">
        <Card>
          <p>
            「めぐり」では、正確な現在地（緯度経度）を画面に出しません。表示は「約1km圏内」「都道府県」といった、おおまかな範囲に丸めています。
          </p>
        </Card>
        <Card>
          <p>
            グルームは現在地から約1km以内、チャットルームは約1km以内または同じ都道府県で見られます。位置情報は、近くの投稿やチャットルームの表示・閲覧範囲の判定に使います。
          </p>
        </Card>
      </div>
      <Callout>
        距離やおおまかな範囲の表示は、安全性や匿名性を保証するものではありません。投稿のタイミングや内容から居場所が推測される可能性があるため、自宅や毎日の行動範囲が分かる情報は載せないようにしてください。
      </Callout>
    </AnchorSection>
  );
}

/* ── 住所 ─────────────────────────────────────────────────── */
function AddressSection() {
  return (
    <AnchorSection id="address" tone="white">
      <SectionHeading
        eyebrow="住所の扱い"
        title="住所は、取引成立後に・送る相手だけに。"
      />
      <div className="mt-8 grid gap-4 md:grid-cols-2">
        <Card>
          <p className="font-bold text-slate-800">現地交換なら、住所は不要。</p>
          <p className="mt-2">
            会って直接交換するため、住所を教える必要がありません。
          </p>
        </Card>
        <Card>
          <p className="font-bold text-slate-800">郵送交換の住所は、成立後に。</p>
          <p className="mt-2">
            住所は取引成立後に、グッズを送る相手にだけ・アプリ内でのみ表示されます。外部SNSの個別のやりとりに住所が残りません。
          </p>
        </Card>
      </div>
      <Callout>
        郵送はお互いに送り合うため、双方の住所がそれぞれの相手に伝わります（「匿名配送」ではありません）。相手や取引に不安がある場合は、フリマサービスなどの匿名配送の利用も検討してください。高額な取引では、追跡ありの配送をおすすめします。
      </Callout>
      <DetailLink href="/guide/mail" label="郵送交換ガイドを見る" className="mt-6" />
    </AnchorSection>
  );
}

/* ── 証跡・評価・通報・ブロック ──────────────────────────── */
function TrustSection() {
  const points = [
    {
      t: "取引に証跡が残る",
      d: "やりとりや取引の記録が残るので、「言った・言わない」を防ぎやすくなります。",
    },
    {
      t: "相互評価",
      d: "相手のこれまでの取引評価を、取引の前に確認できます。",
    },
    {
      t: "合意の前に待ち合わせを確定",
      d: "現地交換は、合意の前に待ち合わせ場所・時間を決めてから成立します。",
    },
    {
      t: "通報とブロック",
      d: "困ったときは通報でき、相手をブロックすることもできます。",
    },
  ];
  return (
    <AnchorSection id="trust">
      <SectionHeading
        eyebrow="トラブル対策"
        title="「晒して自衛」から「仕組みで予防」へ。"
      />
      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        {points.map((point) => (
          <Card key={point.t}>
            <p className="text-[16px] font-black text-slate-900">{point.t}</p>
            <p className="mt-2">{point.d}</p>
          </Card>
        ))}
      </div>
    </AnchorSection>
  );
}

/* ── 未成年（保護者向け） ────────────────────────────────── */
function MinorsSection() {
  return (
    <AnchorSection id="minors" tone="white">
      <SectionHeading
        eyebrow="未成年の利用について"
        title="未成年の方と、保護者の方へ。"
      />
      <ul className="mt-8 space-y-3">
        {[
          "現地で交換するときは、人の多い公共の場所・明るい時間帯での待ち合わせをおすすめします。",
          "不安なときは、保護者の方に相談してから利用してください。",
          "未成年の方が大人と1対1で会うことを、おすすめする設計にはしていません。",
          "心配な点や気になる相手がいたときは、通報とサポート窓口をご利用ください。",
        ].map((line) => (
          <li
            key={line}
            className="flex items-start gap-3 rounded-2xl border border-slate-200 bg-white p-5 text-[14px] font-medium leading-7 text-slate-700"
          >
            <span
              aria-hidden="true"
              className="mt-1 size-2 shrink-0 rounded-full bg-megrum-lavender"
            />
            {line}
          </li>
        ))}
      </ul>
    </AnchorSection>
  );
}

/* ── ページ末尾 ──────────────────────────────────────────── */
function PageEnd() {
  return (
    <section className="px-5 pb-24 pt-6">
      <div className="mx-auto w-full max-w-6xl rounded-[28px] border border-slate-200 bg-white px-6 py-10 md:px-12 md:py-12">
        <p className="text-[14px] font-medium leading-8 text-slate-600">
          くわしい取り扱いは{" "}
          <TextLink href="/privacy">プライバシーポリシー</TextLink> と{" "}
          <TextLink href="/terms">利用規約</TextLink>{" "}
          をご確認ください。ご不明な点や通報のご相談は{" "}
          <TextLink href="/support">サポート窓口</TextLink> で受け付けます。
        </p>
        <div className="mt-8 flex flex-wrap items-center gap-4">
          <PrimaryCtaBlock placement="safety_end" />
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

/* ── 部品 ─────────────────────────────────────────────────── */
function Card({ children }: { children: ReactNode }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-6 text-[14px] font-medium leading-7 text-slate-600 shadow-[0_10px_30px_rgba(58,50,74,0.05)]">
      {children}
    </div>
  );
}
