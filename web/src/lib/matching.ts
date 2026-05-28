/**
 * Megrum マッチング演算（純関数）
 *
 * 仕様: notes/18_matching_v2_design.md
 *
 * MVP のスコープ:
 * - 完全マッチ / 片方向マッチ（forward / backward）
 * - 個別募集（listings）の優先: 譲 X に listing があれば、その listing.wish_ids
 *   群でしかマッチしない（通常 wish より優先）
 * - 同種 / 異種 / どちらでも は **タグ表示のみ**、判定には使わない（§A-1）
 * - 時空交差は呼び出し側で別途フィルタ（mode=local の時）
 */

export type MatchInv = {
  id: string;
  userId: string;
  groupId: string | null;
  characterId: string | null;
  characterRequestId: string | null;
  goodsTypeId: string;
  title: string;
  photoUrl: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  exchangeType: "same_kind" | "cross_kind" | "any";
};

export type UserSummary = {
  id: string;
  handle: string;
  displayName: string;
  primaryArea: string | null;
  /** iter125: アバター URL（avatars バケットの publicUrl） */
  avatarUrl: string | null;
};

export type Match = {
  partner: UserSummary;
  matchType: "complete" | "they_want_you" | "you_want_them";
  /** 私が出す譲 = 相手の wish にヒットしたもの */
  myGives: MatchInv[];
  /** 相手の譲 = 私の wish にヒットしたもの */
  theirGives: MatchInv[];
  /** 個別募集経由のマッチか（自分側 or 相手側いずれかの listing が成立） */
  viaListing: boolean;
  /**
   * iter72-B: 個別募集マッチの種類を細分化。
   *   - "both": 自分の listing と相手の listing が両方成立（A パターン：完璧な双方向）
   *   - "mine_only": 自分の listing だけ成立（相手は通常在庫で応える）
   *   - "partner_only": 相手の listing だけ成立（**自分は通常在庫を駆使して応える** → B パターン）
   *   - "none": listing 経由マッチではない（普通の wish ↔ 譲）
   *
   * UI:
   *   - "both" → ✨ 相手の個別募集にもマッチ！（強調）
   *   - "partner_only" → 📦 相手の個別募集に応えられます（応えて打診 CTA）
   *   - "mine_only" → 📦 あなたの個別募集に相手が応えられます
   */
  listingMatchKind: "both" | "mine_only" | "partner_only" | "none";
  /**
   * iter71-F: 「双方向 listing マッチ」フラグ（後方互換）。listingMatchKind === "both" と同義。
   */
  bothSidesListingMatch: boolean;
  /**
   * 私の個別募集が成立したもの（私 = listing オーナー視点）
   * iter67.6 で `matchedListings` から rename
   */
  myMatchedListings?: MatchedListingInfo[];
  /**
   * 相手の個別募集が成立したもの（相手 = listing オーナー視点）
   * iter67.6 で新規。partner の listing を私の inventory が満たすかを評価
   */
  partnerMatchedListings?: MatchedListingInfo[];
  /**
   * 私と相手の最短距離（m）。現地モード ON 時のみ計算される（iter67.6）
   */
  distanceMeters?: number;
  /**
   * 自分/相手ともに現地交換モードで、AW の日時・範囲が重なった候補。
   * 距離が取れない環境でも「現地交換できる可能性」は示せるよう distanceMeters と分ける。
   */
  localMatch?: boolean;
};

export type MatchedListingInfo = {
  listingId: string;
  // 譲側
  haveIds: string[];
  haveQtys: number[];
  haveLogic: "and" | "or";
  haveGroupId: string | null;
  haveGoodsTypeId: string | null;
  /** マッチに寄与した私の譲（haveIds の subset） */
  matchedHaveIds: string[];
  // 求側（全選択肢、成立フラグ付き）
  options: MatchedOptionInfo[];
};

export type MatchedOptionInfo = {
  id: string;
  position: number;
  wishIds: string[];
  wishQtys: number[];
  logic: "and" | "or";
  exchangeType: "same_kind" | "cross_kind" | "any";
  isCashOffer: boolean;
  cashAmount: number | null;
  /** この選択肢が成立したか */
  matched: boolean;
  /** この選択肢に該当した相手の inventory id 群（matched=true の時のみ） */
  matchedTheirInvIds: string[];
  /**
   * iter104: wish ごとに、ヒットした相手 inventory id を保持。
   * 関係図で「wish A → 候補1, 候補2, ...」を写真で並べるため。
   * 順序は opt.wishIds と一致。matched=false の wish には [] が入る。
   * 単一 wish の場合は [{ wishId: opt.wishIds[0], theirInvIds: [...] }] となる。
   */
  matchedHitsByWish: { wishId: string; theirInvIds: string[] }[];
};

