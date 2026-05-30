import {
  AdminPanel,
  AdminSelect,
  AdminTextInput,
  StatusPill,
  SubmitButton,
  formatDateTime,
} from "../_components";
import { updateUserStatus } from "../actions";
import {
  getAdminContext,
  hasAdminPermission,
} from "@/lib/admin/permissions";
import { sanitizePostgrestSearchTerm } from "@/lib/supabaseFilters";
import { createServiceRoleClient } from "@/lib/supabase/server";

type Props = {
  searchParams: Promise<{ q?: string }>;
};

const ACCOUNT_STATUSES = [
  "registered",
  "verified",
  "onboarding",
  "active",
  "suspended",
  "deletion_requested",
  "deleted",
];

export default async function AdminUsersPage({ searchParams }: Props) {
  const params = await searchParams;
  const q = String(params.q ?? "").trim();
  const context = await getAdminContext(["users.read"]);
  const canUpdateStatus = hasAdminPermission(context, "users.update_status");
  const adminSupabase = createServiceRoleClient();

  let query = adminSupabase
    .from("users")
    .select(
      "id, handle, display_name, avatar_url, account_status, primary_area, created_at, updated_at",
    )
    .order("created_at", { ascending: false })
    .limit(80);

  if (q) {
    const safeTerm = sanitizePostgrestSearchTerm(q);
    if (safeTerm) {
      query = query.or(`handle.ilike.%${safeTerm}%,display_name.ilike.%${safeTerm}%`);
    }
  }

  const { data, error } = await query;
  if (error) throw new Error(error.message);

  const users = (data ?? []) as Array<{
    id: string;
    handle: string;
    display_name: string;
    avatar_url: string | null;
    account_status: string;
    primary_area: string | null;
    created_at: string;
    updated_at: string;
  }>;

  const userIds = users.map((user) => user.id);
  const [authUsers, entitlements] = await Promise.all([
    adminSupabase.auth.admin.listUsers({ page: 1, perPage: 1000 }),
    userIds.length > 0
      ? adminSupabase
          .from("user_entitlements")
          .select("user_id, feature_key, active, source, expires_at")
          .in("user_id", userIds)
      : Promise.resolve({ data: [], error: null }),
  ]);
  if (authUsers.error) throw new Error(authUsers.error.message);
  if (entitlements.error) throw new Error(entitlements.error.message);

  const emailById = new Map(
    authUsers.data.users.map((user) => [user.id, user.email ?? ""]),
  );
  const entitlementByUser = new Map<string, string[]>();
  for (const row of entitlements.data ?? []) {
    const key = row.user_id as string;
    const current = entitlementByUser.get(key) ?? [];
    if (row.active) current.push(`${row.feature_key} (${row.source})`);
    entitlementByUser.set(key, current);
  }

  return (
    <div className="space-y-5">
      <AdminPanel
        title="ユーザー管理"
        description="メール/ハンドルで検索し、アカウント状態を変更します。"
      >
        <form className="grid gap-3 sm:grid-cols-[1fr_auto]" action="/admin/users">
          <AdminTextInput
            name="q"
            label="検索"
            placeholder="@handle または表示名"
            defaultValue={q}
          />
          <div className="flex items-end">
            <button
              type="submit"
              className="h-10 rounded-lg bg-slate-900 px-4 text-[12px] font-black text-white"
            >
              検索
            </button>
          </div>
        </form>
      </AdminPanel>

      <AdminPanel
        title={`ユーザー一覧 ${users.length}件`}
        description="停止・削除系の変更は必ず理由を入力します。"
      >
        <div className="overflow-x-auto">
          <table className="w-full min-w-[860px] border-separate border-spacing-0 text-left">
            <thead>
              <tr className="text-[11px] font-bold text-slate-500">
                <th className="border-b border-slate-200 px-3 py-2">ユーザー</th>
                <th className="border-b border-slate-200 px-3 py-2">状態</th>
                <th className="border-b border-slate-200 px-3 py-2">権限</th>
                <th className="border-b border-slate-200 px-3 py-2">作成</th>
                <th className="border-b border-slate-200 px-3 py-2">操作</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user.id} className="align-top">
                  <td className="border-b border-slate-100 px-3 py-3">
                    <div className="text-[13px] font-black text-slate-900">
                      @{user.handle}
                    </div>
                    <div className="mt-0.5 text-[12px] font-semibold text-slate-600">
                      {user.display_name}
                    </div>
                    <div className="mt-1 text-[11px] text-slate-500">
                      {emailById.get(user.id) || "email未取得"} · {user.primary_area ?? "エリア未設定"}
                    </div>
                    <div className="mt-1 font-mono text-[10px] text-slate-400">
                      {user.id}
                    </div>
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3">
                    <StatusPill tone={statusTone(user.account_status)}>
                      {user.account_status}
                    </StatusPill>
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3">
                    <div className="flex max-w-[220px] flex-wrap gap-1">
                      {(entitlementByUser.get(user.id) ?? []).length === 0 ? (
                        <span className="text-[11px] font-semibold text-slate-400">
                          —
                        </span>
                      ) : (
                        entitlementByUser.get(user.id)?.map((entitlement) => (
                          <StatusPill key={entitlement}>{entitlement}</StatusPill>
                        ))
                      )}
                    </div>
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3 text-[11px] font-semibold text-slate-500">
                    {formatDateTime(user.created_at)}
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3">
                    {canUpdateStatus ? (
                      <form action={updateUserStatus} className="grid w-[260px] gap-2">
                        <input type="hidden" name="user_id" value={user.id} />
                        <input type="hidden" name="return_to" value={`/admin/users${q ? `?q=${encodeURIComponent(q)}` : ""}`} />
                        <AdminSelect
                          name="account_status"
                          label="状態変更"
                          defaultValue={user.account_status}
                        >
                          {ACCOUNT_STATUSES.map((status) => (
                            <option key={status} value={status}>
                              {status}
                            </option>
                          ))}
                        </AdminSelect>
                        <AdminTextInput
                          name="reason"
                          label="理由"
                          placeholder="例: 通報対応、本人申請"
                          required
                        />
                        <SubmitButton>状態を更新</SubmitButton>
                      </form>
                    ) : (
                      <span className="text-[11px] font-semibold text-slate-400">
                        権限なし
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </AdminPanel>
    </div>
  );
}

function statusTone(
  status: string,
): "default" | "warn" | "ok" | "mute" {
  if (status === "active" || status === "verified") return "ok";
  if (status === "suspended" || status === "deletion_requested") return "warn";
  if (status === "deleted") return "mute";
  return "default";
}
