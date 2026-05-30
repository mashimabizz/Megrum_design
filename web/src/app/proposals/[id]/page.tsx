import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { autoExpireProposals } from "@/lib/expire";
import { isUuid, participantOrFilter } from "@/lib/supabaseFilters";
import { ProposalDetailView, type ProposalDetail } from "./ProposalDetailView";

export const metadata = {
  title: "打診詳細 — Megrum",
};

type ProposalRaw = {
  id: string;
  sender_id: string;
  receiver_id: string;
  match_type: "perfect" | "forward" | "backward";
  sender_have_ids: string[];
  sender_have_qtys: number[];
  receiver_have_ids: string[];
  receiver_have_qtys: number[];
  message: string | null;
  message_tone: "standard" | "casual" | "polite" | null;
  status: string;
  agreed_by_sender: boolean;
  agreed_by_receiver: boolean;
  rejected_template: string | null;
  meetup_start_at: string | null;
  meetup_end_at: string | null;
  meetup_place_name: string | null;
  meetup_lat: number | null;
  meetup_lng: number | null;
  meetup_candidates: unknown;
  expose_calendar: boolean;
  cash_offer: boolean;
  cash_amount: number | null;
  listing_id: string | null;
  expires_at: string | null;
  last_action_at: string | null;
  created_at: string;
  extension_count: number;
};

type MeetupCandidateDetail = {
  startAt: string;
  endAt: string;
  placeName: string;
  lat: number;
  lng: number;
  mode: "today" | "scheduled";
};

type GoodsRow = {
  id: string;
  title: string;
  photo_urls: string[] | null;
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

function parseMeetupCandidates(p: ProposalRaw): MeetupCandidateDetail[] {
  const raw = p.meetup_candidates;
  if (Array.isArray(raw)) {
    const parsed = raw
      .slice(0, 3)
      .map((candidate): MeetupCandidateDetail | null => {
        if (!candidate || typeof candidate !== "object") return null;
        const c = candidate as Record<string, unknown>;
        if (
          typeof c.startAt !== "string" ||
          typeof c.endAt !== "string" ||
          typeof c.placeName !== "string" ||
          typeof c.lat !== "number" ||
          typeof c.lng !== "number"
        ) {
          return null;
        }
        return {
          startAt: c.startAt,
          endAt: c.endAt,
          placeName: c.placeName,
          lat: c.lat,
          lng: c.lng,
          mode: c.mode === "today" ? "today" : "scheduled",
        };
      })
      .filter((candidate): candidate is MeetupCandidateDetail => !!candidate);
    if (parsed.length > 0) return parsed;
  }

  if (
    p.meetup_start_at &&
    p.meetup_end_at &&
    p.meetup_place_name &&
    p.meetup_lat != null &&
    p.meetup_lng != null
  ) {
    return [
      {
        startAt: p.meetup_start_at,
        endAt: p.meetup_end_at,
        placeName: p.meetup_place_name,
        lat: p.meetup_lat,
        lng: p.meetup_lng,
        mode: "scheduled",
      },
    ];
  }

  return [];
}

function getMissingProposalColumn(error: {
  code?: string;
  message?: string;
} | null): string | null {
  const message = error?.message ?? "";
  if (
    error?.code !== "PGRST204" &&
    !message.includes("schema cache")
  ) {
    return null;
  }
  const match = message.match(
    /Could not find the '([^']+)' column of 'proposals'/,
  );
  return match?.[1] ?? null;
}

