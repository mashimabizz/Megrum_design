import { useCallback, useMemo, useState } from "react";
import { router, useFocusEffect, useLocalSearchParams } from "expo-router";
import {
  ActionSheetIOS,
  ActivityIndicator,
  Alert,
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
import { IconSymbol } from "../src/components/IconSymbol";
import { Screen } from "../src/components/Screen";
import {
  appendMeguriBoardReply,
  hideMeguriBoardThread,
  loadMeguriBoardThreadDetail,
  markMeguriBoardThreadRead,
  meguriBoardAudienceLabel,
  meguriBoardAudienceMeta,
  meguriBoardCategoryLabel,
  reportMeguriBoardReply,
  reportMeguriBoardThread,
  setMeguriBoardReplyReacted,
  setMeguriBoardThreadBookmarked,
  setMeguriBoardThreadReacted,
  type MeguriBoardActor,
  type MeguriBoardAudienceScope,
  type MeguriBoardReply,
  type MeguriBoardThread,
  type MeguriBoardThreadCategory,
  type MeguriBoardViewMode,
  type MeguriBoardViewerContext,
} from "../src/lib/meguriBoard";
import {
  coordinateFromParams,
  getCurrentLocationContext,
  type MegrumLocationContext,
} from "../src/lib/locationContext";
import {
  DEFAULT_MEGURI_PROFILE,
  loadMeguriProfileSettings,
} from "../src/lib/meguriSettings";
import {
  displayMeguriBoardPrefecture,
  normalizeMeguriBoardPrefecture,
} from "../src/lib/meguriBoardPreferences";
import { useKeyboardInset } from "../src/lib/useKeyboardInset";
import { megrumColors, megrumShadow } from "../src/theme/tokens";

export default function MeguriBoardThreadScreen() {
  const insets = useSafeAreaInsets();
  const keyboardInset = useKeyboardInset();
  const params = useLocalSearchParams<{
    id?: string | string[];
    prefecture?: string | string[];
    spotKey?: string | string[];
    spotLabel?: string | string[];
    viewerLat?: string | string[];
    viewerLng?: string | string[];
    viewMode?: string | string[];
  }>();
  const threadId = readParam(params.id);
  const { previewMode, profile, user } = useAuth();
  const [localArea, setLocalArea] = useState(DEFAULT_MEGURI_PROFILE.baseArea);
  const [localDisplayName, setLocalDisplayName] = useState(DEFAULT_MEGURI_PROFILE.displayName);
  const [thread, setThread] = useState<MeguriBoardThread | null>(null);
  const [replies, setReplies] = useState<MeguriBoardReply[]>([]);
  const [loading, setLoading] = useState(true);
  const [locationContext, setLocationContext] = useState<MegrumLocationContext | null>(null);
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);
  const [sendError, setSendError] = useState<string | null>(null);

  const actor = useMemo<MeguriBoardActor>(
    () => ({
      displayName: profile?.displayName || localDisplayName || DEFAULT_MEGURI_PROFILE.displayName,
      handle: profile?.handle ?? (previewMode ? "preview_hana" : null),
      primaryArea: profile?.primaryArea || localArea || DEFAULT_MEGURI_PROFILE.baseArea,
      userId: user?.id ?? "preview-me",
    }),
    [localArea, localDisplayName, previewMode, profile?.displayName, profile?.handle, profile?.primaryArea, user?.id],
  );

  const viewMode = normalizeViewMode(readParam(params.viewMode));
  const viewerContext = useMemo<MeguriBoardViewerContext>(
    () =>
      buildViewerContext({
        coordinate:
          locationContext?.coordinate ??
          coordinateFromParams({ latitude: params.viewerLat, longitude: params.viewerLng }),
        fallbackArea: profile?.primaryArea || localArea || DEFAULT_MEGURI_PROFILE.baseArea,
        prefecture: readParam(params.prefecture),
        resolvedPrefecture: locationContext?.prefecture ?? null,
        spotKey: readParam(params.spotKey),
        spotLabel: readParam(params.spotLabel),
        viewerId: user?.id ?? actor.userId,
      }),
    [
      actor.userId,
      localArea,
      locationContext?.coordinate,
      locationContext?.prefecture,
      params.prefecture,
      params.spotKey,
      params.spotLabel,
      params.viewerLat,
      params.viewerLng,
      profile?.primaryArea,
      user?.id,
    ],
  );

  const refreshDetail = useCallback(async () => {
    if (!threadId) {
      setThread(null);
      setReplies([]);
      setLoading(false);
      return;
    }
    setLoading(true);
    const settings = await loadMeguriProfileSettings().catch(() => DEFAULT_MEGURI_PROFILE);
    const currentLocation = await getCurrentLocationContext().catch(() => null);
    setLocationContext(currentLocation);
    setLocalArea(settings.baseArea || DEFAULT_MEGURI_PROFILE.baseArea);
    setLocalDisplayName(settings.displayName || DEFAULT_MEGURI_PROFILE.displayName);
    const nextViewerContext = buildViewerContext({
      coordinate:
        currentLocation?.coordinate ??
        coordinateFromParams({ latitude: params.viewerLat, longitude: params.viewerLng }),
      fallbackArea: profile?.primaryArea || settings.baseArea || actor.primaryArea,
      prefecture: readParam(params.prefecture),
      resolvedPrefecture: currentLocation?.prefecture ?? null,
      spotKey: readParam(params.spotKey),
      spotLabel: readParam(params.spotLabel),
      viewerId: user?.id ?? actor.userId,
    });
    const detail = await loadMeguriBoardThreadDetail(
      threadId,
      nextViewerContext,
      { previewMode, viewMode },
    ).catch(() => ({ replies: [] as MeguriBoardReply[], thread: null }));
    setThread(detail.thread ? { ...detail.thread, readAt: Date.now() } : null);
    setReplies(detail.replies);
    setLoading(false);
    if (detail.thread) {
      void markMeguriBoardThreadRead(detail.thread.id);
    }
  }, [
    actor.primaryArea,
    actor.userId,
    params.prefecture,
    params.spotKey,
    params.spotLabel,
    params.viewerLat,
    params.viewerLng,
    previewMode,
    profile?.primaryArea,
    threadId,
    user?.id,
    viewMode,
  ]);

  useFocusEffect(
    useCallback(() => {
      void refreshDetail();
    }, [refreshDetail]),
  );

  async function handleSend() {
    if (!threadId) return;
    const body = draft.trim();
    if (!body) return;
    setSending(true);
    setSendError(null);
    const reply = await appendMeguriBoardReply(
      {
        body,
        previewMode,
        threadId,
        viewer: viewerContext,
        viewMode,
      },
      actor,
    ).catch(() => null);
    setSending(false);
    if (!reply) {
      setSendError("返信を送れませんでした。");
      return;
    }
    setDraft("");
    setReplies((current) => [...current, reply].sort((left, right) => left.createdAt - right.createdAt));
    setThread((current) =>
      current
        ? {
            ...current,
            latestActivityAt: Math.max(current.latestActivityAt, reply.createdAt),
            latestReplyPreview: reply.body,
            replyCount: current.replyCount + 1,
          }
        : current,
    );
  }

  function updateThread(nextThread: MeguriBoardThread) {
    setThread(nextThread);
  }

  async function toggleThreadBookmark() {
    if (!thread) return;
    const bookmarked = !thread.bookmarked;
    updateThread({
      ...thread,
      bookmarkCount: Math.max(0, thread.bookmarkCount + (bookmarked ? 1 : -1)),
      bookmarked,
    });
    await setMeguriBoardThreadBookmarked(thread.id, bookmarked);
  }

  async function toggleThreadReaction() {
    if (!thread) return;
    const reacted = !thread.reacted;
    updateThread({
      ...thread,
      reacted,
      reactionCount: Math.max(0, thread.reactionCount + (reacted ? 1 : -1)),
    });
    await setMeguriBoardThreadReacted(thread.id, reacted);
  }

  async function hideThread() {
    if (!thread) return;
    await hideMeguriBoardThread(thread.id);
    router.back();
  }

  async function reportThread() {
    if (!thread || thread.reported) return;
    updateThread({ ...thread, reported: true });
    await reportMeguriBoardThread(thread.id);
    Alert.alert("通報しました", "確認して対応します。");
  }

  async function toggleReplyReaction(reply: MeguriBoardReply) {
    const reacted = !reply.reacted;
    setReplies((current) =>
      current.map((candidate) =>
        candidate.id === reply.id
          ? {
              ...candidate,
              reacted,
              reactionCount: Math.max(0, candidate.reactionCount + (reacted ? 1 : -1)),
            }
          : candidate,
      ),
    );
    await setMeguriBoardReplyReacted(reply.id, reacted);
  }

  async function reportReply(reply: MeguriBoardReply) {
    if (reply.reported) return;
    setReplies((current) =>
      current.map((candidate) =>
        candidate.id === reply.id ? { ...candidate, reported: true } : candidate,
      ),
    );
    await reportMeguriBoardReply(reply.id);
    Alert.alert("通報しました", "確認して対応します。");
  }

  function openThreadActions() {
    if (!thread) return;
    const labels = [
      thread.bookmarked ? "保存を解除" : "保存する",
      thread.reacted ? "参考になったを取り消す" : "参考になった",
      "非表示にする",
      thread.reported ? "通報済み" : "通報する",
      "キャンセル",
    ];
    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          cancelButtonIndex: 4,
          destructiveButtonIndex: 2,
          disabledButtonIndices: thread.reported ? [3] : undefined,
          options: labels,
          title: thread.title,
        },
        (index) => {
          if (index === 0) void toggleThreadBookmark();
          if (index === 1) void toggleThreadReaction();
          if (index === 2) void hideThread();
          if (index === 3 && !thread.reported) void reportThread();
        },
      );
      return;
    }
    void toggleThreadBookmark();
  }

  function openReplyActions(reply: MeguriBoardReply) {
    const labels = [
      reply.reacted ? "参考になったを取り消す" : "参考になった",
      reply.reported ? "通報済み" : "通報する",
      "キャンセル",
    ];
    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          cancelButtonIndex: 2,
          disabledButtonIndices: reply.reported ? [1] : undefined,
          options: labels,
        },
        (index) => {
          if (index === 0) void toggleReplyReaction(reply);
          if (index === 1 && !reply.reported) void reportReply(reply);
        },
      );
    }
  }

  return (
    <View style={styles.root}>
      <Screen bottomInset={false} contentStyle={styles.screen} scroll={false} topInset={false}>
        <View style={[styles.header, { paddingTop: Math.max(insets.top, 10) + 8 }]}>
          <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.backButton}>
            <IconSymbol name="chevron-back" color={megrumColors.ink} size={20} />
          </Pressable>
          <View style={styles.headerCopy}>
            <Text numberOfLines={1} style={styles.headerTitle}>
              {thread?.title || "スレッド"}
            </Text>
            <Text numberOfLines={1} style={styles.headerSubtitle}>
              {thread ? meguriBoardAudienceMeta(thread) : viewerContext.spotLabel}
            </Text>
          </View>
          {thread ? (
            <Pressable accessibilityRole="button" onPress={openThreadActions} style={styles.headerActionButton}>
              <IconSymbol name="ellipsis-horizontal" color={megrumColors.ink} size={20} />
            </Pressable>
          ) : null}
        </View>

        {loading ? (
          <View style={styles.loadingBox}>
            <ActivityIndicator color={megrumColors.lavender} />
            <Text style={styles.loadingText}>スレッドを読み込み中…</Text>
          </View>
        ) : !thread ? (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyTitle}>スレッドを開けませんでした</Text>
            <Text style={styles.emptyBody}>一覧から入り直すと表示できることがあります。</Text>
          </View>
        ) : (
          <>
            <ScrollView
              contentContainerStyle={[
                styles.content,
                {
                  paddingBottom: Math.max(insets.bottom, 12) + 112,
                },
              ]}
              showsVerticalScrollIndicator={false}
              style={styles.scroll}
            >
              <View style={styles.heroCard}>
                <View style={styles.heroTopRow}>
                  <View style={styles.heroBadgeRow}>
                    <CategoryBadge category={thread.category} />
                    <ScopeBadge scope={thread.audienceScope} />
                  </View>
                  <Text style={styles.heroTime}>{formatRelativeTime(thread.createdAt)}</Text>
                </View>
                <Text style={styles.heroTitle}>{thread.title}</Text>
                <Text style={styles.heroBody}>{thread.body}</Text>
                <Text style={styles.heroMeta}>
                  {meguriBoardAudienceMeta(thread)} · {thread.authorName}
                </Text>
                <View style={styles.threadActions}>
                  <Pressable
                    accessibilityRole="button"
                    onPress={toggleThreadReaction}
                    style={[styles.threadActionPill, thread.reacted ? styles.threadActionPillActive : null]}
                  >
                    <IconSymbol
                      name={thread.reacted ? "heart" : "heart-outline"}
                      color={thread.reacted ? megrumColors.lavender : megrumColors.mutedInk}
                      size={16}
                    />
                    <Text style={[styles.threadActionText, thread.reacted ? styles.threadActionTextActive : null]}>
                      参考 {thread.reactionCount}
                    </Text>
                  </Pressable>
                  <Pressable
                    accessibilityRole="button"
                    onPress={toggleThreadBookmark}
                    style={[styles.threadActionPill, thread.bookmarked ? styles.threadActionPillActive : null]}
                  >
                    <IconSymbol
                      name="star-outline"
                      color={thread.bookmarked ? megrumColors.lavender : megrumColors.mutedInk}
                      size={15}
                    />
                    <Text style={[styles.threadActionText, thread.bookmarked ? styles.threadActionTextActive : null]}>
                      保存
                    </Text>
                  </Pressable>
                </View>
              </View>

              <Text style={styles.replySectionTitle}>返信</Text>
              {replies.length === 0 ? (
                <View style={styles.noRepliesCard}>
                  <Text style={styles.noRepliesTitle}>まだ返信はありません</Text>
                  <Text style={styles.noRepliesBody}>最初のひとことで温度感をつなげていくイメージです。</Text>
                </View>
              ) : (
                replies.map((reply) => (
                  <View
                    key={reply.id}
                    style={[styles.replyRow, reply.mine ? styles.replyRowMine : null]}
                  >
                    {!reply.mine ? (
                      <View style={[styles.replyAvatar, { backgroundColor: colorForAuthor(reply.authorId) }]}>
                        <Text style={styles.replyAvatarText}>{reply.authorName.slice(0, 1)}</Text>
                      </View>
                    ) : null}
                    <View style={reply.mine ? styles.replyContentMine : styles.replyContent}>
                      {!reply.mine ? (
                        <Text style={styles.replyAuthor}>{reply.authorName}</Text>
                      ) : null}
                      <ChatGradientBubble
                        mine={reply.mine}
                        style={[
                          styles.replyBubble,
                          reply.mine ? styles.replyBubbleMine : styles.replyBubbleTheirs,
                        ]}
                      >
                        <Text
                          style={[
                            styles.replyBody,
                            reply.mine ? styles.replyBodyMine : null,
                          ]}
                        >
                          {reply.body}
                        </Text>
                      </ChatGradientBubble>
                      <Text style={[styles.replyTime, reply.mine ? styles.replyTimeMine : null]}>
                        {formatRelativeTime(reply.createdAt)}
                      </Text>
                      <View style={[styles.replyActionRow, reply.mine ? styles.replyActionRowMine : null]}>
                        <Pressable
                          accessibilityRole="button"
                          onPress={() => toggleReplyReaction(reply)}
                          style={[styles.replyActionPill, reply.reacted ? styles.replyActionPillActive : null]}
                        >
                          <IconSymbol
                            name={reply.reacted ? "heart" : "heart-outline"}
                            color={reply.reacted ? megrumColors.lavender : megrumColors.mutedInk}
                            size={13}
                          />
                          <Text style={[styles.replyActionText, reply.reacted ? styles.replyActionTextActive : null]}>
                            {reply.reactionCount}
                          </Text>
                        </Pressable>
                        <Pressable
                          accessibilityRole="button"
                          onPress={() => openReplyActions(reply)}
                          style={styles.replyActionPill}
                        >
                          <IconSymbol name="ellipsis-horizontal" color={megrumColors.mutedInk} size={13} />
                        </Pressable>
                      </View>
                    </View>
                  </View>
                ))
              )}
            </ScrollView>

            <View
              style={[
                styles.composer,
                {
                  marginBottom: keyboardInset,
                  paddingBottom: keyboardInset > 0 ? 8 : Math.max(insets.bottom, 12) + 10,
                },
              ]}
            >
              <TextInput
                multiline
                onChangeText={setDraft}
                placeholder="返信を書く"
                placeholderTextColor="rgba(58,50,74,0.34)"
                style={styles.composerInput}
                textAlignVertical="top"
                value={draft}
              />
              <Pressable
                accessibilityRole="button"
                disabled={sending || !draft.trim()}
                onPress={handleSend}
                style={[
                  styles.sendButton,
                  draft.trim() ? styles.sendButtonActive : null,
                  sending ? styles.sendButtonDisabled : null,
                ]}
              >
                <IconSymbol
                  name={sending ? "ellipsis-horizontal" : "send-outline"}
                  color={draft.trim() ? "#fff" : "rgba(58,50,74,0.42)"}
                  size={18}
                />
              </Pressable>
            </View>
            {sendError ? <Text style={styles.sendError}>{sendError}</Text> : null}
          </>
        )}
      </Screen>
    </View>
  );
}

