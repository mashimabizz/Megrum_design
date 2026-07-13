import type { MetadataRoute } from "next";
import { SITE_URL } from "./_publicComponents";

const routes = [
  "",
  "/features",
  "/safety",
  "/operator",
  "/privacy",
  "/support",
  "/terms",
];

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date("2026-06-26T00:00:00+09:00");

  return routes.map((route) => ({
    url: `${SITE_URL}${route}`,
    lastModified,
    changeFrequency: "monthly",
    priority: route === "" ? 1 : 0.8,
  }));
}
