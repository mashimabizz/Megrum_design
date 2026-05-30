import {
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  type ComponentType,
  type ReactNode,
} from "react";
import { router } from "expo-router";
import type { SFSymbol, SymbolViewProps } from "expo-symbols";
import { LinearGradient } from "expo-linear-gradient";
import {
  ActionSheetIOS,
  Alert,
  ActivityIndicator,
  Animated,
  AppState,
  Easing,
  Image,
  Keyboard,
  Modal,
  PanResponder,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  useWindowDimensions,
} from "react-native";
import { Screen } from "../../src/components/Screen";
import { HomeFeedSkeleton } from "../../src/components/SkeletonScreen";
import { useAuth } from "../../src/auth/AuthProvider";
import { IconSymbol, type IconSymbolName } from "../../src/components/IconSymbol";
import { LiquidGlassSurface } from "../../src/components/LiquidGlass";
import { useProfileDrawer } from "../../src/components/ProfileDrawerContext";
import { hasSupabaseConfig, supabase } from "../../src/lib/supabase";
import {
  MATCH_SECTIONS,
  buildMatchDetailParams,
  type Candidate,
  type CandidatePriority,
  type ShelfRow,
  type ShelfSection,
} from "../../src/data/homeMatches";
import { fetchHomeSupabaseSections } from "../../src/data/homeSupabase";
import { appendMeguriGroomReply } from "../../src/lib/meguriMessages";
import {
  archiveGroomPost,
  blockGroomUser,
  fetchGroomFeed,
  hideGroomPost,
  isUuidLike,
  markGroomPostViewed,
  reportGroomPost,
  setGroomPostLiked,
  type GroomRemotePost,
} from "../../src/lib/groom";
import {
  NativeMapPreview,
  type MapCoordinate,
} from "../../src/components/NativeMapPreview";
import { GroomProfileSlidePanel, type GroomProfileUser } from "../../src/components/meguri/GroomProfileSlidePanel";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useImageReady } from "../../src/lib/useImageReady";
import { formatHashTags } from "../../src/lib/inventoryTags";
import { useKeyboardInset } from "../../src/lib/useKeyboardInset";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";
import { USERS } from "./encounters";

const FALLBACK_LOCAL_CENTER: MapCoordinate = {
  latitude: 35.6595,
  longitude: 139.7005,
};
const TOP_EDGE_FADE_BANDS = Array.from({ length: 24 }, (_, index) => {
  const t = index / 23;
  const strength = Math.pow(1 - t, 1.9);
  return {
    backgroundColor: `rgba(251,249,252,${(0.74 * strength).toFixed(3)})`,
  };
});
const LOCAL_DURATION_OPTIONS = [
  { label: "1時間", value: 60 },
  { label: "2時間", value: 120 },
  { label: "3時間", value: 180 },
  { label: "6時間", value: 360 },
];
const LOCAL_RADIUS_OPTIONS = [300, 500, 1000, 2000];
const PREVIEW_CARRYING_ITEMS: LocalCarryingItem[] = [
  {
    id: "preview-carry-1",
    title: "スア 春ver.",
    subtitle: "LUMENA / トレカ",
    photoUrl: null,
    hue: "#cbbcf4",
  },
  {
    id: "preview-carry-2",
    title: "ジョンウ ラキドロ",
    subtitle: "LUMENA / トレカ",
    photoUrl: null,
    hue: "#a8d4e6",
  },
  {
    id: "preview-carry-3",
    title: "ニンニン アクスタ",
    subtitle: "aespa / アクスタ",
    photoUrl: null,
    hue: "#f3c5d4",
  },
];
type HomeModeView = "national" | "local";
type LocalCarryingItem = {
  id: string;
  title: string;
  subtitle: string;
  photoUrl: string | null;
  hue: string;
};

type HomeGroomPost = {
  authorId?: string;
  caption: string;
  doodles?: HomeGroomDoodleStroke[];
  id: string;
  imagePath?: string | null;
  imageTransform?: HomeGroomImageTransform;
  imageUri: string;
  liked: boolean;
  name: string;
  stickers?: HomeGroomStickerOverlay[];
  timeLabel: string;
  textOverlays?: HomeGroomTextOverlay[];
  viewed?: boolean;
};

type HomeGroomImageTransform = {
  rotation: number;
  scale: number;
  x: number;
  y: number;
};

type HomeGroomTextOverlay = {
  color: string;
  id: string;
  rotation?: number;
  scale?: number;
  text: string;
  tone: "plain" | "label" | "solid";
  x: number;
  y: number;
};

type HomeGroomStickerOverlay = {
  color: string;
  id: string;
  label: string;
  x: number;
  y: number;
};

type HomeGroomDoodleStroke = {
  color: string;
  id: string;
  points: { x: number; y: number }[];
};

const DEFAULT_HOME_GROOM_IMAGE_TRANSFORM: HomeGroomImageTransform = {
  rotation: 0,
  scale: 1,
  x: 0,
  y: 0,
};

function isDefaultHomeGroomImageTransform(transform?: HomeGroomImageTransform | null) {
  if (!transform) return true;
  return (
    Math.abs(transform.rotation) < 0.001 &&
    Math.abs(transform.scale - 1) < 0.001 &&
    Math.abs(transform.x) < 0.001 &&
    Math.abs(transform.y) < 0.001
  );
}

const HOME_GROOM_POSTS: HomeGroomPost[] = [
  {
    id: "home-groom-michirio",
    imageUri:
      "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=82",
    caption: "淡色コーデでトレカケースも合わせてきた",
    liked: false,
    name: "みち",
    timeLabel: "12分前",
  },
  {
    id: "home-groom-kiko",
    imageUri:
      "https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=82",
    caption: "会場前で少しだけ休憩中",
    liked: true,
    name: "きこ",
    timeLabel: "28分前",
  },
  {
    id: "home-groom-yui",
    imageUri:
      "https://images.unsplash.com/photo-1513201099705-a9746e1e201f?auto=format&fit=crop&w=900&q=82",
    caption: "推し色の小物で来ています",
    liked: false,
    name: "ゆい",
    timeLabel: "41分前",
  },
  {
    id: "home-groom-mai",
    imageUri:
      "https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=900&q=82",
    caption: "交換前に軽く身支度",
    liked: false,
    name: "まい",
    timeLabel: "1時間前",
    viewed: true,
  },
];

const HOME_GROOM_USER_BY_NAME: Record<string, string> = {
  "きこ": "kai_kiko",
  "まい": "idol_mai",
  "みち": "michirio",
  "ゆい": "stage_yui",
};

function remotePostToHomeGroomPost(post: GroomRemotePost): HomeGroomPost {
  return {
    authorId: post.author.id,
    caption: post.caption,
    doodles: post.doodles as HomeGroomDoodleStroke[],
    id: post.id,
    imagePath: post.imagePath,
    imageTransform: post.imageTransform,
    imageUri: post.imageUrl,
    liked: post.liked,
    name: post.mine ? "あなた" : post.author.displayName,
    stickers: post.stickers as HomeGroomStickerOverlay[],
    timeLabel: relativeHomeGroomTimeLabel(post.publishedAt),
    textOverlays: post.textOverlays as HomeGroomTextOverlay[],
    viewed: post.viewed,
  };
}

function relativeHomeGroomTimeLabel(value: string) {
  const publishedAt = Date.parse(value);
  if (!Number.isFinite(publishedAt)) return "たった今";
  const diffMinutes = Math.max(0, Math.floor((Date.now() - publishedAt) / 60000));
  if (diffMinutes < 1) return "たった今";
  if (diffMinutes < 60) return `${diffMinutes}分前`;
  const diffHours = Math.floor(diffMinutes / 60);
  if (diffHours < 24) return `${diffHours}時間前`;
  return "昨日";
}

type SymbolModule = {
  SymbolView: ComponentType<SymbolViewProps>;
};

let cachedSymbolView: ComponentType<SymbolViewProps> | null | undefined;
const ENABLE_NATIVE_HOME_EFFECTS = false;

function getIOSSFSymbolView() {
  if (!ENABLE_NATIVE_HOME_EFFECTS) {
    return null;
  }
  if (Platform.OS !== "ios") {
    return null;
  }
  if (cachedSymbolView !== undefined) {
    return cachedSymbolView;
  }
  try {
    cachedSymbolView = (require("expo-symbols") as SymbolModule).SymbolView;
  } catch {
    cachedSymbolView = null;
  }
  return cachedSymbolView;
}

