import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { WishView, type WishItem } from "./WishView";
import { BottomNav } from "@/components/home/BottomNav";
import type {
  ListingItem,
  ListingHaveItem,
  ListingOption,
  ListingWishItem,
} from "../listings/ListingsView";

export const metadata = {
  title: "ウィッシュ — Megrum",
};

type WishRow = {
  id: string;
  title: string;
  description: string | null;
  priority: "top" | "second" | "flexible" | null;
  flex_level: "exact" | "character_any" | "series_any" | null;
  exchange_type: "same_kind" | "cross_kind" | "any" | null;
  quantity: number;
  hue: number | null;
  created_at: string;
  group_id: string | null;
  character_id: string | null;
  goods_type_id: string | null;
  photo_urls: string[] | null;
  group: { name: string } | { name: string }[] | null;
  character: { name: string } | { name: string }[] | null;
  goods_type: { name: string } | { name: string }[] | null;
};

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

type InvRow = {
  id: string;
  title: string;
  photo_urls: string[] | null;
  group: { name: string } | { name: string }[] | null;
  character: { name: string } | { name: string }[] | null;
  goods_type: { name: string } | { name: string }[] | null;
};

function pickOne<T>(v: T | T[] | null): T | null {
  if (!v) return null;
  return Array.isArray(v) ? (v[0] ?? null) : v;
}

// メンバー名 / グループ名 → hue ハッシュ（panel 着色用）
function nameToHue(name: string): number {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = (hash << 5) - hash + name.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash) % 360;
}

export default async function WishesPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // iter143: wishes + listings + options を並列取得
  const [{ data: wishRowsRaw }, { data: listingRowsRaw }] = await Promise.all([
    supabase
      .from("goods_inventory")
      .select(
        "id, title, description, priority, flex_level, exchange_type, quantity, hue, created_at, group_id, character_id, goods_type_id, photo_urls, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .eq("user_id", user.id)
      .eq("kind", "wanted")
      .neq("status", "archived")
      .order("created_at", { ascending: false }),
    supabase
      .from("listings")
      .select(
        `id, have_ids, have_qtys, have_logic, have_group_id, have_goods_type_id, status, note, created_at`,
      )
      .eq("user_id", user.id)
      .neq("status", "closed")
      .order("created_at", { ascending: false }),
  ]);

  const wishRows = (wishRowsRaw as WishRow[]) ?? [];
  const listingRows = (listingRowsRaw as ListingRow[]) ?? [];
  const listingIds = listingRows.map((r) => r.id);

  // iter143: options を bulk fetch（listing 表示 + wish 紐付け判定）
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

  // iter143: wishId → 紐付き listings の集合（active/paused/matched 全て含めるが、closed は除外済）
  const linkedListingsByWishId = new Map<
    string,
    { listingId: string; status: ListingRow["status"] }[]
  >();
  for (const lr of listingRows) {
    const opts = optsByListing.get(lr.id) ?? [];
    for (const o of opts) {
      for (const wId of o.wish_ids ?? []) {
        const arr = linkedListingsByWishId.get(wId) ?? [];
        // 重複除外
        if (!arr.find((x) => x.listingId === lr.id)) {
          arr.push({ listingId: lr.id, status: lr.status });
          linkedListingsByWishId.set(wId, arr);
        }
      }
    }
  }

  // ─── tab 2: 個別募集の表示用に inv / group / goodsType 名を揃える ───
  const allInvIds = new Set<string>();
  for (const r of listingRows) for (const id of r.have_ids ?? []) allInvIds.add(id);
  for (const opts of optsByListing.values())
    for (const o of opts) for (const id of o.wish_ids ?? []) allInvIds.add(id);

  let invById = new Map<string, InvRow>();
  if (allInvIds.size > 0) {
    const { data: invRows } = await supabase
      .from("goods_inventory")
      .select(
        "id, title, photo_urls, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .in("id", Array.from(allInvIds));
    if (invRows) {
      invById = new Map((invRows as InvRow[]).map((r) => [r.id, r]));
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
    if (data) for (const g of data) groupNameById.set(g.id, g.name as string);
  }
  if (allGoodsTypeIds.size > 0) {
    const { data } = await supabase
      .from("goods_types_master")
      .select("id, name")
      .in("id", Array.from(allGoodsTypeIds));
    if (data)
      for (const g of data) goodsTypeNameById.set(g.id, g.name as string);
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

  // ─── tab 1: wish パネル ───
  const wishItems: WishItem[] = wishRows.map((r) => {
    const grp = pickOne(r.group);
    const ch = pickOne(r.character);
    const gt = pickOne(r.goods_type);
    const memberLabel = ch?.name ?? grp?.name ?? r.title;
    const linked = linkedListingsByWishId.get(r.id) ?? [];
    return {
      id: r.id,
      title: r.title,
      note: r.description,
      groupName: grp?.name ?? null,
      characterName: ch?.name ?? null,
      goodsTypeName: gt?.name ?? "?",
      priority: r.priority,
      flexLevel: r.flex_level,
      exchangeType: r.exchange_type ?? "any",
      quantity: r.quantity,
      hue: r.hue ?? nameToHue(memberLabel),
      createdAt: r.created_at,
      photoUrl: (r.photo_urls && r.photo_urls[0]) ?? null,
      // iter143: 個別募集との紐付け情報
      linkedListings: linked,
    };
  });

  return (
    <>
      <WishView wishItems={wishItems} listingItems={listingItems} />
      <BottomNav />
    </>
  );
}
