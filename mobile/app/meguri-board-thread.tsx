import { useCallback, useMemo, useState } from "react";
import Constants from "expo-constants";
import { router, useFocusEffect, useLocalSearchParams } from "expo-router";
import * as ImagePicker from "expo-image-picker";
import {
  ActionSheetIOS,
  ActivityIndicator,
  Alert,
  Image,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  Share,
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
  blockMeguriBoardUser,
  deleteMeguriBoardReply,
  hideMeguriBoardThread,
  loadMeguriBoardThreadDetail,
  markMeguriBoardThreadRead,
  meguriBoardAudienceLabel,
  meguriBoardAudienceMeta,
  MEGURI_BOARD_COMPOSER_CATEGORY_OPTIONS,
  meguriBoardCategoryLabel,
  reportMeguriBoardReply,
  reportMeguriBoardThread,
  setMeguriBoardThreadStatus,
  setMeguriBoardReplyReacted,
  setMeguriBoardThreadBookmarked,
  setMeguriBoardThreadReacted,
  setMeguriBoardThreadSubscribed,
  updateMeguriBoardReply,
  updateMeguriBoardThread,
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
  const [draftImageUris, setDraftImageUris] = useState<string[]>([]);
  const [sending, setSending] = useState(false);
  const [sendError, setSendError] = useState<string | null>(null);
  const [replySearchText, setReplySearchText] = useState("");
  const [quoteTarget, setQuoteTarget] = useState<MeguriBoardReply | null>(null);
  const [threadEditorOpen, setThreadEditorOpen] = useState(false);
  const [threadEditTitle, setThreadEditTitle] = useState("");
  const [threadEditBody, setThreadEditBody] = useState("");
  const [threadEditCategory, setThreadEditCategory] =
    useState<Exclude<MeguriBoardThreadCategory, "all">>("chat");
  const [replyEditor, setReplyEditor] = useState<MeguriBoardReply | null>(null);
  const [replyEditBody, setReplyEditBody] = useState("");

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

  const filteredReplies = useMemo(() => {
    const query = normalizeReplySearch(replySearchText);
    if (!query) return replies;
    return replies.filter((reply) =>
      normalizeReplySearch(
        [
          reply.authorName,
          reply.body,
          reply.quotedAuthorName,
          reply.quotedBody,
        ]
          .filter(Boolean)
          .join(" "),
      ).includes(query),
    );
  }, [replies, replySearchText]);

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
    if (thread?.status === "locked") {
      setSendError("このスレッドは締め切られています。");
      return;
    }
    const body = draft.trim() || (draftImageUris.length > 0 ? "画像を共有しました" : "");
    if (!body) return;
    setSending(true);
    setSendError(null);
    const reply = await appendMeguriBoardReply(
      {
        body,
        imageUris: draftImageUris,
        parentReplyId: quoteTarget?.id ?? null,
        previewMode,
        quotedAuthorName: quoteTarget?.authorName ?? null,
        quotedBody: quoteTarget?.body ?? null,
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
    setDraftImageUris([]);
    setQuoteTarget(null);
    setReplies((current) => [...current, reply].sort((left, right) => left.createdAt - right.createdAt));
    setThread((current) =>
      current
        ? {
            ...current,
            latestActivityAt: Math.max(current.latestActivityAt, reply.createdAt),
            latestReplyPreview: reply.body,
            replyCount: current.replyCount + 1,
            subscribed: true,
          }
        : current,
    );
  }

  async function pickDraftImages() {
    const remaining = Math.max(0, 4 - draftImageUris.length);
    if (remaining === 0 || thread?.status === "locked") return;
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      Alert.alert("写真へのアクセスを許可してください", "返信に画像を添付するには写真ライブラリの許可が必要です。");
      return;
    }
    const result = await ImagePicker.launchImageLibraryAsync({
      allowsEditing: false,
      allowsMultipleSelection: true,
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      quality: 0.82,
      selectionLimit: remaining,
    });
    if (result.canceled) return;
    const nextUris = result.assets
      .map((asset) => asset.uri)
      .filter((uri): uri is string => !!uri)
      .slice(0, remaining);
    setDraftImageUris((current) => [...current, ...nextUris].slice(0, 4));
  }

  function removeDraftImage(uri: string) {
    setDraftImageUris((current) => current.filter((candidate) => candidate !== uri));
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

  async function toggleThreadSubscription() {
    if (!thread) return;
    const subscribed = !thread.subscribed;
    updateThread({ ...thread, subscribed });
    await setMeguriBoardThreadSubscribed(thread.id, subscribed);
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

  async function blockThreadAuthor() {
    if (!thread || thread.mine) return;
    const authorName = thread.authorName;
    await blockMeguriBoardUser(actor.userId, thread.authorId).catch(() => undefined);
    Alert.alert("ブロックしました", `${authorName}さんのスレッドと返信を表示しません。`, [
      { onPress: () => router.back(), text: "OK" },
    ]);
  }

  function confirmBlockThreadAuthor() {
    if (!thread || thread.mine) return;
    Alert.alert(`${thread.authorName}さんをブロックしますか？`, "このユーザーのスレッドと返信を表示しなくなります。", [
      { style: "cancel", text: "キャンセル" },
      { onPress: () => void blockThreadAuthor(), style: "destructive", text: "ブロック" },
    ]);
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

  async function blockReplyAuthor(reply: MeguriBoardReply) {
    if (reply.mine || reply.deleted) return;
    setReplies((current) => current.filter((candidate) => candidate.authorId !== reply.authorId));
    if (quoteTarget?.authorId === reply.authorId) {
      setQuoteTarget(null);
    }
    await blockMeguriBoardUser(actor.userId, reply.authorId).catch(() => undefined);
    Alert.alert("ブロックしました", `${reply.authorName}さんのスレッドと返信を表示しません。`);
  }

  function confirmBlockReplyAuthor(reply: MeguriBoardReply) {
    if (reply.mine || reply.deleted) return;
    Alert.alert(`${reply.authorName}さんをブロックしますか？`, "このユーザーのスレッドと返信を表示しなくなります。", [
      { style: "cancel", text: "キャンセル" },
      { onPress: () => void blockReplyAuthor(reply), style: "destructive", text: "ブロック" },
    ]);
  }

  function openThreadEditor() {
    if (!thread || !thread.mine) return;
    setThreadEditTitle(thread.title);
    setThreadEditBody(thread.body);
    setThreadEditCategory(thread.category);
    setThreadEditorOpen(true);
  }

  async function saveThreadEditor() {
    if (!thread) return;
    const title = threadEditTitle.trim();
    const body = threadEditBody.trim();
    if (!title || !body) return;
    const updatedAt = Date.now();
    const nextThread = {
      ...thread,
      body,
      category: threadEditCategory,
      latestActivityAt: Math.max(thread.latestActivityAt, updatedAt),
      title,
      updatedAt,
    };
    setThread(nextThread);
    setThreadEditorOpen(false);
    await updateMeguriBoardThread({
      body,
      category: threadEditCategory,
      threadId: thread.id,
      title,
    });
  }

  async function toggleThreadLocked() {
    if (!thread || !thread.mine) return;
    const nextStatus = thread.status === "locked" ? "visible" : "locked";
    const updatedAt = Date.now();
    updateThread({
      ...thread,
      latestActivityAt: Math.max(thread.latestActivityAt, updatedAt),
      status: nextStatus,
      updatedAt,
    });
    await setMeguriBoardThreadStatus(thread.id, nextStatus);
  }

  async function archiveThread() {
    if (!thread || !thread.mine) return;
    await setMeguriBoardThreadStatus(thread.id, "archived");
    router.back();
  }

  function confirmArchiveThread() {
    Alert.alert("スレッドを削除しますか？", "一覧と詳細から見えなくなります。", [
      { style: "cancel", text: "キャンセル" },
      { onPress: () => void archiveThread(), style: "destructive", text: "削除する" },
    ]);
  }

  function openReplyEditor(reply: MeguriBoardReply) {
    if (!reply.mine || reply.deleted) return;
    setReplyEditor(reply);
    setReplyEditBody(reply.body);
  }

  async function saveReplyEditor() {
    if (!replyEditor) return;
    const body = replyEditBody.trim();
    if (!body) return;
    const updatedAt = Date.now();
    setReplies((current) =>
      current.map((candidate) =>
        candidate.id === replyEditor.id
          ? { ...candidate, body, deleted: false, status: "visible", updatedAt }
          : candidate,
      ),
    );
    setReplyEditor(null);
    await updateMeguriBoardReply(replyEditor.id, body);
  }

  async function deleteReply(reply: MeguriBoardReply) {
    if (!reply.mine || reply.deleted) return;
    const updatedAt = Date.now();
    setReplies((current) =>
      current.map((candidate) =>
        candidate.id === reply.id
          ? {
              ...candidate,
              body: "この返信は削除されました",
              deleted: true,
              reacted: false,
              reactionCount: 0,
              status: "deleted",
              updatedAt,
            }
          : candidate,
      ),
    );
    await deleteMeguriBoardReply(reply.id);
  }

  function confirmDeleteReply(reply: MeguriBoardReply) {
    Alert.alert("返信を削除しますか？", "削除済みの表示に変わります。", [
      { style: "cancel", text: "キャンセル" },
      { onPress: () => void deleteReply(reply), style: "destructive", text: "削除する" },
    ]);
  }

  function quoteReply(reply: MeguriBoardReply) {
    if (reply.deleted || thread?.status === "locked") return;
    setQuoteTarget(reply);
    setSendError(null);
  }

  async function shareThread() {
    if (!thread) return;
    const url = buildThreadShareUrl(thread, viewerContext, viewMode);
    await Share.share({
      message: `${thread.title}\n${thread.body}\n${url}`,
      title: thread.title,
      url,
    });
  }

  function openThreadActions() {
    if (!thread) return;
    const actions: Array<{ disabled?: boolean; destructive?: boolean; label: string; run?: () => void }> = [];
    if (thread.mine) {
      actions.push(
        { label: "編集する", run: openThreadEditor },
        {
          label: thread.status === "locked" ? "再開する" : "締め切る",
          run: () => void toggleThreadLocked(),
        },
        { destructive: true, label: "削除する", run: confirmArchiveThread },
      );
    }
    actions.push(
      { label: "共有する", run: () => void shareThread() },
      { label: thread.bookmarked ? "保存を解除" : "保存する", run: () => void toggleThreadBookmark() },
      { label: thread.reacted ? "参考になったを取り消す" : "参考になった", run: () => void toggleThreadReaction() },
      {
        label: thread.subscribed ? "通知を止める" : "通知を受け取る",
        run: () => void toggleThreadSubscription(),
      },
      { destructive: true, label: "非表示にする", run: () => void hideThread() },
    );
    if (!thread.mine) {
      actions.push({
        destructive: true,
        label: "このユーザーをブロック",
        run: confirmBlockThreadAuthor,
      });
    }
    actions.push({
      disabled: thread.reported,
      label: thread.reported ? "通報済み" : "通報する",
      run: thread.reported ? undefined : () => void reportThread(),
    });
    const labels = [...actions.map((action) => action.label), "キャンセル"];
    const cancelButtonIndex = labels.length - 1;
    const destructiveButtonIndices = actions
      .map((action, index) => (action.destructive ? index : -1))
      .filter((index) => index >= 0);
    const disabledButtonIndices = actions
      .map((action, index) => (action.disabled ? index : -1))
      .filter((index) => index >= 0);
    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          cancelButtonIndex,
          destructiveButtonIndex: destructiveButtonIndices[0],
          disabledButtonIndices: disabledButtonIndices.length ? disabledButtonIndices : undefined,
          options: labels,
          title: thread.title,
        },
        (index) => {
          actions[index]?.run?.();
        },
      );
      return;
    }
    actions[0]?.run?.();
  }

  function openReplyActions(reply: MeguriBoardReply) {
    const actions: Array<{ disabled?: boolean; destructive?: boolean; label: string; run?: () => void }> = [];
    actions.push({
      disabled: reply.deleted || thread?.status === "locked",
      label: "引用して返信",
      run: () => quoteReply(reply),
    });
    if (reply.mine) {
      actions.push(
        { disabled: reply.deleted, label: "編集する", run: () => openReplyEditor(reply) },
        { destructive: true, disabled: reply.deleted, label: "削除する", run: () => confirmDeleteReply(reply) },
      );
    } else {
      actions.push(
        {
          disabled: reply.deleted,
          label: reply.reacted ? "参考になったを取り消す" : "参考になった",
          run: () => void toggleReplyReaction(reply),
        },
        {
          disabled: reply.reported || reply.deleted,
          label: reply.reported ? "通報済み" : "通報する",
          run: reply.reported ? undefined : () => void reportReply(reply),
        },
        {
          destructive: true,
          disabled: reply.deleted,
          label: "このユーザーをブロック",
          run: () => confirmBlockReplyAuthor(reply),
        },
      );
    }
    const labels = [...actions.map((action) => action.label), "キャンセル"];
    const cancelButtonIndex = labels.length - 1;
    const destructiveButtonIndices = actions
      .map((action, index) => (action.destructive ? index : -1))
      .filter((index) => index >= 0);
    const disabledButtonIndices = actions
      .map((action, index) => (action.disabled ? index : -1))
      .filter((index) => index >= 0);
    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          cancelButtonIndex,
          destructiveButtonIndex: destructiveButtonIndices[0],
          disabledButtonIndices: disabledButtonIndices.length ? disabledButtonIndices : undefined,
          options: labels,
        },
        (index) => {
          actions[index]?.run?.();
        },
      );
      return;
    }
    actions[0]?.run?.();
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
                    {thread.status === "locked" ? <StatusBadge label="締め切り" /> : null}
                  </View>
                  <Text style={styles.heroTime}>{formatRelativeTime(thread.createdAt)}</Text>
                </View>
                <Text style={styles.heroTitle}>{thread.title}</Text>
                <Text style={styles.heroBody}>{thread.body}</Text>
                <AttachmentGrid imageUris={thread.imageUris} />
                <Text style={styles.heroMeta}>
                  {meguriBoardAudienceMeta(thread)} · {thread.authorName}
                  {thread.updatedAt && thread.updatedAt > thread.createdAt + 60000 ? " · 編集済み" : ""}
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
                  <Pressable
                    accessibilityRole="button"
                    onPress={toggleThreadSubscription}
                    style={[styles.threadActionPill, thread.subscribed ? styles.threadActionPillActive : null]}
                  >
                    <IconSymbol
                      name="notifications-outline"
                      color={thread.subscribed ? megrumColors.lavender : megrumColors.mutedInk}
                      size={15}
                    />
                    <Text style={[styles.threadActionText, thread.subscribed ? styles.threadActionTextActive : null]}>
                      {thread.subscribed ? "通知ON" : "通知"}
                    </Text>
                  </Pressable>
                </View>
              </View>

              <View style={styles.replyHeaderRow}>
                <Text style={styles.replySectionTitle}>返信</Text>
                <Text style={styles.replyCountMeta}>{replies.length}件</Text>
              </View>
              <View style={styles.replySearchBox}>
                <IconSymbol name="search" color="rgba(58,50,74,0.42)" size={15} />
                <TextInput
                  onChangeText={setReplySearchText}
                  placeholder="スレッド内を検索"
                  placeholderTextColor="rgba(58,50,74,0.34)"
                  style={styles.replySearchInput}
                  value={replySearchText}
                />
                {replySearchText.trim() ? (
                  <Pressable accessibilityRole="button" hitSlop={8} onPress={() => setReplySearchText("")}>
                    <IconSymbol name="close" color="rgba(58,50,74,0.42)" size={15} />
                  </Pressable>
                ) : null}
              </View>
              {replies.length === 0 ? (
                <View style={styles.noRepliesCard}>
                  <Text style={styles.noRepliesTitle}>まだ返信はありません</Text>
                  <Text style={styles.noRepliesBody}>最初のひとことで温度感をつなげていくイメージです。</Text>
                </View>
              ) : filteredReplies.length === 0 ? (
                <View style={styles.noRepliesCard}>
                  <Text style={styles.noRepliesTitle}>検索結果がありません</Text>
                  <Text style={styles.noRepliesBody}>別の言葉で探してみてください。</Text>
                </View>
              ) : (
                filteredReplies.map((reply) => (
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
                        {reply.quotedBody ? (
                          <View style={[styles.quotePreview, reply.mine ? styles.quotePreviewMine : null]}>
                            <Text
                              numberOfLines={1}
                              style={[styles.quoteAuthor, reply.mine ? styles.quoteAuthorMine : null]}
                            >
                              {reply.quotedAuthorName || "引用"}
                            </Text>
                            <Text
                              numberOfLines={2}
                              style={[styles.quoteBody, reply.mine ? styles.quoteBodyMine : null]}
                            >
                              {reply.quotedBody}
                            </Text>
                          </View>
                        ) : null}
                        <Text
                          style={[
                            styles.replyBody,
                            reply.mine ? styles.replyBodyMine : null,
                            reply.deleted ? styles.replyBodyDeleted : null,
                          ]}
                        >
                          {reply.body}
                        </Text>
                        {!reply.deleted ? <AttachmentGrid imageUris={reply.imageUris} compact /> : null}
                      </ChatGradientBubble>
                      <Text style={[styles.replyTime, reply.mine ? styles.replyTimeMine : null]}>
                        {formatRelativeTime(reply.createdAt)}
                        {reply.updatedAt && reply.updatedAt > reply.createdAt + 60000 ? " · 編集済み" : ""}
                      </Text>
                      <View style={[styles.replyActionRow, reply.mine ? styles.replyActionRowMine : null]}>
                        <Pressable
                          accessibilityRole="button"
                          disabled={reply.deleted}
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

            {thread.status === "locked" ? (
              <View
                style={[
                  styles.lockedComposer,
                  {
                    marginBottom: keyboardInset,
                    paddingBottom: keyboardInset > 0 ? 8 : Math.max(insets.bottom, 12) + 10,
                  },
                ]}
              >
                <Text style={styles.lockedComposerText}>このスレッドは締め切られています</Text>
              </View>
            ) : (
              <View
                style={[
                  styles.composer,
                  {
                    marginBottom: keyboardInset,
                    paddingBottom: keyboardInset > 0 ? 8 : Math.max(insets.bottom, 12) + 10,
                  },
                ]}
              >
                {quoteTarget ? (
                  <View style={styles.composerQuote}>
                    <View style={styles.composerQuoteCopy}>
                      <Text numberOfLines={1} style={styles.composerQuoteAuthor}>
                        {quoteTarget.authorName}へ返信
                      </Text>
                      <Text numberOfLines={1} style={styles.composerQuoteBody}>
                        {quoteTarget.body}
                      </Text>
                    </View>
                    <Pressable accessibilityRole="button" hitSlop={8} onPress={() => setQuoteTarget(null)}>
                      <IconSymbol name="close" color="rgba(58,50,74,0.52)" size={15} />
                    </Pressable>
                  </View>
                ) : null}
                <View style={styles.composerInputRow}>
                  <Pressable
                    accessibilityRole="button"
                    disabled={sending || draftImageUris.length >= 4}
                    onPress={pickDraftImages}
                    style={[styles.attachButton, draftImageUris.length > 0 ? styles.attachButtonActive : null]}
                  >
                    <IconSymbol
                      name="camera-outline"
                      color={draftImageUris.length > 0 ? megrumColors.lavender : "rgba(58,50,74,0.48)"}
                      size={18}
                    />
                  </Pressable>
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
                    disabled={sending || (!draft.trim() && draftImageUris.length === 0)}
                    onPress={handleSend}
                    style={[
                      styles.sendButton,
                      draft.trim() || draftImageUris.length > 0 ? styles.sendButtonActive : null,
                      sending ? styles.sendButtonDisabled : null,
                    ]}
                  >
                    <IconSymbol
                      name={sending ? "ellipsis-horizontal" : "send-outline"}
                      color={draft.trim() || draftImageUris.length > 0 ? "#fff" : "rgba(58,50,74,0.42)"}
                      size={18}
                    />
                  </Pressable>
                </View>
                {draftImageUris.length > 0 ? (
                  <PickedImageRail imageUris={draftImageUris} onRemove={removeDraftImage} />
                ) : null}
              </View>
            )}
            {sendError ? <Text style={styles.sendError}>{sendError}</Text> : null}
          </>
        )}
        <Modal
          animationType="slide"
          onRequestClose={() => setThreadEditorOpen(false)}
          transparent
          visible={threadEditorOpen}
        >
          <View style={styles.modalOverlay}>
            <View style={styles.editorCard}>
              <Text style={styles.editorEyebrow}>THREAD</Text>
              <Text style={styles.editorTitle}>スレッドを編集</Text>
              <TextInput
                onChangeText={setThreadEditTitle}
                placeholder="タイトル"
                placeholderTextColor="rgba(58,50,74,0.34)"
                style={styles.editorInput}
                value={threadEditTitle}
              />
              <TextInput
                multiline
                onChangeText={setThreadEditBody}
                placeholder="本文"
                placeholderTextColor="rgba(58,50,74,0.34)"
                style={[styles.editorInput, styles.editorBodyInput]}
                textAlignVertical="top"
                value={threadEditBody}
              />
              <View style={styles.editorChipRow}>
                {MEGURI_BOARD_COMPOSER_CATEGORY_OPTIONS.map((category) => (
                  <Pressable
                    accessibilityRole="button"
                    key={category}
                    onPress={() => setThreadEditCategory(category)}
                    style={[
                      styles.editorCategoryChip,
                      threadEditCategory === category ? styles.editorCategoryChipActive : null,
                    ]}
                  >
                    <Text
                      style={[
                        styles.editorCategoryChipText,
                        threadEditCategory === category ? styles.editorCategoryChipTextActive : null,
                      ]}
                    >
                      {meguriBoardCategoryLabel(category)}
                    </Text>
                  </Pressable>
                ))}
              </View>
              <View style={styles.editorFooter}>
                <Pressable
                  accessibilityRole="button"
                  onPress={() => setThreadEditorOpen(false)}
                  style={styles.editorSecondary}
                >
                  <Text style={styles.editorSecondaryText}>キャンセル</Text>
                </Pressable>
                <Pressable accessibilityRole="button" onPress={saveThreadEditor} style={styles.editorPrimary}>
                  <Text style={styles.editorPrimaryText}>保存</Text>
                </Pressable>
              </View>
            </View>
          </View>
        </Modal>
        <Modal
          animationType="slide"
          onRequestClose={() => setReplyEditor(null)}
          transparent
          visible={!!replyEditor}
        >
          <View style={styles.modalOverlay}>
            <View style={styles.editorCard}>
              <Text style={styles.editorEyebrow}>REPLY</Text>
              <Text style={styles.editorTitle}>返信を編集</Text>
              <TextInput
                multiline
                onChangeText={setReplyEditBody}
                placeholder="返信を書く"
                placeholderTextColor="rgba(58,50,74,0.34)"
                style={[styles.editorInput, styles.editorBodyInput]}
                textAlignVertical="top"
                value={replyEditBody}
              />
              <View style={styles.editorFooter}>
                <Pressable
                  accessibilityRole="button"
                  onPress={() => setReplyEditor(null)}
                  style={styles.editorSecondary}
                >
                  <Text style={styles.editorSecondaryText}>キャンセル</Text>
                </Pressable>
                <Pressable accessibilityRole="button" onPress={saveReplyEditor} style={styles.editorPrimary}>
                  <Text style={styles.editorPrimaryText}>保存</Text>
                </Pressable>
              </View>
            </View>
          </View>
        </Modal>
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

function StatusBadge({ label }: { label: string }) {
  return (
    <View style={styles.statusBadge}>
      <Text style={styles.statusBadgeText}>{label}</Text>
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

function AttachmentGrid({ compact, imageUris }: { compact?: boolean; imageUris: string[] }) {
  if (imageUris.length === 0) return null;
  return (
    <View style={compact ? styles.attachmentGridCompact : styles.attachmentGrid}>
      {imageUris.slice(0, 4).map((uri, index) => (
        <View key={`${uri}-${index}`} style={compact ? styles.attachmentThumbCompact : styles.attachmentThumb}>
          <Image source={{ uri }} style={styles.attachmentImage} />
        </View>
      ))}
    </View>
  );
}

function PickedImageRail({
  imageUris,
  onRemove,
}: {
  imageUris: string[];
  onRemove: (uri: string) => void;
}) {
  return (
    <ScrollView horizontal contentContainerStyle={styles.pickedImageRail} showsHorizontalScrollIndicator={false}>
      {imageUris.map((uri) => (
        <View key={uri} style={styles.pickedImageWrap}>
          <Image source={{ uri }} style={styles.pickedImage} />
          <Pressable accessibilityRole="button" onPress={() => onRemove(uri)} style={styles.removeImageButton}>
            <IconSymbol name="close" color="#fff" size={12} />
          </Pressable>
        </View>
      ))}
    </ScrollView>
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

function buildThreadShareUrl(
  thread: MeguriBoardThread,
  viewer: MeguriBoardViewerContext,
  viewMode: MeguriBoardViewMode,
) {
  const params = new URLSearchParams({
    id: thread.id,
    prefecture: viewer.prefecture ?? "",
    spotKey: viewer.spotKey ?? "",
    spotLabel: viewer.spotLabel ?? "",
    viewMode,
  });
  return `${getAppScheme()}://meguri-board-thread?${params.toString()}`;
}

function getAppScheme() {
  const configuredScheme = Constants.expoConfig?.scheme;
  if (Array.isArray(configuredScheme) && configuredScheme[0]) return configuredScheme[0];
  if (typeof configuredScheme === "string" && configuredScheme) return configuredScheme;
  return Constants.expoConfig?.extra?.appVariant === "preview" ? "megrum-preview" : "megrum";
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

function normalizeReplySearch(value: string | null | undefined) {
  return (value ?? "").replace(/\s+/g, " ").trim().toLowerCase();
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
  statusBadge: {
    backgroundColor: "rgba(58,50,74,0.08)",
    borderRadius: 999,
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  statusBadgeText: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
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
  attachmentGrid: {
    flexDirection: "row",
    gap: 8,
  },
  attachmentGridCompact: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 6,
    marginTop: 8,
  },
  attachmentThumb: {
    aspectRatio: 1,
    borderRadius: 14,
    flex: 1,
    maxHeight: 132,
    minHeight: 92,
    overflow: "hidden",
  },
  attachmentThumbCompact: {
    borderRadius: 12,
    height: 78,
    overflow: "hidden",
    width: 78,
  },
  attachmentImage: {
    height: "100%",
    width: "100%",
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
  },
  replyHeaderRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 6,
  },
  replyCountMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  replySearchBox: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    flexDirection: "row",
    gap: 8,
    minHeight: 42,
    paddingHorizontal: 12,
  },
  replySearchInput: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 13,
    fontWeight: "800",
    padding: 0,
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
  quotePreview: {
    backgroundColor: "rgba(58,50,74,0.07)",
    borderLeftColor: "rgba(166,149,216,0.72)",
    borderLeftWidth: 3,
    borderRadius: 10,
    gap: 2,
    marginBottom: 8,
    paddingHorizontal: 9,
    paddingVertical: 7,
  },
  quotePreviewMine: {
    backgroundColor: "rgba(255,255,255,0.18)",
    borderLeftColor: "rgba(255,255,255,0.72)",
  },
  quoteAuthor: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  quoteAuthorMine: {
    color: "#fff",
  },
  quoteBody: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 16,
  },
  quoteBodyMine: {
    color: "rgba(255,255,255,0.82)",
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
  replyBodyDeleted: {
    color: "rgba(58,50,74,0.48)",
    fontStyle: "italic",
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
    backgroundColor: "rgba(251,249,252,0.98)",
    borderTopColor: "rgba(58,50,74,0.08)",
    borderTopWidth: StyleSheet.hairlineWidth,
    gap: 10,
    paddingHorizontal: 14,
    paddingTop: 12,
  },
  composerQuote: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: 16,
    borderWidth: 1,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  composerQuoteCopy: {
    flex: 1,
    gap: 2,
  },
  composerQuoteAuthor: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  composerQuoteBody: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  composerInputRow: {
    alignItems: "flex-end",
    flexDirection: "row",
    gap: 10,
  },
  attachButton: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.08)",
    borderRadius: 999,
    height: 44,
    justifyContent: "center",
    width: 44,
  },
  attachButtonActive: {
    backgroundColor: "rgba(166,149,216,0.16)",
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
  pickedImageRail: {
    gap: 8,
    paddingRight: 18,
  },
  pickedImageWrap: {
    borderRadius: 14,
    height: 58,
    overflow: "hidden",
    width: 58,
  },
  pickedImage: {
    height: "100%",
    width: "100%",
  },
  removeImageButton: {
    alignItems: "center",
    backgroundColor: "rgba(26,20,38,0.68)",
    borderRadius: 999,
    height: 20,
    justifyContent: "center",
    position: "absolute",
    right: 4,
    top: 4,
    width: 20,
  },
  lockedComposer: {
    alignItems: "center",
    backgroundColor: "rgba(251,249,252,0.98)",
    borderTopColor: "rgba(58,50,74,0.08)",
    borderTopWidth: StyleSheet.hairlineWidth,
    paddingHorizontal: 14,
    paddingTop: 12,
  },
  lockedComposerText: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    color: megrumColors.mutedInk,
    fontSize: 12.5,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  sendError: {
    color: megrumColors.warn,
    fontSize: 11.5,
    fontWeight: "800",
    paddingHorizontal: 18,
    paddingTop: 6,
    paddingBottom: 4,
  },
  modalOverlay: {
    backgroundColor: "rgba(24,20,32,0.28)",
    flex: 1,
    justifyContent: "flex-end",
    padding: 14,
  },
  editorCard: {
    backgroundColor: "#fff",
    borderRadius: 24,
    gap: 12,
    paddingHorizontal: 18,
    paddingTop: 18,
    paddingBottom: 16,
    ...megrumShadow,
  },
  editorEyebrow: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0,
  },
  editorTitle: {
    color: megrumColors.ink,
    fontSize: 20,
    fontWeight: "900",
  },
  editorInput: {
    backgroundColor: "rgba(251,249,252,0.96)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "800",
    minHeight: 48,
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  editorBodyInput: {
    minHeight: 132,
  },
  editorChipRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  editorCategoryChip: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  editorCategoryChipActive: {
    backgroundColor: "rgba(166,149,216,0.18)",
  },
  editorCategoryChipText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
  },
  editorCategoryChipTextActive: {
    color: megrumColors.lavender,
  },
  editorFooter: {
    flexDirection: "row",
    gap: 10,
    paddingTop: 2,
  },
  editorSecondary: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 16,
    flex: 1,
    minHeight: 46,
    justifyContent: "center",
  },
  editorSecondaryText: {
    color: megrumColors.mutedInk,
    fontSize: 13.5,
    fontWeight: "900",
  },
  editorPrimary: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 16,
    flex: 1,
    minHeight: 46,
    justifyContent: "center",
  },
  editorPrimaryText: {
    color: "#fff",
    fontSize: 13.5,
    fontWeight: "900",
  },
});