export default function HomeScreen() {
  const { previewMode, profile, user } = useAuth();
  const { openDrawer } = useProfileDrawer();
  const usePreviewData = previewMode || !hasSupabaseConfig;
  const [localMode, setLocalMode] = useState(usePreviewData);
  const [sections, setSections] = useState<ShelfSection[]>(() =>
    usePreviewData ? MATCH_SECTIONS : [],
  );
  const [placeName, setPlaceName] = useState(
    usePreviewData ? "守口市地区 豊秀町一丁目" : "",
  );
  const [homeLoading, setHomeLoading] = useState(!usePreviewData);
  const [homeError, setHomeError] = useState<string | null>(null);
  const [localSheetOpen, setLocalSheetOpen] = useState(false);
  const [revertLocalOnSheetClose, setRevertLocalOnSheetClose] = useState(false);
  const [modeSwitching, setModeSwitching] = useState<HomeModeView | null>(null);
  const [homeRefreshing, setHomeRefreshing] = useState(false);
  const [homeGroomPosts, setHomeGroomPosts] = useState(HOME_GROOM_POSTS);
  const [selectedHomeGroomId, setSelectedHomeGroomId] = useState<string | null>(null);
  const [homeGroomViewerSession, setHomeGroomViewerSession] = useState(0);
  const [homeGroomReply, setHomeGroomReply] = useState("");
  const [homeGroomFeedback, setHomeGroomFeedback] = useState("");
  const homeGroomToastTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const edgePulse = useRef(new Animated.Value(0)).current;
  const modeSwitchTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const { width } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const tileWidth = (width - 36 - 10 * 2) / 3;
  const homeTopPadding = Math.max(insets.top, 18) + 12;
  const topEdgeFadeHeight = Math.max(insets.top + 22, 68);
  const metadata = user?.user_metadata as Record<string, unknown> | undefined;
  const homeDisplayName =
    profile?.displayName ??
    stringMetadata(metadata?.display_name) ??
    stringMetadata(metadata?.name) ??
    user?.email?.split("@")[0] ??
    "Megrum";
  const homeAvatarUrl =
    profile?.avatarUrl ??
    stringMetadata(metadata?.avatar_url) ??
    stringMetadata(metadata?.picture);
  const selectedHomeGroomPost =
    homeGroomPosts.find((post) => post.id === selectedHomeGroomId) ?? null;
  const visibleSections = useMemo(() => {
    if (!localMode) return sections;
    return sections
      .map((section) => ({
        ...section,
        rows: section.rows
          .map((row) => ({
            ...row,
            candidates: [...row.candidates].sort((a, b) => Number(!!b.local) - Number(!!a.local)),
          }))
          .filter((row) => row.candidates.length > 0),
      }))
      .filter((section) => section.rows.length > 0);
  }, [localMode, sections]);
  async function loadHomeData({
    isActive = () => true,
    showLoading = true,
  }: {
    isActive?: () => boolean;
    showLoading?: boolean;
  } = {}) {
    if (previewMode || !hasSupabaseConfig) {
      if (!isActive()) return;
      setSections(MATCH_SECTIONS);
      setLocalMode(usePreviewData);
      setPlaceName("守口市地区 豊秀町一丁目");
      setHomeLoading(false);
      setHomeError(null);
      return;
    }
    if (!user) {
      if (!isActive()) return;
      setSections([]);
      setLocalMode(false);
      setPlaceName("");
      setHomeLoading(false);
      setHomeError(null);
      return;
    }

    if (showLoading) setHomeLoading(true);
    setHomeError(null);
    try {
      const result = await fetchHomeSupabaseSections(user.id);
      if (!isActive()) return;
      setSections(result.sections.length > 0 ? result.sections : []);
      const nextLocalMode = result.localModeEnabled;
      setLocalMode(nextLocalMode);
      setPlaceName(result.placeLabel ?? "場所未設定");
    } catch (error: unknown) {
      if (!isActive()) return;
      setSections([]);
      setHomeError(error instanceof Error ? error.message : "読み込みに失敗しました");
    } finally {
      if (isActive()) setHomeLoading(false);
    }
  }

  function refreshHomeData() {
    let active = true;
    loadHomeData({ isActive: () => active }).catch(() => undefined);

    return () => {
      active = false;
    };
  }

  useEffect(() => {
    return refreshHomeData();
  }, [previewMode, user]);

  async function refreshHomeGroomPosts() {
    if (previewMode || !user) {
      setHomeGroomPosts(HOME_GROOM_POSTS);
      return;
    }
    const remotePosts = await fetchGroomFeed(user.id);
    setHomeGroomPosts(remotePosts.map(remotePostToHomeGroomPost));
  }

  async function handleHomeRefresh() {
    setHomeRefreshing(true);
    try {
      await Promise.all([
        loadHomeData({ showLoading: false }),
        refreshHomeGroomPosts().catch(() => undefined),
      ]);
    } finally {
      setHomeRefreshing(false);
    }
  }

  useEffect(() => {
    refreshHomeGroomPosts().catch(() => undefined);
  }, [previewMode, user]);

  useEffect(() => {
    if (previewMode || !user) return undefined;
    const subscription = AppState.addEventListener("change", (state) => {
      if (state === "active") refreshHomeGroomPosts().catch(() => undefined);
    });
    return () => subscription.remove();
  }, [previewMode, user]);

  useEffect(() => {
    return () => {
      if (modeSwitchTimerRef.current) {
        clearTimeout(modeSwitchTimerRef.current);
      }
    };
  }, []);

  useEffect(() => {
    if (!localMode) {
      edgePulse.stopAnimation();
      edgePulse.setValue(0);
      return;
    }
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(edgePulse, {
          toValue: 1,
          duration: 1450,
          useNativeDriver: true,
        }),
        Animated.timing(edgePulse, {
          toValue: 0,
          duration: 1350,
          useNativeDriver: true,
        }),
      ]),
    );
    loop.start();
    return () => loop.stop();
  }, [edgePulse, localMode]);

  function showModeSwitchStatus(next: HomeModeView) {
    if (modeSwitchTimerRef.current) {
      clearTimeout(modeSwitchTimerRef.current);
    }
    setModeSwitching(next);
    modeSwitchTimerRef.current = setTimeout(() => {
      setModeSwitching(null);
      modeSwitchTimerRef.current = null;
    }, 820);
  }

  function openLocalModeSheetForEnable() {
    showModeSwitchStatus("local");
    setLocalMode(true);
    setHomeError(null);
    setRevertLocalOnSheetClose(true);
    setLocalSheetOpen(true);
  }

  async function handleLocalEnabledChange(next: boolean) {
    setLocalMode(next);
    setHomeError(null);
    if (next) {
      openLocalModeSheetForEnable();
      return;
    }

    showModeSwitchStatus("national");
    setLocalSheetOpen(false);
    setRevertLocalOnSheetClose(false);
    if (!supabase || !user || usePreviewData) return;
    const { error } = await supabase
      .from("user_local_mode_settings")
      .upsert({ user_id: user.id, enabled: false }, { onConflict: "user_id" });
    if (error) setHomeError(error.message);
  }

  function openHomeActionMenu() {
    const actions = [
      {
        label: localMode ? "現地交換モードをオフにする" : "現地交換モードをオンにする",
        destructive: localMode,
        onPress: () => {
          void handleLocalEnabledChange(!localMode);
        },
      },
      ...(localMode
        ? [
            {
              label: "現地交換情報を編集する",
              onPress: () => {
                setRevertLocalOnSheetClose(false);
                setLocalSheetOpen(true);
              },
            },
          ]
        : []),
    ];
    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          options: [...actions.map((action) => action.label), "閉じる"],
          cancelButtonIndex: actions.length,
          destructiveButtonIndex:
            actions.findIndex((action) => action.destructive) >= 0
              ? actions.findIndex((action) => action.destructive)
              : undefined,
          title: "現地交換",
          userInterfaceStyle: "light",
          tintColor: megrumColors.lavender,
        },
        (buttonIndex) => {
          actions[buttonIndex]?.onPress();
        },
      );
      return;
    }
    const primary = actions[0];
    primary?.onPress();
  }

  function openHomeGroom(postId: string) {
    setHomeGroomViewerSession((current) => current + 1);
    setSelectedHomeGroomId(postId);
    setHomeGroomFeedback("");
    clearHomeGroomToastTimer();
    setHomeGroomPosts((current) =>
      current.map((post) => (post.id === postId ? { ...post, viewed: true } : post)),
    );
    if (user && isUuidLike(postId)) {
      markGroomPostViewed(user.id, postId).catch(() => undefined);
    }
  }

  function closeHomeGroom() {
    setSelectedHomeGroomId(null);
    setHomeGroomReply("");
    setHomeGroomFeedback("");
    clearHomeGroomToastTimer();
  }

  function selectHomeGroom(postId: string) {
    setSelectedHomeGroomId(postId);
    setHomeGroomFeedback("");
    clearHomeGroomToastTimer();
    setHomeGroomPosts((current) =>
      current.map((post) => (post.id === postId ? { ...post, viewed: true } : post)),
    );
    if (user && isUuidLike(postId)) {
      markGroomPostViewed(user.id, postId).catch(() => undefined);
    }
  }

  function toggleHomeGroomLike() {
    if (!selectedHomeGroomId) return;
    const target = homeGroomPosts.find((post) => post.id === selectedHomeGroomId);
    const nextLiked = !target?.liked;
    setHomeGroomPosts((current) =>
      current.map((post) =>
        post.id === selectedHomeGroomId ? { ...post, liked: !post.liked } : post,
      ),
    );
    if (user && isUuidLike(selectedHomeGroomId)) {
      setGroomPostLiked(user.id, selectedHomeGroomId, nextLiked).catch(() => {
        setHomeGroomPosts((current) =>
          current.map((post) =>
            post.id === selectedHomeGroomId ? { ...post, liked: target?.liked ?? false } : post,
          ),
        );
      });
    }
  }

  function removeHomeGroomPostLocally(postId: string) {
    setHomeGroomPosts((current) => current.filter((post) => post.id !== postId));
    if (selectedHomeGroomId === postId) closeHomeGroom();
  }

  function openHomeGroomActions(post: HomeGroomPost) {
    const mine = post.name === "あなた";
    const actions = mine
      ? [
          {
            destructive: true,
            label: "投稿を削除",
            onPress: () => confirmDeleteHomeGroomPost(post),
          },
        ]
      : [
          {
            label: "このグルームを非表示",
            onPress: () => hideHomeGroomPost(post),
          },
          {
            label: "通報する",
            onPress: () => reportHomeGroomPost(post),
          },
          {
            destructive: true,
            label: "このユーザーをブロック",
            onPress: () => confirmBlockHomeGroomAuthor(post),
          },
        ];

    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          cancelButtonIndex: actions.length,
          destructiveButtonIndex:
            actions.findIndex((action) => action.destructive) >= 0
              ? actions.findIndex((action) => action.destructive)
              : undefined,
          options: [...actions.map((action) => action.label), "閉じる"],
          title: "グルーム",
          userInterfaceStyle: "dark",
          tintColor: megrumColors.lavender,
        },
        (buttonIndex) => actions[buttonIndex]?.onPress(),
      );
      return;
    }

    actions[0]?.onPress();
  }

  function confirmDeleteHomeGroomPost(post: HomeGroomPost) {
    Alert.alert("グルームを削除しますか？", "この投稿は一覧から表示されなくなります。", [
      { style: "cancel", text: "キャンセル" },
      {
        onPress: () => deleteHomeGroomPost(post),
        style: "destructive",
        text: "削除",
      },
    ]);
  }

  async function deleteHomeGroomPost(post: HomeGroomPost) {
    removeHomeGroomPostLocally(post.id);
    if (!user || !isUuidLike(post.id)) return;
    try {
      await archiveGroomPost(user.id, post.id);
    } catch {
      Alert.alert("削除できませんでした", "通信状況を確認して、もう一度お試しください。");
      refreshHomeGroomPosts().catch(() => undefined);
    }
  }

  async function hideHomeGroomPost(post: HomeGroomPost) {
    removeHomeGroomPostLocally(post.id);
    if (!user || !isUuidLike(post.id)) return;
    try {
      await hideGroomPost(user.id, post.id);
    } catch {
      Alert.alert("非表示にできませんでした", "通信状況を確認して、もう一度お試しください。");
      refreshHomeGroomPosts().catch(() => undefined);
    }
  }

  async function reportHomeGroomPost(post: HomeGroomPost) {
    const authorId = homeGroomProfileId(post);
    removeHomeGroomPostLocally(post.id);
    if (!user || !isUuidLike(post.id) || !isUuidLike(authorId)) return;
    try {
      await reportGroomPost(user.id, post.id, authorId);
      await hideGroomPost(user.id, post.id);
      Alert.alert("通報しました", "このグルームは非表示にしました。");
    } catch {
      Alert.alert("通報できませんでした", "通信状況を確認して、もう一度お試しください。");
      refreshHomeGroomPosts().catch(() => undefined);
    }
  }

  function confirmBlockHomeGroomAuthor(post: HomeGroomPost) {
    const authorId = homeGroomProfileId(post);
    if (!authorId) return;
    Alert.alert(`${post.name}さんをブロックしますか？`, "相手のグルームとめぐりあいメッセージが表示されにくくなります。", [
      { style: "cancel", text: "キャンセル" },
      {
        onPress: () => blockHomeGroomAuthor(post),
        style: "destructive",
        text: "ブロック",
      },
    ]);
  }

  async function blockHomeGroomAuthor(post: HomeGroomPost) {
    const authorId = homeGroomProfileId(post);
    setHomeGroomPosts((current) => current.filter((item) => homeGroomProfileId(item) !== authorId));
    closeHomeGroom();
    if (!user || !isUuidLike(authorId)) return;
    try {
      await blockGroomUser(user.id, authorId);
    } catch {
      Alert.alert("ブロックできませんでした", "通信状況を確認して、もう一度お試しください。");
      refreshHomeGroomPosts().catch(() => undefined);
    }
  }

  function clearHomeGroomToastTimer() {
    if (!homeGroomToastTimerRef.current) return;
    clearTimeout(homeGroomToastTimerRef.current);
    homeGroomToastTimerRef.current = null;
  }

  async function sendHomeGroomReply() {
    const post = selectedHomeGroomPost;
    const body = homeGroomReply.trim();
    if (!post || !body) return;
    setHomeGroomReply("");
    setHomeGroomFeedback("メッセージが送信されました");
    clearHomeGroomToastTimer();
    homeGroomToastTimerRef.current = setTimeout(() => {
      setHomeGroomFeedback("");
      homeGroomToastTimerRef.current = null;
    }, 1800);
    try {
      await appendMeguriGroomReply({
        body,
        groomCaption: post.caption,
        groomId: post.id,
        groomImagePath: post.imagePath ?? null,
        groomImageUri: post.imageUri,
        recipientId: post.authorId ?? HOME_GROOM_USER_BY_NAME[post.name] ?? post.id,
        recipientName: post.name,
      });
    } catch {
      // 送信UIは維持し、ローカル保存の失敗だけ握りつぶす。
    }
  }

  return (
    <Screen
      bottomInset={false}
      scroll={false}
      topInset={false}
      topPadding={homeTopPadding}
      contentStyle={styles.screenContent}
    >
      <HomeHeader
        avatarUrl={homeAvatarUrl}
        displayName={homeDisplayName}
        onOpenDrawer={openDrawer}
      />
      <ScrollView
        automaticallyAdjustsScrollIndicatorInsets
        contentInsetAdjustmentBehavior="automatic"
        showsVerticalScrollIndicator={false}
        style={styles.homeScroll}
        contentContainerStyle={styles.homeScrollContent}
        refreshControl={
          <RefreshControl
            refreshing={homeRefreshing}
            onRefresh={handleHomeRefresh}
            tintColor={megrumColors.lavender}
          />
        }
        scrollEventThrottle={16}
      >
        {homeError ? <Text style={styles.inlineError}>{homeError}</Text> : null}
        <HomeGroomRail onOpen={openHomeGroom} posts={homeGroomPosts} />
        {homeLoading ? (
          <HomeFeedSkeleton />
        ) : (
          <>
            {visibleSections.length > 0 ? (
              visibleSections.map((section, sectionIndex) => [
                <StickySectionHeader
                  key={`${section.id}-header`}
                  title={section.id === "possible" ? "交換できるかも？" : section.title}
                />,
                <ShelfSectionRows
                  key={`${section.id}-rows`}
                  section={section}
                  sectionIndex={sectionIndex}
                  tileWidth={tileWidth}
                  localMode={localMode}
                  onCandidatePress={openHomeCandidate}
                />,
              ])
            ) : (
              <View style={styles.emptyMatches}>
                <Text style={styles.emptyMatchesTitle}>まだ候補がありません</Text>
                <Text style={styles.emptyMatchesText}>
                  Wish と譲る候補が増えると、ここに交換候補が並びます。
                </Text>
              </View>
            )}
          </>
        )}
      </ScrollView>
      <TopEdgeFade height={topEdgeFadeHeight} />
      {localMode ? <LocalFocusVignette pulse={edgePulse} /> : null}
      <FloatingSearchButton />
      <FloatingHomeActionButton
        localMode={localMode}
        onPress={openHomeActionMenu}
      />
      {selectedHomeGroomPost ? (
        <HomeGroomViewerModal
          key={`home-groom-viewer-${homeGroomViewerSession}`}
          feedback={homeGroomFeedback}
          onChangeReply={setHomeGroomReply}
          onClose={closeHomeGroom}
          onLike={toggleHomeGroomLike}
          onOpenActions={openHomeGroomActions}
          onSelectPost={selectHomeGroom}
          onSendReply={sendHomeGroomReply}
          post={selectedHomeGroomPost}
          posts={homeGroomPosts}
          reply={homeGroomReply}
        />
      ) : null}
      {modeSwitching ? (
        <View pointerEvents="none" style={styles.modeStatusPill}>
          <Text style={styles.modeStatusText}>
            {modeSwitching === "local"
              ? "今すぐ現地交換モードに切り替え中…"
              : "全国交換モードに切り替え中…"}
          </Text>
        </View>
      ) : null}
      <LocalModeSheet
        open={localSheetOpen}
        previewMode={usePreviewData}
        userId={user?.id ?? null}
        placeName={placeName}
        onClose={() => {
          setLocalSheetOpen(false);
          if (revertLocalOnSheetClose) {
            setRevertLocalOnSheetClose(false);
            handleLocalEnabledChange(false);
          }
        }}
        onApplied={(nextPlace) => {
          setRevertLocalOnSheetClose(false);
          setLocalSheetOpen(false);
          setLocalMode(true);
          setPlaceName(nextPlace);
          refreshHomeData();
        }}
        onError={setHomeError}
      />
    </Screen>
  );
}

function HomeHeader({
  avatarUrl,
  displayName,
  onOpenDrawer,
}: {
  avatarUrl?: string | null;
  displayName: string;
  onOpenDrawer: () => void;
}) {
  return (
    <View style={styles.homeHeader}>
      <Pressable
        accessibilityLabel="プロフィールメニューを開く"
        accessibilityRole="button"
        onPress={onOpenDrawer}
        style={({ pressed }) => [
          styles.homeHeaderAvatarButton,
          pressed ? styles.homeHeaderAvatarPressed : null,
        ]}
      >
        {avatarUrl ? (
          <Image source={{ uri: avatarUrl }} style={styles.homeHeaderAvatarImage} />
        ) : (
          <Text style={styles.homeHeaderAvatarText}>
            {displayName.slice(0, 1).toUpperCase()}
          </Text>
        )}
      </Pressable>
      <Text style={styles.homeHeaderLogo}>Megrum</Text>
      <View pointerEvents="none" style={styles.homeHeaderSpacer} />
    </View>
  );
}