function ScopeBadge({ scope }: { scope: MeguriBoardAudienceScope }) {
  return (
    <View
      style={[
        styles.scopeBadge,
        scope === "nearby_3km" || scope === "same_spot"
          ? styles.scopeBadgeSpot
          : scope === "same_prefecture"
            ? styles.scopeBadgePrefecture
            : styles.scopeBadgeGlobal,
      ]}
    >
      <Text
        style={[
          styles.scopeBadgeText,
          scope === "nearby_3km" || scope === "same_spot"
            ? styles.scopeBadgeTextSpot
            : scope === "same_prefecture"
              ? styles.scopeBadgeTextPrefecture
              : styles.scopeBadgeTextGlobal,
        ]}
      >
        {meguriBoardAudienceLabel(scope)}
      </Text>
    </View>
  );
}

function CategoryBadge({ category }: { category: Exclude<MeguriBoardThreadCategory, "all"> }) {
  return (
    <View style={[styles.categoryBadge, categoryStyle(category)]}>
      <Text style={[styles.categoryBadgeText, categoryTextStyle(category)]}>
        {meguriBoardCategoryLabel(category)}
      </Text>
    </View>
  );
}

function categoryStyle(category: Exclude<MeguriBoardThreadCategory, "all">) {
  switch (category) {
    case "question":
      return styles.categoryBadgeQuestion;
    case "info":
      return styles.categoryBadgeInfo;
    case "trade":
      return styles.categoryBadgeTrade;
    case "lost_found":
      return styles.categoryBadgeLost;
    case "chat":
    default:
      return styles.categoryBadgeChat;
  }
}

