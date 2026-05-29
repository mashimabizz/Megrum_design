import AsyncStorage from "@react-native-async-storage/async-storage";
import { isUuidLike } from "./groom";
import type { MegrumCoordinate } from "./locationContext";
import { hasSupabaseConfig, supabase } from "./supabase";

export type MeguriBoardAudienceScope =
  | "nearby_3km"
  | "same_prefecture"
  | "same_spot"
  | "global";
export type MeguriBoardViewMode = "nearby_3km" | "same_prefecture";

export type MeguriBoardViewerContext = {
  coordinate?: MegrumCoordinate | null;
  prefecture: string | null;
  spotKey: string | null;
  spotLabel: string | null;
  viewerId?: string | null;
};

export type MeguriBoardActor = {
  userId: string;
  displayName: string;
  handle: string | null;
  primaryArea: string | null;
};

export type MeguriBoardThread = {
  id: string;
  authorHandle: string | null;
  authorId: string;
  authorName: string;
  authorPrimaryArea: string | null;
  audienceScope: MeguriBoardAudienceScope;
  body: string;
  createdAt: number;
  latestActivityAt: number;
  latestReplyPreview: string | null;
  mine: boolean;
  distanceMeters: number | null;
  originLat: number | null;
  originLng: number | null;
  prefecture: string | null;
  replyCount: number;
  spotKey: string | null;
  spotLabel: string | null;
  title: string;
};

export type MeguriBoardReply = {
  authorHandle: string | null;
  authorId: string;
  authorName: string;
  authorPrimaryArea: string | null;
  body: string;
  createdAt: number;
  id: string;
  mine: boolean;
  threadId: string;
};

type RemoteUserRow = {
  display_name?: unknown;
  handle?: unknown;
  id?: unknown;
  primary_area?: unknown;
};

type RemoteThreadRow = Record<string, unknown> & {
  author?: RemoteUserRow | RemoteUserRow[] | null;
};

type RemoteReplyRow = Record<string, unknown> & {
  author?: RemoteUserRow | RemoteUserRow[] | null;
};

type CreateMeguriBoardThreadInput = {
  audienceScope: MeguriBoardAudienceScope;
  body: string;
  origin?: MegrumCoordinate | null;
  prefecture: string | null;
  previewMode?: boolean;
  spotKey: string | null;
  spotLabel: string | null;
  title: string;
};

type CreateMeguriBoardReplyInput = {
  body: string;
  previewMode?: boolean;
  threadId: string;
  viewer?: MeguriBoardViewerContext | null;
  viewMode?: MeguriBoardViewMode;
};

const THREADS_KEY = "meguri.board.threads.v1";
const REPLIES_KEY = "meguri.board.replies.v1";

const MAX_LOCAL_THREADS = 120;
const MAX_LOCAL_REPLIES = 480;

const PREVIEW_AUTHORS = {
  me: {
    displayName: "あなた",
    handle: "preview_hana",
    id: "preview-me",
    primaryArea: "東京",
  },
  michi: {
    displayName: "みち",
    handle: "michilion",
    id: "preview-michi",
    primaryArea: "東京",
  },
  yui: {
    displayName: "ゆい",
    handle: "stage_yui",
    id: "preview-yui",
    primaryArea: "東京",
  },
  ren: {
    displayName: "れん",
    handle: "stage_ren",
    id: "preview-ren",
    primaryArea: "東京",
  },
  kiko: {
    displayName: "きこ",
    handle: "kai_kiko",
    id: "preview-kiko",
    primaryArea: "大阪",
  },
} as const;

export const MEGURI_BOARD_AUDIENCE_OPTIONS = [
  "nearby_3km",
  "same_prefecture",
] as const satisfies readonly MeguriBoardAudienceScope[];

export function meguriBoardAudienceLabel(scope: MeguriBoardAudienceScope) {
  switch (scope) {
    case "nearby_3km":
      return "3km圏内";
    case "same_spot":
      return "3km圏内";
    case "same_prefecture":
      return "同じ都道府県";
    case "global":
    default:
      return "全体";
  }
}