function LocalModeSheet({
  open,
  previewMode,
  userId,
  placeName,
  onClose,
  onApplied,
  onError,
}: {
  open: boolean;
  previewMode: boolean;
  userId: string | null;
  placeName: string;
  onClose: () => void;
  onApplied: (placeName: string) => void;
  onError: (message: string | null) => void;
}) {
  const initialVenue = placeName === "場所未設定" ? "" : placeName;
  const [venue, setVenue] = useState(initialVenue);
  const [center, setCenter] = useState<MapCoordinate>(FALLBACK_LOCAL_CENTER);
  const [radiusM, setRadiusM] = useState(500);
  const [durationMin, setDurationMin] = useState(120);
  const [carryingItems, setCarryingItems] = useState<LocalCarryingItem[]>([]);
  const [selectedCarryingIds, setSelectedCarryingIds] = useState<string[]>([]);
  const [pending, setPending] = useState(false);
  const [locating, setLocating] = useState(false);
  const [sheetError, setSheetError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    let active = true;
    setVenue(initialVenue);
    setSheetError(null);
    setPending(false);

    async function loadLocalMode() {
      if (!supabase || !userId || previewMode) {
        setCarryingItems(PREVIEW_CARRYING_ITEMS);
        setSelectedCarryingIds(PREVIEW_CARRYING_ITEMS.slice(0, 2).map((item) => item.id));
        if (!initialVenue) {
          const coordinate = await getCurrentCoordinate();
          if (!active || !coordinate) return;
          setCenter(coordinate);
          const label = await reverseGeocodeLabel(coordinate);
          if (active && label) setVenue(label);
        }
        return;
      }
      let resolvedCenter: MapCoordinate | null = null;
      const { data: settings } = await supabase
        .from("user_local_mode_settings")
        .select("aw_id, radius_m, last_lat, last_lng, selected_carrying_ids")
        .eq("user_id", userId)
        .maybeSingle();
      if (!active) return;

      const settingsRow = settings as
        | {
            aw_id?: string | null;
            radius_m?: number | null;
            last_lat?: number | string | null;
            last_lng?: number | string | null;
            selected_carrying_ids?: string[] | null;
          }
        | null;
      if (settingsRow?.radius_m) setRadiusM(settingsRow.radius_m);
      setSelectedCarryingIds(settingsRow?.selected_carrying_ids ?? []);
      const lastLat = toNumber(settingsRow?.last_lat);
      const lastLng = toNumber(settingsRow?.last_lng);
      if (lastLat != null && lastLng != null) {
        resolvedCenter = { latitude: lastLat, longitude: lastLng };
        setCenter(resolvedCenter);
      }

      if (settingsRow?.aw_id) {
        const { data: aw } = await supabase
          .from("activity_windows")
          .select("venue, start_at, end_at, radius_m, center_lat, center_lng")
          .eq("id", settingsRow.aw_id)
          .eq("user_id", userId)
          .maybeSingle();
        if (!active) return;
        if (aw) {
          const awRow = aw as {
            venue?: string | null;
            start_at?: string | null;
            end_at?: string | null;
            radius_m?: number | null;
            center_lat?: number | string | null;
            center_lng?: number | string | null;
          };
          if (awRow.venue) setVenue(awRow.venue);
          if (awRow.radius_m) setRadiusM(awRow.radius_m);
          const lat = toNumber(awRow.center_lat);
          const lng = toNumber(awRow.center_lng);
          if (lat != null && lng != null) {
            resolvedCenter = { latitude: lat, longitude: lng };
            setCenter(resolvedCenter);
          }
          if (awRow.start_at && awRow.end_at) {
            const minutes = Math.max(
              30,
              Math.round(
                (new Date(awRow.end_at).getTime() -
                  new Date(awRow.start_at).getTime()) /
                  60_000,
              ),
            );
            setDurationMin(minutes);
          }
        }
      }

      if (!resolvedCenter) {
        const coordinate = await getCurrentCoordinate();
        if (!active || !coordinate) return;
        setCenter(coordinate);
        const label = await reverseGeocodeLabel(coordinate);
        if (active && label && !initialVenue) setVenue(label);
      }

      const items = await fetchLocalCarryingItems(userId);
      if (active) setCarryingItems(items);
    }

    loadLocalMode();
    return () => {
      active = false;
    };
  }, [open, initialVenue, previewMode, userId]);

  async function useCurrentLocation() {
    setLocating(true);
    setSheetError(null);
    const coordinate = await getCurrentCoordinate();
    setLocating(false);
    if (!coordinate) {
      setSheetError("現在地を取得できませんでした");
      return;
    }
    setCenter(coordinate);
    const label = await reverseGeocodeLabel(coordinate);
    if (label) setVenue(label);
  }

  async function applySettings() {
    const trimmedVenue = venue.trim();
    if (!trimmedVenue) {
      setSheetError("交換場所を入力してください");
      return;
    }
    if (!supabase || !userId || previewMode) {
      onApplied(trimmedVenue);
      return;
    }
    setPending(true);
    setSheetError(null);
    const result = await applyLocalModeSettings({
      userId,
      venue: trimmedVenue,
      center,
      radiusM,
      durationMin,
      selectedCarryingIds,
    });
    setPending(false);
    if (result?.error) {
      setSheetError(result.error);
      onError(result.error);
      return;
    }
    onError(null);
    onApplied(trimmedVenue);
  }

  const radiusLabel = radiusM >= 1000 ? `${radiusM / 1000}km` : `${radiusM}m`;
  const selectedCarryingCount = selectedCarryingIds.length;
  const nativeSheet = Platform.OS === "ios";

  return (
    <Modal
      animationType="slide"
      onRequestClose={onClose}
      presentationStyle={nativeSheet ? "pageSheet" : "overFullScreen"}
      transparent={!nativeSheet}
      visible={open}
    >
      <View style={[styles.localSheetLayer, nativeSheet ? styles.localSheetNativeLayer : null]}>
        {!nativeSheet ? (
          <Pressable
            accessibilityLabel="閉じる"
            accessibilityRole="button"
            onPress={onClose}
            style={styles.localSheetBackdrop}
          />
        ) : null}
        <View style={[styles.localSheet, nativeSheet ? styles.localSheetNativePanel : null]}>
          <View style={styles.localSheetHandle} />
          <View style={styles.localSheetHeader}>
            <View>
              <Text style={styles.localSheetKicker}>LOCAL MODE</Text>
              <Text style={styles.localSheetTitle}>現地交換モード</Text>
            </View>
            <Pressable
              accessibilityLabel="閉じる"
              accessibilityRole="button"
              onPress={onClose}
              style={styles.localSheetClose}
            >
              <Text style={styles.localSheetCloseText}>×</Text>
            </Pressable>
          </View>
          <Text style={styles.localSheetLead}>
            場所・時間・範囲を設定して、近くで交換できる候補を探します。
          </Text>

          <ScrollView
            showsVerticalScrollIndicator={false}
            contentContainerStyle={styles.localSheetBody}
          >
            <View style={styles.localSection}>
              <View style={styles.localSectionHeader}>
                <Text style={styles.localSectionTitle}>交換場所</Text>
                <Pressable
                  disabled={locating}
                  onPress={useCurrentLocation}
                  style={styles.currentLocationButton}
                >
                  <Text style={styles.currentLocationText}>
                    {locating ? "取得中…" : "現在地"}
                  </Text>
                </Pressable>
              </View>
              <NativeMapPreview
                key={`${center.latitude}-${center.longitude}`}
                center={center}
                height={184}
                interactive
                markers={[
                  {
                    id: "local-center",
                    coordinate: center,
                    label: "●",
                    title: venue || "交換場所",
                  },
                ]}
                onPress={async (coordinate) => {
                  setCenter(coordinate);
                  const label = await reverseGeocodeLabel(coordinate);
                  if (label) setVenue(label);
                }}
                style={styles.localMap}
              />
              <TextInput
                onChangeText={setVenue}
                placeholder="場所を選ぶと自動で入ります"
                placeholderTextColor="rgba(58,50,74,0.38)"
                style={styles.localInput}
                value={venue}
              />
            </View>

            <View style={styles.localSection}>
              <Text style={styles.localSectionTitle}>
                有効時間 / {durationMin}分
              </Text>
              <View style={styles.localChipRow}>
                {LOCAL_DURATION_OPTIONS.map((option) => (
                  <Pressable
                    key={option.value}
                    onPress={() => setDurationMin(option.value)}
                    style={[
                      styles.localChip,
                      durationMin === option.value ? styles.localChipActive : null,
                    ]}
                  >
                    <Text
                      style={[
                        styles.localChipText,
                        durationMin === option.value
                          ? styles.localChipTextActive
                          : null,
                      ]}
                    >
                      {option.label}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>

            <View style={styles.localSection}>
              <Text style={styles.localSectionTitle}>
                マッチ範囲 / {radiusLabel}
              </Text>
              <View style={styles.localChipRow}>
                {LOCAL_RADIUS_OPTIONS.map((option) => (
                  <Pressable
                    key={option}
                    onPress={() => setRadiusM(option)}
                    style={[
                      styles.localChip,
                      radiusM === option ? styles.localChipActive : null,
                    ]}
                  >
                    <Text
                      style={[
                        styles.localChipText,
                        radiusM === option ? styles.localChipTextActive : null,
                      ]}
                    >
                      {option >= 1000 ? `${option / 1000}km` : `${option}m`}
                    </Text>
                  </Pressable>
                ))}
              </View>
            </View>

            <View style={styles.localSection}>
              <View style={styles.localSectionHeader}>
                <Text style={styles.localSectionTitle}>持参するグッズ</Text>
                <Text style={styles.localSectionMeta}>
                  {selectedCarryingCount} / {carryingItems.length}
                </Text>
              </View>
              {carryingItems.length > 0 ? (
                <ScrollView
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  contentContainerStyle={styles.carryingScroller}
                >
                  {carryingItems.map((item) => {
                    const selected = selectedCarryingIds.includes(item.id);
                    return (
                      <Pressable
                        key={item.id}
                        onPress={() => {
                          setSelectedCarryingIds((current) =>
                            current.includes(item.id)
                              ? current.filter((id) => id !== item.id)
                              : [...current, item.id],
                          );
                        }}
                        style={[
                          styles.carryingCard,
                          selected ? styles.carryingCardActive : null,
                        ]}
                      >
                        <View
                          style={[
                            styles.carryingThumb,
                            { backgroundColor: item.photoUrl ? megrumColors.ink : item.hue },
                          ]}
                        >
                          {item.photoUrl ? (
                            <Image
                              source={{ uri: item.photoUrl }}
                              resizeMode="cover"
                              style={styles.carryingImage}
                            />
                          ) : (
                            <Text style={styles.carryingGlyph}>
                              {item.title.slice(0, 1)}
                            </Text>
                          )}
                          <View
                            style={[
                              styles.carryingCheck,
                              selected ? styles.carryingCheckActive : null,
                            ]}
                          >
                            <Text
                              style={[
                                styles.carryingCheckText,
                                selected ? styles.carryingCheckTextActive : null,
                              ]}
                            >
                              {selected ? "✓" : "+"}
                            </Text>
                          </View>
                        </View>
                        <Text numberOfLines={1} style={styles.carryingTitle}>
                          {item.title}
                        </Text>
                        <Text numberOfLines={1} style={styles.carryingSub}>
                          {item.subtitle}
                        </Text>
                      </Pressable>
                    );
                  })}
                </ScrollView>
              ) : (
                <View style={styles.carryingEmpty}>
                  <Text style={styles.carryingEmptyText}>
                    譲る候補の在庫を登録すると、ここで持参グッズを選べます。
                  </Text>
                </View>
              )}
            </View>

            {sheetError ? (
              <View style={styles.localSheetError}>
                <Text style={styles.localSheetErrorText}>{sheetError}</Text>
              </View>
            ) : null}
          </ScrollView>

          <View style={styles.localSheetActions}>
            <Pressable
              disabled={pending}
              onPress={onClose}
              style={styles.localCancelButton}
            >
              <Text style={styles.localCancelText}>キャンセル</Text>
            </Pressable>
            <Pressable
              disabled={pending || !venue.trim()}
              onPress={applySettings}
              style={[
                styles.localApplyButton,
                pending || !venue.trim() ? styles.localApplyButtonDisabled : null,
              ]}
            >
              <Text style={styles.localApplyText}>
                {pending ? "適用中…" : "この設定で表示"}
              </Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}

function FloatingHomeActionButton({
  localMode,
  onPress,
}: {
  localMode: boolean;
  onPress: () => void;
}) {
  const symbolColor = localMode ? megrumColors.lavender : megrumColors.ink;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel="現地交換メニュー"
      onPress={onPress}
      style={({ pressed }) => [
        styles.homeActionButton,
        localMode ? styles.homeActionButtonLive : null,
        pressed ? styles.homeActionButtonPressed : null,
      ]}
    >
      <HomeActionGlass active={localMode} />
      <View style={styles.homeActionIconLayer}>
        <NativeHomeActionSymbol
          color={symbolColor}
          fallbackName="time-outline"
          name={localMode ? "location.circle.fill" : "location.circle"}
        />
      </View>
    </Pressable>
  );
}

function HomeActionGlass({ active }: { active: boolean }) {
  return (
    <LiquidGlassSurface
      glassEffectStyle={{
        style: active ? "regular" : "clear",
        animate: true,
        animationDuration: 0.2,
      }}
      isInteractive
      pointerEvents="none"
      style={StyleSheet.absoluteFillObject}
      fallbackStyle={styles.homeActionFallbackGlass}
      tintColor={active ? "rgba(166,149,216,0.24)" : "rgba(255,255,255,0.12)"}
    />
  );
}

function NativeHomeActionSymbol({
  color,
  fallbackName,
  name,
}: {
  color: string;
  fallbackName: IconSymbolName;
  name: SFSymbol;
}) {
  const SymbolView = getIOSSFSymbolView();
  if (SymbolView) {
    return (
      <SymbolView
        fallback={<IconSymbol color={color} name={fallbackName} size={26} />}
        name={name}
        size={31}
        tintColor={color}
        type="hierarchical"
        weight="semibold"
      />
    );
  }
  return <IconSymbol color={color} name={fallbackName} size={26} />;
}

function LocalFocusVignette({ pulse }: { pulse: Animated.Value }) {
  const opacity = pulse.interpolate({
    inputRange: [0, 1],
    outputRange: [0.32, 0.58],
  });
  const scaleX = pulse.interpolate({
    inputRange: [0, 1],
    outputRange: [1, 1.08],
  });
  return (
    <View pointerEvents="none" style={styles.localFocusLayer}>
      <Animated.View
        style={[styles.localFocusEdge, styles.localFocusLeft, { opacity, transform: [{ scaleX }] }]}
      />
      <Animated.View
        style={[styles.localFocusEdge, styles.localFocusRight, { opacity, transform: [{ scaleX }] }]}
      />
    </View>
  );
}

function FloatingSearchButton() {
  return (
    <Pressable
      accessibilityLabel="検索"
      accessibilityRole="button"
      onPress={() => router.push("/search")}
      style={({ pressed }) => [
        styles.floatingSearchButton,
        pressed ? styles.floatingSearchButtonPressed : null,
      ]}
    >
      <View pointerEvents="none" style={styles.floatingSearchGlassClip}>
        <LiquidGlassSurface
          blurIntensity={70}
          glassEffectStyle={{
            style: "clear",
            animate: true,
            animationDuration: 0.22,
          }}
          isInteractive
          pointerEvents="none"
          style={StyleSheet.absoluteFillObject}
          fallbackStyle={styles.floatingSearchFallback}
          tintColor="rgba(255,255,255,0.2)"
        />
        <View pointerEvents="none" style={styles.floatingSearchOverlay} />
        <LinearGradient
          colors={[
            "rgba(255,255,255,0.92)",
            "rgba(255,255,255,0.34)",
            "rgba(255,255,255,0.04)",
          ]}
          end={{ x: 0.94, y: 0.96 }}
          pointerEvents="none"
          start={{ x: 0.12, y: 0.06 }}
          style={styles.floatingSearchSpecular}
        />
        <View pointerEvents="none" style={styles.floatingSearchInnerGlow} />
        <View style={styles.floatingSearchIconLayer}>
          <View style={styles.searchGlyph}>
            <View style={styles.searchGlyphRing} />
            <View style={styles.searchGlyphHandle} />
          </View>
        </View>
      </View>
    </Pressable>
  );
}

function StickySectionHeader({ title }: { title: string }) {
  return (
    <View style={styles.stickySectionHeader}>
      <Text style={styles.sectionTitle}>{title}</Text>
    </View>
  );
}

function HomeGroomRail({
  onOpen,
  posts,
}: {
  onOpen: (postId: string) => void;
  posts: HomeGroomPost[];
}) {
  return (
    <View style={styles.homeGroomRail}>
      <Text style={styles.homeGroomTitle}>グルーム</Text>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.homeGroomList}
      >
        <Pressable
          accessibilityLabel="グルームを追加"
          accessibilityRole="button"
          onPress={() => router.push("/encounters")}
          style={styles.homeGroomItem}
        >
          <View style={[styles.homeGroomRing, styles.homeGroomAddRing]}>
            <View style={styles.homeGroomAddCircle}>
              <IconSymbol name="add" color={megrumColors.lavender} size={27} />
            </View>
          </View>
          <Text numberOfLines={1} style={styles.homeGroomName}>
            追加
          </Text>
        </Pressable>

        {posts.map((post) => (
          <Pressable
            accessibilityLabel={`${post.name}のグルームを見る`}
            accessibilityRole="button"
            key={post.id}
            onPress={() => onOpen(post.id)}
            style={styles.homeGroomItem}
          >
            <View
              style={[
                styles.homeGroomRing,
                post.liked ? styles.homeGroomRingLiked : null,
                post.viewed ? styles.homeGroomRingViewed : null,
              ]}
            >
              <Image source={{ uri: post.imageUri }} style={styles.homeGroomImage} />
            </View>
            <Text numberOfLines={1} style={styles.homeGroomName}>
              {post.name}
            </Text>
          </Pressable>
        ))}
      </ScrollView>
    </View>
  );
}

function HomeGroomViewerModal({
  feedback,
  onChangeReply,
  onClose,
  onLike,
  onOpenActions,
  onSelectPost,
  onSendReply,
  post,
  posts,
  reply,
}: {
  feedback: string;
  onChangeReply: (value: string) => void;
  onClose: () => void;
  onLike: () => void;
  onOpenActions: (post: HomeGroomPost) => void;
  onSelectPost: (postId: string) => void;
  onSendReply: () => void;
  post: HomeGroomPost | null;
  posts: HomeGroomPost[];
  reply: string;
}) {
  const insets = useSafeAreaInsets();
  const keyboardInset = useKeyboardInset();
  const { height, width } = useWindowDimensions();
  const progress = useRef(new Animated.Value(0)).current;
  const progressValueRef = useRef(0);
  const replyInputRef = useRef<TextInput>(null);
  const swipeX = useRef(new Animated.Value(0)).current;
  const dismissY = useRef(new Animated.Value(0)).current;
  const gestureMode = useRef<"horizontal" | "vertical" | null>(null);
  const [replyFocused, setReplyFocused] = useState(false);
  const [horizontalSwiping, setHorizontalSwiping] = useState(false);
  const [readyImageKeys, setReadyImageKeys] = useState<Set<string>>(() => new Set());
  const horizontalSwipingRef = useRef(false);
  const [profileUser, setProfileUser] = useState<GroomProfileUser | null>(null);
  const canSend = reply.trim().length > 0;
  const currentIndex = post ? posts.findIndex((item) => item.id === post.id) : -1;
  const currentImageReady = post ? readyImageKeys.has(homeGroomImageReadyKey(post)) : false;
  const previousPost = currentIndex > 0 ? posts[currentIndex - 1] ?? null : null;
  const nextPost =
    currentIndex >= 0 && currentIndex < posts.length - 1 ? posts[currentIndex + 1] ?? null : null;

  function markImageReady(postToMark: HomeGroomPost) {
    const key = homeGroomImageReadyKey(postToMark);
    setReadyImageKeys((current) => {
      if (current.has(key)) return current;
      const next = new Set(current);
      next.add(key);
      return next;
    });
  }

  function commitRelativePost(offset: -1 | 1) {
    if (currentIndex < 0) return;
    const nextIndex = currentIndex + offset;
    if (nextIndex < 0) return;
    if (nextIndex >= posts.length) {
      onClose();
      return;
    }
    const next = posts[nextIndex];
    if (next) onSelectPost(next.id);
  }

  function setHorizontalSwipeActive(active: boolean) {
    if (horizontalSwipingRef.current === active) return;
    horizontalSwipingRef.current = active;
    setHorizontalSwiping(active);
    if (active) {
      progress.stopAnimation((value) => {
        progressValueRef.current = value;
      });
    }
  }

  function selectRelativePost(offset: -1 | 1) {
    if (currentIndex < 0) return;
    const nextIndex = currentIndex + offset;
    if (nextIndex < 0) return;
    if (nextIndex >= posts.length) {
      onClose();
      return;
    }
    finishSwipe(offset);
  }

  function finishSwipe(offset: -1 | 1) {
    setHorizontalSwipeActive(true);
    const toValue = offset > 0 ? -width : width;
    Animated.timing(swipeX, {
      toValue,
      duration: 240,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: false,
    }).start(({ finished }) => {
      if (!finished) return;
      setHorizontalSwipeActive(false);
      commitRelativePost(offset);
    });
  }

  function resetSwipe() {
    Animated.spring(swipeX, {
      toValue: 0,
      damping: 20,
      stiffness: 220,
      useNativeDriver: false,
    }).start(() => {
      setHorizontalSwipeActive(false);
    });
  }

  function closeWithDismiss() {
    Animated.timing(dismissY, {
      toValue: height,
      duration: 210,
      easing: Easing.in(Easing.cubic),
      useNativeDriver: false,
    }).start(({ finished }) => {
      if (!finished) return;
      onClose();
    });
  }

  function resetDismiss() {
    Animated.spring(dismissY, {
      toValue: 0,
      damping: 20,
      stiffness: 220,
      useNativeDriver: false,
    }).start();
  }

  function dismissReplyInput() {
    replyInputRef.current?.blur();
    setReplyFocused(false);
    Keyboard.dismiss();
  }

  function sendReplyAndDismiss() {
    dismissReplyInput();
    onSendReply();
  }

  function openProfileFromGroom(postToOpen: HomeGroomPost) {
    dismissReplyInput();
    setProfileUser(homeGroomProfileUser(postToOpen));
  }

  function focusReplyInputAfterProfile() {
    setTimeout(() => {
      replyInputRef.current?.focus();
    }, 120);
  }

  const panResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: (_, gesture) => {
          const horizontal =
            Math.abs(gesture.dx) > 12 && Math.abs(gesture.dx) > Math.abs(gesture.dy) * 1.18;
          const vertical = gesture.dy > 12 && gesture.dy > Math.abs(gesture.dx) * 1.18;
          return horizontal || vertical;
        },
        onPanResponderGrant: () => {
          gestureMode.current = null;
        },
        onPanResponderMove: (_, gesture) => {
          if (!gestureMode.current) {
            gestureMode.current =
              gesture.dy > Math.abs(gesture.dx) * 1.18 ? "vertical" : "horizontal";
          }
          if (gestureMode.current === "vertical") {
            dismissY.setValue(Math.max(0, gesture.dy));
            return;
          }
          setHorizontalSwipeActive(true);
          swipeX.setValue(Math.max(-width, Math.min(width, gesture.dx)));
        },
        onPanResponderRelease: (_, gesture) => {
          if (gestureMode.current === "vertical") {
            if (gesture.dy > 88 || gesture.vy > 0.9) closeWithDismiss();
            else resetDismiss();
            setHorizontalSwipeActive(false);
            gestureMode.current = null;
            return;
          }
          if (gesture.dx < -62 && nextPost) {
            finishSwipe(1);
            gestureMode.current = null;
            return;
          }
          if (gesture.dx > 62 && previousPost) {
            finishSwipe(-1);
            gestureMode.current = null;
            return;
          }
          resetSwipe();
          gestureMode.current = null;
        },
        onPanResponderTerminate: () => {
          if (gestureMode.current === "vertical") {
            resetDismiss();
            setHorizontalSwipeActive(false);
          } else {
            resetSwipe();
          }
          gestureMode.current = null;
        },
      }),
    [height, nextPost, previousPost, width],
  );

  useEffect(() => {
    const listenerId = progress.addListener(({ value }) => {
      progressValueRef.current = value;
    });
    return () => progress.removeListener(listenerId);
  }, [progress]);

  useLayoutEffect(() => {
    swipeX.setValue(0);
    dismissY.setValue(0);
    progress.stopAnimation();
    progressValueRef.current = 0;
    progress.setValue(0);
  }, [dismissY, post?.id, progress, swipeX]);

  useEffect(() => {
    let animation: Animated.CompositeAnimation | null = null;
    let cancelled = false;

    progress.stopAnimation((value) => {
      progressValueRef.current = value;
      if (cancelled || !post || !currentImageReady || replyFocused || profileUser || horizontalSwiping) return;

      const currentValue = Math.max(0, Math.min(0.99, value));
      animation = Animated.timing(progress, {
        toValue: 1,
        duration: Math.max(250, Math.round((1 - currentValue) * 20000)),
        easing: Easing.linear,
        useNativeDriver: false,
      });
      animation.start(({ finished }) => {
        if (finished && !cancelled && !replyFocused) selectRelativePost(1);
      });
    });

    return () => {
      cancelled = true;
      animation?.stop();
      progress.stopAnimation((value) => {
        progressValueRef.current = value;
      });
    };
  }, [currentImageReady, horizontalSwiping, post?.id, profileUser, progress, replyFocused]);

  useEffect(() => {
    const hideSubscription = Keyboard.addListener("keyboardDidHide", () => {
      setReplyFocused(false);
    });
    return () => hideSubscription.remove();
  }, []);

  const dismissDragY = dismissY.interpolate({
    inputRange: [0, height * 0.72],
    outputRange: [0, height * 0.26],
    extrapolate: "clamp",
  });
  const dismissScale = dismissY.interpolate({
    inputRange: [0, height * 0.72],
    outputRange: [1, 0.18],
    extrapolate: "clamp",
  });
  const dismissOpacity = dismissY.interpolate({
    inputRange: [0, height * 0.55],
    outputRange: [1, 0],
    extrapolate: "clamp",
  });
  const backdropOpacity = dismissY.interpolate({
    inputRange: [0, height * 0.55],
    outputRange: [0.48, 0],
    extrapolate: "clamp",
  });
  const staticChromeOpacity = swipeX.interpolate({
    inputRange: [-2, 0, 2],
    outputRange: [0, 1, 0],
    extrapolate: "clamp",
  });
  const chromeTopPadding = Math.max(insets.top, 14) + 8;
  const chromeFooterBottom = Math.max(insets.bottom, 12) + 10 + keyboardInset;
  const currentChrome = post && currentImageReady ? (
    <HomeGroomStoryAttachedChrome
      canSend={canSend}
      footerBottom={chromeFooterBottom}
      headerTop={chromeTopPadding}
      post={post}
      progress={progress}
      progressIndex={Math.max(currentIndex, 0)}
      progressPosts={posts}
      reply={reply}
    />
  ) : null;

  return (
    <Modal
      animationType="fade"
      transparent
      visible={!!post}
      onRequestClose={() => {
        if (profileUser) {
          setProfileUser(null);
          return;
        }
        onClose();
      }}
    >
      {post ? (
        <View style={styles.homeGroomViewer}>
          <Animated.View
            pointerEvents="none"
            style={[styles.homeGroomViewerBackdrop, { opacity: backdropOpacity }]}
          />
          <Animated.View
            style={[
              styles.homeGroomViewerFrame,
              {
                opacity: dismissOpacity,
                transform: [{ translateY: dismissDragY }, { scale: dismissScale }],
              },
            ]}
            {...panResponder.panHandlers}
          >
            <HomeGroomStoryCube
              currentChrome={currentChrome}
              currentPost={post}
              imageReadyKeys={readyImageKeys}
              nextChrome={
                nextPost && readyImageKeys.has(homeGroomImageReadyKey(nextPost)) ? (
                  <HomeGroomStoryAttachedChrome
                    canSend={false}
                    footerBottom={chromeFooterBottom}
                    headerTop={chromeTopPadding}
                    post={nextPost}
                    progressIndex={Math.max(currentIndex + 1, 0)}
                    progressPosts={posts}
                    reply=""
                  />
                ) : null
              }
              nextPost={nextPost}
              onImageReady={markImageReady}
              previousChrome={
                previousPost && readyImageKeys.has(homeGroomImageReadyKey(previousPost)) ? (
                  <HomeGroomStoryAttachedChrome
                    canSend={false}
                    footerBottom={chromeFooterBottom}
                    headerTop={chromeTopPadding}
                    post={previousPost}
                    progressIndex={Math.max(currentIndex - 1, 0)}
                    progressPosts={posts}
                    reply=""
                  />
                ) : null
              }
              previousPost={previousPost}
              swipeX={swipeX}
              width={width}
            />

            {currentImageReady ? (
              <Animated.View
                style={[
                  styles.homeGroomViewerHeader,
                  { opacity: staticChromeOpacity, paddingTop: chromeTopPadding },
                ]}
              >
                <HomeGroomProgressBar currentIndex={Math.max(currentIndex, 0)} posts={posts} progress={progress} />
                <View style={styles.homeGroomViewerHeaderRow}>
                  <Pressable
                    accessibilityLabel={`${post.name}のめぐりプロフィールを開く`}
                    accessibilityRole="button"
                    onPress={() => openProfileFromGroom(post)}
                    style={({ pressed }) => [
                      styles.homeGroomViewerAuthor,
                      styles.homeGroomViewerAuthorInRow,
                      pressed ? styles.homeGroomViewerAuthorPressed : null,
                    ]}
                  >
                    <View style={[styles.homeGroomViewerFace, post.liked ? styles.homeGroomViewerFaceLiked : null]}>
                      <Text style={styles.homeGroomViewerFaceText}>{post.name.slice(0, 1)}</Text>
                    </View>
                    <View style={styles.homeGroomViewerNameWrap}>
                      <Text numberOfLines={1} style={styles.homeGroomViewerName}>{post.name}</Text>
                      <Text numberOfLines={1} style={styles.homeGroomViewerMeta}>{post.timeLabel}</Text>
                    </View>
                  </Pressable>
                  <Pressable
                    accessibilityLabel="グルームのメニューを開く"
                    accessibilityRole="button"
                    onPress={() => onOpenActions(post)}
                    style={styles.homeGroomViewerMenuButton}
                  >
                    <IconSymbol name="ellipsis-horizontal" color="#fff" size={25} />
                  </Pressable>
                </View>
              </Animated.View>
            ) : null}

            <View pointerEvents="box-none" style={styles.homeGroomTapLayer}>
              <Pressable
                accessibilityLabel="前のグルームへ"
                accessibilityRole="button"
                onPress={() => selectRelativePost(-1)}
                style={styles.homeGroomTapZone}
              />
              <Pressable
                accessibilityLabel="次のグルームへ"
                accessibilityRole="button"
                onPress={() => selectRelativePost(1)}
                style={styles.homeGroomTapZone}
              />
            </View>

            {currentImageReady && post.caption.trim() ? (
              <Animated.View style={[styles.homeGroomCaptionPanel, { opacity: staticChromeOpacity }]}>
                {post.caption.trim() ? (
                  <Text style={styles.homeGroomCaptionText}>{post.caption}</Text>
                ) : null}
              </Animated.View>
            ) : null}

            {currentImageReady && feedback ? (
              <View pointerEvents="none" style={styles.homeGroomCenterToast}>
                <Text style={styles.homeGroomCenterToastText}>{feedback}</Text>
              </View>
            ) : null}

            {currentImageReady && replyFocused ? (
              <Pressable
                accessibilityLabel="メッセージ入力を閉じる"
                accessibilityRole="button"
                onPress={dismissReplyInput}
                style={[
                  styles.homeGroomInputDimmer,
                  { bottom: Math.max(insets.bottom, 12) + 78 + keyboardInset },
                ]}
              />
            ) : null}

            {currentImageReady ? (
              <Animated.View
                style={[
                  styles.homeGroomViewerFooter,
                  { opacity: staticChromeOpacity, paddingBottom: chromeFooterBottom },
                ]}
              >
                <View style={styles.homeGroomReplyRow}>
                  <TextInput
                    maxLength={180}
                    multiline
                    onBlur={() => setReplyFocused(false)}
                    onChangeText={onChangeReply}
                    onFocus={() => setReplyFocused(true)}
                    placeholder="メッセージを送信..."
                    placeholderTextColor="rgba(255,255,255,0.78)"
                    ref={replyInputRef}
                    scrollEnabled={false}
                    style={styles.homeGroomReplyInput}
                    value={reply}
                  />
                  <Pressable
                    accessibilityLabel={post.liked ? "いいねを取り消す" : "いいねする"}
                    accessibilityRole="button"
                    onPress={onLike}
                    style={styles.homeGroomViewerAction}
                  >
                    <IconSymbol
                      name={post.liked ? "heart" : "heart-outline"}
                      color={post.liked ? megrumColors.pink : "#fff"}
                      size={31}
                    />
                  </Pressable>
                  <Pressable
                    accessibilityLabel="メッセージを送信"
                    accessibilityRole="button"
                    disabled={!canSend}
                    onPress={sendReplyAndDismiss}
                    style={[styles.homeGroomViewerAction, !canSend ? styles.homeGroomSendButtonDisabled : null]}
                  >
                    <IconSymbol name="send-outline" color="#fff" size={31} />
                  </Pressable>
                </View>
              </Animated.View>
            ) : null}

            <GroomProfileSlidePanel
              onClose={() => setProfileUser(null)}
              onReply={focusReplyInputAfterProfile}
              user={profileUser}
            />
          </Animated.View>
        </View>
      ) : null}
    </Modal>
  );
}

