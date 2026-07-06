import Link from "next/link";
import type { ReactNode } from "react";

export function AdminPanel({
  title,
  description,
  children,
  action,
}: {
  title: string;
  description?: string;
  children: ReactNode;
  action?: ReactNode;
}) {
  return (
    <section className="rounded-lg border border-slate-200 bg-white">
      <div className="flex flex-col gap-2 border-b border-slate-100 px-4 py-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h2 className="text-[14px] font-bold text-slate-900">{title}</h2>
          {description && (
            <p className="mt-0.5 text-[11px] font-medium text-slate-500">
              {description}
            </p>
          )}
        </div>
        {action}
      </div>
      <div className="p-4">{children}</div>
    </section>
  );
}

export function AdminMetric({
  label,
  value,
  tone = "default",
}: {
  label: string;
  value: string | number;
  tone?: "default" | "warn" | "ok";
}) {
  const toneClass =
    tone === "warn"
      ? "border-megrum-pink/70 bg-megrum-pink/15 text-rose-700"
      : tone === "ok"
        ? "border-emerald-200 bg-emerald-50 text-emerald-800"
        : "border-megrum-sky/50 bg-megrum-sky/15 text-slate-900";

  return (
    <div className={`rounded-lg border px-4 py-3 ${toneClass}`}>
      <div className="text-[11px] font-bold text-slate-500">{label}</div>
      <div className="mt-1 text-[24px] font-black leading-none">{value}</div>
    </div>
  );
}

export function StatusPill({
  children,
  tone = "default",
}: {
  children: ReactNode;
  tone?: "default" | "warn" | "ok" | "mute";
}) {
  const toneClass =
    tone === "warn"
      ? "bg-megrum-pink/15 text-rose-700 ring-megrum-pink/70"
      : tone === "ok"
        ? "bg-emerald-50 text-emerald-700 ring-emerald-200"
        : tone === "mute"
          ? "bg-gray-100 text-gray-500 ring-gray-200"
          : "bg-megrum-lavender/15 text-violet-700 ring-megrum-lavender/30";

  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10.5px] font-bold ring-1 ${toneClass}`}
    >
      {children}
    </span>
  );
}

export function AdminTextInput({
  name,
  label,
  placeholder,
  required,
  defaultValue,
  type = "text",
}: {
  name: string;
  label: string;
  placeholder?: string;
  required?: boolean;
  defaultValue?: string;
  type?: string;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-[11px] font-bold text-slate-500">
        {label}
      </span>
      <input
        name={name}
        type={type}
        required={required}
        defaultValue={defaultValue}
        placeholder={placeholder}
        className="h-10 w-full rounded-lg border border-slate-200 bg-white px-3 text-[13px] font-semibold text-slate-900 outline-none focus:border-megrum-lavender focus:ring-2 focus:ring-megrum-lavender/20"
      />
    </label>
  );
}

export function AdminTextarea({
  name,
  label,
  placeholder,
  required,
  defaultValue,
  rows = 3,
}: {
  name: string;
  label: string;
  placeholder?: string;
  required?: boolean;
  defaultValue?: string;
  rows?: number;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-[11px] font-bold text-slate-500">
        {label}
      </span>
      <textarea
        name={name}
        required={required}
        defaultValue={defaultValue}
        placeholder={placeholder}
        rows={rows}
        className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-[13px] font-semibold text-slate-900 outline-none focus:border-megrum-lavender focus:ring-2 focus:ring-megrum-lavender/20"
      />
    </label>
  );
}

export function AdminSelect({
  name,
  label,
  children,
  defaultValue,
  required,
}: {
  name: string;
  label: string;
  children: ReactNode;
  defaultValue?: string;
  required?: boolean;
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-[11px] font-bold text-slate-500">
        {label}
      </span>
      <select
        name={name}
        defaultValue={defaultValue}
        required={required}
        className="h-10 w-full rounded-lg border border-slate-200 bg-white px-3 text-[13px] font-semibold text-slate-900 outline-none focus:border-megrum-lavender focus:ring-2 focus:ring-megrum-lavender/20"
      >
        {children}
      </select>
    </label>
  );
}

export function SubmitButton({ children }: { children: ReactNode }) {
  return (
    <button
      type="submit"
      className="inline-flex h-10 items-center justify-center rounded-lg bg-slate-900 px-4 text-[12px] font-black text-white transition active:scale-[0.99]"
    >
      {children}
    </button>
  );
}

export function AdminLinkButton({
  href,
  children,
}: {
  href: string;
  children: ReactNode;
}) {
  return (
    <Link
      href={href}
      className="inline-flex h-9 items-center rounded-lg border border-slate-200 bg-white px-3 text-[12px] font-bold text-slate-900 transition hover:border-megrum-lavender/50"
    >
      {children}
    </Link>
  );
}

export function formatDateTime(value: string | null | undefined) {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return new Intl.DateTimeFormat("ja-JP", {
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}

export function formatFullDateTime(value: string | null | undefined) {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return new Intl.DateTimeFormat("ja-JP", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}
