import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import Constants from "expo-constants";
import { router, useFocusEffect, useLocalSearchParams } from "expo-router";
import * as ImagePicker from "expo-image-picker";
import {
  ActionSheetIOS,
  ActivityIndicator,
  Alert,
  Image,
  Linking,
  Modal,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  Share,
  StyleSheet,
  Text,
  TextInput,
  type StyleProp,
  type TextStyle,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useAuth } from "../src/auth/AuthProvider";
import { ChatGradientBubble } from "../src/components/ChatGradientBubble";
import { IconSymbol, type IconSymbolName } from "../src/components/IconSymbol";
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
  MEGURI_BOARD_REPORT_REASONS,
  MEGURI_BOARD_COMPOSER_CATEGORY_OPTIONS,
  meguriBoardCategoryLabel,
  meguriBoardReportReasonLabel,
  reportMeguriBoardReply,
  reportMeguriBoardThread,
  clearMeguriBoardReplyDraft,
  setMeguriBoardThreadStatus,
  loadMeguriBoardReplyDraft,
  saveMeguriBoardReplyDraft,
  updateMeguriBoardReply,
  updateMeguriBoardThread,
  type MeguriBoardActor,
  type MeguriBoardAudienceScope,
  type MeguriBoardReply,
  type MeguriBoardReportReason,
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

const REPLY_BODY_LIMIT = 500;
const REPLY_BODY_COLLAPSE_THRESHOLD = 180;
const REPLY_BODY_COLLAPSED_LINES = 6;

type BoardParticipant = {
  handle: string | null;
  id: string;
  isAuthor: boolean;
  lastActiveAt: number;
  mine: boolean;
  name: string;
  primaryArea: string | null;
  replyCount: number;
};

type BoardMediaAttachment = {
  authorName: string;
  body: string;
  createdAt: number;
  id: string;
  replyId: string | null;
  source: "thread" | "reply";
  uri: string;
};

type BoardReplySortMode = "oldest" | "newest" | "popular";
type BoardParticipantSortMode = "recent" | "replies";
type NewReplyNotice = { count: number; firstReplyId: string } | null;
type BoardContextAction = {
  destructive?: boolean;
  disabled?: boolean;
  icon: IconSymbolName;
  key: string;
  label: string;
  onPress: () => void;
};
type ReplySearchSource =
  | {
      label: string;
      replyId?: string;
      type: "author" | "children" | "media" | "mention" | "mine" | "participant";
    }
  | null;

const REPLY_SORT_OPTIONS: { label: string; value: BoardReplySortMode }[] = [
  { label: "古い順", value: "oldest" },
  { label: "新着順", value: "newest" },
  { label: "参考順", value: "popular" },
];

const PARTICIPANT_SORT_OPTIONS: { label: string; value: BoardParticipantSortMode }[] = [
  { label: "最近", value: "recent" },
  { label: "返信数", value: "replies" },
];

const INLINE_URL_PATTERN = /(https?:\/\/[^\s]+)/gi;
const URL_TRAILING_PUNCTUATION_PATTERN = /[.,!?;:)\]}]+$/;

