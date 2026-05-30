import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { isUuid, participantOrFilter } from "@/lib/supabaseFilters";
import { UserProfileView, type UserProfileData } from "./UserProfileView";
import type {
  ListingItem,
  ListingHaveItem,
  ListingOption,
  ListingWishItem,
} from "@/app/listings/ListingsView";

export const metadata = {
  title: "ユーザーのプロフィール — Megrum",
};

function pickOne<T>(v: T | T[] | null): T | null {
  if (!v) return null;
  return Array.isArray(v) ? (v[0] ?? null) : v;
}

export default async function UserPublicPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  if (!isUuid(id)) notFound();
  const supabase = await createClient();
  const {
    data: { user: me },
  } = await supabase.auth.getUser();
  if (!me) redirect("/login");
  // 自分のプロフは /profile へ
  if (me.id === id) redirect("/profile");

  const { data: user } = await supabase
    .from("users")
    .select("id, handle, display_name, avatar_url, primary_area, account_status")
    .eq("id", id)
    .maybeSingle();
  if (!user) notFound();
  if (
    user.account_status === "deleted" ||
    user.account_status === "suspended"
  ) {
    notFound();
  }

  // 評価サマリ（コメントは別画面へ移行: /users/[id]/evaluations）
  const { data: evals } = await supabase
    .from("user_evaluations")
    .select("stars")
    .eq("ratee_id", id);
  const stars = (evals ?? []).map((e) => e.stars as number);
  const ratingAvg =
    stars.length > 0 ? stars.reduce((a, b) => a + b, 0) / stars.length : null;
  const ratingCount = stars.length;

  // 取引完了数
  const { count: completedCount } = await supabase
    .from("proposals")
    .select("id", { count: "exact", head: true })
    .or(participantOrFilter("sender_id", "receiver_id", id))
    .eq("status", "completed");

  // iter97: 譲るグッズ一覧
  const { data: invRows } = await supabase
    .from("goods_inventory")
    .select(
      "id, title, quantity, hue, photo_urls, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
    )
    .eq("user_id", id)
    .eq("kind", "for_trade")
    .eq("status", "active")
    .order("created_at", { ascending: false });

  type InvRow = {
    id: string;
    title: string;
    quantity: number;
    hue: number | null;
    photo_urls: string[] | null;
    group: { name: string } | { name: string }[] | null;
    character: { name: string } | { name: string }[] | null;
    goods_type: { name: string } | { name: string }[] | null;
  };

  function nameToHue(name: string): number {
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = (hash << 5) - hash + name.charCodeAt(i);
      hash |= 0;
    }
    return Math.abs(hash) % 360;
  }

  const inventoryItems = ((invRows as InvRow[]) ?? []).map((r) => {
    const grp = pickOne(r.group);
    const ch = pickOne(r.character);
    const gt = pickOne(r.goods_type);
    const memberName = ch?.name ?? grp?.name ?? "?";
    return {
      id: r.id,
      memberName,
      goodsType: gt?.name ?? "?",
      qty: r.quantity,
      hue: r.hue ?? nameToHue(memberName),
      photoUrl: (r.photo_urls && r.photo_urls[0]) ?? null,
    };
  });

  // iter146: 公開中の listings を ListingsView と同じスタイルで表示するため
  //         自分の listings ページと同等のフル情報を取得する
  type ListingRow = {
    id: string;
    have_ids: string[] | null;
    have_qtys: number[] | null;
    have_logic: "and" | "or";
    have_group_id: string | null;
    have_goods_type_id: string | null;
    status: "active" | "paused" | "matched" | "closed";
    note: string | null;
    created_at: string;
  };
  type OptionRow = {
    id: string;
    listing_id: string;
    position: number;
    wish_ids: string[] | null;
    wish_qtys: number[] | null;
    logic: "and" | "or";
    exchange_type: "same_kind" | "cross_kind" | "any";
    is_cash_offer: boolean;
    cash_amount: number | null;
    wish_group_id: string | null;
    wish_goods_type_id: string | null;
  };
  type FullInvRow = {
    id: string;
    title: string;
    photo_urls: string[] | null;
    group: { name: string } | { name: string }[] | null;
    character: { name: string } | { name: string }[] | null;
    goods_type: { name: string } | { name: string }[] | null;
  };

  const { data: listingRowsRaw } = await supabase
    .from("listings")
    .select(
      "id, have_ids, have_qtys, have_logic, have_group_id, have_goods_type_id, status, note, created_at",
    )
    .eq("user_id", id)
    .eq("status", "active")
    .order("created_at", { ascending: false });

  const listingRows = (listingRowsRaw as ListingRow[]) ?? [];
  const listingIds = listingRows.map((r) => r.id);

  const optsByListing = new Map<string, OptionRow[]>();
  if (listingIds.length > 0) {
    const { data: optRows } = await supabase
      .from("listing_wish_options")
      .select(
        "id, listing_id, position, wish_ids, wish_qtys, logic, exchange_type, is_cash_offer, cash_amount, wish_group_id, wish_goods_type_id",
      )
      .in("listing_id", listingIds)
      .order("position", { ascending: true });
    if (optRows) {
      for (const o of optRows as OptionRow[]) {
        const arr = optsByListing.get(o.listing_id) ?? [];
        arr.push(o);
        optsByListing.set(o.listing_id, arr);
      }
    }
  }

  const allInvIds = new Set<string>();
  for (const r of listingRows) for (const id of r.have_ids ?? []) allInvIds.add(id);
  for (const opts of optsByListing.values())
    for (const o of opts) for (const id of o.wish_ids ?? []) allInvIds.add(id);

  let invById = new Map<string, FullInvRow>();
  if (allInvIds.size > 0) {
    const { data: invR } = await supabase
      .from("goods_inventory")
      .select(
        "id, title, photo_urls, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .in("id", Array.from(allInvIds));
    if (invR) {
      invById = new Map((invR as FullInvRow[]).map((r) => [r.id, r]));
    }
  }

  const allGroupIds = new Set<string>();
  const allGoodsTypeIds = new Set<string>();
  for (const r of listingRows) {
    if (r.have_group_id) allGroupIds.add(r.have_group_id);
    if (r.have_goods_type_id) allGoodsTypeIds.add(r.have_goods_type_id);
  }
  for (const opts of optsByListing.values()) {
    for (const o of opts) {
      if (o.wish_group_id) allGroupIds.add(o.wish_group_id);
      if (o.wish_goods_type_id) allGoodsTypeIds.add(o.wish_goods_type_id);
    }
  }
  const groupNameById = new Map<string, string>();
  const goodsTypeNameById = new Map<string, string>();
  if (allGroupIds.size > 0) {
    const { data } = await supabase
      .from("groups_master")
      .select("id, name")
      .in("id", Array.from(allGroupIds));
    if (data) for (const g of data) groupNameById.set(g.id as string, g.name as string);
  }
  if (allGoodsTypeIds.size > 0) {
    const { data } = await supabase
      .from("goods_types_master")
      .select("id, name")
      .in("id", Array.from(allGoodsTypeIds));
    if (data)
      for (const g of data) goodsTypeNameById.set(g.id as string, g.name as string);
  }

  function toHave(id: string, qty: number): ListingHaveItem | null {
    const r = invById.get(id);
    if (!r) return null;
    return {
      id: r.id,
      title: r.title,
      qty,
      photoUrl: (r.photo_urls && r.photo_urls[0]) ?? null,
      groupName: pickOne(r.group)?.name ?? null,
      characterName: pickOne(r.character)?.name ?? null,
      goodsTypeName: pickOne(r.goods_type)?.name ?? null,
    };
  }
  function toWishLi(id: string, qty: number): ListingWishItem | null {
    const r = invById.get(id);
    if (!r) return null;
    return {
      id: r.id,
      title: r.title,
      qty,
      photoUrl: (r.photo_urls && r.photo_urls[0]) ?? null,
      groupName: pickOne(r.group)?.name ?? null,
      characterName: pickOne(r.character)?.name ?? null,
      goodsTypeName: pickOne(r.goods_type)?.name ?? null,
    };
  }

  const listingItems: ListingItem[] = listingRows.map((r) => {
    const haves = (r.have_ids ?? [])
      .map((id, i) => toHave(id, (r.have_qtys ?? [])[i] ?? 1))
      .filter((x): x is ListingHaveItem => !!x);
    const opts = optsByListing.get(r.id) ?? [];
    const options: ListingOption[] = opts.map((o) => ({
      id: o.id,
      position: o.position,
      logic: o.logic,
      exchangeType: o.exchange_type,
      isCashOffer: o.is_cash_offer,
      cashAmount: o.cash_amount,
      groupName: o.wish_group_id
        ? (groupNameById.get(o.wish_group_id) ?? null)
        : null,
      goodsTypeName: o.wish_goods_type_id
        ? (goodsTypeNameById.get(o.wish_goods_type_id) ?? null)
        : null,
      wishes: o.is_cash_offer
        ? []
        : (o.wish_ids ?? [])
            .map((id, i) => toWishLi(id, (o.wish_qtys ?? [])[i] ?? 1))
            .filter((x): x is ListingWishItem => !!x),
    }));
    return {
      id: r.id,
      haves,
      haveLogic: r.have_logic,
      haveGroupName: r.have_group_id
        ? (groupNameById.get(r.have_group_id) ?? null)
        : null,
      haveGoodsTypeName: r.have_goods_type_id
        ? (goodsTypeNameById.get(r.have_goods_type_id) ?? null)
        : null,
      options,
      status: r.status,
      note: r.note,
    };
  });

  const profile: UserProfileData = {
    id: user.id as string,
    handle: user.handle as string,
    displayName: user.display_name as string,
    avatarUrl: (user.avatar_url as string | null) ?? null,
    primaryArea: (user.primary_area as string | null) ?? null,
    ratingAvg,
    ratingCount,
    completedTradeCount: completedCount ?? 0,
    inventoryItems,
    listingItems,
  };

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title={`@${user.handle}`} sub="プロフィール" backHref="/" />
      <div className="mx-auto w-full max-w-md flex-1 flex-col px-5 pb-12 pt-3">
        <UserProfileView profile={profile} />
      </div>
    </main>
  );
}
