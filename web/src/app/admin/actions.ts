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

const REPORT_SOURCES = [
  "reports",
  "goods_reports",
  "groom_reports",
  "meguri_board_reports",
  "disputes",
] as const;

const REPORT_STATUS_OPTIONS = {
  reports: ["open", "reviewing", "resolved", "dismissed"],
  goods_reports: ["open", "reviewing", "resolved", "dismissed"],
  groom_reports: ["open", "reviewing", "resolved", "dismissed"],
  meguri_board_reports: ["open", "reviewing", "resolved", "rejected"],
  disputes: ["submitted", "response_pending", "arbitrating", "closed"],
} as const;

const GROUP_KINDS = ["group", "work", "solo"] as const;
const ADMIN_NOTIFICATION_KIND = "admin_announcement";

type AccountStatus = (typeof ACCOUNT_STATUSES)[number];
type ReportSource = (typeof REPORT_SOURCES)[number];
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

export async function updateModerationReportStatus(formData: FormData) {
  const context = await getAdminContext(["reports.moderate"]);
  const adminSupabase = createServiceRoleClient();
  const source = requiredString(formData, "source");
  const reportId = requiredUUID(formData, "report_id");
  const status = requiredString(formData, "status");
  const reason = requiredString(formData, "reason");
  const operatorComment = optionalBoundedString(formData, "operator_comment", 2_000);
  const outcome = optionalBoundedString(formData, "outcome", 40);

  if (!isReportSource(source)) {
    throw new Error("未対応の通報種別です");
  }
  if (!REPORT_STATUS_OPTIONS[source].includes(status as never)) {
    throw new Error("未対応の通報ステータスです");
  }

  const { data: before, error: beforeError } = await adminSupabase
    .from(source)
    .select("*")
    .eq("id", reportId)
    .single();
  if (beforeError) throw new Error(beforeError.message);

  const updatePayload: Record<string, unknown> = { status };
  if (source === "reports") {
    updatePayload.resolved_at =
      status === "resolved" || status === "dismissed" ? new Date().toISOString() : null;
  }
  if (source === "disputes") {
    if (operatorComment !== null) {
      updatePayload.operator_comment = operatorComment;
    }
    if (outcome !== null) {
      updatePayload.outcome = outcome || null;
    }
    updatePayload.closed_at = status === "closed" ? new Date().toISOString() : null;
  }

  const { data: after, error } = await adminSupabase
    .from(source)
    .update(updatePayload)
    .eq("id", reportId)
    .select("*")
    .single();
  if (error) throw new Error(error.message);

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "report.status.update",
    targetType: source,
    targetId: reportId,
    reason,
    beforeState: before as Record<string, unknown>,
    afterState: after as Record<string, unknown>,
  });

  revalidatePath("/admin");
  revalidatePath("/admin/operations");
  redirect(safeReturnTo(formData));
}

export async function approveOshiRequestAsNew(formData: FormData) {
  const context = await getAdminContext(["oshi_requests.manage"]);
  const adminSupabase = createServiceRoleClient();
  const requestId = requiredUUID(formData, "request_id");
  const reason = requiredString(formData, "reason");
  const genreId = requiredUUID(formData, "genre_id");
  const name = boundedRequiredString(formData, "name", 100);
  const kind = requiredString(formData, "kind");
  const aliases = parseAliasList(formData.get("aliases"));
  const displayOrder = parseOptionalInteger(formData.get("display_order")) ?? 0;

  if (!GROUP_KINDS.includes(kind as (typeof GROUP_KINDS)[number])) {
    throw new Error("未対応の推しL1種別です");
  }

  const before = await loadPendingOshiRequest(adminSupabase, requestId);

  const { data: group, error: groupError } = await adminSupabase
    .from("groups_master")
    .insert({
      genre_id: genreId,
      name,
      aliases,
      kind,
      display_order: displayOrder,
    })
    .select("id, genre_id, name, aliases, kind, display_order")
    .single();
  if (groupError) throw new Error(groupError.message);

  const { data: after, error } = await adminSupabase
    .from("oshi_requests")
    .update({
      status: "approved",
      approved_group_id: group.id,
      approved_at: new Date().toISOString(),
      rejection_reason: null,
    })
    .eq("id", requestId)
    .select("*")
    .single();
  if (error) throw new Error(error.message);

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "oshi_request.approve_new_group",
    targetType: "oshi_request",
    targetId: requestId,
    reason,
    beforeState: before,
    afterState: after as Record<string, unknown>,
    metadata: { approved_group: group },
  });

  revalidatePath("/admin");
  revalidatePath("/admin/operations");
  redirect(safeReturnTo(formData));
}

