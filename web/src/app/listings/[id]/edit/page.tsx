import { notFound, redirect } from "next/navigation";
import Link from "next/link";
import {
  createClient,
  createServiceRoleClient,
} from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import {
  buildMarketAvailableQtyByInvId,
  getAgreedReservedQtyByInvId,
  withMarketAvailableQuantity,
} from "@/lib/marketAvailability";
import {
  ListingNewForm,
  type ListingFormInitialValues,
} from "@/app/listings/new/ListingNewForm";

export const metadata = {
  title: "個別募集を編集 — Megrum",
};

type ListingRow = {
  id: string;
  user_id: string;
  status: string;
  have_ids: string[] | null;
  have_qtys: number[] | null;
  have_logic: "and" | "or";
  have_group_id: string | null;
  have_goods_type_id: string | null;
  note: string | null;
};

type OptionRow = {
  id: string;
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

function pickName(
  v: { name: string } | { name: string }[] | null,
): string | null {
  if (!v) return null;
  return Array.isArray(v) ? v[0]?.name ?? null : v.name;
}

export default async function ListingEditPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const serviceSupabase = createServiceRoleClient();

  // 対象 listing を fetch + 所有者チェック
  const { data: row } = await supabase
    .from("listings")
    .select(
      `id, user_id, status, have_ids, have_qtys, have_logic,
       have_group_id, have_goods_type_id, note`,
    )
    .eq("id", id)
    .maybeSingle();
  if (!row) notFound();
  const listing = row as ListingRow;
  if (listing.user_id !== user.id) notFound();
  if (listing.status === "matched" || listing.status === "closed") {
    return (
      <main className="flex flex-1 flex-col bg-[#fbf9fc]">
        <HeaderBack title="個別募集を編集" backHref="/listings" />
        <div className="mx-auto w-full max-w-md flex-1 px-5 pt-8">
          <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white p-6 text-center">
            <div className="text-[14px] font-bold text-gray-900">
              この個別募集は編集できません
            </div>
            <div className="mt-2 text-[12px] text-gray-500">
              ステータス：
              <b>{listing.status === "matched" ? "成立" : "完了"}</b>{" "}
              の個別募集は編集不可です。
            </div>
            <Link
              href="/listings"
              className="mt-4 inline-block text-[12px] font-bold text-[#a695d8]"
            >
              ← 個別募集一覧に戻る
            </Link>
          </div>
        </div>
      </main>
    );
  }

  // options
  const { data: optRows } = await supabase
    .from("listing_wish_options")
    .select(
      `id, position, wish_ids, wish_qtys, logic, exchange_type,
       is_cash_offer, cash_amount, wish_group_id, wish_goods_type_id`,
    )
    .eq("listing_id", id)
    .order("position", { ascending: true });
  const options = (optRows as OptionRow[]) ?? [];

  // 自分の active な譲 + active な wish を並列 fetch
  const [{ data: inventoryRows }, { data: wishRows }] = await Promise.all([
    supabase
      .from("goods_inventory")
      .select(
        // iter144: 譲側の選択上限を在庫数に揃えるため quantity も取得
"id, title, photo_urls, hue, quantity, group_id, goods_type_id, group:groups_master(id, name), character:characters_master(id, name), goods_type:goods_types_master(id, name)",
      )
      .eq("user_id", user.id)
      .eq("kind", "for_trade")
      .eq("status", "active")
      .order("created_at", { ascending: false }),
    supabase
      .from("goods_inventory")
      .select(
        // iter145: WishMiniPanel + exchangeType 出し分けに使用するため photo_urls も取得
"id, title, exchange_type, group_id, goods_type_id, photo_urls, group:groups_master(id, name), character:characters_master(id, name), goods_type:goods_types_master(id, name)",
      )
      .eq("user_id", user.id)
      .eq("kind", "wanted")
      .neq("status", "archived")
      .order("created_at", { ascending: false }),
  ]);

  // 編集対象が参照する wish が現在 active でない可能性があるため、
  // wish 側だけは参照 id を別途 union fetch して、編集時に外せるようにする。
  // 譲側は「いま市場に出せる候補」だけを表示し、古い have_id は初期選択から外す。
  const referencedWishIds = new Set<string>();
  for (const o of options) for (const wid of o.wish_ids ?? []) referencedWishIds.add(wid);
  const wishIdsToFetch = Array.from(referencedWishIds).filter(
    (id) => !(wishRows ?? []).some((r) => r.id === id),
  );
  const extraWishRows: typeof wishRows = [];
  if (wishIdsToFetch.length > 0) {
    const { data } = await supabase
      .from("goods_inventory")
      .select(
        // iter145: WishMiniPanel + exchangeType 出し分けに使用するため photo_urls も取得
"id, title, exchange_type, group_id, goods_type_id, photo_urls, group:groups_master(id, name), character:characters_master(id, name), goods_type:goods_types_master(id, name)",
      )
      .in("id", wishIdsToFetch);
    if (data) extraWishRows.push(...data);
  }
  const allInventoryRows = inventoryRows ?? [];
  const allWishRows = [...(wishRows ?? []), ...extraWishRows];
  const reservedQtyByInvId = await getAgreedReservedQtyByInvId(
    serviceSupabase,
    allInventoryRows.map((r) => r.id as string),
  );
  const marketAvailableQtyByInvId = buildMarketAvailableQtyByInvId(
    allInventoryRows,
    reservedQtyByInvId,
  );
  const marketInventoryRows = withMarketAvailableQuantity(
    allInventoryRows,
    marketAvailableQtyByInvId,
  );

  const nameToHue = (name: string): number => {
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = (hash << 5) - hash + name.charCodeAt(i);
      hash |= 0;
    }
    return Math.abs(hash) % 360;
  };

  const inventoryItems = marketInventoryRows.map((r) => {
    const charName = pickName(r.character);
    const grpName = pickName(r.group);
    const memberName = charName ?? grpName ?? r.title;
    return {
      id: r.id,
      title: r.title,
      photoUrl:
        (r.photo_urls && (r.photo_urls as string[])[0]) ?? null,
      groupId: (r as { group_id?: string }).group_id ?? null,
      goodsTypeId: (r as { goods_type_id?: string }).goods_type_id ?? null,
      groupName: grpName,
      characterName: charName,
      goodsTypeName: pickName(r.goods_type),
      hue:
        ((r as { hue?: number }).hue as number | undefined) ??
        nameToHue(memberName),
      // iter144: 在庫数（譲側の qty 上限として form に渡す）
      availableQty: ((r as { quantity?: number }).quantity as number | undefined) ?? 1,
    };
  });

  const wishItems = allWishRows.map((r) => ({
    id: r.id,
    title: r.title,
    exchangeType: (r as { exchange_type?: string }).exchange_type as
      | "same_kind"
      | "cross_kind"
      | "any"
      | undefined,
    groupId: (r as { group_id?: string }).group_id ?? null,
    goodsTypeId: (r as { goods_type_id?: string }).goods_type_id ?? null,
    groupName: pickName(r.group),
    characterName: pickName(r.character),
    goodsTypeName: pickName(r.goods_type),
    // iter145: 画像 URL
    photoUrl:
      ((r as { photo_urls?: string[] }).photo_urls?.[0] as
        | string
        | undefined) ?? null,
  }));

  function uniqueOptions<T extends { id: string; name: string }>(
    src: { id: string | null; name: string | null }[],
  ): T[] {
    const seen = new Map<string, T>();
    for (const o of src) {
      if (o.id && o.name && !seen.has(o.id)) {
        seen.set(o.id, { id: o.id, name: o.name } as T);
      }
    }
    return Array.from(seen.values()).sort((a, b) =>
      a.name.localeCompare(b.name, "ja"),
    );
  }

  const inventoryGroups = uniqueOptions<{ id: string; name: string }>(
    marketInventoryRows.map((r) => ({
      id: (r as { group_id?: string }).group_id ?? null,
      name: pickName(r.group),
    })),
  );
  const inventoryGoodsTypes = uniqueOptions<{ id: string; name: string }>(
    marketInventoryRows.map((r) => ({
      id: (r as { goods_type_id?: string }).goods_type_id ?? null,
      name: pickName(r.goods_type),
    })),
  );
  const wishGroups = uniqueOptions<{ id: string; name: string }>(
    allWishRows.map((r) => ({
      id: (r as { group_id?: string }).group_id ?? null,
      name: pickName(r.group),
    })),
  );
  const wishGoodsTypes = uniqueOptions<{ id: string; name: string }>(
    allWishRows.map((r) => ({
      id: (r as { goods_type_id?: string }).goods_type_id ?? null,
      name: pickName(r.goods_type),
    })),
  );
  const inventoryItemById = new Map(inventoryItems.map((it) => [it.id, it]));
  const canUseInitialHaveGroup =
    !!listing.have_group_id &&
    inventoryGroups.some((g) => g.id === listing.have_group_id);
  const canUseInitialHaveGoodsType =
    !!listing.have_goods_type_id &&
    inventoryGoodsTypes.some((g) => g.id === listing.have_goods_type_id);

  // 初期値構築
  const haveIds = listing.have_ids ?? [];
  const haveQtys = listing.have_qtys ?? [];
  const initialValues: ListingFormInitialValues = {
    haveGroupId: canUseInitialHaveGroup ? listing.have_group_id : null,
    haveGoodsTypeId: canUseInitialHaveGoodsType
      ? listing.have_goods_type_id
      : null,
    selectedHaves: haveIds.flatMap((hid, i) => {
      const item = inventoryItemById.get(hid);
      if (!item || item.availableQty < 1) return [];
      return [
        {
          id: hid,
          qty: Math.min(Math.max(1, haveQtys[i] ?? 1), item.availableQty),
        },
      ];
    }),
    haveLogic: listing.have_logic,
    options: options.map((o) => ({
      position: o.position,
      groupId: o.wish_group_id,
      goodsTypeId: o.wish_goods_type_id,
      selected: (o.wish_ids ?? []).map((wid, i) => ({
        id: wid,
        qty: (o.wish_qtys ?? [])[i] ?? 1,
      })),
      logic: o.logic,
      exchangeType: o.exchange_type,
      isCashOffer: o.is_cash_offer,
      cashAmount: o.cash_amount,
    })),
    note: listing.note ?? "",
  };

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="個別募集を編集" backHref="/listings" />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-8 pt-5">
        <p className="mb-4 text-[12px] leading-relaxed text-gray-500">
          譲・求の組合せやメモを変更できます。保存すると選択肢は新しい内容で
          上書きされます。
        </p>
        <ListingNewForm
          mode="edit"
          listingId={listing.id}
          initialValues={initialValues}
          inventoryItems={inventoryItems}
          wishItems={wishItems}
          inventoryGroups={inventoryGroups}
          inventoryGoodsTypes={inventoryGoodsTypes}
          wishGroups={wishGroups}
          wishGoodsTypes={wishGoodsTypes}
        />
      </div>
    </main>
  );
}
