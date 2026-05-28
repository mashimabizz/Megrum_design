import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { HeaderBack } from "@/components/auth/HeaderBack";
import { autoExpireProposals } from "@/lib/expire";
import { ChatView, type ChatProposal, type ChatMessage } from "./ChatView";
import type { CalEvent } from "@/components/schedule/CalendarOverlayModal";

export const metadata = {
  title: "取引チャット — Megrum",
};

type ProposalRaw = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  cash_offer: boolean;
  cash_amount: number | null;
  sender_have_ids: string[];
  sender_have_qtys: number[];
  receiver_have_ids: string[];
  receiver_have_qtys: number[];
  meetup_start_at: string | null;
  meetup_end_at: string | null;
  meetup_place_name: string | null;
  meetup_lat: number | null;
  meetup_lng: number | null;
  evidence_photo_url: string | null;
  approved_by_sender: boolean;
  approved_by_receiver: boolean;
  agreed_by_sender: boolean;
  agreed_by_receiver: boolean;
  expose_calendar: boolean;
  message: string | null;
  created_at: string;
  expires_at: string | null;
  extension_count: number;
};

type GoodsRow = {
  id: string;
  title: string;
  photo_urls: string[] | null;
  group: { name: string } | { name: string }[] | null;
  character: { name: string } | { name: string }[] | null;
  goods_type: { name: string } | { name: string }[] | null;
};

type MessageRaw = {
  id: string;
  proposal_id: string;
  sender_id: string;
  message_type:
    | "text"
    | "photo"
    | "outfit_photo"
    | "location"
    | "arrival_status"
    | "system";
  body: string | null;
  photo_url: string | null;
  location_lat: number | null;
  location_lng: number | null;
  location_label: string | null;
  meta: Record<string, unknown> | null;
  created_at: string;
};

function pickName(
  v: { name: string } | { name: string }[] | null,
): string | null {
  if (!v) return null;
  return Array.isArray(v) ? v[0]?.name ?? null : v.name;
}