export async function mergeOshiRequestIntoGroup(formData: FormData) {
  const context = await getAdminContext(["oshi_requests.manage"]);
  const adminSupabase = createServiceRoleClient();
  const requestId = requiredUUID(formData, "request_id");
  const groupId = requiredUUID(formData, "approved_group_id");
  const reason = requiredString(formData, "reason");

  const before = await loadPendingOshiRequest(adminSupabase, requestId);
  const group = await loadGroup(adminSupabase, groupId);

  const { data: after, error } = await adminSupabase
    .from("oshi_requests")
    .update({
      status: "merged",
      approved_group_id: groupId,
      approved_at: new Date().toISOString(),
      rejection_reason: null,
    })
    .eq("id", requestId)
    .select("*")
    .single();
  if (error) throw new Error(error.message);

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "oshi_request.merge_group",
    targetType: "oshi_request",
    targetId: requestId,
    reason,
    beforeState: before,
    afterState: after as Record<string, unknown>,
    metadata: { approved_group: group },
  });

  revalidatePath("/admin");
  revalidatePath("/admin/operations");
  redirect(safeReturnTo(formData));
}

export async function rejectOshiRequest(formData: FormData) {
  const context = await getAdminContext(["oshi_requests.manage"]);
  const adminSupabase = createServiceRoleClient();
  const requestId = requiredUUID(formData, "request_id");
  const reason = boundedRequiredString(formData, "reason", 500);
  const before = await loadPendingOshiRequest(adminSupabase, requestId);

  const { data: after, error } = await adminSupabase
    .from("oshi_requests")
    .update({
      status: "rejected",
      approved_group_id: null,
      approved_at: null,
      rejection_reason: reason,
    })
    .eq("id", requestId)
    .select("*")
    .single();
  if (error) throw new Error(error.message);

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "oshi_request.reject",
    targetType: "oshi_request",
    targetId: requestId,
    reason,
    beforeState: before,
    afterState: after as Record<string, unknown>,
  });

  revalidatePath("/admin");
  revalidatePath("/admin/operations");
  redirect(safeReturnTo(formData));
}

export async function approveCharacterRequestAsNew(formData: FormData) {
  const context = await getAdminContext(["oshi_requests.manage"]);
  const adminSupabase = createServiceRoleClient();
  const requestId = requiredUUID(formData, "request_id");
  const reason = requiredString(formData, "reason");
  const groupId = requiredUUID(formData, "group_id");
  const name = boundedRequiredString(formData, "name", 100);
  const aliases = parseAliasList(formData.get("aliases"));
  const displayOrder = parseOptionalInteger(formData.get("display_order")) ?? 0;

  const before = await loadPendingCharacterRequest(adminSupabase, requestId);
  const group = await loadGroup(adminSupabase, groupId);

  const { data: character, error: characterError } = await adminSupabase
    .from("characters_master")
    .insert({
      group_id: groupId,
      genre_id: group.genre_id,
      name,
      aliases,
      display_order: displayOrder,
    })
    .select("id, group_id, genre_id, name, aliases, display_order")
    .single();
  if (characterError) throw new Error(characterError.message);

  const { data: after, error } = await adminSupabase
    .from("character_requests")
    .update({
      status: "approved",
      approved_character_id: character.id,
      approved_at: new Date().toISOString(),
      rejection_reason: null,
    })
    .eq("id", requestId)
    .select("*")
    .single();
  if (error) throw new Error(error.message);

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "character_request.approve_new_character",
    targetType: "character_request",
    targetId: requestId,
    reason,
    beforeState: before,
    afterState: after as Record<string, unknown>,
    metadata: { approved_character: character },
  });

  revalidatePath("/admin");
  revalidatePath("/admin/operations");
  redirect(safeReturnTo(formData));
}

