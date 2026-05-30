import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { router, Stack, useLocalSearchParams } from "expo-router";
import {
  Alert,
  Image,
  Linking,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useAuth } from "../src/auth/AuthProvider";
import { ChatGradientBubble } from "../src/components/ChatGradientBubble";
import { PrimaryButton } from "../src/components/PrimaryButton";
import {
  NativeMapPreview,
  type MapCoordinate,
} from "../src/components/NativeMapPreview";
import { StatusPill } from "../src/components/StatusPill";
import {
  approveTradeCancel,
} from "../src/lib/transactionActions";
import {
  fetchMailingAddressSnapshot,
  formatMailingAddressLines,
  normalizeExchangeMethod,
  parseMailingAddressSnapshot,
  supportsHandExchange,
  supportsMailExchange,
  toMailingAddressSnapshot,
  type ExchangeMethod,
  type MailingAddressSnapshot,
} from "../src/lib/mailingAddress";
import { supabase } from "../src/lib/supabase";
import { useKeyboardInset } from "../src/lib/useKeyboardInset";
import { goToTabRoot } from "../src/navigation/hierarchy";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type ProposalStatus =
  | "sent"
  | "negotiating"
  | "agreement_one_side"
  | "agreed"
  | "completed"
  | "cancelled"
  | "rejected"
  | "expired";

type ProposalRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  cash_offer: boolean | null;
  cash_amount: number | null;
  sender_have_ids: string[] | null;
  sender_have_qtys: number[] | null;
  receiver_have_ids: string[] | null;
  receiver_have_qtys: number[] | null;
  agreed_by_sender: boolean | null;
  agreed_by_receiver: boolean | null;
  meetup_start_at: string | null;
  meetup_end_at: string | null;
  meetup_place_name: string | null;
  meetup_lat: number | null;
  meetup_lng: number | null;
  meetup_candidates: unknown;
  exchange_method: string | null;
  option_tags: string[] | null;
  sender_mailing_address: unknown;
  receiver_mailing_address: unknown;
  evidence_photo_url: string | null;
  evidence_taken_at: string | null;
  approved_by_sender: boolean | null;
  approved_by_receiver: boolean | null;
  message: string | null;
  created_at: string;
  last_action_at: string | null;
  expires_at: string | null;
  extension_count: number | null;
};

type UserRow = {
  id: string;
  handle: string | null;
  display_name: string | null;
  primary_area: string | null;
  avatar_url: string | null;
};

type InventoryRow = {
  id: string;
  title: string;
  photo_urls: string[] | null;
  hue?: number | string | null;
  group: { name: string | null } | { name: string | null }[] | null;
  character: { name: string | null } | { name: string | null }[] | null;
  goods_type: { name: string | null } | { name: string | null }[] | null;
};

type DetailItem = {
  id: string;
  label: string;
  goodsType: string | null;
  photoUrl: string | null;
  qty: number;
  hue: string;
};

type MeetupCandidate = {
  startAt: string;
  endAt: string;
  placeName: string;
  lat: number | null;
  lng: number | null;
};

type AcceptDecision = {
  exchangeMethod: Exclude<ExchangeMethod, "both">;
  meetup: MeetupCandidate | null;
};

const FALLBACK_MEETUP_COORDINATE: MapCoordinate = {
  latitude: 35.5075,
  longitude: 139.6174,
};

type TransactionDetail = {
  id: string;
  status: ProposalStatus;
  exchangeMethod: ExchangeMethod;
  isSender: boolean;
  isReceiver: boolean;
  myAgreed: boolean;
  partnerAgreed: boolean;
  myCompletionApproved: boolean;
  partnerCompletionApproved: boolean;
  hasEvidence: boolean;
  evidencePhotoCount: number;
  evidenceTakenAt: string | null;
  partner: UserRow;
  receive: DetailItem[];
  give: DetailItem[];
  cashOffer: boolean;
  cashAmount: number | null;
  optionTags: string[];
  meetups: MeetupCandidate[];
  message: string | null;
  expiresAt: string | null;
  extensionCount: number;
  openDispute: OpenDispute | null;
  myArrival: ArrivalStatus;
  partnerArrival: ArrivalStatus;
  myOutfitPhoto: string | null;
  partnerOutfitPhoto: string | null;
  mailingAddresses: {
    mine: MailingAddressSnapshot | null;
    partner: MailingAddressSnapshot | null;
  };
  partnerLastReadAt: string | null;
  messages: ChatMessage[];
};

type ArrivalStatus = "enroute" | "arrived" | "left" | null;

type OpenDispute = {
  id: string;
  ticketNo: string;
};

type ChatMessage = {
  id: string;
  senderId: string;
  type:
    | "text"
    | "photo"
    | "outfit_photo"
    | "location"
    | "arrival_status"
    | "system";
  body: string | null;
  photoUrl: string | null;
  locationLat: number | null;
  locationLng: number | null;
  locationLabel: string | null;
  meta: Record<string, unknown> | null;
  createdAt: string;
};

type ProposalReadStateRow = {
  last_read_at: string | null;
};

type MessageRow = {
  id: string;
  sender_id: string;
  message_type: ChatMessage["type"];
  body: string | null;
  photo_url: string | null;
  location_lat: number | null;
  location_lng: number | null;
  location_label: string | null;
  meta: Record<string, unknown> | null;
  created_at: string;
};

