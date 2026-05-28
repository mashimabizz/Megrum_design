import { router, useLocalSearchParams } from "expo-router";
import { useCallback, useEffect, useState } from "react";
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

type Category = "short" | "wrong" | "noshow" | "cancel" | "other";

type ProposalRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  meetup_start_at: string | null;
  meetup_end_at: string | null;
  meetup_place_name: string | null;
};

type DisputeContext = {
  proposalId: string;
  respondentId: string;
  partnerHandle: string;
  meetupSummary: string;
  photoUrls: string[];
};

const CATEGORIES: { id: Category; title: string; sub: string }[] = [
  { id: "short", title: "受け取った点数が少ない", sub: "合意内容より少なかった" },
  { id: "wrong", title: "グッズが違う / 状態が悪い", sub: "内容や状態に相違がある" },
  { id: "noshow", title: "相手が現れなかった", sub: "待ち合わせに来なかった" },
  { id: "cancel", title: "合意済みのキャンセル", sub: "キャンセルの扱いを相談したい" },
  { id: "other", title: "その他", sub: "上記に当てはまらない" },
];

export default function DisputeNewScreen() {
  const { proposalId: rawProposalId } = useLocalSearchParams<{
    proposalId?: string | string[];
  }>();
  const proposalId = Array.isArray(rawProposalId) ? rawProposalId[0] : rawProposalId;
  const { user, previewMode, exitPreview } = useAuth();
  const [context, setContext] = useState<DisputeContext | null>(null);
  const [category, setCategory] = useState<Category>("wrong");
  const [memo, setMemo] = useState("");
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    if (!proposalId || !user || previewMode) return;
    setLoading(true);
    setError(null);
    try {
      setContext(await fetchDisputeContext(proposalId, user.id));
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : "読み込みに失敗しました");
    } finally {
      setLoading(false);
    }
  }, [previewMode, proposalId, user]);

  useEffect(() => {
    void reload();
  }, [reload]);

  async function handleSubmit() {
    if (!user || !context) return;
    setSubmitting(true);
    setError(null);
    try {
      const result = await submitDispute({
        proposalId: context.proposalId,
        reporterId: user.id,
        respondentId: context.respondentId,
        category,
        factMemo: memo,
        evidencePhotoUrls: context.photoUrls,
      });
      if (result.error) setError(result.error);
      else if (result.disputeId) {
        router.replace({ pathname: "/dispute-detail", params: { id: result.disputeId } });
      } else {
        router.replace({ pathname: "/transaction-detail", params: { id: context.proposalId } });
      }
    } finally {
      setSubmitting(false);
    }
  }

  if (previewMode || !user) {
    return (
      <Screen contentStyle={styles.screen}>
        <RouteHeader title="取引について報告" />
        <View style={styles.card}>
          <Text style={styles.title}>ログインが必要です</Text>
          <Text style={styles.text}>申告は実アカウントの取引に紐づけて作成します。</Text>
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
      <RouteHeader title="取引について報告" subtitle="該当する項目を1つ選んでください" />
      {loading ? <ActivityIndicator color={megrumColors.lavender} /> : null}
      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      {context ? (
        <>
          <View style={styles.card}>
            <Text style={styles.caption}>相手</Text>
            <Text style={styles.title}>@{context.partnerHandle}</Text>
            <Text style={styles.text}>{context.meetupSummary}</Text>
          </View>

          <View style={styles.categoryList}>
            {CATEGORIES.map((item) => (
              <Pressable
                key={item.id}
                accessibilityRole="button"
                onPress={() => setCategory(item.id)}
                style={[
                  styles.categoryCard,
                  category === item.id ? styles.categoryCardActive : null,
                ]}
              >
                <View style={[styles.radio, category === item.id ? styles.radioActive : null]}>
                  {category === item.id ? <View style={styles.radioCore} /> : null}
                </View>
                <View style={styles.categoryCopy}>
                  <Text style={styles.categoryTitle}>{item.title}</Text>
                  <Text style={styles.categorySub}>{item.sub}</Text>
                </View>
              </Pressable>
            ))}
          </View>

          <View style={styles.card}>
            <Text style={styles.caption}>事実メモ</Text>
            <TextInput
              value={memo}
              onChangeText={setMemo}
              maxLength={4000}
              multiline
              placeholder="起きたことを時系列で入力してください"
              placeholderTextColor="rgba(58,50,74,0.36)"
              style={styles.memo}
            />
          </View>

          <View style={styles.card}>
            <Text style={styles.caption}>自動添付される取引証跡</Text>
            {context.photoUrls.length > 0 ? (
              <View style={styles.photos}>
                {context.photoUrls.slice(0, 6).map((url, index) => (
                  <Image key={`${url}-${index}`} source={{ uri: url }} style={styles.photo} />
                ))}
              </View>
            ) : (
              <Text style={styles.text}>証跡写真はまだありません</Text>
            )}
          </View>

          <PrimaryButton loading={submitting} onPress={() => void handleSubmit()}>
            申告を送信する
          </PrimaryButton>
        </>
      ) : null}
    </Screen>
  );
}

