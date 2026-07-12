import type { Metadata } from "next";
import type { ReactNode } from "react";

import { PrimaryCtaBlock } from "./_cta";
import {
  DetailLink,
  FaqList,
  JsonLd,
  PublicPage,
  Screenshot,
  Section,
  SectionHeading,
} from "./_publicComponents";
import {
  buildMetadata,
  softwareApplicationJsonLd,
  X_URL,
} from "./_siteConfig";

export const metadata: Metadata = buildMetadata({
  description:
    "譲・求のシェア画像づくりから、条件の合う相手探し、現地交換・郵送交換までを支える推し活グッズの交換アプリ。現地は住所不要、郵送は取引成立後に送る相手だけへ住所を表示します。",
  path: "/",
});

export default function HomePage() {
  return (
    <PublicPage>
      <JsonLd data={softwareApplicationJsonLd()} />
      <Hero />
      <PainSection />
      <SolutionSection />
      <StepsSection />
      <MeguriSection />
      <SafetyDigest />
      <FaqSection />
      <ClosingSection />
    </PublicPage>
  );
}

/* ── 4-1 ヒーロー ─────────────────────────────────────────── */
function Hero() {
  return (
    <section className="relative isolate overflow-hidden px-5 pb-16 pt-32 md:pb-24 md:pt-36">
      <div className="absolute inset-0 -z-20 bg-[#fbf9fc]" />
      <div className="absolute left-0 right-0 top-0 -z-10 h-64 bg-[radial-gradient(circle_at_30%_0%,rgba(166,149,216,0.22),transparent_56%),radial-gradient(circle_at_66%_6%,rgba(243,197,212,0.20),transparent_46%)]" />
      <div className="mx-auto grid w-full max-w-6xl items-center gap-10 md:grid-cols-[1.05fr_0.95fr]">
        <div>
          <p className="text-[12px] font-black uppercase tracking-normal text-violet-700">
            推し活グッズの交換アプリ
          </p>
          <h1 className="mt-4 text-[38px] font-black leading-[1.15] tracking-tight text-slate-950 md:text-[54px]">
            譲・求のシェア画像が、
            <br className="hidden sm:block" />
            すぐ作れる。
          </h1>
          <p className="mt-5 max-w-xl text-[15px] font-medium leading-8 text-slate-600 md:text-[16px]">
            譲れるグッズと求めているグッズを登録するだけ。Xに載せられるシェア画像を、かんたんに作れます。
            条件の合う相手探しから、現地交換・郵送交換までを支える推し活グッズの交換アプリです。
          </p>
          <div className="mt-8">
            <PrimaryCtaBlock placement="hero" />
          </div>
          <p className="mt-4 text-[12px] font-semibold text-slate-500">
            iOS先行（Androidは検討中）
          </p>
        </div>
        <div className="mx-auto w-full max-w-[340px] md:max-w-none">
          <Screenshot
            src="/site-assets/app-home.png"
            alt="Megrumのホーム画面。条件に合うグッズ候補が並んでいる。"
            width={853}
            height={1844}
            priority
          />
        </div>
      </div>
    </section>
  );
}

/* ── 4-2 課題共感 ─────────────────────────────────────────── */
function PainSection() {
  const pains = [
    {
      title: "相手探しが大変",
      body: "検索して、個別に声をかけて、条件を何度もやりとり。見つかるまでが長い。",
    },
    {
      title: "住所を伝えるのが不安",
      body: "郵送のたびに、必要以上の個人情報を教え合うのが心配。",
    },
    {
      title: "トラブルでも泣き寝入り",
      body: "未着や状態相違があっても、少額だと動きづらく、諦めがち。",
    },
  ];
  return (
    <Section
      eyebrow="こんなこと、ありませんか"
      title="Xの「譲・求」、けっこう大変。"
    >
      <div className="mt-10 grid gap-4 md:grid-cols-3">
        {pains.map((pain) => (
          <div
            key={pain.title}
            className="rounded-2xl border border-slate-200 bg-white p-6 shadow-[0_10px_30px_rgba(58,50,74,0.05)]"
          >
            <p className="text-[16px] font-black text-slate-900">{pain.title}</p>
            <p className="mt-3 text-[14px] font-medium leading-7 text-slate-600">
              {pain.body}
            </p>
          </div>
        ))}
      </div>
    </Section>
  );
}

