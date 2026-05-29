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
  GoodsGrid,
  type ColumnCount,
  type GoodsGridPressContext,
  type GoodsGridItem,
  type SheetAnchor,
  type SheetAction,
  SectionTabs,
} from "../../src/components/GoodsGrid";
import { useAuth } from "../../src/auth/AuthProvider";
import { Screen } from "../../src/components/Screen";
import { GoodsGridSkeleton, SkeletonPillRow } from "../../src/components/SkeletonScreen";
import { fetchInventoryTagLabels, formatHashTags } from "../../src/lib/inventoryTags";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

type InventoryStatus = "active" | "keep" | "traded";

type InventoryItem = GoodsGridItem & {
  status: InventoryStatus;
  group: string;
  type: string;
  quantity?: number;
};

type InventoryRow = {
  id: string;
  title: string;
  quantity: number;
  status: "active" | "keep" | "traded" | "reserved" | "archived";
  hue: number | string | null;
  photo_urls: string[] | null;
  group: { name: string | null } | { name: string | null }[] | null;
  character: { name: string | null } | { name: string | null }[] | null;
  character_request:
    | { requested_name: string | null; status: string | null }
    | { requested_name: string | null; status: string | null }[]
    | null;
  goods_type: { name: string | null } | { name: string | null }[] | null;
};

const INITIAL_ITEMS: InventoryItem[] = [
  {
    id: "inv-01",
    title: "スア 春ver.",
    subtitle: "LUMENA / トレカ",
    glyph: "S",
    hue: "#cbbcf4",
    badge: "譲る候補",
    note: "同種優先",
    tagLabels: ["春ver.", "同種優先"],
    status: "active",
    group: "LUMENA",
    type: "トレカ",
  },
  {
    id: "inv-02",
    title: "ジョンウ ラキドロ",
    subtitle: "NCT / トレカ",
    glyph: "J",
    hue: "#a8d4e6",
    badge: "残 1",
    note: "タグ: ラキドロ",
    tagLabels: ["ラキドロ"],
    status: "active",
    group: "NCT",
    type: "トレカ",
  },
  {
    id: "inv-03",
    title: "ニンニン アクスタ",
    subtitle: "aespa / アクスタ",
    glyph: "N",
    hue: "#f3c5d4",
    badge: "現地OK",
    note: "会場持参予定",
    tagLabels: ["現地OK", "アクスタ"],
    status: "active",
    group: "aespa",
    type: "アクスタ",
  },
  {
    id: "inv-04",
    title: "カリナ 缶バッジ",
    subtitle: "aespa / 缶バッジ",
    glyph: "K",
    hue: "#d5cff4",
    badge: "残 2",
    tagLabels: ["缶バッジ"],
    status: "active",
    group: "aespa",
    type: "缶バッジ",
  },
  {
    id: "inv-05",
    title: "V トレカ",
    subtitle: "BTS / トレカ",
    glyph: "V",
    hue: "#b7dceb",
    badge: "キープ",
    note: "自分用",
    tagLabels: ["自分用"],
    status: "keep",
    group: "BTS",
    type: "トレカ",
  },
  {
    id: "inv-06",
    title: "リノ 通常盤",
    subtitle: "SKZ / トレカ",
    glyph: "R",
    hue: "#f7d5df",
    badge: "キープ",
    tagLabels: ["通常盤"],
    status: "keep",
    group: "SKZ",
    type: "トレカ",
  },
  {
    id: "inv-07",
    title: "ミンギュ 会場",
    subtitle: "SVT / トレカ",
    glyph: "M",
    hue: "#c8e8f2",
    badge: "譲渡済",
    note: "2026/05/08",
    tagLabels: ["会場"],
    status: "traded",
    group: "SVT",
    type: "トレカ",
  },
];

const STATUS_TABS: {
  id: InventoryStatus;
  label: string;
  color: string;
}[] = [
  { id: "active", label: "譲る候補", color: megrumColors.lavender },
  { id: "keep", label: "自分用キープ", color: megrumColors.pink },
  { id: "traded", label: "過去に譲った", color: "#9aa3b0" },
];
const STATUS_ORDER: InventoryStatus[] = ["active", "keep", "traded"];

