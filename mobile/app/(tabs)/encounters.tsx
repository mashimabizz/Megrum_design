import { useEffect, useLayoutEffect, useMemo, useRef, useState, type ReactNode } from "react";
import {
  Alert,
  Animated,
  ActivityIndicator,
  ActionSheetIOS,
  AppState,
  Easing,
  Image,
  Keyboard,
  Modal,
  PanResponder,
  Platform,
  type PanResponderGestureState,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  useWindowDimensions,
  View,
} from "react-native";
import { CameraView, useCameraPermissions, type CameraType } from "expo-camera";
import * as ImagePicker from "expo-image-picker";
import * as MediaLibrary from "expo-media-library";
import { useRouter } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Screen } from "../../src/components/Screen";
import { IconSymbol } from "../../src/components/IconSymbol";
import {
  MeguriThreeBoundary,
  MeguriThreeScene,
  type MeguriSceneResident,
} from "../../src/components/meguri/MeguriThreeScene";
import { ihubColors, ihubRadii, ihubShadow } from "../../src/theme/tokens";
import {
  DEFAULT_MEGURI_AVATAR,
  DEFAULT_MEGURI_PROFILE,
  loadMeguriAvatarSettings,
  loadMeguriPlusSettings,
  loadMeguriProfileSettings,
} from "../../src/lib/meguriSettings";
import { GroomProfileSlidePanel, type GroomProfileUser } from "../../src/components/meguri/GroomProfileSlidePanel";
import { useAuth } from "../../src/auth/AuthProvider";
import {
  archiveGroomPost,
  blockGroomUser,
  createGroomPost,
  fetchGroomFeed,
  hideGroomPost,
  isUuidLike,
  markGroomPostViewed,
  reportGroomPost,
  setGroomPostLiked,
  type GroomRemoteAuthor,
  type GroomRemotePost,
} from "../../src/lib/groom";
import { appendMeguriGroomReply } from "../../src/lib/meguriMessages";
import { useKeyboardInset } from "../../src/lib/useKeyboardInset";

const GROOM_CAMERA_QUALITY = 0.88;
const GROOM_LIBRARY_QUALITY = 0.88;
const GROOM_MAX_CAMERA_LONG_EDGE = 2400;

export type MeguriHue = "lav" | "sky" | "pink" | "mint" | "butter";
export type MeguriAnimalType = "cat" | "fox" | "rabbit";
export type MeguriFurColor =
  | "lavender"
  | "sky"
  | "pink"
  | "cream"
  | "mint"
  | "cocoa"
  | "gray";

export type MeguriUser = {
  id: string;
  name: string;
  animalType: MeguriAnimalType;
  furColor: MeguriFurColor;
  hue: MeguriHue;
  oshi: string;
  group: string;
  area: string;
  style: string;
  recent: string;
  hitokoto: string;
  count: number;
  since: string;
};

export type Letter = {
  id: string;
  from: MeguriUser;
  affinity: number;
  placeHint: string;
  timeHint: string;
  body: string;
  opened: boolean;
};

export type GroomPost = {
  id: string;
  author: MeguriUser | null;
  imagePath?: string | null;
  imageUri: string;
  imageTransform?: GroomImageTransform;
  caption: string;
  doodles?: GroomDoodleStroke[];
  publishedAt?: string;
  stickers?: GroomStickerOverlay[];
  textOverlays?: GroomTextOverlay[];
  placeHint: string;
  timeLabel: string;
  liked: boolean;
  mine?: boolean;
};

type GroomImageTransform = {
  rotation: number;
  scale: number;
  x: number;
  y: number;
};

type GroomGestureEvent = {
  nativeEvent: {
    touches?: { pageX: number; pageY: number }[];
  };
};

type GroomTextOverlay = {
  id: string;
  color: string;
  rotation?: number;
  scale?: number;
  text: string;
  tone: "plain" | "label" | "solid";
  x: number;
  y: number;
};

type GroomStickerOverlay = {
  id: string;
  color: string;
  label: string;
  x: number;
  y: number;
};

type GroomDoodleStroke = {
  id: string;
  color: string;
  points: { x: number; y: number }[];
};

type GroomPublishPayload = {
  caption: string;
  doodles: GroomDoodleStroke[];
  imageTransform: GroomImageTransform;
  stickers: GroomStickerOverlay[];
  textOverlays: GroomTextOverlay[];
};

type GroomCapturePayload = {
  base64?: string | null;
  contentType?: string | null;
  uri: string;
};

type GroomAccountGroup = {
  key: string;
  posts: GroomPost[];
};

type GroomOpenOrigin = {
  height: number;
  width: number;
  x: number;
  y: number;
};

export type Achievement = {
  id: string;
  title: string;
  description: string;
  unlocked: boolean;
  hue: MeguriHue;
};

export const MONTHLY_PRICE = 1000;
export const FREE_SEND_LIMIT = 3;
const GROOM_TEXT_COLORS = ["#ffffff", "#ffd1e4", "#bff0ff", "#d9ffca", "#ffe08a"];
const GROOM_DRAW_COLORS = ["#ffffff", "#f3c5d4", "#a8d4e6", "#a695d8", "#f2b95b"];
const DEFAULT_GROOM_IMAGE_TRANSFORM: GroomImageTransform = {
  rotation: 0,
  scale: 1,
  x: 0,
  y: 0,
};

function isDefaultGroomImageTransform(transform?: GroomImageTransform | null) {
  if (!transform) return true;
  return (
    Math.abs(transform.rotation) < 0.001 &&
    Math.abs(transform.scale - 1) < 0.001 &&
    Math.abs(transform.x) < 0.001 &&
    Math.abs(transform.y) < 0.001
  );
}

export const USERS: MeguriUser[] = [
  {
    id: "michirio",
    name: "みち",
    animalType: "cat",
    furColor: "lavender",
    hue: "lav",
    oshi: "リオ",
    group: "VESTA",
    area: "東京",
    style: "現場 / トレカ整理",
    recent: "リオの黒髪ビジュに戻ってきました",
    hitokoto: "今いちばん刺さってるのは MV のラスト 30 秒",
    count: 3,
    since: "今日",
  },
  {
    id: "nova_aya",
    name: "ノア",
    animalType: "rabbit",
    furColor: "sky",
    hue: "sky",
    oshi: "アヤ",
    group: "NOVA",
    area: "神奈川",
    style: "配信中心",
    recent: "新MVを6回見ました",
    hitokoto: "現場行けないぶん配信を回してます",
    count: 1,
    since: "今週",
  },
  {
    id: "kai_kiko",
    name: "きこ",
    animalType: "fox",
    furColor: "pink",
    hue: "pink",
    oshi: "カイ",
    group: "VESTA",
    area: "大阪",
    style: "トレカ収集",
    recent: "昨日のライブ配信が最高だった",
    hitokoto: "ピンクの公式グッズ探し中",
    count: 2,
    since: "先月",
  },
  {
    id: "stage_yui",
    name: "ゆい",
    animalType: "rabbit",
    furColor: "mint",
    hue: "mint",
    oshi: "ナギ",
    group: "夜明けノクターン",
    area: "千葉",
    style: "撮影会",
    recent: "新キービジュ写真集",
    hitokoto: "推しの目線が刺さりました",
    count: 1,
    since: "今日",
  },
  {
    id: "anime_aki",
    name: "あき",
    animalType: "cat",
    furColor: "cream",
    hue: "butter",
    oshi: "ヒナノ",
    group: "星屑シンフォニア",
    area: "東京",
    style: "コスプレ",
    recent: "新衣装製作中",
    hitokoto: "10話の演出が忘れられない",
    count: 2,
    since: "今日",
  },
  {
    id: "stage_ren",
    name: "れん",
    animalType: "fox",
    furColor: "cocoa",
    hue: "lav",
    oshi: "ナギ",
    group: "夜明けノクターン",
    area: "東京",
    style: "千秋楽勢",
    recent: "ナギの新作キービジュ最高",
    hitokoto: "推し活初心者です、よろしくです",
    count: 4,
    since: "今日",
  },
  {
    id: "game_sora",
    name: "そら",
    animalType: "rabbit",
    furColor: "gray",
    hue: "sky",
    oshi: "ルナ",
    group: "アスタリア",
    area: "福岡",
    style: "フェス参戦",
    recent: "新章PV見て泣いた",
    hitokoto: "イラスト練習中、推しを描きたい",
    count: 1,
    since: "先月",
  },
  {
    id: "kpop_mio",
    name: "みお",
    animalType: "cat",
    furColor: "pink",
    hue: "pink",
    oshi: "リオ",
    group: "VESTA",
    area: "京都",
    style: "歌詞翻訳",
    recent: "歌詞ノート3冊目",
    hitokoto: "歌詞和訳が趣味です",
    count: 1,
    since: "先月",
  },
  {
    id: "idol_mai",
    name: "まい",
    animalType: "fox",
    furColor: "cream",
    hue: "butter",
    oshi: "ミナ",
    group: "LUMIA",
    area: "埼玉",
    style: "カフェ巡り",
    recent: "新ビジュの淡色衣装が好きです",
    hitokoto: "今日は推し色ネイルで出かけました",
    count: 1,
    since: "今日",
  },
  {
    id: "cos_haru",
    name: "はる",
    animalType: "cat",
    furColor: "mint",
    hue: "mint",
    oshi: "イツキ",
    group: "月影アンサンブル",
    area: "愛知",
    style: "衣装制作",
    recent: "小物づくりを夜な夜な進めています",
    hitokoto: "同じ作品の話ができるだけでうれしいです",
    count: 1,
    since: "今日",
  },
];

export const LETTERS: Letter[] = [
  {
    id: "letter-1",
    from: USERS[0],
    affinity: 94,
    placeHint: "最近、都内東側のどこか",
    timeHint: "今週の夕方ごろ",
    body: "同じ推しの話が近くで何度か重なっていて、うれしくなりました。よかったら少し話してみたいです。",
    opened: false,
  },
  {
    id: "letter-2",
    from: USERS[2],
    affinity: 89,
    placeHint: "同じイベント圏内",
    timeHint: "最近",
    body: "ピンクの公式グッズの話をしている人が近くにいて、思わずメッセージを書きました。",
    opened: false,
  },
  {
    id: "letter-3",
    from: USERS[3],
    affinity: 78,
    placeHint: "都内のどこか",
    timeHint: "数日前",
    body: "同じ舞台の話ができる人を探していました。無理なければつながれたら嬉しいです。",
    opened: true,
  },
];

export const ACHIEVEMENTS: Achievement[] = [
  {
    id: "again",
    title: "再めぐり達成",
    description: "同じ人と2回以上めぐりあいました",
    unlocked: true,
    hue: "butter",
  },
  {
    id: "same",
    title: "同担の輪",
    description: "同じ推しの人と10回めぐりあいました",
    unlocked: true,
    hue: "lav",
  },
  {
    id: "letter",
    title: "はじめてのメッセージ",
    description: "めぐりメッセージを受け取りました",
    unlocked: true,
    hue: "pink",
  },
  {
    id: "map",
    title: "5エリアめぐり",
    description: "5つのエリアでめぐりを記録",
    unlocked: false,
    hue: "sky",
  },
];

export const GROOM_POSTS: GroomPost[] = [
  {
    id: "groom-michirio",
    author: USERS[0],
    imageUri:
      "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=82",
    caption: "推し色のリボン、今日の現場に間に合いました",
    placeHint: "同じイベント圏内",
    timeLabel: "12分前",
    liked: false,
  },
  {
    id: "groom-michirio-2",
    author: USERS[0],
    imageUri:
      "https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=900&q=82",
    caption: "開演前に交換バッグも整えました",
    placeHint: "同じイベント圏内",
    timeLabel: "8分前",
    liked: false,
  },
  {
    id: "groom-kiko",
    author: USERS[2],
    imageUri:
      "https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=82",
    caption: "淡色コーデでトレカケースも合わせてきた",
    placeHint: "会場周辺",
    timeLabel: "28分前",
    liked: true,
  },
  {
    id: "groom-yui",
    author: USERS[3],
    imageUri:
      "https://images.unsplash.com/photo-1513201099705-a9746e1e201f?auto=format&fit=crop&w=900&q=82",
    caption: "ぬいと一緒に開場待ち。空気がもう楽しい",
    placeHint: "都内東側",
    timeLabel: "41分前",
    liked: false,
  },
  {
    id: "groom-mai",
    author: USERS[8],
    imageUri:
      "https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=900&q=82",
    caption: "推し色ネイル、近くで見るときらきらです",
    placeHint: "同じ駅周辺",
    timeLabel: "1時間前",
    liked: false,
  },
];

export function hueColor(hue: MeguriHue) {
  switch (hue) {
    case "sky":
      return ihubColors.sky;
    case "pink":
      return ihubColors.pink;
    case "mint":
      return "#a8dcc9";
    case "butter":
      return "#efd99b";
    case "lav":
    default:
      return ihubColors.lavender;
  }
}

export function hueTint(hue: MeguriHue, alpha = 0.18) {
  switch (hue) {
    case "sky":
      return `rgba(168,212,230,${alpha})`;
    case "pink":
      return `rgba(243,197,212,${alpha})`;
    case "mint":
      return `rgba(168,220,201,${alpha})`;
    case "butter":
      return `rgba(239,217,155,${alpha})`;
    case "lav":
    default:
      return `rgba(166,149,216,${alpha})`;
  }
}

function remotePostToGroomPost(post: GroomRemotePost): GroomPost {
  return {
    author: post.mine ? null : remoteAuthorToMeguriUser(post.author),
    caption: post.caption,
    doodles: post.doodles as GroomDoodleStroke[],
    id: post.id,
    imagePath: post.imagePath,
    imageTransform: post.imageTransform,
    imageUri: post.imageUrl,
    liked: post.liked,
    mine: post.mine,
    placeHint: post.placeHint,
    publishedAt: post.publishedAt,
    stickers: post.stickers as GroomStickerOverlay[],
    textOverlays: post.textOverlays as GroomTextOverlay[],
    timeLabel: relativeTimeLabel(post.publishedAt),
  };
}

function remoteAuthorToMeguriUser(author: GroomRemoteAuthor): MeguriUser {
  const matched = USERS.find((item) => item.id === author.id || item.name === author.displayName);
  if (matched) {
    return {
      ...matched,
      area: author.primaryArea || matched.area,
      id: author.id,
      name: author.displayName || matched.name,
    };
  }
  return {
    animalType: "cat",
    area: author.primaryArea || "イベント周辺",
    count: 1,
    furColor: "lavender",
    group: "めぐり",
    hitokoto: author.handle ? `@${author.handle}` : "グルームでめぐりました",
    hue: "lav",
    id: author.id,
    name: author.displayName,
    oshi: "推し",
    recent: "グルームを投稿しています",
    since: "今日",
    style: "推し活",
  };
}

function relativeTimeLabel(value: string) {
  const publishedAt = Date.parse(value);
  if (!Number.isFinite(publishedAt)) return "たった今";
  const diffMinutes = Math.max(0, Math.floor((Date.now() - publishedAt) / 60000));
  if (diffMinutes < 1) return "たった今";
  if (diffMinutes < 60) return `${diffMinutes}分前`;
  const diffHours = Math.floor(diffMinutes / 60);
  if (diffHours < 24) return `${diffHours}時間前`;
  return "昨日";
}

