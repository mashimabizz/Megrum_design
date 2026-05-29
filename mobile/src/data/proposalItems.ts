import { findCandidateContext } from "./homeMatches";

export type ProposalSide = "give" | "receive";

export type ProposalChoiceItem = {
  id: string;
  title: string;
  subtitle: string;
  glyph: string;
  hue: string;
  photoUrl?: string | null;
  hint: string;
};

export type ProposalThumbItem = {
  id: string;
  label: string;
  glyph: string;
  color: string;
  photoUrl?: string | null;
};

type CatalogItem = {
  title: string;
  subtitle: string;
  glyph: string;
  hue: string;
  photoUrl?: string | null;
};

type ProposalCatalogOverrides = Map<string, CatalogItem>;

export type ProposalInventoryRow = {
  id: string;
  title: string;
  photo_urls: string[] | null;
  hue?: number | string | null;
  group: { name: string | null } | { name: string | null }[] | null;
  character: { name: string | null } | { name: string | null }[] | null;
  goods_type: { name: string | null } | { name: string | null }[] | null;
};

const GIVE_HINT = "相手がほしいものかも？";
const RECEIVE_HINT = "私がほしいものかも？";

const ITEM_CATALOG: Record<string, CatalogItem> = {
  "give-1": {
    title: "カリナ 春ver.",
    subtitle: "aespa / トレカ",
    glyph: "K",
    hue: "#f3c5d4",
  },
  "give-2": {
    title: "ジョンウ ラキドロ",
    subtitle: "NCT / トレカ",
    glyph: "J",
    hue: "#a8d4e6",
  },
  "receive-1": {
    title: "スア ラキドロ",
    subtitle: "LUMENA / トレカ",
    glyph: "S",
    hue: "#cbbcf4",
  },
  "receive-2": {
    title: "ニンニン 制服",
    subtitle: "aespa / アクスタ",
    glyph: "N",
    hue: "#d5cff4",
  },
  selected: {
    title: "スア ラキドロ",
    subtitle: "LUMENA / トレカ",
    glyph: "S",
    hue: "#cbbcf4",
  },
  "selected-alt": {
    title: "スア 会場限定",
    subtitle: "LUMENA / トレカ",
    glyph: "S",
    hue: "#f3c5d4",
  },
  "partner-have-1": {
    title: "ニンニン 制服",
    subtitle: "aespa / アクスタ",
    glyph: "N",
    hue: "#a8d4e6",
  },
  "partner-have-2": {
    title: "ウィンター 缶バッジ",
    subtitle: "aespa / 缶バッジ",
    glyph: "W",
    hue: "#d5cff4",
  },
  "my-have-1": {
    title: "カリナ 春ver.",
    subtitle: "aespa / トレカ",
    glyph: "K",
    hue: "#f3c5d4",
  },
  "my-have-2": {
    title: "ジョンウ ラキドロ",
    subtitle: "NCT / トレカ",
    glyph: "J",
    hue: "#a8d4e6",
  },
  "my-have-bad": {
    title: "V トレカ",
    subtitle: "BTS / トレカ",
    glyph: "V",
    hue: "#b7dceb",
  },
  "wish-partner-1": {
    title: "カリナ 店舗特典",
    subtitle: "aespa / トレカ",
    glyph: "K",
    hue: "#f7d5df",
  },
  "wish-mine-1": {
    title: "スア ラキドロ",
    subtitle: "LUMENA / トレカ",
    glyph: "S",
    hue: "#cbbcf4",
  },
  "wish-mine-2": {
    title: "ニンニン 制服",
    subtitle: "aespa / アクスタ",
    glyph: "N",
    hue: "#d5cff4",
  },
};

const BASE_IDS: Record<ProposalSide, string[]> = {
  give: ["give-1", "give-2"],
  receive: ["receive-1", "receive-2"],
};

export function parseProposalIdList(value?: string | string[]): string[] {
  const raw = Array.isArray(value) ? value[0] : value;
  if (!raw) return [];
  return raw
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean);
}

