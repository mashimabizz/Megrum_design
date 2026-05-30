import { useEffect, useMemo, useState } from "react";
import { router } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { RouteHeader } from "../../src/components/RouteHeader";
import { Screen } from "../../src/components/Screen";
import { useAuth } from "../../src/auth/AuthProvider";
import { IconSymbol, type IconSymbolName } from "../../src/components/IconSymbol";
import { routeFromNotificationLinkPath } from "../../src/lib/notificationRoutes";
import { setMobileNotificationBadgeCount } from "../../src/lib/notifications";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

type NotificationKind =
  | "proposal_received"
  | "proposal_accepted"
  | "proposal_rejected"
  | "proposal_revised"
  | "evidence_added"
  | "trade_completed"
  | "evaluation_received"
  | "dispute_received"
  | "dispute_responded"
  | "dispute_closed"
  | "cancel_requested"
  | "expires_soon"
  | "groom_reply"
  | "meguri_message"
  | "meguri_board_reply"
  | "meguri_board_mention";

type NotificationItem = {
  id: string;
  kind: NotificationKind;
  title: string;
  body: string | null;
  linkPath: string | null;
  readAt: string | null;
  createdAt: string;
};

type Tone = "lavender" | "ok" | "warn" | "amber" | "mute";
type NotificationFilter = "all" | "unread" | "trades";

const KIND_ICON: Record<NotificationKind, IconSymbolName> = {
  proposal_received: "mail-unread-outline",
  proposal_accepted: "checkmark-circle-outline",
  proposal_rejected: "close-circle-outline",
  proposal_revised: "create-outline",
  evidence_added: "camera-outline",
  trade_completed: "sparkles-outline",
  evaluation_received: "star-outline",
  dispute_received: "warning-outline",
  dispute_responded: "scale-outline",
  dispute_closed: "shield-checkmark-outline",
  cancel_requested: "ban-outline",
  expires_soon: "time-outline",
  groom_reply: "mail-outline",
  meguri_message: "mail-outline",
  meguri_board_reply: "notifications-outline",
  meguri_board_mention: "notifications-outline",
};

const KIND_TONE: Record<NotificationKind, Tone> = {
  proposal_received: "lavender",
  proposal_accepted: "ok",
  proposal_rejected: "mute",
  proposal_revised: "lavender",
  evidence_added: "lavender",
  trade_completed: "ok",
  evaluation_received: "amber",
  dispute_received: "warn",
  dispute_responded: "warn",
  dispute_closed: "lavender",
  cancel_requested: "warn",
  expires_soon: "amber",
  groom_reply: "lavender",
  meguri_message: "lavender",
  meguri_board_reply: "lavender",
  meguri_board_mention: "amber",
};

const PREVIEW_NOTIFICATIONS: NotificationItem[] = [
  {
    id: "preview-notification-1",
    kind: "proposal_received",
    title: "新しい打診が届いています",
    body: "スア 春ver. トレカについて交換の打診があります。",
    linkPath: "/proposals/preview",
    readAt: null,
    createdAt: new Date(Date.now() - 1000 * 60 * 18).toISOString(),
  },
  {
    id: "preview-notification-2",
    kind: "expires_soon",
    title: "返信期限が近づいています",
    body: "相手待ちの打診を確認してください。",
    linkPath: "/proposals/preview",
    readAt: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),
    createdAt: new Date(Date.now() - 1000 * 60 * 60 * 8).toISOString(),
  },
  {
    id: "preview-notification-3",
    kind: "meguri_board_reply",
    title: "購読中のスレッドに返信がありました",
    body: "みち: 物販列は今だと20分くらいです。",
    linkPath: "/meguri-board-thread?id=preview-board-thread-1&viewMode=nearby_3km",
    readAt: null,
    createdAt: new Date(Date.now() - 1000 * 60 * 7).toISOString(),
  },
  {
    id: "preview-notification-4",
    kind: "meguri_board_mention",
    title: "返信でメンションされました",
    body: "ゆい: @preview_hana 25ゲート側の列、見えますか？",
    linkPath: "/meguri-board-thread?id=preview-board-thread-1&viewMode=nearby_3km",
    readAt: null,
    createdAt: new Date(Date.now() - 1000 * 60 * 3).toISOString(),
  },
];