export default function EncountersScreen() {
  const { previewMode, user } = useAuth();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const arrivals = useMemo(() => USERS.slice(0, 5), []);
  const todayCount = Math.min(USERS.length, 10);
  const [activeIndex, setActiveIndex] = useState(0);
  const [homeThreeFailed, setHomeThreeFailed] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [meguriEnabled, setMeguriEnabled] = useState(true);
  const [plusActive, setPlusActive] = useState(false);
  const [selfScene, setSelfScene] = useState<MeguriSceneResident | null>(null);
  const [groomPosts, setGroomPosts] = useState<GroomPost[]>(() => (previewMode ? GROOM_POSTS : []));
  const [groomLoading, setGroomLoading] = useState(!previewMode);
  const [selectedGroomId, setSelectedGroomId] = useState<string | null>(null);
  const [groomReply, setGroomReply] = useState("");
  const [groomReplyNotice, setGroomReplyNotice] = useState("");
  const [groomCameraOpen, setGroomCameraOpen] = useState(false);
  const [groomDraftUri, setGroomDraftUri] = useState<string | null>(null);
  const [groomDraftBase64, setGroomDraftBase64] = useState<string | null>(null);
  const [groomDraftContentType, setGroomDraftContentType] = useState<string | null>(null);
  const [groomDraftCaption, setGroomDraftCaption] = useState("");
  const [groomOpenOrigin, setGroomOpenOrigin] = useState<GroomOpenOrigin | null>(null);
  const [groomViewerSession, setGroomViewerSession] = useState(0);
  const [viewedGroomKeys, setViewedGroomKeys] = useState<Set<string>>(() => new Set());
  const groomToastTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const active = arrivals[activeIndex];
  const selectedGroomPost = groomPosts.find((post) => post.id === selectedGroomId) ?? null;
  const lockedLetters = previewMode && !plusActive ? LETTERS.length : 0;
  const sceneResidents = useMemo(() => arrivals.map(toHomeSceneResident), [arrivals]);
  const headerTop = Math.max(insets.top, 18) + 8;
  const bottomPadding = Math.max(insets.bottom, 12) + 96;

  useEffect(() => {
    const timer = setInterval(() => {
      setActiveIndex((current) => (current + 1) % arrivals.length);
    }, 3200);
    return () => clearInterval(timer);
  }, [arrivals.length]);

  useEffect(() => {
    let mounted = true;
    Promise.all([loadMeguriAvatarSettings(), loadMeguriProfileSettings()])
      .then(([avatar, profile]) => {
        if (!mounted) return;
        setSelfScene({
          animalType: avatar.animalType ?? DEFAULT_MEGURI_AVATAR.animalType,
          furColor: avatar.furColor ?? DEFAULT_MEGURI_AVATAR.furColor,
          hue: avatar.hue ?? DEFAULT_MEGURI_AVATAR.hue,
          id: "me",
          name: profile.displayName || DEFAULT_MEGURI_PROFILE.displayName,
        });
      })
      .catch(() => {
        if (!mounted) return;
        setSelfScene({
          animalType: DEFAULT_MEGURI_AVATAR.animalType,
          furColor: DEFAULT_MEGURI_AVATAR.furColor,
          hue: DEFAULT_MEGURI_AVATAR.hue,
          id: "me",
          name: DEFAULT_MEGURI_PROFILE.displayName,
        });
      });
    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    loadMeguriPlusSettings()
      .then((settings) => setPlusActive(settings.active))
      .catch(() => undefined);
  }, []);

  async function refreshGroomPosts() {
    if (previewMode) {
      setGroomLoading(false);
      setGroomPosts(GROOM_POSTS);
      setViewedGroomKeys(new Set());
      return;
    }
    if (!user) {
      setGroomLoading(false);
      setGroomPosts([]);
      setViewedGroomKeys(new Set());
      return;
    }
    try {
      const remotePosts = await fetchGroomFeed(user.id);
      const nextPosts = remotePosts.map(remotePostToGroomPost);
      setGroomPosts(nextPosts);
      setViewedGroomKeys(
        new Set(nextPosts.filter((_, index) => remotePosts[index]?.viewed).map(groomAccountKey)),
      );
    } finally {
      setGroomLoading(false);
    }
  }

  useEffect(() => {
    setGroomLoading(!previewMode);
    refreshGroomPosts().catch(() => undefined);
  }, [previewMode, user]);

  useEffect(() => {
    if (previewMode || !user) return undefined;
    const subscription = AppState.addEventListener("change", (state) => {
      if (state === "active") refreshGroomPosts().catch(() => undefined);
    });
    return () => subscription.remove();
  }, [previewMode, user]);

  function openGroomCamera() {
    setGroomCameraOpen(true);
  }

  function openGroomEditor(capture: GroomCapturePayload) {
    setGroomCameraOpen(false);
    setGroomDraftUri(capture.uri);
    setGroomDraftBase64(capture.base64 ?? null);
    setGroomDraftContentType(capture.contentType ?? "image/jpeg");
    setGroomDraftCaption("");
  }

  function openGroomPost(post: GroomPost, origin: GroomOpenOrigin | null = null) {
    setGroomViewerSession((current) => current + 1);
    setGroomOpenOrigin(normalizeGroomOpenOrigin(origin));
    setSelectedGroomId(post.id);
    setGroomReply("");
    setGroomReplyNotice("");
    clearGroomToastTimer();
    markGroomViewed(post);
  }

  function selectGroomPost(postId: string) {
    const nextPost = groomPosts.find((post) => post.id === postId);
    setSelectedGroomId(postId);
    setGroomReply("");
    setGroomReplyNotice("");
    clearGroomToastTimer();
    if (nextPost) markGroomViewed(nextPost);
  }

  function closeGroomViewer() {
    setSelectedGroomId(null);
    setGroomOpenOrigin(null);
    setGroomReply("");
    setGroomReplyNotice("");
    clearGroomToastTimer();
  }

  function clearGroomToastTimer() {
    if (!groomToastTimerRef.current) return;
    clearTimeout(groomToastTimerRef.current);
    groomToastTimerRef.current = null;
  }

  function markGroomViewed(post: GroomPost) {
    const key = groomAccountKey(post);
    setViewedGroomKeys((current) => {
      const next = new Set(current);
      next.add(key);
      return next;
    });
    if (user && isUuidLike(post.id)) {
      markGroomPostViewed(user.id, post.id).catch(() => undefined);
    }
  }

  async function publishGroom(payload: GroomPublishPayload) {
    if (!groomDraftUri) return;
    const draftUri = groomDraftUri;
    const draftBase64 = groomDraftBase64;
    const draftContentType = groomDraftContentType;
    const optimisticId = `groom-mine-${Date.now()}`;
    const newPost: GroomPost = {
      id: optimisticId,
      author: null,
      caption: payload.caption.trim(),
      doodles: payload.doodles,
      imageUri: draftUri,
      imageTransform: payload.imageTransform,
      liked: false,
      mine: true,
      placeHint: "今日の現場付近",
      stickers: payload.stickers,
      textOverlays: payload.textOverlays,
      timeLabel: "たった今",
    };
    setGroomPosts((current) => [newPost, ...current]);
    setGroomDraftUri(null);
    setGroomDraftBase64(null);
    setGroomDraftContentType(null);
    setGroomDraftCaption("");
    if (previewMode || !user) return;
    try {
      const remotePost = await createGroomPost(user.id, {
        caption: payload.caption.trim(),
        doodles: payload.doodles,
        imageBase64: draftBase64,
        imageContentType: draftContentType,
        imageTransform: payload.imageTransform,
        imageUri: draftUri,
        placeHint: "今日の現場付近",
        stickers: payload.stickers,
        textOverlays: payload.textOverlays,
      });
      setGroomPosts((current) =>
        current.map((post) => (post.id === optimisticId ? remotePostToGroomPost(remotePost) : post)),
      );
      setViewedGroomKeys((current) => {
        const next = new Set(current);
        next.add(groomAccountKey(remotePostToGroomPost(remotePost)));
        return next;
      });
    } catch (error) {
      console.warn("Failed to publish groom post", error);
      setGroomPosts((current) => current.filter((post) => post.id !== optimisticId));
      setGroomDraftUri(draftUri);
      setGroomDraftBase64(draftBase64);
      setGroomDraftContentType(draftContentType);
      setGroomDraftCaption(payload.caption.trim());
      Alert.alert(
        "グルームを保存できませんでした",
        groomPublishFailureMessage(error),
      );
    }
  }

  function toggleGroomLike(postId: string) {
    const target = groomPosts.find((post) => post.id === postId);
    const nextLiked = !target?.liked;
    setGroomPosts((current) =>
      current.map((post) => (post.id === postId ? { ...post, liked: !post.liked } : post)),
    );
    if (user && isUuidLike(postId)) {
      setGroomPostLiked(user.id, postId, nextLiked).catch(() => {
        setGroomPosts((current) =>
          current.map((post) =>
            post.id === postId ? { ...post, liked: target?.liked ?? false } : post,
          ),
        );
      });
    }
  }

  function removeGroomPostLocally(postId: string) {
    setGroomPosts((current) => current.filter((post) => post.id !== postId));
    if (selectedGroomId === postId) closeGroomViewer();
  }

  function openGroomActions(post: GroomPost) {
    const actions = post.mine
      ? [
          {
            destructive: true,
            label: "投稿を削除",
            onPress: () => confirmDeleteGroomPost(post),
          },
        ]
      : [
          {
            label: "このグルームを非表示",
            onPress: () => hideGroomPostFromFeed(post),
          },
          {
            label: "通報する",
            onPress: () => reportGroomPostFromFeed(post),
          },
          {
            destructive: true,
            label: "このユーザーをブロック",
            onPress: () => confirmBlockGroomAuthor(post),
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
        },
        (buttonIndex) => actions[buttonIndex]?.onPress(),
      );
      return;
    }

    actions[0]?.onPress();
  }

  function confirmDeleteGroomPost(post: GroomPost) {
    Alert.alert("グルームを削除しますか？", "この投稿は一覧から表示されなくなります。", [
      { style: "cancel", text: "キャンセル" },
      {
        onPress: () => deleteGroomPostFromFeed(post),
        style: "destructive",
        text: "削除",
      },
    ]);
  }

  async function deleteGroomPostFromFeed(post: GroomPost) {
    removeGroomPostLocally(post.id);
    if (!user || !isUuidLike(post.id)) return;
    try {
      await archiveGroomPost(user.id, post.id);
    } catch {
      Alert.alert("削除できませんでした", "通信状況を確認して、もう一度お試しください。");
      refreshGroomPosts().catch(() => undefined);
    }
  }

  async function hideGroomPostFromFeed(post: GroomPost) {
    removeGroomPostLocally(post.id);
    if (!user || !isUuidLike(post.id)) return;
    try {
      await hideGroomPost(user.id, post.id);
    } catch {
      Alert.alert("非表示にできませんでした", "通信状況を確認して、もう一度お試しください。");
      refreshGroomPosts().catch(() => undefined);
    }
  }

  async function reportGroomPostFromFeed(post: GroomPost) {
    if (!post.author || !user || !isUuidLike(post.id) || !isUuidLike(post.author.id)) {
      removeGroomPostLocally(post.id);
      return;
    }
    removeGroomPostLocally(post.id);
    try {
      await reportGroomPost(user.id, post.id, post.author.id);
      await hideGroomPost(user.id, post.id);
      Alert.alert("通報しました", "このグルームは非表示にしました。");
    } catch {
      Alert.alert("通報できませんでした", "通信状況を確認して、もう一度お試しください。");
      refreshGroomPosts().catch(() => undefined);
    }
  }

  function confirmBlockGroomAuthor(post: GroomPost) {
    if (!post.author) return;
    Alert.alert(`${post.author.name}さんをブロックしますか？`, "相手のグルームとめぐりあいメッセージが表示されにくくなります。", [
      { style: "cancel", text: "キャンセル" },
      {
        onPress: () => blockGroomAuthorFromFeed(post),
        style: "destructive",
        text: "ブロック",
      },
    ]);
  }

  async function blockGroomAuthorFromFeed(post: GroomPost) {
    const authorId = post.author?.id;
    if (!authorId) return;
    setGroomPosts((current) => current.filter((item) => item.author?.id !== authorId));
    closeGroomViewer();
    if (!user || !isUuidLike(authorId)) return;
    try {
      await blockGroomUser(user.id, authorId);
    } catch {
      Alert.alert("ブロックできませんでした", "通信状況を確認して、もう一度お試しください。");
      refreshGroomPosts().catch(() => undefined);
    }
  }

  async function sendGroomReply() {
    const post = selectedGroomPost;
    const body = groomReply.trim();
    if (!post || !body) return;
    setGroomReply("");
    setGroomReplyNotice("メッセージが送信されました");
    clearGroomToastTimer();
    groomToastTimerRef.current = setTimeout(() => {
      setGroomReplyNotice("");
      groomToastTimerRef.current = null;
    }, 1800);
    if (post.author) {
      try {
        await appendMeguriGroomReply({
          body,
          groomCaption: post.caption,
          groomId: post.id,
          groomImagePath: post.imagePath ?? null,
          groomImageUri: post.imageUri,
          recipientId: post.author.id,
          recipientName: post.author.name,
        });
      } catch {
        // 送信UIは維持し、ローカル保存の失敗だけ握りつぶす。
      }
    }
  }

  return (
    <Screen
      bottomInset={false}
      contentStyle={styles.screenShell}
      scroll={false}
      topInset={false}
    >
      <ScrollView
        automaticallyAdjustsScrollIndicatorInsets={false}
        contentContainerStyle={[
          styles.screen,
          { paddingBottom: bottomPadding, paddingTop: headerTop + 48 },
        ]}
        contentInsetAdjustmentBehavior="never"
        showsVerticalScrollIndicator={false}
      >
        <GroomRail
          loading={groomLoading}
          onAdd={openGroomCamera}
          onOpen={openGroomPost}
          posts={groomPosts}
          viewedKeys={viewedGroomKeys}
        />

        <View style={styles.stageCard}>
          <View style={styles.cloudA} />
          <View style={styles.cloudB} />
          <Pressable
            accessibilityRole="button"
            onPress={() => router.push("/meguri-intro")}
            style={styles.replayButton}
          >
            <Text style={styles.replayButtonText}>演出をもう一度見る</Text>
          </Pressable>
          <Text style={[styles.eyebrow, styles.centerEyebrow]}>今日のめぐり</Text>
          <View style={styles.countRow}>
            <Text style={styles.bigCount}>{todayCount}</Text>
            <Text style={styles.countUnit}>人</Text>
          </View>
          <Text style={styles.stageTitle}>とめぐりあいました！</Text>

          <View style={styles.homeSceneFrame}>
            {!selfScene ? (
              <View style={styles.meguriSceneLoading}>
                <ActivityIndicator color={ihubColors.lavender} />
              </View>
            ) : homeThreeFailed ? (
              <View style={styles.meguriSceneLoading}>
                <ActivityIndicator color={ihubColors.lavender} />
              </View>
            ) : (
              <MeguriThreeBoundary
                fallback={
                  <View style={styles.meguriSceneLoading}>
                    <ActivityIndicator color={ihubColors.lavender} />
                  </View>
                }
                onError={() => setHomeThreeFailed(true)}
              >
                <MeguriThreeScene
                  activeId={null}
                  completedIds={[]}
                  introPhase="ready"
                  mode="summary"
                  onUnavailable={() => setHomeThreeFailed(true)}
                  presentation="home"
                  residents={sceneResidents}
                  self={selfScene}
                  smilingId={active.id}
                />
              </MeguriThreeBoundary>
            )}

            <View style={styles.speechBubble}>
              <Text style={styles.speechText}>「{active.recent}」</Text>
              <View
                style={[
                  styles.bubbleTail,
                  { left: `${12 + activeIndex * 19}%` },
                ]}
              />
            </View>
          </View>
        </View>

        <View style={styles.statsRow}>
          <NumLine value={todayCount} label="今日のめぐり" />
          <NumLine value={14} label="出会った人" />
          <NumLine value={lockedLetters} label="未読メッセージ" />
        </View>

        <View style={styles.shortcutGrid}>
          <ShortcutCard title="広場" subtitle="14人とめぐり" hue="lav" onPress={() => router.push("/meguri-plaza")} />
          <ShortcutCard title="マップ" subtitle="47 都道府県" hue="sky" onPress={() => router.push("/meguri-map")} />
          <ShortcutCard title="実績" subtitle="3 / 4 達成" hue="pink" onPress={() => router.push("/meguri-achievements")} />
          <ShortcutCard title="今日のレポート" subtitle="軽く振り返り" hue="butter" onPress={() => router.push("/meguri-report")} />
        </View>

        <View style={styles.hitokotoCard}>
          <View style={styles.hitokotoIcon}>
            <IconSymbol name="create-outline" color={ihubColors.lavender} size={20} />
          </View>
          <View style={styles.hitokotoCopy}>
            <Text style={styles.hitokotoTitle}>今日のひとこと</Text>
            <Text style={styles.hitokotoSub}>お題: 最近の推し活は？</Text>
          </View>
          <Pressable onPress={() => router.push("/meguri-hitokoto")} style={styles.hitokotoButton}>
            <Text style={styles.hitokotoButtonText}>書く</Text>
          </Pressable>
        </View>
      </ScrollView>

      <View pointerEvents="box-none" style={[styles.fixedHeader, { top: headerTop }]}>
        <Pressable
          accessibilityLabel="めぐり設定"
          accessibilityRole="button"
          onPress={() => setSettingsOpen(true)}
          style={styles.settingsButton}
        >
          <IconSymbol name="settings-outline" color={ihubColors.ink} size={20} />
        </Pressable>
      </View>

      <MeguriSettingsModal
        enabled={meguriEnabled}
        onAvatarEdit={() => {
          setSettingsOpen(false);
          router.push("/meguri-avatar-edit");
        }}
        onClose={() => setSettingsOpen(false)}
        onProfileEdit={() => {
          setSettingsOpen(false);
          router.push("/meguri-profile-edit");
        }}
        onToggle={() => setMeguriEnabled((current) => !current)}
        open={settingsOpen}
      />

      {selectedGroomPost ? (
        <GroomViewerModal
          key={`groom-viewer-${groomViewerSession}`}
          feedback={groomReplyNotice}
          onChangeReply={setGroomReply}
          onClose={closeGroomViewer}
          onLike={() => toggleGroomLike(selectedGroomPost.id)}
          onOpenActions={openGroomActions}
          openOrigin={groomOpenOrigin}
          onSelectPost={selectGroomPost}
          onSendReply={sendGroomReply}
          post={selectedGroomPost}
          posts={groomPosts}
          reply={groomReply}
        />
      ) : null}

      <GroomCameraModal
        onCapture={openGroomEditor}
        onClose={() => setGroomCameraOpen(false)}
        visible={groomCameraOpen}
      />

      <GroomComposerModal
        caption={groomDraftCaption}
        draftUri={groomDraftUri}
        onChangeCaption={setGroomDraftCaption}
        onClose={() => {
          setGroomDraftUri(null);
          setGroomDraftBase64(null);
          setGroomDraftContentType(null);
          setGroomDraftCaption("");
        }}
        onPublish={publishGroom}
        onRetake={() => {
          setGroomDraftUri(null);
          setGroomDraftBase64(null);
          setGroomDraftContentType(null);
          setGroomDraftCaption("");
          openGroomCamera();
        }}
      />
    </Screen>
  );
}

function toHomeSceneResident(user: MeguriUser): MeguriSceneResident {
  return {
    animalType: user.animalType,
    furColor: user.furColor,
    hue: user.hue,
    id: user.id,
    name: user.name,
  };
}

function groomAuthorName(post: GroomPost) {
  if (post.mine) return "あなた";
  return post.author?.name ?? "めぐり";
}

function groomAccountKey(post: GroomPost) {
  if (post.mine) return "mine";
  return post.author?.id ?? post.id;
}

function groomAccountGroups(posts: GroomPost[]): GroomAccountGroup[] {
  const groups: GroomAccountGroup[] = [];
  const groupByKey = new Map<string, GroomAccountGroup>();
  for (const post of posts) {
    const key = groomAccountKey(post);
    const existing = groupByKey.get(key);
    if (existing) {
      existing.posts.push(post);
      continue;
    }
    const next = { key, posts: [post] };
    groupByKey.set(key, next);
    groups.push(next);
  }
  return groups;
}

function groomPostPublishedTime(post: GroomPost) {
  if (!post.publishedAt) return null;
  const time = Date.parse(post.publishedAt);
  return Number.isFinite(time) ? time : null;
}

function groomStoryPosts(posts: GroomPost[]) {
  const indexed = posts.map((post, index) => ({
    index,
    post,
    time: groomPostPublishedTime(post),
  }));
  if (!indexed.some((item) => item.time !== null)) return posts;
  return indexed
    .sort((a, b) => {
      if (a.time === null && b.time === null) return a.index - b.index;
      if (a.time === null) return a.index - b.index;
      if (b.time === null) return a.index - b.index;
      return a.time - b.time || a.index - b.index;
    })
    .map((item) => item.post);
}

function groomInitialStoryPost(group: GroomAccountGroup | null | undefined) {
  if (!group) return null;
  return groomStoryPosts(group.posts)[0] ?? null;
}

function groomLatestStoryPost(group: GroomAccountGroup | null | undefined) {
  if (!group) return null;
  const posts = groomStoryPosts(group.posts);
  return posts[posts.length - 1] ?? null;
}

function normalizeGroomOpenOrigin(origin: GroomOpenOrigin | null | undefined) {
  if (!origin) return null;
  const values = [origin.x, origin.y, origin.width, origin.height];
  if (values.some((value) => !Number.isFinite(value))) return null;
  if (origin.width <= 0 || origin.height <= 0) return null;
  return origin;
}

function GroomRail({
  loading,
  onAdd,
  onOpen,
  posts,
  viewedKeys,
}: {
  loading: boolean;
  onAdd: () => void;
  onOpen: (post: GroomPost, origin?: GroomOpenOrigin | null) => void;
  posts: GroomPost[];
  viewedKeys: Set<string>;
}) {
  const groups = useMemo(() => groomAccountGroups(posts), [posts]);
  return (
    <View style={styles.groomRail}>
      <Text style={styles.groomRailTitle}>グルーム</Text>
      <ScrollView
        horizontal
        contentContainerStyle={styles.groomListContent}
        showsHorizontalScrollIndicator={false}
      >
        <Pressable
          accessibilityLabel="グルームを追加"
          accessibilityRole="button"
          onPress={onAdd}
          style={styles.groomStoryItem}
        >
          <View style={[styles.groomAvatarRing, styles.groomAddRing]}>
            <View style={styles.groomAddCircle}>
              <IconSymbol name="add" color={ihubColors.lavender} size={28} />
            </View>
          </View>
          <Text numberOfLines={1} style={styles.groomStoryName}>
            追加
          </Text>
        </Pressable>

        {loading ? (
          <View style={styles.groomRailLoading}>
            <ActivityIndicator color={ihubColors.lavender} />
          </View>
        ) : null}

        {!loading && groups.map((group) => {
          const post = groomLatestStoryPost(group);
          const initialPost = groomInitialStoryPost(group);
          if (!post || !initialPost) return null;
          return (
            <GroomRailItem
              key={group.key}
              initialPost={initialPost}
              onOpen={onOpen}
              post={post}
              viewed={viewedKeys.has(group.key)}
            />
          );
        })}
      </ScrollView>
    </View>
  );
}

