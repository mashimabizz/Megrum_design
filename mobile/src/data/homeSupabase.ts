import { supabase } from "../lib/supabase";
import type {
  Candidate,
  CandidatePriority,
  ShelfSection,
} from "./homeMatches";

type RelationName = { name: string | null } | { name: string | null }[] | null;

type GoodsRow = {
  id: string;
  user_id: string;
  group_id: string | null;
  character_id: string | null;
  character_request_id?: string | null;
  goods_type_id: string | null;
  title: string;
  photo_urls: string[] | null;
  quantity?: number | null;
  exchange_type?: "same_kind" | "cross_kind" | "any" | null;
  hue?: number | string | null;
  group: RelationName;
  character: RelationName;
  goods_type: RelationName;
};

type Inv = {
  id: string;
  userId: string;
  groupId: string | null;
  characterId: string | null;
  goodsTypeId: string;
  title: string;
  photoUrl: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  hue: string;
};

type UserRow = {
  id: string;
  handle: string | null;
  display_name: string | null;
  primary_area: string | null;
  avatar_url: string | null;
};

type ListingRow = {
  id: string;
  user_id: string;
  have_ids: string[] | null;
  have_qtys: number[] | null;
  have_logic: "and" | "or" | null;
  have_group_id: string | null;
  have_goods_type_id: string | null;
};

type ListingOptionRow = {
  id: string;
  listing_id: string;
  position: number;
  wish_ids: string[] | null;
  wish_qtys: number[] | null;
  logic: "and" | "or" | null;
  exchange_type: "same_kind" | "cross_kind" | "any" | null;
  is_cash_offer: boolean | null;
  cash_amount: number | null;
};

type ListingForMatch = {
  id: string;
  userId: string;
  haveIds: string[];
  haveQtys: number[];
  haveLogic: "and" | "or";
  options: ListingOption[];
};

type ListingOption = {
  id: string;
  position: number;
  wishIds: string[];
  wishQtys: number[];
  logic: "and" | "or";
  isCashOffer: boolean;
};

type Partner = {
  user: {
    id: string;
    handle: string;
    displayName: string;
    primaryArea: string | null;
    avatarUrl: string | null;
  };
  inventory: Inv[];
  wishes: Inv[];
  listings: ListingForMatch[];
};

type Match = {
  partner: Partner["user"];
  matchType: "complete" | "they_want_you" | "you_want_them";
  myGives: Inv[];
  theirGives: Inv[];
  listingMatchKind: "both" | "mine_only" | "partner_only" | "none";
  myListingIds: string[];
  partnerListingIds: string[];
  myListingIdsByTheirGiveId: Record<string, string[]>;
  partnerListingIdsByTheirGiveId: Record<string, string[]>;
  local: boolean;
};

type AWRow = {
  id: string;
  user_id: string;
  venue?: string | null;
  start_at: string;
  end_at: string;
  radius_m: number | null;
  center_lat: number | null;
  center_lng: number | null;
};

type LocalModeRow = {
  enabled: boolean | null;
  aw_id: string | null;
};

type TagPairRow = {
  inventory_id: string;
  tag_id: string;
  tag: { label: string | null } | { label: string | null }[] | null;
};

type TagMaps = {
  tagsByInvId: Record<string, string[]>;
  tagLabelsByInvId: Record<string, string[]>;
};

type CandidateSource = {
  item: Inv;
  side: "mine" | "partner";
};

export type HomeSupabaseResult = {
  sections: ShelfSection[];
  localModeEnabled: boolean;
  placeLabel: string | null;
  unreadNotificationCount: number;
};