/**
 * 1 アイテム同士のマッチ判定。
 *
 * - 同じ goods_type_id が必須
 * - キャラ指定がある場合は character_id 一致必須
 * - キャラ指定がない場合は group_id 一致でマッチ（箱推し的）
 */
export function isMatching(my: MatchInv, theirs: MatchInv): boolean {
  if (my.goodsTypeId !== theirs.goodsTypeId) return false;
  if (my.characterId && theirs.characterId) {
    return my.characterId === theirs.characterId;
  }
  // どちらかキャラ未指定 → group_id で判定（共に group_id 必須）
  if (!my.groupId || !theirs.groupId) return false;
  return my.groupId === theirs.groupId;
}

/**
 * iter67.4：listings の求側を「複数選択肢」モデルに再設計。
 *
 * - 譲側：1 つのバンドル（同 group + 同 goods_type 制約、AND/OR）
 * - 求側：複数の選択肢（最大 5）。選択肢間は OR（相手が 1 つ選ぶ）
 *   各選択肢は独立に：group + goods_type + AND/OR + qty + exchange_type + 定価交換フラグ
 */
export type ListingWishOption = {
  id: string;
  position: number;
  wishIds: string[];
  wishQtys: number[];
  logic: "and" | "or";
  exchangeType: "same_kind" | "cross_kind" | "any";
  isCashOffer: boolean;
  cashAmount: number | null;
};

export type ListingForMatch = {
  id: string;
  haveIds: string[];
  haveQtys: number[];
  haveLogic: "and" | "or";
  haveGroupId: string | null;
  haveGoodsTypeId: string | null;
  options: ListingWishOption[];
};

/**
 * 私 × 1 パートナー の組合せに対してマッチを 1 つ計算（iter67.6 で partner listings 評価追加）。
 *
 * @param myInventory      私の譲 (kind=for_trade, status=active)
 * @param myWishes         私の wish (kind=wanted, status=active)
 * @param myListings       私の active な listings
 * @param myWishById       私の wish を id で引く Map
 * @param myInvById        私の inventory を id で引く Map
 * @param partnerInv       相手の譲
 * @param partnerWishes    相手の wish
 * @param partnerListings  相手の active な listings（iter67.6 追加）
 * @param partnerInvById   相手の inventory を id で引く Map（iter67.6 追加）
 * @param partnerWishById  相手の wish を id で引く Map（iter67.6 追加）
 * @param partner          相手の UserSummary
 */