export default function TransactionDetailScreen() {
  const params = useLocalSearchParams<{
    id?: string | string[];
    direction?: string | string[];
    give?: string | string[];
    note?: string | string[];
    partner?: string | string[];
    partnerAvatarUrl?: string | string[];
    place?: string | string[];
    receive?: string | string[];
    status?: string | string[];
    time?: string | string[];
  }>();
  const { id } = params;
  const proposalId = Array.isArray(id) ? id[0] : id;
  const { user, previewMode, exitPreview } = useAuth();
  const insets = useSafeAreaInsets();
  const [detail, setDetail] = useState<TransactionDetail | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState<
    "accept" | "negotiate" | "reject" | "extend" | "enroute" | "arrived" | null
  >(null);
  const [chatActionLoading, setChatActionLoading] = useState<
    "photo" | "outfit" | "location" | "evidence" | null
  >(null);
  const [acceptDecisionOpen, setAcceptDecisionOpen] = useState(false);
  const [draft, setDraft] = useState("");
  const [sendingMessage, setSendingMessage] = useState(false);
  const [composerFocused, setComposerFocused] = useState(false);
  const messagesScrollRef = useRef<ScrollView>(null);
  const messageEndYRef = useRef(0);
  const messageViewportHeightRef = useRef(0);
  const pendingMessageScrollRef = useRef(false);

  const canAccept = useMemo(() => {
    if (!detail) return false;
    return (
      ["sent", "negotiating", "agreement_one_side"].includes(detail.status) &&
      !detail.myAgreed
    );
  }, [detail]);
  const canNegotiate = detail?.isReceiver && ["sent", "negotiating"].includes(detail.status);
  const canReject = detail?.isReceiver && ["sent", "negotiating"].includes(detail.status);
  const canChat =
    detail &&
    ["sent", "negotiating", "agreement_one_side", "agreed", "completed"].includes(
      detail.status,
    );
  const lastMessageId = detail?.messages[detail.messages.length - 1]?.id ?? null;

  const scrollToLatestMessage = useCallback((animated = true) => {
    requestAnimationFrame(() => {
      const targetY = Math.max(
        0,
        messageEndYRef.current - messageViewportHeightRef.current + 18,
      );
      messagesScrollRef.current?.scrollTo({ y: targetY, animated });
    });
  }, []);

  useEffect(() => {
    if (!lastMessageId) return;
    pendingMessageScrollRef.current = true;
    const timer = setTimeout(() => {
      if (!pendingMessageScrollRef.current) return;
      pendingMessageScrollRef.current = false;
      scrollToLatestMessage(true);
    }, 140);
    return () => clearTimeout(timer);
  }, [lastMessageId, scrollToLatestMessage]);

  useEffect(() => {
    if (!detail || !user || !lastMessageId) return;
    const latestMessage = detail.messages[detail.messages.length - 1];
    if (!latestMessage) return;
    markProposalMessagesRead(detail.id, user.id, latestMessage.createdAt).catch(() => undefined);
  }, [detail?.id, lastMessageId, user?.id]);

  useEffect(() => {
    if (!proposalId) {
      setDetail(null);
      setError("打診IDが見つかりません");
      return;
    }
    if (!supabase || !user || previewMode) {
      setDetail(null);
      setError(
        previewMode
          ? "Preview_hanaでは取引チャットを開けません"
          : "ログイン後に取引詳細を確認できます",
      );
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);
    fetchTransactionDetail(proposalId, user.id)
      .then((next) => {
        if (active) setDetail(next);
      })
      .catch((loadError: unknown) => {
        if (!active) return;
        const fallback = buildRouteFallbackDetail(proposalId, user.id, params);
        if (fallback) {
          setDetail(fallback);
          setError(null);
          return;
        }
        setError(toErrorMessage(loadError, "読み込みに失敗しました"));
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, proposalId, user]);

  async function handleAction(
    action: "accept" | "negotiate" | "reject",
    decision?: AcceptDecision,
  ) {
    if (!detail || !user || !supabase) return;
    setActionLoading(action);
    setError(null);
    try {
      const next = await updateProposalAction(detail, user.id, action, decision);
      setDetail(next);
    } catch (actionError) {
      setError(
        actionError instanceof Error
          ? actionError.message
          : "更新に失敗しました",
      );
    } finally {
      setActionLoading(null);
    }
  }

  function handleAcceptPress() {
    if (!detail) return;
    if (acceptDecisionRequired(detail)) {
      setAcceptDecisionOpen(true);
      return;
    }
    void handleAction("accept", defaultAcceptDecision(detail));
  }

  function openScheduleOverlay() {
    if (!detail) return;
    router.push({
      pathname: "/transaction-schedule",
      params: {
        proposalId: detail.id,
        partnerId: detail.partner.id,
      },
    });
  }

  function openRevisionProposal(method?: ExchangeMethod) {
    if (!detail) return;
    const nextMethod = method ?? detail.exchangeMethod;
    router.push({
      pathname: "/proposal-select",
      params: {
        partnerId: detail.partner.id,
        proposalId: detail.id,
        revise: "1",
        tab: nextMethod === "mail" ? "receive" : "meetup",
        exchangeMethod: nextMethod,
      },
    });
  }

  async function handleExtendProposal() {
    if (!detail || !user || !supabase) return;
    const client = supabase;
    Alert.alert(
      "打診の期限を延長しますか？",
      "現在の期限から7日間延長します。",
      [
        { text: "戻る", style: "cancel" },
        {
          text: "延長する",
          onPress: async () => {
            setActionLoading("extend");
            setError(null);
            try {
              const now = new Date();
              const currentExpires = detail.expiresAt
                ? new Date(detail.expiresAt)
                : null;
              const base =
                currentExpires && currentExpires.getTime() > now.getTime()
                  ? currentExpires
                  : now;
              const nextExpires = new Date(base.getTime() + 7 * 24 * 60 * 60 * 1000);
              const updates: Record<string, unknown> = {
                expires_at: nextExpires.toISOString(),
                extension_count: detail.extensionCount + 1,
                last_action_at: now.toISOString(),
              };
              const { error: updateError } = await client
                .from("proposals")
                .update(updates)
                .eq("id", detail.id);
              const missingColumn = getMissingProposalColumn(updateError);
              if (missingColumn === "extension_count") {
                delete updates.extension_count;
                const { error: retryError } = await client
                  .from("proposals")
                  .update(updates)
                  .eq("id", detail.id);
                if (retryError) throw retryError;
              } else if (updateError) {
                throw updateError;
              }
              await client.from("messages").insert({
                proposal_id: detail.id,
                sender_id: user.id,
                message_type: "system",
                body: "打診期限を7日間延長しました",
                meta: { action: "extend" },
              });
              await refreshDetail();
            } catch (extendError) {
              setError(
                extendError instanceof Error
                  ? extendError.message
                  : "期限延長に失敗しました",
              );
            } finally {
              setActionLoading(null);
            }
          },
        },
      ],
    );
  }

  async function handleSendMessage() {
    if (!detail || !user || !supabase) return;
    const body = draft.trim();
    if (!body) return;
    setSendingMessage(true);
    setError(null);
    try {
      const { error: insertError } = await supabase.from("messages").insert({
        proposal_id: detail.id,
        sender_id: user.id,
        message_type: "text",
        body,
      });
      if (insertError) throw insertError;
      setDraft("");
      setDetail(await fetchTransactionDetail(detail.id, user.id));
    } catch (sendError) {
      setError(sendError instanceof Error ? sendError.message : "送信に失敗しました");
    } finally {
      setSendingMessage(false);
    }
  }

  async function handleArrivalStatus(status: "enroute" | "arrived") {
    if (!detail || !user || !supabase) return;
    setActionLoading(status);
    setError(null);
    try {
      const label = status === "enroute" ? "向かっています" : "到着しました";
      const { error: insertError } = await supabase.from("messages").insert({
        proposal_id: detail.id,
        sender_id: user.id,
        message_type: "arrival_status",
        body: label,
        meta: { status },
      });
      if (insertError) throw insertError;
      setDetail(await fetchTransactionDetail(detail.id, user.id));
    } catch (arrivalError) {
      setError(
        arrivalError instanceof Error
          ? arrivalError.message
          : "ステータス更新に失敗しました",
      );
    } finally {
      setActionLoading(null);
    }
  }

  async function refreshDetail() {
    if (!proposalId || !user) return;
    setDetail(await fetchTransactionDetail(proposalId, user.id));
  }

  async function handleSendCurrentLocation() {
    if (!detail || !user || !supabase) return;
    setChatActionLoading("location");
    setError(null);
    try {
      const ExpoLocation = await import("expo-location");
      const permission = await ExpoLocation.requestForegroundPermissionsAsync();
      if (permission.status !== "granted") {
        setError("位置情報の許可が必要です");
        return;
      }
      const position = await ExpoLocation.getCurrentPositionAsync({
        accuracy: ExpoLocation.Accuracy.Balanced,
      });
      const coordinate = {
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
      };
      const label = await reverseLocationLabel(coordinate);
      const { error: insertError } = await supabase.from("messages").insert({
        proposal_id: detail.id,
        sender_id: user.id,
        message_type: "location",
        body: label ?? "現在地を共有しました",
        location_lat: coordinate.latitude,
        location_lng: coordinate.longitude,
        location_label: label ?? "現在地を共有",
      });
      if (insertError) throw insertError;
      await refreshDetail();
    } catch (locationError) {
      setError(
        locationError instanceof Error
          ? locationError.message
          : "現在地の送信に失敗しました",
      );
    } finally {
      setChatActionLoading(null);
    }
  }

  async function handlePickChatPhoto(kind: "photo" | "outfit_photo") {
    if (!detail || !user || !supabase) return;
    if (kind === "outfit_photo" && detail.status !== "agreed") {
      setError("服装写真は取引予定でのみ共有できます");
      return;
    }
    setChatActionLoading(kind === "outfit_photo" ? "outfit" : "photo");
    setError(null);
    try {
      const ImagePicker = await import("expo-image-picker");
      const permission =
        await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (!permission.granted) {
        setError("写真ライブラリの利用を許可してください");
        return;
      }
      const result = await ImagePicker.launchImageLibraryAsync({
        allowsEditing: true,
        aspect: kind === "outfit_photo" ? [3, 4] : [1, 1],
        mediaTypes: ["images"],
        quality: 0.86,
      });
      if (result.canceled || !result.assets[0]) return;
      const asset = result.assets[0];
      const photoUrl = await uploadChatImage({
        proposalId: detail.id,
        uri: asset.uri,
        mimeType: asset.mimeType ?? null,
        fileName: asset.fileName ?? null,
        kind,
      });
      const { error: insertError } = await supabase.from("messages").insert({
        proposal_id: detail.id,
        sender_id: user.id,
        message_type: kind,
        body: kind === "outfit_photo" ? "服装写真を共有しました" : null,
        photo_url: photoUrl,
      });
      if (insertError) throw insertError;
      await refreshDetail();
    } catch (photoError) {
      setError(
        photoError instanceof Error
          ? photoError.message
          : "写真の送信に失敗しました",
      );
    } finally {
      setChatActionLoading(null);
    }
  }

  function openEvidenceCapturePrompt() {
    if (!detail) return;
    const targetId = detail.id;
    Alert.alert(
      "交換したグッズを撮影してください",
      "両者の交換物が1枚に収まるように撮影してください。",
      [
        { text: "戻る", style: "cancel" },
        {
          text: "撮影する",
          onPress: () =>
            router.push({ pathname: "/transaction-capture", params: { id: targetId } }),
        },
      ],
    );
  }

  const bottomInset = Math.max(insets.bottom, 12);
  const keyboardInset = useKeyboardInset();
  const composerBottomInset = keyboardInset > 0 ? 8 : bottomInset;
  const showComposer = !!detail && detail.status !== "completed" && !!canChat;

  return (
    <View style={styles.chatRoot}>
      <Stack.Screen
        options={{
          headerShown: true,
          title: detail
            ? `@${(detail.partner.handle ?? detail.partner.display_name ?? "取引チャット").replace(
                /^@/,
                "",
              )}`
            : "取引チャット",
          headerBackButtonDisplayMode: "minimal",
          headerBlurEffect: "systemMaterial",
          headerTintColor: megrumColors.lavender,
          headerRight: () =>
            detail ? (
              <Pressable
                accessibilityRole="button"
                accessibilityLabel="取引を通報"
                onPress={() =>
                  router.push({
                    pathname: "/dispute-new",
                    params: { proposalId: detail.id },
                  })
                }
                style={styles.headerReportButton}
              >
                <Text style={styles.headerReportText}>通報</Text>
              </Pressable>
            ) : null,
        }}
      />
      {detail ? (
        <ChatPartnerStrip detail={detail} />
      ) : null}

      {loading ? <Text style={styles.inlineNotice}>取引を読み込み中…</Text> : null}
      {error ? <Text style={styles.inlineError}>{error}</Text> : null}

      {(previewMode || !user) && !detail ? (
        <View style={styles.loginPromptWrap}>
          <View style={styles.loginPrompt}>
            <Text style={styles.loginPromptTitle}>michilionでログイン</Text>
            <Text style={styles.loginPromptText}>
              取引チャットは実アカウントの打診データに接続して表示します。
            </Text>
            <PrimaryButton
              onPress={() => {
                exitPreview();
                router.replace("/login");
              }}
            >
              ログインして取引チャットを見る
            </PrimaryButton>
          </View>
        </View>
      ) : null}

      {detail ? (
        <>
          <View style={styles.chatPinnedArea}>
            {detail.openDispute ? (
              <OpenDisputeBanner dispute={detail.openDispute} />
            ) : null}
            <ExchangeMethodSummaryCard detail={detail} />
            <DealSummaryCard detail={detail} />
            {detail.status === "sent" ||
            detail.status === "negotiating" ||
            detail.status === "agreement_one_side" ? (
              <>
                <ExpireBannerCompact
                  detail={detail}
                  loading={actionLoading === "extend"}
                  onExtend={handleExtendProposal}
                />
                <AgreementBarCompact
                  detail={detail}
                  canAccept={canAccept}
                  canReject={!!canReject}
                  loading={actionLoading}
                  onAccept={handleAcceptPress}
                  onReject={() => handleAction("reject")}
                />
              </>
            ) : null}
            {detail.status === "agreed" && supportsHandExchange(detail.exchangeMethod) ? (
              <OutfitCompactRowNative
                detail={detail}
                uploading={chatActionLoading === "outfit"}
                onTake={() => handlePickChatPhoto("outfit_photo")}
              />
            ) : null}
          </View>

          <ScrollView
            ref={messagesScrollRef}
            onContentSizeChange={() => {
              if (!pendingMessageScrollRef.current) return;
              scrollToLatestMessage(true);
            }}
            onLayout={(event) => {
              messageViewportHeightRef.current = event.nativeEvent.layout.height;
            }}
            style={styles.chatMessagesScroll}
            contentContainerStyle={[
              styles.chatMessagesContent,
              { paddingBottom: showComposer ? 14 : 24 + bottomInset },
            ]}
          >
              <ChatMessageList
                messages={detail.messages}
                partnerLastReadAt={detail.partnerLastReadAt}
                proposalId={detail.id}
                userId={user?.id ?? ""}
              />
            <View
              onLayout={(event) => {
                messageEndYRef.current = event.nativeEvent.layout.y;
                if (!pendingMessageScrollRef.current) return;
                pendingMessageScrollRef.current = false;
                scrollToLatestMessage(true);
              }}
              style={styles.chatMessageEndAnchor}
            />
            {detail.status === "completed" ||
            (detail.status === "agreed" && detail.hasEvidence) ? (
              <CompletionPanel
                detail={detail}
                evidenceUploading={false}
                onAddEvidence={openEvidenceCapturePrompt}
              />
            ) : null}
          </ScrollView>

          {showComposer ? (
            <View
              style={[
                styles.bottomComposer,
                { marginBottom: keyboardInset, paddingBottom: composerBottomInset },
              ]}
            >
              {detail.status === "agreed" && !detail.hasEvidence ? (
                <Pressable
                  accessibilityRole="button"
                  onPress={openEvidenceCapturePrompt}
                  style={styles.evidenceFixedFooterButton}
                >
                  <Text style={styles.evidenceFixedFooterText}>交換後にグッズを撮影</Text>
                </Pressable>
              ) : null}
              {!composerFocused ? (
                <ScrollView
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  contentContainerStyle={styles.webQuickActionRow}
                >
                  {detail.status === "agreed" ? (
                    <>
                      {supportsHandExchange(detail.exchangeMethod) ? (
                        <>
                        <QuickActionChip
                          label={chatActionLoading === "location" ? "送信中…" : "現在地を送る"}
                          icon="⌖"
                          tone="lavender"
                          disabled={!!chatActionLoading}
                          onPress={handleSendCurrentLocation}
                        />
                        <QuickActionChip
                          label={actionLoading === "enroute" ? "更新中…" : "向かっています"}
                          icon="↗"
                          tone={detail.myArrival === "enroute" ? "lavender" : "neutral"}
                          disabled={!!actionLoading}
                          onPress={() => handleArrivalStatus("enroute")}
                        />
                        <QuickActionChip
                          label={actionLoading === "arrived" ? "更新中…" : "到着しました"}
                          icon="✓"
                          tone={detail.myArrival === "arrived" ? "lavender" : "neutral"}
                          disabled={!!actionLoading}
                          onPress={() => handleArrivalStatus("arrived")}
                        />
                        <QuickActionChip
                          label={chatActionLoading === "outfit" ? "送信中…" : "服装写真"}
                          icon="👕"
                          tone="pink"
                          disabled={!!chatActionLoading}
                          onPress={() => handlePickChatPhoto("outfit_photo")}
                        />
                        <QuickActionChip
                          label="遅刻を申請"
                          icon="!"
                          tone="neutral"
                          disabled={!!chatActionLoading}
                          onPress={() =>
                            router.push({
                              pathname: "/transaction-cancel-or-late",
                              params: { id: detail.id, kind: "late" },
                            })
                          }
                        />
                      </>
                      ) : null}
                      <QuickActionChip
                        label="キャンセル申請"
                        icon="!"
                        tone="pink"
                        disabled={!!chatActionLoading}
                        onPress={() =>
                          router.push({
                            pathname: "/transaction-cancel-or-late",
                            params: { id: detail.id, kind: "cancel" },
                          })
                        }
                      />
                    </>
                  ) : (
                    <>
                      <QuickActionChip
                        label="スケジュール"
                        icon="□"
                        tone="lavender"
                        disabled={!!chatActionLoading}
                        onPress={openScheduleOverlay}
                      />
                      <QuickActionChip
                        label="条件を変えて再打診"
                        icon="↻"
                        tone="pink"
                        disabled={!!chatActionLoading}
                        onPress={() => openRevisionProposal()}
                      />
                    </>
                  )}
                </ScrollView>
              ) : null}
              <View style={styles.webComposerRow}>
                <Pressable
                  accessibilityRole="button"
                  onPress={() => handlePickChatPhoto("photo")}
                  style={styles.composerPlusButton}
                >
                  <Text style={styles.composerPlusText}>＋</Text>
                </Pressable>
                <TextInput
                  value={draft}
                  onChangeText={setDraft}
                  placeholder="メッセージ…"
                  placeholderTextColor="rgba(58,50,74,0.38)"
                  multiline
                  onBlur={() => setComposerFocused(false)}
                  onFocus={() => setComposerFocused(true)}
                  scrollEnabled
                  style={styles.webComposerInput}
                  textAlignVertical="top"
                />
                <Pressable
                  disabled={sendingMessage || draft.trim().length === 0}
                  onPress={handleSendMessage}
                  style={[
                    styles.webSendButton,
                    sendingMessage || draft.trim().length === 0
                      ? styles.sendButtonDisabled
                      : null,
                  ]}
                >
                  <Text style={styles.webSendButtonText}>➤</Text>
                </Pressable>
              </View>
            </View>
          ) : null}
          <AcceptDecisionModal
            detail={detail}
            visible={acceptDecisionOpen}
            loading={actionLoading === "accept"}
            onClose={() => setAcceptDecisionOpen(false)}
            onCounter={(method) => {
              setAcceptDecisionOpen(false);
              openRevisionProposal(method);
            }}
            onConfirm={(decision) => {
              setAcceptDecisionOpen(false);
              void handleAction("accept", decision);
            }}
          />
        </>
      ) : null}
    </View>
  );
}

type TransactionRouteParams = {
  direction?: string | string[];
  give?: string | string[];
  note?: string | string[];
  partner?: string | string[];
  partnerAvatarUrl?: string | string[];
  place?: string | string[];
  receive?: string | string[];
  status?: string | string[];
  time?: string | string[];
};

type ChatUploadKind = "photo" | "outfit_photo";
type ChatCoordinate = { latitude: number; longitude: number };

async function reverseLocationLabel(coordinate: ChatCoordinate) {
  try {
    const ExpoLocation = await import("expo-location");
    const addresses = await ExpoLocation.reverseGeocodeAsync(coordinate);
    const first = addresses[0];
    const parts = [
      first?.city,
      first?.district,
      first?.street,
      first?.name,
    ].filter(Boolean);
    return parts.length > 0 ? parts.join(" ") : "現在地を共有";
  } catch {
    return "現在地を共有";
  }
}

async function uploadChatImage(input: {
  proposalId: string;
  uri: string;
  mimeType?: string | null;
  fileName?: string | null;
  kind: ChatUploadKind;
}) {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const ext = extensionFrom(input.fileName ?? input.uri, input.mimeType);
  const prefix = input.kind === "outfit_photo" ? "outfit" : "chat";
  const path = `${input.proposalId}/${prefix}-${Date.now()}.${ext}`;
  const response = await fetch(input.uri);
  const body = await response.arrayBuffer();
  const { error: uploadError } = await supabase.storage
    .from("chat-photos")
    .upload(path, body, {
      contentType: input.mimeType ?? "image/jpeg",
      upsert: false,
    });
  if (uploadError) throw uploadError;
  const { data: signed, error: signedError } = await supabase.storage
    .from("chat-photos")
    .createSignedUrl(path, 60 * 60 * 24 * 365);
  if (signedError) throw signedError;
  return signed?.signedUrl ?? path;
}

function extensionFrom(nameOrUri: string, mimeType?: string | null) {
  const fromName = nameOrUri.split("?")[0]?.split(".").pop()?.toLowerCase();
  if (fromName && fromName.length <= 5 && /^[a-z0-9]+$/.test(fromName)) {
    return fromName === "jpeg" ? "jpg" : fromName;
  }
  if (mimeType?.includes("png")) return "png";
  if (mimeType?.includes("heic")) return "heic";
  return "jpg";
}

type RouteTradeItem = {
  id?: string;
  glyph?: string;
  hue?: string;
  label?: string;
  cash?: boolean;
  photoUrl?: string | null;
};

function buildRouteFallbackDetail(
  proposalId: string,
  userId: string,
  params: TransactionRouteParams,
): TransactionDetail | null {
  const partner = one(params.partner);
  const status = one(params.status);
  if (!partner || !status) return null;
  const direction = one(params.direction);
  const isSender = direction === "sent";
  const place = one(params.place);
  const time = one(params.time);
  const avatarUrl = one(params.partnerAvatarUrl);
  return {
    id: proposalId,
    status: normalizeStatus(status),
    exchangeMethod: "hand",
    isSender,
    isReceiver: !isSender,
    myAgreed: status === "agreed" || status === "completed",
    partnerAgreed: status === "agreed" || status === "completed",
    myCompletionApproved: status === "completed",
    partnerCompletionApproved: status === "completed",
    hasEvidence: false,
    evidencePhotoCount: 0,
    evidenceTakenAt: null,
    partner: {
      id: "partner-from-list",
      handle: partner,
      display_name: partner,
      primary_area: place ?? null,
      avatar_url: avatarUrl || null,
    },
    receive: parseRouteItems(one(params.receive)),
    give: parseRouteItems(one(params.give)),
    cashOffer: false,
    cashAmount: null,
    optionTags: [],
    meetups:
      place && time
        ? [
            {
              startAt: "",
              endAt: "",
              placeName: `${time} / ${place}`,
              lat: null,
              lng: null,
            },
          ]
        : [],
    message: one(params.note) ?? null,
    expiresAt: null,
    extensionCount: 0,
    openDispute: null,
    myArrival: null,
    partnerArrival: null,
    myOutfitPhoto: null,
    partnerOutfitPhoto: null,
    mailingAddresses: {
      mine: null,
      partner: null,
    },
    partnerLastReadAt: null,
    messages: [],
  };
}

function parseRouteItems(raw: string | undefined): DetailItem[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.map((item: RouteTradeItem, index) => {
      const label = typeof item.label === "string" && item.label ? item.label : "グッズ";
      return {
        id: typeof item.id === "string" ? item.id : `route-item-${index}`,
        label,
        goodsType: item.cash ? "定価交換" : null,
        photoUrl: typeof item.photoUrl === "string" ? item.photoUrl : null,
        qty: 1,
        hue: typeof item.hue === "string" ? item.hue : normalizeHue(null, label),
      };
    });
  } catch {
    return [];
  }
}

function one(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value;
}

function normalizeStringArray(value: unknown) {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string" && item.trim().length > 0)
    : [];
}

async function fetchTransactionDetail(
  proposalId: string,
  userId: string,
): Promise<TransactionDetail> {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const coreProposalFields = [
    "id",
    "sender_id",
    "receiver_id",
    "status",
    "cash_offer",
    "cash_amount",
    "sender_have_ids",
    "sender_have_qtys",
    "receiver_have_ids",
    "receiver_have_qtys",
    "agreed_by_sender",
    "agreed_by_receiver",
    "meetup_start_at",
    "meetup_end_at",
    "meetup_place_name",
    "message",
    "created_at",
    "expires_at",
    "extension_count",
    "exchange_method",
    "option_tags",
  ];
  const optionalProposalFields = [
    "meetup_lat",
    "meetup_lng",
    "meetup_candidates",
    "evidence_photo_url",
    "evidence_taken_at",
    "approved_by_sender",
    "approved_by_receiver",
    "last_action_at",
    "sender_mailing_address",
    "receiver_mailing_address",
  ];
  const proposalFields = [...coreProposalFields, ...optionalProposalFields];
  let data: Record<string, unknown> | null = null;
  try {
    data = await fetchProposalRow(proposalId, proposalFields);
  } catch (richFetchError) {
    console.warn("transaction detail rich fetch failed; falling back to core fields", richFetchError);
    data = await fetchProposalRow(proposalId, coreProposalFields);
  }
  if (!data) throw new Error("打診が見つかりません");

  return buildDetail(
    {
      cash_offer: false,
      cash_amount: null,
      meetup_candidates: [],
      meetup_lat: null,
      meetup_lng: null,
      evidence_photo_url: null,
      evidence_taken_at: null,
      approved_by_sender: false,
      approved_by_receiver: false,
      extension_count: 0,
      exchange_method: "hand",
      option_tags: [],
      sender_mailing_address: null,
      receiver_mailing_address: null,
      ...data,
    } as unknown as ProposalRow,
    userId,
  );
}

async function fetchProposalRow(
  proposalId: string,
  fields: string[],
): Promise<Record<string, unknown> | null> {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const selectableFields = [...fields];
  for (let attempt = 0; attempt < fields.length; attempt += 1) {
    const { data, error } = await supabase
      .from("proposals")
      .select(selectableFields.join(", "))
      .eq("id", proposalId)
      .maybeSingle();
    const missingColumn = getMissingProposalColumn(error);
    if (missingColumn && selectableFields.includes(missingColumn)) {
      selectableFields.splice(selectableFields.indexOf(missingColumn), 1);
      continue;
    }
    if (error) throw error;
    return (data as Record<string, unknown> | null) ?? null;
  }
  return null;
}

function getMissingProposalColumn(error: { code?: string; message?: string } | null) {
  const message = error?.message ?? "";
  if (
    error?.code !== "PGRST204" &&
    error?.code !== "42703" &&
    !message.includes("schema cache") &&
    !message.includes("does not exist")
  ) {
    return null;
  }
  return (
    getMissingColumnName(error, "proposals")
  );
}

function getMissingColumnName(
  error: { code?: string; message?: string } | null,
  tableName: string,
) {
  const message = error?.message ?? "";
  return (
    message.match(new RegExp(`Could not find the '([^']+)' column of '${tableName}'`))?.[1] ??
    message.match(new RegExp(`column ${tableName}\\.([a-zA-Z0-9_]+) does not exist`))?.[1] ??
    message.match(/column "([a-zA-Z0-9_]+)" does not exist/)?.[1] ??
    null
  );
}

function isMissingRelationError(
  error: { code?: string; message?: string } | null,
  tableName: string,
) {
  const message = error?.message ?? "";
  return (
    error?.code === "42P01" ||
    error?.code === "PGRST205" ||
    message.includes(`relation "public.${tableName}" does not exist`) ||
    message.includes(`Could not find the table '${tableName}'`) ||
    message.includes(`Could not find the table 'public.${tableName}'`)
  );
}

function toErrorMessage(error: unknown, fallback: string) {
  if (error instanceof Error) return error.message;
  if (
    typeof error === "object" &&
    error &&
    "message" in error &&
    typeof error.message === "string"
  ) {
    return error.message;
  }
  return fallback;
}

async function buildDetail(
  proposal: ProposalRow,
  userId: string,
): Promise<TransactionDetail> {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const isSender = proposal.sender_id === userId;
  const isReceiver = proposal.receiver_id === userId;
  if (!isSender && !isReceiver) throw new Error("この打診には参加していません");

  const partnerId = isSender ? proposal.receiver_id : proposal.sender_id;
  const giveIds = isSender
    ? proposal.sender_have_ids ?? []
    : proposal.receiver_have_ids ?? [];
  const giveQtys = isSender
    ? proposal.sender_have_qtys ?? []
    : proposal.receiver_have_qtys ?? [];
  const receiveIds = isSender
    ? proposal.receiver_have_ids ?? []
    : proposal.sender_have_ids ?? [];
  const receiveQtys = isSender
    ? proposal.receiver_have_qtys ?? []
    : proposal.sender_have_qtys ?? [];
  const itemIds = Array.from(new Set([...giveIds, ...receiveIds]));

  const [partnerData, inventoryData, evidencePhotos, openDispute] = await Promise.all([
    fetchPartnerUser(partnerId),
    fetchDetailInventoryRows(itemIds),
    fetchEvidencePhotoRows(proposal.id),
    fetchOpenDispute(proposal.id),
  ]);

  const inventoryById = new Map(
    inventoryData.map((item) => [
      item.id,
      item,
    ]),
  );
  const evidencePhotoCount = evidencePhotos.length;
  const [messages, partnerLastReadAt] = await Promise.all([
    fetchMessages(proposal.id, proposal),
    fetchProposalLastReadAt(proposal.id, partnerId),
  ]);
  const liveState = summarizeLiveMessages(messages, userId, partnerId);
  const exchangeMethod = normalizeExchangeMethod(proposal.exchange_method);
  const mailingAddresses = await resolveProposalMailingAddresses({
    exchangeMethod,
    isSender,
    proposal,
    userId,
  });

  return {
    id: proposal.id,
    status: normalizeStatus(proposal.status),
    exchangeMethod,
    isSender,
    isReceiver,
    myAgreed: isSender
      ? !!proposal.agreed_by_sender
      : !!proposal.agreed_by_receiver,
    partnerAgreed: isSender
      ? !!proposal.agreed_by_receiver
      : !!proposal.agreed_by_sender,
    myCompletionApproved: isSender
      ? !!proposal.approved_by_sender
      : !!proposal.approved_by_receiver,
    partnerCompletionApproved: isSender
      ? !!proposal.approved_by_receiver
      : !!proposal.approved_by_sender,
    hasEvidence: evidencePhotoCount > 0 || !!proposal.evidence_photo_url,
    evidencePhotoCount,
    evidenceTakenAt: proposal.evidence_taken_at,
    partner:
      partnerData ?? {
        id: partnerId,
        handle: "unknown",
        display_name: "unknown",
        primary_area: null,
        avatar_url: null,
      },
    receive: receiveIds.map((id, index) =>
      toDetailItem(id, receiveQtys[index] ?? 1, inventoryById.get(id)),
    ),
    give: giveIds.map((id, index) =>
      toDetailItem(id, giveQtys[index] ?? 1, inventoryById.get(id)),
    ),
    cashOffer: !!proposal.cash_offer,
    cashAmount: proposal.cash_amount,
    optionTags: normalizeStringArray(proposal.option_tags),
    meetups: parseMeetups(proposal),
    message: proposal.message,
    expiresAt: proposal.expires_at,
    extensionCount: Number(proposal.extension_count ?? 0),
    openDispute,
    myArrival: liveState.myArrival,
    partnerArrival: liveState.partnerArrival,
    myOutfitPhoto: liveState.myOutfitPhoto,
    partnerOutfitPhoto: liveState.partnerOutfitPhoto,
    mailingAddresses,
    partnerLastReadAt,
    messages,
  };
}

async function resolveProposalMailingAddresses(input: {
  exchangeMethod: ExchangeMethod;
  isSender: boolean;
  proposal: ProposalRow;
  userId: string;
}): Promise<TransactionDetail["mailingAddresses"]> {
  if (!supportsMailExchange(input.exchangeMethod)) {
    return { mine: null, partner: null };
  }

  const senderSnapshot = parseMailingAddressSnapshot(
    input.proposal.sender_mailing_address,
  );
  const receiverSnapshot = parseMailingAddressSnapshot(
    input.proposal.receiver_mailing_address,
  );
  const mineSnapshot = input.isSender ? senderSnapshot : receiverSnapshot;
  const partnerSnapshot = input.isSender ? receiverSnapshot : senderSnapshot;
  const finalised =
    input.proposal.status === "agreed" || input.proposal.status === "completed";
  const liveMine = await fetchMailingAddressSnapshot(input.userId, {
    tolerateMissingSchema: true,
  }).catch(() => null);

  return {
    mine: finalised ? mineSnapshot ?? liveMine : liveMine ?? mineSnapshot,
    partner: finalised ? partnerSnapshot : null,
  };
}

async function fetchProposalLastReadAt(proposalId: string, userId: string) {
  if (!supabase) return null;
  const { data, error } = await supabase
    .from("proposal_read_states")
    .select("last_read_at")
    .eq("proposal_id", proposalId)
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    if (!isMissingRelationError(error, "proposal_read_states")) {
      console.warn("proposal read state fetch failed", error);
    }
    return null;
  }
  return ((data as ProposalReadStateRow | null)?.last_read_at) ?? null;
}

