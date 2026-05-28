import * as ImagePicker from "expo-image-picker";
import { router, useLocalSearchParams } from "expo-router";
import { useCallback, useEffect, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useAuth } from "../src/auth/AuthProvider";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { supabase } from "../src/lib/supabase";
import {
  addEvidencePhoto,
  notifyEvidenceComplete,
  removeEvidencePhoto,
  uploadEvidenceImage,
} from "../src/lib/transactionActions";
import { megrumColors, megrumRadii } from "../src/theme/tokens";

type ProposalRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  sender_have_qtys: number[] | null;
  receiver_have_qtys: number[] | null;
  meetup_place_name: string | null;
};

type EvidencePhoto = {
  id: string;
  photoUrl: string;
  position: number;
  takenAt: string;
  isMine: boolean;
};

type CaptureData = {
  proposalId: string;
  myCount: number;
  theirCount: number;
  placeName: string;
  photos: EvidencePhoto[];
};

export default function TransactionCaptureScreen() {
  const { id } = useLocalSearchParams<{ id?: string | string[] }>();
  const proposalId = Array.isArray(id) ? id[0] : id;
  const { user, previewMode, exitPreview } = useAuth();
  const insets = useSafeAreaInsets();
  const [data, setData] = useState<CaptureData | null>(null);
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState<"camera" | "library" | "delete" | "finish" | null>(null);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    if (!proposalId || !user || previewMode) return;
    setLoading(true);
    setError(null);
    try {
      setData(await fetchCaptureData(proposalId, user.id));
    } catch (loadError) {
      setError(loadError instanceof Error ? loadError.message : "読み込みに失敗しました");
    } finally {
      setLoading(false);
    }
  }, [previewMode, proposalId, user]);

  useEffect(() => {
    void reload();
  }, [reload]);

  async function pickImage(source: "camera" | "library") {
    if (!proposalId || !user) return;
    setBusy(source);
    setError(null);
    try {
      const permission =
        source === "camera"
          ? await ImagePicker.requestCameraPermissionsAsync()
          : await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (!permission.granted) {
        setError(
          source === "camera"
            ? "カメラの利用を許可してください"
            : "写真ライブラリの利用を許可してください",
        );
        return;
      }
      const result =
        source === "camera"
          ? await ImagePicker.launchCameraAsync({
              allowsEditing: false,
              mediaTypes: ["images"],
              quality: 0.86,
            })
          : await ImagePicker.launchImageLibraryAsync({
              allowsEditing: false,
              mediaTypes: ["images"],
              quality: 0.86,
            });
      if (result.canceled || !result.assets[0]) return;
      const asset = result.assets[0];
      const photoUrl = await uploadEvidenceImage({
        proposalId,
        uri: asset.uri,
        mimeType: asset.mimeType,
        fileName: asset.fileName,
      });
      const action = await addEvidencePhoto({
        proposalId,
        photoUrl,
        userId: user.id,
      });
      if (action.error) {
        setError(action.error);
        return;
      }
      await reload();
    } catch (pickError) {
      setError(pickError instanceof Error ? pickError.message : "証跡の追加に失敗しました");
    } finally {
      setBusy(null);
    }
  }

  async function handleDelete(photo: EvidencePhoto) {
    if (!user || !proposalId || !photo.isMine) return;
    Alert.alert("証跡を削除しますか？", "自分が追加した写真だけ削除できます。", [
      { text: "閉じる", style: "cancel" },
      {
        text: "削除",
        style: "destructive",
        onPress: () => {
          void (async () => {
            setBusy("delete");
            setError(null);
            const action = await removeEvidencePhoto({
              photoId: photo.id,
              proposalId,
              userId: user.id,
            });
            if (action.error) setError(action.error);
            await reload();
            setBusy(null);
          })();
        },
      },
    ]);
  }

  async function handleFinish() {
    if (!user || !proposalId || !data) return;
    if (data.photos.length === 0) {
      setError("少なくとも1枚は撮影してください");
      return;
    }
    setBusy("finish");
    setError(null);
    try {
      const action = await notifyEvidenceComplete({
        proposalId,
        photoCount: data.photos.length,
        userId: user.id,
      });
      if (action.error) setError(action.error);
      else router.replace({ pathname: "/transaction-detail", params: { id: proposalId } });
    } finally {
      setBusy(null);
    }
  }

  if (previewMode || !user) {
    return (
      <View style={[styles.authFallback, { paddingTop: Math.max(insets.top, 18) + 44 }]}>
        <Text style={styles.authTitle}>ログインが必要です</Text>
        <Text style={styles.authText}>取引証跡は実アカウントの取引に紐づけて保存します。</Text>
        <PrimaryButton
          onPress={() => {
            exitPreview();
            router.replace("/login");
          }}
        >
          ログインする
        </PrimaryButton>
      </View>
    );
  }

  return (
    <View style={styles.root}>
      <View style={styles.glow} />
      <View style={[styles.topBar, { paddingTop: Math.max(insets.top, 18) }]}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="取引チャットに戻る"
          onPress={() => router.replace({ pathname: "/transaction-detail", params: { id: proposalId ?? "" } })}
          style={styles.topButton}
        >
          <Text style={styles.topButtonText}>‹</Text>
        </Pressable>
        <View style={styles.statusChip}>
          <View style={styles.statusDot} />
          <Text style={styles.statusChipText}>オフライン保存</Text>
        </View>
        <Text style={styles.photoCount}>{data?.photos.length ?? 0}枚</Text>
      </View>

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.photoStrip}
        style={[styles.photoStripWrap, { top: Math.max(insets.top, 18) + 74 }]}
      >
        {data?.photos.map((photo) => (
          <Pressable
            key={photo.id}
            disabled={!photo.isMine || busy === "delete"}
            onPress={() => handleDelete(photo)}
            style={styles.photoChip}
          >
            <Image source={{ uri: photo.photoUrl }} style={styles.photoChipImage} />
            <Text style={styles.photoChipLabel}>#{photo.position}</Text>
          </Pressable>
        ))}
      </ScrollView>

      <View style={styles.centerCopy}>
        <Text style={styles.title}>取引証跡を撮影</Text>
        <Text style={styles.subtitle}>両者の交換物を1枚に収めてください</Text>
      </View>

      <View style={styles.viewFinder}>
        <View style={styles.viewHalf}>
          <GoodsStack count={data?.theirCount ?? 0} label={`相手の${data?.theirCount ?? 0}点`} />
        </View>
        <View style={styles.splitLine}>
          <View style={styles.splitBadge}>
            <Text style={styles.splitBadgeText}>↔</Text>
          </View>
        </View>
        <View style={[styles.viewHalf, styles.viewHalfMine]}>
          <GoodsStack count={data?.myCount ?? 0} label={`あなたの${data?.myCount ?? 0}点`} />
        </View>
      </View>

      {loading ? (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator color="#fff" />
        </View>
      ) : null}

      <View style={styles.metaChip}>
        <Text style={styles.metaText}>自動メタ: {timeNow()} · {data?.placeName ?? "—"}</Text>
      </View>

      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      <View style={[styles.controls, { paddingBottom: Math.max(insets.bottom, 18) + 18 }]}>
        <Pressable
          disabled={!!busy}
          onPress={() => void pickImage("library")}
          style={styles.secondaryCircle}
        >
          <Text style={styles.secondaryCircleText}>履歴</Text>
        </Pressable>
        <Pressable
          disabled={!!busy}
          accessibilityRole="button"
          accessibilityLabel="撮影"
          onPress={() => void pickImage("camera")}
          style={styles.shutter}
        >
          {busy === "camera" || busy === "library" ? <ActivityIndicator color={megrumColors.lavender} /> : null}
        </Pressable>
        <Pressable
          disabled={!!busy || !data || data.photos.length === 0}
          onPress={() => void handleFinish()}
          style={[
            styles.finishButton,
            !data || data.photos.length === 0 ? styles.finishButtonDisabled : null,
          ]}
        >
          <Text style={styles.finishButtonText}>完了 →</Text>
        </Pressable>
      </View>
    </View>
  );
}

