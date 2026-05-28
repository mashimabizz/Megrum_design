import {
  AdminPanel,
  AdminSelect,
  AdminTextInput,
  StatusPill,
  SubmitButton,
  formatDateTime,
} from "../_components";
import { upsertAdminRole } from "../actions";
import {
  ADMIN_PERMISSION_OPTIONS,
  ADMIN_ROLES,
  getAdminContext,
  hasAdminPermission,
} from "@/lib/admin/permissions";
import { createServiceRoleClient } from "@/lib/supabase/server";

export default async function AdminRolesPage() {
  const context = await getAdminContext(["roles.read"]);
  const canManage = hasAdminPermission(context, "roles.manage");
  const adminSupabase = createServiceRoleClient();

  const { data, error } = await adminSupabase
    .from("admin_roles")
    .select("user_id, role, permissions, status, requires_mfa, created_at, updated_at")
    .order("updated_at", { ascending: false });
  if (error) throw new Error(error.message);

  const roles = (data ?? []) as Array<{
    user_id: string;
    role: string;
    permissions: string[] | null;
    status: string;
    requires_mfa: boolean;
    created_at: string;
    updated_at: string;
  }>;
  const userIds = roles.map((role) => role.user_id);
  const { data: users, error: usersError } =
    userIds.length > 0
      ? await adminSupabase
          .from("users")
          .select("id, handle, display_name")
          .in("id", userIds)
      : { data: [], error: null };
  if (usersError) throw new Error(usersError.message);

  const userById = new Map(
    (users ?? []).map((user) => [
      user.id as string,
      {
        handle: user.handle as string,
        displayName: user.display_name as string,
      },
    ]),
  );

  return (
    <div className="space-y-5">
      {canManage && (
        <AdminPanel
          title="管理者ロールを追加・更新"
          description="対象は user_id、@handle、メールアドレスで指定できます。owner は全権限です。"
        >
          <form action={upsertAdminRole} className="grid gap-3 lg:grid-cols-2">
            <input type="hidden" name="return_to" value="/admin/roles" />
            <AdminTextInput
              name="user_id"
              label="対象ユーザー"
              placeholder="user_id / @handle / email"
              required
            />
            <AdminTextInput name="reason" label="理由" required />
            <AdminSelect name="role" label="ロール" defaultValue="viewer">
              {ADMIN_ROLES.map((role) => (
                <option key={role} value={role}>
                  {role}
                </option>
              ))}
            </AdminSelect>
            <AdminSelect name="status" label="ステータス" defaultValue="active">
              <option value="active">active</option>
              <option value="disabled">disabled</option>
            </AdminSelect>
            <label className="lg:col-span-2">
              <span className="mb-1 block text-[11px] font-bold text-slate-500">
                権限（カンマまたは改行区切り）
              </span>
              <textarea
                name="permissions"
                rows={4}
                placeholder="users.read, users.update_status, billing.read"
                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-[13px] font-semibold text-slate-900 outline-none focus:border-megrum-lavender focus:ring-2 focus:ring-megrum-lavender/20"
              />
            </label>
            <label className="flex items-center gap-2 text-[12px] font-bold text-slate-700">
              <input
                type="checkbox"
                name="requires_mfa"
                defaultChecked
                className="h-4 w-4 accent-megrum-lavender"
              />
              MFA済みセッションだけ許可
            </label>
            <div className="flex items-end justify-start lg:justify-end">
              <SubmitButton>ロールを保存</SubmitButton>
            </div>
          </form>
        </AdminPanel>
      )}

      <AdminPanel
        title="権限一覧"
        description="ロール変更は必ず監査ログに記録されます。"
      >
        <div className="mb-4 grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
          {ADMIN_PERMISSION_OPTIONS.map((permission) => (
            <div
              key={permission.key}
              className="rounded-lg border border-slate-100 px-3 py-2"
            >
              <div className="font-mono text-[11px] font-bold text-violet-700">
                {permission.key}
              </div>
              <div className="mt-0.5 text-[11px] font-semibold text-slate-500">
                {permission.label}
              </div>
            </div>
          ))}
        </div>

        <div className="overflow-x-auto">
          <table className="w-full min-w-[760px] border-separate border-spacing-0 text-left">
            <thead>
              <tr className="text-[11px] font-bold text-slate-500">
                <th className="border-b border-slate-200 px-3 py-2">管理者</th>
                <th className="border-b border-slate-200 px-3 py-2">ロール</th>
                <th className="border-b border-slate-200 px-3 py-2">権限</th>
                <th className="border-b border-slate-200 px-3 py-2">MFA</th>
                <th className="border-b border-slate-200 px-3 py-2">更新</th>
              </tr>
            </thead>
            <tbody>
              {roles.map((role) => {
                const user = userById.get(role.user_id);
                return (
                  <tr key={role.user_id} className="align-top">
                    <td className="border-b border-slate-100 px-3 py-3">
                      <div className="text-[13px] font-black text-slate-900">
                        {user ? `@${user.handle}` : "unknown"}
                      </div>
                      <div className="mt-0.5 text-[11px] font-semibold text-slate-500">
                        {user?.displayName ?? role.user_id}
                      </div>
                    </td>
                    <td className="border-b border-slate-100 px-3 py-3">
                      <div className="flex flex-wrap gap-1">
                        <StatusPill tone={role.status === "active" ? "ok" : "mute"}>
                          {role.role}
                        </StatusPill>
                        {role.status !== "active" && (
                          <StatusPill tone="mute">{role.status}</StatusPill>
                        )}
                      </div>
                    </td>
                    <td className="border-b border-slate-100 px-3 py-3">
                      <div className="flex max-w-[340px] flex-wrap gap-1">
                        {(role.permissions ?? []).map((permission) => (
                          <StatusPill key={permission}>{permission}</StatusPill>
                        ))}
                      </div>
                    </td>
                    <td className="border-b border-slate-100 px-3 py-3">
                      <StatusPill tone={role.requires_mfa ? "ok" : "warn"}>
                        {role.requires_mfa ? "required" : "off"}
                      </StatusPill>
                    </td>
                    <td className="border-b border-slate-100 px-3 py-3 text-[11px] font-semibold text-slate-500">
                      {formatDateTime(role.updated_at)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </AdminPanel>
    </div>
  );
}
