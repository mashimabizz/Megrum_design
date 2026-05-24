import { hasSupabaseConfig, supabase } from "./supabase";

export type GroomRemoteAuthor = {
  avatarUrl: string | null;
  displayName: string;
  handle: string | null;
  id: string;
  primaryArea: string | null;
};

export type GroomRemoteImageTransform = {
  rotation: number;
  scale: number;
  x: number;
  y: number;
};

export type GroomRemotePost = {
  audienceScope: string;
  author: GroomRemoteAuthor;
  caption: string;
  doodles: unknown[];
  expiresAt: string;
  id: string;
  imagePath: string | null;
  imageTransform: GroomRemoteImageTransform;
  imageUrl: string;
  liked: boolean;
  mine: boolean;
  placeHint: string;
  publishedAt: string;
  stickers: unknown[];
  textOverlays: unknown[];
  viewed: boolean;
};

export type GroomCreatePostInput = {
  caption: string;
  doodles: unknown[];
  imageBase64?: string | null;
  imageContentType?: string | null;
  imageTransform: GroomRemoteImageTransform;
  imageUri: string;
  placeHint?: string;
  stickers: unknown[];
  textOverlays: unknown[];
};

const GROOM_BUCKET = "groom-posts";
const GROOM_MAX_UPLOAD_BYTES = 9.5 * 1024 * 1024;
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isUuidLike(value: string | null | undefined) {
  return typeof value === "string" && UUID_PATTERN.test(value);
}

function groomPostSelect() {
  return [
    "id",
    "user_id",
    "image_url",
    "image_path",
    "caption",
    "status",
    "audience_scope",
    "area_key",
    "place_hint",
    "image_transform",
    "text_overlays",
    "stickers",
    "doodles",
    "published_at",
    "expires_at",
    "users!groom_posts_user_id_fkey(id, display_name, handle, avatar_url, primary_area)",
  ].join(", ");
}

export async function fetchGroomFeed(currentUserId: string): Promise<GroomRemotePost[]> {
  if (!supabase || !hasSupabaseConfig) return [];
  await supabase.rpc("expire_groom_posts").throwOnError();
  const { data, error } = await supabase
    .from("groom_posts")
    .select(groomPostSelect())
    .eq("status", "published")
    .gt("expires_at", new Date().toISOString())
    .order("published_at", { ascending: false })
    .limit(40);

  if (error) throw error;
  const rows = (Array.isArray(data) ? data : []) as unknown as Record<string, unknown>[];
  const ids = rows.map((row) => stringValue(row.id)).filter(Boolean);
  const [likedIds, viewedIds, signedUrls] = await Promise.all([
    fetchGroomReactionIds(currentUserId, ids),
    fetchGroomViewIds(currentUserId, ids),
    signGroomImageUrls(rows),
  ]);

  return rows
    .map((row) => normalizeRemotePost(row, currentUserId, likedIds, viewedIds, signedUrls))
    .filter((post): post is GroomRemotePost => !!post);
}

export async function createGroomPost(
  currentUserId: string,
  input: GroomCreatePostInput,
): Promise<GroomRemotePost> {
  if (!supabase || !hasSupabaseConfig) {
    throw new Error("Supabase is not configured.");
  }

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();
  if (authError || !user) {
    throw new Error("ログイン情報を確認できませんでした。ログインし直してから投稿してください。");
  }
  if (user.id !== currentUserId) {
    throw new Error("ログイン中のユーザー情報が古くなっています。アプリを開き直してから投稿してください。");
  }

  const uploaded = await uploadGroomImage(
    currentUserId,
    input.imageUri,
    input.imageBase64,
    input.imageContentType,
  );
  const audience = await buildGroomAudience(currentUserId);
  const { data, error } = await supabase
    .from("groom_posts")
    .insert({
      audience_scope: "encountered_people",
      audience_user_ids: audience.userIds,
      area_key: audience.areaKey,
      caption: input.caption || null,
      doodles: input.doodles,
      image_path: uploaded.path,
      image_transform: input.imageTransform,
      image_url: uploaded.storedUrl,
      place_hint: input.placeHint ?? "今日の現場付近",
      status: "published",
      stickers: input.stickers,
      text_overlays: input.textOverlays,
      user_id: currentUserId,
    })
    .select(groomPostSelect())
    .single();

  if (error) {
    if (uploaded.path) {
      await supabase.storage.from(GROOM_BUCKET).remove([uploaded.path]).catch(() => undefined);
    }
    throw error;
  }
  const row = data as unknown as Record<string, unknown>;
  const signedUrls = await signGroomImageUrls([row]).catch((signError: unknown) => {
    console.warn("Failed to sign groom image after publishing", signError);
    return new Map<string, string>();
  });
  const post = normalizeRemotePost(
    row,
    currentUserId,
    new Set(),
    new Set([stringValue(row.id)]),
    signedUrls,
    input.imageUri,
  );
  if (!post) throw new Error("Published groom post was malformed.");
  return post;
}