function GroomRailItem({
  initialPost,
  onOpen,
  post,
  viewed,
}: {
  initialPost: GroomPost;
  onOpen: (post: GroomPost, origin?: GroomOpenOrigin | null) => void;
  post: GroomPost;
  viewed: boolean;
}) {
  const ringRef = useRef<View>(null);
  const openingRef = useRef(false);

  function openFromRing() {
    if (openingRef.current) return;
    openingRef.current = true;
    let fallbackLockTimer: ReturnType<typeof setTimeout> | null = setTimeout(() => {
      openingRef.current = false;
      fallbackLockTimer = null;
    }, 520);
    const releaseOpeningLock = () => {
      if (fallbackLockTimer) {
        clearTimeout(fallbackLockTimer);
        fallbackLockTimer = null;
      }
      setTimeout(() => {
        openingRef.current = false;
      }, 320);
    };
    const ring = ringRef.current;
    if (!ring) {
      onOpen(initialPost, null);
      releaseOpeningLock();
      return;
    }
    ring.measureInWindow((x, y, width, height) => {
      const origin = normalizeGroomOpenOrigin({ height, width, x, y });
      if (!origin) {
        onOpen(initialPost, null);
        releaseOpeningLock();
        return;
      }
      onOpen(initialPost, origin);
      releaseOpeningLock();
    });
  }

  return (
    <Pressable
      accessibilityLabel={`${groomAuthorName(post)}のグルームを見る`}
      accessibilityRole="button"
      onPress={openFromRing}
      style={styles.groomStoryItem}
    >
      <View
        ref={ringRef}
        style={[
          styles.groomAvatarRing,
          post.liked ? styles.groomAvatarRingLiked : null,
          viewed ? styles.groomAvatarRingViewed : null,
        ]}
      >
        <Image source={{ uri: post.imageUri }} style={styles.groomAvatarImage} />
      </View>
      <Text numberOfLines={1} style={styles.groomStoryName}>
        {groomAuthorName(post)}
      </Text>
    </Pressable>
  );
}

function GroomViewerModal({
  feedback,
  onChangeReply,
  onClose,
  onLike,
  onOpenActions,
  openOrigin,
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
  onOpenActions: (post: GroomPost) => void;
  openOrigin: GroomOpenOrigin | null;
  onSelectPost: (postId: string) => void;
  onSendReply: () => void;
  post: GroomPost | null;
  posts: GroomPost[];
  reply: string;
}) {
  const insets = useSafeAreaInsets();
  const { height, width } = useWindowDimensions();
  const keyboardInset = useKeyboardInset();
  const progress = useRef(new Animated.Value(0)).current;
  const progressValueRef = useRef(0);
  const replyInputRef = useRef<TextInput>(null);
  const swipeX = useRef(new Animated.Value(0)).current;
  const dismissY = useRef(new Animated.Value(0)).current;
  const openProgress = useRef(new Animated.Value(1)).current;
  const viewerWasOpenRef = useRef(false);
  const gestureMode = useRef<"horizontal" | "vertical" | null>(null);
  const [replyFocused, setReplyFocused] = useState(false);
  const [horizontalSwiping, setHorizontalSwiping] = useState(false);
  const horizontalSwipingRef = useRef(false);
  const [profileUser, setProfileUser] = useState<GroomProfileUser | null>(null);
  const canSend = reply.trim().length > 0;
  const accountGroups = useMemo(() => groomAccountGroups(posts), [posts]);
  const currentAccountKey = post ? groomAccountKey(post) : null;
  const currentAccountIndex = currentAccountKey
    ? accountGroups.findIndex((item) => item.key === currentAccountKey)
    : -1;
  const currentGroup =
    currentAccountIndex >= 0 ? accountGroups[currentAccountIndex] ?? null : null;
  const currentGroupPosts = useMemo(
    () => (currentGroup ? groomStoryPosts(currentGroup.posts) : []),
    [currentGroup],
  );
  const currentPostIndex =
    currentGroup && post
      ? currentGroupPosts.findIndex((item) => item.id === post.id)
      : -1;
  const previousAccountGroup =
    currentAccountIndex > 0 ? accountGroups[currentAccountIndex - 1] ?? null : null;
  const nextAccountGroup =
    currentAccountIndex >= 0 && currentAccountIndex < accountGroups.length - 1
      ? accountGroups[currentAccountIndex + 1] ?? null
      : null;
  const previousAccountPosts = useMemo(
    () => (previousAccountGroup ? groomStoryPosts(previousAccountGroup.posts) : []),
    [previousAccountGroup],
  );
  const nextAccountPosts = useMemo(
    () => (nextAccountGroup ? groomStoryPosts(nextAccountGroup.posts) : []),
    [nextAccountGroup],
  );
  const previousAccountPost = previousAccountPosts[previousAccountPosts.length - 1] ?? null;
  const nextAccountPost = nextAccountPosts[0] ?? null;

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
	    if (!currentGroup || currentPostIndex < 0) return;
	    const nextPostIndex = currentPostIndex + offset;
	    if (nextPostIndex >= 0 && nextPostIndex < currentGroupPosts.length) {
	      onSelectPost(currentGroupPosts[nextPostIndex].id);
	      return;
	    }
	    const hasRelativeAccount =
	      offset > 0
	        ? currentAccountIndex < accountGroups.length - 1
	        : currentAccountIndex > 0;
	    if (!hasRelativeAccount && offset < 0) return;
	    selectRelativeAccount(offset);
	  }

  function selectRelativeAccount(offset: -1 | 1) {
    if (currentAccountIndex < 0) return;
    const nextIndex = currentAccountIndex + offset;
    if (nextIndex < 0 || nextIndex >= accountGroups.length) {
      if (offset > 0) onClose();
      return;
    }
    const nextGroup = accountGroups[nextIndex] ?? null;
    const nextPost = offset > 0 ? groomInitialStoryPost(nextGroup) : groomLatestStoryPost(nextGroup);
    if (nextPost) onSelectPost(nextPost.id);
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
	      selectRelativeAccount(offset);
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
      dismissY.setValue(0);
      swipeX.setValue(0);
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

  function openProfileFromGroom(postToOpen: GroomPost) {
    if (!postToOpen.author) return;
    dismissReplyInput();
    setProfileUser(postToOpen.author);
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
          const clamped = Math.max(-width, Math.min(width, gesture.dx));
          swipeX.setValue(clamped);
        },
        onPanResponderRelease: (_, gesture) => {
          if (gestureMode.current === "vertical") {
            if (gesture.dy > 88 || gesture.vy > 0.9) {
              closeWithDismiss();
            } else {
              resetDismiss();
            }
            setHorizontalSwipeActive(false);
            gestureMode.current = null;
            return;
          }
          if (gesture.dx < -62 && nextAccountPost) {
            finishSwipe(1);
            gestureMode.current = null;
            return;
          }
          if (gesture.dx > 62 && previousAccountPost) {
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
    [accountGroups, currentAccountIndex, height, nextAccountPost, previousAccountPost, width],
  );

  useEffect(() => {
    const listenerId = progress.addListener(({ value }) => {
      progressValueRef.current = value;
    });
    return () => progress.removeListener(listenerId);
  }, [progress]);

  useLayoutEffect(() => {
    let openingAnimation: Animated.CompositeAnimation | null = null;
    swipeX.setValue(0);
    dismissY.setValue(0);
    progress.stopAnimation();
    progressValueRef.current = 0;
    progress.setValue(0);

    const wasOpen = viewerWasOpenRef.current;
    if (!post) {
      viewerWasOpenRef.current = false;
      openProgress.stopAnimation();
      openProgress.setValue(1);
      return undefined;
    }

    if (!wasOpen && openOrigin) {
      openProgress.stopAnimation();
      openProgress.setValue(0);
      openingAnimation = Animated.timing(openProgress, {
        toValue: 1,
        duration: 165,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: false,
      });
      openingAnimation.start();
    } else {
      openProgress.setValue(1);
    }
    viewerWasOpenRef.current = true;

    return () => {
      openingAnimation?.stop();
    };
  }, [dismissY, openOrigin, openProgress, post?.id, progress, swipeX]);

  useEffect(() => {
    let animation: Animated.CompositeAnimation | null = null;
    let cancelled = false;

    progress.stopAnimation((value) => {
      progressValueRef.current = value;
      if (cancelled || !post || replyFocused || profileUser || horizontalSwiping) return;

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
  }, [horizontalSwiping, post?.id, profileUser, progress, replyFocused]);

  useEffect(() => {
    const hideSubscription = Keyboard.addListener("keyboardDidHide", () => {
      setReplyFocused(false);
    });
    return () => hideSubscription.remove();
  }, []);

	  const iconTargetX = (() => {
	    if (currentAccountIndex < 0) return 0;
	    const railLeft = 18;
	    const addItemWidth = 93;
	    const itemCenter = railLeft + addItemWidth + currentAccountIndex * 93 + 37;
	    return itemCenter - width / 2;
	  })();
  const dismissDragY = dismissY.interpolate({
    inputRange: [0, height * 0.72],
    outputRange: [0, height * 0.22],
    extrapolate: "clamp",
  });
  const dismissTargetY = -height * 0.48;
  const dismissTranslateX = dismissY.interpolate({
    inputRange: [0, height * 0.72],
    outputRange: [0, iconTargetX],
    extrapolate: "clamp",
  });
  const dismissTranslateYToIcon = dismissY.interpolate({
    inputRange: [0, height * 0.72],
    outputRange: [0, dismissTargetY],
    extrapolate: "clamp",
  });
  const dismissScale = dismissY.interpolate({
    inputRange: [0, height * 0.72],
    outputRange: [1, 0.08],
    extrapolate: "clamp",
  });
  const dismissOpacity = dismissY.interpolate({
    inputRange: [0, height * 0.55],
    outputRange: [1, 0.18],
    extrapolate: "clamp",
  });
  const dismissBackdropOpacity = dismissY.interpolate({
    inputRange: [0, height * 0.55],
    outputRange: [0.48, 0],
    extrapolate: "clamp",
  });
  const openStartCenterX = openOrigin ? openOrigin.x + openOrigin.width / 2 : width / 2;
  const openStartCenterY = openOrigin ? openOrigin.y + openOrigin.height / 2 : height / 2;
  const openStartScale = openOrigin
    ? Math.max(0.1, Math.min(0.24, openOrigin.width / Math.max(width, 1)))
    : 1;
  const openTranslateX = openProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [openStartCenterX - width / 2, 0],
  });
  const openTranslateY = openProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [openStartCenterY - height / 2, 0],
  });
  const openScale = openProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [openStartScale, 1],
  });
  const openBorderRadius = openProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [999, 0],
    extrapolate: "clamp",
  });
  const openFrameOpacity = openProgress.interpolate({
    inputRange: [0, 0.18, 1],
    outputRange: [0, 1, 1],
    extrapolate: "clamp",
  });
  const viewerBackdropOpacity = Animated.multiply(dismissBackdropOpacity, openProgress);
  const staticChromeOpacity = swipeX.interpolate({
    inputRange: [-2, 0, 2],
    outputRange: [0, 1, 0],
    extrapolate: "clamp",
  });
  const chromeTopPadding = Math.max(insets.top, 14) + 8;
  const chromeFooterBottom = Math.max(insets.bottom, 12) + 10 + keyboardInset;
  const currentChrome = post ? (
    <GroomStoryAttachedChrome
      canSend={canSend}
      footerBottom={chromeFooterBottom}
      headerTop={chromeTopPadding}
      post={post}
      progress={progress}
      progressIndex={Math.max(currentPostIndex, 0)}
      progressPosts={currentGroupPosts.length ? currentGroupPosts : post ? [post] : []}
      reply={reply}
    />
  ) : null;

  return (
    <Modal
      animationType="none"
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
        <View style={styles.groomViewer}>
          <Animated.View
            pointerEvents="none"
            style={[styles.groomViewerBackdrop, { opacity: viewerBackdropOpacity }]}
          />
          <Animated.View
            style={[
              styles.groomOpenFrame,
              {
                borderRadius: openBorderRadius,
                opacity: openFrameOpacity,
                transform: [
                  { scale: openScale },
                  { translateX: openTranslateX },
                  { translateY: openTranslateY },
                ],
              },
            ]}
          >
            <Animated.View
              style={[
                styles.groomDismissFrame,
                {
                  opacity: dismissOpacity,
                  transform: [
                    { translateY: dismissDragY },
                    { translateX: dismissTranslateX },
                    { translateY: dismissTranslateYToIcon },
                    { scale: dismissScale },
                  ],
                },
              ]}
              {...panResponder.panHandlers}
            >
              <GroomStoryCube
                currentChrome={currentChrome}
                currentPost={post}
                nextChrome={
                  nextAccountPost ? (
                    <GroomStoryAttachedChrome
                      canSend={false}
                      footerBottom={chromeFooterBottom}
                      headerTop={chromeTopPadding}
                      post={nextAccountPost}
                      progressPosts={nextAccountPosts}
                      reply=""
                    />
                  ) : null
                }
                nextPost={nextAccountPost}
                previousChrome={
                  previousAccountPost ? (
                    <GroomStoryAttachedChrome
                      canSend={false}
                      footerBottom={chromeFooterBottom}
                      headerTop={chromeTopPadding}
                      post={previousAccountPost}
                      progressIndex={Math.max(previousAccountPosts.length - 1, 0)}
                      progressPosts={previousAccountPosts}
                      reply=""
                    />
                  ) : null
                }
                previousPost={previousAccountPost}
                swipeX={swipeX}
                width={width}
              />

              <Animated.View
                style={[
                  styles.groomViewerHeader,
                  { opacity: staticChromeOpacity, paddingTop: chromeTopPadding },
                ]}
              >
                <GroomProgressBar
                  currentIndex={Math.max(currentPostIndex, 0)}
                  posts={currentGroupPosts.length ? currentGroupPosts : post ? [post] : []}
                  progress={progress}
                />
                <View style={styles.groomViewerHeaderRow}>
                  <Pressable
                    accessibilityLabel={`${groomAuthorName(post)}のめぐりプロフィールを開く`}
                    accessibilityRole="button"
                    disabled={!post.author}
                    onPress={() => openProfileFromGroom(post)}
                    style={({ pressed }) => [
                      styles.groomViewerAuthor,
                      pressed ? styles.groomViewerAuthorPressed : null,
                      !post.author ? styles.groomViewerAuthorDisabled : null,
                    ]}
                  >
                    <GroomFaceAvatar post={post} />
                    <View style={styles.groomViewerNameWrap}>
                      <Text numberOfLines={1} style={styles.groomViewerName}>
                        {groomAuthorName(post)}
                      </Text>
                      <Text numberOfLines={1} style={styles.groomViewerMeta}>
                        {post.timeLabel}
                      </Text>
                    </View>
                  </Pressable>
                  <Pressable
                    accessibilityLabel="グルームのメニューを開く"
                    accessibilityRole="button"
                    onPress={() => onOpenActions(post)}
                    style={styles.groomViewerMenuButton}
                  >
                    <IconSymbol name="ellipsis-horizontal" color="#fff" size={25} />
                  </Pressable>
                </View>
              </Animated.View>

              <View pointerEvents="box-none" style={styles.groomTapLayer}>
                <Pressable
                  accessibilityLabel="前のグルームへ"
                  accessibilityRole="button"
                  onPress={() => selectRelativePost(-1)}
                  style={styles.groomTapZone}
                />
                <Pressable
                  accessibilityLabel="次のグルームへ"
                  accessibilityRole="button"
                  onPress={() => selectRelativePost(1)}
                  style={styles.groomTapZone}
                />
              </View>

              {post.caption.trim() ? (
                <Animated.View style={[styles.groomCaptionPanel, { opacity: staticChromeOpacity }]}>
                  {post.caption.trim() ? (
                    <Text style={styles.groomCaptionText}>{post.caption}</Text>
                  ) : null}
                </Animated.View>
              ) : null}

              {feedback ? (
                <View pointerEvents="none" style={styles.groomCenterToast}>
                  <Text style={styles.groomCenterToastText}>{feedback}</Text>
                </View>
              ) : null}

              {replyFocused ? (
                <Pressable
                  accessibilityLabel="メッセージ入力を閉じる"
                  accessibilityRole="button"
                  onPress={dismissReplyInput}
                  style={[
                    styles.groomInputDimmer,
                    { bottom: Math.max(insets.bottom, 12) + 78 + keyboardInset },
                  ]}
                />
              ) : null}

              <Animated.View
                style={[
                  styles.groomViewerFooter,
                  { opacity: staticChromeOpacity, paddingBottom: chromeFooterBottom },
                ]}
              >
                <View style={styles.groomReplyRow}>
                  <TextInput
                    maxLength={180}
                    multiline
                    onChangeText={onChangeReply}
                    onBlur={() => setReplyFocused(false)}
                    onFocus={() => setReplyFocused(true)}
                    placeholder="メッセージを送信..."
                    placeholderTextColor="rgba(255,255,255,0.78)"
                    ref={replyInputRef}
                    scrollEnabled={false}
                    style={styles.groomReplyInput}
                    value={reply}
                  />
                  <Pressable
                    accessibilityLabel={post.liked ? "いいねを取り消す" : "いいねする"}
                    accessibilityRole="button"
                    onPress={onLike}
                    style={styles.groomViewerAction}
                  >
                    <IconSymbol
                      name={post.liked ? "heart" : "heart-outline"}
                      color={post.liked ? ihubColors.pink : "#fff"}
                      size={31}
                    />
                  </Pressable>
                  <Pressable
                    accessibilityLabel="メッセージを送信"
                    accessibilityRole="button"
                    disabled={!canSend}
                    onPress={sendReplyAndDismiss}
                    style={[styles.groomViewerAction, !canSend ? styles.groomSendButtonDisabled : null]}
                  >
                    <IconSymbol name="send-outline" color="#fff" size={31} />
                  </Pressable>
                </View>
              </Animated.View>
              <GroomProfileSlidePanel
                onClose={() => setProfileUser(null)}
                onReply={focusReplyInputAfterProfile}
                user={profileUser}
              />
            </Animated.View>
          </Animated.View>
        </View>
      ) : null}
    </Modal>
  );
}

