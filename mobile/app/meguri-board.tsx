import { useCallback, useEffect, useMemo, useState } from "react";
import { router, useFocusEffect, useLocalSearchParams } from "expo-router";
import SegmentedControl from "@react-native-segmented-control/segmented-control";
import {
  ActivityIndicator,
  Modal,
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
  createMeguriBoardThread,
  loadMeguriBoardThreads,
  meguriBoardAudienceLabel,
  meguriBoardAudienceMeta,
  type MeguriBoardActor,
  type MeguriBoardAudienceScope,
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
  const [threads, setThreads] = useState<MeguriBoardThread[]>([]);
  const [loading, setLoading] = useState(true);
  const [composerOpen, setComposerOpen] = useState(false);
  const [composerTitle, setComposerTitle] = useState("");
  const [composerBody, setComposerBody] = useState("");
  const [composerScope, setComposerScope] = useState<MeguriBoardAudienceScope>("nearby_3km");
  const [composerError, setComposerError] = useState<string | null>(null);
  const [locationContext, setLocationContext] = useState<MegrumLocationContext | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [viewMode, setViewMode] = useState<MeguriBoardViewMode>("nearby_3km");

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
        prefecture: readParam(params.prefecture),
        resolvedPrefecture: locationContext?.prefecture ?? null,
        spotKey: readParam(params.spotKey),
        spotLabel: readParam(params.spotLabel),
        viewerId: user?.id ?? actor.userId,
      }),
    [
      actor.primaryArea,
      actor.userId,
      locationContext?.coordinate,
      locationContext?.prefecture,
      params.prefecture,
      params.spotKey,
      params.spotLabel,
      params.viewerLat,
      params.viewerLng,
      user?.id,
    ],
  );

  const sections = useMemo(
    () =>
      [
        {
          key: viewMode,
          title: viewMode === "nearby_3km" ? "近くのスレッド" : "都道府県のスレッド",
          rows: threads,
        },
      ].filter((section) => section.rows.length > 0),
    [threads, viewMode],
  );

  const refreshThreads = useCallback(async () => {
    setLoading(true);
    const settings = await loadMeguriProfileSettings().catch(() => DEFAULT_MEGURI_PROFILE);
    const currentLocation = await getCurrentLocationContext().catch(() => null);
    setLocationContext(currentLocation);
    setLocalArea(settings.baseArea || DEFAULT_MEGURI_PROFILE.baseArea);
    setLocalDisplayName(settings.displayName || DEFAULT_MEGURI_PROFILE.displayName);
    const nextThreads = await loadMeguriBoardThreads(
      buildViewerContext({
        fallbackArea: profile?.primaryArea || settings.baseArea || actor.primaryArea,
        fallbackCoordinate: currentLocation?.coordinate ?? coordinateFromParams({
          latitude: params.viewerLat,
          longitude: params.viewerLng,
        }),
        prefecture: readParam(params.prefecture),
        resolvedPrefecture: currentLocation?.prefecture ?? null,
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
      resolvedPrefecture: actionLocation?.prefecture ?? viewerContext.prefecture,
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
              {viewerContext.spotLabel} / {viewerContext.prefecture}
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
              いま見えているのは、現在地から3km圏内、または {viewerContext.prefecture || "このエリア"} のスレッドです。
            </Text>
            <View style={styles.heroMetaRow}>
              <ScopePreviewPill label="3km圏内" value={viewerContext.coordinate ? "現在地から表示" : "位置情報待ち"} />
              <ScopePreviewPill label="都道府県" value={viewerContext.prefecture || "未設定"} />
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
                        <ScopeBadge scope={thread.audienceScope} />
                        <Text style={styles.threadTime}>{formatRelativeTime(thread.latestActivityAt)}</Text>
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
                    ? `${viewerContext.prefecture} を拠点に見ている人向け`
                    : `${viewerContext.prefecture} を拠点に見ている人向け`}
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
    input.resolvedPrefecture || input.prefecture || input.fallbackArea || DEFAULT_MEGURI_PROFILE.baseArea;
  const spotLabel = input.spotLabel || `${prefecture}のめぐりスポット`;
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
