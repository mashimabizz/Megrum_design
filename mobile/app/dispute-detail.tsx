import { router, useLocalSearchParams } from "expo-router";
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Image,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useAuth } from "../src/auth/AuthProvider";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type DisputeStatus = "submitted" | "response_pending" | "arbitrating" | "closed";
type Category = "short" | "wrong" | "noshow" | "cancel" | "other";
type ResponseKind = "accepted" | "disputed";

type DisputeRow = {
  id: string;
  proposal_id: string;
  reporter_id: string;
  respondent_id: string;
  category: Category;
  fact_memo: string | null;
  evidence_photo_urls: string[] | null;
  status: DisputeStatus;
  outcome: "cancelled" | "upheld" | "partial" | null;
  operator_comment: string | null;
  ticket_no: string;
  respondent_deadline_at: string | null;
  operator_deadline_at: string | null;
  submitted_at: string;
  closed_at: string | null;
  respondent_response: "accepted" | "disputed" | "silent" | null;
  respondent_response_text: string | null;
  respondent_evidence_urls: string[] | null;
  respondent_responded_at: string | null;
};

type DisputeMessage = {
  id: string;
  senderRole: "reporter" | "respondent" | "operator";
  body: string;
  createdAt: string;
  isMine: boolean;
};

type DisputeData = {
  id: string;
  proposalId: string;
  iAmReporter: boolean;
  partnerHandle: string;
  category: Category;
  factMemo: string | null;
  status: DisputeStatus;
  outcome: "cancelled" | "upheld" | "partial" | null;
  operatorComment: string | null;
  ticketNo: string;
  respondentDeadlineAt: string | null;
  operatorDeadlineAt: string | null;
  submittedAt: string;
  closedAt: string | null;
  respondentResponse: "accepted" | "disputed" | "silent" | null;
  respondentResponseText: string | null;
  photoUrls: string[];
  respondentPhotoUrls: string[];
  messages: DisputeMessage[];
};

const CATEGORY_LABEL: Record<Category, string> = {
  short: "受け取った点数が少ない",
  wrong: "グッズが違う / 状態が悪い",
  noshow: "相手が現れなかった",
  cancel: "合意済みのキャンセル",
  other: "その他",
};

