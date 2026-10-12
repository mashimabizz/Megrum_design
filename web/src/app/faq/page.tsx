import type { Metadata } from "next";
import Link from "next/link";

import { PrimaryCtaBlock } from "../_cta";
import {
  AnchorSection,
  DetailLink,
  FaqList,
  JsonLd,
  PublicPage,
  SectionHeading,
  TextLink,
} from "../_publicComponents";
import {
  breadcrumbJsonLd,
  buildMetadata,
  CONTACT_EMAIL,
  faqPageJsonLd,
} from "../_siteConfig";

export const metadata: Metadata = buildMetadata({
  title: "よくある質問",
  description:
    "Megrumのよくある質問。料金、出会い系ではないこと、グッズ登録、打診と取引、現地交換・郵送交換の安全、通報・ブロック、アカウントについてまとめています。",
  path: "/faq",
});

type QA = { q: string; a: string };

const BASICS: QA[] = [
  {
    q: "Megrumはどんなサービスですか？",
    a: "推し活グッズを、現地または郵送で交換するためのiOSアプリです。譲・求の登録とシェア画像づくり、条件の合う相手探し、打診から取引までを支えます。",
  },
  {
    q: "無料で使えますか？",
    a: "交換の基本機能は無料で使えます。めぐりメッセージや広告非表示などの便利機能は「Megrumプレミアム」でご利用いただけます。",
  },
  {
    q: "出会い系のようなサービスですか？",
    a: "いいえ。Megrumはグッズ交換に閉じた設計です。ランダムチャットや出会い目的の利用は禁止で、待ち合わせは公共の場をおすすめし、通報とブロックの仕組みもあります。",
  },
  {
    q: "Androidには対応していますか？",
    a: "iOSを先行して提供しています。Android対応は検討中です。",
  },
  {
    q: "Megrumは公式サービスですか？",
    a: "いいえ。明示がない限り、アーティストや事務所、イベント主催者などの公式・公認・提携サービスではありません。アプリ内の名称やタグは、グッズを探しやすくするための参考情報です。",
  },
];

const GOODS: QA[] = [
  {
    q: "どんなグッズを登録できますか？",
    a: "推し活に関係する小型グッズを中心に、交換したいものや探しているものを登録できます。状態・数量・交換条件が相手に誤解なく伝わるように入力してください。",
  },
  {
    q: "チケットや売買目的の登録はできますか？",
    a: "できません。Megrumはユーザー同士の交換を補助するサービスで、売買・買取・チケット譲渡はできません。外部での売買や送金を求められたら、取引を進めず通報してください。",
  },
  {
    q: "公式画像や他人の写真を使ってもいいですか？",
    a: "権利者の許可がない公式画像や、他人が撮影した写真は使わないでください。自分で撮影した写真や、利用許可のある画像を使ってください。",
  },
  {
    q: "wishとは何ですか？",
    a: "探しているグッズや欲しい条件を登録する機能です。登録したwishは、交換候補の確認や打診の参考になります。",
  },
];

const DEAL: QA[] = [
  {
    q: "打診とは何ですか？",
    a: "交換したい相手に「この条件で交換したい」と提案する機能です。相手が内容を確認し、合意の前に条件を調整できます。",
  },
  {
    q: "取引チャットでは何を話せますか？",
    a: "合意後の確認、現地での合流、服装写真、現在地共有、到着状況、交換完了の確認など、取引に必要なやり取りができます。危険な誘導や外部への不自然な誘導は禁止です。",
  },
  {
    q: "Megrum運営者は交換の当事者ですか？",
    a: "いいえ。運営者は交換を補助するプラットフォームを提供します。交換の成立や相手の行動、グッズの真贋・状態を保証するものではありません。困ったときは通報してください。",
  },
];

const SAFETY: QA[] = [
  {
    q: "現地交換で気をつけることはありますか？",
    a: "人通りが多く、スタッフや管理者がいる場所を選び、危険を感じたら中止してください。会場や施設のルールに従い、夜間・人通りの少ない場所・相手の自宅や車内などでの待ち合わせは避けましょう。",
  },
  {
    q: "現在地共有や服装写真は必須ですか？",
    a: "いいえ、現地での合流を補助するための任意機能です。住所・勤務先・学校・連絡先など、必要以上の個人情報は送らないでください。",
  },
  {
    q: "郵送交換では住所が相手に見えますか？",
    a: "取引が成立すると、発送に必要な範囲で郵送先が相手に表示されます。お互いに送り合うため、双方の住所がそれぞれの相手に伝わります（「匿名配送」ではありません）。",
  },
  {
    q: "銀行振込やPayPay、現金交換をMegrumが決済しますか？",
    a: "いいえ。Megrumは会員間の支払いについて、送金・保管・返金・エスクローなどを行いません。カード番号・暗証番号・送金用QRやリンクなど、危険な情報は送らないでください。",
  },
];

