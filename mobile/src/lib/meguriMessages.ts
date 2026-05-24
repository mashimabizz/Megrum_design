import AsyncStorage from "@react-native-async-storage/async-storage";
import { hasSupabaseConfig, supabase } from "./supabase";
import { isUuidLike } from "./groom";

export type MeguriMessageReadState = Record<string, string[]>;

export type MeguriGroomReply = {
  id: string;
  body: string;
  groomCaption?: string;
  groomId: string;
  groomImagePath?: string | null;
  groomImageUri: string;
  mine?: boolean;
  readAt?: number | null;
  recipientId: string;
  recipientName: string;
  sentAt: number;
};

export type MeguriThreadMessage = {
  id: string;
  body: string;
  groomReplyId?: string | null;
  imagePath?: string | null;
  imageUri?: string;
  mine?: boolean;
  peerId: string;
  peerName: string;
  readAt?: number | null;
  sentAt: number;
};

type MeguriLetterLike = {
  id: string;
  opened: boolean;
};

const READ_STATE_KEY = "meguri.message.read.v1";
const GROOM_REPLIES_KEY = "meguri.groom.replies.v1";
const THREAD_MESSAGES_KEY = "meguri.thread.messages.v1";
const GROOM_BUCKET = "groom-posts";
const MEGURI_MESSAGE_BUCKET = "meguri-message-media";

export function getMeguriIncomingMessageIds(letterId: string) {
  return [`${letterId}-hello`, `${letterId}-body`];
}

export function unreadMeguriMessageCount(
  letter: MeguriLetterLike,
  readState: MeguriMessageReadState,
) {
  const incomingIds = getMeguriIncomingMessageIds(letter.id);
  const readIds = new Set([
    ...(letter.opened ? incomingIds : []),
    ...(readState[letter.id] ?? []),
  ]);
  return incomingIds.filter((id) => !readIds.has(id)).length;
}

export async function loadMeguriMessageReadState(): Promise<MeguriMessageReadState> {
  const raw = await AsyncStorage.getItem(READ_STATE_KEY);
  if (!raw) return {};
  try {
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return {};
    return Object.fromEntries(
      Object.entries(parsed).map(([letterId, value]) => [
        letterId,
        Array.isArray(value)
          ? value.filter((messageId): messageId is string => typeof messageId === "string")
          : [],
      ]),
    );
  } catch {
    return {};
  }
}

export async function markMeguriLetterRead(letterId: string) {
  const current = await loadMeguriMessageReadState();
  const incomingIds = getMeguriIncomingMessageIds(letterId);
  const next = {
    ...current,
    [letterId]: Array.from(new Set([...(current[letterId] ?? []), ...incomingIds])),
  };
  await AsyncStorage.setItem(READ_STATE_KEY, JSON.stringify(next));
  return next;
}

export async function loadMeguriGroomReplies(): Promise<MeguriGroomReply[]> {
  const [local, remote] = await Promise.all([
    loadLocalMeguriGroomReplies(),
    loadRemoteMeguriGroomReplies().catch(() => []),
  ]);
  return dedupeGroomReplies([...local, ...remote]);
}

export async function markMeguriGroomRepliesRead(peerId: string) {
  if (!supabase || !hasSupabaseConfig || !isUuidLike(peerId)) return;
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return;
  await supabase
    .from("groom_replies")
    .update({ read_at: new Date().toISOString() })
    .eq("recipient_id", user.id)
    .eq("sender_id", peerId)
    .is("read_at", null);
}

export async function loadMeguriThreadMessages(): Promise<MeguriThreadMessage[]> {
  const [local, remote] = await Promise.all([
    loadLocalMeguriThreadMessages(),
    loadRemoteMeguriThreadMessages().catch(() => []),
  ]);
  return dedupeThreadMessages([...local, ...remote]);
}

