import type { Metadata } from "next";
import Link from "next/link";
import { PublicPage } from "./_publicComponents";

export const metadata: Metadata = {
  title: "ページが見つかりません",
  robots: {
    index: false,
    follow: false,
  },
};

export default function NotFound() {
  return (
    <PublicPage>
      <section className="px-5 pb-20 pt-32">
        <div className="mx-auto w-full max-w-4xl">
          <p className="text-[12px] font-black uppercase tracking-normal text-violet-700">
            404
          </p>
          <h1 className="mt-3 text-[34px] font-black leading-tight tracking-normal text-slate-950 md:text-[48px]">
            ページが見つかりません
          </h1>
          <p className="mt-6 max-w-2xl text-[15px] font-medium leading-8 text-slate-600">
            URLが変更されたか、ページが公開されていない可能性があります。
            Megrumの公式情報は、以下のページから確認できます。
          </p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <Link
              href="/"
              className="inline-flex h-12 items-center justify-center rounded-lg bg-slate-950 px-5 text-[13px] font-black text-white shadow-[0_16px_40px_rgba(58,50,74,0.22)] transition hover:bg-violet-950"
            >
              トップへ戻る
            </Link>
            <Link
              href="/support"
              className="inline-flex h-12 items-center justify-center rounded-lg border border-slate-300 bg-white px-5 text-[13px] font-black text-slate-900 transition hover:border-megrum-lavender/60 hover:text-violet-800"
            >
              サポートを見る
            </Link>
          </div>
        </div>
      </section>
    </PublicPage>
  );
}