async function fetchCaptureData(proposalId: string, userId: string): Promise<CaptureData> {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const { data: row, error } = await supabase
    .from("proposals")
    .select("id, sender_id, receiver_id, status, sender_have_qtys, receiver_have_qtys, meetup_place_name")
    .eq("id", proposalId)
    .maybeSingle();
  if (error) throw error;
  const proposal = row as ProposalRow | null;
  if (!proposal) throw new Error("取引が見つかりません");
  if (proposal.sender_id !== userId && proposal.receiver_id !== userId) {
    throw new Error("この取引には参加していません");
  }
  if (proposal.status !== "agreed") {
    throw new Error("証跡撮影は取引予定のときだけ使えます");
  }

  const { data: photoRows } = await supabase
    .from("proposal_evidence_photos")
    .select("id, photo_url, position, taken_at, taken_by")
    .eq("proposal_id", proposalId)
    .order("position", { ascending: true });
  const isMeSender = proposal.sender_id === userId;
  const myQtys = isMeSender ? proposal.sender_have_qtys : proposal.receiver_have_qtys;
  const theirQtys = isMeSender ? proposal.receiver_have_qtys : proposal.sender_have_qtys;
  return {
    proposalId,
    myCount: sumQty(myQtys),
    theirCount: sumQty(theirQtys),
    placeName: proposal.meetup_place_name ?? "—",
    photos: ((photoRows as {
      id: string;
      photo_url: string;
      position: number;
      taken_at: string;
      taken_by: string | null;
    }[] | null) ?? []).map((photo) => ({
      id: photo.id,
      photoUrl: photo.photo_url,
      position: photo.position,
      takenAt: photo.taken_at,
      isMine: photo.taken_by === userId,
    })),
  };
}

