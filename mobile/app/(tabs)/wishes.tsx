import { router, useLocalSearchParams } from "expo-router";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  Image,
  Modal,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
} from "react-native";
import {
  BottomOptionSheet,
  ColumnSwitcher,
  FloatingAddButton,
  GoodsGrid,
  SectionTabs,
  type ColumnCount,
  type GoodsGridPressContext,
  type GoodsGridItem,
  type SheetAnchor,
  type SheetAction,
} from "../../src/components/GoodsGrid";
import { useAuth } from "../../src/auth/AuthProvider";
import { Screen } from "../../src/components/Screen";
import {
  GoodsGridSkeleton,
  ListingDeckSkeleton,
  SkeletonPillRow,
} from "../../src/components/SkeletonScreen";
import { fetchInventoryTagLabels, formatHashTags } from "../../src/lib/inventoryTags";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

type WishItem = GoodsGridItem & {
  priority: "最優先" | "優先" | "ゆる募";
  linkedListings: number;
  group: string;
  type: string;
  quantity?: number;
};

type ListingItem = {
  id: string;
  status: "ACTIVE" | "PAUSED" | "MATCHED";
  haves: ListingGoodsItem[];
  options: ListingOptionItem[];
  give: string[];
  want: string[];
  logic: "すべて" | "1pick";
  hue: string;
};

type ListingGoodsItem = {
  id: string;
  title: string;
  qty: number;
  photoUrl: string | null;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  hue: string;
};

type ListingOptionItem = {
  id: string;
  position: number;
  logic: "すべて" | "1pick";
  exchangeType: "same_kind" | "cross_kind" | "any";
  isCashOffer: boolean;
  cashAmount: number | null;
  wishes: ListingGoodsItem[];
};

type ListingWishSlot = {
  key: string;
  option: ListingOptionItem;
  wish: ListingGoodsItem | null;
};

type WishRow = {
  id: string;
  title: string;
  quantity: number;
  priority: "top" | "second" | "flexible" | null;
  hue: number | string | null;
  photo_urls: string[] | null;
  group: { name: string | null } | { name: string | null }[] | null;
  character: { name: string | null } | { name: string | null }[] | null;
  goods_type: { name: string | null } | { name: string | null }[] | null;
};

type ListingRow = {
  id: string;
  have_ids: string[] | null;
  have_qtys: number[] | null;
  have_logic: "and" | "or" | null;
  status: "active" | "paused" | "matched" | "closed";
};

type OptionRow = {
  id: string;
  listing_id: string;
  position: number;
  wish_ids: string[] | null;
  wish_qtys: number[] | null;
  logic: "and" | "or" | null;
  exchange_type: "same_kind" | "cross_kind" | "any" | null;
  is_cash_offer: boolean;
  cash_amount: number | null;
};

type InventoryLookupRow = {
  id: string;
  title: string;
  hue: number | string | null;
  photo_urls: string[] | null;
  group: { name: string | null } | { name: string | null }[] | null;
  character: { name: string | null } | { name: string | null }[] | null;
  goods_type: { name: string | null } | { name: string | null }[] | null;
};

type WishData = {
  wishes: WishItem[];
  listings: ListingItem[];
};

type Tab = "wish" | "listings";
const TAB_ORDER: Tab[] = ["wish", "listings"];

const INITIAL_WISHES: WishItem[] = [
  {
    id: "wish-01",
    title: "スア ラキドロ",
    subtitle: "LUMENA / トレカ",
    glyph: "S",
    hue: "#cbbcf4",
    badge: "最優先",
    tagLabels: ["ラキドロ", "最優先"],
    priority: "最優先",
    linkedListings: 2,
    group: "LUMENA",
    type: "トレカ",
  },
  {
    id: "wish-02",
    title: "ニンニン 制服",
    subtitle: "aespa / アクスタ",
    glyph: "N",
    hue: "#a8d4e6",
    badge: "個別募集 1",
    tagLabels: ["制服", "アクスタ"],
    priority: "優先",
    linkedListings: 1,
    group: "aespa",
    type: "アクスタ",
  },
  {
    id: "wish-03",
    title: "カリナ 店舗特典",
    subtitle: "aespa / トレカ",
    glyph: "K",
    hue: "#f3c5d4",
    badge: "未紐付け",
    tagLabels: ["店舗特典"],
    priority: "ゆる募",
    linkedListings: 0,
    group: "aespa",
    type: "トレカ",
  },
  {
    id: "wish-04",
    title: "ウィンター 缶バッジ",
    subtitle: "aespa / 缶バッジ",
    glyph: "W",
    hue: "#d5cff4",
    badge: "個別募集 1",
    tagLabels: ["缶バッジ"],
    priority: "優先",
    linkedListings: 1,
    group: "aespa",
    type: "缶バッジ",
  },
  {
    id: "wish-05",
    title: "リノ トレカ",
    subtitle: "SKZ / トレカ",
    glyph: "R",
    hue: "#b7dceb",
    badge: "ゆる募",
    tagLabels: ["トレカ"],
    priority: "ゆる募",
    linkedListings: 0,
    group: "SKZ",
    type: "トレカ",
  },
];

const INITIAL_LISTINGS: ListingItem[] = [
  {
    id: "listing-01",
    status: "ACTIVE",
    haves: [
      previewListingGoods("preview-have-1", "スア 春ver.", "LUMENA", "スア", "トレカ", "#cbbcf4", 1),
      previewListingGoods("preview-have-2", "ジョンウ ラキドロ", "LUMENA", "ジョンウ", "トレカ", "#a8d4e6", 1),
    ],
    options: [
      {
        id: "listing-01-option-1",
        position: 1,
        logic: "1pick",
        exchangeType: "any",
        isCashOffer: false,
        cashAmount: null,
        wishes: [
          previewListingGoods("preview-wish-1", "スア ラキドロ", "LUMENA", "スア", "トレカ", "#f3c5d4", 1),
        ],
      },
    ],
    give: ["スア 春ver.", "ジョンウ ラキドロ"],
    want: ["スア ラキドロ"],
    logic: "1pick",
    hue: "#cbbcf4",
  },
  {
    id: "listing-02",
    status: "ACTIVE",
    haves: [
      previewListingGoods("preview-have-3", "ニンニン アクスタ", "aespa", "ニンニン", "アクスタ", "#a8d4e6", 1),
    ],
    options: [
      {
        id: "listing-02-option-1",
        position: 1,
        logic: "すべて",
        exchangeType: "same_kind",
        isCashOffer: false,
        cashAmount: null,
        wishes: [
          previewListingGoods("preview-wish-2", "ニンニン 制服", "aespa", "ニンニン", "アクスタ", "#f3c5d4", 1),
          previewListingGoods("preview-wish-4", "ウィンター 缶バッジ", "aespa", "ウィンター", "缶バッジ", "#d5cff4", 1),
        ],
      },
    ],
    give: ["ニンニン アクスタ"],
    want: ["ニンニン 制服", "ウィンター 缶バッジ"],
    logic: "すべて",
    hue: "#a8d4e6",
  },
  {
    id: "listing-03",
    status: "PAUSED",
    haves: [
      previewListingGoods("preview-have-4", "カリナ 缶バッジ", "aespa", "カリナ", "缶バッジ", "#f3c5d4", 1),
    ],
    options: [
      {
        id: "listing-03-option-1",
        position: 1,
        logic: "1pick",
        exchangeType: "any",
        isCashOffer: false,
        cashAmount: null,
        wishes: [
          previewListingGoods("preview-wish-3", "カリナ 店舗特典", "aespa", "カリナ", "トレカ", "#cbbcf4", 1),
        ],
      },
    ],
    give: ["カリナ 缶バッジ"],
    want: ["カリナ 店舗特典"],
    logic: "1pick",
    hue: "#f3c5d4",
  },
];

