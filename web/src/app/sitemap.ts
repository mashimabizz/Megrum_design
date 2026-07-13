import type { MetadataRoute } from "next";

import { SITE_URL } from "./_publicComponents";
import { getPublishedArticles } from "./articles/_articles";

const staticRoutes = [
  "",
  "/features",
  "/safety",
  "/faq",
  "/articles",
  "/guide/local",
  "/guide/mail",
  "/operator",
  "/privacy",
  "/support",
  "/terms",
];

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date("2026-07-13T00:00:00+09:00");

  const staticEntries: MetadataRoute.Sitemap = staticRoutes.map((route) => ({
    url: `${SITE_URL}${route}`,
    lastModified,
    changeFrequency: "monthly",
    priority: route === "" ? 1 : 0.8,
  }));

  const articleEntries: MetadataRoute.Sitemap = getPublishedArticles().map(
    (article) => ({
      url: `${SITE_URL}/articles/${article.slug}`,
      lastModified: new Date(`${article.updatedAt}T00:00:00+09:00`),
      changeFrequency: "monthly",
      priority: 0.6,
    }),
  );

  return [...staticEntries, ...articleEntries];
}