function GroomStoryCube({
  currentPost,
  currentChrome,
  nextPost,
  nextChrome,
  previousPost,
  previousChrome,
  swipeX,
  width,
}: {
  currentPost: GroomPost;
  currentChrome?: ReactNode;
  nextPost: GroomPost | null;
  nextChrome?: ReactNode;
  previousPost: GroomPost | null;
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
    <View style={styles.groomCubeStage}>
      {previousPost ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.groomStoryFace,
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
          <GroomStoryFaceContent
            chrome={previousChrome}
            post={previousPost}
            shadeOpacity={previousShadeOpacity}
          />
        </Animated.View>
      ) : null}
      {nextPost ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.groomStoryFace,
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
          <GroomStoryFaceContent chrome={nextChrome} post={nextPost} shadeOpacity={nextShadeOpacity} />
        </Animated.View>
      ) : null}
      <Animated.View
        pointerEvents="none"
        style={[
          styles.groomStoryFace,
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
        <GroomStoryFaceContent
          chrome={currentChrome}
          chromeOpacity={currentToNextChromeOpacity}
          post={currentPost}
          shadeOpacity={currentToNextShadeOpacity}
        />
      </Animated.View>
      <Animated.View
        pointerEvents="none"
        style={[
          styles.groomStoryFace,
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
        <GroomStoryFaceContent
          chrome={currentChrome}
          chromeOpacity={currentToPreviousChromeOpacity}
          post={currentPost}
          shadeOpacity={currentToPreviousShadeOpacity}
        />
      </Animated.View>
    </View>
  );
}

function GroomStoryFaceContent({
  chrome,
  chromeOpacity = 1,
  post,
  shadeOpacity,
}: {
  chrome?: ReactNode;
  chromeOpacity?: number | Animated.AnimatedInterpolation<number>;
  post: GroomPost;
  shadeOpacity?: number | Animated.AnimatedInterpolation<number>;
}) {
  return (
    <>
      <GroomStoryImageLayer transform={post.imageTransform} uri={post.imageUri} />
      <GroomStoryDecorations
        doodles={post.doodles ?? []}
        stickers={post.stickers ?? []}
        textOverlays={post.textOverlays ?? []}
      />
      {shadeOpacity !== undefined ? (
        <Animated.View
          pointerEvents="none"
          style={[styles.groomStoryCubeShade, { opacity: shadeOpacity }]}
        />
      ) : null}
      {chrome ? (
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

function GroomStoryImageLayer({
  transform,
  uri,
}: {
  transform?: GroomImageTransform;
  uri: string;
}) {
  const [canvasSize, setCanvasSize] = useState({ height: 1, width: 1 });
  const [imageSize, setImageSize] = useState({ height: 16, width: 9 });
  const safeTransform = transform ?? DEFAULT_GROOM_IMAGE_TRANSFORM;

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

  const canvasWidth = Math.max(canvasSize.width, 1);
  const canvasHeight = Math.max(canvasSize.height, 1);
  const imageAspect = Math.max(imageSize.width, 1) / Math.max(imageSize.height, 1);
  const canvasAspect = canvasWidth / canvasHeight;
  const frameWidth = imageAspect >= canvasAspect ? canvasHeight * imageAspect : canvasWidth;
  const frameHeight = imageAspect >= canvasAspect ? canvasHeight : canvasWidth / imageAspect;
  const left = (canvasWidth - frameWidth) / 2;
  const top = (canvasHeight - frameHeight) / 2;

  if (!transform || isDefaultGroomImageTransform(transform)) {
    return <Image resizeMode="cover" source={{ uri }} style={StyleSheet.absoluteFillObject} />;
  }

  return (
    <View
      onLayout={(event) => {
        const { height, width } = event.nativeEvent.layout;
        setCanvasSize({ height, width });
      }}
      style={StyleSheet.absoluteFillObject}
    >
      <GroomStoryBackdrop />
      <Animated.View
        style={[
          styles.groomStoryImageFrame,
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
        <Image
          resizeMode="cover"
          source={{ uri }}
          style={[StyleSheet.absoluteFillObject, styles.groomStoryForegroundImage]}
        />
      </Animated.View>
    </View>
  );
}

function GroomStoryBackdrop() {
  return (
    <View pointerEvents="none" style={styles.groomStoryBackdrop} />
  );
}

function GroomStoryAttachedChrome({
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
  post: GroomPost;
  progress?: Animated.Value;
  progressIndex?: number;
  progressPosts?: GroomPost[];
  reply: string;
}) {
  const posts = progressPosts?.length ? progressPosts : [post];
  return (
    <>
      <View style={[styles.groomViewerHeader, { paddingTop: headerTop }]}>
        {progress ? (
          <GroomProgressBar currentIndex={progressIndex} posts={posts} progress={progress} />
        ) : (
          <GroomAttachedProgressBar currentIndex={progressIndex} posts={posts} />
        )}
        <View style={styles.groomViewerHeaderRow}>
          <View style={styles.groomViewerAuthor}>
            <GroomFaceAvatar post={post} />
            <View style={styles.groomViewerNameWrap}>
              <Text numberOfLines={1} style={styles.groomViewerName}>
                {groomAuthorName(post)}
              </Text>
              <Text numberOfLines={1} style={styles.groomViewerMeta}>
                {post.timeLabel}
              </Text>
            </View>
          </View>
        </View>
      </View>

      {post.caption.trim() ? (
        <View style={styles.groomCaptionPanel}>
          <Text style={styles.groomCaptionText}>{post.caption}</Text>
        </View>
      ) : null}

      <View style={[styles.groomViewerFooter, { paddingBottom: footerBottom }]}>
        <View style={styles.groomReplyRow}>
          <View style={styles.groomReplyGhost}>
            <Text numberOfLines={1} style={styles.groomReplyGhostText}>
              {reply.trim() || "メッセージを送信..."}
            </Text>
          </View>
          <View style={styles.groomViewerAction}>
            <IconSymbol name={post.liked ? "heart" : "heart-outline"} color={post.liked ? ihubColors.pink : "#fff"} size={31} />
          </View>
          <View style={[styles.groomViewerAction, !canSend ? styles.groomSendButtonDisabled : null]}>
            <IconSymbol name="send-outline" color="#fff" size={31} />
          </View>
        </View>
      </View>
    </>
  );
}

function GroomAttachedProgressBar({
  currentIndex,
  posts,
}: {
  currentIndex: number;
  posts: GroomPost[];
}) {
  return (
    <View style={styles.groomProgressRow}>
      {posts.map((item, index) => (
        <View key={item.id} style={styles.groomProgressTrack}>
          <View style={[styles.groomProgressFill, { width: index < currentIndex ? "100%" : "0%" }]} />
        </View>
      ))}
    </View>
  );
}

function GroomStoryDecorations({
  doodles,
  stickers,
  textOverlays,
}: {
  doodles: GroomDoodleStroke[];
  stickers: GroomStickerOverlay[];
  textOverlays: GroomTextOverlay[];
}) {
  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFillObject}>
      {doodles.map((stroke) =>
        stroke.points.map((point, index) => (
          <View
            key={`${stroke.id}-${index}`}
            style={[
              styles.groomDoodleDot,
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
            styles.groomStoryTextOverlay,
            overlay.tone === "label"
              ? styles.groomStoryTextOverlayLabel
              : overlay.tone === "solid"
                ? styles.groomStoryTextOverlaySolid
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
              styles.groomStoryTextOverlayText,
              { color: overlay.tone === "solid" ? ihubColors.ink : overlay.color },
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
            styles.groomStoryStickerOverlay,
            {
              borderColor: sticker.color,
              left: `${sticker.x * 100}%`,
              top: `${sticker.y * 100}%`,
            },
          ]}
        >
          <Text style={[styles.groomStoryStickerText, { color: sticker.color }]}>
            {sticker.label}
          </Text>
        </View>
      ))}
    </View>
  );
}

function EditableGroomStoryDecorations({
  doodles,
  onEditText,
  onMoveText,
  onStartTextGesture,
  stickers,
  textOverlays,
}: {
  doodles: GroomDoodleStroke[];
  onEditText: (overlay: GroomTextOverlay) => void;
  onMoveText: (
    overlayId: string,
    event: { nativeEvent: { touches?: { pageX: number; pageY: number }[] } },
    gesture: PanResponderGestureState,
  ) => void;
  onStartTextGesture: (
    overlay: GroomTextOverlay,
    event: { nativeEvent: { touches?: { pageX: number; pageY: number }[] } },
  ) => void;
  stickers: GroomStickerOverlay[];
  textOverlays: GroomTextOverlay[];
}) {
  return (
    <View pointerEvents="box-none" style={StyleSheet.absoluteFillObject}>
      <View pointerEvents="none" style={StyleSheet.absoluteFillObject}>
        {doodles.map((stroke) =>
          stroke.points.map((point, index) => (
            <View
              key={`${stroke.id}-${index}`}
              style={[
                styles.groomDoodleDot,
                {
                  backgroundColor: stroke.color,
                  left: `${point.x * 100}%`,
                  top: `${point.y * 100}%`,
                },
              ]}
            />
          )),
        )}
        {stickers.map((sticker) => (
          <View
            key={sticker.id}
            style={[
              styles.groomStoryStickerOverlay,
              {
                borderColor: sticker.color,
                left: `${sticker.x * 100}%`,
                top: `${sticker.y * 100}%`,
              },
            ]}
          >
            <Text style={[styles.groomStoryStickerText, { color: sticker.color }]}>
              {sticker.label}
            </Text>
          </View>
        ))}
      </View>

      {textOverlays.map((overlay) => (
        <EditableGroomTextOverlay
          key={overlay.id}
          onEdit={onEditText}
          onMove={onMoveText}
          onStartGesture={onStartTextGesture}
          overlay={overlay}
        />
      ))}
    </View>
  );
}

function EditableGroomTextOverlay({
  onEdit,
  onMove,
  onStartGesture,
  overlay,
}: {
  onEdit: (overlay: GroomTextOverlay) => void;
  onMove: (
    overlayId: string,
    event: { nativeEvent: { touches?: { pageX: number; pageY: number }[] } },
    gesture: PanResponderGestureState,
  ) => void;
  onStartGesture: (
    overlay: GroomTextOverlay,
    event: { nativeEvent: { touches?: { pageX: number; pageY: number }[] } },
  ) => void;
  overlay: GroomTextOverlay;
}) {
  const tapCandidateRef = useRef(true);
  const panResponder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: (event) => {
          tapCandidateRef.current = true;
          onStartGesture(overlay, event);
        },
        onPanResponderMove: (event, gesture) => {
          if (Math.abs(gesture.dx) > 3 || Math.abs(gesture.dy) > 3 || event.nativeEvent.touches.length > 1) {
            tapCandidateRef.current = false;
          }
          onMove(overlay.id, event, gesture);
        },
        onPanResponderRelease: () => {
          if (tapCandidateRef.current) onEdit(overlay);
        },
        onPanResponderTerminate: () => {
          tapCandidateRef.current = false;
        },
      }),
    [onEdit, onMove, onStartGesture, overlay],
  );

  return (
    <Animated.View
      {...panResponder.panHandlers}
      style={[
        styles.groomStoryTextOverlay,
        overlay.tone === "label"
          ? styles.groomStoryTextOverlayLabel
          : overlay.tone === "solid"
            ? styles.groomStoryTextOverlaySolid
            : null,
        styles.groomStoryTextOverlayEditable,
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
          styles.groomStoryTextOverlayText,
          { color: overlay.tone === "solid" ? ihubColors.ink : overlay.color },
        ]}
      >
        {overlay.text}
      </Text>
    </Animated.View>
  );
}

function GroomProgressBar({
  currentIndex,
  posts,
  progress,
}: {
  currentIndex: number;
  posts: GroomPost[];
  progress: Animated.Value;
}) {
  return (
    <View style={styles.groomProgressRow}>
      {posts.map((item, index) => (
        <GroomProgressSegment
          active={index === currentIndex}
          done={index < currentIndex}
          key={item.id}
          progress={progress}
        />
      ))}
    </View>
  );
}

function GroomProgressSegment({
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
      style={styles.groomProgressTrack}
    >
      <Animated.View style={[styles.groomProgressFill, { width: animatedWidth }]} />
    </View>
  );
}

function GroomFaceAvatar({ post }: { post: GroomPost }) {
  const hue = post.author?.hue ?? "lav";
  return (
    <View style={[styles.groomViewerFace, { borderColor: hueColor(hue) }]}>
      <View style={[styles.groomViewerFaceInner, { backgroundColor: hueTint(hue, 0.58) }]}>
        <Text style={styles.groomViewerFaceText}>{groomAuthorName(post).charAt(0)}</Text>
      </View>
    </View>
  );
}

function GroomCameraModal({
  onCapture,
  onClose,
  visible,
}: {
  onCapture: (payload: GroomCapturePayload) => void;
  onClose: () => void;
  visible: boolean;
}) {
  const insets = useSafeAreaInsets();
  const cameraRef = useRef<CameraView>(null);
  const [permission, requestPermission] = useCameraPermissions();
  const [facing, setFacing] = useState<CameraType>("back");
  const [busy, setBusy] = useState<"camera" | "library" | null>(null);
  const [latestLibraryPhotoUri, setLatestLibraryPhotoUri] = useState<string | null>(null);
  const [latestLibraryLoading, setLatestLibraryLoading] = useState(false);
  const [pictureSize, setPictureSize] = useState<string | undefined>(undefined);

  useEffect(() => {
    if (!visible || permission?.granted) return;
    void requestPermission();
  }, [permission?.granted, requestPermission, visible]);

  useEffect(() => {
    if (!visible) return;
    void refreshLatestLibraryPhoto(false);
  }, [visible]);

  async function ensurePhotoLibraryPermission(prompt: boolean) {
    const current = await MediaLibrary.getPermissionsAsync(false, ["photo"]);
    if (current.granted) return true;
    if (!prompt || !current.canAskAgain) return false;
    const next = await MediaLibrary.requestPermissionsAsync(false, ["photo"]);
    return next.granted;
  }

  async function refreshLatestLibraryPhoto(prompt: boolean) {
    setLatestLibraryLoading(true);
    try {
      const granted = await ensurePhotoLibraryPermission(prompt);
      if (!granted) {
        setLatestLibraryPhotoUri(null);
        return;
      }
      const page = await MediaLibrary.getAssetsAsync({
        first: 1,
        mediaType: MediaLibrary.MediaType.photo,
        sortBy: [[MediaLibrary.SortBy.creationTime, false]],
      });
      const latestAsset = page.assets[0];
      if (!latestAsset) {
        setLatestLibraryPhotoUri(null);
        return;
      }
      const latestInfo = await MediaLibrary.getAssetInfoAsync(latestAsset);
      setLatestLibraryPhotoUri(latestInfo.localUri ?? latestInfo.uri ?? latestAsset.uri);
    } catch {
      setLatestLibraryPhotoUri(null);
    } finally {
      setLatestLibraryLoading(false);
    }
  }

  async function takePhoto() {
    if (busy || !permission?.granted) return;
    setBusy("camera");
    try {
      const picture = await cameraRef.current?.takePictureAsync({
        base64: true,
        imageType: "jpg",
        maxDownsampling: 1,
        quality: GROOM_CAMERA_QUALITY,
        skipProcessing: false,
      });
      if (picture?.uri) {
        onCapture({
          base64: picture.base64 ?? null,
          contentType: "image/jpeg",
          uri: picture.uri,
        });
      }
    } catch {
      Alert.alert("撮影できませんでした", "時間を置いてもう一度お試しください。");
    } finally {
      setBusy(null);
    }
  }

  async function pickFromLibrary() {
    if (busy) return;
    setBusy("library");
    try {
      const permissionGranted = await ensurePhotoLibraryPermission(true);
      if (!permissionGranted) {
        Alert.alert("写真を選べません", "アルバムからアップロードするには写真ライブラリの許可が必要です。");
        return;
      }
      void refreshLatestLibraryPhoto(false);
      const result = await ImagePicker.launchImageLibraryAsync({
        allowsEditing: false,
        base64: true,
        mediaTypes: ["images"],
        preferredAssetRepresentationMode:
          ImagePicker.UIImagePickerPreferredAssetRepresentationMode.Compatible,
        quality: GROOM_LIBRARY_QUALITY,
        selectionLimit: 1,
      });
      const asset = result.canceled ? null : result.assets[0];
      if (asset?.uri) {
        onCapture({
          base64: asset.base64 ?? null,
          contentType: asset.mimeType ?? "image/jpeg",
          uri: asset.uri,
        });
      }
    } finally {
      setBusy(null);
    }
  }

  async function updatePictureSize() {
    try {
      const sizes = await cameraRef.current?.getAvailablePictureSizesAsync();
      setPictureSize(selectBestGroomPictureSize(sizes ?? []));
    } catch {
      setPictureSize(undefined);
    }
  }

  return (
    <Modal animationType="fade" visible={visible} onRequestClose={onClose}>
      <View style={styles.groomCameraRoot}>
        {permission?.granted ? (
          <CameraView
            facing={facing}
            mode="picture"
            onCameraReady={() => void updatePictureSize()}
            pictureSize={pictureSize}
            ref={cameraRef}
            responsiveOrientationWhenOrientationLocked
            style={StyleSheet.absoluteFillObject}
          />
        ) : (
          <View style={styles.groomCameraPermission}>
            <Text style={styles.groomCameraPermissionTitle}>カメラを許可してください</Text>
            <Text style={styles.groomCameraPermissionText}>
              グルームの写真を撮るためにカメラを使用します。
            </Text>
            <Pressable onPress={() => void requestPermission()} style={styles.groomCameraPermissionButton}>
              <Text style={styles.groomCameraPermissionButtonText}>許可する</Text>
            </Pressable>
          </View>
        )}

        <View pointerEvents="none" style={styles.groomCameraScrimTop} />
        <View pointerEvents="none" style={styles.groomCameraScrimBottom} />

        <View style={[styles.groomCameraTopBar, { paddingTop: Math.max(insets.top, 14) + 8 }]}>
          <Pressable
            accessibilityLabel="カメラを閉じる"
            accessibilityRole="button"
            onPress={onClose}
            style={styles.groomCameraCloseButton}
          >
            <IconSymbol name="close" color="#fff" size={24} />
          </Pressable>
          <Text style={styles.groomCameraTitle}>グルーム</Text>
          <Pressable
            accessibilityLabel="カメラを切り替える"
            accessibilityRole="button"
            onPress={() => setFacing((current) => (current === "back" ? "front" : "back"))}
            style={styles.groomCameraTopButton}
          >
            <Text style={styles.groomCameraFlipText}>↻</Text>
          </Pressable>
        </View>

        <View style={[styles.groomCameraBottomBar, { paddingBottom: Math.max(insets.bottom, 12) + 8 }]}>
          <Pressable
            accessibilityLabel="アルバムから選ぶ"
            accessibilityRole="button"
            disabled={busy !== null}
            onPress={pickFromLibrary}
            style={styles.groomCameraLibraryButton}
          >
            {latestLibraryPhotoUri ? (
              <Image source={{ uri: latestLibraryPhotoUri }} style={styles.groomCameraLibraryImage} />
            ) : (
              <View style={styles.groomCameraLibraryFallback}>
                <IconSymbol name="camera-outline" color="#fff" size={24} />
              </View>
            )}
            {busy === "library" || latestLibraryLoading ? (
              <View style={styles.groomCameraLibraryBusy}>
                <ActivityIndicator color="#fff" />
              </View>
            ) : null}
          </Pressable>
          <Pressable
            accessibilityLabel="撮影する"
            accessibilityRole="button"
            disabled={busy !== null || !permission?.granted}
            onPress={takePhoto}
            style={styles.groomCameraShutter}
          >
            <View style={styles.groomCameraShutterInner}>
              {busy === "camera" ? <ActivityIndicator color="#fff" /> : null}
            </View>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

function selectBestGroomPictureSize(sizes: string[]) {
  const numericSizes = sizes
    .map((size) => {
      const match = size.match(/^(\d+)x(\d+)$/);
      if (!match) return null;
      const width = Number(match[1]);
      const height = Number(match[2]);
      return Number.isFinite(width) && Number.isFinite(height)
        ? { area: width * height, longEdge: Math.max(width, height), size }
        : null;
    })
    .filter((item): item is { area: number; longEdge: number; size: string } => !!item)
    .sort((a, b) => b.area - a.area);
  const uploadFriendlySize = numericSizes.find(
    (item) => item.longEdge <= GROOM_MAX_CAMERA_LONG_EDGE,
  );
  if (uploadFriendlySize) return uploadFriendlySize.size;
  if (numericSizes.length > 0) return numericSizes[numericSizes.length - 1]?.size;
  if (sizes.includes("High")) return "High";
  return sizes[0];
}

function groomPublishFailureMessage(error: unknown) {
  if (error instanceof Error) {
    if (
      error.message.startsWith("画像サイズが大きすぎます") ||
      error.message.startsWith("グルーム画像を読み込めませんでした") ||
      error.message.startsWith("ログイン情報を確認できませんでした") ||
      error.message.startsWith("ログイン中のユーザー情報が古くなっています")
    ) {
      return error.message;
    }
    if (
      error.message.includes("row-level security") ||
      error.message.includes("permission") ||
      error.message.includes("Unauthorized") ||
      error.message.includes("403")
    ) {
      return "保存権限を確認できませんでした。ログインし直してから、もう一度投稿してください。";
    }
  }
  return "通信状況を確認して、もう一度投稿してください。";
}

function GroomComposerModal({
  caption,
  draftUri,
  onChangeCaption,
  onClose,
  onPublish,
  onRetake,
}: {
  caption: string;
  draftUri: string | null;
  onChangeCaption: (value: string) => void;
  onClose: () => void;
  onPublish: (payload: GroomPublishPayload) => void;
  onRetake: () => void;
}) {
  const insets = useSafeAreaInsets();
  const keyboardInset = useKeyboardInset();
  const [tool, setTool] = useState<"none" | "text" | "draw">("none");
  const [editingTextId, setEditingTextId] = useState<string | null>(null);
  const [textDraft, setTextDraft] = useState("");
  const [textDraftOrigin, setTextDraftOrigin] = useState<{ x: number; y: number } | null>(null);
  const [textColor, setTextColor] = useState(GROOM_TEXT_COLORS[0]);
  const [textTone, setTextTone] = useState<GroomTextOverlay["tone"]>("plain");
  const [drawColor, setDrawColor] = useState(GROOM_DRAW_COLORS[1]);
  const [imageTransform, setImageTransform] = useState<GroomImageTransform>(DEFAULT_GROOM_IMAGE_TRANSFORM);
  const [textOverlays, setTextOverlays] = useState<GroomTextOverlay[]>([]);
  const [doodles, setDoodles] = useState<GroomDoodleStroke[]>([]);
  const [canvasSize, setCanvasSize] = useState({ height: 1, width: 1 });
  const canvasRef = useRef<View>(null);
  const canvasWindowRef = useRef({ height: 1, width: 1, x: 0, y: 0 });
  const currentStrokeId = useRef<string | null>(null);
  const textGestureRef = useRef<{
    fingerOffsetX: number;
    fingerOffsetY: number;
    id: string;
    moved: boolean;
    startAngle: number | null;
    startDistance: number | null;
    startMidX: number | null;
    startMidY: number | null;
    startRotation: number;
    startScale: number;
    startX: number;
    startY: number;
  } | null>(null);
  const imageTapCandidateRef = useRef(false);
  const imageTapPointRef = useRef<{ pageX: number; pageY: number } | null>(null);
  const imageGestureRef = useRef<{
    startAngle: number;
    startDistance: number;
    startMidX: number;
    startMidY: number;
    startRotation: number;
    startScale: number;
    startX: number;
    startY: number;
  } | null>(null);

  useEffect(() => {
    if (draftUri) {
      setTool("none");
      setEditingTextId(null);
      setTextDraft("");
      setTextDraftOrigin(null);
      setTextColor(GROOM_TEXT_COLORS[0]);
      setTextTone("plain");
      setDrawColor(GROOM_DRAW_COLORS[1]);
      setImageTransform(DEFAULT_GROOM_IMAGE_TRANSFORM);
      setTextOverlays([]);
      setDoodles([]);
    }
  }, [draftUri]);

  function updateCanvasMetrics(event: { nativeEvent: { layout: { height: number; width: number } } }) {
    const { height, width } = event.nativeEvent.layout;
    setCanvasSize({ height, width });
    requestAnimationFrame(() => {
      canvasRef.current?.measureInWindow((x, y, measuredWidth, measuredHeight) => {
        canvasWindowRef.current = {
          height: measuredHeight || height || 1,
          width: measuredWidth || width || 1,
          x,
          y,
        };
      });
    });
  }

  function addTextOverlay() {
    const clean = textDraft.trim();
    if (!clean) {
      if (editingTextId) {
        setTextOverlays((current) => current.filter((overlay) => overlay.id !== editingTextId));
      }
      setEditingTextId(null);
      setTextDraft("");
      setTextDraftOrigin(null);
      setTool("none");
      return;
    }
    if (editingTextId) {
      setTextOverlays((current) =>
        current.map((overlay) =>
          overlay.id === editingTextId
            ? { ...overlay, color: textColor, text: clean, tone: textTone }
            : overlay,
        ),
      );
      setEditingTextId(null);
      setTextDraft("");
      setTextDraftOrigin(null);
      setTool("none");
      return;
    }
    const index = textOverlays.length;
    const origin = textDraftOrigin;
    setTextOverlays((current) => [
      ...current,
      {
        color: textColor,
        id: `groom-text-${Date.now()}`,
        rotation: 0,
        scale: 1,
        text: clean,
        tone: textTone,
        x: origin?.x ?? (index % 2 === 0 ? 0.14 : 0.34),
        y: origin?.y ?? Math.min(0.66, 0.22 + index * 0.11),
      },
    ]);
    setTextDraft("");
    setTextDraftOrigin(null);
    setTool("none");
  }

  function undoLatest() {
    if (textOverlays.length > 0) {
      setTextOverlays((current) => current.slice(0, -1));
      return;
    }
    setDoodles((current) => current.slice(0, -1));
  }

  function editTextOverlay(overlay: GroomTextOverlay) {
    setEditingTextId(overlay.id);
    setTextDraft(overlay.text);
    setTextDraftOrigin(null);
    setTextColor(overlay.color);
    setTextTone(overlay.tone);
    setTool("text");
  }

  function clearTextEditing() {
    setEditingTextId(null);
    setTextDraft("");
    setTextDraftOrigin(null);
    setTool("none");
  }

  function gestureDistance(event: GroomGestureEvent) {
    const touches = event.nativeEvent.touches ?? [];
    if (touches.length < 2) return null;
    const [first, second] = touches;
    return Math.hypot(first.pageX - second.pageX, first.pageY - second.pageY);
  }

  function gestureAngle(event: GroomGestureEvent) {
    const touches = event.nativeEvent.touches ?? [];
    if (touches.length < 2) return null;
    const [first, second] = touches;
    return Math.atan2(second.pageY - first.pageY, second.pageX - first.pageX) * (180 / Math.PI);
  }

  function gestureMidpoint(event: GroomGestureEvent) {
    const touches = event.nativeEvent.touches ?? [];
    if (touches.length < 2) return null;
    const [first, second] = touches;
    return {
      x: (first.pageX + second.pageX) / 2,
      y: (first.pageY + second.pageY) / 2,
    };
  }

  function openTextInputAtPoint(point: { pageX: number; pageY: number } | null) {
    const canvas = canvasWindowRef.current;
    const x = point
      ? Math.max(0.04, Math.min(0.86, (point.pageX - canvas.x) / Math.max(canvas.width, 1)))
      : null;
    const y = point
      ? Math.max(0.08, Math.min(0.82, (point.pageY - canvas.y) / Math.max(canvas.height, 1)))
      : null;
    setEditingTextId(null);
    setTextDraft("");
    setTextDraftOrigin(x != null && y != null ? { x, y } : null);
    setTool("text");
  }

  function startTextGesture(overlay: GroomTextOverlay, event: GroomGestureEvent) {
    const touch = event.nativeEvent.touches?.[0];
    const midpoint = gestureMidpoint(event);
    const angle = gestureAngle(event);
    const canvas = canvasWindowRef.current;
    const overlayPageX = canvas.x + overlay.x * canvas.width;
    const overlayPageY = canvas.y + overlay.y * canvas.height;
    textGestureRef.current = {
      fingerOffsetX: touch ? touch.pageX - overlayPageX : 0,
      fingerOffsetY: touch ? touch.pageY - overlayPageY : 0,
      id: overlay.id,
      moved: false,
      startAngle: angle,
      startDistance: gestureDistance(event),
      startMidX: midpoint?.x ?? null,
      startMidY: midpoint?.y ?? null,
      startRotation: overlay.rotation ?? 0,
      startScale: overlay.scale ?? 1,
      startX: overlay.x,
      startY: overlay.y,
    };
  }

  function moveTextOverlay(
    overlayId: string,
    event: GroomGestureEvent,
    gesture: PanResponderGestureState,
  ) {
    let start = textGestureRef.current;
    if (!start || start.id !== overlayId) return;
    const touches = event.nativeEvent.touches ?? [];
    const distance = gestureDistance(event);
    const angle = gestureAngle(event);
    const midpoint = gestureMidpoint(event);
    if (distance && touches.length >= 2) {
      const currentOverlay = textOverlays.find((overlay) => overlay.id === overlayId);
      const base =
        start.startDistance !== null && start.startAngle !== null && start.startMidX !== null && start.startMidY !== null
          ? start
          : {
              ...start,
              startAngle: angle ?? 0,
              startDistance: distance,
              startMidX: midpoint?.x ?? 0,
              startMidY: midpoint?.y ?? 0,
              startRotation: currentOverlay?.rotation ?? start.startRotation,
              startScale: currentOverlay?.scale ?? start.startScale,
              startX: currentOverlay?.x ?? start.startX,
              startY: currentOverlay?.y ?? start.startY,
            };
      const baseDistance = base.startDistance ?? distance;
      const nextScale = Math.max(0.35, Math.min(3.2, base.startScale * (distance / Math.max(baseDistance, 1))));
      const nextRotation = base.startRotation + ((angle ?? base.startAngle ?? 0) - (base.startAngle ?? 0));
      const nextX = base.startX + ((midpoint?.x ?? base.startMidX ?? 0) - (base.startMidX ?? 0)) / Math.max(canvasWindowRef.current.width, 1);
      const nextY = base.startY + ((midpoint?.y ?? base.startMidY ?? 0) - (base.startMidY ?? 0)) / Math.max(canvasWindowRef.current.height, 1);
      textGestureRef.current = { ...base, moved: true };
      setTextOverlays((current) =>
        current.map((overlay) =>
          overlay.id === overlayId
            ? {
                ...overlay,
                rotation: nextRotation,
                scale: nextScale,
                x: Math.max(0.02, Math.min(0.92, nextX)),
                y: Math.max(0.04, Math.min(0.92, nextY)),
              }
            : overlay,
        ),
      );
      return;
    }

    if (start.startDistance !== null || start.startAngle !== null) {
      const currentOverlay = textOverlays.find((overlay) => overlay.id === overlayId);
      start = {
        ...start,
        startAngle: null,
        startDistance: null,
        startMidX: null,
        startMidY: null,
        startRotation: currentOverlay?.rotation ?? start.startRotation,
        startScale: currentOverlay?.scale ?? start.startScale,
        startX: currentOverlay?.x ?? start.startX,
        startY: currentOverlay?.y ?? start.startY,
      };
      textGestureRef.current = start;
    }

    if (Math.abs(gesture.dx) > 1 || Math.abs(gesture.dy) > 1) {
      textGestureRef.current = { ...start, moved: true };
    }
    const touch = touches[0];
    const canvas = canvasWindowRef.current;
    const nextX = touch
      ? (touch.pageX - canvas.x - start.fingerOffsetX) / Math.max(canvas.width, 1)
      : start.startX + gesture.dx / Math.max(canvasSize.width, 1);
    const nextY = touch
      ? (touch.pageY - canvas.y - start.fingerOffsetY) / Math.max(canvas.height, 1)
      : start.startY + gesture.dy / Math.max(canvasSize.height, 1);
    const clampedX = Math.max(0.02, Math.min(0.92, nextX));
    const clampedY = Math.max(0.04, Math.min(0.92, nextY));
    const currentOverlay = textOverlays.find((overlay) => overlay.id === overlayId);
    textGestureRef.current = {
      ...start,
      fingerOffsetX: touch ? touch.pageX - (canvas.x + clampedX * canvas.width) : start.fingerOffsetX,
      fingerOffsetY: touch ? touch.pageY - (canvas.y + clampedY * canvas.height) : start.fingerOffsetY,
      moved: true,
      startAngle: null,
      startDistance: null,
      startMidX: null,
      startMidY: null,
      startRotation: currentOverlay?.rotation ?? start.startRotation,
      startScale: currentOverlay?.scale ?? start.startScale,
      startX: clampedX,
      startY: clampedY,
    };
    setTextOverlays((current) =>
      current.map((overlay) =>
        overlay.id === overlayId ? { ...overlay, x: clampedX, y: clampedY } : overlay,
      ),
    );
  }

  function startImageGesture(event: GroomGestureEvent) {
    const distance = gestureDistance(event);
    const angle = gestureAngle(event);
    const midpoint = gestureMidpoint(event);
    if (!distance || angle === null || !midpoint) return;
    imageGestureRef.current = {
      startAngle: angle,
      startDistance: distance,
      startMidX: midpoint.x,
      startMidY: midpoint.y,
      startRotation: imageTransform.rotation,
      startScale: imageTransform.scale,
      startX: imageTransform.x,
      startY: imageTransform.y,
    };
  }

  function moveImageTransform(event: GroomGestureEvent) {
    const start = imageGestureRef.current;
    const distance = gestureDistance(event);
    const angle = gestureAngle(event);
    const midpoint = gestureMidpoint(event);
    if (!start || !distance || angle === null || !midpoint) return;
    const nextScale = Math.max(0.22, Math.min(3.2, start.startScale * (distance / Math.max(start.startDistance, 1))));
    const nextRotation = start.startRotation + (angle - start.startAngle);
    const nextX = start.startX + (midpoint.x - start.startMidX) / Math.max(canvasWindowRef.current.width, 1);
    const nextY = start.startY + (midpoint.y - start.startMidY) / Math.max(canvasWindowRef.current.height, 1);
    setImageTransform({
      rotation: nextRotation,
      scale: nextScale,
      x: Math.max(-0.68, Math.min(0.68, nextX)),
      y: Math.max(-0.68, Math.min(0.68, nextY)),
    });
  }

  function pointFromGesture(nativeEvent: { locationX: number; locationY: number }) {
    return {
      x: Math.max(0.02, Math.min(0.98, nativeEvent.locationX / Math.max(canvasSize.width, 1))),
      y: Math.max(0.02, Math.min(0.98, nativeEvent.locationY / Math.max(canvasSize.height, 1))),
    };
  }

  const drawResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: () => tool === "draw",
        onStartShouldSetPanResponder: () => tool === "draw",
        onPanResponderGrant: (event) => {
          const id = `groom-doodle-${Date.now()}`;
          currentStrokeId.current = id;
          const first = pointFromGesture(event.nativeEvent);
          setDoodles((current) => [...current, { color: drawColor, id, points: [first] }]);
        },
        onPanResponderMove: (event) => {
          const id = currentStrokeId.current;
          if (!id) return;
          const nextPoint = pointFromGesture(event.nativeEvent);
          setDoodles((current) =>
            current.map((stroke) =>
              stroke.id === id
                ? { ...stroke, points: [...stroke.points, nextPoint] }
                : stroke,
            ),
          );
        },
        onPanResponderRelease: () => {
          currentStrokeId.current = null;
        },
        onPanResponderTerminate: () => {
          currentStrokeId.current = null;
        },
      }),
    [canvasSize.height, canvasSize.width, drawColor, tool],
  );

  const imageTransformResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: (event) =>
          tool === "none" && ((event.nativeEvent.touches?.length ?? 0) >= 2 || imageTapCandidateRef.current),
        onStartShouldSetPanResponder: () => tool === "none",
        onPanResponderGrant: (event) => {
          const touch = event.nativeEvent.touches?.[0];
          imageTapCandidateRef.current = true;
          imageTapPointRef.current = touch ? { pageX: touch.pageX, pageY: touch.pageY } : null;
          if ((event.nativeEvent.touches?.length ?? 0) >= 2) {
            imageTapCandidateRef.current = false;
            startImageGesture(event);
          }
        },
        onPanResponderMove: (event, gesture) => {
          if (Math.abs(gesture.dx) > 4 || Math.abs(gesture.dy) > 4) {
            imageTapCandidateRef.current = false;
          }
          if ((event.nativeEvent.touches?.length ?? 0) < 2) return;
          if (!imageGestureRef.current) startImageGesture(event);
          imageTapCandidateRef.current = false;
          moveImageTransform(event);
        },
        onPanResponderRelease: () => {
          if (imageTapCandidateRef.current) openTextInputAtPoint(imageTapPointRef.current);
          imageTapCandidateRef.current = false;
          imageTapPointRef.current = null;
          imageGestureRef.current = null;
        },
        onPanResponderTerminate: () => {
          imageTapCandidateRef.current = false;
          imageTapPointRef.current = null;
          imageGestureRef.current = null;
        },
      }),
    [imageTransform.rotation, imageTransform.scale, imageTransform.x, imageTransform.y, tool],
  );

  function publishEditedGroom() {
    onPublish({
      caption,
      doodles,
      imageTransform,
      stickers: [],
      textOverlays,
    });
  }

  return (
    <Modal animationType="slide" visible={!!draftUri} onRequestClose={onClose}>
      <View style={styles.groomStoryEditorRoot}>
        {draftUri ? (
          <GroomStoryImageLayer transform={imageTransform} uri={draftUri} />
        ) : null}
        <View
          pointerEvents={tool === "none" ? "auto" : "none"}
          style={styles.groomStoryImageGestureLayer}
          {...imageTransformResponder.panHandlers}
        />
        <View
          ref={canvasRef}
          pointerEvents={tool === "draw" ? "none" : "box-none"}
          style={StyleSheet.absoluteFillObject}
          onLayout={updateCanvasMetrics}
        >
          <EditableGroomStoryDecorations
            doodles={doodles}
            onEditText={editTextOverlay}
            onMoveText={moveTextOverlay}
            onStartTextGesture={startTextGesture}
            stickers={[]}
            textOverlays={textOverlays}
          />
        </View>
        <View
          pointerEvents={tool === "draw" ? "auto" : "none"}
          style={StyleSheet.absoluteFillObject}
          {...drawResponder.panHandlers}
        />

        {tool !== "text" ? (
          <View style={[styles.groomStoryTopBar, { paddingTop: Math.max(insets.top, 14) + 8 }]}>
            <Pressable
              accessibilityLabel="編集を閉じる"
              accessibilityRole="button"
              onPress={onClose}
              style={styles.groomStoryToolButton}
            >
              <IconSymbol name="close" color="#fff" size={23} />
            </Pressable>
            <View style={styles.groomStoryToolCluster}>
              <Pressable
                accessibilityLabel="文字を追加"
                accessibilityRole="button"
                onPress={() => openTextInputAtPoint(null)}
                style={styles.groomStoryToolButton}
              >
                <Text style={styles.groomStoryToolText}>Aa</Text>
              </Pressable>
              <Pressable
                accessibilityLabel="描画する"
                accessibilityRole="button"
                onPress={() => setTool((current) => (current === "draw" ? "none" : "draw"))}
                style={[styles.groomStoryToolButton, tool === "draw" ? styles.groomStoryToolButtonActive : null]}
              >
                <IconSymbol name="create-outline" color="#fff" size={22} />
              </Pressable>
              <Pressable
                accessibilityLabel="ひとつ戻す"
                accessibilityRole="button"
                onPress={undoLatest}
                style={styles.groomStoryToolButton}
              >
                <Text style={styles.groomStoryToolText}>↶</Text>
              </Pressable>
            </View>
          </View>
        ) : null}

        {tool === "text" ? (
          <View style={styles.groomStoryTextEditLayer}>
            <View style={[styles.groomStoryTextEditTopBar, { paddingTop: Math.max(insets.top, 14) + 8 }]}>
              <Pressable
                accessibilityRole="button"
                onPress={addTextOverlay}
                style={styles.groomStoryTextDoneButton}
              >
                <Text style={styles.groomStoryTextDoneButtonText}>完了</Text>
              </Pressable>
            </View>
            <TextInput
              autoFocus
              maxLength={60}
              multiline
              onChangeText={setTextDraft}
              onSubmitEditing={addTextOverlay}
              placeholder="テキストを入力"
              placeholderTextColor="rgba(255,255,255,0.62)"
              selectionColor={ihubColors.lavender}
              style={[
                styles.groomStoryLiveTextInput,
                textTone === "label"
                  ? styles.groomStoryLiveTextInputLabel
                  : textTone === "solid"
                    ? styles.groomStoryLiveTextInputSolid
                    : null,
                { color: textTone === "solid" ? ihubColors.ink : textColor },
              ]}
              value={textDraft}
            />
            <View
              style={[
                styles.groomStoryTextControlTray,
                { bottom: Math.max(insets.bottom, 12) + keyboardInset + 12 },
              ]}
            >
              <View style={styles.groomStoryColorRow}>
                {GROOM_TEXT_COLORS.map((color) => (
                  <Pressable
                    key={color}
                    accessibilityLabel={`文字色 ${color}`}
                    onPress={() => setTextColor(color)}
                    style={[
                      styles.groomStoryColorDot,
                      { backgroundColor: color },
                      textColor === color ? styles.groomStoryColorDotActive : null,
                    ]}
                  />
                ))}
              </View>
              <View style={styles.groomStoryToneRow}>
                {(["plain", "label", "solid"] as const).map((tone) => (
                  <Pressable
                    key={tone}
                    onPress={() => setTextTone(tone)}
                    style={[styles.groomStoryToneChip, textTone === tone ? styles.groomStoryToneChipActive : null]}
                  >
                    <Text style={styles.groomStoryToneText}>
                      {tone === "plain" ? "文字" : tone === "label" ? "帯" : "塗り"}
                    </Text>
                  </Pressable>
                ))}
              </View>
              {editingTextId ? (
                <Pressable onPress={clearTextEditing} style={styles.groomStoryCancelChip}>
                  <Text style={styles.groomStoryCancelText}>やめる</Text>
                </Pressable>
              ) : null}
            </View>
          </View>
        ) : null}

        {tool === "draw" ? (
          <View style={[styles.groomStoryDrawTray, { bottom: Math.max(insets.bottom, 12) + 96 }]}>
            <Text style={styles.groomStoryDrawHint}>画面をなぞって描画</Text>
            <View style={styles.groomStoryColorRow}>
              {GROOM_DRAW_COLORS.map((color) => (
                <Pressable
                  key={color}
                  onPress={() => setDrawColor(color)}
                  style={[
                    styles.groomStoryColorDot,
                    { backgroundColor: color },
                    drawColor === color ? styles.groomStoryColorDotActive : null,
                  ]}
                />
              ))}
            </View>
          </View>
        ) : null}

        {tool !== "text" ? (
          <View
            style={[
              styles.groomStoryBottomBar,
              {
                bottom: keyboardInset,
                paddingBottom: Math.max(insets.bottom, 12) + 10,
              },
            ]}
          >
            <TextInput
              maxLength={80}
              onChangeText={onChangeCaption}
              placeholder="キャプションを追加"
              placeholderTextColor="rgba(255,255,255,0.64)"
              style={styles.groomStoryCaptionInput}
              value={caption}
            />
            <View style={styles.groomStoryBottomActions}>
              <Pressable onPress={onRetake} style={styles.groomStoryRetakeButton}>
                <Text style={styles.groomStoryRetakeText}>撮り直す</Text>
              </Pressable>
              <Pressable onPress={publishEditedGroom} style={styles.groomStoryPublishButton}>
                <Text style={styles.groomStoryPublishText}>投稿する</Text>
              </Pressable>
            </View>
          </View>
        ) : null}
      </View>
    </Modal>
  );
}