export function meguriBoardAudienceMeta(
  thread: Pick<
    MeguriBoardThread,
    "audienceScope" | "distanceMeters" | "prefecture" | "spotLabel"
  >,
) {
  switch (thread.audienceScope) {
    case "nearby_3km":
      return thread.distanceMeters !== null
        ? `現在地から${formatDistance(thread.distanceMeters)}`
        : "3km圏内";
    case "same_spot":
      return thread.distanceMeters !== null
        ? `現在地から${formatDistance(thread.distanceMeters)}`
        : thread.spotLabel || "3km圏内";
    case "same_prefecture":
      return thread.prefecture || "同じ都道府県";
    case "global":
    default:
      return "どこからでも見える";
  }
}

export async function loadMeguriBoardThreads(
  viewer: MeguriBoardViewerContext,
  options: { previewMode?: boolean; viewMode?: MeguriBoardViewMode } = {},
) {
  const usePreviewData = shouldUsePreviewMeguriBoard(viewer.viewerId, options.previewMode);
  const viewMode = options.viewMode ?? "nearby_3km";
  const [localThreads, localReplies, remoteThreads] = await Promise.all([
    loadLocalMeguriBoardThreads(),
    loadLocalMeguriBoardReplies(),
    usePreviewData ? Promise.resolve([]) : loadRemoteMeguriBoardThreads(viewer, viewMode).catch(() => []),
  ]);
  const preview = usePreviewData ? createPreviewMeguriBoardDataset() : null;
  const mergedThreads = dedupeThreads([
    ...(preview?.threads ?? []),
    ...localThreads,
    ...remoteThreads,
  ]);
  const mergedReplies = dedupeReplies([
    ...(preview?.replies ?? []),
    ...localReplies,
  ]);
  return overlayReplySummaries(
    mergedThreads.filter((thread) => canViewMeguriBoardThread(thread, viewer, viewMode)),
    mergedReplies,
  );
}

export async function loadMeguriBoardThreadDetail(
  threadId: string,
  viewer: MeguriBoardViewerContext,
  options: { previewMode?: boolean; viewMode?: MeguriBoardViewMode } = {},
) {
  const usePreviewData = shouldUsePreviewMeguriBoard(viewer.viewerId, options.previewMode);
  const viewMode = options.viewMode ?? "nearby_3km";
  const [threads, localReplies, remoteReplies] = await Promise.all([
    loadMeguriBoardThreads(viewer, options),
    loadLocalMeguriBoardReplies(),
    usePreviewData || !threadId
      ? Promise.resolve([])
      : loadRemoteMeguriBoardReplies(threadId, viewer, viewMode).catch(() => []),
  ]);
  const preview = usePreviewData ? createPreviewMeguriBoardDataset() : null;
  const thread = threads.find((candidate) => candidate.id === threadId) ?? null;
  if (!thread) {
    return { replies: [] as MeguriBoardReply[], thread: null };
  }
  const replies = dedupeReplies([
    ...(preview?.replies.filter((reply) => reply.threadId === threadId) ?? []),
    ...localReplies.filter((reply) => reply.threadId === threadId),
    ...remoteReplies,
  ]).sort((left, right) => left.createdAt - right.createdAt);
  return { replies, thread };
}

export async function createMeguriBoardThread(
  input: CreateMeguriBoardThreadInput,
  actor: MeguriBoardActor,
) {
  const remote = await appendRemoteMeguriBoardThread(input, actor).catch(() => null);
  if (remote) {
    await storeLocalMeguriBoardThread(remote);
    return remote;
  }
  const createdAt = Date.now();
  const localThread: MeguriBoardThread = {
    authorHandle: actor.handle,
    authorId: actor.userId,
    authorName: actor.displayName,
    authorPrimaryArea: actor.primaryArea,
    audienceScope: input.audienceScope,
    body: input.body.trim(),
    createdAt,
    distanceMeters: input.origin ? 0 : null,
    id: `meguri-board-thread-${createdAt}`,
    latestActivityAt: createdAt,
    latestReplyPreview: null,
    mine: true,
    originLat: input.origin?.latitude ?? null,
    originLng: input.origin?.longitude ?? null,
    prefecture: input.prefecture || actor.primaryArea || null,
    replyCount: 0,
    spotKey: input.spotKey,
    spotLabel: input.spotLabel,
    title: input.title.trim(),
  };
  await storeLocalMeguriBoardThread(localThread);
  return localThread;
}

