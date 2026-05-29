import { useEffect, useMemo, useState, type ReactNode } from "react";
import { router } from "expo-router";
import { Image, Pressable, StyleSheet, Text, View } from "react-native";
import { Screen } from "../../src/components/Screen";
import { useAuth } from "../../src/auth/AuthProvider";
import { IconSymbol } from "../../src/components/IconSymbol";
import {
  fetchMailingAddress,
  formatMailingAddressSummary,
  type MailingAddressRecord,
} from "../../src/lib/mailingAddress";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../../src/theme/tokens";

type ProfileData = {
  userId: string;
  handle: string;
  displayName: string;
  primaryArea: string | null;
  avatarUrl: string | null;
  tradeCount: number;
  ratingAvg: number | null;
  ratingCount: number;
  listingsCount: number;
  mailingAddress: MailingAddressRecord | null;
  oshiGroups: OshiGroup[];
  items: ProfileItem[];
};

type ProfileItem = {
  id: string;
  title: string;
  subtitle: string;
  photoUrl: string | null;
  hue: string;
};

type OshiGroup = {
  groupName: string;
  members: string[];
};

type ProfileRow = {
  handle: string | null;
  display_name: string | null;
  primary_area: string | null;
  avatar_url: string | null;
};

type OshiRow = {
  group_id: string | null;
  character_id: string | null;
  oshi_request_id: string | null;
  character_request_id: string | null;
  priority: number;
  group: MasterName;
  character: MasterName;
  oshi_request:
    | { requested_name: string | null }
    | { requested_name: string | null }[]
    | null;
  character_request:
    | { requested_name: string | null }
    | { requested_name: string | null }[]
    | null;
};

type MasterName = { name: string | null } | { name: string | null }[] | null;

type InventoryRow = {
  id: string;
  title: string | null;
  photo_urls: string[] | null;
  hue: string | null;
  group: MasterName;
  character: MasterName;
  goods_type: MasterName;
};