function categoryTextStyle(category: Exclude<MeguriBoardThreadCategory, "all">) {
  switch (category) {
    case "question":
      return styles.categoryBadgeTextQuestion;
    case "info":
      return styles.categoryBadgeTextInfo;
    case "trade":
      return styles.categoryBadgeTextTrade;
    case "lost_found":
      return styles.categoryBadgeTextLost;
    case "chat":
    default:
      return styles.categoryBadgeTextChat;
  }
}

function readParam(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value;
}

function buildViewerContext(input: {
  coordinate?: MeguriBoardViewerContext["coordinate"];
  fallbackArea: string | null;
  prefecture?: string | null;
  resolvedPrefecture?: string | null;
  spotKey?: string | null;
  spotLabel?: string | null;
  viewerId?: string | null;
}): MeguriBoardViewerContext {
  const prefecture =
    normalizeMeguriBoardPrefecture(input.prefecture) ||
    normalizeMeguriBoardPrefecture(input.resolvedPrefecture) ||
    normalizeMeguriBoardPrefecture(input.fallbackArea) ||
    normalizeMeguriBoardPrefecture(DEFAULT_MEGURI_PROFILE.baseArea) ||
    "東京";
  const spotLabel = input.spotLabel || `${displayMeguriBoardPrefecture(prefecture)}のめぐりスポット`;
  const spotKey = input.spotKey || `${slugify(prefecture)}-meguri-board`;
  return {
    coordinate: input.coordinate ?? null,
    prefecture,
    spotKey,
    spotLabel,
    viewerId: input.viewerId,
  };
}