function HomeResidentsFallback({
  activeIndex,
  users,
}: {
  activeIndex: number;
  users: MeguriUser[];
}) {
  return (
    <View style={styles.homeFallbackScene}>
      <View style={styles.homeFallbackGround} />
      <View style={styles.homeFallbackRow}>
        {users.map((user, index) => (
          <View
            key={user.id}
            style={[
              styles.homeFallbackPerson,
              index === activeIndex ? styles.homeFallbackPersonActive : null,
            ]}
          >
            <WalkingCard user={user} size={index === activeIndex ? 66 : 58} active={index === activeIndex} />
          </View>
        ))}
      </View>
    </View>
  );
}

export function RoundButton({
  icon,
  onPress,
}: {
  icon: "mail-unread-outline" | "sparkles-outline";
  onPress: () => void;
}) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.roundButton}>
      <IconSymbol name={icon} color={ihubColors.ink} size={18} />
    </Pressable>
  );
}

export function MeguriSettingsModal({
  enabled,
  onAvatarEdit,
  onClose,
  onProfileEdit,
  onToggle,
  open,
}: {
  enabled: boolean;
  onAvatarEdit: () => void;
  onClose: () => void;
  onProfileEdit: () => void;
  onToggle: () => void;
  open: boolean;
}) {
  return (
    <Modal animationType="slide" transparent visible={open} onRequestClose={onClose}>
      <View style={styles.modalLayer}>
        <Pressable style={styles.modalBackdrop} onPress={onClose} />
        <View style={styles.modalPanel}>
          <View style={styles.modalHandle} />
          <Text style={styles.modalKicker}>MEGURI SETTINGS</Text>
          <Text style={styles.modalTitle}>めぐり設定</Text>
          <View style={styles.settingsList}>
            <SettingRow
              icon="sparkles-outline"
              onPress={onAvatarEdit}
              subtitle="動物・毛色など"
              title="アバター編集"
            />
            <SettingRow
              icon="create-outline"
              onPress={onProfileEdit}
              subtitle="名前、めぐりで別れ際のメッセージ"
              title="プロフィール編集"
            />
            <View style={styles.settingRow}>
              <View style={styles.settingIcon}>
                <IconSymbol name="settings-outline" color={ihubColors.lavender} size={18} />
              </View>
              <View style={styles.settingCopy}>
                <Text style={styles.settingTitle}>めぐり機能</Text>
                <Text style={styles.settingSub}>{enabled ? "ON" : "OFF"}</Text>
              </View>
              <Pressable
                accessibilityRole="switch"
                accessibilityState={{ checked: enabled }}
                onPress={onToggle}
                style={[styles.settingSwitch, enabled ? styles.settingSwitchOn : null]}
              >
                <View style={[styles.settingKnob, enabled ? styles.settingKnobOn : null]} />
              </Pressable>
            </View>
          </View>
          <Pressable onPress={onClose} style={styles.modalCloseButton}>
            <Text style={styles.modalCloseText}>閉じる</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

export function SettingRow({
  icon,
  onPress,
  subtitle,
  title,
}: {
  icon: "create-outline" | "sparkles-outline";
  onPress: () => void;
  subtitle: string;
  title: string;
}) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.settingRow}>
      <View style={styles.settingIcon}>
        <IconSymbol name={icon} color={ihubColors.lavender} size={18} />
      </View>
      <View style={styles.settingCopy}>
        <Text style={styles.settingTitle}>{title}</Text>
        <Text style={styles.settingSub}>{subtitle}</Text>
      </View>
      <IconSymbol name="chevron-forward" color="rgba(58,50,74,0.34)" size={18} />
    </Pressable>
  );
}