export default async function TransactionChatPage({
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

  // iter78-E: 期限切れを自動的に expired に
  await autoExpireProposals(supabase, user.id);

  // proposal を fetch
  const { data: proposalRow } = await supabase
    .from("proposals")
    .select(
      `id, sender_id, receiver_id, status, cash_offer, cash_amount,
       sender_have_ids, sender_have_qtys, receiver_have_ids, receiver_have_qtys,
       meetup_start_at, meetup_end_at, meetup_place_name, meetup_lat, meetup_lng,
       evidence_photo_url, approved_by_sender, approved_by_receiver,
       agreed_by_sender, agreed_by_receiver,
       expose_calendar, message, created_at,
       expires_at, extension_count`,
    )
    .eq("id", id)
    .maybeSingle();
  if (!proposalRow) notFound();
  const p = proposalRow as ProposalRaw;
  if (p.sender_id !== user.id && p.receiver_id !== user.id) notFound();
  const isMeSender = p.sender_id === user.id;

  // 合意済 or ネゴ中 / 完了済 はチャット可。
  // sent は送信者の「相手待ち」詳細としてだけ許可し、受信者は応答用の打診詳細へ回す。
  const canOpenTransactionDetail =
    ["agreed", "negotiating", "agreement_one_side", "completed"].includes(
      p.status,
    ) ||
    (p.status === "sent" && isMeSender);
  if (!canOpenTransactionDetail) {
    redirect(`/proposals/${id}`);
  }

  // iter68.1: 撮影済→自動 redirect は撤廃。
  // ユーザーは chat 画面に留まり、system message「✓ 取引証跡が届きました」をタップで approve に遷移。
  // 完了済かつ未評価のみ rate に redirect（評価のリマインド）
  if (p.status === "completed") {
    const { data: existingEval } = await supabase
      .from("user_evaluations")
      .select("id")
      .eq("proposal_id", id)
      .eq("rater_id", user.id)
      .maybeSingle();
    if (!existingEval) {
      redirect(`/transactions/${id}/rate`);
    }
  }

  const partnerId = isMeSender ? p.receiver_id : p.sender_id;

  // 相手 user（iter122: avatar_url も取得）
  const { data: partner } = await supabase
    .from("users")
    .select("id, handle, display_name, primary_area, avatar_url")
    .eq("id", partnerId)
    .maybeSingle();

  // 提示物アイテム
  const allInvIds = [
    ...p.sender_have_ids,
    ...p.receiver_have_ids,
  ].filter((x, i, a) => a.indexOf(x) === i);
  const invById = new Map<
    string,
    { label: string; goodsTypeName: string | null; photoUrl: string | null }
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
        const charName = pickName(r.character);
        const groupName = pickName(r.group);
        invById.set(r.id, {
          label: charName ?? groupName ?? r.title,
          goodsTypeName: pickName(r.goods_type),
          photoUrl: (r.photo_urls && r.photo_urls[0]) ?? null,
        });
      }
    }
  }

  // ユーザー視点：受け取る ⇄ 出す
  // 自分が sender なら sender_have が「私の譲」、receiver_have が「私が受け取る」
  const myGiveIds = isMeSender ? p.sender_have_ids : p.receiver_have_ids;
  const myGiveQtys = isMeSender ? p.sender_have_qtys : p.receiver_have_qtys;
  const myReceiveIds = isMeSender ? p.receiver_have_ids : p.sender_have_ids;
  const myReceiveQtys = isMeSender
    ? p.receiver_have_qtys
    : p.sender_have_qtys;

  function toItems(ids: string[], qtys: number[]) {
    return ids.map((id, i) => {
      const inv = invById.get(id);
      return {
        id,
        label: inv?.label ?? "?",
        goodsTypeName: inv?.goodsTypeName ?? null,
        photoUrl: inv?.photoUrl ?? null,
        qty: qtys[i] ?? 1,
      };
    });
  }

  const proposal: ChatProposal = {
    id: p.id,
    status: p.status as ChatProposal["status"],
    cashOffer: p.cash_offer,
    cashAmount: p.cash_amount,
    myGiveItems: toItems(myGiveIds, myGiveQtys),
    myReceiveItems: p.cash_offer && !isMeSender
      ? [] // 相手が cash 提案 → 私が金銭を受け取る（このパターンは MVP は通常出ない）
      : toItems(myReceiveIds, myReceiveQtys),
    meetupStartAt: p.meetup_start_at,
    meetupEndAt: p.meetup_end_at,
    meetupPlaceName: p.meetup_place_name,
    meetupLat: p.meetup_lat,
    meetupLng: p.meetup_lng,
    partner: {
      id: partnerId,
      handle: partner?.handle ?? "?",
      displayName: partner?.display_name ?? "?",
      primaryArea: partner?.primary_area ?? null,
      avatarUrl: (partner?.avatar_url as string | null) ?? null,
    },
    me: {
      id: user.id,
    },
    hasEvidence: !!p.evidence_photo_url,
    evidencePhotoCount: 0, // 後で更新
    // iter73: 自分視点の合意フラグ（agreed_by_* がネゴ合意 / approved_by_* は完了承認）
    myAgreed: isMeSender ? p.agreed_by_sender : p.agreed_by_receiver,
    partnerAgreed: isMeSender ? p.agreed_by_receiver : p.agreed_by_sender,
    iAmReceiver: !isMeSender,
    expiresAt: p.expires_at,
    extensionCount: p.extension_count ?? 0,
    openDispute: null, // 後で更新
  };

  // iter79-C: open dispute（同 proposal）を fetch して proposal に注入
  const { data: openDisputeRow } = await supabase
    .from("disputes")
    .select("id, ticket_no, status")
    .eq("proposal_id", p.id)
    .neq("status", "closed")
    .maybeSingle();
  if (openDisputeRow) {
    proposal.openDispute = {
      id: openDisputeRow.id as string,
      ticketNo: openDisputeRow.ticket_no as string,
    };
  }

  // 証跡写真（複数枚）
  const { data: evidencePhotos } = await supabase
    .from("proposal_evidence_photos")
    .select("id, photo_url, position, taken_at, taken_by")
    .eq("proposal_id", id)
    .order("position", { ascending: true });
  proposal.evidencePhotoCount = evidencePhotos?.length ?? 0;
  if (proposal.evidencePhotoCount > 0) {
    proposal.hasEvidence = true;
  }

  // iter70-B：自分 + 相手の AW + schedules を fetch（カレンダー重ね表示用）
  // 相手側は RLS の "Calendar disclosure: counterpart can read" が
  // expose_calendar=true & status in (sent/negotiating/agreement_one_side/agreed) で
  // 許可されているときのみ読める。
  const horizonStart = new Date();
  const horizonEnd = new Date();
  horizonEnd.setDate(horizonEnd.getDate() + 14);
  const horizonStartIso = horizonStart.toISOString();
  const horizonEndIso = horizonEnd.toISOString();

  const [myAwResult, partnerAwResult, mySchedulesResult, partnerSchedulesResult] =
    await Promise.all([
      supabase
        .from("activity_windows")
        .select("id, venue, event_name, eventless, start_at, end_at, note")
        .eq("user_id", user.id)
        .eq("status", "enabled")
        .lte("start_at", horizonEndIso)
        .gte("end_at", horizonStartIso)
        .order("start_at", { ascending: true }),
      supabase
        .from("activity_windows")
        .select("id, venue, event_name, eventless, start_at, end_at, note")
        .eq("user_id", partnerId)
        .eq("status", "enabled")
        .lte("start_at", horizonEndIso)
        .gte("end_at", horizonStartIso)
        .order("start_at", { ascending: true }),
      supabase
        .from("schedules")
        .select("id, title, start_at, end_at, note")
        .eq("user_id", user.id)
        .lte("start_at", horizonEndIso)
        .gte("end_at", horizonStartIso)
        .order("start_at", { ascending: true }),
      supabase
        .from("schedules")
        .select("id, title, start_at, end_at, note")
        .eq("user_id", partnerId)
        .lte("start_at", horizonEndIso)
        .gte("end_at", horizonStartIso)
        .order("start_at", { ascending: true }),
    ]);

  type AwRow = {
    id: string;
    venue: string;
    event_name: string | null;
    eventless: boolean;
    start_at: string;
    end_at: string;
    note: string | null;
  };
  type ScheduleRow = {
    id: string;
    title: string;
    start_at: string;
    end_at: string;
    note: string | null;
  };

  const calendarEvents: CalEvent[] = [];
  const myAws = (myAwResult.data as AwRow[] | null) ?? [];
  for (const a of myAws) {
    calendarEvents.push({
      id: `aw-me-${a.id}`,
      kind: "aw",
      side: "me",
      title: a.event_name ?? (a.eventless ? "合流可（フリー）" : a.venue),
      startAt: a.start_at,
      endAt: a.end_at,
      venue: a.venue,
      note: a.note,
    });
  }
  const mySchedules = (mySchedulesResult.data as ScheduleRow[] | null) ?? [];
  for (const s of mySchedules) {
    calendarEvents.push({
      id: `sch-me-${s.id}`,
      kind: "schedule",
      side: "me",
      title: s.title,
      startAt: s.start_at,
      endAt: s.end_at,
      note: s.note,
    });
  }
  const partnerExposed = p.expose_calendar;
  if (partnerExposed) {
    const partnerAws = (partnerAwResult.data as AwRow[] | null) ?? [];
    for (const a of partnerAws) {
      calendarEvents.push({
        id: `aw-partner-${a.id}`,
        kind: "aw",
        side: "partner",
        title: a.event_name ?? (a.eventless ? "合流可（フリー）" : a.venue),
        startAt: a.start_at,
        endAt: a.end_at,
        venue: a.venue,
        note: a.note,
      });
    }
    const partnerSchedules =
      (partnerSchedulesResult.data as ScheduleRow[] | null) ?? [];
    for (const s of partnerSchedules) {
      calendarEvents.push({
        id: `sch-partner-${s.id}`,
        kind: "schedule",
        side: "partner",
        title: s.title,
        startAt: s.start_at,
        endAt: s.end_at,
        note: s.note,
      });
    }
  }

  // メッセージ一覧
  const { data: msgs } = await supabase
    .from("messages")
    .select(
      `id, proposal_id, sender_id, message_type, body, photo_url,
       location_lat, location_lng, location_label, meta, created_at`,
    )
    .eq("proposal_id", id)
    .order("created_at", { ascending: true });

  const messages: ChatMessage[] = ((msgs as MessageRaw[]) ?? []).map((m) => ({
    id: m.id,
    senderId: m.sender_id,
    isMine: m.sender_id === user.id,
    type: m.message_type,
    body: m.body,
    photoUrl: m.photo_url,
    lat: m.location_lat,
    lng: m.location_lng,
    locationLabel: m.location_label,
    meta: m.meta,
    createdAt: m.created_at,
  }));

  // iter71-B：打診時に送信した proposal.message を最初のチャットメッセージとして
  // 仮想挿入（DB には書かないが、UI 上は通常のメッセージバブルで先頭表示）
  if (p.message?.trim()) {
    messages.unshift({
      id: `proposal-message-${p.id}`,
      senderId: p.sender_id,
      isMine: p.sender_id === user.id,
      type: "text",
      body: p.message,
      photoUrl: null,
      lat: null,
      lng: null,
      locationLabel: null,
      meta: { virtual: "proposal_message" },
      createdAt: p.created_at,
    });
  }

  // 双方の到着状態（最新の arrival_status を見る）
  function latestArrival(
    forUserId: string,
  ): "enroute" | "arrived" | "left" | null {
    const last = messages
      .filter((m) => m.type === "arrival_status" && m.senderId === forUserId)
      .pop();
    if (!last) return null;
    const status = (last.meta as { status?: string } | null)?.status;
    if (status === "enroute" || status === "arrived" || status === "left")
      return status;
    return null;
  }

  // 服装写真の最新（双方）
  function latestOutfit(forUserId: string): string | null {
    const last = messages
      .filter((m) => m.type === "outfit_photo" && m.senderId === forUserId)
      .pop();
    return last?.photoUrl ?? null;
  }

  return (
    <main className="animate-route-slide-in-right flex flex-1 flex-col bg-[#fbf9fc]">
      <HeaderBack
        title={`@${proposal.partner.handle}`}
        sub={
          (latestArrival(proposal.partner.id) === "arrived"
            ? "● 会場到着"
            : latestArrival(proposal.partner.id) === "enroute"
              ? "向かっています"
              : "未到着") +
          (proposal.partner.primaryArea
            ? ` ・${proposal.partner.primaryArea}`
            : "")
        }
        backHref="/transactions"
      />
      <ChatView
        proposal={proposal}
        messages={messages}
        myArrival={latestArrival(user.id)}
        partnerArrival={latestArrival(proposal.partner.id)}
        myOutfitPhoto={latestOutfit(user.id)}
        partnerOutfitPhoto={latestOutfit(proposal.partner.id)}
        calendarEvents={calendarEvents}
        partnerCalendarExposed={partnerExposed}
      />
    </main>
  );
}
