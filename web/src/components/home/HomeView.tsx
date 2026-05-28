"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState, useTransition } from "react";
// iter134: ホーム画面のログアウト撤去に伴い logout import 不要
import {
  MatchDetailModal,
  type MatchDetailPageData,
} from "./MatchDetailModal";
import {
  type MatchCardData,
  type MatchCardListingInfo,
  type MiniItem,
} from "./MatchCard";
import { isMatching, type Match, type MatchInv } from "@/lib/matching";
import {
  disableLocalMode,
  enableLocalMode,
  type LocalModeSettings,
} from "./actions";
import {
  LocalModeSheet,
  type SimpleAW,
  type SimpleItem,
} from "./LocalModeSheet";
import { useImageReady } from "@/components/common/useImageReady";

// メンバー名 / グループ名 → hue (色相) ハッシュ
function nameToHue(name: string): number {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = (hash << 5) - hash + name.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash) % 360;
}

function toMini(inv: MatchInv): MiniItem {
  const label = inv.characterName ?? inv.groupName ?? inv.title ?? "?";
  return {
    id: inv.id,
    label,
    goodsTypeName: inv.goodsTypeName,
    photoUrl: inv.photoUrl,
    hue: nameToHue(label),
  };
}

/**
 * iter114: 2 つのタグ id 配列の Jaccard 類似度（0.0〜1.0）
 *
 * - 完全に同じタグ集合 = 1.0
 * - 重複タグ無し = 0.0
 * - 片方タグ無し = 0.0（共通要素ゼロのため）
 *
 * 関係図で「wish のタグと候補のタグがどれだけ一致するか」のスコア。
 * 高いほど類似 → 候補リストの上位に並べる。
 */
function jaccardScore(a: string[], b: string[]): number {
  if (a.length === 0 || b.length === 0) return 0;
  const setA = new Set(a);
  const setB = new Set(b);
  let intersect = 0;
  for (const x of setA) if (setB.has(x)) intersect++;
  const union = setA.size + setB.size - intersect;
  return union > 0 ? intersect / union : 0;
}

/** Match を MatchCard 用データに変換（iter67.6: partner listings 対応 / iter67.8: 在庫情報） */
function matchToCard(
  m: Match,
  myInvById: Map<string, MatchInv>,
  myWishById: Map<string, MatchInv>,
  partnersInvById: Map<string, MatchInv>,
  partnersWishById: Map<string, MatchInv>,
  myInventoryQty: Record<string, number>,
  tagsByInvId: Record<string, string[]>,
): MatchCardData {
  /**
   * iter67.8：listing 情報を hydrate する際、commitments 情報も計算
   *
   * @param isMyListing 自分が listing オーナーか
   */
  const hydrate = (
    listings: typeof m.myMatchedListings,
    haveLookup: Map<string, MatchInv>,
    wishLookup: Map<string, MatchInv>,
    isMyListing: boolean,
  ): MatchCardListingInfo[] | undefined =>
    listings?.map((ml) => {
      const haves = ml.haveIds.map((id, i) => {
        const inv = haveLookup.get(id);
        const item: MiniItem = inv
          ? toMini(inv)
          : { id, label: "?", goodsTypeName: null, photoUrl: null, hue: 0 };
        return {
          item,
          qty: ml.haveQtys[i] ?? 1,
          matched: ml.matchedHaveIds.includes(id),
        };
      });
      // iter104: 候補（相手側 inv）lookup
      //   my listing なら相手の inv（partnersInvById）から候補を引く
      //   partner listing なら私の inv（myInvById）から候補を引く
      const candidateLookup = isMyListing ? partnersInvById : myInvById;

      const options = ml.options.map((opt) => ({
        id: opt.id,
        position: opt.position,
        logic: opt.logic,
        exchangeType: opt.exchangeType,
        isCashOffer: opt.isCashOffer,
        cashAmount: opt.cashAmount,
        matched: opt.matched,
        wishes: opt.wishIds.map((id, i) => {
          const inv = wishLookup.get(id);
          const item: MiniItem = inv
            ? toMini(inv)
            : { id, label: "?", goodsTypeName: null, photoUrl: null, hue: 0 };
          // iter104: この wish にヒットした候補（相手側 inv）を hydrate
          // iter114: タグ Jaccard 類似度の高い候補を上位に並べる
          const wishHits = opt.matchedHitsByWish.find((h) => h.wishId === id);
          const wishTags = tagsByInvId[id] ?? [];
          const candidates = (wishHits?.theirInvIds ?? [])
            .map((cid) => {
              const cinv = candidateLookup.get(cid);
              const candTags = tagsByInvId[cid] ?? [];
              return {
                item: cinv
                  ? toMini(cinv)
                  : {
                      id: cid,
                      label: "?",
                      goodsTypeName: null,
                      photoUrl: null,
                      hue: 0,
                    },
                qty: 1, // 候補側の qty は表示上 1 件で OK（在庫数は別途）
                _score: jaccardScore(wishTags, candTags),
              };
            })
            // タグ類似度（Jaccard）降順、同点は元の順
            .sort((a, b) => b._score - a._score)
            // 表示型に合わせて _score を落とす
            .map(({ item, qty }) => ({ item, qty }));
          return {
            item,
            qty: opt.wishQtys[i] ?? 1,
            candidates,
          };
        }),
        /**
         * 私が追加で出す必要があるアイテム：
         *  - my listing：[]（perOptionMyCommitment 側）
         *  - partner listing：option.matchedTheirInvIds × wishQtys
         *    （wishQtys[i] が「相手が要求する数」なので、私が出すべき数）
         *
         * 注：matchedTheirInvIds は wish_ids から派生した相手側 hit。
         *     partner listing context では wish_ids に対応するのは私の inv なので、
         *     wish_ids[i] と wishQtys[i] のペアで「i 番目 wish 用に必要な qty」が分かる
         */
        myAdditionalCommitments: isMyListing
          ? []
          : opt.matchedTheirInvIds.map((id) => ({
              itemId: id,
              // wishQtys は wish_ids 順に対応。同じ id が複数の wish にヒットする場合は
              // 最初に見つかった wish の qty を使う（簡略化）
              qty: (() => {
                for (let i = 0; i < opt.wishIds.length; i++) {
                  const myWishItem = wishLookup.get(opt.wishIds[i]);
                  const myInvItem = myInvById.get(id);
                  if (
                    myWishItem &&
                    myInvItem &&
                    myWishItem.goodsTypeId === myInvItem.goodsTypeId
                  ) {
                    return opt.wishQtys[i] ?? 1;
                  }
                }
                return 1;
              })(),
            })),
      }));

      // listing 全体の per-option commitment (my listing の haves)
      const perOptionMyCommitment = isMyListing
        ? ml.haveIds.map((id, i) => ({
            itemId: id,
            qty: ml.haveQtys[i] ?? 1,
          }))
        : [];

      return {
        listingId: ml.listingId,
        haveLogic: ml.haveLogic,
        haves,
        options,
        isMyListing,
        perOptionMyCommitment,
      };
    });

  const myMatched = hydrate(m.myMatchedListings, myInvById, myWishById, true);
  const partnerMatched = hydrate(
    m.partnerMatchedListings,
    partnersInvById,
    partnersWishById,
    false,
  );

  // バッジ判定：listing 経由マッチで AND があれば 'set'、それ以外は 'any'
  const allListings = [
    ...(m.myMatchedListings ?? []),
    ...(m.partnerMatchedListings ?? []),
  ];
  const hasAnd = allListings.some(
    (ml) =>
      ml.haveLogic === "and" ||
      ml.options.some((o) => o.matched && o.logic === "and"),
  );
  const listingBadge: MatchCardData["listingBadge"] = m.viaListing
    ? hasAnd
      ? "set"
      : "any"
    : null;

  // 定価交換選択肢（cash_offer）が含まれているか（iter67.6 サブバッジ用）
  const hasCashOffer = allListings.some((ml) =>
    ml.options.some((o) => o.isCashOffer),
  );

  // 距離テキスト（現地モード ON 時のみ）
  let distanceText: string | undefined;
  if (typeof m.distanceMeters === "number") {
    const d = m.distanceMeters;
    distanceText =
      d < 1000 ? `約 ${Math.round(d)}m` : `約 ${(d / 1000).toFixed(1)}km`;
  }

  return {
    id: `match-${m.partner.id}`,
    partnerId: m.partner.id,
    userName: m.partner.displayName || m.partner.handle,
    userHandle: m.partner.handle,
    userAvatarUrl: m.partner.avatarUrl,
    myGives: m.myGives.map(toMini),
    theirGives: m.theirGives.map(toMini),
    matchType: m.matchType,
    distance: m.partner.primaryArea || "広域",
    exchangeType: "any",
    listingBadge,
    hasCashOffer,
    myMatchedListings: myMatched,
    partnerMatchedListings: partnerMatched,
    bothSidesListingMatch: m.bothSidesListingMatch,
    listingMatchKind: m.listingMatchKind,
    distanceText,
    localAvailable: m.localMatch === true,
    myInventoryQty,
  };
}

