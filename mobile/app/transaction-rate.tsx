import { router, useLocalSearchParams } from "expo-router";
import { useCallback, useEffect, useState } from "react";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useAuth } from "../src/auth/AuthProvider";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { Screen } from "../src/components/Screen";
import { supabase } from "../src/lib/supabase";
import { submitEvaluation } from "../src/lib/transactionActions";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type ProposalRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
};

type RateData = {
  proposalId: string;
  partnerHandle: string;
  partnerDisplayName: string;
  alreadyRated: boolean;
  myStars: number | null;
  myComment: string | null;
};

export default function TransactionRateScreen() {
  const { id } = useLocalSearchParams<{ id?: string | string[] }>();
  const proposalId = Array.isArray(id) ? id[0] : id;
  const { user, previewMode, exitPreview } = useAuth();
  const [data, setData] = useState<RateData | null>(null);
  const [stars, setStars] = useState(5);
  const [comment, setComment] = useState("");
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    if (!proposalId || !user || previewMode) return;
    setLoading(true);
    setError(null);
    try {
      const next = await fetchRateData(proposalId, user.id);
      setData(next);
      setStars(next.myStars ?? 5);
      setComment(next.myComment ?? "");
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
    if (!user || !proposalId || !data) return;
    setSubmitting(true);
    setError(null);
    try {
      const action = await submitEvaluation({
        proposalId,
        userId: user.id,
        stars,
        comment: comment.trim() || undefined,
      });
      if (action.error) setError(action.error);
      else router.replace("/transactions");
    } finally {
      setSubmitting(false);
    }
  }

  if (previewMode || !user) {
    return (
      <Screen contentStyle={styles.screen}>
        <View style={styles.hero}>
          <Text style={styles.heroTitle}>ログインが必要です</Text>
          <Text style={styles.heroSub}>評価は実アカウントの取引完了後に送信できます。</Text>
        </View>
        <PrimaryButton
          onPress={() => {
            exitPreview();
            router.replace("/login");
          }}
        >
          ログインする
        </PrimaryButton>
      </Screen>
    );
  }

  return (
    <View style={styles.root}>
      <Screen contentStyle={styles.screen}>
        <View style={styles.celebrate}>
          <View style={styles.checkBadge}>
            <Text style={styles.checkText}>✓</Text>
          </View>
          <Text style={styles.doneTitle}>取引完了！</Text>
          <Text style={styles.doneSub}>
            @{data?.partnerHandle ?? "相手"} との交換が記録されました
          </Text>
        </View>

        {loading ? <ActivityIndicator color={megrumColors.lavender} /> : null}
        {error ? <Text style={styles.errorText}>{error}</Text> : null}

        {data ? (
          <View style={styles.ratingCard}>
            <Text style={styles.cardTitle}>取引相手を評価</Text>
            <View style={styles.stars}>
              {[1, 2, 3, 4, 5].map((value) => (
                <Pressable
                  key={value}
                  disabled={data.alreadyRated}
                  accessibilityRole="button"
                  accessibilityLabel={`${value}星`}
                  onPress={() => setStars(value)}
                  style={styles.starButton}
                >
                  <Text
                    style={[
                      styles.star,
                      value <= stars ? styles.starActive : styles.starInactive,
                    ]}
                  >
                    ★
                  </Text>
                </Pressable>
              ))}
            </View>
            <TextInput
              editable={!data.alreadyRated}
              value={comment}
              onChangeText={setComment}
              maxLength={1000}
              multiline
              placeholder="コメント（任意）"
              placeholderTextColor="rgba(58,50,74,0.36)"
              style={styles.commentInput}
            />
            {data.alreadyRated ? (
              <Text style={styles.ratedText}>✓ 評価送信済み</Text>
            ) : null}
          </View>
        ) : null}
      </Screen>

      {data ? (
        <View style={styles.stickyCta}>
          {data.alreadyRated ? (
            <PrimaryButton onPress={() => router.replace("/transactions")}>
              取引一覧に戻る
            </PrimaryButton>
          ) : (
            <PrimaryButton loading={submitting} onPress={() => void handleSubmit()}>
              評価を送信
            </PrimaryButton>
          )}
        </View>
      ) : null}
    </View>
  );
}