/* ── 4-3 解決策（3軸） ────────────────────────────────────── */
function SolutionSection() {
  return (
    <section className="bg-white px-5 py-16 md:py-20">
      <div className="mx-auto w-full max-w-6xl">
        <SectionHeading
          eyebrow="Megrumができること"
          title="整理して、見つけて、安全に交換する。"
        />
        <div className="mt-12 space-y-16">
          <FeatureRow
            index="01"
            title="整理する"
            lead="探すのはMegrum、告知はX。"
            body="マイグッズ（譲れるもの）とほしいもの（求めているもの）を登録すれば、Xに載せられる譲・求のシェア画像がすぐ作れます。個別の条件もそのまま残せます。"
            screenshot={{ label: "譲・求のシェア画像（SS-2・納品待ち）" }}
            detailHref="/features#share-image"
          />
          <FeatureRow
            index="02"
            title="見つかる"
            lead="条件の合う相手が、候補に並ぶ。"
            body="検索して個別に声をかける往復を減らせます。気になる相手には、提示物・受け取る物・待ち合わせ条件まで含めて打診でき、合意の前にチャットで調整できます。"
            reverse
            screenshot={{ label: "候補シート（SS-3・納品待ち）" }}
            detailHref="/features#matching"
          />
          <div>
            <div className="max-w-3xl">
              <div className="flex items-baseline gap-3">
                <span className="font-[var(--font-inter-tight)] text-[15px] font-black text-megrum-lavender">
                  03
                </span>
                <h3 className="text-[22px] font-black tracking-normal text-slate-950 md:text-[28px]">
                  安全に交換する
                </h3>
              </div>
              <p className="mt-3 text-[15px] font-medium leading-8 text-slate-600">
                現地でも郵送でも、住所の扱いを分けて設計しています。
              </p>
            </div>
            <div className="mt-8 grid gap-4 md:grid-cols-2">
              <SafetyCard title="現地交換">
                <p>
                  合意の前に待ち合わせ場所・時間を確定してから成立。当日は到着状況の共有や、任意の現在地共有、服装写真で合流をサポートします。
                </p>
                <p className="mt-3 font-bold text-slate-800">
                  会って直接だから、住所を教える必要がありません。送料ゼロ・実物を確認してから交換できます。
                </p>
                <LocationNotice />
              </SafetyCard>
              <SafetyCard title="郵送交換">
                <p>
                  住所は取引成立後に、グッズを送る相手にだけ・アプリ内でのみ表示されます。外部SNSの個別連絡に住所を残しません。
                </p>
                <p className="mt-3 font-medium text-slate-600">
                  追跡番号を記録すれば、発送状況を確認しやすくなります。
                </p>
              </SafetyCard>
            </div>
            <div className="mt-4 rounded-2xl border border-megrum-lavender/30 bg-megrum-lavender/[0.06] p-5">
              <p className="text-[14px] font-medium leading-7 text-slate-700">
                取引には証跡が残り、相互評価もできます。
                <span className="font-black text-slate-900">
                  「晒して自衛」から「仕組みで予防」へ。
                </span>
              </p>
            </div>
            <DetailLink href="/features#trade" className="mt-5" />
          </div>
        </div>
      </div>
    </section>
  );
}

