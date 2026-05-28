import { router, useLocalSearchParams } from "expo-router";
import { useCallback, useEffect, useMemo, useState } from "react";
import { ActivityIndicator, StyleSheet, Text, View } from "react-native";
import { useAuth } from "../src/auth/AuthProvider";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type EvaluationRow = {
  stars: number;
  comment: string | null;
  created_at: string;
  rater_id: string;
};

type EvaluationData = {
  userId: string;
  handle: string;
  displayName: string;
  evaluations: (EvaluationRow & { raterHandle: string })[];
};

export default function UserEvaluationsScreen() {
  const { id: rawId } = useLocalSearchParams<{ id?: string | string[] }>();
  const userId = Array.isArray(rawId) ? rawId[0] : rawId;
  const { user, previewMode, exitPreview } = useAuth();
  const [data, setData] = useState<EvaluationData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    if (!userId || !user || previewMode) return;
    setLoading(true);
    setError(null);
    try {
      setData(await fetchEvaluationData(userId));
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : "評価を読み込めませんでした");
    } finally {
      setLoading(false);
    }
  }, [previewMode, user, userId]);

  useEffect(() => {
    void reload();
  }, [reload]);

  const stats = useMemo(() => buildStats(data?.evaluations ?? []), [data?.evaluations]);
  const comments = (data?.evaluations ?? []).filter(
    (evaluation) => evaluation.comment && evaluation.comment.trim().length > 0,
  );

  if (previewMode || !user) {
    return (
      <Screen contentStyle={styles.screen}>
        <RouteHeader title="評価一覧" />
        <View style={styles.card}>
          <Text style={styles.title}>ログインが必要です</Text>
          <Text style={styles.muted}>評価一覧はログイン後に確認できます。</Text>
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
        title={data ? `@${data.handle} の評価` : "評価一覧"}
        subtitle={data ? `${data.evaluations.length} 件` : undefined}
      />
      {loading ? <ActivityIndicator color={megrumColors.lavender} /> : null}
      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      {data ? (
        data.evaluations.length === 0 ? (
          <View style={styles.emptyCard}>
            <Text style={styles.muted}>まだ評価がありません</Text>
          </View>
        ) : (
          <>
            <View style={styles.summaryCard}>
              <View style={styles.averageBox}>
                <Text style={styles.average}>★{stats.average.toFixed(1)}</Text>
                <Text style={styles.count}>{data.evaluations.length} 件</Text>
              </View>
              <View style={styles.histogram}>
                {[5, 4, 3, 2, 1].map((star) => {
                  const count = stats.histogram[star] ?? 0;
                  const ratio = data.evaluations.length > 0
                    ? count / data.evaluations.length
                    : 0;
                  return (
                    <View key={star} style={styles.histogramRow}>
                      <Text style={styles.histogramLabel}>{star}</Text>
                      <Text style={styles.histogramStar}>★</Text>
                      <View style={styles.histogramTrack}>
                        <View style={[styles.histogramFill, { flex: ratio }]} />
                        <View style={{ flex: 1 - ratio }} />
                      </View>
                      <Text style={styles.histogramCount}>{count}</Text>
                    </View>
                  );
                })}
              </View>
            </View>

            <View style={styles.comments}>
              {comments.length > 0 ? (
                comments.map((evaluation, index) => (
                  <View key={`${evaluation.created_at}-${index}`} style={styles.commentCard}>
                    <View style={styles.commentTop}>
                      <Text style={styles.rater}>@{evaluation.raterHandle}</Text>
                      <Text style={styles.commentStars}>
                        {"★".repeat(evaluation.stars)}
                        <Text style={styles.commentStarsMuted}>
                          {"★".repeat(5 - evaluation.stars)}
                        </Text>
                      </Text>
                      <Text style={styles.date}>{formatDate(evaluation.created_at)}</Text>
                    </View>
                    <Text style={styles.comment}>{evaluation.comment}</Text>
                  </View>
                ))
              ) : (
                <View style={styles.emptyCard}>
                  <Text style={styles.muted}>コメント付きの評価はまだありません</Text>
                </View>
              )}
            </View>
          </>
        )
      ) : null}
    </Screen>
  );
}