async function fetchRateData(proposalId: string, userId: string): Promise<RateData> {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const { data: row, error } = await supabase
    .from("proposals")
    .select("id, sender_id, receiver_id, status")
    .eq("id", proposalId)
    .maybeSingle();
  if (error) throw error;
  const proposal = row as ProposalRow | null;
  if (!proposal) throw new Error("取引が見つかりません");
  if (proposal.sender_id !== userId && proposal.receiver_id !== userId) {
    throw new Error("この取引には参加していません");
  }
  if (proposal.status !== "completed") {
    throw new Error("評価は取引完了後に送信できます");
  }

  const partnerId = proposal.sender_id === userId
    ? proposal.receiver_id
    : proposal.sender_id;
  const [{ data: existing }, { data: partner }] = await Promise.all([
    supabase
      .from("user_evaluations")
      .select("id, stars, comment")
      .eq("proposal_id", proposalId)
      .eq("rater_id", userId)
      .maybeSingle(),
    supabase
      .from("users")
      .select("handle, display_name")
      .eq("id", partnerId)
      .maybeSingle(),
  ]);

  const evaluation = existing as { id: string; stars: number | null; comment: string | null } | null;
  const partnerRow = partner as { handle: string | null; display_name: string | null } | null;
  return {
    proposalId,
    partnerHandle: partnerRow?.handle ?? partnerRow?.display_name ?? "?",
    partnerDisplayName: partnerRow?.display_name ?? "?",
    alreadyRated: !!evaluation,
    myStars: evaluation?.stars ?? null,
    myComment: evaluation?.comment ?? null,
  };
}

const styles = StyleSheet.create({
  root: {
    backgroundColor: megrumColors.background,
    flex: 1,
  },
  screen: {
    gap: 16,
    paddingBottom: 130,
  },
  hero: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.2)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 8,
    padding: 18,
    ...megrumShadow,
  },
  heroTitle: {
    color: megrumColors.ink,
    fontSize: 20,
    fontWeight: "900",
  },
  heroSub: {
    color: megrumColors.mutedInk,
    fontSize: 12.5,
    fontWeight: "800",
    lineHeight: 19,
  },
  celebrate: {
    alignItems: "center",
    gap: 7,
    paddingTop: 38,
  },
  checkBadge: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 34,
    height: 68,
    justifyContent: "center",
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.28,
    shadowRadius: 18,
    width: 68,
  },
  checkText: {
    color: "#fff",
    fontSize: 30,
    fontWeight: "900",
  },
  doneTitle: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
    marginTop: 5,
  },
  doneSub: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  errorText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
    lineHeight: 18,
  },
  ratingCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1,
    gap: 12,
    padding: 17,
    ...megrumShadow,
  },
  cardTitle: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
    textAlign: "center",
  },
  stars: {
    flexDirection: "row",
    justifyContent: "center",
  },
  starButton: {
    alignItems: "center",
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  star: {
    fontSize: 33,
    lineHeight: 38,
  },
  starActive: {
    color: megrumColors.lavender,
  },
  starInactive: {
    color: "rgba(58,50,74,0.12)",
  },
  commentInput: {
    backgroundColor: megrumColors.background,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 14,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "700",
    minHeight: 96,
    paddingHorizontal: 13,
    paddingVertical: 12,
    textAlignVertical: "top",
  },
  ratedText: {
    color: megrumColors.ok,
    fontSize: 12,
    fontWeight: "900",
    textAlign: "center",
  },
  stickyCta: {
    backgroundColor: "rgba(255,255,255,0.94)",
    borderColor: "rgba(166,149,216,0.16)",
    borderTopWidth: 1,
    bottom: 0,
    left: 0,
    paddingBottom: 30,
    paddingHorizontal: 18,
    paddingTop: 12,
    position: "absolute",
    right: 0,
  },
});