export default function ProfileScreen() {
  const { previewMode, user } = useAuth();
  const [profile, setProfile] = useState<ProfileData | null>(() =>
    !supabase || previewMode ? fallbackProfile(user?.email, previewMode) : null,
  );
  const [loading, setLoading] = useState(!!supabase && !previewMode);
  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    if (!supabase || previewMode) {
      setProfile(fallbackProfile(user?.email, previewMode));
      setLoading(false);
      setLoadError(null);
      return;
    }
    if (!user) {
      setProfile(null);
      setLoading(false);
      setLoadError(null);
      return;
    }

    let active = true;
    setProfile(null);
    setLoading(true);
    setLoadError(null);
    fetchProfileData(user.id, user.email)
      .then((next) => {
        if (active) setProfile(next);
      })
      .catch((error: unknown) => {
        if (!active) return;
        setLoadError(error instanceof Error ? error.message : "読み込みに失敗しました");
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, user]);

  const oshiSummary = useMemo(
    () => formatOshiSummary(profile?.oshiGroups ?? []),
    [profile?.oshiGroups],
  );

  return (
    <Screen contentStyle={styles.screen}>
      <View style={styles.header}>
        <Pressable
          accessibilityLabel="戻る"
          accessibilityRole="button"
          onPress={() => {
            if (router.canGoBack()) {
              router.back();
              return;
            }
            router.replace("/");
          }}
          style={styles.headerIcon}
        >
          <Text style={styles.backIcon}>‹</Text>
        </Pressable>
        <Text style={styles.title}>プロフィール</Text>
        <Pressable
          accessibilityLabel="プロフィール編集"
          accessibilityRole="button"
          onPress={() => router.push("/profile-edit")}
          style={styles.headerIcon}
        >
          <IconSymbol name="create-outline" color={megrumColors.ink} size={19} />
        </Pressable>
      </View>

      {loading ? <Text style={styles.inlineNotice}>プロフィールを読み込み中…</Text> : null}
      {loadError ? <Text style={styles.inlineError}>{loadError}</Text> : null}

      {profile ? (
        <>
          <ProfileHero profile={profile} />

          <View style={styles.statsStrip}>
            <MiniStat
              label="評価"
              value={profile.ratingAvg == null ? "★—" : `★${profile.ratingAvg.toFixed(1)}`}
              onPress={() =>
                router.push({
                  pathname: "/user-evaluations",
                  params: { id: profile.userId },
                })
              }
            />
            <MiniStat label="取引" value={`${profile.tradeCount}`} />
            <MiniStat label="譲る候補" value={`${profile.items.length}`} />
            <MiniStat label="個別募集" value={`${profile.listingsCount}`} />
          </View>

          <ProfileSection title="推し">
            <Pressable
              accessibilityRole="button"
              onPress={() => router.push("/oshi-settings")}
              style={({ pressed }) => [
                styles.oshiCard,
                pressed ? styles.rowPressed : null,
              ]}
            >
              <View style={styles.oshiBubble}>
                <Text style={styles.oshiBubbleText}>
                  {profile.oshiGroups[0]?.groupName.slice(0, 1) ?? "推"}
                </Text>
              </View>
              <View style={styles.oshiBubbleAlt}>
                <Text style={styles.oshiBubbleText}>
                  {profile.oshiGroups[1]?.groupName.slice(0, 1) ?? "し"}
                </Text>
              </View>
              <View style={styles.oshiCopy}>
                <Text numberOfLines={1} style={styles.oshiTitle}>
                  {oshiSummary.title}
                </Text>
                <Text numberOfLines={1} style={styles.oshiMeta}>
                  {oshiSummary.meta}
                </Text>
              </View>
              <IconSymbol name="chevron-forward" color="rgba(58,50,74,0.34)" size={18} />
            </Pressable>
          </ProfileSection>

          <ProfileSection title="郵送交換">
            <Pressable
              accessibilityRole="button"
              onPress={() => router.push("/address-settings")}
              style={({ pressed }) => [
                styles.settingsRow,
                pressed ? styles.rowPressed : null,
              ]}
            >
              <View style={styles.settingsRowIcon}>
                <IconSymbol name="mail-outline" color={megrumColors.lavender} size={19} />
              </View>
              <View style={styles.settingsRowCopy}>
                <Text style={styles.settingsRowTitle}>住所設定</Text>
                <Text numberOfLines={2} style={styles.settingsRowMeta}>
                  {profile.mailingAddress
                    ? formatMailingAddressSummary(profile.mailingAddress)
                    : "未登録です。郵送交換の前に登録してください。"}
                </Text>
              </View>
              <IconSymbol name="chevron-forward" color="rgba(58,50,74,0.34)" size={18} />
            </Pressable>
          </ProfileSection>

          <ProfileSection title="譲る候補" hint={`${profile.items.length}件`}>
            {profile.items.length === 0 ? (
              <Pressable
                accessibilityRole="button"
                onPress={() => router.push("/inventory")}
                style={({ pressed }) => [
                  styles.emptyPublicBox,
                  pressed ? styles.rowPressed : null,
                ]}
              >
                <Text style={styles.emptyPublicTitle}>公開中の譲る候補はありません</Text>
                <Text style={styles.emptyPublicText}>マイ在庫から譲る候補を追加できます</Text>
              </Pressable>
            ) : (
              <View style={styles.publicGrid}>
                {profile.items.slice(0, 6).map((item) => (
                  <Pressable
                    key={item.id}
                    accessibilityRole="button"
                    onPress={() =>
                      router.push({
                        pathname: "/goods-editor",
                        params: { id: item.id, mode: "edit" },
                      })
                    }
                    style={({ pressed }) => [
                      styles.publicItem,
                      pressed ? styles.publicItemPressed : null,
                    ]}
                  >
                    <View style={[styles.publicThumb, { backgroundColor: item.hue }]}>
                      {item.photoUrl ? (
                        <Image source={{ uri: item.photoUrl }} style={styles.publicImage} />
                      ) : (
                        <Text style={styles.publicLetter}>{item.title.slice(0, 1)}</Text>
                      )}
                    </View>
                    <Text numberOfLines={1} style={styles.publicTitle}>
                      {item.title}
                    </Text>
                    <Text numberOfLines={1} style={styles.publicSubtitle}>
                      {item.subtitle}
                    </Text>
                  </Pressable>
                ))}
              </View>
            )}
          </ProfileSection>

        </>
      ) : null}
    </Screen>
  );
}