const TRADE_NOTIFICATION_KINDS = new Set<NotificationKind>([
  "proposal_received",
  "proposal_accepted",
  "proposal_rejected",
  "proposal_revised",
  "evidence_added",
  "trade_completed",
  "evaluation_received",
  "dispute_received",
  "dispute_responded",
  "dispute_closed",
  "cancel_requested",
  "expires_soon",
]);

const FILTER_TABS: { key: NotificationFilter; label: string }[] = [
  { key: "all", label: "すべて" },
  { key: "unread", label: "未読" },
  { key: "trades", label: "取引" },
];

export default function NotificationsScreen() {
  const { previewMode, user } = useAuth();
  const [items, setItems] = useState<NotificationItem[]>(() =>
    !supabase || previewMode ? PREVIEW_NOTIFICATIONS : [],
  );
  const [loading, setLoading] = useState(!!supabase && !previewMode);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const [filter, setFilter] = useState<NotificationFilter>("all");

  useEffect(() => {
    if (!supabase || previewMode) {
      setItems(PREVIEW_NOTIFICATIONS);
      setLoading(false);
      setError(null);
      return;
    }
    if (!user) {
      setItems([]);
      setLoading(false);
      setError(null);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);
    fetchNotifications(user.id)
      .then((next) => {
        if (active) setItems(next);
      })
      .catch((reason: unknown) => {
        if (!active) return;
        setError(reason instanceof Error ? reason.message : "通知を読み込めませんでした");
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, user]);

  const unreadCount = useMemo(() => items.filter((item) => !item.readAt).length, [items]);
  const visibleItems = useMemo(() => {
    if (filter === "unread") return items.filter((item) => !item.readAt);
    if (filter === "trades") return items.filter((item) => TRADE_NOTIFICATION_KINDS.has(item.kind));
    return items;
  }, [filter, items]);

  useEffect(() => {
    void setMobileNotificationBadgeCount(unreadCount);
  }, [unreadCount]);

  async function markAllRead() {
    const readAt = new Date().toISOString();
    setItems((current) => current.map((item) => ({ ...item, readAt: item.readAt ?? readAt })));
    if (!supabase || !user || previewMode) return;
    setPending(true);
    const { error } = await supabase
      .from("notifications")
      .update({ read_at: readAt })
      .eq("user_id", user.id)
      .is("read_at", null);
    setPending(false);
    if (error) setError(error.message);
  }

  async function handleTap(item: NotificationItem) {
    const readAt = new Date().toISOString();
    if (!item.readAt) {
      setItems((current) =>
        current.map((next) => (next.id === item.id ? { ...next, readAt } : next)),
      );
      if (supabase && user && !previewMode) {
        supabase
          .from("notifications")
          .update({ read_at: readAt })
          .eq("id", item.id)
          .eq("user_id", user.id)
          .then(({ error }) => {
            if (error) setError(error.message);
          });
      }
    }
    const route = routeFromNotificationLinkPath(item.linkPath);
    if (route) router.push(route);
  }

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader
        title="通知"
        subtitle={
          unreadCount > 0
            ? `未読 ${unreadCount} 件 / 全 ${items.length} 件`
            : `全 ${items.length} 件 すべて既読`
        }
        right={
          unreadCount > 0 ? (
            <Pressable
              accessibilityRole="button"
              disabled={pending}
              onPress={markAllRead}
              style={styles.markAllButton}
            >
              <Text style={styles.markAllText}>既読</Text>
            </Pressable>
          ) : null
        }
      />
      <View style={styles.tabBar}>
        {FILTER_TABS.map((tab) => {
          const selected = filter === tab.key;
          const badge =
            tab.key === "unread"
              ? unreadCount
              : tab.key === "all"
                ? items.length
                : items.filter((item) => TRADE_NOTIFICATION_KINDS.has(item.kind)).length;
          return (
            <Pressable
              accessibilityRole="button"
              key={tab.key}
              onPress={() => setFilter(tab.key)}
              style={({ pressed }) => [
                styles.tabButton,
                selected ? styles.tabButtonSelected : null,
                pressed ? styles.pressed : null,
              ]}
            >
              <Text style={[styles.tabText, selected ? styles.tabTextSelected : null]}>
                {tab.label}
              </Text>
              {badge > 0 ? (
                <Text style={[styles.tabBadge, selected ? styles.tabBadgeSelected : null]}>
                  {badge}
                </Text>
              ) : null}
            </Pressable>
          );
        })}
      </View>
      {loading ? <Text style={styles.loadingText}>通知を読み込み中…</Text> : null}
      {error ? <Text style={styles.inlineError}>{error}</Text> : null}
      {visibleItems.length === 0 ? (
        <View style={styles.emptyBox}>
          <Text style={styles.emptyTitle}>
            {filter === "unread" ? "未読の通知はありません" : "まだ通知はありません"}
          </Text>
          <Pressable onPress={() => router.replace("/")}>
            <Text style={styles.emptyLink}>ホームに戻る →</Text>
          </Pressable>
        </View>
      ) : (
        <View style={styles.list}>
          {visibleItems.map((item) => (
            <NotificationCard key={item.id} item={item} onPress={() => handleTap(item)} />
          ))}
        </View>
      )}
    </Screen>
  );
}

function NotificationCard({
  item,
  onPress,
}: {
  item: NotificationItem;
  onPress: () => void;
}) {
  const unread = !item.readAt;
  const tone = KIND_TONE[item.kind];
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.row,
        unread ? styles.rowUnread : null,
        pressed ? styles.pressed : null,
      ]}
    >
      <View style={styles.rowInner}>
        <View style={styles.iconRail}>
          <View style={[styles.iconBox, toneStyle(tone)]}>
            <IconSymbol name={KIND_ICON[item.kind]} size={20} color={toneColor(tone)} />
          </View>
        </View>
        <View style={styles.rowCopy}>
          <View style={styles.cardTop}>
            <Text numberOfLines={1} style={[styles.cardTitle, unread ? styles.cardTitleUnread : null]}>
              {item.title}
            </Text>
            <Text style={styles.timeText}>{formatRelative(item.createdAt)}</Text>
          </View>
          {item.body ? (
            <Text numberOfLines={3} style={styles.bodyText}>
              {item.body}
            </Text>
          ) : null}
          <View style={styles.rowDivider} />
        </View>
        {unread ? <View style={styles.unreadDot} /> : null}
      </View>
    </Pressable>
  );
}

