import { useEffect, useMemo, useState } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { router, Stack, useLocalSearchParams } from "expo-router";
import {
  Image,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { Screen } from "../src/components/Screen";
import { useAuth } from "../src/auth/AuthProvider";
import { IconSymbol } from "../src/components/IconSymbol";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type MasterName = { name: string | null } | { name: string | null }[] | null;

type InventoryHitRow = {
  id: string;
  user_id: string;
  title: string;
  photo_urls: string[] | null;
  group_id: string | null;
  character_id: string | null;
  goods_type_id: string | null;
  group: MasterName;
  character: MasterName;
  goods_type: MasterName;
};

type SearchHit = {
  id: string;
  userId: string;
  userHandle: string;
  userDisplayName: string;
  primaryArea: string | null;
  ratingAvg: number | null;
  ratingCount: number;
  title: string;
  photoUrl: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  wishHit: boolean;
};

type WishRef = {
  group_id: string | null;
  character_id: string | null;
  goods_type_id: string | null;
};

const RECENT_KEY = "megrum-search-recent-v1";
const POPULAR_KEYWORDS = [
  "スア トレカ",
  "ヒナ 生写真",
  "WORLD TOUR",
  "POP-UP STORE",
  "横浜アリーナ",
  "推し誕生日カフェ",
];

const PREVIEW_HITS: SearchHit[] = [
  {
    id: "preview-search-1",
    userId: "preview-user-1",
    userHandle: "michilion",
    userDisplayName: "michi",
    primaryArea: "東京都",
    ratingAvg: 4.9,
    ratingCount: 12,
    title: "スア 春ver. トレカ",
    photoUrl: null,
    groupName: "LUMENA",
    characterName: "スア",
    goodsTypeName: "トレカ",
    wishHit: true,
  },
  {
    id: "preview-search-2",
    userId: "preview-user-2",
    userHandle: "hana_trade",
    userDisplayName: "ハナ",
    primaryArea: "大阪府",
    ratingAvg: 4.8,
    ratingCount: 8,
    title: "ニンニン 制服 アクスタ",
    photoUrl: null,
    groupName: "aespa",
    characterName: "ニンニン",
    goodsTypeName: "アクスタ",
    wishHit: false,
  },
];

export default function SearchScreen() {
  const params = useLocalSearchParams<{ q?: string | string[] }>();
  const initialQuery = Array.isArray(params.q) ? params.q[0] : params.q;
  const { previewMode, user } = useAuth();
  const [draft, setDraft] = useState(initialQuery ?? "");
  const [query, setQuery] = useState(initialQuery ?? "");
  const [recent, setRecent] = useState<string[]>([]);
  const [hits, setHits] = useState<SearchHit[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    AsyncStorage.getItem(RECENT_KEY)
      .then((raw) => {
        if (!raw) return;
        const parsed: unknown = JSON.parse(raw);
        if (Array.isArray(parsed)) {
          setRecent(parsed.filter((item): item is string => typeof item === "string"));
        }
      })
      .catch(() => {
        setRecent([]);
      });
  }, []);

  useEffect(() => {
    const q = query.trim();
    if (!q) {
      setHits([]);
      setError(null);
      return;
    }

    setRecent((current) => {
      const next = [q, ...current.filter((item) => item !== q)].slice(0, 6);
      AsyncStorage.setItem(RECENT_KEY, JSON.stringify(next)).catch(() => undefined);
      return next;
    });

    if (!supabase || previewMode) {
      setHits(PREVIEW_HITS.filter((hit) => matchPreviewHit(hit, q)));
      setLoading(false);
      setError(null);
      return;
    }
    if (!user) {
      setHits([]);
      setLoading(false);
      setError(null);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);
    fetchSearchHits(user.id, q)
      .then((next) => {
        if (active) setHits(next);
      })
      .catch((reason: unknown) => {
        if (!active) return;
        setError(reason instanceof Error ? reason.message : "検索に失敗しました");
        setHits([]);
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, query, user]);

  const sortedHits = useMemo(
    () => [...hits].sort((a, b) => Number(b.wishHit) - Number(a.wishHit)),
    [hits],
  );

  function submit(nextQuery = draft) {
    const q = nextQuery.trim();
    if (!q) return;
    setDraft(q);
    setQuery(q);
    router.setParams({ q });
  }

  function clearQuery() {
    setDraft("");
    setQuery("");
    router.setParams({ q: "" });
  }

  return (
    <Screen contentStyle={styles.screen} topInset={false}>
      <Stack.Screen
        options={{
          headerShown: true,
          title: "検索",
          headerLargeTitleEnabled: true,
          headerBlurEffect: "systemMaterial",
          headerTransparent: false,
          headerTintColor: megrumColors.lavender,
          headerSearchBarOptions: {
            autoCapitalize: "none",
            hideWhenScrolling: false,
            obscureBackground: false,
            placement: "integratedButton",
            placeholder: "グッズ・推し・ユーザーを検索",
            tintColor: megrumColors.lavender,
            onCancelButtonPress: clearQuery,
            onChangeText: (event) => {
              const next = event.nativeEvent.text;
              setDraft(next);
              setQuery(next);
            },
            onSearchButtonPress: (event) => {
              submit(event.nativeEvent.text);
            },
          },
        }}
      />

      {query ? (
        <View style={styles.resultsBlock}>
          <View style={styles.resultSummary}>
            <Text style={styles.resultCount}>{sortedHits.length}件</Text>
            <Text style={styles.resultQuery}>「{query}」</Text>
          </View>
          {loading ? <Text style={styles.loadingText}>検索中…</Text> : null}
          {error ? <Text style={styles.inlineError}>{error}</Text> : null}
          {!loading && sortedHits.length === 0 ? (
            <View style={styles.emptyBox}>
              <Text style={styles.emptyTitle}>該当する譲が見つかりませんでした</Text>
              <Text style={styles.emptyText}>キーワードを短くすると見つかりやすくなります。</Text>
            </View>
          ) : (
            <View style={styles.hitList}>
              {sortedHits.map((hit) => (
                <HitCard key={hit.id} hit={hit} />
              ))}
            </View>
          )}
        </View>
      ) : (
        <View style={styles.suggestions}>
          {recent.length > 0 ? (
            <SuggestionGroup title="履歴" values={recent} onPress={submit} />
          ) : null}
          <SuggestionGroup
            title="人気の検索"
            values={POPULAR_KEYWORDS}
            onPress={submit}
          />
        </View>
      )}
    </Screen>
  );
}

function HitCard({ hit }: { hit: SearchHit }) {
  const memberName = hit.characterName ?? hit.groupName ?? hit.title ?? "?";
  const hue = Math.abs(
    Array.from(memberName).reduce((sum, char) => sum + char.charCodeAt(0), 0),
  ) % 360;
  const placeholderColor = `hsl(${hue}, 36%, 78%)`;

  return (
    <Pressable
      accessibilityRole="button"
      onPress={() =>
        router.push({
          pathname: "/user-profile",
          params: { id: hit.userId },
        })
      }
      style={({ pressed }) => [styles.hitCard, pressed ? styles.pressed : null]}
    >
      <View style={styles.hitUserRow}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{hit.userDisplayName.slice(0, 1) || "?"}</Text>
        </View>
        <View style={styles.hitUserCopy}>
          <Text numberOfLines={1} style={styles.handle}>
            @{hit.userHandle}
          </Text>
          <Text numberOfLines={1} style={styles.meta}>
            {hit.primaryArea ?? "エリア未設定"}
            {hit.ratingAvg !== null ? ` ・ ★${hit.ratingAvg.toFixed(1)} (${hit.ratingCount})` : ""}
          </Text>
        </View>
        <View style={[styles.matchBadge, hit.wishHit ? styles.wishBadge : styles.tradeBadge]}>
          <Text style={styles.matchBadgeText}>{hit.wishHit ? "wish候補" : "出品中"}</Text>
        </View>
      </View>

      <View style={styles.itemPreview}>
        <View style={[styles.itemThumb, { backgroundColor: placeholderColor }]}>
          {hit.photoUrl ? (
            <Image source={{ uri: hit.photoUrl }} style={styles.itemImage} />
          ) : (
            <Text style={styles.itemLetter}>{memberName.slice(0, 1)}</Text>
          )}
        </View>
        <View style={styles.itemCopy}>
          <Text numberOfLines={1} style={styles.itemTitle}>
            譲：{hit.title}
          </Text>
          <Text numberOfLines={1} style={styles.itemMeta}>
            {[hit.groupName, hit.characterName, hit.goodsTypeName].filter(Boolean).join(" ・ ")}
          </Text>
        </View>
        <IconSymbol name="chevron-forward" size={16} color={megrumColors.lavender} />
      </View>
    </Pressable>
  );
}

function SuggestionGroup({
  onPress,
  title,
  values,
}: {
  onPress: (value: string) => void;
  title: string;
  values: string[];
}) {
  return (
    <View style={styles.suggestionGroup}>
      <Text style={styles.suggestionTitle}>{title}</Text>
      <View style={styles.chips}>
        {values.map((value) => (
          <Pressable
            key={value}
            accessibilityRole="button"
            onPress={() => onPress(value)}
            style={({ pressed }) => [styles.chip, pressed ? styles.pressed : null]}
          >
            <Text style={styles.chipText}>{value}</Text>
          </Pressable>
        ))}
      </View>
    </View>
  );
}

async function fetchSearchHits(userId: string, q: string): Promise<SearchHit[]> {
  if (!supabase) return [];
  const ilike = `%${q}%`;
  const { data: titleRows } = await supabase
    .from("goods_inventory")
    .select(
      "id, user_id, title, photo_urls, group_id, character_id, goods_type_id, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
    )
    .neq("user_id", userId)
    .eq("kind", "for_trade")
    .eq("status", "active")
    .ilike("title", ilike)
    .limit(20);

  const { data: chMaster } = await supabase
    .from("characters_master")
    .select("id")
    .ilike("name", ilike)
    .limit(20);
  const characterIds = ((chMaster as { id: string }[] | null) ?? []).map((row) => row.id);
  const { data: charRows } =
    characterIds.length > 0
      ? await supabase
          .from("goods_inventory")
          .select(
            "id, user_id, title, photo_urls, group_id, character_id, goods_type_id, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
          )
          .neq("user_id", userId)
          .eq("kind", "for_trade")
          .eq("status", "active")
          .in("character_id", characterIds)
          .limit(20)
      : { data: null };

  const { data: grMaster } = await supabase
    .from("groups_master")
    .select("id")
    .ilike("name", ilike)
    .limit(20);
  const groupIds = ((grMaster as { id: string }[] | null) ?? []).map((row) => row.id);
  const { data: groupRows } =
    groupIds.length > 0
      ? await supabase
          .from("goods_inventory")
          .select(
            "id, user_id, title, photo_urls, group_id, character_id, goods_type_id, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
          )
          .neq("user_id", userId)
          .eq("kind", "for_trade")
          .eq("status", "active")
          .in("group_id", groupIds)
          .limit(20)
      : { data: null };

  const merged = new Map<string, InventoryHitRow>();
  for (const rows of [titleRows, charRows, groupRows]) {
    for (const row of ((rows as InventoryHitRow[] | null) ?? [])) {
      merged.set(row.id, row);
    }
  }
  const allHits = Array.from(merged.values()).slice(0, 30);
  const userIds = Array.from(new Set(allHits.map((row) => row.user_id)));
  const usersById = new Map<string, { handle: string; displayName: string; primaryArea: string | null }>();
  if (userIds.length > 0) {
    const { data: users } = await supabase
      .from("users")
      .select("id, handle, display_name, primary_area")
      .in("id", userIds);
    for (const row of ((users as { id: string; handle: string | null; display_name: string | null; primary_area: string | null }[] | null) ?? [])) {
      usersById.set(row.id, {
        handle: row.handle ?? "unknown",
        displayName: row.display_name ?? row.handle ?? "?",
        primaryArea: row.primary_area,
      });
    }
  }

  const { data: wishRows } = await supabase
    .from("goods_inventory")
    .select("group_id, character_id, goods_type_id")
    .eq("user_id", userId)
    .eq("kind", "wanted")
    .neq("status", "archived");
  const wishes = (wishRows as WishRef[] | null) ?? [];

  const ratingByUser = new Map<string, { avg: number | null; count: number }>();
  if (userIds.length > 0) {
    const { data: evaluations } = await supabase
      .from("user_evaluations")
      .select("ratee_id, stars")
      .in("ratee_id", userIds);
    const grouped = new Map<string, number[]>();
    for (const row of ((evaluations as { ratee_id: string; stars: number }[] | null) ?? [])) {
      const next = grouped.get(row.ratee_id) ?? [];
      next.push(row.stars);
      grouped.set(row.ratee_id, next);
    }
    for (const [id, stars] of grouped.entries()) {
      ratingByUser.set(id, {
        avg: stars.reduce((sum, star) => sum + star, 0) / stars.length,
        count: stars.length,
      });
    }
  }

  return allHits.map((row) => {
    const owner = usersById.get(row.user_id);
    const rating = ratingByUser.get(row.user_id);
    return {
      id: row.id,
      userId: row.user_id,
      userHandle: owner?.handle ?? "unknown",
      userDisplayName: owner?.displayName ?? "?",
      primaryArea: owner?.primaryArea ?? null,
      ratingAvg: rating?.avg ?? null,
      ratingCount: rating?.count ?? 0,
      title: row.title,
      photoUrl: row.photo_urls?.[0] ?? null,
      groupName: pickName(row.group),
      characterName: pickName(row.character),
      goodsTypeName: pickName(row.goods_type),
      wishHit: wishes.some((wish) => {
        if (wish.goods_type_id !== row.goods_type_id) return false;
        if (wish.character_id && row.character_id) {
          return wish.character_id === row.character_id;
        }
        return Boolean(wish.group_id && wish.group_id === row.group_id);
      }),
    };
  });
}

function matchPreviewHit(hit: SearchHit, q: string) {
  const haystack = [
    hit.title,
    hit.userHandle,
    hit.groupName,
    hit.characterName,
    hit.goodsTypeName,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();
  return haystack.includes(q.toLowerCase());
}

function pickName(value: MasterName): string | null {
  if (!value) return null;
  return Array.isArray(value) ? value[0]?.name ?? null : value.name;
}

const styles = StyleSheet.create({
  screen: {
    gap: 16,
  },
  searchBox: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 12,
    borderWidth: 1,
    flexDirection: "row",
    gap: 10,
    minHeight: 48,
    paddingHorizontal: 14,
  },
  searchInput: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 16,
    fontWeight: "700",
    paddingVertical: 10,
  },
  resultsBlock: {
    gap: 10,
  },
  resultSummary: {
    alignItems: "baseline",
    flexDirection: "row",
    gap: 6,
    paddingHorizontal: 2,
  },
  resultCount: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  resultQuery: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
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
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: megrumRadii.lg,
    borderStyle: "dashed",
    borderWidth: 1,
    padding: 24,
  },
  emptyTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  emptyText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 5,
  },
  hitList: {
    gap: 10,
  },
  hitCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    padding: 14,
    ...megrumShadow,
  },
  pressed: {
    opacity: 0.86,
    transform: [{ scale: 0.99 }],
  },
  hitUserRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
    marginBottom: 10,
  },
  avatar: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.20)",
    borderRadius: megrumRadii.pill,
    height: 38,
    justifyContent: "center",
    width: 38,
  },
  avatarText: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  hitUserCopy: {
    flex: 1,
  },
  handle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  meta: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 1,
  },
  matchBadge: {
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  wishBadge: {
    backgroundColor: megrumColors.lavender,
  },
  tradeBadge: {
    backgroundColor: megrumColors.ok,
  },
  matchBadgeText: {
    color: megrumColors.surface,
    fontSize: 9,
    fontWeight: "900",
  },
  itemPreview: {
    alignItems: "center",
    backgroundColor: megrumColors.background,
    borderRadius: 10,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  itemThumb: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.65)",
    borderRadius: 6,
    borderWidth: 1,
    height: 48,
    justifyContent: "center",
    overflow: "hidden",
    width: 36,
  },
  itemImage: {
    height: "100%",
    width: "100%",
  },
  itemLetter: {
    color: megrumColors.surface,
    fontSize: 14,
    fontWeight: "900",
  },
  itemCopy: {
    flex: 1,
  },
  itemTitle: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  itemMeta: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  suggestions: {
    gap: 18,
  },
  suggestionGroup: {
    gap: 8,
  },
  suggestionTitle: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
    paddingHorizontal: 2,
  },
  chips: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 7,
  },
  chip: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  chipText: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "800",
  },
});
