import { useEffect, useState } from "react";
import { router, useLocalSearchParams } from "expo-router";
import {
  Image,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import { useAuth } from "../src/auth/AuthProvider";
import { IconSymbol } from "../src/components/IconSymbol";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type MasterName = { name: string | null } | { name: string | null }[] | null;

type UserProfile = {
  id: string;
  handle: string;
  displayName: string;
  primaryArea: string | null;
  avatarUrl: string | null;
  ratingAvg: number | null;
  ratingCount: number;
  tradeCount: number;
  items: ProfileItem[];
};

type ProfileItem = {
  id: string;
  title: string;
  subtitle: string;
  photoUrl: string | null;
  hue: string;
};

const PREVIEW_PROFILE: UserProfile = {
  id: "preview-user-1",
  handle: "michilion",
  displayName: "michi",
  primaryArea: "東京都",
  avatarUrl: null,
  ratingAvg: 4.9,
  ratingCount: 12,
  tradeCount: 18,
  items: [
    {
      id: "preview-item-1",
      title: "スア 春ver. トレカ",
      subtitle: "LUMENA ・ スア ・ トレカ",
      photoUrl: null,
      hue: "#cbbcf4",
    },
    {
      id: "preview-item-2",
      title: "ジョンウ ラキドロ",
      subtitle: "NCT ・ ジョンウ ・ トレカ",
      photoUrl: null,
      hue: "#a8d4e6",
    },
  ],
};

export default function UserProfileScreen() {
  const params = useLocalSearchParams<{ id?: string | string[] }>();
  const profileId = Array.isArray(params.id) ? params.id[0] : params.id;
  const { previewMode, user } = useAuth();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!profileId) {
      setError("ユーザーIDが見つかりません");
      setProfile(null);
      return;
    }
    if (!supabase || previewMode) {
      setProfile(PREVIEW_PROFILE);
      setError(null);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);
    fetchUserProfile(profileId)
      .then((next) => {
        if (active) setProfile(next);
      })
      .catch((reason: unknown) => {
        if (!active) return;
        setError(reason instanceof Error ? reason.message : "プロフィールを読み込めませんでした");
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, profileId]);

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader title="相手プロフィール" subtitle="譲る候補と評価を確認" />
      {loading ? <Text style={styles.loadingText}>読み込み中…</Text> : null}
      {error ? <Text style={styles.inlineError}>{error}</Text> : null}
      {profile ? (
        <>
          <View style={styles.hero}>
            <View style={styles.avatar}>
              {profile.avatarUrl ? (
                <Image source={{ uri: profile.avatarUrl }} style={styles.avatarImage} />
              ) : (
                <Text style={styles.avatarText}>
                  {profile.displayName.slice(0, 2) || "?"}
                </Text>
              )}
            </View>
            <View style={styles.identity}>
              <Text numberOfLines={1} style={styles.handle}>
                @{profile.handle}
              </Text>
              <Text numberOfLines={1} style={styles.name}>
                {profile.displayName} ・ {profile.primaryArea ?? "エリア未設定"}
              </Text>
            </View>
            <View style={styles.statsRow}>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel="評価一覧を見る"
                onPress={() =>
                  router.push({
                    pathname: "/user-evaluations",
                    params: { id: profile.id },
                  })
                }
                style={styles.statButton}
              >
                <Stat label="評価" value={profile.ratingAvg == null ? "—" : `★${profile.ratingAvg.toFixed(1)}`} />
              </Pressable>
              <Stat label="件数" value={`${profile.ratingCount}`} />
              <Stat label="取引" value={`${profile.tradeCount}`} />
            </View>
          </View>

          <View style={styles.section}>
            <Text style={styles.sectionTitle}>譲る候補</Text>
            {profile.items.length === 0 ? (
              <View style={styles.emptyBox}>
                <Text style={styles.emptyText}>現在表示できる譲る候補はありません</Text>
              </View>
            ) : (
              <View style={styles.itemsGrid}>
                {profile.items.map((item) => (
                  <View key={item.id} style={styles.itemCard}>
                    <View style={[styles.itemThumb, { backgroundColor: item.hue }]}>
                      {item.photoUrl ? (
                        <Image source={{ uri: item.photoUrl }} style={styles.itemImage} />
                      ) : (
                        <Text style={styles.itemLetter}>{item.title.slice(0, 1)}</Text>
                      )}
                    </View>
                    <Text numberOfLines={1} style={styles.itemTitle}>
                      {item.title}
                    </Text>
                    <Text numberOfLines={1} style={styles.itemSubtitle}>
                      {item.subtitle}
                    </Text>
                  </View>
                ))}
              </View>
            )}
          </View>

          {user && user.id !== profile.id ? (
            <Pressable
              accessibilityRole="button"
              onPress={() =>
                router.push({
                  pathname: "/proposal-select",
                  params: { partnerId: profile.id },
                })
              }
              style={styles.cta}
            >
              <Text style={styles.ctaText}>この人に打診する</Text>
              <IconSymbol name="arrow-forward" size={16} color="#fff" />
            </Pressable>
          ) : null}
        </>
      ) : null}
    </Screen>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.stat}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

