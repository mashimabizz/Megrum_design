"use client";

import type { ReactNode } from "react";
import { createPortal } from "react-dom";

export type BottomActionSheetAction = {
  label: string;
  onClick: () => void;
  tone?: "primary" | "normal" | "danger" | "muted";
  disabled?: boolean;
};

export function BottomActionSheet({
  title,
  subtitle,
  imageUrl,
  fallbackLabel,
  meta,
  actions,
  onClose,
}: {
  title: string;
  subtitle?: string;
  imageUrl?: string | null;
  fallbackLabel: string;
  meta?: ReactNode;
  actions: BottomActionSheetAction[];
  onClose: () => void;
}) {
  const sheet = (
    <div
      className="animate-action-sheet-backdrop-in fixed inset-0 z-[110] flex items-end justify-center bg-black/45 px-0 backdrop-blur-[2px]"
      role="dialog"
      aria-modal="true"
      aria-label="アクションメニュー"
      onClick={onClose}
    >
      <div
        className="animate-action-sheet-in w-full max-w-md rounded-t-[28px] border border-white/80 bg-white px-4 pb-[calc(env(safe-area-inset-bottom)+14px)] pt-3 shadow-[0_-22px_54px_rgba(58,50,74,0.24)]"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mx-auto mb-3 h-1.5 w-10 rounded-full bg-[#3a324a1f]" />
        <div className="mb-3 flex items-center gap-3 rounded-2xl border border-[#3a324a10] bg-[#fbf9fc] px-3 py-2.5">
          {imageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={imageUrl}
              alt={title}
              className="h-14 w-11 flex-shrink-0 rounded-[10px] object-cover shadow-[0_3px_8px_rgba(58,50,74,0.16)]"
            />
          ) : (
            <div className="flex h-14 w-11 flex-shrink-0 items-center justify-center rounded-[10px] bg-megrum-lavender/20 text-[16px] font-extrabold text-megrum-lavender">
              {fallbackLabel[0] ?? "?"}
            </div>
          )}
          <div className="min-w-0 flex-1">
            <div className="truncate text-[14px] font-extrabold text-[#3a324a]">
              {title}
            </div>
            {subtitle && (
              <div className="mt-0.5 truncate text-[11px] font-medium text-[#3a324a8c]">
                {subtitle}
              </div>
            )}
          </div>
          {meta}
        </div>
        <div className="space-y-2">
          {actions.map((action) => (
            <button
              key={action.label}
              type="button"
              disabled={action.disabled}
              onClick={action.onClick}
              className={actionButtonClass(action.tone)}
            >
              {action.label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );

  // Card pop/bounce animations use transform, which can trap fixed children.
  // Portaling to body keeps the sheet anchored to the viewport, not the card.
  if (typeof document === "undefined") return null;
  return createPortal(sheet, document.body);
}

function actionButtonClass(tone: BottomActionSheetAction["tone"]) {
  const base =
    "flex h-12 w-full items-center justify-center rounded-[14px] text-[14px] font-extrabold transition-transform active:scale-[0.985] disabled:opacity-45";
  switch (tone) {
    case "primary":
      return `${base} bg-gradient-to-r from-megrum-lavender to-megrum-sky text-white shadow-[0_8px_18px_rgba(166,149,216,0.34)]`;
    case "danger":
      return `${base} bg-red-50 text-red-600`;
    case "muted":
      return `${base} bg-[#3a324a08] text-[#3a324a]`;
    default:
      return `${base} border border-[#3a324a10] bg-white text-[#3a324a]`;
  }
}