export async function appendMeguriBoardReply(
  input: CreateMeguriBoardReplyInput,
  actor: MeguriBoardActor,
) {
  const remote = await appendRemoteMeguriBoardReply(input, actor).catch(() => null);
  if (remote) {
    await storeLocalMeguriBoardReply(remote);
    return remote;
  }
  const createdAt = Date.now();
  const reply: MeguriBoardReply = {
    authorHandle: actor.handle,
    authorId: actor.userId,
    authorName: actor.displayName,
    authorPrimaryArea: actor.primaryArea,
    body: input.body.trim(),
    createdAt,
    id: `meguri-board-reply-${createdAt}`,
    mine: true,
    threadId: input.threadId,
  };
  await storeLocalMeguriBoardReply(reply);
  return reply;
}

function shouldUsePreviewMeguriBoard(viewerId?: string | null, previewMode?: boolean) {
  if (previewMode) return true;
  if (!hasSupabaseConfig) return true;
  if (!viewerId || !isUuidLike(viewerId)) return true;
  return false;
}

function canViewMeguriBoardThread(
  thread: Pick<
    MeguriBoardThread,
    | "audienceScope"
    | "authorId"
    | "distanceMeters"
    | "originLat"
    | "originLng"
    | "prefecture"
    | "spotKey"
  >,
  viewer: MeguriBoardViewerContext,
  viewMode: MeguriBoardViewMode,
) {
  if (viewer.viewerId && viewer.viewerId === thread.authorId) return true;
  const viewerPrefecture = normalizeAreaKey(viewer.prefecture);
  const threadPrefecture = normalizeAreaKey(thread.prefecture);
  if (viewMode === "same_prefecture") {
    if (thread.audienceScope !== "same_prefecture" && thread.audienceScope !== "global") return false;
    return !!viewerPrefecture && !!threadPrefecture && viewerPrefecture === threadPrefecture;
  }
  if (thread.audienceScope !== "nearby_3km" && thread.audienceScope !== "same_spot") return false;
  if (thread.distanceMeters !== null) return thread.distanceMeters <= 3000;
  if (viewer.coordinate && thread.originLat !== null && thread.originLng !== null) {
    return (
      haversineMeters(
        viewer.coordinate.latitude,
        viewer.coordinate.longitude,
        thread.originLat,
        thread.originLng,
      ) <= 3000
    );
  }
  if (!viewer.spotKey || !thread.spotKey) {
    return !!viewerPrefecture && !!threadPrefecture && viewerPrefecture === threadPrefecture;
  }
  return viewer.spotKey === thread.spotKey;
}

function overlayReplySummaries(threads: MeguriBoardThread[], replies: MeguriBoardReply[]) {
  const repliesByThread = new Map<string, MeguriBoardReply[]>();
  for (const reply of replies) {
    const group = repliesByThread.get(reply.threadId);
    if (group) group.push(reply);
    else repliesByThread.set(reply.threadId, [reply]);
  }
  return [...threads]
    .map((thread) => {
      const group = repliesByThread.get(thread.id) ?? [];
      if (group.length === 0) return thread;
      const sorted = [...group].sort((left, right) => left.createdAt - right.createdAt);
      const latest = sorted[sorted.length - 1];
      return {
        ...thread,
        latestActivityAt: Math.max(thread.latestActivityAt, latest.createdAt),
        latestReplyPreview: latest.body || thread.latestReplyPreview,
        replyCount: Math.max(thread.replyCount, sorted.length),
      };
    })
    .sort((left, right) => right.latestActivityAt - left.latestActivityAt);
}

