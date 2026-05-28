import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { WishNewForm } from "./WishNewForm";
import { HeaderBack } from "@/components/auth/HeaderBack";

export const metadata = {
  title: "ウィッシュを追加 — Megrum",
};

export default async function WishNewPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 並列取得
  const [{ data: userOshi }, { data: characters }, { data: goodsTypes }] =
    await Promise.all([
      supabase
        .from("user_oshi")
        .select("group_id, group:groups_master(id, name)")
        .eq("user_id", user.id)
        .not("group_id", "is", null),
      supabase
        .from("characters_master")
        .select("id, name, group_id")
        .order("display_order", { ascending: true }),
      supabase
        .from("goods_types_master")
        .select("id, name")
        .order("display_order", { ascending: true }),
    ]);

  const groupMap = new Map<string, { id: string; name: string }>();
  for (const o of userOshi ?? []) {
    if (!o.group_id) continue;
    const grp = Array.isArray(o.group) ? o.group[0] : o.group;
    if (grp && !groupMap.has(grp.id)) {
      groupMap.set(grp.id, { id: grp.id, name: grp.name });
    }
  }
  const groups = Array.from(groupMap.values());

  const groupIds = new Set(groups.map((g) => g.id));
  const filteredCharacters = (characters ?? [])
    .filter((c) => c.group_id && groupIds.has(c.group_id))
    .map((c) => ({ id: c.id, name: c.name, group_id: c.group_id! }));

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="ウィッシュを追加" backHref="/wishes" />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-8 pt-6">
        <p className="mb-5 text-xs leading-relaxed text-gray-500">
          探したいグッズを登録します。優先度と許容範囲を設定すると、
          マッチする譲が見つかった時にお知らせできます。
        </p>
        <WishNewForm
          groups={groups}
          characters={filteredCharacters}
          goodsTypes={goodsTypes ?? []}
        />
      </div>
    </main>
  );
}