export default function DisputeDetailScreen() {
  const { id: rawId } = useLocalSearchParams<{ id?: string | string[] }>();
  const disputeId = Array.isArray(rawId) ? rawId[0] : rawId;
  const { user, previewMode, exitPreview } = useAuth();
  const [data, setData] = useState<DisputeData | null>(null);
  const [message, setMessage] = useState("");
  const [responseText, setResponseText] = useState("");
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState<"accept" | "dispute" | "message" | null>(null);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    if (!disputeId || !user || previewMode) return;
    setLoading(true);
    setError(null);
    try {
      setData(await fetchDisputeDetail(disputeId, user.id));
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : "読み込みに失敗しました");
    } finally {
      setLoading(false);
    }
  }, [disputeId, previewMode, user]);

  useEffect(() => {
    void reload();
  }, [reload]);

  const canRespond = useMemo(
    () =>
      !!data &&
      !data.iAmReporter &&
      !data.respondentResponse &&
      (data.status === "submitted" || data.status === "response_pending"),
    [data],
  );
  const canSendMessage = data && data.status !== "closed";

  async function respond(kind: ResponseKind) {
    if (!data || !user) return;
    if (kind === "disputed" && !responseText.trim()) {
      setError("反論内容を入力してください");
      return;
    }
    setSubmitting(kind === "accepted" ? "accept" : "dispute");
    setError(null);
    try {
      const result = await respondToDispute({
        disputeId: data.id,
        proposalId: data.proposalId,
        userId: user.id,
        response: kind,
        text: responseText,
      });
      if (result.error) setError(result.error);
      else await reload();
    } finally {
      setSubmitting(null);
    }
  }

  async function sendMessage() {
    if (!data || !user || !message.trim()) return;
    setSubmitting("message");
    setError(null);
    try {
      const result = await sendDisputeMessage({
        disputeId: data.id,
        userId: user.id,
        body: message,
      });
      if (result.error) setError(result.error);
      else {
        setMessage("");
        await reload();
      }
    } finally {
      setSubmitting(null);
    }
  }

  if (previewMode || !user) {
    return (
      <Screen contentStyle={styles.screen}>
        <RouteHeader title="申告ステータス" />
        <View style={styles.card}>
          <Text style={styles.title}>ログインが必要です</Text>
          <Text style={styles.muted}>申告ステータスは実アカウントで確認できます。</Text>
          <PrimaryButton
            onPress={() => {
              exitPreview();
              router.replace("/login");
            }}
          >
            ログインする
          </PrimaryButton>
        </View>
      </Screen>
    );
  }

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader
        title={data?.status === "closed" ? "運営からの回答" : "申告ステータス"}
        subtitle={data?.ticketNo}
      />
      {loading ? <ActivityIndicator color={megrumColors.lavender} /> : null}
      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      {data ? (
        <>
          <View style={styles.statusCard}>
            <View style={styles.statusTop}>
              <Text style={styles.statusBadge}>{statusLabel(data.status)}</Text>
              <Text style={styles.date}>{formatDateTime(data.submittedAt)}</Text>
            </View>
            <Text style={styles.title}>{CATEGORY_LABEL[data.category]}</Text>
            <Text style={styles.muted}>
              {data.iAmReporter ? `相手: @${data.partnerHandle}` : `申告者: @${data.partnerHandle}`}
            </Text>
          </View>

          <View style={styles.card}>
            <Text style={styles.label}>申告内容</Text>
            <Text style={styles.bodyText}>{data.factMemo || "メモはありません"}</Text>
            {data.photoUrls.length > 0 ? (
              <View style={styles.photos}>
                {data.photoUrls.slice(0, 8).map((url, index) => (
                  <Image key={`${url}-${index}`} source={{ uri: url }} style={styles.photo} />
                ))}
              </View>
            ) : null}
          </View>

          {canRespond ? (
            <View style={styles.card}>
              <Text style={styles.label}>回答</Text>
              <Text style={styles.muted}>
                事実を認めると取引はキャンセル処理されます。相違がある場合は反論内容を入力してください。
              </Text>
              <TextInput
                value={responseText}
                onChangeText={setResponseText}
                multiline
                maxLength={4000}
                placeholder="反論内容（反論する場合は必須）"
                placeholderTextColor="rgba(58,50,74,0.36)"
                style={styles.textArea}
              />
              <View style={styles.responseActions}>
                <PrimaryButton
                  variant="secondary"
                  loading={submitting === "accept"}
                  onPress={() => void respond("accepted")}
                  style={styles.responseButton}
                >
                  事実を認める
                </PrimaryButton>
                <PrimaryButton
                  loading={submitting === "dispute"}
                  onPress={() => void respond("disputed")}
                  style={styles.responseButton}
                >
                  反論を提出
                </PrimaryButton>
              </View>
            </View>
          ) : data.respondentResponse ? (
            <View style={styles.card}>
              <Text style={styles.label}>相手側の回答</Text>
              <Text style={styles.bodyText}>
                {data.respondentResponse === "accepted" ? "事実を認めました" : "反論が提出されました"}
              </Text>
              {data.respondentResponseText ? (
                <Text style={styles.muted}>{data.respondentResponseText}</Text>
              ) : null}
            </View>
          ) : null}

          {data.status === "closed" ? (
            <View style={styles.resultCard}>
              <Text style={styles.label}>結果</Text>
              <Text style={styles.title}>{outcomeLabel(data.outcome)}</Text>
              <Text style={styles.muted}>
                {data.operatorComment ?? "運営の確認が完了しました。"}
              </Text>
            </View>
          ) : (
            <View style={styles.card}>
              <Text style={styles.label}>進行状況</Text>
              <TimelineRow done label="申告受付" />
              <TimelineRow done={!!data.respondentResponse} label="相手の回答" />
              <TimelineRow done={data.status === "arbitrating"} label="運営確認" />
              <TimelineRow done={false} label="結果通知" />
            </View>
          )}

          {data.messages.length > 0 ? (
            <View style={styles.card}>
              <Text style={styles.label}>追加のやりとり</Text>
              {data.messages.map((item) => (
                <View
                  key={item.id}
                  style={[styles.messageBubble, item.isMine ? styles.messageMine : null]}
                >
                  <Text style={styles.messageRole}>{roleLabel(item.senderRole)}</Text>
                  <Text style={styles.messageBody}>{item.body}</Text>
                  <Text style={styles.messageTime}>{formatDateTime(item.createdAt)}</Text>
                </View>
              ))}
            </View>
          ) : null}

          {canSendMessage ? (
            <View style={styles.card}>
              <Text style={styles.label}>追加情報</Text>
              <TextInput
                value={message}
                onChangeText={setMessage}
                multiline
                maxLength={4000}
                placeholder="運営に伝えたい補足を入力"
                placeholderTextColor="rgba(58,50,74,0.36)"
                style={styles.textArea}
              />
              <PrimaryButton
                loading={submitting === "message"}
                disabled={!message.trim()}
                onPress={() => void sendMessage()}
              >
                追加情報を送信
              </PrimaryButton>
            </View>
          ) : null}

          <Pressable
            accessibilityRole="button"
            onPress={() =>
              router.push({ pathname: "/transaction-detail", params: { id: data.proposalId } })
            }
            style={styles.backToTrade}
          >
            <Text style={styles.backToTradeText}>取引チャットへ戻る</Text>
          </Pressable>
        </>
      ) : null}
    </Screen>
  );
}

