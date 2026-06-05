import Link from "next/link";
import type { ReactNode } from "react";
import { getAdminContext } from "@/lib/admin/permissions";

export const metadata = {
  title: "管理者ページ — Megrum",
};

const NAV_ITEMS = [
  { href: "/admin", label: "概要" },
  { href: "/admin/users", label: "ユーザー" },
  { href: "/admin/roles", label: "権限" },
  { href: "/admin/billing", label: "有料プラン" },
  { href: "/admin/audit", label: "監査ログ" },
];

export default async function AdminLayout({
  children,
}: {
  children: ReactNode;
}) {
  const context = await getAdminContext();

  return (
    <main className="min-h-screen flex-1 bg-[#fbf9fc] text-slate-900">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-3 px-4 py-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <Link href="/admin" className="text-[11px] font-bold text-slate-500">
              Megrum
            </Link>
            <h1 className="mt-1 text-[22px] font-black tracking-normal">
              管理者ページ
            </h1>
            <p className="mt-1 text-[11px] font-semibold text-slate-500">
              {context.user.email ?? context.user.id} · {context.role}
            </p>
          </div>
          <nav className="flex flex-wrap gap-2">
            {NAV_ITEMS.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-[12px] font-bold text-slate-700 transition hover:border-megrum-lavender/50 hover:text-violet-700"
              >
                {item.label}
              </Link>
            ))}
          </nav>
        </div>
      </header>
      <div className="mx-auto w-full max-w-6xl px-4 py-5">{children}</div>
    </main>
  );
}