async function fetchUserProfile(id: string): Promise<UserProfile> {
  if (!supabase) return PREVIEW_PROFILE;
  const [{ data: userRow }, { data: evaluations }, { count: tradeCount }, { data: itemRows }] =
    await Promise.all([
      supabase
        .from("users")
        .select("id, handle, display_name, primary_area, avatar_url")
        .eq("id", id)
        .maybeSingle(),
      supabase.from("user_evaluations").select("stars").eq("ratee_id", id),
      supabase
        .from("proposals")
        .select("id", { count: "exact", head: true })
        .or(`sender_id.eq.${id},receiver_id.eq.${id}`)
        .eq("status", "completed"),
      supabase
        .from("goods_inventory")
        .select(
          "id, title, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
        )
        .eq("user_id", id)
        .eq("kind", "for_trade")
        .eq("status", "active")
        .limit(12),
    ]);

  const row = userRow as {
    id: string;
    handle: string | null;
    display_name: string | null;
    primary_area: string | null;
    avatar_url: string | null;
  } | null;
  if (!row) throw new Error("ユーザーが見つかりません");
  const stars = ((evaluations as { stars: number }[] | null) ?? []).map((item) => item.stars);
  const ratingAvg =
    stars.length > 0 ? stars.reduce((sum, star) => sum + star, 0) / stars.length : null;

  return {
    id: row.id,
    handle: row.handle ?? "unknown",
    displayName: row.display_name ?? row.handle ?? "?",
    primaryArea: row.primary_area,
    avatarUrl: row.avatar_url,
    ratingAvg,
    ratingCount: stars.length,
    tradeCount: tradeCount ?? 0,
    items: ((itemRows as {
      id: string;
      title: string;
      photo_urls: string[] | null;
      hue: string | number | null;
      group: MasterName;
      character: MasterName;
      goods_type: MasterName;
    }[] | null) ?? []).map((item) => ({
      id: item.id,
      title: item.title,
      subtitle: [pickName(item.group), pickName(item.character), pickName(item.goods_type)]
        .filter(Boolean)
        .join(" ・ "),
      photoUrl: item.photo_urls?.[0] ?? null,
      hue: normalizeHue(item.hue, item.title),
    })),
  };
}

function pickName(value: MasterName): string | null {
  if (!value) return null;
  return Array.isArray(value) ? value[0]?.name ?? null : value.name;
}

function normalizeHue(value: string | number | null, fallback: string) {
  if (typeof value === "string" && value.startsWith("#")) return value;
  if (typeof value === "number") return `hsl(${value}, 38%, 78%)`;
  const hue = Math.abs(Array.from(fallback).reduce((sum, char) => sum + char.charCodeAt(0), 0)) % 360;
  return `hsl(${hue}, 38%, 78%)`;
}

const styles = StyleSheet.create({
  screen: {
    gap: 16,
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
  },
  hero: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    padding: 18,
    ...megrumShadow,
  },
  avatar: {
    alignItems: "center",
    alignSelf: "center",
    backgroundColor: "rgba(166,149,216,0.18)",
    borderRadius: 24,
    height: 86,
    justifyContent: "center",
    overflow: "hidden",
    width: 86,
  },
  avatarImage: {
    height: "100%",
    width: "100%",
  },
  avatarText: {
    color: megrumColors.lavender,
    fontSize: 24,
    fontWeight: "900",
  },
  identity: {
    alignItems: "center",
    marginTop: 12,
  },
  handle: {
    color: megrumColors.ink,
    fontSize: 20,
    fontWeight: "900",
  },
  name: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 3,
  },
  statsRow: {
    flexDirection: "row",
    gap: 8,
    marginTop: 16,
  },
  statButton: {
    flex: 1,
  },
  stat: {
    alignItems: "center",
    backgroundColor: megrumColors.background,
    borderRadius: megrumRadii.md,
    flex: 1,
    paddingVertical: 10,
  },
  statValue: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  statLabel: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "800",
    marginTop: 2,
  },
  section: {
    gap: 8,
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
    paddingHorizontal: 2,
  },
  emptyBox: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    padding: 18,
  },
  emptyText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    textAlign: "center",
  },
  itemsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
  },
  itemCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    padding: 10,
    width: "47.8%",
  },
  itemThumb: {
    alignItems: "center",
    aspectRatio: 0.72,
    borderRadius: 10,
    justifyContent: "center",
    overflow: "hidden",
    width: "100%",
  },
  itemImage: {
    height: "100%",
    width: "100%",
  },
  itemLetter: {
    color: megrumColors.surface,
    fontSize: 24,
    fontWeight: "900",
  },
  itemTitle: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
    marginTop: 8,
  },
  itemSubtitle: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  cta: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.md,
    flexDirection: "row",
    gap: 6,
    justifyContent: "center",
    minHeight: 50,
  },
  ctaText: {
    color: megrumColors.surface,
    fontSize: 14,
    fontWeight: "900",
  },
});