function homeGroomProfileId(post: HomeGroomPost) {
  return post.authorId ?? HOME_GROOM_USER_BY_NAME[post.name] ?? post.id;
}

function homeGroomProfileUser(post: HomeGroomPost): GroomProfileUser {
  const profileId = homeGroomProfileId(post);
  const matchedUser = USERS.find((user) => user.id === profileId);
  if (matchedUser) return matchedUser;
  return {
    animalType: "cat",
    area: "イベント周辺",
    count: 1,
    furColor: "lavender",
    group: "公開プロフィール",
    hitokoto: post.caption,
    hue: "lav",
    id: profileId,
    name: post.name,
    oshi: "推し",
    recent: post.caption,
    since: post.timeLabel,
    style: "推し活",
  };
}

function homeGroomImageReadyKey(post: HomeGroomPost) {
  return `${post.id}:${post.imageUri}`;
}

function HomeGroomImageLoadingOverlay() {
  return (
    <View pointerEvents="none" style={styles.homeGroomImageLoadingOverlay}>
      <ActivityIndicator color="#fff" size="large" />
    </View>
  );
}

function HomeGroomStoryCube({
  currentPost,
  currentChrome,
  imageReadyKeys,
  nextPost,
  nextChrome,
  onImageReady,
  previousPost,
  previousChrome,
  swipeX,
  width,
}: {
  currentPost: HomeGroomPost;
  currentChrome?: ReactNode;
  imageReadyKeys: ReadonlySet<string>;
  nextPost: HomeGroomPost | null;
  nextChrome?: ReactNode;
  onImageReady: (post: HomeGroomPost) => void;
  previousPost: HomeGroomPost | null;
  previousChrome?: ReactNode;
  swipeX: Animated.Value;
  width: number;
}) {
  const perspective = Math.max(width * 1.28, 620);
  const seamOverlap = 1;
  const currentToNextLeft = swipeX.interpolate({
    inputRange: [-width, -width * 0.5, 0],
    outputRange: [-width + seamOverlap, -width * 0.5 + seamOverlap, 0],
    extrapolate: "clamp",
  });
  const currentToNextRotateY = swipeX.interpolate({
    inputRange: [-width, 0],
    outputRange: ["-90deg", "0deg"],
    extrapolate: "clamp",
  });
  const currentToNextOpacity = swipeX.interpolate({
    inputRange: [-width, -1, 0, 1],
    outputRange: [0, 1, 1, 0],
    extrapolate: "clamp",
  });
  const currentToNextShadeOpacity = swipeX.interpolate({
    inputRange: [-width, -width * 0.5, 0],
    outputRange: [0.34, 0.2, 0],
    extrapolate: "clamp",
  });
  const currentToNextChromeOpacity = swipeX.interpolate({
    inputRange: [-width, -1, 0],
    outputRange: [1, 1, 0],
    extrapolate: "clamp",
  });
  const currentToPreviousLeft = swipeX.interpolate({
    inputRange: [0, width * 0.5, width],
    outputRange: [0, width * 0.5 - seamOverlap, width - seamOverlap],
    extrapolate: "clamp",
  });
  const currentToPreviousRotateY = swipeX.interpolate({
    inputRange: [0, width],
    outputRange: ["0deg", "90deg"],
    extrapolate: "clamp",
  });
  const currentToPreviousOpacity = swipeX.interpolate({
    inputRange: [-1, 0, 1, width],
    outputRange: [0, 1, 1, 0],
    extrapolate: "clamp",
  });
  const currentToPreviousShadeOpacity = swipeX.interpolate({
    inputRange: [0, width * 0.5, width],
    outputRange: [0, 0.2, 0.34],
    extrapolate: "clamp",
  });
  const currentToPreviousChromeOpacity = swipeX.interpolate({
    inputRange: [0, 1, width],
    outputRange: [0, 1, 1],
    extrapolate: "clamp",
  });
  const nextLeft = swipeX.interpolate({
    inputRange: [-width, -width * 0.5, 0],
    outputRange: [0, width * 0.5 - seamOverlap, width - seamOverlap],
    extrapolate: "clamp",
  });
  const nextRotateY = swipeX.interpolate({
    inputRange: [-width, 0],
    outputRange: ["0deg", "90deg"],
    extrapolate: "clamp",
  });
  const nextOpacity = swipeX.interpolate({
    inputRange: [-width, -1, 0],
    outputRange: [1, 1, 0],
    extrapolate: "clamp",
  });
  const nextShadeOpacity = swipeX.interpolate({
    inputRange: [-width, -width * 0.5, 0],
    outputRange: [0, 0.2, 0.34],
    extrapolate: "clamp",
  });
  const previousLeft = swipeX.interpolate({
    inputRange: [0, width * 0.5, width],
    outputRange: [-width + seamOverlap, -width * 0.5 + seamOverlap, 0],
    extrapolate: "clamp",
  });
  const previousRotateY = swipeX.interpolate({
    inputRange: [0, width],
    outputRange: ["-90deg", "0deg"],
    extrapolate: "clamp",
  });
  const previousOpacity = swipeX.interpolate({
    inputRange: [0, 1, width],
    outputRange: [0, 1, 1],
    extrapolate: "clamp",
  });
  const previousShadeOpacity = swipeX.interpolate({
    inputRange: [0, width * 0.5, width],
    outputRange: [0.34, 0.2, 0],
    extrapolate: "clamp",
  });

  return (
    <View style={styles.homeGroomStoryStage}>
      {previousPost ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.homeGroomStoryFace,
            {
              left: previousLeft,
              opacity: previousOpacity,
              transform: [{ perspective }, { rotateY: previousRotateY }],
              transformOrigin: "right center",
              width,
              zIndex: 2,
            },
          ]}
        >
          <HomeGroomStoryFaceContent
            chrome={previousChrome}
            imageReady={imageReadyKeys.has(homeGroomImageReadyKey(previousPost))}
            onImageReady={() => onImageReady(previousPost)}
            post={previousPost}
            shadeOpacity={previousShadeOpacity}
          />
        </Animated.View>
      ) : null}
      {nextPost ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.homeGroomStoryFace,
            {
              left: nextLeft,
              opacity: nextOpacity,
              transform: [{ perspective }, { rotateY: nextRotateY }],
              transformOrigin: "left center",
              width,
              zIndex: 2,
            },
          ]}
        >
          <HomeGroomStoryFaceContent
            chrome={nextChrome}
            imageReady={imageReadyKeys.has(homeGroomImageReadyKey(nextPost))}
            onImageReady={() => onImageReady(nextPost)}
            post={nextPost}
            shadeOpacity={nextShadeOpacity}
          />
        </Animated.View>
      ) : null}
      <Animated.View
        pointerEvents="none"
        style={[
          styles.homeGroomStoryFace,
          {
            left: currentToNextLeft,
            opacity: currentToNextOpacity,
            transform: [{ perspective }, { rotateY: currentToNextRotateY }],
            transformOrigin: "right center",
            width,
            zIndex: 3,
          },
        ]}
      >
        <HomeGroomStoryFaceContent
          chrome={currentChrome}
          chromeOpacity={currentToNextChromeOpacity}
          imageReady={imageReadyKeys.has(homeGroomImageReadyKey(currentPost))}
          onImageReady={() => onImageReady(currentPost)}
          post={currentPost}
          shadeOpacity={currentToNextShadeOpacity}
        />
      </Animated.View>
      <Animated.View
        pointerEvents="none"
        style={[
          styles.homeGroomStoryFace,
          {
            left: currentToPreviousLeft,
            opacity: currentToPreviousOpacity,
            transform: [{ perspective }, { rotateY: currentToPreviousRotateY }],
            transformOrigin: "left center",
            width,
            zIndex: 3,
          },
        ]}
      >
        <HomeGroomStoryFaceContent
          chrome={currentChrome}
          chromeOpacity={currentToPreviousChromeOpacity}
          imageReady={imageReadyKeys.has(homeGroomImageReadyKey(currentPost))}
          onImageReady={() => onImageReady(currentPost)}
          post={currentPost}
          shadeOpacity={currentToPreviousShadeOpacity}
        />
      </Animated.View>
    </View>
  );
}