export async function archiveGroomPost(currentUserId: string, postId: string) {
  if (!supabase || !hasSupabaseConfig || !isUuidLike(postId)) return;
  const { error } = await supabase
    .from("groom_posts")
    .update({ status: "archived" })
    .eq("id", postId)
    .eq("user_id", currentUserId);
  if (error) throw error;
}

export async function hideGroomPost(currentUserId: string, postId: string) {
  if (!supabase || !hasSupabaseConfig || !isUuidLike(postId)) return;
  const { error } = await supabase
    .from("groom_hidden_posts")
    .upsert(
      {
        groom_post_id: postId,
        user_id: currentUserId,
      },
      { onConflict: "user_id,groom_post_id" },
    );
  if (error) throw error;
}

export async function reportGroomPost(
  currentUserId: string,
  postId: string,
  reportedUserId: string,
  reason: "spam" | "harassment" | "privacy" | "other" = "other",
) {
  if (
    !supabase ||
    !hasSupabaseConfig ||
    !isUuidLike(postId) ||
    !isUuidLike(reportedUserId) ||
    currentUserId === reportedUserId
  ) {
    return;
  }
  const { error } = await supabase.from("groom_reports").insert({
    groom_post_id: postId,
    reason,
    reported_user_id: reportedUserId,
    reporter_id: currentUserId,
  });
  if (error && error.code !== "23505") throw error;
}

export async function blockGroomUser(currentUserId: string, blockedUserId: string) {
  if (
    !supabase ||
    !hasSupabaseConfig ||
    !isUuidLike(blockedUserId) ||
    currentUserId === blockedUserId
  ) {
    return;
  }
  const { error } = await supabase
    .from("groom_user_blocks")
    .upsert(
      {
        blocked_id: blockedUserId,
        blocker_id: currentUserId,
      },
      { onConflict: "blocker_id,blocked_id" },
    );
  if (error) throw error;
}

export async function setGroomPostLiked(
  currentUserId: string,
  postId: string,
  liked: boolean,
) {
  if (!supabase || !hasSupabaseConfig || !isUuidLike(postId)) return;
  if (liked) {
    const { error } = await supabase
      .from("groom_reactions")
      .upsert(
        {
          groom_post_id: postId,
          reaction_type: "like",
          user_id: currentUserId,
        },
        { onConflict: "groom_post_id,user_id,reaction_type" },
      );
    if (error) throw error;
    return;
  }

  const { error } = await supabase
    .from("groom_reactions")
    .delete()
    .eq("groom_post_id", postId)
    .eq("user_id", currentUserId)
    .eq("reaction_type", "like");
  if (error) throw error;
}

export async function markGroomPostViewed(currentUserId: string, postId: string) {
  if (!supabase || !hasSupabaseConfig || !isUuidLike(postId)) return;
  const { error } = await supabase
    .from("groom_views")
    .upsert(
      {
        groom_post_id: postId,
        user_id: currentUserId,
        viewed_at: new Date().toISOString(),
      },
      { onConflict: "groom_post_id,user_id" },
    );
  if (error) throw error;
}

