import Link from "next/link";
import { redirect } from "next/navigation";
import {
  createClient,
  createServiceRoleClient,
} from "@/lib/supabase/server";
import { MegrumLogo } from "@/components/auth/MegrumLogo";
import { PrimaryLinkButton } from "@/components/auth/PrimaryButton";
import { GoogleAuthButton } from "@/components/auth/GoogleAuthButton";
import { HomeView } from "@/components/home/HomeView";
import { BottomNav } from "@/components/home/BottomNav";
import {
  awsOverlap,
  computeAllMatches,
  haversineMeters,
  type MatchInv,
  type UserSummary,
} from "@/lib/matching";
import {
  applyListingMarketAvailability,
  buildMarketAvailableQtyByInvId,
  getAgreedReservedQtyByInvId,
  withMarketAvailableQuantity,
} from "@/lib/marketAvailability";

type Props = {
  searchParams: Promise<{
    code?: string;
    error?: string;
    error_code?: string;
    error_description?: string;
    openLocalMode?: string;
    /**
     * iter142: 「全国 view」を一時的に見たい時の URL フラグ
     * - "national" → 現地モード ON でも AW フィルタを適用しない
     * - 未指定 / その他 → 通常通り（現地モード ON なら AW フィルタ）
     * 現地モード自体（DB 上の enabled）は維持される
     */
    view?: string;
  }>;
};

type GoodsRow = {
  id: string;
  user_id: string;
  group_id: string | null;
  character_id: string | null;
  character_request_id: string | null;
  goods_type_id: string | null;
  title: string;
  photo_urls: string[] | null;
  quantity: number;
  exchange_type: "same_kind" | "cross_kind" | "any" | null;
  group: { name: string } | { name: string }[] | null;
  character: { name: string } | { name: string }[] | null;
  goods_type: { name: string } | { name: string }[] | null;
};

type AWRow = {
  id: string;
  user_id: string;
  start_at: string;
  end_at: string;
  radius_m: number;
  center_lat: number | null;
  center_lng: number | null;
};

function pickName(
  v: { name: string } | { name: string }[] | null,
): string | null {
  if (!v) return null;
  return Array.isArray(v) ? v[0]?.name ?? null : v.name;
}

function toMatchInv(r: GoodsRow): MatchInv | null {
  if (!r.goods_type_id) return null;
  return {
    id: r.id,
    userId: r.user_id,
    groupId: r.group_id,
    characterId: r.character_id,
    characterRequestId: r.character_request_id,
    goodsTypeId: r.goods_type_id,
    title: r.title,
    photoUrl: (r.photo_urls && r.photo_urls[0]) ?? null,
    groupName: pickName(r.group),
    characterName: pickName(r.character),
    goodsTypeName: pickName(r.goods_type),
    exchangeType: (r.exchange_type ?? "any") as
      | "same_kind"
      | "cross_kind"
      | "any",
  };
}