function HomeGroomStoryFaceContent({
  chrome,
  chromeOpacity = 1,
  imageReady,
  onImageReady,
  post,
  shadeOpacity,
}: {
  chrome?: ReactNode;
  chromeOpacity?: number | Animated.AnimatedInterpolation<number>;
  imageReady: boolean;
  onImageReady: () => void;
  post: HomeGroomPost;
  shadeOpacity?: number | Animated.AnimatedInterpolation<number>;
}) {
  return (
    <>
      <HomeGroomStoryImageLayer onReady={onImageReady} transform={post.imageTransform} uri={post.imageUri} />
      {imageReady ? (
        <HomeGroomStoryDecorations
          doodles={post.doodles ?? []}
          stickers={post.stickers ?? []}
          textOverlays={post.textOverlays ?? []}
        />
      ) : (
        <HomeGroomImageLoadingOverlay />
      )}
      {imageReady && shadeOpacity !== undefined ? (
        <Animated.View
          pointerEvents="none"
          style={[styles.homeGroomStoryCubeShade, { opacity: shadeOpacity }]}
        />
      ) : null}
      {imageReady && chrome ? (
        <Animated.View
          pointerEvents="none"
          style={[StyleSheet.absoluteFillObject, { opacity: chromeOpacity }]}
        >
          {chrome}
        </Animated.View>
      ) : null}
    </>
  );
}

