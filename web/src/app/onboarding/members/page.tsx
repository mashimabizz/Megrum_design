import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { MembersForm, type Section } from "./MembersForm";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { ProgressDots } from "@/components/auth/ProgressDots";

export const metadata = {
  title: "プロフィール設定 — Megrum",
};

/**
 * オンボーディング 3/4: メンバー / キャラクター選択（モックアップ AOOnboardMember 準拠）
 *
 * - 各推しごとにセクション分け
 * - 「箱推し」 or 個別メンバー（複数可）
 * - 審査中の推し（oshi_request_id）は承認後選択になるので「承認後」表示
 */
export default async function MembersPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // 並列クエリ
  const [
    { data: userOshiList },
    { data: characters },
    { data: pendingCharacterRequests },
  ] = await Promise.all([
    supabase
      .from("user_oshi")
      .select(
        "id, group_id, oshi_request_id, character_id, character_request_id, kind, priority, group:groups_master(id, name), oshi_request:oshi_requests(id, requested_name)",
      )
      .eq("user_id", user.id)
      .order("priority", { ascending: true }),
    supabase
      .from("characters_master")
      .select("id, group_id, name, display_order")
      .order("display_order", { ascending: true }),
    supabase
      .from("character_requests")
      .select(
        "id, group_id, oshi_request_id, requested_name, user_id, created_at",
      )
      .eq("status", "pending")
      .order("created_at", { ascending: false }),
  ]);

  // 推し選択未完なら戻す
  if (!userOshiList || userOshiList.length === 0) {
    redirect("/onboarding/oshi");
  }

  // 同じ user_oshi.id で複数 row（複数メンバー選択）の可能性があるので、
  // group_id + oshi_request_id でユニーク化してセクション化
  type OshiKey = string; // group_id || oshi_request_id
  const sectionMap = new Map<
    OshiKey,
    {
      oshiId: string; // 代表の user_oshi.id（最小 priority）
      groupId: string | null;
      oshiRequestId: string | null;
      groupName: string;
      isPendingRequest: boolean;
      memberIds: string[]; // 既選択 characters_master.id
      requestIds: string[]; // 既選択 character_requests.id
      kind: "box" | "specific" | "multi";
      minPriority: number;
    }
  >();

  for (const o of userOshiList) {
    const groupRel = Array.isArray(o.group) ? o.group[0] : o.group;
    const reqRel = Array.isArray(o.oshi_request)
      ? o.oshi_request[0]
      : o.oshi_request;
    const key: OshiKey = (o.group_id ?? o.oshi_request_id) as string;
    if (!key) continue;

    const existing = sectionMap.get(key);
    if (existing) {
      if (o.character_id) existing.memberIds.push(o.character_id);
      if (o.character_request_id)
        existing.requestIds.push(o.character_request_id);
      if (o.priority < existing.minPriority) {
        existing.minPriority = o.priority;
        existing.oshiId = o.id;
      }
    } else {
      sectionMap.set(key, {
        oshiId: o.id,
        groupId: o.group_id,
        oshiRequestId: o.oshi_request_id,
        groupName: groupRel?.name ?? reqRel?.requested_name ?? "(不明)",
        isPendingRequest: !!o.oshi_request_id,
        memberIds: o.character_id ? [o.character_id] : [],
        requestIds: o.character_request_id ? [o.character_request_id] : [],
        kind: (o.kind ?? "box") as "box" | "specific" | "multi",
        minPriority: o.priority,
      });
    }
  }

  // characters を group_id ごとにマップ化
  const charsByGroup = new Map<string, { id: string; name: string }[]>();
  for (const c of characters ?? []) {
    if (!c.group_id) continue;
    const arr = charsByGroup.get(c.group_id) ?? [];
    arr.push({ id: c.id, name: c.name });
    charsByGroup.set(c.group_id, arr);
  }

  // 審査中メンバー（character_requests）を 親キー（group_id or oshi_request_id）ごとにマップ化
  type PendingMember = { id: string; name: string; isMine: boolean };
  const pendingByGroup = new Map<string, PendingMember[]>();
  const pendingByOshiRequest = new Map<string, PendingMember[]>();
  for (const r of pendingCharacterRequests ?? []) {
    const item: PendingMember = {
      id: r.id,
      name: r.requested_name,
      isMine: r.user_id === user.id,
    };
    if (r.group_id) {
      const arr = pendingByGroup.get(r.group_id) ?? [];
      arr.push(item);
      pendingByGroup.set(r.group_id, arr);
    } else if (r.oshi_request_id) {
      const arr = pendingByOshiRequest.get(r.oshi_request_id) ?? [];
      arr.push(item);
      pendingByOshiRequest.set(r.oshi_request_id, arr);
    }
  }

  // section 構築（minPriority 順）
  const sections: Section[] = Array.from(sectionMap.values())
    .sort((a, b) => a.minPriority - b.minPriority)
    .map((s) => ({
      oshiId: s.oshiId,
      groupId: s.groupId,
      oshiRequestId: s.oshiRequestId,
      groupName: s.groupName,
      isPendingRequest: s.isPendingRequest,
      members: s.groupId ? (charsByGroup.get(s.groupId) ?? []) : [],
      pendingMembers: s.groupId
        ? (pendingByGroup.get(s.groupId) ?? [])
        : s.oshiRequestId
          ? (pendingByOshiRequest.get(s.oshiRequestId) ?? [])
          : [],
    }));

  // 既存選択の初期値構築
  const initialSelections: Record<
    string,
    { isBox: boolean; memberIds: string[]; requestIds: string[] }
  > = {};
  for (const s of sectionMap.values()) {
    initialSelections[s.oshiId] = {
      isBox: s.kind === "box",
      memberIds: s.memberIds,
      requestIds: s.requestIds,
    };
  }

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title="プロフィール設定"
        sub="推しメン・推しキャラ"
        progress="3/4"
        backHref="/onboarding/oshi"
      />
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col px-5 pb-8 pt-6">
        <ProgressDots current={2} total={4} />
        <h2 className="mt-4 text-[22px] font-extrabold leading-tight text-gray-900">
          メンバーは？
        </h2>
        <p className="mt-2 text-xs leading-relaxed text-gray-500">
          推しごとに「箱推し」または個別メンバーを選択できます
        </p>
        <MembersForm
          sections={sections}
          initialSelections={initialSelections}
        />
      </div>
    </main>
  );
}