async function markProposalMessagesRead(
  proposalId: string,
  userId: string,
  lastReadAt: string,
) {
  if (!supabase) return;
  const { error } = await supabase
    .from("proposal_read_states")
    .upsert(
      {
        proposal_id: proposalId,
        user_id: userId,
        last_read_at: lastReadAt,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "proposal_id,user_id" },
    );
  if (error && !isMissingRelationError(error, "proposal_read_states")) {
    console.warn("proposal read state upsert failed", error);
  }
}

async function fetchPartnerUser(partnerId: string): Promise<UserRow | null> {
  if (!supabase) return null;
  const rich = await supabase
    .from("users")
    .select("id, handle, display_name, primary_area, avatar_url")
    .eq("id", partnerId)
    .maybeSingle();
  const missingColumn = getMissingColumnName(rich.error, "users");
  if (!rich.error) return (rich.data as UserRow | null) ?? null;
  if (missingColumn === "avatar_url") {
    const fallback = await supabase
      .from("users")
      .select("id, handle, display_name, primary_area")
      .eq("id", partnerId)
      .maybeSingle();
    if (!fallback.error && fallback.data) {
      return { ...(fallback.data as Omit<UserRow, "avatar_url">), avatar_url: null };
    }
  }
  console.warn("transaction detail partner fetch failed", rich.error);
  return null;
}

async function fetchDetailInventoryRows(itemIds: string[]): Promise<InventoryRow[]> {
  if (!supabase || itemIds.length === 0) return [];
  const { data, error } = await supabase
    .from("goods_inventory")
    .select(
      "id, title, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
    )
    .in("id", itemIds);
  if (error) {
    console.warn("transaction detail inventory fetch failed", error);
    return [];
  }
  return (data as InventoryRow[] | null) ?? [];
}

async function fetchEvidencePhotoRows(
  proposalId: string,
): Promise<{ id: string; photo_url: string | null; position: number | null; taken_at: string | null }[]> {
  if (!supabase) return [];
  const { data, error } = await supabase
    .from("proposal_evidence_photos")
    .select("id, photo_url, position, taken_at")
    .eq("proposal_id", proposalId)
    .order("position", { ascending: true });
  if (error) {
    console.warn("transaction detail evidence fetch failed", error);
    return [];
  }
  return (
    (data as
      | { id: string; photo_url: string | null; position: number | null; taken_at: string | null }[]
      | null) ?? []
  );
}

async function fetchOpenDispute(proposalId: string): Promise<OpenDispute | null> {
  if (!supabase) return null;
  const { data, error } = await supabase
    .from("disputes")
    .select("id, ticket_no, status")
    .eq("proposal_id", proposalId)
    .neq("status", "closed")
    .limit(1);
  if (error) {
    console.warn("transaction detail dispute fetch failed", error);
    return null;
  }
  const row = (data as { id: string; ticket_no?: string | null }[] | null)?.[0];
  if (!row) return null;
  return {
    id: row.id,
    ticketNo: row.ticket_no ?? row.id.slice(0, 8),
  };
}

function summarizeLiveMessages(
  messages: ChatMessage[],
  userId: string,
  partnerId: string,
) {
  let myArrival: ArrivalStatus = null;
  let partnerArrival: ArrivalStatus = null;
  let myOutfitPhoto: string | null = null;
  let partnerOutfitPhoto: string | null = null;

  for (const message of messages) {
    if (message.type === "arrival_status") {
      const rawStatus = message.meta?.status;
      const status =
        rawStatus === "enroute" || rawStatus === "arrived" || rawStatus === "left"
          ? rawStatus
          : null;
      if (status && message.senderId === userId) myArrival = status;
      if (status && message.senderId === partnerId) partnerArrival = status;
    }
    if (message.type === "outfit_photo" && message.photoUrl) {
      if (message.senderId === userId) myOutfitPhoto = message.photoUrl;
      if (message.senderId === partnerId) partnerOutfitPhoto = message.photoUrl;
    }
  }

  return { myArrival, partnerArrival, myOutfitPhoto, partnerOutfitPhoto };
}

async function fetchMessages(
  proposalId: string,
  proposal: ProposalRow,
): Promise<ChatMessage[]> {
  if (!supabase) return [];
  const selectableFields = [
    "id",
    "sender_id",
    "message_type",
    "body",
    "photo_url",
    "location_lat",
    "location_lng",
    "location_label",
    "meta",
    "created_at",
  ];
  let rows: MessageRow[] = [];
  for (let attempt = 0; attempt < selectableFields.length; attempt += 1) {
    const { data, error } = await supabase
      .from("messages")
      .select(selectableFields.join(", "))
      .eq("proposal_id", proposalId)
      .order("created_at", { ascending: true });
    const missingColumn = getMissingColumnName(error, "messages");
    if (missingColumn && selectableFields.includes(missingColumn)) {
      selectableFields.splice(selectableFields.indexOf(missingColumn), 1);
      continue;
    }
    if (!error) rows = ((data as unknown as MessageRow[] | null) ?? []);
    break;
  }
  const messages: ChatMessage[] = rows.map((row) => ({
    id: row.id,
    senderId: row.sender_id,
    type: row.message_type,
    body: row.body,
    photoUrl: row.photo_url ?? null,
    locationLat: row.location_lat ?? null,
    locationLng: row.location_lng ?? null,
    locationLabel: row.location_label ?? null,
    meta: row.meta ?? null,
    createdAt: row.created_at,
  }));
  if (proposal.message?.trim()) {
    messages.unshift({
      id: `proposal-message-${proposal.id}`,
      senderId: proposal.sender_id,
      type: "text",
      body: proposal.message,
      photoUrl: null,
      locationLat: null,
      locationLng: null,
      locationLabel: null,
      meta: { virtual: "proposal_message" },
      createdAt: proposal.created_at,
    });
  }
  return messages;
}

async function updateProposalAction(
  detail: TransactionDetail,
  userId: string,
  action: "accept" | "negotiate" | "reject",
  decision?: AcceptDecision,
) {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const now = new Date().toISOString();
  const updates: Record<string, unknown> = { last_action_at: now };

  if (action === "accept") {
    const acceptedMethod = decision?.exchangeMethod ?? resolveSingleExchangeMethod(detail);
    if (!acceptedMethod) {
      throw new Error("交換手段を1つ選んでください。");
    }
    updates.exchange_method = acceptedMethod;
    if (acceptedMethod === "hand") {
      const selectedMeetup =
        decision?.meetup ??
        (detail.meetups.length === 1 ? detail.meetups[0] : null);
      if (!selectedMeetup) {
        throw new Error("現地交換で進める候補日時を1つ選んでください。");
      }
      updates.meetup_start_at = selectedMeetup.startAt;
      updates.meetup_end_at = selectedMeetup.endAt;
      updates.meetup_place_name = selectedMeetup.placeName;
      updates.meetup_lat = selectedMeetup.lat;
      updates.meetup_lng = selectedMeetup.lng;
      updates.meetup_candidates = [meetupToProposalJson(selectedMeetup, 0)];
    }
    const senderId = detail.isSender ? userId : detail.partner.id;
    const receiverId = detail.isReceiver ? userId : detail.partner.id;
    let myMailingAddress: MailingAddressSnapshot | null = null;
    if (supportsMailExchange(acceptedMethod)) {
      myMailingAddress = await fetchMailingAddressSnapshot(userId, {
        tolerateMissingSchema: true,
      }).catch(() => null);
      if (!myMailingAddress) {
        throw new Error("郵送交換に合意する前に住所を登録してください。");
      }
      if (detail.isSender) {
        updates.sender_mailing_address = toMailingAddressSnapshot(myMailingAddress);
      }
      if (detail.isReceiver) {
        updates.receiver_mailing_address = toMailingAddressSnapshot(myMailingAddress);
      }
    }
    const agreedBySender = detail.isSender ? true : detail.partnerAgreed;
    const agreedByReceiver = detail.isReceiver ? true : detail.partnerAgreed;
    updates.agreed_by_sender = agreedBySender;
    updates.agreed_by_receiver = agreedByReceiver;
    updates.status =
      agreedBySender && agreedByReceiver ? "agreed" : "agreement_one_side";
    if (supportsMailExchange(acceptedMethod) && updates.status === "agreed") {
      const [senderAddress, receiverAddress] = await Promise.all([
        detail.isSender
          ? Promise.resolve(myMailingAddress)
          : fetchMailingAddressSnapshot(senderId, { tolerateMissingSchema: true }).catch(
              () => null,
            ),
        detail.isReceiver
          ? Promise.resolve(myMailingAddress)
          : fetchMailingAddressSnapshot(receiverId, {
              tolerateMissingSchema: true,
            }).catch(() => null),
      ]);
      if (!senderAddress || !receiverAddress) {
        throw new Error("郵送交換を成立させるには、双方の住所登録が必要です。");
      }
      updates.sender_mailing_address = toMailingAddressSnapshot(senderAddress);
      updates.receiver_mailing_address = toMailingAddressSnapshot(receiverAddress);
    }
  } else if (action === "negotiate") {
    updates.status = "negotiating";
  } else {
    updates.status = "rejected";
  }

  const { error } = await supabase
    .from("proposals")
    .update(updates)
    .eq("id", detail.id);
  if (error) throw error;

  const systemBody =
    action === "accept"
      ? updates.status === "agreed"
        ? "両者が合意しました。取引を進めましょう ✓"
        : "あなたが合意しました（相手の合意待ち）"
      : action === "negotiate"
        ? "条件相談に進みました"
        : "打診が見送られました";

  await supabase.from("messages").insert({
    proposal_id: detail.id,
    sender_id: userId,
    message_type: "system",
    body: systemBody,
    meta: { action, decision },
  });

  return fetchTransactionDetail(detail.id, userId);
}

function resolveSingleExchangeMethod(
  detail: TransactionDetail,
): AcceptDecision["exchangeMethod"] | null {
  if (detail.exchangeMethod === "both") return null;
  return detail.exchangeMethod;
}

function defaultAcceptDecision(detail: TransactionDetail): AcceptDecision | undefined {
  const exchangeMethod = resolveSingleExchangeMethod(detail);
  if (!exchangeMethod) return undefined;
  return {
    exchangeMethod,
    meetup:
      exchangeMethod === "hand" && detail.meetups.length === 1
        ? detail.meetups[0]
        : null,
  };
}

function acceptDecisionRequired(detail: TransactionDetail) {
  if (detail.exchangeMethod === "both") return true;
  if (detail.exchangeMethod === "hand" && detail.meetups.length !== 1) return true;
  return false;
}

function meetupToProposalJson(meetup: MeetupCandidate, index: number) {
  return {
    id: `accepted-${index + 1}`,
    label: `候補${index + 1}`,
    startAt: meetup.startAt,
    endAt: meetup.endAt,
    placeName: meetup.placeName,
    place: meetup.placeName,
    lat: meetup.lat,
    lng: meetup.lng,
    latitude: meetup.lat,
    longitude: meetup.lng,
  };
}

function ExchangeMethodSummaryCard({ detail }: { detail: TransactionDetail }) {
  const [detailOpen, setDetailOpen] = useState(false);
  return (
    <>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="交換手段の詳細を表示"
        onPress={() => setDetailOpen(true)}
        style={({ pressed }) => [
          styles.dealCollapsedCard,
          pressed ? styles.dealCollapsedCardPressed : null,
        ]}
      >
        <Text style={styles.dealCollapsedLabel}>交換手段</Text>
        <Text numberOfLines={1} style={styles.dealCollapsedSummary}>
          {exchangeMethodSummary(detail.exchangeMethod)}
        </Text>
        <Text style={styles.dealCollapsedAction}>詳細</Text>
      </Pressable>
      <ExchangeMethodDetailModal
        detail={detail}
        visible={detailOpen}
        onClose={() => setDetailOpen(false)}
      />
    </>
  );
}