function GoodsStack({ count, label }: { count: number; label: string }) {
  return (
    <View style={styles.goodsStack}>
      <View style={styles.goodsCards}>
        {Array.from({ length: Math.max(1, Math.min(count, 4)) }).map((_, index) => (
          <View
            key={index}
            style={[
              styles.goodsCard,
              {
                transform: [
                  { rotate: `${(index - (Math.min(count, 4) - 1) / 2) * 4}deg` },
                  { translateY: Math.abs(index - 1.5) * 2 },
                ],
              },
            ]}
          >
            <Text style={styles.goodsCardText}>Mg</Text>
          </View>
        ))}
      </View>
      <Text style={styles.goodsLabel}>{label}</Text>
    </View>
  );
}

function sumQty(values: number[] | null) {
  return (values ?? []).reduce((sum, value) => sum + (value || 0), 0);
}

function timeNow() {
  const date = new Date();
  return `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
}

const styles = StyleSheet.create({
  root: {
    backgroundColor: "#0a0810",
    flex: 1,
    overflow: "hidden",
  },
  glow: {
    backgroundColor: "rgba(166,149,216,0.28)",
    borderRadius: 180,
    height: 360,
    left: "14%",
    position: "absolute",
    top: "28%",
    width: 360,
  },
  topBar: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    left: 18,
    position: "absolute",
    right: 18,
    zIndex: 5,
  },
  topButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.12)",
    borderRadius: megrumRadii.pill,
    height: 40,
    justifyContent: "center",
    width: 40,
  },
  topButtonText: {
    color: "#fff",
    fontSize: 34,
    fontWeight: "800",
    lineHeight: 36,
  },
  statusChip: {
    alignItems: "center",
    backgroundColor: "rgba(0,0,0,0.42)",
    borderRadius: megrumRadii.pill,
    flexDirection: "row",
    gap: 7,
    paddingHorizontal: 13,
    paddingVertical: 8,
  },
  statusDot: {
    backgroundColor: "#f59e0b",
    borderRadius: 3,
    height: 6,
    width: 6,
  },
  statusChipText: {
    color: "rgba(255,255,255,0.82)",
    fontSize: 11,
    fontWeight: "900",
  },
  photoCount: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 12,
    fontWeight: "900",
    minWidth: 40,
    textAlign: "right",
  },
  photoStripWrap: {
    left: 0,
    position: "absolute",
    right: 0,
    zIndex: 4,
  },
  photoStrip: {
    gap: 9,
    paddingHorizontal: 18,
  },
  photoChip: {
    alignItems: "center",
    gap: 4,
  },
  photoChipImage: {
    borderColor: "rgba(255,255,255,0.58)",
    borderRadius: 8,
    borderWidth: 2,
    height: 68,
    width: 52,
  },
  photoChipLabel: {
    backgroundColor: "rgba(0,0,0,0.65)",
    borderRadius: megrumRadii.pill,
    color: "#fff",
    fontSize: 9,
    fontWeight: "900",
    paddingHorizontal: 6,
  },
  centerCopy: {
    left: 18,
    position: "absolute",
    right: 18,
    top: "16%",
    zIndex: 3,
  },
  title: {
    color: "#fff",
    fontSize: 18,
    fontWeight: "900",
    textAlign: "center",
  },
  subtitle: {
    color: "rgba(255,255,255,0.68)",
    fontSize: 11.5,
    fontWeight: "800",
    marginTop: 5,
    textAlign: "center",
  },
  viewFinder: {
    borderColor: megrumColors.lavender,
    borderRadius: 20,
    borderWidth: 2,
    bottom: 214,
    flexDirection: "row",
    left: 30,
    overflow: "hidden",
    position: "absolute",
    right: 30,
    top: "29%",
  },
  viewHalf: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    flex: 1,
    justifyContent: "center",
  },
  viewHalfMine: {
    backgroundColor: "rgba(243,197,212,0.18)",
  },
  splitLine: {
    borderColor: "rgba(255,255,255,0.42)",
    borderStyle: "dashed",
    borderWidth: 0.7,
    position: "relative",
    width: 1,
  },
  splitBadge: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 14,
    height: 28,
    justifyContent: "center",
    left: -13.5,
    position: "absolute",
    top: "48%",
    width: 28,
  },
  splitBadgeText: {
    color: megrumColors.lavender,
    fontSize: 15,
    fontWeight: "900",
  },
  goodsStack: {
    alignItems: "center",
    gap: 12,
  },
  goodsCards: {
    flexDirection: "row",
    gap: 4,
  },
  goodsCard: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.88)",
    borderRadius: 5,
    height: 58,
    justifyContent: "flex-end",
    paddingBottom: 5,
    width: 40,
  },
  goodsCardText: {
    color: "rgba(10,8,16,0.46)",
    fontSize: 9,
    fontWeight: "900",
  },
  goodsLabel: {
    backgroundColor: "rgba(0,0,0,0.5)",
    borderRadius: megrumRadii.pill,
    color: "#fff",
    fontSize: 10,
    fontWeight: "900",
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  loadingOverlay: {
    alignItems: "center",
    bottom: 0,
    justifyContent: "center",
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
  },
  metaChip: {
    alignSelf: "center",
    backgroundColor: "rgba(0,0,0,0.5)",
    borderRadius: megrumRadii.pill,
    bottom: 154,
    paddingHorizontal: 14,
    paddingVertical: 8,
    position: "absolute",
  },
  metaText: {
    color: "#fff",
    fontSize: 11,
    fontWeight: "800",
  },
  errorText: {
    alignSelf: "center",
    backgroundColor: "rgba(217,130,107,0.92)",
    borderRadius: 12,
    bottom: 111,
    color: "#fff",
    fontSize: 12,
    fontWeight: "900",
    maxWidth: "86%",
    paddingHorizontal: 12,
    paddingVertical: 8,
    position: "absolute",
    textAlign: "center",
  },
  controls: {
    alignItems: "center",
    bottom: 0,
    flexDirection: "row",
    justifyContent: "space-around",
    left: 0,
    paddingHorizontal: 34,
    position: "absolute",
    right: 0,
  },
  secondaryCircle: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.14)",
    borderRadius: megrumRadii.pill,
    height: 48,
    justifyContent: "center",
    width: 48,
  },
  secondaryCircleText: {
    color: "#fff",
    fontSize: 10,
    fontWeight: "900",
  },
  shutter: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(255,255,255,0.46)",
    borderRadius: 42,
    borderWidth: 5,
    height: 82,
    justifyContent: "center",
    width: 82,
  },
  finishButton: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    height: 48,
    justifyContent: "center",
    paddingHorizontal: 15,
  },
  finishButtonDisabled: {
    backgroundColor: "rgba(255,255,255,0.14)",
  },
  finishButtonText: {
    color: "#fff",
    fontSize: 11.5,
    fontWeight: "900",
  },
  authFallback: {
    backgroundColor: megrumColors.background,
    flex: 1,
    gap: 14,
    paddingHorizontal: 20,
  },
  authTitle: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
  },
  authText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 20,
  },
});