async function fetchDisputeContext(
  proposalId: string,
  userId: string,
): Promise<DisputeContext> {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const { data: row, error } = await supabase
    .from("proposals")
    .select("id, sender_id, receiver_id, status, meetup_start_at, meetup_end_at, meetup_place_name")
    .eq("id", proposalId)
    .maybeSingle();
  if (error) throw error;
  const proposal = row as ProposalRow | null;
  if (!proposal) throw new Error("取引が見つかりません");
  if (proposal.sender_id !== userId && proposal.receiver_id !== userId) {
    throw new Error("この取引には参加していません");
  }
  if (proposal.status !== "agreed" && proposal.status !== "completed") {
    throw new Error("申告できるのは取引予定または完了後のみです");
  }

  const respondentId = proposal.sender_id === userId
    ? proposal.receiver_id
    : proposal.sender_id;
  const [{ data: partner }, { data: existing }, { data: photos }] = await Promise.all([
    supabase
      .from("users")
      .select("handle, display_name")
      .eq("id", respondentId)
      .maybeSingle(),
    supabase
      .from("disputes")
      .select("id")
      .eq("proposal_id", proposalId)
      .neq("status", "closed")
      .maybeSingle(),
    supabase
      .from("proposal_evidence_photos")
      .select("photo_url")
      .eq("proposal_id", proposalId)
      .order("position", { ascending: true }),
  ]);
  if (existing) throw new Error("この取引には既に申告中の事案があります");
  const partnerRow = partner as { handle: string | null; display_name: string | null } | null;
  return {
    proposalId,
    respondentId,
    partnerHandle: partnerRow?.handle ?? partnerRow?.display_name ?? "?",
    meetupSummary: formatMeetup(proposal),
    photoUrls: ((photos as { photo_url: string }[] | null) ?? []).map((photo) => photo.photo_url),
  };
}

async function submitDispute(input: {
  proposalId: string;
  reporterId: string;
  respondentId: string;
  category: Category;
  factMemo: string;
  evidencePhotoUrls: string[];
}) {
  if (!supabase) return { error: "Supabaseが未設定です" };
  const now = new Date();
  const yy = String(now.getFullYear()).slice(-2);
  const mm = String(now.getMonth() + 1).padStart(2, "0");
  const dd = String(now.getDate()).padStart(2, "0");
  const ticketNo = `DPT-${yy}${mm}${dd}-${String(Date.now()).slice(-4)}`;
  const respondentDeadline = new Date(now.getTime() + 24 * 60 * 60_000).toISOString();
  const operatorDeadline = new Date(now.getTime() + 48 * 60 * 60_000).toISOString();

  const { data, error } = await supabase
    .from("disputes")
    .insert({
      proposal_id: input.proposalId,
      reporter_id: input.reporterId,
      respondent_id: input.respondentId,
      category: input.category,
      fact_memo: input.factMemo.trim() || null,
      evidence_photo_urls: input.evidencePhotoUrls,
      status: "submitted",
      ticket_no: ticketNo,
      respondent_deadline_at: respondentDeadline,
      operator_deadline_at: operatorDeadline,
    })
    .select("id")
    .single();
  if (error || !data) {
    return { error: error?.message ?? "申告の作成に失敗しました" };
  }

  await supabase.from("messages").insert({
    proposal_id: input.proposalId,
    sender_id: input.reporterId,
    message_type: "system",
    body: `⚠️ 申告が送信されました（${ticketNo}）— 運営が確認します`,
    meta: { action: "dispute_submitted", dispute_id: (data as { id: string }).id },
  });
  await supabase.from("notifications").insert({
    user_id: input.respondentId,
    kind: "dispute_received",
    title: `取引について申告がありました（${ticketNo}）`,
    body: "回答期限は24時間以内です。早めに確認してください。",
    link_path: `/transactions/${input.proposalId}`,
    proposal_id: input.proposalId,
    dispute_id: (data as { id: string }).id,
  });
  return { disputeId: (data as { id: string }).id };
}

function formatMeetup(proposal: ProposalRow) {
  if (!proposal.meetup_start_at || !proposal.meetup_end_at) {
    return proposal.meetup_place_name ?? "待ち合わせ情報なし";
  }
  const start = new Date(proposal.meetup_start_at);
  const end = new Date(proposal.meetup_end_at);
  return `${proposal.meetup_place_name ?? "場所未設定"} ・ ${start.getMonth() + 1}/${start.getDate()} ${timeText(start)}〜${timeText(end)}`;
}

function timeText(date: Date) {
  return `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
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
    gap: 7,
    padding: 15,
    ...megrumShadow,
  },
  caption: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.5,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  text: {
    color: megrumColors.mutedInk,
    fontSize: 12.5,
    fontWeight: "800",
    lineHeight: 19,
  },
  errorText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
    lineHeight: 18,
  },
  categoryList: {
    gap: 8,
  },
  categoryCard: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    flexDirection: "row",
    gap: 11,
    padding: 13,
  },
  categoryCardActive: {
    borderColor: "rgba(166,149,216,0.5)",
    backgroundColor: "rgba(166,149,216,0.08)",
  },
  radio: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.18)",
    borderRadius: megrumRadii.pill,
    borderWidth: 2,
    height: 22,
    justifyContent: "center",
    width: 22,
  },
  radioActive: {
    borderColor: megrumColors.lavender,
  },
  radioCore: {
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    height: 10,
    width: 10,
  },
  categoryCopy: {
    flex: 1,
  },
  categoryTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  categorySub: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  memo: {
    backgroundColor: megrumColors.background,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 14,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "700",
    minHeight: 120,
    padding: 12,
    textAlignVertical: "top",
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
});