async function fetchDisputeDetail(id: string, userId: string): Promise<DisputeData> {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const { data: row, error } = await supabase
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
  if (error) throw error;
  const dispute = row as DisputeRow | null;
  if (!dispute) throw new Error("申告が見つかりません");
  if (dispute.reporter_id !== userId && dispute.respondent_id !== userId) {
    throw new Error("この申告には参加していません");
  }

  const partnerId = dispute.reporter_id === userId
    ? dispute.respondent_id
    : dispute.reporter_id;
  const [{ data: partner }, { data: evidence }, { data: messages }] = await Promise.all([
    supabase
      .from("users")
      .select("handle, display_name")
      .eq("id", partnerId)
      .maybeSingle(),
    supabase
      .from("proposal_evidence_photos")
      .select("photo_url")
      .eq("proposal_id", dispute.proposal_id),
    supabase
      .from("dispute_messages")
      .select("id, sender_id, sender_role, body, created_at")
      .eq("dispute_id", dispute.id)
      .order("created_at", { ascending: true }),
  ]);
  const partnerRow = partner as { handle: string | null; display_name: string | null } | null;
  const attached = ((evidence as { photo_url: string }[] | null) ?? []).map((item) => item.photo_url);
  const extra = dispute.evidence_photo_urls ?? [];
  return {
    id: dispute.id,
    proposalId: dispute.proposal_id,
    iAmReporter: dispute.reporter_id === userId,
    partnerHandle: partnerRow?.handle ?? partnerRow?.display_name ?? "?",
    category: dispute.category,
    factMemo: dispute.fact_memo,
    status: dispute.status,
    outcome: dispute.outcome,
    operatorComment: dispute.operator_comment,
    ticketNo: dispute.ticket_no,
    respondentDeadlineAt: dispute.respondent_deadline_at,
    operatorDeadlineAt: dispute.operator_deadline_at,
    submittedAt: dispute.submitted_at,
    closedAt: dispute.closed_at,
    respondentResponse: dispute.respondent_response,
    respondentResponseText: dispute.respondent_response_text,
    photoUrls: [...attached, ...extra],
    respondentPhotoUrls: dispute.respondent_evidence_urls ?? [],
    messages: ((messages as {
      id: string;
      sender_id: string | null;
      sender_role: "reporter" | "respondent" | "operator";
      body: string;
      created_at: string;
    }[] | null) ?? []).map((item) => ({
      id: item.id,
      senderRole: item.sender_role,
      body: item.body,
      createdAt: item.created_at,
      isMine: item.sender_id === userId,
    })),
  };
}

async function respondToDispute(input: {
  disputeId: string;
  proposalId: string;
  userId: string;
  response: ResponseKind;
  text: string;
}) {
  if (!supabase) return { error: "Supabaseが未設定です" };
  const now = new Date().toISOString();
  if (input.response === "accepted") {
    const { error } = await supabase
      .from("disputes")
      .update({
        respondent_response: "accepted",
        respondent_response_text: input.text.trim() || null,
        respondent_responded_at: now,
        status: "closed",
        outcome: "cancelled",
        closed_at: now,
        operator_comment: "被申告者が事実を認めたため、迅速処理されました",
      })
      .eq("id", input.disputeId)
      .eq("respondent_id", input.userId);
    if (error) return { error: error.message };
    await supabase
      .from("proposals")
      .update({ status: "cancelled", last_action_at: now })
      .eq("id", input.proposalId);
    await supabase.from("messages").insert({
      proposal_id: input.proposalId,
      sender_id: input.userId,
      message_type: "system",
      body: "✓ 申告は事実と認められ、取引はキャンセルされました",
      meta: { action: "dispute_accepted", dispute_id: input.disputeId },
    });
    return {};
  }

  const { error } = await supabase
    .from("disputes")
    .update({
      respondent_response: "disputed",
      respondent_response_text: input.text.trim(),
      respondent_responded_at: now,
      status: "arbitrating",
    })
    .eq("id", input.disputeId)
    .eq("respondent_id", input.userId);
  if (error) return { error: error.message };
  await supabase.from("messages").insert({
    proposal_id: input.proposalId,
    sender_id: input.userId,
    message_type: "system",
    body: "⚖️ 申告に反論が提出されました。運営による仲裁が開始されます",
    meta: { action: "dispute_responded", dispute_id: input.disputeId },
  });
  return {};
}