async function loadLocalMeguriBoardThreads(): Promise<MeguriBoardThread[]> {
  const raw = await AsyncStorage.getItem(THREADS_KEY);
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(isMeguriBoardThread).map(normalizeStoredThread);
  } catch {
    return [];
  }
}

async function loadLocalMeguriBoardReplies(): Promise<MeguriBoardReply[]> {
  const raw = await AsyncStorage.getItem(REPLIES_KEY);
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(isMeguriBoardReply);
  } catch {
    return [];
  }
}

async function storeLocalMeguriBoardThread(nextThread: MeguriBoardThread) {
  const current = await loadLocalMeguriBoardThreads();
  const next = dedupeThreads([...current, nextThread])
    .sort((left, right) => right.latestActivityAt - left.latestActivityAt)
    .slice(0, MAX_LOCAL_THREADS);
  await AsyncStorage.setItem(THREADS_KEY, JSON.stringify(next));
}

async function storeLocalMeguriBoardReply(nextReply: MeguriBoardReply) {
  const current = await loadLocalMeguriBoardReplies();
  const exists = current.some((reply) => reply.id === nextReply.id);
  const next = dedupeReplies([...current, nextReply])
    .sort((left, right) => left.createdAt - right.createdAt)
    .slice(-MAX_LOCAL_REPLIES);
  await AsyncStorage.setItem(REPLIES_KEY, JSON.stringify(next));
  await syncLocalMeguriBoardThreadForReply(nextReply, exists);
}

async function syncLocalMeguriBoardThreadForReply(reply: MeguriBoardReply, alreadyCounted: boolean) {
  const current = await loadLocalMeguriBoardThreads();
  const next = current.map((thread) =>
    thread.id === reply.threadId
      ? {
          ...thread,
          latestActivityAt: Math.max(thread.latestActivityAt, reply.createdAt),
          latestReplyPreview: reply.body,
          replyCount: thread.replyCount + (alreadyCounted ? 0 : 1),
        }
      : thread,
  );
  await AsyncStorage.setItem(
    THREADS_KEY,
    JSON.stringify(
      next
        .sort((left, right) => right.latestActivityAt - left.latestActivityAt)
        .slice(0, MAX_LOCAL_THREADS),
    ),
  );
}

async function loadRemoteMeguriBoardThreads(
  viewer: MeguriBoardViewerContext,
  viewMode: MeguriBoardViewMode,
): Promise<MeguriBoardThread[]> {
  if (!supabase || !hasSupabaseConfig) return [];
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return [];
  const rpc = await supabase.rpc("list_meguri_board_threads_for_viewer", {
    p_prefecture: viewer.prefecture,
    p_scope: viewMode,
    p_viewer_lat: viewer.coordinate?.latitude ?? null,
    p_viewer_lng: viewer.coordinate?.longitude ?? null,
  });
  if (!rpc.error) {
    const rows: unknown[] = Array.isArray(rpc.data) ? rpc.data : [];
    return rows
      .map((row) => remoteMeguriBoardThreadToLocal(row as RemoteThreadRow, user.id))
      .filter((thread): thread is MeguriBoardThread => !!thread);
  }

  const { data, error } = await supabase
    .from("meguri_board_threads")
    .select(remoteThreadSelect(false))
    .order("latest_activity_at", { ascending: false })
    .limit(120);
  if (error) throw error;
  const rows: unknown[] = Array.isArray(data) ? data : [];
  return rows
    .map((row) => remoteMeguriBoardThreadToLocal(row as RemoteThreadRow, user.id))
    .filter((thread): thread is MeguriBoardThread => !!thread)
    .filter((thread) => canViewMeguriBoardThread(thread, viewer, viewMode));
}

