import { notFound, redirect } from "next/navigation";
import {
  createClient,
  createServiceRoleClient,
} from "@/lib/supabase/server";
import {
  applyListingMarketAvailability,
  buildMarketAvailableQtyByInvId,
  getAgreedReservedQtyByInvId,
  withMarketAvailableQuantity,
} from "@/lib/marketAvailability";
import { ProposeFlow, type ProposeInv } from "./ProposeFlow";

export const metadata = {
  title: "打診 — Megrum",
};

type GoodsRow = {
  id: string;
  user_id: string;
  group_id: string | null;
  character_id: string | null;
  goods_type_id: string | null;
  title: string;
  photo_urls: string[] | null;
  quantity: number;
  group: { name: string } | { name: string }[] | null;
  character: { name: string } | { name: string }[] | null;
  goods_type: { name: string } | { name: string }[] | null;
};

type MeetupCandidatePayload = {
  startAt: string;
  endAt: string;
  placeName: string;
  lat: number;
  lng: number;
  mode: "today" | "scheduled";
};

function pickName(
  v: { name: string } | { name: string }[] | null,
): string | null {
  if (!v) return null;
  return Array.isArray(v) ? v[0]?.name ?? null : v.name;
}

function toInv(r: GoodsRow): ProposeInv | null {
  if (!r.goods_type_id) return null;
  return {
    id: r.id,
    title: r.title,
    quantity: r.quantity,
    photoUrl: (r.photo_urls && r.photo_urls[0]) ?? null,
    groupId: r.group_id,
    characterId: r.character_id,
    goodsTypeId: r.goods_type_id,
    groupName: pickName(r.group),
    characterName: pickName(r.character),
    goodsTypeName: pickName(r.goods_type),
  };
}

function parseMeetupCandidates(raw: unknown): MeetupCandidatePayload[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .slice(0, 3)
    .map((candidate): MeetupCandidatePayload | null => {
      if (!candidate || typeof candidate !== "object") return null;
      const c = candidate as Record<string, unknown>;
      if (
        typeof c.startAt !== "string" ||
        typeof c.endAt !== "string" ||
        typeof c.placeName !== "string" ||
        typeof c.lat !== "number" ||
        typeof c.lng !== "number"
      ) {
        return null;
      }
      return {
        startAt: c.startAt,
        endAt: c.endAt,
        placeName: c.placeName,
        lat: c.lat,
        lng: c.lng,
        mode: c.mode === "today" ? "today" : "scheduled",
      };
    })
    .filter((candidate): candidate is MeetupCandidatePayload => !!candidate);
}

function isMeetupCandidatesSchemaCacheError(error: {
  code?: string;
  message?: string;
} | null) {
  const message = error?.message ?? "";
  return (
    error?.code === "PGRST204" ||
    (message.includes("meetup_candidates") &&
      message.includes("schema cache"))
  );
}

type Props = {
  params: Promise<{ partnerId: string }>;
  searchParams: Promise<{
    matchType?: string;
    /** iter67.7: 関係図モーダルから打診開始した時の listing id */
    listing?: string;
    /** iter67.7: その listing の選択肢 position（1〜5） */
    option?: string;
    /** iter67.8: 複数選択肢の position をカンマ区切りで指定（"1,2,3" など） */
    options?: string;
    /**
     * iter108: 関係図ツリー型から候補レベル選択で渡される
     * inventory_id をカンマ区切りで指定（"uuid1,uuid2,uuid3" など）
     */
    candidates?: string;
    /**
     * iter109: 複数 listing 跨ぎの aggregated 打診
     * gives = 私が出す inv_id（自分側）、receives = 私が受け取る inv_id（相手側）。
     * いずれもカンマ区切り。listings は参照する listing_id（任意・トレース用）。
     */
    gives?: string;
    receives?: string;
    listings?: string;
    /** iter70-C: 再打診時の元 proposal id */
    proposalId?: string;
    revise?: string;
    /** iter71-E: カレンダー予定からの再打診で時間帯・場所をプリセット */
    meetupStart?: string;
    meetupEnd?: string;
    meetupPlace?: string;
    /** 関係図経由など、提示物選択の初期タブ指定 */
    tab?: string;
  }>;
};