async function fetchNotifications(userId: string): Promise<NotificationItem[]> {
  if (!supabase) return [];
  const { data, error } = await supabase
    .from("notifications")
    .select("id, kind, title, body, link_path, read_at, created_at")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(100);
  if (error) throw error;
  return ((data as {
    id: string;
    kind: string;
    title: string;
    body: string | null;
    link_path: string | null;
    read_at: string | null;
    created_at: string;
  }[] | null) ?? []).map((row) => ({
    id: row.id,
    kind: normalizeKind(row.kind),
    title: row.title,
    body: row.body,
    linkPath: row.link_path,
    readAt: row.read_at,
    createdAt: row.created_at,
  }));
}

function normalizeKind(value: string): NotificationKind {
  return value in KIND_ICON ? (value as NotificationKind) : "proposal_received";
}

function formatRelative(iso: string): string {
  const diffMs = Date.now() - new Date(iso).getTime();
  const minutes = Math.floor(diffMs / 60_000);
  if (minutes < 1) return "今";
  if (minutes < 60) return `${minutes}分前`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}時間前`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}日前`;
  const date = new Date(iso);
  return `${date.getMonth() + 1}/${date.getDate()}`;
}

function toneStyle(tone: Tone) {
  if (tone === "ok") return styles.iconOk;
  if (tone === "warn") return styles.iconWarn;
  if (tone === "amber") return styles.iconAmber;
  if (tone === "mute") return styles.iconMute;
  return styles.iconLavender;
}