export function WalkingCard({
  active,
  size,
  user,
}: {
  active?: boolean;
  size: number;
  user: MeguriUser;
}) {
  const bob = useRef(new Animated.Value(0)).current;
  const accent = hueColor(user.hue);

  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(bob, {
          toValue: 1,
          duration: active ? 840 : 1300,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
        Animated.timing(bob, {
          toValue: 0,
          duration: active ? 840 : 1300,
          easing: Easing.inOut(Easing.sin),
          useNativeDriver: true,
        }),
      ]),
    );
    loop.start();
    return () => loop.stop();
  }, [active, bob]);

  const translateY = bob.interpolate({
    inputRange: [0, 1],
    outputRange: [0, active ? -5 : -2],
  });
  const rotateLeft = bob.interpolate({
    inputRange: [0, 1],
    outputRange: ["-12deg", active ? "22deg" : "4deg"],
  });
  const rotateRight = bob.interpolate({
    inputRange: [0, 1],
    outputRange: ["12deg", active ? "-20deg" : "-4deg"],
  });

  return (
    <Animated.View style={[styles.walker, { width: size, transform: [{ translateY }] }]}>
      <View style={[styles.armRow, { top: size * 0.36 }]}>
        <Animated.View
          style={[
            styles.arm,
            styles.leftArm,
            { backgroundColor: accent, transform: [{ rotate: rotateLeft }] },
          ]}
        />
        <Animated.View
          style={[
            styles.arm,
            styles.rightArm,
            { backgroundColor: accent, transform: [{ rotate: rotateRight }] },
          ]}
        />
      </View>
      <View
        style={[
          styles.walkerBody,
          {
            width: size,
            height: size,
            borderRadius: Math.round(size * 0.24),
            borderColor: accent,
          },
        ]}
      >
        <View style={[styles.avatarPattern, { backgroundColor: hueTint(user.hue, 0.54) }]} />
        <Text style={[styles.walkerInitial, { fontSize: Math.round(size * 0.42) }]}>
          {user.name.charAt(0)}
        </Text>
      </View>
      <View style={styles.legs}>
        <Animated.View
          style={[
            styles.leg,
            { backgroundColor: accent, transform: [{ rotate: rotateRight }] },
          ]}
        />
        <Animated.View
          style={[
            styles.leg,
            { backgroundColor: accent, transform: [{ rotate: rotateLeft }] },
          ]}
        />
      </View>
      <View style={styles.walkerShadow} />
    </Animated.View>
  );
}

export function MiniChip({ label }: { label: string }) {
  return (
    <View style={styles.miniChip}>
      <Text style={styles.miniChipText}>{label}</Text>
    </View>
  );
}

export function NumLine({ label, value }: { label: string; value: number }) {
  return (
    <View style={styles.numLine}>
      <Text style={styles.numValue}>{value}</Text>
      <Text style={styles.numLabel}>{label}</Text>
    </View>
  );
}

export function ShortcutCard({
  hue,
  onPress,
  subtitle,
  title,
}: {
  hue: MeguriHue;
  onPress?: () => void;
  subtitle: string;
  title: string;
}) {
  return (
    <Pressable
      accessibilityRole={onPress ? "button" : undefined}
      onPress={onPress}
      style={[styles.shortcutCard, { backgroundColor: hueTint(hue, 0.18) }]}
    >
      <View style={[styles.shortcutIcon, { backgroundColor: hueColor(hue) }]}>
        <IconSymbol name="sparkles-outline" color="#fff" size={17} />
      </View>
      <Text style={styles.shortcutTitle}>{title}</Text>
      <Text style={styles.shortcutSubtitle}>{subtitle}</Text>
    </Pressable>
  );
}

export function SectionHeader({ subtitle, title }: { subtitle: string; title: string }) {
  return (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionTitle}>{title}</Text>
      <Text style={styles.sectionSubtitle}>{subtitle}</Text>
    </View>
  );
}

export function MapPin({
  count,
  hue,
  label,
  left,
  top,
}: {
  count: string;
  hue: MeguriHue;
  label: string;
  left: `${number}%`;
  top: `${number}%`;
}) {
  return (
    <View style={[styles.mapPin, { left, top, backgroundColor: hueColor(hue) }]}>
      <Text style={styles.mapPinCount}>{count}</Text>
      <Text style={styles.mapPinLabel}>{label}</Text>
    </View>
  );
}

export function LetterEnvelope({
  letter,
  onOpen,
  onPlan,
  subscribed,
}: {
  letter: Letter;
  onOpen: () => void;
  onPlan: () => void;
  subscribed: boolean;
}) {
  const canRead = subscribed;
  return (
    <Pressable
      accessibilityRole="button"
      onPress={canRead ? onOpen : onPlan}
      style={styles.letterEnvelope}
    >
      {!canRead ? <View style={styles.waxSeal} /> : null}
      <View style={styles.creaseLeft} />
      <View style={styles.creaseRight} />
      <View style={styles.letterStatusRow}>
        <Text style={styles.letterStatus}>{canRead ? "表示できます" : "未読"}</Text>
        <Text style={styles.letterAffinity}>相性 {letter.affinity}%</Text>
      </View>
      <Text style={styles.letterFrom}>@{letter.from.id} さんから</Text>
      <Text style={styles.letterMeta}>
        {letter.from.group} / {letter.from.oshi} 推し
      </Text>
      <View style={styles.letterPreview}>
        {canRead ? (
          <Text numberOfLines={2} style={styles.letterPreviewText}>
            「{letter.body}」
          </Text>
        ) : (
          <Text style={styles.letterPreviewText}>
            「同じ推しの
            <Text style={styles.blurText}>　すれ違いがくりかえし重なって</Text>
            …」
          </Text>
        )}
      </View>
      <View style={styles.letterHintRow}>
        <Text style={styles.letterHint}>{letter.placeHint}</Text>
        <Text style={styles.letterHint}>{letter.timeHint}</Text>
      </View>
    </Pressable>
  );
}

export function LetterModal({
  letter,
  onClose,
  onPlan,
  onReply,
  subscribed,
}: {
  letter: Letter | null;
  onClose: () => void;
  onPlan: () => void;
  onReply?: () => void;
  subscribed: boolean;
}) {
  const canRead = !!letter && subscribed;

  return (
    <Modal animationType="fade" transparent visible={!!letter} onRequestClose={onClose}>
      <View style={styles.centerModalLayer}>
        <Pressable style={styles.modalBackdrop} onPress={onClose} />
        {letter ? (
          <View style={styles.letterModalPanel}>
            <Text style={styles.modalKicker}>MESSAGE</Text>
            <Text style={styles.modalTitle}>@{letter.from.id} さんから</Text>
            <Text style={styles.modalSub}>
              {letter.placeHint} / {letter.timeHint}
            </Text>
            {canRead ? (
              <>
                <Text style={styles.letterBody}>{letter.body}</Text>
                <Pressable onPress={onReply ?? onClose} style={styles.modalPrimaryButton}>
                  <Text style={styles.modalPrimaryText}>返信を書く</Text>
                </Pressable>
              </>
            ) : (
              <>
                <View style={styles.bigLock}>
                  <IconSymbol name="lock-closed-outline" color={ihubColors.ink} size={24} />
                </View>
                <Text style={styles.lockExplain}>
                  本文の表示と返信には Megrum Plus が必要です。
                </Text>
                <Pressable onPress={onPlan} style={styles.modalPrimaryButton}>
                  <Text style={styles.modalPrimaryText}>Plusを見る</Text>
                </Pressable>
              </>
            )}
            <Pressable onPress={onClose} style={styles.modalCloseButton}>
              <Text style={styles.modalCloseText}>閉じる</Text>
            </Pressable>
          </View>
        ) : null}
      </View>
    </Modal>
  );
}

