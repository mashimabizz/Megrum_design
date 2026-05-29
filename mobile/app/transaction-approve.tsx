import { router, useLocalSearchParams } from "expo-router";
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useAuth } from "../src/auth/AuthProvider";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import {
  exchangeMethodLabel,
  normalizeExchangeMethod,
  type ExchangeMethod,
} from "../src/lib/mailingAddress";
import { supabase } from "../src/lib/supabase";
import { approveCompletion } from "../src/lib/transactionActions";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type ProposalRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  evidence_photo_url: string | null;
  evidence_taken_at: string | null;
  approved_by_sender: boolean | null;
  approved_by_receiver: boolean | null;
  meetup_place_name: string | null;
  exchange_method: string | null;
  sender_have_ids: string[] | null;
  sender_have_qtys: number[] | null;
  receiver_have_ids: string[] | null;
  receiver_have_qtys: number[] | null;
};

type EvidencePhoto = {
  id: string;
  photoUrl: string;
  position: number;
  takenAt: string;
  takenBy: string | null;
  photographerLabel: string;
};

type GoodsRow = {
  id: string;
  title: string | null;
  group: { name: string | null } | { name: string | null }[] | null;
  character: { name: string | null } | { name: string | null }[] | null;
  goods_type: { name: string | null } | { name: string | null }[] | null;
};

type ApproveRow = {
  side: "me" | "them";
  handle: string;
  desc: string;
  letters: string[];
};

type ApproveData = {
  proposalId: string;
  photos: EvidencePhoto[];
  photoTakenAt: string | null;
  placeName: string | null;
  exchangeMethod: ExchangeMethod;
  rows: ApproveRow[];
  partnerHandle: string;
  myApproved: boolean;
  partnerApproved: boolean;
};

