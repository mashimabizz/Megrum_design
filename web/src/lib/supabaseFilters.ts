const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isUuid(value: string | null | undefined): value is string {
  return typeof value === "string" && UUID_PATTERN.test(value);
}

export function participantOrFilter(
  leftColumn: string,
  rightColumn: string,
  userId: string,
) {
  if (!isUuid(userId)) {
    throw new Error("Invalid UUID for Supabase filter");
  }
  return `${leftColumn}.eq.${userId},${rightColumn}.eq.${userId}`;
}

export function sanitizePostgrestSearchTerm(value: string) {
  return value
    .normalize("NFKC")
    .replace(/[^\p{L}\p{N}\s@_-]/gu, "")
    .replace(/^@+/, "")
    .trim()
    .slice(0, 40);
}
