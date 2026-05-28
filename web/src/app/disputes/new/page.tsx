import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { DisputeNewForm } from "./DisputeNewForm";

export const metadata = {
  title: "取引について報告 — Megrum",
};

type ProposalRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  meetup_start_at: string | null;
  meetup_end_at: string | null;
  meetup_place_name: string | null;
  evidence_photo_url: string | null;
};

export default async function DisputeNewPage({
  searchParams,
}: {
  searchParams: Promise<{ proposalId?: string }>;
}) {
  const { proposalId } = await searchParams;
  if (!proposalId) notFound();

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: row } = await supabase
    .from("proposals")
    .select(
      `id, sender_id, receiver_id, status,
       meetup_start_at, meetup_end_at, meetup_place_name, evidence_photo_url`,
    )
    .eq("id", proposalId)
    .maybeSingle();
  if (!row) notFound();
  const p = row as ProposalRow;
  if (p.sender_id !== user.id && p.receiver_id !== user.id) notFound();
  if (p.status !== "agreed" && p.status !== "completed") {
    redirect(`/transactions/${p.id}`);
  }

  const partnerId = p.sender_id === user.id ? p.receiver_id : p.sender_id;
  const { data: partner } = await supabase
    .from("users")
    .select("handle, display_name")
    .eq("id", partnerId)
    .maybeSingle();

  // 既存 open dispute あれば詳細にリダイレクト
  const { data: existing } = await supabase
    .from("disputes")
    .select("id")
    .eq("proposal_id", p.id)
    .neq("status", "closed")
    .maybeSingle();
  if (existing) {
    redirect(`/disputes/${existing.id}`);
  }

  // C-3 で撮影した取引証跡を auto-attach 用に取得
  const { data: evidencePhotos } = await supabase
    .from("proposal_evidence_photos")
    .select("id, photo_url, position, taken_at")
    .eq("proposal_id", p.id)
    .order("position", { ascending: true });

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title="取引について報告"
        sub="該当する項目を1つ選んでください"
        backHref={`/transactions/${p.id}`}
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-3">
        <DisputeNewForm
          proposalId={p.id}
          partnerHandle={partner?.handle ?? "?"}
          partnerDisplayName={partner?.display_name ?? "?"}
          meetupSummary={
            p.meetup_start_at && p.meetup_end_at && p.meetup_place_name
              ? `${p.meetup_place_name} ・ ${formatRange(p.meetup_start_at, p.meetup_end_at)}`
              : p.meetup_place_name ?? "—"
          }
          autoAttachedPhotoUrls={(evidencePhotos ?? []).map(
            (e) => e.photo_url as string,
          )}
        />
      </div>
    </main>
  );
}

function formatRange(startIso: string, endIso: string): string {
  const s = new Date(startIso);
  const e = new Date(endIso);
  const dateFmt = (d: Date) =>
    `${d.getMonth() + 1}/${d.getDate()}`;
  const timeFmt = (d: Date) =>
    `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  return `${dateFmt(s)} ${timeFmt(s)}〜${timeFmt(e)}`;
}