const REPORT: QA[] = [
  {
    q: "どんな内容を通報できますか？",
    a: "嫌がらせ、なりすまし、個人情報の公開、危険な合流誘導、不正なグッズ、権利侵害、スパム、外部サービスへの不自然な誘導などを通報できます。",
  },
  {
    q: "通報すると相手に知られますか？",
    a: "通報者の情報を相手に直接は伝えない形で確認します。ただし申告内容から相手が推測できる場合や、安全確保・法令対応のために必要な範囲で情報を扱う場合があります。",
  },
  {
    q: "ブロックするとどうなりますか？",
    a: "相手との表示ややり取りが制限され、検索結果・ホーム候補・通知などの一部が表示されなくなります。危険や規約違反が解消しない場合は、通報も利用してください。",
  },
];

const ACCOUNT: QA[] = [
  {
    q: "未成年でも利用できますか？",
    a: "親権者など法定代理人の同意を得たうえで利用してください。現地交換や位置情報などを使う場合は保護者と相談し、人通りの多い場所を選んでください。詳しくは利用規約をご確認ください。",
  },
  {
    q: "アカウントを削除できますか？",
    a: "アプリの設定画面から削除を開始できます。保存が続く場合がある情報や手順はサポート窓口をご確認ください。有料プランは、アカウント削除とは別にApp Storeから解約してください。",
  },
];

const ALL_QA = [...BASICS, ...GOODS, ...DEAL, ...SAFETY, ...REPORT, ...ACCOUNT];

export default function FaqPage() {
  return (
    <PublicPage>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "ホーム", path: "/" },
          { name: "よくある質問", path: "/faq" },
        ])}
      />
      <JsonLd data={faqPageJsonLd(ALL_QA)} />
      <FaqHero />
      <AnchorSection id="basics">
        <SectionHeading eyebrow="基本" title="Megrumについて" />
        <FaqList items={BASICS} />
      </AnchorSection>
      <AnchorSection id="goods" tone="white">
        <SectionHeading eyebrow="グッズ登録" title="登録・wishについて" />
        <FaqList items={GOODS} />
      </AnchorSection>
      <AnchorSection id="deal">
        <SectionHeading eyebrow="打診・取引" title="打診と取引チャット" />
        <FaqList items={DEAL} />
      </AnchorSection>
      <AnchorSection id="safety" tone="white">
        <SectionHeading eyebrow="現地・郵送と安全" title="安全に交換するために" />
        <FaqList items={SAFETY} />
        <div className="mt-6 flex flex-wrap gap-x-6 gap-y-2">
          <DetailLink href="/safety" label="安全への取り組み" />
          <DetailLink href="/guide/local" label="現地交換ガイド" />
          <DetailLink href="/guide/mail" label="郵送交換ガイド" />
        </div>
      </AnchorSection>
      <AnchorSection id="report">
        <SectionHeading eyebrow="通報・ブロック" title="困ったときは" />
        <FaqList items={REPORT} />
      </AnchorSection>
      <AnchorSection id="account" tone="white">
        <SectionHeading eyebrow="アカウント" title="アカウント・年齢について" />
        <FaqList items={ACCOUNT} />
      </AnchorSection>
      <PageEnd />
    </PublicPage>
  );
}

function FaqHero() {
  return (
    <section className="relative isolate overflow-hidden px-5 pb-6 pt-32 md:pt-36">
      <div className="absolute left-0 right-0 top-0 -z-10 h-56 bg-[radial-gradient(circle_at_32%_0%,rgba(166,149,216,0.20),transparent_58%),radial-gradient(circle_at_68%_8%,rgba(243,197,212,0.18),transparent_48%)]" />
      <div className="mx-auto w-full max-w-6xl">
        <nav aria-label="パンくず" className="text-[12px] font-bold text-slate-500">
          <Link href="/" className="transition hover:text-violet-700">
            ホーム
          </Link>
          <span className="mx-2 text-slate-300">/</span>
          <span className="text-slate-700">よくある質問</span>
        </nav>
        <h1 className="mt-5 max-w-3xl text-[34px] font-black leading-[1.16] tracking-tight text-slate-950 md:text-[48px]">
          よくある質問。
        </h1>
        <p className="mt-5 max-w-2xl text-[15px] font-medium leading-8 text-slate-600 md:text-[16px]">
          解決しない場合や、安全上の問題、不正利用、個人情報の誤公開、権利侵害の疑いがある場合は、アプリ内の通報機能または{" "}
          <TextLink href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</TextLink>{" "}
          へご連絡ください。パスワードや認証コードなど、対応に不要な情報は送らないでください。
        </p>
      </div>
    </section>
  );
}

function PageEnd() {
  return (
    <section className="px-5 pb-24 pt-6">
      <div className="mx-auto w-full max-w-6xl rounded-[28px] border border-slate-200 bg-white px-6 py-10 md:px-12 md:py-12">
        <p className="text-[14px] font-medium leading-8 text-slate-600">
          くわしい取り扱いは <TextLink href="/terms">利用規約</TextLink> と{" "}
          <TextLink href="/privacy">プライバシーポリシー</TextLink>{" "}
          を、ご相談は <TextLink href="/support">サポート窓口</TextLink>{" "}
          をご確認ください。
        </p>
        <div className="mt-8 flex flex-wrap items-center gap-4">
          <PrimaryCtaBlock placement="faq_end" />
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
