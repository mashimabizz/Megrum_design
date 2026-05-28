import { router, useLocalSearchParams } from "expo-router";
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Alert,
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
import { notifyLate, requestTradeCancel } from "../src/lib/transactionActions";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type Kind = "cancel" | "late";

type ProposalRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  meetup_start_at: string | null;
  meetup_place_name: string | null;
};

type Context = {
  proposalId: string;
  partnerHandle: string;
  meetupSummary: string;
};

const CANCEL_REASONS = [
  "体調不良 / 急用",
  "会場・時間が合わなくなった",
  "他で交換が成立した",
  "相手と連絡がつかなくなった",
  "その他",
];

const LATE_REASONS = [
  "電車遅延 / 交通機関",
  "会場での合流に時間がかかる",
  "前の取引が押している",
  "その他",
];

const LATE_MINUTES: { value: 10 | 20 | 30 | 60 | 90; label: string }[] = [
  { value: 10, label: "10分" },
  { value: 20, label: "20分" },
  { value: 30, label: "30分" },
  { value: 60, label: "1時間" },
  { value: 90, label: "1時間以上" },
];

export default function TransactionCancelOrLateScreen() {
  const { id: rawId, kind: rawKind } = useLocalSearchParams<{
    id?: string | string[];
    kind?: string | string[];
  }>();
  const proposalId = Array.isArray(rawId) ? rawId[0] : rawId;
  const kindValue = Array.isArray(rawKind) ? rawKind[0] : rawKind;
  const kind: Kind = kindValue === "late" ? "late" : "cancel";
  const isCancel = kind === "cancel";
  const reasons = useMemo(() => (isCancel ? CANCEL_REASONS : LATE_REASONS), [isCancel]);
  const { user, previewMode, exitPreview } = useAuth();
  const [context, setContext] = useState<Context | null>(null);
  const [reasonIndex, setReasonIndex] = useState(0);
  const [lateIndex, setLateIndex] = useState(1);
  const [note, setNote] = useState("");
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    if (!proposalId || !user || previewMode) return;
    setLoading(true);
    setError(null);
    try {
      setContext(await fetchContext(proposalId, user.id));
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : "読み込みに失敗しました");
    } finally {
      setLoading(false);
    }
  }, [previewMode, proposalId, user]);

  useEffect(() => {
    void reload();
  }, [reload]);

  async function submit() {
    if (!user || !proposalId) return;
    const reason = reasons[reasonIndex];
    const run = async () => {
      setSubmitting(true);
      setError(null);
      try {
        const result = isCancel
          ? await requestTradeCancel({
              proposalId,
              userId: user.id,
              reason,
              note: note.trim() || undefined,
            })
          : await notifyLate({
              proposalId,
              userId: user.id,
              lateMinutes: LATE_MINUTES[lateIndex].value,
              reason,
              note: note.trim() || undefined,
            });
        if (result.error) setError(result.error);
        else router.replace({ pathname: "/transaction-detail", params: { id: proposalId } });
      } finally {
        setSubmitting(false);
      }
    };

    if (isCancel) {
      Alert.alert(
        "キャンセルを送信しますか？",
        "相手の同意でキャンセル成立、異議があれば申告フローに進みます。",
        [
          { text: "閉じる", style: "cancel" },
          { text: "送信", style: "destructive", onPress: () => void run() },
        ],
      );
      return;
    }
    await run();
  }

  if (previewMode || !user) {
    return (
      <Screen contentStyle={styles.screen}>
        <RouteHeader title={isCancel ? "取引をキャンセル" : "遅刻を連絡"} />
        <View style={styles.card}>
          <Text style={styles.title}>ログインが必要です</Text>
          <Text style={styles.muted}>取引チャットへの通知は実アカウントに接続します。</Text>
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
        title={isCancel ? "取引をキャンセル" : "遅刻を連絡"}
        subtitle={isCancel ? "相手と合意の上で取り消します" : "到着が遅れる旨を相手に通知"}
      />
      {loading ? <ActivityIndicator color={megrumColors.lavender} /> : null}
      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      {context ? (
        <>
          <View style={styles.card}>
            <View style={styles.partnerIcon}>
              <Text style={styles.partnerIconText}>{context.partnerHandle.slice(0, 1).toUpperCase()}</Text>
            </View>
            <View style={styles.contextCopy}>
              <Text style={styles.title}>@{context.partnerHandle}</Text>
              <Text style={styles.muted}>{context.meetupSummary}</Text>
            </View>
          </View>

          {!isCancel ? (
            <View style={styles.section}>
              <Text style={styles.label}>どのくらい遅れますか</Text>
              <View style={styles.lateGrid}>
                {LATE_MINUTES.map((item, index) => (
                  <Pressable
                    key={item.value}
                    onPress={() => setLateIndex(index)}
                    style={[
                      styles.lateChip,
                      lateIndex === index ? styles.lateChipActive : null,
                    ]}
                  >
                    <Text
                      style={[
                        styles.lateChipText,
                        lateIndex === index ? styles.lateChipTextActive : null,
                      ]}
                    >
                      {item.label}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>
          ) : null}

          <View style={styles.section}>
            <Text style={styles.label}>理由</Text>
            <View style={styles.reasonCard}>
              {reasons.map((reason, index) => (
                <Pressable
                  key={reason}
                  onPress={() => setReasonIndex(index)}
                  style={[
                    styles.reasonRow,
                    reasonIndex === index ? styles.reasonRowActive : null,
                  ]}
                >
                  <View style={[styles.radio, reasonIndex === index ? styles.radioActive : null]}>
                    {reasonIndex === index ? <View style={styles.radioCore} /> : null}
                  </View>
                  <Text style={styles.reasonText}>{reason}</Text>
                </Pressable>
              ))}
            </View>
          </View>

          <View style={styles.section}>
            <Text style={styles.label}>メモ（任意）</Text>
            <TextInput
              value={note}
              onChangeText={setNote}
              maxLength={500}
              multiline
              placeholder={isCancel ? "相手への一言を添えると印象が変わります" : "会場到着後に再連絡します など"}
              placeholderTextColor="rgba(58,50,74,0.36)"
              style={styles.noteInput}
            />
          </View>

          <View style={[styles.infoBox, isCancel ? styles.warnBox : null]}>
            <Text style={styles.infoText}>
              {isCancel
                ? "キャンセルは相手の同意で成立します。相手が同意しない場合は申告フローへ進みます。"
                : "相手に取引チャット通知が届きます。30分以上の場合、相手は取引キャンセルを選択できます。"}
            </Text>
          </View>

          <PrimaryButton loading={submitting} onPress={() => void submit()}>
            {isCancel ? "キャンセルを送信" : "遅刻を通知"}
          </PrimaryButton>
        </>
      ) : null}
    </Screen>
  );
}

async function fetchContext(proposalId: string, userId: string): Promise<Context> {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const { data: row, error } = await supabase
    .from("proposals")
    .select("id, sender_id, receiver_id, status, meetup_start_at, meetup_place_name")
    .eq("id", proposalId)
    .maybeSingle();
  if (error) throw error;
  const proposal = row as ProposalRow | null;
  if (!proposal) throw new Error("取引が見つかりません");
  if (proposal.sender_id !== userId && proposal.receiver_id !== userId) {
    throw new Error("この取引には参加していません");
  }
  if (proposal.status !== "agreed") {
    throw new Error("取引予定のときだけ使えます");
  }
  const partnerId = proposal.sender_id === userId
    ? proposal.receiver_id
    : proposal.sender_id;
  const { data: partner } = await supabase
    .from("users")
    .select("handle, display_name")
    .eq("id", partnerId)
    .maybeSingle();
  const partnerRow = partner as { handle: string | null; display_name: string | null } | null;
  return {
    proposalId,
    partnerHandle: partnerRow?.handle ?? partnerRow?.display_name ?? "?",
    meetupSummary: formatMeetup(proposal),
  };
}

function formatMeetup(proposal: ProposalRow) {
  const place = proposal.meetup_place_name ?? "場所未設定";
  if (!proposal.meetup_start_at) return place;
  const start = new Date(proposal.meetup_start_at);
  return `${place} ・ ${start.getMonth() + 1}/${start.getDate()} ${String(start.getHours()).padStart(2, "0")}:${String(start.getMinutes()).padStart(2, "0")}`;
}

const styles = StyleSheet.create({
  screen: {
    gap: 14,
  },
  card: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    flexDirection: "row",
    gap: 11,
    padding: 14,
    ...megrumShadow,
  },
  partnerIcon: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    borderRadius: 12,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  partnerIconText: {
    color: megrumColors.lavender,
    fontSize: 16,
    fontWeight: "900",
  },
  contextCopy: {
    flex: 1,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  muted: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 17,
    marginTop: 2,
  },
  errorText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
  },
  section: {
    gap: 7,
  },
  label: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
    letterSpacing: 0.4,
    paddingHorizontal: 2,
  },
  lateGrid: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    flexDirection: "row",
    gap: 6,
    padding: 10,
  },
  lateChip: {
    alignItems: "center",
    backgroundColor: megrumColors.background,
    borderRadius: 10,
    flex: 1,
    justifyContent: "center",
    paddingVertical: 10,
  },
  lateChipActive: {
    backgroundColor: megrumColors.lavender,
  },
  lateChipText: {
    color: megrumColors.ink,
    fontSize: 10.5,
    fontWeight: "900",
  },
  lateChipTextActive: {
    color: megrumColors.surface,
  },
  reasonCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    overflow: "hidden",
  },
  reasonRow: {
    alignItems: "center",
    borderBottomColor: "rgba(58,50,74,0.05)",
    borderBottomWidth: 1,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  reasonRowActive: {
    backgroundColor: "rgba(166,149,216,0.07)",
  },
  radio: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.22)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1.5,
    height: 18,
    justifyContent: "center",
    width: 18,
  },
  radioActive: {
    borderColor: megrumColors.lavender,
    backgroundColor: megrumColors.lavender,
  },
  radioCore: {
    backgroundColor: megrumColors.surface,
    borderRadius: megrumRadii.pill,
    height: 6,
    width: 6,
  },
  reasonText: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 12.5,
    fontWeight: "800",
  },
  noteInput: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "700",
    minHeight: 104,
    padding: 13,
    textAlignVertical: "top",
  },
  infoBox: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  warnBox: {
    backgroundColor: "#fff5f0",
    borderColor: "rgba(217,130,107,0.25)",
    borderWidth: 1,
  },
  infoText: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 18,
  },
});
