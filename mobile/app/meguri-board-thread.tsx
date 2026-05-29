import { useCallback, useMemo, useState } from "react";
import { router, useFocusEffect, useLocalSearchParams } from "expo-router";
import {
  ActivityIndicator,
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
  loadMeguriBoardThreadDetail,
  meguriBoardAudienceLabel,
  meguriBoardAudienceMeta,
  type MeguriBoardActor,
  type MeguriBoardAudienceScope,
  type MeguriBoardReply,
  type MeguriBoardThread,
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
    setThread(detail.thread);
    setReplies(detail.replies);
    setLoading(false);
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
                  <ScopeBadge scope={thread.audienceScope} />
                  <Text style={styles.heroTime}>{formatRelativeTime(thread.createdAt)}</Text>
                </View>
                <Text style={styles.heroTitle}>{thread.title}</Text>
                <Text style={styles.heroBody}>{thread.body}</Text>
                <Text style={styles.heroMeta}>
                  {meguriBoardAudienceMeta(thread)} · {thread.authorName}
                </Text>
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
    input.resolvedPrefecture || input.prefecture || input.fallbackArea || DEFAULT_MEGURI_PROFILE.baseArea;
  const spotLabel = input.spotLabel || `${prefecture}のめぐりスポット`;
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
