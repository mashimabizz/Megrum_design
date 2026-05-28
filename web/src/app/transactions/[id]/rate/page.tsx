import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { RateView, type RateData } from "./RateView";

export const metadata = {
  title: "取引完了 — Megrum",
};

type Row = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
};

export default async function RatePage({
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
    .select(`id, sender_id, receiver_id, status`)
    .eq("id", id)
    .maybeSingle();
  if (!row) notFound();
  const p = row as Row;
  if (p.sender_id !== user.id && p.receiver_id !== user.id) notFound();
  if (p.status !== "completed") redirect(`/transactions/${id}`);

  // 既に評価済か
  const { data: existing } = await supabase
    .from("user_evaluations")
    .select("id, stars, comment")
    .eq("proposal_id", id)
    .eq("rater_id", user.id)
    .maybeSingle();

  // 相手 user
  const isMeSender = p.sender_id === user.id;
  const partnerId = isMeSender ? p.receiver_id : p.sender_id;
  const { data: partner } = await supabase
    .from("users")
    .select("handle, display_name")
    .eq("id", partnerId)
    .maybeSingle();

  const data: RateData = {
    proposalId: p.id,
    partnerHandle: partner?.handle ?? "?",
    partnerDisplayName: partner?.display_name ?? "?",
    alreadyRated: !!existing,
    myStars: existing?.stars ?? null,
    myComment: existing?.comment ?? null,
  };

  return <RateView data={data} />;
}
