import { supabase } from "./supabase";

export type ExchangeMethod = "hand" | "mail";

export type MailingAddressInput = {
  recipientName: string;
  postalCode: string;
  prefecture: string;
  city: string;
  line1: string;
  line2: string;
  phoneNumber: string;
};

export type MailingAddressRecord = MailingAddressInput & {
  userId: string;
  createdAt: string | null;
  updatedAt: string | null;
};

export type MailingAddressSnapshot = {
  recipientName: string;
  postalCode: string;
  prefecture: string;
  city: string;
  line1: string;
  line2: string | null;
  phoneNumber: string | null;
};

type MailingAddressRow = {
  user_id: string;
  recipient_name: string | null;
  postal_code: string | null;
  prefecture: string | null;
  city: string | null;
  line1: string | null;
  line2: string | null;
  phone_number: string | null;
  created_at?: string | null;
  updated_at?: string | null;
};

type SchemaTolerance = {
  tolerateMissingSchema?: boolean;
};

const MAILING_ADDRESS_FIELDS =
  "user_id, recipient_name, postal_code, prefecture, city, line1, line2, phone_number, created_at, updated_at";

export async function fetchMailingAddress(
  userId: string,
  options: SchemaTolerance = {},
): Promise<MailingAddressRecord | null> {
  if (!supabase) return null;
  const { data, error } = await supabase
    .from("user_mailing_addresses")
    .select(MAILING_ADDRESS_FIELDS)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    if (options.tolerateMissingSchema && isMissingMailingAddressSchemaError(error)) {
      return null;
    }
    throw error;
  }
  return mapMailingAddressRow(data as MailingAddressRow | null);
}

export async function fetchMailingAddressSnapshot(
  userId: string,
  options: SchemaTolerance = {},
): Promise<MailingAddressSnapshot | null> {
  const address = await fetchMailingAddress(userId, options);
  return address ? toMailingAddressSnapshot(address) : null;
}

export async function upsertMailingAddress(
  userId: string,
  input: MailingAddressInput,
): Promise<void> {
  if (!supabase) return;
  const normalized = normalizeMailingAddressInput(input);
  const { error } = await supabase.from("user_mailing_addresses").upsert(
    {
      user_id: userId,
      recipient_name: normalized.recipientName,
      postal_code: normalized.postalCode,
      prefecture: normalized.prefecture,
      city: normalized.city,
      line1: normalized.line1,
      line2: emptyToNull(normalized.line2),
      phone_number: emptyToNull(normalized.phoneNumber),
    },
    { onConflict: "user_id" },
  );
  if (error) throw error;
}

export function normalizeExchangeMethod(value?: string | null): ExchangeMethod {
  return value === "mail" ? "mail" : "hand";
}

export function exchangeMethodLabel(method: ExchangeMethod) {
  return method === "mail" ? "郵送交換" : "現地交換";
}

export function isMailingAddressReady(
  address: MailingAddressSnapshot | MailingAddressRecord | null | undefined,
) {
  if (!address) return false;
  return [
    address.recipientName,
    address.postalCode,
    address.prefecture,
    address.city,
    address.line1,
  ].every((value) => typeof value === "string" && value.trim().length > 0);
}

export function formatMailingAddressSummary(
  address: MailingAddressSnapshot | MailingAddressRecord | null | undefined,
) {
  if (!isMailingAddressReady(address)) return "未登録";
  const readyAddress = address as MailingAddressSnapshot | MailingAddressRecord;
  const postal = formatPostalCode(readyAddress.postalCode);
  return [postal, `${readyAddress.prefecture}${readyAddress.city}${readyAddress.line1}`]
    .filter(Boolean)
    .join(" ");
}

export function formatMailingAddressLines(
  address: MailingAddressSnapshot | MailingAddressRecord | null | undefined,
) {
  if (!isMailingAddressReady(address)) return ["住所未登録"];
  const readyAddress = address as MailingAddressSnapshot | MailingAddressRecord;
  return [
    readyAddress.recipientName,
    formatPostalCode(readyAddress.postalCode),
    `${readyAddress.prefecture}${readyAddress.city}${readyAddress.line1}`,
    cleanLine(readyAddress.line2),
    cleanLine(readyAddress.phoneNumber)
      ? `TEL ${cleanLine(readyAddress.phoneNumber)}`
      : null,
  ].filter((line): line is string => !!line);
}