export default function MeguriBoardThreadScreen() {
  const insets = useSafeAreaInsets();
  const keyboardInset = useKeyboardInset();
  const params = useLocalSearchParams<{
    focusReply?: string | string[];
    id?: string | string[];
    prefecture?: string | string[];
    replyId?: string | string[];
    spotKey?: string | string[];
    spotLabel?: string | string[];
    viewerLat?: string | string[];
    viewerLng?: string | string[];
    viewMode?: string | string[];
  }>();
  const threadId = readParam(params.id);
  const sharedReplyId = readParam(params.replyId);
  const shouldFocusReplyComposer = readParam(params.focusReply) === "1";
  const { previewMode, profile, user } = useAuth();
  const [localArea, setLocalArea] = useState(DEFAULT_MEGURI_PROFILE.baseArea);
  const [localDisplayName, setLocalDisplayName] = useState(DEFAULT_MEGURI_PROFILE.displayName);
  const [thread, setThread] = useState<MeguriBoardThread | null>(null);
  const [replies, setReplies] = useState<MeguriBoardReply[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [newReplyNotice, setNewReplyNotice] = useState<NewReplyNotice>(null);
  const [locationContext, setLocationContext] = useState<MegrumLocationContext | null>(null);
  const [draft, setDraft] = useState("");
  const [draftImageUris, setDraftImageUris] = useState<string[]>([]);
  const [replyDraftReady, setReplyDraftReady] = useState(false);
  const [sending, setSending] = useState(false);
  const [sendError, setSendError] = useState<string | null>(null);
  const [replySearchText, setReplySearchText] = useState("");
  const [replySearchSource, setReplySearchSource] = useState<ReplySearchSource>(null);
  const [replyJumpText, setReplyJumpText] = useState("");
  const [quoteTarget, setQuoteTarget] = useState<MeguriBoardReply | null>(null);
  const [threadEditorOpen, setThreadEditorOpen] = useState(false);
  const [threadEditTitle, setThreadEditTitle] = useState("");
  const [threadEditBody, setThreadEditBody] = useState("");
  const [threadEditCategory, setThreadEditCategory] =
    useState<Exclude<MeguriBoardThreadCategory, "all">>("chat");
  const [replyEditor, setReplyEditor] = useState<MeguriBoardReply | null>(null);
  const [replyEditBody, setReplyEditBody] = useState("");
  const [imagePreviewUri, setImagePreviewUri] = useState<string | null>(null);
  const [previousReadAt, setPreviousReadAt] = useState<number | null>(null);
  const [participantsOpen, setParticipantsOpen] = useState(false);
  const [participantSearchText, setParticipantSearchText] = useState("");
  const [participantSortMode, setParticipantSortMode] = useState<BoardParticipantSortMode>("recent");
  const [mediaGalleryOpen, setMediaGalleryOpen] = useState(false);
  const [threadInfoOpen, setThreadInfoOpen] = useState(false);
  const [threadActionMenuOpen, setThreadActionMenuOpen] = useState(false);
  const [replyActionMenuReply, setReplyActionMenuReply] = useState<MeguriBoardReply | null>(null);
  const [threadBodyExpanded, setThreadBodyExpanded] = useState(false);
  const [expandedReplyIds, setExpandedReplyIds] = useState<Set<string>>(() => new Set());
  const [replySortMode, setReplySortMode] = useState<BoardReplySortMode>("oldest");
  const [searchCursorIndex, setSearchCursorIndex] = useState(0);
  const [highlightedReplyId, setHighlightedReplyId] = useState<string | null>(null);
  const [replyReturnTargetId, setReplyReturnTargetId] = useState<string | null>(null);
  const scrollViewRef = useRef<ScrollView | null>(null);
  const composerInputRef = useRef<TextInput | null>(null);
  const replyOffsetsRef = useRef<Record<string, number>>({});
  const newReplyNoticeRef = useRef<NewReplyNotice>(null);
  const repliesRef = useRef<MeguriBoardReply[]>([]);
  const focusReplyThreadIdRef = useRef<string | null>(null);
  const sharedReplyScrollKeyRef = useRef<string | null>(null);
  const highlightedReplyTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

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

  const replyNumberById = useMemo(() => {
    return new Map(replies.map((reply, index) => [reply.id, index + 1]));
  }, [replies]);

  const replyChildCountById = useMemo(() => {
    const counts = new Map<string, number>();
    replies.forEach((reply) => {
      if (!reply.parentReplyId || reply.deleted) return;
      counts.set(reply.parentReplyId, (counts.get(reply.parentReplyId) ?? 0) + 1);
    });
    return counts;
  }, [replies]);

  const replySearchQuery = useMemo(() => normalizeReplySearch(replySearchText), [replySearchText]);

  const filteredReplies = useMemo(() => {
    if (replySearchSource?.type === "children" && replySearchSource.replyId) {
      return replies.filter((reply) => reply.parentReplyId === replySearchSource.replyId);
    }
    if (replySearchSource?.type === "mine") {
      return replies.filter((reply) => reply.mine);
    }
    if (replySearchSource?.type === "media") {
      return replies.filter((reply) => !reply.deleted && reply.imageUris.length > 0);
    }
    if (replySearchSource?.type === "author" && thread) {
      return replies.filter((reply) => !reply.deleted && reply.authorId === thread.authorId);
    }
    if (!replySearchQuery) return replies;
    return replies.filter((reply) => {
      return normalizeReplySearch(
        [
          reply.authorName,
          reply.authorHandle,
          reply.body,
          reply.quotedAuthorName,
          reply.quotedBody,
        ]
          .filter(Boolean)
          .join(" "),
      ).includes(replySearchQuery);
    });
  }, [replies, replyNumberById, replySearchQuery, replySearchSource?.replyId, replySearchSource?.type, thread]);

  const sortedReplies = useMemo(() => {
    const next = [...filteredReplies];
    if (replySortMode === "newest") {
      next.sort((left, right) => right.createdAt - left.createdAt);
      return next;
    }
    if (replySortMode === "popular") {
      next.sort((left, right) => {
        const scoreDiff = right.reactionCount - left.reactionCount;
        if (scoreDiff !== 0) return scoreDiff;
        return right.createdAt - left.createdAt;
      });
      return next;
    }
    next.sort((left, right) => left.createdAt - right.createdAt);
    return next;
  }, [filteredReplies, replySortMode]);

  const activeFilteredReply = useMemo(() => {
    if (!replySearchQuery || sortedReplies.length === 0) return null;
    const index = Math.min(Math.max(searchCursorIndex, 0), sortedReplies.length - 1);
    return sortedReplies[index] ?? sortedReplies[0] ?? null;
  }, [replySearchQuery, searchCursorIndex, sortedReplies]);

  const replyReturnTarget = useMemo(() => {
    if (!replyReturnTargetId) return null;
    return replies.find((reply) => reply.id === replyReturnTargetId) ?? null;
  }, [replies, replyReturnTargetId]);

  const unreadSeparatorReplyId = useMemo(() => {
    if (replySearchQuery || replies.length === 0) return null;
    const firstUnreadReply = replies.find((reply) => !previousReadAt || reply.createdAt > previousReadAt);
    return firstUnreadReply?.id ?? null;
  }, [previousReadAt, replies, replySearchQuery]);

  const participants = useMemo<BoardParticipant[]>(() => {
    if (!thread) return [];
    const participantMap = new Map<string, BoardParticipant>();
    const upsertParticipant = (input: {
      handle: string | null;
      id: string;
      isAuthor?: boolean;
      lastActiveAt: number;
      mine?: boolean;
      name: string;
      primaryArea: string | null;
      replyIncrement?: number;
    }) => {
      const existing = participantMap.get(input.id);
      if (existing) {
        participantMap.set(input.id, {
          ...existing,
          handle: existing.handle ?? input.handle,
          isAuthor: existing.isAuthor || !!input.isAuthor,
          lastActiveAt: Math.max(existing.lastActiveAt, input.lastActiveAt),
          mine: existing.mine || !!input.mine,
          name: existing.name || input.name,
          primaryArea: existing.primaryArea ?? input.primaryArea,
          replyCount: existing.replyCount + (input.replyIncrement ?? 0),
        });
        return;
      }
      participantMap.set(input.id, {
        handle: input.handle,
        id: input.id,
        isAuthor: !!input.isAuthor,
        lastActiveAt: input.lastActiveAt,
        mine: !!input.mine,
        name: input.name,
        primaryArea: input.primaryArea,
        replyCount: input.replyIncrement ?? 0,
      });
    };
    upsertParticipant({
      handle: thread.authorHandle,
      id: thread.authorId,
      isAuthor: true,
      lastActiveAt: thread.createdAt,
      mine: thread.mine || thread.authorId === actor.userId,
      name: thread.authorName,
      primaryArea: thread.authorPrimaryArea,
    });
    replies.forEach((reply) => {
      if (reply.deleted) return;
      upsertParticipant({
        handle: reply.authorHandle,
        id: reply.authorId,
        lastActiveAt: reply.createdAt,
        mine: reply.mine || reply.authorId === actor.userId,
        name: reply.authorName,
        primaryArea: reply.authorPrimaryArea,
        replyIncrement: 1,
      });
    });
    return Array.from(participantMap.values()).sort((left, right) => {
      if (left.isAuthor !== right.isAuthor) return left.isAuthor ? -1 : 1;
      return right.lastActiveAt - left.lastActiveAt;
    });
  }, [actor.userId, replies, thread]);

  const participantSearchQuery = useMemo(
    () => normalizeReplySearch(participantSearchText),
    [participantSearchText],
  );

  const filteredParticipants = useMemo(() => {
    if (!participantSearchQuery) return participants;
    return participants.filter((participant) => {
      const searchable = [
        participant.name,
        participant.handle,
        participant.handle ? `@${participant.handle.replace(/^@/, "")}` : null,
        participant.primaryArea,
        participant.mine ? "あなた" : null,
        participant.isAuthor ? "作成者" : null,
      ]
        .filter(Boolean)
        .join(" ");
      return normalizeReplySearch(searchable).includes(participantSearchQuery);
    });
  }, [participantSearchQuery, participants]);

  const sortedParticipants = useMemo(() => {
    const next = [...filteredParticipants];
    next.sort((left, right) => {
      if (participantSortMode === "replies") {
        const replyDiff = right.replyCount - left.replyCount;
        if (replyDiff !== 0) return replyDiff;
      } else if (left.isAuthor !== right.isAuthor) {
        return left.isAuthor ? -1 : 1;
      }
      const activeDiff = right.lastActiveAt - left.lastActiveAt;
      if (activeDiff !== 0) return activeDiff;
      if (left.isAuthor !== right.isAuthor) return left.isAuthor ? -1 : 1;
      return left.name.localeCompare(right.name, "ja");
    });
    return next;
  }, [filteredParticipants, participantSortMode]);

  const activeMentionQuery = useMemo(() => extractDraftMentionQuery(draft), [draft]);
  const mentionSuggestions = useMemo(() => {
    if (activeMentionQuery === null) return [];
    return participants
      .filter((participant) => !participant.mine && (participant.handle || participant.name))
      .filter((participant) => {
        const needle = activeMentionQuery;
        if (!needle) return true;
        return normalizeReplySearch(
          [participant.name, participant.handle, participant.primaryArea].filter(Boolean).join(" "),
        ).includes(needle);
      })
      .slice(0, 6);
  }, [activeMentionQuery, participants]);

  const mediaAttachments = useMemo<BoardMediaAttachment[]>(() => {
    if (!thread) return [];
    const attachments: BoardMediaAttachment[] = thread.imageUris.map((uri, index) => ({
      authorName: thread.authorName,
      body: thread.body,
      createdAt: thread.createdAt,
      id: `thread-${index}-${uri}`,
      replyId: null,
      source: "thread",
      uri,
    }));
    replies.forEach((reply) => {
      if (reply.deleted) return;
      reply.imageUris.forEach((uri, index) => {
        attachments.push({
          authorName: reply.authorName,
          body: reply.body,
          createdAt: reply.createdAt,
          id: `reply-${reply.id}-${index}-${uri}`,
          replyId: reply.id,
          source: "reply",
          uri,
        });
      });
    });
    return attachments;
  }, [replies, thread]);
  const threadInfoRows = useMemo(() => {
    if (!thread) return [];
    return [
      { label: "カテゴリ", value: meguriBoardCategoryLabel(thread.category) },
      { label: "公開範囲", value: meguriBoardAudienceLabel(thread.audienceScope) },
      { label: "場所", value: thread.spotLabel || thread.prefecture || "未設定" },
      { label: "作成者", value: thread.authorName },
      { label: "作成日時", value: formatAbsoluteDateTime(thread.createdAt) },
      { label: "最終更新", value: formatAbsoluteDateTime(thread.latestActivityAt) },
      { label: "返信", value: `${thread.replyCount}件` },
      { label: "参加者", value: `${participants.length}人` },
      { label: "画像", value: `${mediaAttachments.length}枚` },
      { label: "参考", value: `${thread.reactionCount}件` },
      { label: "閲覧", value: `${thread.viewCount}回` },
      { label: "状態", value: thread.status === "locked" ? "締め切り" : "表示中" },
    ];
  }, [mediaAttachments.length, participants.length, thread]);
  const threadBodyCollapsible = (thread?.body.trim().length ?? 0) > 180;
  const hasReplyDraft = !!draft.trim() || draftImageUris.length > 0;
  const viewerMentionReplies = useMemo(
    () => replies.filter((reply) => !reply.mine && replyMentionsHandle(reply.body, actor.handle)),
    [actor.handle, replies],
  );
  const viewerReplies = useMemo(() => replies.filter((reply) => reply.mine), [replies]);
  const mediaReplies = useMemo(
    () => replies.filter((reply) => !reply.deleted && reply.imageUris.length > 0),
    [replies],
  );
  const threadAuthorReplies = useMemo(() => {
    if (!thread) return [];
    return replies.filter((reply) => !reply.deleted && reply.authorId === thread.authorId);
  }, [replies, thread]);

  useEffect(() => {
    setSearchCursorIndex(0);
  }, [replySearchQuery, replySortMode]);

  useEffect(() => {
    setThreadBodyExpanded(false);
  }, [thread?.id]);

  useEffect(() => {
    repliesRef.current = replies;
  }, [replies]);

  useEffect(() => {
    newReplyNoticeRef.current = newReplyNotice;
  }, [newReplyNotice]);

  useEffect(() => {
    if (sortedReplies.length === 0) {
      if (searchCursorIndex !== 0) setSearchCursorIndex(0);
      return;
    }
    if (searchCursorIndex >= sortedReplies.length) {
      setSearchCursorIndex(0);
    }
  }, [searchCursorIndex, sortedReplies.length]);

  useEffect(() => {
    return () => {
      if (highlightedReplyTimerRef.current) {
        clearTimeout(highlightedReplyTimerRef.current);
      }
    };
  }, []);

  useEffect(() => {
    if (!sharedReplyId || loading || replies.length === 0) return;
    if (sharedReplyScrollKeyRef.current === sharedReplyId) return;
    if (!replies.some((reply) => reply.id === sharedReplyId)) return;
    sharedReplyScrollKeyRef.current = sharedReplyId;
    let attempts = 0;
    const runScroll = () => {
      const y = replyOffsetsRef.current[sharedReplyId];
      if (typeof y === "number") {
        if (replySearchText.trim()) {
          clearReplySearch();
        }
        highlightReply(sharedReplyId);
        scrollViewRef.current?.scrollTo({ animated: true, y: Math.max(0, y - 12) });
        return;
      }
      attempts += 1;
      if (attempts < 5) {
        setTimeout(runScroll, 160);
      }
    };
    setTimeout(runScroll, 240);
  }, [loading, replies, replySearchText, sharedReplyId]);

  function highlightReply(replyId: string) {
    setHighlightedReplyId(replyId);
    if (highlightedReplyTimerRef.current) {
      clearTimeout(highlightedReplyTimerRef.current);
    }
    highlightedReplyTimerRef.current = setTimeout(() => {
      setHighlightedReplyId((current) => (current === replyId ? null : current));
      highlightedReplyTimerRef.current = null;
    }, 2600);
  }

  function scrollToLatestReply(animated = true) {
    const latestReply = replies.reduce<MeguriBoardReply | null>((latest, reply) => {
      if (!latest || reply.createdAt > latest.createdAt) return reply;
      return latest;
    }, null);
    requestAnimationFrame(() => {
      if (latestReply) {
        const y = replyOffsetsRef.current[latestReply.id];
        if (typeof y === "number") {
          scrollViewRef.current?.scrollTo({ animated, y: Math.max(0, y - 12) });
          return;
        }
      }
      if (replySortMode === "newest") {
        scrollViewRef.current?.scrollTo({ animated, y: 0 });
        return;
      }
      scrollViewRef.current?.scrollToEnd({ animated });
    });
  }

  function focusReplyComposer() {
    if (thread?.status === "locked") return;
    requestAnimationFrame(() => {
      scrollViewRef.current?.scrollToEnd({ animated: true });
      composerInputRef.current?.focus();
    });
  }

  function openParticipants() {
    setParticipantSearchText("");
    setParticipantsOpen(true);
  }

  function closeParticipants() {
    setParticipantsOpen(false);
    setParticipantSearchText("");
  }

  function filterRepliesByParticipant(participant: BoardParticipant) {
    if (participant.replyCount === 0) return;
    setReplySearchText(participant.handle || participant.name);
    setReplySearchSource({ label: participant.name, type: "participant" });
    closeParticipants();
  }

  function filterRepliesByReplyAuthor(reply: MeguriBoardReply) {
    const participant = participants.find((candidate) => candidate.id === reply.authorId);
    if (!participant) return;
    filterRepliesByParticipant(participant);
  }

  function filterViewerMentions() {
    const handle = actor.handle?.trim().replace(/^@/, "");
    if (!handle || viewerMentionReplies.length === 0) return;
    setReplySearchText(`@${handle}`);
    setReplySearchSource({ label: `@${handle}`, type: "mention" });
    setSearchCursorIndex(0);
    const firstMention = [...viewerMentionReplies].sort((left, right) => left.createdAt - right.createdAt)[0];
    setTimeout(() => {
      const y = firstMention ? replyOffsetsRef.current[firstMention.id] : undefined;
      if (typeof y === "number") {
        scrollViewRef.current?.scrollTo({ animated: true, y: Math.max(0, y - 12) });
      }
    }, 120);
  }

  function filterViewerReplies() {
    if (viewerReplies.length === 0) return;
    setReplySearchText("自分の返信");
    setReplySearchSource({ label: "自分の返信", type: "mine" });
    setSearchCursorIndex(0);
    const firstOwnReply = [...viewerReplies].sort((left, right) => left.createdAt - right.createdAt)[0];
    setTimeout(() => {
      const y = firstOwnReply ? replyOffsetsRef.current[firstOwnReply.id] : undefined;
      if (typeof y === "number") {
        scrollViewRef.current?.scrollTo({ animated: true, y: Math.max(0, y - 12) });
      }
    }, 120);
  }

  function filterMediaReplies() {
    if (mediaReplies.length === 0) return;
    setReplySearchText("画像付き返信");
    setReplySearchSource({ label: "画像付き返信", type: "media" });
    setSearchCursorIndex(0);
    const firstMediaReply = [...mediaReplies].sort((left, right) => left.createdAt - right.createdAt)[0];
    setTimeout(() => {
      const y = firstMediaReply ? replyOffsetsRef.current[firstMediaReply.id] : undefined;
      if (typeof y === "number") {
        scrollViewRef.current?.scrollTo({ animated: true, y: Math.max(0, y - 12) });
      }
    }, 120);
  }

  function filterThreadAuthorReplies() {
    if (!thread || threadAuthorReplies.length === 0) return;
    setReplySearchText("作成者の返信");
    setReplySearchSource({ label: "作成者の返信", type: "author" });
    setSearchCursorIndex(0);
    const firstAuthorReply = [...threadAuthorReplies].sort((left, right) => left.createdAt - right.createdAt)[0];
    setTimeout(() => {
      const y = firstAuthorReply ? replyOffsetsRef.current[firstAuthorReply.id] : undefined;
      if (typeof y === "number") {
        scrollViewRef.current?.scrollTo({ animated: true, y: Math.max(0, y - 12) });
      }
    }, 120);
  }

  function filterChildReplies(parentReply: MeguriBoardReply) {
    const childReplies = replies.filter((reply) => reply.parentReplyId === parentReply.id);
    if (childReplies.length === 0) return;
    const label = "この返信への返信";
    setReplySearchText(label);
    setReplySearchSource({ label, replyId: parentReply.id, type: "children" });
    setSearchCursorIndex(0);
    const firstChildReply = [...childReplies].sort((left, right) => left.createdAt - right.createdAt)[0];
    setTimeout(() => {
      const y = firstChildReply ? replyOffsetsRef.current[firstChildReply.id] : undefined;
      if (typeof y === "number") {
        scrollViewRef.current?.scrollTo({ animated: true, y: Math.max(0, y - 12) });
      }
    }, 120);
  }

  function handleReplySearchChange(text: string) {
    setReplySearchText(text);
    setReplySearchSource(null);
  }

  function clearReplySearch() {
    setReplySearchText("");
    setReplySearchSource(null);
  }

  function rememberReplyOffset(replyId: string, y: number) {
    replyOffsetsRef.current[replyId] = y;
  }

  function isReplyBodyCollapsible(reply: MeguriBoardReply) {
    return !reply.deleted && reply.body.trim().length > REPLY_BODY_COLLAPSE_THRESHOLD;
  }

  function toggleReplyBodyExpanded(replyId: string) {
    setExpandedReplyIds((current) => {
      const next = new Set(current);
      if (next.has(replyId)) {
        next.delete(replyId);
      } else {
        next.add(replyId);
      }
      return next;
    });
  }

  function scrollToReplyOffset(replyId: string) {
    const y = replyOffsetsRef.current[replyId];
    if (typeof y !== "number") return false;
    highlightReply(replyId);
    scrollViewRef.current?.scrollTo({ animated: true, y: Math.max(0, y - 12) });
    return true;
  }

  function scrollToReply(replyId: string | null) {
    if (!replyId) return;
    const runScroll = () => {
      if (!scrollToReplyOffset(replyId)) {
        Alert.alert("引用元を表示できません", "検索条件を解除しても引用元が見つかりませんでした。");
      }
    };
    if (replySearchText.trim()) {
      clearReplySearch();
      setTimeout(runScroll, 140);
      return;
    }
    runScroll();
  }

  function jumpToQuotedReply(parentReplyId: string | null, fromReplyId: string) {
    if (!parentReplyId) return;
    setReplyReturnTargetId(fromReplyId);
    scrollToReply(parentReplyId);
  }

  function returnToQuotedFromReply() {
    if (!replyReturnTargetId) return;
    const targetId = replyReturnTargetId;
    setReplyReturnTargetId(null);
    revealReplyInThreadContext(targetId);
  }

  function revealReplyInThreadContext(replyId: string | null) {
    if (!replyId) return;
    const shouldResetSearch = replySearchText.trim().length > 0;
    const shouldResetSort = replySortMode !== "oldest";
    if (shouldResetSearch) {
      clearReplySearch();
    }
    if (shouldResetSort) {
      setReplySortMode("oldest");
    }
    const delay = shouldResetSearch || shouldResetSort ? 220 : 40;
    setTimeout(() => {
      if (scrollToReplyOffset(replyId)) return;
      setTimeout(() => {
        if (!scrollToReplyOffset(replyId)) {
          Alert.alert("返信を表示できません", "元の流れに戻しても対象の返信が見つかりませんでした。");
        }
      }, 180);
    }, delay);
  }

  function jumpToSearchResult(direction: -1 | 1) {
    if (!replySearchQuery || sortedReplies.length === 0) return;
    const nextIndex =
      (searchCursorIndex + direction + sortedReplies.length) % sortedReplies.length;
    const targetReply = sortedReplies[nextIndex];
    setSearchCursorIndex(nextIndex);
    if (targetReply) {
      scrollToReplyOffset(targetReply.id);
    }
  }

  function jumpToReplyNumber() {
    const replyNumber = Number.parseInt(replyJumpText, 10);
    if (!Number.isFinite(replyNumber) || replyNumber < 1 || replyNumber > replies.length) {
      Alert.alert("返信が見つかりません", `1〜${replies.length}の番号を入力してください。`);
      return;
    }
    const targetReply = replies[replyNumber - 1];
    if (!targetReply) {
      Alert.alert("返信が見つかりません", "指定された番号の返信が見つかりませんでした。");
      return;
    }
    clearReplySearch();
    setReplyJumpText("");
    setTimeout(() => scrollToReply(targetReply.id), 140);
  }

  function jumpToUnreadReply() {
    if (!unreadSeparatorReplyId) return;
    if (replySortMode !== "oldest") {
      setReplySortMode("oldest");
    }
    setTimeout(() => scrollToReply(unreadSeparatorReplyId), replySortMode === "oldest" ? 80 : 180);
  }

  function jumpToNewReplyNotice() {
    if (!newReplyNotice) return;
    const targetId = newReplyNotice.firstReplyId;
    setNewReplyNotice(null);
    if (replySortMode !== "oldest") {
      setReplySortMode("oldest");
    }
    setTimeout(() => scrollToReply(targetId), replySortMode === "oldest" ? 80 : 180);
  }

  function jumpToMediaSource(attachment: BoardMediaAttachment) {
    setMediaGalleryOpen(false);
    if (!attachment.replyId) {
      requestAnimationFrame(() => {
        scrollViewRef.current?.scrollTo({ animated: true, y: 0 });
      });
      return;
    }
    setTimeout(() => scrollToReply(attachment.replyId), 80);
  }

  const refreshDetail = useCallback(async (options: { silent?: boolean } = {}) => {
    if (!threadId) {
      setThread(null);
      setReplies([]);
      setLoading(false);
      setRefreshing(false);
      return;
    }
    if (options.silent) {
      setRefreshing(true);
    } else {
      setLoading(true);
    }
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
    const currentReplies = repliesRef.current;
    if (options.silent && currentReplies.length > 0) {
      const currentReplyIds = new Set(currentReplies.map((reply) => reply.id));
      const newlyLoadedReplies = detail.replies
        .filter((reply) => !reply.deleted && !currentReplyIds.has(reply.id))
        .sort((left, right) => left.createdAt - right.createdAt);
      if (newlyLoadedReplies.length > 0) {
        setNewReplyNotice({
          count: newlyLoadedReplies.length,
          firstReplyId: newlyLoadedReplies[0].id,
        });
      } else if (
        newReplyNoticeRef.current &&
        !detail.replies.some((reply) => reply.id === newReplyNoticeRef.current?.firstReplyId)
      ) {
        setNewReplyNotice(null);
      }
    } else if (!options.silent) {
      setNewReplyNotice(null);
    }
    setPreviousReadAt(detail.thread?.readAt ?? null);
    setThread(detail.thread ? { ...detail.thread, readAt: Date.now() } : null);
    setReplies(detail.replies);
    setLoading(false);
    setRefreshing(false);
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

  const refreshDetailSilently = useCallback(() => {
    void refreshDetail({ silent: true });
  }, [refreshDetail]);

  useFocusEffect(
    useCallback(() => {
      void refreshDetail();
    }, [refreshDetail]),
  );

  useEffect(() => {
    setDraft("");
    setDraftImageUris([]);
    setQuoteTarget(null);
    setReplyDraftReady(false);
    focusReplyThreadIdRef.current = null;
  }, [threadId]);

  useEffect(() => {
    if (!threadId || replyDraftReady) return;
    let alive = true;
    void loadMeguriBoardReplyDraft(threadId)
      .then((savedDraft) => {
        if (!alive) return;
        if (savedDraft) {
          setDraft(savedDraft.body);
          setDraftImageUris(savedDraft.imageUris);
        }
        setReplyDraftReady(true);
      })
      .catch(() => {
        if (alive) setReplyDraftReady(true);
      });
    return () => {
      alive = false;
    };
  }, [replyDraftReady, threadId]);

  useEffect(() => {
    if (!threadId || !replyDraftReady || thread?.status === "locked") return;
    const handle = setTimeout(() => {
      void saveMeguriBoardReplyDraft(threadId, {
        body: draft,
        imageUris: draftImageUris,
      });
    }, 350);
    return () => clearTimeout(handle);
  }, [draft, draftImageUris, replyDraftReady, thread?.status, threadId]);

  useEffect(() => {
    if (!shouldFocusReplyComposer || loading || !thread || !replyDraftReady || thread.status === "locked") return;
    if (focusReplyThreadIdRef.current === thread.id) return;
    focusReplyThreadIdRef.current = thread.id;
    const handle = setTimeout(() => {
      focusReplyComposer();
    }, 220);
    return () => clearTimeout(handle);
  }, [loading, replyDraftReady, shouldFocusReplyComposer, thread]);

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
    await clearMeguriBoardReplyDraft(threadId);
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
    setPreviousReadAt(Date.now());
    setNewReplyNotice(null);
    setTimeout(() => scrollToLatestReply(), 80);
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

  async function discardReplyDraft() {
    if (!threadId) return;
    setDraft("");
    setDraftImageUris([]);
    setQuoteTarget(null);
    setSendError(null);
    await clearMeguriBoardReplyDraft(threadId);
  }

  function updateThread(nextThread: MeguriBoardThread) {
    setThread(nextThread);
  }

  async function hideThread() {
    if (!thread) return;
    await hideMeguriBoardThread(thread.id);
    router.back();
  }

  async function reportThread(reason: MeguriBoardReportReason) {
    if (!thread || thread.reported) return;
    updateThread({ ...thread, reported: true });
    await reportMeguriBoardThread(thread.id, reason);
    Alert.alert("通報しました", "確認して対応します。");
  }

  function openThreadReportReasonPicker() {
    if (!thread || thread.reported) return;
    if (Platform.OS !== "ios") {
      void reportThread("other");
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
        void reportThread(reason);
      },
    );
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

  async function reportReply(reply: MeguriBoardReply, reason: MeguriBoardReportReason) {
    if (reply.reported) return;
    setReplies((current) =>
      current.map((candidate) =>
        candidate.id === reply.id ? { ...candidate, reported: true } : candidate,
      ),
    );
    await reportMeguriBoardReply(reply.id, reason);
    Alert.alert("通報しました", "確認して対応します。");
  }

  function openReplyReportReasonPicker(reply: MeguriBoardReply) {
    if (reply.reported || reply.deleted) return;
    if (Platform.OS !== "ios") {
      void reportReply(reply, "other");
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
        void reportReply(reply, reason);
      },
    );
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
              bookmarked: false,
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

  function mentionReplyAuthor(reply: MeguriBoardReply) {
    if (reply.deleted || reply.mine || thread?.status === "locked") return;
    const mention = reply.authorHandle ? `@${reply.authorHandle}` : `@${reply.authorName.replace(/\s+/g, "")}`;
    setDraft((current) => {
      const trimmed = current.trimStart();
      if (trimmed.startsWith(`${mention} `) || trimmed === mention) return current;
      return current ? `${mention} ${current}` : `${mention} `;
    });
    setQuoteTarget(null);
    setSendError(null);
  }

  function insertMentionSuggestion(participant: BoardParticipant) {
    const mention = participant.handle ? `@${participant.handle}` : `@${participant.name.replace(/\s+/g, "")}`;
    setDraft((current) => {
      if (extractDraftMentionQuery(current) === null) return current ? `${current.trimEnd()} ${mention} ` : `${mention} `;
      return current.replace(/(^|\s)@([^\s@]{0,24})$/, `$1${mention} `);
    });
    setQuoteTarget(null);
    setSendError(null);
    requestAnimationFrame(() => composerInputRef.current?.focus());
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

  async function shareReply(reply: MeguriBoardReply) {
    if (!thread || reply.deleted) return;
    const url = buildThreadShareUrl(thread, viewerContext, viewMode, reply.id);
    await Share.share({
      message: `${thread.title}\n${reply.authorName}: ${reply.body}\n${url}`,
      title: thread.title,
      url,
    });
  }

  function showReplyTimestamp(reply: MeguriBoardReply) {
    const rows = [`投稿: ${formatFullDateTime(reply.createdAt)}`];
    if (reply.updatedAt && reply.updatedAt > reply.createdAt + 60000) {
      rows.push(`編集: ${formatFullDateTime(reply.updatedAt)}`);
    }
    Alert.alert("返信の日時", rows.join("\n"));
  }

  function showThreadTimestamp() {
    if (!thread) return;
    const rows = [`作成: ${formatFullDateTime(thread.createdAt)}`];
    if (thread.updatedAt && thread.updatedAt > thread.createdAt + 60000) {
      rows.push(`更新: ${formatFullDateTime(thread.updatedAt)}`);
    }
    Alert.alert("スレッドの日時", rows.join("\n"));
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

  function openThreadActions() {
    if (!thread) return;
    setThreadActionMenuOpen(true);
  }

  function openReplyActions(reply: MeguriBoardReply) {
    setReplyActionMenuReply(reply);
  }

  function runReplyContextAction(reply: MeguriBoardReply, action: (target: MeguriBoardReply) => void) {
    setReplyActionMenuReply(null);
    requestAnimationFrame(() => action(reply));
  }

  function runThreadContextAction(action: () => void) {
    setThreadActionMenuOpen(false);
    requestAnimationFrame(action);
  }

  const threadContextActions: BoardContextAction[] = thread
    ? [
        ...(thread.status === "locked"
          ? []
          : [
              {
                icon: "create-outline" as const,
                key: "reply",
                label: "リプライ",
                onPress: () => runThreadContextAction(focusReplyComposer),
              },
            ]),
        {
          icon: "send-outline",
          key: "share",
          label: "転送",
          onPress: () => runThreadContextAction(() => void shareThread()),
        },
        ...(thread.mine
          ? [
              {
                icon: "document-text-outline" as const,
                key: "edit",
                label: "編集",
                onPress: () => runThreadContextAction(openThreadEditor),
              },
              {
                destructive: true,
                icon: "close-circle-outline" as const,
                key: "delete",
                label: "削除",
                onPress: () => runThreadContextAction(confirmArchiveThread),
              },
            ]
          : [
              {
                disabled: thread.reported,
                icon: "warning-outline" as const,
                key: "report",
                label: thread.reported ? "通報済み" : "通報",
                onPress: () => runThreadContextAction(openThreadReportReasonPicker),
              },
              {
                destructive: true,
                icon: "ban-outline" as const,
                key: "block",
                label: "ブロック",
                onPress: () => runThreadContextAction(confirmBlockThreadAuthor),
              },
            ]),
      ]
    : [];

  const replyContextActions: BoardContextAction[] = replyActionMenuReply
    ? [
        {
          disabled: replyActionMenuReply.deleted || thread?.status === "locked",
          icon: "create-outline",
          key: "reply",
          label: "リプライ",
          onPress: () => runReplyContextAction(replyActionMenuReply, quoteReply),
        },
        {
          disabled: replyActionMenuReply.deleted,
          icon: "send-outline",
          key: "share",
          label: "転送",
          onPress: () => runReplyContextAction(replyActionMenuReply, (reply) => void shareReply(reply)),
        },
        {
          disabled: replyActionMenuReply.deleted,
          icon: "document-text-outline",
          key: "profile",
          label: "プロフィール",
          onPress: () => runReplyContextAction(replyActionMenuReply, (reply) => openBoardUserProfile(reply.authorId)),
        },
        ...(replyActionMenuReply.mine
          ? [
              {
                disabled: replyActionMenuReply.deleted,
                icon: "document-text-outline" as const,
                key: "edit",
                label: "編集",
                onPress: () => runReplyContextAction(replyActionMenuReply, openReplyEditor),
              },
              {
                destructive: true,
                disabled: replyActionMenuReply.deleted,
                icon: "close-circle-outline" as const,
                key: "delete",
                label: "削除",
                onPress: () => runReplyContextAction(replyActionMenuReply, confirmDeleteReply),
              },
            ]
          : [
              {
                disabled: replyActionMenuReply.reported || replyActionMenuReply.deleted,
                icon: "warning-outline" as const,
                key: "report",
                label: replyActionMenuReply.reported ? "通報済み" : "通報",
                onPress: () => runReplyContextAction(replyActionMenuReply, openReplyReportReasonPicker),
              },
              {
                destructive: true,
                disabled: replyActionMenuReply.deleted,
                icon: "ban-outline" as const,
                key: "block",
                label: "ブロック",
                onPress: () => runReplyContextAction(replyActionMenuReply, confirmBlockReplyAuthor),
              },
            ]),
      ]
    : [];

  return (
    <View style={styles.root}>
      <Screen bottomInset={false} contentStyle={styles.screen} scroll={false} topInset={false}>
        <View style={[styles.header, { paddingTop: Math.max(insets.top, 10) + 8 }]}>
          <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.backButton}>
            <IconSymbol name="chevron-back" color={megrumColors.ink} size={20} />
          </Pressable>
          <View style={styles.headerCopy}>
            <Text numberOfLines={1} style={styles.headerTitle}>
              掲示板
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
              ref={scrollViewRef}
              contentContainerStyle={[
                styles.content,
                {
                  paddingBottom: Math.max(insets.bottom, 12) + 112,
                },
              ]}
              refreshControl={
                <RefreshControl
                  refreshing={refreshing}
                  tintColor={megrumColors.lavender}
                  onRefresh={refreshDetailSilently}
                />
              }
              showsVerticalScrollIndicator={false}
              style={styles.scroll}
            >
              <View style={styles.replyGroup}>
                <Pressable
                  accessibilityRole="button"
                  onLongPress={openThreadActions}
                  style={[styles.replyRow, thread.mine ? styles.replyRowMine : null]}
                >
                  {!thread.mine ? (
                    <Pressable
                      accessibilityRole="button"
                      hitSlop={8}
                      onPress={() => openBoardUserProfile(thread.authorId)}
                      style={[styles.replyAvatar, { backgroundColor: colorForAuthor(thread.authorId) }]}
                    >
                      <Text style={styles.replyAvatarText}>{thread.authorName.slice(0, 1)}</Text>
                    </Pressable>
                  ) : null}
                  <View style={thread.mine ? styles.replyContentMine : styles.replyContent}>
                    {!thread.mine ? (
                      <View style={styles.replyMetaRow}>
                        <Pressable
                          accessibilityRole="button"
                          hitSlop={8}
                          onPress={() => openBoardUserProfile(thread.authorId)}
                          style={styles.replyAuthorButton}
                        >
                          <Text numberOfLines={1} style={styles.replyAuthor}>{thread.authorName}</Text>
                        </Pressable>
                      </View>
                    ) : null}
                    <ChatGradientBubble
                      mine={thread.mine}
                      style={[
                        styles.replyBubble,
                        thread.mine ? styles.replyBubbleMine : styles.replyBubbleTheirs,
                      ]}
                    >
                      <HighlightedText
                        linkify
                        numberOfLines={threadBodyCollapsible && !threadBodyExpanded ? 5 : undefined}
                        query=""
                        style={[styles.replyBody, thread.mine ? styles.replyBodyMine : null]}
                        text={thread.body}
                      />
                      {threadBodyCollapsible ? (
                        <Pressable
                          accessibilityRole="button"
                          onPress={() => setThreadBodyExpanded((current) => !current)}
                          style={[
                            styles.replyReadMoreButton,
                            thread.mine ? styles.replyReadMoreButtonMine : null,
                          ]}
                        >
                          <Text
                            style={[
                              styles.replyReadMoreText,
                              thread.mine ? styles.replyReadMoreTextMine : null,
                            ]}
                          >
                            {threadBodyExpanded ? "閉じる" : "続きを読む"}
                          </Text>
                        </Pressable>
                      ) : null}
                      <AttachmentGrid compact imageUris={thread.imageUris} onPressImage={setImagePreviewUri} />
                    </ChatGradientBubble>
                    <Pressable
                      accessibilityRole="button"
                      hitSlop={8}
                      onPress={showThreadTimestamp}
                      style={styles.replyTimeButton}
                    >
                      <Text style={styles.replyTime}>
                        {formatRelativeTime(thread.createdAt)}
                        {thread.updatedAt && thread.updatedAt > thread.createdAt + 60000 ? " · 編集済み" : ""}
                      </Text>
                    </Pressable>
                  </View>
                </Pressable>
              </View>
              {replies.length === 0 ? (
                <View style={styles.noRepliesCard}>
                  <Text style={styles.noRepliesTitle}>まだ返信はありません</Text>
                  <Text style={styles.noRepliesBody}>最初のひとことで現地の様子を共有できます。</Text>
                </View>
              ) : sortedReplies.length === 0 ? (
                <View style={styles.noRepliesCard}>
                  <Text style={styles.noRepliesTitle}>検索結果がありません</Text>
                  <Text style={styles.noRepliesBody}>別の言葉で探してみてください。</Text>
                </View>
              ) : (
                sortedReplies.map((reply) => {
                  const replyByThreadAuthor = reply.authorId === thread.authorId;
                  const quoteAuthorLabel = reply.quotedAuthorName || "引用";
                  const mentionsViewer = !reply.mine && replyMentionsHandle(reply.body, actor.handle);
                  const replyBodyCollapsible = isReplyBodyCollapsible(reply) && !replySearchQuery;
                  const replyBodyExpanded = expandedReplyIds.has(reply.id);
                  return (
                    <View
                      key={reply.id}
                      onLayout={(event) => rememberReplyOffset(reply.id, event.nativeEvent.layout.y)}
                      style={styles.replyGroup}
                    >
                      {replySortMode === "oldest" && reply.id === unreadSeparatorReplyId ? (
                        <View style={styles.unreadSeparator}>
                          <View style={styles.unreadSeparatorLine} />
                          <Text style={styles.unreadSeparatorText}>ここから未読</Text>
                          <View style={styles.unreadSeparatorLine} />
                        </View>
                      ) : null}
                      <Pressable
                        accessibilityRole="button"
                        onLongPress={() => openReplyActions(reply)}
                        style={[styles.replyRow, reply.mine ? styles.replyRowMine : null]}
                      >
                        {!reply.mine ? (
                          <Pressable
                            accessibilityRole="button"
                            hitSlop={8}
                            onPress={() => openBoardUserProfile(reply.authorId)}
                            style={[styles.replyAvatar, { backgroundColor: colorForAuthor(reply.authorId) }]}
                          >
                            <Text style={styles.replyAvatarText}>{reply.authorName.slice(0, 1)}</Text>
                          </Pressable>
                        ) : null}
                        <View style={reply.mine ? styles.replyContentMine : styles.replyContent}>
                          <View style={reply.mine ? styles.replyMetaRowMine : styles.replyMetaRow}>
                            {!reply.mine ? (
                              <Pressable
                                accessibilityRole="button"
                                hitSlop={8}
                                onPress={() => openBoardUserProfile(reply.authorId)}
                                style={styles.replyAuthorButton}
                              >
                                <HighlightedText
                                  numberOfLines={1}
                                  query={replySearchQuery}
                                  style={styles.replyAuthor}
                                  text={reply.authorName}
                                />
                              </Pressable>
                            ) : null}
                            {replyByThreadAuthor ? (
                              <View style={styles.replyAuthorBadge}>
                                <Text style={styles.replyAuthorBadgeText}>作成者</Text>
                              </View>
                            ) : null}
                            {mentionsViewer ? (
                              <View style={styles.replyMentionBadge}>
                                <Text style={styles.replyMentionBadgeText}>あなた宛て</Text>
                              </View>
                            ) : null}
                            {reply.reported ? (
                              <View style={styles.replyReportedBadge}>
                                <Text style={styles.replyReportedBadgeText}>通報済み</Text>
                              </View>
                            ) : null}
                          </View>
                          <ChatGradientBubble
                            mine={reply.mine}
                            style={[
                              styles.replyBubble,
                              reply.mine ? styles.replyBubbleMine : styles.replyBubbleTheirs,
                              mentionsViewer ? styles.replyBubbleMention : null,
                              highlightedReplyId === reply.id ? styles.replyBubbleHighlighted : null,
                            ]}
                          >
                            {reply.quotedBody ? (
                              <Pressable
                                accessibilityRole="button"
                                disabled={!reply.parentReplyId}
                                onPress={() => jumpToQuotedReply(reply.parentReplyId, reply.id)}
                                style={[styles.quotePreview, reply.mine ? styles.quotePreviewMine : null]}
                              >
                                <HighlightedText
                                  numberOfLines={1}
                                  query={replySearchQuery}
                                  style={[styles.quoteAuthor, reply.mine ? styles.quoteAuthorMine : null]}
                                  text={quoteAuthorLabel}
                                />
                                <HighlightedText
                                  highlightStyle={reply.mine ? styles.searchHighlightMine : null}
                                  numberOfLines={2}
                                  query={replySearchQuery}
                                  style={[styles.quoteBody, reply.mine ? styles.quoteBodyMine : null]}
                                  text={reply.quotedBody}
                                />
                              </Pressable>
                            ) : null}
                            <HighlightedText
                              linkify
                              highlightStyle={reply.mine ? styles.searchHighlightMine : null}
                              numberOfLines={
                                replyBodyCollapsible && !replyBodyExpanded ? REPLY_BODY_COLLAPSED_LINES : undefined
                              }
                              query={replySearchQuery}
                              style={[
                                styles.replyBody,
                                reply.mine ? styles.replyBodyMine : null,
                                reply.deleted ? styles.replyBodyDeleted : null,
                              ]}
                              text={reply.body}
                            />
                            {replyBodyCollapsible ? (
                              <Pressable
                                accessibilityRole="button"
                                onPress={() => toggleReplyBodyExpanded(reply.id)}
                                style={[
                                  styles.replyReadMoreButton,
                                  reply.mine ? styles.replyReadMoreButtonMine : null,
                                ]}
                              >
                                <Text
                                  style={[
                                    styles.replyReadMoreText,
                                    reply.mine ? styles.replyReadMoreTextMine : null,
                                  ]}
                                >
                                  {replyBodyExpanded ? "閉じる" : "続きを読む"}
                                </Text>
                              </Pressable>
                            ) : null}
                            {!reply.deleted ? (
                              <AttachmentGrid
                                compact
                                imageUris={reply.imageUris}
                                onPressImage={setImagePreviewUri}
                              />
                            ) : null}
                          </ChatGradientBubble>
                          <Pressable
                            accessibilityRole="button"
                            hitSlop={8}
                            onPress={() => showReplyTimestamp(reply)}
                            style={styles.replyTimeButton}
                          >
                            <Text style={styles.replyTime}>
                              {formatRelativeTime(reply.createdAt)}
                              {reply.updatedAt && reply.updatedAt > reply.createdAt + 60000 ? " · 編集済み" : ""}
                            </Text>
                          </Pressable>
                        </View>
                      </Pressable>
                    </View>
                  );
                })
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
                    <Pressable
                      accessibilityRole="button"
                      onPress={() => revealReplyInThreadContext(quoteTarget.id)}
                      style={styles.composerQuoteCopy}
                    >
                      <Text numberOfLines={1} style={styles.composerQuoteAuthor}>
                        {`${quoteTarget.authorName}へ返信`}
                      </Text>
                      <Text numberOfLines={1} style={styles.composerQuoteBody}>
                        {quoteTarget.body}
                      </Text>
                    </Pressable>
                    <Pressable accessibilityRole="button" hitSlop={8} onPress={() => setQuoteTarget(null)}>
                      <IconSymbol name="close" color="rgba(58,50,74,0.52)" size={15} />
                    </Pressable>
                  </View>
                ) : null}
                {hasReplyDraft ? (
                  <View style={styles.composerDraftStatus}>
                    <Text style={styles.composerDraftText}>
                      下書き保存中{draftImageUris.length > 0 ? ` · 画像${draftImageUris.length}枚` : ""}
                    </Text>
                    <Pressable
                      accessibilityRole="button"
                      onPress={discardReplyDraft}
                      style={styles.composerDraftDiscard}
                    >
                      <Text style={styles.composerDraftDiscardText}>破棄</Text>
                    </Pressable>
                  </View>
                ) : null}
                {mentionSuggestions.length > 0 ? (
                  <View style={styles.mentionSuggestionBox}>
                    <Text style={styles.mentionSuggestionTitle}>メンション候補</Text>
                    <ScrollView
                      horizontal
                      keyboardShouldPersistTaps="handled"
                      showsHorizontalScrollIndicator={false}
                    >
                      <View style={styles.mentionSuggestionRail}>
                        {mentionSuggestions.map((participant) => (
                          <Pressable
                            accessibilityRole="button"
                            key={participant.id}
                            onPress={() => insertMentionSuggestion(participant)}
                            style={styles.mentionSuggestionChip}
                          >
                            <Text numberOfLines={1} style={styles.mentionSuggestionHandle}>
                              {participant.handle ? `@${participant.handle}` : `@${participant.name.replace(/\s+/g, "")}`}
                            </Text>
                            <Text numberOfLines={1} style={styles.mentionSuggestionName}>
                              {participant.name}
                            </Text>
                          </Pressable>
                        ))}
                      </View>
                    </ScrollView>
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
                    ref={composerInputRef}
                    maxLength={REPLY_BODY_LIMIT}
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
                    disabled={sending || !hasReplyDraft}
                    onPress={handleSend}
                    style={[
                      styles.sendButton,
                      hasReplyDraft ? styles.sendButtonActive : null,
                      sending ? styles.sendButtonDisabled : null,
                    ]}
                  >
                    <IconSymbol
                      name={sending ? "ellipsis-horizontal" : "send-outline"}
                      color={hasReplyDraft ? "#fff" : "rgba(58,50,74,0.42)"}
                      size={18}
                    />
                  </Pressable>
                </View>
                <Text style={styles.composerInputCounter}>
                  {draft.length}/{REPLY_BODY_LIMIT}
                </Text>
                {draftImageUris.length > 0 ? (
                  <PickedImageRail imageUris={draftImageUris} onRemove={removeDraftImage} />
                ) : null}
              </View>
            )}
            {sendError ? <Text style={styles.sendError}>{sendError}</Text> : null}
            <BoardContextMenuModal
              actions={threadContextActions}
              onClose={() => setThreadActionMenuOpen(false)}
              visible={threadActionMenuOpen}
            />
            <BoardContextMenuModal
              actions={replyContextActions}
              onClose={() => setReplyActionMenuReply(null)}
              visible={!!replyActionMenuReply}
            />
          </>
        )}
        <Modal
          animationType="slide"
          onRequestClose={closeParticipants}
          transparent
          visible={participantsOpen}
        >
          <View style={styles.modalOverlay}>
            <Pressable
              accessibilityRole="button"
              onPress={closeParticipants}
              style={StyleSheet.absoluteFill}
            />
            <View style={[styles.editorCard, styles.participantsCard]}>
              <View style={styles.participantsHeader}>
                <View style={styles.participantsTitleBlock}>
                  <Text style={styles.editorEyebrow}>THREAD</Text>
                  <Text style={styles.editorTitle}>参加者</Text>
                  <Text style={styles.participantsLead}>
                    {participantSearchQuery
                      ? `${sortedParticipants.length}/${participants.length}人が該当しています`
                      : `${participants.length}人がこのスレッドに参加しています`}
                  </Text>
                  <Text style={styles.participantsHint}>
                    返信している人をタップすると、その人の返信だけを表示します
                  </Text>
                </View>
                <Pressable
                  accessibilityRole="button"
                  onPress={closeParticipants}
                  style={styles.participantsCloseButton}
                >
                  <IconSymbol name="close" color={megrumColors.mutedInk} size={16} />
                </Pressable>
              </View>
              <View style={styles.participantsSearchBox}>
                <IconSymbol name="search" color="rgba(58,50,74,0.42)" size={15} />
                <TextInput
                  onChangeText={setParticipantSearchText}
                  placeholder="名前・@ID・エリアで検索"
                  placeholderTextColor="rgba(58,50,74,0.34)"
                  style={styles.participantsSearchInput}
                  value={participantSearchText}
                />
                {participantSearchText.trim() ? (
                  <Pressable
                    accessibilityRole="button"
                    hitSlop={8}
                    onPress={() => setParticipantSearchText("")}
                  >
                    <IconSymbol name="close" color="rgba(58,50,74,0.42)" size={15} />
                  </Pressable>
                ) : null}
              </View>
              <View style={styles.participantsSortSegment}>
                {PARTICIPANT_SORT_OPTIONS.map((option) => {
                  const active = participantSortMode === option.value;
                  return (
                    <Pressable
                      accessibilityRole="button"
                      key={option.value}
                      onPress={() => setParticipantSortMode(option.value)}
                      style={[styles.participantsSortOption, active ? styles.participantsSortOptionActive : null]}
                    >
                      <Text
                        style={[
                          styles.participantsSortOptionText,
                          active ? styles.participantsSortOptionTextActive : null,
                        ]}
                      >
                        {option.label}
                      </Text>
                    </Pressable>
                  );
                })}
              </View>
              <ScrollView
                contentContainerStyle={styles.participantsList}
                showsVerticalScrollIndicator={false}
              >
                {sortedParticipants.length === 0 ? (
                  <View style={styles.participantsEmptyCard}>
                    <Text style={styles.participantsEmptyTitle}>該当する参加者がいません</Text>
                    <Text style={styles.participantsEmptyBody}>名前、@ID、エリアを変えて探してみてください。</Text>
                  </View>
                ) : null}
                {sortedParticipants.map((participant) => (
                  <Pressable
                    accessibilityRole="button"
                    disabled={participant.replyCount === 0}
                    key={participant.id}
                    onPress={() => filterRepliesByParticipant(participant)}
                    style={[
                      styles.participantRow,
                      participant.replyCount === 0 ? styles.participantRowDisabled : null,
                    ]}
                  >
                    <View
                      style={[
                        styles.participantAvatar,
                        { backgroundColor: colorForAuthor(participant.id) },
                      ]}
                    >
                      <Text style={styles.participantAvatarText}>{participant.name.slice(0, 1)}</Text>
                    </View>
                    <View style={styles.participantCopy}>
                      <View style={styles.participantNameRow}>
                        <Text numberOfLines={1} style={styles.participantName}>
                          {participant.name}
                        </Text>
                        {participant.mine ? (
                          <View style={styles.participantMiniBadge}>
                            <Text style={styles.participantMiniBadgeText}>あなた</Text>
                          </View>
                        ) : null}
                        {participant.isAuthor ? (
                          <View style={styles.participantMiniBadge}>
                            <Text style={styles.participantMiniBadgeText}>作成者</Text>
                          </View>
                        ) : null}
                      </View>
                      <Text numberOfLines={1} style={styles.participantMeta}>
                        {participantSummary(participant)}
                      </Text>
                    </View>
                    <View style={styles.participantTail}>
                      <Text style={styles.participantActiveAt}>
                        {formatRelativeTime(participant.lastActiveAt)}
                      </Text>
                      <View style={styles.participantTailActions}>
                        <Text
                          style={[
                            styles.participantFilterHint,
                            participant.replyCount === 0 ? styles.participantFilterHintDisabled : null,
                          ]}
                        >
                          {participant.replyCount > 0 ? "返信を見る" : "返信なし"}
                        </Text>
                        <Pressable
                          accessibilityRole="button"
                          hitSlop={8}
                          onPress={(event) => {
                            event.stopPropagation();
                            closeParticipants();
                            openBoardUserProfile(participant.id);
                          }}
                          style={styles.participantProfileButton}
                        >
                          <Text style={styles.participantProfileText}>プロフィール</Text>
                        </Pressable>
                      </View>
                    </View>
                  </Pressable>
                ))}
              </ScrollView>
            </View>
          </View>
        </Modal>
        <Modal
          animationType="slide"
          onRequestClose={() => setMediaGalleryOpen(false)}
          transparent
          visible={mediaGalleryOpen}
        >
          <View style={styles.modalOverlay}>
            <Pressable
              accessibilityRole="button"
              onPress={() => setMediaGalleryOpen(false)}
              style={StyleSheet.absoluteFill}
            />
            <View style={[styles.editorCard, styles.mediaGalleryCard]}>
              <View style={styles.participantsHeader}>
                <View style={styles.participantsTitleBlock}>
                  <Text style={styles.editorEyebrow}>MEDIA</Text>
                  <Text style={styles.editorTitle}>画像一覧</Text>
                  <Text style={styles.participantsLead}>
                    このスレッド内の画像 {mediaAttachments.length}枚
                  </Text>
                </View>
                <Pressable
                  accessibilityRole="button"
                  onPress={() => setMediaGalleryOpen(false)}
                  style={styles.participantsCloseButton}
                >
                  <IconSymbol name="close" color={megrumColors.mutedInk} size={16} />
                </Pressable>
              </View>
              <ScrollView
                contentContainerStyle={styles.mediaGalleryGrid}
                showsVerticalScrollIndicator={false}
              >
                {mediaAttachments.map((attachment) => (
                  <View key={attachment.id} style={styles.mediaGalleryItem}>
                    <Pressable
                      accessibilityRole="imagebutton"
                      onPress={() => setImagePreviewUri(attachment.uri)}
                      style={styles.mediaGalleryThumb}
                    >
                      <Image source={{ uri: attachment.uri }} style={styles.mediaGalleryImage} />
                    </Pressable>
                    <View style={styles.mediaGalleryCopy}>
                      <Text numberOfLines={1} style={styles.mediaGallerySource}>
                        {attachment.source === "thread" ? "スレッド本文" : attachment.authorName}
                      </Text>
                      <Text numberOfLines={2} style={styles.mediaGalleryBody}>
                        {attachment.body}
                      </Text>
                      <View style={styles.mediaGalleryFooter}>
                        <Text style={styles.mediaGalleryTime}>
                          {formatRelativeTime(attachment.createdAt)}
                        </Text>
                        <Pressable
                          accessibilityRole="button"
                          onPress={() => jumpToMediaSource(attachment)}
                          style={styles.mediaGalleryJumpButton}
                        >
                          <Text style={styles.mediaGalleryJumpText}>
                            {attachment.source === "thread" ? "本文へ" : "返信へ"}
                          </Text>
                        </Pressable>
                      </View>
                    </View>
                  </View>
                ))}
              </ScrollView>
            </View>
          </View>
        </Modal>
        <Modal
          animationType="slide"
          onRequestClose={() => setThreadInfoOpen(false)}
          transparent
          visible={threadInfoOpen}
        >
          <View style={styles.modalOverlay}>
            <Pressable
              accessibilityRole="button"
              onPress={() => setThreadInfoOpen(false)}
              style={StyleSheet.absoluteFill}
            />
            <View style={[styles.editorCard, styles.threadInfoCard]}>
              <View style={styles.participantsHeader}>
                <View style={styles.participantsTitleBlock}>
                  <Text style={styles.editorEyebrow}>THREAD</Text>
                  <Text style={styles.editorTitle}>スレッド情報</Text>
                  <Text style={styles.participantsLead}>
                    表示範囲、参加状況、更新状況をまとめて確認できます
                  </Text>
                </View>
                <Pressable
                  accessibilityRole="button"
                  onPress={() => setThreadInfoOpen(false)}
                  style={styles.participantsCloseButton}
                >
                  <IconSymbol name="close" color={megrumColors.mutedInk} size={16} />
                </Pressable>
              </View>
              <View style={styles.threadInfoList}>
                {threadInfoRows.map((row) => (
                  <View key={row.label} style={styles.threadInfoRow}>
                    <Text style={styles.threadInfoLabel}>{row.label}</Text>
                    <Text numberOfLines={2} style={styles.threadInfoValue}>
                      {row.value}
                    </Text>
                  </View>
                ))}
              </View>
            </View>
          </View>
        </Modal>
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
        <Modal
          animationType="fade"
          onRequestClose={() => setImagePreviewUri(null)}
          transparent
          visible={!!imagePreviewUri}
        >
          <View style={styles.imagePreviewLayer}>
            <Pressable
              accessibilityRole="button"
              onPress={() => setImagePreviewUri(null)}
              style={StyleSheet.absoluteFill}
            />
            {imagePreviewUri ? (
              <Image
                resizeMode="contain"
                source={{ uri: imagePreviewUri }}
                style={styles.imagePreview}
              />
            ) : null}
            <Pressable
              accessibilityRole="button"
              onPress={() => setImagePreviewUri(null)}
              style={[styles.imagePreviewClose, { top: Math.max(insets.top, 10) + 10 }]}
            >
              <IconSymbol name="close" color="#fff" size={18} />
            </Pressable>
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

function AttachmentGrid({
  compact,
  imageUris,
  onPressImage,
}: {
  compact?: boolean;
  imageUris: string[];
  onPressImage?: (uri: string) => void;
}) {
  if (imageUris.length === 0) return null;
  return (
    <View style={compact ? styles.attachmentGridCompact : styles.attachmentGrid}>
      {imageUris.slice(0, 4).map((uri, index) => (
        <Pressable
          key={`${uri}-${index}`}
          accessibilityRole="button"
          disabled={!onPressImage}
          onPress={() => onPressImage?.(uri)}
          style={compact ? styles.attachmentThumbCompact : styles.attachmentThumb}
        >
          <Image source={{ uri }} style={styles.attachmentImage} />
        </Pressable>
      ))}
    </View>
  );
}

function BoardContextMenuModal({
  actions,
  onClose,
  visible,
}: {
  actions: BoardContextAction[];
  onClose: () => void;
  visible: boolean;
}) {
  return (
    <Modal animationType="fade" onRequestClose={onClose} transparent visible={visible}>
      <Pressable accessibilityRole="button" onPress={onClose} style={styles.contextMenuOverlay}>
        <View style={styles.contextMenuWrap}>
          <View style={styles.contextMenuBubble}>
            {actions.map((action) => (
              <Pressable
                accessibilityRole="button"
                disabled={action.disabled}
                key={action.key}
                onPress={action.onPress}
                style={[
                  styles.contextMenuItem,
                  action.disabled ? styles.contextMenuItemDisabled : null,
                ]}
              >
                <IconSymbol
                  name={action.icon}
                  color={action.destructive ? "#ff8f8f" : "#fff"}
                  size={24}
                />
                <Text
                  adjustsFontSizeToFit
                  minimumFontScale={0.82}
                  numberOfLines={1}
                  style={[
                    styles.contextMenuText,
                    action.destructive ? styles.contextMenuTextDestructive : null,
                  ]}
                >
                  {action.label}
                </Text>
              </Pressable>
            ))}
          </View>
          <View style={styles.contextMenuPointer} />
        </View>
      </Pressable>
    </Modal>
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

function HighlightedText({
  highlightStyle,
  linkify = false,
  numberOfLines,
  query,
  style,
  text,
}: {
  highlightStyle?: StyleProp<TextStyle>;
  linkify?: boolean;
  numberOfLines?: number;
  query: string;
  style: StyleProp<TextStyle>;
  text: string;
}) {
  if (linkify) {
    const linkSegments = splitInlineUrlSegments(text);
    if (linkSegments.some((segment) => segment.url)) {
      return (
        <Text numberOfLines={numberOfLines} style={style}>
          {linkSegments.map((segment, index) =>
            segment.url ? (
              <Text
                key={`${segment.text}-${index}`}
                onPress={() => openInlineUrl(segment.url ?? segment.text)}
                style={styles.inlineLinkText}
              >
                {renderHighlightedTextSegments(segment.text, query, highlightStyle)}
              </Text>
            ) : (
              <Text key={`${segment.text}-${index}`}>
                {renderHighlightedTextSegments(segment.text, query, highlightStyle)}
              </Text>
            ),
          )}
        </Text>
      );
    }
  }
  const segments = splitHighlightSegments(text, query);
  if (!query || segments.length === 1 && !segments[0]?.match) {
    return (
      <Text numberOfLines={numberOfLines} style={style}>
        {text}
      </Text>
    );
  }
  return (
    <Text numberOfLines={numberOfLines} style={style}>
      {segments.map((segment, index) => (
        <Text
          key={`${segment.text}-${index}`}
          style={segment.match ? [styles.searchHighlight, highlightStyle] : null}
        >
          {segment.text}
        </Text>
      ))}
    </Text>
  );
}

function renderHighlightedTextSegments(text: string, query: string, highlightStyle?: StyleProp<TextStyle>) {
  const segments = splitHighlightSegments(text, query);
  if (!query || segments.length === 1 && !segments[0]?.match) {
    return text;
  }
  return segments.map((segment, index) => (
    <Text
      key={`${segment.text}-${index}`}
      style={segment.match ? [styles.searchHighlight, highlightStyle] : null}
    >
      {segment.text}
    </Text>
  ));
}

function splitInlineUrlSegments(text: string) {
  const segments: Array<{ text: string; url?: string }> = [];
  INLINE_URL_PATTERN.lastIndex = 0;
  let cursor = 0;
  let match: RegExpExecArray | null;
  while ((match = INLINE_URL_PATTERN.exec(text)) !== null) {
    const matchedText = match[0] ?? "";
    if (!matchedText) continue;
    if (match.index > cursor) {
      segments.push({ text: text.slice(cursor, match.index) });
    }
    const trimmedUrl = matchedText.replace(URL_TRAILING_PUNCTUATION_PATTERN, "");
    const trailingText = matchedText.slice(trimmedUrl.length);
    if (trimmedUrl) {
      segments.push({ text: trimmedUrl, url: trimmedUrl });
    }
    if (trailingText) {
      segments.push({ text: trailingText });
    }
    cursor = match.index + matchedText.length;
  }
  if (cursor < text.length) {
    segments.push({ text: text.slice(cursor) });
  }
  return segments.length > 0 ? segments : [{ text }];
}

function openInlineUrl(url: string) {
  Linking.openURL(url).catch(() => {
    Alert.alert("リンクを開けません", "URLを確認して、もう一度お試しください。");
  });
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

function replyMentionsHandle(body: string, handle: string | null) {
  const normalizedHandle = handle?.trim().replace(/^@/, "").toLowerCase();
  if (!normalizedHandle) return false;
  const mentions = body.toLowerCase().match(/@[a-z0-9._-]+/g) ?? [];
  return mentions.some((mention) => mention.slice(1) === normalizedHandle);
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
  replyId?: string,
) {
  const params = new URLSearchParams({
    id: thread.id,
    prefecture: viewer.prefecture ?? "",
    spotKey: viewer.spotKey ?? "",
    spotLabel: viewer.spotLabel ?? "",
    viewMode,
  });
  if (replyId) {
    params.set("replyId", replyId);
  }
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

function formatAbsoluteDateTime(value: number) {
  return new Intl.DateTimeFormat("ja-JP", {
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    month: "numeric",
  }).format(new Date(value));
}

function formatFullDateTime(value: number) {
  return new Intl.DateTimeFormat("ja-JP", {
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    month: "long",
    weekday: "short",
    year: "numeric",
  }).format(new Date(value));
}

function normalizeReplySearch(value: string | null | undefined) {
  return (value ?? "").replace(/\s+/g, " ").trim().toLowerCase();
}

function extractDraftMentionQuery(value: string) {
  const match = value.match(/(^|\s)@([^\s@]{0,24})$/);
  if (!match) return null;
  return normalizeReplySearch(match[2] ?? "");
}

function splitHighlightSegments(value: string, query: string) {
  const normalizedQuery = normalizeReplySearch(query);
  if (!normalizedQuery) return [{ match: false, text: value }];
  const lowerValue = value.toLowerCase();
  const segments: Array<{ match: boolean; text: string }> = [];
  let cursor = 0;
  while (cursor < value.length) {
    const nextIndex = lowerValue.indexOf(normalizedQuery, cursor);
    if (nextIndex < 0) {
      segments.push({ match: false, text: value.slice(cursor) });
      break;
    }
    if (nextIndex > cursor) {
      segments.push({ match: false, text: value.slice(cursor, nextIndex) });
    }
    const endIndex = nextIndex + normalizedQuery.length;
    segments.push({ match: true, text: value.slice(nextIndex, endIndex) });
    cursor = endIndex;
  }
  return segments.filter((segment) => segment.text.length > 0);
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

function participantSummary(participant: BoardParticipant) {
  const parts: string[] = [];
  if (participant.handle) parts.push(`@${participant.handle}`);
  if (participant.primaryArea) parts.push(participant.primaryArea);
  if (participant.replyCount > 0) parts.push(`返信 ${participant.replyCount}件`);
  if (parts.length === 0) return "返信なし";
  return parts.join(" · ");
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
  headerActionButtonDisabled: {
    opacity: 0.42,
  },
  headerActions: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
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
  heroReadMoreButton: {
    alignSelf: "flex-start",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    paddingHorizontal: 11,
    paddingVertical: 6,
  },
  heroReadMoreText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
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
  heroMetaRow: {
    alignItems: "center",
    flexDirection: "row",
    flexWrap: "wrap",
  },
  heroMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  heroMetaAuthorButton: {
    alignSelf: "center",
  },
  heroMetaAuthor: {
    color: megrumColors.lavender,
    fontSize: 11.5,
    fontWeight: "900",
  },
  threadActions: {
    flexDirection: "row",
    flexWrap: "wrap",
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
  replyHeaderActions: {
    alignItems: "center",
    flex: 1,
    flexWrap: "wrap",
    flexDirection: "row",
    gap: 8,
    justifyContent: "flex-end",
  },
  replyCountMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  latestReplyButton: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    flexDirection: "row",
    gap: 3,
    minHeight: 26,
    paddingHorizontal: 9,
  },
  latestReplyButtonText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  replyReturnButton: {
    alignItems: "center",
    backgroundColor: "rgba(243,197,212,0.28)",
    borderRadius: 999,
    minHeight: 26,
    paddingHorizontal: 9,
    justifyContent: "center",
  },
  replyReturnButtonText: {
    color: "#ba6d8d",
    fontSize: 11,
    fontWeight: "900",
  },
  unreadJumpButton: {
    alignItems: "center",
    backgroundColor: "rgba(168,212,230,0.24)",
    borderRadius: 999,
    minHeight: 26,
    paddingHorizontal: 9,
    justifyContent: "center",
  },
  unreadJumpButtonText: {
    color: "#4f7e92",
    fontSize: 11,
    fontWeight: "900",
  },
  newReplyJumpButton: {
    alignItems: "center",
    backgroundColor: "rgba(116,191,155,0.18)",
    borderRadius: 999,
    minHeight: 26,
    paddingHorizontal: 9,
    justifyContent: "center",
  },
  newReplyJumpButtonText: {
    color: "#3d8f6d",
    fontSize: 11,
    fontWeight: "900",
  },
  mentionJumpButton: {
    alignItems: "center",
    backgroundColor: "rgba(243,197,212,0.28)",
    borderRadius: 999,
    minHeight: 26,
    paddingHorizontal: 9,
    justifyContent: "center",
  },
  mentionJumpButtonText: {
    color: "#ba6d8d",
    fontSize: 11,
    fontWeight: "900",
  },
  mineJumpButton: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.14)",
    borderRadius: 999,
    minHeight: 26,
    paddingHorizontal: 9,
    justifyContent: "center",
  },
  mineJumpButtonText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  savedReplyJumpButton: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.14)",
    borderRadius: 999,
    flexDirection: "row",
    gap: 4,
    minHeight: 26,
    paddingHorizontal: 9,
    justifyContent: "center",
  },
  savedReplyJumpButtonText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  mediaReplyJumpButton: {
    alignItems: "center",
    backgroundColor: "rgba(168,212,230,0.24)",
    borderRadius: 999,
    flexDirection: "row",
    gap: 4,
    minHeight: 26,
    paddingHorizontal: 9,
    justifyContent: "center",
  },
  mediaReplyJumpButtonText: {
    color: "#4f7e92",
    fontSize: 11,
    fontWeight: "900",
  },
  authorReplyJumpButton: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.14)",
    borderRadius: 999,
    flexDirection: "row",
    gap: 4,
    minHeight: 26,
    paddingHorizontal: 9,
    justifyContent: "center",
  },
  authorReplyJumpButtonText: {
    color: "#7a6fc2",
    fontSize: 11,
    fontWeight: "900",
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
  replyActiveFilterBar: {
    alignItems: "center",
    alignSelf: "flex-start",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderColor: "rgba(166,149,216,0.24)",
    borderRadius: 999,
    borderWidth: 1,
    flexDirection: "row",
    gap: 8,
    maxWidth: "100%",
    minHeight: 32,
    paddingLeft: 12,
    paddingRight: 5,
  },
  replyActiveFilterText: {
    color: megrumColors.lavender,
    flexShrink: 1,
    fontSize: 11.5,
    fontWeight: "900",
  },
  replyActiveFilterClear: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 999,
    minHeight: 24,
    justifyContent: "center",
    paddingHorizontal: 10,
  },
  replyActiveFilterClearText: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  replyActiveFilterContext: {
    alignItems: "center",
    backgroundColor: "rgba(168,212,230,0.24)",
    borderRadius: 999,
    minHeight: 24,
    justifyContent: "center",
    paddingHorizontal: 10,
  },
  replyActiveFilterContextText: {
    color: "#4f7e92",
    fontSize: 10.5,
    fontWeight: "900",
  },
  replySortRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
  },
  replySortLabel: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  replySortSegment: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    flex: 1,
    flexDirection: "row",
    padding: 3,
  },
  replySortOption: {
    alignItems: "center",
    borderRadius: 999,
    flex: 1,
    minHeight: 30,
    justifyContent: "center",
  },
  replySortOptionActive: {
    backgroundColor: "#fff",
    ...megrumShadow,
  },
  replySortOptionText: {
    color: "rgba(58,50,74,0.54)",
    fontSize: 11,
    fontWeight: "900",
  },
  replySortOptionTextActive: {
    color: megrumColors.lavender,
  },
  replyJumpRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  replyJumpInputWrap: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 15,
    borderWidth: 1,
    flex: 1,
    flexDirection: "row",
    gap: 4,
    minHeight: 38,
    paddingHorizontal: 12,
  },
  replyJumpPrefix: {
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
  },
  replyJumpInput: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 12,
    fontWeight: "900",
    padding: 0,
  },
  replyJumpButton: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    minHeight: 36,
    justifyContent: "center",
    paddingHorizontal: 14,
  },
  replyJumpButtonActive: {
    backgroundColor: "rgba(166,149,216,0.16)",
  },
  replyJumpButtonText: {
    color: "rgba(58,50,74,0.42)",
    fontSize: 11,
    fontWeight: "900",
  },
  replyJumpButtonTextActive: {
    color: megrumColors.lavender,
  },
  replySearchNavigator: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.1)",
    borderRadius: 16,
    flexDirection: "row",
    justifyContent: "space-between",
    minHeight: 38,
    paddingHorizontal: 12,
  },
  replySearchNavigatorLabel: {
    color: megrumColors.lavender,
    fontSize: 11.5,
    fontWeight: "900",
  },
  replySearchNavigatorActions: {
    flexDirection: "row",
    gap: 8,
  },
  replySearchNavigatorButton: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 999,
    minHeight: 28,
    justifyContent: "center",
    paddingHorizontal: 11,
  },
  replySearchNavigatorButtonText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
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
  replyGroup: {
    gap: 10,
  },
  unreadSeparator: {
    alignItems: "center",
    flexDirection: "row",
    gap: 9,
    paddingHorizontal: 4,
    paddingVertical: 2,
  },
  unreadSeparatorLine: {
    backgroundColor: "rgba(166,149,216,0.28)",
    flex: 1,
    height: StyleSheet.hairlineWidth,
  },
  unreadSeparatorText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
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
  replyMetaRow: {
    alignItems: "center",
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 6,
    paddingHorizontal: 4,
  },
  replyMetaRowMine: {
    alignItems: "center",
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 6,
    justifyContent: "flex-end",
    paddingHorizontal: 4,
  },
  replyAuthorButton: {
    flexShrink: 1,
  },
  replyAuthor: {
    color: megrumColors.mutedInk,
    flexShrink: 1,
    fontSize: 11,
    fontWeight: "800",
  },
  replyNumber: {
    color: "rgba(58,50,74,0.44)",
    fontSize: 10.5,
    fontWeight: "900",
  },
  replyNumberActive: {
    color: megrumColors.lavender,
  },
  replyAuthorBadge: {
    backgroundColor: "rgba(166,149,216,0.14)",
    borderRadius: 999,
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  replyAuthorBadgeText: {
    color: megrumColors.lavender,
    fontSize: 9.5,
    fontWeight: "900",
  },
  replyMentionBadge: {
    backgroundColor: "rgba(168,212,230,0.24)",
    borderRadius: 999,
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  replyMentionBadgeText: {
    color: "#4f7e92",
    fontSize: 9.5,
    fontWeight: "900",
  },
  replyReportedBadge: {
    backgroundColor: "rgba(220,120,94,0.16)",
    borderRadius: 999,
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  replyReportedBadgeText: {
    color: "#c06c52",
    fontSize: 9.5,
    fontWeight: "900",
  },
  replyBubble: {
    borderRadius: 18,
    maxWidth: "100%",
    overflow: "hidden",
    paddingHorizontal: 14,
    paddingVertical: 11,
  },
  replyBubbleMention: {
    borderColor: "rgba(168,212,230,0.72)",
    borderWidth: 1,
  },
  replyBubbleHighlighted: {
    borderColor: "rgba(166,149,216,0.72)",
    borderWidth: 2,
    shadowColor: megrumColors.lavender,
    shadowOffset: { height: 8, width: 0 },
    shadowOpacity: 0.22,
    shadowRadius: 14,
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
  replyReadMoreButton: {
    alignItems: "center",
    alignSelf: "flex-start",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    marginTop: 7,
    minHeight: 26,
    justifyContent: "center",
    paddingHorizontal: 10,
  },
  replyReadMoreButtonMine: {
    alignSelf: "flex-end",
    backgroundColor: "rgba(255,255,255,0.18)",
  },
  replyReadMoreText: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  replyReadMoreTextMine: {
    color: "#fff",
  },
  replyTime: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "700",
    paddingHorizontal: 4,
  },
  replyTimeButton: {
    alignSelf: "flex-start",
  },
  replyTimeButtonMine: {
    alignSelf: "flex-start",
  },
  replyTimeMine: {
    textAlign: "left",
  },
  contextMenuOverlay: {
    alignItems: "center",
    backgroundColor: "rgba(0,0,0,0.06)",
    flex: 1,
    justifyContent: "center",
    paddingHorizontal: 22,
  },
  contextMenuWrap: {
    alignItems: "center",
    maxWidth: 360,
    width: "100%",
  },
  contextMenuBubble: {
    backgroundColor: "rgba(4,4,5,0.94)",
    borderColor: "rgba(255,255,255,0.08)",
    borderRadius: 18,
    borderWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    flexWrap: "wrap",
    overflow: "hidden",
    width: "100%",
  },
  contextMenuItem: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.08)",
    borderRightWidth: StyleSheet.hairlineWidth,
    borderTopWidth: StyleSheet.hairlineWidth,
    gap: 8,
    justifyContent: "center",
    minHeight: 92,
    paddingHorizontal: 10,
    paddingVertical: 12,
    width: "33.333%",
  },
  contextMenuItemDisabled: {
    opacity: 0.28,
  },
  contextMenuText: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 12.5,
    fontWeight: "800",
    lineHeight: 16,
    textAlign: "center",
  },
  contextMenuTextDestructive: {
    color: "#ffb2b2",
  },
  contextMenuPointer: {
    borderLeftColor: "transparent",
    borderLeftWidth: 12,
    borderRightColor: "transparent",
    borderRightWidth: 12,
    borderTopColor: "rgba(4,4,5,0.94)",
    borderTopWidth: 12,
    height: 0,
    width: 0,
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
  replyActionPillDisabled: {
    opacity: 0.42,
  },
  replyActionText: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
  replyActionTextActive: {
    color: megrumColors.lavender,
  },
  searchHighlight: {
    backgroundColor: "rgba(239,217,155,0.55)",
    borderRadius: 5,
    overflow: "hidden",
  },
  searchHighlightMine: {
    backgroundColor: "rgba(255,255,255,0.24)",
  },
  inlineLinkText: {
    fontWeight: "900",
    textDecorationLine: "underline",
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
    minHeight: 22,
    justifyContent: "center",
    paddingHorizontal: 9,
  },
  composerDraftDiscardText: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
  mentionSuggestionBox: {
    gap: 7,
  },
  mentionSuggestionTitle: {
    color: "rgba(58,50,74,0.48)",
    fontSize: 10.5,
    fontWeight: "900",
    paddingLeft: 2,
  },
  mentionSuggestionRail: {
    flexDirection: "row",
    gap: 8,
    paddingRight: 10,
  },
  mentionSuggestionChip: {
    backgroundColor: "#fff",
    borderColor: "rgba(166,149,216,0.2)",
    borderRadius: 999,
    borderWidth: 1,
    maxWidth: 146,
    minHeight: 34,
    paddingHorizontal: 11,
    justifyContent: "center",
    ...megrumShadow,
  },
  mentionSuggestionHandle: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  mentionSuggestionName: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
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
  composerInputCounter: {
    alignSelf: "flex-end",
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: -4,
    paddingRight: 56,
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
  imagePreviewLayer: {
    alignItems: "center",
    backgroundColor: "rgba(12,10,16,0.92)",
    flex: 1,
    justifyContent: "center",
    paddingHorizontal: 14,
  },
  imagePreview: {
    borderRadius: 18,
    height: "78%",
    width: "100%",
  },
  imagePreviewClose: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.18)",
    borderRadius: 999,
    height: 42,
    justifyContent: "center",
    position: "absolute",
    right: 16,
    width: 42,
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
  participantsCard: {
    maxHeight: "72%",
  },
  participantsHeader: {
    alignItems: "flex-start",
    flexDirection: "row",
    gap: 12,
    justifyContent: "space-between",
  },
  participantsTitleBlock: {
    flex: 1,
    gap: 4,
  },
  participantsLead: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  participantsHint: {
    color: "rgba(58,50,74,0.48)",
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
  },
  participantsCloseButton: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    height: 34,
    justifyContent: "center",
    width: 34,
  },
  participantsSearchBox: {
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
  participantsSearchInput: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 13,
    fontWeight: "800",
    padding: 0,
  },
  participantsSortSegment: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    flexDirection: "row",
    padding: 3,
  },
  participantsSortOption: {
    alignItems: "center",
    borderRadius: 999,
    flex: 1,
    minHeight: 30,
    justifyContent: "center",
  },
  participantsSortOptionActive: {
    backgroundColor: "#fff",
    ...megrumShadow,
  },
  participantsSortOptionText: {
    color: "rgba(58,50,74,0.54)",
    fontSize: 11,
    fontWeight: "900",
  },
  participantsSortOptionTextActive: {
    color: megrumColors.lavender,
  },
  participantsList: {
    gap: 8,
    paddingTop: 4,
  },
  participantsEmptyCard: {
    alignItems: "center",
    backgroundColor: "rgba(251,249,252,0.96)",
    borderColor: "rgba(58,50,74,0.06)",
    borderRadius: 18,
    borderWidth: 1,
    gap: 5,
    paddingHorizontal: 14,
    paddingVertical: 18,
  },
  participantsEmptyTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  participantsEmptyBody: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 17,
    textAlign: "center",
  },
  participantRow: {
    alignItems: "center",
    backgroundColor: "rgba(251,249,252,0.96)",
    borderColor: "rgba(58,50,74,0.06)",
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 11,
    paddingVertical: 10,
  },
  participantRowDisabled: {
    opacity: 0.72,
  },
  participantAvatar: {
    alignItems: "center",
    borderRadius: 20,
    height: 40,
    justifyContent: "center",
    width: 40,
  },
  participantAvatarText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "900",
  },
  participantCopy: {
    flex: 1,
    gap: 3,
  },
  participantNameRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 5,
  },
  participantName: {
    color: megrumColors.ink,
    flexShrink: 1,
    fontSize: 13.5,
    fontWeight: "900",
  },
  participantMiniBadge: {
    backgroundColor: "rgba(166,149,216,0.14)",
    borderRadius: 999,
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  participantMiniBadgeText: {
    color: megrumColors.lavender,
    fontSize: 9.5,
    fontWeight: "900",
  },
  participantMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  participantActiveAt: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
  },
  participantTail: {
    alignItems: "flex-end",
    gap: 3,
  },
  participantTailActions: {
    alignItems: "flex-end",
    gap: 5,
  },
  participantFilterHint: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  participantFilterHintDisabled: {
    color: "rgba(58,50,74,0.34)",
  },
  participantProfileButton: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 999,
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  participantProfileText: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
  },
  threadInfoCard: {
    maxHeight: "72%",
  },
  threadInfoList: {
    backgroundColor: "rgba(251,249,252,0.72)",
    borderRadius: 20,
    gap: 1,
    overflow: "hidden",
  },
  threadInfoRow: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.82)",
    flexDirection: "row",
    gap: 12,
    justifyContent: "space-between",
    minHeight: 42,
    paddingHorizontal: 13,
    paddingVertical: 9,
  },
  threadInfoLabel: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "900",
  },
  threadInfoValue: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 12.5,
    fontWeight: "900",
    textAlign: "right",
  },
  mediaGalleryCard: {
    maxHeight: "78%",
  },
  mediaGalleryGrid: {
    gap: 10,
    paddingTop: 4,
  },
  mediaGalleryItem: {
    backgroundColor: "rgba(251,249,252,0.96)",
    borderColor: "rgba(58,50,74,0.06)",
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: "row",
    gap: 11,
    padding: 10,
  },
  mediaGalleryThumb: {
    aspectRatio: 1,
    borderRadius: 15,
    overflow: "hidden",
    width: 92,
  },
  mediaGalleryImage: {
    height: "100%",
    width: "100%",
  },
  mediaGalleryCopy: {
    flex: 1,
    gap: 5,
    justifyContent: "center",
  },
  mediaGallerySource: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  mediaGalleryBody: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 16,
  },
  mediaGalleryFooter: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    paddingTop: 2,
  },
  mediaGalleryTime: {
    color: "rgba(58,50,74,0.46)",
    fontSize: 10.5,
    fontWeight: "800",
  },
  mediaGalleryJumpButton: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.14)",
    borderRadius: 999,
    minHeight: 28,
    justifyContent: "center",
    paddingHorizontal: 10,
  },
  mediaGalleryJumpText: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
});