type CandidatePriority = 0 | 1 | 2;
type HomeModeView = "national" | "local";
type MatchDetailSlideDirection = "from-right" | "from-left" | "none";

const MODE_SWITCH_STATUS_MS = 480;
const MODE_SWITCH_SHEET_STATUS_MS = 260;
const MATCH_DETAIL_QUERY_KEY = "matchDetail";

type WishShelfCandidate = {
  key: string;
  card: MatchCardData;
  item: MiniItem;
  priority: CandidatePriority;
  myListingMatches: MatchCardListingInfo[];
  partnerListingMatches: MatchCardListingInfo[];
  tagScore: number;
  tagLabels: string[];
  local: boolean;
};

type WishShelfRow = {
  key: string;
  characterLabel: string;
  goodsTypeName: string;
  candidates: WishShelfCandidate[];
  bestPriority: CandidatePriority;
  bestTagScore: number;
  localCount: number;
};

type WishShelfSections = {
  listingRows: WishShelfRow[];
  possibleRows: WishShelfRow[];
};

function getCandidatePriority(
  myListings: MatchCardListingInfo[],
  partnerListings: MatchCardListingInfo[],
): CandidatePriority {
  const hasMyListing = myListings.length > 0;
  const hasPartnerListing = partnerListings.length > 0;
  if (hasMyListing && hasPartnerListing) return 0;
  if (hasMyListing || hasPartnerListing) return 1;
  return 2;
}

function getCandidateListingMatches(
  card: MatchCardData,
  receiveItemId: string,
): {
  myListingMatches: MatchCardListingInfo[];
  partnerListingMatches: MatchCardListingInfo[];
} {
  const myListingMatches = (card.myMatchedListings ?? []).filter((listing) =>
    listing.options.some(
      (option) =>
        option.matched &&
        option.wishes.some((wish) =>
          wish.candidates.some((candidate) => candidate.item.id === receiveItemId),
        ),
    ),
  );
  const partnerListingMatches = (card.partnerMatchedListings ?? []).filter(
    (listing) =>
      listing.haves.some(
        (have) => have.matched && have.item.id === receiveItemId,
      ),
  );
  return { myListingMatches, partnerListingMatches };
}

function getBestCandidatePriority(card: MatchCardData): CandidatePriority {
  return card.theirGives.reduce<CandidatePriority>((best, item) => {
    const { myListingMatches, partnerListingMatches } =
      getCandidateListingMatches(card, item.id);
    const priority = getCandidatePriority(
      myListingMatches,
      partnerListingMatches,
    );
    return Math.min(best, priority) as CandidatePriority;
  }, 2);
}

function truncateByChars(value: string, max: number): string {
  const chars = Array.from(value);
  if (chars.length <= max) return value;
  return `${chars.slice(0, max).join("")}…`;
}

function truncateTagLabel(value: string, max: number): string {
  const chars = Array.from(value);
  if (chars.length <= max) return value;
  return `${chars.slice(0, max).join("")}...`;
}

function getPriorityFrameClass(priority: CandidatePriority): string {
  if (priority === 0) {
    return "border-2 border-[#a695d8] ring-2 ring-[#f3c5d4]/70 shadow-[0_0_0_1px_rgba(255,255,255,0.84),7px_9px_24px_rgba(166,149,216,0.30),0_0_20px_rgba(243,197,212,0.32)]";
  }
  if (priority === 1) {
    return "border-[1.5px] border-[#a8d4e6] ring-1 ring-[#a695d8]/35 shadow-[7px_9px_20px_rgba(92,141,168,0.20)]";
  }
  return "border border-[#3a324a14] shadow-[7px_9px_18px_rgba(58,50,74,0.13)]";
}

function buildTagScoreByInvId(
  partnerInventory: MatchInv[],
  myWishes: MatchInv[],
  tagsByInvId: Record<string, string[]>,
): Map<string, number> {
  const scores = new Map<string, number>();

  for (const inv of partnerInventory) {
    const invTags = tagsByInvId[inv.id] ?? [];
    if (invTags.length === 0) {
      scores.set(inv.id, 0);
      continue;
    }

    let best = 0;
    for (const wish of myWishes) {
      if (!isMatching(inv, wish)) continue;
      const score = jaccardScore(tagsByInvId[wish.id] ?? [], invTags);
      if (score > best) best = score;
    }
    scores.set(inv.id, best);
  }

  return scores;
}

