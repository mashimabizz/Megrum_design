import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { BottomNav } from "@/components/home/BottomNav";
import { SearchView, type SearchHit } from "./SearchView";

export const metadata = {
  title: "検索 — Megrum",
};

type InventoryHitRow = {
  id: string;
  user_id: string;
  title: string;
  photo_urls: string[] | null;
  group: { name: string } | { name: string }[] | null;
  character: { name: string } | { name: string }[] | null;
  goods_type: { name: string } | { name: string }[] | null;
};

function pickName(
  v: { name: string } | { name: string }[] | null,
): string | null {
  if (!v) return null;
  return Array.isArray(v) ? v[0]?.name ?? null : v.name;
}

const POPULAR_KEYWORDS = [
  "スア トレカ",
  "ヒナ 生写真",
  "WORLD TOUR",
  "POP-UP STORE",
  "横浜アリーナ",
  "推し誕生日カフェ",
];

export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q: rawQ } = await searchParams;
  const q = (rawQ ?? "").trim();

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  let hits: SearchHit[] = [];
  if (q.length > 0) {
    /**
     * 検索アルゴリズム：
     * - キーワードを title / character.name / group.name に対して partial match
     * - 自分以外のユーザーで kind='for_trade' status='active' のみ
     * - 上位 30 件
     */
    const ilike = `%${q}%`;

    // 1. title 直接マッチ
    const { data: titleRows } = await supabase
      .from("goods_inventory")
      .select(
        `id, user_id, title, photo_urls,
         group:groups_master(name),
         character:characters_master(name),
         goods_type:goods_types_master(name)`,
      )
      .neq("user_id", user.id)
      .eq("kind", "for_trade")
      .eq("status", "active")
      .ilike("title", ilike)
      .limit(20);

    // 2. character.name 経由 — characters_master を name で検索
    const { data: chMaster } = await supabase
      .from("characters_master")
      .select("id")
      .ilike("name", ilike)
      .limit(20);
    const charIds = (chMaster ?? []).map((c) => c.id as string);
    let charRows: InventoryHitRow[] | null = null;
    if (charIds.length > 0) {
      const { data } = await supabase
        .from("goods_inventory")
        .select(
          `id, user_id, title, photo_urls,
           group:groups_master(name),
           character:characters_master(name),
           goods_type:goods_types_master(name)`,
        )
        .neq("user_id", user.id)
        .eq("kind", "for_trade")
        .eq("status", "active")
        .in("character_id", charIds)
        .limit(20);
      charRows = data as InventoryHitRow[] | null;
    }

    // 3. group.name 経由
    const { data: grMaster } = await supabase
      .from("groups_master")
      .select("id")
      .ilike("name", ilike)
      .limit(20);
    const groupIds = (grMaster ?? []).map((g) => g.id as string);
    let groupRows: InventoryHitRow[] | null = null;
    if (groupIds.length > 0) {
      const { data } = await supabase
        .from("goods_inventory")
        .select(
          `id, user_id, title, photo_urls,
           group:groups_master(name),
           character:characters_master(name),
           goods_type:goods_types_master(name)`,
        )
        .neq("user_id", user.id)
        .eq("kind", "for_trade")
        .eq("status", "active")
        .in("group_id", groupIds)
        .limit(20);
      groupRows = data as InventoryHitRow[] | null;
    }

    const merged = new Map<string, InventoryHitRow>();
    for (const arr of [titleRows, charRows, groupRows]) {
      if (!arr) continue;
      for (const r of arr as InventoryHitRow[]) merged.set(r.id, r);
    }
    const allHits = Array.from(merged.values()).slice(0, 30);

    // ユーザー情報をまとめて取得
    const userIds = Array.from(new Set(allHits.map((r) => r.user_id)));
    const usersById = new Map<
      string,
      { handle: string; displayName: string; primaryArea: string | null }
    >();
    if (userIds.length > 0) {
      const { data: us } = await supabase
        .from("users")
        .select("id, handle, display_name, primary_area")
        .in("id", userIds);
      if (us) {
        for (const u of us)
          usersById.set(u.id as string, {
            handle: u.handle as string,
            displayName: u.display_name as string,
            primaryArea: (u.primary_area as string | null) ?? null,
          });
      }
    }

    // 自分の wish にヒットしているか（完全マッチかどうかの簡易判定）
    const { data: myWishRows } = await supabase
      .from("goods_inventory")
      .select("group_id, character_id, goods_type_id")
      .eq("user_id", user.id)
      .eq("kind", "wanted")
      .neq("status", "archived");
    type WishRef = {
      group_id: string | null;
      character_id: string | null;
      goods_type_id: string | null;
    };
    const myWishes: WishRef[] = (myWishRows ?? []) as WishRef[];

    // 評価サマリ（hit ユーザーごと）
    const ratingByUser = new Map<
      string,
      { avg: number | null; count: number }
    >();
    if (userIds.length > 0) {
      const { data: evs } = await supabase
        .from("user_evaluations")
        .select("ratee_id, stars")
        .in("ratee_id", userIds);
      if (evs) {
        const grouped = new Map<string, number[]>();
        for (const e of evs) {
          const arr = grouped.get(e.ratee_id as string) ?? [];
          arr.push(e.stars as number);
          grouped.set(e.ratee_id as string, arr);
        }
        for (const [uid, arr] of grouped.entries()) {
          ratingByUser.set(uid, {
            avg: arr.reduce((a, b) => a + b, 0) / arr.length,
            count: arr.length,
          });
        }
      }
    }

    hits = allHits.map((row) => {
      const u = usersById.get(row.user_id);
      const grName = pickName(row.group);
      const charName = pickName(row.character);
      const typeName = pickName(row.goods_type);

      // 完全マッチ判定（私の wish にヒット）
      const wishHit = myWishes.some((w) => {
        // 同 goods_type 必須
        if (w.goods_type_id !== (row as { goods_type_id?: string }).goods_type_id)
          return false;
        if (
          w.character_id &&
          (row as { character_id?: string }).character_id
        ) {
          return (
            w.character_id ===
            (row as { character_id?: string }).character_id
          );
        }
        if (!w.group_id) return false;
        return w.group_id === (row as { group_id?: string }).group_id;
      });

      const rating = ratingByUser.get(row.user_id);

      return {
        id: row.id,
        userId: row.user_id,
        userHandle: u?.handle ?? "?",
        userDisplayName: u?.displayName ?? "?",
        primaryArea: u?.primaryArea ?? null,
        ratingAvg: rating?.avg ?? null,
        ratingCount: rating?.count ?? 0,
        title: row.title,
        photoUrl: (row.photo_urls && row.photo_urls[0]) ?? null,
        groupName: grName,
        characterName: charName,
        goodsTypeName: typeName,
        wishHit,
      } satisfies SearchHit;
    });
  }

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
        <div className="border-b border-[#3a324a0f] bg-white px-[18px] pb-3 pt-3">
          <div className="mx-auto max-w-md">
            <div className="text-[19px] font-extrabold tracking-[0.3px] text-[#3a324a]">
              検索
            </div>
            <div className="mt-[1px] text-[11px] text-[#3a324a8c]">
              他ユーザーの譲（出品中）からキーワード検索
            </div>
          </div>
        </div>

        <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-4 pt-3">
          <SearchView
            query={q}
            hits={hits}
            popularKeywords={POPULAR_KEYWORDS}
          />
        </div>
      </main>
      <BottomNav />
    </>
  );
}
