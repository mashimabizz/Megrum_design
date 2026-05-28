import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { CancelOrLateForm } from "./CancelOrLateForm";

export const metadata = {
  title: "取引キャンセル / 遅刻通知 — Megrum",
};

type ProposalRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  meetup_start_at: string | null;
  meetup_place_name: string | null;
};

export default async function CancelOrLatePage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ kind?: "cancel" | "late" }>;
}) {
  const { id } = await params;
  const { kind = "cancel" } = await searchParams;
  if (kind !== "cancel" && kind !== "late") notFound();

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: row } = await supabase
    .from("proposals")
    .select(
      "id, sender_id, receiver_id, status, meetup_start_at, meetup_place_name",
    )
    .eq("id", id)
    .maybeSingle();
  if (!row) notFound();
  const p = row as ProposalRow;
  if (p.sender_id !== user.id && p.receiver_id !== user.id) notFound();
  if (p.status !== "agreed") {
    redirect(`/transactions/${p.id}`);
  }

  const partnerId = p.sender_id === user.id ? p.receiver_id : p.sender_id;
  const { data: partner } = await supabase
    .from("users")
    .select("handle, display_name")
    .eq("id", partnerId)
    .maybeSingle();

  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title={kind === "cancel" ? "取引をキャンセル" : "遅刻を連絡"}
        sub={
          kind === "cancel"
            ? "相手と合意の上で取り消します"
            : "到着が遅れる旨を相手に通知"
        }
        backHref={`/transactions/${p.id}`}
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-3">
        <CancelOrLateForm
          proposalId={p.id}
          kind={kind}
          partnerHandle={partner?.handle ?? "?"}
          partnerDisplayName={partner?.display_name ?? "?"}
          meetupStartAt={p.meetup_start_at}
          meetupPlaceName={p.meetup_place_name}
        />
      </div>
    </main>
  );
}
