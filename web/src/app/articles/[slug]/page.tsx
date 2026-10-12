import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";

import { PrimaryCtaBlock } from "../../_cta";
import { JsonLd, PublicPage } from "../../_publicComponents";
import { breadcrumbJsonLd, buildMetadata, SITE_URL } from "../../_siteConfig";
import { ArticleCard } from "../_ArticleCard";
import {
  getArticleBySlug,
  getPublishedArticles,
  getRelatedArticles,
} from "../_articles";
import { Markdown } from "../_markdown";

const FEATURE_LABELS: Record<string, string> = {
  "share-image": "シェア画像",
  matching: "候補と打診",
  trade: "取引・交換",
  meguri: "めぐり",
  safety: "安全",
};

export function generateStaticParams() {
  return getPublishedArticles().map((article) => ({ slug: article.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const article = getArticleBySlug(slug);
  if (!article) return {};
  return buildMetadata({
    title: article.title,
    description: article.description,
    path: `/articles/${slug}`,
    ogImage: article.coverImage,
  });
}

export default async function ArticleDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const article = getArticleBySlug(slug);
  if (!article) notFound();

  const related = getRelatedArticles(slug, article.category);
  const relatedFeatures = article.relatedFeatures.filter(
    (key) => key in FEATURE_LABELS,
  );

  const articleLd = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: article.title,
    description: article.description,
    datePublished: article.publishedAt,
    dateModified: article.updatedAt,
    author: { "@type": "Organization", name: article.author },
    mainEntityOfPage: `${SITE_URL}/articles/${slug}`,
    ...(article.coverImage
      ? { image: `${SITE_URL}${article.coverImage}` }
      : {}),
  };

  return (
    <PublicPage>
      <JsonLd
        data={breadcrumbJsonLd([
          { name: "ホーム", path: "/" },
          { name: "記事", path: "/articles" },
          { name: article.title, path: `/articles/${slug}` },
        ])}
      />
      <JsonLd data={articleLd} />

      <article className="px-5 pb-16 pt-32 md:pt-36">
        <div className="mx-auto w-full max-w-3xl">
          <nav aria-label="パンくず" className="text-[12px] font-bold text-slate-500">
            <Link href="/" className="transition hover:text-violet-700">
              ホーム
            </Link>
            <span className="mx-2 text-slate-300">/</span>
            <Link href="/articles" className="transition hover:text-violet-700">
              記事
            </Link>
            <span className="mx-2 text-slate-300">/</span>
            <span className="text-slate-700">{article.category}</span>
          </nav>

          <span className="mt-6 inline-block rounded-full bg-megrum-lavender/10 px-3 py-1 text-[11px] font-bold text-violet-700">
            {article.category}
          </span>
          <h1 className="mt-4 text-[30px] font-black leading-[1.2] tracking-tight text-slate-950 md:text-[40px]">
            {article.title}
          </h1>
          <p className="mt-4 text-[12px] font-bold text-slate-400">
            公開 {article.publishedAt}
            {article.updatedAt !== article.publishedAt && (
              <span> ・ 更新 {article.updatedAt}</span>
            )}
          </p>

          <div className="mt-8">
            <Markdown content={article.content} />
          </div>

          {relatedFeatures.length > 0 && (
            <div className="mt-10 rounded-2xl border border-slate-200 bg-white p-5">
              <p className="text-[12px] font-black uppercase tracking-normal text-violet-700">
                関連する機能
              </p>
              <div className="mt-3 flex flex-wrap gap-2">
                {relatedFeatures.map((key) => (
                  <Link
                    key={key}
                    href={`/features#${key}`}
                    className="rounded-full border border-slate-200 px-3 py-1.5 text-[12px] font-bold text-slate-700 transition hover:border-megrum-lavender/50 hover:text-violet-700"
                  >
                    {FEATURE_LABELS[key]}
                  </Link>
                ))}
              </div>
            </div>
          )}
        </div>
      </article>

      {related.length > 0 && (
        <section className="bg-white px-5 py-16">
          <div className="mx-auto w-full max-w-6xl">
            <h2 className="text-[20px] font-black tracking-tight text-slate-950">
              関連記事
            </h2>
            <div className="mt-6 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
              {related.map((item) => (
                <ArticleCard key={item.slug} article={item} />
              ))}
            </div>
          </div>
        </section>
      )}

      <section className="px-5 pb-24 pt-10">
        <div className="mx-auto w-full max-w-3xl rounded-[28px] border border-slate-200 bg-white px-6 py-10 md:px-10">
          <div className="flex flex-wrap items-center gap-4">
            <PrimaryCtaBlock placement="article_end" />
            <Link
              href="/articles"
              className="text-[13px] font-bold text-violet-700 underline decoration-megrum-lavender/40 underline-offset-4 transition hover:text-violet-900"
            >
              記事一覧へ
            </Link>
          </div>
        </div>
      </section>
    </PublicPage>
  );
}