function buildWishShelves(
  cards: MatchCardData[],
  tagScoreByInvId: Map<string, number>,
  tagLabelsByInvId: Record<string, string[]>,
): WishShelfRow[] {
  const sortedCards = [...cards].sort((a, b) => {
    const byPriority = getBestCandidatePriority(a) - getBestCandidatePriority(b);
    if (byPriority !== 0) return byPriority;
    const byLocal = Number(b.localAvailable === true) - Number(a.localAvailable === true);
    if (byLocal !== 0) return byLocal;
    return a.userHandle.localeCompare(b.userHandle, "ja");
  });

  const rows = new Map<string, WishShelfRow>();
  const seen = new Set<string>();

  for (const card of sortedCards) {
    for (const item of card.theirGives) {
      const candidateKey = `${card.partnerId}:${item.id}`;
      if (seen.has(candidateKey)) continue;
      seen.add(candidateKey);

      const { myListingMatches, partnerListingMatches } =
        getCandidateListingMatches(card, item.id);
      const priority = getCandidatePriority(
        myListingMatches,
        partnerListingMatches,
      );
      const goodsTypeName = item.goodsTypeName ?? "グッズ";
      const rowKey = `${item.label}::${goodsTypeName}`;
      const tagScore = tagScoreByInvId.get(item.id) ?? 0;
      const tagLabels = tagLabelsByInvId[item.id] ?? [];
      let row = rows.get(rowKey);
      if (!row) {
        row = {
          key: rowKey,
          characterLabel: item.label,
          goodsTypeName,
          candidates: [],
          bestPriority: priority,
          bestTagScore: tagScore,
          localCount: 0,
        };
        rows.set(rowKey, row);
      }

      const local = card.localAvailable === true;
      row.candidates.push({
        key: candidateKey,
        card,
        item,
        priority,
        myListingMatches,
        partnerListingMatches,
        tagScore,
        tagLabels,
        local,
      });
      row.bestPriority = Math.min(row.bestPriority, priority) as CandidatePriority;
      row.bestTagScore = Math.max(row.bestTagScore, tagScore);
      if (local) row.localCount += 1;
    }
  }

  const result = [...rows.values()];
  for (const row of result) {
    row.candidates.sort((a, b) => {
      const byPriority = a.priority - b.priority;
      if (byPriority !== 0) return byPriority;
      const byTagScore = b.tagScore - a.tagScore;
      if (byTagScore !== 0) return byTagScore;
      const byLocal = Number(b.local) - Number(a.local);
      if (byLocal !== 0) return byLocal;
      return a.card.userHandle.localeCompare(b.card.userHandle, "ja");
    });
  }

  return result.sort((a, b) => {
    const byPriority = a.bestPriority - b.bestPriority;
    if (byPriority !== 0) return byPriority;
    const byTagScore = b.bestTagScore - a.bestTagScore;
    if (byTagScore !== 0) return byTagScore;
    const byLocalCount = b.localCount - a.localCount;
    if (byLocalCount !== 0) return byLocalCount;
    const byCount = b.candidates.length - a.candidates.length;
    if (byCount !== 0) return byCount;
    return a.characterLabel.localeCompare(b.characterLabel, "ja");
  });
}

function subsetWishShelfRow(
  row: WishShelfRow,
  candidates: WishShelfCandidate[],
  keySuffix: string,
): WishShelfRow | null {
  if (candidates.length === 0) return null;
  return {
    ...row,
    key: `${row.key}::${keySuffix}`,
    candidates,
    bestPriority: candidates.reduce<CandidatePriority>(
      (best, candidate) => Math.min(best, candidate.priority) as CandidatePriority,
      2,
    ),
    bestTagScore: candidates.reduce(
      (best, candidate) => Math.max(best, candidate.tagScore),
      0,
    ),
    localCount: candidates.filter((candidate) => candidate.local).length,
  };
}

function splitWishShelves(rows: WishShelfRow[]): WishShelfSections {
  const listingRows: WishShelfRow[] = [];
  const possibleRows: WishShelfRow[] = [];

  for (const row of rows) {
    const listingRow = subsetWishShelfRow(
      row,
      row.candidates.filter((candidate) => candidate.priority < 2),
      "listing",
    );
    if (listingRow) listingRows.push(listingRow);

    const possibleRow = subsetWishShelfRow(
      row,
      row.candidates.filter((candidate) => candidate.priority === 2),
      "possible",
    );
    if (possibleRow) possibleRows.push(possibleRow);
  }

  return { listingRows, possibleRows };
}