async function fetchGroomReactionIds(currentUserId: string, postIds: string[]) {
  if (!supabase || postIds.length === 0) return new Set<string>();
  const { data, error } = await supabase
    .from("groom_reactions")
    .select("groom_post_id")
    .eq("user_id", currentUserId)
    .eq("reaction_type", "like")
    .in("groom_post_id", postIds);
  if (error) throw error;
  return new Set((Array.isArray(data) ? data : []).map((row) => stringValue(row.groom_post_id)));
}

async function fetchGroomViewIds(currentUserId: string, postIds: string[]) {
  if (!supabase || postIds.length === 0) return new Set<string>();
  const { data, error } = await supabase
    .from("groom_views")
    .select("groom_post_id")
    .eq("user_id", currentUserId)
    .in("groom_post_id", postIds);
  if (error) throw error;
  return new Set((Array.isArray(data) ? data : []).map((row) => stringValue(row.groom_post_id)));
}

async function uploadGroomImage(
  currentUserId: string,
  uri: string,
  base64?: string | null,
  base64ContentType?: string | null,
) {
  if (!supabase) throw new Error("Supabase is not configured.");
  if (/^https?:\/\//i.test(uri)) {
    return { path: null, storedUrl: uri };
  }

  const imageBody = base64
    ? {
        body: base64ToArrayBuffer(base64),
        contentType: contentTypeForUri(uri, base64ContentType ?? null),
      }
    : await readLocalImageWithFetch(uri);
  if (imageBody.body.byteLength > GROOM_MAX_UPLOAD_BYTES) {
    throw new Error("画像サイズが大きすぎます。別の写真を選ぶか、少し小さくしてから投稿してください。");
  }
  const contentType = imageBody.contentType;
  const extension = extensionForContentType(contentType);
  const path = `${currentUserId}/${Date.now()}_${Math.random().toString(36).slice(2)}.${extension}`;
  const { error } = await supabase.storage
    .from(GROOM_BUCKET)
    .upload(path, imageBody.body, {
      contentType,
      upsert: false,
    });
  if (error) throw error;
  return { path, storedUrl: path };
}

async function readLocalImageWithFetch(uri: string) {
  try {
    const response = await fetch(uri);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    return {
      body: await response.arrayBuffer(),
      contentType: contentTypeForUri(uri, response.headers.get("content-type")),
    };
  } catch (error) {
    throw new Error(
      `グルーム画像を読み込めませんでした。もう一度撮影するか、アルバムから選び直してください。${error instanceof Error ? ` (${error.message})` : ""}`,
    );
  }
}

async function buildGroomAudience(currentUserId: string) {
  if (!supabase) return { areaKey: null, userIds: [] as string[] };
  const { data: profile } = await supabase
    .from("users")
    .select("primary_area")
    .eq("id", currentUserId)
    .maybeSingle();
  const areaKey =
    typeof (profile as Record<string, unknown> | null | undefined)?.primary_area === "string"
      ? ((profile as Record<string, unknown>).primary_area as string)
      : null;
  let rpcIds: string[] = [];
  try {
    const { data } = await supabase.rpc("groom_audience_for_user", { author_id: currentUserId });
    rpcIds = Array.isArray(data)
      ? data.filter((id: unknown): id is string => typeof id === "string" && isUuidLike(id))
      : [];
  } catch {
    rpcIds = [];
  }
  if (rpcIds.length > 0 || !areaKey) return { areaKey, userIds: rpcIds };

  const { data } = await supabase
    .from("users")
    .select("id")
    .eq("primary_area", areaKey)
    .eq("account_status", "active")
    .neq("id", currentUserId)
    .limit(200);
  const userIds = (Array.isArray(data) ? data : [])
    .map((row) => stringValue((row as Record<string, unknown>).id))
    .filter(isUuidLike);
  return { areaKey, userIds };
}

