import { useCallback, useEffect, useMemo, useState } from "react";
import Constants from "expo-constants";
import { router, useFocusEffect, useLocalSearchParams } from "expo-router";
import SegmentedControl from "@react-native-segmented-control/segmented-control";
import * as ImagePicker from "expo-image-picker";
import {
  ActionSheetIOS,
  ActivityIndicator,
  Alert,
  Image,
  Modal,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  Share,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useAuth } from "../src/auth/AuthProvider";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { Screen } from "../src/components/Screen";
import {
  MEGURI_BOARD_AUDIENCE_OPTIONS,
  MEGURI_BOARD_CATEGORY_OPTIONS,
  MEGURI_BOARD_COMPOSER_CATEGORY_OPTIONS,
  MEGURI_BOARD_REPORT_REASONS,
  MEGURI_BOARD_SORT_OPTIONS,
  blockMeguriBoardUser,
  clearMeguriBoardComposerDraft,
  createMeguriBoardThread,
  filterMeguriBoardThreads,
  hideMeguriBoardThread,
  loadMeguriBoardComposerDraft,
  loadMeguriBoardReplyDraftThreadIds,
  loadMeguriBoardThreads,
  markMeguriBoardThreadRead,
  meguriBoardAudienceLabel,
  meguriBoardAudienceMeta,
  meguriBoardCategoryLabel,
  meguriBoardReportReasonLabel,
  meguriBoardSortLabel,
  reportMeguriBoardThread,
  saveMeguriBoardComposerDraft,
  setMeguriBoardThreadBookmarked,
  setMeguriBoardThreadReacted,
  setMeguriBoardThreadSubscribed,
  type MeguriBoardActor,
  type MeguriBoardAudienceScope,
  type MeguriBoardReportReason,
  type MeguriBoardThreadCategory,
  type MeguriBoardThreadSort,
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
import {
  displayMeguriBoardPrefecture,
  loadMeguriBoardDefaultPrefecture,
  MEGURI_BOARD_PREFECTURE_OPTIONS,
  normalizeMeguriBoardPrefecture,
  saveMeguriBoardDefaultPrefecture,
} from "../src/lib/meguriBoardPreferences";
import { megrumColors, megrumShadow } from "../src/theme/tokens";
import { IconSymbol } from "../src/components/IconSymbol";

const SCOPE_SEGMENTS = ["3km圏内", "都道府県"];
const VIEW_MODE_SEGMENTS = ["3km圏内", "都道府県"];
const VIEW_MODE_OPTIONS = ["nearby_3km", "same_prefecture"] as const satisfies readonly MeguriBoardViewMode[];
const THREAD_TITLE_LIMIT = 80;
const THREAD_BODY_LIMIT = 500;

export default function MeguriBoardScreen() {
  const insets = useSafeAreaInsets();
  const params = useLocalSearchParams<{
    compose?: string | string[];
    prefecture?: string | string[];
    spotKey?: string | string[];
    spotLabel?: string | string[];
    viewerLat?: string | string[];
    viewerLng?: string | string[];
  }>();
  const { previewMode, profile, user } = useAuth();
  const [localArea, setLocalArea] = useState(DEFAULT_MEGURI_PROFILE.baseArea);
  const [localDisplayName, setLocalDisplayName] = useState(DEFAULT_MEGURI_PROFILE.displayName);
  const [selectedPrefecture, setSelectedPrefecture] = useState<string | null>(() =>
    normalizeMeguriBoardPrefecture(readParam(params.prefecture)),
  );
  const [threads, setThreads] = useState<MeguriBoardThread[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [composerOpen, setComposerOpen] = useState(false);
  const [composerTitle, setComposerTitle] = useState("");
  const [composerBody, setComposerBody] = useState("");
  const [composerImageUris, setComposerImageUris] = useState<string[]>([]);
  const [composerDraftReady, setComposerDraftReady] = useState(false);
  const [composerCategory, setComposerCategory] =
    useState<Exclude<MeguriBoardThreadCategory, "all">>("question");
  const [composerScope, setComposerScope] = useState<MeguriBoardAudienceScope>("nearby_3km");
  const [composerError, setComposerError] = useState<string | null>(null);
  const [locationContext, setLocationContext] = useState<MegrumLocationContext | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [viewMode, setViewMode] = useState<MeguriBoardViewMode>("nearby_3km");
  const [categoryFilter, setCategoryFilter] = useState<MeguriBoardThreadCategory>("all");
  const [searchText, setSearchText] = useState("");
  const [sortMode, setSortMode] = useState<MeguriBoardThreadSort>("active");
  const [mediaOnly, setMediaOnly] = useState(false);
  const [markingVisibleRead, setMarkingVisibleRead] = useState(false);
  const [replyDraftThreadIds, setReplyDraftThreadIds] = useState<Set<string>>(new Set());

  const actor = useMemo<MeguriBoardActor>(
    () => ({
      displayName: profile?.displayName || localDisplayName || DEFAULT_MEGURI_PROFILE.displayName,
      handle: profile?.handle ?? (previewMode ? "preview_hana" : null),
      primaryArea: profile?.primaryArea || localArea || DEFAULT_MEGURI_PROFILE.baseArea,
      userId: user?.id ?? "preview-me",
    }),
    [localArea, localDisplayName, previewMode, profile?.displayName, profile?.handle, profile?.primaryArea, user?.id],
  );

  const viewerContext = useMemo<MeguriBoardViewerContext>(
    () =>
      buildViewerContext({
        fallbackArea: actor.primaryArea,
        fallbackCoordinate: locationContext?.coordinate ?? coordinateFromParams({
          latitude: params.viewerLat,
          longitude: params.viewerLng,
        }),
        prefecture:
          selectedPrefecture ??
          normalizeMeguriBoardPrefecture(readParam(params.prefecture)) ??
          normalizeMeguriBoardPrefecture(actor.primaryArea),
        resolvedPrefecture: null,
        spotKey: readParam(params.spotKey),
        spotLabel: readParam(params.spotLabel),
        viewerId: user?.id ?? actor.userId,
      }),
    [
      actor.primaryArea,
      actor.userId,
      locationContext?.coordinate,
      params.prefecture,
      params.spotKey,
      params.spotLabel,
      params.viewerLat,
      params.viewerLng,
      selectedPrefecture,
      user?.id,
    ],
  );

  const visibleThreads = useMemo(
    () => {
      const filteredThreads = filterMeguriBoardThreads(threads, {
        category: categoryFilter,
        draftThreadIds: replyDraftThreadIds,
        query: searchText,
        sort: sortMode,
      });
      return mediaOnly
        ? filteredThreads.filter((thread) => thread.imageUris.length > 0)
        : filteredThreads;
    },
    [categoryFilter, mediaOnly, replyDraftThreadIds, searchText, sortMode, threads],
  );
  const sortCountBaseThreads = useMemo(
    () => {
      const filteredThreads = filterMeguriBoardThreads(threads, {
        category: categoryFilter,
        query: searchText,
        sort: "active",
      });
      return mediaOnly
        ? filteredThreads.filter((thread) => thread.imageUris.length > 0)
        : filteredThreads;
    },
    [categoryFilter, mediaOnly, searchText, threads],
  );
  const sortCounts = useMemo<Record<MeguriBoardThreadSort, number>>(
    () => ({
      active: sortCountBaseThreads.length,
      new: sortCountBaseThreads.length,
      hot: sortCountBaseThreads.length,
      saved: sortCountBaseThreads.filter((thread) => thread.bookmarked).length,
      subscribed: sortCountBaseThreads.filter((thread) => thread.subscribed).length,
      participated: sortCountBaseThreads.filter((thread) => thread.participated).length,
      drafts: sortCountBaseThreads.filter((thread) => replyDraftThreadIds.has(thread.id)).length,
      mine: sortCountBaseThreads.filter((thread) => thread.mine).length,
      unread: sortCountBaseThreads.filter(isThreadUnread).length,
    }),
    [replyDraftThreadIds, sortCountBaseThreads],
  );
  const hasActiveFilters =
    categoryFilter !== "all" || !!searchText.trim() || sortMode !== "active" || mediaOnly;
  const hasComposerDraft =
    !!composerTitle.trim() || !!composerBody.trim() || composerImageUris.length > 0;
  const activeFilterChips = useMemo(() => {
    const chips: { key: string; label: string }[] = [];
    const query = searchText.trim();
    if (query) {
      chips.push({ key: "search", label: `検索: ${query.length > 18 ? `${query.slice(0, 18)}...` : query}` });
    }
    if (categoryFilter !== "all") {
      chips.push({ key: "category", label: `カテゴリ: ${meguriBoardCategoryLabel(categoryFilter)}` });
    }
    if (sortMode !== "active") {
      chips.push({ key: "sort", label: `並び替え: ${meguriBoardSortLabel(sortMode)}` });
    }
    if (mediaOnly) {
      chips.push({ key: "media", label: "画像あり" });
    }
    return chips;
  }, [categoryFilter, mediaOnly, searchText, sortMode]);

  const sections = useMemo(
    () =>
      [
        {
          key: viewMode,
          title:
            sortMode === "mine"
              ? "自分のスレッド"
              : sortMode === "participated"
                ? "参加中のスレッド"
              : sortMode === "drafts"
                ? "下書き中のスレッド"
              : sortMode === "unread"
                ? "未読スレッド"
              : viewMode === "nearby_3km"
                ? "近くのスレッド"
                : "都道府県のスレッド",
          rows: visibleThreads,
        },
      ].filter((section) => section.rows.length > 0),
    [sortMode, viewMode, visibleThreads],
  );

  const refreshThreads = useCallback(async (
    prefectureOverride?: string | null,
    options: { silent?: boolean } = {},
  ) => {
    if (options.silent) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }
    const settings = await loadMeguriProfileSettings().catch(() => DEFAULT_MEGURI_PROFILE);
    const currentLocation = await getCurrentLocationContext().catch(() => null);
    const nextPrefecture =
      normalizeMeguriBoardPrefecture(prefectureOverride) ??
      selectedPrefecture ??
      normalizeMeguriBoardPrefecture(readParam(params.prefecture)) ??
      (await loadMeguriBoardDefaultPrefecture(
        profile?.primaryArea || settings.baseArea || actor.primaryArea,
      ));
    setLocationContext(currentLocation);
    setLocalArea(settings.baseArea || DEFAULT_MEGURI_PROFILE.baseArea);
    setLocalDisplayName(settings.displayName || DEFAULT_MEGURI_PROFILE.displayName);
    setSelectedPrefecture(nextPrefecture);
    const [nextThreads, draftThreadIds] = await Promise.all([
      loadMeguriBoardThreads(
        buildViewerContext({
          fallbackArea: profile?.primaryArea || settings.baseArea || actor.primaryArea,
          fallbackCoordinate: currentLocation?.coordinate ?? coordinateFromParams({
            latitude: params.viewerLat,
            longitude: params.viewerLng,
          }),
          prefecture: nextPrefecture,
          resolvedPrefecture: null,
          spotKey: readParam(params.spotKey),
          spotLabel: readParam(params.spotLabel),
          viewerId: user?.id ?? actor.userId,
        }),
        { previewMode, viewMode },
      ).catch(() => []),
      loadMeguriBoardReplyDraftThreadIds().catch(() => []),
    ]);
    setThreads(nextThreads);
    setReplyDraftThreadIds(new Set(draftThreadIds));
    setLoading(false);
    setRefreshing(false);
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
    selectedPrefecture,
    user?.id,
    viewMode,
  ]);

  const refreshThreadsSilently = useCallback(() => {
    void refreshThreads(undefined, { silent: true });
  }, [refreshThreads]);

  useFocusEffect(
    useCallback(() => {
      void refreshThreads();
    }, [refreshThreads]),
  );

  useEffect(() => {
    if (readParam(params.compose) === "1") {
      openComposer();
    }
  }, [params.compose]);

  useEffect(() => {
    if (!composerOpen) {
      setComposerDraftReady(false);
      return;
    }
    if (composerDraftReady) return;
    let alive = true;
    void loadMeguriBoardComposerDraft(viewerContext)
      .then((draft) => {
        if (!alive) return;
        if (draft) {
          setComposerTitle(draft.title);
          setComposerBody(draft.body);
          setComposerImageUris(draft.imageUris);
          setComposerCategory(draft.category);
          setComposerScope(
            draft.audienceScope === "same_prefecture" ? "same_prefecture" : "nearby_3km",
          );
        }
        setComposerDraftReady(true);
      })
      .catch(() => {
        if (alive) setComposerDraftReady(true);
      });
    return () => {
      alive = false;
    };
  }, [composerDraftReady, composerOpen, viewerContext]);

  useEffect(() => {
    if (!composerOpen || !composerDraftReady) return;
    const handle = setTimeout(() => {
      void saveMeguriBoardComposerDraft(viewerContext, {
        audienceScope: composerScope,
        body: composerBody,
        category: composerCategory,
        imageUris: composerImageUris,
        title: composerTitle,
      });
    }, 350);
    return () => clearTimeout(handle);
  }, [
    composerBody,
    composerCategory,
    composerDraftReady,
    composerImageUris,
    composerOpen,
    composerScope,
    composerTitle,
    viewerContext,
  ]);

  function openPrefecturePicker() {
    if (Platform.OS !== "ios") return;
    const optionLabels = MEGURI_BOARD_PREFECTURE_OPTIONS.map(displayMeguriBoardPrefecture);
    const cancelButtonIndex = optionLabels.length;
    ActionSheetIOS.showActionSheetWithOptions(
      {
        cancelButtonIndex,
        options: [...optionLabels, "キャンセル"],
        title: "都道府県を選択",
      },
      (buttonIndex) => {
        if (buttonIndex === cancelButtonIndex) return;
        const nextPrefecture = MEGURI_BOARD_PREFECTURE_OPTIONS[buttonIndex];
        if (nextPrefecture) {
          void handleSelectPrefecture(nextPrefecture);
        }
      },
    );
  }

  async function handleSelectPrefecture(nextPrefecture: string) {
    const normalized = await saveMeguriBoardDefaultPrefecture(nextPrefecture);
    if (!normalized) return;
    setSelectedPrefecture(normalized);
    void refreshThreads(normalized);
  }

  async function pickComposerImages() {
    const remaining = Math.max(0, 4 - composerImageUris.length);
    if (remaining === 0) return;
    const permission = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!permission.granted) {
      Alert.alert("写真へのアクセスを許可してください", "掲示板に画像を添付するには写真ライブラリの許可が必要です。");
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
    setComposerImageUris((current) => [...current, ...nextUris].slice(0, 4));
  }

  function removeComposerImage(uri: string) {
    setComposerImageUris((current) => current.filter((candidate) => candidate !== uri));
  }

  async function discardComposerDraft() {
    setComposerTitle("");
    setComposerBody("");
    setComposerImageUris([]);
    setComposerError(null);
    await clearMeguriBoardComposerDraft(viewerContext);
  }

  function openComposer() {
    setComposerDraftReady(false);
    setComposerOpen(true);
  }

  function resetBoardFilters() {
    setCategoryFilter("all");
    setSearchText("");
    setSortMode("active");
    setMediaOnly(false);
  }

  function clearFilterChip(key: string) {
    switch (key) {
      case "search":
        setSearchText("");
        break;
      case "category":
        setCategoryFilter("all");
        break;
      case "sort":
        setSortMode("active");
        break;
      case "media":
        setMediaOnly(false);
        break;
      default:
        break;
    }
  }

  function closeComposer() {
    setComposerOpen(false);
  }

  async function handleCreateThread() {
    const title = composerTitle.trim();
    const body = composerBody.trim();
    if (!title) {
      setComposerError("タイトルを入れてください。");
      return;
    }
    if (!body) {
      setComposerError("本文を入れてください。");
      return;
    }
    setSubmitting(true);
    setComposerError(null);
    const actionLocation =
      locationContext ?? (await getCurrentLocationContext().catch(() => null));
    const actionContext = buildViewerContext({
      fallbackArea: actor.primaryArea,
      fallbackCoordinate: actionLocation?.coordinate ?? viewerContext.coordinate ?? null,
      prefecture: viewerContext.prefecture,
      resolvedPrefecture: null,
      spotKey: viewerContext.spotKey,
      spotLabel: viewerContext.spotLabel,
      viewerId: viewerContext.viewerId,
    });
    setLocationContext(actionLocation);
    if (composerScope === "nearby_3km" && !actionContext.coordinate) {
      setSubmitting(false);
      setComposerError("3km圏内のスレッドを立てるには、位置情報の許可が必要です。");
      return;
    }
    const thread = await createMeguriBoardThread(
      {
        audienceScope: composerScope,
        body,
        category: composerCategory,
        imageUris: composerImageUris,
        origin: actionContext.coordinate ?? null,
        prefecture: actionContext.prefecture,
        previewMode,
        spotKey: actionContext.spotKey,
        spotLabel: actionContext.spotLabel,
        title,
      },
      actor,
    ).catch(() => null);
    setSubmitting(false);
    if (!thread) {
      setComposerError("スレッドを作成できませんでした。");
      return;
    }
    setComposerOpen(false);
    setComposerTitle("");
    setComposerBody("");
    setComposerImageUris([]);
    await clearMeguriBoardComposerDraft(actionContext);
    setComposerCategory("question");
    setComposerScope("nearby_3km");
    setThreads((current) =>
      [thread, ...current.filter((candidate) => candidate.id !== thread.id)].sort(
        (left, right) => right.latestActivityAt - left.latestActivityAt,
      ),
    );
    router.push({
      pathname: "/meguri-board-thread",
      params: {
        id: thread.id,
        prefecture: actionContext.prefecture || "",
        spotKey: actionContext.spotKey || "",
        spotLabel: actionContext.spotLabel || "",
        viewerLat: actionContext.coordinate ? String(actionContext.coordinate.latitude) : "",
        viewerLng: actionContext.coordinate ? String(actionContext.coordinate.longitude) : "",
        viewMode,
      },
    });
  }

  function updateThreadLocally(nextThread: MeguriBoardThread) {
    setThreads((current) =>
      current
        .map((thread) => (thread.id === nextThread.id ? nextThread : thread))
        .sort((left, right) => right.latestActivityAt - left.latestActivityAt),
    );
  }

  async function markVisibleUnreadThreadsRead() {
    if (markingVisibleRead) return;
    const unreadIds = visibleThreads
      .filter((thread) => !thread.readAt || thread.readAt < thread.latestActivityAt)
      .map((thread) => thread.id);
    if (unreadIds.length === 0) return;
    const unreadIdSet = new Set(unreadIds);
    const nextReadAt = Date.now();
    setMarkingVisibleRead(true);
    setThreads((current) =>
      current.map((thread) =>
        unreadIdSet.has(thread.id)
          ? { ...thread, readAt: Math.max(nextReadAt, thread.latestActivityAt) }
          : thread,
      ),
    );
    try {
      await Promise.all(unreadIds.map((threadId) => markMeguriBoardThreadRead(threadId)));
    } finally {
      setMarkingVisibleRead(false);
    }
  }

  async function toggleThreadBookmark(thread: MeguriBoardThread) {
    const bookmarked = !thread.bookmarked;
    updateThreadLocally({
      ...thread,
      bookmarkCount: Math.max(0, thread.bookmarkCount + (bookmarked ? 1 : -1)),
      bookmarked,
    });
    await setMeguriBoardThreadBookmarked(thread.id, bookmarked);
  }

  async function toggleThreadReaction(thread: MeguriBoardThread) {
    const reacted = !thread.reacted;
    updateThreadLocally({
      ...thread,
      reacted,
      reactionCount: Math.max(0, thread.reactionCount + (reacted ? 1 : -1)),
    });
    await setMeguriBoardThreadReacted(thread.id, reacted);
  }

  async function toggleThreadSubscription(thread: MeguriBoardThread) {
    const subscribed = !thread.subscribed;
    updateThreadLocally({ ...thread, subscribed });
    await setMeguriBoardThreadSubscribed(thread.id, subscribed);
  }

  async function hideThread(thread: MeguriBoardThread) {
    setThreads((current) => current.filter((candidate) => candidate.id !== thread.id));
    await hideMeguriBoardThread(thread.id);
  }

  async function reportThread(thread: MeguriBoardThread, reason: MeguriBoardReportReason) {
    updateThreadLocally({ ...thread, reported: true });
    await reportMeguriBoardThread(thread.id, reason);
    Alert.alert("通報しました", "確認して対応します。");
  }

  function openReportReasonPicker(thread: MeguriBoardThread) {
    if (thread.reported) return;
    if (Platform.OS !== "ios") {
      void reportThread(thread, "other");
      return;
    }
    const labels = MEGURI_BOARD_REPORT_REASONS.map(meguriBoardReportReasonLabel);
    const cancelButtonIndex = labels.length;
    ActionSheetIOS.showActionSheetWithOptions(
      {
        cancelButtonIndex,
        options: [...labels, "キャンセル"],
        title: "通報理由を選択",
      },
      (index) => {
        const reason = MEGURI_BOARD_REPORT_REASONS[index];
        if (!reason) return;
        void reportThread(thread, reason);
      },
    );
  }

  async function shareThread(thread: MeguriBoardThread) {
    const url = buildThreadShareUrl(thread, viewerContext, viewMode);
    await Share.share({
      message: `${thread.title}\n${thread.body}\n${url}`,
      title: thread.title,
      url,
    });
  }

  function openBoardUserProfile(userId: string) {
    if (!userId) return;
    if (userId === actor.userId) {
      router.push("/(tabs)/profile");
      return;
    }
    router.push({
      pathname: "/user-profile",
      params: { id: userId },
    });
  }

  async function blockThreadAuthor(thread: MeguriBoardThread) {
    if (thread.mine) return;
    setThreads((current) => current.filter((candidate) => candidate.authorId !== thread.authorId));
    await blockMeguriBoardUser(actor.userId, thread.authorId).catch(() => undefined);
    Alert.alert("ブロックしました", "このユーザーのスレッドと返信を表示しません。");
  }

  function confirmBlockThreadAuthor(thread: MeguriBoardThread) {
    if (thread.mine) return;
    Alert.alert(`${thread.authorName}さんをブロックしますか？`, "このユーザーのスレッドと返信を表示しなくなります。", [
      { style: "cancel", text: "キャンセル" },
      { onPress: () => void blockThreadAuthor(thread), style: "destructive", text: "ブロック" },
    ]);
  }

  function openThreadActions(thread: MeguriBoardThread) {
    const actions: Array<{ destructive?: boolean; disabled?: boolean; label: string; run?: () => void }> = [
      { label: "共有する", run: () => void shareThread(thread) },
      {
        label: thread.mine ? "自分のプロフィール" : "投稿者プロフィール",
        run: () => openBoardUserProfile(thread.authorId),
      },
      { label: thread.bookmarked ? "保存を解除" : "保存する", run: () => void toggleThreadBookmark(thread) },
      { label: thread.reacted ? "参考になったを取り消す" : "参考になった", run: () => void toggleThreadReaction(thread) },
      {
        label: thread.subscribed ? "通知を止める" : "通知を受け取る",
        run: () => void toggleThreadSubscription(thread),
      },
      { destructive: true, label: "非表示にする", run: () => void hideThread(thread) },
    ];
    if (!thread.mine) {
      actions.push({
        destructive: true,
        label: "このユーザーをブロック",
        run: () => confirmBlockThreadAuthor(thread),
      });
    }
    actions.push({
      disabled: thread.reported,
      label: thread.reported ? "通報済み" : "通報する",
      run: thread.reported ? undefined : () => openReportReasonPicker(thread),
    });
    const labels = [...actions.map((action) => action.label), "キャンセル"];
    const cancelButtonIndex = labels.length - 1;
    const destructiveButtonIndex = actions.findIndex((action) => action.destructive);
    const disabledButtonIndices = actions
      .map((action, index) => (action.disabled ? index : -1))
      .filter((index) => index >= 0);
    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          cancelButtonIndex,
          destructiveButtonIndex: destructiveButtonIndex >= 0 ? destructiveButtonIndex : undefined,
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
    void shareThread(thread);
  }

  return (
    <>
      <Screen bottomInset={false} contentStyle={styles.screen} scroll={false} topInset={false}>
        <View style={[styles.header, { paddingTop: Math.max(insets.top, 10) + 8 }]}>
          <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.roundButton}>
            <IconSymbol name="chevron-back" color={megrumColors.ink} size={20} />
          </Pressable>
          <View style={styles.headerCopy}>
            <Text style={styles.headerTitle}>スポット掲示板</Text>
            <Text numberOfLines={1} style={styles.headerSubtitle}>
              {viewerContext.spotLabel} / {displayMeguriBoardPrefecture(viewerContext.prefecture)}
            </Text>
          </View>
          <Pressable accessibilityRole="button" onPress={openComposer} style={styles.composeButton}>
            <IconSymbol name="add" color="#fff" size={18} />
          </Pressable>
        </View>

        <ScrollView
          contentContainerStyle={[
            styles.content,
            { paddingBottom: Math.max(insets.bottom, 12) + 34 },
          ]}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              tintColor={megrumColors.lavender}
              onRefresh={refreshThreadsSilently}
            />
          }
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.heroCard}>
            <View style={styles.heroLabelRow}>
              <Text style={styles.heroKicker}>MEGURI BOARD</Text>
              {previewMode ? (
                <View style={styles.previewBadge}>
                  <Text style={styles.previewBadgeText}>preview</Text>
                </View>
              ) : null}
            </View>
            <Text style={styles.heroTitle}>現地の温度感をゆるく共有</Text>
            <Text style={styles.heroBody}>
              いま見えているのは、現在地から3km圏内、または {displayMeguriBoardPrefecture(viewerContext.prefecture)} のスレッドです。
            </Text>
            <View style={styles.heroMetaRow}>
              <ScopePreviewPill label="3km圏内" value={viewerContext.coordinate ? "現在地から表示" : "位置情報待ち"} />
              <ScopePreviewPill label="都道府県" value={displayMeguriBoardPrefecture(viewerContext.prefecture)} />
            </View>
          </View>

          <SegmentedControl
            selectedIndex={VIEW_MODE_OPTIONS.indexOf(viewMode)}
            values={VIEW_MODE_SEGMENTS}
            onChange={(event) =>
              setViewMode(
                VIEW_MODE_OPTIONS[event.nativeEvent.selectedSegmentIndex] ?? "nearby_3km",
              )
            }
          />

          <View style={styles.searchBox}>
            <IconSymbol name="search" color="rgba(58,50,74,0.42)" size={17} />
            <TextInput
              autoCapitalize="none"
              clearButtonMode="while-editing"
              onChangeText={setSearchText}
              placeholder="スレッドを検索"
              placeholderTextColor="rgba(58,50,74,0.34)"
              style={styles.searchInput}
              value={searchText}
            />
          </View>

          <ScrollView
            horizontal
            contentContainerStyle={styles.filterRail}
            showsHorizontalScrollIndicator={false}
          >
            {MEGURI_BOARD_CATEGORY_OPTIONS.map((category) => (
              <Pressable
                key={category}
                accessibilityRole="button"
                onPress={() => setCategoryFilter(category)}
                style={[
                  styles.filterChip,
                  categoryFilter === category ? styles.filterChipActive : null,
                ]}
              >
                <Text
                  style={[
                    styles.filterChipText,
                    categoryFilter === category ? styles.filterChipTextActive : null,
                  ]}
                >
                  {meguriBoardCategoryLabel(category)}
                </Text>
              </Pressable>
            ))}
          </ScrollView>

          <View style={styles.sortRail}>
            {MEGURI_BOARD_SORT_OPTIONS.map((sort) => (
              (() => {
                const active = sortMode === sort;
                const count = sortCounts[sort] ?? 0;
                const showCount = sort !== "active" && sort !== "new" && sort !== "hot" && count > 0;
                return (
                  <Pressable
                    key={sort}
                    accessibilityRole="button"
                    onPress={() => setSortMode(sort)}
                    style={[styles.sortButton, active ? styles.sortButtonActive : null]}
                  >
                    <Text style={[styles.sortButtonText, active ? styles.sortButtonTextActive : null]}>
                      {meguriBoardSortLabel(sort)}
                    </Text>
                    {showCount ? (
                      <View style={[styles.sortCountBadge, active ? styles.sortCountBadgeActive : null]}>
                        <Text style={[styles.sortCountText, active ? styles.sortCountTextActive : null]}>
                          {count > 99 ? "99+" : count}
                        </Text>
                      </View>
                    ) : null}
                  </Pressable>
                );
              })()
            ))}
          </View>

          <Pressable
            accessibilityRole="button"
            onPress={() => setMediaOnly((current) => !current)}
            style={[styles.mediaFilterButton, mediaOnly ? styles.mediaFilterButtonActive : null]}
          >
            <IconSymbol
              name="camera-outline"
              color={mediaOnly ? megrumColors.lavender : megrumColors.mutedInk}
              size={14}
            />
            <Text style={[styles.mediaFilterText, mediaOnly ? styles.mediaFilterTextActive : null]}>
              画像あり
            </Text>
          </Pressable>

          {!loading ? (
            <View style={styles.resultSummaryRow}>
              <Text style={styles.resultSummaryText}>
                表示 {visibleThreads.length}件
              </Text>
              {hasActiveFilters ? (
                <Pressable
                  accessibilityRole="button"
                  onPress={resetBoardFilters}
                  style={styles.resultResetButton}
                >
                  <Text style={styles.resultResetText}>条件をリセット</Text>
                </Pressable>
              ) : null}
            </View>
          ) : null}

          {!loading && activeFilterChips.length > 0 ? (
            <ScrollView
              horizontal
              contentContainerStyle={styles.activeFilterRail}
              showsHorizontalScrollIndicator={false}
            >
              {activeFilterChips.map((chip) => (
                <Pressable
                  key={chip.key}
                  accessibilityRole="button"
                  onPress={() => clearFilterChip(chip.key)}
                  style={styles.activeFilterChip}
                >
                  <Text style={styles.activeFilterText}>{chip.label}</Text>
                  <IconSymbol name="close" color={megrumColors.lavender} size={13} />
                </Pressable>
              ))}
            </ScrollView>
          ) : null}

          {!loading && sortMode === "unread" && visibleThreads.length > 0 ? (
            <Pressable
              accessibilityRole="button"
              onPress={markVisibleUnreadThreadsRead}
              style={({ pressed }) => [
                styles.markReadCard,
                pressed ? styles.markReadCardPressed : null,
              ]}
            >
              <View style={styles.markReadCopy}>
                <Text style={styles.markReadLabel}>未読の整理</Text>
                <Text style={styles.markReadBody}>表示中の {visibleThreads.length} 件を既読にします</Text>
              </View>
              <View style={styles.markReadPill}>
                <IconSymbol name="checkmark-circle-outline" color={megrumColors.lavender} size={15} />
                <Text style={styles.markReadPillText}>
                  {markingVisibleRead ? "処理中" : "既読にする"}
                </Text>
              </View>
            </Pressable>
          ) : null}

          <Pressable
            accessibilityRole="button"
            onPress={openPrefecturePicker}
            style={({ pressed }) => [
              styles.prefectureSelector,
              pressed ? styles.prefectureSelectorPressed : null,
            ]}
          >
            <View style={styles.prefectureSelectorCopy}>
              <Text style={styles.prefectureSelectorLabel}>都道府県</Text>
              <Text style={styles.prefectureSelectorValue}>
                {displayMeguriBoardPrefecture(viewerContext.prefecture)}
              </Text>
            </View>
            <IconSymbol name="chevron-down" color={megrumColors.lavender} size={18} />
          </Pressable>

          <PrimaryButton onPress={openComposer}>スレッドを立てる</PrimaryButton>

          {loading ? (
            <View style={styles.loadingBox}>
              <ActivityIndicator color={megrumColors.lavender} />
              <Text style={styles.loadingText}>掲示板を読み込み中…</Text>
            </View>
          ) : sections.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyTitle}>
                {sortMode === "mine"
                  ? "自分のスレッドはまだありません"
                  : sortMode === "participated"
                    ? "参加中のスレッドはまだありません"
                  : sortMode === "drafts"
                    ? "返信下書きのあるスレッドはありません"
                  : sortMode === "unread"
                    ? "未読スレッドはありません"
                    : "まだスレッドはありません"}
              </Text>
              <Text style={styles.emptyBody}>
                {sortMode === "mine"
                  ? "スレッドを立てると、ここからすぐ戻れます。"
                  : sortMode === "participated"
                    ? "スレッドに返信すると、ここから会話へ戻れます。"
                  : sortMode === "drafts"
                    ? "返信を書きかけると、ここからすぐ再開できます。"
                  : sortMode === "unread"
                    ? "新しい返信がつくと、ここに表示されます。"
                  : "最初のひとことを置いておくと、あとから返事がつきやすいです。"}
              </Text>
            </View>
          ) : (
            sections.map((section) => (
              <View key={section.key} style={styles.section}>
                <Text style={styles.sectionTitle}>{section.title}</Text>
                <View style={styles.sectionRows}>
                  {section.rows.map((thread) => (
                    <Pressable
                      key={thread.id}
                      accessibilityRole="button"
                      onPress={() =>
                        router.push({
                          pathname: "/meguri-board-thread",
                          params: {
                            id: thread.id,
                            prefecture: viewerContext.prefecture || "",
                            spotKey: viewerContext.spotKey || "",
                            spotLabel: viewerContext.spotLabel || "",
                            viewerLat: viewerContext.coordinate ? String(viewerContext.coordinate.latitude) : "",
                            viewerLng: viewerContext.coordinate ? String(viewerContext.coordinate.longitude) : "",
                            viewMode,
                          },
                        })
                      }
                      onLongPress={() => openThreadActions(thread)}
                      style={({ pressed }) => [
                        styles.threadCard,
                        isThreadUnread(thread) ? styles.threadCardUnread : null,
                        pressed ? styles.threadCardPressed : null,
                      ]}
                    >
                      <View style={styles.threadTopRow}>
                        <View style={styles.threadBadgeRow}>
                          <CategoryBadge category={thread.category} />
                          <ScopeBadge scope={thread.audienceScope} />
                          {thread.isPinned ? <StatusBadge label="固定" /> : null}
                          {thread.status === "locked" ? <StatusBadge label="締め切り" /> : null}
                          {replyDraftThreadIds.has(thread.id) ? <StatusBadge label="下書きあり" /> : null}
                          {isThreadUnread(thread) ? (
                            <View style={styles.unreadBadge}>
                              <Text style={styles.unreadBadgeText}>未読</Text>
                            </View>
                          ) : null}
                        </View>
                        <View style={styles.threadTopActions}>
                          {thread.imageUris.length > 0 ? (
                            <View style={styles.mediaCountBadge}>
                              <IconSymbol name="camera-outline" color={megrumColors.lavender} size={13} />
                              <Text style={styles.mediaCountText}>{thread.imageUris.length}</Text>
                            </View>
                          ) : null}
                          <Text style={styles.threadTime}>{formatThreadListTimeLabel(thread)}</Text>
                          <Pressable
                            accessibilityRole="button"
                            hitSlop={8}
                            onPress={() => openThreadActions(thread)}
                            style={styles.moreButton}
                          >
                            <IconSymbol name="ellipsis-horizontal" color={megrumColors.mutedInk} size={17} />
                          </Pressable>
                        </View>
                      </View>
                      <Text numberOfLines={2} style={styles.threadTitle}>
                        {thread.title}
                      </Text>
                      <Text numberOfLines={3} style={styles.threadBody}>
                        {thread.body}
                      </Text>
                      <AttachmentGrid imageUris={thread.imageUris} compact />
                      <View style={styles.threadMetaRow}>
                        <Text numberOfLines={1} style={styles.threadMeta}>
                          {meguriBoardAudienceMeta(thread)} ·{" "}
                        </Text>
                        <Pressable
                          accessibilityRole="button"
                          hitSlop={8}
                          onPress={(event) => {
                            event.stopPropagation();
                            openBoardUserProfile(thread.authorId);
                          }}
                          style={styles.threadAuthorButton}
                        >
                          <Text numberOfLines={1} style={styles.threadAuthorText}>
                            {thread.authorName}
                          </Text>
                        </Pressable>
                      </View>
                      <View style={styles.threadFooter}>
                        <Text
                          numberOfLines={1}
                          style={[styles.replyPreview, isThreadUnread(thread) ? styles.replyPreviewUnread : null]}
                        >
                          {thread.latestReplyPreview || "まだ返信はありません"}
                        </Text>
                        <Pressable
                          accessibilityRole="button"
                          hitSlop={8}
                          onPress={() => toggleThreadReaction(thread)}
                          style={[styles.metricPill, thread.reacted ? styles.metricPillActive : null]}
                        >
                          <IconSymbol
                            name="heart"
                            color={thread.reacted ? megrumColors.lavender : megrumColors.mutedInk}
                            size={14}
                          />
                          <Text style={[styles.metricPillText, thread.reacted ? styles.metricPillTextActive : null]}>
                            {thread.reactionCount}
                          </Text>
                        </Pressable>
                        <Pressable
                          accessibilityRole="button"
                          hitSlop={8}
                          onPress={() => toggleThreadBookmark(thread)}
                          style={[styles.metricPill, thread.bookmarked ? styles.metricPillActive : null]}
                        >
                          <IconSymbol
                            name="star-outline"
                            color={thread.bookmarked ? megrumColors.lavender : megrumColors.mutedInk}
                            size={14}
                          />
                        </Pressable>
                        <Pressable
                          accessibilityRole="button"
                          hitSlop={8}
                          onPress={() => toggleThreadSubscription(thread)}
                          style={[styles.metricPill, thread.subscribed ? styles.metricPillActive : null]}
                        >
                          <IconSymbol
                            name="notifications-outline"
                            color={thread.subscribed ? megrumColors.lavender : megrumColors.mutedInk}
                            size={14}
                          />
                        </Pressable>
                        <View style={styles.replyCount}>
                          <IconSymbol name="mail-outline" color={megrumColors.mutedInk} size={15} />
                          <Text style={styles.replyCountText}>{thread.replyCount}</Text>
                        </View>
                      </View>
                    </Pressable>
                  ))}
                </View>
              </View>
            ))
          )}
        </ScrollView>
      </Screen>

      <Modal animationType="slide" transparent visible={composerOpen} onRequestClose={closeComposer}>
        <View style={styles.modalLayer}>
          <Pressable style={styles.modalBackdrop} onPress={closeComposer} />
          <View style={[styles.modalPanel, { paddingBottom: Math.max(insets.bottom, 14) + 12 }]}>
            <View style={styles.modalHandle} />
            <Text style={styles.modalTitle}>新しいスレッド</Text>
            <Text style={styles.modalSubTitle}>作成時の位置を基準に、見える範囲を選びます。</Text>
            {hasComposerDraft ? (
              <View style={styles.composerDraftStatus}>
                <Text style={styles.composerDraftText}>
                  下書き保存中{composerImageUris.length > 0 ? ` · 画像${composerImageUris.length}枚` : ""}
                </Text>
                <Pressable
                  accessibilityRole="button"
                  onPress={discardComposerDraft}
                  style={styles.composerDraftDiscard}
                >
                  <Text style={styles.composerDraftDiscardText}>破棄</Text>
                </Pressable>
              </View>
            ) : null}

            <View style={styles.field}>
              <View style={styles.fieldHeader}>
                <Text style={styles.fieldLabel}>タイトル</Text>
                <Text style={styles.inputCounter}>
                  {composerTitle.length}/{THREAD_TITLE_LIMIT}
                </Text>
              </View>
              <TextInput
                maxLength={THREAD_TITLE_LIMIT}
                onChangeText={setComposerTitle}
                placeholder="例: 物販列いまどれくらい？"
                placeholderTextColor="rgba(58,50,74,0.35)"
                style={styles.input}
                value={composerTitle}
              />
            </View>

            <View style={styles.field}>
              <View style={styles.fieldHeader}>
                <Text style={styles.fieldLabel}>本文</Text>
                <Text style={styles.inputCounter}>
                  {composerBody.length}/{THREAD_BODY_LIMIT}
                </Text>
              </View>
              <TextInput
                maxLength={THREAD_BODY_LIMIT}
                multiline
                onChangeText={setComposerBody}
                placeholder="現地で聞きたいことや、今の温度感をひとこと。"
                placeholderTextColor="rgba(58,50,74,0.35)"
                style={[styles.input, styles.textarea]}
                textAlignVertical="top"
                value={composerBody}
              />
            </View>

            <View style={styles.field}>
              <View style={styles.attachmentHeader}>
                <Text style={styles.fieldLabel}>画像</Text>
                <Text style={styles.attachmentLimit}>{composerImageUris.length}/4</Text>
              </View>
              <PickedImageRail
                imageUris={composerImageUris}
                onPick={pickComposerImages}
                onRemove={removeComposerImage}
              />
            </View>

            <View style={styles.field}>
              <Text style={styles.fieldLabel}>カテゴリ</Text>
              <View style={styles.composerCategoryGrid}>
                {MEGURI_BOARD_COMPOSER_CATEGORY_OPTIONS.map((category) => (
                  <Pressable
                    key={category}
                    accessibilityRole="button"
                    onPress={() => setComposerCategory(category)}
                    style={[
                      styles.composerCategoryChip,
                      composerCategory === category ? styles.composerCategoryChipActive : null,
                    ]}
                  >
                    <Text
                      style={[
                        styles.composerCategoryText,
                        composerCategory === category ? styles.composerCategoryTextActive : null,
                      ]}
                    >
                      {meguriBoardCategoryLabel(category)}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>

            <View style={styles.field}>
              <Text style={styles.fieldLabel}>公開範囲</Text>
              <SegmentedControl
                selectedIndex={composerScope === "same_prefecture" ? 1 : 0}
                values={SCOPE_SEGMENTS}
                onChange={(event) =>
                  setComposerScope(
                    MEGURI_BOARD_AUDIENCE_OPTIONS[event.nativeEvent.selectedSegmentIndex] ??
                      "nearby_3km",
                  )
                }
              />
              <Text style={styles.scopeHelp}>
                {composerScope === "nearby_3km" || composerScope === "same_spot"
                  ? "現在地から3km圏内にいる人向け"
                  : composerScope === "same_prefecture"
                    ? `${displayMeguriBoardPrefecture(viewerContext.prefecture)} を拠点に見ている人向け`
                    : `${displayMeguriBoardPrefecture(viewerContext.prefecture)} を拠点に見ている人向け`}
              </Text>
            </View>

            {composerError ? <Text style={styles.errorText}>{composerError}</Text> : null}

            <View style={styles.modalActions}>
              <PrimaryButton
                onPress={closeComposer}
                style={styles.modalSecondary}
                variant="secondary"
              >
                閉じる
              </PrimaryButton>
              <PrimaryButton loading={submitting} onPress={handleCreateThread} style={styles.modalPrimary}>
                投稿する
              </PrimaryButton>
            </View>
          </View>
        </View>
      </Modal>
    </>
  );
}

function ScopePreviewPill({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.scopePreviewPill}>
      <Text style={styles.scopePreviewLabel}>{label}</Text>
      <Text numberOfLines={1} style={styles.scopePreviewValue}>
        {value}
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
          {index === 3 && imageUris.length > 4 ? (
            <View style={styles.attachmentMoreOverlay}>
              <Text style={styles.attachmentMoreText}>+{imageUris.length - 4}</Text>
            </View>
          ) : null}
        </View>
      ))}
    </View>
  );
}