function HomeGroomStoryImageLayer({
  onReady,
  transform,
  uri,
}: {
  onReady?: () => void;
  transform?: HomeGroomImageTransform;
  uri: string;
}) {
  const [canvasSize, setCanvasSize] = useState({ height: 1, width: 1 });
  const [imageSize, setImageSize] = useState({ height: 16, width: 9 });
  const safeTransform = transform ?? DEFAULT_HOME_GROOM_IMAGE_TRANSFORM;

  useEffect(() => {
    let mounted = true;
    Image.getSize(
      uri,
      (width, height) => {
        if (mounted && width > 0 && height > 0) setImageSize({ height, width });
      },
      () => {
        if (mounted) setImageSize({ height: 16, width: 9 });
      },
    );
    return () => {
      mounted = false;
    };
  }, [uri]);

  if (!transform || isDefaultHomeGroomImageTransform(transform)) {
    return <Image onLoadEnd={onReady} resizeMode="cover" source={{ uri }} style={StyleSheet.absoluteFillObject} />;
  }

  const canvasWidth = Math.max(canvasSize.width, 1);
  const canvasHeight = Math.max(canvasSize.height, 1);
  const imageAspect = Math.max(imageSize.width, 1) / Math.max(imageSize.height, 1);
  const canvasAspect = canvasWidth / canvasHeight;
  const frameWidth = imageAspect >= canvasAspect ? canvasHeight * imageAspect : canvasWidth;
  const frameHeight = imageAspect >= canvasAspect ? canvasHeight : canvasWidth / imageAspect;
  const left = (canvasWidth - frameWidth) / 2;
  const top = (canvasHeight - frameHeight) / 2;

  return (
    <View
      onLayout={(event) => {
        const { height, width } = event.nativeEvent.layout;
        setCanvasSize({ height, width });
      }}
      style={StyleSheet.absoluteFillObject}
    >
      <View pointerEvents="none" style={styles.homeGroomStoryBackdrop} />
      <Animated.View
        style={[
          styles.homeGroomStoryImageFrame,
          {
            height: frameHeight,
            left,
            top,
            width: frameWidth,
            transform: [
              { translateX: safeTransform.x * canvasWidth },
              { translateY: safeTransform.y * canvasHeight },
              { rotate: `${safeTransform.rotation}deg` },
              { scale: safeTransform.scale },
            ],
          },
        ]}
      >
        <Image onLoadEnd={onReady} resizeMode="cover" source={{ uri }} style={StyleSheet.absoluteFillObject} />
      </Animated.View>
    </View>
  );
}

function HomeGroomStoryDecorations({
  doodles,
  stickers,
  textOverlays,
}: {
  doodles: HomeGroomDoodleStroke[];
  stickers: HomeGroomStickerOverlay[];
  textOverlays: HomeGroomTextOverlay[];
}) {
  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFillObject}>
      {doodles.map((stroke) =>
        stroke.points.map((point, index) => (
          <View
            key={`${stroke.id}-${index}`}
            style={[
              styles.homeGroomDoodleDot,
              {
                backgroundColor: stroke.color,
                left: `${point.x * 100}%`,
                top: `${point.y * 100}%`,
              },
            ]}
          />
        )),
      )}
      {textOverlays.map((overlay) => (
        <View
          key={overlay.id}
          style={[
            styles.homeGroomStoryTextOverlay,
            overlay.tone === "label"
              ? styles.homeGroomStoryTextOverlayLabel
              : overlay.tone === "solid"
                ? styles.homeGroomStoryTextOverlaySolid
                : null,
            {
              left: `${overlay.x * 100}%`,
              top: `${overlay.y * 100}%`,
              transform: [{ rotate: `${overlay.rotation ?? 0}deg` }, { scale: overlay.scale ?? 1 }],
            },
          ]}
        >
          <Text
            numberOfLines={3}
            style={[
              styles.homeGroomStoryTextOverlayText,
              { color: overlay.tone === "solid" ? megrumColors.ink : overlay.color },
            ]}
          >
            {overlay.text}
          </Text>
        </View>
      ))}
      {stickers.map((sticker) => (
        <View
          key={sticker.id}
          style={[
            styles.homeGroomStoryStickerOverlay,
            {
              borderColor: sticker.color,
              left: `${sticker.x * 100}%`,
              top: `${sticker.y * 100}%`,
            },
          ]}
        >
          <Text style={[styles.homeGroomStoryStickerText, { color: sticker.color }]}>
            {sticker.label}
          </Text>
        </View>
      ))}
    </View>
  );
}

function HomeGroomStoryAttachedChrome({
  canSend,
  footerBottom,
  headerTop,
  post,
  progress,
  progressIndex = 0,
  progressPosts,
  reply,
}: {
  canSend: boolean;
  footerBottom: number;
  headerTop: number;
  post: HomeGroomPost;
  progress?: Animated.Value;
  progressIndex?: number;
  progressPosts?: HomeGroomPost[];
  reply: string;
}) {
  const posts = progressPosts?.length ? progressPosts : [post];
  return (
    <>
      <View style={[styles.homeGroomViewerHeader, { paddingTop: headerTop }]}>
        {progress ? (
          <HomeGroomProgressBar currentIndex={progressIndex} posts={posts} progress={progress} />
        ) : (
          <HomeGroomAttachedProgressBar currentIndex={progressIndex} posts={posts} />
        )}
        <View style={styles.homeGroomViewerAuthor}>
          <View style={[styles.homeGroomViewerFace, post.liked ? styles.homeGroomViewerFaceLiked : null]}>
            <Text style={styles.homeGroomViewerFaceText}>{post.name.slice(0, 1)}</Text>
          </View>
          <View style={styles.homeGroomViewerNameWrap}>
            <Text numberOfLines={1} style={styles.homeGroomViewerName}>
              {post.name}
            </Text>
            <Text numberOfLines={1} style={styles.homeGroomViewerMeta}>
              {post.timeLabel}
            </Text>
          </View>
        </View>
      </View>

      {post.caption.trim() ? (
        <View style={styles.homeGroomCaptionPanel}>
          <Text style={styles.homeGroomCaptionText}>{post.caption}</Text>
        </View>
      ) : null}

      <View style={[styles.homeGroomViewerFooter, { paddingBottom: footerBottom }]}>
        <View style={styles.homeGroomReplyRow}>
          <View style={styles.homeGroomReplyGhost}>
            <Text numberOfLines={1} style={styles.homeGroomReplyGhostText}>
              {reply.trim() || "メッセージを送信..."}
            </Text>
          </View>
          <View style={styles.homeGroomViewerAction}>
            <IconSymbol name={post.liked ? "heart" : "heart-outline"} color={post.liked ? megrumColors.pink : "#fff"} size={31} />
          </View>
          <View style={[styles.homeGroomViewerAction, !canSend ? styles.homeGroomSendButtonDisabled : null]}>
            <IconSymbol name="send-outline" color="#fff" size={31} />
          </View>
        </View>
      </View>
    </>
  );
}

function HomeGroomAttachedProgressBar({
  currentIndex,
  posts,
}: {
  currentIndex: number;
  posts: HomeGroomPost[];
}) {
  return (
    <View style={styles.homeGroomProgressRow}>
      {posts.map((item, index) => (
        <View key={item.id} style={styles.homeGroomProgressTrack}>
          <View style={[styles.homeGroomProgressFill, { width: index < currentIndex ? "100%" : "0%" }]} />
        </View>
      ))}
    </View>
  );
}

function HomeGroomProgressBar({
  currentIndex,
  posts,
  progress,
}: {
  currentIndex: number;
  posts: HomeGroomPost[];
  progress: Animated.Value;
}) {
  return (
    <View style={styles.homeGroomProgressRow}>
      {posts.map((item, index) => (
        <HomeGroomProgressSegment
          active={index === currentIndex}
          done={index < currentIndex}
          key={item.id}
          progress={progress}
        />
      ))}
    </View>
  );
}

function HomeGroomProgressSegment({
  active,
  done,
  progress,
}: {
  active: boolean;
  done: boolean;
  progress: Animated.Value;
}) {
  const [width, setWidth] = useState(0);
  const animatedWidth = active
    ? progress.interpolate({
        inputRange: [0, 1],
        outputRange: [0, width],
        extrapolate: "clamp",
      })
    : done
      ? width
      : 0;

  return (
    <View
      onLayout={(event) => setWidth(event.nativeEvent.layout.width)}
      style={styles.homeGroomProgressTrack}
    >
      <Animated.View style={[styles.homeGroomProgressFill, { width: animatedWidth }]} />
    </View>
  );
}

function TopEdgeFade({
  height,
}: {
  height: number;
}) {
  return (
    <View pointerEvents="none" style={[styles.topEdgeFade, { height }]}>
      {TOP_EDGE_FADE_BANDS.map((band, index) => (
        <View
          key={`top-edge-fade-${index}`}
          style={[styles.topEdgeFadeBand, band]}
        />
      ))}
    </View>
  );
}

function ShelfSectionRows({
  section,
  sectionIndex,
  tileWidth,
  localMode,
  onCandidatePress,
}: {
  section: ShelfSection;
  sectionIndex: number;
  tileWidth: number;
  localMode: boolean;
  onCandidatePress: (
    section: ShelfSection,
    row: ShelfRow,
    candidate: Candidate,
  ) => void;
}) {
  const entries = section.rows.flatMap((row) =>
    row.candidates.map((candidate) => ({ candidate, row })),
  );

  return (
    <View style={styles.shelfSectionRows}>
      <View style={styles.homeCandidateGrid}>
        {entries.map(({ candidate, row }, index) => (
          <AnimatedCandidateTile
            key={`${row.id}-${candidate.id}`}
            candidate={candidate}
            delayMs={sectionIndex * 120 + index * 35}
            width={tileWidth}
            localMode={localMode}
            onPress={() => onCandidatePress(section, row, candidate)}
          />
        ))}
      </View>
    </View>
  );
}

function AnimatedCandidateTile({
  candidate,
  delayMs,
  width,
  localMode,
  onPress,
}: {
  candidate: Candidate;
  delayMs: number;
  width: number;
  localMode: boolean;
  onPress: () => void;
}) {
  const appear = useRef(new Animated.Value(0)).current;
  const mountedAt = useRef(Date.now()).current;
  const hasAnimated = useRef(false);
  const imageReady = useImageReady(candidate.photoUrl);

  useEffect(() => {
    if (!imageReady || hasAnimated.current) return;
    const remainingDelay = Math.max(0, delayMs - (Date.now() - mountedAt));
    const timer = setTimeout(() => {
      hasAnimated.current = true;
      Animated.timing(appear, {
        toValue: 1,
        duration: 520,
        useNativeDriver: true,
      }).start();
    }, remainingDelay);

    return () => clearTimeout(timer);
  }, [appear, delayMs, imageReady, mountedAt]);

  const translateY = appear.interpolate({
    inputRange: [0, 1],
    outputRange: [14, 0],
  });
  const scale = appear.interpolate({
    inputRange: [0, 1],
    outputRange: [0.96, 1],
  });

  return (
    <Animated.View
      pointerEvents={imageReady ? "auto" : "none"}
      style={{
        opacity: appear,
        transform: [{ translateY }, { scale }],
        width,
      }}
    >
      <CandidateTile
        candidate={candidate}
        width={width}
        localMode={localMode}
        onPress={onPress}
      />
    </Animated.View>
  );
}

function CandidateTile({
  candidate,
  width,
  localMode,
  onPress,
}: {
  candidate: Candidate;
  width: number;
  localMode: boolean;
  onPress: () => void;
}) {
  const showLocal = localMode && candidate.local;
  const tagLine = formatHashTags(candidate.tagLabels ?? (candidate.tag ? [candidate.tag] : []));
  const frameStyle = useMemo(
    () => getPriorityFrameStyle(candidate.priority),
    [candidate.priority],
  );

  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.tileHitArea,
        showLocal ? styles.tileHitAreaLocal : null,
        { width },
      ]}
    >
      {showLocal ? <LocalAura /> : null}
      <View style={[styles.tileCard, frameStyle, { width, height: width * 1.34 }]}>
        <View
          style={[
            styles.fakeImage,
            {
              backgroundColor: candidate.hue,
            },
          ]}
        >
          {candidate.photoUrl ? (
            <Image
              resizeMode="cover"
              source={{ uri: candidate.photoUrl }}
              style={styles.realImage}
            />
          ) : (
            <>
              <View style={styles.fakeImageGlow} />
              <Text style={styles.fakeImageLetter}>{candidate.member}</Text>
            </>
          )}
        </View>
        {showLocal ? (
          <View style={styles.liveBadge}>
            <Text style={styles.liveBadgeText}>LIVE</Text>
          </View>
        ) : null}
        {tagLine ? (
          <View style={styles.tagOverlay}>
            <Text numberOfLines={1} style={styles.tagText}>
              {tagLine}
            </Text>
          </View>
        ) : null}
      </View>
    </Pressable>
  );
}

function openHomeCandidate(
  section: ShelfSection,
  row: ShelfRow,
  candidate: Candidate,
) {
  if (section.id === "possible") {
    router.push({
      pathname: "/user-profile",
      params: { id: candidate.partnerId ?? candidate.id },
    });
    return;
  }

  router.push({
    pathname: "/match-detail",
    params: buildMatchDetailParams(row, candidate),
  });
}

type LocalModeActionResult = { error?: string } | undefined;

