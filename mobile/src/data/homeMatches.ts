export type CandidatePriority = "both" | "oneSide" | "wish";

export type Candidate = {
  id: string;
  label: string;
  member: string;
  type: string;
  hue: string;
  photoUrl?: string | null;
  tag?: string;
  tagLabels?: string[];
  local: boolean;
  priority: CandidatePriority;
  tagScore?: number;
  partnerId?: string;
  partnerHandle?: string;
  partnerDisplayName?: string;
  avatarUrl?: string | null;
  giveIds?: string[];
  receiveIds?: string[];
  listingIds?: string[];
  matchType?: "complete" | "they_want_you" | "you_want_them";
};

export type ShelfRow = {
  id: string;
  character: string;
  goodsType: string;
  candidates: Candidate[];
};

export type ShelfSection = {
  id: string;
  title: string;
  rows: ShelfRow[];
};

export type CandidateContext = {
  section: ShelfSection;
  row: ShelfRow;
  candidate: Candidate;
};

export const MATCH_SECTIONS: ShelfSection[] = [
  {
    id: "listing",
    title: "マッチしてるよ！",
    rows: [
      {
        id: "sua-card",
        character: "スア",
        goodsType: "トレカ",
        candidates: [
          {
            id: "sua-card-01",
            label: "スア 春ver.",
            member: "S",
            type: "トレカ",
            hue: "#cbbcf4",
            tag: "双方条件",
            tagLabels: ["春ver.", "同種優先"],
            local: true,
            priority: "both",
          },
          {
            id: "sua-card-02",
            label: "スア ラキドロ",
            member: "S",
            type: "トレカ",
            hue: "#a8d4e6",
            tag: "タグ一致",
            tagLabels: ["ラキドロ"],
            local: false,
            priority: "both",
          },
          {
            id: "sua-card-03",
            label: "スア 会場限定",
            member: "S",
            type: "トレカ",
            hue: "#f3c5d4",
            tag: "相手条件",
            tagLabels: ["会場限定"],
            local: true,
            priority: "oneSide",
          },
          {
            id: "sua-card-04",
            label: "スア 通常盤",
            member: "S",
            type: "トレカ",
            hue: "#d9eef5",
            tag: "候補",
            tagLabels: ["通常盤"],
            local: false,
            priority: "oneSide",
          },
        ],
      },
      {
        id: "nin-acrylic",
        character: "ニンニン",
        goodsType: "アクスタ",
        candidates: [
          {
            id: "nin-acrylic-01",
            label: "ニンニン アクスタ",
            member: "N",
            type: "アクスタ",
            hue: "#bcd8fa",
            tag: "自分条件",
            tagLabels: ["アクスタ"],
            local: false,
            priority: "oneSide",
          },
          {
            id: "nin-acrylic-02",
            label: "ニンニン 制服",
            member: "N",
            type: "アクスタ",
            hue: "#f7d5df",
            tag: "現地OK",
            tagLabels: ["制服", "現地OK"],
            local: true,
            priority: "oneSide",
          },
          {
            id: "nin-acrylic-03",
            label: "ニンニン ライブ",
            member: "N",
            type: "アクスタ",
            hue: "#d5cff4",
            tag: "タグ一致",
            tagLabels: ["ライブ"],
            local: false,
            priority: "oneSide",
          },
        ],
      },
    ],
  },
  {
    id: "possible",
    title: "交換できるかも",
    rows: [
      {
        id: "karina-card",
        character: "カリナ",
        goodsType: "トレカ",
        candidates: [
          {
            id: "karina-card-01",
            label: "カリナ トレカ",
            member: "K",
            type: "トレカ",
            hue: "#c8e8f2",
            tag: "wish一致",
            tagLabels: ["トレカ"],
            local: false,
            priority: "wish",
          },
          {
            id: "karina-card-02",
            label: "カリナ 初回盤",
            member: "K",
            type: "トレカ",
            hue: "#f2c6d7",
            tag: "現地OK",
            tagLabels: ["初回盤", "現地OK"],
            local: true,
            priority: "wish",
          },
          {
            id: "karina-card-03",
            label: "カリナ 店舗特典",
            member: "K",
            type: "トレカ",
            hue: "#cabcf1",
            tag: "衣装",
            tagLabels: ["店舗特典", "衣装"],
            local: false,
            priority: "wish",
          },
          {
            id: "karina-card-04",
            label: "カリナ ラントレ",
            member: "K",
            type: "トレカ",
            hue: "#b7dceb",
            tag: "候補",
            tagLabels: ["ラントレ"],
            local: false,
            priority: "wish",
          },
        ],
      },
      {
        id: "winter-badge",
        character: "ウィンター",
        goodsType: "缶バッジ",
        candidates: [
          {
            id: "winter-badge-01",
            label: "ウィンター 缶バッジ",
            member: "W",
            type: "缶バッジ",
            hue: "#d8cef6",
            tag: "wish一致",
            tagLabels: ["缶バッジ"],
            local: false,
            priority: "wish",
          },
          {
            id: "winter-badge-02",
            label: "ウィンター 会場",
            member: "W",
            type: "缶バッジ",
            hue: "#acd8e7",
            tag: "近い",
            tagLabels: ["会場"],
            local: true,
            priority: "wish",
          },
          {
            id: "winter-badge-03",
            label: "ウィンター 通常",
            member: "W",
            type: "缶バッジ",
            hue: "#f3c9d6",
            tag: "候補",
            tagLabels: ["通常"],
            local: false,
            priority: "wish",
          },
        ],
      },
    ],
  },
];

export function flattenMatchCandidates(): CandidateContext[] {
  return MATCH_SECTIONS.flatMap((section) =>
    section.rows.flatMap((row) =>
      row.candidates.map((candidate) => ({
        section,
        row,
        candidate,
      })),
    ),
  );
}

export function findCandidateContext(candidateId?: string | null) {
  if (!candidateId) return null;
  return (
    flattenMatchCandidates().find(
      (context) => context.candidate.id === candidateId,
    ) ?? null
  );
}

export function getAdjacentCandidateContexts(candidateId?: string | null) {
  const contexts = flattenMatchCandidates();
  const index = contexts.findIndex((context) => context.candidate.id === candidateId);
  if (index < 0) {
    return { previous: null, next: null };
  }

  return {
    previous: contexts[index - 1] ?? null,
    next: contexts[index + 1] ?? null,
  };
}

export function buildMatchDetailParams(row: ShelfRow, candidate: Candidate) {
  return {
    candidateId: candidate.id,
    title: candidate.label,
    subtitle: `${row.character} × ${row.goodsType} / ${candidate.tag ?? "候補"}`,
    member: candidate.member,
    hue: candidate.hue,
    photoUrl: candidate.photoUrl ?? "",
    priority: candidate.priority,
    local: candidate.local ? "true" : "false",
    tag: candidate.tag ?? "",
    partnerId: candidate.partnerId ?? "",
    partnerHandle: candidate.partnerHandle ?? "",
    partnerDisplayName: candidate.partnerDisplayName ?? "",
    avatarUrl: candidate.avatarUrl ?? "",
    gives: candidate.giveIds?.join(",") ?? "",
    receives: candidate.receiveIds?.join(",") ?? "",
    listings: candidate.listingIds?.join(",") ?? "",
    matchType: candidate.matchType ?? "",
  };
}