function toneColor(tone: Tone) {
  if (tone === "ok") return "#16a34a";
  if (tone === "warn") return megrumColors.warn;
  if (tone === "amber") return "#b7791f";
  if (tone === "mute") return "rgba(58,50,74,0.55)";
  return megrumColors.lavender;
}

const styles = StyleSheet.create({
  screen: {
    gap: 12,
  },
  markAllButton: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  markAllText: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
  tabBar: {
    borderBottomColor: "rgba(58,50,74,0.10)",
    borderBottomWidth: StyleSheet.hairlineWidth,
    flexDirection: "row",
    gap: 0,
    marginHorizontal: -18,
    paddingHorizontal: 18,
  },
  tabButton: {
    alignItems: "center",
    flex: 1,
    flexDirection: "row",
    gap: 6,
    justifyContent: "center",
    minHeight: 46,
    opacity: 0.68,
    position: "relative",
  },
  tabButtonSelected: {
    borderBottomColor: megrumColors.ink,
    borderBottomWidth: 2,
    opacity: 1,
  },
  tabText: {
    color: megrumColors.mutedInk,
    fontSize: 14,
    fontWeight: "900",
  },
  tabTextSelected: {
    color: megrumColors.ink,
  },
  tabBadge: {
    backgroundColor: "rgba(58,50,74,0.07)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
    minWidth: 20,
    overflow: "hidden",
    paddingHorizontal: 6,
    paddingVertical: 2,
    textAlign: "center",
  },
  tabBadgeSelected: {
    backgroundColor: "rgba(166,149,216,0.16)",
    color: megrumColors.lavender,
  },
  loadingText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  inlineError: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
  emptyBox: {
    alignItems: "center",
    paddingVertical: 48,
  },
  emptyTitle: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  emptyLink: {
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
    marginTop: 8,
  },
  list: {
    marginHorizontal: -18,
  },
  row: {
    backgroundColor: megrumColors.background,
  },
  rowUnread: {
    backgroundColor: "rgba(166,149,216,0.045)",
  },
  rowInner: {
    alignItems: "flex-start",
    flexDirection: "row",
    minHeight: 82,
    paddingLeft: 18,
    paddingRight: 18,
    paddingTop: 13,
  },
  pressed: {
    opacity: 0.72,
  },
  iconRail: {
    alignItems: "center",
    paddingTop: 2,
    width: 48,
  },
  iconBox: {
    alignItems: "center",
    borderRadius: megrumRadii.pill,
    height: 40,
    justifyContent: "center",
    width: 40,
  },
  iconLavender: {
    backgroundColor: "rgba(166,149,216,0.16)",
  },
  iconOk: {
    backgroundColor: "rgba(34,197,94,0.14)",
  },
  iconWarn: {
    backgroundColor: "rgba(217,130,107,0.13)",
  },
  iconAmber: {
    backgroundColor: "rgba(245,158,11,0.14)",
  },
  iconMute: {
    backgroundColor: "rgba(58,50,74,0.06)",
  },
  rowCopy: {
    flex: 1,
    paddingBottom: 13,
    position: "relative",
  },
  cardTop: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  cardTitle: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 14.5,
    fontWeight: "800",
    lineHeight: 19,
  },
  cardTitleUnread: {
    fontWeight: "900",
  },
  timeText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  bodyText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "700",
    lineHeight: 19,
    marginTop: 4,
  },
  rowDivider: {
    backgroundColor: "rgba(58,50,74,0.09)",
    bottom: 0,
    height: StyleSheet.hairlineWidth,
    left: 0,
    position: "absolute",
    right: 0,
  },
  unreadDot: {
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    height: 9,
    marginLeft: 9,
    marginTop: 9,
    width: 9,
  },
});
