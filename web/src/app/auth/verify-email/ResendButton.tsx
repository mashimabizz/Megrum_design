"use client";

import { useEffect, useRef, useState } from "react";
import { resendVerification } from "@/app/auth/actions";
import { Spinner } from "@/components/auth/Spinner";
import { useRipple } from "@/components/auth/useRipple";

const COOLDOWN_SECONDS = 60;

/**
 * 認証メール再送ボタン（モックアップ AOSecondaryButton 準拠）
 * - 60秒のクールダウン付き
 * - 初期値は initialCooldown で指定可能（resend 直後は60秒）
 */
export function ResendButton({
  email,
  initialCooldown = 0,
}: {
  email: string;
  initialCooldown?: number;
}) {
  const [pending, setPending] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [cooldown, setCooldown] = useState(initialCooldown);

  useEffect(() => {
    if (cooldown <= 0) return;
    const timer = setInterval(() => {
      setCooldown((c) => Math.max(0, c - 1));
    }, 1000);
    return () => clearInterval(timer);
  }, [cooldown]);

  async function handleResend() {
    setPending(true);
    setMessage(null);
    setError(null);

    const formData = new FormData();
    formData.set("email", email);
    const result = await resendVerification(formData);

    setPending(false);
    if (result?.error) {
      setError(result.error);
    } else {
      setMessage("確認メールを再送しました");
      setCooldown(COOLDOWN_SECONDS);
    }
  }

  const disabled = pending || cooldown > 0;
  const ref = useRef<HTMLButtonElement>(null);
  const { trigger, renderRipples } = useRipple({
    color: "bg-megrum-lavender/25",
  });

  return (
    <div>
      <button
        ref={ref}
        type="button"
        onClick={handleResend}
        onMouseDown={(e) => !disabled && trigger(e, ref.current)}
        disabled={disabled}
        className="relative flex w-full items-center justify-center gap-2.5 overflow-hidden rounded-[14px] border-[1.5px] border-solid border-[#a695d855] bg-white px-4 py-[13px] text-sm font-bold text-gray-900 transition-all duration-150 hover:bg-[#a695d80d] hover:border-[#a695d899] active:scale-[0.97] disabled:cursor-not-allowed disabled:opacity-50"
      >
        <span className="relative z-10 flex items-center gap-2">
          {pending ? (
            <>
              <Spinner size={16} />
              <span>送信中...</span>
            </>
          ) : cooldown > 0 ? (
            <span>再送信する（あと {cooldown} 秒）</span>
          ) : (
            <span>再送信する</span>
          )}
        </span>
        {renderRipples()}
      </button>
      {message && (
        <p className="mt-2 text-xs text-emerald-600">{message}</p>
      )}
      {error && <p className="mt-2 text-xs text-red-600">{error}</p>}
    </div>
  );
}