export function HomeView({
  profile,
  localMode,
  currentAW,
  carryingItems,
  autoOpenLocalSheet = false,
  matches,
  myInventory,
  myWishes,
  partnersInventory,
  partnersWishes,
  myInventoryQty,
  tagsByInvId,
  tagLabelsByInvId,
  unreadNotificationCount = 0,
  isNationalView = false,
}: {
  profile: {
    handle: string;
    display_name: string;
    avatar_url?: string | null;
  } | null;
  localMode: LocalModeSettings | null;
  currentAW: SimpleAW | null;
  carryingItems: SimpleItem[];
  autoOpenLocalSheet?: boolean;
  matches: Match[];
  myInventory: MatchInv[];
  myWishes: MatchInv[];
  /** 全パートナーの inv フラット（モーダル描画時の lookup 用、iter67.6） */
  partnersInventory: MatchInv[];
  partnersWishes: MatchInv[];
  /** 自分の inv id → quantity（在庫オーバーチェック用、iter67.8） */
  myInventoryQty: Record<string, number>;
  /** iter114: inventory_id → tag_id[]（候補のタグ類似度ソート用） */
  tagsByInvId: Record<string, string[]>;
  /** iter152.7: inventory_id → tag label[]（ホーム候補カードのタグ表示用） */
  tagLabelsByInvId: Record<string, string[]>;
  /** iter92: 通知の未読数（ホームヘッダーのベルバッジ用） */
  unreadNotificationCount?: number;
  /** iter142: ?view=national の URL flag。現地モード ON でも全国一覧を表示 */
  isNationalView?: boolean;
}) {
  const [selectedCandidate, setSelectedCandidate] =
    useState<WishShelfCandidate | null>(null);
  const [detailSlideDirection, setDetailSlideDirection] =
    useState<MatchDetailSlideDirection>("from-right");
  const [clientViewMode, setClientViewMode] = useState<HomeModeView | null>(
    null,
  );
  const [localEnabledOverride, setLocalEnabledOverride] = useState<
    boolean | null
  >(null);
  const [pending, startTransition] = useTransition();
  const [optimisticMode, setOptimisticMode] = useState<HomeModeView | null>(
    null,
  );
  const [modeSwitching, setModeSwitching] = useState(false);
  const modeSwitchTimerRef = useRef<number | null>(null);
  // iter142: pill toggle で view 切替（DB は触らない）
  const router = useRouter();

  const allCards = useMemo(() => {
    const myInvById = new Map(myInventory.map((i) => [i.id, i]));
    const myWishById = new Map(myWishes.map((w) => [w.id, w]));
    const partnersInvById = new Map(partnersInventory.map((i) => [i.id, i]));
    const partnersWishById = new Map(partnersWishes.map((w) => [w.id, w]));
    return matches.map((m) =>
      matchToCard(
        m,
        myInvById,
        myWishById,
        partnersInvById,
        partnersWishById,
        myInventoryQty,
        tagsByInvId,
      ),
    );
  }, [
    matches,
    myInventory,
    myWishes,
    partnersInventory,
    partnersWishes,
    myInventoryQty,
    tagsByInvId,
  ]);
  const tagScoreByInvId = useMemo(
    () => buildTagScoreByInvId(partnersInventory, myWishes, tagsByInvId),
    [partnersInventory, myWishes, tagsByInvId],
  );
  const isLocal = localEnabledOverride ?? localMode?.enabled ?? false;
  const actualViewMode: HomeModeView =
    isLocal && !isNationalView ? "local" : "national";
  const visualViewMode = optimisticMode ?? clientViewMode ?? actualViewMode;
  const visibleCards = useMemo(
    () =>
      visualViewMode === "local"
        ? allCards.filter((card) => card.localAvailable)
        : allCards,
    [allCards, visualViewMode],
  );
  const wishShelves = useMemo(
    () => buildWishShelves(visibleCards, tagScoreByInvId, tagLabelsByInvId),
    [visibleCards, tagScoreByInvId, tagLabelsByInvId],
  );
  const wishShelfSections = useMemo(
    () => splitWishShelves(wishShelves),
    [wishShelves],
  );
  const detailCandidates = useMemo(
    () =>
      wishShelfSections.listingRows.flatMap((row) => row.candidates),
    [wishShelfSections],
  );
  const detailCandidateByKey = useMemo(
    () => new Map(detailCandidates.map((candidate) => [candidate.key, candidate])),
    [detailCandidates],
  );
  const detailCandidateByKeyRef = useRef(detailCandidateByKey);
  const hasWishShelfCandidates =
    wishShelfSections.listingRows.length > 0 ||
    wishShelfSections.possibleRows.length > 0;
  const selectedDetailIndex = selectedCandidate
    ? detailCandidates.findIndex(
        (candidate) => candidate.key === selectedCandidate.key,
      )
    : -1;
  const previousDetailCandidate =
    selectedDetailIndex > 0 ? detailCandidates[selectedDetailIndex - 1] : null;
  const nextDetailCandidate =
    selectedDetailIndex >= 0 && selectedDetailIndex < detailCandidates.length - 1
      ? detailCandidates[selectedDetailIndex + 1]
      : null;
  const previousDetailPage = previousDetailCandidate
    ? buildMatchDetailPage(previousDetailCandidate)
    : null;
  const nextDetailPage = nextDetailCandidate
    ? buildMatchDetailPage(nextDetailCandidate)
    : null;

  useEffect(() => {
    detailCandidateByKeyRef.current = detailCandidateByKey;
  }, [detailCandidateByKey]);

  useEffect(() => {
    if (typeof window === "undefined") return;

    function syncDetailFromUrl() {
      const url = new URL(window.location.href);
      const key = url.searchParams.get(MATCH_DETAIL_QUERY_KEY);
      if (!key) {
        setSelectedCandidate(null);
        return;
      }
      const candidate = detailCandidateByKeyRef.current.get(key);
      if (!candidate) {
        setSelectedCandidate(null);
        return;
      }
      setDetailSlideDirection("from-right");
      setSelectedCandidate(candidate);
    }

    window.addEventListener("popstate", syncDetailFromUrl);
    syncDetailFromUrl();
    return () => window.removeEventListener("popstate", syncDetailFromUrl);
  }, []);

  // 現地モード state（DB から取得した初期値）
  const [sheetOpen, setSheetOpen] = useState(autoOpenLocalSheet);
  /** iter133: 現地交換モード OFF 確認ダイアログ */
  const [showOffConfirm, setShowOffConfirm] = useState(false);
  /**
   * iter129: 現地モード ON で開いた直後の sheet で、ユーザーが apply せず
   * close した場合に「全国」へ戻すための追跡フラグ
   * - handleEnableLocal で true にする
   * - sheet の onApplied で false にする
   * - sheet の onClose で「true のままなら disable して revert」
   */
  const [needsRevertOnClose, setNeedsRevertOnClose] = useState(false);

  // ?openLocalMode=1 で戻ってきたとき：URL パラメータを掃除しつつシート開く
  useEffect(() => {
    if (autoOpenLocalSheet && typeof window !== "undefined") {
      const url = new URL(window.location.href);
      url.searchParams.delete("openLocalMode");
      window.history.replaceState({}, "", url.toString());
    }
  }, [autoOpenLocalSheet]);

  const nationalModeActive = visualViewMode === "national";
  const localModeActive = visualViewMode === "local";
  const showModeSwitchOverlay = modeSwitching || pending;
  const modeSwitchMessage =
    visualViewMode === "local"
      ? "今すぐ現地交換モードに切り替え中…"
      : "全国交換モードに切り替え中…";
  const settings: LocalModeSettings = localMode
    ? { ...localMode, enabled: isLocal }
    : {
        enabled: isLocal,
        awId: currentAW?.id ?? null,
        radiusM: currentAW?.radiusM ?? 500,
        selectedCarryingIds: [],
        selectedWishIds: [],
        lastLat: currentAW?.centerLat ?? null,
        lastLng: currentAW?.centerLng ?? null,
      };

  function clearModeSwitchTimer() {
    if (modeSwitchTimerRef.current && typeof window !== "undefined") {
      window.clearTimeout(modeSwitchTimerRef.current);
      modeSwitchTimerRef.current = null;
    }
  }

  function beginModeSwitch(target: HomeModeView) {
    clearModeSwitchTimer();
    setOptimisticMode(target);
    setModeSwitching(true);
  }

  function hideModeSwitchOverlay(delayMs = MODE_SWITCH_STATUS_MS) {
    clearModeSwitchTimer();
    if (typeof window === "undefined") {
      setModeSwitching(false);
      return;
    }
    modeSwitchTimerRef.current = window.setTimeout(() => {
      setModeSwitching(false);
      setOptimisticMode(null);
      modeSwitchTimerRef.current = null;
    }, delayMs);
  }

  function cancelModeSwitch() {
    clearModeSwitchTimer();
    setOptimisticMode(null);
    setModeSwitching(false);
  }

  function replaceViewParam(nextMode: HomeModeView) {
    if (typeof window === "undefined") return;
    const url = new URL(window.location.href);
    if (nextMode === "national" && isLocal) {
      url.searchParams.set("view", "national");
    } else {
      url.searchParams.delete("view");
    }
    window.history.replaceState(window.history.state, "", url.toString());
  }

  useEffect(() => {
    return () => clearModeSwitchTimer();
  }, []);

  useEffect(() => {
    if (!optimisticMode || optimisticMode !== actualViewMode || pending) return;
    const timer = window.setTimeout(() => {
      setOptimisticMode(null);
      setModeSwitching(false);
    }, MODE_SWITCH_STATUS_MS);
    return () => window.clearTimeout(timer);
  }, [actualViewMode, optimisticMode, pending]);

  /**
   * iter140: AW が既に保存済の状態での即時再 ON
   * - sheet を開かない、GPS も取らない
   * - DB の enabled フラグだけ立てる（iter136 で AW は保持されている）
   */
  function handleQuickReenable() {
    beginModeSwitch("local");
    startTransition(async () => {
      try {
        const r = await enableLocalMode({});
        if (r?.error) {
          cancelModeSwitch();
          return;
        }
        setLocalEnabledOverride(true);
        setClientViewMode("local");
        replaceViewParam("local");
        hideModeSwitchOverlay();
      } catch (error) {
        cancelModeSwitch();
        throw error;
      }
    });
  }

  // 現地モード ON 切替時に GPS 取得
  function handleEnableLocal() {
    beginModeSwitch("local");
    setNeedsRevertOnClose(true); // iter129: apply せずに閉じたら revert
    if (typeof window === "undefined" || !navigator.geolocation) {
      // Geolocation なくても ON にする（fallback として last_lat/lng を維持）
      startTransition(async () => {
        try {
          const r = await enableLocalMode({});
          if (r?.error) {
            cancelModeSwitch();
            return;
          }
          setLocalEnabledOverride(true);
          setClientViewMode("local");
          replaceViewParam("local");
          setSheetOpen(true);
          hideModeSwitchOverlay(MODE_SWITCH_SHEET_STATUS_MS);
        } catch (error) {
          cancelModeSwitch();
          throw error;
        }
      });
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        startTransition(async () => {
          try {
            const r = await enableLocalMode({
              lat: pos.coords.latitude,
              lng: pos.coords.longitude,
            });
            if (r?.error) {
              cancelModeSwitch();
              return;
            }
            setLocalEnabledOverride(true);
            setClientViewMode("local");
            replaceViewParam("local");
            setSheetOpen(true);
            hideModeSwitchOverlay(MODE_SWITCH_SHEET_STATUS_MS);
          } catch (error) {
            cancelModeSwitch();
            throw error;
          }
        });
      },
      () => {
        // 取得失敗 → 位置情報なしで ON
        startTransition(async () => {
          try {
            const r = await enableLocalMode({});
            if (r?.error) {
              cancelModeSwitch();
              return;
            }
            setLocalEnabledOverride(true);
            setClientViewMode("local");
            replaceViewParam("local");
            setSheetOpen(true);
            hideModeSwitchOverlay(MODE_SWITCH_SHEET_STATUS_MS);
          } catch (error) {
            cancelModeSwitch();
            throw error;
          }
        });
      },
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 5 * 60_000 },
    );
  }

  // iter142: handleDisableLocal は撤廃（pill から DB を切り替えなくなったため）
  //   真の OFF は ConfirmOffDialog onConfirm 内でインラインで disableLocalMode を呼ぶ

  // chosen AW info
  const chosenAW = currentAW;
  const placeButtonLabel = isLocal && chosenAW?.venue
    ? truncateByChars(chosenAW.venue, 8)
    : "（現地交換モードOFF）";

  function handlePlaceButtonClick() {
    if (isLocal || currentAW) {
      setSheetOpen(true);
      return;
    }
    handleEnableLocal();
  }

  function handleLocalToggleClick() {
    if (isLocal) {
      setShowOffConfirm(true);
      return;
    }
    if (currentAW) {
      handleQuickReenable();
      return;
    }
    handleEnableLocal();
  }

  function buildMatchDetailPage(
    candidate: WishShelfCandidate,
  ): MatchDetailPageData {
    return {
      partnerHandle: candidate.card.userHandle,
      partnerId: candidate.card.partnerId,
      partnerAvatarUrl: candidate.card.userAvatarUrl,
      myAvatarUrl: profile?.avatar_url ?? null,
      myListings: candidate.myListingMatches,
      partnerListings: candidate.partnerListingMatches,
      myInventoryQty: candidate.card.myInventoryQty ?? {},
      simpleReceives: [candidate.item],
      simpleGives: candidate.card.myGives,
      simpleProposeHref: buildSimpleProposeHref(candidate),
      highlightedItemId: candidate.item.id,
    };
  }

  function handleSelectCandidate(candidate: WishShelfCandidate) {
    if (
      candidate.myListingMatches.length > 0 ||
      candidate.partnerListingMatches.length > 0
    ) {
      setDetailSlideDirection("from-right");
      setSelectedCandidate(candidate);
      writeMatchDetailHistory(candidate, "push");
      return;
    }
    router.push(buildSimpleProposeHref(candidate));
  }

  function getHistoryState(): Record<string, unknown> {
    const state = window.history.state;
    return state && typeof state === "object"
      ? { ...(state as Record<string, unknown>) }
      : {};
  }

  function writeMatchDetailHistory(
    candidate: WishShelfCandidate,
    mode: "push" | "replace",
  ) {
    if (typeof window === "undefined") return;
    const url = new URL(window.location.href);
    url.searchParams.set(MATCH_DETAIL_QUERY_KEY, candidate.key);
    const state = {
      ...getHistoryState(),
      megrumMatchDetail: true,
      matchDetailKey: candidate.key,
    };
    if (mode === "replace") {
      window.history.replaceState(state, "", url.toString());
    } else {
      window.history.pushState(state, "", url.toString());
    }
  }

  function clearMatchDetailHistoryEntry() {
    if (typeof window === "undefined") return;
    const url = new URL(window.location.href);
    if (!url.searchParams.has(MATCH_DETAIL_QUERY_KEY)) return;
    url.searchParams.delete(MATCH_DETAIL_QUERY_KEY);
    const state = {
      ...getHistoryState(),
      megrumMatchDetail: false,
      matchDetailKey: null,
    };
    window.history.replaceState(state, "", url.toString());
  }

  function handleDismissMatchDetail() {
    if (typeof window !== "undefined") {
      const url = new URL(window.location.href);
      const state = window.history.state as
        | { megrumMatchDetail?: boolean }
        | null;
      if (url.searchParams.has(MATCH_DETAIL_QUERY_KEY)) {
        if (state?.megrumMatchDetail) {
          window.history.back();
          return;
        }
        clearMatchDetailHistoryEntry();
      }
    }
    setSelectedCandidate(null);
  }

  function handleLeaveMatchDetailForRoute() {
    clearMatchDetailHistoryEntry();
  }

  function navigateMatchDetail(delta: -1 | 1) {
    if (selectedDetailIndex < 0) return;
    const next = detailCandidates[selectedDetailIndex + delta];
    if (!next) return;
    setDetailSlideDirection("none");
    setSelectedCandidate(next);
    writeMatchDetailHistory(next, "replace");
  }

  return (
    <main className="relative flex flex-1 flex-col bg-[#fbf9fc] pb-[88px]">
      {/* iter130: 現地交換モード時の ambient glow（画面縁をふわっと光らせる） */}
      {isLocal && <div aria-hidden="true" className="local-mode-glow" />}

      {/* モード切替・適用中のローディングオーバーレイ */}
      {showModeSwitchOverlay && (
        <div className="fixed inset-0 z-[80] flex items-start justify-center bg-[#fbf9fc]/38 px-5 pt-[calc(env(safe-area-inset-top)+86px)] backdrop-blur-[3px]">
          <div className="flex min-w-[210px] items-center gap-3 rounded-full border border-white/75 bg-white/86 px-4 py-3 shadow-[0_14px_32px_rgba(58,50,74,0.18)] backdrop-blur-xl">
            <span className="relative flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-[#a695d81c]">
              <span className="absolute h-8 w-8 animate-ping rounded-full bg-[#a695d833]" />
              <span className="relative block h-3.5 w-3.5 rounded-full bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] shadow-[0_0_14px_rgba(166,149,216,0.55)]" />
            </span>
            <span className="min-w-0 text-[13px] font-extrabold leading-snug text-[#3a324a]">
              {modeSwitchMessage}
            </span>
          </div>
        </div>
      )}
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col">
        <div className="flex items-center justify-between gap-3 px-5 pb-1.5 pt-4">
          <div className="flex items-center gap-2">
            <Link
              href="/notifications"
              className="relative flex h-9 w-9 items-center justify-center rounded-full border border-[#3a324a14] bg-white shadow-sm"
              aria-label="通知"
            >
              <svg
                width="15"
                height="15"
                viewBox="0 0 15 15"
                fill="none"
                stroke="#3a324a"
                strokeWidth="1.4"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M3.5 6a4 4 0 018 0v3l1 2H2.5l1-2V6z" />
                <path d="M6 13.5a1.5 1.5 0 003 0" />
              </svg>
              {unreadNotificationCount > 0 && (
                <span className="absolute -right-0.5 -top-0.5 flex h-[16px] min-w-[16px] items-center justify-center rounded-full bg-[#d9826b] px-1 text-[9px] font-extrabold tabular-nums text-white">
                  {unreadNotificationCount > 99
                    ? "99+"
                    : unreadNotificationCount}
                </span>
              )}
            </Link>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handlePlaceButtonClick}
              className="flex h-9 min-w-[76px] max-w-[170px] items-center justify-center truncate rounded-full border border-[#a695d83d] bg-white px-3 text-[12.5px] font-extrabold text-[#3a324a] shadow-sm active:scale-[0.98]"
              aria-label="交換場所と現地交換設定を開く"
            >
              <span className="truncate">{placeButtonLabel}</span>
            </button>
            <button
              type="button"
              onClick={handleLocalToggleClick}
              className={`flex h-9 w-9 items-center justify-center rounded-full border shadow-sm transition-colors ${
                isLocal
                  ? "border-[#a695d855] bg-[#a695d80a] active:bg-[#a695d814]"
                  : "border-[#3a324a14] bg-white active:bg-[#3a324a08]"
              }`}
              aria-label={
                isLocal
                  ? "現地交換モードを OFF にする"
                  : "現地交換モードを開始する"
              }
            >
              <span
                aria-hidden="true"
                className={`flex h-3.5 w-6 items-center rounded-full px-0.5 ${
                  isLocal ? "bg-[#a695d8]" : "bg-[#3a324a14]"
                }`}
              >
                <span
                  className={`block h-2.5 w-2.5 rounded-full bg-white ${
                    isLocal ? "ml-auto" : ""
                  }`}
                />
              </span>
            </button>
          </div>
        </div>

        {/* モード切替 pill
            iter142: pill は「view 切替」のみで DB を変えない。
            - 全国：?view=national にして AW フィルタを外す（現地モードは裏で ON のまま）
            - 現地：?view=national を外して AW フィルタを戻す
            真の OFF（DB 切替）は、上の chip タップ（確認ダイアログ）or 時間切れの 2 通りだけ。
            初回セットアップ時のみ handleEnableLocal で sheet を開く。 */}
        <div className="relative mx-5 mt-2 grid grid-cols-2 overflow-hidden rounded-full border border-white/80 bg-[#3a324a0a] p-1 shadow-[inset_0_1px_2px_rgba(58,50,74,0.08)]">
          <span
            aria-hidden="true"
            className={`pointer-events-none absolute inset-y-1 left-1 w-[calc(50%-4px)] rounded-full bg-white shadow-[0_5px_16px_rgba(58,50,74,0.16),inset_0_0_0_1px_rgba(255,255,255,0.88)] transition-transform duration-500 ease-[cubic-bezier(0.22,1,0.36,1)] motion-reduce:transition-none ${
              localModeActive ? "translate-x-full" : "translate-x-0"
            }`}
          />
          <button
            type="button"
            onClick={() => {
              if (visualViewMode !== "national") {
                beginModeSwitch("national");
                setClientViewMode("national");
                replaceViewParam("national");
                hideModeSwitchOverlay();
              }
            }}
            disabled={showModeSwitchOverlay}
            className={`relative z-10 rounded-full py-2 text-[12px] font-bold transition-[color,transform] duration-300 active:scale-[0.98] ${
              nationalModeActive ? "text-[#3a324a]" : "text-[#3a324a8c]"
            } disabled:opacity-50`}
          >
            🌐 全国交換モード
          </button>
          <button
            type="button"
            onClick={() => {
              if (isLocal) {
                if (visualViewMode === "national") {
                  // 全国 view を見ていた状態 → 現地 view に戻す
                  beginModeSwitch("local");
                  setClientViewMode("local");
                  replaceViewParam("local");
                  hideModeSwitchOverlay();
                } else {
                  // 既に現地 view → sheet を開いて設定変更
                  setSheetOpen(true);
                }
              } else if (currentAW) {
                // iter142.1: AW 設定済 + 現地 OFF → 即時 ON（chip と同じ挙動）
                //   sheet を開かない・revert flag も立てない
                handleQuickReenable();
              } else {
                // 初回セットアップ（AW 未設定 → sheet 必須）
                handleEnableLocal();
              }
            }}
            disabled={showModeSwitchOverlay}
            className={`relative z-10 rounded-full py-2 text-[12px] font-bold transition-[color,transform] duration-300 active:scale-[0.98] ${
              localModeActive ? "text-[#3a324a]" : "text-[#3a324a8c]"
            } disabled:opacity-50`}
          >
            📍 今すぐ現地交換モード
          </button>
        </div>

        <section className="mt-3 flex min-h-0 flex-1 flex-col">
          <div className="flex-1 space-y-1.5 overflow-y-auto px-5 py-2">
            {!hasWishShelfCandidates ? (
              <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white px-5 py-10 text-center">
                <div className="text-[13px] font-bold text-[#3a324a]">
                  現在マッチがありません
                </div>
                <div className="mt-1 text-[11px] leading-relaxed text-[#3a324a8c]">
                  Wish と譲の条件が重なると、ここに候補が並びます。
                </div>
              </div>
            ) : (
              <>
                <WishShelfSectionView
                  title="マッチしてるよ！"
                  rows={wishShelfSections.listingRows}
                  baseDelayMs={0}
                  onSelect={handleSelectCandidate}
                />
                <WishShelfSectionView
                  title="交換できるかも"
                  rows={wishShelfSections.possibleRows}
                  baseDelayMs={wishShelfSections.listingRows.length * 95 + 80}
                  onSelect={handleSelectCandidate}
                />
              </>
            )}

            {/* iter134: ようこそ表示・ログアウトはホーム画面から撤廃
                （ログアウトは /profile に集約済） */}
          </div>
        </section>
      </div>

      <Link
        href="/search"
        scroll={false}
        transitionTypes={["megrum-bottom-nav"]}
        className="fixed bottom-[calc(env(safe-area-inset-bottom)+88px)] left-[max(18px,calc((100vw-28rem)/2+18px))] z-50 flex h-[54px] w-[54px] items-center justify-center rounded-full border border-white/70 bg-white/62 text-[#3a324a] shadow-[0_16px_34px_rgba(58,50,74,0.18),inset_0_1px_0_rgba(255,255,255,0.9),inset_0_-1px_0_rgba(58,50,74,0.08)] backdrop-blur-[24px] backdrop-saturate-[180%] transition-transform active:scale-[0.94]"
        aria-label="検索"
      >
        <svg
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <circle cx="11" cy="11" r="7" />
          <path d="M16.5 16.5L21 21" />
        </svg>
      </Link>

      {selectedCandidate && (
        <MatchDetailModal
          key={selectedCandidate.key}
          partnerHandle={selectedCandidate.card.userHandle}
          partnerId={selectedCandidate.card.partnerId}
          partnerAvatarUrl={selectedCandidate.card.userAvatarUrl}
          myAvatarUrl={profile?.avatar_url ?? null}
          myListings={selectedCandidate.myListingMatches}
          partnerListings={selectedCandidate.partnerListingMatches}
          myInventoryQty={selectedCandidate.card.myInventoryQty ?? {}}
          simpleReceives={[selectedCandidate.item]}
          simpleGives={selectedCandidate.card.myGives}
          simpleProposeHref={buildSimpleProposeHref(selectedCandidate)}
          highlightedItemId={selectedCandidate.item.id}
          slideDirection={detailSlideDirection}
          previousPage={previousDetailPage}
          nextPage={nextDetailPage}
          canNavigatePrev={selectedDetailIndex > 0}
          canNavigateNext={
            selectedDetailIndex >= 0 &&
            selectedDetailIndex < detailCandidates.length - 1
          }
          onNavigatePrev={() => navigateMatchDetail(-1)}
          onNavigateNext={() => navigateMatchDetail(1)}
          onClose={handleDismissMatchDetail}
          onNavigateAway={handleLeaveMatchDetailForRoute}
        />
      )}

      {/* 現地モード設定シート（iter129: apply 無しで close したら全国へ revert） */}
      <LocalModeSheet
        open={sheetOpen}
        onClose={() => {
          setSheetOpen(false);
          if (needsRevertOnClose) {
            // 適用せずに閉じた → 全国モードに戻す
            beginModeSwitch("national");
            startTransition(async () => {
              try {
                const r = await disableLocalMode();
                if (r?.error) {
                  cancelModeSwitch();
                  return;
                }
                setLocalEnabledOverride(false);
                setClientViewMode("national");
                replaceViewParam("local");
                hideModeSwitchOverlay();
              } catch (error) {
                cancelModeSwitch();
                throw error;
              }
            });
          }
          setNeedsRevertOnClose(false);
        }}
        onApplied={() => {
          // 適用成功 → revert フラグをクリア（モード ON で確定）
          setNeedsRevertOnClose(false);
          setLocalEnabledOverride(true);
          setClientViewMode("local");
          replaceViewParam("local");
        }}
        initial={settings}
        currentAW={currentAW}
        carryingItems={carryingItems}
      />

      {/* iter133: 現地交換モード OFF 確認ダイアログ */}
      {showOffConfirm && (
        <ConfirmOffDialog
          onCancel={() => setShowOffConfirm(false)}
          onConfirm={() => {
            setShowOffConfirm(false);
            // iter142: 真の OFF（DB enabled=false）+ ?view=national を外す
            beginModeSwitch("national");
            startTransition(async () => {
              try {
                const r = await disableLocalMode();
                if (r?.error) {
                  cancelModeSwitch();
                  return;
                }
                setLocalEnabledOverride(false);
                setClientViewMode("national");
                replaceViewParam("local");
                hideModeSwitchOverlay();
              } catch (error) {
                cancelModeSwitch();
                throw error;
              }
            });
          }}
        />
      )}
    </main>
  );
}