export async function fetchHomeSupabaseSections(
  userId: string,
): Promise<HomeSupabaseResult> {
  if (!supabase) {
    return {
      sections: [],
      localModeEnabled: false,
      placeLabel: null,
      unreadNotificationCount: 0,
    };
  }

  const goodsSelect =
    "id, user_id, group_id, character_id, character_request_id, goods_type_id, title, photo_urls, quantity, exchange_type, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)";

  const [
    { data: localModeRaw },
    { data: myInventoryRaw },
    { data: myWishesRaw },
    { data: myListingsRaw },
    { data: otherInventoryRaw },
    { data: otherWishesRaw },
    { data: otherUsersRaw },
    { data: otherListingsRaw },
    { data: myAWsRaw },
    { data: otherAWsRaw },
    { count: unreadNotificationCount },
  ] = await Promise.all([
    supabase
      .from("user_local_mode_settings")
      .select("enabled, aw_id")
      .eq("user_id", userId)
      .maybeSingle(),
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .eq("user_id", userId)
      .eq("kind", "for_trade")
      .eq("status", "active"),
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .eq("user_id", userId)
      .eq("kind", "wanted")
      .neq("status", "archived"),
    supabase
      .from("listings")
      .select("id, user_id, have_ids, have_qtys, have_logic, have_group_id, have_goods_type_id")
      .eq("user_id", userId)
      .eq("status", "active"),
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .neq("user_id", userId)
      .eq("kind", "for_trade")
      .eq("status", "active")
      .limit(500),
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .neq("user_id", userId)
      .eq("kind", "wanted")
      .neq("status", "archived")
      .limit(500),
    supabase
      .from("users")
      .select("id, handle, display_name, primary_area, avatar_url")
      .neq("id", userId)
      .limit(500),
    supabase
      .from("listings")
      .select("id, user_id, have_ids, have_qtys, have_logic, have_group_id, have_goods_type_id")
      .neq("user_id", userId)
      .eq("status", "active")
      .limit(500),
    supabase
      .from("activity_windows")
      .select("id, user_id, venue, start_at, end_at, radius_m, center_lat, center_lng")
      .eq("user_id", userId)
      .eq("status", "enabled"),
    supabase
      .from("activity_windows")
      .select("id, user_id, venue, start_at, end_at, radius_m, center_lat, center_lng")
      .neq("user_id", userId)
      .eq("status", "enabled")
      .limit(500),
    supabase
      .from("notifications")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .is("read_at", null),
  ]);

  const localMode = localModeRaw as LocalModeRow | null;
  const myAWs = (myAWsRaw as AWRow[] | null) ?? [];
  const currentAW = myAWs.find((aw) => aw.id === localMode?.aw_id) ?? myAWs[0] ?? null;
  const myInventory = ((myInventoryRaw as GoodsRow[] | null) ?? [])
    .map(toInv)
    .filter((item): item is Inv => !!item);
  const myWishes = ((myWishesRaw as GoodsRow[] | null) ?? [])
    .map(toInv)
    .filter((item): item is Inv => !!item);
  const otherInventory = ((otherInventoryRaw as GoodsRow[] | null) ?? [])
    .map(toInv)
    .filter((item): item is Inv => !!item);
  const otherWishes = ((otherWishesRaw as GoodsRow[] | null) ?? [])
    .map(toInv)
    .filter((item): item is Inv => !!item);

  const allListings = [
    ...(((myListingsRaw as ListingRow[] | null) ?? [])),
    ...(((otherListingsRaw as ListingRow[] | null) ?? [])),
  ];
  const optionsByListing = await fetchListingOptions(allListings.map((listing) => listing.id));
  const listings = allListings.map((row) => toListing(row, optionsByListing));
  const myListings = listings.filter((listing) => listing.userId === userId);
  const partnerListingsByUser = groupBy(
    listings.filter((listing) => listing.userId !== userId),
    (listing) => listing.userId,
  );

  const partners = new Map<string, Partner>();
  for (const user of ((otherUsersRaw as UserRow[] | null) ?? [])) {
    partners.set(user.id, {
      user: {
        id: user.id,
        handle: user.handle ?? "unknown",
        displayName: user.display_name ?? user.handle ?? "ユーザー",
        primaryArea: user.primary_area,
        avatarUrl: user.avatar_url,
      },
      inventory: [],
      wishes: [],
      listings: partnerListingsByUser.get(user.id) ?? [],
    });
  }
  for (const inv of otherInventory) {
    partners.get(inv.userId)?.inventory.push(inv);
  }
  for (const wish of otherWishes) {
    partners.get(wish.userId)?.wishes.push(wish);
  }

  const localPartnerIds = buildLocalPartnerSet({
    enabled: !!localMode?.enabled,
    currentAW,
    partnerAWs: (otherAWsRaw as AWRow[] | null) ?? [],
  });
  const { tagsByInvId, tagLabelsByInvId } = await fetchInventoryTags([
    ...myInventory,
    ...myWishes,
    ...otherInventory,
    ...otherWishes,
  ]).catch(() => emptyTagMaps());
  const matches = computeMatches({
    myInventory,
    myWishes,
    myListings,
    partners: Array.from(partners.values()),
    localPartnerIds,
  });

  return {
    sections: buildSections(matches, myWishes, tagsByInvId, tagLabelsByInvId),
    localModeEnabled: !!localMode?.enabled,
    placeLabel: currentAW?.venue ?? null,
    unreadNotificationCount: unreadNotificationCount ?? 0,
  };
}

