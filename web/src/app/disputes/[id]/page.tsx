import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { DisputeView, type DisputeDetail } from "./DisputeView";

export const metadata = {
  title: "申告ステータス — Megrum",
};

type DisputeRow = {
  id: string;
  proposal_id: string;
  reporter_id: string;
  respondent_id: string;
  category: "short" | "wrong" | "noshow" | "cancel" | "other";
  fact_memo: string | null;
  evidence_photo_urls: string[];
  status: "submitted" | "response_pending" | "arbitrating" | "closed";
  outcome: "cancelled" | "upheld" | "partial" | null;
  operator_comment: string | null;
  ticket_no: string;
  respondent_deadline_at: string | null;
  operator_deadline_at: string | null;
  submitted_at: string;
  closed_at: string | null;
  respondent_response: "accepted" | "disputed" | "silent" | null;
  respondent_response_text: string | null;
  respondent_evidence_urls: string[];
  respondent_responded_at: string | null;
};

export default async function DisputeDetailPage({
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
    .from("disputes")
    .select(
      `id, proposal_id, reporter_id, respondent_id, category, fact_memo,
       evidence_photo_urls, status, outcome, operator_comment, ticket_no,
       respondent_deadline_at, operator_deadline_at, submitted_at, closed_at,
       respondent_response, respondent_response_text, respondent_evidence_urls,
       respondent_responded_at`,
    )
    .eq("id", id)
    .maybeSingle();
  if (!row) notFound();
  const d = row as DisputeRow;
  if (d.reporter_id !== user.id && d.respondent_id !== user.id) notFound();

  // 取引証跡（auto-attached）も取得して表示
  const { data: evidencePhotos } = await supabase
    .from("proposal_evidence_photos")
    .select("photo_url")
    .eq("proposal_id", d.proposal_id);

  // iter89-D5d: dispute_messages を時系列で取得
  const { data: msgRows } = await supabase
    .from("dispute_messages")
    .select("id, sender_id, sender_role, body, photo_urls, created_at")
    .eq("dispute_id", d.id)
    .order("created_at", { ascending: true });
  const disputeMessages = (msgRows ?? []).map((m) => ({
    id: m.id as string,
    senderRole: m.sender_role as "reporter" | "respondent" | "operator",
    body: m.body as string,
    photoUrls: (m.photo_urls as string[] | null) ?? [],
    createdAt: m.created_at as string,
    isMine: (m.sender_id as string | null) === user.id,
  }));

  const partnerId =
    d.reporter_id === user.id ? d.respondent_id : d.reporter_id;
  const { data: partner } = await supabase
    .from("users")
    .select("handle, display_name")
    .eq("id", partnerId)
    .maybeSingle();

  const detail: DisputeDetail = {
    id: d.id,
    proposalId: d.proposal_id,
    iAmReporter: d.reporter_id === user.id,
    partnerHandle: partner?.handle ?? "?",
    partnerDisplayName: partner?.display_name ?? "?",
    category: d.category,
    factMemo: d.fact_memo,
    extraPhotoUrls: d.evidence_photo_urls ?? [],
    autoAttachedPhotoUrls: (evidencePhotos ?? []).map(
      (e) => e.photo_url as string,
    ),
    status: d.status,
    outcome: d.outcome,
    operatorComment: d.operator_comment,
    ticketNo: d.ticket_no,
    respondentDeadlineAt: d.respondent_deadline_at,
    operatorDeadlineAt: d.operator_deadline_at,
    submittedAt: d.submitted_at,
    closedAt: d.closed_at,
    respondentResponse: d.respondent_response,
    respondentResponseText: d.respondent_response_text,
    respondentEvidenceUrls: d.respondent_evidence_urls ?? [],
    respondentRespondedAt: d.respondent_responded_at,
    messages: disputeMessages,
  };

  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title={
          d.status === "closed" ? "運営からの回答" : "申告ステータス"
        }
        sub={d.ticket_no}
        backHref={`/transactions/${d.proposal_id}`}
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-3">
        <DisputeView detail={detail} />
      </div>
    </main>
  );
}
