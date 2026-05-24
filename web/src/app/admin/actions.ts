"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import {
  ADMIN_PERMISSION_OPTIONS,
  ADMIN_ROLES,
  getAdminContext,
  parsePermissions,
  writeAdminAuditLog,
} from "@/lib/admin/permissions";
import { createServiceRoleClient } from "@/lib/supabase/server";

const ACCOUNT_STATUSES = [
  "registered",
  "verified",
  "onboarding",
  "active",
  "suspended",
  "deletion_requested",
  "deleted",
] as const;

type AccountStatus = (typeof ACCOUNT_STATUSES)[number];
type ServiceSupabase = ReturnType<typeof createServiceRoleClient>;

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const KNOWN_PERMISSIONS = new Set<string>([
  "*",
  ...ADMIN_PERMISSION_OPTIONS.map((option) => option.key),
  ...Array.from(
    new Set(ADMIN_PERMISSION_OPTIONS.map((option) => option.key.split(".")[0])),
  ).map((namespace) => `${namespace}.*`),
]);

export async function updateUserStatus(formData: FormData) {
  const context = await getAdminContext(["users.update_status"]);
  const adminSupabase = createServiceRoleClient();
  const userId = await resolveUserId(
    adminSupabase,
    requiredString(formData, "user_id"),
  );
  const accountStatus = requiredString(formData, "account_status");
  const reason = requiredString(formData, "reason");

  if (!isAccountStatus(accountStatus)) {
    throw new Error("未対応のアカウント状態です");
  }
  if (userId === context.user.id && accountStatus !== "active") {
    throw new Error("自分自身の管理画面アクセスを失う変更はできません");
  }

  const { data: before, error: beforeError } = await adminSupabase
    .from("users")
    .select("id, handle, display_name, account_status")
    .eq("id", userId)
    .single();
  if (beforeError) throw new Error(beforeError.message);

  const { data: after, error } = await adminSupabase
    .from("users")
    .update({ account_status: accountStatus })
    .eq("id", userId)
    .select("id, handle, display_name, account_status")
    .single();
  if (error) throw new Error(error.message);

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "user.account_status.update",
    targetType: "user",
    targetId: userId,
    reason,
    beforeState: before as Record<string, unknown>,
    afterState: after as Record<string, unknown>,
  });

  revalidatePath("/admin");
  revalidatePath("/admin/users");
  redirect(safeReturnTo(formData));
}

export async function upsertAdminRole(formData: FormData) {
  const context = await getAdminContext(["roles.manage"]);
  const adminSupabase = createServiceRoleClient();
  const userId = await resolveUserId(
    adminSupabase,
    requiredString(formData, "user_id"),
  );
  const role = requiredString(formData, "role");
  const status = requiredString(formData, "status");
  const reason = requiredString(formData, "reason");
  const requiresMfa = formData.get("requires_mfa") === "on";

  if (!ADMIN_ROLES.includes(role as (typeof ADMIN_ROLES)[number])) {
    throw new Error("未対応の管理者ロールです");
  }
  if (status !== "active" && status !== "disabled") {
    throw new Error("未対応の管理者ステータスです");
  }
  if (userId === context.user.id && status !== "active") {
    throw new Error("自分自身の管理者権限を無効化できません");
  }

  const { data: before, error: beforeError } = await adminSupabase
    .from("admin_roles")
    .select("user_id, role, permissions, status, requires_mfa, created_by")
    .eq("user_id", userId)
    .maybeSingle();
  if (beforeError) throw new Error(beforeError.message);

  if (
    before?.role === "owner" &&
    before.status === "active" &&
    (role !== "owner" || status !== "active")
  ) {
    await assertAnotherActiveOwner(adminSupabase, userId);
  }

  const permissions =
    role === "owner" ? ["*"] : normalizePermissions(parsePermissions(formData.get("permissions")));

  const { data: after, error } = await adminSupabase
    .from("admin_roles")
    .upsert(
      {
        user_id: userId,
        role,
        permissions,
        status,
        requires_mfa: requiresMfa,
        created_by: before?.created_by ?? context.user.id,
      },
      { onConflict: "user_id" },
    )
    .select("user_id, role, permissions, status, requires_mfa, created_by")
    .single();
  if (error) throw new Error(error.message);

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "admin_role.upsert",
    targetType: "admin_role",
    targetId: userId,
    reason,
    beforeState: (before as Record<string, unknown> | null) ?? null,
    afterState: after as Record<string, unknown>,
  });

  revalidatePath("/admin");
  revalidatePath("/admin/roles");
  redirect(safeReturnTo(formData));
}

