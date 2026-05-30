import { useCallback, useEffect, useMemo, useState } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { router, Stack, useLocalSearchParams } from "expo-router";
import {
  ActionSheetIOS,
  Alert,
  Keyboard,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import {
  GoodsGrid,
  type GoodsGridItem,
  type GoodsGridPressContext,
} from "../src/components/GoodsGrid";
import { Screen } from "../src/components/Screen";
import { useAuth } from "../src/auth/AuthProvider";
import { JAPAN_PREFECTURES, displayPrefectureName } from "../src/data/japanPrefectures";
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
  created_at: string | null;
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
  createdAt: string | null;
  ownerLoginRank: number | null;
  hue: string;
  tagLabels: string[];
  optionTags: string[];
  meetupDates: string[];
  meetupPrefectures: string[];
  exchangeMethods: string[];
  matchBucket: SearchMatchBucket;
};

type SearchResultItem = GoodsGridItem & {
  userId: string;
  matchBucket: SearchMatchBucket;
};

type SearchFilterState = {
  groups: string[];
  members: string[];
  goodsTypes: string[];
  meetupDates: string[];
  meetupPlaces: string[];
  optionTags: string[];
  tags: string[];
  exchangeMethods: string[];
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

type OwnerLoginRankRow = {
  user_id: string | null;
  login_rank: number | null;
};

type ProposalSearchMetadataRow = {
  sender_have_ids: string[] | null;
  receiver_have_ids: string[] | null;
  option_tags: string[] | null;
  meetup_start_at: string | null;
  meetup_place_name: string | null;
  exchange_method: string | null;
};

type SearchFilterDateOption = {
  value: string;
  day: string;
  weekday: string;
  month: string;
};

type SearchMetadata = {
  optionTags: string[];
  meetupDates: string[];
  meetupPrefectures: string[];
  exchangeMethods: string[];
};

type SearchSortKey = "recentLogin" | "newest";

const RECENT_KEY = "megrum-search-recent-v1";
const EMPTY_FILTERS: SearchFilterState = {
  groups: [],
  members: [],
  goodsTypes: [],
  meetupDates: [],
  meetupPlaces: [],
  optionTags: [],
  tags: [],
  exchangeMethods: [],
};
const EXCHANGE_FILTERS = ["現地交換", "郵送", "どちらもOK"];
const DEFAULT_OPTION_TAGS = ["即日発送", "同日発送", "開演前OK", "終演後OK", "グッズ販売中OK"];
const PREFECTURE_FILTERS = JAPAN_PREFECTURES.map((prefecture) =>
  displayPrefectureName(prefecture.name),
);
const SORT_LABELS: Record<SearchSortKey, string> = {
  recentLogin: "ログインが新しい順",
  newest: "新着順",
};

const PREVIEW_HITS: SearchHit[] = [
  {
    id: "preview-search-1",
    userId: "preview-user-1",
    title: "スア 春ver. トレカ",
    photoUrl: null,
    groupName: "LUMENA",
    characterName: "スア",
    goodsTypeName: "トレカ",
    createdAt: "2026-05-30T07:00:00.000Z",
    ownerLoginRank: 1,
    hue: "#cbbcf4",
    tagLabels: ["春ver.", "同種優先"],
    optionTags: ["終演後OK"],
    meetupDates: [toLocalDateKey(new Date())],
    meetupPrefectures: ["東京都"],
    exchangeMethods: ["現地交換"],
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
    createdAt: "2026-05-29T12:00:00.000Z",
    ownerLoginRank: 2,
    hue: "#a8d4e6",
    tagLabels: ["制服", "現地OK"],
    optionTags: ["即日発送"],
    meetupDates: [toLocalDateKey(addDays(new Date(), 1))],
    meetupPrefectures: ["神奈川県"],
    exchangeMethods: ["どちらもOK"],
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
    createdAt: "2026-05-28T12:00:00.000Z",
    ownerLoginRank: 3,
    hue: "#f3c5d4",
    tagLabels: ["会場限定"],
    optionTags: [],
    meetupDates: [],
    meetupPrefectures: [],
    exchangeMethods: [],
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
  "id, user_id, title, photo_urls, group_id, character_id, goods_type_id, created_at, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)";

export default function SearchScreen() {
  const params = useLocalSearchParams<{ q?: string | string[] }>();
  const initialQuery = Array.isArray(params.q) ? params.q[0] : params.q;
  const { previewMode, user } = useAuth();
  const insets = useSafeAreaInsets();
  const [draft, setDraft] = useState(initialQuery ?? "");
  const [query, setQuery] = useState(initialQuery ?? "");
  const [recent, setRecent] = useState<string[]>([]);
  const [popular, setPopular] = useState<string[]>([]);
  const [popularLoading, setPopularLoading] = useState(false);
  const [hits, setHits] = useState<SearchHit[]>([]);
  const [filters, setFilters] = useState<SearchFilterState>(EMPTY_FILTERS);
  const [filterOpen, setFilterOpen] = useState(false);
  const [sortKey, setSortKey] = useState<SearchSortKey>("recentLogin");
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

  const filteredHits = useMemo(
    () => hits.filter((hit) => searchHitPassesFilters(hit, filters)),
    [filters, hits],
  );
  const sortedHits = useMemo(
    () => sortSearchHits(filteredHits, sortKey),
    [filteredHits, sortKey],
  );
  const filterOptions = useMemo(() => buildSearchFilterOptions(hits), [hits]);
  const activeFilterCount = countActiveSearchFilters(filters);

  const sections = useMemo(
    () =>
      RESULT_SECTIONS.map((section) => ({
        ...section,
        items: sortedHits
          .filter((hit) => hit.matchBucket === section.id)
          .map(toResultItem),
      })),
    [sortedHits],
  );

  const totalCount = sortedHits.length;
  const filterFooterBottom = Math.max(insets.bottom, 12) + 16;
  const footerBottomPadding = filterFooterBottom + 86;
  const dismissKeyboard = useCallback(() => {
    Keyboard.dismiss();
  }, []);

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

  function openSortOptions() {
    Keyboard.dismiss();
    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          cancelButtonIndex: 0,
          options: ["キャンセル", SORT_LABELS.recentLogin, SORT_LABELS.newest],
          title: "並び替え",
        },
        (buttonIndex) => {
          if (buttonIndex === 1) setSortKey("recentLogin");
          if (buttonIndex === 2) setSortKey("newest");
        },
      );
      return;
    }
    Alert.alert("並び替え", undefined, [
      { text: SORT_LABELS.recentLogin, onPress: () => setSortKey("recentLogin") },
      { text: SORT_LABELS.newest, onPress: () => setSortKey("newest") },
      { text: "キャンセル", style: "cancel" },
    ]);
  }

  function openResult(item: SearchResultItem, _context: GoodsGridPressContext) {
    router.push({
      pathname: "/user-profile",
      params: { id: item.userId },
    });
  }

  return (
    <Screen
      scroll={false}
      contentStyle={StyleSheet.flatten([
        styles.screen,
        { paddingBottom: footerBottomPadding },
      ])}
      topInset={false}
    >
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

      <ScrollView
        automaticallyAdjustsScrollIndicatorInsets
        contentInsetAdjustmentBehavior="automatic"
        keyboardDismissMode="interactive"
        keyboardShouldPersistTaps="handled"
        onTouchStart={dismissKeyboard}
        showsVerticalScrollIndicator={false}
        style={styles.searchScroll}
        contentContainerStyle={styles.searchContent}
      >
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
      </ScrollView>
      <View pointerEvents="box-none" style={[styles.filterFooter, { bottom: filterFooterBottom }]}>
        <View style={styles.filterFooterPill}>
          <Pressable
            accessibilityLabel="検索フィルターを開く"
            accessibilityRole="button"
            onPress={() => setFilterOpen(true)}
            style={({ pressed }) => [
              styles.filterFooterButton,
              pressed ? styles.filterIconButtonPressed : null,
            ]}
          >
            <Text style={styles.filterFooterIcon}>☷</Text>
            {activeFilterCount > 0 ? (
              <View style={styles.filterCountBadge}>
                <Text style={styles.filterCountBadgeText}>{activeFilterCount}</Text>
              </View>
            ) : null}
          </Pressable>
          <Text
            accessibilityLabel={`検索結果 ${totalCount}件`}
            style={styles.filterFooterCount}
          >
            {loading ? "…" : formatSearchCount(totalCount)}
          </Text>
          <Pressable
            accessibilityLabel={`並び替え ${SORT_LABELS[sortKey]}`}
            accessibilityRole="button"
            onPress={openSortOptions}
            style={({ pressed }) => [
              styles.filterFooterButton,
              pressed ? styles.filterIconButtonPressed : null,
            ]}
          >
            <Text style={styles.filterFooterIcon}>↕</Text>
          </Pressable>
        </View>
      </View>
      <SearchFilterSheet
        filters={filters}
        open={filterOpen}
        options={filterOptions}
        onClose={() => setFilterOpen(false)}
        onReset={() => setFilters(EMPTY_FILTERS)}
        onToggle={(key, value) =>
          setFilters((current) => toggleSearchFilterValue(current, key, value))
        }
      />
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

function SearchFilterSheet({
  filters,
  onClose,
  onReset,
  onToggle,
  open,
  options,
}: {
  filters: SearchFilterState;
  onClose: () => void;
  onReset: () => void;
  onToggle: (key: keyof SearchFilterState, value: string) => void;
  open: boolean;
  options: SearchFilterState;
}) {
  return (
    <Modal animationType="slide" transparent visible={open} onRequestClose={onClose}>
      <View style={styles.filterSheetRoot}>
        <Pressable style={styles.filterSheetBackdrop} onPress={onClose} />
        <View style={styles.filterSheet}>
          <View style={styles.filterSheetHeader}>
            <Text style={styles.filterSheetTitle}>検索フィルター</Text>
            <Pressable accessibilityRole="button" onPress={onReset} style={styles.filterReset}>
              <Text style={styles.filterResetText}>リセット</Text>
            </Pressable>
          </View>
          <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.filterSheetContent}>
            <FilterChipGroup
              active={filters.groups}
              filterKey="groups"
              options={options.groups}
              title="グループ"
              onToggle={onToggle}
            />
            <FilterChipGroup
              active={filters.members}
              filterKey="members"
              options={options.members}
              title="メンバー"
              onToggle={onToggle}
            />
            <FilterChipGroup
              active={filters.goodsTypes}
              filterKey="goodsTypes"
              options={options.goodsTypes}
              title="グッズ種別"
              onToggle={onToggle}
            />
            <FilterDateCalendar
              active={filters.meetupDates}
              title="現地交換日付"
              dates={buildMeetupDateOptions()}
              onToggle={(value) => onToggle("meetupDates", value)}
            />
            <FilterChipGroup
              active={filters.meetupPlaces}
              filterKey="meetupPlaces"
              options={options.meetupPlaces}
              title="現地交換場所"
              onToggle={onToggle}
            />
            <FilterChipGroup
              active={filters.optionTags}
              filterKey="optionTags"
              options={options.optionTags}
              title="交換条件タグ"
              onToggle={onToggle}
            />
            <FilterChipGroup
              active={filters.tags}
              filterKey="tags"
              options={options.tags}
              title="グッズタグ"
              onToggle={onToggle}
            />
            <FilterChipGroup
              active={filters.exchangeMethods}
              filterKey="exchangeMethods"
              options={options.exchangeMethods}
              title="交換手段"
              onToggle={onToggle}
            />
          </ScrollView>
          <Pressable accessibilityRole="button" onPress={onClose} style={styles.filterApply}>
            <Text style={styles.filterApplyText}>結果を見る</Text>
          </Pressable>
        </View>
      </View>
    </Modal>
  );
}

function FilterDateCalendar({
  active,
  dates,
  onToggle,
  title,
}: {
  active: string[];
  dates: SearchFilterDateOption[];
  onToggle: (value: string) => void;
  title: string;
}) {
  return (
    <View style={styles.filterGroup}>
      <Text style={styles.filterGroupTitle}>{title}</Text>
      <View style={styles.filterCalendarGrid}>
        {dates.map((date) => {
          const selected = active.includes(date.value);
          return (
            <Pressable
              accessibilityRole="button"
              accessibilityState={{ selected }}
              key={date.value}
              onPress={() => onToggle(date.value)}
              style={[
                styles.filterDateCell,
                selected ? styles.filterDateCellActive : null,
              ]}
            >
              <Text
                style={[
                  styles.filterDateMonth,
                  selected ? styles.filterDateTextActive : null,
                ]}
              >
                {date.month}
              </Text>
              <Text
                style={[
                  styles.filterDateDay,
                  selected ? styles.filterDateTextActive : null,
                ]}
              >
                {date.day}
              </Text>
              <Text
                style={[
                  styles.filterDateWeekday,
                  selected ? styles.filterDateTextActive : null,
                ]}
              >
                {date.weekday}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

function FilterChipGroup({
  active,
  empty,
  filterKey,
  onToggle,
  options,
  title,
}: {
  active: string[];
  empty?: string;
  filterKey: keyof SearchFilterState;
  onToggle: (key: keyof SearchFilterState, value: string) => void;
  options: string[];
  title: string;
}) {
  return (
    <View style={styles.filterGroup}>
      <Text style={styles.filterGroupTitle}>{title}</Text>
      {options.length === 0 ? (
        <Text style={styles.filterGroupEmpty}>{empty ?? "候補がありません"}</Text>
      ) : (
        <View style={styles.filterGroupChips}>
          {options.map((value) => {
            const selected = active.includes(value);
            return (
              <Pressable
                accessibilityRole="button"
                accessibilityState={{ selected }}
                key={value}
                onPress={() => onToggle(filterKey, value)}
                style={[styles.filterChipOption, selected ? styles.filterChipOptionActive : null]}
              >
                <Text
                  style={[
                    styles.filterChipOptionText,
                    selected ? styles.filterChipOptionTextActive : null,
                  ]}
                >
                  {value}
                </Text>
              </Pressable>
            );
          })}
        </View>
      )}
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
  const [myInventory, myWishes, partnerWishesByUser, tagLabelsById, ownerLoginRanks, metadataById] = await Promise.all([
    fetchMyInventoryRefs(userId),
    fetchMyWishRefs(userId),
    fetchPartnerWishRefs(userIds),
    fetchInventoryTagLabels(allHits.map((row) => row.id)).catch(
      () => ({} as Record<string, string[]>),
    ),
    fetchOwnerLoginRanks(userIds),
    fetchProposalSearchMetadata(allHits.map((row) => row.id)),
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
      const metadata = metadataById.get(row.id);
      return {
        id: row.id,
        userId: row.user_id,
        title: row.title,
        photoUrl: row.photo_urls?.[0] ?? null,
        groupName,
        characterName,
        goodsTypeName,
        createdAt: row.created_at,
        ownerLoginRank: ownerLoginRanks.get(row.user_id) ?? null,
        hue: normalizeHue(row.hue, label),
        tagLabels,
        optionTags: metadata?.optionTags ?? [],
        meetupDates: metadata?.meetupDates ?? [],
        meetupPrefectures: metadata?.meetupPrefectures ?? [],
        exchangeMethods: metadata?.exchangeMethods ?? [],
        matchBucket,
      };
    })
    .sort(compareSearchHits);
}

async function fetchProposalSearchMetadata(inventoryIds: string[]) {
  const metadataById = new Map<string, SearchMetadata>();
  if (!supabase || inventoryIds.length === 0) return metadataById;
  const select =
    "sender_have_ids, receiver_have_ids, option_tags, meetup_start_at, meetup_place_name, exchange_method";
  const statuses = ["sent", "negotiating", "agreement_one_side", "agreed"];
  try {
    const [senderResult, receiverResult] = await Promise.all([
      supabase
        .from("proposals")
        .select(select)
        .overlaps("sender_have_ids", inventoryIds)
        .in("status", statuses)
        .limit(120),
      supabase
        .from("proposals")
        .select(select)
        .overlaps("receiver_have_ids", inventoryIds)
        .in("status", statuses)
        .limit(120),
    ]);
    if (senderResult.error && receiverResult.error) return metadataById;
    const rows = [
      ...(((senderResult.data as ProposalSearchMetadataRow[] | null) ?? [])),
      ...(((receiverResult.data as ProposalSearchMetadataRow[] | null) ?? [])),
    ];
    return mapProposalSearchMetadata(rows, inventoryIds);
  } catch {
    return metadataById;
  }
}

async function fetchOwnerLoginRanks(userIds: string[]) {
  const ranks = new Map<string, number>();
  if (!supabase || userIds.length === 0) return ranks;
  const { data, error } = await supabase.rpc("rank_users_by_recent_login", {
    p_user_ids: userIds,
  });
  if (error) return ranks;
  for (const row of (data as OwnerLoginRankRow[] | null) ?? []) {
    if (row.user_id && typeof row.login_rank === "number") {
      ranks.set(row.user_id, row.login_rank);
    }
  }
  return ranks;
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

function sortSearchHits(hits: SearchHit[], sortKey: SearchSortKey) {
  const next = [...hits];
  if (sortKey === "newest") {
    return next.sort(compareSearchHitsByCreatedAt);
  }
  return next.sort(compareSearchHitsByLoginRank);
}

function compareSearchHitsByLoginRank(a: SearchHit, b: SearchHit) {
  const aRank = a.ownerLoginRank ?? Number.MAX_SAFE_INTEGER;
  const bRank = b.ownerLoginRank ?? Number.MAX_SAFE_INTEGER;
  if (aRank !== bRank) return aRank - bRank;
  return compareSearchHitsByCreatedAt(a, b);
}

function compareSearchHitsByCreatedAt(a: SearchHit, b: SearchHit) {
  const created = timestampValue(b.createdAt) - timestampValue(a.createdAt);
  if (created !== 0) return created;
  return compareSearchHits(a, b);
}

function timestampValue(value: string | null | undefined) {
  if (!value) return 0;
  const time = Date.parse(value);
  return Number.isFinite(time) ? time : 0;
}

function formatSearchCount(count: number) {
  if (count >= 1000) return "1000+";
  return String(count);
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

function buildSearchFilterOptions(hits: SearchHit[]): SearchFilterState {
  const groups = new Set<string>();
  const members = new Set<string>();
  const goodsTypes = new Set<string>();
  const tags = new Set<string>();
  for (const hit of hits) {
    if (hit.groupName) groups.add(hit.groupName);
    if (hit.characterName) members.add(hit.characterName);
    if (hit.goodsTypeName) goodsTypes.add(hit.goodsTypeName);
    hit.tagLabels.forEach((tag) => tags.add(tag));
  }
  const tagList = Array.from(tags).sort((a, b) => a.localeCompare(b, "ja"));
  return {
    groups: Array.from(groups).sort((a, b) => a.localeCompare(b, "ja")),
    members: Array.from(members).sort((a, b) => a.localeCompare(b, "ja")),
    goodsTypes: Array.from(goodsTypes).sort((a, b) => a.localeCompare(b, "ja")),
    meetupDates: buildMeetupDateOptions().map((date) => date.value),
    meetupPlaces: PREFECTURE_FILTERS,
    optionTags: DEFAULT_OPTION_TAGS,
    tags: tagList,
    exchangeMethods: EXCHANGE_FILTERS,
  };
}

function searchHitPassesFilters(hit: SearchHit, filters: SearchFilterState) {
  if (filters.groups.length > 0 && (!hit.groupName || !filters.groups.includes(hit.groupName))) {
    return false;
  }
  if (
    filters.members.length > 0 &&
    (!hit.characterName || !filters.members.includes(hit.characterName))
  ) {
    return false;
  }
  if (
    filters.goodsTypes.length > 0 &&
    (!hit.goodsTypeName || !filters.goodsTypes.includes(hit.goodsTypeName))
  ) {
    return false;
  }
  if (
    filters.tags.length > 0 &&
    !filters.tags.some((tag) => hit.tagLabels.includes(tag))
  ) {
    return false;
  }
  if (
    filters.optionTags.length > 0 &&
    !filters.optionTags.some((tag) => hit.optionTags.includes(tag))
  ) {
    return false;
  }
  if (
    filters.meetupDates.length > 0 &&
    !filters.meetupDates.some((date) => hit.meetupDates.includes(date))
  ) {
    return false;
  }
  if (
    filters.meetupPlaces.length > 0 &&
    !filters.meetupPlaces.some((place) => hit.meetupPrefectures.includes(place))
  ) {
    return false;
  }
  if (filters.exchangeMethods.length > 0) {
    const matchesMethod = filters.exchangeMethods.some((method) =>
      hit.exchangeMethods.includes(method),
    );
    if (!matchesMethod) return false;
  }
  return true;
}

function buildMeetupDateOptions() {
  const today = startOfLocalDay(new Date());
  return Array.from({ length: 35 }, (_, index): SearchFilterDateOption => {
    const date = addDays(today, index);
    return {
      value: toLocalDateKey(date),
      month: `${date.getMonth() + 1}月`,
      day: String(date.getDate()),
      weekday: "日月火水木金土"[date.getDay()] ?? "",
    };
  });
}

function mapProposalSearchMetadata(
  rows: ProposalSearchMetadataRow[],
  inventoryIds: string[],
) {
  const inventoryIdSet = new Set(inventoryIds);
  const maps = new Map<
    string,
    {
      optionTags: Set<string>;
      meetupDates: Set<string>;
      meetupPrefectures: Set<string>;
      exchangeMethods: Set<string>;
    }
  >();

  for (const row of rows) {
    const rowInventoryIds = Array.from(
      new Set([...(row.sender_have_ids ?? []), ...(row.receiver_have_ids ?? [])]),
    ).filter((id) => inventoryIdSet.has(id));
    if (rowInventoryIds.length === 0) continue;
    const optionTags = (row.option_tags ?? []).filter(Boolean);
    const meetupDate = row.meetup_start_at ? toLocalDateKey(new Date(row.meetup_start_at)) : null;
    const meetupPrefectures = extractPrefecturesFromText(row.meetup_place_name ?? "");
    const exchangeMethod = searchExchangeMethodLabel(row.exchange_method);

    for (const id of rowInventoryIds) {
      const target =
        maps.get(id) ??
        {
          optionTags: new Set<string>(),
          meetupDates: new Set<string>(),
          meetupPrefectures: new Set<string>(),
          exchangeMethods: new Set<string>(),
        };
      optionTags.forEach((tag) => target.optionTags.add(tag));
      if (meetupDate) target.meetupDates.add(meetupDate);
      meetupPrefectures.forEach((prefecture) => target.meetupPrefectures.add(prefecture));
      if (exchangeMethod) target.exchangeMethods.add(exchangeMethod);
      maps.set(id, target);
    }
  }

  return new Map(
    Array.from(maps.entries()).map(([id, value]) => [
      id,
      {
        optionTags: Array.from(value.optionTags),
        meetupDates: Array.from(value.meetupDates),
        meetupPrefectures: Array.from(value.meetupPrefectures),
        exchangeMethods: Array.from(value.exchangeMethods),
      },
    ]),
  );
}

function extractPrefecturesFromText(text: string) {
  if (!text.trim()) return [];
  return PREFECTURE_FILTERS.filter((prefecture) => {
    const short = prefecture.replace(/[都府県]$/, "");
    return text.includes(prefecture) || text.includes(short);
  });
}

function searchExchangeMethodLabel(value: string | null | undefined) {
  if (value === "mail") return "郵送";
  if (value === "both") return "どちらもOK";
  if (value === "hand") return "現地交換";
  return null;
}

function startOfLocalDay(date: Date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function addDays(date: Date, days: number) {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
}

function toLocalDateKey(date: Date) {
  if (Number.isNaN(date.getTime())) return "";
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function toggleSearchFilterValue(
  current: SearchFilterState,
  key: keyof SearchFilterState,
  value: string,
): SearchFilterState {
  const values = current[key];
  const nextValues = values.includes(value)
    ? values.filter((item) => item !== value)
    : [...values, value];
  return { ...current, [key]: nextValues };
}

function countActiveSearchFilters(filters: SearchFilterState) {
  return Object.values(filters).reduce((sum, values) => sum + values.length, 0);
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
    flex: 1,
    gap: 16,
  },
  searchScroll: {
    flex: 1,
  },
  searchContent: {
    gap: 16,
    paddingBottom: 8,
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
  filterFooter: {
    alignItems: "center",
    left: 0,
    position: "absolute",
    right: 0,
  },
  filterFooterPill: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.96)",
    borderColor: "rgba(255,255,255,0.92)",
    borderWidth: 1,
    borderRadius: 44,
    flexDirection: "row",
    gap: 22,
    justifyContent: "center",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.12,
    shadowRadius: 26,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  filterFooterButton: {
    alignItems: "center",
    backgroundColor: "rgba(168,212,230,0.14)",
    borderRadius: 999,
    height: 58,
    justifyContent: "center",
    width: 58,
  },
  filterFooterCount: {
    color: "#07333a",
    fontSize: 25,
    fontWeight: "500",
    letterSpacing: 0,
    minWidth: 76,
    textAlign: "center",
  },
  filterFooterIcon: {
    color: megrumColors.sky,
    fontSize: 27,
    fontWeight: "900",
    lineHeight: 31,
    textAlign: "center",
  },
  filterIconButtonPressed: {
    opacity: 0.86,
    transform: [{ scale: 0.96 }],
  },
  filterCountBadge: {
    alignItems: "center",
    backgroundColor: megrumColors.sky,
    borderColor: megrumColors.surface,
    borderRadius: 999,
    borderWidth: 1,
    height: 19,
    justifyContent: "center",
    minWidth: 19,
    paddingHorizontal: 5,
    position: "absolute",
    right: -3,
    top: -3,
  },
  filterCountBadgeText: {
    color: megrumColors.surface,
    fontSize: 10,
    fontWeight: "900",
  },
  filterSheetRoot: {
    backgroundColor: "rgba(20,16,29,0.32)",
    flex: 1,
    justifyContent: "flex-end",
  },
  filterSheetBackdrop: {
    bottom: 0,
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
  },
  filterSheet: {
    backgroundColor: megrumColors.background,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: "84%",
    paddingBottom: 18,
    paddingHorizontal: 18,
    paddingTop: 16,
  },
  filterSheetHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 12,
  },
  filterSheetTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  filterReset: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  filterResetText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  filterSheetContent: {
    gap: 15,
    paddingBottom: 16,
  },
  filterGroup: {
    gap: 8,
  },
  filterGroupTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  filterGroupEmpty: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
  },
  filterGroupChips: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 7,
  },
  filterCalendarGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 7,
  },
  filterDateCell: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 14,
    borderWidth: 1,
    minHeight: 58,
    paddingHorizontal: 7,
    paddingVertical: 7,
    width: 58,
  },
  filterDateCellActive: {
    backgroundColor: "rgba(166,149,216,0.16)",
    borderColor: "rgba(166,149,216,0.44)",
  },
  filterDateMonth: {
    color: megrumColors.mutedInk,
    fontSize: 8.5,
    fontWeight: "800",
  },
  filterDateDay: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
    lineHeight: 18,
    marginTop: 1,
  },
  filterDateWeekday: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "900",
  },
  filterDateTextActive: {
    color: megrumColors.lavender,
  },
  filterChipOption: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  filterChipOptionActive: {
    backgroundColor: "rgba(166,149,216,0.16)",
    borderColor: "rgba(166,149,216,0.42)",
  },
  filterChipOptionText: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
  },
  filterChipOptionTextActive: {
    color: megrumColors.lavender,
  },
  filterApply: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 15,
    paddingVertical: 14,
  },
  filterApplyText: {
    color: megrumColors.surface,
    fontSize: 14,
    fontWeight: "900",
  },
  pressed: {
    opacity: 0.86,
    transform: [{ scale: 0.99 }],
  },
});
