import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { EditForm } from "./EditForm";

export const metadata = {
  title: "グッズを編集 — Megrum",
};

type ItemRow = {
  id: string;
  user_id: string;
  kind: "for_trade" | "wanted";
  group_id: string | null;
  character_id: string | null;
  character_request_id: string | null;
  goods_type_id: string | null;
  title: string;
  description: string | null;
  condition: "sealed" | "mint" | "good" | "fair" | "poor" | null;
  quantity: number;
  hue: number | null;
  photo_urls: string[] | null;
  carrying: boolean;
  status: "active" | "keep" | "traded" | "reserved" | "archived";
};

/**
 * 在庫編集ページ — /inventory/[id]
 *
 * - アイテムの全フィールド編集
 * - 削除ボタン
 */
export default async function InventoryEditPage({
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

  // 並列取得：アイテム本体 + マスタ群 + iter113 タグ
  const [
    { data: item },
    { data: userOshi },
    { data: goodsTypes },
    { data: characters },
    { data: pendingRequests },
    { data: tagRows },
  ] = await Promise.all([
    supabase
      .from("goods_inventory")
      .select(
        "id, user_id, kind, group_id, character_id, character_request_id, goods_type_id, title, description, condition, quantity, hue, photo_urls, carrying, status",
      )
      .eq("id", id)
      .eq("user_id", user.id)
      .maybeSingle(),
    supabase
      .from("user_oshi")
      .select("group_id, group:groups_master(id, name)")
      .eq("user_id", user.id)
      .not("group_id", "is", null),
    supabase
      .from("goods_types_master")
      .select("id, name")
      .order("display_order", { ascending: true }),
    supabase
      .from("characters_master")
      .select("id, name, group_id")
      .order("display_order", { ascending: true }),
    supabase
      .from("character_requests")
      .select("id, group_id, requested_name")
      .eq("user_id", user.id)
      .eq("status", "pending")
      .order("created_at", { ascending: false }),
    // iter113: 紐づくタグをロード
    supabase
      .from("goods_inventory_tags")
      .select("tag:tags_master(id, label)")
      .eq("inventory_id", id),
  ]);

  if (!item) notFound();
  const it = item as ItemRow;
  const isReadOnly = it.status === "traded";

  // ユーザーの推しグループを抽出
  const groupMap = new Map<string, { id: string; name: string }>();
  for (const o of userOshi ?? []) {
    if (!o.group_id) continue;
    const grp = Array.isArray(o.group) ? o.group[0] : o.group;
    if (grp && !groupMap.has(grp.id)) {
      groupMap.set(grp.id, { id: grp.id, name: grp.name });
    }
  }
  // 編集中のアイテムが推しに無いグループに属している可能性に備える
  // → そのグループも masters_master から取得して候補に追加
  if (it.group_id && !groupMap.has(it.group_id)) {
    const { data: g } = await supabase
      .from("groups_master")
      .select("id, name")
      .eq("id", it.group_id)
      .maybeSingle();
    if (g) groupMap.set(g.id, { id: g.id, name: g.name });
  }
  const groups = Array.from(groupMap.values());

  // 該当グループのキャラのみ（編集中のグループ含む）
  const groupIds = new Set(groups.map((g) => g.id));
  const filteredCharacters = (characters ?? [])
    .filter((c) => c.group_id && groupIds.has(c.group_id))
    .map((c) => ({ id: c.id, name: c.name, group_id: c.group_id! }));

  // 自分の pending リクエスト + 編集中のアイテムが参照しているリクエストも含める
  const pendingMembers = (pendingRequests ?? [])
    .filter((r) => r.group_id && groupIds.has(r.group_id))
    .map((r) => ({
      id: r.id,
      name: r.requested_name,
      group_id: r.group_id!,
    }));

  // iter113: タグ抽出
  type TagRowShape = {
    tag: { id: string; label: string } | { id: string; label: string }[] | null;
  };
  const tags = ((tagRows as TagRowShape[]) ?? [])
    .map((r) => (Array.isArray(r.tag) ? r.tag[0] : r.tag))
    .filter((t): t is { id: string; label: string } => !!t);

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title={isReadOnly ? "グッズ詳細" : "グッズを編集"}
        backHref="/inventory"
      />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-12 pt-5">
        <EditForm
          item={{
            id: it.id,
            groupId: it.group_id ?? "",
            characterId: it.character_id,
            characterRequestId: it.character_request_id,
            goodsTypeId: it.goods_type_id ?? "",
            title: it.title,
            description: it.description,
            condition: it.condition,
            quantity: it.quantity,
            photoUrls: it.photo_urls ?? [],
            status: it.status,
            tags,
          }}
          groups={groups}
          goodsTypes={goodsTypes ?? []}
          characters={filteredCharacters}
          pendingMembers={pendingMembers}
        />
      </div>
    </main>
  );
}