export function matchPair(input: {
  myInventory: MatchInv[];
  myWishes: MatchInv[];
  myListings: ListingForMatch[];
  myWishById: Map<string, MatchInv>;
  myInvById: Map<string, MatchInv>;
  partnerInv: MatchInv[];
  partnerWishes: MatchInv[];
  partnerListings: ListingForMatch[];
  partnerInvById: Map<string, MatchInv>;
  partnerWishById: Map<string, MatchInv>;
  partner: UserSummary;
}): Match | null {
  const {
    myInventory,
    myWishes,
    myListings,
    myWishById,
    myInvById,
    partnerInv,
    partnerWishes,
    partnerListings,
    partnerInvById,
    partnerWishById,
    partner,
  } = input;

  /* ─── どの私の譲が listing でカバーされているか ─── */
  const listingsCoveringInv = new Map<string, ListingForMatch[]>();
  for (const l of myListings) {
    for (const hid of l.haveIds) {
      const arr = listingsCoveringInv.get(hid) ?? [];
      arr.push(l);
      listingsCoveringInv.set(hid, arr);
    }
  }

  /* ─── 結果プール ─── */
  const myGivesMap = new Map<string, MatchInv>();
  const theirGivesMap = new Map<string, MatchInv>();
  const myMatchedListings: MatchedListingInfo[] = [];
  const partnerMatchedListings: MatchedListingInfo[] = [];
  let viaListing = false;

  /* ─── 1a. 私の listing 駆動マッチ（partnerInv が私の wish に hit） ─── */
  for (const l of myListings) {
    const lm = evaluateListingMatch(l, myInvById, myWishById, partnerInv);
    if (!lm) continue;
    viaListing = true;
    myMatchedListings.push({
      listingId: l.id,
      haveIds: l.haveIds,
      haveQtys: l.haveQtys,
      haveLogic: l.haveLogic,
      haveGroupId: l.haveGroupId,
      haveGoodsTypeId: l.haveGoodsTypeId,
      matchedHaveIds: lm.matchedHaveIds,
      options: lm.options,
    });
    for (const id of lm.matchedHaveIds) {
      const inv = myInvById.get(id);
      if (inv) myGivesMap.set(inv.id, inv);
    }
    for (const opt of lm.options) {
      if (!opt.matched) continue;
      for (const id of opt.matchedTheirInvIds) {
        const inv = partnerInv.find((p) => p.id === id);
        if (inv) theirGivesMap.set(inv.id, inv);
      }
    }
  }

  /* ─── 1b. 相手の listing 駆動マッチ（myInventory が相手の wish に hit） ─── */
  // iter72.1：A パターン（厳密双方向）の判定用に、自分の listing.haves だけで
  // 相手の listing が成立するかを別評価する。
  //   - "loose" = myInventory（私の全在庫）で評価 → これを partnerMatchedListings に保存
  //   - "strict" = 私の listing.haves だけで評価 → bothSidesListingMatch 判定に使う
  // 「自分は listing 成立 + 相手の listing は通常在庫を駆使してようやく成立」のケースを
  // "both" 扱いから外すため。
  const myListingHaveIdSet = new Set<string>();
  for (const l of myListings) {
    for (const id of l.haveIds) myListingHaveIdSet.add(id);
  }
  const myListingHavesAsInv = myInventory.filter((m) =>
    myListingHaveIdSet.has(m.id),
  );

  let partnerListingStrictlyMatched = false; // 厳密判定用フラグ

  for (const l of partnerListings) {
    const lm = evaluateListingMatch(
      l,
      partnerInvById,
      partnerWishById,
      myInventory,
    );
    if (!lm) continue;
    viaListing = true;
    partnerMatchedListings.push({
      listingId: l.id,
      haveIds: l.haveIds,
      haveQtys: l.haveQtys,
      haveLogic: l.haveLogic,
      haveGroupId: l.haveGroupId,
      haveGoodsTypeId: l.haveGoodsTypeId,
      matchedHaveIds: lm.matchedHaveIds,
      options: lm.options,
    });
    // 相手 listing の have（=相手が出すもの）を theirGives へ
    for (const id of lm.matchedHaveIds) {
      const inv = partnerInvById.get(id);
      if (inv) theirGivesMap.set(inv.id, inv);
    }
    // 相手 listing が成立した選択肢の「私のアイテム」を myGives へ
    for (const opt of lm.options) {
      if (!opt.matched) continue;
      for (const id of opt.matchedTheirInvIds) {
        const inv = myInventory.find((m) => m.id === id);
        if (inv) myGivesMap.set(inv.id, inv);
      }
    }

    // 厳密判定：私の listing.haves だけで応えられるか？
    if (myListingHavesAsInv.length > 0 && !partnerListingStrictlyMatched) {
      const strictLm = evaluateListingMatch(
        l,
        partnerInvById,
        partnerWishById,
        myListingHavesAsInv,
      );
      if (strictLm) partnerListingStrictlyMatched = true;
    }
  }

  /* ─── 2. 通常マッチ（listing にカバーされていない譲・求） ─── */

  // forward: 私の譲が相手の wish にヒット（listing 駆動でない譲のみ）
  for (const myInv of myInventory) {
    if (myGivesMap.has(myInv.id)) continue;
    if (listingsCoveringInv.has(myInv.id)) continue; // listing 側でハンドル済み
    for (const theirWish of partnerWishes) {
      if (isMatching(myInv, theirWish)) {
        myGivesMap.set(myInv.id, myInv);
        break;
      }
    }
  }

  // backward: 相手の譲が私の wish にヒット（listing 経由で既出のものは除く）
  for (const theirInv of partnerInv) {
    if (theirGivesMap.has(theirInv.id)) continue;
    for (const myWish of myWishes) {
      if (isMatching(theirInv, myWish)) {
        theirGivesMap.set(theirInv.id, theirInv);
        break;
      }
    }
  }

  if (myGivesMap.size === 0 && theirGivesMap.size === 0) return null;

  // iter72-B + iter72.1: listing マッチの種類を細分化（厳密判定）
  // "both" は **自分の listing が成立 AND 相手の listing も「私の listing.haves だけで」成立** のときのみ
  const hasMyListing = myMatchedListings.length > 0;
  const hasPartnerListing = partnerMatchedListings.length > 0;
  const listingMatchKind: Match["listingMatchKind"] =
    hasMyListing && partnerListingStrictlyMatched
      ? "both"
      : hasMyListing
        ? "mine_only"
        : hasPartnerListing
          ? "partner_only"
          : "none";
  const bothSidesListingMatch = listingMatchKind === "both";

  let matchType: Match["matchType"];
  if (myGivesMap.size > 0 && theirGivesMap.size > 0) {
    // iter71-F: 「個別募集片側だけ + 反対側は通常マッチ」のケースは
    // perfect 扱いにせず、片方向に格下げ。「双方向 listing」のみ complete。
    if (listingMatchKind === "mine_only") {
      // 自分の listing だけマッチ → 相手が私のものを欲しがっている寄り
      matchType = "they_want_you";
    } else if (listingMatchKind === "partner_only") {
      // 相手の listing だけマッチ → 私が相手の listing に応えられる寄り
      matchType = "you_want_them";
    } else {
      matchType = "complete";
    }
  } else if (myGivesMap.size > 0) {
    matchType = "they_want_you";
  } else {
    matchType = "you_want_them";
  }

  return {
    partner,
    matchType,
    myGives: Array.from(myGivesMap.values()),
    theirGives: Array.from(theirGivesMap.values()),
    viaListing,
    listingMatchKind,
    bothSidesListingMatch,
    myMatchedListings:
      myMatchedListings.length > 0 ? myMatchedListings : undefined,
    partnerMatchedListings:
      partnerMatchedListings.length > 0
        ? partnerMatchedListings
        : undefined,
  };
}