async function fetchEvaluationData(userId: string): Promise<EvaluationData> {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const { data: target, error } = await supabase
    .from("users")
    .select("id, handle, display_name, account_status")
    .eq("id", userId)
    .maybeSingle();
  if (error) throw error;
  const targetUser = target as {
    id: string;
    handle: string | null;
    display_name: string | null;
    account_status: string | null;
  } | null;
  if (!targetUser || targetUser.account_status === "deleted" || targetUser.account_status === "suspended") {
    throw new Error("ユーザーが見つかりません");
  }

  const { data: rows } = await supabase
    .from("user_evaluations")
    .select("stars, comment, created_at, rater_id")
    .eq("ratee_id", userId)
    .order("created_at", { ascending: false });
  const evaluations = ((rows as EvaluationRow[] | null) ?? []);
  const raterIds = Array.from(new Set(evaluations.map((evaluation) => evaluation.rater_id)));
  const handleMap = new Map<string, string>();
  if (raterIds.length > 0) {
    const { data: raters } = await supabase
      .from("users")
      .select("id, handle")
      .in("id", raterIds);
    for (const rater of (raters as { id: string; handle: string | null }[] | null) ?? []) {
      handleMap.set(rater.id, rater.handle ?? "?");
    }
  }
  return {
    userId,
    handle: targetUser.handle ?? targetUser.display_name ?? "?",
    displayName: targetUser.display_name ?? "?",
    evaluations: evaluations.map((evaluation) => ({
      ...evaluation,
      raterHandle: handleMap.get(evaluation.rater_id) ?? "?",
    })),
  };
}

function buildStats(evaluations: EvaluationRow[]) {
  const histogram: Record<number, number> = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
  let sum = 0;
  for (const evaluation of evaluations) {
    sum += evaluation.stars;
    histogram[evaluation.stars] = (histogram[evaluation.stars] ?? 0) + 1;
  }
  return {
    average: evaluations.length > 0 ? sum / evaluations.length : 0,
    histogram,
  };
}

function formatDate(value: string) {
  const date = new Date(value);
  return `${date.getFullYear()}/${String(date.getMonth() + 1).padStart(2, "0")}/${String(date.getDate()).padStart(2, "0")}`;
}

const styles = StyleSheet.create({
  screen: {
    gap: 14,
  },
  card: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 10,
    padding: 16,
    ...megrumShadow,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  muted: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    textAlign: "center",
  },
  errorText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
  },
  emptyCard: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderStyle: "dashed",
    borderWidth: 1,
    paddingVertical: 32,
  },
  summaryCard: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.06)",
    borderColor: "rgba(166,149,216,0.32)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    flexDirection: "row",
    gap: 16,
    padding: 15,
  },
  averageBox: {
    alignItems: "center",
    minWidth: 80,
  },
  average: {
    color: megrumColors.lavender,
    fontSize: 28,
    fontWeight: "900",
  },
  count: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "800",
  },
  histogram: {
    flex: 1,
    gap: 4,
  },
  histogramRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 6,
  },
  histogramLabel: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "800",
    textAlign: "right",
    width: 12,
  },
  histogramStar: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
  },
  histogramTrack: {
    backgroundColor: "rgba(58,50,74,0.05)",
    borderRadius: megrumRadii.pill,
    flex: 1,
    flexDirection: "row",
    height: 7,
    overflow: "hidden",
  },
  histogramFill: {
    backgroundColor: megrumColors.lavender,
  },
  histogramCount: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "800",
    textAlign: "right",
    width: 20,
  },
  comments: {
    gap: 9,
  },
  commentCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    padding: 14,
  },
  commentTop: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
    marginBottom: 7,
  },
  rater: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  commentStars: {
    color: megrumColors.lavender,
    flex: 1,
    fontSize: 10.5,
    fontWeight: "900",
  },
  commentStarsMuted: {
    color: "rgba(58,50,74,0.12)",
  },
  date: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "800",
  },
  comment: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "700",
    lineHeight: 20,
  },
});