function FeatureRow({
  index,
  title,
  lead,
  body,
  screenshot,
  detailHref,
  reverse = false,
}: {
  index: string;
  title: string;
  lead: string;
  body: string;
  screenshot: { src?: string; label: string };
  detailHref: string;
  reverse?: boolean;
}) {
  return (
    <div
      className={`grid items-center gap-8 md:grid-cols-2 ${
        reverse ? "md:[&>*:first-child]:order-2" : ""
      }`}
    >
      <div>
        <div className="flex items-baseline gap-3">
          <span className="font-[var(--font-inter-tight)] text-[15px] font-black text-megrum-lavender">
            {index}
          </span>
          <h3 className="text-[22px] font-black tracking-normal text-slate-950 md:text-[28px]">
            {title}
          </h3>
        </div>
        <p className="mt-3 text-[17px] font-black text-slate-900">{lead}</p>
        <p className="mt-3 max-w-xl text-[14px] font-medium leading-7 text-slate-600 md:text-[15px]">
          {body}
        </p>
        <DetailLink href={detailHref} className="mt-5" />
      </div>
      <div className="mx-auto w-full max-w-[300px]">
        <Screenshot
          src={screenshot.src}
          alt={title}
          placeholderLabel={screenshot.label}
        />
      </div>
    </div>
  );
}

function SafetyCard({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-[0_10px_30px_rgba(58,50,74,0.05)]">
      <p className="text-[16px] font-black text-slate-900">{title}</p>
      <div className="mt-3 text-[14px] font-medium leading-7 text-slate-600">
        {children}
      </div>
    </div>
  );
}

/** 位置情報の必須併記（notes/80 §1-2・notes/82 §0A）。 */
function LocationNotice() {
  return (
    <p className="mt-4 rounded-xl bg-slate-50 px-3 py-2 text-[12px] font-semibold leading-6 text-slate-500">
      正確な現在地は表示されません。
    </p>
  );
}

/* ── 4-4 使い方 3ステップ ─────────────────────────────────── */
function StepsSection() {
  const steps = [
    { n: "1", t: "登録する", d: "譲れるもの・求めているものを登録。" },
    { n: "2", t: "打診する", d: "条件の合う候補から相手を選んで打診。" },
    { n: "3", t: "交換する", d: "合意して交換（現地 or 郵送）。" },
  ];
  return (
    <Section eyebrow="使い方" title="登録して、打診して、交換する。">
      <ol className="mt-10 grid gap-4 md:grid-cols-3">
        {steps.map((step) => (
          <li
            key={step.n}
            className="rounded-2xl border border-slate-200 bg-white p-6"
          >
            <span className="grid size-10 place-items-center rounded-full bg-gradient-to-br from-megrum-lavender to-megrum-sky font-[var(--font-inter-tight)] text-[18px] font-black text-white">
              {step.n}
            </span>
            <p className="mt-4 text-[16px] font-black text-slate-900">{step.t}</p>
            <p className="mt-2 text-[14px] font-medium leading-7 text-slate-600">
              {step.d}
            </p>
          </li>
        ))}
      </ol>
    </Section>
  );
}

/* ── 4-4b めぐり ─────────────────────────────────────────── */
function MeguriSection() {
  return (
    <section className="bg-white px-5 py-16 md:py-20">
      <div className="mx-auto w-full max-w-6xl">
        <div className="grid items-center gap-10 md:grid-cols-2">
          <div>
            <SectionHeading
              eyebrow="めぐり"
              title="交換だけじゃない。同じ推しの人と、めぐりあう。"
            />
            <p className="mt-5 max-w-xl text-[15px] font-medium leading-8 text-slate-600">
              会場や街で、近くにいる同じ界隈の人の「いま」がのぞけます。グルーム（写真スナップ）で現場の雰囲気を共有したり、チャットルームで列状況や現地情報をやりとりしたり。すれ違った記録は「めぐりあった人」に残っていきます。
            </p>
            <p className="mt-5 rounded-xl border border-megrum-sky/40 bg-megrum-sky/[0.08] px-4 py-3 text-[12px] font-semibold leading-6 text-slate-600">
              正確な現在地は表示されません。グルームは現在地から約1km以内、チャットルームは約1km以内または同じ都道府県で見られます。
            </p>
            <DetailLink href="/features#meguri" label="めぐりを詳しく" className="mt-5" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Screenshot
              placeholderLabel="めぐりマップ（SS-7・納品待ち）"
              alt="めぐりマップ"
              ratio="300 / 640"
            />
            <Screenshot
              placeholderLabel="グルーム（SS-8・納品待ち）"
              alt="グルーム"
              ratio="300 / 640"
              className="mt-8"
            />
          </div>
        </div>
      </div>
    </section>
  );
}

