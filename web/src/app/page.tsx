import Image from "next/image";
import Link from "next/link";
import { PublicPage, Section, TextLink } from "./_publicComponents";

const features = [
  {
    title: "マイグッズとwishをまとめる",
    text: "譲れるグッズ、求めているグッズ、個別の条件を登録し、候補探しの土台を作ります。",
  },
  {
    title: "候補を見て打診する",
    text: "交換しやすい候補を見ながら、提示物、受け取る物、待ち合わせ条件を含めて打診できます。",
  },
  {
    title: "取引チャットで進める",
    text: "合意前の調整から成立後の連絡まで、取引チャットで文脈を残しながら進めます。",
  },
  {
    title: "現地交換を支える",
    text: "待ち合わせ、到着状況、任意の現在地共有、服装写真など、当日の合流を補助します。",
  },
];

const publicInfo = [
  {
    title: "プライバシーポリシー",
    text: "取得する情報、利用目的、位置情報や写真の扱い、開示等の請求窓口を明示しています。",
    href: "/privacy",
  },
  {
    title: "サポート窓口",
    text: "問い合わせ、通報相談、アカウント削除、個人情報に関する請求を受け付けます。",
    href: "/support",
  },
  {
    title: "利用規約",
    text: "Megrumの利用条件、禁止事項、取引上の注意、アカウントに関するルールを掲載しています。",
    href: "/terms",
  },
];