async function fetchInventoryTags(items: Inv[]): Promise<TagMaps> {
  const tagsByInvId: Record<string, string[]> = {};
  const tagLabelsByInvId: Record<string, string[]> = {};
  const ids = Array.from(new Set(items.map((item) => item.id)));
  if (!supabase || ids.length === 0) return { tagsByInvId, tagLabelsByInvId };

  const { data } = await supabase
    .from("goods_inventory_tags")
    .select("inventory_id, tag_id, tag:tags_master(label)")
    .in("inventory_id", ids);

  for (const row of (data as TagPairRow[] | null) ?? []) {
    const tags = tagsByInvId[row.inventory_id] ?? [];
    tags.push(row.tag_id);
    tagsByInvId[row.inventory_id] = tags;

    const tag = Array.isArray(row.tag) ? row.tag[0] : row.tag;
    if (tag?.label) {
      const labels = tagLabelsByInvId[row.inventory_id] ?? [];
      labels.push(tag.label);
      tagLabelsByInvId[row.inventory_id] = labels;
    }
  }

  return { tagsByInvId, tagLabelsByInvId };
}

function emptyTagMaps(): TagMaps {
  return { tagsByInvId: {}, tagLabelsByInvId: {} };
}

async function fetchListingOptions(listingIds: string[]) {
  if (!supabase || listingIds.length === 0) return new Map<string, ListingOptionRow[]>();
  const { data } = await supabase
    .from("listing_wish_options")
    .select("id, listing_id, position, wish_ids, wish_qtys, logic, exchange_type, is_cash_offer, cash_amount")
    .in("listing_id", listingIds)
    .order("position", { ascending: true });
  return groupBy((data as ListingOptionRow[] | null) ?? [], (option) => option.listing_id);
}

function computeMatches(input: {
  myInventory: Inv[];
  myWishes: Inv[];
  myListings: ListingForMatch[];
  partners: Partner[];
  localPartnerIds: Set<string>;
}): Match[] {
  const myInvById = new Map(input.myInventory.map((item) => [item.id, item]));
  const myWishById = new Map(input.myWishes.map((item) => [item.id, item]));

  const matches = input.partners
    .map((partner) =>
      computePartnerMatch({
        partner,
        myInventory: input.myInventory,
        myWishes: input.myWishes,
        myListings: input.myListings,
        myInvById,
        myWishById,
        local: input.localPartnerIds.has(partner.user.id),
      }),
    )
    .filter((match): match is Match => !!match);

  const order = { both: 0, mine_only: 1, partner_only: 1, none: 2 } as const;
  return matches.sort((a, b) => {
    const listingOrder = order[a.listingMatchKind] - order[b.listingMatchKind];
    if (listingOrder !== 0) return listingOrder;
    if (a.local !== b.local) return a.local ? -1 : 1;
    return b.theirGives.length - a.theirGives.length;
  });
}

