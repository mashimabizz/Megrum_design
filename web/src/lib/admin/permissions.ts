import { headers } from "next/headers";
import { notFound, redirect } from "next/navigation";
import {
  createClient,
  createServiceRoleClient,
} from "@/lib/supabase/server";

export const ADMIN_PERMISSION_OPTIONS = [
  { key: "users.read", label: "ユーザー閲覧" },
  { key: "users.update_status", label: "ユーザー状態変更" },
  { key: "roles.read", label: "管理者権限閲覧" },
  { key: "roles.manage", label: "管理者権限変更" },
  { key: "billing.read", label: "課金・プラン閲覧" },
  { key: "subscriptions.manage", label: "サブスク同期管理" },
  { key: "entitlements.manage", label: "有料権限付与/停止" },
  { key: "reports.read", label: "通報閲覧" },
  { key: "reports.moderate", label: "通報対応" },
  { key: "audit.read", label: "監査ログ閲覧" },
] as const;

export type AdminPermission = (typeof ADMIN_PERMISSION_OPTIONS)[number]["key"];

export const ADMIN_ROLES = [
  "owner",
  "support",
  "trust_safety",
  "billing",
  "viewer",
] as const;

export type AdminRole = (typeof ADMIN_ROLES)[number];

export type AdminContext = {
  user: {
    id: string;
    email: string | null;
  };
  role: AdminRole;
  permissions: string[];
  requiresMfa: boolean;
};

type AdminRoleRow = {
  user_id: string;
  role: AdminRole;
  permissions: string[] | null;
  requires_mfa: boolean;
};

export function hasAdminPermission(
  context: Pick<AdminContext, "role" | "permissions">,
  permission: AdminPermission,
) {
  if (context.role === "owner") return true;
  if (context.permissions.includes("*")) return true;
  if (context.permissions.includes(permission)) return true;
  const namespace = permission.split(".")[0];
  return context.permissions.includes(`${namespace}.*`);
}

export function parsePermissions(value: FormDataEntryValue | null) {
  return String(value ?? "")
    .split(/[\s,]+/)
    .map((permission) => permission.trim())
    .filter(Boolean);
}

export async function getAdminContext(required: AdminPermission[] = []) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const adminSupabase = createServiceRoleClient();
  const { data, error } = await adminSupabase
    .from("admin_roles")
    .select("user_id, role, permissions, requires_mfa")
    .eq("user_id", user.id)
    .eq("status", "active")
    .maybeSingle();

  if (error) {
    throw new Error(`管理者権限の確認に失敗しました: ${error.message}`);
  }
  if (!data) {
    notFound();
  }

  const row = data as AdminRoleRow;
  const context: AdminContext = {
    user: {
      id: user.id,
      email: user.email ?? null,
    },
    role: row.role,
    permissions: row.role === "owner" ? ["*"] : row.permissions ?? [],
    requiresMfa: row.requires_mfa,
  };

  if (context.requiresMfa) {
    const {
      data: { session },
    } = await supabase.auth.getSession();
    const aal = session?.access_token
      ? readJwtStringClaim(session.access_token, "aal")
      : null;
    if (aal !== "aal2") {
      notFound();
    }
  }

  const allowed = required.every((permission) =>
    hasAdminPermission(context, permission),
  );
  if (!allowed) {
    notFound();
  }

  return context;
}

export async function writeAdminAuditLog(input: {
  actorUserId: string | null;
  action: string;
  targetType: string;
  targetId?: string | null;
  reason?: string | null;
  beforeState?: Record<string, unknown> | null;
  afterState?: Record<string, unknown> | null;
  metadata?: Record<string, unknown>;
}) {
  const adminSupabase = createServiceRoleClient();
  const headerStore = await headers();
  const forwardedFor = headerStore.get("x-forwarded-for");
  const requestIp =
    forwardedFor?.split(",")[0]?.trim() ??
    headerStore.get("x-real-ip") ??
    null;

  const { error } = await adminSupabase.from("admin_audit_logs").insert({
    actor_user_id: input.actorUserId,
    action: input.action,
    target_type: input.targetType,
    target_id: input.targetId ?? null,
    reason: input.reason ?? null,
    before_state: input.beforeState ?? null,
    after_state: input.afterState ?? null,
    request_ip: requestIp,
    user_agent: headerStore.get("user-agent"),
    metadata: input.metadata ?? {},
  });

  if (error) {
    throw new Error(`監査ログの保存に失敗しました: ${error.message}`);
  }
}

function readJwtStringClaim(token: string, claim: string) {
  const payload = token.split(".")[1];
  if (!payload) return null;
  try {
    const json = Buffer.from(
      payload.replace(/-/g, "+").replace(/_/g, "/"),
      "base64",
    ).toString("utf8");
    const parsed = JSON.parse(json) as Record<string, unknown>;
    const value = parsed[claim];
    return typeof value === "string" ? value : null;
  } catch {
    return null;
  }
}