function buildSimpleProposeHref(candidate: WishShelfCandidate): string {
  const params = new URLSearchParams();
  params.set("matchType", candidate.card.matchType);
  params.set("receives", candidate.item.id);
  if (candidate.card.myGives.length > 0) {
    params.set("gives", candidate.card.myGives.map((i) => i.id).join(","));
  }
  return `/propose/${candidate.card.partnerId}?${params.toString()}`;
}

function WishShelfSectionView({
  title,
  rows,
  baseDelayMs,
  onSelect,
}: {
  title: string;
  rows: WishShelfRow[];
  baseDelayMs: number;
  onSelect: (candidate: WishShelfCandidate) => void;
}) {
  if (rows.length === 0) return null;

  return (
    <section className="space-y-1.5 pt-2 first:pt-0">
      <h1 className="px-0.5 text-[22px] font-extrabold leading-tight text-[#111111]">
        {title}
      </h1>
      {rows.map((row, idx) => (
        <WishShelfRowView
          key={row.key}
          row={row}
          delayMs={baseDelayMs + idx * 95}
          onSelect={onSelect}
        />
      ))}
    </section>
  );
}

function WishShelfRowView({
  row,
  delayMs,
  onSelect,
}: {
  row: WishShelfRow;
  delayMs: number;
  onSelect: (candidate: WishShelfCandidate) => void;
}) {
  return (
    <section
      className="animate-section-fade-down py-0.5"
      style={{ animationDelay: `${delayMs}ms` }}
    >
      <div className="flex min-w-0 items-center gap-1.5 px-0.5">
        <h2 className="truncate text-[13px] font-extrabold leading-tight text-[#3a324a]">
          {row.characterLabel}
        </h2>
        <span className="flex-shrink-0 text-[10.5px] font-bold text-[#3a324a66]">
          × {row.goodsTypeName}
        </span>
      </div>

      <div className="home-shelf-row-scroll -mx-5 mt-1 flex gap-3 overflow-x-auto px-5 pb-4 pt-3 [&::-webkit-scrollbar]:hidden">
        {row.candidates.map((candidate, idx) => (
          <WishShelfTile
            key={candidate.key}
            candidate={candidate}
            delayMs={delayMs + idx * 85}
            onSelect={() => onSelect(candidate)}
          />
        ))}
      </div>
    </section>
  );
}