export async function markMeguriThreadMessagesRead(peerId: string) {
  if (!supabase || !hasSupabaseConfig || !isUuidLike(peerId)) return;
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return;
  await supabase
    .from("meguri_messages")
    .update({ read_at: new Date().toISOString() })
    .eq("recipient_id", user.id)
    .eq("sender_id", peerId)
    .is("read_at", null);
}

export async function appendMeguriThreadMessage(
  input: Omit<MeguriThreadMessage, "id" | "mine" | "sentAt"> & {
    id?: string;
    sentAt?: number;
  },
) {
  const remote = await appendRemoteMeguriThreadMessage(input).catch(() => null);
  if (remote) {
    await storeLocalThreadMessage(remote);
    return remote;
  }
  const nextMessage: MeguriThreadMessage = {
    ...input,
    body: input.body || (input.imageUri ? "画像を送信しました" : ""),
    id: input.id ?? `meguri-thread-${Date.now()}`,
    mine: true,
    sentAt: input.sentAt ?? Date.now(),
  };
  await storeLocalThreadMessage(nextMessage);
  return nextMessage;
}

async function loadLocalMeguriGroomReplies(): Promise<MeguriGroomReply[]> {
  const raw = await AsyncStorage.getItem(GROOM_REPLIES_KEY);
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(isMeguriGroomReply);
  } catch {
    return [];
  }
}

async function loadLocalMeguriThreadMessages(): Promise<MeguriThreadMessage[]> {
  const raw = await AsyncStorage.getItem(THREAD_MESSAGES_KEY);
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(isMeguriThreadMessage);
  } catch {
    return [];
  }
}

export async function appendMeguriGroomReply(
  input: Omit<MeguriGroomReply, "id" | "sentAt"> & {
    id?: string;
    sentAt?: number;
  },
) {
  const remote = await appendRemoteMeguriGroomReply(input).catch(() => null);
  if (remote) {
    await storeLocalGroomReply(remote);
    return remote;
  }
  const nextReply: MeguriGroomReply = {
    ...input,
    id: input.id ?? `groom-reply-${Date.now()}`,
    mine: true,
    sentAt: input.sentAt ?? Date.now(),
  };
  await storeLocalGroomReply(nextReply);
  return nextReply;
}

async function storeLocalGroomReply(nextReply: MeguriGroomReply) {
  const current = await loadLocalMeguriGroomReplies();
  const next = [...current.filter((reply) => reply.id !== nextReply.id), nextReply]
    .sort((a, b) => a.sentAt - b.sentAt)
    .slice(-80);
  await AsyncStorage.setItem(GROOM_REPLIES_KEY, JSON.stringify(next));
}

async function storeLocalThreadMessage(nextMessage: MeguriThreadMessage) {
  const current = await loadLocalMeguriThreadMessages();
  const next = [...current.filter((message) => message.id !== nextMessage.id), nextMessage]
    .sort((a, b) => a.sentAt - b.sentAt)
    .slice(-200);
  await AsyncStorage.setItem(THREAD_MESSAGES_KEY, JSON.stringify(next));
}

async function loadRemoteMeguriGroomReplies(): Promise<MeguriGroomReply[]> {
  if (!supabase || !hasSupabaseConfig) return [];
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return [];
  const { data, error } = await supabase
    .from("groom_replies")
    .select(
      [
        "id",
        "groom_post_id",
        "sender_id",
        "recipient_id",
        "body",
        "groom_snapshot",
        "read_at",
        "created_at",
        "sender:users!groom_replies_sender_id_fkey(id, display_name, handle)",
        "recipient:users!groom_replies_recipient_id_fkey(id, display_name, handle)",
      ].join(", "),
    )
    .or(`sender_id.eq.${user.id},recipient_id.eq.${user.id}`)
    .order("created_at", { ascending: true })
    .limit(120);
  if (error) throw error;
  const rows = (Array.isArray(data) ? data : []) as unknown as Record<string, unknown>[];
  const signedUrls = await signSnapshotImageUrls(rows);
  return rows
    .map((row) => remoteGroomReplyToLocal(row, user.id, signedUrls))
    .filter((reply): reply is MeguriGroomReply => !!reply);
}

