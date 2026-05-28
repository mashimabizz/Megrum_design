import {
  AdminPanel,
  AdminTextInput,
  StatusPill,
  SubmitButton,
  formatDateTime,
} from "../_components";
import { setManualEntitlement } from "../actions";
import {
  getAdminContext,
  hasAdminPermission,
} from "@/lib/admin/permissions";
import { createServiceRoleClient } from "@/lib/supabase/server";

export default async function AdminBillingPage() {
  const context = await getAdminContext(["billing.read"]);
  const canManageEntitlements = hasAdminPermission(
    context,
    "entitlements.manage",
  );
  const adminSupabase = createServiceRoleClient();

  const [subscriptionsResult, entitlementsResult, overridesResult] =
    await Promise.all([
      adminSupabase
        .from("subscriptions")
        .select(
          "id, user_id, plan_type, status, transaction_provider, transaction_provider_subscription_id, current_period_end, cancel_at_period_end, updated_at",
        )
        .order("updated_at", { ascending: false })
        .limit(80),
      adminSupabase
        .from("user_entitlements")
        .select("user_id, feature_key, active, source, expires_at, updated_at")
        .order("updated_at", { ascending: false })
        .limit(120),
      adminSupabase
        .from("plan_overrides")
        .select("id, user_id, feature_key, active, reason, expires_at, created_by, created_at")
        .order("created_at", { ascending: false })
        .limit(40),
    ]);

  if (subscriptionsResult.error) throw new Error(subscriptionsResult.error.message);
  if (entitlementsResult.error) throw new Error(entitlementsResult.error.message);
  if (overridesResult.error) throw new Error(overridesResult.error.message);

  const subscriptions = (subscriptionsResult.data ?? []) as Array<{
    id: string;
    user_id: string;
    plan_type: string;
    status: string;
    transaction_provider: string;
    transaction_provider_subscription_id: string | null;
    current_period_end: string | null;
    cancel_at_period_end: boolean;
    updated_at: string;
  }>;
  const entitlements = (entitlementsResult.data ?? []) as Array<{
    user_id: string;
    feature_key: string;
    active: boolean;
    source: string;
    expires_at: string | null;
    updated_at: string;
  }>;
  const overrides = (overridesResult.data ?? []) as Array<{
    id: string;
    user_id: string;
    feature_key: string;
    active: boolean;
    reason: string;
    expires_at: string | null;
    created_by: string | null;
    created_at: string;
  }>;

  const userIds = Array.from(
    new Set([
      ...subscriptions.map((row) => row.user_id),
      ...entitlements.map((row) => row.user_id),
      ...overrides.map((row) => row.user_id),
    ]),
  );
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
      `${user.display_name as string} (@${user.handle as string})`,
    ]),
  );

  return (
    <div className="space-y-5">
      {canManageEntitlements && (
        <AdminPanel
          title="有料権限の手動上書き"
          description="返金対応、キャンペーン、サポート対応などで一時的に権限を付与/停止します。"
        >
          <form action={setManualEntitlement} className="grid gap-3 lg:grid-cols-2">
            <input type="hidden" name="return_to" value="/admin/billing" />
            <AdminTextInput
              name="user_id"
              label="対象ユーザー"
              placeholder="user_id / @handle / email"
              required
            />
            <AdminTextInput
              name="feature_key"
              label="権限キー"
              defaultValue="premium"
              required
            />
            <AdminTextInput
              name="expires_at"
              label="有効期限"
              type="datetime-local"
            />
            <AdminTextInput
              name="reason"
              label="理由"
              placeholder="例: 決済復旧までの暫定付与"
              required
            />
            <label className="flex items-center gap-2 text-[12px] font-bold text-slate-700">
              <input
                type="checkbox"
                name="active"
                defaultChecked
                className="h-4 w-4 accent-megrum-lavender"
              />
              この権限を有効にする
            </label>
            <div className="flex items-end justify-start lg:justify-end">
              <SubmitButton>権限を保存</SubmitButton>
            </div>
          </form>
        </AdminPanel>
      )}

      <AdminPanel
        title="現在の有料権限"
        description="アプリ側のPremium判定は user_entitlements を参照します。"
      >
        <div className="overflow-x-auto">
          <table className="w-full min-w-[760px] border-separate border-spacing-0 text-left">
            <thead>
              <tr className="text-[11px] font-bold text-slate-500">
                <th className="border-b border-slate-200 px-3 py-2">ユーザー</th>
                <th className="border-b border-slate-200 px-3 py-2">権限</th>
                <th className="border-b border-slate-200 px-3 py-2">状態</th>
                <th className="border-b border-slate-200 px-3 py-2">期限</th>
                <th className="border-b border-slate-200 px-3 py-2">更新</th>
              </tr>
            </thead>
            <tbody>
              {entitlements.map((row) => (
                <tr key={`${row.user_id}:${row.feature_key}`} className="align-top">
                  <td className="border-b border-slate-100 px-3 py-3 text-[12px] font-bold text-slate-900">
                    {userById.get(row.user_id) ?? row.user_id}
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3">
                    <StatusPill>{row.feature_key}</StatusPill>
                    <span className="ml-2 text-[11px] font-semibold text-slate-500">
                      {row.source}
                    </span>
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3">
                    <StatusPill tone={row.active ? "ok" : "mute"}>
                      {row.active ? "active" : "inactive"}
                    </StatusPill>
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3 text-[11px] font-semibold text-slate-500">
                    {formatDateTime(row.expires_at)}
                  </td>
                  <td className="border-b border-slate-100 px-3 py-3 text-[11px] font-semibold text-slate-500">
                    {formatDateTime(row.updated_at)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </AdminPanel>

      <div className="grid gap-5 lg:grid-cols-2">
        <AdminPanel title="サブスクリプション同期" description="Stripe webhook等から反映された契約です。">
          <div className="space-y-2">
            {subscriptions.length === 0 ? (
              <p className="text-[12px] font-semibold text-slate-500">
                まだサブスクリプションはありません。
              </p>
            ) : (
              subscriptions.map((subscription) => (
                <div
                  key={subscription.id}
                  className="rounded-lg border border-slate-100 px-3 py-2"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="text-[12px] font-black text-slate-900">
                        {userById.get(subscription.user_id) ?? subscription.user_id}
                      </div>
                      <div className="mt-1 text-[11px] font-semibold text-slate-500">
                        {subscription.transaction_provider} · {subscription.plan_type}
                      </div>
                    </div>
                    <StatusPill tone={subscription.status === "active" ? "ok" : "warn"}>
                      {subscription.status}
                    </StatusPill>
                  </div>
                  <div className="mt-2 text-[11px] font-semibold text-slate-500">
                    期限 {formatDateTime(subscription.current_period_end)}
                    {subscription.cancel_at_period_end ? " · 期間終了で解約" : ""}
                  </div>
                </div>
              ))
            )}
          </div>
        </AdminPanel>

        <AdminPanel title="手動上書き履歴" description="直近40件を表示します。">
          <div className="space-y-2">
            {overrides.length === 0 ? (
              <p className="text-[12px] font-semibold text-slate-500">
                まだ手動上書きはありません。
              </p>
            ) : (
              overrides.map((override) => (
                <div
                  key={override.id}
                  className="rounded-lg border border-slate-100 px-3 py-2"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="text-[12px] font-black text-slate-900">
                        {override.feature_key}
                      </div>
                      <div className="mt-1 text-[11px] font-semibold text-slate-500">
                        {userById.get(override.user_id) ?? override.user_id}
                      </div>
                    </div>
                    <StatusPill tone={override.active ? "ok" : "mute"}>
                      {override.active ? "active" : "inactive"}
                    </StatusPill>
                  </div>
                  <p className="mt-2 text-[11px] font-semibold leading-relaxed text-slate-600">
                    {override.reason}
                  </p>
                  <div className="mt-1 text-[10.5px] font-semibold text-slate-400">
                    {formatDateTime(override.created_at)} · 期限 {formatDateTime(override.expires_at)}
                  </div>
                </div>
              ))
            )}
          </div>
        </AdminPanel>
      </div>
    </div>
  );
}
