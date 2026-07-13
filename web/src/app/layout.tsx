import type { Metadata } from "next";
import { Noto_Sans_JP, Inter_Tight } from "next/font/google";
import "./globals.css";

const notoSansJP = Noto_Sans_JP({
  variable: "--font-noto-sans-jp",
  subsets: ["latin"],
  weight: ["400", "500", "700", "800"],
});

// MegrumLogo の "Mg" 表示用（モックアップ AOLogo 準拠）
const interTight = Inter_Tight({
  variable: "--font-inter-tight",
  subsets: ["latin"],
  weight: ["700", "800"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://megrum.jp"),
  title: {
    default: "Megrum | 推し活グッズの交換アプリ",
    template: "%s | Megrum",
  },
  description:
    "Megrumは、推し活グッズの登録、ほしいもの、打診、取引チャット、現地交換・郵送交換をまとめて扱うiOSアプリです。",
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "Megrum",
    description:
      "推し活グッズの交換を、現地でも郵送でも安心して進めるためのiOSアプリ。",
    url: "https://megrum.jp",
    siteName: "Megrum",
    locale: "ja_JP",
    type: "website",
    images: [
      {
        url: "/site-assets/megrum-icon.png",
        width: 512,
        height: 512,
        alt: "Megrum app icon",
      },
    ],
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="ja"
      className={`${notoSansJP.variable} ${interTight.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col font-sans">
        {children}
      </body>
    </html>
  );
}
