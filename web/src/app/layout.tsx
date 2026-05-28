import type { Metadata } from "next";
import { Noto_Sans_JP, Inter_Tight } from "next/font/google";
import { BottomNavTransitionBridge } from "@/components/home/BottomNavTransitionBridge";
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
  title: "Megrum — 推し活グッズ交換",
  description: "K-POP / アニメ等のファンが現地でグッズを交換するプラットフォーム",
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
        <BottomNavTransitionBridge />
        {children}
      </body>
    </html>
  );
}
