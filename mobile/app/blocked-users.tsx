import { useCallback, useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Image,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { router } from "expo-router";
import { useAuth } from "../src/auth/AuthProvider";
import { IconSymbol } from "../src/components/IconSymbol";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import { unblockMeguriBoardUser } from "../src/lib/meguriBoard";
import { hasSupabaseConfig, supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type BlockRow = {
  blocked_id: string;
  created_at: string | null;
};

type UserRow = {
  avatar_url: string | null;
  display_name: string | null;
  handle: string | null;
  id: string;
  primary_area: string | null;
};

type BlockedUser = {
  avatarUrl: string | null;
  blockedAt: string | null;
  displayName: string;
  handle: string | null;
  primaryArea: string | null;
  userId: string;
};

const PREVIEW_BLOCKED_USERS: BlockedUser[] = [
  {
    avatarUrl: null,
    blockedAt: new Date(Date.now() - 1000 * 60 * 60 * 26).toISOString(),
    displayName: "Megrumユーザー",
    handle: "blocked_sample",
    primaryArea: "東京都",
    userId: "preview-blocked-user",
  },
];

export default function BlockedUsersScreen() {
  const { exitPreview, previewMode, user } = useAuth();
  const [items, setItems] = useState<BlockedUser[]>([]);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [unblockingId, setUnblockingId] = useState<string | null>(null);

  const isDemo = previewMode || !hasSupabaseConfig || !supabase;

  const load = useCallback(
    async (mode: "initial" | "refresh" = "initial") => {
      if (mode === "refresh") {
        setRefreshing(true);
      } else {
        setLoading(true);
      }
      setError(null);
      try {
        if (isDemo) {
          setItems(PREVIEW_BLOCKED_USERS);
          return;
        }
        if (!user?.id) {
          setItems([]);
          return;
        }
        setItems(await fetchBlockedUsers(user.id));
      } catch (loadError) {
        setError(
          loadError instanceof Error
            ? loadError.message
            : "ブロックした人を読み込めませんでした",
        );
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [isDemo, user?.id],
  );

  useEffect(() => {
    void load("initial");
  }, [load]);

  const emptyLabel = useMemo(() => {
    if (!user && !isDemo) return "ログインしているアカウントで表示できます";
    return "ブロック中のユーザーはいません";
  }, [isDemo, user]);

  const handleUnblock = useCallback(
    async (target: BlockedUser) => {
      if (unblockingId) return;
      setUnblockingId(target.userId);
      setError(null);
      try {
        if (!isDemo && user?.id) {
          await unblockMeguriBoardUser(user.id, target.userId);
        }
        setItems((current) => current.filter((item) => item.userId !== target.userId));
      } catch (unblockError) {
        setError(
          unblockError instanceof Error
            ? unblockError.message
            : "ブロックを解除できませんでした",
        );
      } finally {
        setUnblockingId(null);
      }
    },
    [isDemo, unblockingId, user?.id],
  );

  const confirmUnblock = useCallback(
    (target: BlockedUser) => {
      Alert.alert(
        "ブロックを解除しますか？",
        `${userLabel(target)}さんをブロックした人から外します。`,
        [
          { style: "cancel", text: "キャンセル" },
          {
            onPress: () => {
              void handleUnblock(target);
            },
            style: "destructive",
            text: "解除する",
          },
        ],
      );
    },
    [handleUnblock],
  );

  if (!user && !isDemo) {
    return (
      <Screen contentStyle={styles.screen}>
        <RouteHeader title="ブロックした人" subtitle="ブロック中のユーザーを管理" />
        <View style={styles.loginCard}>
          <IconSymbol name="ban-outline" size={34} color={megrumColors.lavender} />
          <Text style={styles.loginTitle}>ログインが必要です</Text>
          <Text style={styles.loginDescription}>
            ブロックした人の一覧はログイン後に確認できます。
          </Text>
          <PrimaryButton
            onPress={() => {
              exitPreview();
              router.replace("/login");
            }}
          >
            ログインする
          </PrimaryButton>
        </View>
      </Screen>
    );
  }

  return (
    <Screen scroll={false} contentStyle={styles.screen}>
      <RouteHeader title="ブロックした人" subtitle="ブロック中のユーザーを管理" />
      <View style={styles.summaryCard}>
        <View style={styles.summaryIcon}>
          <IconSymbol name="ban-outline" size={22} color={megrumColors.lavender} />
        </View>
        <View style={styles.summaryCopy}>
          <Text style={styles.summaryTitle}>{items.length}人をブロック中</Text>
          <Text style={styles.summaryDescription}>
            解除すると、相手のグルームや掲示板の投稿が再び表示対象になります。
          </Text>
        </View>
      </View>

      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      <ScrollView
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => {
              void load("refresh");
            }}
            tintColor={megrumColors.lavender}
          />
        }
        showsVerticalScrollIndicator={false}
        style={styles.listScroll}
      >
        {loading ? (
          <View style={styles.loadingCard}>
            <ActivityIndicator color={megrumColors.lavender} />
            <Text style={styles.loadingText}>読み込んでいます</Text>
          </View>
        ) : items.length > 0 ? (
          items.map((item) => (
            <BlockedUserRow
              item={item}
              key={item.userId}
              onUnblock={confirmUnblock}
              unblocking={unblockingId === item.userId}
            />
          ))
        ) : (
          <View style={styles.emptyCard}>
            <IconSymbol name="checkmark-circle-outline" size={32} color={megrumColors.ok} />
            <Text style={styles.emptyTitle}>{emptyLabel}</Text>
            <Text style={styles.emptyDescription}>
              必要になった時は、プロフィールや掲示板のメニューからブロックできます。
            </Text>
          </View>
        )}
      </ScrollView>
    </Screen>
  );
}

function BlockedUserRow({
  item,
  onUnblock,
  unblocking,
}: {
  item: BlockedUser;
  onUnblock: (item: BlockedUser) => void;
  unblocking: boolean;
}) {
  return (
    <View style={styles.row}>
      <View style={styles.avatar}>
        {item.avatarUrl ? (
          <Image source={{ uri: item.avatarUrl }} style={styles.avatarImage} />
        ) : (
          <Text style={styles.avatarInitial}>{userLabel(item).slice(0, 1).toUpperCase()}</Text>
        )}
      </View>
      <View style={styles.rowCopy}>
        <Text numberOfLines={1} style={styles.rowTitle}>
          {userLabel(item)}
        </Text>
        <Text numberOfLines={1} style={styles.rowMeta}>
          {item.primaryArea ? `${item.primaryArea} · ` : ""}
          {formatBlockedAt(item.blockedAt)}
        </Text>
      </View>
      <Pressable
        accessibilityLabel={`${userLabel(item)}のブロックを解除`}
        accessibilityRole="button"
        disabled={unblocking}
        onPress={() => onUnblock(item)}
        style={({ pressed }) => [
          styles.unblockButton,
          pressed && !unblocking ? styles.unblockButtonPressed : null,
          unblocking ? styles.unblockButtonDisabled : null,
        ]}
      >
        {unblocking ? (
          <ActivityIndicator color={megrumColors.warn} size="small" />
        ) : (
          <Text style={styles.unblockText}>解除</Text>
        )}
      </Pressable>
    </View>
  );
}

async function fetchBlockedUsers(currentUserId: string): Promise<BlockedUser[]> {
  if (!supabase) return PREVIEW_BLOCKED_USERS;
  const { data, error } = await supabase
    .from("groom_user_blocks")
    .select("blocked_id, created_at")
    .eq("blocker_id", currentUserId)
    .order("created_at", { ascending: false });
  if (error) throw error;

  const blocks = ((data as BlockRow[] | null) ?? []).filter((row) => row.blocked_id);
  if (blocks.length === 0) return [];

  const blockedIds = blocks.map((row) => row.blocked_id);
  const { data: users, error: usersError } = await supabase
    .from("users")
    .select("id, handle, display_name, avatar_url, primary_area")
    .in("id", blockedIds);
  if (usersError) throw usersError;

  const usersById = new Map<string, UserRow>();
  for (const profile of (users as UserRow[] | null) ?? []) {
    usersById.set(profile.id, profile);
  }

  return blocks.map((block) => {
    const profile = usersById.get(block.blocked_id);
    return {
      avatarUrl: profile?.avatar_url ?? null,
      blockedAt: block.created_at,
      displayName: profile?.display_name || profile?.handle || "Megrumユーザー",
      handle: profile?.handle ?? null,
      primaryArea: profile?.primary_area ?? null,
      userId: block.blocked_id,
    };
  });
}

function userLabel(user: BlockedUser) {
  if (user.handle) return `@${user.handle.replace(/^@/, "")}`;
  return user.displayName;
}

function formatBlockedAt(value: string | null) {
  if (!value) return "ブロック中";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "ブロック中";
  return `${date.getMonth() + 1}/${date.getDate()}からブロック中`;
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    gap: 14,
    paddingHorizontal: 18,
  },
  summaryCard: {
    ...megrumShadow,
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.84)",
    borderColor: "rgba(255,255,255,0.86)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    padding: 16,
  },
  summaryIcon: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.15)",
    borderRadius: megrumRadii.pill,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  summaryCopy: {
    flex: 1,
    gap: 4,
  },
  summaryTitle: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  summaryDescription: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 18,
  },
  listContent: {
    gap: 10,
    paddingBottom: 24,
  },
  listScroll: {
    flex: 1,
  },
  row: {
    ...megrumShadow,
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.9)",
    borderColor: "rgba(255,255,255,0.9)",
    borderRadius: 20,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    padding: 12,
  },
  avatar: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    borderRadius: megrumRadii.pill,
    height: 52,
    justifyContent: "center",
    overflow: "hidden",
    width: 52,
  },
  avatarImage: {
    height: "100%",
    width: "100%",
  },
  avatarInitial: {
    color: megrumColors.lavender,
    fontSize: 20,
    fontWeight: "900",
  },
  rowCopy: {
    flex: 1,
    gap: 4,
  },
  rowTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  rowMeta: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  unblockButton: {
    alignItems: "center",
    backgroundColor: "rgba(217,130,107,0.12)",
    borderRadius: megrumRadii.pill,
    minWidth: 68,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  unblockButtonPressed: {
    opacity: 0.72,
  },
  unblockButtonDisabled: {
    opacity: 0.55,
  },
  unblockText: {
    color: megrumColors.warn,
    fontSize: 13,
    fontWeight: "900",
  },
  loadingCard: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: megrumRadii.xl,
    borderStyle: "dashed",
    borderWidth: 1,
    gap: 10,
    paddingVertical: 34,
  },
  loadingText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
  },
  emptyCard: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: megrumRadii.xl,
    borderStyle: "dashed",
    borderWidth: 1,
    gap: 8,
    paddingHorizontal: 22,
    paddingVertical: 36,
  },
  emptyTitle: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  emptyDescription: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 18,
    textAlign: "center",
  },
  errorText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
    lineHeight: 17,
  },
  loginCard: {
    ...megrumShadow,
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.88)",
    borderColor: "rgba(255,255,255,0.86)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 12,
    padding: 22,
  },
  loginTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  loginDescription: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "700",
    lineHeight: 20,
    textAlign: "center",
  },
});