function ProfileHero({ profile }: { profile: ProfileData }) {
  return (
    <View style={styles.hero}>
      <View style={styles.heroGlowPink} />
      <View style={styles.heroGlowSky} />
      <View style={styles.heroTop}>
        <View style={styles.avatar}>
          {profile.avatarUrl ? (
            <Image source={{ uri: profile.avatarUrl }} style={styles.avatarImage} />
          ) : (
            <Text style={styles.avatarText}>
              {(profile.displayName || profile.handle || "Mg").slice(0, 2)}
            </Text>
          )}
        </View>
        <View style={styles.heroIdentity}>
          <Text numberOfLines={1} style={styles.handle}>
            @{profile.handle || "未設定"}
          </Text>
          <Text numberOfLines={1} style={styles.displayName}>
            {profile.displayName || "（表示名未設定）"}
          </Text>
          <Text numberOfLines={1} style={styles.heroMeta}>
            {profile.primaryArea ?? "エリア未設定"} ・ 取引 {profile.tradeCount} 回
          </Text>
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="評価一覧を見る"
          onPress={() =>
            router.push({
              pathname: "/user-evaluations",
              params: { id: profile.userId },
            })
          }
          style={styles.ratingPanel}
        >
          <Text style={styles.ratingValue}>
            {profile.ratingAvg == null ? "★—" : `★${profile.ratingAvg.toFixed(1)}`}
          </Text>
          <Text style={styles.ratingCount}>{profile.ratingCount} 件</Text>
          <Text style={styles.ratingLink}>詳細 ›</Text>
        </Pressable>
      </View>
    </View>
  );
}

function MiniStat({
  label,
  value,
  onPress,
}: {
  label: string;
  value: string;
  onPress?: () => void;
}) {
  const content = (
    <>
      <Text style={styles.miniStatValue}>{value}</Text>
      <Text style={styles.miniStatLabel}>{label}</Text>
    </>
  );
  if (!onPress) return <View style={styles.miniStat}>{content}</View>;
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [
        styles.miniStat,
        pressed ? styles.rowPressed : null,
      ]}
    >
      {content}
    </Pressable>
  );
}

