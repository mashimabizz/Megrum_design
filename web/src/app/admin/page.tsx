import Link from "next/link";
import {
  AdminLinkButton,
  AdminMetric,
  AdminPanel,
  StatusPill,
  formatFullDateTime,
} from "./_components";
import { getAdminContext } from "@/lib/admin/permissions";
import { createServiceRoleClient } from "@/lib/supabase/server";

export default async function AdminDashboardPage() {
  await getAdminContext();
  const adminSupabase = createServiceRoleClient();

  const [
    totalUsers,
    activeUsers,
    suspendedUsers,
    activeMegrumPlus,
    activeAdmins,
    recentAudit,
  ] = await Promise.all([
    countRows(adminSupabase, "users"),
    countRows(adminSupabase, "users", [["account_status", "active"]]),
    countRows(adminSupabase, "users", [["account_status", "suspended"]]),
    countRows(adminSupabase, "user_entitlements", [
      ["feature_key", "megrum_plus"],
      ["active", true],
    ]),
    countRows(adminSupabase, "admin_roles", [["status", "active"]]),
    adminSupabase
      .from("admin_audit_logs")
      .select("id, action, target_type, target_id, actor_user_id, created_at")
      .order("created_at", { ascending: false })
      .limit(8),
  ]);

  const auditRows = (recentAudit.data ?? []) as Array<{
    id: string;
    action: string;
    target_type: string;
    target_id: string | null;
    actor_user_id: string | null;
    created_at: string;
  }>;

  return (
    <div className="space-y-5">
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <AdminMetric label="総ユーザー" value={totalUsers} />
        <AdminMetric label="active ユーザー" value={activeUsers} tone="ok" />
        <AdminMetric label="停止中" value={suspendedUsers} tone="warn" />
        <AdminMetric label="メグルムプラス" value={activeMegrumPlus} />
      </div>

      <div className="grid gap-5 lg:grid-cols-[1.1fr_0.9fr]">
        <AdminPanel
          title="運用チェック"
          description="通報、マスタ追加、通知、ユーザー管理、権限管理の入口です。"
        >
          <div className="grid gap-3 sm:grid-cols-2">
            <QuickLink
              href="/admin/operations"
              title="運用管理"
              body="通報、推し追加リクエスト、運営通知をまとめて処理します。"
            />
            <QuickLink
              href="/admin/users"
              title="ユーザー管理"
              body="アカウント状態の確認、停止・復帰を行います。"
            />
            <QuickLink
              href="/admin/roles"
              title="管理者権限"
              body={`有効な管理者: ${activeAdmins}件。MFA必須のロールで保護します。`}
            />
            <QuickLink
              href="/admin/billing"
              title="有料プラン"
              body="サブスク同期、メグルムプラス権限、手動上書きを確認します。"
            />
            <QuickLink
              href="/admin/audit"
              title="監査ログ"
              body="管理者操作の履歴を時系列で追跡します。"
            />
          </div>
        </AdminPanel>

        <AdminPanel
          title="直近の管理者操作"
          description="変更内容は監査ログに残ります。"
          action={<AdminLinkButton href="/admin/audit">すべて見る</AdminLinkButton>}
        >
          <div className="space-y-2">
            {auditRows.length === 0 ? (
              <p className="text-[12px] font-semibold text-slate-500">
                まだ管理者操作は記録されていません。
              </p>
            ) : (
              auditRows.map((row) => (
                <div
                  key={row.id}
                  className="rounded-lg border border-slate-100 px-3 py-2"
                >
                  <div className="flex items-center justify-between gap-3">
                    <span className="text-[12px] font-black text-slate-900">
                      {row.action}
                    </span>
                    <StatusPill tone="mute">{formatFullDateTime(row.created_at)}</StatusPill>
                  </div>
                  <p className="mt-1 text-[11px] font-semibold text-slate-500">
                    {row.target_type} / {row.target_id ?? "—"}
                  </p>
                </div>
              ))
            )}
          </div>
        </AdminPanel>
      </div>
    </div>
  );
}

function QuickLink({
  href,
  title,
  body,
}: {
  href: string;
  title: string;
  body: string;
}) {
  return (
    <Link
      href={href}
      className="block rounded-lg border border-slate-200 p-4 transition hover:border-megrum-lavender/50 hover:bg-megrum-lavender/10"
    >
      <div className="text-[13px] font-black text-slate-900">{title}</div>
      <p className="mt-1 text-[11px] font-semibold leading-relaxed text-slate-500">
        {body}
      </p>
    </Link>
  );
}

async function countRows(
  adminSupabase: ReturnType<typeof createServiceRoleClient>,
  table: string,
  filters: Array<[string, string | boolean]> = [],
) {
  let query = adminSupabase.from(table).select("*", {
    count: "exact",
    head: true,
  });
  for (const [column, value] of filters) {
    query = query.eq(column, value);
  }
  const { count, error } = await query;
  if (error) throw new Error(error.message);
  return count ?? 0;
}