function ExchangeMethodDetailModal({
  detail,
  visible,
  onClose,
}: {
  detail: TransactionDetail;
  visible: boolean;
  onClose: () => void;
}) {
  return (
    <Modal animationType="fade" transparent visible={visible} onRequestClose={onClose}>
      <Pressable style={styles.dealModalBackdrop} onPress={onClose}>
        <Pressable style={styles.dealModalCard}>
          <View style={styles.dealModalHeader}>
            <View>
              <Text style={styles.dealModalTitle}>交換手段</Text>
              <Text style={styles.dealModalSub}>
                交換手段：{exchangeMethodSummary(detail.exchangeMethod)}
              </Text>
            </View>
            <Pressable accessibilityRole="button" onPress={onClose} style={styles.dealModalClose}>
              <Text style={styles.dealModalCloseText}>×</Text>
            </Pressable>
          </View>

          <ScrollView
            showsVerticalScrollIndicator={false}
            contentContainerStyle={styles.dealModalContent}
          >
            <View style={styles.dealModalSection}>
              <Text style={styles.dealModalSectionTitle}>交換手段</Text>
              <Text style={styles.exchangeMethodModalBody}>
                {exchangeMethodDescription(detail.exchangeMethod)}
              </Text>
            </View>

            {supportsMailExchange(detail.exchangeMethod) ? (
              <MailingAddressDetailPanel
                detail={detail}
                onOpenSettings={() => {
                  onClose();
                  router.push("/address-settings");
                }}
              />
            ) : null}

            {supportsHandExchange(detail.exchangeMethod) ? (
              <View style={styles.dealModalSection}>
                <View style={styles.dealModalSectionHeader}>
                  <Text style={styles.dealModalSectionTitle}>現地交換の候補</Text>
                  <Text style={styles.dealModalSectionCount}>{detail.meetups.length}件</Text>
                </View>
                <DealMeetupCandidateCard meetups={detail.meetups} />
              </View>
            ) : null}
          </ScrollView>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function MailingAddressDetailPanel({
  detail,
  onOpenSettings,
}: {
  detail: TransactionDetail;
  onOpenSettings: () => void;
}) {
  const finalised = detail.status === "agreed" || detail.status === "completed";
  const partnerLabel = detail.partner.handle
    ? `@${detail.partner.handle} の住所`
    : `${detail.partner.display_name ?? "相手"}の住所`;
  const mineLines = detail.mailingAddresses.mine
    ? formatMailingAddressLines(detail.mailingAddresses.mine)
    : ["未登録です。合意前に住所設定を済ませてください。"];
  const partnerLines = detail.mailingAddresses.partner
    ? formatMailingAddressLines(detail.mailingAddresses.partner)
    : ["相手の住所は、合意後に表示されます。"];

  return (
    <View style={styles.mailBanner}>
      <View style={styles.mailBannerHeader}>
        <Text style={styles.mailBannerTitle}>住所</Text>
        <StatusPill
          label={finalised ? "住所表示中" : "合意後に表示"}
          tone={finalised ? "lavender" : "sky"}
        />
      </View>
      <Text style={styles.mailBannerBody}>
        {finalised
          ? "この取引の当事者だけに住所を表示しています。"
          : detail.exchangeMethod === "both"
            ? "この取引は現地交換も郵送交換も選べます。郵送で進める場合、合意が成立すると当事者同士に住所を表示します。"
            : "この取引は郵送です。合意が成立すると、当事者同士に住所を表示します。"}
      </Text>
      <MailingAddressCard lines={mineLines} title="あなたの住所" />
      {finalised ? (
        <MailingAddressCard lines={partnerLines} title={partnerLabel} />
      ) : (
        <View style={styles.mailBannerActionRow}>
          <Text style={styles.mailBannerHint}>
            未登録のままだと、最終合意の時点で止まります。
          </Text>
          {!detail.mailingAddresses.mine ? (
            <Pressable
              accessibilityRole="button"
              onPress={onOpenSettings}
              style={styles.mailBannerLinkButton}
            >
              <Text style={styles.mailBannerLinkText}>住所設定を開く</Text>
            </Pressable>
          ) : null}
        </View>
      )}
    </View>
  );
}

function MailingAddressCard({
  lines,
  title,
}: {
  lines: string[];
  title: string;
}) {
  return (
    <View style={styles.mailAddressCard}>
      <Text style={styles.mailAddressTitle}>{title}</Text>
      {lines.map((line, index) => (
        <Text key={`${title}-${index}`} style={styles.mailAddressLine}>
          {line}
        </Text>
      ))}
    </View>
  );
}

function ChatPartnerStrip({ detail }: { detail: TransactionDetail }) {
  const handle = detail.partner.handle ?? detail.partner.display_name ?? "unknown";
  const isAgreed = detail.status === "agreed" || detail.status === "completed";
  const arrivalColor =
    detail.partnerArrival === "arrived"
      ? megrumColors.ok
      : detail.partnerArrival === "enroute"
        ? "#e0a847"
        : "rgba(58,50,74,0.42)";
  const arrivalLabel = isAgreed
    ? arrivalStatusLabel(detail.partnerArrival)
    : detail.partner.primary_area
      ? detail.partner.primary_area
      : "取引チャット";
  return (
    <Pressable
      accessibilityRole="button"
      onPress={() =>
        router.push({
          pathname: "/user-profile",
          params: { id: detail.partner.id },
        })
      }
      style={styles.chatPartnerStrip}
    >
      <View style={styles.headerAvatar}>
        {detail.partner.avatar_url ? (
          <Image source={{ uri: detail.partner.avatar_url }} style={styles.headerAvatarImage} />
        ) : (
          <Text style={styles.headerAvatarText}>
            {handle.replace(/^@/, "").slice(0, 1).toUpperCase()}
          </Text>
        )}
      </View>
      <View style={styles.chatHeaderCopy}>
        <Text numberOfLines={1} style={styles.chatHeaderName}>@{handle.replace(/^@/, "")}</Text>
        <View style={styles.chatHeaderMetaRow}>
          <View
            style={[
              styles.chatHeaderDot,
              { backgroundColor: isAgreed ? arrivalColor : megrumColors.lavender },
            ]}
          />
          <Text
            numberOfLines={1}
            style={[
              styles.chatHeaderMetaText,
              { color: isAgreed ? arrivalColor : megrumColors.mutedInk },
            ]}
          >
            {arrivalLabel}
          </Text>
          {isAgreed && detail.partner.primary_area ? (
            <Text numberOfLines={1} style={styles.chatHeaderArea}>
              · {detail.partner.primary_area}
            </Text>
          ) : null}
        </View>
      </View>
      <AgreementHeaderBadge detail={detail} />
    </Pressable>
  );
}

function AgreementHeaderBadge({ detail }: { detail: TransactionDetail }) {
  const label = headerAgreementLabel(detail);
  const complete = detail.status === "agreed" || detail.status === "completed";
  const waiting =
    detail.status === "agreement_one_side" ||
    detail.myAgreed ||
    detail.partnerAgreed;
  return (
    <View
      style={[
        styles.chatHeaderStatusBadge,
        complete
          ? styles.chatHeaderStatusBadgeDone
          : waiting
            ? styles.chatHeaderStatusBadgeWaiting
            : null,
      ]}
    >
      <Text
        numberOfLines={1}
        style={[
          styles.chatHeaderStatusText,
          complete ? styles.chatHeaderStatusTextDone : null,
        ]}
      >
        {label}
      </Text>
    </View>
  );
}

function DealSummaryCard({ detail }: { detail: TransactionDetail }) {
  const [detailOpen, setDetailOpen] = useState(false);
  return (
    <>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="取引内容の詳細を表示"
        onPress={() => setDetailOpen(true)}
        style={({ pressed }) => [
          styles.dealCollapsedCard,
          pressed ? styles.dealCollapsedCardPressed : null,
        ]}
      >
        <Text style={styles.dealCollapsedLabel}>交換内容</Text>
        <Text numberOfLines={1} style={styles.dealCollapsedSummary}>
          {tradeSummaryLine(detail)}
        </Text>
        <Text style={styles.dealCollapsedAction}>詳細</Text>
      </Pressable>
      {detail.optionTags.length > 0 ? (
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.dealConditionTagRow}
        >
          {detail.optionTags.map((tag) => (
            <View key={tag} style={styles.dealConditionTag}>
              <Text style={styles.dealConditionTagText}>{tag}</Text>
            </View>
          ))}
        </ScrollView>
      ) : null}
      <DealDetailModal
        detail={detail}
        visible={detailOpen}
        onClose={() => setDetailOpen(false)}
      />
    </>
  );
}

function DealDetailModal({
  detail,
  visible,
  onClose,
}: {
  detail: TransactionDetail;
  visible: boolean;
  onClose: () => void;
}) {
  const statusLabelText =
    detail.status === "completed"
      ? "完了"
      : detail.status === "agreed"
        ? "合意済"
        : "提案中";
  return (
    <Modal animationType="fade" transparent visible={visible} onRequestClose={onClose}>
      <Pressable style={styles.dealModalBackdrop} onPress={onClose}>
        <Pressable style={styles.dealModalCard}>
          <View style={styles.dealModalHeader}>
            <View>
              <Text style={styles.dealModalTitle}>取引内容</Text>
              <Text style={styles.dealModalSub}>{statusLabelText}</Text>
            </View>
            <Pressable accessibilityRole="button" onPress={onClose} style={styles.dealModalClose}>
              <Text style={styles.dealModalCloseText}>×</Text>
            </Pressable>
          </View>

          <ScrollView
            showsVerticalScrollIndicator={false}
            contentContainerStyle={styles.dealModalContent}
          >
            <View style={styles.dealModalSection}>
              <Text style={styles.dealModalSectionTitle}>交換内容</Text>
              <DealExchangeCard detail={detail} />
            </View>

          </ScrollView>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function DealExchangeCard({ detail }: { detail: TransactionDetail }) {
  return (
    <View style={styles.dealExchangeCard}>
      <DealSidePanel
        label={`相手の譲（${detail.receive.length}）`}
        items={detail.receive}
        cashOffer={detail.cashOffer}
        cashAmount={detail.cashAmount}
      />
      <View style={styles.dealExchangeSwapColumn}>
        <DealArrowDot color={megrumColors.lavender} direction="right" />
        <DealArrowDot color={megrumColors.sky} direction="left" />
      </View>
      <DealSidePanel
        label={`あなたの譲（${detail.give.length}）`}
        items={detail.give}
        alignRight
      />
    </View>
  );
}

function DealSidePanel({
  label,
  items,
  cashOffer,
  cashAmount,
  alignRight,
}: {
  label: string;
  items: DetailItem[];
  cashOffer?: boolean;
  cashAmount?: number | null;
  alignRight?: boolean;
}) {
  return (
    <View style={[styles.dealExchangeSidePanel, alignRight ? styles.dealExchangeSidePanelRight : null]}>
      <Text
        style={[
          styles.dealExchangeSideLabel,
          alignRight ? styles.dealExchangeSideLabelRight : null,
        ]}
      >
        {label}
      </Text>
      {cashOffer && items.length === 0 ? (
        <View style={[styles.dealExchangeCash, alignRight ? styles.dealExchangeCashRight : null]}>
          <Text style={styles.dealExchangeCashText}>¥{cashAmount?.toLocaleString() ?? "—"}</Text>
        </View>
      ) : (
        <DealModalItemThumbs items={items} alignRight={alignRight} />
      )}
    </View>
  );
}

function DealArrowDot({
  color,
  direction,
}: {
  color: string;
  direction: "left" | "right";
}) {
  return (
    <View style={[styles.dealExchangeArrowDot, { backgroundColor: color }]}>
      <Text style={styles.dealExchangeArrowText}>{direction === "right" ? "→" : "←"}</Text>
    </View>
  );
}

function DealModalItemThumbs({
  items,
  alignRight,
}: {
  items: DetailItem[];
  alignRight?: boolean;
}) {
  if (items.length === 0) {
    return <Text style={styles.dealModalEmpty}>—</Text>;
  }
  return (
    <View style={[styles.dealModalItems, alignRight ? styles.dealModalItemsRight : null]}>
      {items.map((item) => (
        <View key={item.id} style={styles.dealModalThumb}>
          {item.photoUrl ? (
            <Image source={{ uri: item.photoUrl }} style={styles.dealModalThumbPhoto} />
          ) : (
            <View style={[styles.dealModalThumbFallback, { backgroundColor: item.hue }]}>
              <View style={styles.dealModalThumbShine} />
              <Text style={styles.dealModalThumbGlyph}>{item.label.slice(0, 1)}</Text>
            </View>
          )}
          {item.qty > 1 ? (
            <View style={styles.dealModalThumbQty}>
              <Text style={styles.dealModalThumbQtyText}>×{item.qty}</Text>
            </View>
          ) : null}
          <View style={styles.dealModalThumbMeta}>
            <Text numberOfLines={1} style={styles.dealModalThumbLabel}>{item.label}</Text>
            <Text numberOfLines={1} style={styles.dealModalThumbSub}>{item.goodsType ?? "グッズ"}</Text>
          </View>
        </View>
      ))}
    </View>
  );
}

function DealMeetupCandidateCard({ meetups }: { meetups: MeetupCandidate[] }) {
  if (meetups.length === 0) {
    return <Text style={styles.dealModalEmpty}>候補は未設定です</Text>;
  }
  const mapMeetups = meetups
    .map((meetup, index) => (hasMeetupCoordinate(meetup) ? { index, meetup } : null))
    .filter(
      (entry): entry is {
        index: number;
        meetup: MeetupCandidate & { lat: number; lng: number };
      } => !!entry,
    );
  const center = getDealMeetupMapCenter(mapMeetups.map((entry) => entry.meetup));
  return (
    <View style={styles.dealMeetupMapCard}>
      <View style={styles.dealMeetupMapPanel}>
        {mapMeetups.length > 0 ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="地図アプリで待ち合わせ場所を開く"
            onPress={() => openMeetupInMaps(mapMeetups[0].meetup)}
          >
            <NativeMapPreview
              center={center}
              height={184}
              markers={mapMeetups.map(({ index, meetup }) => ({
                id: `${meetup.startAt}-${meetup.endAt}-${index}`,
                coordinate: {
                  latitude: meetup.lat,
                  longitude: meetup.lng,
                },
                label: String(index + 1),
                title: meetup.placeName,
              }))}
            />
            <View style={styles.dealMeetupMapOpenPill}>
              <Text style={styles.dealMeetupMapOpenText}>地図で開く</Text>
            </View>
          </Pressable>
        ) : (
          <View style={styles.dealMeetupMapEmpty}>
            <Text style={styles.dealMeetupMapEmptyText}>地図情報は未設定です</Text>
          </View>
        )}
      </View>
      <View style={styles.dealCandidateList}>
        {meetups.map((meetup, index) => (
          <View key={`${meetup.startAt}-${meetup.endAt}-${index}`} style={styles.dealCandidateRow}>
            <View style={styles.dealCandidateNumber}>
              <Text style={styles.dealCandidateNumberText}>{index + 1}</Text>
            </View>
            <View style={styles.dealCandidateCopy}>
              <Text numberOfLines={1} style={styles.dealCandidateTime}>
                {formatDateTime(meetup.startAt, meetup.endAt)}
              </Text>
              <Text numberOfLines={1} style={styles.dealCandidatePlace}>
                {meetup.placeName}
              </Text>
            </View>
          </View>
        ))}
      </View>
    </View>
  );
}

function hasMeetupCoordinate(
  meetup: MeetupCandidate,
): meetup is MeetupCandidate & { lat: number; lng: number } {
  return Number.isFinite(meetup.lat) && Number.isFinite(meetup.lng);
}

function getDealMeetupMapCenter(
  meetups: Array<MeetupCandidate & { lat: number; lng: number }>,
): MapCoordinate {
  if (meetups.length === 0) return FALLBACK_MEETUP_COORDINATE;
  const total = meetups.reduce(
    (acc, meetup) => ({
      latitude: acc.latitude + meetup.lat,
      longitude: acc.longitude + meetup.lng,
    }),
    { latitude: 0, longitude: 0 },
  );
  return {
    latitude: total.latitude / meetups.length,
    longitude: total.longitude / meetups.length,
  };
}

function openMeetupInMaps(meetup: MeetupCandidate & { lat: number; lng: number }) {
  const label = encodeURIComponent(meetup.placeName || "待ち合わせ場所");
  const latLng = `${meetup.lat},${meetup.lng}`;
  const url =
    Platform.OS === "ios"
      ? `http://maps.apple.com/?ll=${latLng}&q=${label}`
      : `geo:${latLng}?q=${latLng}(${label})`;
  Linking.openURL(url).catch(() => undefined);
}
function MiniItemRow({
  items,
  alignRight,
}: {
  items: DetailItem[];
  alignRight?: boolean;
}) {
  const visible = items.slice(0, 2);
  if (items.length === 0) {
    return <Text style={styles.miniItemEmpty}>—</Text>;
  }
  return (
    <View style={[styles.miniItemRow, alignRight ? styles.miniItemRowRight : null]}>
      {visible.map((item) => (
        <MiniItemThumb key={item.id} item={item} />
      ))}
      {items.length > visible.length ? (
        <View style={styles.miniMore}>
          <Text style={styles.miniMoreText}>+{items.length - visible.length}</Text>
        </View>
      ) : null}
    </View>
  );
}

function MiniItemThumb({ item }: { item: DetailItem }) {
  return (
    <View style={styles.miniThumb}>
      {item.photoUrl ? (
        <Image source={{ uri: item.photoUrl }} style={styles.miniThumbImage} />
      ) : (
        <View style={[styles.miniThumbFallback, { backgroundColor: item.hue }]}>
          <Text style={styles.miniThumbGlyph}>{item.label.slice(0, 1)}</Text>
        </View>
      )}
      {item.qty > 1 ? (
        <View style={styles.miniQty}>
          <Text style={styles.miniQtyText}>×{item.qty}</Text>
        </View>
      ) : null}
    </View>
  );
}

function CashChipNative({ amount }: { amount: number | null }) {
  return (
    <View style={styles.cashChipNative}>
      <Text style={styles.cashChipText}>¥{amount?.toLocaleString() ?? "—"}</Text>
    </View>
  );
}

function ExpireBannerCompact({
  detail,
  loading,
  onExtend,
}: {
  detail: TransactionDetail;
  loading: boolean;
  onExtend: () => void;
}) {
  if (!detail.expiresAt) return null;
  const remainMs = new Date(detail.expiresAt).getTime() - Date.now();
  const remainDays = Math.ceil(remainMs / (1000 * 60 * 60 * 24));
  if (remainDays > 3) return null;
  const warn = remainDays <= 1;
  const canExtend = detail.extensionCount < 3;
  return (
    <View style={[styles.expireBanner, warn ? styles.expireBannerWarn : null]}>
      <Text style={styles.expireIcon}>{warn ? "!" : "⏰"}</Text>
      <View style={styles.expireCopy}>
        <Text style={[styles.expireTitle, warn ? styles.expireTitleWarn : null]}>
          {remainDays <= 0
            ? "本日期限切れ"
            : remainDays === 1
              ? "あと1日で期限切れ"
              : `あと${remainDays}日で期限切れ`}
        </Text>
        <Text style={styles.expireSub}>延長 {detail.extensionCount}/3 回 ・ +7日延長できます</Text>
      </View>
      <Pressable
        accessibilityRole="button"
        disabled={loading || !canExtend}
        onPress={onExtend}
        style={[styles.expireButton, warn ? styles.expireButtonWarn : null]}
      >
        <Text style={styles.expireButtonText}>{canExtend ? "+7日延長" : "上限"}</Text>
      </Pressable>
    </View>
  );
}

function AgreementBarCompact({
  detail,
  canAccept,
  canReject,
  loading,
  onAccept,
  onReject,
}: {
  detail: TransactionDetail;
  canAccept: boolean;
  canReject: boolean;
  loading: string | null;
  onAccept: () => void;
  onReject: () => void;
}) {
  const isInitialSenderWaiting = detail.status === "sent" && detail.isSender;
  const statusText = isInitialSenderWaiting
    ? `@${detail.partner.handle ?? detail.partner.display_name ?? "相手"} の返信待ちです`
    : detail.myAgreed
      ? "あなた合意済 · 相手の合意待ち"
      : detail.partnerAgreed
        ? "相手合意済 · あなたの確認をお願いします"
        : "両者の合意で取引フェーズへ進めます";
  return (
    <View style={styles.agreementCompact}>
      <Text style={styles.agreementCompactText}>{statusText}</Text>
      <View style={styles.agreementCompactActions}>
        {canReject ? (
          <Pressable
            accessibilityRole="button"
            disabled={!!loading}
            onPress={onReject}
            style={styles.agreementRejectButton}
          >
            <Text style={styles.agreementRejectText}>拒否</Text>
          </Pressable>
        ) : null}
        <Pressable
          accessibilityRole="button"
          disabled={!!loading || !canAccept || detail.myAgreed || isInitialSenderWaiting}
          onPress={onAccept}
          style={[
            styles.agreementAcceptButton,
            !!loading || !canAccept || detail.myAgreed || isInitialSenderWaiting
              ? styles.actionDisabled
              : null,
          ]}
        >
          <Text style={styles.agreementAcceptText}>
            {isInitialSenderWaiting
              ? "相手の返信待ち"
              : detail.myAgreed
                ? "合意済（相手の合意待ち）"
                : detail.partnerAgreed
                  ? "✓ この内容で合意して取引へ進む →"
                  : "✓ この内容で合意する"}
          </Text>
        </Pressable>
      </View>
    </View>
  );
}

function AcceptDecisionModal({
  detail,
  visible,
  loading,
  onClose,
  onCounter,
  onConfirm,
}: {
  detail: TransactionDetail;
  visible: boolean;
  loading: boolean;
  onClose: () => void;
  onCounter: (method?: ExchangeMethod) => void;
  onConfirm: (decision: AcceptDecision) => void;
}) {
  const [selectedMethod, setSelectedMethod] =
    useState<AcceptDecision["exchangeMethod"] | null>(null);
  const [selectedMeetupIndex, setSelectedMeetupIndex] = useState<number | null>(null);

  useEffect(() => {
    if (!visible) return;
    const method = resolveSingleExchangeMethod(detail);
    setSelectedMethod(method);
    setSelectedMeetupIndex(method === "hand" && detail.meetups.length === 1 ? 0 : null);
  }, [detail.id, detail.exchangeMethod, detail.meetups.length, visible]);

  if (!visible) return null;

  const needsMethodChoice = detail.exchangeMethod === "both";
  const selectedMeetup =
    selectedMethod === "hand" && selectedMeetupIndex !== null
      ? detail.meetups[selectedMeetupIndex] ?? null
      : null;
  const canConfirm =
    !!selectedMethod &&
    (selectedMethod === "mail" || (selectedMethod === "hand" && !!selectedMeetup));

  return (
    <Modal animationType="fade" transparent visible={visible} onRequestClose={onClose}>
      <Pressable style={styles.dealModalBackdrop} onPress={onClose}>
        <Pressable style={styles.acceptModalCard}>
          <View style={styles.dealModalHeader}>
            <View>
              <Text style={styles.dealModalTitle}>応じる条件を選択</Text>
              <Text style={styles.dealModalSub}>
                {needsMethodChoice
                  ? "交換手段を1つ選んでください"
                  : "現地交換の候補を1つ選んでください"}
              </Text>
            </View>
            <Pressable accessibilityRole="button" onPress={onClose} style={styles.dealModalClose}>
              <Text style={styles.dealModalCloseText}>×</Text>
            </Pressable>
          </View>

          <ScrollView contentContainerStyle={styles.acceptModalContent}>
            {needsMethodChoice ? (
              <View style={styles.acceptChoiceGroup}>
                <Text style={styles.dealModalSectionTitle}>交換手段</Text>
                <View style={styles.acceptChoiceRow}>
                  <AcceptChoiceButton
                    active={selectedMethod === "hand"}
                    label="現地交換"
                    onPress={() => {
                      setSelectedMethod("hand");
                      setSelectedMeetupIndex(detail.meetups.length === 1 ? 0 : null);
                    }}
                  />
                  <AcceptChoiceButton
                    active={selectedMethod === "mail"}
                    label="郵送交換"
                    onPress={() => {
                      setSelectedMethod("mail");
                      setSelectedMeetupIndex(null);
                    }}
                  />
                </View>
              </View>
            ) : null}

            {selectedMethod === "hand" ? (
              <View style={styles.acceptChoiceGroup}>
                <View style={styles.dealModalSectionHeader}>
                  <Text style={styles.dealModalSectionTitle}>現地交換の候補</Text>
                  <Text style={styles.dealModalSectionCount}>{detail.meetups.length}件</Text>
                </View>
                {detail.meetups.length > 0 ? (
                  detail.meetups.map((meetup, index) => {
                    const active = selectedMeetupIndex === index;
                    return (
                      <Pressable
                        key={`${meetup.startAt}-${meetup.endAt}-${index}`}
                        accessibilityRole="button"
                        onPress={() => setSelectedMeetupIndex(index)}
                        style={[
                          styles.acceptMeetupRow,
                          active ? styles.acceptMeetupRowActive : null,
                        ]}
                      >
                        <View
                          style={[
                            styles.acceptRadio,
                            active ? styles.acceptRadioActive : null,
                          ]}
                        >
                          {active ? <View style={styles.acceptRadioDot} /> : null}
                        </View>
                        <View style={styles.acceptMeetupCopy}>
                          <Text style={styles.acceptMeetupTime}>
                            {formatDateTime(meetup.startAt, meetup.endAt)}
                          </Text>
                          <Text numberOfLines={1} style={styles.acceptMeetupPlace}>
                            {meetup.placeName}
                          </Text>
                        </View>
                      </Pressable>
                    );
                  })
                ) : (
                  <Text style={styles.exchangeMethodModalBody}>
                    現地交換の候補がありません。条件を変えて再打診してください。
                  </Text>
                )}
              </View>
            ) : null}

            {selectedMethod === "mail" ? (
              <View style={styles.acceptChoiceGroup}>
                <Text style={styles.dealModalSectionTitle}>郵送交換</Text>
                <Text style={styles.exchangeMethodModalBody}>
                  郵送で応じる場合、合意成立後に当事者同士だけに住所が表示されます。
                </Text>
              </View>
            ) : null}
          </ScrollView>

          <View style={styles.acceptModalFooter}>
            <Pressable
              accessibilityRole="button"
              onPress={() => onCounter(selectedMethod ?? detail.exchangeMethod)}
              style={styles.acceptCounterButton}
            >
              <Text style={styles.acceptCounterText}>条件を変えて再打診</Text>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              disabled={!canConfirm || loading}
              onPress={() => {
                if (!selectedMethod) return;
                onConfirm({
                  exchangeMethod: selectedMethod,
                  meetup: selectedMethod === "hand" ? selectedMeetup : null,
                });
              }}
              style={[
                styles.acceptConfirmButton,
                !canConfirm || loading ? styles.actionDisabled : null,
              ]}
            >
              <Text style={styles.acceptConfirmText}>
                {loading ? "更新中…" : "この条件で応じる"}
              </Text>
            </Pressable>
          </View>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function AcceptChoiceButton({
  active,
  label,
  onPress,
}: {
  active: boolean;
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={[styles.acceptChoiceButton, active ? styles.acceptChoiceButtonActive : null]}
    >
      <Text style={[styles.acceptChoiceText, active ? styles.acceptChoiceTextActive : null]}>
        {label}
      </Text>
    </Pressable>
  );
}

function OutfitCompactRowNative({
  detail,
  uploading,
  onTake,
}: {
  detail: TransactionDetail;
  uploading: boolean;
  onTake: () => void;
}) {
  return (
    <View style={styles.outfitCompactWeb}>
      <Text style={styles.outfitIcon}>👕</Text>
      <Text style={styles.outfitTitle}>服装写真</Text>
      <Text numberOfLines={1} style={styles.outfitState}>あなた: {detail.myOutfitPhoto ? "共有済" : "未シェア"}</Text>
      <Text style={styles.outfitSlash}>/</Text>
      <Text numberOfLines={1} style={styles.outfitState}>相手: {detail.partnerOutfitPhoto ? "共有済" : "未シェア"}</Text>
      <Pressable
        accessibilityRole="button"
        disabled={uploading}
        onPress={onTake}
        style={styles.outfitShootButton}
      >
        <Text style={styles.outfitShootText}>{uploading ? "送信中…" : detail.myOutfitPhoto ? "撮り直す" : "撮影"}</Text>
      </Pressable>
    </View>
  );
}

function ChatMessageList({
  messages,
  partnerLastReadAt,
  proposalId,
  userId,
}: {
  messages: ChatMessage[];
  partnerLastReadAt: string | null;
  proposalId: string;
  userId: string;
}) {
  if (messages.length === 0) {
    return (
      <View style={styles.emptyMessageCard}>
        <Text style={styles.emptyMessageText}>まだメッセージがありません。挨拶から始めましょう</Text>
      </View>
    );
  }
  const nodes: ReactNode[] = [];
  let lastDay: string | null = null;
  for (const message of messages) {
    const date = new Date(message.createdAt);
    const dayKey = `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
    if (dayKey !== lastDay) {
      nodes.push(
        <View key={`day-${dayKey}-${message.id}`} style={styles.daySeparator}>
          <Text style={styles.daySeparatorText}>{dayLabel(message.createdAt)}</Text>
        </View>,
      );
      lastDay = dayKey;
    }
    nodes.push(
      <ChatBubble
        key={message.id}
        message={message}
        mine={message.senderId === userId}
        read={message.senderId === userId && isReadByPartner(message, partnerLastReadAt)}
        proposalId={proposalId}
        userId={userId}
      />,
    );
  }
  return <>{nodes}</>;
}

function isReadByPartner(message: ChatMessage, partnerLastReadAt: string | null) {
  if (!partnerLastReadAt) return false;
  if (message.type === "system" || message.type === "arrival_status") return false;
  const readTime = new Date(partnerLastReadAt).getTime();
  const messageTime = new Date(message.createdAt).getTime();
  if (Number.isNaN(readTime) || Number.isNaN(messageTime)) return false;
  return readTime >= messageTime;
}

function TradeColumn({
  title,
  items,
  alignRight,
}: {
  title: string;
  items: DetailItem[];
  alignRight?: boolean;
}) {
  return (
    <View style={styles.tradeColumn}>
      <Text style={[styles.tradeTitle, alignRight ? styles.tradeTitleRight : null]}>
        {title}
      </Text>
      <View style={[styles.detailItems, alignRight ? styles.detailItemsRight : null]}>
        {items.map((item) => (
          <View key={item.id} style={styles.detailItem}>
            {item.photoUrl ? (
              <Image source={{ uri: item.photoUrl }} style={styles.itemPhoto} />
            ) : (
              <View style={[styles.itemFallback, { backgroundColor: item.hue }]}>
                <Text style={styles.itemGlyph}>{item.label.slice(0, 1)}</Text>
              </View>
            )}
            <Text numberOfLines={1} style={styles.itemLabel}>
              {item.label}
            </Text>
            {item.qty > 1 ? <Text style={styles.itemQty}>x{item.qty}</Text> : null}
          </View>
        ))}
      </View>
    </View>
  );
}

function ChatBubble({
  message,
  mine,
  read,
  proposalId,
  userId,
}: {
  message: ChatMessage;
  mine: boolean;
  read: boolean;
  proposalId: string;
  userId: string;
}) {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const system = message.type === "system" || message.type === "arrival_status";
  const text = messageText(message);
  const openApprove = message.meta?.action === "open_approve";
  const cancelRequested = message.meta?.action === "cancel_requested" && !mine;

  async function handleApproveCancel() {
    if (!userId || pending) return;
    Alert.alert(
      "キャンセルに同意しますか？",
      "取引は無効化され、評価への影響はありません。",
      [
        { text: "戻る", style: "cancel" },
        {
          text: "同意する",
          style: "destructive",
          onPress: async () => {
            setPending(true);
            setError(null);
            const result = await approveTradeCancel({ proposalId, userId });
            setPending(false);
            if (result.error) {
              setError(result.error);
              return;
            }
            goToTabRoot("/transactions");
          },
        },
      ],
    );
  }

  if (system) {
    if (cancelRequested) {
      return (
        <View style={styles.cancelRequestCard}>
          <View style={styles.cancelRequestHeader}>
            <View style={styles.cancelRequestIcon}>
              <Text style={styles.cancelRequestIconText}>!</Text>
            </View>
            <Text style={styles.cancelRequestTitle}>キャンセル要請</Text>
          </View>
          <Text style={styles.cancelRequestBody}>{text}</Text>
          {error ? <Text style={styles.cancelRequestError}>{error}</Text> : null}
          <View style={styles.cancelRequestActions}>
            <Pressable
              disabled={pending}
              onPress={() =>
                router.push({
                  pathname: "/dispute-new",
                  params: { proposalId },
                })
              }
              style={styles.cancelRequestSecondary}
            >
              <Text style={styles.cancelRequestSecondaryText}>申告する</Text>
            </Pressable>
            <Pressable
              disabled={pending}
              onPress={handleApproveCancel}
              style={[
                styles.cancelRequestPrimary,
                pending ? styles.cancelRequestDisabled : null,
              ]}
            >
              <Text style={styles.cancelRequestPrimaryText}>
                {pending ? "処理中…" : "同意してキャンセル"}
              </Text>
            </Pressable>
          </View>
        </View>
      );
    }

    return (
      <Pressable
        disabled={!openApprove}
        onPress={() =>
          router.push({ pathname: "/transaction-approve", params: { id: proposalId } })
        }
        style={[styles.systemMessage, openApprove ? styles.systemMessageAction : null]}
      >
        <Text style={styles.systemMessageText}>{text}</Text>
        {openApprove ? <Text style={styles.systemMessageArrow}>確認へ →</Text> : null}
      </Pressable>
    );
  }

  if (message.type === "location") {
    return <LocationChatBubble message={message} mine={mine} read={read} />;
  }

  return (
    <View style={[styles.chatBubbleRow, mine ? styles.chatBubbleRowMine : null]}>
      <View style={mine ? styles.chatBubbleMineWrap : styles.chatBubblePartnerWrap}>
        {mine ? <ChatMessageMeta createdAt={message.createdAt} read={read} /> : null}
        <ChatGradientBubble mine={mine} style={[styles.chatBubble, mine ? styles.chatBubbleMine : null]}>
          {message.photoUrl ? (
            <Image source={{ uri: message.photoUrl }} style={styles.chatPhoto} />
          ) : null}
          <Text style={[styles.chatBubbleText, mine ? styles.chatBubbleTextMine : null]}>
            {text}
          </Text>
        </ChatGradientBubble>
        {!mine ? <ChatMessageMeta createdAt={message.createdAt} /> : null}
      </View>
    </View>
  );
}

function ChatMessageMeta({
  createdAt,
  read,
}: {
  createdAt: string;
  read?: boolean;
}) {
  return (
    <View style={styles.chatMessageMeta}>
      {read ? <Text style={styles.chatMessageMetaText}>既読</Text> : null}
      <Text style={styles.chatMessageMetaText}>{shortTime(createdAt)}</Text>
    </View>
  );
}

function LocationChatBubble({
  message,
  mine,
  read,
}: {
  message: ChatMessage;
  mine: boolean;
  read: boolean;
}) {
  const hasCoordinate =
    typeof message.locationLat === "number" &&
    typeof message.locationLng === "number";
  const coordinate = hasCoordinate
    ? {
        latitude: message.locationLat as number,
        longitude: message.locationLng as number,
      }
    : null;

  return (
    <View style={[styles.chatBubbleRow, mine ? styles.chatBubbleRowMine : null]}>
      <View style={mine ? styles.chatBubbleMineWrap : styles.chatBubblePartnerWrap}>
        {mine ? <ChatMessageMeta createdAt={message.createdAt} read={read} /> : null}
        <View
          style={[
            styles.locationBubble,
            mine ? styles.locationBubbleMine : styles.locationBubblePartner,
          ]}
        >
          {coordinate ? (
            <NativeMapPreview
              center={coordinate}
              height={118}
              markers={[
                {
                  id: "shared-location",
                  coordinate,
                  label: "!",
                  title: message.locationLabel ?? "現在地",
                },
              ]}
              style={styles.locationMap}
            />
          ) : null}
          <View style={styles.locationBody}>
            <Text style={styles.locationTitle}>
              {message.locationLabel ?? "現在地を共有"}
            </Text>
            {coordinate ? (
              <Pressable
                accessibilityRole="button"
                onPress={() =>
                  Linking.openURL(
                    `http://maps.apple.com/?ll=${coordinate.latitude},${coordinate.longitude}`,
                  )
                }
              >
                <Text style={styles.locationLink}>地図アプリで開く →</Text>
              </Pressable>
            ) : null}
          </View>
        </View>
        {!mine ? <ChatMessageMeta createdAt={message.createdAt} /> : null}
      </View>
    </View>
  );
}