async function loadRemoteMeguriThreadMessages(): Promise<MeguriThreadMessage[]> {
  if (!supabase || !hasSupabaseConfig) return [];
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return [];
  const { data, error } = await supabase
    .from("meguri_messages")
    .select(
      [
        "id",
        "sender_id",
        "recipient_id",
        "source_groom_reply_id",
        "body",
        "image_url",
        "image_path",
        "read_at",
        "created_at",
        "sender:users!meguri_messages_sender_id_fkey(id, display_name, handle)",
        "recipient:users!meguri_messages_recipient_id_fkey(id, display_name, handle)",
      ].join(", "),
    )
    .or(`sender_id.eq.${user.id},recipient_id.eq.${user.id}`)
    .order("created_at", { ascending: true })
    .limit(240);
  if (error) throw error;
  const rows = (Array.isArray(data) ? data : []) as unknown as Record<string, unknown>[];
  const signedUrls = await signStorageUrls(
    MEGURI_MESSAGE_BUCKET,
    rows.map((row) => stringValue(row.image_path)).filter(Boolean),
  );
  return rows
    .map((row) => remoteThreadMessageToLocal(row, user.id, signedUrls))
    .filter((message): message is MeguriThreadMessage => !!message);
}

async function appendRemoteMeguriGroomReply(
  input: Omit<MeguriGroomReply, "id" | "sentAt"> & {
    id?: string;
    sentAt?: number;
  },
): Promise<MeguriGroomReply | null> {
  if (
    !supabase ||
    !hasSupabaseConfig ||
    !isUuidLike(input.groomId) ||
    !isUuidLike(input.recipientId)
  ) {
    return null;
  }
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user || user.id === input.recipientId) return null;
  const snapshot = {
    caption: input.groomCaption ?? "",
    image_path: input.groomImagePath ?? null,
    image_url: input.groomImageUri,
  };
  const { data, error } = await supabase
    .from("groom_replies")
    .insert({
      body: input.body,
      groom_post_id: input.groomId,
      groom_snapshot: snapshot,
      recipient_id: input.recipientId,
      sender_id: user.id,
    })
    .select(
      [
        "id",
        "groom_post_id",
        "sender_id",
        "recipient_id",
        "body",
        "groom_snapshot",
        "read_at",
        "created_at",
        "sender:users!groom_replies_sender_id_fkey(id, display_name, handle)",
        "recipient:users!groom_replies_recipient_id_fkey(id, display_name, handle)",
      ].join(", "),
    )
    .single();
  if (error) throw error;

  const reply = remoteGroomReplyToLocal(data as unknown as Record<string, unknown>, user.id);
  if (!reply) return null;
  const { error: notificationError } = await supabase
    .from("notifications")
    .insert({
      body: input.body.slice(0, 120),
      groom_reply_id: reply.id,
      kind: "groom_reply",
      link_path: `/meguri-letters?open=1&userId=${user.id}`,
      title: "グルームに返信が届きました",
      user_id: input.recipientId,
    });
  if (notificationError) {
    console.warn("Failed to create groom reply notification", notificationError.message);
  }
  return reply;
}

