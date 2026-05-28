import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { CaptureView, type EvidencePhoto } from "./CaptureView";

export const metadata = {
  title: "取引証跡を撮影 — Megrum",
};

type Row = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  sender_have_qtys: number[] | null;
  receiver_have_qtys: number[] | null;
  meetup_place_name: string | null;
};

type EvidenceRow = {
  id: string;
  photo_url: string;
  position: number;
  taken_at: string;
  taken_by: string | null;
};

export default async function CapturePage({
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
      "id, sender_id, receiver_id, status, sender_have_qtys, receiver_have_qtys, meetup_place_name",
    )
    .eq("id", id)
    .maybeSingle();
  if (!row) notFound();
  const p = row as Row;
  if (p.sender_id !== user.id && p.receiver_id !== user.id) notFound();

  if (p.status !== "agreed") {
    // 完了済はチャットに戻す
    redirect(`/transactions/${id}`);
  }

  const { data: photoRows } = await supabase
    .from("proposal_evidence_photos")
    .select("id, photo_url, position, taken_at, taken_by")
    .eq("proposal_id", id)
    .order("position", { ascending: true });

  const photos: EvidencePhoto[] = ((photoRows as EvidenceRow[]) ?? []).map((r) => ({
    id: r.id,
    photoUrl: r.photo_url,
    position: r.position,
    takenAt: r.taken_at,
    isMine: r.taken_by === user.id,
  }));

  const isMeSender = p.sender_id === user.id;
  const myQtys = isMeSender ? p.sender_have_qtys : p.receiver_have_qtys;
  const theirQtys = isMeSender ? p.receiver_have_qtys : p.sender_have_qtys;
  const myCount = (myQtys ?? []).reduce((s, q) => s + (q || 0), 0);
  const theirCount = (theirQtys ?? []).reduce((s, q) => s + (q || 0), 0);

  return (
    <CaptureView
      proposalId={p.id}
      myCount={myCount}
      theirCount={theirCount}
      placeName={p.meetup_place_name ?? "—"}
      photos={photos}
    />
  );
}
