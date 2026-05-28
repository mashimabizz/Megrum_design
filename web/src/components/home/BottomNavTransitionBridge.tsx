"use client";

import { useEffect, useRef } from "react";
import { usePathname } from "next/navigation";
import { consumeBottomNavTransitionFlag } from "@/components/home/BottomNav";

/**
 * BottomNav 経由の画面遷移だけ、次ページの入りを軽く整える。
 * 通常の戻る/詳細遷移には影響させないため sessionStorage のフラグで限定する。
 */
export function BottomNavTransitionBridge() {
  const pathname = usePathname();
  const mountedRef = useRef(false);

  useEffect(() => {
    if (!mountedRef.current) {
      mountedRef.current = true;
      return;
    }

    if (!consumeBottomNavTransitionFlag()) return;

    const body = window.document.body;
    body.classList.remove("megrum-bottom-nav-loading");
    body.classList.remove("megrum-bottom-nav-transitioning");
    body.classList.add("megrum-bottom-nav-route-entering");

    const timer = window.setTimeout(() => {
      body.classList.remove("megrum-bottom-nav-route-entering");
    }, 520);

    return () => {
      window.clearTimeout(timer);
      body.classList.remove("megrum-bottom-nav-loading");
      body.classList.remove("megrum-bottom-nav-route-entering");
    };
  }, [pathname]);

  return null;
}
