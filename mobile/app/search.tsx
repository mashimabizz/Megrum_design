import { useCallback, useEffect, useMemo, useState } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { router, Stack, useLocalSearchParams } from "expo-router";
import {
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import {
  GoodsGrid,
  type GoodsGridItem,
  type GoodsGridPressContext,
} from "../src/components/GoodsGrid";
import { Screen } from "../src/components/Screen";
import { useAuth } from "../src/auth/AuthProvider";
import { fetchInventoryTagLabels } from "../src/lib/inventoryTags";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii } from "../src/theme/tokens";

type MasterName = { name: string | null } | { name: string | null }[] | null;

type InventoryHitRow = {
  id: string;
  user_id: string;
  title: string;
  photo_urls: string[] | null;
  group_id: string | null;
  character_id: string | null;
  goods_type_id: string | null;
  hue?: number | string | null;
  group: MasterName;
  character: MasterName;
  goods_type: MasterName;
};

type InventoryMatchRef = {
  id: string;
  user_id: string;
  group_id: string | null;
  character_id: string | null;
  goods_type_id: string | null;
};

type SearchMatchBucket = "matched" | "possible" | "none";

type SearchHit = {
  id: string;
  userId: string;
  title: string;
  photoUrl: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  hue: string;
  tagLabels: string[];
  matchBucket: SearchMatchBucket;
};

type SearchResultItem = GoodsGridItem & {
  userId: string;
  matchBucket: SearchMatchBucket;
};

type PopularSearchRow = {
  term: string | null;
  search_count: number | null;
  last_searched_at: string | null;
};

type TagSearchRow = {
  id: string;
  label?: string | null;
};

const RECENT_KEY = "megrum-search-recent-v1";

const PREVIEW_HITS: SearchHit[] = [
  {
    id: "preview-search-1",
    userId: "preview-user-1",
    title: "スア 春ver. トレカ",
    photoUrl: null,
    groupName: "LUMENA",
    characterName: "スア",
    goodsTypeName: "トレカ",
    hue: "#cbbcf4",
    tagLabels: ["春ver.", "同種優先"],
    matchBucket: "matched",
  },
  {
    id: "preview-search-2",
    userId: "preview-user-2",
    title: "ニンニン 制服 アクスタ",
    photoUrl: null,
    groupName: "aespa",
    characterName: "ニンニン",
    goodsTypeName: "アクスタ",
    hue: "#a8d4e6",
    tagLabels: ["制服", "現地OK"],
    matchBucket: "possible",
  },
  {
    id: "preview-search-3",
    userId: "preview-user-3",
    title: "ミンギュ 会場限定 トレカ",
    photoUrl: null,
    groupName: "SEVENTEEN",
    characterName: "ミンギュ",
    goodsTypeName: "トレカ",
    hue: "#f3c5d4",
    tagLabels: ["会場限定"],
    matchBucket: "none",
  },
];

const RESULT_SECTIONS: {
  id: SearchMatchBucket;
  title: string;
  empty: string;
}[] = [
  {
    id: "matched",
    title: "マッチしてるよ！",
    empty: "条件がそろったグッズはまだありません",
  },
  {
    id: "possible",
    title: "交換できるかも？",
    empty: "片側条件に合うグッズはまだありません",
  },
  {
    id: "none",
    title: "マッチなし",
    empty: "検索にはヒットしましたが、条件一致はありません",
  },
];

const GOODS_SELECT =
  "id, user_id, title, photo_urls, group_id, character_id, goods_type_id, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)";