export default function HomePage() {
  return (
    <PublicPage>
      <section className="relative isolate min-h-[86svh] overflow-hidden px-5 pb-14 pt-32 md:pb-20 md:pt-36">
        <div className="absolute inset-0 -z-20 bg-[#fbf9fc]" />
        <Image
          src="/site-assets/app-home.png"
          alt="Megrumのホーム画面。自分の条件に合うグッズ候補が並んでいる。"
          width={853}
          height={1844}
          priority
          className="absolute bottom-[-10%] right-[-54%] -z-10 h-[70%] w-auto max-w-none rounded-[32px] object-contain opacity-35 shadow-[0_28px_80px_rgba(58,50,74,0.18)] sm:right-[-18%] sm:h-[84%] sm:opacity-60 md:bottom-[-20%] md:right-[4%] md:h-[104%] md:opacity-[0.9]"
        />
        <div className="absolute inset-0 -z-10 bg-[linear-gradient(90deg,#fbf9fc_0%,rgba(251,249,252,0.95)_38%,rgba(251,249,252,0.62)_70%,rgba(251,249,252,0.38)_100%)]" />
        <div className="absolute left-0 right-0 top-0 -z-10 h-48 bg-[radial-gradient(circle_at_35%_0%,rgba(166,149,216,0.24),transparent_58%),radial-gradient(circle_at_62%_8%,rgba(243,197,212,0.22),transparent_46%)]" />

        <div className="mx-auto flex w-full max-w-6xl flex-col justify-center">
          <div className="max-w-2xl">
            <p className="text-[12px] font-black uppercase tracking-normal text-violet-700">
              iOS app for oshi goods exchange
            </p>
            <h1 className="mt-4 text-[42px] font-black leading-[1.05] tracking-normal text-slate-950 md:text-[68px]">
              推し活グッズの交換を、現地で安心して進める。
            </h1>
            <p className="mt-6 max-w-xl text-[16px] font-medium leading-8 text-slate-700 md:text-[18px]">
              Megrumは、K-POPやアニメなどの推し活グッズを登録し、wishや候補から打診して、取引チャットで現地交換まで進めるためのiOSアプリです。
            </p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link
                href="/privacy"
                className="inline-flex h-12 items-center justify-center rounded-lg bg-slate-950 px-5 text-[13px] font-black text-white shadow-[0_16px_40px_rgba(58,50,74,0.22)] transition hover:bg-violet-950"
              >
                プライバシーポリシーを見る
              </Link>
              <Link
                href="/support"
                className="inline-flex h-12 items-center justify-center rounded-lg border border-slate-300 bg-white/80 px-5 text-[13px] font-black text-slate-900 backdrop-blur transition hover:border-megrum-lavender/60 hover:text-violet-800"
              >
                問い合わせる
              </Link>
            </div>
          </div>
        </div>
      </section>

      <Section
        eyebrow="Service"
        title="グッズ登録から当日の合流まで、iOSアプリの中でつながる。"
        description="Megrumは通常ユーザー向けWebアプリではなく、iOSアプリを主な利用体験として提供します。このWebサイトは、サービス内容、サポート窓口、法務情報を公開する公式サイトです。"
      >
        <div className="mt-10 grid gap-4 md:grid-cols-4">
          {features.map((feature) => (
            <article
              key={feature.title}
              className="rounded-lg border border-slate-200 bg-white p-5 shadow-[0_12px_32px_rgba(58,50,74,0.05)]"
            >
              <h3 className="text-[16px] font-black tracking-normal text-slate-950">
                {feature.title}
              </h3>
              <p className="mt-3 text-[13px] font-medium leading-7 text-slate-600">
                {feature.text}
              </p>
            </article>
          ))}
        </div>
      </Section>

      <section className="bg-white px-5 py-16 md:py-20">
        <div className="mx-auto grid w-full max-w-6xl gap-10 md:grid-cols-[0.9fr_1.1fr] md:items-center">
          <div>
            <p className="text-[12px] font-black uppercase tracking-normal text-violet-700">
              Matching and search
            </p>
            <h2 className="mt-3 text-[30px] font-black leading-tight tracking-normal text-slate-950 md:text-[42px]">
              交換できるかもしれないグッズを、画像で探しやすく。
            </h2>
            <p className="mt-4 text-[15px] font-medium leading-8 text-slate-600">
              検索結果や候補一覧では、グッズ画像、タグ、交換条件の一致状況を見ながら判断できます。条件が合いそうな相手へは、打診から取引チャットへ進みます。
            </p>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Image
              src="/site-assets/app-search-before.png"
              alt="Megrumの検索画面。推しやwish候補から探せる。"
              width={853}
              height={1844}
              className="h-auto w-full rounded-[28px] shadow-[0_20px_60px_rgba(58,50,74,0.14)]"
            />
            <Image
              src="/site-assets/app-search-results.png"
              alt="Megrumの検索結果画面。グッズが画像グリッドで並んでいる。"
              width={853}
              height={1844}
              className="mt-10 h-auto w-full rounded-[28px] shadow-[0_20px_60px_rgba(58,50,74,0.14)]"
            />
          </div>
        </div>
      </section>

      <Section
        eyebrow="Safety"
        title="プライバシーと連絡手段を、公開ページとして用意しています。"
        description="リリース後も利用者がいつでも確認できる公式情報として、継続運用する前提のページです。"
      >
        <div className="mt-10 grid gap-4 md:grid-cols-3">
          {publicInfo.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-lg border border-slate-200 bg-white p-5 shadow-[0_12px_32px_rgba(58,50,74,0.05)] transition hover:border-megrum-lavender/60"
            >
              <h3 className="text-[16px] font-black tracking-normal text-slate-950">
                {item.title}
              </h3>
              <p className="mt-3 text-[13px] font-medium leading-7 text-slate-600">
                {item.text}
              </p>
            </Link>
          ))}
        </div>
      </Section>

      <section className="bg-[linear-gradient(135deg,rgba(166,149,216,0.16),rgba(168,212,230,0.18),rgba(243,197,212,0.2))] px-5 py-16 md:py-20">
        <div className="mx-auto grid w-full max-w-6xl gap-10 md:grid-cols-[1fr_0.85fr] md:items-center">
          <div>
            <p className="text-[12px] font-black uppercase tracking-normal text-violet-700">
              Meguri
            </p>
            <h2 className="mt-3 text-[30px] font-black leading-tight tracking-normal text-slate-950 md:text-[42px]">
              交換だけでなく、現地の推し活のめぐりも扱います。
            </h2>
            <p className="mt-4 text-[15px] font-medium leading-8 text-slate-700">
              Megrumには、現地の推し活情報や近くの投稿を見つける「めぐり」体験もあります。公開範囲、位置情報、通報・ブロックなどの扱いは
              <TextLink href="/privacy">プライバシーポリシー</TextLink>
              で確認できます。
            </p>
          </div>
          <Image
            src="/site-assets/app-meguri.png"
            alt="Megrumのめぐりホーム画面。地図と現地の投稿が表示されている。"
            width={853}
            height={1844}
            className="mx-auto h-auto w-full max-w-[360px] rounded-[28px] shadow-[0_24px_70px_rgba(58,50,74,0.16)]"
          />
        </div>
      </section>
    </PublicPage>
  );
}