/* ── 4-5 安全ダイジェスト ─────────────────────────────────── */
function SafetyDigest() {
  const cards = [
    {
      t: "位置情報",
      d: "正確な現在地は表示されません。表示はおおまかな範囲に丸めています。",
    },
    {
      t: "住所",
      d: "郵送の住所は取引成立後に、送る相手にだけ・アプリ内でのみ表示。",
    },
    {
      t: "証跡・評価・通報",
      d: "取引に証跡が残り、相互評価・通報とブロックの仕組みがあります。",
    },
    {
      t: "未成年への配慮",
      d: "安全に使ってもらうための配慮を設けています。",
    },
  ];
  return (
    <Section eyebrow="安全への取り組み" title="「怪しくない」を、仕組みで。">
      <div className="mt-10 grid gap-4 sm:grid-cols-2 md:grid-cols-4">
        {cards.map((card) => (
          <div
            key={card.t}
            className="rounded-2xl border border-slate-200 bg-white p-5"
          >
            <p className="text-[15px] font-black text-slate-900">{card.t}</p>
            <p className="mt-2 text-[13px] font-medium leading-7 text-slate-600">
              {card.d}
            </p>
          </div>
        ))}
      </div>
      <DetailLink href="/safety" label="安全への取り組みを詳しく" className="mt-6" />
    </Section>
  );
}

/* ── 4-6 FAQ 抜粋 ────────────────────────────────────────── */
function FaqSection() {
  const items = [
    {
      q: "無料で使えますか？",
      a: (
        <p>
          交換の基本機能は無料で使えます。めぐりメッセージや広告非表示などの便利機能は「Megrumプレミアム」でご利用いただけます。
        </p>
      ),
    },
    {
      q: "出会い系のようなサービスですか？",
      a: (
        <p>
          いいえ。Megrumはグッズ交換に閉じた設計です。待ち合わせは公共の場をおすすめし、通報とブロックの仕組みもあります。
        </p>
      ),
    },
    {
      q: "Androidはいつ対応しますか？",
      a: <p>iOSを先行して提供しています。Android対応は検討中です。</p>,
    },
    {
      q: "現地交換はどこで使えますか？",
      a: <p>関西の主要公演から順次拡大していきます。</p>,
    },
  ];
  return (
    <Section eyebrow="よくある質問" title="はじめる前に。">
      <FaqList items={items} />
    </Section>
  );
}

/* ── 4-8 クロージングCTA ─────────────────────────────────── */
function ClosingSection() {
  return (
    <section className="px-5 pb-24 pt-4">
      <div className="mx-auto w-full max-w-6xl overflow-hidden rounded-[28px] border border-white/70 bg-gradient-to-br from-megrum-lavender/15 via-megrum-sky/10 to-megrum-pink/15 px-6 py-12 md:px-12 md:py-16">
        <h2 className="max-w-2xl text-[26px] font-black leading-tight tracking-tight text-slate-950 md:text-[36px]">
          住所を教え合わずに、交換相手が見つかる。
        </h2>
        <p className="mt-4 max-w-xl text-[14px] font-medium leading-8 text-slate-600 md:text-[15px]">
          安全な交換のコツも発信しています。まずは公式Xで最新情報をチェックしてください。
        </p>
        <div className="mt-8 flex flex-wrap items-center gap-4">
          <PrimaryCtaBlock placement="closing" />
          <a
            href={X_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="text-[13px] font-bold text-violet-700 underline decoration-megrum-lavender/40 underline-offset-4 transition hover:text-violet-900"
          >
            @megrum_jp を見る
          </a>
        </div>
      </div>
    </section>
  );
}