function WishShelfTile({
  candidate,
  delayMs,
  onSelect,
}: {
  candidate: WishShelfCandidate;
  delayMs: number;
  onSelect: () => void;
}) {
  const item = candidate.item;
  const hasPhoto = !!item.photoUrl;
  const tagLabel = candidate.tagLabels[0]
    ? truncateTagLabel(candidate.tagLabels[0], 8)
    : null;
  const fallbackBg = `repeating-linear-gradient(135deg, hsl(${item.hue}, 28%, 88%) 0 6px, hsl(${item.hue}, 28%, 78%) 6px 12px)`;
  const imageReady = useImageReady(item.photoUrl);

  return (
    <button
      type="button"
      onClick={onSelect}
      className={`home-shelf-tile group text-left active:scale-[0.97] ${
        imageReady
          ? "animate-home-shelf-panel-in"
          : "pointer-events-none opacity-0"
      }`}
      style={{ animationDelay: `${delayMs}ms` }}
      aria-label={`${item.label}の候補を開く`}
    >
      <div
        className={
          candidate.local
            ? "home-shelf-local-aura rounded-[16px]"
            : "rounded-[16px]"
        }
      >
        <div
          className={`home-shelf-tile-card match-card-inner relative overflow-hidden rounded-[16px] bg-[#f4f1f7] transition-transform duration-150 group-hover:-translate-y-0.5 ${getPriorityFrameClass(candidate.priority)}`}
          style={{ background: hasPhoto ? "#3a324a" : fallbackBg }}
        >
          {hasPhoto ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={item.photoUrl!}
              alt={item.label}
              className="absolute inset-0 h-full w-full object-cover"
              loading="lazy"
              decoding="async"
            />
          ) : (
            <span className="absolute inset-0 flex items-center justify-center text-[30px] font-extrabold text-white/95 drop-shadow">
              {item.label[0] ?? "?"}
            </span>
          )}
          {tagLabel && (
            <span className="absolute inset-x-2 bottom-1.5 z-10 truncate rounded-full bg-white/90 px-2 py-[3px] text-center text-[9px] font-extrabold text-[#3a324a] shadow-[0_2px_7px_rgba(58,50,74,0.18)] backdrop-blur">
              {tagLabel}
            </span>
          )}
        </div>
      </div>
    </button>
  );
}