async function loadRemoteMeguriBoardReplies(
  threadId: string,
  viewer: MeguriBoardViewerContext,
  viewMode: MeguriBoardViewMode = "nearby_3km",
): Promise<MeguriBoardReply[]> {
  if (!supabase || !hasSupabaseConfig || !threadId) return [];
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return [];
  if (isUuidLike(threadId)) {
    const rpc = await supabase.rpc("list_meguri_board_replies_for_viewer", {
      p_prefecture: viewer.prefecture,
      p_scope: viewMode,
      p_thread_id: threadId,
      p_viewer_lat: viewer.coordinate?.latitude ?? null,
      p_viewer_lng: viewer.coordinate?.longitude ?? null,
    });
    if (!rpc.error) {
      const rows: unknown[] = Array.isArray(rpc.data) ? rpc.data : [];
      return rows
        .map((row) => remoteMeguriBoardReplyToLocal(row as RemoteReplyRow, user.id))
        .filter((reply): reply is MeguriBoardReply => !!reply);
    }
  }
  if (!isUuidLike(threadId)) return [];

  const { data, error } = await supabase
    .from("meguri_board_replies")
    .select(remoteReplySelect())
    .eq("thread_id", threadId)
    .order("created_at", { ascending: true })
    .limit(300);
  if (error) throw error;
  const rows: unknown[] = Array.isArray(data) ? data : [];
  return rows
    .map((row) => remoteMeguriBoardReplyToLocal(row as RemoteReplyRow, user.id))
    .filter((reply): reply is MeguriBoardReply => !!reply);
}

async function appendRemoteMeguriBoardThread(
  input: CreateMeguriBoardThreadInput,
  actor: MeguriBoardActor,
) {
  if (
    !supabase ||
    !hasSupabaseConfig ||
    input.previewMode ||
    !actor.userId ||
    !isUuidLike(actor.userId)
  ) {
    return null;
  }
  const payload = {
    author_id: actor.userId,
    audience_scope: input.audienceScope,
    body: input.body.trim(),
    origin_lat: input.origin?.latitude ?? null,
    origin_lng: input.origin?.longitude ?? null,
    prefecture: input.prefecture || actor.primaryArea || null,
    spot_key: input.spotKey,
    spot_label: input.spotLabel,
    title: input.title.trim(),
  };
  let { data, error } = await supabase
    .from("meguri_board_threads")
    .insert(payload)
    .select(remoteThreadSelect(true))
    .single();
  if (error && shouldRetryLegacyBoardInsert(error)) {
    const { origin_lat: _originLat, origin_lng: _originLng, ...rest } = payload;
    const retry = await supabase
      .from("meguri_board_threads")
      .insert({
        ...rest,
        audience_scope: legacyAudienceScope(input.audienceScope),
      })
      .select(remoteThreadSelect(false))
      .single();
    data = retry.data;
    error = retry.error;
  }
  if (error || !data) throw error ?? new Error("Failed to create meguri board thread.");
  return remoteMeguriBoardThreadToLocal(data as unknown as RemoteThreadRow, actor.userId);
}

async function appendRemoteMeguriBoardReply(
  input: CreateMeguriBoardReplyInput,
  actor: MeguriBoardActor,
) {
  if (
    !supabase ||
    !hasSupabaseConfig ||
    input.previewMode ||
    !actor.userId ||
    !isUuidLike(actor.userId)
  ) {
    return null;
  }
  if (input.viewer && isUuidLike(input.threadId)) {
    const rpc = await supabase.rpc("append_meguri_board_reply_for_viewer", {
      p_body: input.body.trim(),
      p_prefecture: input.viewer.prefecture,
      p_scope: input.viewMode ?? "nearby_3km",
      p_thread_id: input.threadId,
      p_viewer_lat: input.viewer.coordinate?.latitude ?? null,
      p_viewer_lng: input.viewer.coordinate?.longitude ?? null,
    });
    if (!rpc.error) {
      const row = Array.isArray(rpc.data) ? rpc.data[0] : null;
      const reply = row
        ? remoteMeguriBoardReplyToLocal(row as RemoteReplyRow, actor.userId)
        : null;
      if (reply) return reply;
    }
  }
  const { data, error } = await supabase
    .from("meguri_board_replies")
    .insert({
      author_id: actor.userId,
      body: input.body.trim(),
      thread_id: input.threadId,
    })
    .select(remoteReplySelect())
    .single();
  if (error || !data) throw error ?? new Error("Failed to create meguri board reply.");
  return remoteMeguriBoardReplyToLocal(data as unknown as RemoteReplyRow, actor.userId);
}

