"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";

const BOTTOM_NAV_TRANSITION_KEY = "megrum-bottom-nav-transition";

/**
 * ボトムナビ
 *
 * MVP の主要タブ: ホーム / 取引 / 在庫 / wish / プロフ
 *
 * inline=true の時は fixed コンテナを描画せずリンク行のみ返す
 * （InventoryFooter のように親が一体化フッターを持つ場合に使う）
 */
export function BottomNav({ inline = false }: { inline?: boolean } = {}) {
  const pathname = usePathname();
  const [optimisticTarget, setOptimisticTarget] = useState<{
    href: string;
    fromPath: string;
  } | null>(null);

  // iter65.8: AW タブを削除（現地交換モードはホーム画面で完結）
  // iter67-E: 「取引」タブを追加（中央配置）
  // iter126: WISH と 取引 の位置を入れ替え（wish が 在庫 の隣に来る方が動線として自然）
  const items = [
    { href: "/", label: "ホーム", icon: "home" as const },
    { href: "/inventory", label: "在庫", icon: "inventory" as const },
    { href: "/wishes", label: "wish", icon: "wish" as const },
    { href: "/transactions", label: "取引", icon: "transactions" as const },
    { href: "/profile", label: "プロフ", icon: "profile" as const },
  ];

  const visualPathname =
    optimisticTarget?.fromPath === pathname ? optimisticTarget.href : pathname;
  const activeItemIndex = items.findIndex((it) =>
    it.href === "/"
      ? visualPathname === "/"
      : visualPathname.startsWith(it.href),
  );
  const activeIndex = Math.max(0, activeItemIndex);

  const links = items.map((it, index) => {
    const actualActive =
      it.href === "/" ? pathname === "/" : pathname.startsWith(it.href);
    const visualActive =
      it.href === "/"
        ? visualPathname === "/"
        : visualPathname.startsWith(it.href);
    return (
      <Link
        key={it.href}
        href={it.href}
        scroll={false}
        transitionTypes={["megrum-bottom-nav"]}
        onNavigate={() => {
          if (!actualActive) {
            setOptimisticTarget({ href: it.href, fromPath: pathname });
            markBottomNavNavigation();
          }
        }}
        className={`relative z-10 flex h-[54px] flex-1 flex-col items-center justify-center gap-[3px] rounded-full text-[9.5px] leading-none transition-[color,transform,filter] duration-300 active:scale-[0.94] ${
          visualActive
            ? "font-extrabold text-megrum-lavender drop-shadow-[0_2px_7px_rgba(58,50,74,0.18)]"
            : "font-bold text-[#3a324a99]"
        }`}
        aria-current={actualActive ? "page" : undefined}
        style={{
          transitionDelay: visualActive ? "50ms" : `${index * 12}ms`,
        }}
      >
        <span
          className={`flex h-[25px] w-[25px] items-center justify-center rounded-full transition-transform duration-300 ${
            visualActive ? "-translate-y-0.5 scale-105" : "scale-95"
          }`}
        >
          <NavIcon name={it.icon} />
        </span>
        <span>{it.label}</span>
      </Link>
    );
  });

  const rail = (
    <div className="relative h-[66px] overflow-hidden rounded-full border border-white/65 bg-white/58 p-1.5 shadow-[0_18px_45px_rgba(58,50,74,0.18),0_4px_13px_rgba(255,255,255,0.62),inset_0_1px_0_rgba(255,255,255,0.86),inset_0_-1px_0_rgba(58,50,74,0.08)] backdrop-blur-[26px] backdrop-saturate-[190%]">
      <div className="pointer-events-none absolute inset-0 rounded-full bg-[linear-gradient(135deg,rgba(255,255,255,0.78),rgba(255,255,255,0.22)_42%,rgba(255,255,255,0.52))]" />
      <div className="pointer-events-none absolute inset-x-4 top-1 h-px bg-white/80" />
      <div
        className={`pointer-events-none absolute inset-y-1.5 left-1.5 rounded-full bg-white/64 shadow-[0_10px_26px_rgba(58,50,74,0.16),inset_0_1px_0_rgba(255,255,255,0.92),inset_0_-1px_0_rgba(58,50,74,0.05)] backdrop-blur-[18px] transition-[transform,opacity] duration-500 ease-[cubic-bezier(0.2,1,0.22,1)] motion-reduce:transition-none ${
          activeItemIndex >= 0 ? "opacity-100" : "opacity-0"
        }`}
        style={{
          width: `calc((100% - 12px) / ${items.length})`,
          transform: `translate3d(${activeIndex * 100}%, 0, 0)`,
        }}
      />
      <div className="relative flex h-full items-center">{links}</div>
    </div>
  );

  if (inline) {
    return rail;
  }

  return (
    <nav className="pointer-events-none fixed inset-x-0 bottom-0 z-40 pb-[calc(env(safe-area-inset-bottom)+10px)]">
      <div className="pointer-events-auto mx-auto max-w-md px-4">
        <div className="mx-auto w-full max-w-[400px]">{rail}</div>
      </div>
    </nav>
  );
}

function markBottomNavNavigation() {
  if (typeof window === "undefined") return;
  window.document.body.classList.add("megrum-bottom-nav-loading");
  window.document.body.classList.add("megrum-bottom-nav-transitioning");
  try {
    window.sessionStorage.setItem(BOTTOM_NAV_TRANSITION_KEY, "1");
  } catch {
    // sessionStorage が使えない環境でもナビゲーション自体は続行する。
  }
  window.setTimeout(() => {
    window.document.body.classList.remove("megrum-bottom-nav-loading");
    window.document.body.classList.remove("megrum-bottom-nav-transitioning");
  }, 900);
}

export function consumeBottomNavTransitionFlag() {
  if (typeof window === "undefined") return false;
  try {
    const shouldAnimate =
      window.sessionStorage.getItem(BOTTOM_NAV_TRANSITION_KEY) === "1";
    window.sessionStorage.removeItem(BOTTOM_NAV_TRANSITION_KEY);
    return shouldAnimate;
  } catch {
    return false;
  }
}

function NavIcon({
  name,
}: {
  name: "home" | "inventory" | "transactions" | "wish" | "profile";
}) {
  switch (name) {
    case "transactions":
      return (
        <svg
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          {/* 双方向矢印（取引のシンボル） */}
          <path d="M7 7h12m-3-3l3 3-3 3" />
          <path d="M17 17H5m3-3l-3 3 3 3" />
        </svg>
      );
    case "home":
      return (
        <svg
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M3 11l9-8 9 8v10a2 2 0 01-2 2h-4v-7h-6v7H5a2 2 0 01-2-2V11z" />
        </svg>
      );
    case "inventory":
      return (
        <svg
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <rect x="3" y="7" width="18" height="13" rx="2" />
          <path d="M3 11h18M9 7V4h6v3" />
        </svg>
      );
    case "wish":
      return (
        <svg
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M12 2l2.5 5.5L20 9l-4.5 3.8L17 19l-5-3-5 3 1.5-6.2L4 9l5.5-1.5z" />
        </svg>
      );
    case "profile":
      return (
        <svg
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <circle cx="12" cy="8" r="4" />
          <path d="M4 21a8 8 0 0116 0" />
        </svg>
      );
  }
}
