import Image from "next/image";
import Link from "next/link";

import type { ArticleMeta } from "./_articles";

export function ArticleCard({ article }: { article: ArticleMeta }) {
  return (
    <Link
      href={`/articles/${article.slug}`}
      className="group flex flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white transition hover:border-megrum-lavender/50 hover:shadow-[0_16px_40px_rgba(58,50,74,0.08)]"
    >
      <div className="relative flex aspect-[16/9] items-center justify-center overflow-hidden bg-gradient-to-br from-megrum-lavender/12 to-megrum-sky/12">
        {article.coverImage ? (
          <Image
            src={article.coverImage}
            alt=""
            fill
            sizes="(max-width: 768px) 100vw, 33vw"
            className="object-cover"
          />
        ) : (
          <span className="font-[var(--font-inter-tight)] text-[15px] font-black text-megrum-lavender/70">
            Megrum
          </span>
        )}
      </div>
      <div className="flex flex-1 flex-col p-5">
        <span className="w-fit rounded-full bg-megrum-lavender/10 px-2.5 py-1 text-[11px] font-bold text-violet-700">
          {article.category}
        </span>
        <h3 className="mt-3 text-[16px] font-black leading-snug text-slate-900 group-hover:text-violet-700">
          {article.title}
        </h3>
        <p className="mt-2 line-clamp-2 text-[13px] font-medium leading-6 text-slate-600">
          {article.description}
        </p>
        <time
          className="mt-4 text-[11px] font-bold text-slate-400"
          dateTime={article.publishedAt}
        >
          {article.publishedAt}
        </time>
      </div>
    </Link>
  );
}
