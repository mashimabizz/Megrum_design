import fs from "node:fs";
import path from "node:path";

/**
 * 記事の読み込み（notes/82 §4C）。
 * 正本は web/content/articles/*.md。ビルド時に fs で読み、frontmatter を
 * 自前パースする（依存追加なし・raw HTML を通さない方針）。
 */

export const ARTICLE_CATEGORIES = [
  "安全・トラブル対策",
  "交換ノウハウ",
  "推し活・現場Tips",
  "Megrumの使い方",
  "お知らせ",
] as const;

export interface ArticleMeta {
  slug: string;
  title: string;
  description: string;
  publishedAt: string;
  updatedAt: string;
  category: string;
  tags: string[];
  author: string;
  reviewedAt?: string;
  coverImage?: string;
  draft: boolean;
  relatedFeatures: string[];
}

export interface Article extends ArticleMeta {
  content: string;
}

const ARTICLES_DIR = path.join(process.cwd(), "content", "articles");

function parseFrontmatter(raw: string): {
  data: Record<string, unknown>;
  content: string;
} {
  const match = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/.exec(raw);
  if (!match) return { data: {}, content: raw };
  const [, frontmatter, body] = match;
  const data: Record<string, unknown> = {};
  for (const line of frontmatter.split(/\r?\n/)) {
    const kv = /^([A-Za-z0-9_]+):\s*(.*)$/.exec(line);
    if (!kv) continue;
    const key = kv[1];
    const rest = kv[2].trim();
    if (rest === "true" || rest === "false") {
      data[key] = rest === "true";
    } else if (rest.startsWith("[")) {
      try {
        data[key] = JSON.parse(rest);
      } catch {
        data[key] = [];
      }
    } else {
      data[key] = rest.replace(/^["']|["']$/g, "");
    }
  }
  return { data, content: body.trim() };
}

function toMeta(slug: string, data: Record<string, unknown>): ArticleMeta {
  return {
    slug,
    title: String(data.title ?? slug),
    description: String(data.description ?? ""),
    publishedAt: String(data.publishedAt ?? ""),
    updatedAt: String(data.updatedAt ?? data.publishedAt ?? ""),
    category: String(data.category ?? "お知らせ"),
    tags: Array.isArray(data.tags) ? (data.tags as string[]) : [],
    author: String(data.author ?? "Megrum編集部"),
    reviewedAt: data.reviewedAt ? String(data.reviewedAt) : undefined,
    coverImage: data.coverImage ? String(data.coverImage) : undefined,
    draft: data.draft === true,
    relatedFeatures: Array.isArray(data.relatedFeatures)
      ? (data.relatedFeatures as string[])
      : [],
  };
}

function readAll(): Article[] {
  let files: string[] = [];
  try {
    files = fs.readdirSync(ARTICLES_DIR);
  } catch {
    return [];
  }
  const articles: Article[] = [];
  for (const file of files) {
    if (!file.endsWith(".md") && !file.endsWith(".mdx")) continue;
    const slug = file.replace(/\.mdx?$/, "");
    const raw = fs.readFileSync(path.join(ARTICLES_DIR, file), "utf8");
    const { data, content } = parseFrontmatter(raw);
    articles.push({ ...toMeta(slug, data), content });
  }
  return articles;
}

/** 公開記事（draft 除外）を新着順で返す。 */
export function getPublishedArticles(): Article[] {
  return readAll()
    .filter((article) => !article.draft)
    .sort((a, b) => (a.publishedAt < b.publishedAt ? 1 : -1));
}

/** slug で公開記事を1件返す（draft/未存在は null）。 */
export function getArticleBySlug(slug: string): Article | null {
  return readAll().find((a) => a.slug === slug && !a.draft) ?? null;
}

/** 関連記事（同カテゴリ優先→新着）。自分を除外し最大 n 件。 */
export function getRelatedArticles(
  slug: string,
  category: string,
  n = 3,
): ArticleMeta[] {
  const others = getPublishedArticles().filter((a) => a.slug !== slug);
  const sameCategory = others.filter((a) => a.category === category);
  const rest = others.filter((a) => a.category !== category);
  return [...sameCategory, ...rest].slice(0, n);
}