function normalizeViewMode(value: string | null | undefined): MeguriBoardViewMode {
  return value === "same_prefecture" ? "same_prefecture" : "nearby_3km";
}

function slugify(value: string) {
  return value.toLowerCase().replace(/\s+/g, "-");
}

function formatRelativeTime(value: number) {
  const diff = Math.max(0, Date.now() - value);
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return "たった今";
  if (minutes < 60) return `${minutes}分前`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}時間前`;
  const days = Math.floor(hours / 24);
  return `${days}日前`;
}

function colorForAuthor(authorId: string) {
  const palette = [
    "rgba(166,149,216,0.86)",
    "rgba(168,212,230,0.92)",
    "rgba(243,197,212,0.9)",
    "rgba(239,217,155,0.92)",
  ];
  let sum = 0;
  for (let index = 0; index < authorId.length; index += 1) {
    sum += authorId.charCodeAt(index);
  }
  return palette[sum % palette.length] || palette[0];
}

const styles = StyleSheet.create({
  root: {
    backgroundColor: megrumColors.background,
    flex: 1,
  },
  screen: {
    backgroundColor: megrumColors.background,
    flex: 1,
    paddingHorizontal: 0,
  },
  header: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 12,
    paddingBottom: 12,
    paddingHorizontal: 14,
  },
  backButton: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    height: 40,
    justifyContent: "center",
    width: 40,
  },
  headerActionButton: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    height: 40,
    justifyContent: "center",
    width: 40,
  },
  headerCopy: {
    flex: 1,
    gap: 2,
  },
  headerTitle: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  headerSubtitle: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "700",
  },
  loadingBox: {
    alignItems: "center",
    flex: 1,
    gap: 10,
    justifyContent: "center",
  },
  loadingText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "700",
  },
  emptyCard: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 22,
    borderWidth: 1,
    gap: 8,
    marginHorizontal: 18,
    marginTop: 20,
    paddingHorizontal: 18,
    paddingVertical: 26,
  },
  emptyTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  emptyBody: {
    color: megrumColors.mutedInk,
    fontSize: 12.5,
    fontWeight: "700",
    textAlign: "center",
  },
  scroll: {
    flex: 1,
  },
  content: {
    gap: 14,
    paddingHorizontal: 18,
    paddingTop: 16,
  },
  heroCard: {
    backgroundColor: "#fff",
    borderRadius: 22,
    gap: 8,
    paddingHorizontal: 16,
    paddingVertical: 16,
    ...megrumShadow,
  },
  heroTopRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  heroBadgeRow: {
    alignItems: "center",
    flexDirection: "row",
    flex: 1,
    gap: 6,
  },
  categoryBadge: {
    borderRadius: 999,
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  categoryBadgeQuestion: {
    backgroundColor: "rgba(166,149,216,0.16)",
  },
  categoryBadgeInfo: {
    backgroundColor: "rgba(168,212,230,0.26)",
  },
  categoryBadgeChat: {
    backgroundColor: "rgba(58,50,74,0.08)",
  },
  categoryBadgeTrade: {
    backgroundColor: "rgba(243,197,212,0.3)",
  },
  categoryBadgeLost: {
    backgroundColor: "rgba(239,217,155,0.32)",
  },
  categoryBadgeText: {
    fontSize: 10.5,
    fontWeight: "900",
  },
  categoryBadgeTextQuestion: {
    color: megrumColors.lavender,
  },
  categoryBadgeTextInfo: {
    color: "#4f7e92",
  },
  categoryBadgeTextChat: {
    color: megrumColors.mutedInk,
  },
  categoryBadgeTextTrade: {
    color: "#ba6d8d",
  },
  categoryBadgeTextLost: {
    color: "#9a722c",
  },
  scopeBadge: {
    borderRadius: 999,
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  scopeBadgeSpot: {
    backgroundColor: "rgba(166,149,216,0.14)",
  },
  scopeBadgePrefecture: {
    backgroundColor: "rgba(168,212,230,0.26)",
  },
  scopeBadgeGlobal: {
    backgroundColor: "rgba(243,197,212,0.26)",
  },
  scopeBadgeText: {
    fontSize: 10.5,
    fontWeight: "900",
  },
  scopeBadgeTextSpot: {
    color: megrumColors.lavender,
  },
  scopeBadgeTextPrefecture: {
    color: "#4f7e92",
  },
  scopeBadgeTextGlobal: {
    color: "#ba6d8d",
  },
  heroTime: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "700",
  },
  heroTitle: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
    lineHeight: 24,
  },
  heroBody: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "700",
    lineHeight: 20,
  },
  heroMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  threadActions: {
    flexDirection: "row",
    gap: 8,
    marginTop: 4,
  },
  threadActionPill: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    flexDirection: "row",
    gap: 5,
    minHeight: 32,
    paddingHorizontal: 11,
  },
  threadActionPillActive: {
    backgroundColor: "rgba(166,149,216,0.16)",
  },
  threadActionText: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "900",
  },
  threadActionTextActive: {
    color: megrumColors.lavender,
  },
  replySectionTitle: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
    marginTop: 6,
  },
  noRepliesCard: {
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1,
    gap: 6,
    paddingHorizontal: 14,
    paddingVertical: 14,
  },
  noRepliesTitle: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "900",
  },
  noRepliesBody: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 18,
  },
  replyRow: {
    alignItems: "flex-end",
    flexDirection: "row",
    gap: 10,
  },
  replyRowMine: {
    justifyContent: "flex-end",
  },
  replyAvatar: {
    alignItems: "center",
    borderRadius: 18,
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  replyAvatarText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "900",
  },
  replyContent: {
    flex: 1,
    gap: 5,
    maxWidth: "84%",
  },
  replyContentMine: {
    alignItems: "flex-end",
    gap: 5,
    maxWidth: "84%",
  },
  replyAuthor: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    paddingHorizontal: 4,
  },
  replyBubble: {
    borderRadius: 18,
    maxWidth: "100%",
    overflow: "hidden",
    paddingHorizontal: 14,
    paddingVertical: 11,
  },
  replyBubbleMine: {
    borderBottomRightRadius: 8,
  },
  replyBubbleTheirs: {
    borderBottomLeftRadius: 8,
  },
  replyBody: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "700",
    lineHeight: 20,
  },
  replyBodyMine: {
    color: "#fff",
  },
  replyTime: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "700",
    paddingHorizontal: 4,
  },
  replyTimeMine: {
    textAlign: "right",
  },
  replyActionRow: {
    flexDirection: "row",
    gap: 6,
    paddingHorizontal: 4,
  },
  replyActionRowMine: {
    justifyContent: "flex-end",
  },
  replyActionPill: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    flexDirection: "row",
    gap: 3,
    minHeight: 24,
    paddingHorizontal: 8,
  },
  replyActionPillActive: {
    backgroundColor: "rgba(166,149,216,0.16)",
  },
  replyActionText: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
  replyActionTextActive: {
    color: megrumColors.lavender,
  },
  composer: {
    alignItems: "flex-end",
    backgroundColor: "rgba(251,249,252,0.98)",
    borderTopColor: "rgba(58,50,74,0.08)",
    borderTopWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 14,
    paddingTop: 12,
  },
  composerInput: {
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1,
    color: megrumColors.ink,
    flex: 1,
    fontSize: 14,
    fontWeight: "700",
    maxHeight: 118,
    minHeight: 48,
    paddingHorizontal: 14,
    paddingTop: 13,
  },
  sendButton: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.12)",
    borderRadius: 999,
    height: 44,
    justifyContent: "center",
    width: 44,
  },
  sendButtonActive: {
    backgroundColor: megrumColors.lavender,
  },
  sendButtonDisabled: {
    opacity: 0.8,
  },
  sendError: {
    color: megrumColors.warn,
    fontSize: 11.5,
    fontWeight: "800",
    paddingHorizontal: 18,
    paddingTop: 6,
    paddingBottom: 4,
  },
});
