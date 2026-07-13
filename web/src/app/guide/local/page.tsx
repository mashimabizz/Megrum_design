import type { Metadata } from "next";
import Link from "next/link";
import type { ReactNode } from "react";

import { PrimaryCtaBlock } from "../../_cta";
import {
  AnchorSection,
  Callout,
  DetailLink,
  JsonLd,
  PublicPage,
  SectionHeading,
  TextLink,
} from "../../_publicComponents";
import { breadcrumbJsonLd, buildMetadata } from "../../_siteConfig";

export const metadata: Metadata = buildMetadata({
  title: "現地交換ガイド・マナー",
  description:
    "現地交換を安全・スムーズに進めるためのガイド。待ち合わせの決め方、当日の流れ、会場やお店でのマナー、安全のための注意をまとめました。",
  path: "/guide/local",
});

const ANCHORS = [
  { href: "#meet", label: "待ち合わせ" },
  { href: "#day", label: "当日の流れ" },
  { href: "#manner", label: "マナー" },
  { href: "#safe", label: "安全のために" },
];

export default function LocalGuidePage() {
  return (
    <PublicPage>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "ホーム", path: "/" },
          { name: "現地交換ガイド", path: "/guide/local" },
        ])}
      />
      <GuideHero />
      <MeetSection />
      <DaySection />
      <MannerSection />
      <SafeSection />
      <PageEnd />
    </PublicPage>
  );
}

function GuideHero() {
  return (
    <section className="relative isolate overflow-hidden px-5 pb-10 pt-32 md:pt-36">
      <div className="absolute left-0 right-0 top-0 -z-10 h-56 bg-[radial-gradient(circle_at_32%_0%,rgba(166,149,216,0.20),transparent_58%),radial-gradient(circle_at_68%_8%,rgba(243,197,212,0.18),transparent_48%)]" />
      <div className="mx-auto w-full max-w-6xl">
        <nav aria-label="パンくず" className="text-[12px] font-bold text-slate-500">
          <Link href="/" className="transition hover:text-violet-700">
            ホーム
          </Link>
          <span className="mx-2 text-slate-300">/</span>
          <span className="text-slate-700">現地交換ガイド</span>
        </nav>
        <h1 className="mt-5 max-w-3xl text-[32px] font-black leading-[1.16] tracking-tight text-slate-950 md:text-[46px]">
          現地交換を、安全に・スムーズに。
        </h1>
        <p className="mt-5 max-w-2xl text-[15px] font-medium leading-8 text-slate-600 md:text-[16px]">
          会場や街での現地交換を、気持ちよく進めるためのガイドです。待ち合わせの決め方から当日の流れ、会場でのマナーまで。
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

function MeetSection() {
  return (
    <AnchorSection id="meet">
      <SectionHeading eyebrow="待ち合わせ" title="場所と時間は、合意の前に決める。" />
      <TipList
        items={[
          "Megrumでは、合意の前に待ち合わせ場所と時間を確定してから取引が成立します。",
          "人が多く、明るい公共の場所を選びましょう（会場の指定エリア、駅、商業施設など）。",
          "はじめての相手とは、人目のある場所で・短時間で会うのが安心です。",
        ]}
      />
    </AnchorSection>
  );
}

function DaySection() {
  return (
    <AnchorSection id="day" tone="white">
      <SectionHeading eyebrow="当日の流れ" title="合流して、実物を確認してから交換。" />
      <TipList
        items={[
          "到着状況を共有して合流します。任意で現在地共有や服装写真も使えます。",
          "その場で実物を確認してから交換します。状態が違うと感じたら、無理に交換しないこと。",
          "会って直接だから、送料ゼロ・その場で完結できるのが現地交換の良さです。",
        ]}
      />
      <Callout className="mt-6">
        正確な現在地は表示されません。それでも、待ち合わせ場所ややりとりの内容から居場所が推測されることがあります。自宅や毎日の行動範囲が分かる情報は出さないようにしましょう。
      </Callout>
    </AnchorSection>
  );
}

function MannerSection() {
  return (
    <AnchorSection id="manner">
      <SectionHeading eyebrow="マナー" title="会場・お店では、まわりへの配慮を。" />
      <TipList
        items={[
          "お店の中での交換は、お店のルールに従いましょう（店内での交換を断っている場所も多いです）。ショップ前や休憩スペースなど、迷惑にならない場所で。",
          "通路をふさいだり、長時間の場所取りをしないようにしましょう。",
          "掲示物は撤去されることもあります。Megrumなら事前に相手が見つかるので、その場の掲示に頼らず合流できます。",
        ]}
      />
    </AnchorSection>
  );
}

function SafeSection() {
  return (
    <AnchorSection id="safe" tone="white">
      <SectionHeading eyebrow="安全のために" title="不安なときは、無理をしない。" />
      <TipList
        items={[
          "相手の評価や取引実績を、事前に確認しましょう。",
          "少しでも不安を感じたら、無理に取引を進めず中止してかまいません。困ったときは通報できます。",
        ]}
      />
      <Callout className="mt-6">
        未成年の方は、保護者に相談してから利用してください。大人と1対1で会うことは避けましょう。
      </Callout>
      <DetailLink href="/safety" label="安全への取り組みを詳しく" className="mt-6" />
    </AnchorSection>
  );
}

function PageEnd() {
  return (
    <section className="px-5 pb-24 pt-6">
      <div className="mx-auto w-full max-w-6xl rounded-[28px] border border-slate-200 bg-white px-6 py-10 md:px-12 md:py-12">
        <p className="text-[14px] font-medium leading-8 text-slate-600">
          郵送で交換したいときは{" "}
          <TextLink href="/guide/mail">郵送交換ガイド</TextLink>{" "}
          もどうぞ。取引の流れは{" "}
          <TextLink href="/features#trade">機能紹介</TextLink>{" "}
          で確認できます。
        </p>
        <div className="mt-8 flex flex-wrap items-center gap-4">
          <PrimaryCtaBlock placement="guide_local_end" />
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

function TipList({ items }: { items: string[] }) {
  return (
    <ul className="mt-8 space-y-3">
      {items.map((item) => (
        <li
          key={item}
          className="flex items-start gap-3 rounded-2xl border border-slate-200 bg-white p-5 text-[14px] font-medium leading-7 text-slate-700"
        >
          <Bullet />
          <span>{item}</span>
        </li>
      ))}
    </ul>
  );
}

function Bullet(): ReactNode {
  return (
    <span
      aria-hidden="true"
      className="mt-1.5 size-2 shrink-0 rounded-full bg-megrum-lavender"
    />
  );
}