async function fetchProfileData(
  userId: string,
  email?: string,
): Promise<ProfileData> {
  if (!supabase) return fallbackProfile(email, false);
  const [
    { data: profile },
    { data: oshi },
    { count: tradeCount },
    { count: listingsCount },
    { data: evaluations },
    { data: items },
    mailingAddress,
  ] = await Promise.all([
    supabase
      .from("users")
      .select("handle, display_name, primary_area, avatar_url")
      .eq("id", userId)
      .maybeSingle(),
    supabase
      .from("user_oshi")
      .select(
        "group_id, character_id, oshi_request_id, character_request_id, priority, group:groups_master(name), character:characters_master(name), oshi_request:oshi_requests(requested_name), character_request:character_requests(requested_name)",
      )
      .eq("user_id", userId)
      .order("priority", { ascending: true }),
    supabase
      .from("proposals")
      .select("id", { count: "exact", head: true })
      .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)
      .eq("status", "completed"),
    supabase
      .from("listings")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("status", "active"),
    supabase.from("user_evaluations").select("stars").eq("ratee_id", userId),
    supabase
      .from("goods_inventory")
      .select(
        "id, title, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .eq("user_id", userId)
      .eq("kind", "for_trade")
      .eq("status", "active")
      .limit(6),
    fetchMailingAddress(userId, { tolerateMissingSchema: true }),
  ]);

  const profileRow = profile as ProfileRow | null;
  const stars = ((evaluations as { stars: number }[] | null) ?? [])
    .map((evaluation) => evaluation.stars)
    .filter((star) => typeof star === "number");
  const ratingAvg =
    stars.length > 0 ? stars.reduce((sum, star) => sum + star, 0) / stars.length : null;

  return {
    userId,
    handle: profileRow?.handle ?? makeHandle(email),
    displayName: profileRow?.display_name ?? (email ? "michi" : "ゲスト"),
    primaryArea: profileRow?.primary_area ?? null,
    avatarUrl: profileRow?.avatar_url ?? null,
    tradeCount: tradeCount ?? 0,
    ratingAvg,
    ratingCount: stars.length,
    listingsCount: listingsCount ?? 0,
    mailingAddress,
    oshiGroups: buildOshiGroups((oshi as OshiRow[] | null) ?? []),
    items: buildProfileItems((items as InventoryRow[] | null) ?? []),
  };
}

function fallbackProfile(email?: string, previewMode = false): ProfileData {
  return {
    userId: "preview-user-1",
    handle: previewMode ? "michilion" : makeHandle(email),
    displayName: previewMode ? "michi" : email ? "michi" : "ゲスト",
    primaryArea: previewMode ? "東京都" : null,
    avatarUrl: null,
    tradeCount: previewMode ? 18 : 0,
    ratingAvg: previewMode ? 4.9 : null,
    ratingCount: previewMode ? 12 : 0,
    listingsCount: previewMode ? 3 : 0,
    mailingAddress: previewMode
      ? {
          userId: "preview-user-1",
          recipientName: "michi",
          postalCode: "1500001",
          prefecture: "東京都",
          city: "渋谷区",
          line1: "神南1-2-3",
          line2: "Megrumハイツ 101",
          phoneNumber: "",
          createdAt: null,
          updatedAt: null,
        }
      : null,
    oshiGroups: previewMode
      ? [
          { groupName: "BTS", members: ["ジミン", "ジョングク"] },
          { groupName: "aespa", members: ["ニンニン"] },
        ]
      : [],
    items: previewMode
      ? [
          {
            id: "preview-item-1",
            title: "ジミン トレカ",
            subtitle: "BTS ・ ジミン ・ トレカ",
            photoUrl: null,
            hue: "#cbbcf4",
          },
          {
            id: "preview-item-2",
            title: "ジョングク トレカ",
            subtitle: "BTS ・ ジョングク ・ トレカ",
            photoUrl: null,
            hue: "#a8d4e6",
          },
          {
            id: "preview-item-3",
            title: "ニンニン トレカ",
            subtitle: "aespa ・ ニンニン ・ トレカ",
            photoUrl: null,
            hue: "#f3c5d4",
          },
        ]
      : [],
  };
}

function buildOshiGroups(rows: OshiRow[]): OshiGroup[] {
  const groups = new Map<string, OshiGroup>();
  for (const row of rows) {
    const groupId = row.group_id ?? row.oshi_request_id;
    const groupName =
      pickName(row.group) ?? pickRequestName(row.oshi_request) ?? null;
    if (!groupId || !groupName) continue;
    const group = groups.get(groupId) ?? { groupName, members: [] };
    const memberName =
      pickName(row.character) ?? pickRequestName(row.character_request);
    if (memberName) group.members.push(memberName);
    groups.set(groupId, group);
  }
  return Array.from(groups.values());
}

