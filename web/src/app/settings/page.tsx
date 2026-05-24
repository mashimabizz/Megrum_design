import { redirect } from "next/navigation";
import Link from "next/link";
import {
  createClient,
  createServiceRoleClient,
} from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { logout } from "@/app/auth/actions";

export const metadata = {
  title: "設定 — Megrum",
};

/**
 * iter93: 設定一覧画面
 *
 * プロフ画面の「設定・サポート」セクションから流入する集約画面。
 * - 通知設定（実装済）
 * - プロフィール編集（既存 /profile/edit へリンク）
 * - 推し設定（既存 /profile/oshi へリンク）
 * - ヘルプ・問い合わせ（実装済 /help）
 * - アカウント関連（削除は次フェーズ）
 */
export default async function SettingsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const adminSupabase = createServiceRoleClient();
  const { data: adminRole } = await adminSupabase
    .from("admin_roles")
    .select("user_id")
    .eq("user_id", user.id)
    .eq("status", "active")
    .maybeSingle();
  const isAdmin = Boolean(adminRole);

  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="設定" backHref="/profile" />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-3">
        <Section label="プロフィール">
          <Row href="/profile/edit" icon="👤" title="プロフィール編集" sub="ハンドル・表示名・性別・エリア" />
          <Row href="/profile/oshi" icon="💜" title="推し設定" sub="グループ・メンバー" />
        </Section>

        <Section label="通知">
          <Row
            href="/settings/notifications"
            icon="🔔"
            title="通知設定"
            sub="メール通知の ON/OFF（in-app 通知は常時 ON）"
          />
        </Section>

        <Section label="サポート">
          <Row href="/help" icon="？" title="ヘルプ・FAQ" sub="使い方・取引の流れ" />
          <Row
            href="mailto:support@megrum.jp"
            icon="✉"
            title="運営に問い合わせ"
            sub="support@megrum.jp"
            external
          />
        </Section>

        {isAdmin && (
          <Section label="管理者">
            <Row href="/admin" icon="⚙" title="管理者ページ" sub="ユーザー・権限・有料プラン管理" />
          </Section>
        )}

        <Section label="規約・法的情報">
          <Row href="/legal/terms" icon="📄" title="利用規約" />
          <Row href="/legal/privacy" icon="🔐" title="プライバシーポリシー" />
          <Row href="/legal/notice" icon="📜" title="特定商取引法に基づく表記" />
        </Section>

        <Section label="アカウント">
          <form action={logout}>
            <button
              type="submit"
              className="block w-full px-3.5 py-3 text-center text-[12px] font-bold text-[#3a324a8c]"
            >
              ログアウト
            </button>
          </form>
          <button
            type="button"
            disabled
            className="block w-full px-3.5 py-3 text-center text-[11px] font-semibold text-[#d4866b] opacity-60"
          >
            アカウント削除（準備中）
          </button>
        </Section>

        <div className="pb-3 pt-1 text-center text-[10px] text-[#3a324a4d]">
          Megrum MVP · build dev
        </div>
      </div>
    </main>
  );
}

function Section({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mb-4">
      <div className="mb-1.5 px-1 text-[10.5px] font-bold uppercase tracking-[0.6px] text-[#3a324a8c]">
        {label}
      </div>
      <div className="overflow-hidden rounded-2xl border border-[#3a324a14] bg-white">
        {children}
      </div>
    </div>
  );
}

function Row({
  href,
  icon,
  title,
  sub,
  external,
}: {
  href: string;
  icon: string;
  title: string;
  sub?: string;
  external?: boolean;
}) {
  const inner = (
    <div className="flex items-center gap-3 border-b border-[#3a324a08] px-3.5 py-3 last:border-b-0">
      <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center text-[18px] leading-none">
        {icon}
      </div>
      <div className="min-w-0 flex-1">
        <div className="text-[13px] font-bold text-[#3a324a]">{title}</div>
        {sub && (
          <div className="mt-0.5 text-[10.5px] text-[#3a324a8c]">{sub}</div>
        )}
      </div>
      <span className="text-[12px] text-[#3a324a8c]">›</span>
    </div>
  );
  if (external) {
    return (
      <a href={href} className="block active:scale-[0.99]">
        {inner}
      </a>
    );
  }
  return (
    <Link href={href} className="block active:scale-[0.99]">
      {inner}
    </Link>
  );
}