async function signGroomImageUrls(rows: Record<string, unknown>[]) {
  if (!supabase || rows.length === 0) return new Map<string, string>();
  const paths = Array.from(
    new Set(rows.map((row) => stringValue(row.image_path)).filter((path) => path.length > 0)),
  );
  if (paths.length === 0) return new Map<string, string>();
  const { data, error } = await supabase.storage
    .from(GROOM_BUCKET)
    .createSignedUrls(paths, 60 * 60);
  if (error) throw error;
  const signed = new Map<string, string>();
  for (const item of data ?? []) {
    if (item.path && item.signedUrl) signed.set(item.path, item.signedUrl);
  }
  return signed;
}

function normalizeRemotePost(
  row: Record<string, unknown>,
  currentUserId: string,
  likedIds: Set<string>,
  viewedIds: Set<string>,
  signedUrls: Map<string, string>,
  imageUrlFallback?: string,
): GroomRemotePost | null {
  const id = stringValue(row.id);
  const userId = stringValue(row.user_id);
  const imagePath = nullableStringValue(row.image_path);
  const imageUrl =
    (imagePath ? signedUrls.get(imagePath) : null) ?? imageUrlFallback ?? stringValue(row.image_url);
  const publishedAt = stringValue(row.published_at);
  const expiresAt = stringValue(row.expires_at);
  if (!id || !userId || !imageUrl || !publishedAt || !expiresAt) return null;
  const userRow = objectValue(row.users);
  return {
    audienceScope: stringValue(row.audience_scope) || "encountered_people",
    author: {
      avatarUrl: nullableStringValue(userRow.avatar_url),
      displayName:
        stringValue(userRow.display_name) || stringValue(userRow.handle) || "めぐりユーザー",
      handle: nullableStringValue(userRow.handle),
      id: userId,
      primaryArea: nullableStringValue(userRow.primary_area),
    },
    caption: stringValue(row.caption),
    doodles: arrayValue(row.doodles),
    expiresAt,
    id,
    imagePath,
    imageTransform: imageTransformValue(row.image_transform),
    imageUrl,
    liked: likedIds.has(id),
    mine: userId === currentUserId,
    placeHint: stringValue(row.place_hint) || "同じイベント圏内",
    publishedAt,
    stickers: arrayValue(row.stickers),
    textOverlays: arrayValue(row.text_overlays),
    viewed: viewedIds.has(id),
  };
}

function contentTypeForUri(uri: string, header: string | null) {
  if (header === "image/jpeg" || header === "image/png" || header === "image/webp") return header;
  const lower = uri.toLowerCase();
  if (lower.includes(".png")) return "image/png";
  if (lower.includes(".webp")) return "image/webp";
  return "image/jpeg";
}

function extensionForContentType(contentType: string) {
  if (contentType.includes("png")) return "png";
  if (contentType.includes("webp")) return "webp";
  return "jpg";
}

function base64ToArrayBuffer(value: string) {
  const clean = value
    .replace(/^data:[^;]+;base64,/, "")
    .replace(/[\r\n\s]/g, "");
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  const padding = clean.endsWith("==") ? 2 : clean.endsWith("=") ? 1 : 0;
  const byteLength = Math.floor((clean.length * 3) / 4) - padding;
  const bytes = new Uint8Array(byteLength);
  let buffer = 0;
  let bits = 0;
  let index = 0;

  for (let i = 0; i < clean.length; i += 1) {
    const char = clean[i];
    if (char === "=") break;
    const value = alphabet.indexOf(char);
    if (value < 0) continue;
    buffer = (buffer << 6) | value;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      if (index < byteLength) {
        bytes[index] = (buffer >> bits) & 0xff;
        index += 1;
      }
    }
  }

  return bytes.buffer;
}

function imageTransformValue(value: unknown): GroomRemoteImageTransform {
  const next = objectValue(value);
  return {
    rotation: numberValue(next.rotation, 0),
    scale: numberValue(next.scale, 1),
    x: numberValue(next.x, 0),
    y: numberValue(next.y, 0),
  };
}

function objectValue(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return value as Record<string, unknown>;
}

function arrayValue(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
}

function stringValue(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function nullableStringValue(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

function numberValue(value: unknown, fallback: number) {
  return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}