function computePartnerMatch(input: {
  partner: Partner;
  myInventory: Inv[];
  myWishes: Inv[];
  myListings: ListingForMatch[];
  myInvById: Map<string, Inv>;
  myWishById: Map<string, Inv>;
  local: boolean;
}): Match | null {
  const partnerInvById = new Map(input.partner.inventory.map((item) => [item.id, item]));
  const partnerWishById = new Map(input.partner.wishes.map((item) => [item.id, item]));
  const myGives = new Map<string, Inv>();
  const theirGives = new Map<string, Inv>();
  const myListingIds: string[] = [];
  const partnerListingIds: string[] = [];
  const myListingIdsByTheirGiveId = new Map<string, string[]>();
  const partnerListingIdsByTheirGiveId = new Map<string, string[]>();

  for (const listing of input.myListings) {
    const hit = evaluateListing(listing, input.myInvById, input.myWishById, input.partner.inventory);
    if (!hit) continue;
    myListingIds.push(listing.id);
    for (const id of hit.haveIds) addInv(myGives, input.myInvById.get(id));
    for (const id of hit.matchedIds) {
      addInv(theirGives, partnerInvById.get(id));
      addMapValue(myListingIdsByTheirGiveId, id, listing.id);
    }
  }

  for (const listing of input.partner.listings) {
    const hit = evaluateListing(listing, partnerInvById, partnerWishById, input.myInventory);
    if (!hit) continue;
    partnerListingIds.push(listing.id);
    for (const id of hit.haveIds) {
      addInv(theirGives, partnerInvById.get(id));
      addMapValue(partnerListingIdsByTheirGiveId, id, listing.id);
    }
    for (const id of hit.matchedIds) addInv(myGives, input.myInvById.get(id));
  }

  const coveredMyIds = new Set(input.myListings.flatMap((listing) => listing.haveIds));
  for (const item of input.myInventory) {
    if (myGives.has(item.id) || coveredMyIds.has(item.id)) continue;
    if (input.partner.wishes.some((wish) => isMatching(item, wish))) {
      myGives.set(item.id, item);
    }
  }

  for (const item of input.partner.inventory) {
    if (theirGives.has(item.id)) continue;
    if (input.myWishes.some((wish) => isMatching(item, wish))) {
      theirGives.set(item.id, item);
    }
  }

  if (myGives.size === 0 && theirGives.size === 0) return null;

  const listingMatchKind =
    myListingIds.length > 0 && partnerListingIds.length > 0
      ? "both"
      : myListingIds.length > 0
        ? "mine_only"
        : partnerListingIds.length > 0
          ? "partner_only"
          : "none";
  const matchType =
    myGives.size > 0 && theirGives.size > 0
      ? listingMatchKind === "none" || listingMatchKind === "both"
        ? "complete"
        : listingMatchKind === "mine_only"
          ? "they_want_you"
          : "you_want_them"
      : myGives.size > 0
        ? "they_want_you"
        : "you_want_them";

  return {
    partner: input.partner.user,
    matchType,
    myGives: Array.from(myGives.values()),
    theirGives: Array.from(theirGives.values()),
    listingMatchKind,
    myListingIds,
    partnerListingIds,
    myListingIdsByTheirGiveId: mapToRecord(myListingIdsByTheirGiveId),
    partnerListingIdsByTheirGiveId: mapToRecord(partnerListingIdsByTheirGiveId),
    local: input.local,
  };
}

function evaluateListing(
  listing: ListingForMatch,
  haveById: Map<string, Inv>,
  wishById: Map<string, Inv>,
  counterpartInventory: Inv[],
) {
  const haveIds =
    listing.haveLogic === "and"
      ? listing.haveIds.filter((id) => haveById.has(id))
      : listing.haveIds.filter((id) => haveById.has(id)).slice(0, 1);
  if (haveIds.length === 0) return null;

  const matchedIds = new Set<string>();
  for (const option of listing.options) {
    if (option.isCashOffer) continue;
    const hitsByWish = option.wishIds.map((wishId) => {
      const wish = wishById.get(wishId);
      if (!wish) return [] as string[];
      return counterpartInventory
        .filter((item) => isMatching(item, wish))
        .map((item) => item.id);
    });
    const optionMatched =
      option.logic === "and"
        ? hitsByWish.length > 0 && hitsByWish.every((ids) => ids.length > 0)
        : hitsByWish.some((ids) => ids.length > 0);
    if (!optionMatched) continue;
    for (const id of hitsByWish.flat()) matchedIds.add(id);
  }

  if (matchedIds.size === 0) return null;
  return { haveIds, matchedIds: Array.from(matchedIds) };
}