export function buildProposalChoices(
  ids: string[],
  side: ProposalSide,
  overrides?: ProposalCatalogOverrides,
  options?: { includeFallback?: boolean },
): ProposalChoiceItem[] {
  const orderedIds =
    options?.includeFallback === false
      ? uniqueIds(ids)
      : uniqueIds(ids.length > 0 ? ids : BASE_IDS[side]);
  return orderedIds.map((id) => toProposalChoice(id, side, overrides));
}

export function buildProposalThumbs(
  ids: string[],
  side: ProposalSide,
  overrides?: ProposalCatalogOverrides,
  options?: { includeFallback?: boolean },
): ProposalThumbItem[] {
  const orderedIds =
    options?.includeFallback === false
      ? uniqueIds(ids)
      : uniqueIds(ids.length > 0 ? ids : BASE_IDS[side]);
  return orderedIds.map((id) => toProposalThumb(id, side, overrides));
}

export function isUuid(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
    value,
  );
}

export function buildProposalCatalogOverrides(rows: ProposalInventoryRow[]) {
  return new Map(
    rows.map((row) => {
      const character = pickName(row.character);
      const group = pickName(row.group);
      const goodsType = pickName(row.goods_type);
      const title = row.title || [character, group, goodsType].filter(Boolean).join(" ");
      const label = character ?? group ?? title;
      return [
        row.id,
        {
          title,
          subtitle: [group, goodsType].filter(Boolean).join(" / ") || "グッズ",
          glyph: (label || "?").slice(0, 1),
          hue: normalizeHue(row.hue, label || title),
          photoUrl: row.photo_urls?.[0] ?? null,
        },
      ] as const;
    }),
  );
}

function toProposalChoice(
  id: string,
  side: ProposalSide,
  overrides?: ProposalCatalogOverrides,
): ProposalChoiceItem {
  const item = resolveItem(id, side, overrides);
  return {
    id,
    title: item.title,
    subtitle: item.subtitle,
    glyph: item.glyph,
    hue: item.hue,
    photoUrl: item.photoUrl,
    hint: side === "give" ? GIVE_HINT : RECEIVE_HINT,
  };
}

function toProposalThumb(
  id: string,
  side: ProposalSide,
  overrides?: ProposalCatalogOverrides,
): ProposalThumbItem {
  const item = resolveItem(id, side, overrides);
  return {
    id,
    label: item.title,
    glyph: item.glyph,
    color: item.hue,
    photoUrl: item.photoUrl,
  };
}

function resolveItem(
  id: string,
  side: ProposalSide,
  overrides?: ProposalCatalogOverrides,
): CatalogItem {
  const override = overrides?.get(id);
  if (override) return override;

  const catalogItem = ITEM_CATALOG[id];
  if (catalogItem) return catalogItem;

  const context = findCandidateContext(id);
  if (context) {
    return {
      title: context.candidate.label,
      subtitle: `${context.row.character} / ${context.row.goodsType}`,
      glyph: context.candidate.member,
      hue: context.candidate.hue,
      photoUrl: context.candidate.photoUrl,
    };
  }

  const label = id.replace(/[-_]/g, " ");
  return {
    title: label,
    subtitle: "プレビュー / グッズ",
    glyph: label.slice(0, 1).toUpperCase() || "?",
    hue: side === "give" ? "#a8d4e6" : "#cbbcf4",
  };
}

function uniqueIds(ids: string[]): string[] {
  return Array.from(new Set(ids.filter(Boolean)));
}

function pickName(
  value: { name: string | null } | { name: string | null }[] | null,
) {
  if (!value) return null;
  return Array.isArray(value) ? value[0]?.name ?? null : value.name;
}

function normalizeHue(value: number | string | null | undefined, seed: string) {
  if (typeof value === "number") return `hsl(${value}, 62%, 78%)`;
  if (typeof value === "string" && value.trim()) {
    return value.startsWith("#") || value.startsWith("hsl")
      ? value
      : `hsl(${Number(value) || nameToHue(seed)}, 62%, 78%)`;
  }
  return `hsl(${nameToHue(seed)}, 62%, 78%)`;
}

function nameToHue(name: string) {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = (hash << 5) - hash + name.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash) % 360;
}