async function appendRemoteMeguriThreadMessage(
  input: Omit<MeguriThreadMessage, "id" | "mine" | "sentAt"> & {
    id?: string;
    sentAt?: number;
  },
): Promise<MeguriThreadMessage | null> {
  if (!supabase || !hasSupabaseConfig || !isUuidLike(input.peerId)) return null;
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user || user.id === input.peerId) return null;

  const uploaded =
    input.imageUri && !/^https?:\/\//i.test(input.imageUri)
      ? await uploadMeguriMessageImage(user.id, input.imageUri)
      : null;
  const imagePath = uploaded?.path ?? input.imagePath ?? null;
  const imageUrl = uploaded?.storedUrl ?? input.imageUri ?? null;
  const body = input.body || (imagePath ? "画像を送信しました" : "");
  if (!body && !imagePath) return null;

  const { data, error } = await supabase
    .from("meguri_messages")
    .insert({
      body,
      image_path: imagePath,
      image_url: imageUrl,
      message_type: imagePath ? "image" : "text",
      recipient_id: input.peerId,
      sender_id: user.id,
      source_groom_reply_id: input.groomReplyId ?? null,
    })
    .select(
      [
        "id",
        "sender_id",
        "recipient_id",
        "source_groom_reply_id",
        "body",
        "image_url",
        "image_path",
        "read_at",
        "created_at",
        "sender:users!meguri_messages_sender_id_fkey(id, display_name, handle)",
        "recipient:users!meguri_messages_recipient_id_fkey(id, display_name, handle)",
      ].join(", "),
    )
    .single();
  if (error) {
    if (uploaded?.path) {
      await supabase.storage.from(MEGURI_MESSAGE_BUCKET).remove([uploaded.path]).catch(() => undefined);
    }
    throw error;
  }
  const row = data as unknown as Record<string, unknown>;
  const signedUrls = await signStorageUrls(MEGURI_MESSAGE_BUCKET, [stringValue(row.image_path)]);
  const message = remoteThreadMessageToLocal(row, user.id, signedUrls);
  if (!message) return null;
  const { error: notificationError } = await supabase.from("notifications").insert({
    body: message.body.slice(0, 120),
    kind: "meguri_message",
    link_path: `/meguri-letters?open=1&userId=${user.id}`,
    meguri_message_id: message.id,
    title: "めぐりあいメッセージが届きました",
    user_id: input.peerId,
  });
  if (notificationError) {
    console.warn("Failed to create meguri message notification", notificationError.message);
  }
  return message;
}

function isMeguriGroomReply(value: unknown): value is MeguriGroomReply {
  if (!value || typeof value !== "object") return false;
  const reply = value as Partial<MeguriGroomReply>;
  return (
    typeof reply.id === "string" &&
    typeof reply.body === "string" &&
    typeof reply.groomId === "string" &&
    typeof reply.groomImageUri === "string" &&
    typeof reply.recipientId === "string" &&
    typeof reply.recipientName === "string" &&
    typeof reply.sentAt === "number"
  );
}

function isMeguriThreadMessage(value: unknown): value is MeguriThreadMessage {
  if (!value || typeof value !== "object") return false;
  const message = value as Partial<MeguriThreadMessage>;
  return (
    typeof message.id === "string" &&
    typeof message.body === "string" &&
    typeof message.peerId === "string" &&
    typeof message.peerName === "string" &&
    typeof message.sentAt === "number"
  );
}

function remoteGroomReplyToLocal(
  row: Record<string, unknown>,
  currentUserId: string,
  signedUrls = new Map<string, string>(),
): MeguriGroomReply | null {
  const id = stringValue(row.id);
  const groomId = stringValue(row.groom_post_id);
  const senderId = stringValue(row.sender_id);
  const recipientId = stringValue(row.recipient_id);
  const body = stringValue(row.body);
  const createdAt = stringValue(row.created_at);
  if (!id || !groomId || !senderId || !recipientId || !body || !createdAt) return null;
  const mine = senderId === currentUserId;
  const peerId = mine ? recipientId : senderId;
  const peer = objectValue(mine ? row.recipient : row.sender);
  const snapshot = objectValue(row.groom_snapshot);
  const imagePath = nullableStringValue(snapshot.image_path);
  return {
    body,
    groomCaption: stringValue(snapshot.caption),
    groomId,
    groomImagePath: imagePath,
    groomImageUri: (imagePath ? signedUrls.get(imagePath) : null) ?? stringValue(snapshot.image_url),
    id,
    mine,
    readAt: row.read_at ? Date.parse(stringValue(row.read_at)) || null : null,
    recipientId: peerId,
    recipientName: stringValue(peer.display_name) || stringValue(peer.handle) || "めぐりユーザー",
    sentAt: Date.parse(createdAt) || Date.now(),
  };
}