/**
 * iter67.4：1 listing が相手とマッチするかを「選択肢」モデルで判定。
 *
 * 仕様:
 * - 各選択肢を独立に評価：
 *   - 定価交換 (is_cash_offer=true) は MVP では「常に成立」扱い（マッチング演算では発火しない）
 *     → 通常の wish 系マッチには寄与しない。UI 表示のみ
 *   - 通常選択肢：option.logic に従って相手の譲群と整合判定
 *     - AND: 全 wish_ids が相手の譲群のいずれかにヒット必要
 *     - OR : 少なくとも 1 件で OK
 * - listing が成立 = 少なくとも 1 つの選択肢が成立
 * - 成立時：listing.have_logic に従って譲を出す
 *
 * 数量 (qty) はマッチ判定では未使用（タグ表示のみ）。実数量は打診で調整。
 *
 * @returns null = listing 全体不成立 / { matchedHaveIds, options } = 寄与情報
 */
function evaluateListingMatch(
  listing: ListingForMatch,
  myInvById: Map<string, MatchInv>,
  myWishById: Map<string, MatchInv>,
  partnerInv: MatchInv[],
): {
  matchedHaveIds: string[];
  options: MatchedOptionInfo[];
} | null {
  const optionResults: MatchedOptionInfo[] = [];

  for (const opt of listing.options) {
    if (opt.isCashOffer) {
      // 定価交換は MVP マッチング対象外（UI 表示のみ、matched=false で記録）
      optionResults.push({
        id: opt.id,
        position: opt.position,
        wishIds: opt.wishIds,
        wishQtys: opt.wishQtys,
        logic: opt.logic,
        exchangeType: opt.exchangeType,
        isCashOffer: true,
        cashAmount: opt.cashAmount,
        matched: false,
        matchedTheirInvIds: [],
        matchedHitsByWish: [],
      });
      continue;
    }

    // 各 wish_id について「相手の譲群のいずれかにヒット」したかを判定
    const matchedByWishId = new Map<string, string[]>();
    for (const wid of opt.wishIds) {
      const myWish = myWishById.get(wid);
      if (!myWish) continue;
      const hits = partnerInv
        .filter((p) => isMatching(p, myWish))
        .map((p) => p.id);
      if (hits.length > 0) {
        matchedByWishId.set(wid, hits);
      }
    }

    const optMatched =
      opt.logic === "and"
        ? opt.wishIds.every((wid) => matchedByWishId.has(wid))
        : matchedByWishId.size > 0;

    // iter104: wish 順に対応する hits 配列を作る（matched 時のみ値、未 matched は []）
    const matchedHitsByWish = opt.wishIds.map((wid) => ({
      wishId: wid,
      theirInvIds: optMatched ? matchedByWishId.get(wid) ?? [] : [],
    }));

    optionResults.push({
      id: opt.id,
      position: opt.position,
      wishIds: opt.wishIds,
      wishQtys: opt.wishQtys,
      logic: opt.logic,
      exchangeType: opt.exchangeType,
      isCashOffer: false,
      cashAmount: null,
      matched: optMatched,
      matchedTheirInvIds: optMatched
        ? Array.from(new Set(Array.from(matchedByWishId.values()).flat()))
        : [],
      matchedHitsByWish,
    });
  }

  // listing 全体が成立する条件：少なくとも 1 つの「通常」選択肢が matched
  const anyMatched = optionResults.some((o) => o.matched);
  if (!anyMatched) return null;

  // 譲側：have_logic=AND なら全件、OR なら 1 件のみ
  const matchedHaveIds: string[] =
    listing.haveLogic === "and"
      ? listing.haveIds.filter((hid) => myInvById.has(hid))
      : listing.haveIds.filter((hid) => myInvById.has(hid)).slice(0, 1);

  if (matchedHaveIds.length === 0) return null;

  return { matchedHaveIds, options: optionResults };
}

