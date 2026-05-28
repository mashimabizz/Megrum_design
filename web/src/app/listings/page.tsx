import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { BottomNav } from "@/components/home/BottomNav";
import { FloatingAddButton } from "@/components/common/FloatingAddButton";
import {
  ListingsView,
  type ListingItem,
  type ListingHaveItem,
  type ListingOption,
  type ListingWishItem,
} from "./ListingsView";

export const metadata = {
  title: "個別募集 — Megrum",
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

export default async function ListingsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // listings + 関連 options を fetch
  const { data: rows } = await supabase
    .from("listings")
    .select(
      `id, have_ids, have_qtys, have_logic, have_group_id, have_goods_type_id, status, note, created_at`,
    )
    .eq("user_id", user.id)
    .neq("status", "closed")
    .order("created_at", { ascending: false });

  const listingRows = (rows as ListingRow[]) ?? [];
  const listingIds = listingRows.map((r) => r.id);

  // options を bulk fetch
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

  // 全 inv id（haves + options.wishes）を flatten して in-clause で一括取得
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

  // group/goods_type マスタも取得（listing 内 group/goods_type 表示用）
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
    if (data)
      for (const g of data) groupNameById.set(g.id, g.name as string);
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
  function toWish(id: string, qty: number): ListingWishItem | null {
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

  const items: ListingItem[] = listingRows.map((r) => {
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
            .map((id, i) => toWish(id, (o.wish_qtys ?? [])[i] ?? 1))
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

  return (
    <>
      <main
        className="flex flex-1 flex-col bg-[#fbf9fc] pb-[88px]"
        style={{
          fontFamily: '"Noto Sans JP", -apple-system, system-ui',
          color: "#3a324a",
        }}
      >
        <div className="h-[60px]" />
        <div className="border-b border-[#3a324a0f] bg-white px-[18px] pb-[10px] pt-3">
          <div className="mx-auto flex max-w-md items-center justify-between">
            <div>
              <div className="text-[19px] font-extrabold tracking-[0.3px] text-[#3a324a]">
                個別募集
              </div>
              <div className="mt-[1px] text-[11px] text-[#3a324a8c]">
                譲 1 バンドル × 求 複数選択肢でピンポイント募集
              </div>
            </div>
          </div>
        </div>

        <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-4 pt-4">
          <ListingsView items={items} />
        </div>
        <FloatingAddButton href="/listings/new" label="個別募集を追加" />
      </main>
      <BottomNav />
    </>
  );
}
