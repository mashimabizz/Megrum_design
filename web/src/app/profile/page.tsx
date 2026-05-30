import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { BottomNav } from "@/components/home/BottomNav";
import { ProfileView } from "./ProfileView";
import { participantOrFilter } from "@/lib/supabaseFilters";

export const metadata = {
  title: "プロフ — Megrum",
};

type OshiRow = {
  group_id: string | null;
  character_id: string | null;
  oshi_request_id: string | null;
  character_request_id: string | null;
  kind: "box" | "specific" | "multi";
  priority: number;
  group: { name: string } | { name: string }[] | null;
  character: { name: string } | { name: string }[] | null;
  oshi_request:
    | { requested_name: string }
    | { requested_name: string }[]
    | null;
  character_request:
    | { requested_name: string }
    | { requested_name: string }[]
    | null;
};

function pickOne<T>(v: T | T[] | null): T | null {
  if (!v) return null;
  return Array.isArray(v) ? (v[0] ?? null) : v;
}

export default async function ProfilePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 並列：プロフ + 推し + AW件数 + 取引件数 + 公開募集数 + 評価
  // iter86: AW は現地モード切替時のみ設定する単一値（複数登録は廃止）。
  // awCount は ProfileView に互換用フィールドとして渡し続けるが UI 上は非表示。
  // iter148: 評価サマリ（hero 右側に表示するため）
  const [
    { data: profile },
    { data: oshi },
    { count: awCount },
    { count: tradeCount },
    { count: listingsCount },
    { data: evals },
  ] = await Promise.all([
    supabase
      .from("users")
      .select(
        "handle, display_name, gender, primary_area, account_status, avatar_url",
      )
      .eq("id", user.id)
      .maybeSingle(),
    supabase
      .from("user_oshi")
      .select(
        "group_id, character_id, oshi_request_id, character_request_id, kind, priority, group:groups_master(name), character:characters_master(name), oshi_request:oshi_requests(requested_name), character_request:character_requests(requested_name)",
      )
      .eq("user_id", user.id)
      .order("priority", { ascending: true }),
    supabase
      .from("activity_windows")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .eq("status", "enabled"),
    supabase
      .from("proposals")
      .select("id", { count: "exact", head: true })
      .or(participantOrFilter("sender_id", "receiver_id", user.id))
      .eq("status", "completed"),
    supabase
      .from("listings")
      .select("id", { count: "exact", head: true })
      .eq("user_id", user.id)
      .eq("status", "active"),
    supabase
      .from("user_evaluations")
      .select("stars")
      .eq("ratee_id", user.id),
  ]);

  const stars = (evals ?? []).map((e) => e.stars as number);
  const ratingAvg =
    stars.length > 0 ? stars.reduce((a, b) => a + b, 0) / stars.length : null;
  const ratingCount = stars.length;

  // 推しグループでまとめる
  const groupMap = new Map<
    string,
    { groupId: string; groupName: string; members: { id: string; name: string }[] }
  >();
  for (const row of (oshi as OshiRow[]) ?? []) {
    const grp = pickOne(row.group);
    const oshiReq = pickOne(row.oshi_request);
    const groupId = row.group_id ?? row.oshi_request_id;
    const groupName = grp?.name ?? oshiReq?.requested_name;
    if (!groupId || !groupName) continue;

    if (!groupMap.has(groupId)) {
      groupMap.set(groupId, {
        groupId,
        groupName,
        members: [],
      });
    }

    if (row.character_id) {
      const ch = pickOne(row.character);
      if (ch) {
        groupMap.get(groupId)!.members.push({
          id: row.character_id,
          name: ch.name,
        });
      }
    }

    if (row.character_request_id) {
      const chReq = pickOne(row.character_request);
      if (chReq) {
        groupMap.get(groupId)!.members.push({
          id: row.character_request_id,
          name: chReq.requested_name,
        });
      }
    }
  }

  const oshiSummary = Array.from(groupMap.values());

  return (
    <>
      <ProfileView
        userId={user.id}
        profile={{
          handle: profile?.handle ?? "",
          displayName: profile?.display_name ?? "",
          gender: profile?.gender ?? null,
          primaryArea: profile?.primary_area ?? null,
          emailVerifiedAt: user.email_confirmed_at ?? null,
          avatarUrl: (profile?.avatar_url as string | null) ?? null,
        }}
        oshiGroups={oshiSummary}
        awCount={awCount ?? 0}
        tradeCount={tradeCount ?? 0}
        listingsCount={listingsCount ?? 0}
        ratingAvg={ratingAvg}
        ratingCount={ratingCount}
      />
      <BottomNav />
    </>
  );
}
