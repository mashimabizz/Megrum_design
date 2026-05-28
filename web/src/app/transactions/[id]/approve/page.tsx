import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { ApproveView, type ApproveData } from "./ApproveView";

export const metadata = {
  title: "取引完了の確認 — Megrum",
};

type Row = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  evidence_photo_url: string | null;
  evidence_taken_at: string | null;
  approved_by_sender: boolean;
  approved_by_receiver: boolean;
  meetup_place_name: string | null;
  sender_have_ids: string[];
  sender_have_qtys: number[];
  receiver_have_ids: string[];
  receiver_have_qtys: number[];
};

type EvidenceRow = {
  id: string;
  photo_url: string;
  position: number;
  taken_at: string;
};

type GoodsRow = {
  id: string;
  title: string;
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

export default async function ApprovePage({
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

  const { data: row } = await supabase
    .from("proposals")
    .select(
      `id, sender_id, receiver_id, status,
       evidence_photo_url, evidence_taken_at,
       approved_by_sender, approved_by_receiver,
       meetup_place_name,
       sender_have_ids, sender_have_qtys,
       receiver_have_ids, receiver_have_qtys`,
    )
    .eq("id", id)
    .maybeSingle();
  if (!row) notFound();
  const p = row as Row;
  if (p.sender_id !== user.id && p.receiver_id !== user.id) notFound();

  if (p.status === "completed") redirect(`/transactions/${id}/rate`);

  // 複数枚証跡を fetch
  const { data: photoRows } = await supabase
    .from("proposal_evidence_photos")
    .select("id, photo_url, position, taken_at")
    .eq("proposal_id", id)
    .order("position", { ascending: true });
  const photos = ((photoRows as EvidenceRow[]) ?? []).map((r) => ({
    id: r.id,
    photoUrl: r.photo_url,
    position: r.position,
    takenAt: r.taken_at,
  }));

  // 1 枚も無ければ撮影画面に
  if (photos.length === 0) redirect(`/transactions/${id}/capture`);

  // partner
  const isMeSender = p.sender_id === user.id;
  const partnerId = isMeSender ? p.receiver_id : p.sender_id;
  const { data: partner } = await supabase
    .from("users")
    .select("handle, display_name")
    .eq("id", partnerId)
    .maybeSingle();

  // items
  const allIds = [...p.sender_have_ids, ...p.receiver_have_ids].filter(
    (x, i, a) => a.indexOf(x) === i,
  );
  const invMap = new Map<string, { label: string; goodsTypeName: string | null }>();
  if (allIds.length > 0) {
    const { data: invs } = await supabase
      .from("goods_inventory")
      .select(
        "id, title, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .in("id", allIds);
    if (invs) {
      for (const r of invs as GoodsRow[]) {
        const charName = pickName(r.character);
        const groupName = pickName(r.group);
        invMap.set(r.id, {
          label: charName ?? groupName ?? r.title,
          goodsTypeName: pickName(r.goods_type),
        });
      }
    }
  }

  function summary(ids: string[], qtys: number[]): string {
    if (!ids.length) return "—";
    return ids
      .map((id, i) => {
        const inv = invMap.get(id);
        return `${inv?.label ?? "?"} ×${qtys[i] ?? 1}`;
      })
      .join(" / ");
  }
  function letters(ids: string[], qtys: number[]): string[] {
    const out: string[] = [];
    for (let i = 0; i < ids.length; i++) {
      const inv = invMap.get(ids[i]);
      const ch = inv?.label?.[0] ?? "?";
      for (let k = 0; k < (qtys[i] ?? 1); k++) out.push(ch);
    }
    return out;
  }

  const partnerHandle = partner?.handle ?? "?";
  const myApproved = isMeSender ? p.approved_by_sender : p.approved_by_receiver;
  const partnerApproved = isMeSender
    ? p.approved_by_receiver
    : p.approved_by_sender;

  // sender 側 = 「相手」or「あなた」を判定
  // 表示は両者を独立行で
  const data: ApproveData = {
    proposalId: p.id,
    photos,
    photoTakenAt: p.evidence_taken_at ?? null,
    placeName: p.meetup_place_name ?? null,
    rows: [
      {
        side: isMeSender ? "them" : "me",
        handle: isMeSender ? partnerHandle : "あなた",
        desc: summary(p.receiver_have_ids, p.receiver_have_qtys),
        letters: letters(p.receiver_have_ids, p.receiver_have_qtys),
      },
      {
        side: isMeSender ? "me" : "them",
        handle: isMeSender ? "あなた" : partnerHandle,
        desc: summary(p.sender_have_ids, p.sender_have_qtys),
        letters: letters(p.sender_have_ids, p.sender_have_qtys),
      },
    ],
    partnerHandle,
    myApproved,
    partnerApproved,
  };

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack title="取引完了の確認" backHref={`/transactions/${id}`} />
      <ApproveView data={data} />
    </main>
  );
}