export async function setManualEntitlement(formData: FormData) {
  const context = await getAdminContext(["entitlements.manage"]);
  const adminSupabase = createServiceRoleClient();
  const userId = await resolveUserId(
    adminSupabase,
    requiredString(formData, "user_id"),
  );
  const featureKey = requiredString(formData, "feature_key")
    .trim()
    .toLowerCase();
  const active = formData.get("active") === "on";
  const reason = requiredString(formData, "reason");
  const expiresAt = parseOptionalDateTime(formData.get("expires_at"));

  if (!/^[a-z0-9_.-]{2,64}$/.test(featureKey)) {
    throw new Error("feature_key は英小文字・数字・_ . - の2〜64文字で指定してください");
  }

  const { data: before, error: beforeError } = await adminSupabase
    .from("user_entitlements")
    .select("user_id, feature_key, active, source, subscription_id, override_id, expires_at")
    .eq("user_id", userId)
    .eq("feature_key", featureKey)
    .maybeSingle();
  if (beforeError) throw new Error(beforeError.message);

  const { data: override, error: overrideError } = await adminSupabase
    .from("plan_overrides")
    .insert({
      user_id: userId,
      feature_key: featureKey,
      active,
      reason,
      expires_at: expiresAt,
      created_by: context.user.id,
    })
    .select("id, user_id, feature_key, active, reason, expires_at, created_by")
    .single();
  if (overrideError) throw new Error(overrideError.message);

  const { data: after, error } = await adminSupabase
    .from("user_entitlements")
    .upsert(
      {
        user_id: userId,
        feature_key: featureKey,
        active,
        source: "manual_override",
        subscription_id: null,
        override_id: override.id,
        expires_at: expiresAt,
        metadata: { reason },
      },
      { onConflict: "user_id,feature_key" },
    )
    .select("user_id, feature_key, active, source, subscription_id, override_id, expires_at")
    .single();
  if (error) throw new Error(error.message);

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "entitlement.manual_override",
    targetType: "user_entitlement",
    targetId: `${userId}:${featureKey}`,
    reason,
    beforeState: (before as Record<string, unknown> | null) ?? null,
    afterState: after as Record<string, unknown>,
    metadata: { override_id: override.id },
  });

  revalidatePath("/admin");
  revalidatePath("/admin/billing");
  revalidatePath("/admin/users");
  redirect(safeReturnTo(formData));
}

function requiredString(formData: FormData, key: string) {
  const value = String(formData.get(key) ?? "").trim();
  if (!value) throw new Error(`${key} が未入力です`);
  return value;
}

function safeReturnTo(formData: FormData) {
  const raw = String(formData.get("return_to") ?? "");
  return raw.startsWith("/admin") ? raw : "/admin";
}

function isAccountStatus(value: string): value is AccountStatus {
  return ACCOUNT_STATUSES.includes(value as AccountStatus);
}

function normalizePermissions(permissions: string[]) {
  const unique = Array.from(new Set(permissions));
  const unknown = unique.filter((permission) => !KNOWN_PERMISSIONS.has(permission));
  if (unknown.length > 0) {
    throw new Error(`未対応の権限です: ${unknown.join(", ")}`);
  }
  return unique;
}

function parseOptionalDateTime(value: FormDataEntryValue | null) {
  const raw = String(value ?? "").trim();
  if (!raw) return null;
  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) {
    throw new Error("expires_at の日時形式が正しくありません");
  }
  return date.toISOString();
}

async function assertAnotherActiveOwner(
  adminSupabase: ServiceSupabase,
  excludingUserId: string,
) {
  const { data, error } = await adminSupabase
    .from("admin_roles")
    .select("user_id")
    .eq("role", "owner")
    .eq("status", "active");
  if (error) throw new Error(error.message);

  const activeOwners = (data ?? []).filter(
    (owner) => owner.user_id !== excludingUserId,
  );
  if (activeOwners.length === 0) {
    throw new Error("最後のowner管理者を無効化・降格できません");
  }
}

async function resolveUserId(adminSupabase: ServiceSupabase, rawValue: string) {
  const value = rawValue.trim();
  if (UUID_RE.test(value)) return value;

  const handle = value.startsWith("@") ? value.slice(1) : value;
  if (/^[a-z0-9_]{3,20}$/.test(handle)) {
    const { data, error } = await adminSupabase
      .from("users")
      .select("id")
      .eq("handle", handle)
      .maybeSingle();
    if (error) throw new Error(error.message);
    if (data?.id) return data.id as string;
  }

  if (value.includes("@")) {
    const { data, error } = await adminSupabase.auth.admin.listUsers({
      page: 1,
      perPage: 1000,
    });
    if (error) throw new Error(error.message);
    const user = data.users.find(
      (candidate) => candidate.email?.toLowerCase() === value.toLowerCase(),
    );
    if (user) return user.id;
  }

  throw new Error("対象ユーザーが見つかりません");
}
