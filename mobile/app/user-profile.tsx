import { useEffect, useMemo, useRef, useState } from "react";
import { router, useLocalSearchParams } from "expo-router";
import {
  Image,
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
  ColumnSwitcher,
  GoodsGrid,
  SectionTabs,
  type ColumnCount,
  type GoodsGridItem,
} from "../src/components/GoodsGrid";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import { useAuth } from "../src/auth/AuthProvider";
import { IconSymbol } from "../src/components/IconSymbol";
import { fetchInventoryTagLabels } from "../src/lib/inventoryTags";
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
  listings: ProfileListing[];
};

type ProfileItem = GoodsGridItem & {
  group: string;
  quantity?: number;
  type: string;
};

type ProfileListing = {
  id: string;
  status: "ACTIVE" | "PAUSED" | "MATCHED";
  haves: ListingGoodsItem[];
  options: ListingOptionItem[];
  give: string[];
  want: string[];
  logic: "すべて" | "1pick";
  hue: string;
  group: string;
  type: string;
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

type ProfileInventoryRow = {
  id: string;
  title: string;
  quantity: number;
  hue: number | string | null;
  photo_urls: string[] | null;
  group: MasterName;
  character: MasterName;
  goods_type: MasterName;
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
  group: MasterName;
  character: MasterName;
  goods_type: MasterName;
};

type ProfileTab = "items" | "listings";

const PROFILE_TAB_ORDER: ProfileTab[] = ["items", "listings"];

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
      subtitle: "LUMENA / トレカ",
      glyph: "ス",
      photoUrl: null,
      hue: "#cbbcf4",
      badge: "譲る候補",
      tagLabels: ["春ver.", "同種優先"],
      group: "LUMENA",
      type: "トレカ",
    },
    {
      id: "preview-item-2",
      title: "ジョンウ ラキドロ",
      subtitle: "NCT / トレカ",
      glyph: "ジ",
      photoUrl: null,
      hue: "#a8d4e6",
      badge: "残 1",
      tagLabels: ["ラキドロ"],
      group: "NCT",
      type: "トレカ",
    },
  ],
  listings: [
    {
      id: "preview-listing-1",
      status: "ACTIVE",
      haves: [
        {
          id: "preview-item-1",
          title: "スア 春ver. トレカ",
          qty: 1,
          photoUrl: null,
          groupName: "LUMENA",
          characterName: "スア",
          goodsTypeName: "トレカ",
          hue: "#cbbcf4",
        },
      ],
      options: [
        {
          id: "preview-listing-1-option-1",
          position: 1,
          logic: "1pick",
          exchangeType: "same_kind",
          isCashOffer: false,
          cashAmount: null,
          wishes: [
            {
              id: "preview-wish-1",
              title: "ミンジ ラキドロ",
              qty: 1,
              photoUrl: null,
              groupName: "NewJeans",
              characterName: "ミンジ",
              goodsTypeName: "トレカ",
              hue: "#f3c5d4",
            },
          ],
        },
      ],
      give: ["スア"],
      want: ["ミンジ"],
      logic: "1pick",
      hue: "#cbbcf4",
      group: "LUMENA",
      type: "トレカ",
    },
  ],
};