function QuickActionChip({
  label,
  icon,
  tone,
  disabled,
  onPress,
}: {
  label: string;
  icon: string;
  tone: "lavender" | "pink" | "neutral";
  disabled?: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled}
      onPress={onPress}
      style={[
        styles.quickActionChip,
        tone === "lavender"
          ? styles.quickActionLavender
          : tone === "pink"
            ? styles.quickActionPink
            : styles.quickActionNeutral,
        disabled ? styles.quickActionDisabled : null,
      ]}
    >
      <Text
        style={[
          styles.quickActionIcon,
          tone === "neutral" ? styles.quickActionIconNeutral : null,
        ]}
      >
        {icon}
      </Text>
      <Text style={styles.quickActionLabel}>{label}</Text>
    </Pressable>
  );
}

function OpenDisputeBanner({ dispute }: { dispute: OpenDispute }) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={() =>
        router.push({ pathname: "/dispute-detail", params: { id: dispute.id } })
      }
      style={styles.disputeBanner}
    >
      <View style={styles.disputeIcon}>
        <Text style={styles.disputeIconText}>!</Text>
      </View>
      <View style={styles.disputeCopy}>
        <Text style={styles.disputeTitle}>申告 {dispute.ticketNo} ・ 仲裁中</Text>
        <Text style={styles.disputeSub}>ステータス確認はタップ</Text>
      </View>
      <Text style={styles.disputeArrow}>›</Text>
    </Pressable>
  );
}