function remoteMeguriBoardThreadToLocal(
  row: RemoteThreadRow,
  viewerId: string,
): MeguriBoardThread | null {
  const author = authorObject(row);
  const id = stringValue(row.id);
  const authorId = stringValue(row.author_id) || stringValue(author.id);
  const title = stringValue(row.title);
  const body = stringValue(row.body);
  if (!id || !authorId || !title || !body) return null;
  return {
    authorHandle: nullableStringValue(author.handle),
    authorId,
    authorName:
      nullableStringValue(author.display_name) ||
      nullableStringValue(author.handle) ||
      "めぐりユーザー",
    authorPrimaryArea: nullableStringValue(author.primary_area),
    audienceScope: normalizeAudienceScope(row.audience_scope),
    body,
    createdAt: timestampValue(row.created_at, Date.now()),
    id,
    latestActivityAt: timestampValue(row.latest_activity_at, timestampValue(row.created_at, Date.now())),
    latestReplyPreview: nullableStringValue(row.latest_reply_preview),
    mine: authorId === viewerId,
    distanceMeters: nullableNumberValue(row.distance_m),
    originLat: nullableNumberValue(row.origin_lat),
    originLng: nullableNumberValue(row.origin_lng),
    prefecture: nullableStringValue(row.prefecture),
    replyCount: numberValue(row.reply_count, 0),
    spotKey: nullableStringValue(row.spot_key),
    spotLabel: nullableStringValue(row.spot_label),
    title,
  };
}

function remoteMeguriBoardReplyToLocal(
  row: RemoteReplyRow,
  viewerId: string,
): MeguriBoardReply | null {
  const author = authorObject(row);
  const id = stringValue(row.id);
  const threadId = stringValue(row.thread_id);
  const authorId = stringValue(row.author_id) || stringValue(author.id);
  const body = stringValue(row.body);
  if (!id || !threadId || !authorId || !body) return null;
  return {
    authorHandle: nullableStringValue(author.handle),
    authorId,
    authorName:
      nullableStringValue(author.display_name) ||
      nullableStringValue(author.handle) ||
      "めぐりユーザー",
    authorPrimaryArea: nullableStringValue(author.primary_area),
    body,
    createdAt: timestampValue(row.created_at, Date.now()),
    id,
    mine: authorId === viewerId,
    threadId,
  };
}

