import type { Metadata } from "next";
import Link from "next/link";

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
  title: "郵送交換ガイド",
  description:
    "郵送交換を安全に進めるためのガイド。住所の扱い、追跡ありの配送をすすめる理由と普通郵便のリスク、トラブルを避ける工夫、高額な取引で慎重になるためのポイントをまとめました。",
  path: "/guide/mail",
});

const ANCHORS = [
  { href: "#address", label: "住所の扱い" },
  { href: "#ship", label: "送り方" },
  { href: "#trouble", label: "トラブル対策" },
  { href: "#highvalue", label: "高額な取引" },
];

export default function MailGuidePage() {
  return (
    <PublicPage>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "ホーム", path: "/" },
          { name: "郵送交換ガイド", path: "/guide/mail" },
        ])}
      />
      <GuideHero />
      <AddressSection />
      <ShipSection />
      <TroubleSection />
      <HighValueSection />
      <PageEnd />
    </PublicPage>
  );
}

function GuideHero() {
  return (
    <section className="relative isolate overflow-hidden px-5 pb-10 pt-32 md:pt-36">
      <div className="absolute left-0 right-0 top-0 -z-10 h-56 bg-[radial-gradient(circle_at_32%_0%,rgba(168,212,230,0.20),transparent_58%),radial-gradient(circle_at_68%_8%,rgba(166,149,216,0.16),transparent_48%)]" />
      <div className="mx-auto w-full max-w-6xl">
        <nav aria-label="パンくず" className="text-[12px] font-bold text-slate-500">
          <Link href="/" className="transition hover:text-violet-700">
            ホーム
          </Link>
          <span className="mx-2 text-slate-300">/</span>
          <span className="text-slate-700">郵送交換ガイド</span>
        </nav>
        <h1 className="mt-5 max-w-3xl text-[32px] font-black leading-[1.16] tracking-tight text-slate-950 md:text-[46px]">
          郵送交換を、安心して。
        </h1>
        <p className="mt-5 max-w-2xl text-[15px] font-medium leading-8 text-slate-600 md:text-[16px]">
          待ち合わせできない相手とも交換できるのが郵送の良さです。住所の扱いと、安全に送るためのポイントを正直にまとめました。
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

function AddressSection() {
  return (
    <AnchorSection id="address">
      <SectionHeading eyebrow="住所の扱い" title="住所は、成立後に・送る相手だけに。" />
      <TipList
        items={[
          "住所は取引成立後に、グッズを送る相手にだけ・アプリ内でのみ表示されます。外部SNSの個別のやりとりに住所を残さないでください。",
          "郵送はお互いに送り合うため、双方の住所がそれぞれの相手に伝わります。",
        ]}
      />
      <Callout className="mt-6">
        Megrumの郵送は「匿名配送」ではありません。相手に住所を知られたくない場合や、不安がある取引では、フリマサービスなどの匿名配送の利用も検討してください。
      </Callout>
    </AnchorSection>
  );
}

function ShipSection() {
  return (
    <AnchorSection id="ship" tone="white">
      <SectionHeading eyebrow="送り方" title="追跡ありの配送を、おすすめします。" />
      <TipList
        items={[
          "追跡ありの配送なら記録が残り、「送った・届かない」の水掛け論を避けやすくなります。",
          "サイズ・重さ・料金は、発送前に郵便局や配送会社で確認しましょう。",
        ]}
      />
      <Callout className="mt-6">
        普通郵便は安く送れますが、追跡も補償もありません。届かなくても記録が残らず、トラブルになりがちです。特に高額なものや、大切なものには使わないでください。
      </Callout>
    </AnchorSection>
  );
}

function TroubleSection() {
  return (
    <AnchorSection id="trouble">
      <SectionHeading eyebrow="トラブル対策" title="送る前に、記録を残す。" />
      <TipList
        items={[
          "発送前に、グッズと伝票（追跡番号）の写真を残しておきましょう。",
          "追跡番号はアプリに記録できます。発送状況を相手と確認しやすくなります。",
          "状態は正直に伝え、水濡れや折れを防ぐようにていねいに梱包しましょう。",
        ]}
      />
    </AnchorSection>
  );
}

function HighValueSection() {
  return (
    <AnchorSection id="highvalue" tone="white">
      <SectionHeading eyebrow="高額な取引" title="無理だと感じたら、見送る。" />
      <TipList
        items={[
          "高額なものや、相手に不安がある取引では、フリマサービスなどの匿名配送・補償のある方法も検討してください。",
          "少しでも不安を感じたら、取引を見送る判断も大切です。困ったときは通報できます。",
        ]}
      />
      <DetailLink href="/safety" label="安全への取り組みを詳しく" className="mt-6" />
    </AnchorSection>
  );
}

function PageEnd() {
  return (
    <section className="px-5 pb-24 pt-6">
      <div className="mx-auto w-full max-w-6xl rounded-[28px] border border-slate-200 bg-white px-6 py-10 md:px-12 md:py-12">
        <p className="text-[14px] font-medium leading-8 text-slate-600">
          会って交換したいときは{" "}
          <TextLink href="/guide/local">現地交換ガイド</TextLink>{" "}
          もどうぞ。取引の流れは{" "}
          <TextLink href="/features#trade">機能紹介</TextLink>{" "}
          で確認できます。
        </p>
        <div className="mt-8 flex flex-wrap items-center gap-4">
          <PrimaryCtaBlock placement="guide_mail_end" />
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
          <span
            aria-hidden="true"
            className="mt-1.5 size-2 shrink-0 rounded-full bg-megrum-sky"
          />
          <span>{item}</span>
        </li>
      ))}
    </ul>
  );
}
