import {
  AdminPanel,
  StatusPill,
  formatFullDateTime,
} from "../_components";
import { getAdminContext } from "@/lib/admin/permissions";
import { createServiceRoleClient } from "@/lib/supabase/server";

export default async function AdminAuditPage() {
  await getAdminContext(["audit.read"]);
  const adminSupabase = createServiceRoleClient();

  const { data, error } = await adminSupabase
    .from("admin_audit_logs")
    .select(
      "id, actor_user_id, action, target_type, target_id, reason, before_state, after_state, request_ip, user_agent, metadata, created_at",
    )
    .order("created_at", { ascending: false })
    .limit(120);
  if (error) throw new Error(error.message);

  const logs = (data ?? []) as Array<{
    id: string;
    actor_user_id: string | null;
    action: string;
    target_type: string;
    target_id: string | null;
    reason: string | null;
    before_state: Record<string, unknown> | null;
    after_state: Record<string, unknown> | null;
    request_ip: string | null;
    user_agent: string | null;
    metadata: Record<string, unknown>;
    created_at: string;
  }>;

  const actorIds = Array.from(
    new Set(logs.map((log) => log.actor_user_id).filter(Boolean) as string[]),
  );
  const { data: actors, error: actorsError } =
    actorIds.length > 0
      ? await adminSupabase
          .from("users")
          .select("id, handle, display_name")
          .in("id", actorIds)
      : { data: [], error: null };
  if (actorsError) throw new Error(actorsError.message);

  const actorById = new Map(
    (actors ?? []).map((actor) => [
      actor.id as string,
      `${actor.display_name as string} (@${actor.handle as string})`,
    ]),
  );

  return (
    <AdminPanel
      title="監査ログ"
      description="管理者操作、webhook処理、権限上書きの履歴を確認します。"
    >
      <div className="overflow-x-auto">
        <table className="w-full min-w-[900px] border-separate border-spacing-0 text-left">
          <thead>
            <tr className="text-[11px] font-bold text-slate-500">
              <th className="border-b border-slate-200 px-3 py-2">日時</th>
              <th className="border-b border-slate-200 px-3 py-2">操作</th>
              <th className="border-b border-slate-200 px-3 py-2">実行者</th>
              <th className="border-b border-slate-200 px-3 py-2">対象</th>
              <th className="border-b border-slate-200 px-3 py-2">理由</th>
              <th className="border-b border-slate-200 px-3 py-2">詳細</th>
            </tr>
          </thead>
          <tbody>
            {logs.map((log) => (
              <tr key={log.id} className="align-top">
                <td className="border-b border-slate-100 px-3 py-3 text-[11px] font-semibold text-slate-500">
                  {formatFullDateTime(log.created_at)}
                </td>
                <td className="border-b border-slate-100 px-3 py-3">
                  <StatusPill>{log.action}</StatusPill>
                </td>
                <td className="border-b border-slate-100 px-3 py-3 text-[12px] font-bold text-slate-900">
                  {log.actor_user_id
                    ? actorById.get(log.actor_user_id) ?? log.actor_user_id
                    : "system"}
                  {log.request_ip && (
                    <div className="mt-1 font-mono text-[10px] font-semibold text-slate-400">
                      {log.request_ip}
                    </div>
                  )}
                </td>
                <td className="border-b border-slate-100 px-3 py-3">
                  <div className="text-[12px] font-black text-slate-900">
                    {log.target_type}
                  </div>
                  <div className="mt-1 font-mono text-[10px] text-slate-400">
                    {log.target_id ?? "—"}
                  </div>
                </td>
                <td className="border-b border-slate-100 px-3 py-3 text-[12px] font-semibold text-slate-600">
                  {log.reason ?? "—"}
                </td>
                <td className="border-b border-slate-100 px-3 py-3">
                  <details className="max-w-[260px]">
                    <summary className="cursor-pointer text-[11px] font-bold text-violet-700">
                      JSON
                    </summary>
                    <pre className="mt-2 max-h-72 overflow-auto rounded-lg bg-slate-950 p-3 text-[10px] leading-relaxed text-slate-100">
                      {JSON.stringify(
                        {
                          before: log.before_state,
                          after: log.after_state,
                          metadata: log.metadata,
                          user_agent: log.user_agent,
                        },
                        null,
                        2,
                      )}
                    </pre>
                  </details>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </AdminPanel>
  );
}