export default async function ProposePage({ params, searchParams }: Props) {
  const { partnerId } = await params;
  const {
    matchType: matchTypeRaw,
    listing: listingIdRaw,
    option: optionRaw,
    options: optionsRaw,
    candidates: candidatesRaw,
    gives: givesRaw,
    receives: receivesRaw,
    listings: listingsRaw,
    proposalId: reviseProposalIdRaw,
    revise: reviseFlagRaw,
    meetupStart: meetupStartOverride,
    meetupEnd: meetupEndOverride,
    meetupPlace: meetupPlaceOverride,
    tab: initialTabRaw,
  } = await searchParams;
  const reviseFromProposalId =
    reviseFlagRaw === "1" && reviseProposalIdRaw ? reviseProposalIdRaw : null;

  const supabase = await createClient();
  const serviceSupabase = createServiceRoleClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  if (user.id === partnerId) redirect("/");

  const goodsSelect =
    "id, user_id, group_id, character_id, goods_type_id, title, photo_urls, quantity, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)";

  const [
    { data: partner },
    { data: myInvRaw },
    { data: theirInvRaw },
    { data: myWishesRaw },
    { data: theirWishesRaw },
    { data: partnerLocalMode },
  ] = await Promise.all([
    supabase
      .from("users")
      .select("id, handle, display_name, primary_area")
      .eq("id", partnerId)
      .maybeSingle(),
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .eq("user_id", user.id)
      .eq("kind", "for_trade")
      .eq("status", "active"),
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .eq("user_id", partnerId)
      .eq("kind", "for_trade")
      .eq("status", "active"),
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .eq("user_id", user.id)
      .eq("kind", "wanted")
      .neq("status", "archived"),
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .eq("user_id", partnerId)
      .eq("kind", "wanted")
      .neq("status", "archived"),
    // 相手の現地モード設定（enabled & aw_id）
    supabase
      .from("user_local_mode_settings")
      .select("enabled, aw_id, last_lat, last_lng")
      .eq("user_id", partnerId)
      .maybeSingle(),
  ]);

  if (!partner) notFound();

  // 相手の現地モード AW（venue/座標/時間帯）を取得
  let partnerAW: {
    venue: string;
    centerLat: number | null;
    centerLng: number | null;
    startAt: string;
    endAt: string;
  } | null = null;
  if (partnerLocalMode?.enabled && partnerLocalMode.aw_id) {
    const { data: aw } = await supabase
      .from("activity_windows")
      .select("venue, center_lat, center_lng, start_at, end_at")
      .eq("id", partnerLocalMode.aw_id)
      .maybeSingle();
    if (aw) {
      partnerAW = {
        venue: aw.venue,
        centerLat: aw.center_lat,
        centerLng: aw.center_lng,
        startAt: aw.start_at,
        endAt: aw.end_at,
      };
    }
  }

  const myInvRows = ((myInvRaw as GoodsRow[]) ?? []);
  const theirInvRows = ((theirInvRaw as GoodsRow[]) ?? []);
  const marketRows = [...myInvRows, ...theirInvRows];
  const reservedQtyByInvId = await getAgreedReservedQtyByInvId(
    serviceSupabase,
    marketRows.map((r) => r.id),
    reviseFromProposalId ?? undefined,
  );
  const marketAvailableQtyByInvId = buildMarketAvailableQtyByInvId(
    marketRows,
    reservedQtyByInvId,
  );

  const myInv = withMarketAvailableQuantity(
    myInvRows,
    marketAvailableQtyByInvId,
  )
    .map(toInv)
    .filter((x): x is ProposeInv => !!x);
  const theirInv = withMarketAvailableQuantity(
    theirInvRows,
    marketAvailableQtyByInvId,
  )
    .map(toInv)
    .filter((x): x is ProposeInv => !!x);
  const myWishes = ((myWishesRaw as GoodsRow[]) ?? [])
    .map(toInv)
    .filter((x): x is ProposeInv => !!x);
  const theirWishes = ((theirWishesRaw as GoodsRow[]) ?? [])
    .map(toInv)
    .filter((x): x is ProposeInv => !!x);

  // wish 一致 pre-check 用：相手の wish にヒットする自分の譲、自分の wish にヒットする相手の譲
  function isHit(my: ProposeInv, theirs: ProposeInv): boolean {
    if (my.goodsTypeId !== theirs.goodsTypeId) return false;
    if (my.characterId && theirs.characterId)
      return my.characterId === theirs.characterId;
    if (!my.groupId || !theirs.groupId) return false;
    return my.groupId === theirs.groupId;
  }
  const myInvWithFlag = myInv.map((m) => ({
    ...m,
    wishMatch: theirWishes.some((w) => isHit(m, w)),
  }));
  const theirInvWithFlag = theirInv.map((t) => ({
    ...t,
    wishMatch: myWishes.some((w) => isHit(t, w)),
  }));

  const matchType: "perfect" | "forward" | "backward" =
    matchTypeRaw === "they_want_you"
      ? "forward"
      : matchTypeRaw === "you_want_them"
        ? "backward"
        : matchTypeRaw === "complete" || matchTypeRaw === "perfect"
          ? "perfect"
          : "perfect";
  const initialTab: "mine" | "theirs" | "meetup" =
    initialTabRaw === "theirs" || initialTabRaw === "meetup"
      ? initialTabRaw
      : "mine";

  /* ─ iter67.7：listing / option 経由打診の初期値プリフィル ─ */
  type Initial = {
    senderHaveIds: string[];
    senderHaveQtys: number[];
    receiverHaveIds: string[];
    receiverHaveQtys: number[];
    cashOffer?: { amount: number };
    listingId?: string;
    /** iter70-C: 再打診の元 proposal id（送信成功後にこの旧 proposal を cancel する） */
    reviseFromProposalId?: string;
    meetupStartAt?: string;
    meetupEndAt?: string;
    meetupPlaceName?: string;
    meetupLat?: number;
    meetupLng?: number;
    meetupCandidates?: MeetupCandidatePayload[];
    message?: string;
  } | null;
  let initial: Initial = null;

  /* ─ iter70-C：再打診プリフィル ─ 既存 proposal の値で initial を埋める */
  if (reviseFromProposalId) {
    const prevProposalSelectWithCandidates = `id, sender_id, receiver_id, status,
         sender_have_ids, sender_have_qtys, receiver_have_ids, receiver_have_qtys,
         cash_offer, cash_amount, listing_id,
         meetup_start_at, meetup_end_at, meetup_place_name, meetup_lat, meetup_lng,
         meetup_candidates,
         message`;
    const prevProposalSelectFallback = `id, sender_id, receiver_id, status,
         sender_have_ids, sender_have_qtys, receiver_have_ids, receiver_have_qtys,
         cash_offer, cash_amount, listing_id,
         meetup_start_at, meetup_end_at, meetup_place_name, meetup_lat, meetup_lng,
         message`;
    let { data: prevRow, error: prevRowError } = await supabase
      .from("proposals")
      .select(prevProposalSelectWithCandidates)
      .eq("id", reviseFromProposalId)
      .maybeSingle();
    if (isMeetupCandidatesSchemaCacheError(prevRowError)) {
      const retry = await supabase
        .from("proposals")
        .select(prevProposalSelectFallback)
        .eq("id", reviseFromProposalId)
        .maybeSingle();
      prevRow = retry.data
        ? { ...retry.data, meetup_candidates: [] }
        : retry.data;
      prevRowError = retry.error;
    }
    if (prevRow) {
      const isMePrevSender = prevRow.sender_id === user.id;
      // 視点を「自分が送信者」基準に揃える
      const senderHaveIds = isMePrevSender
        ? (prevRow.sender_have_ids as string[]) ?? []
        : (prevRow.receiver_have_ids as string[]) ?? [];
      const senderHaveQtys = isMePrevSender
        ? (prevRow.sender_have_qtys as number[]) ?? []
        : (prevRow.receiver_have_qtys as number[]) ?? [];
      const receiverHaveIds = isMePrevSender
        ? (prevRow.receiver_have_ids as string[]) ?? []
        : (prevRow.sender_have_ids as string[]) ?? [];
      const receiverHaveQtys = isMePrevSender
        ? (prevRow.receiver_have_qtys as number[]) ?? []
        : (prevRow.sender_have_qtys as number[]) ?? [];
      const hasMeetupOverride =
        !!meetupStartOverride || !!meetupEndOverride || !!meetupPlaceOverride;
      initial = {
        senderHaveIds,
        senderHaveQtys,
        receiverHaveIds,
        receiverHaveQtys,
        cashOffer: prevRow.cash_offer
          ? { amount: prevRow.cash_amount as number }
          : undefined,
        listingId: (prevRow.listing_id as string | null) ?? undefined,
        reviseFromProposalId,
        // iter71-E: クエリ override 優先（カレンダー予定タップ由来）
        meetupStartAt:
          meetupStartOverride ??
          (prevRow.meetup_start_at as string | undefined),
        meetupEndAt:
          meetupEndOverride ?? (prevRow.meetup_end_at as string | undefined),
        meetupPlaceName:
          meetupPlaceOverride ??
          (prevRow.meetup_place_name as string | null) ??
          undefined,
        meetupLat: (prevRow.meetup_lat as number | null) ?? undefined,
        meetupLng: (prevRow.meetup_lng as number | null) ?? undefined,
        meetupCandidates: hasMeetupOverride
          ? undefined
          : parseMeetupCandidates(
              "meetup_candidates" in prevRow
                ? prevRow.meetup_candidates
                : undefined,
            ),
        message: (prevRow.message as string | null) ?? undefined,
      };
    }
  }

  /**
   * iter67.8: 単一 (option=N) と 複数 (options=1,2,3) の両方に対応。
   * 単一の場合は options に変換して同じ処理を通す。
   */
  const positions: number[] = [];
  if (optionsRaw) {
    for (const p of optionsRaw.split(",").map((s) => parseInt(s.trim(), 10))) {
      if (Number.isFinite(p) && p >= 1 && p <= 5 && !positions.includes(p)) {
        positions.push(p);
      }
    }
  } else if (optionRaw) {
    const p = parseInt(optionRaw, 10);
    if (Number.isFinite(p) && p >= 1 && p <= 5) positions.push(p);
  }

  /* ─ iter109: gives / receives（複数 listing 跨ぎ aggregated）プリフィル ─
     関係図ツリー型から両 listing の選択を 1 つに集約して渡される。
     listing 単位の候補（candidates）より先に評価。 */
  if (givesRaw || receivesRaw) {
    const isUuid = (s: string) => /^[0-9a-f-]+$/i.test(s) && s.length >= 30;
    const giveIds = (givesRaw ?? "")
      .split(",")
      .map((s) => s.trim())
      .filter(isUuid);
    const recvIds = (receivesRaw ?? "")
      .split(",")
      .map((s) => s.trim())
      .filter(isUuid);

    // 所有チェック：gives は myInv、receives は theirInv に存在することを確認
    const validGives = giveIds.filter((id) =>
      myInvWithFlag.some((m) => m.id === id),
    );
    const validRecvs = recvIds.filter((id) =>
      theirInvWithFlag.some((t) => t.id === id),
    );

    if (validGives.length > 0 || validRecvs.length > 0) {
      // listings query 参照（任意。最初の 1 件を listing_id に紐付け、
      // 複数なら null = 「特定 listing 紐付けなし」として打診を作成）
      const listingIds = (listingsRaw ?? "")
        .split(",")
        .map((s) => s.trim())
        .filter(isUuid);

      initial = {
        senderHaveIds: validGives,
        senderHaveQtys: validGives.map(() => 1),
        receiverHaveIds: validRecvs,
        receiverHaveQtys: validRecvs.map(() => 1),
        listingId: listingIds.length === 1 ? listingIds[0] : undefined,
      };
    }
  }

  /* ─ iter108: 候補（candidates）レベルプリフィル ─
     関係図ツリー型から「特定の inv 候補を選んで打診」する場合、
     listing + candidates=invid1,invid2 で渡される。option ベースより優先。 */
  if (!initial && listingIdRaw && candidatesRaw) {
    const candidateIds = candidatesRaw
      .split(",")
      .map((s) => s.trim())
      .filter((s) => /^[0-9a-f-]+$/i.test(s));

    if (candidateIds.length > 0) {
      const { data: listingRow } = await supabase
        .from("listings")
        .select("id, user_id, have_ids, have_qtys, have_logic, status")
        .eq("id", listingIdRaw)
        .maybeSingle();

      if (listingRow) {
        const isMyListing = listingRow.user_id === user.id;
        const isPartnerListing = listingRow.user_id === partnerId;

        if (isMyListing || isPartnerListing) {
          const marketListing = applyListingMarketAvailability(
            {
              haveIds: (listingRow.have_ids as string[]) ?? [],
              haveQtys: (listingRow.have_qtys as number[]) ?? [],
              haveLogic: (listingRow.have_logic as "and" | "or") ?? "and",
            },
            marketAvailableQtyByInvId,
          );
          if (marketListing) {
            const { haveIds, haveQtys } = marketListing;

            // 候補は「相手側の inv」を期待
            //   isMyListing → 候補は partner の inv（receiver_have に入る）
            //   partner listing → 候補は my の inv（sender_have に入る）
            const candidatePool: ProposeInv[] = isMyListing
              ? theirInvWithFlag
              : myInvWithFlag;
            const validCandidates = candidateIds.filter((cid) =>
              candidatePool.some((p) => p.id === cid),
            );

            if (validCandidates.length > 0) {
              // qty は candidate あたり 1（数量調整は ProposeFlow 側で）
              const candQtys = validCandidates.map(() => 1);

              if (isMyListing) {
                initial = {
                  senderHaveIds: haveIds,
                  senderHaveQtys: haveQtys,
                  receiverHaveIds: validCandidates,
                  receiverHaveQtys: candQtys,
                  listingId: listingRow.id as string,
                };
              } else {
                initial = {
                  senderHaveIds: validCandidates,
                  senderHaveQtys: candQtys,
                  receiverHaveIds: haveIds,
                  receiverHaveQtys: haveQtys,
                  listingId: listingRow.id as string,
                };
              }
            }
          }
        }
      }
    }
  }

  if (!initial && listingIdRaw && positions.length > 0) {
    const [{ data: listingRow }, { data: optionRows }] = await Promise.all([
      supabase
        .from("listings")
        .select("id, user_id, have_ids, have_qtys, have_logic, status")
        .eq("id", listingIdRaw)
        .maybeSingle(),
      supabase
        .from("listing_wish_options")
        .select(
          "id, listing_id, position, wish_ids, wish_qtys, is_cash_offer, cash_amount",
        )
        .eq("listing_id", listingIdRaw)
        .in("position", positions)
        .order("position", { ascending: true }),
    ]);

    if (listingRow && optionRows && optionRows.length > 0) {
      const isMyListing = listingRow.user_id === user.id;
      const isPartnerListing = listingRow.user_id === partnerId;

      if (isMyListing || isPartnerListing) {
        const marketListing = applyListingMarketAvailability(
          {
            haveIds: (listingRow.have_ids as string[]) ?? [],
            haveQtys: (listingRow.have_qtys as number[]) ?? [],
            haveLogic: (listingRow.have_logic as "and" | "or") ?? "and",
          },
          marketAvailableQtyByInvId,
        );
        if (marketListing) {
          const { haveIds, haveQtys } = marketListing;
          const N = optionRows.length;
          const cashOpt = optionRows.find(
            (o) => o.is_cash_offer,
          ) as { cash_amount: number } | undefined;

          // 集計用 Map（itemId → qty）
          const senderAgg = new Map<string, number>();
          const receiverAgg = new Map<string, number>();

          if (isMyListing) {
            // 私の listing：私が出す = haveIds × N、私が受け取る = 各 option の wishes に対応する相手 inv
            for (const id of haveIds) {
              const i = haveIds.indexOf(id);
              const baseQty = haveQtys[i] ?? 1;
              senderAgg.set(id, (senderAgg.get(id) ?? 0) + baseQty * N);
            }
            for (const opt of optionRows) {
              if (opt.is_cash_offer) continue;
              const wishIds = (opt.wish_ids as string[]) ?? [];
              const wishQtys = (opt.wish_qtys as number[]) ?? [];
              for (let i = 0; i < wishIds.length; i++) {
                const myWish = myWishes.find((w) => w.id === wishIds[i]);
                if (!myWish) continue;
                const partnerHits = theirInvWithFlag.filter((t) => {
                  if (t.goodsTypeId !== myWish.goodsTypeId) return false;
                  if (myWish.characterId && t.characterId)
                    return myWish.characterId === t.characterId;
                  return (
                    !!myWish.groupId &&
                    !!t.groupId &&
                    myWish.groupId === t.groupId
                  );
                });
                for (const h of partnerHits) {
                  receiverAgg.set(
                    h.id,
                    (receiverAgg.get(h.id) ?? 0) + (wishQtys[i] ?? 1),
                  );
                }
              }
            }
          } else {
            // 相手の listing：私が受け取る = haveIds × N、私が出す = 各 option の wishes に対応する私の inv
            for (const id of haveIds) {
              const i = haveIds.indexOf(id);
              const baseQty = haveQtys[i] ?? 1;
              receiverAgg.set(id, (receiverAgg.get(id) ?? 0) + baseQty * N);
            }
            for (const opt of optionRows) {
              if (opt.is_cash_offer) continue;
              const wishIds = (opt.wish_ids as string[]) ?? [];
              const wishQtys = (opt.wish_qtys as number[]) ?? [];
              for (let i = 0; i < wishIds.length; i++) {
                const theirWish = theirWishes.find((w) => w.id === wishIds[i]);
                if (!theirWish) continue;
                const myHits = myInvWithFlag.filter((m) => {
                  if (m.goodsTypeId !== theirWish.goodsTypeId) return false;
                  if (theirWish.characterId && m.characterId)
                    return theirWish.characterId === m.characterId;
                  return (
                    !!theirWish.groupId &&
                    !!m.groupId &&
                    theirWish.groupId === m.groupId
                  );
                });
                for (const h of myHits) {
                  senderAgg.set(
                    h.id,
                    (senderAgg.get(h.id) ?? 0) + (wishQtys[i] ?? 1),
                  );
                }
              }
            }
          }

          const senderHaveIds = Array.from(senderAgg.keys());
          const senderHaveQtys = senderHaveIds.map((id) => senderAgg.get(id)!);
          const receiverHaveIds = Array.from(receiverAgg.keys());
          const receiverHaveQtys = receiverHaveIds.map(
            (id) => receiverAgg.get(id)!,
          );

          if (cashOpt && optionRows.length === 1) {
            // 唯一の選択肢が定価交換 → 通常の cash 打診
            if (isMyListing) {
              initial = {
                senderHaveIds: haveIds,
                senderHaveQtys: haveQtys,
                receiverHaveIds: [],
                receiverHaveQtys: [],
                cashOffer: { amount: cashOpt.cash_amount },
                listingId: listingRow.id,
              };
            } else {
              initial = {
                senderHaveIds: [],
                senderHaveQtys: [],
                receiverHaveIds: haveIds,
                receiverHaveQtys: haveQtys,
                cashOffer: { amount: cashOpt.cash_amount },
                listingId: listingRow.id,
              };
            }
          } else {
            // 通常 or cash 含む組合せ
            initial = {
              senderHaveIds,
              senderHaveQtys,
              receiverHaveIds,
              receiverHaveQtys,
              cashOffer: cashOpt
                ? { amount: cashOpt.cash_amount }
                : undefined,
              listingId: listingRow.id,
            };
          }
        }
      }
    }
  }

  return (
    <ProposeFlow
      partner={{
        id: partner.id,
        handle: partner.handle,
        displayName: partner.display_name,
        primaryArea: partner.primary_area,
        localModeEnabled: !!partnerLocalMode?.enabled,
        localModeAW: partnerAW,
      }}
      myInv={myInvWithFlag}
      theirInv={theirInvWithFlag}
      matchType={matchType}
      initial={initial ?? undefined}
      initialTab={initialTab}
    />
  );
}