function createPreviewMeguriBoardDataset() {
  const now = Date.now();
  const replies: MeguriBoardReply[] = [
    createPreviewReply(
      "preview-board-reply-1",
      "preview-board-thread-1",
      PREVIEW_AUTHORS.ren,
      "いま 20 分くらいです。スタッフさんが列を3本に分けてました。",
      now - 42 * 60000,
    ),
    createPreviewReply(
      "preview-board-reply-2",
      "preview-board-thread-1",
      PREVIEW_AUTHORS.yui,
      "25ゲート側は日陰が少ないので、水だけあると助かります。",
      now - 31 * 60000,
    ),
    createPreviewReply(
      "preview-board-reply-3",
      "preview-board-thread-2",
      PREVIEW_AUTHORS.michi,
      "東側の出口はかなり流れが速かったです。駅は少し混んでました。",
      now - 92 * 60000,
    ),
    createPreviewReply(
      "preview-board-reply-4",
      "preview-board-thread-3",
      PREVIEW_AUTHORS.kiko,
      "小さいレジャーシートとモバイルバッテリーは本当に役立ちました。",
      now - 6 * 3600000,
    ),
  ];

  const threads = overlayReplySummaries(
    [
      createPreviewThread(
        "preview-board-thread-1",
        PREVIEW_AUTHORS.michi,
        "物販列いまどれくらい？",
        "25ゲート前から見える範囲で、今から並ぶか迷っています。",
        "nearby_3km",
        "tokyo-dome-gate25",
        "東京ドーム 25ゲート前",
        "東京",
        35.7056,
        139.7519,
        420,
        now - 54 * 60000,
      ),
      createPreviewThread(
        "preview-board-thread-2",
        PREVIEW_AUTHORS.yui,
        "終演後の駅導線どんな感じでした？",
        "有明アリーナから出たあと、混み方が穏やかなルートがあれば知りたいです。",
        "same_prefecture",
        "ariake-arena-main",
        "有明アリーナ",
        "東京",
        35.6432,
        139.7949,
        null,
        now - 2 * 3600000,
      ),
      createPreviewThread(
        "preview-board-thread-3",
        PREVIEW_AUTHORS.kiko,
        "今週の現地で持っていって助かったもの",
        "遠征組でも現地勢でも、これは便利だったという小物があれば知りたいです。",
        "same_prefecture",
        null,
        "今週の現地",
        "大阪",
        34.6694,
        135.4762,
        null,
        now - 7 * 3600000,
      ),
      createPreviewThread(
        "preview-board-thread-4",
        PREVIEW_AUTHORS.kiko,
        "京セラの入場列、手前は空いてます",
        "2ゲート寄りはまだ余裕ありました。大阪勢向けのメモです。",
        "nearby_3km",
        "kyocera-dome-gate2",
        "京セラドーム 2ゲート前",
        "大阪",
        34.6694,
        135.4762,
        7800,
        now - 36 * 60000,
      ),
    ],
    replies,
  );

  return { replies, threads };
}

function createPreviewThread(
  id: string,
  author: (typeof PREVIEW_AUTHORS)[keyof typeof PREVIEW_AUTHORS],
  title: string,
  body: string,
  audienceScope: MeguriBoardAudienceScope,
  spotKey: string | null,
  spotLabel: string | null,
  prefecture: string | null,
  originLat: number | null,
  originLng: number | null,
  distanceMeters: number | null,
  createdAt: number,
): MeguriBoardThread {
  return {
    authorHandle: author.handle,
    authorId: author.id,
    authorName: author.displayName,
    authorPrimaryArea: author.primaryArea,
    audienceScope,
    body,
    createdAt,
    id,
    latestActivityAt: createdAt,
    latestReplyPreview: null,
    mine: false,
    distanceMeters,
    originLat,
    originLng,
    prefecture,
    replyCount: 0,
    spotKey,
    spotLabel,
    title,
  };
}

function createPreviewReply(
  id: string,
  threadId: string,
  author: (typeof PREVIEW_AUTHORS)[keyof typeof PREVIEW_AUTHORS],
  body: string,
  createdAt: number,
): MeguriBoardReply {
  return {
    authorHandle: author.handle,
    authorId: author.id,
    authorName: author.displayName,
    authorPrimaryArea: author.primaryArea,
    body,
    createdAt,
    id,
    mine: false,
    threadId,
  };
}

function dedupeThreads(threads: MeguriBoardThread[]) {
  const keyed = new Map<string, MeguriBoardThread>();
  for (const thread of threads) {
    keyed.set(thread.id, thread);
  }
  return [...keyed.values()];
}

function dedupeReplies(replies: MeguriBoardReply[]) {
  const keyed = new Map<string, MeguriBoardReply>();
  for (const reply of replies) {
    keyed.set(reply.id, reply);
  }
  return [...keyed.values()];
}

function isMeguriBoardThread(value: unknown): value is MeguriBoardThread {
  const row = objectValue(value);
  return (
    !!stringValue(row.id) &&
    !!stringValue(row.authorId) &&
    !!stringValue(row.authorName) &&
    !!stringValue(row.title) &&
    !!stringValue(row.body) &&
    typeof row.createdAt === "number" &&
    typeof row.latestActivityAt === "number" &&
    typeof row.replyCount === "number"
  );
}