export default function TransactionApproveScreen() {
  const { id } = useLocalSearchParams<{ id?: string | string[] }>();
  const proposalId = Array.isArray(id) ? id[0] : id;
  const { user, previewMode, exitPreview } = useAuth();
  const [data, setData] = useState<ApproveData | null>(null);
  const [loading, setLoading] = useState(false);
  const [approving, setApproving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedPhotoId, setSelectedPhotoId] = useState<string | null>(null);
  const selectedPhoto = useMemo(
    () =>
      data?.photos.find((photo) => photo.id === selectedPhotoId) ??
      data?.photos[0] ??
      null,
    [data?.photos, selectedPhotoId],
  );
  const photoMeta = useMemo(
    () => formatPhotoMeta(data?.photoTakenAt ?? selectedPhoto?.takenAt ?? null),
    [data?.photoTakenAt, selectedPhoto?.takenAt],
  );

  const reload = useCallback(async () => {
    if (!proposalId || !user || previewMode) return;
    setLoading(true);
    setError(null);
    try {
      const next = await fetchApproveData(proposalId, user.id);
      setData(next);
    } catch (loadError) {
      const message = loadError instanceof Error ? loadError.message : "読み込みに失敗しました";
      if (message === "NO_PHOTOS") {
        router.replace({ pathname: "/transaction-capture", params: { id: proposalId } });
        return;
      }
      if (message === "COMPLETED") {
        router.replace({ pathname: "/transaction-rate", params: { id: proposalId } });
        return;
      }
      setError(message);
    } finally {
      setLoading(false);
    }
  }, [previewMode, proposalId, user]);

  useEffect(() => {
    void reload();
  }, [reload]);

  useEffect(() => {
    if (!data?.photos.length) {
      setSelectedPhotoId(null);
      return;
    }
    setSelectedPhotoId((current) =>
      current && data.photos.some((photo) => photo.id === current)
        ? current
        : data.photos[0].id,
    );
  }, [data?.photos]);

  async function handleApprove() {
    if (!user || !proposalId) return;
    setApproving(true);
    setError(null);
    try {
      const action = await approveCompletion({ proposalId, userId: user.id });
      if (action.error) setError(action.error);
      else if (action.redirectTo === "/transaction-rate") {
        router.replace({ pathname: "/transaction-rate", params: { id: proposalId } });
      } else {
        await reload();
      }
    } finally {
      setApproving(false);
    }
  }

  if (previewMode || !user) {
    return (
      <Screen contentStyle={styles.screen}>
        <RouteHeader title="取引完了の確認" />
        <View style={styles.noticeCard}>
          <Text style={styles.noticeTitle}>ログインが必要です</Text>
          <Text style={styles.noticeText}>証跡の承認は実アカウントの取引に接続します。</Text>
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
    <View style={styles.root}>
      <Screen contentStyle={styles.screen}>
        <RouteHeader title="取引完了の確認" />
        {loading ? <ActivityIndicator color={megrumColors.lavender} /> : null}
        {error ? <Text style={styles.errorText}>{error}</Text> : null}

        {data ? (
          <>
            <View style={styles.photoPanel}>
              {selectedPhoto ? (
                <Image source={{ uri: selectedPhoto.photoUrl }} style={styles.heroPhoto} />
              ) : null}
              <View style={styles.photoMetaCard}>
                <Text style={styles.photoMetaTitle}>
                  取引証跡 #{selectedPhoto?.position ?? 1}（{data.photos.length}枚）
                </Text>
                <Text style={styles.photoMetaText}>{photoMeta}</Text>
                <Text numberOfLines={1} style={styles.photoMetaText}>
                  {selectedPhoto?.photographerLabel ?? "撮影者不明"}
                </Text>
                <Text numberOfLines={1} style={styles.photoMetaText}>
                  {data.exchangeMethod === "mail"
                    ? exchangeMethodLabel(data.exchangeMethod)
                    : data.placeName ?? "場所未設定"}
                </Text>
              </View>
            </View>

            {data.photos.length > 1 ? (
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.photoList}
              >
                {data.photos.map((photo) => (
                  <Pressable
                    key={photo.id}
                    accessibilityRole="button"
                    accessibilityLabel={`証跡${photo.position}を選択`}
                    onPress={() => setSelectedPhotoId(photo.id)}
                    style={[
                      styles.thumbButton,
                      photo.id === selectedPhoto?.id ? styles.thumbButtonSelected : null,
                    ]}
                  >
                    <Image source={{ uri: photo.photoUrl }} style={styles.thumb} />
                    <Text
                      numberOfLines={1}
                      style={[
                        styles.thumbLabel,
                        photo.id === selectedPhoto?.id ? styles.thumbLabelSelected : null,
                      ]}
                    >
                      #{photo.position} {photo.photographerLabel}
                    </Text>
                  </Pressable>
                ))}
              </ScrollView>
            ) : null}

            <View style={styles.rowsPanel}>
              {data.rows.map((row, index) => (
                <View key={`${row.side}-${index}`}>
                  <ApproveItemRow row={row} />
                  {index < data.rows.length - 1 ? <View style={styles.divider} /> : null}
                </View>
              ))}
            </View>

            <View style={styles.statusPanel}>
              <Text style={styles.statusTitle}>両者の確認</Text>
              <ApproveStatusRow
                done={data.partnerApproved}
                label={`@${data.partnerHandle} が承認`}
                sub={data.partnerApproved ? "承認済" : "承認待ち"}
              />
              <ApproveStatusRow
                done={data.myApproved}
                label="あなたの承認"
                sub={data.myApproved ? "承認済" : "内容を確認してください"}
              />
            </View>

            <Text style={styles.hintText}>
              内容に問題がある場合は「相違あり」からサポートへ申告できます。
            </Text>
          </>
        ) : null}
      </Screen>

      {data ? (
        <View style={styles.stickyCta}>
          <Pressable
            disabled={approving || data.myApproved}
            onPress={() => router.push({ pathname: "/dispute-new", params: { proposalId: proposalId ?? "" } })}
            style={[styles.disputeButton, data.myApproved ? styles.disabled : null]}
          >
            <Text style={styles.disputeText}>相違あり</Text>
          </Pressable>
          <PrimaryButton
            loading={approving}
            disabled={data.myApproved && !data.partnerApproved}
            onPress={() => void handleApprove()}
            style={styles.approveButton}
          >
            {data.myApproved && !data.partnerApproved
              ? "承認済（相手待ち）"
              : data.myApproved && data.partnerApproved
                ? "完了処理を実行 →"
                : "承認して完了"}
          </PrimaryButton>
        </View>
      ) : null}
    </View>
  );
}