function ProposalNegotiationPanel({
  detail,
  canAccept,
  canNegotiate,
  canReject,
  actionLoading,
  onAccept,
  onNegotiate,
  onReject,
  onExtend,
}: {
  detail: TransactionDetail;
  canAccept: boolean;
  canNegotiate: boolean;
  canReject: boolean;
  actionLoading: "accept" | "negotiate" | "reject" | "extend" | "enroute" | "arrived" | null;
  onAccept: () => void;
  onNegotiate: () => void;
  onReject: () => void;
  onExtend: () => void;
}) {
  const expired = detail.expiresAt
    ? new Date(detail.expiresAt).getTime() < Date.now()
    : false;
  return (
    <View style={styles.negotiationPanel}>
      <View style={styles.negotiationHeader}>
        <View>
          <Text style={styles.negotiationTitle}>
            {detail.status === "agreement_one_side"
              ? detail.myAgreed
                ? "相手の合意待ち"
                : "あなたの合意待ち"
              : detail.status === "negotiating"
                ? "条件を相談中"
                : "打診中"}
          </Text>
          <Text style={styles.negotiationSub}>
            {detail.expiresAt
              ? `${expired ? "期限切れ" : "期限"} ${formatDeadline(detail.expiresAt)}`
              : "期限は未設定です"}
            {detail.extensionCount > 0 ? ` / 延長${detail.extensionCount}回` : ""}
          </Text>
        </View>
        <Pressable
          accessibilityRole="button"
          disabled={actionLoading === "extend"}
          onPress={onExtend}
          style={styles.extendButton}
        >
          <Text style={styles.extendButtonText}>
            {actionLoading === "extend" ? "延長中…" : "7日延長"}
          </Text>
        </Pressable>
      </View>
      <View style={styles.agreementStateRow}>
        <View style={[styles.agreementStateChip, detail.myAgreed ? styles.agreementStateChipDone : null]}>
          <Text style={[styles.agreementStateChipText, detail.myAgreed ? styles.agreementStateChipTextDone : null]}>
            私 {detail.myAgreed ? "合意済" : "未合意"}
          </Text>
        </View>
        <View style={[styles.agreementStateChip, detail.partnerAgreed ? styles.agreementStateChipDone : null]}>
          <Text style={[styles.agreementStateChipText, detail.partnerAgreed ? styles.agreementStateChipTextDone : null]}>
            相手 {detail.partnerAgreed ? "合意済" : "未合意"}
          </Text>
        </View>
      </View>
      <View style={styles.negotiationActions}>
        {canAccept ? (
          <Pressable
            accessibilityRole="button"
            disabled={!!actionLoading}
            onPress={onAccept}
            style={[styles.negotiationPrimary, actionLoading ? styles.actionDisabled : null]}
          >
            <Text style={styles.negotiationPrimaryText}>
              {actionLoading === "accept" ? "合意中…" : "この内容で合意する"}
            </Text>
          </Pressable>
        ) : null}
        {canNegotiate ? (
          <Pressable
            accessibilityRole="button"
            disabled={!!actionLoading}
            onPress={onNegotiate}
            style={[styles.negotiationSecondary, actionLoading ? styles.actionDisabled : null]}
          >
            <Text style={styles.negotiationSecondaryText}>
              {actionLoading === "negotiate" ? "更新中…" : "条件を相談する"}
            </Text>
          </Pressable>
        ) : null}
        {canReject ? (
          <Pressable
            accessibilityRole="button"
            disabled={!!actionLoading}
            onPress={onReject}
            style={[styles.negotiationReject, actionLoading ? styles.actionDisabled : null]}
          >
            <Text style={styles.negotiationRejectText}>
              {actionLoading === "reject" ? "処理中…" : "見送る"}
            </Text>
          </Pressable>
        ) : null}
      </View>
    </View>
  );
}

function AgreedLivePanel({
  detail,
  outfitLoading,
  onShareOutfit,
}: {
  detail: TransactionDetail;
  outfitLoading: boolean;
  onShareOutfit: () => void;
}) {
  return (
    <View style={styles.livePanel}>
      <View style={styles.liveHeader}>
        <View>
          <Text style={styles.liveTitle}>当日の合流準備</Text>
          <Text style={styles.liveSub}>現在地・到着・服装写真をここから共有できます</Text>
        </View>
        <StatusPill label="取引予定" tone="sky" />
      </View>
      <View style={styles.liveGrid}>
        <LiveStateTile label="私" status={detail.myArrival} photoUrl={detail.myOutfitPhoto} />
        <LiveStateTile label="相手" status={detail.partnerArrival} photoUrl={detail.partnerOutfitPhoto} />
      </View>
      <Pressable
        accessibilityRole="button"
        disabled={outfitLoading}
        onPress={onShareOutfit}
        style={[styles.outfitShareButton, outfitLoading ? styles.actionDisabled : null]}
      >
        <Text style={styles.outfitShareText}>
          {outfitLoading ? "送信中…" : detail.myOutfitPhoto ? "服装写真を更新" : "服装写真を共有"}
        </Text>
      </Pressable>
    </View>
  );
}

function LiveStateTile({
  label,
  status,
  photoUrl,
}: {
  label: string;
  status: ArrivalStatus;
  photoUrl: string | null;
}) {
  return (
    <View style={styles.liveStateTile}>
      <Text style={styles.liveStateLabel}>{label}</Text>
      <Text style={styles.liveStateStatus}>{arrivalStatusLabel(status)}</Text>
      {photoUrl ? <Image source={{ uri: photoUrl }} style={styles.liveStatePhoto} /> : null}
    </View>
  );
}

function CompletionPanel({
  detail,
  evidenceUploading,
  onAddEvidence,
}: {
  detail: TransactionDetail;
  evidenceUploading: boolean;
  onAddEvidence: () => void;
}) {
  if (detail.status === "completed") {
    return (
      <View style={styles.completionPanel}>
        <View style={styles.completionIcon}>
          <Text style={styles.completionIconText}>✓</Text>
        </View>
        <View style={styles.completionCopy}>
          <Text style={styles.completionTitle}>取引完了</Text>
          <Text style={styles.completionSub}>評価を送って、交換体験を記録できます。</Text>
        </View>
        <Pressable
          accessibilityRole="button"
          onPress={() =>
            router.push({ pathname: "/transaction-rate", params: { id: detail.id } })
          }
          style={styles.completionButton}
        >
          <Text style={styles.completionButtonText}>評価</Text>
        </Pressable>
      </View>
    );
  }

  if (!detail.hasEvidence) return null;

  return (
    <View style={styles.evidenceCard}>
      <View>
        <Text style={styles.evidenceTitle}>取引証跡が届いています</Text>
        <Text style={styles.evidenceSub}>
          {detail.myCompletionApproved
            ? detail.partnerCompletionApproved
              ? "両者承認済みです"
              : "あなたは承認済み。相手の承認待ちです。"
            : "内容を確認して、問題なければ承認してください。"}
        </Text>
      </View>
      <View style={styles.evidenceActions}>
        <Pressable
          accessibilityRole="button"
          disabled={evidenceUploading}
          onPress={onAddEvidence}
          style={styles.evidenceSecondary}
        >
          <Text style={styles.evidenceSecondaryText}>
            {evidenceUploading ? "撮影中…" : "追加撮影"}
          </Text>
        </Pressable>
        <Pressable
          accessibilityRole="button"
          onPress={() =>
            router.push({ pathname: "/transaction-approve", params: { id: detail.id } })
          }
          style={styles.evidencePrimary}
        >
          <Text style={styles.evidencePrimaryText}>確認へ</Text>
        </Pressable>
      </View>
    </View>
  );
}

function messageText(message: ChatMessage) {
  if (message.type === "arrival_status") {
    const status = message.meta?.status;
    if (status === "arrived") return "到着しました";
    if (status === "enroute") return "向かっています";
    if (status === "left") return "離れました";
  }
  if (message.type === "location") {
    return message.locationLabel ?? "現在地を共有しました";
  }
  if (message.type === "outfit_photo") {
    return message.body ?? "服装写真を共有しました";
  }
  if (message.type === "photo") {
    return message.body ?? "写真を共有しました";
  }
  return message.body ?? "";
}

function shortTime(value: string) {
  const date = new Date(value);
  return `${String(date.getHours()).padStart(2, "0")}:${String(
    date.getMinutes(),
  ).padStart(2, "0")}`;
}

function dayLabel(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "";
  return `${date.getMonth() + 1}/${date.getDate()} (${"日月火水木金土"[date.getDay()]}) · ${shortTime(value)}`;
}

function toDetailItem(id: string, qty: number, row?: InventoryRow): DetailItem {
  const label =
    pickName(row?.character) ?? pickName(row?.group) ?? row?.title ?? "グッズ";
  return {
    id,
    label,
    goodsType: pickName(row?.goods_type),
    photoUrl: row?.photo_urls?.[0] ?? null,
    qty,
    hue: normalizeHue(row?.hue, label),
  };
}

function parseMeetups(proposal: ProposalRow): MeetupCandidate[] {
  const fromJson = Array.isArray(proposal.meetup_candidates)
    ? proposal.meetup_candidates
        .map((candidate) => {
          if (!candidate || typeof candidate !== "object") return null;
          const raw = candidate as Record<string, unknown>;
          const startAt = typeof raw.startAt === "string" ? raw.startAt : null;
          const endAt = typeof raw.endAt === "string" ? raw.endAt : null;
          const placeName =
            typeof raw.placeName === "string" ? raw.placeName : null;
          if (!startAt || !endAt || !placeName) return null;
          return {
            startAt,
            endAt,
            placeName,
            lat: typeof raw.lat === "number" ? raw.lat : null,
            lng: typeof raw.lng === "number" ? raw.lng : null,
          };
        })
        .filter((candidate): candidate is MeetupCandidate => !!candidate)
    : [];
  if (fromJson.length > 0) return fromJson;
  if (
    proposal.meetup_start_at &&
    proposal.meetup_end_at &&
    proposal.meetup_place_name
  ) {
    return [
      {
        startAt: proposal.meetup_start_at,
        endAt: proposal.meetup_end_at,
        placeName: proposal.meetup_place_name,
        lat: proposal.meetup_lat,
        lng: proposal.meetup_lng,
      },
    ];
  }
  return [];
}

function normalizeStatus(status: string): ProposalStatus {
  if (
    status === "sent" ||
    status === "negotiating" ||
    status === "agreement_one_side" ||
    status === "agreed" ||
    status === "completed" ||
    status === "cancelled" ||
    status === "rejected" ||
    status === "expired"
  ) {
    return status;
  }
  return "cancelled";
}

function statusLabel(detail: TransactionDetail) {
  if (detail.status === "sent") return detail.isReceiver ? "新着打診" : "相手待ち";
  if (detail.status === "negotiating") return "ネゴ中";
  if (detail.status === "agreement_one_side") {
    return detail.myAgreed ? "相手の合意待ち" : "合意待ち";
  }
  if (detail.status === "agreed") return "取引予定";
  if (detail.status === "completed") return "完了";
  if (detail.status === "rejected") return "見送り";
  if (detail.status === "expired") return "期限切れ";
  return "キャンセル";
}

function headerAgreementLabel(detail: TransactionDetail) {
  if (detail.status === "completed") return "完了";
  if (detail.status === "agreed") return "合意済";
  if (detail.status === "agreement_one_side") {
    return detail.myAgreed ? "相手待ち" : "確認待ち";
  }
  if (detail.myAgreed && detail.partnerAgreed) return "合意済";
  if (detail.myAgreed) return "相手待ち";
  if (detail.partnerAgreed) return "確認待ち";
  if (detail.status === "negotiating") return "相談中";
  if (detail.status === "sent") return detail.isSender ? "返信待ち" : "未合意";
  return statusLabel(detail);
}

function exchangeMethodSummary(method: ExchangeMethod) {
  if (method === "mail") return "郵送のみ";
  if (method === "both") return "郵送・現地交換どちらもOK";
  return "現地交換のみ";
}

function exchangeMethodDescription(method: ExchangeMethod) {
  if (method === "mail") {
    return "この取引は郵送のみで進めます。住所は当事者だけに表示されます。";
  }
  if (method === "both") {
    return "この取引は郵送でも現地交換でも進められます。郵送で進める場合は、成立後に当事者同士の住所を表示します。";
  }
  return "この取引は現地交換のみで進めます。";
}

function tradeSummaryLine(detail: TransactionDetail) {
  const receiveSummary =
    detail.cashOffer && detail.receive.length === 0
      ? `¥${detail.cashAmount?.toLocaleString() ?? "—"}`
      : itemSummary(detail.receive);
  return `受け取る ${receiveSummary}  ⇄  出す ${itemSummary(detail.give)}`;
}

function itemSummary(items: DetailItem[]) {
  if (items.length === 0) return "未設定";
  const first = items[0];
  const suffix = items.length > 1 ? ` 他${items.length - 1}点` : "";
  return `${first.label}${first.qty > 1 ? `×${first.qty}` : ""}${suffix}`;
}

function formatDateTime(startAt: string, endAt: string) {
  if (!startAt || !endAt) return "候補時間";
  const start = new Date(startAt);
  const end = new Date(endAt);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
    return "候補時間";
  }
  return `${start.getMonth() + 1}/${start.getDate()} ${timeText(start)} - ${timeText(end)}`;
}

function timeText(date: Date) {
  return `${String(date.getHours()).padStart(2, "0")}:${String(
    date.getMinutes(),
  ).padStart(2, "0")}`;
}

function formatDeadline(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "未設定";
  return `${date.getMonth() + 1}/${date.getDate()} ${timeText(date)}`;
}

function arrivalStatusLabel(status: ArrivalStatus) {
  if (status === "arrived") return "到着済み";
  if (status === "enroute") return "向かっています";
  if (status === "left") return "離れました";
  return "未共有";
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

function normalizeHue(value: number | string | null | undefined, seed: string) {
  if (typeof value === "number") return `hsl(${value}, 62%, 78%)`;
  if (typeof value === "string" && value.trim()) {
    return value.startsWith("#") || value.startsWith("hsl")
      ? value
      : `hsl(${Number(value) || nameToHue(seed)}, 62%, 78%)`;
  }
  return `hsl(${nameToHue(seed)}, 62%, 78%)`;
}

function nameToHue(name: string) {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = (hash << 5) - hash + name.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash) % 360;
}