function remoteThreadMessageToLocal(
  row: Record<string, unknown>,
  currentUserId: string,
  signedUrls = new Map<string, string>(),
): MeguriThreadMessage | null {
  const id = stringValue(row.id);
  const senderId = stringValue(row.sender_id);
  const recipientId = stringValue(row.recipient_id);
  const body = stringValue(row.body);
  const createdAt = stringValue(row.created_at);
  if (!id || !senderId || !recipientId || !createdAt) return null;
  const mine = senderId === currentUserId;
  const peerId = mine ? recipientId : senderId;
  const peer = objectValue(mine ? row.recipient : row.sender);
  const imagePath = nullableStringValue(row.image_path);
  return {
    body,
    groomReplyId: nullableStringValue(row.source_groom_reply_id),
    id,
    imagePath,
    imageUri: (imagePath ? signedUrls.get(imagePath) : null) ?? nullableStringValue(row.image_url) ?? undefined,
    mine,
    peerId,
    peerName: stringValue(peer.display_name) || stringValue(peer.handle) || "めぐりユーザー",
    readAt: row.read_at ? Date.parse(stringValue(row.read_at)) || null : null,
    sentAt: Date.parse(createdAt) || Date.now(),
  };
}

function dedupeGroomReplies(replies: MeguriGroomReply[]) {
  const byId = new Map<string, MeguriGroomReply>();
  for (const reply of replies) byId.set(reply.id, reply);
  return Array.from(byId.values()).sort((a, b) => a.sentAt - b.sentAt);
}

function dedupeThreadMessages(messages: MeguriThreadMessage[]) {
  const byId = new Map<string, MeguriThreadMessage>();
  for (const message of messages) byId.set(message.id, message);
  return Array.from(byId.values()).sort((a, b) => a.sentAt - b.sentAt);
}

async function uploadMeguriMessageImage(currentUserId: string, uri: string) {
  if (!supabase) throw new Error("Supabase is not configured.");
  const response = await fetch(uri);
  if (!response.ok) {
    throw new Error("めぐりあいメッセージ画像を読み込めませんでした");
  }
  const arrayBuffer = await response.arrayBuffer();
  const contentType = contentTypeForUri(uri, response.headers.get("content-type"));
  const extension = extensionForContentType(contentType);
  const path = `${currentUserId}/${Date.now()}_${Math.random().toString(36).slice(2)}.${extension}`;
  const { error } = await supabase.storage
    .from(MEGURI_MESSAGE_BUCKET)
    .upload(path, arrayBuffer, {
      contentType,
      upsert: false,
    });
  if (error) throw error;
  return { path, storedUrl: path };
}

async function signSnapshotImageUrls(rows: Record<string, unknown>[]) {
  const paths = rows
    .map((row) => nullableStringValue(objectValue(row.groom_snapshot).image_path))
    .filter((path): path is string => !!path);
  return signStorageUrls(GROOM_BUCKET, paths);
}

async function signStorageUrls(bucket: string, rawPaths: string[]) {
  if (!supabase) return new Map<string, string>();
  const paths = Array.from(new Set(rawPaths.filter((path) => path.length > 0)));
  if (paths.length === 0) return new Map<string, string>();
  const { data, error } = await supabase.storage.from(bucket).createSignedUrls(paths, 60 * 60);
  if (error) throw error;
  const signed = new Map<string, string>();
  for (const item of data ?? []) {
    if (item.path && item.signedUrl) signed.set(item.path, item.signedUrl);
  }
  return signed;
}

function contentTypeForUri(uri: string, header: string | null) {
  if (header?.startsWith("image/")) return header;
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

function objectValue(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return value as Record<string, unknown>;
}

function stringValue(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function nullableStringValue(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}