function buildSections(
  matches: Match[],
  myWishes: Inv[],
  tagsByInvId: Record<string, string[]>,
  tagLabelsByInvId: Record<string, string[]>,
): ShelfSection[] {
  const listingRows = new Map<string, Candidate[]>();
  const possibleRows = new Map<string, Candidate[]>();
  const seen = new Set<string>();

  for (const match of matches) {
    for (const { item, side } of displayItemsForMatch(match)) {
      const key = `${match.partner.id}:${item.id}`;
      if (seen.has(key)) continue;
      seen.add(key);

      const itemMyListingIds =
        side === "partner" ? match.myListingIdsByTheirGiveId[item.id] ?? [] : [];
      const itemPartnerListingIds =
        side === "partner"
          ? match.partnerListingIdsByTheirGiveId[item.id] ?? []
          : [];
      const priority = priorityForListingIds(
        itemMyListingIds,
        itemPartnerListingIds,
      );
      const tagScore = bestTagScoreForItem(item, myWishes, tagsByInvId);
      const tagLabels = tagLabelsByInvId[item.id] ?? [];
      const candidate: Candidate = {
        id: item.id,
        label: item.title,
        member: (item.characterName ?? item.groupName ?? item.title).slice(0, 1),
        type: item.goodsTypeName ?? "グッズ",
        hue: item.hue,
        photoUrl: item.photoUrl,
        tag: tagLabels[0] ?? undefined,
        tagLabels,
        local: match.local,
        priority,
        tagScore,
        partnerId: match.partner.id,
        partnerHandle: match.partner.handle,
        partnerDisplayName: match.partner.displayName,
        avatarUrl: match.partner.avatarUrl,
        giveIds: match.myGives.map((give) => give.id),
        receiveIds: match.theirGives.map((receive) => receive.id),
        listingIds: [...itemMyListingIds, ...itemPartnerListingIds],
        matchType: match.matchType,
      };
      const rowKey = `${item.characterName ?? item.groupName ?? "その他"}__${item.goodsTypeName ?? "グッズ"}`;
      const target = priority === "wish" ? possibleRows : listingRows;
      const current = target.get(rowKey) ?? [];
      current.push(candidate);
      target.set(rowKey, current);
    }
  }

  return [
    {
      id: "listing",
      title: "マッチしてるよ！",
      rows: mapRows(listingRows),
    },
    {
      id: "possible",
      title: "交換できるかも",
      rows: mapRows(possibleRows),
    },
  ].filter((section) => section.rows.length > 0);
}

function displayItemsForMatch(match: Match): CandidateSource[] {
  if (match.theirGives.length > 0) {
    return match.theirGives.map((item) => ({ item, side: "partner" }));
  }
  return match.myGives.map((item) => ({ item, side: "mine" }));
}

function mapRows(rows: Map<string, Candidate[]>) {
  return Array.from(rows.entries())
    .map(([key, candidates]) => {
      const [character, goodsType] = key.split("__");
      return {
        id: key,
        character,
        goodsType,
        candidates: candidates.sort(compareCandidates),
      };
    })
    .sort((a, b) => {
      const priority = bestPriorityRank(a.candidates) - bestPriorityRank(b.candidates);
      if (priority !== 0) return priority;
      const tagScore = bestTagScore(b.candidates) - bestTagScore(a.candidates);
      if (tagScore !== 0) return tagScore;
      const localCount =
        b.candidates.filter((candidate) => candidate.local).length -
        a.candidates.filter((candidate) => candidate.local).length;
      if (localCount !== 0) return localCount;
      if (a.candidates.length !== b.candidates.length) {
        return b.candidates.length - a.candidates.length;
      }
      return a.character.localeCompare(b.character, "ja");
    });
}

function toInv(row: GoodsRow): Inv | null {
  if (!row.goods_type_id) return null;
  const characterName = pickName(row.character);
  const groupName = pickName(row.group);
  const goodsTypeName = pickName(row.goods_type);
  const label = characterName ?? groupName ?? row.title;
  return {
    id: row.id,
    userId: row.user_id,
    groupId: row.group_id,
    characterId: row.character_id,
    goodsTypeId: row.goods_type_id,
    title: row.title,
    photoUrl: row.photo_urls?.[0] ?? null,
    groupName,
    characterName,
    goodsTypeName,
    hue: normalizeHue(row.hue, label),
  };
}

function toListing(
  row: ListingRow,
  optionsByListing: Map<string, ListingOptionRow[]>,
): ListingForMatch {
  return {
    id: row.id,
    userId: row.user_id,
    haveIds: row.have_ids ?? [],
    haveQtys: row.have_qtys ?? [],
    haveLogic: row.have_logic ?? "and",
    options: (optionsByListing.get(row.id) ?? []).map((option) => ({
      id: option.id,
      position: option.position,
      wishIds: option.wish_ids ?? [],
      wishQtys: option.wish_qtys ?? [],
      logic: option.logic ?? "or",
      isCashOffer: !!option.is_cash_offer,
    })),
  };
}