export async function mergeCharacterRequestIntoCharacter(formData: FormData) {
  const context = await getAdminContext(["oshi_requests.manage"]);
  const adminSupabase = createServiceRoleClient();
  const requestId = requiredUUID(formData, "request_id");
  const characterId = requiredUUID(formData, "approved_character_id");
  const reason = requiredString(formData, "reason");

  const before = await loadPendingCharacterRequest(adminSupabase, requestId);
  const { data: character, error: characterError } = await adminSupabase
    .from("characters_master")
    .select("id, group_id, genre_id, name, aliases, display_order")
    .eq("id", characterId)
    .single();
  if (characterError) throw new Error(characterError.message);

  const { data: after, error } = await adminSupabase
    .from("character_requests")
    .update({
      status: "merged",
      approved_character_id: characterId,
      approved_at: new Date().toISOString(),
      rejection_reason: null,
    })
    .eq("id", requestId)
    .select("*")
    .single();
  if (error) throw new Error(error.message);

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "character_request.merge_character",
    targetType: "character_request",
    targetId: requestId,
    reason,
    beforeState: before,
    afterState: after as Record<string, unknown>,
    metadata: { approved_character: character },
  });

  revalidatePath("/admin");
  revalidatePath("/admin/operations");
  redirect(safeReturnTo(formData));
}

export async function rejectCharacterRequest(formData: FormData) {
  const context = await getAdminContext(["oshi_requests.manage"]);
  const adminSupabase = createServiceRoleClient();
  const requestId = requiredUUID(formData, "request_id");
  const reason = boundedRequiredString(formData, "reason", 500);
  const before = await loadPendingCharacterRequest(adminSupabase, requestId);

  const { data: after, error } = await adminSupabase
    .from("character_requests")
    .update({
      status: "rejected",
      approved_character_id: null,
      approved_at: null,
      rejection_reason: reason,
    })
    .eq("id", requestId)
    .select("*")
    .single();
  if (error) throw new Error(error.message);

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "character_request.reject",
    targetType: "character_request",
    targetId: requestId,
    reason,
    beforeState: before,
    afterState: after as Record<string, unknown>,
  });

  revalidatePath("/admin");
  revalidatePath("/admin/operations");
  redirect(safeReturnTo(formData));
}

export async function sendAdminNotification(formData: FormData) {
  const context = await getAdminContext(["notifications.send"]);
  const adminSupabase = createServiceRoleClient();
  const audience = requiredString(formData, "audience");
  const title = boundedRequiredString(formData, "title", 100);
  const body = optionalBoundedString(formData, "body", 500);
  const linkPath = optionalBoundedString(formData, "link_path", 500);
  const reason = requiredString(formData, "reason");

  if (linkPath !== null && linkPath !== "" && !linkPath.startsWith("/")) {
    throw new Error("link_path はアプリ内パス（/ から始まる値）で指定してください");
  }

  let recipientIds: string[];
  if (audience === "all") {
    const { data, error } = await adminSupabase
      .from("users")
      .select("id")
      .in("account_status", ["verified", "onboarding", "active"]);
    if (error) throw new Error(error.message);
    recipientIds = (data ?? []).map((row) => row.id as string);
  } else if (audience === "user") {
    recipientIds = [
      await resolveUserId(
        adminSupabase,
        requiredString(formData, "recipient_user"),
      ),
    ];
  } else {
    throw new Error("通知の宛先が不正です");
  }

  if (recipientIds.length === 0) {
    throw new Error("通知対象ユーザーが見つかりません");
  }

  let insertedCount = 0;
  for (const batch of chunks(recipientIds, 500)) {
    const { data, error } = await adminSupabase
      .from("notifications")
      .insert(
        batch.map((userId) => ({
          user_id: userId,
          kind: ADMIN_NOTIFICATION_KIND,
          title,
          body,
          link_path: linkPath || "/notifications",
        })),
      )
      .select("id");
    if (error) throw new Error(error.message);
    insertedCount += data?.length ?? batch.length;
  }

  await writeAdminAuditLog({
    actorUserId: context.user.id,
    action: "notification.admin_announcement.send",
    targetType: "notification",
    targetId: audience === "user" ? recipientIds[0] : "all",
    reason,
    metadata: {
      audience,
      recipient_count: insertedCount,
      title,
      link_path: linkPath || "/notifications",
    },
  });

  revalidatePath("/admin");
  revalidatePath("/admin/operations");
  redirect(safeReturnTo(formData));
}