async function fetchApproveData(proposalId: string, userId: string): Promise<ApproveData> {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const { data: row, error } = await supabase
    .from("proposals")
    .select(
      `id, sender_id, receiver_id, status,
       evidence_taken_at, approved_by_sender, approved_by_receiver,
       evidence_photo_url,
       meetup_place_name, exchange_method, sender_have_ids, sender_have_qtys,
       receiver_have_ids, receiver_have_qtys`,
    )
    .eq("id", proposalId)
    .maybeSingle();
  if (error) throw error;
  const proposal = row as ProposalRow | null;
  if (!proposal) throw new Error("取引が見つかりません");
  if (proposal.sender_id !== userId && proposal.receiver_id !== userId) {
    throw new Error("この取引には参加していません");
  }
  if (proposal.status === "completed") throw new Error("COMPLETED");

  const { data: photosData } = await supabase
    .from("proposal_evidence_photos")
    .select("id, photo_url, position, taken_at, taken_by")
    .eq("proposal_id", proposalId)
    .order("position", { ascending: true });
  const rawPhotos = ((photosData as {
    id: string;
    photo_url: string;
    position: number;
    taken_at: string;
    taken_by: string | null;
  }[] | null) ?? []);
  if (rawPhotos.length === 0 && proposal.evidence_photo_url) {
    rawPhotos.push({
      id: "legacy-evidence",
      photo_url: proposal.evidence_photo_url,
      position: 1,
      taken_at: proposal.evidence_taken_at ?? new Date().toISOString(),
      taken_by: null,
    });
  }
  if (rawPhotos.length === 0) throw new Error("NO_PHOTOS");

  const isMeSender = proposal.sender_id === userId;
  const partnerId = isMeSender ? proposal.receiver_id : proposal.sender_id;
  const [{ data: partner }, inventoryById] = await Promise.all([
    supabase
      .from("users")
      .select("handle, display_name")
      .eq("id", partnerId)
      .maybeSingle(),
    fetchInventoryMap([
      ...(proposal.sender_have_ids ?? []),
      ...(proposal.receiver_have_ids ?? []),
    ]),
  ]);
  const partnerHandle =
    (partner as { handle?: string | null; display_name?: string | null } | null)?.handle ??
    (partner as { display_name?: string | null } | null)?.display_name ??
    "?";
  const photos = rawPhotos.map((photo) => ({
    id: photo.id,
    photoUrl: photo.photo_url,
    position: photo.position,
    takenAt: photo.taken_at,
    takenBy: photo.taken_by,
    photographerLabel:
      photo.taken_by === userId
        ? "あなたが撮影"
        : photo.taken_by === partnerId
          ? `@${partnerHandle} が撮影`
          : "撮影者不明",
  }));
  const senderIds = proposal.sender_have_ids ?? [];
  const senderQtys = proposal.sender_have_qtys ?? [];
  const receiverIds = proposal.receiver_have_ids ?? [];
  const receiverQtys = proposal.receiver_have_qtys ?? [];

  return {
    proposalId: proposal.id,
    photos,
    photoTakenAt: proposal.evidence_taken_at,
    placeName: proposal.meetup_place_name,
    exchangeMethod: normalizeExchangeMethod(proposal.exchange_method),
    rows: [
      {
        side: isMeSender ? "them" : "me",
        handle: isMeSender ? partnerHandle : "あなた",
        desc: summarize(receiverIds, receiverQtys, inventoryById),
        letters: letters(receiverIds, receiverQtys, inventoryById),
      },
      {
        side: isMeSender ? "me" : "them",
        handle: isMeSender ? "あなた" : partnerHandle,
        desc: summarize(senderIds, senderQtys, inventoryById),
        letters: letters(senderIds, senderQtys, inventoryById),
      },
    ],
    partnerHandle,
    myApproved: isMeSender ? !!proposal.approved_by_sender : !!proposal.approved_by_receiver,
    partnerApproved: isMeSender
      ? !!proposal.approved_by_receiver
      : !!proposal.approved_by_sender,
  };
}

