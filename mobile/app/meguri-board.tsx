import { useCallback, useEffect, useMemo, useState } from "react";
import { router, useFocusEffect, useLocalSearchParams } from "expo-router";
import SegmentedControl from "@react-native-segmented-control/segmented-control";
import {
  ActionSheetIOS,
  ActivityIndicator,
  Alert,
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
import { PrimaryButton } from "../src/components/PrimaryButton";
import { Screen } from "../src/components/Screen";
import {
  MEGURI_BOARD_AUDIENCE_OPTIONS,
  MEGURI_BOARD_CATEGORY_OPTIONS,
  MEGURI_BOARD_COMPOSER_CATEGORY_OPTIONS,
  MEGURI_BOARD_SORT_OPTIONS,
  createMeguriBoardThread,
  filterMeguriBoardThreads,
  hideMeguriBoardThread,
  loadMeguriBoardThreads,
  meguriBoardAudienceLabel,
  meguriBoardAudienceMeta,
  meguriBoardCategoryLabel,
  meguriBoardSortLabel,
  reportMeguriBoardThread,
  setMeguriBoardThreadBookmarked,
  setMeguriBoardThreadReacted,
  setMeguriBoardThreadSubscribed,
  type MeguriBoardActor,
  type MeguriBoardAudienceScope,
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
  const [composerOpen, setComposerOpen] = useState(false);
  const [composerTitle, setComposerTitle] = useState("");
  const [composerBody, setComposerBody] = useState("");
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
    () =>
      filterMeguriBoardThreads(threads, {
        category: categoryFilter,
        query: searchText,
        sort: sortMode,
      }),
    [categoryFilter, searchText, sortMode, threads],
  );

  const sections = useMemo(
    () =>
      [
        {
          key: viewMode,
          title: viewMode === "nearby_3km" ? "近くのスレッド" : "都道府県のスレッド",
          rows: visibleThreads,
        },
      ].filter((section) => section.rows.length > 0),
    [viewMode, visibleThreads],
  );

  const refreshThreads = useCallback(async (prefectureOverride?: string | null) => {
    setLoading(true);
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
    const nextThreads = await loadMeguriBoardThreads(
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
    ).catch(() => []);
    setThreads(nextThreads);
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
    selectedPrefecture,
    user?.id,
    viewMode,
  ]);

  useFocusEffect(
    useCallback(() => {
      void refreshThreads();
    }, [refreshThreads]),
  );

  useEffect(() => {
    if (readParam(params.compose) === "1") {
      setComposerOpen(true);
    }
  }, [params.compose]);

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

  async function reportThread(thread: MeguriBoardThread) {
    updateThreadLocally({ ...thread, reported: true });
    await reportMeguriBoardThread(thread.id);
    Alert.alert("通報しました", "確認して対応します。");
  }

  function openThreadActions(thread: MeguriBoardThread) {
    const labels = [
      thread.bookmarked ? "保存を解除" : "保存する",
      thread.reacted ? "参考になったを取り消す" : "参考になった",
      thread.subscribed ? "通知を止める" : "通知を受け取る",
      "非表示にする",
      thread.reported ? "通報済み" : "通報する",
      "キャンセル",
    ];
    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          cancelButtonIndex: 5,
          destructiveButtonIndex: 3,
          disabledButtonIndices: thread.reported ? [4] : undefined,
          options: labels,
          title: thread.title,
        },
        (index) => {
          if (index === 0) void toggleThreadBookmark(thread);
          if (index === 1) void toggleThreadReaction(thread);
          if (index === 2) void toggleThreadSubscription(thread);
          if (index === 3) void hideThread(thread);
          if (index === 4 && !thread.reported) void reportThread(thread);
        },
      );
      return;
    }
    void toggleThreadBookmark(thread);
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
          <Pressable accessibilityRole="button" onPress={() => setComposerOpen(true)} style={styles.composeButton}>
            <IconSymbol name="add" color="#fff" size={18} />
          </Pressable>
        </View>

        <ScrollView
          contentContainerStyle={[
            styles.content,
            { paddingBottom: Math.max(insets.bottom, 12) + 34 },
          ]}
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
              <Pressable
                key={sort}
                accessibilityRole="button"
                onPress={() => setSortMode(sort)}
                style={[styles.sortButton, sortMode === sort ? styles.sortButtonActive : null]}
              >
                <Text style={[styles.sortButtonText, sortMode === sort ? styles.sortButtonTextActive : null]}>
                  {meguriBoardSortLabel(sort)}
                </Text>
              </Pressable>
            ))}
          </View>

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

          <PrimaryButton onPress={() => setComposerOpen(true)}>スレッドを立てる</PrimaryButton>

          {loading ? (
            <View style={styles.loadingBox}>
              <ActivityIndicator color={megrumColors.lavender} />
              <Text style={styles.loadingText}>掲示板を読み込み中…</Text>
            </View>
          ) : sections.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyTitle}>まだスレッドはありません</Text>
              <Text style={styles.emptyBody}>最初のひとことを置いておくと、あとから返事がつきやすいです。</Text>
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
                      style={({ pressed }) => [
                        styles.threadCard,
                        pressed ? styles.threadCardPressed : null,
                      ]}
                    >
                      <View style={styles.threadTopRow}>
                        <View style={styles.threadBadgeRow}>
                          <CategoryBadge category={thread.category} />
                          <ScopeBadge scope={thread.audienceScope} />
                          {thread.status === "locked" ? <StatusBadge label="締め切り" /> : null}
                          {thread.readAt && thread.readAt >= thread.latestActivityAt ? null : (
                            <View style={styles.unreadDot} />
                          )}
                        </View>
                        <View style={styles.threadTopActions}>
                          <Text style={styles.threadTime}>{formatRelativeTime(thread.latestActivityAt)}</Text>
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
                      <Text numberOfLines={1} style={styles.threadMeta}>
                        {meguriBoardAudienceMeta(thread)} · {thread.authorName}
                      </Text>
                      <View style={styles.threadFooter}>
                        <Text numberOfLines={1} style={styles.replyPreview}>
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

      <Modal animationType="slide" transparent visible={composerOpen} onRequestClose={() => setComposerOpen(false)}>
        <View style={styles.modalLayer}>
          <Pressable style={styles.modalBackdrop} onPress={() => setComposerOpen(false)} />
          <View style={[styles.modalPanel, { paddingBottom: Math.max(insets.bottom, 14) + 12 }]}>
            <View style={styles.modalHandle} />
            <Text style={styles.modalTitle}>新しいスレッド</Text>
            <Text style={styles.modalSubTitle}>作成時の位置を基準に、見える範囲を選びます。</Text>

            <View style={styles.field}>
              <Text style={styles.fieldLabel}>タイトル</Text>
              <TextInput
                maxLength={80}
                onChangeText={setComposerTitle}
                placeholder="例: 物販列いまどれくらい？"
                placeholderTextColor="rgba(58,50,74,0.35)"
                style={styles.input}
                value={composerTitle}
              />
            </View>

            <View style={styles.field}>
              <Text style={styles.fieldLabel}>本文</Text>
              <TextInput
                maxLength={500}
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
                onPress={() => setComposerOpen(false)}
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
  moreButton: {
    alignItems: "center",
    height: 26,
    justifyContent: "center",
    width: 26,
  },
  unreadDot: {
    backgroundColor: megrumColors.sky,
    borderRadius: 999,
    height: 7,
    width: 7,
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
  threadMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
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
  field: {
    gap: 8,
  },
  fieldLabel: {
    color: megrumColors.ink,
    fontSize: 12.5,
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