const styles = StyleSheet.create({
  chatRoot: {
    backgroundColor: megrumColors.background,
    flex: 1,
  },
  chatHeaderBar: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.98)",
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: 1,
    flexDirection: "row",
    gap: 10,
    paddingBottom: 8,
    paddingHorizontal: 14,
  },
  headerReportButton: {
    backgroundColor: "rgba(217,130,107,0.10)",
    borderColor: "rgba(217,130,107,0.28)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  headerReportText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
  },
  chatPartnerStrip: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.96)",
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: 1,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 14,
    paddingVertical: 9,
  },
  chatBackButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 32,
    justifyContent: "center",
    width: 32,
  },
  chatBackText: {
    color: megrumColors.ink,
    fontSize: 25,
    fontWeight: "800",
    lineHeight: 27,
  },
  headerAvatar: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    borderRadius: 16,
    height: 32,
    justifyContent: "center",
    overflow: "hidden",
    width: 32,
  },
  headerAvatarImage: {
    height: "100%",
    width: "100%",
  },
  headerAvatarText: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  chatHeaderCopy: {
    flex: 1,
    minWidth: 0,
  },
  chatHeaderName: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "800",
  },
  chatHeaderMetaRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 4,
    marginTop: 1,
  },
  chatHeaderDot: {
    borderRadius: 3,
    height: 6,
    width: 6,
  },
  chatHeaderMetaText: {
    fontSize: 10,
    fontWeight: "900",
  },
  chatHeaderArea: {
    color: megrumColors.mutedInk,
    flexShrink: 1,
    fontSize: 10,
    fontWeight: "700",
  },
  chatHeaderChevron: {
    color: "rgba(58,50,74,0.32)",
    fontSize: 18,
    fontWeight: "900",
  },
  chatHeaderStatusBadge: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    justifyContent: "center",
    maxWidth: 78,
    minWidth: 56,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  chatHeaderStatusBadgeWaiting: {
    backgroundColor: "rgba(166,149,216,0.10)",
    borderColor: "rgba(166,149,216,0.24)",
  },
  chatHeaderStatusBadgeDone: {
    backgroundColor: megrumColors.ok,
    borderColor: megrumColors.ok,
  },
  chatHeaderStatusText: {
    color: megrumColors.ink,
    fontSize: 10,
    fontWeight: "900",
  },
  chatHeaderStatusTextDone: {
    color: megrumColors.surface,
  },
  chatPinnedArea: {
    backgroundColor: megrumColors.background,
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: 1,
    gap: 6,
    paddingBottom: 6,
    paddingHorizontal: 14,
    paddingTop: 10,
  },
  mailBanner: {
    backgroundColor: "rgba(255,255,255,0.96)",
    borderColor: "rgba(166,149,216,0.20)",
    borderRadius: 14,
    borderWidth: 1,
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 12,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.07,
    shadowRadius: 8,
  },
  mailBannerHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  mailBannerTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  mailBannerBody: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "700",
    lineHeight: 17,
  },
  mailBannerActionRow: {
    gap: 8,
  },
  mailBannerHint: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "700",
  },
  mailBannerLinkButton: {
    alignSelf: "flex-start",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  mailBannerLinkText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  mailAddressCard: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderRadius: 12,
    gap: 3,
    paddingHorizontal: 11,
    paddingVertical: 10,
  },
  mailAddressTitle: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
    marginBottom: 3,
  },
  mailAddressLine: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "700",
    lineHeight: 16,
  },
  exchangeMethodModalBody: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 18,
  },
  dealCollapsedCard: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 12,
    borderWidth: 1,
    flexDirection: "row",
    gap: 8,
    minHeight: 42,
    paddingHorizontal: 12,
    paddingVertical: 8,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 7,
  },
  dealCollapsedCardPressed: {
    opacity: 0.78,
  },
  dealCollapsedLabel: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  dealCollapsedSummary: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 11.5,
    fontWeight: "800",
    minWidth: 0,
  },
  dealCollapsedAction: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
  dealConditionTagRow: {
    gap: 6,
    paddingTop: 7,
  },
  dealConditionTag: {
    backgroundColor: "rgba(168,212,230,0.16)",
    borderColor: "rgba(168,212,230,0.36)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  dealConditionTagText: {
    color: "#3a7c93",
    fontSize: 10,
    fontWeight: "900",
  },
  dealCardWeb: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.20)",
    borderRadius: 14,
    borderWidth: 1,
    overflow: "hidden",
    shadowColor: megrumColors.lavender,
    shadowOpacity: 0.08,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
  },
  dealCardPressed: {
    opacity: 0.78,
  },
  dealCardTopRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 12,
    paddingTop: 8,
  },
  dealCardEyebrow: {
    color: megrumColors.lavender,
    flex: 1,
    fontSize: 9.5,
    fontWeight: "900",
    letterSpacing: 0.5,
  },
  dealCardBadge: {
    backgroundColor: "rgba(217,130,107,0.14)",
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 7,
    paddingVertical: 2,
  },
  dealCardBadgeDone: {
    backgroundColor: megrumColors.ok,
  },
  dealCardBadgeText: {
    color: megrumColors.surface,
    fontSize: 9,
    fontWeight: "900",
    letterSpacing: 0.4,
  },
  dealTradeRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 6,
    paddingBottom: 8,
    paddingHorizontal: 12,
    paddingTop: 5,
  },
  dealSide: {
    flex: 1,
    minWidth: 0,
  },
  dealSideRight: {
    alignItems: "flex-end",
  },
  dealSideLabel: {
    color: megrumColors.mutedInk,
    fontSize: 8.5,
    fontWeight: "900",
    letterSpacing: 0.4,
    marginBottom: 3,
  },
  dealSideLabelRight: {
    textAlign: "right",
  },
  dealSwapIcon: {
    color: megrumColors.lavender,
    fontSize: 15,
    fontWeight: "900",
  },
  miniItemRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 4,
  },
  miniItemRowRight: {
    justifyContent: "flex-end",
  },
  miniItemEmpty: {
    color: "rgba(58,50,74,0.28)",
    fontSize: 10,
    fontStyle: "italic",
    fontWeight: "800",
  },
  miniThumb: {
    borderColor: "rgba(255,255,255,0.66)",
    borderRadius: 3,
    borderWidth: 1,
    height: 28,
    overflow: "hidden",
    position: "relative",
    width: 22,
  },
  miniThumbImage: {
    height: "100%",
    width: "100%",
  },
  miniThumbFallback: {
    alignItems: "center",
    height: "100%",
    justifyContent: "center",
    width: "100%",
  },
  miniThumbGlyph: {
    color: megrumColors.surface,
    fontSize: 10,
    fontWeight: "900",
  },
  miniQty: {
    backgroundColor: "rgba(0,0,0,0.60)",
    borderBottomLeftRadius: 3,
    position: "absolute",
    right: 0,
    top: 0,
    paddingHorizontal: 2,
  },
  miniQtyText: {
    color: megrumColors.surface,
    fontSize: 7,
    fontWeight: "900",
  },
  miniMore: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.04)",
    borderRadius: 5,
    height: 28,
    justifyContent: "center",
    minWidth: 22,
    paddingHorizontal: 4,
  },
  miniMoreText: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "900",
  },
  cashChipNative: {
    alignSelf: "flex-start",
    backgroundColor: "rgba(122,154,138,0.08)",
    borderRadius: 6,
    paddingHorizontal: 7,
    paddingVertical: 2,
  },
  cashChipText: {
    color: "#7a9a8a",
    fontSize: 11,
    fontWeight: "900",
  },
  dealMeetupRow: {
    alignItems: "center",
    borderTopColor: "rgba(58,50,74,0.08)",
    borderTopWidth: 1,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  dealMapThumb: {
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 8,
    borderWidth: 1,
    height: 44,
    overflow: "hidden",
    width: 68,
  },
  dealMapEmpty: {
    alignItems: "center",
    backgroundColor: "#e8eef0",
    flex: 1,
    justifyContent: "center",
  },
  dealMapEmptyText: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "800",
  },
  dealMeetupCopy: {
    flex: 1,
    minWidth: 0,
  },
  dealMeetupEyebrow: {
    color: megrumColors.lavender,
    fontSize: 8.5,
    fontWeight: "900",
    letterSpacing: 0.4,
  },
  dealMeetupTime: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
    marginTop: 1,
  },
  dealMeetupPlace: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "800",
    marginTop: 1,
  },
  dealMeetupArrow: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
  dealModalBackdrop: {
    alignItems: "center",
    backgroundColor: "rgba(10,8,16,0.42)",
    flex: 1,
    justifyContent: "center",
    paddingHorizontal: 18,
  },
  dealModalCard: {
    backgroundColor: megrumColors.surface,
    borderRadius: 22,
    gap: 13,
    maxHeight: "86%",
    maxWidth: 420,
    padding: 16,
    width: "100%",
  },
  dealModalContent: {
    gap: 13,
    paddingBottom: 2,
  },
  dealModalHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  dealModalTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  dealModalSub: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    marginTop: 2,
  },
  dealModalClose: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: megrumRadii.pill,
    height: 34,
    justifyContent: "center",
    width: 34,
  },
  dealModalCloseText: {
    color: megrumColors.ink,
    fontSize: 20,
    fontWeight: "800",
    lineHeight: 22,
  },
  dealModalSection: {
    backgroundColor: "rgba(58,50,74,0.035)",
    borderRadius: 14,
    gap: 8,
    padding: 12,
  },
  dealModalSectionTitle: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
  dealModalSectionHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  dealModalSectionCount: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.lavender,
    fontSize: 9.5,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  dealExchangeCard: {
    alignItems: "flex-start",
    backgroundColor: "rgba(168,212,230,0.08)",
    borderRadius: 16,
    flexDirection: "row",
    gap: 9,
    padding: 10,
  },
  dealExchangeSidePanel: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.07)",
    borderRadius: 13,
    borderWidth: 1,
    flex: 1,
    minHeight: 118,
    padding: 9,
  },
  dealExchangeSidePanelRight: {
    backgroundColor: "rgba(243,197,212,0.08)",
  },
  dealExchangeSideLabel: {
    color: "#5c8da8",
    fontSize: 10.5,
    fontWeight: "900",
    marginBottom: 8,
  },
  dealExchangeSideLabelRight: {
    color: megrumColors.lavender,
    textAlign: "right",
  },
  dealExchangeSwapColumn: {
    alignItems: "center",
    gap: 4,
    paddingTop: 24,
  },
  dealExchangeArrowDot: {
    alignItems: "center",
    borderRadius: 999,
    height: 24,
    justifyContent: "center",
    width: 24,
  },
  dealExchangeArrowText: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
    lineHeight: 15,
  },
  dealExchangeCash: {
    alignSelf: "flex-start",
    backgroundColor: "rgba(122,154,138,0.10)",
    borderRadius: 10,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  dealExchangeCashRight: {
    alignSelf: "flex-end",
  },
  dealExchangeCashText: {
    color: "#6b8c78",
    fontSize: 13,
    fontWeight: "900",
  },
  dealModalItems: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  dealModalItemsRight: {
    justifyContent: "flex-end",
  },
  dealModalThumb: {
    backgroundColor: "rgba(58,50,74,0.03)",
    borderRadius: 10,
    overflow: "hidden",
    position: "relative",
    width: 48,
  },
  dealModalThumbPhoto: {
    height: 48,
    width: 48,
  },
  dealModalThumbFallback: {
    alignItems: "center",
    height: 48,
    justifyContent: "center",
    overflow: "hidden",
    position: "relative",
    width: 48,
  },
  dealModalThumbShine: {
    backgroundColor: "rgba(255,255,255,0.24)",
    borderRadius: 999,
    height: 34,
    position: "absolute",
    right: -8,
    top: -8,
    width: 34,
  },
  dealModalThumbGlyph: {
    color: megrumColors.surface,
    fontSize: 17,
    fontWeight: "900",
  },
  dealModalThumbQty: {
    backgroundColor: "rgba(0,0,0,0.60)",
    borderBottomLeftRadius: 5,
    paddingHorizontal: 3,
    paddingVertical: 1,
    position: "absolute",
    right: 0,
    top: 0,
  },
  dealModalThumbQtyText: {
    color: megrumColors.surface,
    fontSize: 8,
    fontWeight: "900",
  },
  dealModalThumbMeta: {
    paddingHorizontal: 4,
    paddingVertical: 4,
  },
  dealModalThumbLabel: {
    color: megrumColors.ink,
    fontSize: 9.5,
    fontWeight: "900",
  },
  dealModalThumbSub: {
    color: megrumColors.mutedInk,
    fontSize: 8.5,
    fontWeight: "800",
    marginTop: 1,
  },
  dealModalItem: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
  },
  dealModalItemPhoto: {
    borderRadius: 8,
    height: 48,
    width: 38,
  },
  dealModalItemFallback: {
    alignItems: "center",
    borderRadius: 8,
    height: 48,
    justifyContent: "center",
    width: 38,
  },
  dealModalItemGlyph: {
    color: megrumColors.surface,
    fontSize: 15,
    fontWeight: "900",
  },
  dealModalItemCopy: {
    flex: 1,
    minWidth: 0,
  },
  dealModalItemLabel: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  dealModalItemMeta: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  dealModalEmpty: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  dealModalCash: {
    alignSelf: "flex-start",
    backgroundColor: "rgba(122,154,138,0.10)",
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  dealModalCashText: {
    color: "#6b8c78",
    fontSize: 15,
    fontWeight: "900",
  },
  dealModalMeetup: {
    gap: 3,
  },
  dealModalMeetupTime: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  dealModalMeetupPlace: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  dealCandidateList: {
    gap: 8,
    padding: 12,
  },
  dealMeetupMapCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 14,
    borderWidth: 1,
    overflow: "hidden",
  },
  dealMeetupMapPanel: {
    backgroundColor: "#edf3f4",
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: 1,
    minHeight: 184,
    overflow: "hidden",
  },
  dealMeetupMapEmpty: {
    alignItems: "center",
    flex: 1,
    minHeight: 184,
    justifyContent: "center",
  },
  dealMeetupMapEmptyText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  dealMeetupMapOpenPill: {
    backgroundColor: "rgba(58,50,74,0.78)",
    borderRadius: megrumRadii.pill,
    bottom: 10,
    paddingHorizontal: 10,
    paddingVertical: 5,
    position: "absolute",
    right: 10,
  },
  dealMeetupMapOpenText: {
    color: megrumColors.surface,
    fontSize: 10,
    fontWeight: "900",
  },
  dealCandidateRow: {
    alignItems: "flex-start",
    flexDirection: "row",
    gap: 9,
  },
  dealCandidateNumber: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    height: 22,
    justifyContent: "center",
    marginTop: 1,
    width: 22,
  },
  dealCandidateNumberText: {
    color: megrumColors.surface,
    fontSize: 11,
    fontWeight: "900",
  },
  dealCandidateCopy: {
    flex: 1,
    minWidth: 0,
  },
  dealCandidateTime: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  dealCandidatePlace: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  dealModalMessage: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 18,
  },
  expireBanner: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.04)",
    borderColor: "rgba(166,149,216,0.34)",
    borderRadius: 10,
    borderWidth: 1,
    flexDirection: "row",
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  expireBannerWarn: {
    backgroundColor: "#fff5f0",
    borderColor: "rgba(217,130,107,0.50)",
  },
  expireIcon: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
  },
  expireCopy: {
    flex: 1,
  },
  expireTitle: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  expireTitleWarn: {
    color: megrumColors.warn,
  },
  expireSub: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "800",
    marginTop: 2,
  },
  expireButton: {
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  expireButtonWarn: {
    backgroundColor: megrumColors.warn,
  },
  expireButtonText: {
    color: megrumColors.surface,
    fontSize: 10,
    fontWeight: "900",
  },
  agreementCompact: {
    backgroundColor: "rgba(166,149,216,0.07)",
    borderColor: "rgba(166,149,216,0.34)",
    borderRadius: 12,
    borderWidth: 1,
    overflow: "hidden",
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  agreementCompactText: {
    color: megrumColors.ink,
    fontSize: 10.5,
    fontWeight: "700",
    lineHeight: 16,
  },
  agreementCompactActions: {
    flexDirection: "row",
    gap: 6,
    marginTop: 8,
  },
  agreementRejectButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 10,
    borderWidth: 1,
    justifyContent: "center",
    paddingHorizontal: 13,
    paddingVertical: 7,
  },
  agreementRejectText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  agreementAcceptButton: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 10,
    flex: 1,
    justifyContent: "center",
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  agreementAcceptText: {
    color: megrumColors.surface,
    fontSize: 11.5,
    fontWeight: "900",
  },
  acceptModalCard: {
    backgroundColor: megrumColors.surface,
    borderRadius: 22,
    maxHeight: "86%",
    overflow: "hidden",
    paddingTop: 16,
    width: "92%",
  },
  acceptModalContent: {
    gap: 12,
    padding: 16,
  },
  acceptChoiceGroup: {
    backgroundColor: "rgba(58,50,74,0.035)",
    borderRadius: 14,
    gap: 9,
    padding: 12,
  },
  acceptChoiceRow: {
    flexDirection: "row",
    gap: 8,
  },
  acceptChoiceButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: 12,
    borderWidth: 1,
    flex: 1,
    paddingHorizontal: 12,
    paddingVertical: 11,
  },
  acceptChoiceButtonActive: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderColor: "rgba(166,149,216,0.48)",
  },
  acceptChoiceText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
  },
  acceptChoiceTextActive: {
    color: megrumColors.lavender,
  },
  acceptMeetupRow: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 13,
    borderWidth: 1,
    flexDirection: "row",
    gap: 10,
    padding: 10,
  },
  acceptMeetupRowActive: {
    backgroundColor: "rgba(166,149,216,0.10)",
    borderColor: "rgba(166,149,216,0.46)",
  },
  acceptRadio: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.20)",
    borderRadius: 999,
    borderWidth: 2,
    height: 22,
    justifyContent: "center",
    width: 22,
  },
  acceptRadioActive: {
    borderColor: megrumColors.lavender,
  },
  acceptRadioDot: {
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    height: 10,
    width: 10,
  },
  acceptMeetupCopy: {
    flex: 1,
    minWidth: 0,
  },
  acceptMeetupTime: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  acceptMeetupPlace: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  acceptModalFooter: {
    borderTopColor: "rgba(58,50,74,0.08)",
    borderTopWidth: 1,
    flexDirection: "row",
    gap: 8,
    padding: 14,
  },
  acceptCounterButton: {
    alignItems: "center",
    backgroundColor: "rgba(243,197,212,0.16)",
    borderRadius: 12,
    flex: 1,
    justifyContent: "center",
    paddingVertical: 11,
  },
  acceptCounterText: {
    color: megrumColors.warn,
    fontSize: 11.5,
    fontWeight: "900",
  },
  acceptConfirmButton: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 12,
    flex: 1,
    justifyContent: "center",
    paddingVertical: 11,
  },
  acceptConfirmText: {
    color: megrumColors.surface,
    fontSize: 11.5,
    fontWeight: "900",
  },
  outfitCompactWeb: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.04)",
    borderColor: "rgba(166,149,216,0.34)",
    borderRadius: 10,
    borderWidth: 1,
    flexDirection: "row",
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  outfitIcon: {
    fontSize: 12,
  },
  outfitTitle: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  outfitState: {
    color: megrumColors.ink,
    flexShrink: 1,
    fontSize: 10,
    fontWeight: "700",
  },
  outfitSlash: {
    color: megrumColors.mutedInk,
    fontSize: 10,
  },
  outfitShootButton: {
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  outfitShootText: {
    color: megrumColors.surface,
    fontSize: 10,
    fontWeight: "900",
  },
  chatMessagesScroll: {
    flex: 1,
  },
  chatMessagesContent: {
    gap: 8,
    paddingHorizontal: 14,
    paddingTop: 8,
  },
  chatMessageEndAnchor: {
    height: 1,
  },
  emptyMessageCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 12,
    borderStyle: "dashed",
    borderWidth: 1,
    paddingHorizontal: 16,
    paddingVertical: 22,
  },
  emptyMessageText: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    textAlign: "center",
  },
  daySeparator: {
    alignItems: "center",
    paddingVertical: 2,
  },
  daySeparatorText: {
    backgroundColor: "rgba(58,50,74,0.04)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "700",
    overflow: "hidden",
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  evidenceCalloutWeb: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.40)",
    borderRadius: 14,
    borderStyle: "dashed",
    borderWidth: 1,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  evidenceCalloutIcon: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 10,
    height: 32,
    justifyContent: "center",
    width: 32,
  },
  evidenceCalloutIconText: {
    color: megrumColors.surface,
    fontSize: 14,
    fontWeight: "900",
  },
  evidenceCalloutCopy: {
    flex: 1,
  },
  evidenceCalloutTitle: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  evidenceCalloutSub: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "800",
    marginTop: 2,
  },
  evidenceCalloutButton: {
    backgroundColor: megrumColors.lavender,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  evidenceCalloutButtonText: {
    color: megrumColors.surface,
    fontSize: 11.5,
    fontWeight: "900",
  },
  bottomComposer: {
    backgroundColor: "rgba(255,255,255,0.96)",
    borderTopColor: "rgba(166,149,216,0.13)",
    borderTopWidth: 1,
    paddingTop: 8,
  },
  evidenceFixedFooterButton: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 16,
    justifyContent: "center",
    marginBottom: 7,
    marginHorizontal: 12,
    minHeight: 48,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.20,
    shadowRadius: 14,
  },
  evidenceFixedFooterText: {
    color: megrumColors.surface,
    fontSize: 14,
    fontWeight: "900",
  },
  webQuickActionRow: {
    gap: 6,
    paddingBottom: 6,
    paddingHorizontal: 12,
  },
  webComposerRow: {
    alignItems: "flex-end",
    flexDirection: "row",
    gap: 8,
    paddingHorizontal: 12,
  },
  composerPlusButton: {
    alignItems: "center",
    alignSelf: "flex-end",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 18,
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  composerPlusText: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "700",
  },
  webComposerInput: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1,
    color: megrumColors.ink,
    flex: 1,
    fontSize: 16,
    fontWeight: "700",
    lineHeight: 20,
    maxHeight: 156,
    minHeight: 36,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  webSendButton: {
    alignItems: "center",
    alignSelf: "flex-end",
    backgroundColor: megrumColors.lavender,
    borderRadius: 18,
    height: 36,
    justifyContent: "center",
    shadowColor: megrumColors.lavender,
    shadowOpacity: 0.36,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    width: 36,
  },
  webSendButtonText: {
    color: megrumColors.surface,
    fontSize: 15,
    fontWeight: "900",
  },
  loginPromptWrap: {
    flex: 1,
    justifyContent: "center",
    paddingHorizontal: 18,
  },
  screen: {
    gap: 14,
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  backButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 44,
    justifyContent: "center",
    width: 44,
    ...megrumShadow,
  },
  backText: {
    color: megrumColors.ink,
    fontSize: 32,
    fontWeight: "800",
    lineHeight: 34,
  },
  inlineNotice: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  inlineError: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  loginPrompt: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 11,
    padding: 16,
    ...megrumShadow,
  },
  loginPromptTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  loginPromptText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  partnerCard: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 24,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    padding: 14,
    ...megrumShadow,
  },
  partnerAvatar: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    borderRadius: 22,
    height: 52,
    justifyContent: "center",
    overflow: "hidden",
    width: 52,
  },
  partnerAvatarImage: {
    height: "100%",
    width: "100%",
  },
  partnerAvatarText: {
    color: megrumColors.lavender,
    fontSize: 18,
    fontWeight: "900",
  },
  partnerCopy: {
    flex: 1,
  },
  partnerName: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  partnerMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  agreeState: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  agreeStateText: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  disputeBanner: {
    alignItems: "center",
    backgroundColor: "#fff5f0",
    borderColor: "rgba(217,130,107,0.25)",
    borderRadius: 16,
    borderWidth: 1,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  disputeIcon: {
    alignItems: "center",
    backgroundColor: megrumColors.warn,
    borderRadius: 11,
    height: 22,
    justifyContent: "center",
    width: 22,
  },
  disputeIconText: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
  },
  disputeCopy: {
    flex: 1,
  },
  disputeTitle: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
  },
  disputeSub: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  disputeArrow: {
    color: megrumColors.warn,
    fontSize: 18,
    fontWeight: "900",
  },
  negotiationPanel: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.20)",
    borderRadius: 22,
    borderWidth: 1,
    gap: 12,
    padding: 14,
    ...megrumShadow,
  },
  negotiationHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
    justifyContent: "space-between",
  },
  negotiationTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  negotiationSub: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 3,
  },
  extendButton: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderColor: "rgba(166,149,216,0.28)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  extendButtonText: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  agreementStateRow: {
    flexDirection: "row",
    gap: 7,
  },
  agreementStateChip: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  agreementStateChipDone: {
    backgroundColor: "rgba(34,197,94,0.12)",
  },
  agreementStateChipText: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
  agreementStateChipTextDone: {
    color: megrumColors.ok,
  },
  negotiationActions: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  negotiationPrimary: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.md,
    flexGrow: 1,
    justifyContent: "center",
    minHeight: 42,
    paddingHorizontal: 13,
  },
  negotiationPrimaryText: {
    color: megrumColors.surface,
    fontSize: 12,
    fontWeight: "900",
  },
  negotiationSecondary: {
    alignItems: "center",
    backgroundColor: "rgba(168,212,230,0.18)",
    borderRadius: megrumRadii.md,
    justifyContent: "center",
    minHeight: 42,
    paddingHorizontal: 13,
  },
  negotiationSecondaryText: {
    color: "#3a7c93",
    fontSize: 12,
    fontWeight: "900",
  },
  negotiationReject: {
    alignItems: "center",
    borderRadius: megrumRadii.md,
    justifyContent: "center",
    minHeight: 42,
    paddingHorizontal: 10,
  },
  negotiationRejectText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
  },
  livePanel: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(168,212,230,0.25)",
    borderRadius: 22,
    borderWidth: 1,
    gap: 12,
    padding: 14,
    ...megrumShadow,
  },
  liveHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  liveTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  liveSub: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 3,
  },
  liveGrid: {
    flexDirection: "row",
    gap: 8,
  },
  liveStateTile: {
    backgroundColor: "rgba(58,50,74,0.04)",
    borderRadius: 15,
    flex: 1,
    minHeight: 74,
    padding: 10,
  },
  liveStateLabel: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
  },
  liveStateStatus: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
    marginTop: 4,
  },
  liveStatePhoto: {
    borderRadius: 8,
    height: 36,
    marginTop: 7,
    width: 36,
  },
  outfitShareButton: {
    alignItems: "center",
    backgroundColor: "rgba(243,197,212,0.24)",
    borderColor: "rgba(243,197,212,0.44)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    justifyContent: "center",
    minHeight: 42,
  },
  outfitShareText: {
    color: "#b85f80",
    fontSize: 12,
    fontWeight: "900",
  },
  actionDisabled: {
    opacity: 0.55,
  },
  tradePanel: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(168,212,230,0.25)",
    borderRadius: 24,
    borderWidth: 1,
    flexDirection: "row",
    gap: 10,
    padding: 14,
  },
  tradeColumn: {
    flex: 1,
  },
  tradeTitle: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
    marginBottom: 8,
  },
  tradeTitleRight: {
    textAlign: "right",
  },
  detailItems: {
    gap: 8,
  },
  detailItemsRight: {
    alignItems: "flex-end",
  },
  detailItem: {
    alignItems: "center",
    flexDirection: "row",
    gap: 7,
    maxWidth: "100%",
  },
  itemPhoto: {
    borderRadius: 8,
    height: 42,
    width: 34,
  },
  itemFallback: {
    alignItems: "center",
    borderRadius: 8,
    height: 42,
    justifyContent: "center",
    width: 34,
  },
  itemGlyph: {
    color: megrumColors.surface,
    fontSize: 15,
    fontWeight: "900",
  },
  itemLabel: {
    color: megrumColors.ink,
    flexShrink: 1,
    fontSize: 11.5,
    fontWeight: "900",
    maxWidth: 82,
  },
  itemQty: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
  },
  tradeCenter: {
    alignItems: "center",
    width: 26,
  },
  tradeArrow: {
    color: megrumColors.lavender,
    fontSize: 18,
    fontWeight: "900",
    lineHeight: 18,
  },
  tradeArrowMuted: {
    color: megrumColors.sky,
    fontSize: 18,
    fontWeight: "900",
    lineHeight: 18,
  },
  section: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 10,
    padding: 14,
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  chatSection: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 12,
    padding: 14,
  },
  chatHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  chatSub: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  arrivalActions: {
    flexDirection: "row",
    gap: 6,
  },
  arrivalButton: {
    backgroundColor: "rgba(168,212,230,0.18)",
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  arrivalButtonStrong: {
    backgroundColor: megrumColors.lavender,
  },
  arrivalButtonText: {
    color: "#3a7c93",
    fontSize: 10.5,
    fontWeight: "900",
  },
  arrivalButtonTextStrong: {
    color: megrumColors.surface,
  },
  messagesList: {
    gap: 8,
  },
  quickActionRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 7,
    marginTop: 8,
  },
  quickActionChip: {
    alignItems: "center",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    flexDirection: "row",
    gap: 5,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  quickActionLavender: {
    backgroundColor: "rgba(166,149,216,0.14)",
    borderColor: "rgba(166,149,216,0.28)",
  },
  quickActionPink: {
    backgroundColor: "rgba(243,197,212,0.22)",
    borderColor: "rgba(243,197,212,0.42)",
  },
  quickActionNeutral: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
  },
  quickActionDisabled: {
    opacity: 0.55,
  },
  quickActionIcon: {
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
  },
  quickActionIconNeutral: {
    color: megrumColors.ink,
  },
  quickActionLabel: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
  },
  systemMessage: {
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: megrumRadii.pill,
    maxWidth: "86%",
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  systemMessageAction: {
    backgroundColor: "rgba(166,149,216,0.14)",
    borderColor: "rgba(166,149,216,0.22)",
    borderWidth: 1,
    paddingHorizontal: 12,
  },
  systemMessageText: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    textAlign: "center",
  },
  systemMessageArrow: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
    marginTop: 2,
    textAlign: "center",
  },
  cancelRequestCard: {
    alignSelf: "stretch",
    backgroundColor: "#fff5f0",
    borderColor: "rgba(217,130,107,0.25)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    overflow: "hidden",
  },
  cancelRequestHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 7,
    paddingHorizontal: 12,
    paddingTop: 11,
  },
  cancelRequestIcon: {
    alignItems: "center",
    backgroundColor: megrumColors.warn,
    borderRadius: 10,
    height: 20,
    justifyContent: "center",
    width: 20,
  },
  cancelRequestIconText: {
    color: megrumColors.surface,
    fontSize: 12,
    fontWeight: "900",
    lineHeight: 14,
  },
  cancelRequestTitle: {
    color: megrumColors.warn,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.3,
  },
  cancelRequestBody: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "700",
    lineHeight: 18,
    paddingHorizontal: 12,
    paddingTop: 6,
  },
  cancelRequestError: {
    color: "#b42318",
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
    paddingHorizontal: 12,
    paddingTop: 7,
  },
  cancelRequestActions: {
    backgroundColor: "rgba(255,255,255,0.42)",
    borderTopColor: "rgba(217,130,107,0.12)",
    borderTopWidth: 1,
    flexDirection: "row",
    gap: 7,
    marginTop: 10,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  cancelRequestSecondary: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 10,
    borderWidth: 1,
    justifyContent: "center",
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  cancelRequestSecondaryText: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
  },
  cancelRequestPrimary: {
    alignItems: "center",
    backgroundColor: megrumColors.warn,
    borderRadius: 10,
    flex: 1,
    justifyContent: "center",
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  cancelRequestDisabled: {
    opacity: 0.55,
  },
  cancelRequestPrimaryText: {
    color: megrumColors.surface,
    fontSize: 12,
    fontWeight: "900",
  },
  chatBubbleRow: {
    alignItems: "flex-start",
  },
  chatBubbleRowMine: {
    alignItems: "flex-end",
  },
  chatBubblePartnerWrap: {
    alignItems: "flex-start",
    maxWidth: "82%",
  },
  chatBubbleMineWrap: {
    alignItems: "flex-end",
    flexDirection: "row",
    gap: 5,
    justifyContent: "flex-end",
    maxWidth: "88%",
  },
  chatBubble: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 17,
    borderTopLeftRadius: 6,
    maxWidth: "100%",
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  chatBubbleMine: {
    backgroundColor: "transparent",
    borderTopLeftRadius: 17,
    borderTopRightRadius: 6,
  },
  chatBubbleText: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "700",
    lineHeight: 19,
  },
  chatBubbleTextMine: {
    color: megrumColors.surface,
  },
  chatPhoto: {
    borderRadius: 12,
    height: 150,
    marginBottom: 7,
    width: 190,
  },
  chatMessageMeta: {
    alignItems: "flex-start",
    gap: 1,
    minWidth: 28,
    paddingBottom: 3,
  },
  chatMessageMetaText: {
    color: "rgba(58,50,74,0.48)",
    fontSize: 9,
    fontWeight: "800",
    lineHeight: 11,
  },
  chatTime: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "800",
    marginTop: 4,
  },
  chatTimeMine: {
    color: "rgba(255,255,255,0.72)",
  },
  locationBubble: {
    borderRadius: 17,
    maxWidth: "100%",
    overflow: "hidden",
  },
  locationBubbleMine: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.32)",
    borderTopRightRadius: 6,
    borderWidth: 1,
  },
  locationBubblePartner: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderTopLeftRadius: 6,
    borderWidth: 1,
  },
  locationMap: {
    width: 232,
  },
  locationBody: {
    gap: 3,
    paddingHorizontal: 11,
    paddingVertical: 9,
  },
  locationTitle: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  locationLink: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
  },
  locationTime: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "800",
  },
  composer: {
    alignItems: "flex-end",
    backgroundColor: "rgba(58,50,74,0.04)",
    borderRadius: 18,
    flexDirection: "row",
    gap: 8,
    padding: 7,
  },
  composerInput: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 13,
    fontWeight: "700",
    maxHeight: 92,
    minHeight: 38,
    paddingHorizontal: 9,
    paddingVertical: 8,
  },
  sendButton: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    height: 38,
    justifyContent: "center",
    paddingHorizontal: 13,
  },
  sendButtonDisabled: {
    opacity: 0.45,
  },
  sendButtonText: {
    color: megrumColors.surface,
    fontSize: 12,
    fontWeight: "900",
  },
  meetupCard: {
    alignItems: "center",
    backgroundColor: "rgba(168,212,230,0.14)",
    borderRadius: 16,
    flexDirection: "row",
    gap: 4,
    overflow: "hidden",
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  meetupMapThumb: {
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: 11,
    borderWidth: 1,
    height: 62,
    marginRight: 9,
    overflow: "hidden",
    width: 84,
  },
  meetupCopy: {
    flex: 1,
    gap: 3,
    minWidth: 0,
  },
  meetupTime: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  meetupPlace: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  meetupMapLink: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
  },
  emptyText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  messageText: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "700",
    lineHeight: 20,
  },
  actions: {
    gap: 10,
  },
  evidenceCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 12,
    padding: 15,
    ...megrumShadow,
  },
  evidenceTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  evidenceSub: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 18,
    marginTop: 4,
  },
  evidenceActions: {
    flexDirection: "row",
    gap: 9,
  },
  evidenceSecondary: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.05)",
    borderRadius: megrumRadii.md,
    flex: 1,
    justifyContent: "center",
    minHeight: 46,
  },
  evidenceSecondaryText: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  evidencePrimary: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.md,
    flex: 1,
    justifyContent: "center",
    minHeight: 46,
  },
  evidencePrimaryText: {
    color: megrumColors.surface,
    fontSize: 12.5,
    fontWeight: "900",
  },
  completionPanel: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(34,197,94,0.18)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    padding: 15,
    ...megrumShadow,
  },
  completionIcon: {
    alignItems: "center",
    backgroundColor: megrumColors.ok,
    borderRadius: megrumRadii.pill,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  completionIconText: {
    color: megrumColors.surface,
    fontSize: 22,
    fontWeight: "900",
  },
  completionCopy: {
    flex: 1,
  },
  completionTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  completionSub: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
    marginTop: 3,
  },
  completionButton: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    height: 42,
    justifyContent: "center",
    paddingHorizontal: 15,
  },
  completionButtonText: {
    color: megrumColors.surface,
    fontSize: 12,
    fontWeight: "900",
  },
  tradeSupportActions: {
    flexDirection: "row",
    gap: 8,
  },
  tradeSupportButton: {
    alignItems: "center",
    backgroundColor: "rgba(168,212,230,0.16)",
    borderRadius: megrumRadii.md,
    flex: 1,
    justifyContent: "center",
    minHeight: 42,
  },
  tradeSupportWarn: {
    backgroundColor: "rgba(217,130,107,0.1)",
  },
  tradeSupportText: {
    color: "#3a7c93",
    fontSize: 12,
    fontWeight: "900",
  },
  tradeSupportWarnText: {
    color: megrumColors.warn,
  },
  rejectButton: {
    alignItems: "center",
    minHeight: 44,
    justifyContent: "center",
  },
  rejectText: {
    color: megrumColors.warn,
    fontSize: 13,
    fontWeight: "900",
  },
});