function toNumber(value: unknown) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function stringMetadata(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

async function getCurrentCoordinate(): Promise<MapCoordinate | null> {
  try {
    const Location = await import("expo-location");
    const permission = await Location.requestForegroundPermissionsAsync();
    if (permission.status !== "granted") return null;
    const position = await Location.getCurrentPositionAsync({
      accuracy: Location.Accuracy.Balanced,
    });
    return {
      latitude: position.coords.latitude,
      longitude: position.coords.longitude,
    };
  } catch {
    return null;
  }
}

async function reverseGeocodeLabel(coordinate: MapCoordinate) {
  try {
    const Location = await import("expo-location");
    const results = await Location.reverseGeocodeAsync(coordinate);
    const first = results[0];
    if (!first) return null;
    return (
      first.name ||
      first.street ||
      first.district ||
      first.subregion ||
      first.city ||
      first.region ||
      null
    );
  } catch {
    return null;
  }
}

async function applyLocalModeSettings(input: {
  userId: string;
  venue: string;
  center: MapCoordinate;
  radiusM: number;
  durationMin: number;
  selectedCarryingIds: string[];
}): Promise<LocalModeActionResult> {
  if (!supabase) return undefined;
  const venue = input.venue.trim();
  if (!venue || venue.length > 100) {
    return { error: "場所名を入力してください（1〜100文字）" };
  }
  if (input.radiusM < 50 || input.radiusM > 5000) {
    return { error: "半径は50m〜5000mで指定してください" };
  }

  const start = new Date();
  const end = new Date(
    start.getTime() + Math.max(30, input.durationMin) * 60_000,
  );
  const { data: settings } = await supabase
    .from("user_local_mode_settings")
    .select("aw_id")
    .eq("user_id", input.userId)
    .maybeSingle();
  const settingsRow = settings as { aw_id?: string | null } | null;
  let awId = settingsRow?.aw_id ?? null;

  const awFields = {
    venue,
    event_name: null,
    eventless: true,
    start_at: start.toISOString(),
    end_at: end.toISOString(),
    radius_m: input.radiusM,
    center_lat: input.center.latitude,
    center_lng: input.center.longitude,
    status: "enabled" as const,
  };

  if (awId) {
    const { error } = await supabase
      .from("activity_windows")
      .update(awFields)
      .eq("id", awId)
      .eq("user_id", input.userId);
    if (error) awId = null;
  }

  if (!awId) {
    const { data: created, error } = await supabase
      .from("activity_windows")
      .insert({ ...awFields, user_id: input.userId })
      .select("id")
      .single();
    if (error || !created) {
      return { error: error?.message ?? "AW の作成に失敗しました" };
    }
    awId = (created as { id: string }).id;
  }

  await supabase
    .from("activity_windows")
    .update({ status: "disabled" })
    .eq("user_id", input.userId)
    .eq("status", "enabled")
    .neq("id", awId);

  const { error: upsertError } = await supabase
    .from("user_local_mode_settings")
    .upsert(
      {
        user_id: input.userId,
        enabled: true,
        aw_id: awId,
        radius_m: input.radiusM,
        last_lat: input.center.latitude,
        last_lng: input.center.longitude,
        selected_carrying_ids: input.selectedCarryingIds,
      },
      { onConflict: "user_id" },
    );

  if (upsertError) return { error: upsertError.message };
  return undefined;
}

async function fetchLocalCarryingItems(userId: string): Promise<LocalCarryingItem[]> {
  if (!supabase) return [];
  const { data } = await supabase
    .from("goods_inventory")
    .select(
      "id, title, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
    )
    .eq("user_id", userId)
    .eq("kind", "for_trade")
    .eq("status", "active")
    .order("created_at", { ascending: false });
  return ((data as {
    id: string;
    title: string;
    photo_urls: string[] | null;
    hue: number | string | null;
    group: LocalNameRelation;
    character: LocalNameRelation;
    goods_type: LocalNameRelation;
  }[] | null) ?? []).map((row) => {
    const label = pickLocalName(row.character) ?? pickLocalName(row.group) ?? row.title;
    const goodsType = pickLocalName(row.goods_type) ?? "グッズ";
    return {
      id: row.id,
      title: row.title || label,
      subtitle: `${pickLocalName(row.group) ?? "未設定"} / ${goodsType}`,
      photoUrl: row.photo_urls?.[0] ?? null,
      hue: normalizeLocalHue(row.hue, label),
    };
  });
}

type LocalNameRelation =
  | { name: string | null }
  | { name: string | null }[]
  | null
  | undefined;

function pickLocalName(value: LocalNameRelation) {
  if (!value) return null;
  return Array.isArray(value) ? value[0]?.name ?? null : value.name;
}

function normalizeLocalHue(value: number | string | null | undefined, seed: string) {
  if (typeof value === "number") return `hsl(${value}, 62%, 78%)`;
  if (typeof value === "string" && value.trim()) {
    return value.startsWith("#") || value.startsWith("hsl")
      ? value
      : `hsl(${Number(value) || localNameToHue(seed)}, 62%, 78%)`;
  }
  return `hsl(${localNameToHue(seed)}, 62%, 78%)`;
}

function localNameToHue(name: string) {
  let hash = 0;
  for (let index = 0; index < name.length; index += 1) {
    hash = (hash << 5) - hash + name.charCodeAt(index);
    hash |= 0;
  }
  return Math.abs(hash) % 360;
}

function LocalAura() {
  const pulse = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, {
          toValue: 1,
          duration: 1200,
          useNativeDriver: true,
        }),
        Animated.timing(pulse, {
          toValue: 0,
          duration: 1200,
          useNativeDriver: true,
        }),
      ]),
    );
    animation.start();

    return () => animation.stop();
  }, [pulse]);

  const scale = pulse.interpolate({
    inputRange: [0, 1],
    outputRange: [1, 1.04],
  });
  const opacity = pulse.interpolate({
    inputRange: [0, 1],
    outputRange: [0.45, 0.72],
  });

  return (
    <Animated.View
      pointerEvents="none"
      style={[
        styles.localAura,
        {
          opacity,
          transform: [{ scale }],
        },
      ]}
    />
  );
}

function getPriorityFrameStyle(priority: CandidatePriority) {
  if (priority === "both") {
    return {
      borderColor: "rgba(166,149,216,0.72)",
      borderWidth: 2,
      shadowColor: megrumColors.lavender,
      shadowOpacity: 0.22,
      shadowRadius: 16,
      shadowOffset: { width: 0, height: 8 },
      elevation: 4,
    };
  }

  if (priority === "oneSide") {
    return {
      borderColor: "rgba(168,212,230,0.78)",
      borderWidth: 1.5,
      shadowColor: megrumColors.sky,
      shadowOpacity: 0.18,
      shadowRadius: 12,
      shadowOffset: { width: 0, height: 7 },
      elevation: 3,
    };
  }

  return {
    borderColor: "rgba(58,50,74,0.10)",
    borderWidth: 1,
    shadowColor: megrumColors.ink,
    shadowOpacity: 0.08,
    shadowRadius: 10,
    shadowOffset: { width: 4, height: 8 },
    elevation: 2,
  };
}

