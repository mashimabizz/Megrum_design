import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { CarryingSelectView } from "./CarryingSelectView";

export const metadata = {
  title: "持参グッズを選択 — Megrum",
};

type Props = {
  searchParams: Promise<{ return?: string }>;
};

/**
 * 持参グッズ選択画面（写真付きグリッド）
 *
 * - ホーム → 現地交換モード → 「グッズを選ぶ」から遷移
 * - 自分の active な譲を全件、写真付きパネルで表示
 * - 推し / 種別で絞り込み
 * - 多選択
 * - 「N 件で確定」CTA → 戻り先（return パラメータ or /）
 */
export default async function SelectCarryingPage({ searchParams }: Props) {
  const params = await searchParams;
  const returnTo = params.return ?? "";

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 並列：在庫 + 現在の選択
  const [{ data: inventoryRows }, { data: localMode }] = await Promise.all([
    supabase
      .from("goods_inventory")
      .select(
        "id, title, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .eq("user_id", user.id)
      .eq("kind", "for_trade")
      .eq("status", "active")
      .order("created_at", { ascending: false }),
    supabase
      .from("user_local_mode_settings")
      .select("selected_carrying_ids")
      .eq("user_id", user.id)
      .maybeSingle(),
  ]);

  type Row = {
    id: string;
    title: string;
    photo_urls: string[] | null;
    hue: number | null;
    group: { name: string } | { name: string }[] | null;
    character: { name: string } | { name: string }[] | null;
    goods_type: { name: string } | { name: string }[] | null;
  };

  const pickName = (
    v: { name: string } | { name: string }[] | null,
  ): string | null => {
    if (!v) return null;
    return Array.isArray(v) ? v[0]?.name ?? null : v.name;
  };

  const nameToHue = (name: string): number => {
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = (hash << 5) - hash + name.charCodeAt(i);
      hash |= 0;
    }
    return Math.abs(hash) % 360;
  };

  const items = ((inventoryRows as Row[]) ?? []).map((r) => {
    const charName = pickName(r.character);
    const grpName = pickName(r.group);
    const memberName = charName ?? grpName ?? r.title;
    return {
      id: r.id,
      title: r.title,
      photoUrl: (r.photo_urls && r.photo_urls[0]) ?? null,
      groupName: grpName,
      characterName: charName,
      goodsTypeName: pickName(r.goods_type),
      hue: r.hue ?? nameToHue(memberName),
    };
  });

  const initialSelected =
    (localMode?.selected_carrying_ids as string[] | null) ?? [];

  // returnTo の安全化：相対パスのみ許可
  const safeReturn =
    returnTo === "local-mode" ? "/?openLocalMode=1" : "/";

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="持参グッズを選択" backHref={safeReturn} />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-[120px] pt-4">
        <CarryingSelectView
          items={items}
          initialSelected={initialSelected}
          returnTo={safeReturn}
        />
      </div>
    </main>
  );
}