export function toMailingAddressSnapshot(
  address: MailingAddressRecord | MailingAddressSnapshot,
): MailingAddressSnapshot {
  return {
    recipientName: address.recipientName.trim(),
    postalCode: normalizePostalCode(address.postalCode),
    prefecture: address.prefecture.trim(),
    city: address.city.trim(),
    line1: address.line1.trim(),
    line2: cleanLine(address.line2),
    phoneNumber: cleanLine(address.phoneNumber),
  };
}

export function parseMailingAddressSnapshot(
  value: unknown,
): MailingAddressSnapshot | null {
  if (!value || typeof value !== "object") return null;
  const raw = value as Record<string, unknown>;
  const snapshot: MailingAddressSnapshot = {
    recipientName: stringOrEmpty(raw.recipientName),
    postalCode: normalizePostalCode(stringOrEmpty(raw.postalCode)),
    prefecture: stringOrEmpty(raw.prefecture),
    city: stringOrEmpty(raw.city),
    line1: stringOrEmpty(raw.line1),
    line2: stringOrNull(raw.line2),
    phoneNumber: stringOrNull(raw.phoneNumber),
  };
  return isMailingAddressReady(snapshot) ? snapshot : null;
}

export function formatMailingAddressError(error: unknown) {
  if (
    typeof error === "object" &&
    error &&
    "message" in error &&
    typeof error.message === "string"
  ) {
    if (isMissingMailingAddressSchemaError(error)) {
      return "住所設定の保存先がまだ反映されていません。migration を適用してから再度お試しください。";
    }
    return error.message;
  }
  return "住所を保存できませんでした。時間を置いて再度お試しください。";
}

function mapMailingAddressRow(row: MailingAddressRow | null): MailingAddressRecord | null {
  if (!row) return null;
  return {
    userId: row.user_id,
    recipientName: row.recipient_name?.trim() ?? "",
    postalCode: normalizePostalCode(row.postal_code ?? ""),
    prefecture: row.prefecture?.trim() ?? "",
    city: row.city?.trim() ?? "",
    line1: row.line1?.trim() ?? "",
    line2: row.line2?.trim() ?? "",
    phoneNumber: row.phone_number?.trim() ?? "",
    createdAt: row.created_at ?? null,
    updatedAt: row.updated_at ?? null,
  };
}

function normalizeMailingAddressInput(input: MailingAddressInput): MailingAddressInput {
  return {
    recipientName: input.recipientName.trim(),
    postalCode: normalizePostalCode(input.postalCode),
    prefecture: input.prefecture.trim(),
    city: input.city.trim(),
    line1: input.line1.trim(),
    line2: input.line2.trim(),
    phoneNumber: input.phoneNumber.trim(),
  };
}

function normalizePostalCode(value: string) {
  return value.replace(/[^\d]/g, "").slice(0, 7);
}

function formatPostalCode(value: string) {
  const digits = normalizePostalCode(value);
  if (digits.length <= 3) return digits ? `〒${digits}` : "";
  return `〒${digits.slice(0, 3)}-${digits.slice(3)}`;
}

function cleanLine(value?: string | null) {
  const next = value?.trim();
  return next ? next : null;
}

function emptyToNull(value: string) {
  return value.trim() ? value.trim() : null;
}

function stringOrEmpty(value: unknown) {
  return typeof value === "string" ? value.trim() : "";
}

function stringOrNull(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function isMissingMailingAddressSchemaError(error: unknown) {
  if (!error || typeof error !== "object") return false;
  const code = "code" in error ? error.code : null;
  const message =
    "message" in error && typeof error.message === "string"
      ? error.message
      : "";
  return (
    code === "42P01" ||
    code === "PGRST205" ||
    code === "PGRST204" ||
    code === "42703" ||
    message.includes("user_mailing_addresses") ||
    message.includes("sender_mailing_address") ||
    message.includes("receiver_mailing_address") ||
    message.includes("schema cache") ||
    message.includes("does not exist")
  );
}