/**
 * 全パートナーに対してマッチを計算し、ソート済み配列を返す。
 *
 * ソート: complete > they_want_you = you_want_them
 *         同タイプ内では viaListing 優先
 */
export function computeAllMatches(input: {
  myInventory: MatchInv[];
  myWishes: MatchInv[];
  myListings: ListingForMatch[];
  partners: Array<{
    user: UserSummary;
    inventory: MatchInv[];
    wishes: MatchInv[];
    /** iter67.6: 相手の listings（同じ user_id のもの） */
    listings: ListingForMatch[];
  }>;
}): Match[] {
  const myWishById = new Map<string, MatchInv>();
  for (const w of input.myWishes) myWishById.set(w.id, w);
  const myInvById = new Map<string, MatchInv>();
  for (const i of input.myInventory) myInvById.set(i.id, i);

  const matches: Match[] = [];
  for (const p of input.partners) {
    const partnerInvById = new Map<string, MatchInv>();
    for (const i of p.inventory) partnerInvById.set(i.id, i);
    const partnerWishById = new Map<string, MatchInv>();
    for (const w of p.wishes) partnerWishById.set(w.id, w);

    const m = matchPair({
      myInventory: input.myInventory,
      myWishes: input.myWishes,
      myListings: input.myListings,
      myWishById,
      myInvById,
      partnerInv: p.inventory,
      partnerWishes: p.wishes,
      partnerListings: p.listings,
      partnerInvById,
      partnerWishById,
      partner: p.user,
    });
    if (m) matches.push(m);
  }

  // ソート（iter67.6 で viaListing 優先に変更）
  const order = { complete: 0, they_want_you: 1, you_want_them: 2 } as const;
  matches.sort((a, b) => {
    // listing 経由 を最上位に
    if (a.viaListing !== b.viaListing) return a.viaListing ? -1 : 1;
    // 同じ群内では matchType 順
    const oa = order[a.matchType];
    const ob = order[b.matchType];
    if (oa !== ob) return oa - ob;
    return 0;
  });

  return matches;
}

/**
 * UI ラベル生成（マッチカードの「譲・受」に使う）。
 *
 * 例: "スア トレカ / ヒナ 缶バッジ +2"
 */
export function buildLabel(items: MatchInv[]): string {
  if (items.length === 0) return "—";
  const labels = items.slice(0, 3).map((it) =>
    `${it.characterName ?? it.groupName ?? "?"} ${it.goodsTypeName ?? ""}`.trim(),
  );
  const main = labels.join(" / ");
  return items.length > 3 ? `${main} +${items.length - 3}` : main;
}

/**
 * 2 点間の距離（メートル）— Haversine 公式
 */
export function haversineMeters(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const R = 6371000; // 地球半径 m
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * AW の時空交差判定: 時間帯が重なる + 距離が radius 内
 */
export function awsOverlap(
  myAW: {
    startAt: string;
    endAt: string;
    centerLat: number | null;
    centerLng: number | null;
    radiusM: number;
  },
  theirAW: {
    startAt: string;
    endAt: string;
    centerLat: number | null;
    centerLng: number | null;
    radiusM: number;
  },
): boolean {
  // 時間
  const myStart = new Date(myAW.startAt).getTime();
  const myEnd = new Date(myAW.endAt).getTime();
  const theirStart = new Date(theirAW.startAt).getTime();
  const theirEnd = new Date(theirAW.endAt).getTime();
  if (myEnd < theirStart || theirEnd < myStart) return false;

  // 空間（座標がなければ時間だけ重なれば OK と扱う）
  if (
    myAW.centerLat === null ||
    myAW.centerLng === null ||
    theirAW.centerLat === null ||
    theirAW.centerLng === null
  ) {
    return true;
  }
  const dist = haversineMeters(
    myAW.centerLat,
    myAW.centerLng,
    theirAW.centerLat,
    theirAW.centerLng,
  );
  // 双方の半径合計内なら交差
  return dist <= myAW.radiusM + theirAW.radiusM;
}
