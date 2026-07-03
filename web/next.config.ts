import path from "node:path";
import type { NextConfig } from "next";

const securityHeaders = [
  {
    key: "Strict-Transport-Security",
    value: "max-age=63072000; includeSubDomains; preload",
  },
  {
    key: "Content-Security-Policy",
    value: "base-uri 'self'; frame-ancestors 'none'; object-src 'none'; form-action 'self'",
  },
  {
    key: "X-Content-Type-Options",
    value: "nosniff",
  },
  {
    key: "X-Frame-Options",
    value: "DENY",
  },
  {
    key: "Referrer-Policy",
    value: "origin-when-cross-origin",
  },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(), browsing-topics=()",
  },
];

const privateNoStoreHeaders = [
  {
    key: "Cache-Control",
    value: "private, no-store, max-age=0",
  },
];

const nextConfig: NextConfig = {
  // Workspace root を明示的に web/ に固定（lockfile 検知の警告抑止）
  turbopack: {
    root: path.resolve(__dirname),
  },
  async headers() {
    return [
      {
        source: "/:path*",
        headers: securityHeaders,
      },
      {
        source: "/admin/:path*",
        headers: privateNoStoreHeaders,
      },
      {
        source: "/auth/:path*",
        headers: privateNoStoreHeaders,
      },
      {
        source: "/login",
        headers: privateNoStoreHeaders,
      },
      {
        source: "/password-reset",
        headers: privateNoStoreHeaders,
      },
      {
        source: "/password-reset-confirm",
        headers: privateNoStoreHeaders,
      },
    ];
  },
};

export default nextConfig;