export default function SearchScreen() {
  const params = useLocalSearchParams<{ q?: string | string[] }>();
  const initialQuery = Array.isArray(params.q) ? params.q[0] : params.q;
  const { previewMode, user } = useAuth();
  const [draft, setDraft] = useState(initialQuery ?? "");
  const [query, setQuery] = useState(initialQuery ?? "");
  const [recent, setRecent] = useState<string[]>([]);
  const [popular, setPopular] = useState<string[]>([]);
  const [popularLoading, setPopularLoading] = useState(false);
  const [hits, setHits] = useState<SearchHit[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadPopularSearches = useCallback(() => {
    if (!supabase || previewMode) {
      setPopular([]);
      setPopularLoading(false);
      return;
    }
    setPopularLoading(true);
    fetchPopularSearchTerms()
      .then(setPopular)
      .catch(() => {
        setPopular([]);
      })
      .finally(() => setPopularLoading(false));
  }, [previewMode]);

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
    loadPopularSearches();
  }, [loadPopularSearches]);

  useEffect(() => {
    const q = query.trim();
    if (!q) {
      setHits([]);
      setError(null);
      setLoading(false);
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
        if (!active) return;
        setHits(next);
        void recordSearchQuery(q, next.length).then(loadPopularSearches);
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
  }, [loadPopularSearches, previewMode, query, user]);

  const sections = useMemo(
    () =>
      RESULT_SECTIONS.map((section) => ({
        ...section,
        items: hits
          .filter((hit) => hit.matchBucket === section.id)
          .map(toResultItem),
      })),
    [hits],
  );

  const totalCount = hits.length;

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

  function openResult(item: SearchResultItem, _context: GoodsGridPressContext) {
    router.push({
      pathname: "/user-profile",
      params: { id: item.userId },
    });
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
          headerBackButtonDisplayMode: "minimal",
          headerBackTitle: "",
          headerSearchBarOptions: {
            autoCapitalize: "none",
            hideWhenScrolling: false,
            obscureBackground: false,
            placement: "integratedButton",
            placeholder: "グッズ・推し・タグを検索",
            tintColor: megrumColors.lavender,
            onCancelButtonPress: clearQuery,
            onChangeText: (event) => {
              setDraft(event.nativeEvent.text);
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
            <Text style={styles.resultCount}>{totalCount}件</Text>
            <Text style={styles.resultQuery}>「{query}」</Text>
          </View>
          {loading ? <Text style={styles.loadingText}>検索中…</Text> : null}
          {error ? <Text style={styles.inlineError}>{error}</Text> : null}
          {!loading && totalCount === 0 ? (
            <View style={styles.emptyBox}>
              <Text style={styles.emptyTitle}>該当する譲が見つかりませんでした</Text>
              <Text style={styles.emptyText}>キーワードを短くするか、タグ名で検索してみてください。</Text>
            </View>
          ) : (
            <View style={styles.sectionList}>
              {sections.map((section) => (
                <ResultSection
                  key={section.id}
                  title={section.title}
                  empty={section.empty}
                  items={section.items}
                  onPressItem={openResult}
                />
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
            values={popular}
            loading={popularLoading}
            emptyLabel="検索実績がまだありません"
            onPress={submit}
          />
        </View>
      )}
    </Screen>
  );
}

function ResultSection({
  empty,
  items,
  onPressItem,
  title,
}: {
  empty: string;
  items: SearchResultItem[];
  onPressItem: (item: SearchResultItem, context: GoodsGridPressContext) => void;
  title: string;
}) {
  return (
    <View style={styles.resultSection}>
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>{title}</Text>
        <Text style={styles.sectionCount}>{items.length}件</Text>
      </View>
      {items.length > 0 ? (
        <GoodsGrid
          items={items}
          columns={3}
          emptyLabel={empty}
          showTopRow
          topRowMode="tag"
          showBottomStrip={false}
          onPressItem={(item, context) =>
            onPressItem(item as SearchResultItem, context)
          }
        />
      ) : (
        <Text style={styles.sectionEmpty}>{empty}</Text>
      )}
    </View>
  );
}

function SuggestionGroup({
  emptyLabel,
  loading,
  onPress,
  title,
  values,
}: {
  emptyLabel?: string;
  loading?: boolean;
  onPress: (value: string) => void;
  title: string;
  values: string[];
}) {
  return (
    <View style={styles.suggestionGroup}>
      <Text style={styles.suggestionTitle}>{title}</Text>
      {loading ? <Text style={styles.suggestionMeta}>読み込み中…</Text> : null}
      {!loading && values.length === 0 && emptyLabel ? (
        <Text style={styles.suggestionMeta}>{emptyLabel}</Text>
      ) : null}
      {values.length > 0 ? (
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
      ) : null}
    </View>
  );
}

async function fetchSearchHits(userId: string, q: string): Promise<SearchHit[]> {
  if (!supabase) return [];
  const ilike = `%${q}%`;
  const [titleRows, characterIds, groupIds, tagInventoryIds] = await Promise.all([
    fetchInventoryRowsByTitle(userId, ilike),
    fetchMasterIds("characters_master", ilike),
    fetchMasterIds("groups_master", ilike),
    fetchInventoryIdsByTag(q),
  ]);

  const [charRows, groupRows, tagRows] = await Promise.all([
    characterIds.length > 0
      ? fetchInventoryRowsByColumn(userId, "character_id", characterIds)
      : Promise.resolve([]),
    groupIds.length > 0
      ? fetchInventoryRowsByColumn(userId, "group_id", groupIds)
      : Promise.resolve([]),
    tagInventoryIds.length > 0
      ? fetchInventoryRowsByIds(userId, tagInventoryIds)
      : Promise.resolve([]),
  ]);

  const merged = new Map<string, InventoryHitRow>();
  for (const row of [...titleRows, ...charRows, ...groupRows, ...tagRows]) {
    merged.set(row.id, row);
  }
  const allHits = Array.from(merged.values()).slice(0, 60);
  const userIds = Array.from(new Set(allHits.map((row) => row.user_id)));
  const [myInventory, myWishes, partnerWishesByUser, tagLabelsById] = await Promise.all([
    fetchMyInventoryRefs(userId),
    fetchMyWishRefs(userId),
    fetchPartnerWishRefs(userIds),
    fetchInventoryTagLabels(allHits.map((row) => row.id)).catch(
      () => ({} as Record<string, string[]>),
    ),
  ]);

  return allHits
    .map((row) => {
      const tagLabels = tagLabelsById[row.id] ?? [];
      const hitMatchesMyWish = myWishes.some((wish) => inventoryMatches(row, wish));
      const ownerWantsMine =
        partnerWishesByUser
          .get(row.user_id)
          ?.some((wish) => myInventory.some((item) => inventoryMatches(item, wish))) ??
        false;
      const matchBucket: SearchMatchBucket =
        hitMatchesMyWish && ownerWantsMine
          ? "matched"
          : hitMatchesMyWish || ownerWantsMine
            ? "possible"
            : "none";
      const characterName = pickName(row.character);
      const groupName = pickName(row.group);
      const goodsTypeName = pickName(row.goods_type);
      const label = characterName ?? groupName ?? row.title;
      return {
        id: row.id,
        userId: row.user_id,
        title: row.title,
        photoUrl: row.photo_urls?.[0] ?? null,
        groupName,
        characterName,
        goodsTypeName,
        hue: normalizeHue(row.hue, label),
        tagLabels,
        matchBucket,
      };
    })
    .sort(compareSearchHits);
}

async function fetchInventoryRowsByTitle(userId: string, ilike: string) {
  if (!supabase) return [];
  const { data, error } = await supabase
    .from("goods_inventory")
    .select(GOODS_SELECT)
    .neq("user_id", userId)
    .eq("kind", "for_trade")
    .eq("status", "active")
    .ilike("title", ilike)
    .limit(30);
  if (error) throw error;
  return (data as InventoryHitRow[] | null) ?? [];
}

async function fetchInventoryRowsByColumn(
  userId: string,
  column: "character_id" | "group_id",
  ids: string[],
) {
  if (!supabase || ids.length === 0) return [];
  const { data, error } = await supabase
    .from("goods_inventory")
    .select(GOODS_SELECT)
    .neq("user_id", userId)
    .eq("kind", "for_trade")
    .eq("status", "active")
    .in(column, ids)
    .limit(40);
  if (error) throw error;
  return (data as InventoryHitRow[] | null) ?? [];
}

async function fetchInventoryRowsByIds(userId: string, ids: string[]) {
  if (!supabase || ids.length === 0) return [];
  const { data, error } = await supabase
    .from("goods_inventory")
    .select(GOODS_SELECT)
    .neq("user_id", userId)
    .eq("kind", "for_trade")
    .eq("status", "active")
    .in("id", ids)
    .limit(40);
  if (error) throw error;
  return (data as InventoryHitRow[] | null) ?? [];
}

async function fetchMasterIds(
  table: "characters_master" | "groups_master",
  ilike: string,
) {
  if (!supabase) return [];
  const { data } = await supabase.from(table).select("id").ilike("name", ilike).limit(30);
  return ((data as { id: string }[] | null) ?? []).map((row) => row.id);
}

async function fetchInventoryIdsByTag(q: string) {
  if (!supabase) return [];
  const { data: tagRows, error } = await supabase.rpc("search_tags", {
    p_q: q,
    p_limit: 20,
  });
  if (error) return [];
  const tagIds = ((tagRows as TagSearchRow[] | null) ?? []).map((row) => row.id);
  if (tagIds.length === 0) return [];
  const { data } = await supabase
    .from("goods_inventory_tags")
    .select("inventory_id")
    .in("tag_id", tagIds)
    .limit(80);
  return Array.from(
    new Set(((data as { inventory_id: string }[] | null) ?? []).map((row) => row.inventory_id)),
  );
}

async function fetchMyInventoryRefs(userId: string): Promise<InventoryMatchRef[]> {
  if (!supabase) return [];
  const { data } = await supabase
    .from("goods_inventory")
    .select("id, user_id, group_id, character_id, goods_type_id")
    .eq("user_id", userId)
    .eq("kind", "for_trade")
    .eq("status", "active");
  return (data as InventoryMatchRef[] | null) ?? [];
}

async function fetchMyWishRefs(userId: string): Promise<InventoryMatchRef[]> {
  if (!supabase) return [];
  const { data } = await supabase
    .from("goods_inventory")
    .select("id, user_id, group_id, character_id, goods_type_id")
    .eq("user_id", userId)
    .eq("kind", "wanted")
    .neq("status", "archived");
  return (data as InventoryMatchRef[] | null) ?? [];
}

async function fetchPartnerWishRefs(userIds: string[]) {
  const grouped = new Map<string, InventoryMatchRef[]>();
  if (!supabase || userIds.length === 0) return grouped;
  const { data } = await supabase
    .from("goods_inventory")
    .select("id, user_id, group_id, character_id, goods_type_id")
    .in("user_id", userIds)
    .eq("kind", "wanted")
    .neq("status", "archived")
    .limit(500);
  for (const row of (data as InventoryMatchRef[] | null) ?? []) {
    const values = grouped.get(row.user_id) ?? [];
    values.push(row);
    grouped.set(row.user_id, values);
  }
  return grouped;
}

async function fetchPopularSearchTerms() {
  if (!supabase) return [];
  const { data, error } = await supabase.rpc("get_popular_search_terms", {
    p_limit: 10,
  });
  if (error) return [];
  return ((data as PopularSearchRow[] | null) ?? [])
    .map((row) => row.term?.trim() ?? "")
    .filter(Boolean);
}

async function recordSearchQuery(q: string, resultCount: number) {
  if (!supabase) return;
  await supabase.rpc("record_search_query", {
    p_query: q,
    p_result_count: resultCount,
  });
}

function toResultItem(hit: SearchHit): SearchResultItem {
  const label = hit.characterName ?? hit.groupName ?? hit.title;
  return {
    id: hit.id,
    userId: hit.userId,
    matchBucket: hit.matchBucket,
    title: hit.title,
    subtitle: [hit.groupName, hit.goodsTypeName].filter(Boolean).join(" / ") || "グッズ",
    glyph: label.slice(0, 1) || "?",
    hue: hit.hue,
    photoUrl: hit.photoUrl,
    tagLabels: hit.tagLabels,
    badge: hit.tagLabels[0] ?? "タグ未設定",
  };
}

function inventoryMatches(
  item: Pick<InventoryMatchRef, "group_id" | "character_id" | "goods_type_id">,
  wish: Pick<InventoryMatchRef, "group_id" | "character_id" | "goods_type_id">,
) {
  if (!item.goods_type_id || item.goods_type_id !== wish.goods_type_id) return false;
  if (item.character_id && wish.character_id) return item.character_id === wish.character_id;
  if (!item.group_id || !wish.group_id) return false;
  return item.group_id === wish.group_id;
}

function compareSearchHits(a: SearchHit, b: SearchHit) {
  const bucketOrder: Record<SearchMatchBucket, number> = {
    matched: 0,
    possible: 1,
    none: 2,
  };
  const bucket = bucketOrder[a.matchBucket] - bucketOrder[b.matchBucket];
  if (bucket !== 0) return bucket;
  const tagCount = b.tagLabels.length - a.tagLabels.length;
  if (tagCount !== 0) return tagCount;
  return a.title.localeCompare(b.title, "ja");
}

function matchPreviewHit(hit: SearchHit, q: string) {
  const haystack = [
    hit.title,
    hit.groupName,
    hit.characterName,
    hit.goodsTypeName,
    ...hit.tagLabels,
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

function normalizeHue(value: number | string | null | undefined, seed: string) {
  if (typeof value === "number") return `hsl(${value}, 62%, 78%)`;
  if (typeof value === "string" && value.trim()) {
    return value.startsWith("#") || value.startsWith("hsl")
      ? value
      : `hsl(${Number(value) || nameToHue(seed)}, 62%, 78%)`;
  }
  return `hsl(${nameToHue(seed)}, 62%, 78%)`;
}

function nameToHue(name: string) {
  let hash = 0;
  for (let index = 0; index < name.length; index += 1) {
    hash = (hash << 5) - hash + name.charCodeAt(index);
    hash |= 0;
  }
  return Math.abs(hash) % 360;
}

const styles = StyleSheet.create({
  screen: {
    gap: 16,
  },
  resultsBlock: {
    gap: 12,
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
    lineHeight: 18,
    marginTop: 5,
    textAlign: "center",
  },
  sectionList: {
    gap: 22,
  },
  resultSection: {
    gap: 9,
  },
  sectionHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 2,
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  sectionCount: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  sectionEmpty: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    paddingHorizontal: 2,
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
  suggestionMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
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
  pressed: {
    opacity: 0.86,
    transform: [{ scale: 0.99 }],
  },
});
