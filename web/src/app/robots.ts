import type { MetadataRoute } from "next";
import { SITE_URL } from "./_publicComponents";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: [
        "/",
        "/operator",
        "/privacy",
        "/support",
        "/terms",
        "/site-assets/",
      ],
      disallow: ["/admin", "/auth", "/login", "/password-reset"],
    },
    sitemap: `${SITE_URL}/sitemap.xml`,
    host: SITE_URL,
  };
}
