import AsyncStorage from "@react-native-async-storage/async-storage";
import type { AuthProfile } from "../auth/AuthProvider";
import { hasSupabaseConfig, supabase } from "./supabase";

export const MEGURI_PLUS_FEATURE_KEY = "meguri_plus";
export const MEGURI_PLUS_FREE_SEND_LIMIT = 2;
export const MEGURI_PLUS_MONTHLY_SEND_LIMIT = 8;
export const MEGURI_PLUS_REVIEW_HANDLE = "michilion";

export type MeguriPlusState = {
  active: boolean;
  canUseReviewToggle: boolean;
  freeSendLimit: number;
  monthlySendLimit: number;
  source: "entitlement" | "review_override" | "none";
};

const REVIEW_OVERRIDE_KEY = "meguri.plus.reviewOverride.v1";

export function canUseMeguriPlusReviewToggle(
  profile: Pick<AuthProfile, "handle"> | null | undefined,
) {
  return normalizeHandle(profile?.handle) === MEGURI_PLUS_REVIEW_HANDLE;
}

export async function loadMeguriPlusState(
  profile: Pick<AuthProfile, "handle"> | null | undefined,
): Promise<MeguriPlusState> {
  const canUseReviewToggle = canUseMeguriPlusReviewToggle(profile);
  const reviewOverride = canUseReviewToggle
    ? await loadReviewOverride()
    : null;
  if (reviewOverride !== null) {
    return toState(reviewOverride, canUseReviewToggle, "review_override");
  }

  const entitlementActive = await loadRemoteEntitlement();
  return toState(entitlementActive, canUseReviewToggle, entitlementActive ? "entitlement" : "none");
}

export async function saveMeguriPlusReviewOverride(
  profile: Pick<AuthProfile, "handle"> | null | undefined,
  active: boolean,
) {
  if (!canUseMeguriPlusReviewToggle(profile)) return false;
  await AsyncStorage.setItem(REVIEW_OVERRIDE_KEY, JSON.stringify({ active }));
  return true;
}

async function loadReviewOverride() {
  const raw = await AsyncStorage.getItem(REVIEW_OVERRIDE_KEY);
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    return typeof parsed?.active === "boolean" ? parsed.active : null;
  } catch {
    return null;
  }
}

async function loadRemoteEntitlement() {
  if (!supabase || !hasSupabaseConfig) return false;
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return false;

  const { data, error } = await supabase
    .from("user_entitlements")
    .select("active, expires_at")
    .eq("user_id", user.id)
    .eq("feature_key", MEGURI_PLUS_FEATURE_KEY)
    .maybeSingle();
  if (error || !data?.active) return false;

  const expiresAt =
    typeof data.expires_at === "string" && data.expires_at.length > 0
      ? Date.parse(data.expires_at)
      : null;
  return !expiresAt || expiresAt > Date.now();
}

function toState(
  active: boolean,
  canUseReviewToggle: boolean,
  source: MeguriPlusState["source"],
): MeguriPlusState {
  return {
    active,
    canUseReviewToggle,
    freeSendLimit: MEGURI_PLUS_FREE_SEND_LIMIT,
    monthlySendLimit: MEGURI_PLUS_MONTHLY_SEND_LIMIT,
    source,
  };
}

function normalizeHandle(handle: string | null | undefined) {
  return (handle ?? "").replace(/^@/, "").trim().toLowerCase();
}
