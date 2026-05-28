"use client";

import Link from "next/link";
import {
  useRef,
  type ButtonHTMLAttributes,
  type MouseEvent,
  type ReactNode,
} from "react";
import { Spinner } from "./Spinner";
import { useRipple } from "./useRipple";

/**
 * モックアップ AOPrimaryButton 完全準拠：
 * - linear-gradient(135deg, #a695d8, #a8d4e6) = lavender→sky の 2色グラデ
 *   ※ ピンクは入らない（cool-tone 寄り）
 * - 影：0 4px 14px rgba(166,149,216,0.33)
 * - rounded-[14px] / padding 15px 24px / fontSize 14px / letterSpacing 0.3px
 */
const baseClass =
  "relative block w-full overflow-hidden rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-6 py-[15px] text-center text-sm font-bold tracking-[0.3px] text-white shadow-[0_4px_14px_rgba(166,149,216,0.33)] transition-all duration-150 hover:brightness-105 active:scale-[0.97] disabled:cursor-not-allowed disabled:opacity-50";

/**
 * モックアップ AOSecondaryButton 完全準拠：
 * - 白背景 + 1.5px 紫透明枠（#a695d855 = lavender 33%）+ 黒テキスト
 * - rounded-[14px] / fontSize 14px / padding 13px 16px / gap 10
 *
 * 用途: Google ログイン、再送信ボタン等
 */
export const secondaryBaseClass =
  "relative flex w-full items-center justify-center gap-2.5 overflow-hidden rounded-[14px] border-[1.5px] border-solid border-[#a695d855] bg-white px-4 py-[13px] text-sm font-bold text-gray-900 transition-all duration-150 hover:bg-[#a695d80d] hover:border-[#a695d899] active:scale-[0.97] disabled:cursor-not-allowed disabled:opacity-50";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  pending?: boolean;
  pendingLabel?: string;
  children: ReactNode;
};

/**
 * Megrum プライマリボタン
 * - A: active:scale-[0.97] でタクタイル感
 * - B: pending 中スピナー
 * - F: pending 中の色シフト
 * - Ripple: クリック位置から波紋（Material Design 風）
 */
export function PrimaryButton({
  pending = false,
  pendingLabel,
  children,
  disabled,
  className = "",
  onMouseDown,
  ...rest
}: ButtonProps) {
  const ref = useRef<HTMLButtonElement>(null);
  const { trigger, renderRipples } = useRipple();

  function handleMouseDown(e: MouseEvent<HTMLButtonElement>) {
    if (!disabled && !pending) {
      trigger(e, ref.current);
    }
    onMouseDown?.(e);
  }

  return (
    <button
      {...rest}
      ref={ref}
      disabled={disabled || pending}
      onMouseDown={handleMouseDown}
      className={`${baseClass} ${className}`}
    >
      <span className="relative z-10">
        {pending ? (
          <span className="flex items-center justify-center gap-2">
            <Spinner size={20} />
            <span>{pendingLabel ?? children}</span>
          </span>
        ) : (
          children
        )}
      </span>
      {renderRipples()}
    </button>
  );
}

type LinkProps = {
  href: string;
  children: ReactNode;
  className?: string;
};

/**
 * Megrum プライマリリンク（ボタン見た目の Link）
 * - active:scale-[0.97] + Ripple
 */
export function PrimaryLinkButton({
  href,
  children,
  className = "",
}: LinkProps) {
  const ref = useRef<HTMLAnchorElement>(null);
  const { trigger, renderRipples } = useRipple();

  return (
    <Link
      href={href}
      ref={ref}
      onMouseDown={(e) => trigger(e, ref.current)}
      className={`${baseClass} ${className}`}
    >
      <span className="relative z-10">{children}</span>
      {renderRipples()}
    </Link>
  );
}