async function sendDisputeMessage(input: {
  disputeId: string;
  userId: string;
  body: string;
}) {
  if (!supabase) return { error: "Supabaseが未設定です" };
  const text = input.body.trim();
  if (!text) return { error: "本文を入力してください" };
  const { data: dispute } = await supabase
    .from("disputes")
    .select("reporter_id, respondent_id, status")
    .eq("id", input.disputeId)
    .maybeSingle();
  const row = dispute as { reporter_id: string; respondent_id: string; status: string } | null;
  if (!row) return { error: "申告が見つかりません" };
  if (row.status === "closed") return { error: "クローズ済の申告には送信できません" };
  const role = row.reporter_id === input.userId
    ? "reporter"
    : row.respondent_id === input.userId
      ? "respondent"
      : null;
  if (!role) return { error: "参加者ではありません" };
  const { error } = await supabase.from("dispute_messages").insert({
    dispute_id: input.disputeId,
    sender_id: input.userId,
    sender_role: role,
    body: text,
    photo_urls: [],
  });
  if (error) return { error: error.message };
  return {};
}

function TimelineRow({ done, label }: { done: boolean; label: string }) {
  return (
    <View style={styles.timelineRow}>
      <View style={[styles.timelineDot, done ? styles.timelineDotDone : null]}>
        {done ? <Text style={styles.timelineCheck}>✓</Text> : null}
      </View>
      <Text style={styles.timelineLabel}>{label}</Text>
    </View>
  );
}

function statusLabel(status: DisputeStatus) {
  if (status === "submitted") return "受付済み";
  if (status === "response_pending") return "相手の回答待ち";
  if (status === "arbitrating") return "運営確認中";
  return "完了";
}

function outcomeLabel(outcome: DisputeData["outcome"]) {
  if (outcome === "cancelled") return "取引キャンセル";
  if (outcome === "upheld") return "申告不成立";
  if (outcome === "partial") return "一部反映";
  return "結果確定";
}

function roleLabel(role: DisputeMessage["senderRole"]) {
  if (role === "operator") return "運営";
  return role === "reporter" ? "申告者" : "被申告者";
}

function formatDateTime(value: string) {
  const date = new Date(value);
  return `${date.getMonth() + 1}/${date.getDate()} ${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
}

const styles = StyleSheet.create({
  screen: {
    gap: 13,
  },
  card: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 9,
    padding: 15,
    ...megrumShadow,
  },
  statusCard: {
    backgroundColor: "rgba(166,149,216,0.07)",
    borderColor: "rgba(166,149,216,0.28)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 6,
    padding: 15,
  },
  statusTop: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  statusBadge: {
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    color: megrumColors.surface,
    fontSize: 10.5,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  date: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
  },
  title: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  muted: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  label: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.4,
  },
  bodyText: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "700",
    lineHeight: 21,
  },
  errorText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
  },
  photos: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  photo: {
    borderRadius: 10,
    height: 86,
    width: 66,
  },
  textArea: {
    backgroundColor: megrumColors.background,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 14,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "700",
    minHeight: 104,
    padding: 12,
    textAlignVertical: "top",
  },
  responseActions: {
    flexDirection: "row",
    gap: 9,
  },
  responseButton: {
    flex: 1,
  },
  resultCard: {
    backgroundColor: "rgba(34,197,94,0.08)",
    borderColor: "rgba(34,197,94,0.22)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 8,
    padding: 15,
  },
  timelineRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
    paddingVertical: 4,
  },
  timelineDot: {
    borderColor: "rgba(166,149,216,0.4)",
    borderRadius: megrumRadii.pill,
    borderStyle: "dashed",
    borderWidth: 1.5,
    height: 24,
    width: 24,
  },
  timelineDotDone: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.lavender,
    borderStyle: "solid",
    justifyContent: "center",
  },
  timelineCheck: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
  },
  timelineLabel: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "800",
  },
  messageBubble: {
    alignSelf: "flex-start",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 16,
    maxWidth: "88%",
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  messageMine: {
    alignSelf: "flex-end",
    backgroundColor: "rgba(166,149,216,0.16)",
  },
  messageRole: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
    marginBottom: 4,
  },
  messageBody: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "700",
    lineHeight: 19,
  },
  messageTime: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "800",
    marginTop: 5,
  },
  backToTrade: {
    alignItems: "center",
    paddingVertical: 10,
  },
  backToTradeText: {
    color: megrumColors.lavender,
    fontSize: 13,
    fontWeight: "900",
  },
});