function buildLocalPartnerSet(input: {
  enabled: boolean;
  currentAW: AWRow | null;
  partnerAWs: AWRow[];
}) {
  const result = new Set<string>();
  if (!input.enabled || !input.currentAW) return result;
  for (const aw of input.partnerAWs) {
    if (awsOverlap(input.currentAW, aw)) result.add(aw.user_id);
  }
  return result;
}

function awsOverlap(myAW: AWRow, theirAW: AWRow) {
  const myStart = new Date(myAW.start_at).getTime();
  const myEnd = new Date(myAW.end_at).getTime();
  const theirStart = new Date(theirAW.start_at).getTime();
  const theirEnd = new Date(theirAW.end_at).getTime();
  if (myEnd < theirStart || theirEnd < myStart) return false;
  if (
    myAW.center_lat == null ||
    myAW.center_lng == null ||
    theirAW.center_lat == null ||
    theirAW.center_lng == null
  ) {
    return true;
  }
  const distance = haversineMeters(
    myAW.center_lat,
    myAW.center_lng,
    theirAW.center_lat,
    theirAW.center_lng,
  );
  return distance <= (myAW.radius_m ?? 500) + (theirAW.radius_m ?? 500);
}

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number) {
  const radius = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);
  return radius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function isMatching(a: Inv, b: Inv) {
  if (a.goodsTypeId !== b.goodsTypeId) return false;
  if (a.characterId && b.characterId) return a.characterId === b.characterId;
  if (!a.groupId || !b.groupId) return false;
  return a.groupId === b.groupId;
}

function addInv(target: Map<string, Inv>, item?: Inv) {
  if (item) target.set(item.id, item);
}

function addMapValue(map: Map<string, string[]>, key: string, value: string) {
  const values = map.get(key) ?? [];
  if (!values.includes(value)) values.push(value);
  map.set(key, values);
}

function mapToRecord(map: Map<string, string[]>) {
  const record: Record<string, string[]> = {};
  for (const [key, value] of map.entries()) record[key] = value;
  return record;
}

function priorityForListingIds(
  myListingIds: string[],
  partnerListingIds: string[],
): CandidatePriority {
  if (myListingIds.length > 0 && partnerListingIds.length > 0) return "both";
  if (myListingIds.length > 0 || partnerListingIds.length > 0) {
    return "oneSide";
  }
  return "wish";
}

function priorityRank(priority: CandidatePriority) {
  if (priority === "both") return 0;
  if (priority === "oneSide") return 1;
  return 2;
}

function compareCandidates(a: Candidate, b: Candidate) {
  const priority = priorityRank(a.priority) - priorityRank(b.priority);
  if (priority !== 0) return priority;
  const tagScore = (b.tagScore ?? 0) - (a.tagScore ?? 0);
  if (tagScore !== 0) return tagScore;
  if (a.local !== b.local) return a.local ? -1 : 1;
  return a.label.localeCompare(b.label, "ja");
}

function bestPriorityRank(candidates: Candidate[]) {
  return candidates.reduce(
    (best, candidate) => Math.min(best, priorityRank(candidate.priority)),
    2,
  );
}

function bestTagScore(candidates: Candidate[]) {
  return candidates.reduce(
    (best, candidate) => Math.max(best, candidate.tagScore ?? 0),
    0,
  );
}

function bestTagScoreForItem(
  item: Inv,
  myWishes: Inv[],
  tagsByInvId: Record<string, string[]>,
) {
  const itemTags = tagsByInvId[item.id] ?? [];
  if (itemTags.length === 0) return 0;
  let best = 0;
  for (const wish of myWishes) {
    if (!isMatching(item, wish)) continue;
    best = Math.max(best, jaccardScore(tagsByInvId[wish.id] ?? [], itemTags));
  }
  return best;
}

function jaccardScore(a: string[], b: string[]) {
  if (a.length === 0 || b.length === 0) return 0;
  const setA = new Set(a);
  const setB = new Set(b);
  let intersect = 0;
  for (const value of setA) {
    if (setB.has(value)) intersect += 1;
  }
  const union = setA.size + setB.size - intersect;
  return union > 0 ? intersect / union : 0;
}

function pickName(value: RelationName) {
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

function groupBy<T>(items: T[], getKey: (item: T) => string) {
  const map = new Map<string, T[]>();
  for (const item of items) {
    const key = getKey(item);
    const current = map.get(key) ?? [];
    current.push(item);
    map.set(key, current);
  }
  return map;
}