export default async function ProposalDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  if (!isUuid(id)) notFound();
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // iter78-E: 期限切れを自動的に expired に
  await autoExpireProposals(supabase, user.id);

  const proposalFields = [
    "id",
    "sender_id",
    "receiver_id",
    "match_type",
    "sender_have_ids",
    "sender_have_qtys",
    "receiver_have_ids",
    "receiver_have_qtys",
    "message",
    "message_tone",
    "status",
    "agreed_by_sender",
    "agreed_by_receiver",
    "rejected_template",
    "meetup_start_at",
    "meetup_end_at",
    "meetup_place_name",
    "meetup_lat",
    "meetup_lng",
    "meetup_candidates",
    "expose_calendar",
    "cash_offer",
    "cash_amount",
    "listing_id",
    "expires_at",
    "last_action_at",
    "created_at",
    "extension_count",
  ];
  const selectableFields = [...proposalFields];
  let row: Record<string, unknown> | null = null;
  let rowError: { code?: string; message?: string } | null = null;
  for (let attempt = 0; attempt < proposalFields.length; attempt += 1) {
    const result = await supabase
      .from("proposals")
      .select(selectableFields.join(", "))
      .eq("id", id)
      .maybeSingle();
    row = (result.data as Record<string, unknown> | null) ?? null;
    rowError = result.error;
    const missingColumn = getMissingProposalColumn(rowError);
    if (missingColumn && selectableFields.includes(missingColumn)) {
      selectableFields.splice(selectableFields.indexOf(missingColumn), 1);
      continue;
    }
    break;
  }

  if (!row) notFound();
  const p = {
    meetup_candidates: [],
    rejected_template: null,
    extension_count: 0,
    meetup_lat: null,
    meetup_lng: null,
    ...row,
  } as ProposalRaw;

  // 自分が sender or receiver のみアクセス可
  if (p.sender_id !== user.id && p.receiver_id !== user.id) notFound();

  const isReceiver = p.receiver_id === user.id;

  // 相手 user 情報
  const partnerId = isReceiver ? p.sender_id : p.receiver_id;
  const { data: partner } = await supabase
    .from("users")
    .select("id, handle, display_name, primary_area")
    .eq("id", partnerId)
    .maybeSingle();

  // iter77-B: 相手の評価サマリ / 取引回数 / AW 一致判定 / 直近の服装写真
  const [
    { data: ratingsRows },
    { count: completedTradesCount },
    { data: partnerAws },
    { data: latestOutfitMsg },
  ] = await Promise.all([
    supabase.from("user_evaluations").select("stars").eq("ratee_id", partnerId),
    supabase
      .from("proposals")
      .select("id", { count: "exact", head: true })
      .or(participantOrFilter("sender_id", "receiver_id", partnerId))
      .eq("status", "completed"),
    // 自分の AW（受信者なら自分側、送信者でも自分の AW）と提案 meetup の重なり判定用
    p.meetup_start_at && p.meetup_end_at
      ? supabase
          .from("activity_windows")
          .select("id, start_at, end_at")
          .eq("user_id", user.id)
          .eq("status", "enabled")
          .lte("start_at", p.meetup_end_at)
          .gte("end_at", p.meetup_start_at)
          .limit(1)
      : Promise.resolve({ data: null }),
    // 相手の最新の服装写真（合意済以降のチャットから抽出）
    supabase
      .from("messages")
      .select("photo_url, created_at")
      .eq("proposal_id", p.id)
      .eq("sender_id", partnerId)
      .eq("message_type", "outfit_photo")
      .order("created_at", { ascending: false })
      .limit(1),
  ]);

  const starValues = (ratingsRows ?? []).map(
    (r: { stars: number }) => r.stars,
  );
  const ratingAvg =
    starValues.length > 0
      ? starValues.reduce((a, b) => a + b, 0) / starValues.length
      : null;
  const ratingCount = starValues.length;
  const tradeCount = completedTradesCount ?? 0;
  const matchAw = (partnerAws?.length ?? 0) > 0;
  const partnerOutfitPhoto =
    latestOutfitMsg && latestOutfitMsg.length > 0
      ? (latestOutfitMsg[0].photo_url as string | null)
      : null;
  const meetupCandidates = parseMeetupCandidates(p);

  // 提示物アイテムの詳細を fetch
  const allInvIds = [
    ...p.sender_have_ids,
    ...p.receiver_have_ids,
  ].filter((x, i, a) => a.indexOf(x) === i);

  const invById = new Map<
    string,
    { title: string; photoUrl: string | null; label: string; groupName: string | null; characterName: string | null; goodsTypeName: string | null }
  >();
  if (allInvIds.length > 0) {
    const { data: invs } = await supabase
      .from("goods_inventory")
      .select(
        "id, title, photo_urls, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .in("id", allInvIds);
    if (invs) {
      for (const r of invs as GoodsRow[]) {
        const groupName = pickName(r.group);
        const charName = pickName(r.character);
        const typeName = pickName(r.goods_type);
        invById.set(r.id, {
          title: r.title,
          photoUrl: (r.photo_urls && r.photo_urls[0]) ?? null,
          label: charName ?? groupName ?? r.title,
          groupName,
          characterName: charName,
          goodsTypeName: typeName,
        });
      }
    }
  }

  function toItems(
    ids: string[],
    qtys: number[],
  ): ProposalDetail["senderItems"] {
    return ids.map((id, i) => {
      const inv = invById.get(id);
      return {
        id,
        label: inv?.label ?? "?",
        title: inv?.title ?? "?",
        photoUrl: inv?.photoUrl ?? null,
        groupName: inv?.groupName ?? null,
        characterName: inv?.characterName ?? null,
        goodsTypeName: inv?.goodsTypeName ?? null,
        qty: qtys[i] ?? 1,
      };
    });
  }

  const detail: ProposalDetail = {
    id: p.id,
    isReceiver,
    isSender: !isReceiver,
    matchType: p.match_type,
    status: p.status as ProposalDetail["status"],
    senderItems: toItems(p.sender_have_ids, p.sender_have_qtys),
    receiverItems: toItems(p.receiver_have_ids, p.receiver_have_qtys),
    message: p.message ?? "",
    messageTone: p.message_tone,
    meetupStartAt: p.meetup_start_at,
    meetupEndAt: p.meetup_end_at,
    meetupPlaceName: p.meetup_place_name,
    meetupLat: p.meetup_lat,
    meetupLng: p.meetup_lng,
    meetupCandidates,
    exposeCalendar: p.expose_calendar,
    cashOffer: p.cash_offer,
    cashAmount: p.cash_amount,
    listingId: p.listing_id,
    expiresAt: p.expires_at,
    lastActionAt: p.last_action_at,
    createdAt: p.created_at,
    rejectedTemplate: p.rejected_template,
    partner: {
      id: partnerId,
      handle: partner?.handle ?? "?",
      displayName: partner?.display_name ?? "?",
      primaryArea: partner?.primary_area ?? null,
    },
    partnerRatingAvg: ratingAvg,
    partnerRatingCount: ratingCount,
    partnerTradeCount: tradeCount,
    matchAw,
    partnerOutfitPhotoUrl: partnerOutfitPhoto,
    extensionCount: p.extension_count ?? 0,
  };

  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title="打診詳細"
        sub={isReceiver ? "受信" : "送信"}
        backHref="/proposals"
      />
      <div className="mx-auto w-full max-w-md flex-1 overflow-y-auto px-5 pb-12 pt-4">
        <ProposalDetailView detail={detail} />
      </div>
    </main>
  );
}