/* ─── iter133: 現地交換モード OFF 確認ダイアログ ─── */

function ConfirmOffDialog({
  onCancel,
  onConfirm,
}: {
  onCancel: () => void;
  onConfirm: () => void;
}) {
  return (
    <div
      className="fixed inset-0 z-[120] flex items-center justify-center bg-black/55 px-4 backdrop-blur-sm"
      onClick={onCancel}
    >
      <div
        className="w-full max-w-sm overflow-hidden rounded-[18px] bg-white shadow-[0_20px_60px_rgba(0,0,0,0.3)]"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="px-4 pt-4 pb-2">
          <div className="flex items-center gap-2">
            <span className="text-[20px]">📍</span>
            <span className="text-[14px] font-extrabold text-[#3a324a]">
              現地交換モードを OFF にしますか？
            </span>
          </div>
          <div className="mt-2 text-[11.5px] leading-relaxed text-[#3a324a8c]">
            全国交換モードに切り替わります。設定した場所・時間・持参グッズは
            保存されたまま、いつでも再開できます。
          </div>
        </div>
        <div className="flex gap-2 border-t border-[#3a324a08] bg-[#fbf9fc] px-4 py-3">
          <button
            type="button"
            onClick={onCancel}
            className="flex-1 rounded-[10px] border border-[#3a324a14] bg-white py-2.5 text-[12px] font-extrabold text-[#3a324a]"
          >
            このまま続ける
          </button>
          <button
            type="button"
            onClick={onConfirm}
            className="flex-1 rounded-[10px] bg-[#3a324a] py-2.5 text-[12px] font-extrabold text-white shadow-[0_2px_6px_rgba(58,50,74,0.25)]"
          >
            OFF にする
          </button>
        </div>
      </div>
    </div>
  );
}