export default async function Home({ searchParams }: Props) {
  const params = await searchParams;

  // フォールバック：認証コードが root に飛んできた場合は /auth/callback へ転送
  if (params.code) {
    redirect(`/auth/callback?code=${params.code}`);
  }

  // フォールバック：認証エラーが root に飛んできた場合
  if (params.error) {
    const errorParams = new URLSearchParams({
      error: params.error,
      ...(params.error_code && { error_code: params.error_code }),
      ...(params.error_description && {
        error_description: params.error_description,
      }),
    });
    redirect(`/auth/auth-error?${errorParams.toString()}`);
  }

  const supabase = await createClient();
  const serviceSupabase = createServiceRoleClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // 未ログイン → Welcome 画面
  if (!user) {
    return <WelcomeView />;
  }

  const goodsSelect =
    "id, user_id, group_id, character_id, character_request_id, goods_type_id, title, photo_urls, quantity, exchange_type, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)";

  // ログイン中：マッチング演算に必要なデータを並列取得
  const [
    { data: profile },
    { data: localMode },
    { data: aws },
    { data: carryingItems },
    { data: myInventoryRaw },
    { data: myWishesRaw },
    { data: myListings },
    { data: othersInventoryRaw },
    { data: othersWishesRaw },
    { data: otherUsersRaw },
    { data: othersAWsRawAll },
    { data: othersLocalModeOnRows },
    { data: othersListingsRaw },
  ] = await Promise.all([
    supabase
      .from("users")
      .select("handle, display_name, avatar_url")
      .eq("id", user.id)
      .maybeSingle(),
    supabase
      .from("user_local_mode_settings")
      .select(
        "enabled, aw_id, radius_m, selected_carrying_ids, selected_wish_ids, last_lat, last_lng",
      )
      .eq("user_id", user.id)
      .maybeSingle(),
    supabase
      .from("activity_windows")
      .select(
        "id, venue, event_name, eventless, start_at, end_at, radius_m, center_lat, center_lng",
      )
      .eq("user_id", user.id)
      .eq("status", "enabled")
      .order("start_at", { ascending: true }),
    supabase
      .from("goods_inventory")
      .select(
        "id, title, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .eq("user_id", user.id)
      .eq("kind", "for_trade")
      .eq("status", "active")
      .order("created_at", { ascending: false }),

    // 自分の譲（マッチ計算用）
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .eq("user_id", user.id)
      .eq("kind", "for_trade")
      .eq("status", "active"),
    // 自分の wish（マッチ計算用）
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .eq("user_id", user.id)
      .eq("kind", "wanted")
      .neq("status", "archived"),
    // 自分の active な listings（iter67.4 で「譲 1 + 求 N 選択肢」化）
    supabase
      .from("listings")
      .select(
        "id, have_ids, have_qtys, have_logic, have_group_id, have_goods_type_id",
      )
      .eq("user_id", user.id)
      .eq("status", "active"),

    // 他者の譲
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .neq("user_id", user.id)
      .eq("kind", "for_trade")
      .eq("status", "active")
      .limit(500),
    // 他者の wish
    supabase
      .from("goods_inventory")
      .select(goodsSelect)
      .neq("user_id", user.id)
      .eq("kind", "wanted")
      .neq("status", "archived")
      .limit(500),
    // 他者の users（iter125: avatar_url も取得）
    supabase
      .from("users")
      .select("id, handle, display_name, primary_area, avatar_url")
      .neq("id", user.id)
      .limit(500),
    // 他者の AW（現地マッチ用）
    // iter136: AW は現地モード OFF 時も DB に残るので、
    //   ここで取得後 user_local_mode_settings.enabled でフィルタする必要あり
    supabase
      .from("activity_windows")
      .select(
        "id, user_id, start_at, end_at, radius_m, center_lat, center_lng",
      )
      .neq("user_id", user.id)
      .eq("status", "enabled")
      .limit(500),
    // iter136: 他者の現地モード ON フラグ（user_id 配列）
    // user_local_mode_settings は RLS で本人行のみ参照可。
    // マッチングのサーバー処理では enabled な user_id だけ必要なので、
    // service role で最小列だけ読む（last_lat/lng 等は取得しない）。
    serviceSupabase
      .from("user_local_mode_settings")
      .select("user_id")
      .eq("enabled", true)
      .neq("user_id", user.id),
    // 他者の active な listings（iter67.6 で追加）
    supabase
      .from("listings")
      .select(
        "id, user_id, have_ids, have_qtys, have_logic, have_group_id, have_goods_type_id",
      )
      .neq("user_id", user.id)
      .eq("status", "active")
      .limit(500),
  ]);

  // ─── マッチング演算 ──────────────────────────────────────
  const myInventoryRows = ((myInventoryRaw as GoodsRow[]) ?? []);
  const othersInventoryRows = ((othersInventoryRaw as GoodsRow[]) ?? []);
  const marketInventoryRows = [...myInventoryRows, ...othersInventoryRows];
  const reservedQtyByInvId = await getAgreedReservedQtyByInvId(
    serviceSupabase,
    marketInventoryRows.map((r) => r.id),
  );
  const marketAvailableQtyByInvId = buildMarketAvailableQtyByInvId(
    marketInventoryRows,
    reservedQtyByInvId,
  );
  const availableMyInventoryRows = withMarketAvailableQuantity(
    myInventoryRows,
    marketAvailableQtyByInvId,
  );
  const availableOthersInventoryRows = withMarketAvailableQuantity(
    othersInventoryRows,
    marketAvailableQtyByInvId,
  );

  const myInventory = availableMyInventoryRows
    .map(toMatchInv)
    .filter((x): x is MatchInv => !!x);
  // iter67.8 + iter153: 在庫オーバーチェック用（市場残数を使用）
  const myInventoryQty: Record<string, number> = {};
  for (const r of availableMyInventoryRows) {
    myInventoryQty[r.id] = (r.quantity as number | undefined) ?? 1;
  }

  // iter92: 通知の未読数（ホームヘッダーのベルバッジ用）
  const { count: unreadNotificationCount } = await supabase
    .from("notifications")
    .select("id", { count: "exact", head: true })
    .eq("user_id", user.id)
    .is("read_at", null);
  const myWishes = ((myWishesRaw as GoodsRow[]) ?? [])
    .map(toMatchInv)
    .filter((x): x is MatchInv => !!x);
  // 自分の listings のオプション（求側選択肢）を取得
  const myListingIds = (myListings ?? []).map((l) => l.id as string);
  type OptRow = {
    id: string;
    listing_id: string;
    position: number;
    wish_ids: string[] | null;
    wish_qtys: number[] | null;
    logic: "and" | "or";
    exchange_type: "same_kind" | "cross_kind" | "any";
    is_cash_offer: boolean;
    cash_amount: number | null;
  };
  const myOptionsByListing = new Map<string, OptRow[]>();
  if (myListingIds.length > 0) {
    const { data: optRows } = await supabase
      .from("listing_wish_options")
      .select(
        "id, listing_id, position, wish_ids, wish_qtys, logic, exchange_type, is_cash_offer, cash_amount",
      )
      .in("listing_id", myListingIds)
      .order("position", { ascending: true });
    if (optRows) {
      for (const o of optRows as OptRow[]) {
        const arr = myOptionsByListing.get(o.listing_id) ?? [];
        arr.push(o);
        myOptionsByListing.set(o.listing_id, arr);
      }
    }
  }

  const myListingsForMatch = (myListings ?? [])
    .map((l) => {
      const opts = myOptionsByListing.get(l.id as string) ?? [];
      return {
        id: l.id as string,
        haveIds: (l.have_ids as string[]) ?? [],
        haveQtys: (l.have_qtys as number[]) ?? [],
        haveLogic: (l.have_logic as "and" | "or") ?? "and",
        haveGroupId: (l.have_group_id as string | null) ?? null,
        haveGoodsTypeId: (l.have_goods_type_id as string | null) ?? null,
        options: opts.map((o) => ({
          id: o.id,
          position: o.position,
          wishIds: o.wish_ids ?? [],
          wishQtys: o.wish_qtys ?? [],
          logic: o.logic,
          exchangeType: o.exchange_type,
          isCashOffer: o.is_cash_offer,
          cashAmount: o.cash_amount,
        })),
      };
    })
    .map((l) => applyListingMarketAvailability(l, marketAvailableQtyByInvId))
    .filter((l): l is NonNullable<typeof l> => !!l);

  // 他者 listings の options 取得 + 構造化（iter67.6）
  type OthersListingRow = {
    id: string;
    user_id: string;
    have_ids: string[];
    have_qtys: number[];
    have_logic: "and" | "or";
    have_group_id: string | null;
    have_goods_type_id: string | null;
  };
  const othersListings = (othersListingsRaw ?? []) as OthersListingRow[];
  const othersListingIds = othersListings.map((l) => l.id);
  const othersOptionsByListing = new Map<string, OptRow[]>();
  if (othersListingIds.length > 0) {
    const { data: othersOpts } = await supabase
      .from("listing_wish_options")
      .select(
        "id, listing_id, position, wish_ids, wish_qtys, logic, exchange_type, is_cash_offer, cash_amount",
      )
      .in("listing_id", othersListingIds)
      .order("position", { ascending: true });
    if (othersOpts) {
      for (const o of othersOpts as OptRow[]) {
        const arr = othersOptionsByListing.get(o.listing_id) ?? [];
        arr.push(o);
        othersOptionsByListing.set(o.listing_id, arr);
      }
    }
  }
  const othersListingsByUser = new Map<
    string,
    typeof myListingsForMatch
  >();
  for (const l of othersListings) {
    const opts = othersOptionsByListing.get(l.id) ?? [];
    const entry = {
      id: l.id,
      haveIds: l.have_ids ?? [],
      haveQtys: l.have_qtys ?? [],
      haveLogic: l.have_logic,
      haveGroupId: l.have_group_id,
      haveGoodsTypeId: l.have_goods_type_id,
      options: opts.map((o) => ({
        id: o.id,
        position: o.position,
        wishIds: o.wish_ids ?? [],
        wishQtys: o.wish_qtys ?? [],
        logic: o.logic,
        exchangeType: o.exchange_type,
        isCashOffer: o.is_cash_offer,
        cashAmount: o.cash_amount,
      })),
    };
    const marketEntry = applyListingMarketAvailability(
      entry,
      marketAvailableQtyByInvId,
    );
    if (!marketEntry) continue;
    const arr = othersListingsByUser.get(l.user_id) ?? [];
    arr.push(marketEntry);
    othersListingsByUser.set(l.user_id, arr);
  }

  // パートナー単位にグループ化
  const partnersMap = new Map<
    string,
    {
      user: UserSummary;
      inventory: MatchInv[];
      wishes: MatchInv[];
      listings: typeof myListingsForMatch;
    }
  >();
  for (const u of otherUsersRaw ?? []) {
    partnersMap.set(u.id, {
      user: {
        id: u.id,
        handle: u.handle,
        displayName: u.display_name,
        primaryArea: u.primary_area,
        avatarUrl: (u.avatar_url as string | null) ?? null,
      },
      inventory: [],
      wishes: [],
      listings: othersListingsByUser.get(u.id) ?? [],
    });
  }
  for (const r of availableOthersInventoryRows) {
    const inv = toMatchInv(r);
    if (!inv) continue;
    const p = partnersMap.get(r.user_id);
    if (p) p.inventory.push(inv);
  }
  for (const r of (othersWishesRaw as GoodsRow[]) ?? []) {
    const inv = toMatchInv(r);
    if (!inv) continue;
    const p = partnersMap.get(r.user_id);
    if (p) p.wishes.push(inv);
  }

  let matches = computeAllMatches({
    myInventory,
    myWishes,
    myListings: myListingsForMatch,
    partners: Array.from(partnersMap.values()),
  });

  // iter114: タグ類似度マッチ用に、関係する全 inventory のタグをロード
  //   matchToCard で wish と候補のタグを Jaccard 比較して候補を並び替える
  const allInvIds = new Set<string>();
  for (const inv of myInventory) allInvIds.add(inv.id);
  for (const w of myWishes) allInvIds.add(w.id);
  for (const p of partnersMap.values()) {
    for (const inv of p.inventory) allInvIds.add(inv.id);
    for (const w of p.wishes) allInvIds.add(w.id);
  }
  const tagsByInvId: Record<string, string[]> = {};
  const tagLabelsByInvId: Record<string, string[]> = {};
  if (allInvIds.size > 0) {
    const { data: tagPairs } = await supabase
      .from("goods_inventory_tags")
      .select("inventory_id, tag_id, tag:tags_master(label)")
      .in("inventory_id", Array.from(allInvIds));
    type TagPairRow = {
      inventory_id: string;
      tag_id: string;
      tag: { label: string } | { label: string }[] | null;
    };
    for (const r of (tagPairs as TagPairRow[]) ?? []) {
      const list = tagsByInvId[r.inventory_id] ?? [];
      list.push(r.tag_id);
      tagsByInvId[r.inventory_id] = list;
      const tag = Array.isArray(r.tag) ? r.tag[0] : r.tag;
      if (tag?.label) {
        const labels = tagLabelsByInvId[r.inventory_id] ?? [];
        labels.push(tag.label);
        tagLabelsByInvId[r.inventory_id] = labels;
      }
    }
  }

  // ─── 現地モード時の時空交差フィルタ ──────────────────────
  const isLocal = localMode?.enabled ?? false;
  const currentAW =
    (aws ?? []).find((a) => a.id === localMode?.aw_id) ?? null;

  // iter142: 「全国 view」フラグ（現地モード ON でも一時的に全国一覧を見るため）
  const isNationalView = params.view === "national";

  // iter142: AW の終了時刻が過ぎていたら自動で現地モード OFF
  // Server Component なので Date.now() は request 単位で 1 回だけ評価される（pure 扱い OK）
  // eslint-disable-next-line react-hooks/purity
  const _serverNow = Date.now();
  if (
    isLocal &&
    currentAW &&
    new Date(currentAW.end_at).getTime() < _serverNow
  ) {
    await supabase
      .from("user_local_mode_settings")
      .update({ enabled: false })
      .eq("user_id", user.id);
    redirect("/");
  }

  if (currentAW) {
    // 他者 AW を user_id で集約
    const partnerAWs = new Map<string, AWRow[]>();
    // iter136: 現地モード OFF のユーザーの AW は無視
    const localModeOnUserIds = new Set(
      (othersLocalModeOnRows ?? []).map((r) => r.user_id as string),
    );
    const othersAWsRaw = ((othersAWsRawAll as AWRow[]) ?? []).filter((a) =>
      localModeOnUserIds.has(a.user_id),
    );
    for (const a of othersAWsRaw) {
      const arr = partnerAWs.get(a.user_id) ?? [];
      arr.push(a);
      partnerAWs.set(a.user_id, arr);
    }
    const myAWForOverlap = {
      startAt: currentAW.start_at,
      endAt: currentAW.end_at,
      centerLat: currentAW.center_lat,
      centerLng: currentAW.center_lng,
      radiusM: currentAW.radius_m,
    };
    const localMatchPartnerIds = new Set<string>();
    for (const m of matches) {
      const aws = partnerAWs.get(m.partner.id) ?? [];
      if (aws.some((a) =>
        awsOverlap(myAWForOverlap, {
          startAt: a.start_at,
          endAt: a.end_at,
          centerLat: a.center_lat,
          centerLng: a.center_lng,
          radiusM: a.radius_m,
        }),
      )) {
        localMatchPartnerIds.add(m.partner.id);
      }
    }
    matches = matches.map((m) =>
      localMatchPartnerIds.has(m.partner.id) ? { ...m, localMatch: true } : m,
    );

    // 距離（m）を最短 AW から算出（iter67.6）
    if (
      (localMode?.last_lat != null || currentAW.center_lat != null) &&
      (localMode?.last_lng != null || currentAW.center_lng != null)
    ) {
      const myLat = (localMode?.last_lat ?? currentAW.center_lat) as number;
      const myLng = (localMode?.last_lng ?? currentAW.center_lng) as number;
      matches = matches.map((m) => {
        const aws = partnerAWs.get(m.partner.id) ?? [];
        let minDist = Infinity;
        for (const a of aws) {
          if (a.center_lat == null || a.center_lng == null) continue;
          const d = haversineMeters(myLat, myLng, a.center_lat, a.center_lng);
          if (d < minDist) minDist = d;
        }
        return Number.isFinite(minDist)
          ? { ...m, distanceMeters: minDist }
          : m;
      });
    }
  }

  return (
    <>
      <HomeView
        profile={profile}
        localMode={
          localMode
            ? {
                enabled: localMode.enabled,
                awId: localMode.aw_id,
                radiusM: localMode.radius_m,
                selectedCarryingIds: localMode.selected_carrying_ids ?? [],
                selectedWishIds: localMode.selected_wish_ids ?? [],
                lastLat: localMode.last_lat,
                lastLng: localMode.last_lng,
              }
            : null
        }
        currentAW={
          currentAW
            ? {
                id: currentAW.id,
                venue: currentAW.venue,
                eventName: currentAW.event_name,
                eventless: currentAW.eventless,
                startAt: currentAW.start_at,
                endAt: currentAW.end_at,
                radiusM: currentAW.radius_m ?? 500,
                centerLat: currentAW.center_lat ?? null,
                centerLng: currentAW.center_lng ?? null,
              }
            : null
        }
        carryingItems={(carryingItems ?? []).map((r) => ({
          id: r.id,
          title: r.title,
          groupName: pickName(r.group),
          characterName: pickName(r.character),
          goodsTypeName: pickName(r.goods_type),
          photoUrl: null,
        }))}
        autoOpenLocalSheet={params.openLocalMode === "1"}
        matches={matches}
        myInventory={myInventory}
        myWishes={myWishes}
        partnersInventory={Array.from(partnersMap.values()).flatMap(
          (p) => p.inventory,
        )}
        partnersWishes={Array.from(partnersMap.values()).flatMap(
          (p) => p.wishes,
        )}
        myInventoryQty={myInventoryQty}
        tagsByInvId={tagsByInvId}
        tagLabelsByInvId={tagLabelsByInvId}
        unreadNotificationCount={unreadNotificationCount ?? 0}
        isNationalView={isNationalView}
      />
      <BottomNav />
    </>
  );
}

// ──────────────────────────────────────────────
// Welcome 画面（未ログイン時）
// ──────────────────────────────────────────────
function WelcomeView() {
  return (
    <main className="flex flex-1 flex-col bg-[linear-gradient(180deg,#a695d822_0%,#a8d4e614_45%,#ffffff_100%)] px-7 pb-8 pt-20">
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col">
        {/* 中央：ロゴ + タイトル + キャッチコピー */}
        <div className="flex flex-1 flex-col items-center justify-center text-center">
          <MegrumLogo size={88} />
          <h1 className="mt-6 text-[34px] font-extrabold tracking-wide text-gray-900">
            Megrum
          </h1>
          <p className="mt-2.5 max-w-[280px] text-[13px] leading-relaxed text-gray-500">
            グッズ交換を、
            <br />
            現地で、もっと簡単に。
          </p>
        </div>

        {/* 下部：CTA */}
        <div>
          <PrimaryLinkButton href="/signup">
            メールアドレスで新規登録
          </PrimaryLinkButton>
          <div className="mt-2.5">
            <GoogleAuthButton label="Googleで新規登録" />
          </div>
          <div className="mt-5 text-center text-[13px] text-gray-500">
            すでにアカウントをお持ちの方は{" "}
            <Link
              href="/login"
              className="font-bold text-purple-600 hover:text-purple-700"
            >
              ログイン
            </Link>
          </div>
        </div>
      </div>
    </main>
  );
}