function requiredString(formData: FormData, key: string) {
  const value = String(formData.get(key) ?? "").trim();
  if (!value) throw new Error(`${key} が未入力です`);
  return value;
}

function boundedRequiredString(formData: FormData, key: string, maxLength: number) {
  const value = requiredString(formData, key);
  if (value.length > maxLength) {
    throw new Error(`${key} は${maxLength}文字以内で入力してください`);
  }
  return value;
}

function optionalBoundedString(
  formData: FormData,
  key: string,
  maxLength: number,
) {
  const value = String(formData.get(key) ?? "").trim();
  if (!value) return null;
  if (value.length > maxLength) {
    throw new Error(`${key} は${maxLength}文字以内で入力してください`);
  }
  return value;
}

function requiredUUID(formData: FormData, key: string) {
  const value = requiredString(formData, key);
  if (!UUID_RE.test(value)) {
    throw new Error(`${key} はUUIDで指定してください`);
  }
  return value;
}

function safeReturnTo(formData: FormData) {
  const raw = String(formData.get("return_to") ?? "");
  return raw.startsWith("/admin") ? raw : "/admin";
}

function isAccountStatus(value: string): value is AccountStatus {
  return ACCOUNT_STATUSES.includes(value as AccountStatus);
}

function isReportSource(value: string): value is ReportSource {
  return REPORT_SOURCES.includes(value as ReportSource);
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

function parseAliasList(value: FormDataEntryValue | null) {
  return Array.from(
    new Set(
      String(value ?? "")
        .split(/[\n,]+/)
        .map((alias) => alias.trim())
        .filter(Boolean),
    ),
  ).slice(0, 30);
}

function parseOptionalInteger(value: FormDataEntryValue | null) {
  const raw = String(value ?? "").trim();
  if (!raw) return null;
  const parsed = Number.parseInt(raw, 10);
  if (!Number.isFinite(parsed)) {
    throw new Error("数値の形式が正しくありません");
  }
  return parsed;
}

function chunks<T>(items: T[], size: number) {
  const result: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size));
  }
  return result;
}

async function loadPendingOshiRequest(
  adminSupabase: ServiceSupabase,
  requestId: string,
) {
  const { data, error } = await adminSupabase
    .from("oshi_requests")
    .select("*")
    .eq("id", requestId)
    .single();
  if (error) throw new Error(error.message);
  if (data.status !== "pending") {
    throw new Error("pending 以外の推し追加リクエストは処理できません");
  }
  return data as Record<string, unknown>;
}

async function loadPendingCharacterRequest(
  adminSupabase: ServiceSupabase,
  requestId: string,
) {
  const { data, error } = await adminSupabase
    .from("character_requests")
    .select("*")
    .eq("id", requestId)
    .single();
  if (error) throw new Error(error.message);
  if (data.status !== "pending") {
    throw new Error("pending 以外のメンバー追加リクエストは処理できません");
  }
  return data as Record<string, unknown>;
}

async function loadGroup(adminSupabase: ServiceSupabase, groupId: string) {
  const { data, error } = await adminSupabase
    .from("groups_master")
    .select("id, genre_id, name, aliases, kind, display_order")
    .eq("id", groupId)
    .single();
  if (error) throw new Error(error.message);
  return data as {
    id: string;
    genre_id: string;
    name: string;
    aliases: string[];
    kind: string;
    display_order: number;
  };
}