async function fetchInventoryMap(ids: string[]) {
  if (!supabase) return new Map<string, { label: string; goodsTypeName: string | null }>();
  const uniqueIds = Array.from(new Set(ids));
  if (uniqueIds.length === 0) return new Map<string, { label: string; goodsTypeName: string | null }>();
  const { data } = await supabase
    .from("goods_inventory")
    .select(
      "id, title, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
    )
    .in("id", uniqueIds);
  const map = new Map<string, { label: string; goodsTypeName: string | null }>();
  for (const row of (data as GoodsRow[] | null) ?? []) {
    const label = pickName(row.character) ?? pickName(row.group) ?? row.title ?? "グッズ";
    map.set(row.id, { label, goodsTypeName: pickName(row.goods_type) });
  }
  return map;
}

function ApproveItemRow({ row }: { row: ApproveRow }) {
  return (
    <View style={styles.itemRow}>
      <View style={[styles.sideBadge, row.side === "me" ? styles.sideBadgeMe : styles.sideBadgeThem]}>
        <Text style={styles.sideBadgeText}>{row.side === "me" ? "私" : "相"}</Text>
      </View>
      <View style={styles.itemCopy}>
        <Text style={styles.itemHandle}>@{row.handle}</Text>
        <Text numberOfLines={2} style={styles.itemDesc}>{row.desc}</Text>
      </View>
      <View style={styles.letters}>
        {row.letters.slice(0, 4).map((letter, index) => (
          <View key={`${letter}-${index}`} style={styles.letterCard}>
            <Text style={styles.letterText}>{letter}</Text>
          </View>
        ))}
        {row.letters.length > 4 ? (
          <Text style={styles.moreLetters}>+{row.letters.length - 4}</Text>
        ) : null}
      </View>
    </View>
  );
}

function ApproveStatusRow({
  done,
  label,
  sub,
}: {
  done: boolean;
  label: string;
  sub: string;
}) {
  return (
    <View style={styles.statusRow}>
      <View style={[styles.statusMark, done ? styles.statusMarkDone : null]}>
        {done ? <Text style={styles.statusMarkText}>✓</Text> : null}
      </View>
      <View>
        <Text style={styles.statusLabel}>{label}</Text>
        <Text style={styles.statusSub}>{sub}</Text>
      </View>
    </View>
  );
}

function summarize(
  ids: string[],
  qtys: number[],
  inventoryById: Map<string, { label: string; goodsTypeName: string | null }>,
) {
  if (ids.length === 0) return "—";
  return ids
    .map((id, index) => {
      const item = inventoryById.get(id);
      return `${item?.label ?? "?"} ×${qtys[index] ?? 1}`;
    })
    .join(" / ");
}

function letters(
  ids: string[],
  qtys: number[],
  inventoryById: Map<string, { label: string; goodsTypeName: string | null }>,
) {
  const out: string[] = [];
  for (let i = 0; i < ids.length; i += 1) {
    const letter = inventoryById.get(ids[i])?.label?.slice(0, 1) ?? "?";
    for (let count = 0; count < (qtys[i] ?? 1); count += 1) out.push(letter);
  }
  return out;
}

function pickName(
  value:
    | { name: string | null }
    | { name: string | null }[]
    | null
    | undefined,
) {
  if (!value) return null;
  return Array.isArray(value) ? value[0]?.name ?? null : value.name;
}

function formatPhotoMeta(value: string | null) {
  if (!value) return "—";
  const date = new Date(value);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")} ${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
}