const styles = StyleSheet.create({
  screenContent: {
    flex: 1,
    paddingHorizontal: 18,
  },
  homeScroll: {
    flex: 1,
    marginHorizontal: -18,
    zIndex: 1,
  },
  homeScrollContent: {
    paddingBottom: 132,
    paddingHorizontal: 18,
    paddingTop: 10,
  },
  homeHeader: {
    alignItems: "center",
    flexDirection: "row",
    height: 44,
    justifyContent: "space-between",
    marginBottom: 6,
    zIndex: 28,
  },
  homeHeaderAvatarButton: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    borderColor: "rgba(255,255,255,0.92)",
    borderRadius: 999,
    borderWidth: 1,
    height: 38,
    justifyContent: "center",
    overflow: "hidden",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 7 },
    shadowOpacity: 0.08,
    shadowRadius: 14,
    width: 38,
  },
  homeHeaderAvatarPressed: {
    opacity: 0.82,
    transform: [{ scale: 0.97 }],
  },
  homeHeaderAvatarImage: {
    height: "100%",
    width: "100%",
  },
  homeHeaderAvatarText: {
    color: megrumColors.lavender,
    fontSize: 16,
    fontWeight: "900",
  },
  homeHeaderLogo: {
    color: megrumColors.ink,
    fontSize: 21,
    fontWeight: "900",
    letterSpacing: 0,
  },
  homeHeaderSpacer: {
    width: 38,
  },
  topEdgeFade: {
    left: -18,
    overflow: "hidden",
    position: "absolute",
    right: -18,
    top: 0,
    zIndex: 18,
  },
  topEdgeFadeBand: {
    flex: 1,
  },
  floatingSearchButton: {
    alignItems: "center",
    borderRadius: 999,
    bottom: 102,
    height: 62,
    justifyContent: "center",
    left: 16,
    position: "absolute",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 16 },
    shadowOpacity: 0.18,
    shadowRadius: 28,
    width: 62,
    zIndex: 20,
  },
  floatingSearchButtonPressed: {
    opacity: 0.9,
    transform: [{ scale: 0.94 }],
  },
  floatingSearchFallback: {
    backgroundColor: "rgba(255,255,255,0.42)",
  },
  floatingSearchGlassClip: {
    ...StyleSheet.absoluteFillObject,
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.2)",
    borderColor: "rgba(255,255,255,0.92)",
    borderRadius: 999,
    borderWidth: StyleSheet.hairlineWidth,
    justifyContent: "center",
    overflow: "hidden",
  },
  floatingSearchOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(255,255,255,0.24)",
  },
  floatingSearchSpecular: {
    borderRadius: 999,
    bottom: 0,
    left: 0,
    opacity: 0.86,
    position: "absolute",
    right: 0,
    top: 0,
  },
  floatingSearchInnerGlow: {
    ...StyleSheet.absoluteFillObject,
    borderColor: "rgba(255,255,255,0.84)",
    borderRadius: 999,
    borderWidth: 1,
    shadowColor: "#ffffff",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.7,
    shadowRadius: 8,
  },
  floatingSearchIconLayer: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.2)",
    borderColor: "rgba(255,255,255,0.36)",
    borderRadius: 999,
    borderWidth: StyleSheet.hairlineWidth,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  searchGlyph: {
    height: 30,
    position: "relative",
    width: 30,
  },
  searchGlyphRing: {
    borderColor: megrumColors.ink,
    borderRadius: 999,
    borderWidth: 3,
    height: 18,
    left: 3,
    position: "absolute",
    top: 3,
    width: 18,
  },
  searchGlyphHandle: {
    backgroundColor: megrumColors.ink,
    borderRadius: 999,
    bottom: 5,
    height: 3,
    position: "absolute",
    right: 2,
    transform: [{ rotate: "45deg" }],
    width: 12,
  },
  homeActionButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.34)",
    borderColor: "rgba(255,255,255,0.78)",
    borderRadius: 999,
    borderWidth: StyleSheet.hairlineWidth,
    bottom: 104,
    height: 58,
    justifyContent: "center",
    overflow: "hidden",
    position: "absolute",
    right: 18,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 16 },
    shadowOpacity: 0.13,
    shadowRadius: 28,
    width: 58,
    zIndex: 21,
  },
  homeActionButtonLive: {
    backgroundColor: "rgba(166,149,216,0.18)",
    borderColor: "rgba(255,255,255,0.9)",
    shadowColor: megrumColors.lavender,
    shadowOpacity: 0.3,
  },
  homeActionButtonPressed: {
    opacity: 0.86,
    transform: [{ scale: 0.96 }],
  },
  homeActionFallbackGlass: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(255,255,255,0.86)",
  },
  homeActionIconLayer: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.08)",
    borderRadius: 999,
    height: 58,
    justifyContent: "center",
    width: 58,
  },
  localFocusLayer: {
    bottom: 0,
    left: 0,
    pointerEvents: "none",
    position: "absolute",
    right: 0,
    top: 0,
    zIndex: 12,
  },
  localFocusEdge: {
    backgroundColor: "rgba(166,149,216,0.28)",
    bottom: 0,
    position: "absolute",
    top: 0,
    width: 24,
  },
  localFocusLeft: {
    left: -12,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 18, height: 0 },
    shadowOpacity: 0.55,
    shadowRadius: 30,
  },
  localFocusRight: {
    right: -12,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: -18, height: 0 },
    shadowOpacity: 0.55,
    shadowRadius: 30,
  },
  modeStatusPill: {
    alignItems: "center",
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.76)",
    borderColor: "rgba(255,255,255,0.40)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 16,
    paddingVertical: 9,
    position: "absolute",
    top: 58,
    zIndex: 30,
  },
  modeStatusText: {
    color: megrumColors.surface,
    fontSize: 12,
    fontWeight: "900",
  },
  localSheetLayer: {
    backgroundColor: "rgba(20,18,28,0.28)",
    flex: 1,
    justifyContent: "flex-end",
  },
  localSheetNativeLayer: {
    backgroundColor: megrumColors.background,
    justifyContent: "flex-start",
  },
  localSheetBackdrop: {
    bottom: 0,
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
  },
  localSheet: {
    backgroundColor: "rgba(255,255,255,0.97)",
    borderColor: "rgba(255,255,255,0.92)",
    borderTopLeftRadius: 30,
    borderTopRightRadius: 30,
    borderWidth: 1,
    maxHeight: "86%",
    paddingBottom: 18,
    paddingHorizontal: 20,
    paddingTop: 10,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: -16 },
    shadowOpacity: 0.16,
    shadowRadius: 34,
  },
  localSheetNativePanel: {
    backgroundColor: megrumColors.background,
    borderTopLeftRadius: 0,
    borderTopRightRadius: 0,
    borderWidth: 0,
    maxHeight: "100%",
    shadowOpacity: 0,
    shadowRadius: 0,
  },
  localSheetHandle: {
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.14)",
    borderRadius: 999,
    height: 5,
    marginBottom: 15,
    width: 42,
  },
  localSheetHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  localSheetKicker: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 0.8,
  },
  localSheetTitle: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 27,
    marginTop: 3,
  },
  localSheetClose: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.07)",
    borderRadius: 999,
    height: 34,
    justifyContent: "center",
    width: 34,
  },
  localSheetCloseText: {
    color: "rgba(58,50,74,0.62)",
    fontSize: 24,
    fontWeight: "600",
    lineHeight: 27,
  },
  localSheetLead: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    marginTop: 9,
  },
  localSheetBody: {
    gap: 16,
    paddingBottom: 16,
    paddingTop: 17,
  },
  localSection: {
    gap: 10,
  },
  localSectionHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  localSectionTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  localSectionMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  carryingScroller: {
    gap: 10,
    paddingRight: 12,
  },
  carryingCard: {
    backgroundColor: "rgba(255,255,255,0.92)",
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: 16,
    borderWidth: 1,
    padding: 8,
    width: 104,
  },
  carryingCardActive: {
    borderColor: "rgba(166,149,216,0.72)",
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.18,
    shadowRadius: 14,
  },
  carryingThumb: {
    alignItems: "center",
    aspectRatio: 3 / 4,
    borderRadius: 12,
    justifyContent: "center",
    overflow: "hidden",
    position: "relative",
    width: "100%",
  },
  carryingImage: {
    height: "100%",
    width: "100%",
  },
  carryingGlyph: {
    color: megrumColors.surface,
    fontSize: 26,
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.24)",
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 5,
  },
  carryingCheck: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.74)",
    borderColor: "rgba(255,255,255,0.86)",
    borderRadius: 999,
    borderWidth: 1,
    height: 24,
    justifyContent: "center",
    position: "absolute",
    right: 6,
    top: 6,
    width: 24,
  },
  carryingCheckActive: {
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.surface,
  },
  carryingCheckText: {
    color: megrumColors.lavender,
    fontSize: 13,
    fontWeight: "900",
    lineHeight: 16,
  },
  carryingCheckTextActive: {
    color: megrumColors.surface,
  },
  carryingTitle: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
    marginTop: 7,
  },
  carryingSub: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "800",
    marginTop: 2,
  },
  carryingEmpty: {
    backgroundColor: "rgba(58,50,74,0.045)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    paddingHorizontal: 13,
    paddingVertical: 12,
  },
  carryingEmptyText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
  },
  currentLocationButton: {
    backgroundColor: "rgba(166,149,216,0.13)",
    borderColor: "rgba(166,149,216,0.32)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  currentLocationText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  localMap: {
    borderRadius: 20,
    overflow: "hidden",
  },
  localInput: {
    backgroundColor: "rgba(58,50,74,0.05)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 17,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "800",
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  localChipRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 9,
  },
  localChip: {
    backgroundColor: "rgba(58,50,74,0.055)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 13,
    paddingVertical: 9,
  },
  localChipActive: {
    backgroundColor: "rgba(166,149,216,0.18)",
    borderColor: "rgba(166,149,216,0.48)",
  },
  localChipText: {
    color: "rgba(58,50,74,0.60)",
    fontSize: 11,
    fontWeight: "900",
  },
  localChipTextActive: {
    color: megrumColors.ink,
  },
  localSheetError: {
    backgroundColor: "rgba(239,68,68,0.09)",
    borderColor: "rgba(239,68,68,0.16)",
    borderRadius: 16,
    borderWidth: 1,
    paddingHorizontal: 13,
    paddingVertical: 10,
  },
  localSheetErrorText: {
    color: megrumColors.warn,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
  },
  localSheetActions: {
    flexDirection: "row",
    gap: 10,
    paddingTop: 2,
  },
  localCancelButton: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 18,
    flex: 0.36,
    justifyContent: "center",
    paddingVertical: 14,
  },
  localCancelText: {
    color: "rgba(58,50,74,0.62)",
    fontSize: 13,
    fontWeight: "900",
  },
  localApplyButton: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 18,
    flex: 0.64,
    justifyContent: "center",
    paddingVertical: 14,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.24,
    shadowRadius: 18,
  },
  localApplyButtonDisabled: {
    opacity: 0.45,
  },
  localApplyText: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
  },
  identityRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
    marginBottom: 14,
  },
  identityText: {
    flex: 1,
  },
  kicker: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.4,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 25,
    fontWeight: "900",
    letterSpacing: 0,
    lineHeight: 29,
  },
  inlineError: {
    color: megrumColors.warn,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
  },
  loadingText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  homeGroomRail: {
    gap: 10,
    marginBottom: 8,
    marginTop: 2,
  },
  homeGroomTitle: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 27,
  },
  homeGroomList: {
    gap: 13,
    paddingRight: 18,
  },
  homeGroomItem: {
    alignItems: "center",
    gap: 6,
    width: 80,
  },
  homeGroomRing: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: megrumColors.lavender,
    borderRadius: 999,
    borderWidth: 2,
    height: 74,
    justifyContent: "center",
    padding: 3,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.16,
    shadowRadius: 12,
    width: 74,
  },
  homeGroomRingLiked: {
    borderColor: megrumColors.pink,
    shadowColor: megrumColors.pink,
  },
  homeGroomRingViewed: {
    borderColor: "rgba(58,50,74,0.24)",
    shadowColor: "rgba(58,50,74,0.20)",
    shadowOpacity: 0.06,
  },
  homeGroomImage: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    height: "100%",
    width: "100%",
  },
  homeGroomAddRing: {
    borderColor: "rgba(166,149,216,0.34)",
    borderStyle: "dashed",
    shadowOpacity: 0.08,
  },
  homeGroomAddCircle: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    height: "100%",
    justifyContent: "center",
    width: "100%",
  },
  homeGroomName: {
    color: "rgba(58,50,74,0.72)",
    fontSize: 11,
    fontWeight: "900",
    maxWidth: 78,
    textAlign: "center",
  },
  homeGroomViewer: {
    flex: 1,
  },
  homeGroomViewerBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#05080d",
  },
  homeGroomViewerFrame: {
    backgroundColor: "#000",
    flex: 1,
    overflow: "hidden",
  },
  homeGroomStoryStage: {
    backgroundColor: "#05080d",
    flex: 1,
    overflow: "hidden",
  },
  homeGroomStoryFace: {
    backfaceVisibility: "hidden",
    backgroundColor: "#05080d",
    bottom: 0,
    overflow: "hidden",
    position: "absolute",
    top: 0,
  },
  homeGroomStoryCubeShade: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#000",
  },
  homeGroomImageLoadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    alignItems: "center",
    backgroundColor: "#05080d",
    justifyContent: "center",
    zIndex: 10,
  },
  homeGroomStoryBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#8f8c86",
  },
  homeGroomStoryImageFrame: {
    overflow: "hidden",
    position: "absolute",
  },
  homeGroomDoodleDot: {
    borderRadius: 999,
    height: 5,
    marginLeft: -2.5,
    marginTop: -2.5,
    opacity: 0.9,
    position: "absolute",
    width: 5,
  },
  homeGroomStoryTextOverlay: {
    maxWidth: "70%",
    position: "absolute",
  },
  homeGroomStoryTextOverlayLabel: {
    backgroundColor: "rgba(0,0,0,0.32)",
    borderRadius: 13,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  homeGroomStoryTextOverlaySolid: {
    backgroundColor: "#fff",
    borderRadius: 13,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  homeGroomStoryTextOverlayText: {
    fontSize: 26,
    fontWeight: "900",
    lineHeight: 33,
    textShadowColor: "rgba(0,0,0,0.35)",
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 5,
  },
  homeGroomStoryStickerOverlay: {
    borderRadius: 999,
    borderWidth: 2,
    paddingHorizontal: 9,
    paddingVertical: 5,
    position: "absolute",
  },
  homeGroomStoryStickerText: {
    fontSize: 13,
    fontWeight: "900",
  },
  homeGroomViewerHeader: {
    left: 0,
    paddingHorizontal: 12,
    position: "absolute",
    right: 0,
    top: 0,
    zIndex: 8,
  },
  homeGroomProgressRow: {
    flexDirection: "row",
    gap: 4,
  },
  homeGroomProgressTrack: {
    backgroundColor: "rgba(255,255,255,0.34)",
    borderRadius: 99,
    flex: 1,
    height: 3,
    overflow: "hidden",
  },
  homeGroomProgressFill: {
    backgroundColor: "rgba(255,255,255,0.92)",
    borderRadius: 99,
    height: "100%",
  },
  homeGroomViewerHeaderRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
    marginTop: 14,
  },
  homeGroomViewerAuthor: {
    alignItems: "center",
    borderRadius: 999,
    flexDirection: "row",
    gap: 10,
    marginTop: 14,
  },
  homeGroomViewerAuthorInRow: {
    flex: 1,
    marginTop: 0,
    minWidth: 0,
  },
  homeGroomViewerAuthorPressed: {
    opacity: 0.72,
  },
  homeGroomViewerMenuButton: {
    alignItems: "center",
    backgroundColor: "rgba(0,0,0,0.18)",
    borderRadius: megrumRadii.pill,
    height: 38,
    justifyContent: "center",
    width: 38,
  },
  homeGroomViewerFace: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.58)",
    borderColor: megrumColors.pink,
    borderRadius: 999,
    borderWidth: 2,
    height: 38,
    justifyContent: "center",
    width: 38,
  },
  homeGroomViewerFaceLiked: {
    borderColor: megrumColors.pink,
  },
  homeGroomViewerFaceText: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  homeGroomViewerNameWrap: {
    flex: 1,
    minWidth: 0,
  },
  homeGroomViewerName: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "900",
  },
  homeGroomViewerMeta: {
    color: "rgba(255,255,255,0.78)",
    fontSize: 13,
    fontWeight: "800",
    marginTop: 2,
  },
  homeGroomTapLayer: {
    bottom: 108,
    flexDirection: "row",
    left: 0,
    position: "absolute",
    right: 0,
    top: 112,
    zIndex: 3,
  },
  homeGroomTapZone: {
    flex: 1,
  },
  homeGroomCaptionPanel: {
    bottom: 112,
    left: 18,
    position: "absolute",
    right: 76,
    zIndex: 7,
  },
  homeGroomCaptionText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "500",
    lineHeight: 18,
    textAlign: "left",
  },
  homeGroomFeedbackText: {
    color: "rgba(255,255,255,0.82)",
    fontSize: 12,
    fontWeight: "700",
    marginTop: 8,
    textAlign: "left",
  },
  homeGroomCenterToast: {
    alignSelf: "center",
    backgroundColor: "rgba(20,16,29,0.74)",
    borderColor: "rgba(255,255,255,0.18)",
    borderRadius: 18,
    borderWidth: 1,
    left: 42,
    paddingHorizontal: 18,
    paddingVertical: 12,
    position: "absolute",
    right: 42,
    top: "45%",
    zIndex: 11,
  },
  homeGroomCenterToastText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "900",
    textAlign: "center",
  },
  homeGroomInputDimmer: {
    backgroundColor: "rgba(0,0,0,0.34)",
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
    zIndex: 8,
  },
  homeGroomViewerFooter: {
    bottom: 0,
    left: 0,
    paddingHorizontal: 13,
    position: "absolute",
    right: 0,
    zIndex: 9,
  },
  homeGroomReplyRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 11,
  },
  homeGroomReplyInput: {
    backgroundColor: "rgba(5,8,13,0.42)",
    borderColor: "rgba(255,255,255,0.46)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    color: "#fff",
    flex: 1,
    fontSize: 16,
    fontWeight: "800",
    lineHeight: 21,
    maxHeight: 100,
    minHeight: 50,
    paddingHorizontal: 18,
    paddingVertical: 12,
  },
  homeGroomReplyGhost: {
    alignItems: "center",
    backgroundColor: "rgba(5,8,13,0.42)",
    borderColor: "rgba(255,255,255,0.46)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    flex: 1,
    justifyContent: "center",
    minHeight: 50,
    paddingHorizontal: 18,
    paddingVertical: 12,
  },
  homeGroomReplyGhostText: {
    alignSelf: "stretch",
    color: "rgba(255,255,255,0.78)",
    fontSize: 16,
    fontWeight: "800",
    lineHeight: 21,
  },
  homeGroomViewerAction: {
    alignItems: "center",
    borderRadius: megrumRadii.pill,
    height: 48,
    justifyContent: "center",
    width: 42,
  },
  homeGroomSendButtonDisabled: {
    opacity: 0.52,
  },
  emptyMatches: {
    backgroundColor: "rgba(255,255,255,0.86)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 20,
    borderWidth: 1,
    paddingHorizontal: 18,
    paddingVertical: 22,
  },
  emptyMatchesTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  emptyMatchesText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 18,
    marginTop: 6,
  },
  stickySectionHeader: {
    backgroundColor: "transparent",
    marginHorizontal: -18,
    paddingBottom: 10,
    paddingHorizontal: 18,
    paddingTop: 12,
    zIndex: 10,
  },
  shelfSectionRows: {
    gap: 9,
    marginBottom: 22,
  },
  homeCandidateGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
    paddingBottom: 18,
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
    letterSpacing: 0,
    lineHeight: 22,
    position: "relative",
  },
  shelfRow: {
    gap: 4,
  },
  rowTitleLine: {
    alignItems: "baseline",
    flexDirection: "row",
    gap: 6,
    paddingHorizontal: 1,
  },
  rowCharacter: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
    maxWidth: 180,
  },
  rowGoods: {
    color: "rgba(58,50,74,0.45)",
    fontSize: 10.5,
    fontWeight: "900",
  },
  rowScroller: {
    gap: 12,
    paddingBottom: 15,
    paddingTop: 9,
  },
  tileHitArea: {
    borderRadius: 13,
  },
  tileHitAreaLocal: {
    overflow: "visible",
  },
  tileCard: {
    backgroundColor: "rgba(58,50,74,0.05)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 13,
    borderWidth: 1,
    overflow: "hidden",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 3, height: 6 },
    shadowOpacity: 0.08,
    shadowRadius: 9,
  },
  fakeImage: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  realImage: {
    height: "100%",
    width: "100%",
  },
  fakeImageGlow: {
    backgroundColor: "rgba(255,255,255,0.26)",
    borderRadius: 999,
    height: 58,
    position: "absolute",
    right: -17,
    top: -12,
    width: 58,
  },
  fakeImageLetter: {
    color: megrumColors.surface,
    fontSize: 32,
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.16)",
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 5,
  },
  tagOverlay: {
    backgroundColor: "rgba(255,255,255,0.86)",
    borderRadius: 6,
    maxWidth: "78%",
    paddingHorizontal: 6,
    paddingVertical: 3,
    position: "absolute",
    right: 6,
    top: 6,
  },
  tagText: {
    color: megrumColors.ink,
    fontSize: 9,
    fontWeight: "900",
  },
  liveBadge: {
    backgroundColor: megrumColors.lavender,
    borderRadius: 6,
    paddingHorizontal: 6,
    paddingVertical: 3,
    position: "absolute",
    right: 8,
    top: 31,
  },
  liveBadgeText: {
    color: megrumColors.surface,
    fontSize: 9,
    fontWeight: "900",
  },
  localAura: {
    backgroundColor: "rgba(166,149,216,0.16)",
    borderColor: "rgba(166,149,216,0.52)",
    borderRadius: 22,
    borderWidth: 1,
    bottom: -5,
    left: -5,
    position: "absolute",
    right: -5,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.42,
    shadowRadius: 18,
    top: -5,
  },
});