export function PlusModal({
  onClose,
  onToggle,
  open,
  subscribed,
}: {
  onClose: () => void;
  onToggle: () => void;
  open: boolean;
  subscribed: boolean;
}) {
  return (
    <Modal animationType="slide" transparent visible={open} onRequestClose={onClose}>
      <View style={styles.modalLayer}>
        <Pressable style={styles.modalBackdrop} onPress={onClose} />
        <View style={styles.modalPanel}>
          <View style={styles.modalHandle} />
          <Text style={styles.modalKicker}>PLUS</Text>
          <Text style={styles.modalTitle}>Megrum Plus</Text>
          <Text style={styles.modalPrice}>月額 {MONTHLY_PRICE.toLocaleString()}円</Text>
          <View style={styles.planBullets}>
            <PlanBullet text="届いたメッセージの本文を表示" />
            <PlanBullet text="本文を表示した相手に返信" />
            <PlanBullet text="無料枠を超えてメッセージを送信" />
            <PlanBullet text="めぐり履歴と広場を長く保存" />
          </View>
          <Pressable onPress={onToggle} style={styles.modalPrimaryButton}>
            <Text style={styles.modalPrimaryText}>
              {subscribed ? "Freeに戻す" : "Plusを有効にする"}
            </Text>
          </Pressable>
          <Pressable onPress={onClose} style={styles.modalCloseButton}>
            <Text style={styles.modalCloseText}>閉じる</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

export function PlanBullet({ text }: { text: string }) {
  return (
    <View style={styles.planBullet}>
      <Text style={styles.planBulletDot}>•</Text>
      <Text style={styles.planBulletText}>{text}</Text>
    </View>
  );
}

export function HitokotoModal({ onClose, open }: { onClose: () => void; open: boolean }) {
  const [answer, setAnswer] = useState("リオの黒髪ビジュに戻ってきました");
  return (
    <Modal animationType="slide" transparent visible={open} onRequestClose={onClose}>
      <View style={styles.modalLayer}>
        <Pressable style={styles.modalBackdrop} onPress={onClose} />
        <View style={styles.modalPanel}>
          <View style={styles.modalHandle} />
          <Text style={styles.modalKicker}>DAILY PROMPT</Text>
          <Text style={styles.modalTitle}>最近の推し活は？</Text>
          <Text style={styles.modalSub}>
            この答えが、めぐりあった人へのあなたのひとことになります。
          </Text>
          <TextInput
            maxLength={60}
            multiline
            onChangeText={setAnswer}
            placeholder="気軽に書いて大丈夫です"
            placeholderTextColor="rgba(58,50,74,0.38)"
            style={styles.composerInput}
            value={answer}
          />
          <Pressable onPress={onClose} style={styles.modalPrimaryButton}>
            <Text style={styles.modalPrimaryText}>カードを更新</Text>
          </Pressable>
          <Pressable onPress={onClose} style={styles.modalCloseButton}>
            <Text style={styles.modalCloseText}>閉じる</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

export function ComposerModal({
  draft,
  onChangeDraft,
  onClose,
  onSend,
  open,
}: {
  draft: string;
  onChangeDraft: (value: string) => void;
  onClose: () => void;
  onSend: () => void;
  open: boolean;
}) {
  return (
    <Modal animationType="slide" transparent visible={open} onRequestClose={onClose}>
      <View style={styles.modalLayer}>
        <Pressable style={styles.modalBackdrop} onPress={onClose} />
        <View style={styles.modalPanel}>
          <View style={styles.modalHandle} />
          <Text style={styles.modalKicker}>SEND MESSAGE</Text>
          <Text style={styles.modalTitle}>メッセージを書く</Text>
          <Text style={styles.modalSub}>
            相手には、ぼかした推し傾向とメッセージ到着だけが通知されます。
          </Text>
          <TextInput
            maxLength={180}
            multiline
            onChangeText={onChangeDraft}
            placeholder="短く、安心して読める一言を入力"
            placeholderTextColor="rgba(58,50,74,0.38)"
            style={styles.composerInput}
            value={draft}
          />
          <Pressable
            disabled={!draft.trim()}
            onPress={onSend}
            style={[styles.modalPrimaryButton, !draft.trim() ? styles.disabledButton : null]}
          >
            <Text style={styles.modalPrimaryText}>送る</Text>
          </Pressable>
          <Pressable onPress={onClose} style={styles.modalCloseButton}>
            <Text style={styles.modalCloseText}>閉じる</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  screenShell: {
    paddingBottom: 0,
    paddingHorizontal: 0,
    paddingTop: 0,
  },
  screen: {
    gap: 16,
    paddingHorizontal: 16,
  },
  topBar: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 6,
  },
  eyebrow: {
    color: ihubColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.7,
  },
  topActions: {
    flexDirection: "row",
    gap: 8,
  },
  homeHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "flex-end",
    minHeight: 42,
    paddingHorizontal: 6,
  },
  fixedHeader: {
    alignItems: "flex-end",
    left: 16,
    position: "absolute",
    right: 16,
    zIndex: 20,
  },
  settingsButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.86)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: ihubRadii.pill,
    borderWidth: 1,
    height: 40,
    justifyContent: "center",
    width: 40,
    ...ihubShadow,
  },
  groomRail: {
    gap: 11,
    marginTop: 2,
  },
  groomRailTitle: {
    color: ihubColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 27,
  },
	  groomListContent: {
	    gap: 13,
	    paddingRight: 18,
	  },
  groomRailLoading: {
    alignItems: "center",
    height: 74,
    justifyContent: "center",
    width: 80,
  },
	  groomStoryItem: {
	    alignItems: "center",
	    gap: 6,
	    width: 80,
	  },
  groomAvatarRing: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: ihubColors.lavender,
    borderRadius: 999,
    borderWidth: 2,
	    height: 74,
    justifyContent: "center",
    padding: 3,
    shadowColor: ihubColors.lavender,
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.16,
    shadowRadius: 12,
	    width: 74,
  },
  groomAvatarRingLiked: {
    borderColor: ihubColors.pink,
    shadowColor: ihubColors.pink,
  },
  groomAvatarRingViewed: {
    borderColor: "rgba(58,50,74,0.24)",
    shadowColor: "rgba(58,50,74,0.20)",
    shadowOpacity: 0.06,
  },
  groomAvatarImage: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    height: "100%",
    width: "100%",
  },
  groomAddRing: {
    borderColor: "rgba(166,149,216,0.34)",
    borderStyle: "dashed",
    shadowOpacity: 0.08,
  },
  groomAddCircle: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    height: "100%",
    justifyContent: "center",
    width: "100%",
  },
	  groomStoryName: {
    color: "rgba(58,50,74,0.72)",
    fontSize: 11,
    fontWeight: "900",
	    maxWidth: 78,
    textAlign: "center",
  },
  groomViewer: {
    flex: 1,
  },
  groomViewerBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#05080d",
  },
  groomOpenFrame: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#000",
    overflow: "hidden",
  },
  groomDismissFrame: {
    backgroundColor: "#000",
    flex: 1,
    overflow: "hidden",
  },
  groomCubeStage: {
    backgroundColor: "#05080d",
    flex: 1,
    overflow: "hidden",
  },
	  groomStoryFace: {
	    backfaceVisibility: "hidden",
	    backgroundColor: "#05080d",
	    bottom: 0,
	    overflow: "hidden",
	    position: "absolute",
	    top: 0,
	  },
  groomStoryCubeShade: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#000",
  },
  groomDoodleDot: {
    borderRadius: 999,
    height: 8,
    marginLeft: -4,
    marginTop: -4,
    opacity: 0.92,
    position: "absolute",
    width: 8,
  },
  groomStoryTextOverlay: {
    maxWidth: "70%",
    paddingHorizontal: 10,
    paddingVertical: 6,
    position: "absolute",
  },
  groomStoryTextOverlayEditable: {
    zIndex: 12,
  },
  groomStoryTextOverlayLabel: {
    backgroundColor: "rgba(5,8,13,0.48)",
    borderRadius: 12,
  },
  groomStoryTextOverlaySolid: {
    backgroundColor: "rgba(255,255,255,0.9)",
    borderRadius: 14,
  },
  groomStoryTextOverlayText: {
    fontSize: 23,
    fontWeight: "900",
    lineHeight: 28,
    textShadowColor: "rgba(0,0,0,0.34)",
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 4,
  },
  groomStoryStickerOverlay: {
    backgroundColor: "rgba(5,8,13,0.34)",
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 7,
    position: "absolute",
  },
  groomStoryStickerText: {
    fontSize: 15,
    fontWeight: "900",
  },
  groomViewerScrimTop: {
    backgroundColor: "rgba(0,0,0,0.32)",
    height: 178,
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
  },
  groomViewerScrimBottom: {
    backgroundColor: "rgba(0,0,0,0.7)",
    bottom: 0,
    height: 198,
    left: 0,
    position: "absolute",
    right: 0,
  },
  groomViewerHeader: {
    left: 0,
    paddingHorizontal: 12,
    position: "absolute",
    right: 0,
    top: 0,
    zIndex: 8,
  },
  groomProgressRow: {
    flexDirection: "row",
    gap: 4,
  },
  groomProgressTrack: {
    backgroundColor: "rgba(255,255,255,0.34)",
    borderRadius: 99,
    flex: 1,
    height: 3,
    overflow: "hidden",
  },
  groomProgressFill: {
    backgroundColor: "rgba(255,255,255,0.92)",
    borderRadius: 99,
    height: "100%",
  },
  groomViewerHeaderRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
    marginTop: 14,
  },
  groomViewerAuthor: {
    alignItems: "center",
    flexDirection: "row",
    flex: 1,
    gap: 10,
    minWidth: 0,
    borderRadius: 999,
  },
  groomViewerAuthorPressed: {
    opacity: 0.72,
  },
  groomViewerAuthorDisabled: {
    opacity: 1,
  },
  groomViewerMenuButton: {
    alignItems: "center",
    backgroundColor: "rgba(0,0,0,0.18)",
    borderRadius: ihubRadii.pill,
    height: 38,
    justifyContent: "center",
    width: 38,
  },
  groomViewerFace: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.24)",
    borderRadius: 999,
    borderWidth: 2,
    height: 38,
    justifyContent: "center",
    padding: 2,
    width: 38,
  },
  groomViewerFaceInner: {
    alignItems: "center",
    borderRadius: 999,
    height: "100%",
    justifyContent: "center",
    width: "100%",
  },
  groomViewerFaceText: {
    color: ihubColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  groomViewerNameWrap: {
    flex: 1,
    minWidth: 0,
  },
  groomViewerName: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "900",
  },
  groomViewerMeta: {
    color: "rgba(255,255,255,0.78)",
    fontSize: 13,
    fontWeight: "800",
    marginTop: 2,
  },
  groomViewerIconButton: {
    alignItems: "center",
    height: 40,
    justifyContent: "center",
    width: 40,
  },
  groomViewerClose: {
    alignItems: "center",
    height: 44,
    justifyContent: "center",
    width: 44,
  },
  groomTapLayer: {
    bottom: 108,
    flexDirection: "row",
    left: 0,
    position: "absolute",
    right: 0,
    top: 112,
    zIndex: 3,
  },
  groomTapZone: {
    flex: 1,
  },
  groomViewerFooter: {
    bottom: 0,
    left: 0,
    paddingHorizontal: 13,
    position: "absolute",
    right: 0,
    zIndex: 9,
  },
  groomCaptionPanel: {
    bottom: 112,
    left: 18,
    position: "absolute",
    right: 76,
    zIndex: 7,
  },
  groomCaptionText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "500",
    lineHeight: 18,
    textAlign: "left",
  },
  groomFeedbackText: {
    color: "rgba(255,255,255,0.82)",
    fontSize: 12,
    fontWeight: "700",
    marginTop: 8,
    textAlign: "left",
  },
  groomCenterToast: {
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
  groomCenterToastText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "900",
    textAlign: "center",
  },
  groomInputDimmer: {
    backgroundColor: "rgba(0,0,0,0.34)",
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
    zIndex: 8,
  },
  groomReplyRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 11,
  },
  groomReplyInput: {
    backgroundColor: "rgba(5,8,13,0.42)",
    borderColor: "rgba(255,255,255,0.46)",
    borderRadius: ihubRadii.pill,
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
  groomReplyGhost: {
    alignItems: "center",
    backgroundColor: "rgba(5,8,13,0.42)",
    borderColor: "rgba(255,255,255,0.46)",
    borderRadius: ihubRadii.pill,
    borderWidth: 1,
    flex: 1,
    justifyContent: "center",
    minHeight: 50,
    paddingHorizontal: 18,
    paddingVertical: 12,
  },
  groomReplyGhostText: {
    alignSelf: "stretch",
    color: "rgba(255,255,255,0.78)",
    fontSize: 16,
    fontWeight: "800",
    lineHeight: 21,
  },
  groomViewerAction: {
    alignItems: "center",
    borderRadius: ihubRadii.pill,
    height: 48,
    justifyContent: "center",
    width: 42,
  },
  groomSendButtonDisabled: {
    opacity: 0.52,
  },
  groomCameraRoot: {
    backgroundColor: "#05080d",
    flex: 1,
    overflow: "hidden",
  },
  groomCameraScrimTop: {
    backgroundColor: "rgba(0,0,0,0.24)",
    height: 150,
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
  },
  groomCameraScrimBottom: {
    backgroundColor: "rgba(0,0,0,0.28)",
    bottom: 0,
    height: 178,
    left: 0,
    position: "absolute",
    right: 0,
  },
  groomCameraTopBar: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    left: 0,
    paddingHorizontal: 18,
    position: "absolute",
    right: 0,
    top: 0,
    zIndex: 12,
  },
  groomCameraCloseButton: {
    alignItems: "center",
    backgroundColor: "rgba(5,8,13,0.38)",
    borderRadius: 999,
    height: 46,
    justifyContent: "center",
    width: 46,
  },
  groomCameraTopButton: {
    alignItems: "center",
    backgroundColor: "rgba(5,8,13,0.38)",
    borderRadius: 999,
    height: 46,
    justifyContent: "center",
    width: 46,
  },
  groomCameraFlipText: {
    color: "#fff",
    fontSize: 23,
    fontWeight: "900",
    lineHeight: 26,
  },
  groomCameraTitle: {
    color: "rgba(255,255,255,0.9)",
    fontSize: 14,
    fontWeight: "900",
    letterSpacing: 2,
  },
  groomCameraToolRail: {
    gap: 28,
    left: 30,
    position: "absolute",
    top: "38%",
    zIndex: 12,
  },
  groomCameraToolText: {
    color: "rgba(255,255,255,0.92)",
    fontSize: 36,
    fontWeight: "400",
    lineHeight: 39,
    textShadowColor: "rgba(0,0,0,0.2)",
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 5,
  },
  groomCameraToolCircle: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.86)",
    borderRadius: 999,
    borderWidth: 3,
    height: 62,
    justifyContent: "center",
    width: 62,
  },
  groomCameraToolSquare: {
    backgroundColor: "rgba(255,255,255,0.86)",
    borderRadius: 4,
    height: 18,
    width: 18,
  },
  groomCameraBottomBar: {
    alignItems: "center",
    bottom: 0,
    height: 158,
    justifyContent: "center",
    left: 0,
    paddingHorizontal: 22,
    position: "absolute",
    right: 0,
    zIndex: 12,
  },
  groomCameraShutter: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.34)",
    borderRadius: 999,
    height: 108,
    justifyContent: "center",
    width: 108,
  },
  groomCameraShutterInner: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.28)",
    borderRadius: 28,
    height: 56,
    justifyContent: "center",
    width: 56,
  },
  groomCameraLibraryButton: {
    alignItems: "center",
    backgroundColor: "rgba(5,8,13,0.44)",
    borderColor: "rgba(255,255,255,0.34)",
    borderRadius: 15,
    borderWidth: 1,
    left: 26,
    height: 58,
    justifyContent: "center",
    overflow: "hidden",
    position: "absolute",
    top: 42,
    width: 58,
  },
  groomCameraLibraryImage: {
    height: "100%",
    width: "100%",
  },
  groomCameraLibraryFallback: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.16)",
    height: "100%",
    justifyContent: "center",
    width: "100%",
  },
  groomCameraLibraryBusy: {
    ...StyleSheet.absoluteFillObject,
    alignItems: "center",
    backgroundColor: "rgba(5,8,13,0.42)",
    justifyContent: "center",
  },
  groomCameraPermission: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
    paddingHorizontal: 28,
  },
  groomCameraPermissionTitle: {
    color: "#fff",
    fontSize: 22,
    fontWeight: "900",
    marginBottom: 12,
    textAlign: "center",
  },
  groomCameraPermissionText: {
    color: "rgba(255,255,255,0.68)",
    fontSize: 14,
    fontWeight: "700",
    lineHeight: 21,
    marginBottom: 22,
    textAlign: "center",
  },
  groomCameraPermissionButton: {
    backgroundColor: "#fff",
    borderRadius: 999,
    paddingHorizontal: 22,
    paddingVertical: 12,
  },
  groomCameraPermissionButtonText: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  groomStoryEditorRoot: {
    backgroundColor: "#8f8c86",
    flex: 1,
  },
  groomStoryImageFrame: {
    backgroundColor: "#090b10",
    overflow: "hidden",
    position: "absolute",
    zIndex: 1,
  },
  groomStoryForegroundImage: {
    opacity: 1,
  },
  groomStoryImageGestureLayer: {
    ...StyleSheet.absoluteFillObject,
  },
  groomStoryBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#8f8c86",
  },
  groomStoryTopBar: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    left: 0,
    paddingHorizontal: 12,
    position: "absolute",
    right: 0,
    top: 0,
    zIndex: 20,
  },
  groomStoryToolCluster: {
    flexDirection: "row",
    gap: 8,
  },
  groomStoryToolButton: {
    alignItems: "center",
    backgroundColor: "rgba(5,8,13,0.34)",
    borderColor: "rgba(255,255,255,0.22)",
    borderRadius: 999,
    borderWidth: 1,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  groomStoryToolButtonActive: {
    backgroundColor: "rgba(255,255,255,0.24)",
    borderColor: "rgba(255,255,255,0.7)",
  },
  groomStoryToolText: {
    color: "#fff",
    fontSize: 17,
    fontWeight: "900",
    lineHeight: 20,
  },
  groomStoryTextEditLayer: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(0,0,0,0.62)",
    zIndex: 26,
  },
  groomStoryTextEditTopBar: {
    alignItems: "flex-end",
    left: 0,
    paddingHorizontal: 28,
    position: "absolute",
    right: 0,
    top: 0,
    zIndex: 2,
  },
  groomStoryTextDoneButton: {
    paddingHorizontal: 8,
    paddingVertical: 10,
  },
  groomStoryTextDoneButtonText: {
    color: "#fff",
    fontSize: 20,
    fontWeight: "900",
  },
  groomStoryLiveTextInput: {
    backgroundColor: "transparent",
    color: "#fff",
    fontSize: 42,
    fontWeight: "500",
    left: 34,
    lineHeight: 52,
    minHeight: 108,
    paddingHorizontal: 10,
    paddingVertical: 10,
    position: "absolute",
    right: 34,
    textAlignVertical: "center",
    top: "32%",
  },
  groomStoryLiveTextInputLabel: {
    backgroundColor: "rgba(5,8,13,0.42)",
    borderRadius: 18,
  },
  groomStoryLiveTextInputSolid: {
    backgroundColor: "rgba(255,255,255,0.92)",
    borderRadius: 20,
  },
  groomStoryTextControlTray: {
    alignItems: "center",
    gap: 10,
    left: 20,
    position: "absolute",
    right: 20,
  },
  groomStoryColorRow: {
    alignItems: "center",
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    justifyContent: "center",
    marginTop: 10,
  },
  groomStoryColorDot: {
    borderColor: "rgba(255,255,255,0.76)",
    borderRadius: 999,
    borderWidth: 1,
    height: 26,
    width: 26,
  },
  groomStoryColorDotActive: {
    borderColor: "#fff",
    borderWidth: 3,
    transform: [{ scale: 1.08 }],
  },
  groomStoryToneChip: {
    backgroundColor: "rgba(5,8,13,0.38)",
    borderColor: "rgba(255,255,255,0.24)",
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  groomStoryToneChipActive: {
    backgroundColor: "rgba(255,255,255,0.24)",
    borderColor: "rgba(255,255,255,0.72)",
  },
  groomStoryToneRow: {
    alignItems: "center",
    backgroundColor: "rgba(34,32,34,0.68)",
    borderRadius: 18,
    flexDirection: "row",
    gap: 8,
    justifyContent: "center",
    padding: 8,
  },
  groomStoryToneText: {
    color: "#fff",
    fontSize: 11,
    fontWeight: "900",
  },
  groomStoryDoneChip: {
    backgroundColor: "#fff",
    borderRadius: 999,
    paddingHorizontal: 13,
    paddingVertical: 8,
  },
  groomStoryDoneText: {
    color: ihubColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  groomStoryCancelChip: {
    backgroundColor: "rgba(5,8,13,0.42)",
    borderColor: "rgba(255,255,255,0.26)",
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  groomStoryCancelText: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "900",
  },
  groomStoryStickerTray: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 9,
    left: 14,
    position: "absolute",
    right: 14,
    zIndex: 18,
  },
  groomStoryStickerChoice: {
    backgroundColor: "rgba(5,8,13,0.42)",
    borderRadius: 999,
    borderWidth: 1,
    paddingHorizontal: 13,
    paddingVertical: 9,
  },
  groomStoryStickerChoiceText: {
    fontSize: 13,
    fontWeight: "900",
  },
  groomStoryDrawTray: {
    backgroundColor: "rgba(5,8,13,0.38)",
    borderColor: "rgba(255,255,255,0.2)",
    borderRadius: 20,
    borderWidth: 1,
    left: 14,
    paddingHorizontal: 13,
    paddingVertical: 11,
    position: "absolute",
    right: 14,
    zIndex: 18,
  },
  groomStoryDrawHint: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "900",
  },
  groomStoryBottomBar: {
    bottom: 0,
    gap: 10,
    left: 0,
    paddingHorizontal: 12,
    position: "absolute",
    right: 0,
    zIndex: 20,
  },
  groomStoryCaptionInput: {
    backgroundColor: "rgba(5,8,13,0.42)",
    borderColor: "rgba(255,255,255,0.28)",
    borderRadius: 24,
    borderWidth: 1,
    color: "#fff",
    fontSize: 14,
    fontWeight: "800",
    minHeight: 46,
    paddingHorizontal: 16,
    paddingVertical: 11,
  },
  groomStoryBottomActions: {
    flexDirection: "row",
    gap: 9,
  },
  groomStoryRetakeButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.16)",
    borderColor: "rgba(255,255,255,0.26)",
    borderRadius: 999,
    borderWidth: 1,
    flex: 1,
    paddingVertical: 13,
  },
  groomStoryRetakeText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "900",
  },
  groomStoryPublishButton: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 999,
    flex: 1,
    paddingVertical: 13,
  },
  groomStoryPublishText: {
    color: ihubColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  groomComposerLayer: {
    backgroundColor: "rgba(20,16,30,0.48)",
    flex: 1,
    justifyContent: "flex-end",
  },
  groomComposerPanel: {
    backgroundColor: "#fff",
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    gap: 13,
    paddingHorizontal: 18,
    paddingTop: 10,
  },
  groomComposerTitleRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  groomComposerTitleCopy: {
    flex: 1,
    gap: 2,
  },
  groomComposerClose: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.08)",
    borderRadius: ihubRadii.pill,
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  groomDraftImage: {
    alignSelf: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 26,
    height: 254,
    width: "100%",
  },
  groomCaptionInput: {
    backgroundColor: "rgba(166,149,216,0.09)",
    borderColor: "rgba(166,149,216,0.14)",
    borderRadius: 18,
    borderWidth: 1,
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "800",
    minHeight: 48,
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  groomComposerActions: {
    flexDirection: "row",
    gap: 10,
  },
  groomComposerSecondary: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: ihubRadii.pill,
    flex: 1,
    paddingVertical: 14,
  },
  groomComposerSecondaryText: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  groomComposerPrimary: {
    alignItems: "center",
    backgroundColor: ihubColors.lavender,
    borderRadius: ihubRadii.pill,
    flex: 1,
    paddingVertical: 14,
  },
  groomComposerPrimaryText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "900",
  },
  roundButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.82)",
    borderRadius: ihubRadii.pill,
    height: 38,
    justifyContent: "center",
    shadowColor: "#3a324a",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.07,
    shadowRadius: 6,
    width: 38,
  },
  pageTitle: {
    color: ihubColors.ink,
    fontSize: 36,
    fontWeight: "900",
    lineHeight: 42,
    paddingHorizontal: 6,
  },
  stageCard: {
    backgroundColor: "#f5ecf7",
    borderRadius: 28,
    minHeight: 452,
    overflow: "hidden",
    paddingBottom: 18,
    paddingTop: 56,
    position: "relative",
    shadowColor: ihubColors.lavender,
    shadowOffset: { width: 0, height: 14 },
    shadowOpacity: 0.2,
    shadowRadius: 30,
  },
  replayButton: {
    backgroundColor: "rgba(255,255,255,0.86)",
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: ihubRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 8,
    position: "absolute",
    right: 14,
    top: 14,
    zIndex: 3,
  },
  replayButtonText: {
    color: ihubColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  introCta: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.88)",
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 28,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    padding: 14,
    ...ihubShadow,
  },
  introCtaIcon: {
    alignItems: "center",
    backgroundColor: ihubColors.lavender,
    borderRadius: 18,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  introCtaCopy: {
    flex: 1,
    gap: 3,
  },
  introCtaTitle: {
    color: ihubColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  introCtaSub: {
    color: ihubColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  cloudA: {
    backgroundColor: "rgba(255,255,255,0.72)",
    borderRadius: 999,
    height: 18,
    left: 20,
    position: "absolute",
    top: 28,
    width: 78,
  },
  cloudB: {
    backgroundColor: "rgba(255,255,255,0.48)",
    borderRadius: 999,
    height: 14,
    position: "absolute",
    right: 28,
    top: 52,
    width: 62,
  },
  centerEyebrow: {
    textAlign: "center",
  },
  countRow: {
    alignItems: "flex-end",
    flexDirection: "row",
    justifyContent: "center",
    marginTop: 4,
  },
  bigCount: {
    color: ihubColors.lavender,
    fontSize: 62,
    fontWeight: "900",
    letterSpacing: 0,
    lineHeight: 66,
  },
  countUnit: {
    color: ihubColors.ink,
    fontSize: 24,
    fontWeight: "900",
    marginBottom: 8,
    marginLeft: 4,
  },
  stageTitle: {
    color: ihubColors.ink,
    fontSize: 19,
    fontWeight: "900",
    marginTop: -2,
    textAlign: "center",
  },
  speechBubble: {
    alignSelf: "center",
    backgroundColor: "rgba(255,255,255,0.9)",
    borderRadius: 18,
    bottom: 13,
    maxWidth: 278,
    paddingHorizontal: 14,
    paddingVertical: 9,
    position: "absolute",
    zIndex: 5,
  },
  speechText: {
    color: "rgba(58,50,74,0.66)",
    fontSize: 12.5,
    fontWeight: "700",
    lineHeight: 18,
    marginTop: 2,
  },
  bubbleTail: {
    backgroundColor: "rgba(255,255,255,0.9)",
    height: 12,
    position: "absolute",
    top: -5,
    transform: [{ rotate: "45deg" }],
    width: 12,
  },
  homeSceneFrame: {
    backgroundColor: "rgba(255,255,255,0.3)",
    borderColor: "rgba(255,255,255,0.76)",
    borderRadius: 24,
    borderWidth: 1,
    height: 226,
    marginHorizontal: 10,
    marginTop: 14,
    overflow: "hidden",
    position: "relative",
  },
  meguriSceneLoading: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  homeFallbackScene: {
    backgroundColor: "#c9f1ff",
    flex: 1,
    justifyContent: "flex-end",
    overflow: "hidden",
  },
  homeFallbackGround: {
    backgroundColor: "#bfecc2",
    borderTopLeftRadius: 120,
    borderTopRightRadius: 120,
    bottom: -36,
    height: 116,
    left: -22,
    position: "absolute",
    right: -22,
  },
  homeFallbackRow: {
    alignItems: "flex-end",
    flexDirection: "row",
    justifyContent: "center",
    paddingBottom: 12,
  },
  homeFallbackPerson: {
    marginHorizontal: -3,
    opacity: 0.92,
    transform: [{ scale: 0.94 }],
  },
  homeFallbackPersonActive: {
    opacity: 1,
    transform: [{ translateY: -5 }, { scale: 1.04 }],
  },
  stageFloor: {
    height: 214,
    marginTop: 12,
    overflow: "hidden",
    position: "relative",
  },
  floorGlow: {
    backgroundColor: "rgba(255,239,198,0.5)",
    borderRadius: 999,
    height: 42,
    left: "22%",
    position: "absolute",
    right: "22%",
    top: 24,
  },
  floorPlane: {
    backgroundColor: "rgba(104,163,128,0.46)",
    bottom: 0,
    height: 132,
    left: -10,
    position: "absolute",
    right: -10,
    transform: [{ skewX: "-10deg" }],
  },
  backRow: {
    flexDirection: "row",
    gap: 30,
    justifyContent: "center",
    left: 0,
    position: "absolute",
    right: 0,
    top: 58,
  },
  frontRow: {
    alignItems: "flex-end",
    bottom: 16,
    flexDirection: "row",
    gap: 16,
    justifyContent: "center",
    left: 0,
    position: "absolute",
    right: 0,
  },
  stagePersonBack: {
    opacity: 0.78,
    transform: [{ scale: 0.88 }],
  },
  stagePersonActiveBack: {
    opacity: 1,
    transform: [{ translateY: -8 }, { scale: 0.98 }],
  },
  stagePersonFront: {
    opacity: 0.94,
    transform: [{ scale: 0.98 }],
  },
  stagePersonActiveFront: {
    opacity: 1,
    transform: [{ translateY: -8 }, { scale: 1.08 }],
  },
  stageFooter: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.56)",
    borderTopColor: "rgba(255,255,255,0.8)",
    borderTopWidth: 1,
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  dots: {
    alignItems: "center",
    flexDirection: "row",
    gap: 5,
  },
  dot: {
    backgroundColor: "rgba(58,50,74,0.22)",
    borderRadius: 999,
    height: 6,
    width: 6,
  },
  dotActive: {
    backgroundColor: ihubColors.lavender,
    width: 18,
  },
  stageChips: {
    flexDirection: "row",
    gap: 6,
  },
  miniChip: {
    backgroundColor: "rgba(255,255,255,0.8)",
    borderRadius: ihubRadii.pill,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  miniChipText: {
    color: ihubColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  nextButton: {
    backgroundColor: ihubColors.lavender,
    borderRadius: ihubRadii.pill,
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  nextButtonText: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "900",
  },
  walker: {
    alignItems: "center",
    paddingBottom: 20,
    position: "relative",
  },
  armRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    left: -8,
    position: "absolute",
    right: -8,
    zIndex: 0,
  },
  arm: {
    borderRadius: 99,
    height: 7,
    opacity: 0.85,
    width: 20,
  },
  leftArm: {
    transformOrigin: "100% 50%",
  },
  rightArm: {
    transformOrigin: "0% 50%",
  },
  walkerBody: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderWidth: 2,
    justifyContent: "center",
    overflow: "hidden",
    position: "relative",
    zIndex: 1,
  },
  avatarPattern: {
    height: "100%",
    opacity: 0.92,
    position: "absolute",
    width: "100%",
  },
  walkerInitial: {
    color: "#fff",
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.26)",
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  legs: {
    bottom: 12,
    flexDirection: "row",
    gap: 10,
    position: "absolute",
    zIndex: 0,
  },
  leg: {
    borderRadius: 99,
    height: 19,
    opacity: 0.82,
    width: 7,
  },
  walkerShadow: {
    backgroundColor: "rgba(0,0,0,0.16)",
    borderRadius: 999,
    bottom: 5,
    height: 6,
    position: "absolute",
    width: "76%",
  },
  statsRow: {
    flexDirection: "row",
    gap: 14,
    paddingHorizontal: 6,
  },
  numLine: {
    flex: 1,
  },
  numValue: {
    color: ihubColors.ink,
    fontSize: 24,
    fontWeight: "900",
  },
  numLabel: {
    color: "rgba(58,50,74,0.54)",
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  shortcutGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
  },
  shortcutCard: {
    borderRadius: 20,
    minHeight: 92,
    padding: 13,
    width: "48.5%",
  },
  shortcutIcon: {
    alignItems: "center",
    borderRadius: 13,
    height: 34,
    justifyContent: "center",
    marginBottom: 10,
    width: 34,
  },
  shortcutTitle: {
    color: ihubColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  shortcutSubtitle: {
    color: "rgba(58,50,74,0.56)",
    fontSize: 11.5,
    fontWeight: "800",
    marginTop: 3,
  },
  hitokotoCard: {
    alignItems: "center",
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 22,
    borderWidth: 1,
    flexDirection: "row",
    gap: 14,
    padding: 16,
    ...ihubShadow,
  },
  hitokotoIcon: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    borderRadius: 15,
    height: 44,
    justifyContent: "center",
    width: 44,
  },
  hitokotoCopy: {
    flex: 1,
  },
  hitokotoTitle: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  hitokotoSub: {
    color: "rgba(58,50,74,0.56)",
    fontSize: 12,
    fontWeight: "800",
    marginTop: 2,
  },
  hitokotoButton: {
    backgroundColor: ihubColors.lavender,
    borderRadius: ihubRadii.pill,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  hitokotoButtonText: {
    color: "#fff",
    fontSize: 13,
    fontWeight: "900",
  },
  topOnlyNote: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.1)",
    borderRadius: 20,
    paddingHorizontal: 18,
    paddingVertical: 12,
  },
  topOnlyText: {
    color: "rgba(58,50,74,0.58)",
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    textAlign: "center",
  },
  sectionHeader: {
    gap: 4,
    marginTop: 4,
    paddingHorizontal: 6,
  },
  sectionTitle: {
    color: "#111",
    fontSize: 25,
    fontWeight: "900",
    lineHeight: 31,
  },
  sectionSubtitle: {
    color: "rgba(58,50,74,0.56)",
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  plazaCard: {
    backgroundColor: ihubColors.surface,
    borderRadius: 26,
    gap: 16,
    padding: 18,
    ...ihubShadow,
  },
  plazaRow: {
    flexDirection: "row",
    justifyContent: "space-around",
  },
  plazaItem: {
    alignItems: "center",
    width: 86,
  },
  plazaName: {
    color: "rgba(58,50,74,0.58)",
    fontSize: 10.5,
    fontWeight: "900",
    marginTop: -8,
  },
  mapCard: {
    backgroundColor: "#eef6fb",
    borderRadius: 26,
    height: 232,
    overflow: "hidden",
    position: "relative",
  },
  mapBlobA: {
    backgroundColor: "rgba(166,149,216,0.24)",
    borderRadius: 80,
    height: 120,
    left: 26,
    position: "absolute",
    top: 34,
    width: 130,
  },
  mapBlobB: {
    backgroundColor: "rgba(168,212,230,0.46)",
    borderRadius: 90,
    height: 132,
    position: "absolute",
    right: 32,
    top: 22,
    width: 150,
  },
  mapBlobC: {
    backgroundColor: "rgba(243,197,212,0.34)",
    borderRadius: 80,
    bottom: 22,
    height: 98,
    left: 118,
    position: "absolute",
    width: 120,
  },
  mapPin: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.9)",
    borderRadius: 18,
    borderWidth: 2,
    minWidth: 58,
    paddingHorizontal: 10,
    paddingVertical: 8,
    position: "absolute",
  },
  mapPinCount: {
    color: "#fff",
    fontSize: 18,
    fontWeight: "900",
    lineHeight: 20,
  },
  mapPinLabel: {
    color: "#fff",
    fontSize: 10,
    fontWeight: "900",
    marginTop: 1,
  },
  mapFootnote: {
    bottom: 16,
    color: "rgba(58,50,74,0.58)",
    fontSize: 11,
    fontWeight: "800",
    left: 18,
    position: "absolute",
  },
  achievementGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
  },
  achievementCard: {
    borderRadius: 20,
    minHeight: 132,
    padding: 14,
    width: "48.5%",
  },
  achievementIcon: {
    alignItems: "center",
    borderRadius: 13,
    height: 34,
    justifyContent: "center",
    marginBottom: 12,
    width: 34,
  },
  achievementTitle: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  achievementText: {
    color: "rgba(58,50,74,0.58)",
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
    marginTop: 5,
  },
  letterList: {
    gap: 12,
  },
  letterEnvelope: {
    backgroundColor: "#f7efdc",
    borderRadius: 22,
    overflow: "hidden",
    padding: 18,
    position: "relative",
    shadowColor: "#8b6d35",
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.12,
    shadowRadius: 20,
  },
  waxSeal: {
    alignSelf: "center",
    backgroundColor: "#d58aa2",
    borderRadius: 999,
    height: 38,
    position: "absolute",
    top: -15,
    width: 38,
  },
  creaseLeft: {
    backgroundColor: "rgba(138,107,53,0.05)",
    height: "55%",
    left: 0,
    position: "absolute",
    top: 0,
    transform: [{ skewY: "-24deg" }],
    width: "50%",
  },
  creaseRight: {
    backgroundColor: "rgba(138,107,53,0.05)",
    height: "55%",
    position: "absolute",
    right: 0,
    top: 0,
    transform: [{ skewY: "24deg" }],
    width: "50%",
  },
  letterStatusRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  letterStatus: {
    color: "#9b7445",
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.8,
  },
  letterAffinity: {
    color: "rgba(58,50,74,0.56)",
    fontSize: 12,
    fontWeight: "900",
  },
  letterFrom: {
    color: ihubColors.ink,
    fontSize: 19,
    fontWeight: "900",
    marginTop: 7,
  },
  letterMeta: {
    color: "rgba(58,50,74,0.56)",
    fontSize: 12,
    fontWeight: "800",
    marginTop: 3,
  },
  letterPreview: {
    backgroundColor: "rgba(255,255,255,0.52)",
    borderRadius: 12,
    marginTop: 10,
    padding: 10,
  },
  letterPreviewText: {
    color: ihubColors.ink,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 19,
  },
  blurText: {
    color: "rgba(58,50,74,0.22)",
  },
  letterHintRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12,
    marginTop: 12,
  },
  letterHint: {
    color: "rgba(58,50,74,0.56)",
    fontSize: 11,
    fontWeight: "800",
  },
  sendCard: {
    backgroundColor: ihubColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 24,
    borderWidth: 1,
    gap: 10,
    padding: 16,
  },
  sendMeter: {
    flexDirection: "row",
    gap: 8,
  },
  sendMeterDot: {
    borderRadius: ihubRadii.pill,
    height: 10,
    width: 48,
  },
  sendMeterDotUsed: {
    backgroundColor: ihubColors.lavender,
  },
  sendMeterDotOpen: {
    backgroundColor: "rgba(58,50,74,0.12)",
  },
  sendTitle: {
    color: ihubColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  sendBody: {
    color: "rgba(58,50,74,0.58)",
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  sendButton: {
    alignItems: "center",
    backgroundColor: ihubColors.lavender,
    borderRadius: 18,
    marginTop: 4,
    paddingVertical: 14,
  },
  sendButtonText: {
    color: ihubColors.surface,
    fontSize: 14,
    fontWeight: "900",
  },
  plusCard: {
    backgroundColor: ihubColors.ink,
    borderRadius: 26,
    gap: 10,
    padding: 18,
  },
  plusKicker: {
    color: "rgba(255,255,255,0.58)",
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.5,
  },
  plusTitle: {
    color: "#fff",
    fontSize: 25,
    fontWeight: "900",
  },
  plusText: {
    color: "rgba(255,255,255,0.76)",
    fontSize: 12.5,
    fontWeight: "800",
    lineHeight: 19,
  },
  plusButton: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 18,
    marginTop: 4,
    paddingVertical: 13,
  },
  plusButtonText: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  modalLayer: {
    backgroundColor: "rgba(20,16,28,0.28)",
    flex: 1,
    justifyContent: "flex-end",
  },
  centerModalLayer: {
    alignItems: "center",
    backgroundColor: "rgba(20,16,28,0.28)",
    flex: 1,
    justifyContent: "center",
    padding: 18,
  },
  modalBackdrop: {
    ...StyleSheet.absoluteFillObject,
  },
  modalPanel: {
    backgroundColor: ihubColors.surface,
    borderTopLeftRadius: 30,
    borderTopRightRadius: 30,
    gap: 13,
    padding: 20,
    paddingBottom: 30,
  },
  letterModalPanel: {
    backgroundColor: ihubColors.surface,
    borderRadius: 30,
    gap: 13,
    padding: 20,
    width: "100%",
  },
  modalHandle: {
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.16)",
    borderRadius: ihubRadii.pill,
    height: 5,
    marginBottom: 6,
    width: 46,
  },
  modalKicker: {
    color: ihubColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.4,
  },
  modalTitle: {
    color: ihubColors.ink,
    fontSize: 24,
    fontWeight: "900",
    lineHeight: 30,
  },
  modalPrice: {
    color: ihubColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  modalSub: {
    color: "rgba(58,50,74,0.60)",
    fontSize: 12.5,
    fontWeight: "800",
    lineHeight: 19,
  },
  settingsList: {
    gap: 10,
  },
  settingRow: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.045)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    padding: 13,
  },
  settingIcon: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.15)",
    borderRadius: 14,
    height: 38,
    justifyContent: "center",
    width: 38,
  },
  settingCopy: {
    flex: 1,
    gap: 2,
  },
  settingTitle: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  settingSub: {
    color: "rgba(58,50,74,0.58)",
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 17,
  },
  settingSwitch: {
    backgroundColor: "rgba(58,50,74,0.18)",
    borderRadius: ihubRadii.pill,
    height: 30,
    justifyContent: "center",
    paddingHorizontal: 3,
    width: 52,
  },
  settingSwitchOn: {
    backgroundColor: ihubColors.lavender,
  },
  settingKnob: {
    backgroundColor: "#fff",
    borderRadius: ihubRadii.pill,
    height: 24,
    width: 24,
  },
  settingKnobOn: {
    alignSelf: "flex-end",
  },
  planBullets: {
    gap: 9,
  },
  planBullet: {
    flexDirection: "row",
    gap: 8,
  },
  planBulletDot: {
    color: ihubColors.lavender,
    fontSize: 18,
    fontWeight: "900",
    lineHeight: 20,
  },
  planBulletText: {
    color: ihubColors.ink,
    flex: 1,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 20,
  },
  modalPrimaryButton: {
    alignItems: "center",
    backgroundColor: ihubColors.lavender,
    borderRadius: 18,
    marginTop: 4,
    paddingVertical: 14,
  },
  disabledButton: {
    opacity: 0.42,
  },
  modalPrimaryText: {
    color: ihubColors.surface,
    fontSize: 14,
    fontWeight: "900",
  },
  modalCloseButton: {
    alignItems: "center",
    paddingVertical: 8,
  },
  modalCloseText: {
    color: "rgba(58,50,74,0.58)",
    fontSize: 13,
    fontWeight: "900",
  },
  bigLock: {
    alignItems: "center",
    alignSelf: "center",
    backgroundColor: "rgba(166,149,216,0.18)",
    borderRadius: 28,
    height: 62,
    justifyContent: "center",
    marginTop: 4,
    width: 62,
  },
  lockExplain: {
    color: ihubColors.ink,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 20,
    textAlign: "center",
  },
  letterBody: {
    color: ihubColors.ink,
    fontSize: 15,
    fontWeight: "800",
    lineHeight: 24,
  },
  composerInput: {
    backgroundColor: "rgba(58,50,74,0.05)",
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: 18,
    borderWidth: 1,
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "800",
    minHeight: 124,
    padding: 14,
    textAlignVertical: "top",
  },
});
