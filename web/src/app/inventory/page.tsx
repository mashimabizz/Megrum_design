import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import {
  InventoryFooter,
  InventoryView,
  type InventoryItemFull,
} from "./InventoryView";

export const metadata = {
  title: "マイ在庫 — Megrum",
};

type InventoryRow = {
  id: string;
  kind: "for_trade" | "wanted";
  title: string;
  quantity: number;
  status: "active" | "keep" | "traded" | "reserved" | "archived";
  carrying: boolean;
  hue: number | null;
  photo_urls: string[] | null;
  group: { name: string } | { name: string }[] | null;
  character: { name: string } | { name: string }[] | null;
  character_request:
    | { requested_name: string; status: string }
    | { requested_name: string; status: string }[]
    | null;
  goods_type: { name: string } | { name: string }[] | null;
};

function pickOne<T>(v: T | T[] | null): T | null {
  if (!v) return null;
  return Array.isArray(v) ? (v[0] ?? null) : v;
}

// メンバー名 → hue（0〜360）の単純ハッシュ
function nameToHue(name: string): number {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = (hash << 5) - hash + name.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash) % 360;
}

export default async function InventoryPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 譲在庫を取得（iter65.6: 持参グッズ管理機能廃止に伴い is_going_out fetch 削除）
  const { data: rows } = await supabase
    .from("goods_inventory")
    .select(
      "id, kind, title, quantity, status, carrying, hue, photo_urls, group:groups_master(name), character:characters_master(name), character_request:character_requests(requested_name, status), goods_type:goods_types_master(name)",
    )
    .eq("user_id", user.id)
    .eq("kind", "for_trade")
    .neq("status", "archived")
    .order("created_at", { ascending: false });

  const items: InventoryItemFull[] = ((rows as InventoryRow[]) ?? []).map(
    (r) => {
      const grp = pickOne(r.group);
      const ch = pickOne(r.character);
      const req = pickOne(r.character_request);
      const gt = pickOne(r.goods_type);
      // メンバー名解決: characters_master 優先 → 審査中リクエスト → グループ名
      const memberName =
        ch?.name ?? req?.requested_name ?? grp?.name ?? "?";
      const isPending = !ch && !!req && req.status === "pending";
      return {
        id: r.id,
        memberName,
        groupName: grp?.name ?? null,
        goodsType: gt?.name ?? "?",
        series: null, // 「シリーズ」は廃止予定（DB 値は表示しない）
        qty: r.quantity,
        hue: r.hue ?? nameToHue(memberName),
        carrying: r.carrying,
        status: r.status,
        photoUrl: (r.photo_urls && r.photo_urls[0]) ?? null,
        isPending,
      };
    },
  );

  return (
    <>
      <InventoryView items={items} />
      <InventoryFooter />
    </>
  );
}
