import { redirect } from "next/navigation";
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
import { ListingNewForm } from "./ListingNewForm";

export const metadata = {
  title: "個別募集を追加 — Megrum",
};

type Props = {
  searchParams: Promise<{
    /** iter143: WISH 画面の「未紐付け」から飛んできた時のプリセット wish */
    wishId?: string;
  }>;
};

export default async function ListingNewPage({ searchParams }: Props) {
  const params = await searchParams;
  const preselectWishId = params.wishId ?? null;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const serviceSupabase = createServiceRoleClient();

  // 自分の active な譲 + active な wish を並列 fetch
  // groups/goods_types の選択肢は **在庫から実際に登録されているもの** に限定する（iter67.4 改修）
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
        // iter145: wish の画像有無で exchangeType を出し分け、
        //         WishMiniPanel で画像表示するため photo_urls も取得
        "id, title, exchange_type, group_id, goods_type_id, photo_urls, group:groups_master(id, name), character:characters_master(id, name), goods_type:goods_types_master(id, name)",
      )
      .eq("user_id", user.id)
      .eq("kind", "wanted")
      .neq("status", "archived")
      .order("created_at", { ascending: false }),
  ]);

  const rawInventoryRows = inventoryRows ?? [];
  const reservedQtyByInvId = await getAgreedReservedQtyByInvId(
    serviceSupabase,
    rawInventoryRows.map((r) => r.id as string),
  );
  const marketAvailableQtyByInvId = buildMarketAvailableQtyByInvId(
    rawInventoryRows,
    reservedQtyByInvId,
  );
  const marketInventoryRows = withMarketAvailableQuantity(
    rawInventoryRows,
    marketAvailableQtyByInvId,
  );

  // メンバー名 → hue ハッシュ
  const nameToHue = (name: string): number => {
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = (hash << 5) - hash + name.charCodeAt(i);
      hash |= 0;
    }
    return Math.abs(hash) % 360;
  };

  const pickName = (
    v: { name: string } | { name: string }[] | null,
  ): string | null => {
    if (!v) return null;
    return Array.isArray(v) ? v[0]?.name ?? null : v.name;
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

  const wishItems = (wishRows ?? []).map((r) => ({
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
    // iter145: 画像 URL（WishMiniPanel + exchangeType 出し分けに使用）
    photoUrl:
      ((r as { photo_urls?: string[] }).photo_urls?.[0] as
        | string
        | undefined) ?? null,
  }));

  // ─── 在庫由来の groups / goods_types を抽出（重複排除） ───
  // 譲側 dropdown は inventoryItems から、求側選択肢は wishItems から
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
    (wishRows ?? []).map((r) => ({
      id: (r as { group_id?: string }).group_id ?? null,
      name: pickName(r.group),
    })),
  );
  const wishGoodsTypes = uniqueOptions<{ id: string; name: string }>(
    (wishRows ?? []).map((r) => ({
      id: (r as { goods_type_id?: string }).goods_type_id ?? null,
      name: pickName(r.goods_type),
    })),
  );

  // 何もないと作成不能 → 案内表示
  if (inventoryItems.length === 0 || wishItems.length === 0) {
    return (
      <main className="flex flex-1 flex-col bg-[#fbf9fc]">
        <HeaderBack title="個別募集を追加" backHref="/listings" />
        <div className="mx-auto w-full max-w-md flex-1 px-5 pt-8">
          <div className="rounded-2xl border border-dashed border-[#3a324a14] bg-white p-6 text-center">
            <div className="text-[14px] font-bold text-gray-900">
              個別募集を作るには、譲と wish の両方が必要です
            </div>
            <div className="mt-2 space-y-1 text-[12px] text-gray-500">
              {inventoryItems.length === 0 && (
                <div>
                  譲るグッズがありません ·{" "}
                  <Link
                    href="/inventory/new"
                    className="font-bold text-[#a695d8]"
                  >
                    登録 →
                  </Link>
                </div>
              )}
              {wishItems.length === 0 && (
                <div>
                  wish がありません ·{" "}
                  <Link href="/wishes/new" className="font-bold text-[#a695d8]">
                    登録 →
                  </Link>
                </div>
              )}
            </div>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="個別募集を追加" backHref="/listings" />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-8 pt-5">
        <p className="mb-4 text-[12px] leading-relaxed text-gray-500">
          譲るグッズと求める wish をそれぞれ複数選び、AND/OR と数量を組み合わせて
          ピンポイントの交換条件を作ります。
        </p>
        <ListingNewForm
          inventoryItems={inventoryItems}
          wishItems={wishItems}
          inventoryGroups={inventoryGroups}
          inventoryGoodsTypes={inventoryGoodsTypes}
          wishGroups={wishGroups}
          wishGoodsTypes={wishGoodsTypes}
          preselectWishId={preselectWishId}
        />
      </div>
    </main>
  );
}
