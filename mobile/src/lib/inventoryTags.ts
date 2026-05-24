import { supabase } from "./supabase";

type TagPairRow = {
  inventory_id: string;
  tag: { label: string | null } | { label: string | null }[] | null;
};

export async function fetchInventoryTagLabels(
  inventoryIds: string[],
): Promise<Record<string, string[]>> {
  const result: Record<string, string[]> = {};
  const ids = Array.from(new Set(inventoryIds.filter(Boolean)));
  if (!supabase || ids.length === 0) return result;

  const { data, error } = await supabase
    .from("goods_inventory_tags")
    .select("inventory_id, tag:tags_master(label)")
    .in("inventory_id", ids);
  if (error) return result;

  for (const row of (data as TagPairRow[] | null) ?? []) {
    const tag = Array.isArray(row.tag) ? row.tag[0] : row.tag;
    if (!tag?.label) continue;
    const labels = result[row.inventory_id] ?? [];
    labels.push(tag.label);
    result[row.inventory_id] = labels;
  }

  return result;
}

export function formatHashTags(labels?: string[] | null) {
  const unique = Array.from(
    new Set((labels ?? []).map((label) => label.trim()).filter(Boolean)),
  );
  if (unique.length === 0) return null;
  return unique
    .slice(0, 3)
    .map((label) => `# ${label}`)
    .join("  ");
}