export default function InventoryScreen() {
  const { user, previewMode } = useAuth();
  const params = useLocalSearchParams<{ refresh?: string | string[] }>();
  const { width: windowWidth } = useWindowDimensions();
  const pageWidth = Math.max(1, windowWidth - 36);
  const routeRefresh = one(params.refresh);
  const [items, setItems] = useState<InventoryItem[]>(() =>
    !supabase || previewMode ? INITIAL_ITEMS : [],
  );
  const [status, setStatus] = useState<InventoryStatus>("active");
  const [columns, setColumns] = useState<ColumnCount>(3);
  const [selected, setSelected] = useState<InventoryItem | null>(null);
  const [selectedAnchor, setSelectedAnchor] = useState<SheetAnchor | null>(null);
  const [deleteConfirmItem, setDeleteConfirmItem] = useState<InventoryItem | null>(null);
  const [deletingItemIds, setDeletingItemIds] = useState<string[]>([]);
  const [activeGroup, setActiveGroup] = useState<string | null>(null);
  const [activeType, setActiveType] = useState<string | null>(null);
  const [loading, setLoading] = useState(!!supabase && !previewMode);
  const [loadError, setLoadError] = useState<string | null>(null);
  const pagerRef = useRef<ScrollView>(null);
  const [pagerPosition, setPagerPosition] = useState(
    STATUS_ORDER.indexOf("active"),
  );

  useEffect(() => {
    if (!supabase || previewMode) {
      setItems(INITIAL_ITEMS);
      setLoading(false);
      setLoadError(null);
      return;
    }
    if (!user) {
      setItems([]);
      setLoading(false);
      setLoadError(null);
      return;
    }

    let active = true;
    setLoading(true);
    setLoadError(null);
    fetchInventoryItems(user.id)
      .then((next) => {
        if (active) setItems(next);
      })
      .catch((error: unknown) => {
        if (!active) return;
        setItems([]);
        setLoadError(error instanceof Error ? error.message : "読み込みに失敗しました");
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, routeRefresh, user]);

  const groupOptions = useMemo(() => {
    const values = new Set<string>();
    for (const item of items) values.add(item.group);
    return Array.from(values).sort((a, b) => a.localeCompare(b, "ja"));
  }, [items]);
  const typeOptions = useMemo(() => {
    const values = new Set<string>();
    for (const item of items) values.add(item.type);
    return Array.from(values).sort((a, b) => a.localeCompare(b, "ja"));
  }, [items]);
  const filteredItems = useMemo(
    () =>
      items.filter((item) => {
        if (activeGroup && item.group !== activeGroup) return false;
        if (activeType && item.type !== activeType) return false;
        return true;
      }),
    [activeGroup, activeType, items],
  );
  const itemsByStatus = useMemo(
    () =>
      filteredItems.reduce<Record<InventoryStatus, InventoryItem[]>>(
        (acc, item) => {
          acc[item.status].push(item);
          return acc;
        },
        { active: [], keep: [], traded: [] },
      ),
    [filteredItems],
  );
  const counts = useMemo(
    () => ({
      active: itemsByStatus.active.length,
      keep: itemsByStatus.keep.length,
      traded: itemsByStatus.traded.length,
    }),
    [itemsByStatus],
  );
  const tabs = STATUS_TABS.map((tab) => ({
    ...tab,
    count: counts[tab.id],
  }));
  const selectedActions = selected
    ? buildActions({
        item: selected,
        onClose: closeSelectedActions,
        onEdit: () => {
          const item = selected;
          closeSelectedActions();
          openInventoryEditor(item, item.status === "traded" ? "readonly" : "edit");
        },
        onMove: (nextStatus) => {
          const itemId = selected.id;
          const previousStatus = selected.status;
          setItems((current) =>
            current.map((item) =>
              item.id === itemId
                ? {
                    ...item,
                    status: nextStatus,
                    badge: nextStatus === "active" ? "譲る候補" : "キープ",
                  }
                : item,
            ),
          );
          closeSelectedActions();
          if (supabase && user && !previewMode) {
            void updateInventoryStatus({
              itemId,
              nextStatus,
              previousStatus,
              userId: user.id,
            }).catch((error: unknown) => {
              setLoadError(error instanceof Error ? error.message : "状態変更に失敗しました");
              setItems((current) =>
                current.map((item) =>
                  item.id === itemId
                    ? {
                        ...item,
                        status: previousStatus,
                        badge: previousStatus === "active" ? "譲る候補" : "キープ",
                      }
                    : item,
                ),
              );
            });
          }
        },
        onDelete: () => {
          const item = selected;
          closeSelectedActions();
          setDeleteConfirmItem(item);
        },
      })
    : [];

  function confirmInventoryDelete() {
    if (!deleteConfirmItem) return;
    const target = deleteConfirmItem;
    setDeleteConfirmItem(null);
    setDeletingItemIds((current) =>
      current.includes(target.id) ? current : [...current, target.id],
    );
  }

  function completeInventoryDelete(id: string) {
    const target = items.find((item) => item.id === id);
    setDeletingItemIds((current) => current.filter((itemId) => itemId !== id));
    setItems((current) => current.filter((item) => item.id !== id));
    if (supabase && user && !previewMode) {
      void archiveInventoryItem({ itemId: id, userId: user.id })
        .then(() => {
          setLoadError(null);
        })
        .catch((error: unknown) => {
          setLoadError(error instanceof Error ? error.message : "削除に失敗しました");
          if (target) {
            setItems((current) =>
              current.some((item) => item.id === target.id)
                ? current
                : [target, ...current],
            );
          }
        });
    }
  }

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
            <Text style={styles.title}>マイ在庫</Text>
            <View style={styles.headerActions}>
              <ColumnSwitcher value={columns} onChange={setColumns} />
              <HeaderIconButton label="フィルタ" glyph="≡" />
              <HeaderIconButton label="検索" glyph="⌕" />
            </View>
          </View>

          <SectionTabs
            value={status}
            tabs={tabs}
            position={pagerPosition}
            onChange={selectStatus}
          />
        </View>

        {loadError ? <Text style={styles.inlineError}>{loadError}</Text> : null}

        {loading ? (
          <View style={styles.loadingSkeleton}>
            <SkeletonPillRow count={2} />
            <GoodsGridSkeleton columns={columns} count={9} />
          </View>
        ) : (
          <>
            <View style={styles.filters}>
              <FilterRow
                label="推し"
                options={groupOptions}
                active={activeGroup}
                onChange={(next) => {
                  setActiveGroup(next);
                  closeSelectedActions();
                }}
              />
              <FilterRow
                label="種別"
                options={typeOptions}
                active={activeType}
                onChange={(next) => {
                  setActiveType(next);
                  closeSelectedActions();
                }}
              />
            </View>

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
              {STATUS_ORDER.map((pageStatus) => (
                <View key={pageStatus} style={[styles.inventoryPage, { width: pageWidth }]}>
                  {renderInventoryContent(pageStatus)}
                </View>
              ))}
            </ScrollView>
          </>
        )}
      </ScrollView>

      <BottomOptionSheet
        visible={!!selected}
        title={selected?.title ?? ""}
        anchor={selectedAnchor}
        presentation="glass"
        preview={
          selected
            ? {
                glyph: selected.glyph,
                hue: selected.hue,
                photoUrl: selected.photoUrl,
              }
            : null
        }
        subtitle={
          selected
            ? formatHashTags(selected.tagLabels) ??
              (selected.status === "traded"
              ? "過去に譲ったグッズです。編集や削除はできません。"
                : selected.note ?? "タグ未設定")
            : undefined
        }
        actions={selectedActions}
        onClose={closeSelectedActions}
      />
      <InventoryDeleteConfirmModal
        item={deleteConfirmItem}
        onCancel={() => setDeleteConfirmItem(null)}
        onConfirm={confirmInventoryDelete}
      />
    </Screen>
  );

  function selectStatus(next: InventoryStatus) {
    if (!STATUS_ORDER.includes(next)) return;
    setStatus(next);
    closeSelectedActions();
    const nextIndex = STATUS_ORDER.indexOf(next);
    setPagerPosition(nextIndex);
    pagerRef.current?.scrollTo({ x: nextIndex * pageWidth, animated: true });
  }

  function handlePagerScroll(event: NativeSyntheticEvent<NativeScrollEvent>) {
    setPagerPosition(event.nativeEvent.contentOffset.x / pageWidth);
  }

  function handlePagerSettled(event: NativeSyntheticEvent<NativeScrollEvent>) {
    const nextIndex = Math.max(
      0,
      Math.min(STATUS_ORDER.length - 1, Math.round(event.nativeEvent.contentOffset.x / pageWidth)),
    );
    const next = STATUS_ORDER[nextIndex] ?? "active";
    setStatus(next);
    setPagerPosition(nextIndex);
    closeSelectedActions();
  }

  function renderInventoryContent(pageStatus: InventoryStatus) {
    return (
      <View style={styles.gridScroll}>
        <GoodsGrid
          items={itemsByStatus[pageStatus]}
          columns={columns}
          showTopRow={false}
          deletingIds={deletingItemIds}
          onItemFadeOutEnd={completeInventoryDelete}
          addTileLabel={pageStatus === "active" ? "追加" : undefined}
          onPressAddTile={
            pageStatus === "active"
              ? () => openInventoryEditor(null, "create")
              : undefined
          }
          emptyLabel={
            pageStatus === "active"
              ? "譲る候補のグッズはまだありません"
              : pageStatus === "keep"
                ? "自分用キープのグッズはまだありません"
                : "過去に譲ったグッズはまだありません"
          }
          onPressItem={(gridItem, context) => {
            if (deletingItemIds.includes(gridItem.id)) return;
            const item = items.find((current) => current.id === gridItem.id);
            if (!item) return;
            setSelectedAnchor(normalizePressContext(context));
            setSelected(item);
          }}
        />
      </View>
    );
  }

  function closeSelectedActions() {
    setSelected(null);
    setSelectedAnchor(null);
  }
}

async function fetchInventoryItems(userId: string): Promise<InventoryItem[]> {
  if (!supabase) return INITIAL_ITEMS;
  const { data, error } = await supabase
    .from("goods_inventory")
    .select(
      "id, title, quantity, status, hue, photo_urls, group:groups_master(name), character:characters_master(name), character_request:character_requests(requested_name, status), goods_type:goods_types_master(name)",
    )
    .eq("user_id", userId)
    .eq("kind", "for_trade")
    .neq("status", "archived")
    .order("created_at", { ascending: false });
  if (error) throw error;
  const rows = (data as InventoryRow[] | null) ?? [];
  const tagLabelsById = await fetchInventoryTagLabels(rows.map((row) => row.id));
  return rows.map((row) => toInventoryItem(row, tagLabelsById[row.id] ?? []));
}

function toInventoryItem(row: InventoryRow, tagLabels: string[] = []): InventoryItem {
  const groupName = pickName(row.group) ?? "未設定";
  const characterName =
    pickName(row.character) ??
    pickRequestName(row.character_request) ??
    groupName;
  const goodsType = pickName(row.goods_type) ?? "グッズ";
  const status = normalizeInventoryStatus(row.status);
  return {
    id: row.id,
    title: row.title || `${characterName} ${goodsType}`,
    subtitle: `${groupName} / ${goodsType}`,
    glyph: characterName.slice(0, 1),
    hue: normalizeHue(row.hue, characterName),
    badge:
      status === "traded"
        ? "譲渡済"
        : status === "keep"
          ? "キープ"
          : row.quantity > 1
            ? `残 ${row.quantity}`
            : "譲る候補",
    note: row.quantity > 1 ? `交換可能数 ${row.quantity}` : undefined,
    tagLabels,
    status,
    group: groupName,
    type: goodsType,
    quantity: row.quantity,
    photoUrl: row.photo_urls?.[0] ?? null,
  };
}

function normalizeInventoryStatus(status: InventoryRow["status"]): InventoryStatus {
  if (status === "traded") return "traded";
  if (status === "active") return "active";
  return "keep";
}

async function updateInventoryStatus({
  itemId,
  nextStatus,
  previousStatus,
  userId,
}: {
  itemId: string;
  nextStatus: InventoryStatus;
  previousStatus: InventoryStatus;
  userId: string;
}) {
  if (!supabase) return;
  if (previousStatus === "active" && nextStatus !== "active") {
    await removeUnavailableHavesFromListings(userId, [itemId]);
  }

  const { error } = await supabase
    .from("goods_inventory")
    .update({ status: nextStatus })
    .eq("id", itemId)
    .eq("user_id", userId)
    .eq("kind", "for_trade");
  if (error) throw error;
}

async function archiveInventoryItem({
  itemId,
  userId,
}: {
  itemId: string;
  userId: string;
}) {
  if (!supabase) return;
  await removeUnavailableHavesFromListings(userId, [itemId]);
  const { error } = await supabase
    .from("goods_inventory")
    .update({ status: "archived" })
    .eq("id", itemId)
    .eq("user_id", userId)
    .eq("kind", "for_trade")
    .neq("status", "traded");
  if (error) throw error;
}

async function removeUnavailableHavesFromListings(userId: string, inventoryIds: string[]) {
  if (!supabase || inventoryIds.length === 0) return;
  const removeSet = new Set(inventoryIds);
  const { data, error } = await supabase
    .from("listings")
    .select("id, have_ids, have_qtys")
    .eq("user_id", userId)
    .in("status", ["active", "paused"]);
  if (error) throw error;

  for (const listing of
    (data as {
      id: string;
      have_ids: string[] | null;
      have_qtys: number[] | null;
    }[] | null) ?? []) {
    const haveIds = listing.have_ids ?? [];
    if (!haveIds.some((id) => removeSet.has(id))) continue;

    const nextIds: string[] = [];
    const nextQtys: number[] = [];
    for (let index = 0; index < haveIds.length; index += 1) {
      const haveId = haveIds[index];
      if (removeSet.has(haveId)) continue;
      nextIds.push(haveId);
      nextQtys.push(listing.have_qtys?.[index] ?? 1);
    }

    const { error: updateError } =
      nextIds.length === 0
        ? await supabase
            .from("listings")
            .update({ status: "closed" })
            .eq("id", listing.id)
            .eq("user_id", userId)
        : await supabase
            .from("listings")
            .update({ have_ids: nextIds, have_qtys: nextQtys })
            .eq("id", listing.id)
            .eq("user_id", userId);
    if (updateError) throw updateError;
  }
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

function pickRequestName(
  value:
    | { requested_name: string | null; status: string | null }
    | { requested_name: string | null; status: string | null }[]
    | null
    | undefined,
) {
  if (!value) return null;
  const request = Array.isArray(value) ? value[0] : value;
  return request?.requested_name ?? null;
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

function HeaderIconButton({ label, glyph }: { label: string; glyph: string }) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      style={styles.headerIconButton}
    >
      <Text style={styles.headerIconText}>{glyph}</Text>
    </Pressable>
  );
}

function openInventoryEditor(
  item: InventoryItem | null,
  mode: "create" | "edit" | "readonly",
) {
  router.push({
    pathname: "/goods-editor",
    params: {
      kind: "inventory",
      mode,
      id: item?.id ?? "",
      title: item?.title ?? "",
      subtitle: item?.subtitle ?? "",
      group: item?.group ?? "",
      goodsType: item?.type ?? "",
      note: item?.note ?? "",
      glyph: item?.glyph ?? "",
      hue: item?.hue ?? "#cbbcf4",
      badge: item?.badge ?? (mode === "create" ? "NEW" : "譲る候補"),
      quantity: item?.quantity ? String(item.quantity) : "1",
    },
  });
}

function FilterRow({
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
        <FilterChip
          label="すべて"
          active={active === null}
          onPress={() => onChange(null)}
        />
        {options.map((option) => (
          <FilterChip
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

function FilterChip({
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

function buildActions({
  item,
  onClose,
  onEdit,
  onMove,
  onDelete,
}: {
  item: InventoryItem;
  onClose: () => void;
  onEdit: () => void;
  onMove: (status: InventoryStatus) => void;
  onDelete: () => void;
}): SheetAction[] {
  if (item.status === "traded") {
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
      id: "move",
      label: item.status === "keep" ? "譲る候補へ" : "自分キープへ",
      onPress: () => onMove(item.status === "keep" ? "active" : "keep"),
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

function InventoryDeleteConfirmModal({
  item,
  onCancel,
  onConfirm,
}: {
  item: InventoryItem | null;
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
          <Text style={styles.deleteModalTitle}>在庫を削除しますか？</Text>
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
            削除後はマッチング候補や打診の対象から外れます。
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

function one(value?: string | string[]) {
  return Array.isArray(value) ? value[0] : value;
}

function normalizePressContext(context: GoodsGridPressContext): SheetAnchor {
  return {
    pageX: Number.isFinite(context.pageX) ? context.pageX : 0,
    pageY: Number.isFinite(context.pageY) ? context.pageY : 0,
  };
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
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    flexDirection: "row",
    justifyContent: "space-between",
    marginHorizontal: -2,
    paddingHorizontal: 12,
    paddingVertical: 10,
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
    gap: 6,
  },
  headerIconButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 10,
    borderWidth: 1,
    height: 34,
    justifyContent: "center",
    width: 34,
  },
  headerIconText: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
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
  inventoryPage: {
    minHeight: 220,
  },
  gridScroll: {
    paddingBottom: 24,
  },
});