function buildProfileItems(rows: InventoryRow[]): ProfileItem[] {
  return rows.map((row) => {
    const character = pickName(row.character);
    const goodsType = pickName(row.goods_type);
    const group = pickName(row.group);
    const fallbackTitle = [character, goodsType].filter(Boolean).join(" ") || "グッズ";
    return {
      id: row.id,
      title: row.title ?? fallbackTitle,
      subtitle: [group, character, goodsType].filter(Boolean).join(" ・ "),
      photoUrl: firstPhoto(row.photo_urls),
      hue: row.hue ?? megrumColors.sky,
    };
  });
}

function formatOshiSummary(groups: OshiGroup[]) {
  if (groups.length === 0) {
    return {
      title: "推し未設定",
      meta: "推し設定から追加できます",
    };
  }
  const memberCount = groups.reduce((sum, group) => sum + group.members.length, 0);
  return {
    title: groups
      .slice(0, 2)
      .map((group) =>
        group.members.length > 0
          ? `${group.groupName}・${group.members.slice(0, 2).join("/")}`
          : group.groupName,
      )
      .join(" / "),
    meta: `${groups.length}グループ・${memberCount}メンバー`,
  };
}

function pickName(value: MasterName | undefined) {
  if (!value) return null;
  return Array.isArray(value) ? value[0]?.name ?? null : value.name;
}

function pickRequestName(
  value:
    | { requested_name: string | null }
    | { requested_name: string | null }[]
    | null
    | undefined,
) {
  if (!value) return null;
  return Array.isArray(value)
    ? value[0]?.requested_name ?? null
    : value.requested_name;
}

function firstPhoto(value: string[] | null) {
  return Array.isArray(value) && typeof value[0] === "string" ? value[0] : null;
}

function makeHandle(email?: string) {
  if (!email) return "preview_hana";
  const local = email.split("@")[0]?.replace(/[^a-zA-Z0-9_]/g, "").toLowerCase();
  return local || "megrum_user";
}