export default function UserProfileScreen() {
  const params = useLocalSearchParams<{ id?: string | string[] }>();
  const profileId = Array.isArray(params.id) ? params.id[0] : params.id;
  const { previewMode, user } = useAuth();
  const { width: windowWidth } = useWindowDimensions();
  const pageWidth = Math.max(1, windowWidth - 36);
  const pagerRef = useRef<ScrollView>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<ProfileTab>("items");
  const [columns, setColumns] = useState<ColumnCount>(3);
  const [activeGroup, setActiveGroup] = useState<string | null>(null);
  const [activeType, setActiveType] = useState<string | null>(null);
  const [pagerPosition, setPagerPosition] = useState(0);

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

  const filteredItems = useMemo(
    () =>
      (profile?.items ?? []).filter((item) => {
        if (activeGroup && item.group !== activeGroup) return false;
        if (activeType && item.type !== activeType) return false;
        return true;
      }),
    [activeGroup, activeType, profile?.items],
  );
  const filteredListings = useMemo(
    () =>
      (profile?.listings ?? []).filter((listing) => {
        if (activeGroup && listing.group !== activeGroup) return false;
        if (activeType && listing.type !== activeType) return false;
        return true;
      }),
    [activeGroup, activeType, profile?.listings],
  );
  const groupOptions = useMemo(
    () =>
      uniqueSorted([
        ...(profile?.items ?? []).map((item) => item.group),
        ...(profile?.listings ?? []).map((listing) => listing.group),
      ]),
    [profile?.items, profile?.listings],
  );
  const typeOptions = useMemo(
    () =>
      uniqueSorted([
        ...(profile?.items ?? []).map((item) => item.type),
        ...(profile?.listings ?? []).map((listing) => listing.type),
      ]),
    [profile?.items, profile?.listings],
  );
  const tabs = useMemo(
    () => [
      {
        id: "items" as const,
        label: "譲る候補",
        count: filteredItems.length,
        color: megrumColors.lavender,
      },
      {
        id: "listings" as const,
        label: "個別募集",
        count: filteredListings.length,
        color: megrumColors.sky,
      },
    ],
    [filteredItems.length, filteredListings.length],
  );

  function selectTab(next: ProfileTab) {
    setTab(next);
    const nextIndex = PROFILE_TAB_ORDER.indexOf(next);
    setPagerPosition(nextIndex);
    pagerRef.current?.scrollTo({ x: nextIndex * pageWidth, animated: true });
  }

  function handlePagerScroll(event: NativeSyntheticEvent<NativeScrollEvent>) {
    setPagerPosition(event.nativeEvent.contentOffset.x / pageWidth);
  }

  function handlePagerSettled(event: NativeSyntheticEvent<NativeScrollEvent>) {
    const nextIndex = Math.max(
      0,
      Math.min(
        PROFILE_TAB_ORDER.length - 1,
        Math.round(event.nativeEvent.contentOffset.x / pageWidth),
      ),
    );
    setTab(PROFILE_TAB_ORDER[nextIndex] ?? "items");
    setPagerPosition(nextIndex);
  }

  return (
    <Screen bottomInset={false} scroll={false} contentStyle={styles.screen}>
      <ScrollView
        automaticallyAdjustsScrollIndicatorInsets
        contentInsetAdjustmentBehavior="automatic"
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        <RouteHeader title="相手プロフィール" subtitle="譲る候補と個別募集を確認" />
        {loading ? <Text style={styles.loadingText}>読み込み中…</Text> : null}
        {error ? <Text style={styles.inlineError}>{error}</Text> : null}
        {profile ? (
          <>
            <ProfileHero profile={profile} />

            <View style={styles.statsStrip}>
              <MiniStat
                label="評価"
                value={profile.ratingAvg == null ? "★—" : `★${profile.ratingAvg.toFixed(1)}`}
                accessibilityLabel="評価一覧を見る"
                onPress={() =>
                  router.push({
                    pathname: "/user-evaluations",
                    params: { id: profile.id },
                  })
                }
              />
              <MiniStat label="取引" value={`${profile.tradeCount}`} />
              <MiniStat label="譲る候補" value={`${profile.items.length}`} />
              <MiniStat label="個別募集" value={`${profile.listings.length}`} />
            </View>

            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>公開中</Text>
              {tab === "items" ? (
                <ColumnSwitcher value={columns} onChange={setColumns} />
              ) : (
                <View style={styles.sectionHeaderSpacer} />
              )}
            </View>

            <SectionTabs
              value={tab}
              tabs={tabs}
              position={pagerPosition}
              onChange={selectTab}
            />

            <View style={styles.filters}>
              <FilterRow
                label="推し"
                options={groupOptions}
                active={activeGroup}
                onChange={setActiveGroup}
              />
              <FilterRow
                label="種別"
                options={typeOptions}
                active={activeType}
                onChange={setActiveType}
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
              <View style={[styles.profilePage, { width: pageWidth }]}>
                <GoodsGrid
                  items={filteredItems}
                  columns={columns}
                  showTopRow={false}
                  emptyLabel="現在表示できる譲る候補はありません"
                  onPressItem={(item) => {
                    router.push({
                      pathname: "/proposal-select",
                      params: {
                        partnerId: profile.id,
                        partnerHandle: profile.handle,
                        receives: item.id,
                      },
                    });
                  }}
                />
              </View>
              <View style={[styles.profilePage, { width: pageWidth }]}>
                <ProfileListingsPanel
                  listings={filteredListings}
                  onPress={(listing) =>
                    router.push({
                      pathname: "/proposal-select",
                      params: {
                        partnerId: profile.id,
                        partnerHandle: profile.handle,
                        receives: listing.haves.map((item) => item.id).join(","),
                        listings: listing.id,
                      },
                    })
                  }
                />
              </View>
            </ScrollView>

            {user && user.id !== profile.id ? (
              <Pressable
                accessibilityRole="button"
                onPress={() =>
                  router.push({
                    pathname: "/proposal-select",
                    params: { partnerId: profile.id, partnerHandle: profile.handle },
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
      </ScrollView>
    </Screen>
  );
}

function ProfileHero({ profile }: { profile: UserProfile }) {
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
              params: { id: profile.id },
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
  accessibilityLabel,
  label,
  value,
  onPress,
}: {
  accessibilityLabel?: string;
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
      accessibilityLabel={accessibilityLabel ?? label}
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
        <FilterChip label="すべて" active={active === null} onPress={() => onChange(null)} />
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

function ProfileListingsPanel({
  listings,
  onPress,
}: {
  listings: ProfileListing[];
  onPress: (listing: ProfileListing) => void;
}) {
  if (listings.length === 0) {
    return (
      <View style={styles.listingEmpty}>
        <Text style={styles.listingEmptyText}>現在表示できる個別募集はありません</Text>
      </View>
    );
  }

  return (
    <View style={styles.listingsHost}>
      {listings.map((listing) => (
        <PublicListingCard
          key={listing.id}
          listing={listing}
          onPress={() => onPress(listing)}
        />
      ))}
    </View>
  );
}

function PublicListingCard({
  listing,
  onPress,
}: {
  listing: ProfileListing;
  onPress: () => void;
}) {
  const slots = getListingWishSlots(listing);
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.listingCard}>
      <View style={styles.listingGlowSky} />
      <View style={styles.listingGlowPink} />
      <View style={styles.listingTop}>
        <StatusBadge status={listing.status} />
        <Text numberOfLines={1} style={styles.listingMeta}>
          {listing.logic}
        </Text>
        <View style={styles.listingActionPill}>
          <Text style={styles.listingActionText}>打診へ</Text>
          <IconSymbol name="arrow-forward" size={13} color={megrumColors.lavender} />
        </View>
      </View>
      <View style={styles.listingBody}>
        <ListingSide label="譲る" items={listing.haves} accent={megrumColors.sky} />
        <View style={styles.listingConnector}>
          <View style={styles.listingConnectorLine} />
          <View style={styles.listingConnectorKnot}>
            <Text style={styles.listingConnectorText}>∿</Text>
          </View>
        </View>
        <ListingWishSide slots={slots} />
      </View>
    </Pressable>
  );
}

function StatusBadge({ status }: { status: ProfileListing["status"] }) {
  return (
    <View style={styles.statusBadge}>
      <Text style={styles.statusBadgeText}>{listingStatusLabel(status)}</Text>
    </View>
  );
}

function ListingSide({
  label,
  items,
  accent,
}: {
  label: string;
  items: ListingGoodsItem[];
  accent: string;
}) {
  return (
    <View style={styles.listingSide}>
      <Text style={styles.listingSideLabel}>{label}</Text>
      <View style={styles.listingGoodsGrid}>
        {items.map((item, index) => (
          <View key={`${item.id}-${index}`} style={styles.listingGoodsTile}>
            <ListingGoodsVisual item={item} accent={accent} />
            <Text numberOfLines={2} style={styles.listingGoodsName}>
              {shortItemLabel(item)}
            </Text>
          </View>
        ))}
        {items.length === 0 ? (
          <View style={styles.listingGoodsTile}>
            <ListingEmptyVisual label="譲" />
            <Text numberOfLines={1} style={styles.listingGoodsName}>
              未設定
            </Text>
          </View>
        ) : null}
      </View>
    </View>
  );
}

function ListingWishSide({ slots }: { slots: ListingWishSlot[] }) {
  return (
    <View style={styles.listingSide}>
      <Text style={styles.listingSideLabel}>求める</Text>
      <View style={styles.listingGoodsGrid}>
        {slots.map((slot) => (
          <View key={slot.key} style={styles.listingGoodsTile}>
            {slot.option.isCashOffer ? (
              <ListingCashVisual amount={slot.option.cashAmount} />
            ) : slot.wish ? (
              <ListingGoodsVisual item={slot.wish} accent={megrumColors.pink} />
            ) : (
              <ListingEmptyVisual label="求" />
            )}
            <Text numberOfLines={2} style={styles.listingGoodsName}>
              {listingWishSlotLabel(slot)}
            </Text>
          </View>
        ))}
        {slots.length === 0 ? (
          <View style={styles.listingGoodsTile}>
            <ListingEmptyVisual label="求" />
            <Text numberOfLines={1} style={styles.listingGoodsName}>
              未設定
            </Text>
          </View>
        ) : null}
      </View>
    </View>
  );
}

function ListingGoodsVisual({
  item,
  accent,
}: {
  item: ListingGoodsItem;
  accent: string;
}) {
  const glyph = shortItemLabel(item).slice(0, 1) || "?";
  return (
    <View
      style={[
        styles.listingGoodsVisual,
        {
          backgroundColor: item.photoUrl ? megrumColors.surface : item.hue,
          borderColor: accent,
        },
      ]}
    >
      {item.photoUrl ? (
        <Image source={{ uri: item.photoUrl }} resizeMode="cover" style={styles.listingGoodsImage} />
      ) : (
        <Text style={styles.listingGoodsGlyph}>{glyph}</Text>
      )}
      <View style={styles.listingQtyBadge}>
        <Text style={styles.listingQtyText}>×{item.qty}</Text>
      </View>
    </View>
  );
}

function ListingCashVisual({ amount }: { amount: number | null }) {
  return (
    <View style={styles.listingCashVisual}>
      <Text style={styles.listingCashSymbol}>¥</Text>
      <Text numberOfLines={1} style={styles.listingCashText}>
        {amount?.toLocaleString() ?? "相談"}
      </Text>
    </View>
  );
}

function ListingEmptyVisual({ label }: { label: string }) {
  return (
    <View style={styles.listingEmptyVisual}>
      <Text style={styles.listingEmptyVisualText}>{label}</Text>
    </View>
  );
}

async function fetchUserProfile(id: string): Promise<UserProfile> {
  if (!supabase) return PREVIEW_PROFILE;
  const [
    { data: userRow },
    { data: evaluations },
    { count: tradeCount },
    { data: itemRowsRaw, error: itemError },
    { data: listingRowsRaw, error: listingError },
  ] = await Promise.all([
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
        "id, title, quantity, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .eq("user_id", id)
      .eq("kind", "for_trade")
      .eq("status", "active")
      .order("created_at", { ascending: false })
      .limit(60),
    supabase
      .from("listings")
      .select("id, have_ids, have_qtys, have_logic, status")
      .eq("user_id", id)
      .eq("status", "active")
      .order("created_at", { ascending: false })
      .limit(30),
  ]);
  if (itemError) throw itemError;
  if (listingError) throw listingError;

  const row = userRow as {
    id: string;
    handle: string | null;
    display_name: string | null;
    primary_area: string | null;
    avatar_url: string | null;
  } | null;
  if (!row) throw new Error("ユーザーが見つかりません");

  const itemRows = (itemRowsRaw as ProfileInventoryRow[] | null) ?? [];
  const listingRows = (listingRowsRaw as ListingRow[] | null) ?? [];
  const listingIds = listingRows.map((listing) => listing.id);
  const { data: optionRowsRaw, error: optionError } =
    listingIds.length > 0
      ? await supabase
          .from("listing_wish_options")
          .select(
            "id, listing_id, position, wish_ids, wish_qtys, logic, exchange_type, is_cash_offer, cash_amount",
          )
          .in("listing_id", listingIds)
          .order("position", { ascending: true })
      : { data: [], error: null };
  if (optionError) throw optionError;

  const optionRows = (optionRowsRaw as OptionRow[] | null) ?? [];
  const optionsByListing = new Map<string, OptionRow[]>();
  for (const option of optionRows) {
    const current = optionsByListing.get(option.listing_id) ?? [];
    current.push(option);
    optionsByListing.set(option.listing_id, current);
  }

  const inventoryIds = Array.from(
    new Set([
      ...itemRows.map((item) => item.id),
      ...listingRows.flatMap((listing) => listing.have_ids ?? []),
      ...optionRows.flatMap((option) => option.wish_ids ?? []),
    ]),
  );
  const [{ data: inventoryRowsRaw, error: inventoryError }, tagLabelsById] =
    await Promise.all([
      inventoryIds.length > 0
        ? supabase
            .from("goods_inventory")
            .select(
              "id, title, hue, photo_urls, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
            )
            .in("id", inventoryIds)
        : Promise.resolve({ data: [], error: null }),
      fetchInventoryTagLabels(itemRows.map((item) => item.id)),
    ]);
  if (inventoryError) throw inventoryError;

  const inventoryById = new Map(
    ((inventoryRowsRaw as InventoryLookupRow[] | null) ?? []).map((item) => [
      item.id,
      item,
    ]),
  );
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
    items: itemRows.map((item) => toProfileItem(item, tagLabelsById[item.id] ?? [])),
    listings: listingRows.map((listing) =>
      toProfileListing(listing, optionsByListing.get(listing.id) ?? [], inventoryById),
    ),
  };
}

function toProfileItem(row: ProfileInventoryRow, tagLabels: string[] = []): ProfileItem {
  const groupName = pickName(row.group) ?? "未設定";
  const characterName = pickName(row.character) ?? groupName;
  const goodsType = pickName(row.goods_type) ?? "グッズ";
  return {
    id: row.id,
    title: row.title || `${characterName} ${goodsType}`,
    subtitle: `${groupName} / ${goodsType}`,
    glyph: characterName.slice(0, 1),
    hue: normalizeHue(row.hue, characterName),
    badge: row.quantity > 1 ? `残 ${row.quantity}` : "譲る候補",
    note: row.quantity > 1 ? `交換可能数 ${row.quantity}` : undefined,
    photoUrl: row.photo_urls?.[0] ?? null,
    tagLabels,
    group: groupName,
    quantity: row.quantity,
    type: goodsType,
  };
}

function toProfileListing(
  row: ListingRow,
  options: OptionRow[],
  inventoryById: Map<string, InventoryLookupRow>,
): ProfileListing {
  const haves = (row.have_ids ?? []).flatMap((id, index) => {
    const source = inventoryById.get(id);
    return source ? [toListingGoodsItem(source, row.have_qtys?.[index] ?? 1)] : [];
  });
  const optionItems: ListingOptionItem[] = [...options]
    .sort((a, b) => a.position - b.position)
    .map((option) => ({
      id: option.id,
      position: option.position,
      logic: option.logic === "and" ? "すべて" : "1pick",
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
      return [`定価 ${option.cashAmount?.toLocaleString() ?? "相談"}円`];
    }
    return option.wishes.map(shortItemLabel);
  });
  const firstHave = haves[0];
  const seed = giveLabels[0] ?? wantLabels[0] ?? "募集";
  return {
    id: row.id,
    status:
      row.status === "matched"
        ? "MATCHED"
        : row.status === "paused"
          ? "PAUSED"
          : "ACTIVE",
    haves,
    options: optionItems,
    give: giveLabels.length > 0 ? giveLabels : ["譲る候補"],
    want: wantLabels.length > 0 ? wantLabels : ["求めるもの"],
    logic: row.have_logic === "and" ? "すべて" : "1pick",
    hue: firstHave?.hue ?? normalizeHue(inventoryById.get(row.have_ids?.[0] ?? "")?.hue, seed),
    group: firstHave?.groupName ?? "未設定",
    type: firstHave?.goodsTypeName ?? "グッズ",
  };
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

function getListingWishSlots(listing: ProfileListing): ListingWishSlot[] {
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

function listingStatusLabel(status: ProfileListing["status"]) {
  if (status === "MATCHED") return "成立済み";
  if (status === "PAUSED") return "一時停止";
  return "公開中";
}

function listingWishSlotLabel(slot: ListingWishSlot) {
  if (slot.option.isCashOffer) {
    return slot.option.cashAmount == null
      ? "定価 相談"
      : `定価 ${slot.option.cashAmount.toLocaleString()}円`;
  }
  return slot.wish ? shortItemLabel(slot.wish) : "求めるもの";
}

function shortItemLabel(item: ListingGoodsItem) {
  return item.characterName ?? item.groupName ?? item.title;
}

function pickName(value: MasterName): string | null {
  if (!value) return null;
  return Array.isArray(value) ? value[0]?.name ?? null : value.name;
}

function normalizeHue(value: string | number | null | undefined, fallback: string) {
  if (typeof value === "string" && value.startsWith("#")) return value;
  if (typeof value === "number") return `hsl(${value}, 38%, 78%)`;
  const hue = Math.abs(Array.from(fallback).reduce((sum, char) => sum + char.charCodeAt(0), 0)) % 360;
  return `hsl(${hue}, 38%, 78%)`;
}

function uniqueSorted(values: string[]) {
  return Array.from(new Set(values.filter(Boolean))).sort((a, b) => a.localeCompare(b, "ja"));
}

const styles = StyleSheet.create({
  screen: {
    paddingHorizontal: 18,
  },
  scrollContent: {
    gap: 16,
    paddingBottom: 28,
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
  rowPressed: {
    backgroundColor: "rgba(166,149,216,0.08)",
  },
  sectionHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  sectionHeaderSpacer: {
    height: 34,
    width: 108,
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
    marginHorizontal: -18,
    minHeight: 220,
  },
  profilePage: {
    paddingHorizontal: 18,
    paddingBottom: 4,
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
  listingsHost: {
    gap: 12,
  },
  listingCard: {
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
  },
  listingGlowSky: {
    backgroundColor: "rgba(168,212,230,0.28)",
    borderRadius: 999,
    bottom: -42,
    height: 142,
    left: -46,
    position: "absolute",
    width: 142,
  },
  listingGlowPink: {
    backgroundColor: "rgba(243,197,212,0.34)",
    borderRadius: 999,
    height: 136,
    position: "absolute",
    right: -52,
    top: -36,
    width: 136,
  },
  listingTop: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  listingMeta: {
    color: megrumColors.mutedInk,
    flex: 1,
    fontSize: 10.5,
    fontWeight: "900",
  },
  listingActionPill: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.13)",
    borderRadius: megrumRadii.pill,
    flexDirection: "row",
    gap: 3,
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  listingActionText: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
  },
  listingBody: {
    gap: 10,
    marginTop: 14,
  },
  listingSide: {
    backgroundColor: "rgba(255,255,255,0.62)",
    borderColor: "rgba(58,50,74,0.06)",
    borderRadius: 16,
    borderWidth: 1,
    gap: 8,
    padding: 10,
  },
  listingSideLabel: {
    backgroundColor: "rgba(255,255,255,0.78)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  listingGoodsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
    width: "100%",
  },
  listingGoodsTile: {
    alignItems: "center",
    gap: 5,
    width: 64,
  },
  listingGoodsName: {
    color: megrumColors.ink,
    fontSize: 9.5,
    fontWeight: "800",
    lineHeight: 12,
    textAlign: "center",
  },
  listingGoodsVisual: {
    alignItems: "center",
    borderRadius: 14,
    borderWidth: 2,
    height: 54,
    justifyContent: "center",
    overflow: "hidden",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 7 },
    shadowOpacity: 0.15,
    shadowRadius: 13,
    width: 54,
  },
  listingGoodsImage: {
    height: "100%",
    width: "100%",
  },
  listingGoodsGlyph: {
    color: megrumColors.surface,
    fontSize: 19,
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.24)",
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 4,
  },
  listingQtyBadge: {
    backgroundColor: "rgba(58,50,74,0.68)",
    borderBottomLeftRadius: 8,
    paddingHorizontal: 5,
    paddingVertical: 1,
    position: "absolute",
    right: 0,
    top: 0,
  },
  listingQtyText: {
    color: megrumColors.surface,
    fontSize: 9,
    fontWeight: "900",
  },
  listingCashVisual: {
    alignItems: "center",
    backgroundColor: "rgba(122,154,138,0.12)",
    borderColor: "rgba(122,154,138,0.34)",
    borderRadius: 15,
    borderWidth: 1,
    height: 54,
    justifyContent: "center",
    overflow: "hidden",
    width: 54,
  },
  listingCashSymbol: {
    color: megrumColors.ink,
    fontSize: 21,
    fontWeight: "900",
    lineHeight: 23,
  },
  listingCashText: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "900",
    maxWidth: "82%",
  },
  listingEmptyVisual: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.70)",
    borderColor: "rgba(58,50,74,0.16)",
    borderRadius: 15,
    borderStyle: "dashed",
    borderWidth: 1,
    height: 54,
    justifyContent: "center",
    width: 54,
  },
  listingEmptyVisualText: {
    color: "rgba(58,50,74,0.45)",
    fontSize: 12,
    fontWeight: "900",
  },
  listingConnector: {
    alignItems: "center",
    alignSelf: "center",
    height: 28,
    justifyContent: "center",
    width: 74,
  },
  listingConnectorLine: {
    backgroundColor: "rgba(166,149,216,0.34)",
    height: 2,
    position: "absolute",
    width: 74,
  },
  listingConnectorKnot: {
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
  listingConnectorText: {
    color: megrumColors.lavender,
    fontSize: 18,
    fontWeight: "900",
    lineHeight: 22,
  },
  statusBadge: {
    alignItems: "center",
    backgroundColor: megrumColors.ok,
    borderRadius: megrumRadii.pill,
    justifyContent: "center",
    minWidth: 52,
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  statusBadgeText: {
    color: megrumColors.surface,
    fontSize: 9.5,
    fontWeight: "900",
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
