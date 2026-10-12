import type { Metadata } from "next";
import Link from "next/link";

import { JsonLd, PublicPage } from "../_publicComponents";
import { breadcrumbJsonLd, buildMetadata } from "../_siteConfig";
import { ArticleCard } from "./_ArticleCard";
import { getPublishedArticles } from "./_articles";

export const metadata: Metadata = buildMetadata({
  title: "記事",
  description:
    "推し活グッズ交換を安全・スムーズに進めるための記事。安全・トラブル対策、交換ノウハウ、現場Tips、Megrumの使い方をまとめています。",
  path: "/articles",
});

export default function ArticlesPage() {
  const articles = getPublishedArticles();
  return (
    <PublicPage>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "ホーム", path: "/" },
          { name: "記事", path: "/articles" },
        ])}
      />
      <section className="relative isolate overflow-hidden px-5 pb-6 pt-32 md:pt-36">
        <div className="absolute left-0 right-0 top-0 -z-10 h-56 bg-[radial-gradient(circle_at_32%_0%,rgba(166,149,216,0.20),transparent_58%),radial-gradient(circle_at_68%_8%,rgba(168,212,230,0.16),transparent_48%)]" />
        <div className="mx-auto w-full max-w-6xl">
          <nav aria-label="パンくず" className="text-[12px] font-bold text-slate-500">
            <Link href="/" className="transition hover:text-violet-700">
              ホーム
            </Link>
            <span className="mx-2 text-slate-300">/</span>
            <span className="text-slate-700">記事</span>
          </nav>
          <h1 className="mt-5 text-[34px] font-black leading-[1.16] tracking-tight text-slate-950 md:text-[48px]">
            記事
          </h1>
          <p className="mt-5 max-w-2xl text-[15px] font-medium leading-8 text-slate-600 md:text-[16px]">
            交換を、もっと安心でスムーズに。安全・トラブル対策や交換のコツ、Megrumの使い方をまとめています。
          </p>
        </div>
      </section>

      <section className="px-5 pb-24 pt-10">
        <div className="mx-auto w-full max-w-6xl">
          {articles.length === 0 ? (
            <div className="rounded-2xl border border-slate-200 bg-white p-10 text-center">
              <p className="text-[15px] font-bold text-slate-700">
                記事は準備中です。
              </p>
              <p className="mt-2 text-[13px] font-medium text-slate-500">
                安全な交換のコツから順に公開していきます。
              </p>
            </div>
          ) : (
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {articles.map((article) => (
                <ArticleCard key={article.slug} article={article} />
              ))}
            </div>
          )}
        </div>
      </section>
    </PublicPage>
  );
}