function PickedImageRail({
  imageUris,
  onPick,
  onRemove,
}: {
  imageUris: string[];
  onPick: () => void;
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
      {imageUris.length < 4 ? (
        <Pressable accessibilityRole="button" onPress={onPick} style={styles.addImageButton}>
          <IconSymbol name="camera-outline" color={megrumColors.lavender} size={18} />
          <Text style={styles.addImageText}>追加</Text>
        </Pressable>
      ) : null}
    </ScrollView>
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

function buildViewerContext(input: {
  fallbackArea: string | null;
  fallbackCoordinate?: MeguriBoardViewerContext["coordinate"];
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
    coordinate: input.fallbackCoordinate ?? null,
    prefecture,
    spotKey,
    spotLabel,
    viewerId: input.viewerId,
  };
}

function readParam(value: string | string[] | undefined) {
  return Array.isArray(value) ? value[0] : value;
}

function isThreadUnread(thread: Pick<MeguriBoardThread, "latestActivityAt" | "readAt">) {
  return !thread.readAt || thread.readAt < thread.latestActivityAt;
}

function slugify(value: string) {
  return value.toLowerCase().replace(/\s+/g, "-");
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

function formatThreadListTimeLabel(thread: MeguriBoardThread) {
  if (thread.replyCount > 0) {
    return `返信 ${formatRelativeTime(thread.latestActivityAt)}`;
  }
  if (thread.updatedAt && thread.updatedAt > thread.createdAt + 60000) {
    return `更新 ${formatRelativeTime(thread.updatedAt)}`;
  }
  return `作成 ${formatRelativeTime(thread.createdAt)}`;
}

const styles = StyleSheet.create({
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
    paddingHorizontal: 16,
  },
  roundButton: {
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
    fontSize: 18,
    fontWeight: "900",
  },
  headerSubtitle: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "700",
  },
  composeButton: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    height: 40,
    justifyContent: "center",
    width: 40,
  },
  content: {
    gap: 16,
    paddingBottom: 28,
    paddingHorizontal: 18,
    paddingTop: 16,
  },
  heroCard: {
    backgroundColor: "#fff",
    borderRadius: 24,
    gap: 10,
    paddingHorizontal: 18,
    paddingVertical: 18,
    ...megrumShadow,
  },
  heroLabelRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  heroKicker: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  previewBadge: {
    backgroundColor: "rgba(168,212,230,0.32)",
    borderRadius: 999,
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  previewBadgeText: {
    color: megrumColors.ink,
    fontSize: 10,
    fontWeight: "900",
  },
  heroTitle: {
    color: megrumColors.ink,
    fontSize: 21,
    fontWeight: "900",
  },
  heroBody: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "700",
    lineHeight: 19,
  },
  heroMetaRow: {
    flexDirection: "row",
    gap: 10,
  },
  searchBox: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: "row",
    gap: 8,
    paddingHorizontal: 13,
    paddingVertical: 11,
  },
  searchInput: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 14,
    fontWeight: "800",
    minHeight: 22,
    padding: 0,
  },
  filterRail: {
    gap: 8,
    paddingRight: 18,
  },
  filterChip: {
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 13,
    paddingVertical: 8,
  },
  filterChipActive: {
    backgroundColor: "rgba(166,149,216,0.18)",
    borderColor: "rgba(166,149,216,0.46)",
  },
  filterChipText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
  },
  filterChipTextActive: {
    color: megrumColors.lavender,
  },
  sortRail: {
    backgroundColor: "rgba(58,50,74,0.07)",
    borderRadius: 999,
    flexDirection: "row",
    padding: 4,
  },
  sortButton: {
    alignItems: "center",
    borderRadius: 999,
    flex: 1,
    justifyContent: "center",
    minHeight: 34,
    paddingVertical: 8,
  },
  sortButtonActive: {
    backgroundColor: "#fff",
    ...megrumShadow,
  },
  sortButtonText: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "900",
  },
  sortButtonTextActive: {
    color: megrumColors.ink,
  },
  sortCountBadge: {
    alignItems: "center",
    backgroundColor: "rgba(168,212,230,0.9)",
    borderColor: "#fff",
    borderRadius: 999,
    borderWidth: 1,
    height: 16,
    justifyContent: "center",
    minWidth: 16,
    paddingHorizontal: 4,
    position: "absolute",
    right: 1,
    top: 1,
  },
  sortCountBadgeActive: {
    backgroundColor: "rgba(166,149,216,0.92)",
  },
  sortCountText: {
    color: "#fff",
    fontSize: 8.5,
    fontWeight: "900",
  },
  sortCountTextActive: {
    color: "#fff",
  },
  mediaFilterButton: {
    alignItems: "center",
    alignSelf: "flex-start",
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 999,
    borderWidth: 1,
    flexDirection: "row",
    gap: 5,
    minHeight: 34,
    paddingHorizontal: 13,
  },
  mediaFilterButtonActive: {
    backgroundColor: "rgba(166,149,216,0.14)",
    borderColor: "rgba(166,149,216,0.42)",
  },
  mediaFilterText: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "900",
  },
  mediaFilterTextActive: {
    color: megrumColors.lavender,
  },
  resultSummaryRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    minHeight: 32,
  },
  resultSummaryText: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "900",
  },
  resultResetButton: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    minHeight: 30,
    justifyContent: "center",
    paddingHorizontal: 12,
  },
  resultResetText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  activeFilterRail: {
    gap: 8,
    paddingRight: 18,
  },
  activeFilterChip: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.1)",
    borderColor: "rgba(166,149,216,0.28)",
    borderRadius: 999,
    borderWidth: 1,
    flexDirection: "row",
    gap: 5,
    minHeight: 30,
    paddingHorizontal: 11,
  },
  activeFilterText: {
    color: megrumColors.lavender,
    fontSize: 10.8,
    fontWeight: "900",
  },
  markReadCard: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.11)",
    borderColor: "rgba(166,149,216,0.24)",
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    justifyContent: "space-between",
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  markReadCardPressed: {
    opacity: 0.9,
  },
  markReadCopy: {
    flex: 1,
    gap: 3,
  },
  markReadLabel: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  markReadBody: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "700",
  },
  markReadPill: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 999,
    flexDirection: "row",
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  markReadPillText: {
    color: megrumColors.lavender,
    fontSize: 11.5,
    fontWeight: "900",
  },
  scopePreviewPill: {
    backgroundColor: "rgba(166,149,216,0.1)",
    borderRadius: 16,
    flex: 1,
    gap: 2,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  scopePreviewLabel: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
  },
  scopePreviewValue: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "800",
  },
  prefectureSelector: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(166,149,216,0.2)",
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    justifyContent: "space-between",
    paddingHorizontal: 16,
    paddingVertical: 13,
  },
  prefectureSelectorPressed: {
    opacity: 0.9,
  },
  prefectureSelectorCopy: {
    gap: 3,
  },
  prefectureSelectorLabel: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
  },
  prefectureSelectorValue: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  loadingBox: {
    alignItems: "center",
    gap: 10,
    paddingVertical: 42,
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
    borderRadius: 20,
    borderWidth: 1,
    gap: 8,
    paddingHorizontal: 18,
    paddingVertical: 28,
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
    lineHeight: 18,
    textAlign: "center",
  },
  section: {
    gap: 10,
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  sectionRows: {
    gap: 12,
  },
  threadCard: {
    backgroundColor: "#fff",
    borderRadius: 20,
    gap: 8,
    paddingHorizontal: 16,
    paddingVertical: 15,
    ...megrumShadow,
  },
  threadCardUnread: {
    borderColor: "rgba(168,212,230,0.55)",
    borderWidth: 1,
  },
  threadCardPressed: {
    opacity: 0.94,
    transform: [{ scale: 0.992 }],
  },
  threadTopRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  threadBadgeRow: {
    alignItems: "center",
    flexDirection: "row",
    flex: 1,
    gap: 6,
  },
  threadTopActions: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  mediaCountBadge: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    flexDirection: "row",
    gap: 3,
    minHeight: 24,
    paddingHorizontal: 8,
  },
  mediaCountText: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  moreButton: {
    alignItems: "center",
    height: 26,
    justifyContent: "center",
    width: 26,
  },
  unreadBadge: {
    backgroundColor: "rgba(168,212,230,0.24)",
    borderRadius: 999,
    minHeight: 24,
    paddingHorizontal: 9,
    justifyContent: "center",
  },
  unreadBadgeText: {
    color: "#4f7e92",
    fontSize: 10.5,
    fontWeight: "900",
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
    fontSize: 10,
    fontWeight: "900",
  },
  threadTime: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "700",
  },
  threadTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
    lineHeight: 22,
  },
  threadBody: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "700",
    lineHeight: 19,
  },
  attachmentGrid: {
    flexDirection: "row",
    gap: 8,
  },
  attachmentGridCompact: {
    flexDirection: "row",
    gap: 7,
  },
  attachmentThumb: {
    aspectRatio: 1,
    borderRadius: 14,
    flex: 1,
    maxHeight: 112,
    minHeight: 80,
    overflow: "hidden",
  },
  attachmentThumbCompact: {
    borderRadius: 12,
    height: 58,
    overflow: "hidden",
    width: 58,
  },
  attachmentImage: {
    height: "100%",
    width: "100%",
  },
  attachmentMoreOverlay: {
    ...StyleSheet.absoluteFillObject,
    alignItems: "center",
    backgroundColor: "rgba(26,20,38,0.44)",
    justifyContent: "center",
  },
  attachmentMoreText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "900",
  },
  threadMeta: {
    color: megrumColors.mutedInk,
    flexShrink: 0,
    fontSize: 11.5,
    fontWeight: "800",
  },
  threadMetaRow: {
    alignItems: "center",
    flexDirection: "row",
    minWidth: 0,
  },
  threadAuthorButton: {
    flexShrink: 1,
  },
  threadAuthorText: {
    color: megrumColors.lavender,
    fontSize: 11.5,
    fontWeight: "900",
  },
  threadFooter: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
  },
  replyPreview: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 12,
    fontWeight: "700",
  },
  replyPreviewUnread: {
    color: "#4f7e92",
    fontWeight: "900",
  },
  replyCount: {
    alignItems: "center",
    flexDirection: "row",
    gap: 4,
  },
  replyCountText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
  },
  metricPill: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    flexDirection: "row",
    gap: 3,
    minHeight: 26,
    paddingHorizontal: 8,
  },
  metricPillActive: {
    backgroundColor: "rgba(166,149,216,0.16)",
  },
  metricPillText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  metricPillTextActive: {
    color: megrumColors.lavender,
  },
  modalLayer: {
    flex: 1,
    justifyContent: "flex-end",
  },
  modalBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(26,20,38,0.18)",
  },
  modalPanel: {
    backgroundColor: megrumColors.surface,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    gap: 16,
    paddingHorizontal: 18,
    paddingTop: 12,
  },
  modalHandle: {
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.12)",
    borderRadius: 999,
    height: 5,
    width: 54,
  },
  modalTitle: {
    color: megrumColors.ink,
    fontSize: 19,
    fontWeight: "900",
  },
  modalSubTitle: {
    color: megrumColors.mutedInk,
    fontSize: 12.5,
    fontWeight: "700",
    marginTop: -10,
  },
  composerDraftStatus: {
    alignItems: "center",
    alignSelf: "flex-start",
    backgroundColor: "rgba(166,149,216,0.1)",
    borderRadius: 999,
    flexDirection: "row",
    gap: 8,
    minHeight: 30,
    paddingLeft: 12,
    paddingRight: 5,
  },
  composerDraftText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  composerDraftDiscard: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 999,
    justifyContent: "center",
    minHeight: 22,
    paddingHorizontal: 9,
  },
  composerDraftDiscardText: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
  field: {
    gap: 8,
  },
  fieldHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  fieldLabel: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  inputCounter: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  attachmentHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  attachmentLimit: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  pickedImageRail: {
    gap: 10,
    paddingRight: 18,
  },
  pickedImageWrap: {
    borderRadius: 16,
    height: 72,
    overflow: "hidden",
    width: 72,
  },
  pickedImage: {
    height: "100%",
    width: "100%",
  },
  removeImageButton: {
    alignItems: "center",
    backgroundColor: "rgba(26,20,38,0.68)",
    borderRadius: 999,
    height: 22,
    justifyContent: "center",
    position: "absolute",
    right: 5,
    top: 5,
    width: 22,
  },
  addImageButton: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.1)",
    borderColor: "rgba(166,149,216,0.28)",
    borderRadius: 16,
    borderWidth: 1,
    gap: 4,
    height: 72,
    justifyContent: "center",
    width: 72,
  },
  addImageText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  composerCategoryGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  composerCategoryChip: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 13,
    paddingVertical: 8,
  },
  composerCategoryChipActive: {
    backgroundColor: "rgba(166,149,216,0.18)",
    borderColor: "rgba(166,149,216,0.44)",
  },
  composerCategoryText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
  },
  composerCategoryTextActive: {
    color: megrumColors.lavender,
  },
  input: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 16,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "700",
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  textarea: {
    minHeight: 116,
  },
  scopeHelp: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "700",
    marginTop: 8,
  },
  errorText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
  },
  modalActions: {
    flexDirection: "row",
    gap: 10,
  },
  modalPrimary: {
    flex: 1,
  },
  modalSecondary: {
    flex: 1,
  },
});
