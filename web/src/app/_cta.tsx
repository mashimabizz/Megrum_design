"use client";

import { track } from "./_analytics";
import { primaryCta } from "./_siteConfig";

/**
 * 主CTA（notes/82 §6）。フェーズ連動で公式Xフォロー↔App Store を切り替える。
 * href 未確定（App Store ID 未設定など）の場合は何も描画しない
 * = 存在しないダウンロード先へのリンクを作らない（notes/82 §1 役割2）。
 *
 * クリック時に計測境界 track() を呼ぶ（現状 no-op・§6-1）。
 */
export function PrimaryCta({
  placement,
  size = "lg",
  className = "",
}: {
  /** 計測用の設置場所ラベル（例: "hero" / "header" / "closing"） */
  placement: string;
  size?: "lg" | "sm";
  className?: string;
}) {
  const cta = primaryCta();
  if (!cta.href) return null;

  const dims =
    size === "lg"
      ? "px-6 py-3.5 text-[15px]"
      : "px-4 py-2.5 text-[13px]";

  const base =
    "inline-flex items-center justify-center gap-2 rounded-[14px] font-black text-white " +
    "bg-gradient-to-r from-megrum-lavender to-megrum-sky " +
    "shadow-[0_14px_32px_rgba(166,149,216,0.36)] transition " +
    "hover:brightness-[1.03] active:scale-[0.98] " +
    "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-megrum-lavender";

  return (
    <a
      href={cta.href}
      target="_blank"
      rel="noopener noreferrer"
      onClick={() => track(cta.event, { placement })}
      className={[base, dims, className].filter(Boolean).join(" ")}
      aria-label={cta.label}
    >
      <CtaIcon kind={cta.kind} />
      {cta.label}
    </a>
  );
}

/** CTAの補足文（sublabel）付きの縦積みブロック。ヒーロー/クロージング用。 */
export function PrimaryCtaBlock({
  placement,
  className = "",
}: {
  placement: string;
  className?: string;
}) {
  const cta = primaryCta();
  if (!cta.href) return null;
  return (
    <div className={["flex flex-col items-start gap-2", className].filter(Boolean).join(" ")}>
      <PrimaryCta placement={placement} />
      <p className="text-[12px] font-semibold text-slate-500">{cta.sublabel}</p>
    </div>
  );
}

function CtaIcon({ kind }: { kind: "x_follow" | "app_store" }) {
  if (kind === "x_follow") {
    return (
      <svg
        aria-hidden="true"
        viewBox="0 0 24 24"
        className="size-4 fill-current"
      >
        <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24h-6.66l-5.214-6.817-5.966 6.817H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231 5.45-6.231Zm-1.161 17.52h1.833L7.084 4.126H5.117L17.083 19.77Z" />
      </svg>
    );
  }
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 24 24"
      className="size-4 fill-current"
    >
      <path d="M16.365 1.43c0 1.14-.417 2.2-1.11 3.02-.75.9-1.98 1.6-3.19 1.5-.14-1.11.43-2.28 1.09-3.04.75-.86 2.06-1.5 3.21-1.48ZM20.9 17.02c-.55 1.28-.82 1.85-1.53 2.98-.99 1.58-2.39 3.54-4.12 3.55-1.54.02-1.94-1.01-4.03-1-2.09.01-2.53 1.02-4.07 1-1.73-.02-3.05-1.79-4.04-3.36-2.77-4.41-3.06-9.58-1.35-12.33 1.21-1.95 3.13-3.09 4.93-3.09 1.84 0 2.99 1.01 4.51 1.01 1.47 0 2.37-1.01 4.5-1.01 1.61 0 3.31.88 4.53 2.39-3.98 2.18-3.33 7.85.67 9.86Z" />
    </svg>
  );
}