function ProfileSection({
  title,
  hint,
  children,
}: {
  title: string;
  hint?: string;
  children: ReactNode;
}) {
  return (
    <View style={styles.section}>
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>{title}</Text>
        {hint ? <Text style={styles.sectionHint}>{hint}</Text> : null}
      </View>
      <View style={styles.sectionBody}>{children}</View>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    gap: 15,
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  headerIcon: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.86)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 999,
    borderWidth: 1,
    height: 38,
    justifyContent: "center",
    width: 38,
  },
  backIcon: {
    color: megrumColors.ink,
    fontSize: 29,
    fontWeight: "700",
    lineHeight: 32,
    marginTop: -1,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 19,
    fontWeight: "900",
    letterSpacing: 0,
    lineHeight: 24,
  },
  inlineError: {
    color: megrumColors.warn,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 17,
  },
  inlineNotice: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 17,
  },
  hero: {
    backgroundColor: megrumColors.lavender,
    borderRadius: 18,
    overflow: "hidden",
    padding: 20,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 24,
  },
  heroGlowPink: {
    backgroundColor: "rgba(243,197,212,0.34)",
    borderRadius: 999,
    height: 132,
    position: "absolute",
    right: -34,
    top: -48,
    width: 132,
  },
  heroGlowSky: {
    backgroundColor: "rgba(168,212,230,0.62)",
    borderRadius: 999,
    bottom: -58,
    height: 154,
    left: -46,
    position: "absolute",
    width: 154,
  },
  heroTop: {
    alignItems: "center",
    flexDirection: "row",
    gap: 13,
  },
  avatar: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.18)",
    borderColor: "rgba(255,255,255,0.30)",
    borderRadius: 16,
    borderWidth: 2,
    height: 58,
    justifyContent: "center",
    overflow: "hidden",
    width: 58,
  },
  avatarImage: {
    height: "100%",
    width: "100%",
  },
  avatarText: {
    color: megrumColors.surface,
    fontSize: 19,
    fontWeight: "900",
  },
  heroIdentity: {
    flex: 1,
    minWidth: 0,
  },
  handle: {
    color: megrumColors.surface,
    fontSize: 16,
    fontWeight: "900",
  },
  displayName: {
    color: "rgba(255,255,255,0.92)",
    fontSize: 12,
    fontWeight: "800",
    marginTop: 2,
  },
  heroMeta: {
    color: "rgba(255,255,255,0.84)",
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 3,
  },
  ratingPanel: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.15)",
    borderRadius: 12,
    flexShrink: 0,
    justifyContent: "center",
    minWidth: 58,
    paddingHorizontal: 10,
    paddingVertical: 8,
  },
  ratingValue: {
    color: megrumColors.surface,
    fontSize: 15,
    fontWeight: "900",
    lineHeight: 16,
  },
  ratingCount: {
    color: "rgba(255,255,255,0.90)",
    fontSize: 9.5,
    fontWeight: "800",
    marginTop: 2,
  },
  ratingLink: {
    color: "rgba(255,255,255,0.78)",
    fontSize: 8.5,
    fontWeight: "800",
    marginTop: 2,
  },
  statsStrip: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    flexDirection: "row",
    overflow: "hidden",
    ...megrumShadow,
  },
  miniStat: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
    minHeight: 58,
    paddingHorizontal: 4,
    paddingVertical: 10,
  },
  miniStatValue: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  miniStatLabel: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "800",
    marginTop: 3,
  },
  section: {
    gap: 8,
  },
  sectionHeader: {
    alignItems: "baseline",
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 2,
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  sectionHint: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  sectionBody: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    overflow: "hidden",
  },
  oshiCard: {
    alignItems: "center",
    flexDirection: "row",
    minHeight: 76,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  oshiBubble: {
    alignItems: "center",
    backgroundColor: megrumColors.pink,
    borderColor: megrumColors.surface,
    borderRadius: 18,
    borderWidth: 2,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  oshiBubbleAlt: {
    alignItems: "center",
    backgroundColor: megrumColors.sky,
    borderColor: megrumColors.surface,
    borderRadius: 18,
    borderWidth: 2,
    height: 42,
    justifyContent: "center",
    marginLeft: -10,
    width: 42,
  },
  oshiBubbleText: {
    color: megrumColors.surface,
    fontSize: 15,
    fontWeight: "900",
  },
  oshiCopy: {
    flex: 1,
    marginLeft: 12,
  },
  oshiTitle: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "900",
  },
  oshiMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 3,
  },
  rowPressed: {
    backgroundColor: "rgba(166,149,216,0.08)",
  },
  publicGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
    padding: 12,
  },
  publicItem: {
    width: "31.3%",
  },
  publicItemPressed: {
    opacity: 0.78,
  },
  publicThumb: {
    alignItems: "center",
    aspectRatio: 0.78,
    borderRadius: 14,
    justifyContent: "center",
    overflow: "hidden",
    width: "100%",
  },
  publicImage: {
    height: "100%",
    width: "100%",
  },
  publicLetter: {
    color: megrumColors.surface,
    fontSize: 26,
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.20)",
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 4,
  },
  publicTitle: {
    color: megrumColors.ink,
    fontSize: 10.5,
    fontWeight: "900",
    marginTop: 6,
  },
  publicSubtitle: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "800",
    marginTop: 1,
  },
  emptyPublicBox: {
    paddingHorizontal: 15,
    paddingVertical: 18,
  },
  emptyPublicTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  emptyPublicText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 4,
  },
  settingsRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
    minHeight: 76,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  settingsRowIcon: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: 14,
    height: 38,
    justifyContent: "center",
    width: 38,
  },
  settingsRowCopy: {
    flex: 1,
    minWidth: 0,
  },
  settingsRowTitle: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "900",
  },
  settingsRowMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 17,
    marginTop: 3,
  },
});