const styles = StyleSheet.create({
  root: {
    backgroundColor: megrumColors.background,
    flex: 1,
  },
  screen: {
    gap: 14,
    paddingBottom: 130,
  },
  noticeCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.2)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 10,
    padding: 16,
    ...megrumShadow,
  },
  noticeTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  noticeText: {
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
  photoPanel: {
    backgroundColor: "#120e1c",
    borderRadius: 22,
    minHeight: 260,
    overflow: "hidden",
  },
  heroPhoto: {
    height: 260,
    width: "100%",
  },
  photoMetaCard: {
    backgroundColor: "rgba(0,0,0,0.46)",
    borderRadius: 16,
    bottom: 12,
    left: 12,
    paddingHorizontal: 12,
    paddingVertical: 9,
    position: "absolute",
    right: 12,
  },
  photoMetaTitle: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "900",
  },
  photoMetaText: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  photoList: {
    gap: 8,
    paddingRight: 18,
  },
  thumbButton: {
    borderColor: "transparent",
    borderRadius: 13,
    borderWidth: 2,
    gap: 4,
    padding: 3,
    width: 78,
  },
  thumbButtonSelected: {
    backgroundColor: "rgba(166,149,216,0.10)",
    borderColor: megrumColors.lavender,
  },
  thumb: {
    borderRadius: 10,
    height: 78,
    width: 60,
  },
  thumbLabel: {
    color: megrumColors.mutedInk,
    fontSize: 8.5,
    fontWeight: "900",
    lineHeight: 11,
    width: "100%",
  },
  thumbLabelSelected: {
    color: megrumColors.lavender,
  },
  rowsPanel: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    overflow: "hidden",
  },
  itemRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  sideBadge: {
    alignItems: "center",
    borderRadius: megrumRadii.pill,
    height: 30,
    justifyContent: "center",
    width: 30,
  },
  sideBadgeMe: {
    backgroundColor: "rgba(243,197,212,0.34)",
  },
  sideBadgeThem: {
    backgroundColor: "rgba(168,212,230,0.34)",
  },
  sideBadgeText: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
  },
  itemCopy: {
    flex: 1,
    minWidth: 0,
  },
  itemHandle: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  itemDesc: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    lineHeight: 15,
    marginTop: 2,
  },
  letters: {
    alignItems: "center",
    flexDirection: "row",
    gap: 3,
  },
  letterCard: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderColor: "rgba(255,255,255,0.7)",
    borderRadius: 4,
    borderWidth: 1,
    height: 30,
    justifyContent: "center",
    width: 22,
  },
  letterText: {
    color: "#fff",
    fontSize: 10,
    fontWeight: "900",
  },
  moreLetters: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "900",
  },
  divider: {
    backgroundColor: "rgba(58,50,74,0.08)",
    height: StyleSheet.hairlineWidth,
  },
  statusPanel: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    gap: 12,
    padding: 14,
  },
  statusTitle: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  statusRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
  },
  statusMark: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderColor: "rgba(166,149,216,0.55)",
    borderRadius: megrumRadii.pill,
    borderStyle: "dashed",
    borderWidth: 1.5,
    height: 30,
    width: 30,
  },
  statusMarkDone: {
    alignItems: "center",
    backgroundColor: megrumColors.ok,
    borderColor: megrumColors.ok,
    borderStyle: "solid",
    justifyContent: "center",
  },
  statusMarkText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "900",
  },
  statusLabel: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  statusSub: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  hintText: {
    backgroundColor: "rgba(58,50,74,0.04)",
    borderRadius: 11,
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 17,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  stickyCta: {
    backgroundColor: "rgba(255,255,255,0.94)",
    borderColor: "rgba(166,149,216,0.16)",
    borderTopWidth: 1,
    bottom: 0,
    flexDirection: "row",
    gap: 10,
    left: 0,
    paddingBottom: 30,
    paddingHorizontal: 18,
    paddingTop: 12,
    position: "absolute",
    right: 0,
  },
  disputeButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    justifyContent: "center",
    paddingHorizontal: 16,
  },
  disputeText: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  approveButton: {
    flex: 1,
  },
  disabled: {
    opacity: 0.45,
  },
});