function isMeguriBoardReply(value: unknown): value is MeguriBoardReply {
  const row = objectValue(value);
  return (
    !!stringValue(row.id) &&
    !!stringValue(row.threadId) &&
    !!stringValue(row.authorId) &&
    !!stringValue(row.authorName) &&
    !!stringValue(row.body) &&
    typeof row.createdAt === "number"
  );
}

function normalizeStoredThread(thread: MeguriBoardThread): MeguriBoardThread {
  return {
    ...thread,
    audienceScope: normalizeAudienceScope(thread.audienceScope),
    distanceMeters: nullableNumberValue(thread.distanceMeters),
    originLat: nullableNumberValue(thread.originLat),
    originLng: nullableNumberValue(thread.originLng),
  };
}

function remoteThreadSelect(includeLocation: boolean) {
  return [
    "id",
    "author_id",
    "title",
    "body",
    "audience_scope",
    "spot_key",
    "spot_label",
    "prefecture",
    includeLocation ? "origin_lat" : null,
    includeLocation ? "origin_lng" : null,
    "reply_count",
    "latest_reply_preview",
    "latest_activity_at",
    "created_at",
    "author:users!meguri_board_threads_author_id_fkey(id, display_name, handle, primary_area)",
  ]
    .filter(Boolean)
    .join(", ");
}

function remoteReplySelect() {
  return [
    "id",
    "thread_id",
    "author_id",
    "body",
    "created_at",
    "author:users!meguri_board_replies_author_id_fkey(id, display_name, handle, primary_area)",
  ].join(", ");
}

function authorObject(row: RemoteThreadRow | RemoteReplyRow): Record<string, unknown> {
  const nested = relationObject(row.author);
  if (Object.keys(nested).length > 0) return nested;
  return {
    display_name: row.author_display_name,
    handle: row.author_handle,
    id: row.author_id,
    primary_area: row.author_primary_area,
  };
}

function relationObject(value: unknown): Record<string, unknown> {
  if (Array.isArray(value)) return objectValue(value[0]);
  return objectValue(value);
}

function objectValue(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return value as Record<string, unknown>;
}

function stringValue(value: unknown) {
  return typeof value === "string" ? value : "";
}

function nullableStringValue(value: unknown) {
  return typeof value === "string" && value.length > 0 ? value : null;
}

function numberValue(value: unknown, fallback: number) {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}

function nullableNumberValue(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function normalizeAudienceScope(value: unknown): MeguriBoardAudienceScope {
  if (
    value === "nearby_3km" ||
    value === "same_spot" ||
    value === "same_prefecture" ||
    value === "global"
  ) {
    return value;
  }
  return "same_prefecture";
}

function timestampValue(value: unknown, fallback: number) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value !== "string") return fallback;
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normalizeAreaKey(value: string | null) {
  if (!value) return null;
  return value.replace(/\s+/g, "").trim();
}

function formatDistance(value: number) {
  if (value < 1000) return `${Math.max(50, Math.round(value / 50) * 50)}m`;
  return `${(value / 1000).toFixed(value < 10000 ? 1 : 0)}km`;
}

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number) {
  const radius = 6371000;
  const toRad = (value: number) => (value * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return radius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function legacyAudienceScope(scope: MeguriBoardAudienceScope): "same_spot" | "same_prefecture" | "global" {
  if (scope === "nearby_3km") return "same_spot";
  if (scope === "same_spot" || scope === "same_prefecture" || scope === "global") return scope;
  return "same_prefecture";
}

function shouldRetryLegacyBoardInsert(error: unknown) {
  const message =
    typeof error === "object" && error && "message" in error
      ? String((error as { message?: unknown }).message ?? "")
      : String(error);
  return (
    message.includes("origin_lat") ||
    message.includes("origin_lng") ||
    message.includes("audience_scope") ||
    message.includes("meguri_board_threads_audience_scope_check") ||
    message.includes("meguri_board_scope_context")
  );
}