export default function WishesScreen() {
  const { user, previewMode } = useAuth();
  const params = useLocalSearchParams<{
    tab?: Tab | Tab[];
    refresh?: string | string[];
  }>();
  const routeTab = one(params.tab);
  const routeRefresh = one(params.refresh);
  const { width: windowWidth } = useWindowDimensions();
  const pageWidth = Math.max(1, windowWidth - 36);
  const [tab, setTab] = useState<Tab>(
    routeTab === "listings" ? "listings" : "wish",
  );
  const [columns, setColumns] = useState<ColumnCount>(3);
  const [wishes, setWishes] = useState<WishItem[]>(() =>
    !supabase || previewMode ? INITIAL_WISHES : [],
  );
  const [listings, setListings] = useState<ListingItem[]>(() =>
    !supabase || previewMode ? INITIAL_LISTINGS : [],
  );
  const [selectedWish, setSelectedWish] = useState<WishItem | null>(null);
  const [selectedWishAnchor, setSelectedWishAnchor] = useState<SheetAnchor | null>(null);
  const [deleteConfirmWish, setDeleteConfirmWish] = useState<WishItem | null>(null);
  const [deletingWishIds, setDeletingWishIds] = useState<string[]>([]);
  const [selectedListing, setSelectedListing] = useState<ListingItem | null>(
    null,
  );
  const [deleteConfirmListing, setDeleteConfirmListing] =
    useState<ListingItem | null>(null);
  const [activeGroup, setActiveGroup] = useState<string | null>(null);
  const [activeType, setActiveType] = useState<string | null>(null);
  const [loading, setLoading] = useState(!!supabase && !previewMode);
  const [loadError, setLoadError] = useState<string | null>(null);
  const pagerRef = useRef<ScrollView>(null);
  const [pagerPosition, setPagerPosition] = useState(() =>
    TAB_ORDER.indexOf(routeTab === "listings" ? "listings" : "wish"),
  );

  useEffect(() => {
    if (routeTab === "listings" || routeTab === "wish") {
      const nextIndex = TAB_ORDER.indexOf(routeTab);
      setTab(routeTab);
      setPagerPosition(nextIndex);
      pagerRef.current?.scrollTo({ x: nextIndex * pageWidth, animated: false });
    }
  }, [pageWidth, routeTab]);

  useEffect(() => {
    if (!supabase || previewMode) {
      setWishes(INITIAL_WISHES);
      setListings(INITIAL_LISTINGS);
      setLoading(false);
      setLoadError(null);
      return;
    }
    if (!user) {
      setWishes([]);
      setListings([]);
      setLoading(false);
      setLoadError(null);
      return;
    }

    let active = true;
    setLoading(true);
    setLoadError(null);
    fetchWishData(user.id)
      .then((data) => {
        if (!active) return;
        setWishes(data.wishes);
        setListings(data.listings);
      })
      .catch((error: unknown) => {
        if (!active) return;
        setWishes([]);
        setListings([]);
        setLoadError(error instanceof Error ? error.message : "読み込みに失敗しました");
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, routeRefresh, user]);

  function toggleListingStatus(id: string) {
    const current = listings.find((item) => item.id === id);
    if (!current || current.status === "MATCHED") return;
    const nextStatus = current?.status === "ACTIVE" ? "paused" : "active";
    setListings((current) =>
      current.map((item) =>
        item.id === id
          ? {
              ...item,
              status: item.status === "ACTIVE" ? "PAUSED" : "ACTIVE",
            }
          : item,
      ),
    );
    setSelectedListing(null);
    if (supabase && user && !previewMode) {
      supabase
        .from("listings")
        .update({ status: nextStatus })
        .eq("id", id)
        .eq("user_id", user.id)
        .then(({ error }) => {
          if (error) setLoadError(error.message);
        });
    }
  }

  function deleteListing(id: string) {
    const target = listings.find((item) => item.id === id);
    if (target?.status === "MATCHED") return;
    setListings((current) => current.filter((item) => item.id !== id));
    setSelectedListing(null);
    if (supabase && user && !previewMode) {
      void closeListing({ listingId: id, userId: user.id }).catch((error: unknown) => {
        setLoadError(error instanceof Error ? error.message : "個別募集の削除に失敗しました");
        if (target) {
          setListings((current) =>
            current.some((item) => item.id === target.id) ? current : [target, ...current],
          );
        }
      });
    }
  }

  function requestDeleteListing(listing: ListingItem) {
    if (listing.status === "MATCHED") return;
    setSelectedListing(null);
    setDeleteConfirmListing(listing);
  }

  function confirmListingDelete() {
    if (!deleteConfirmListing) return;
    const target = deleteConfirmListing;
    setDeleteConfirmListing(null);
    deleteListing(target.id);
  }

  const groupOptions = useMemo(() => {
    const values = new Set<string>();
    for (const wish of wishes) values.add(wish.group);
    return Array.from(values).sort((a, b) => a.localeCompare(b, "ja"));
  }, [wishes]);
  const typeOptions = useMemo(() => {
    const values = new Set<string>();
    for (const wish of wishes) values.add(wish.type);
    return Array.from(values).sort((a, b) => a.localeCompare(b, "ja"));
  }, [wishes]);
  const filteredWishes = useMemo(
    () =>
      wishes.filter((wish) => {
        if (activeGroup && wish.group !== activeGroup) return false;
        if (activeType && wish.type !== activeType) return false;
        return true;
      }),
    [activeGroup, activeType, wishes],
  );

  const tabs = useMemo(
    () => [
      {
        id: "wish" as const,
        label: "Wish",
        count: filteredWishes.length,
        color: megrumColors.lavender,
      },
      {
        id: "listings" as const,
        label: "個別募集",
        count: listings.length,
        color: megrumColors.sky,
      },
    ],
    [filteredWishes.length, listings.length],
  );
  const wishGridItems = useMemo(
    () =>
      filteredWishes.map((wish) => ({
        ...wish,
        badge:
          wish.linkedListings === 0
            ? "未紐付け"
            : `募集 ${wish.linkedListings}`,
      })),
    [filteredWishes],
  );

  const wishActions = selectedWish
    ? buildWishActions({
        item: selectedWish,
        onClose: closeSelectedWish,
        onEdit: () => {
          const wish = selectedWish;
          closeSelectedWish();
          openWishEditor(wish, "edit");
        },
        onListing: () => {
          const wish = selectedWish;
          closeSelectedWish();
          openListingEditor(null, "create", wish);
        },
        onDelete: () => {
          const wish = selectedWish;
          closeSelectedWish();
          setDeleteConfirmWish(wish);
        },
      })
    : [];

  function confirmWishDelete() {
    if (!deleteConfirmWish) return;
    const target = deleteConfirmWish;
    setDeleteConfirmWish(null);
    setDeletingWishIds((current) =>
      current.includes(target.id) ? current : [...current, target.id],
    );
  }

  function completeWishDelete(id: string) {
    const target = wishes.find((item) => item.id === id);
    setDeletingWishIds((current) => current.filter((itemId) => itemId !== id));
    setWishes((current) => current.filter((item) => item.id !== id));
    if (supabase && user && !previewMode) {
      void archiveWish({ userId: user.id, wishId: id })
        .then(() => {
          setListings((current) =>
            current.filter((listing) =>
              listing.options.every((option) =>
                option.wishes.every((wish) => wish.id !== id),
              ),
            ),
          );
          setLoadError(null);
        })
        .catch((error: unknown) => {
          setLoadError(error instanceof Error ? error.message : "wish の削除に失敗しました");
          if (target) {
            setWishes((current) =>
              current.some((item) => item.id === target.id)
                ? current
                : [target, ...current],
            );
          }
        });
    }
  }

  const listingActions = selectedListing
    ? buildListingActions({
        item: selectedListing,
        onClose: () => setSelectedListing(null),
        onEdit: () => {
          const listing = selectedListing;
          setSelectedListing(null);
          openListingEditor(listing, "edit");
        },
        onToggle: () => toggleListingStatus(selectedListing.id),
        onDelete: () => requestDeleteListing(selectedListing),
      })
    : [];

  return (
    <Screen scroll={false} contentStyle={styles.screenContent}>
      <ScrollView
        automaticallyAdjustsScrollIndicatorInsets
        contentInsetAdjustmentBehavior="automatic"
        showsVerticalScrollIndicator={false}
        stickyHeaderIndices={[0]}
        style={styles.screenScroll}
        contentContainerStyle={styles.screenScrollContent}
      >
        <View style={styles.stickyHeaderBlock}>
          <View style={styles.header}>
            <Text style={styles.title}>ウィッシュ</Text>
            <View style={styles.headerActions}>
              {tab === "wish" ? (
                <ColumnSwitcher value={columns} onChange={setColumns} />
              ) : null}
            </View>
          </View>

          <SectionTabs
            value={tab}
            tabs={tabs}
            position={pagerPosition}
            onChange={selectTab}
          />
        </View>

        {loadError ? <Text style={styles.inlineError}>{loadError}</Text> : null}

        {loading ? (
          <View style={styles.loadingSkeleton}>
            {tab === "wish" ? (
              <>
                <SkeletonPillRow count={2} />
                <GoodsGridSkeleton columns={columns} count={9} />
              </>
            ) : (
              <ListingDeckSkeleton count={3} />
            )}
          </View>
        ) : (
          <>
            {tab === "wish" ? (
              <View style={styles.filters}>
                <WishFilterRow
                  label="推し"
                  options={groupOptions}
                  active={activeGroup}
                  onChange={(next) => {
                    setActiveGroup(next);
                    closeSelectedWish();
                  }}
                />
                <WishFilterRow
                  label="種別"
                  options={typeOptions}
                  active={activeType}
                  onChange={(next) => {
                    setActiveType(next);
                    closeSelectedWish();
                  }}
                />
              </View>
            ) : null}

            <ScrollView
              ref={pagerRef}
              horizontal
              pagingEnabled
              bounces={false}
              directionalLockEnabled
              showsHorizontalScrollIndicator={false}
              scrollEventThrottle={16}
              style={styles.contentHost}
              onScroll={handlePagerScroll}
              onMomentumScrollEnd={handlePagerSettled}
            >
              {TAB_ORDER.map((pageTab) => (
                <View key={pageTab} style={[styles.tabPage, { width: pageWidth }]}>
                  {renderTabPage(pageTab)}
                </View>
              ))}
            </ScrollView>
          </>
        )}
      </ScrollView>

      <FloatingAddButton
        label={tab === "wish" ? "Wishを追加" : "個別募集を追加"}
        onPress={() => {
          if (tab === "wish") {
            openWishEditor(null, "create");
            return;
          }

          openListingEditor(null, "create");
        }}
      />

      <BottomOptionSheet
        visible={!!selectedWish}
        title={selectedWish?.title ?? ""}
        anchor={selectedWishAnchor}
        presentation="glass"
        preview={
          selectedWish
            ? {
                glyph: selectedWish.glyph,
                hue: selectedWish.hue,
                photoUrl: selectedWish.photoUrl,
              }
            : null
        }
        subtitle={formatHashTags(selectedWish?.tagLabels) ?? "タグ未設定"}
        actions={wishActions}
        onClose={closeSelectedWish}
      />

      <WishDeleteConfirmModal
        item={deleteConfirmWish}
        onCancel={() => setDeleteConfirmWish(null)}
        onConfirm={confirmWishDelete}
      />

      <ListingDeleteConfirmModal
        item={deleteConfirmListing}
        onCancel={() => setDeleteConfirmListing(null)}
        onConfirm={confirmListingDelete}
      />

      <BottomOptionSheet
        visible={!!selectedListing}
        title="個別募集"
        subtitle={
          selectedListing
            ? `${listingStatusLabel(selectedListing.status)} / ${selectedListing.logic}`
            : undefined
        }
        actions={listingActions}
        onClose={() => setSelectedListing(null)}
      />
    </Screen>
  );

  function selectTab(next: Tab) {
    if (!TAB_ORDER.includes(next)) return;
    setTab(next);
    closeSelectedWish();
    setSelectedListing(null);
    const nextIndex = TAB_ORDER.indexOf(next);
    setPagerPosition(nextIndex);
    pagerRef.current?.scrollTo({ x: nextIndex * pageWidth, animated: true });
  }

  function closeSelectedWish() {
    setSelectedWish(null);
    setSelectedWishAnchor(null);
  }

  function handlePagerScroll(event: NativeSyntheticEvent<NativeScrollEvent>) {
    setPagerPosition(event.nativeEvent.contentOffset.x / pageWidth);
  }

  function handlePagerSettled(event: NativeSyntheticEvent<NativeScrollEvent>) {
    const nextIndex = Math.max(
      0,
      Math.min(TAB_ORDER.length - 1, Math.round(event.nativeEvent.contentOffset.x / pageWidth)),
    );
    const next = TAB_ORDER[nextIndex] ?? "wish";
    setTab(next);
    setPagerPosition(nextIndex);
    closeSelectedWish();
    setSelectedListing(null);
  }

  function renderTabPage(pageTab: Tab) {
    if (pageTab === "wish") {
      return (
        <GoodsGrid
          items={wishGridItems}
          columns={columns}
          emptyLabel="まだ Wish がありません"
          deletingIds={deletingWishIds}
          onItemFadeOutEnd={completeWishDelete}
          showTopRow={false}
          showUnlinkedWarning
          onPressItem={(gridItem, context) => {
            if (deletingWishIds.includes(gridItem.id)) return;
            const wish = wishes.find((item) => item.id === gridItem.id);
            if (!wish) return;
            setSelectedWishAnchor(normalizePressContext(context));
            setSelectedWish(wish);
          }}
        />
      );
    }
    return (
      <ListingsPanel
        listings={listings}
        onSelect={setSelectedListing}
        onEdit={(listing) => openListingEditor(listing, "edit")}
        onDelete={requestDeleteListing}
      />
    );
  }
}

async function fetchWishData(userId: string): Promise<WishData> {
  if (!supabase) {
    return { wishes: INITIAL_WISHES, listings: INITIAL_LISTINGS };
  }
  const [{ data: wishRowsRaw, error: wishError }, { data: listingRowsRaw, error: listingError }] =
    await Promise.all([
      supabase
        .from("goods_inventory")
        .select(
          "id, title, quantity, priority, hue, photo_urls, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
        )
        .eq("user_id", userId)
        .eq("kind", "wanted")
        .neq("status", "archived")
        .order("created_at", { ascending: false }),
      supabase
        .from("listings")
        .select("id, have_ids, have_qtys, have_logic, status")
        .eq("user_id", userId)
        .neq("status", "closed")
        .order("created_at", { ascending: false }),
    ]);
  if (wishError) throw wishError;
  if (listingError) throw listingError;

  const wishRows = (wishRowsRaw as WishRow[] | null) ?? [];
  const tagLabelsByWishId = await fetchInventoryTagLabels(wishRows.map((wish) => wish.id));
  const listingRows = (listingRowsRaw as ListingRow[] | null) ?? [];
  const listingIds = listingRows.map((listing) => listing.id);
  const { data: optionRowsRaw, error: optionError } =
    listingIds.length > 0
      ? await supabase
          .from("listing_wish_options")
          .select("id, listing_id, position, wish_ids, wish_qtys, logic, exchange_type, is_cash_offer, cash_amount")
          .in("listing_id", listingIds)
          .order("position", { ascending: true })
      : { data: [], error: null };
  if (optionError) throw optionError;
  const optionRows = (optionRowsRaw as OptionRow[] | null) ?? [];
  const optionsByListing = new Map<string, OptionRow[]>();
  for (const option of optionRows) {
    const options = optionsByListing.get(option.listing_id) ?? [];
    options.push(option);
    optionsByListing.set(option.listing_id, options);
  }

  const wishIdsInListings = new Map<string, number>();
  for (const option of optionRows) {
    for (const wishId of option.wish_ids ?? []) {
      wishIdsInListings.set(wishId, (wishIdsInListings.get(wishId) ?? 0) + 1);
    }
  }

  const allItemIds = Array.from(
    new Set([
      ...wishRows.map((wish) => wish.id),
      ...listingRows.flatMap((listing) => listing.have_ids ?? []),
      ...optionRows.flatMap((option) => option.wish_ids ?? []),
    ]),
  );
  const { data: inventoryRowsRaw, error: inventoryError } =
    allItemIds.length > 0
      ? await supabase
          .from("goods_inventory")
          .select(
            "id, title, hue, photo_urls, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
          )
          .in("id", allItemIds)
      : { data: [], error: null };
  if (inventoryError) throw inventoryError;
  const inventoryById = new Map(
    ((inventoryRowsRaw as InventoryLookupRow[] | null) ?? []).map((item) => [
      item.id,
      item,
    ]),
  );

  return {
    wishes: wishRows.map((wish) =>
      toWishItem(wish, wishIdsInListings.get(wish.id) ?? 0, tagLabelsByWishId[wish.id] ?? []),
    ),
    listings: listingRows.map((listing) =>
      toListingItem(listing, optionsByListing.get(listing.id) ?? [], inventoryById),
    ),
  };
}

function toWishItem(row: WishRow, linkedListings: number, tagLabels: string[] = []): WishItem {
  const groupName = pickName(row.group) ?? "未設定";
  const characterName = pickName(row.character) ?? groupName;
  const goodsType = pickName(row.goods_type) ?? "グッズ";
  const priority = priorityLabel(row.priority);
  return {
    id: row.id,
    title: row.title || `${characterName} ${goodsType}`,
    subtitle: `${groupName} / ${goodsType}`,
    glyph: characterName.slice(0, 1),
    hue: normalizeHue(row.hue, characterName),
    badge: linkedListings > 0 ? `募集 ${linkedListings}` : "未紐付け",
    tagLabels,
    priority,
    linkedListings,
    group: groupName,
    type: goodsType,
    quantity: row.quantity,
    photoUrl: row.photo_urls?.[0] ?? null,
  };
}

function toListingItem(
  row: ListingRow,
  options: OptionRow[],
  inventoryById: Map<string, InventoryLookupRow>,
): ListingItem {
  const haves = (row.have_ids ?? []).flatMap((id, index) => {
    const source = inventoryById.get(id);
    return source ? [toListingGoodsItem(source, row.have_qtys?.[index] ?? 1)] : [];
  });
  const optionItems: ListingOptionItem[] = [...options]
    .sort((a, b) => a.position - b.position)
    .map((option) => ({
      id: option.id,
      position: option.position,
      logic: option.logic === "and" ? "すべて" : "1pick" as const,
      exchangeType: option.exchange_type ?? "any",
      isCashOffer: !!option.is_cash_offer,
      cashAmount: option.cash_amount ?? null,
      wishes: (option.wish_ids ?? []).flatMap((id, index) => {
        const source = inventoryById.get(id);
        return source ? [toListingGoodsItem(source, option.wish_qtys?.[index] ?? 1)] : [];
      }),
    }));
  const giveLabels = haves.map((item) => shortItemLabel(item));
  const wantLabels = optionItems.flatMap((option) => {
    if (option.isCashOffer) {
      return [`定価 ${option.cashAmount ?? ""}円`];
    }
    return option.wishes.map(shortItemLabel);
  });
  const seed = giveLabels[0] ?? wantLabels[0] ?? "募集";
  return {
    id: row.id,
    status:
      row.status === "active"
        ? "ACTIVE"
        : row.status === "matched"
          ? "MATCHED"
          : "PAUSED",
    haves,
    options: optionItems,
    give: giveLabels.length > 0 ? giveLabels : ["譲る候補"],
    want: wantLabels.length > 0 ? wantLabels : ["求めるもの"],
    logic: row.have_logic === "and" ? "すべて" : "1pick",
    hue: haves[0]?.hue ?? normalizeHue(inventoryById.get(row.have_ids?.[0] ?? "")?.hue, seed),
  };
}

function shortItemLabel(item: ListingGoodsItem) {
  return item.characterName ?? item.groupName ?? item.title;
}

function toListingGoodsItem(row: InventoryLookupRow, qty: number): ListingGoodsItem {
  const groupName = pickName(row.group);
  const characterName = pickName(row.character);
  const goodsTypeName = pickName(row.goods_type);
  const seed = characterName ?? groupName ?? row.title;
  return {
    id: row.id,
    title: row.title,
    qty: Math.max(1, qty || 1),
    photoUrl: row.photo_urls?.[0] ?? null,
    groupName,
    characterName,
    goodsTypeName,
    hue: normalizeHue(row.hue, seed),
  };
}

function previewListingGoods(
  id: string,
  title: string,
  groupName: string,
  characterName: string,
  goodsTypeName: string,
  hue: string,
  qty: number,
): ListingGoodsItem {
  return {
    id,
    title,
    qty,
    photoUrl: null,
    groupName,
    characterName,
    goodsTypeName,
    hue,
  };
}

function priorityLabel(priority: WishRow["priority"]): WishItem["priority"] {
  if (priority === "top") return "最優先";
  if (priority === "flexible") return "ゆる募";
  return "優先";
}

function listingStatusLabel(status: ListingItem["status"]) {
  if (status === "ACTIVE") return "ACTIVE";
  if (status === "MATCHED") return "取引中";
  return "一時停止";
}

async function closeListing({
  listingId,
  userId,
}: {
  listingId: string;
  userId: string;
}) {
  if (!supabase) return;
  const { error } = await supabase
    .from("listings")
    .update({ status: "closed" })
    .eq("id", listingId)
    .eq("user_id", userId)
    .in("status", ["active", "paused"]);
  if (error) throw error;
}

async function archiveWish({
  userId,
  wishId,
}: {
  userId: string;
  wishId: string;
}) {
  if (!supabase) return;
  await closeListingsUsingWishes(userId, [wishId]);
  const { error } = await supabase
    .from("goods_inventory")
    .update({ status: "archived" })
    .eq("id", wishId)
    .eq("user_id", userId)
    .eq("kind", "wanted");
  if (error) throw error;
}

async function closeListingsUsingWishes(userId: string, wishIds: string[]) {
  if (!supabase || wishIds.length === 0) return;
  const listingIds = new Set<string>();

  for (const wishId of wishIds) {
    const { data, error } = await supabase
      .from("listing_wish_options")
      .select("listing_id, listing:listings!inner(user_id, status)")
      .contains("wish_ids", [wishId]);
    if (error) throw error;

    for (const row of
      (data as {
        listing_id: string;
        listing:
          | { user_id?: string | null; status?: string | null }
          | { user_id?: string | null; status?: string | null }[]
          | null;
      }[] | null) ?? []) {
      const listing = Array.isArray(row.listing) ? row.listing[0] : row.listing;
      if (
        listing?.user_id === userId &&
        (listing.status === "active" || listing.status === "paused")
      ) {
        listingIds.add(row.listing_id);
      }
    }
  }

  const ids = Array.from(listingIds);
  if (ids.length === 0) return;
  const { error: updateError } = await supabase
    .from("listings")
    .update({ status: "closed" })
    .eq("user_id", userId)
    .in("id", ids);
  if (updateError) throw updateError;
}

function pickName(
  value:
    | { name: string | null }
    | { name: string | null }[]
    | null
    | undefined,
) {
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
  for (let i = 0; i < name.length; i++) {
    hash = (hash << 5) - hash + name.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash) % 360;
}

function one(value?: string | string[]) {
  return Array.isArray(value) ? value[0] : value;
}

function normalizePressContext(context: GoodsGridPressContext): SheetAnchor {
  return {
    pageX: Number.isFinite(context.pageX) ? context.pageX : 0,
    pageY: Number.isFinite(context.pageY) ? context.pageY : 0,
  };
}

function openWishEditor(
  wish: WishItem | null,
  mode: "create" | "edit",
) {
  router.push({
    pathname: "/goods-editor",
    params: {
      kind: "wish",
      mode,
      id: wish?.id ?? "",
      title: wish?.title ?? "",
      subtitle: wish?.subtitle ?? "",
      group: wish?.group ?? "",
      goodsType: wish?.type ?? "",
      note: wish?.priority ?? "",
      glyph: wish?.glyph ?? "",
      hue: wish?.hue ?? "#f3c5d4",
      badge:
        wish == null
          ? "NEW"
          : wish.linkedListings === 0
            ? "未紐付け"
            : `募集 ${wish.linkedListings}`,
      quantity: wish?.quantity ? String(wish.quantity) : "1",
    },
  });
}

function openListingEditor(
  listing: ListingItem | null,
  mode: "create" | "edit",
  wish?: WishItem | null,
) {
  router.push({
    pathname: "/listing-editor",
    params: {
      mode,
      id: listing?.id ?? "",
      wishId: wish?.id ?? "",
      status: listing?.status ?? "ACTIVE",
      logic: listing?.logic ?? "1pick",
      give: listing?.give.join("、") ?? "",
      want: listing?.want.join("、") ?? wish?.title ?? "",
    },
  });
}

function WishFilterRow({
  label,
  options,
  active,
  onChange,
}: {
  label: string;
  options: string[];
  active: string | null;
  onChange: (next: string | null) => void;
}) {
  if (options.length === 0) return null;

  return (
    <View style={styles.filterRow}>
      <Text style={styles.filterLabel}>{label}</Text>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.filterChips}
      >
        <WishFilterChip
          label="すべて"
          active={active === null}
          onPress={() => onChange(null)}
        />
        {options.map((option) => (
          <WishFilterChip
            key={option}
            label={option}
            active={active === option}
            onPress={() => onChange(option)}
          />
        ))}
      </ScrollView>
    </View>
  );
}

function WishFilterChip({
  label,
  active,
  onPress,
}: {
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected: active }}
      onPress={onPress}
      style={[styles.filterChip, active ? styles.filterChipActive : null]}
    >
      <Text
        numberOfLines={1}
        style={[styles.filterChipText, active ? styles.filterChipTextActive : null]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

function ListingsPanel({
  listings,
  onSelect,
  onEdit,
  onDelete,
}: {
  listings: ListingItem[];
  onSelect: (listing: ListingItem) => void;
  onEdit: (listing: ListingItem) => void;
  onDelete: (listing: ListingItem) => void;
}) {
  if (listings.length === 0) {
    return (
      <View style={styles.listingEmpty}>
        <Text style={styles.listingEmptyText}>まだ個別募集がありません</Text>
      </View>
    );
  }

  return (
    <View style={styles.listingsHost}>
      <ListingDeck
        listings={listings}
        onSelect={onSelect}
        onEdit={onEdit}
        onDelete={onDelete}
      />
    </View>
  );
}

function ListingDeck({
  listings,
  onSelect,
  onEdit,
  onDelete,
}: {
  listings: ListingItem[];
  onSelect: (listing: ListingItem) => void;
  onEdit: (listing: ListingItem) => void;
  onDelete: (listing: ListingItem) => void;
}) {
  return (
    <View style={styles.deckSection}>
      <View style={styles.deckHeader}>
        <Text style={styles.deckTitle}>募集デッキ</Text>
        <Text style={styles.deckCount}>{listings.length}件</Text>
      </View>
      <View style={styles.deckList}>
        {listings.map((listing) => (
          <ListingDeckCard
            key={listing.id}
            listing={listing}
            onPress={() => onSelect(listing)}
            onEdit={() => onEdit(listing)}
            onDelete={() => onDelete(listing)}
          />
        ))}
      </View>
    </View>
  );
}

function ListingDeckCard({
  listing,
  onPress,
  onEdit,
  onDelete,
}: {
  listing: ListingItem;
  onPress: () => void;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const slots = getListingWishSlots(listing);
  return (
    <Pressable onPress={onPress} style={styles.deckCard}>
      <View style={styles.deckCardGlowPink} />
      <View style={styles.deckCardGlowSky} />
      <View style={styles.deckTop}>
        <StatusBadge status={listing.status} />
        <Text numberOfLines={1} style={styles.deckMeta}>
          {listing.logic}
        </Text>
        <View style={styles.listingActions}>
          <MiniIcon
            label="✎"
            accessibilityLabel={
              listing.status === "MATCHED" ? "個別募集の詳細" : "個別募集を編集"
            }
            onPress={onEdit}
          />
          {listing.status !== "MATCHED" ? (
            <MiniIcon label="×" accessibilityLabel="個別募集を削除" danger onPress={onDelete} />
          ) : null}
        </View>
      </View>

      <View style={styles.deckBodyRich}>
        <DeckGoodsStack label="譲る" items={listing.haves} accent={megrumColors.sky} />
        <View style={styles.deckCord}>
          <View style={styles.deckCordLine} />
          <View style={styles.deckKnot}>
            <Text style={styles.deckKnotText}>∿</Text>
          </View>
        </View>
        <DeckWishCluster slots={slots} />
      </View>
    </Pressable>
  );
}

function StatusBadge({ status }: { status: ListingItem["status"] }) {
  const active = status === "ACTIVE";
  const matched = status === "MATCHED";
  return (
    <View
      style={[
        styles.statusBadge,
        active ? styles.statusBadgeActive : null,
        matched ? styles.statusBadgeMatched : null,
      ]}
    >
      <Text
        style={[
          styles.statusBadgeText,
          active ? styles.statusBadgeTextActive : null,
          matched ? styles.statusBadgeTextMatched : null,
        ]}
      >
        {listingStatusLabel(status)}
      </Text>
    </View>
  );
}

function getListingWishSlots(listing: ListingItem): ListingWishSlot[] {
  return [...listing.options]
    .sort((a, b) => a.position - b.position)
    .flatMap<ListingWishSlot>((option) => {
      if (option.isCashOffer) {
        return [{ key: `${option.id}:cash`, option, wish: null }];
      }
      return option.wishes.map((wish) => ({
        key: `${option.id}:${wish.id}`,
        option,
        wish,
      }));
    });
}

function DeckGoodsStack({
  label,
  items,
  accent,
}: {
  label: string;
  items: ListingGoodsItem[];
  accent: string;
}) {
  return (
    <View style={styles.deckSide}>
      <Text style={styles.deckSideLabel}>{label}</Text>
      <View style={styles.deckGoodsGrid}>
        {items.map((item, index) => (
          <View key={`${item.id}-${index}`} style={styles.deckGoodsTile}>
            <DeckGoodsVisual item={item} size={54} accent={accent} />
            <Text numberOfLines={2} style={styles.deckGoodsName}>
              {shortItemLabel(item)}
            </Text>
          </View>
        ))}
        {items.length === 0 ? (
          <View style={styles.deckGoodsTile}>
            <DeckEmptyVisual label="譲" size={54} />
            <Text numberOfLines={1} style={styles.deckGoodsName}>
              未設定
            </Text>
          </View>
        ) : null}
      </View>
    </View>
  );
}

function DeckWishCluster({ slots }: { slots: ListingWishSlot[] }) {
  return (
    <View style={styles.deckSide}>
      <Text style={styles.deckSideLabel}>求める</Text>
      <View style={styles.deckGoodsGrid}>
        {slots.map((slot) => (
          <View key={slot.key} style={styles.deckGoodsTile}>
            {slot.option.isCashOffer ? (
              <DeckCashVisual amount={slot.option.cashAmount} size={54} />
            ) : slot.wish ? (
              <DeckGoodsVisual item={slot.wish} size={54} accent={megrumColors.pink} />
            ) : (
              <DeckEmptyVisual label="求" size={54} />
            )}
            <Text numberOfLines={2} style={styles.deckGoodsName}>
              {listingWishSlotLabel(slot)}
            </Text>
          </View>
        ))}
        {slots.length === 0 ? (
          <View style={styles.deckGoodsTile}>
            <DeckEmptyVisual label="求" size={54} />
            <Text numberOfLines={1} style={styles.deckGoodsName}>
              未設定
            </Text>
          </View>
        ) : null}
      </View>
    </View>
  );
}

function listingWishSlotLabel(slot: ListingWishSlot) {
  if (slot.option.isCashOffer) {
    return slot.option.cashAmount == null
      ? "定価 相談"
      : `定価 ${slot.option.cashAmount.toLocaleString()}円`;
  }
  return slot.wish ? shortItemLabel(slot.wish) : "求めるもの";
}

function DeckGoodsVisual({
  item,
  size,
  accent,
}: {
  item: ListingGoodsItem;
  size: number;
  accent: string;
}) {
  const glyph = shortItemLabel(item).slice(0, 1) || "?";
  return (
    <View
      style={[
        styles.deckGoodsVisual,
        {
          borderColor: accent,
          height: size,
          width: size,
          borderRadius: size >= 76 ? 18 : 14,
          backgroundColor: item.photoUrl ? megrumColors.surface : item.hue,
        },
      ]}
    >
      {item.photoUrl ? (
        <Image source={{ uri: item.photoUrl }} resizeMode="cover" style={styles.deckGoodsImage} />
      ) : (
        <Text style={[styles.deckGoodsGlyph, { fontSize: Math.max(18, size * 0.34) }]}>
          {glyph}
        </Text>
      )}
      <View style={styles.deckQtyBadge}>
        <Text style={styles.deckQtyText}>×{item.qty}</Text>
      </View>
    </View>
  );
}

function DeckCashVisual({
  amount,
  size,
}: {
  amount: number | null;
  size: number;
}) {
  return (
    <View style={[styles.deckCashVisual, { height: size, width: size }]}>
      <Text style={styles.deckCashSymbol}>¥</Text>
      <Text numberOfLines={1} style={styles.deckCashText}>
        {amount?.toLocaleString() ?? "相談"}
      </Text>
    </View>
  );
}

function DeckEmptyVisual({ label, size }: { label: string; size: number }) {
  return (
    <View style={[styles.deckEmptyVisual, { height: size, width: size }]}>
      <Text style={styles.deckEmptyText}>{label}</Text>
    </View>
  );
}

function ListingCard({
  listing,
  onPress,
  onEdit,
  onToggle,
  onDelete,
}: {
  listing: ListingItem;
  onPress: () => void;
  onEdit: () => void;
  onToggle: () => void;
  onDelete: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={styles.listingCard}>
      <View style={styles.listingTop}>
        <StatusBadge status={listing.status} />
        <View style={styles.listingTopText}>
          <Text style={styles.listingTitle}>
            {listing.status === "ACTIVE" ? "ACTIVE" : "PAUSED"}
          </Text>
          <Text style={styles.listingSub}>{listing.logic}</Text>
        </View>
        <View style={styles.listingActions}>
          <MiniIcon label="✎" accessibilityLabel="個別募集を編集" onPress={onEdit} />
          <MiniIcon
            label={listing.status === "ACTIVE" ? "II" : "ON"}
            accessibilityLabel={listing.status === "ACTIVE" ? "個別募集を一時停止" : "個別募集を再開"}
            onPress={onToggle}
          />
          <MiniIcon label="×" accessibilityLabel="個別募集を削除" danger onPress={onDelete} />
        </View>
      </View>

      <View style={styles.tradeLine}>
        <TradeSide
          label="譲"
          items={listing.haves}
          values={listing.give}
          hue={listing.hue}
          logic={listing.logic}
        />
        <View style={styles.tradeConnector}>
          <View style={styles.tradeConnectorDot} />
          <View style={styles.tradeConnectorLine} />
          <View style={styles.tradeConnectorDot} />
        </View>
        <TradeSide
          label="求"
          items={getListingWishSlots(listing).flatMap((slot) => (slot.wish ? [slot.wish] : []))}
          values={listing.want}
          hue="#f3c5d4"
          logic={listing.logic}
          right
        />
      </View>
    </Pressable>
  );
}

function MiniIcon({
  label,
  accessibilityLabel,
  danger,
  onPress,
}: {
  label: string;
  accessibilityLabel?: string;
  danger?: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      onPress={(event) => {
        event.stopPropagation();
        onPress();
      }}
      style={[
        styles.miniIcon,
        danger ? styles.miniIconDanger : styles.miniIconDefault,
      ]}
    >
      <Text
        style={[
          styles.miniIconText,
          danger ? styles.miniIconTextDanger : styles.miniIconTextDefault,
        ]}
      >
        {label}
      </Text>
    </Pressable>
  );
}

function TradeSide({
  label,
  items,
  values,
  hue,
  logic,
  right,
}: {
  label: string;
  items: ListingGoodsItem[];
  values: string[];
  hue: string;
  logic: ListingItem["logic"];
  right?: boolean;
}) {
  const multi = values.length > 1;
  return (
    <View style={styles.tradeSide}>
      <Text style={[styles.tradeSideLabel, right ? styles.tradeSideRight : null]}>
        {label}
      </Text>
      <View
        style={[
          multi ? styles.tradeOptionFrame : styles.tradeSingleFrame,
          right ? styles.tradeOptionRight : null,
        ]}
      >
        {multi ? (
          <View style={[styles.logicTag, right ? styles.logicTagRight : null]}>
            <Text style={styles.logicTagText}>{logic}</Text>
          </View>
        ) : null}
        <View
          style={[
            styles.tradeItems,
            right ? styles.tradeItemsRight : styles.tradeItemsLeft,
          ]}
        >
          {items.length > 0
            ? items.slice(0, 3).map((item, index) => (
                <DeckGoodsVisual
                  key={`${item.id}-${index}`}
                  item={item}
                  size={38}
                  accent={right ? megrumColors.pink : megrumColors.sky}
                />
              ))
            : values.slice(0, 3).map((value, index) => (
            <View
              key={`${value}-${index}`}
              style={[styles.tradeMiniItem, { backgroundColor: hue }]}
            >
              <Text style={styles.tradeMiniText}>{value[0] ?? "?"}</Text>
            </View>
          ))}
          {values.length > 3 ? (
            <View style={styles.tradeOverflow}>
              <Text style={styles.tradeOverflowText}>+{values.length - 3}</Text>
            </View>
          ) : null}
        </View>
      </View>
    </View>
  );
}

function buildWishActions({
  item,
  onClose,
  onEdit,
  onListing,
  onDelete,
}: {
  item: WishItem;
  onClose: () => void;
  onEdit: () => void;
  onListing: () => void;
  onDelete: () => void;
}): SheetAction[] {
  return [
    {
      id: "edit",
      label: "編集する",
      onPress: onEdit,
    },
    {
      id: "listing",
      label: item.linkedListings > 0 ? "+ 個別募集を追加" : "個別募集を作る",
      onPress: onListing,
    },
    {
      id: "delete",
      label: "削除",
      tone: "danger",
      onPress: onDelete,
    },
    {
      id: "close",
      label: "閉じる",
      tone: "muted",
      onPress: onClose,
    },
  ];
}

function WishDeleteConfirmModal({
  item,
  onCancel,
  onConfirm,
}: {
  item: WishItem | null;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  return (
    <Modal
      visible={!!item}
      transparent
      animationType="fade"
      onRequestClose={onCancel}
    >
      <View style={styles.deleteModalRoot}>
        <Pressable style={styles.deleteModalBackdrop} onPress={onCancel} />
        <View style={styles.deleteModalPanel}>
          <Text style={styles.deleteModalTitle}>wish を削除しますか？</Text>
          {item ? (
            <View style={styles.deleteModalPreview}>
              {item.photoUrl ? (
                <Image
                  source={{ uri: item.photoUrl }}
                  resizeMode="cover"
                  style={styles.deleteModalImage}
                />
              ) : (
                <View
                  style={[
                    styles.deleteModalFallback,
                    { backgroundColor: item.hue },
                  ]}
                >
                  <Text style={styles.deleteModalFallbackText}>
                    {item.glyph}
                  </Text>
                </View>
              )}
              <View style={styles.deleteModalCopy}>
                <Text numberOfLines={1} style={styles.deleteModalItemTitle}>
                  {item.title}
                </Text>
                <Text numberOfLines={1} style={styles.deleteModalItemSub}>
                  {item.subtitle}
                </Text>
              </View>
            </View>
          ) : null}
          <Text style={styles.deleteModalBody}>
            削除後はマッチング候補や個別募集の候補から外れます。
          </Text>
          <View style={styles.deleteModalActions}>
            <Pressable onPress={onCancel} style={styles.deleteModalCancel}>
              <Text style={styles.deleteModalCancelText}>閉じる</Text>
            </Pressable>
            <Pressable onPress={onConfirm} style={styles.deleteModalDanger}>
              <Text style={styles.deleteModalDangerText}>削除する</Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}

function ListingDeleteConfirmModal({
  item,
  onCancel,
  onConfirm,
}: {
  item: ListingItem | null;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  return (
    <Modal
      visible={!!item}
      transparent
      animationType="fade"
      onRequestClose={onCancel}
    >
      <View style={styles.deleteModalRoot}>
        <Pressable style={styles.deleteModalBackdrop} onPress={onCancel} />
        <View style={styles.deleteModalPanel}>
          <Text style={styles.deleteModalTitle}>
            本当に個別募集を削除しますか？
          </Text>
          {item ? (
            <View style={styles.deleteModalPreview}>
              <View style={styles.deleteModalListingIcon}>
                <Text style={styles.deleteModalListingIconText}>募</Text>
              </View>
              <View style={styles.deleteModalCopy}>
                <Text numberOfLines={2} style={styles.deleteModalItemTitle}>
                  譲る: {item.give.join("、")}
                </Text>
                <Text numberOfLines={2} style={styles.deleteModalItemSub}>
                  求める: {item.want.join("、")}
                </Text>
              </View>
            </View>
          ) : null}
          <Text style={styles.deleteModalBody}>
            削除すると、この個別募集は一覧やマッチング候補に表示されなくなります。
          </Text>
          <View style={styles.deleteModalActions}>
            <Pressable onPress={onCancel} style={styles.deleteModalCancel}>
              <Text style={styles.deleteModalCancelText}>閉じる</Text>
            </Pressable>
            <Pressable onPress={onConfirm} style={styles.deleteModalDanger}>
              <Text style={styles.deleteModalDangerText}>削除する</Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}

function buildListingActions({
  item,
  onClose,
  onEdit,
  onToggle,
  onDelete,
}: {
  item: ListingItem;
  onClose: () => void;
  onEdit: () => void;
  onToggle: () => void;
  onDelete: () => void;
}): SheetAction[] {
  if (item.status === "MATCHED") {
    return [
      {
        id: "edit",
        label: "詳細を見る",
        onPress: onEdit,
      },
      {
        id: "close",
        label: "閉じる",
        tone: "muted",
        onPress: onClose,
      },
    ];
  }

  return [
    {
      id: "edit",
      label: "編集する",
      onPress: onEdit,
    },
    {
      id: "toggle",
      label: item.status === "ACTIVE" ? "一時停止" : "再開する",
      onPress: onToggle,
    },
    {
      id: "delete",
      label: "削除",
      tone: "danger",
      onPress: onDelete,
    },
    {
      id: "close",
      label: "閉じる",
      tone: "muted",
      onPress: onClose,
    },
  ];
}

const styles = StyleSheet.create({
  screenContent: {
    gap: 12,
    paddingHorizontal: 18,
  },
  screenScroll: {
    flex: 1,
    marginHorizontal: -18,
  },
  screenScrollContent: {
    gap: 12,
    paddingBottom: 132,
    paddingHorizontal: 18,
  },
  stickyHeaderBlock: {
    backgroundColor: megrumColors.background,
    gap: 12,
    marginHorizontal: -18,
    paddingBottom: 8,
    paddingHorizontal: 18,
    paddingTop: 2,
  },
  loadingSkeleton: {
    gap: 14,
  },
  deleteModalRoot: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
    padding: 20,
  },
  deleteModalBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(20,18,28,0.50)",
  },
  deleteModalPanel: {
    backgroundColor: megrumColors.surface,
    borderRadius: 20,
    gap: 13,
    padding: 18,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 18 },
    shadowOpacity: 0.24,
    shadowRadius: 34,
    width: "100%",
  },
  deleteModalTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  deleteModalPreview: {
    alignItems: "center",
    backgroundColor: megrumColors.background,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 14,
    borderWidth: 1,
    flexDirection: "row",
    gap: 11,
    padding: 10,
  },
  deleteModalImage: {
    borderRadius: 8,
    height: 54,
    width: 40,
  },
  deleteModalFallback: {
    alignItems: "center",
    borderRadius: 8,
    height: 54,
    justifyContent: "center",
    width: 40,
  },
  deleteModalFallbackText: {
    color: megrumColors.surface,
    fontSize: 18,
    fontWeight: "900",
  },
  deleteModalListingIcon: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.18)",
    borderColor: "rgba(166,149,216,0.34)",
    borderRadius: 12,
    borderWidth: 1,
    height: 54,
    justifyContent: "center",
    width: 54,
  },
  deleteModalListingIconText: {
    color: megrumColors.lavender,
    fontSize: 17,
    fontWeight: "900",
  },
  deleteModalCopy: {
    flex: 1,
  },
  deleteModalItemTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  deleteModalItemSub: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "700",
    marginTop: 3,
  },
  deleteModalBody: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 18,
  },
  deleteModalActions: {
    flexDirection: "row",
    gap: 9,
  },
  deleteModalCancel: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 13,
    flex: 1,
    paddingVertical: 12,
  },
  deleteModalCancelText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "900",
  },
  deleteModalDanger: {
    alignItems: "center",
    backgroundColor: "rgba(239,68,68,0.12)",
    borderColor: "rgba(239,68,68,0.24)",
    borderRadius: 13,
    borderWidth: 1,
    flex: 1,
    paddingVertical: 12,
  },
  deleteModalDangerText: {
    color: "#dc2626",
    fontSize: 13,
    fontWeight: "900",
  },
  header: {
    alignItems: "center",
    backgroundColor: "transparent",
    flexDirection: "row",
    justifyContent: "space-between",
    marginHorizontal: -2,
    minHeight: 56,
    paddingHorizontal: 2,
    paddingVertical: 8,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 19,
    fontWeight: "900",
    letterSpacing: 0,
    lineHeight: 24,
  },
  headerActions: {
    alignItems: "center",
    flexDirection: "row",
    minWidth: 92,
    justifyContent: "flex-end",
  },
  inlineNotice: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  inlineError: {
    color: megrumColors.warn,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 17,
  },
  filters: {
    marginHorizontal: -18,
    paddingLeft: 18,
  },
  filterRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 6,
    marginBottom: 6,
  },
  filterLabel: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "900",
    letterSpacing: 0.4,
    textAlign: "right",
    width: 30,
  },
  filterChips: {
    gap: 6,
    paddingRight: 18,
  },
  filterChip: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  filterChipActive: {
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.lavender,
  },
  filterChipText: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "800",
  },
  filterChipTextActive: {
    color: megrumColors.surface,
  },
  contentHost: {
    minHeight: 1,
  },
  tabPage: {
    minHeight: 220,
  },
  scrollContent: {
    paddingBottom: 24,
  },
  listingsHost: {
    gap: 14,
  },
  listingEmpty: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderStyle: "dashed",
    borderWidth: 1,
    justifyContent: "center",
    paddingVertical: 38,
  },
  listingEmptyText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  deckSection: {
    marginHorizontal: -18,
  },
  deckHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    paddingHorizontal: 18,
  },
  deckTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  deckCount: {
    backgroundColor: "rgba(58,50,74,0.04)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 10,
    paddingVertical: 4,
  },
  deckList: {
    gap: 12,
    paddingHorizontal: 18,
    paddingTop: 8,
    paddingBottom: 4,
  },
  deckCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.34)",
    borderRadius: 22,
    borderWidth: 1,
    minHeight: 246,
    overflow: "hidden",
    padding: 13,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 16 },
    shadowOpacity: 0.13,
    shadowRadius: 26,
    width: "100%",
  },
  deckCardGlowPink: {
    backgroundColor: "rgba(243,197,212,0.34)",
    borderRadius: 999,
    height: 136,
    position: "absolute",
    right: -52,
    top: -36,
    width: 136,
  },
  deckCardGlowSky: {
    backgroundColor: "rgba(168,212,230,0.28)",
    borderRadius: 999,
    bottom: -42,
    height: 142,
    left: -46,
    position: "absolute",
    width: 142,
  },
  deckTop: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  deckMeta: {
    color: megrumColors.mutedInk,
    flex: 1,
    fontSize: 10.5,
    fontWeight: "900",
  },
  deckBody: {
    alignItems: "center",
    flexDirection: "row",
    flex: 1,
    justifyContent: "space-between",
    marginTop: 14,
  },
  deckBodyRich: {
    gap: 10,
    marginTop: 14,
  },
  deckSide: {
    backgroundColor: "rgba(255,255,255,0.62)",
    borderColor: "rgba(58,50,74,0.06)",
    borderRadius: 16,
    borderWidth: 1,
    gap: 8,
    padding: 10,
  },
  deckSideLabel: {
    backgroundColor: "rgba(255,255,255,0.78)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  deckBubbles: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "center",
    minHeight: 118,
    width: "100%",
  },
  deckGoodsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    width: "100%",
  },
  deckGoodsTile: {
    alignItems: "center",
    gap: 5,
    width: 64,
  },
  deckGoodsName: {
    color: megrumColors.ink,
    fontSize: 9.5,
    fontWeight: "800",
    lineHeight: 12,
    textAlign: "center",
  },
  deckPhotoStack: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "center",
    minHeight: 122,
    width: "100%",
  },
  deckPhotoLayer: {
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.14,
    shadowRadius: 14,
  },
  deckMorePhoto: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.78)",
    borderRadius: megrumRadii.pill,
    bottom: 10,
    height: 26,
    justifyContent: "center",
    position: "absolute",
    right: 5,
    width: 38,
  },
  deckWishCluster: {
    height: 126,
    position: "relative",
    width: 118,
  },
  deckWishNode: {
    position: "absolute",
  },
  deckWishMore: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.78)",
    borderRadius: megrumRadii.pill,
    bottom: 0,
    height: 26,
    justifyContent: "center",
    position: "absolute",
    right: 2,
    width: 38,
  },
  deckGoodsVisual: {
    alignItems: "center",
    borderWidth: 2,
    justifyContent: "center",
    overflow: "hidden",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 7 },
    shadowOpacity: 0.15,
    shadowRadius: 13,
  },
  deckGoodsImage: {
    height: "100%",
    width: "100%",
  },
  deckGoodsGlyph: {
    color: megrumColors.surface,
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.24)",
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 4,
  },
  deckQtyBadge: {
    backgroundColor: "rgba(58,50,74,0.68)",
    borderBottomLeftRadius: 8,
    paddingHorizontal: 5,
    paddingVertical: 1,
    position: "absolute",
    right: 0,
    top: 0,
  },
  deckQtyText: {
    color: megrumColors.surface,
    fontSize: 9,
    fontWeight: "900",
  },
  deckCashVisual: {
    alignItems: "center",
    backgroundColor: "rgba(122,154,138,0.12)",
    borderColor: "rgba(122,154,138,0.34)",
    borderRadius: 15,
    borderWidth: 1,
    justifyContent: "center",
    overflow: "hidden",
  },
  deckCashSymbol: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 24,
  },
  deckCashText: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "900",
    maxWidth: "82%",
  },
  deckEmptyVisual: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.70)",
    borderColor: "rgba(58,50,74,0.16)",
    borderRadius: 15,
    borderStyle: "dashed",
    borderWidth: 1,
    justifyContent: "center",
  },
  deckEmptyText: {
    color: "rgba(58,50,74,0.45)",
    fontSize: 12,
    fontWeight: "900",
  },
  deckBubble: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.92)",
    borderRadius: 18,
    borderWidth: 2,
    height: 96,
    justifyContent: "center",
    marginHorizontal: -18,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.14,
    shadowRadius: 14,
    width: 72,
  },
  deckBubbleText: {
    color: megrumColors.surface,
    fontSize: 25,
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.22)",
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 4,
  },
  deckMore: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.76)",
    borderRadius: megrumRadii.pill,
    bottom: 8,
    height: 28,
    justifyContent: "center",
    position: "absolute",
    right: 12,
    width: 40,
  },
  deckMoreText: {
    color: megrumColors.surface,
    fontSize: 11,
    fontWeight: "900",
  },
  deckCord: {
    alignItems: "center",
    alignSelf: "center",
    height: 28,
    justifyContent: "center",
    width: 74,
  },
  deckCordLine: {
    backgroundColor: "rgba(166,149,216,0.34)",
    height: 2,
    position: "absolute",
    width: 74,
  },
  deckKnot: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.44)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 28,
    justifyContent: "center",
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.2,
    shadowRadius: 12,
    width: 28,
  },
  deckKnotText: {
    color: megrumColors.lavender,
    fontSize: 18,
    fontWeight: "900",
    lineHeight: 22,
  },
  listingList: {
    gap: 12,
  },
  listingCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    padding: 13,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 16,
  },
  listingTop: {
    alignItems: "center",
    flexDirection: "row",
    gap: 9,
  },
  listingTopText: {
    flex: 1,
  },
  listingTitle: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  listingSub: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "800",
    marginTop: 2,
  },
  listingActions: {
    flexDirection: "row",
    gap: 5,
  },
  statusBadge: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    justifyContent: "center",
    minWidth: 52,
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  statusBadgeActive: {
    backgroundColor: megrumColors.ok,
  },
  statusBadgeMatched: {
    backgroundColor: "rgba(166,149,216,0.16)",
  },
  statusBadgeText: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "900",
  },
  statusBadgeTextActive: {
    color: megrumColors.surface,
  },
  statusBadgeTextMatched: {
    color: megrumColors.lavender,
  },
  miniIcon: {
    alignItems: "center",
    borderRadius: 12,
    height: 28,
    justifyContent: "center",
    width: 28,
  },
  miniIconDefault: {
    backgroundColor: "rgba(58,50,74,0.06)",
  },
  miniIconDanger: {
    backgroundColor: "rgba(217,130,107,0.12)",
  },
  miniIconText: {
    fontSize: 10,
    fontWeight: "900",
  },
  miniIconTextDefault: {
    color: megrumColors.ink,
  },
  miniIconTextDanger: {
    color: megrumColors.warn,
  },
  tradeLine: {
    alignItems: "center",
    flexDirection: "row",
    gap: 9,
    marginTop: 13,
  },
  tradeSide: {
    flex: 1,
  },
  tradeSideLabel: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
    marginBottom: 6,
  },
  tradeSideRight: {
    textAlign: "right",
  },
  tradeItems: {
    flexDirection: "row",
    gap: 5,
  },
  tradeSingleFrame: {
    minHeight: 42,
  },
  tradeOptionFrame: {
    borderColor: "rgba(166,149,216,0.20)",
    borderRadius: 12,
    borderWidth: 1,
    minHeight: 58,
    paddingHorizontal: 6,
    paddingBottom: 6,
    paddingTop: 15,
  },
  tradeOptionRight: {
    borderColor: "rgba(243,197,212,0.34)",
  },
  tradeItemsLeft: {
    justifyContent: "flex-start",
  },
  tradeItemsRight: {
    justifyContent: "flex-end",
  },
  tradeMiniItem: {
    alignItems: "center",
    borderRadius: 8,
    height: 46,
    justifyContent: "center",
    width: 36,
  },
  tradeMiniText: {
    color: megrumColors.surface,
    fontSize: 16,
    fontWeight: "900",
  },
  tradeOverflow: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.08)",
    borderRadius: 8,
    height: 46,
    justifyContent: "center",
    width: 36,
  },
  tradeOverflowText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  logicTag: {
    backgroundColor: megrumColors.lavender,
    borderRadius: megrumRadii.pill,
    left: 6,
    paddingHorizontal: 7,
    paddingVertical: 2,
    position: "absolute",
    top: -8,
    zIndex: 1,
  },
  logicTagRight: {
    left: undefined,
    right: 6,
  },
  logicTagText: {
    color: megrumColors.surface,
    fontSize: 9,
    fontWeight: "900",
  },
  tradeConnector: {
    alignItems: "center",
    width: 28,
  },
  tradeConnectorDot: {
    backgroundColor: megrumColors.lavender,
    borderRadius: 5,
    height: 10,
    width: 10,
  },
  tradeConnectorLine: {
    backgroundColor: "rgba(166,149,216,0.38)",
    height: 1.5,
    width: 28,
  },
});
