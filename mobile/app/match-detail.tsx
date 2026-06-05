import { router, useLocalSearchParams } from "expo-router";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  Animated,
  ActivityIndicator,
  Easing,
  Image,
  Modal,
  PanResponder,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import {
  findCandidateContext,
  getAdjacentCandidateContexts,
  type CandidateContext,
} from "../src/data/homeMatches";
import { useAuth } from "../src/auth/AuthProvider";
import {
  buildProposalCatalogOverrides,
  buildProposalThumbs,
  type ProposalInventoryRow,
  type ProposalThumbItem,
} from "../src/data/proposalItems";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii } from "../src/theme/tokens";

type Priority = "both" | "oneSide" | "wish";
type ListingKind = "both" | "mine" | "partner" | "simple";
type Logic = "and" | "or";
type ExchangeType = "same_kind" | "cross_kind" | "any";

type MiniItem = {
  id: string;
  label: string;
  glyph: string;
  color: string;
  photoUrl?: string | null;
};

type ListingHave = {
  item: MiniItem;
  qty: number;
  matched: boolean;
};

type ListingWish = {
  item: MiniItem;
  qty: number;
  candidates: { item: MiniItem; qty: number }[];
};

type ListingOption = {
  id: string;
  position: number;
  logic: Logic;
  exchangeType: ExchangeType;
  isCashOffer?: boolean;
  cashAmount?: number | null;
  matched: boolean;
  wishes: ListingWish[];
};

type ListingInfo = {
  listingId: string;
  haveLogic: Logic;
  haves: ListingHave[];
  options: ListingOption[];
  isMyListing: boolean;
};

type DetailData = {
  myListings: ListingInfo[];
  partnerListings: ListingInfo[];
  simpleReceives: MiniItem[];
  simpleGives: MiniItem[];
};

type PopupTarget = {
  listingId: string;
  viewpoint: "mine" | "partner";
  wishItem: MiniItem;
  wishQty: number;
  candidates: { item: MiniItem; qty: number }[];
  exchangeType: ExchangeType;
  fallbackHave: MiniItem;
};

type Selection = Record<string, string[]>;
type HaveSelection = Record<string, string[]>;

type ListingRow = {
  id: string;
  user_id: string;
  have_ids: string[] | null;
  have_qtys: number[] | null;
  have_logic: Logic | null;
};

type ListingOptionRow = {
  id: string;
  listing_id: string;
  position: number;
  wish_ids: string[] | null;
  wish_qtys: number[] | null;
  logic: Logic | null;
  exchange_type: ExchangeType | null;
  is_cash_offer: boolean | null;
  cash_amount: number | null;
};

type RealInventoryRow = ProposalInventoryRow & {
  group_id: string | null;
  character_id: string | null;
  goods_type_id: string | null;
};

type CatalogMiniItem = MiniItem & {
  groupId: string | null;
  characterId: string | null;
  goodsTypeId: string | null;
};

const PARTNER_HANDLE = "michilion";
const MY_AVATAR = "私";
const SWIPE_DISTANCE_MIN = 72;
const SWIPE_DISTANCE_MAX = 118;
const SWIPE_FAST_DISTANCE = 42;
const SWIPE_SETTLE_MS = 220;
const SWIPE_RESISTANCE = 0.22;

const BASE_ITEMS = {
  selected: { id: "selected", label: "スア ラキドロ", glyph: "S", color: "#cbbcf4" },
  selectedAlt: { id: "selected-alt", label: "スア 会場限定", glyph: "S", color: "#f3c5d4" },
  partnerHave: { id: "partner-have-1", label: "ニンニン 制服", glyph: "N", color: "#a8d4e6" },
  partnerHave2: { id: "partner-have-2", label: "ウィンター 缶バッジ", glyph: "W", color: "#d5cff4" },
  myHave: { id: "my-have-1", label: "カリナ 春ver.", glyph: "K", color: "#f3c5d4" },
  myHave2: { id: "my-have-2", label: "ジョンウ ラキドロ", glyph: "J", color: "#a8d4e6" },
  myHaveBad: { id: "my-have-bad", label: "V トレカ", glyph: "V", color: "#b7dceb" },
  wishPartner: { id: "wish-partner-1", label: "カリナ 店舗特典", glyph: "K", color: "#f7d5df" },
  wishMine: { id: "wish-mine-1", label: "スア ラキドロ", glyph: "S", color: "#cbbcf4" },
  wishMine2: { id: "wish-mine-2", label: "ニンニン 制服", glyph: "N", color: "#d5cff4" },
};

export default function MatchDetailScreen() {
  const { user, previewMode } = useAuth();
  const params = useLocalSearchParams<{
    candidateId?: string | string[];
    title?: string | string[];
    subtitle?: string | string[];
    member?: string | string[];
    hue?: string | string[];
    priority?: Priority | Priority[];
    local?: string | string[];
    tag?: string | string[];
    partnerId?: string | string[];
    partnerHandle?: string | string[];
    partnerDisplayName?: string | string[];
    avatarUrl?: string | string[];
    photoUrl?: string | string[];
    gives?: string | string[];
    receives?: string | string[];
    listings?: string | string[];
    matchType?: string | string[];
    visualExpanded?: string | string[];
  }>();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const routeCandidateId = one(params.candidateId);
  const [activeContext, setActiveContext] = useState<CandidateContext | null>(() =>
    findCandidateContext(routeCandidateId),
  );
  const activeCandidate = activeContext?.candidate;
  const activeRow = activeContext?.row;
  const title = activeCandidate?.label || one(params.title) || BASE_ITEMS.selected.label;
  const member = activeCandidate?.member || one(params.member) || title.slice(0, 1);
  const color = activeCandidate?.hue || one(params.hue) || BASE_ITEMS.selected.color;
  const photoUrl = activeCandidate?.photoUrl ?? one(params.photoUrl) ?? null;
  const priority = activeCandidate?.priority || parsePriority(one(params.priority));
  const tag = activeCandidate?.tag ?? one(params.tag);
  const routePartnerId = one(params.partnerId);
  const partnerId = routePartnerId || activeCandidate?.partnerId || "";
  const partnerHandle =
    one(params.partnerHandle) || activeCandidate?.partnerHandle || PARTNER_HANDLE;
  const partnerDisplayName =
    one(params.partnerDisplayName) ||
    activeCandidate?.partnerDisplayName ||
    partnerHandle;
  const routeGiveIds = parseRouteIds(one(params.gives));
  const routeReceiveIds = parseRouteIds(one(params.receives));
  const routeItemIdsKey = [...routeGiveIds, ...routeReceiveIds].join(",");
  const routeListingIds = parseRouteIds(one(params.listings));
  const routeListingIdsKey = routeListingIds.join(",");
  const routeMatchType = normalizeMatchType(one(params.matchType));
  const visualExpanded = one(params.visualExpanded);
  const shouldResolveCatalog =
    !!supabase && !previewMode && routeItemIdsKey.length > 0;
  const listingResolutionKey = [
    user?.id ?? "guest",
    routeListingIdsKey,
    routeItemIdsKey,
  ].join("|");
  const shouldResolveRealListing =
    !!supabase &&
    !!user &&
    !previewMode &&
    routeListingIds.length > 0 &&
    routeItemIdsKey.length > 0;
  const [catalogResolvedKey, setCatalogResolvedKey] = useState(() =>
    shouldResolveCatalog ? "" : routeItemIdsKey,
  );
  const [realListingResolvedKey, setRealListingResolvedKey] = useState(() =>
    shouldResolveRealListing ? "" : listingResolutionKey,
  );
  const hasRouteProposal =
    routeGiveIds.length > 0 || routeReceiveIds.length > 0 || routeListingIds.length > 0;
  const listingKind = inferListingKind(priority, tag);
  const highlightedItem: MiniItem = {
    id: activeCandidate?.id ?? "selected",
    label: title,
    glyph: member,
    color,
    photoUrl,
  };
  const adjacentContexts = useMemo(
    () => getAdjacentCandidateContexts(activeCandidate?.id ?? routeCandidateId),
    [activeCandidate?.id, routeCandidateId],
  );
  const [catalogOverrides, setCatalogOverrides] = useState<
    ReturnType<typeof buildProposalCatalogOverrides>
  >(() => new Map());
  const [realListingData, setRealListingData] = useState<DetailData | null>(null);
  const routeCatalogReady =
    !shouldResolveCatalog || catalogResolvedKey === routeItemIdsKey;
  const realListingReady =
    !shouldResolveRealListing ||
    realListingResolvedKey === listingResolutionKey;
  const routeDataLoading = !routeCatalogReady || !realListingReady;
  const data = useMemo(
    () => {
      if (realListingData && listingKind !== "simple") return realListingData;
      return buildDetailData(
        highlightedItem,
        listingKind,
        routeGiveIds,
        routeReceiveIds,
        catalogOverrides,
      );
    },
    [
      catalogOverrides,
      highlightedItem.id,
      highlightedItem.label,
      highlightedItem.glyph,
      highlightedItem.color,
      highlightedItem.photoUrl,
      listingKind,
      realListingData,
      routeItemIdsKey,
    ],
  );
  const [selection, setSelection] = useState<Selection>(() =>
    initialSelection([...data.myListings, ...data.partnerListings], highlightedItem.id),
  );
  const [haveSelection, setHaveSelection] = useState<HaveSelection>(() =>
    initialHaveSelection([...data.myListings, ...data.partnerListings], highlightedItem.id),
  );
  const [popupTarget, setPopupTarget] = useState<PopupTarget | null>(null);
  const [swapCoverContext, setSwapCoverContext] =
    useState<CandidateContext | null>(null);
  const dragX = useRef(new Animated.Value(0)).current;
  const swipeLockRef = useRef(false);
  const swapFrameIdsRef = useRef<number[]>([]);
  const [isSwipeSettling, setIsSwipeSettling] = useState(false);

  useEffect(
    () => () => {
      for (const id of swapFrameIdsRef.current) {
        cancelAnimationFrame(id);
      }
      swapFrameIdsRef.current = [];
    },
    [],
  );

  useEffect(() => {
    const listings = [...data.myListings, ...data.partnerListings];
    setSelection(initialSelection(listings, highlightedItem.id));
    setHaveSelection(initialHaveSelection(listings, highlightedItem.id));
    setPopupTarget(null);
  }, [data, highlightedItem.id]);

  useEffect(() => {
    if (visualExpanded !== "candidates" || routeDataLoading) return;
    const target = firstVisualCandidatePopupTarget({
      myListings: data.myListings,
      partnerListings: data.partnerListings,
      highlightedItemId: highlightedItem.id,
    });
    if (target) setPopupTarget(target);
  }, [data, highlightedItem.id, routeDataLoading, visualExpanded]);

  useEffect(() => {
    if (!supabase || previewMode || routeItemIdsKey.length === 0) {
      setCatalogOverrides(new Map());
      setCatalogResolvedKey(routeItemIdsKey);
      return;
    }
    const ids = Array.from(new Set([...routeGiveIds, ...routeReceiveIds]));
    let active = true;
    setCatalogOverrides(new Map());
    setCatalogResolvedKey("");
    void (async () => {
      try {
        const { data: rows } = await supabase
          .from("goods_inventory")
          .select(
            "id, title, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
          )
          .in("id", ids);
        if (!active) return;
        setCatalogOverrides(
          buildProposalCatalogOverrides((rows as ProposalInventoryRow[] | null) ?? []),
        );
        setCatalogResolvedKey(routeItemIdsKey);
      } catch {
        if (!active) return;
        setCatalogOverrides(new Map());
        setCatalogResolvedKey(routeItemIdsKey);
      }
    })();
    return () => {
      active = false;
    };
  }, [previewMode, routeItemIdsKey]);

  useEffect(() => {
    if (
      !supabase ||
      !user ||
      previewMode ||
      routeListingIds.length === 0 ||
      routeItemIdsKey.length === 0
    ) {
      setRealListingData(null);
      setRealListingResolvedKey(listingResolutionKey);
      return;
    }

    let active = true;
    setRealListingData(null);
    setRealListingResolvedKey("");
    fetchRealListingDetail({
      listingIds: routeListingIds,
      userId: user.id,
      routeGiveIds,
      routeReceiveIds,
    })
      .then((next) => {
        if (!active) return;
        setRealListingData(next);
        setRealListingResolvedKey(listingResolutionKey);
      })
      .catch(() => {
        if (!active) return;
        setRealListingData(null);
        setRealListingResolvedKey(listingResolutionKey);
      });
    return () => {
      active = false;
    };
  }, [listingResolutionKey, previewMode, routeItemIdsKey, routeListingIdsKey, user?.id]);

  const panResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: (_, gesture) => {
          if (popupTarget || isSwipeSettling || swipeLockRef.current) return false;
          const absX = Math.abs(gesture.dx);
          const absY = Math.abs(gesture.dy);
          if (absX < 8 || absX <= absY * 1.08) return false;
          return gesture.dx < 0
            ? !!adjacentContexts.next
            : !!adjacentContexts.previous;
        },
        onPanResponderGrant: () => {
          dragX.stopAnimation();
        },
        onPanResponderMove: (_, gesture) => {
          const canMove =
            gesture.dx < 0
              ? !!adjacentContexts.next
              : !!adjacentContexts.previous;
          const rawOffset = canMove ? gesture.dx : gesture.dx * SWIPE_RESISTANCE;
          const nextOffset = Math.max(-width, Math.min(width, rawOffset));
          dragX.setValue(nextOffset);
        },
        onPanResponderRelease: (_, gesture) => {
          const wantsNext = gesture.dx < 0;
          const target = wantsNext
            ? adjacentContexts.next
            : adjacentContexts.previous;
          const threshold = Math.min(
            SWIPE_DISTANCE_MAX,
            Math.max(SWIPE_DISTANCE_MIN, width * 0.24),
          );
          const farEnough = Math.abs(gesture.dx) >= threshold;
          const fastEnough =
            Math.abs(gesture.dx) >= SWIPE_FAST_DISTANCE &&
            Math.abs(gesture.vx) >= 0.55;

          if (target && (farEnough || fastEnough)) {
            commitSwipe(target, wantsNext ? "next" : "previous");
            return;
          }
          settleSwipeBack();
        },
        onPanResponderTerminate: settleSwipeBack,
      }),
    [
      adjacentContexts.next,
      adjacentContexts.previous,
      dragX,
      isSwipeSettling,
      popupTarget,
      width,
    ],
  );

  function settleSwipeBack() {
    Animated.spring(dragX, {
      toValue: 0,
      damping: 18,
      stiffness: 170,
      mass: 0.72,
      useNativeDriver: true,
    }).start();
  }

  function commitSwipe(
    nextContext: CandidateContext,
    direction: "next" | "previous",
  ) {
    if (swipeLockRef.current) return;
    swipeLockRef.current = true;
    setIsSwipeSettling(true);
    Animated.timing(dragX, {
      toValue: direction === "next" ? -width : width,
      duration: SWIPE_SETTLE_MS,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start(({ finished }) => {
      if (!finished) {
        swipeLockRef.current = false;
        setIsSwipeSettling(false);
        return;
      }
      setSwapCoverContext(nextContext);
      scheduleSwapFrame(() => {
        setActiveContext(nextContext);
        dragX.setValue(0);
        scheduleSwapFrame(() => {
          setSwapCoverContext(null);
          swipeLockRef.current = false;
          setIsSwipeSettling(false);
        });
      });
    });
  }

  function scheduleSwapFrame(callback: () => void) {
    const frameId = requestAnimationFrame(() => {
      swapFrameIdsRef.current = swapFrameIdsRef.current.filter(
        (id) => id !== frameId,
      );
      callback();
    });
    swapFrameIdsRef.current.push(frameId);
  }

  const aggregated = aggregateSelection({
    myListings: data.myListings,
    partnerListings: data.partnerListings,
    selection,
    haveSelection,
  });
  const hasRelationSelection = aggregated.referencedListingIds.length > 0;
  const proposalGiveIds =
    hasRelationSelection || routeGiveIds.length === 0 ? aggregated.giveIds : routeGiveIds;
  const proposalReceiveIds =
    hasRelationSelection || routeReceiveIds.length === 0
      ? aggregated.receiveIds
      : routeReceiveIds;
  const proposalListingIds =
    hasRelationSelection || routeListingIds.length === 0
      ? aggregated.referencedListingIds
      : routeListingIds;
  const proposalParams = {
    tab: "meetup",
    candidateId: highlightedItem.id,
    ...(partnerId ? { partnerId } : {}),
    partnerHandle,
    matchType: routeMatchType,
    gives: proposalGiveIds.join(","),
    receives: proposalReceiveIds.join(","),
    listings: proposalListingIds.join(","),
  };
  const simpleProposalParams = {
    tab: "meetup",
    candidateId: highlightedItem.id,
    ...(partnerId ? { partnerId } : {}),
    partnerHandle,
    matchType: routeMatchType,
    gives: (routeGiveIds.length > 0
      ? routeGiveIds
      : data.simpleGives.map((item) => item.id)
    ).join(","),
    receives: (routeReceiveIds.length > 0
      ? routeReceiveIds
      : data.simpleReceives.map((item) => item.id)
    ).join(","),
  };
  const totalSelected = Object.values(selection).reduce(
    (sum, ids) => sum + ids.length,
    0,
  );
  const hasListingRelation =
    routeListingIds.length > 0 || data.myListings.length > 0 || data.partnerListings.length > 0;
  const hasSimpleRelation =
    !hasListingRelation &&
    (hasRouteProposal || data.simpleReceives.length > 0 || data.simpleGives.length > 0);

  return (
    <View style={styles.root}>
      <Animated.View
        style={[
          styles.swipeRail,
          {
            transform: [{ translateX: dragX }],
          },
        ]}
        {...panResponder.panHandlers}
      >
        {adjacentContexts.previous ? (
          <SwipePreview
            context={adjacentContexts.previous}
            side="previous"
            width={width}
          />
        ) : null}
        {adjacentContexts.next ? (
          <SwipePreview
            context={adjacentContexts.next}
            side="next"
            width={width}
          />
        ) : null}

        <View style={[styles.swipePage, { width }]}>
          <View style={[styles.header, { paddingTop: Math.max(insets.top, 18) + 8 }]}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="閉じる"
              onPress={() => router.back()}
              style={styles.closeButton}
            >
              <Text style={styles.closeText}>×</Text>
            </Pressable>
            <View style={styles.headerCopy}>
              <Text style={styles.headerTitle}>関係図</Text>
            </View>
            {partnerId ? (
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={`${partnerDisplayName}のプロフィールを見る`}
                onPress={() =>
                  router.push({
                    pathname: "/user-profile",
                    params: { id: partnerId },
                  })
                }
                style={styles.profileButton}
              >
                <Text style={styles.profileButtonText}>プロフィール</Text>
              </Pressable>
            ) : null}
          </View>

          <ScrollView
            showsVerticalScrollIndicator={false}
            contentContainerStyle={[
              styles.content,
              {
                paddingBottom:
                  Math.max(insets.bottom, 12) +
                  (!routeDataLoading && (totalSelected > 0 || hasSimpleRelation) ? 96 : 24),
              },
            ]}
          >
            {routeDataLoading ? (
              <View style={styles.detailLoadingPanel}>
                <ActivityIndicator color={megrumColors.lavender} size="small" />
                <Text style={styles.detailLoadingTitle}>マッチ詳細を読み込み中…</Text>
                <Text style={styles.detailLoadingText}>
                  在庫と個別募集を確認しています
                </Text>
              </View>
            ) : (
              <>
                {data.myListings.length > 0 ? (
                  <SectionGroup
                    title="あなたの個別募集"
                    titleOnly
                    subtitle=""
                    accentColor={megrumColors.lavender}
                  >
                    {data.myListings.map((listing, index) => (
                      <ListingTree
                        key={listing.listingId}
                        listing={listing}
                        index={index}
                        viewpoint="mine"
                        highlightedItemId={highlightedItem.id}
                        selection={selection}
                        haveSelection={haveSelection}
                        onToggleCandidate={toggleCandidate}
                        onToggleHave={toggleHave}
                        onOpenPopup={setPopupTarget}
                      />
                    ))}
                  </SectionGroup>
                ) : null}

                {data.partnerListings.length > 0 ? (
                  <SectionGroup
                    title={`@${partnerHandle} の個別募集`}
                    subtitle="相手が出している条件で、あなたの在庫がヒット"
                    accentColor={megrumColors.pink}
                  >
                    {data.partnerListings.map((listing, index) => (
                      <ListingTree
                        key={listing.listingId}
                        listing={listing}
                        index={index}
                        viewpoint="partner"
                        highlightedItemId={highlightedItem.id}
                        selection={selection}
                        haveSelection={haveSelection}
                        onToggleCandidate={toggleCandidate}
                        onToggleHave={toggleHave}
                        onOpenPopup={setPopupTarget}
                      />
                    ))}
                  </SectionGroup>
                ) : null}

                {!hasListingRelation ? (
                  hasSimpleRelation ? (
                    <SimpleRelationPanel
                      receivesItems={data.simpleReceives}
                      givesItems={data.simpleGives}
                      highlightedItemId={highlightedItem.id}
                    />
                  ) : (
                    <View style={styles.emptyRelation}>
                      <Text style={styles.emptyRelationText}>個別募集経由のマッチはありません</Text>
                    </View>
                  )
                ) : null}

                {totalSelected > 0 ? (
                  <GlobalSummary
                    receivesItems={aggregated.receivesItems}
                    givesItems={aggregated.givesItems}
                    highlightedItemId={highlightedItem.id}
                  />
                ) : null}
              </>
            )}
          </ScrollView>

          {!routeDataLoading && totalSelected > 0 ? (
            <View style={[styles.footer, { paddingBottom: Math.max(insets.bottom, 12) }]}>
              <Pressable
                onPress={() => setSelection({})}
                style={styles.resetButton}
              >
                <Text style={styles.resetButtonText}>リセット</Text>
              </Pressable>
              <Pressable
                onPress={() =>
                  router.push({
                    pathname: "/proposal-select",
                    params: proposalParams,
                  })
                }
                style={styles.primaryFooterButton}
              >
                <Text style={styles.primaryFooterButtonText}>
                  打診に進む（{totalSelected} 件）→
                </Text>
              </Pressable>
            </View>
          ) : null}

          {!routeDataLoading && hasSimpleRelation ? (
            <View style={[styles.footer, { paddingBottom: Math.max(insets.bottom, 12) }]}>
              <Pressable onPress={() => router.back()} style={styles.resetButton}>
                <Text style={styles.resetButtonText}>閉じる</Text>
              </Pressable>
              <Pressable
                onPress={() =>
                  router.push({
                    pathname: "/proposal-select",
                    params: simpleProposalParams,
                  })
                }
                style={styles.primaryFooterButton}
              >
                <Text style={styles.primaryFooterButtonText}>この内容で打診へ →</Text>
              </Pressable>
            </View>
          ) : null}
        </View>
      </Animated.View>

      {popupTarget ? (
        <WishPopup
          target={popupTarget}
          highlightedItemId={highlightedItem.id}
          selectedIds={selection[popupTarget.listingId] ?? []}
          onToggleCandidate={(id) => toggleCandidate(popupTarget.listingId, id)}
          onClose={() => setPopupTarget(null)}
        />
      ) : null}

      {swapCoverContext ? (
        <SwipeSettledCover context={swapCoverContext} width={width} />
      ) : null}
    </View>
  );

  function toggleCandidate(listingId: string, candidateId: string) {
    setSelection((current) => {
      const ids = current[listingId] ?? [];
      const nextIds = ids.includes(candidateId)
        ? ids.filter((id) => id !== candidateId)
        : [...ids, candidateId];
      const next = { ...current };
      if (nextIds.length === 0) delete next[listingId];
      else next[listingId] = nextIds;
      return next;
    });
  }

  function toggleHave(listingId: string, haveId: string) {
    setHaveSelection((current) => {
      const ids = current[listingId] ?? [];
      const nextIds = ids.includes(haveId)
        ? ids.filter((id) => id !== haveId)
        : [...ids, haveId];
      return { ...current, [listingId]: nextIds };
    });
  }
}

function SwipePreview({
  context,
  side,
  width,
}: {
  context: CandidateContext;
  side: "previous" | "next";
  width: number;
}) {
  const insets = useSafeAreaInsets();
  const { row, candidate } = context;
  const title = candidate.label;
  const highlightedItem: MiniItem = {
    id: candidate.id,
    label: title,
    glyph: candidate.member,
    color: candidate.hue,
    photoUrl: candidate.photoUrl ?? null,
  };
  const listingKind = inferListingKind(candidate.priority, candidate.tag);
  const data = useMemo(
    () => buildDetailData(highlightedItem, listingKind),
    [highlightedItem.id, highlightedItem.label, highlightedItem.glyph, highlightedItem.color, listingKind],
  );
  const previewListings = [...data.myListings, ...data.partnerListings];
  const previewSelection = useMemo(
    () => initialSelection(previewListings, highlightedItem.id),
    [highlightedItem.id, previewListings],
  );
  const previewHaveSelection = useMemo(
    () => initialHaveSelection(previewListings, highlightedItem.id),
    [highlightedItem.id, previewListings],
  );
  const hasListingRelation =
    data.myListings.length > 0 || data.partnerListings.length > 0;
  const hasSimpleRelation =
    !hasListingRelation &&
    (data.simpleReceives.length > 0 || data.simpleGives.length > 0);

  return (
    <View
      pointerEvents="none"
      style={[
        styles.previewPage,
        {
          left: side === "previous" ? -width : width,
          width,
        },
      ]}
    >
      <View style={[styles.header, { paddingTop: Math.max(insets.top, 18) + 8 }]}>
        <View style={styles.closeButton}>
          <Text style={styles.closeText}>×</Text>
        </View>
        <View style={styles.headerCopy}>
          <Text style={styles.headerTitle}>関係図</Text>
        </View>
      </View>

      <ScrollView
        scrollEnabled={false}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={[styles.content, styles.previewContent]}
      >
        {data.myListings.length > 0 ? (
          <SectionGroup
            title="あなたの個別募集"
            titleOnly
            subtitle=""
            accentColor={megrumColors.lavender}
          >
            {data.myListings.map((listing, index) => (
              <ListingTree
                key={listing.listingId}
                listing={listing}
                index={index}
                viewpoint="mine"
                highlightedItemId={highlightedItem.id}
                selection={previewSelection}
                haveSelection={previewHaveSelection}
                onToggleCandidate={() => undefined}
                onToggleHave={() => undefined}
                onOpenPopup={() => undefined}
              />
            ))}
          </SectionGroup>
        ) : null}

        {data.partnerListings.length > 0 ? (
          <SectionGroup
            title={`@${PARTNER_HANDLE} の個別募集`}
            subtitle="相手が出している条件で、あなたの在庫がヒット"
            accentColor={megrumColors.pink}
          >
            {data.partnerListings.map((listing, index) => (
              <ListingTree
                key={listing.listingId}
                listing={listing}
                index={index}
                viewpoint="partner"
                highlightedItemId={highlightedItem.id}
                selection={previewSelection}
                haveSelection={previewHaveSelection}
                onToggleCandidate={() => undefined}
                onToggleHave={() => undefined}
                onOpenPopup={() => undefined}
              />
            ))}
          </SectionGroup>
        ) : null}

        {!hasListingRelation && hasSimpleRelation ? (
          <SimpleRelationPanel
            receivesItems={data.simpleReceives}
            givesItems={data.simpleGives}
            highlightedItemId={highlightedItem.id}
          />
        ) : null}
      </ScrollView>
    </View>
  );
}

function SwipeSettledCover({
  context,
  width,
}: {
  context: CandidateContext;
  width: number;
}) {
  const insets = useSafeAreaInsets();
  const { candidate } = context;
  const highlightedItem: MiniItem = {
    id: candidate.id,
    label: candidate.label,
    glyph: candidate.member,
    color: candidate.hue,
    photoUrl: candidate.photoUrl ?? null,
  };
  const listingKind = inferListingKind(candidate.priority, candidate.tag);
  const data = useMemo(
    () => buildDetailData(highlightedItem, listingKind),
    [
      highlightedItem.id,
      highlightedItem.label,
      highlightedItem.glyph,
      highlightedItem.color,
      listingKind,
    ],
  );
  const previewListings = [...data.myListings, ...data.partnerListings];
  const previewSelection = useMemo(
    () => initialSelection(previewListings, highlightedItem.id),
    [highlightedItem.id, previewListings],
  );
  const previewHaveSelection = useMemo(
    () => initialHaveSelection(previewListings, highlightedItem.id),
    [highlightedItem.id, previewListings],
  );
  const hasListingRelation =
    data.myListings.length > 0 || data.partnerListings.length > 0;
  const hasSimpleRelation =
    !hasListingRelation &&
    (data.simpleReceives.length > 0 || data.simpleGives.length > 0);

  return (
    <View pointerEvents="none" style={[styles.swapCover, { width }]}>
      <View style={[styles.header, { paddingTop: Math.max(insets.top, 18) + 8 }]}>
        <View style={styles.closeButton}>
          <Text style={styles.closeText}>×</Text>
        </View>
        <View style={styles.headerCopy}>
          <Text style={styles.headerTitle}>関係図</Text>
        </View>
      </View>

      <ScrollView
        scrollEnabled={false}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={[styles.content, styles.previewContent]}
      >
        {data.myListings.length > 0 ? (
          <SectionGroup
            title="あなたの個別募集"
            titleOnly
            subtitle=""
            accentColor={megrumColors.lavender}
          >
            {data.myListings.map((listing, index) => (
              <ListingTree
                key={listing.listingId}
                listing={listing}
                index={index}
                viewpoint="mine"
                highlightedItemId={highlightedItem.id}
                selection={previewSelection}
                haveSelection={previewHaveSelection}
                onToggleCandidate={() => undefined}
                onToggleHave={() => undefined}
                onOpenPopup={() => undefined}
              />
            ))}
          </SectionGroup>
        ) : null}

        {data.partnerListings.length > 0 ? (
          <SectionGroup
            title={`@${PARTNER_HANDLE} の個別募集`}
            subtitle="相手が出している条件で、あなたの在庫がヒット"
            accentColor={megrumColors.pink}
          >
            {data.partnerListings.map((listing, index) => (
              <ListingTree
                key={listing.listingId}
                listing={listing}
                index={index}
                viewpoint="partner"
                highlightedItemId={highlightedItem.id}
                selection={previewSelection}
                haveSelection={previewHaveSelection}
                onToggleCandidate={() => undefined}
                onToggleHave={() => undefined}
                onOpenPopup={() => undefined}
              />
            ))}
          </SectionGroup>
        ) : null}

        {!hasListingRelation && hasSimpleRelation ? (
          <SimpleRelationPanel
            receivesItems={data.simpleReceives}
            givesItems={data.simpleGives}
            highlightedItemId={highlightedItem.id}
          />
        ) : null}
      </ScrollView>
    </View>
  );
}

function ListingTree({
  listing,
  index,
  viewpoint,
  highlightedItemId,
  selection,
  haveSelection,
  onToggleCandidate,
  onToggleHave,
  onOpenPopup,
}: {
  listing: ListingInfo;
  index: number;
  viewpoint: "mine" | "partner";
  highlightedItemId: string;
  selection: Selection;
  haveSelection: HaveSelection;
  onToggleCandidate: (listingId: string, candidateId: string) => void;
  onToggleHave: (listingId: string, haveId: string) => void;
  onOpenPopup: (target: PopupTarget) => void;
}) {
  const fallbackHave = listing.haves[0]?.item ?? BASE_ITEMS.myHave;
  const optionCount = listing.options.filter((option) => !option.isCashOffer).length;
  const cashOption = listing.options.find((option) => option.isCashOffer);

  return (
    <View style={styles.listingTree}>
      <View style={styles.listingHeader}>
        <View style={styles.listingHeaderText}>
          <Text style={styles.listingTitle}>個別募集{index + 1}</Text>
          <Text style={styles.listingOptionCount}>（選択肢 {optionCount} 件）</Text>
        </View>
        {cashOption ? (
          <View style={styles.cashPill}>
            <Text style={styles.cashPillText}>
              ¥{cashOption.cashAmount?.toLocaleString() ?? "—"} も可
            </Text>
          </View>
        ) : null}
      </View>

      <View style={styles.treeBody}>
        <View style={styles.treeSideLeft}>
          <OwnerLabel
            color={megrumColors.pink}
            name={`@${PARTNER_HANDLE} が譲るもの`}
            avatarName={PARTNER_HANDLE}
          />
          {viewpoint === "mine" ? (
            <OptionList
              listing={listing}
              viewpoint={viewpoint}
              fallbackHave={fallbackHave}
              highlightedItemId={highlightedItemId}
              selection={selection}
              onOpenPopup={onOpenPopup}
            />
          ) : (
            <HaveList
              listing={listing}
              highlightedItemId={highlightedItemId}
              selectedIds={haveSelection[listing.listingId] ?? []}
              onToggleHave={onToggleHave}
            />
          )}
        </View>

        <View style={styles.treeSideRight}>
          <OwnerLabel
            color={megrumColors.lavender}
            name="あなた が譲るもの"
            avatarName={MY_AVATAR}
            right
          />
          {viewpoint === "mine" ? (
            <HaveList
              listing={listing}
              highlightedItemId={highlightedItemId}
              selectedIds={haveSelection[listing.listingId] ?? []}
              onToggleHave={onToggleHave}
            />
          ) : (
            <OptionList
              listing={listing}
              viewpoint={viewpoint}
              fallbackHave={fallbackHave}
              highlightedItemId={highlightedItemId}
              selection={selection}
              onOpenPopup={onOpenPopup}
            />
          )}
        </View>
      </View>
    </View>
  );
}

function OptionList({
  listing,
  viewpoint,
  fallbackHave,
  highlightedItemId,
  selection,
  onOpenPopup,
}: {
  listing: ListingInfo;
  viewpoint: "mine" | "partner";
  fallbackHave: MiniItem;
  highlightedItemId: string;
  selection: Selection;
  onOpenPopup: (target: PopupTarget) => void;
}) {
  const [archiveOpen, setArchiveOpen] = useState(false);
  const validOptions = listing.options.filter((option) => !option.isCashOffer);
  const matchingOptions = validOptions
    .filter((option) => option.wishes.some((wish) => wish.candidates.length > 0))
    .sort((a, b) => {
      if (a.matched !== b.matched) return Number(b.matched) - Number(a.matched);
      return a.position - b.position;
    });
  const unavailableGroups = validOptions
    .map((option) => ({
      option,
      wishes: option.wishes.filter((wish) => wish.candidates.length === 0),
    }))
    .filter((group) => group.wishes.length > 0);
  const unavailableTotal = unavailableGroups.reduce(
    (sum, group) => sum + group.wishes.length,
    0,
  );

  return (
    <View style={styles.optionList}>
      {matchingOptions.map((option) => (
        <OptionGroup
          key={option.id}
          option={option}
          listing={listing}
          viewpoint={viewpoint}
          fallbackHave={fallbackHave}
          highlightedItemId={highlightedItemId}
          selectedIds={selection[listing.listingId] ?? []}
          onOpenPopup={onOpenPopup}
        />
      ))}
      {unavailableTotal > 0 ? (
        <View style={styles.unavailableArchive}>
          <Pressable
            onPress={() => setArchiveOpen((current) => !current)}
            style={styles.unavailableArchiveButton}
          >
            <Text style={styles.unavailableArchiveText}>
              {archiveOpen ? "− 閉じる" : `＋ 条件外の選択肢 ${unavailableTotal} 件`}
            </Text>
          </Pressable>
          {archiveOpen ? (
            <View style={styles.unavailableArchiveBody}>
              {unavailableGroups.map(({ option, wishes }) => (
                <View key={option.id} style={styles.unavailableGroup}>
                  <Text style={styles.unavailableGroupTitle}>
                    #{option.position}
                    {option.logic === "and" && wishes.length > 1 ? " セット" : ""}
                    {option.logic === "or" && wishes.length > 1 ? " いずれか" : ""}
                  </Text>
                  {wishes.map((wish) => (
                    <UnavailableWishRow
                      key={`${option.id}-${wish.item.id}`}
                      wish={wish}
                      exchangeType={option.exchangeType}
                      fallbackHave={fallbackHave}
                    />
                  ))}
                </View>
              ))}
            </View>
          ) : null}
        </View>
      ) : null}
    </View>
  );
}

function OptionGroup({
  option,
  listing,
  viewpoint,
  fallbackHave,
  highlightedItemId,
  selectedIds,
  onOpenPopup,
}: {
  option: ListingOption;
  listing: ListingInfo;
  viewpoint: "mine" | "partner";
  fallbackHave: MiniItem;
  highlightedItemId: string;
  selectedIds: string[];
  onOpenPopup: (target: PopupTarget) => void;
}) {
  const visibleWishes = option.wishes.filter((wish) => wish.candidates.length > 0);
  const isAndGroup = option.logic === "and" && option.wishes.length > 1;
  const isOrGroup = option.logic === "or" && option.wishes.length > 1;
  if (visibleWishes.length === 0) return null;

  return (
    <View
      style={[
        styles.optionGroup,
        isAndGroup ? styles.optionGroupAnd : null,
        isOrGroup ? styles.optionGroupOr : null,
      ]}
    >
      {isAndGroup || isOrGroup ? (
        <View style={styles.optionGroupHeader}>
          <View
            style={[
              styles.optionGroupBadge,
              isAndGroup ? styles.optionGroupBadgeAnd : styles.optionGroupBadgeOr,
            ]}
          >
            <Text
              style={[
                styles.optionGroupBadgeText,
                isAndGroup
                  ? styles.optionGroupBadgeTextAnd
                  : styles.optionGroupBadgeTextOr,
              ]}
            >
              #{option.position} {isAndGroup ? "セット (AND)" : "いずれか (OR)"}
            </Text>
          </View>
          <Text style={styles.optionGroupSub}>
            {isAndGroup ? "全部一緒に" : "どれか 1 つで OK"}
          </Text>
        </View>
      ) : null}

      <View style={styles.optionWishes}>
        {visibleWishes.map((wish) => (
          <WishRow
            key={wish.item.id}
            wish={wish}
            exchangeType={option.exchangeType}
            fallbackHave={fallbackHave}
            highlightedItemId={highlightedItemId}
            selectedIds={selectedIds}
            onOpen={() =>
              onOpenPopup({
                listingId: listing.listingId,
                viewpoint,
                wishItem: wish.item,
                wishQty: wish.qty,
                candidates: wish.candidates,
                exchangeType: option.exchangeType,
                fallbackHave,
              })
            }
          />
        ))}
      </View>
    </View>
  );
}

function WishRow({
  wish,
  exchangeType,
  fallbackHave,
  highlightedItemId,
  selectedIds,
  onOpen,
}: {
  wish: ListingWish;
  exchangeType: ExchangeType;
  fallbackHave: MiniItem;
  highlightedItemId: string;
  selectedIds: string[];
  onOpen: () => void;
}) {
  const selectedCandidates = wish.candidates.filter((candidate) =>
    selectedIds.includes(candidate.item.id),
  );

  return (
    <View style={styles.wishRow}>
      <Pressable onPress={onOpen} style={styles.wishButton}>
        <View style={styles.wishPhotoWrap}>
          <ItemPhoto item={wish.item} qty={1} size={42} variant="wish" />
          <View style={[styles.exchangeChipSmall, exchangeChipStyle(exchangeType)]}>
            <Text style={styles.exchangeChipSmallText}>
              {exchangeLabel(exchangeType)}
            </Text>
          </View>
        </View>
        <View style={styles.wishText}>
          <View style={styles.wishTitleLine}>
            <Text style={styles.wishTargetIcon}>🎯</Text>
            <Text numberOfLines={1} style={styles.wishTitle}>
              {wish.item.label}
            </Text>
            <Text style={styles.wishQty}>×{wish.qty}</Text>
          </View>
          <Text style={styles.wishMeta}>候補 {wish.candidates.length} 件</Text>
        </View>
        <Text style={styles.chevron}>›</Text>
      </Pressable>

      {selectedCandidates.length > 0 ? (
        <View style={styles.selectedCandidates}>
          <Text style={styles.selectedCandidatesLabel}>選択中：</Text>
          <View style={styles.selectedCandidateStrip}>
            {selectedCandidates.map((candidate) => (
              <ItemPhoto
                key={candidate.item.id}
                item={candidate.item}
                qty={1}
                size={38}
                variant="candidate"
                highlighted={candidate.item.id === highlightedItemId}
              />
            ))}
          </View>
        </View>
      ) : null}
    </View>
  );
}

function HaveList({
  listing,
  highlightedItemId,
  selectedIds,
  onToggleHave,
}: {
  listing: ListingInfo;
  highlightedItemId: string;
  selectedIds: string[];
  onToggleHave: (listingId: string, haveId: string) => void;
}) {
  const [showUnavailable, setShowUnavailable] = useState(false);
  const interactive = listing.haveLogic === "or" && listing.haves.length >= 2;
  const visibleHaves = listing.haves.filter(
    (have) =>
      showUnavailable || have.matched || have.item.id === highlightedItemId,
  );
  const hiddenUnavailableCount = listing.haves.length - visibleHaves.length;

  return (
    <View style={styles.haveList}>
      {visibleHaves.map((have) => {
        const selected = selectedIds.includes(have.item.id);
        const highlighted = have.item.id === highlightedItemId;
        if (!interactive) {
          return (
            <ItemPhoto
              key={have.item.id}
              item={have.item}
              qty={have.qty}
              size={56}
              variant="have"
              dim={!have.matched}
              highlighted={highlighted}
            />
          );
        }

        return (
          <Pressable
            key={have.item.id}
            onPress={() => onToggleHave(listing.listingId, have.item.id)}
            style={[
              styles.haveSelectable,
              selected ? styles.haveSelectableOn : styles.haveSelectableOff,
            ]}
          >
            <ItemPhoto
              item={have.item}
              qty={have.qty}
              size={56}
              variant="have"
              highlighted={highlighted}
            />
            {selected ? (
              <View style={styles.selectedBadge}>
                <Text style={styles.selectedBadgeText}>✓</Text>
              </View>
            ) : null}
          </Pressable>
        );
      })}
      {hiddenUnavailableCount > 0 ? (
        <Pressable
          onPress={() => setShowUnavailable(true)}
          style={styles.hiddenButton}
        >
          <Text style={styles.hiddenButtonText}>
            ＋ 交換できない候補 {hiddenUnavailableCount} 件
          </Text>
        </Pressable>
      ) : null}
      {showUnavailable && hiddenUnavailableCount === 0 ? (
        <Pressable
          onPress={() => setShowUnavailable(false)}
          style={styles.hiddenButton}
        >
          <Text style={styles.hiddenButtonMuted}>閉じる</Text>
        </Pressable>
      ) : null}
      {listing.haves.length > 1 ? (
        <View
          style={[
            styles.logicPill,
            listing.haveLogic === "and" ? styles.logicPillAnd : styles.logicPillOr,
          ]}
        >
          <Text
            style={[
              styles.logicPillText,
              listing.haveLogic === "and"
                ? styles.logicPillTextAnd
                : styles.logicPillTextOr,
            ]}
          >
            {listing.haveLogic === "and" ? "全部 AND" : "いずれか OR ─ 選択可"}
          </Text>
        </View>
      ) : null}
    </View>
  );
}

function SimpleRelationPanel({
  receivesItems,
  givesItems,
  highlightedItemId,
}: {
  receivesItems: MiniItem[];
  givesItems: MiniItem[];
  highlightedItemId: string;
}) {
  return (
    <View style={styles.simplePanel}>
      <View style={styles.simpleHeader}>
        <Text style={styles.simpleHeaderTitle}>譲 × wish の関係</Text>
        <Text style={styles.simpleHeaderSub}>
          個別募集なしで、お互いの登録内容が重なっています
        </Text>
      </View>
      <View style={styles.simpleBody}>
        <View style={[styles.simpleSide, styles.simpleReceive]}>
          <Text style={styles.simpleReceiveTitle}>あなたが受け取る</Text>
          <Text style={styles.simpleMeta}>@{PARTNER_HANDLE} の譲</Text>
          <ThumbStrip items={receivesItems} highlightedItemId={highlightedItemId} />
        </View>
        <View style={styles.simpleSwap}>
          <Text style={styles.simpleSwapText}>⇄</Text>
        </View>
        <View style={[styles.simpleSide, styles.simpleGive]}>
          <Text style={styles.simpleGiveTitle}>あなたが譲る</Text>
          <Text style={styles.simpleMeta}>相手の wish に一致</Text>
          <ThumbStrip items={givesItems} highlightedItemId={highlightedItemId} />
        </View>
      </View>
    </View>
  );
}

function GlobalSummary({
  receivesItems,
  givesItems,
  highlightedItemId,
}: {
  receivesItems: MiniItem[];
  givesItems: MiniItem[];
  highlightedItemId: string;
}) {
  return (
    <View style={styles.summary}>
      <Text style={styles.summaryTitle}>📋 結論：この交換</Text>
      <View style={styles.summaryLine}>
        <View style={styles.summarySide}>
          <Text style={[styles.summaryBadge, styles.summaryReceiveBadge]}>あなたが受</Text>
          <ThumbStrip items={receivesItems} highlightedItemId={highlightedItemId} />
        </View>
        <Text style={styles.summarySwap}>⇄</Text>
        <View style={styles.summarySide}>
          <Text style={[styles.summaryBadge, styles.summaryGiveBadge]}>あなたが譲</Text>
          <ThumbStrip items={givesItems} highlightedItemId={highlightedItemId} />
        </View>
      </View>
    </View>
  );
}

function WishPopup({
  target,
  highlightedItemId,
  selectedIds,
  onToggleCandidate,
  onClose,
}: {
  target: PopupTarget;
  highlightedItemId: string;
  selectedIds: string[];
  onToggleCandidate: (candidateId: string) => void;
  onClose: () => void;
}) {
  const insets = useSafeAreaInsets();
  const candidateOwner =
    target.viewpoint === "mine" ? `@${PARTNER_HANDLE}` : "あなた";
  const candidateColor =
    target.viewpoint === "mine" ? megrumColors.pink : megrumColors.lavender;

  return (
    <Modal visible transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.popupBackdrop} onPress={onClose}>
        <Pressable
          style={[
            styles.popupPanel,
            { paddingBottom: Math.max(insets.bottom, 12) + 10 },
          ]}
        >
          <View style={styles.popupHeader}>
            <Text style={styles.popupTargetIcon}>🎯</Text>
            <View style={styles.popupHeaderCopy}>
              <Text numberOfLines={1} style={styles.popupTitle}>
                {target.wishItem.label}
              </Text>
              <Text style={styles.popupSub}>
                wish ×{target.wishQty}・{target.candidates.length} 件の候補
              </Text>
            </View>
            <Pressable onPress={onClose} style={styles.popupClose}>
              <Text style={styles.popupCloseText}>×</Text>
            </Pressable>
          </View>

          <View style={styles.popupBody}>
            <View style={styles.popupWishSide}>
              <ItemPhoto item={target.wishItem} qty={target.wishQty} size={104} variant="wish" />
              <View style={[styles.exchangeChip, exchangeChipStyle(target.exchangeType)]}>
                <Text style={styles.exchangeChipText}>
                  {exchangeLabel(target.exchangeType)}
                </Text>
              </View>
              <Text numberOfLines={1} style={styles.popupFallback}>
                ↑ あなたの譲：{target.fallbackHave.label}
              </Text>
            </View>

            <View style={styles.popupCandidates}>
              <View style={styles.popupOwnerLine}>
                <MiniAvatar name={candidateOwner} color={candidateColor} />
                <Text style={[styles.popupOwnerText, { color: candidateColor }]}>
                  {candidateOwner} が譲るもの
                </Text>
                <Text style={styles.popupTapHint}>（タップで選択）</Text>
              </View>
              <View style={styles.candidateGrid}>
                {target.candidates.map((candidate) => {
                  const selected = selectedIds.includes(candidate.item.id);
                  const highlighted = candidate.item.id === highlightedItemId;
                  return (
                    <Pressable
                      key={candidate.item.id}
                      onPress={() => onToggleCandidate(candidate.item.id)}
                      style={[
                        styles.candidateButton,
                        selected ? styles.candidateButtonSelected : null,
                        highlighted ? styles.candidateButtonHighlighted : null,
                      ]}
                    >
                      <ItemPhoto
                        item={candidate.item}
                        qty={candidate.qty}
                        size={56}
                        variant="candidate"
                        highlighted={highlighted}
                      />
                      <Text numberOfLines={1} style={styles.candidateLabel}>
                        {candidate.item.label}
                      </Text>
                      {highlighted ? (
                        <View style={styles.sourceBadge}>
                          <Text style={styles.sourceBadgeText}>選択元</Text>
                        </View>
                      ) : null}
                      {selected ? (
                        <View style={styles.candidateCheck}>
                          <Text style={styles.candidateCheckText}>✓</Text>
                        </View>
                      ) : null}
                    </Pressable>
                  );
                })}
              </View>
            </View>
          </View>

          <Pressable onPress={onClose} style={styles.popupReturnButton}>
            <Text style={styles.popupReturnButtonText}>戻る</Text>
          </Pressable>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function SectionGroup({
  title,
  subtitle,
  accentColor,
  children,
  titleOnly = false,
}: {
  title: string;
  subtitle: string;
  accentColor: string;
  children: React.ReactNode;
  titleOnly?: boolean;
}) {
  return (
    <View style={styles.section}>
      <View
        style={[
          styles.sectionHeader,
          titleOnly
            ? styles.sectionHeaderPlain
            : { backgroundColor: alpha(accentColor, 0.08) },
        ]}
      >
        <Text
          style={[
            styles.sectionTitle,
            titleOnly ? styles.sectionTitlePlain : { color: accentColor },
          ]}
        >
          {title}
        </Text>
        {!titleOnly ? <Text style={styles.sectionSubtitle}>{subtitle}</Text> : null}
      </View>
      {children}
    </View>
  );
}

function OwnerLabel({
  color,
  name,
  avatarName,
  right,
}: {
  color: string;
  name: string;
  avatarName: string;
  right?: boolean;
}) {
  return (
    <View style={[styles.ownerLabel, right ? styles.ownerLabelRight : null]}>
      <MiniAvatar name={avatarName} color={color} />
      <Text numberOfLines={1} style={[styles.ownerLabelText, { color }]}>
        {name}
      </Text>
    </View>
  );
}

function MiniAvatar({ name, color }: { name: string; color: string }) {
  return (
    <View style={[styles.miniAvatar, { backgroundColor: color }]}>
      <Text style={styles.miniAvatarText}>
        {name.replace(/^@/, "").slice(0, 1).toUpperCase()}
      </Text>
    </View>
  );
}

function ItemPhoto({
  item,
  qty,
  size,
  variant,
  dim,
  highlighted,
}: {
  item: MiniItem;
  qty: number;
  size: number;
  variant: "have" | "candidate" | "wish";
  dim?: boolean;
  highlighted?: boolean;
}) {
  return (
    <View
      style={[
        styles.itemPhoto,
        {
          width: size,
          height: size,
          borderColor: variant === "have" ? megrumColors.sky : megrumColors.pink,
          backgroundColor: item.color,
          opacity: dim ? 0.48 : 1,
        },
        highlighted ? styles.itemPhotoHighlighted : null,
      ]}
    >
      {item.photoUrl ? (
        <Image source={{ uri: item.photoUrl }} style={styles.itemPhotoImage} />
      ) : (
        <>
          <View style={styles.itemPhotoShine} />
          <Text style={[styles.itemPhotoGlyph, { fontSize: Math.max(14, size * 0.34) }]}>
            {item.glyph}
          </Text>
        </>
      )}
      {qty > 1 ? (
        <View style={styles.qtyBadge}>
          <Text style={styles.qtyBadgeText}>×{qty}</Text>
        </View>
      ) : null}
    </View>
  );
}

function ThumbStrip({
  items,
  highlightedItemId,
}: {
  items: MiniItem[];
  highlightedItemId: string;
}) {
  if (items.length === 0) {
    return <Text style={styles.thumbEmpty}>未選択</Text>;
  }

  return (
    <View style={styles.thumbStrip}>
      {items.slice(0, 6).map((item) => (
        <ItemPhoto
          key={item.id}
          item={item}
          qty={1}
          size={26}
          variant="candidate"
          highlighted={item.id === highlightedItemId}
        />
      ))}
      {items.length > 6 ? (
        <Text style={styles.thumbOverflow}>+{items.length - 6}</Text>
      ) : null}
    </View>
  );
}

function UnavailableWishRow({
  wish,
  exchangeType,
  fallbackHave,
}: {
  wish: ListingWish;
  exchangeType: ExchangeType;
  fallbackHave: MiniItem;
}) {
  return (
    <View style={styles.unavailableWishRow}>
      <View style={styles.wishPhotoWrap}>
        <ItemPhoto item={wish.item} qty={1} size={38} variant="wish" dim />
        <View style={[styles.exchangeChipSmall, exchangeChipStyle(exchangeType)]}>
          <Text style={styles.exchangeChipSmallText}>{exchangeLabel(exchangeType)}</Text>
        </View>
      </View>
      <View style={styles.unavailableWishText}>
        <Text numberOfLines={1} style={styles.unavailableWishTitle}>
          {wish.item.label} ×{wish.qty}
        </Text>
        <Text numberOfLines={1} style={styles.unavailableWishMeta}>
          条件に合う候補なし / 参考: {fallbackHave.label}
        </Text>
      </View>
    </View>
  );
}

function buildDetailData(
  highlightedItem: MiniItem,
  listingKind: ListingKind,
  routeGiveIds: string[] = [],
  routeReceiveIds: string[] = [],
  catalogOverrides?: ReturnType<typeof buildProposalCatalogOverrides>,
) {
  const selected = highlightedItem;
  const routeGives = buildRouteMiniItems(routeGiveIds, "give", catalogOverrides);
  const routeReceives = buildRouteMiniItems(
    routeReceiveIds,
    "receive",
    catalogOverrides,
  );
  const myHaveItems =
    routeGives.length > 0 ? routeGives : [BASE_ITEMS.myHave, BASE_ITEMS.myHave2];
  const partnerHaveItems =
    routeReceives.length > 0 ? routeReceives : [selected, BASE_ITEMS.partnerHave];
  const myListing: ListingInfo = {
    listingId: "my-listing-1",
    haveLogic: "or",
    isMyListing: true,
    haves: [
      ...myHaveItems.map((item) => ({ item, qty: 1, matched: true })),
      ...(routeGives.length > 0
        ? []
        : [{ item: BASE_ITEMS.myHaveBad, qty: 1, matched: false }]),
    ],
    options: [
      {
        id: "my-opt-1",
        position: 1,
        logic: "and",
        exchangeType: "any",
        matched: true,
        wishes: [
          {
            item: { ...selected, id: "wish-mine-1" },
            qty: 1,
            candidates:
              routeReceives.length > 0
                ? routeReceives.map((item) => ({ item, qty: 1 }))
                : [
                    { item: selected, qty: 1 },
                    { item: BASE_ITEMS.selectedAlt, qty: 1 },
                  ],
          },
          {
            item: BASE_ITEMS.wishMine2,
            qty: 1,
            candidates: [{ item: BASE_ITEMS.partnerHave, qty: 1 }],
          },
        ],
      },
      {
        id: "my-opt-2",
        position: 2,
        logic: "or",
        exchangeType: "same_kind",
        matched: false,
        wishes: [
          {
            item: BASE_ITEMS.partnerHave2,
            qty: 1,
            candidates: [],
          },
        ],
      },
    ],
  };
  const partnerListing: ListingInfo = {
    listingId: "partner-listing-1",
    haveLogic: "and",
    isMyListing: false,
    haves: partnerHaveItems.map((item) => ({ item, qty: 1, matched: true })),
    options: [
      {
        id: "partner-opt-1",
        position: 1,
        logic: "or",
        exchangeType: "cross_kind",
        matched: true,
        wishes: [
          {
            item: BASE_ITEMS.wishPartner,
            qty: 1,
            candidates: myHaveItems.map((item) => ({ item, qty: 1 })),
          },
        ],
      },
      {
        id: "partner-opt-cash",
        position: 2,
        logic: "or",
        exchangeType: "any",
        matched: false,
        isCashOffer: true,
        cashAmount: 800,
        wishes: [],
      },
    ],
  };

  return {
    myListings:
      listingKind === "both" || listingKind === "mine" ? [myListing] : [],
    partnerListings:
      listingKind === "both" || listingKind === "partner" ? [partnerListing] : [],
    simpleReceives:
      listingKind === "simple"
        ? routeReceives.length > 0
          ? routeReceives
          : [selected, BASE_ITEMS.partnerHave]
        : [],
    simpleGives:
      listingKind === "simple" ? myHaveItems : [],
  };
}

async function fetchRealListingDetail({
  listingIds,
  userId,
  routeGiveIds,
  routeReceiveIds,
}: {
  listingIds: string[];
  userId: string;
  routeGiveIds: string[];
  routeReceiveIds: string[];
}) {
  if (!supabase || listingIds.length === 0) return null;

  const [{ data: listingRows }, { data: optionRows }] = await Promise.all([
    supabase
      .from("listings")
      .select("id, user_id, have_ids, have_qtys, have_logic")
      .in("id", listingIds),
    supabase
      .from("listing_wish_options")
      .select(
        "id, listing_id, position, wish_ids, wish_qtys, logic, exchange_type, is_cash_offer, cash_amount",
      )
      .in("listing_id", listingIds)
      .order("position", { ascending: true }),
  ]);

  const listings = (listingRows as ListingRow[] | null) ?? [];
  if (listings.length === 0) return null;

  const optionsByListing = groupBy(
    (optionRows as ListingOptionRow[] | null) ?? [],
    (option) => option.listing_id,
  );
  const invIds = new Set<string>();
  for (const listing of listings) {
    for (const id of listing.have_ids ?? []) invIds.add(id);
  }
  for (const option of (optionRows as ListingOptionRow[] | null) ?? []) {
    for (const id of option.wish_ids ?? []) invIds.add(id);
  }
  for (const id of routeGiveIds) invIds.add(id);
  for (const id of routeReceiveIds) invIds.add(id);

  const catalog = await fetchCatalogMiniItems(Array.from(invIds));
  const routeGiveItems = routeGiveIds.flatMap((id) => {
    const item = catalog.get(id);
    return item ? [item] : [];
  });
  const routeReceiveItems = routeReceiveIds.flatMap((id) => {
    const item = catalog.get(id);
    return item ? [item] : [];
  });

  const myListings: ListingInfo[] = [];
  const partnerListings: ListingInfo[] = [];
  for (const listing of listings) {
    const isMyListing = listing.user_id === userId;
    const routeCounterpart = isMyListing ? routeReceiveItems : routeGiveItems;
    const matchedHaveIds = new Set(isMyListing ? routeGiveIds : routeReceiveIds);
    const haves: ListingHave[] = (listing.have_ids ?? []).flatMap((id, index) => {
      const item = catalog.get(id);
      if (!item) return [];
      return [
        {
          item,
          qty: Math.max(1, listing.have_qtys?.[index] ?? 1),
          matched: matchedHaveIds.size === 0 || matchedHaveIds.has(id),
        },
      ];
    });
    const options = (optionsByListing.get(listing.id) ?? []).map(
      (option): ListingOption => {
        const wishes: ListingWish[] = (option.wish_ids ?? []).flatMap(
          (wishId, index) => {
            const wish = catalog.get(wishId);
            if (!wish) return [];
            const candidates = routeCounterpart
              .filter((candidate) => catalogItemsMatch(candidate, wish))
              .map((candidate) => ({ item: candidate, qty: 1 }));
            return [
              {
                item: wish,
                qty: Math.max(1, option.wish_qtys?.[index] ?? 1),
                candidates,
              },
            ];
          },
        );
        return {
          id: option.id,
          position: option.position,
          logic: option.logic ?? "or",
          exchangeType: option.exchange_type ?? "any",
          isCashOffer: !!option.is_cash_offer,
          cashAmount: option.cash_amount,
          matched:
            !!option.is_cash_offer ||
            wishes.some((wish) => wish.candidates.length > 0),
          wishes,
        };
      },
    );
    const detail: ListingInfo = {
      listingId: listing.id,
      haveLogic: listing.have_logic ?? "and",
      haves,
      options,
      isMyListing,
    };
    if (isMyListing) myListings.push(detail);
    else partnerListings.push(detail);
  }

  return { myListings, partnerListings, simpleReceives: [], simpleGives: [] };
}

async function fetchCatalogMiniItems(ids: string[]) {
  const catalog = new Map<string, CatalogMiniItem>();
  if (!supabase || ids.length === 0) return catalog;

  const { data } = await supabase
    .from("goods_inventory")
    .select(
      "id, title, photo_urls, hue, group_id, character_id, goods_type_id, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
    )
    .in("id", ids);
  const rows = (data as RealInventoryRow[] | null) ?? [];
  const overrides = buildProposalCatalogOverrides(rows);
  for (const row of rows) {
    const item = overrides.get(row.id);
    if (!item) continue;
    catalog.set(row.id, {
      id: row.id,
      label: item.title,
      glyph: item.glyph,
      color: item.hue,
      photoUrl: item.photoUrl,
      groupId: row.group_id,
      characterId: row.character_id,
      goodsTypeId: row.goods_type_id,
    });
  }
  return catalog;
}

function catalogItemsMatch(a: CatalogMiniItem, b: CatalogMiniItem) {
  if (a.goodsTypeId !== b.goodsTypeId) return false;
  if (a.characterId && b.characterId) return a.characterId === b.characterId;
  if (!a.groupId || !b.groupId) return false;
  return a.groupId === b.groupId;
}

function buildRouteMiniItems(
  ids: string[],
  side: "give" | "receive",
  catalogOverrides?: ReturnType<typeof buildProposalCatalogOverrides>,
): MiniItem[] {
  if (ids.length === 0) return [];
  return buildProposalThumbs(ids, side, catalogOverrides).map(thumbToMiniItem);
}

function thumbToMiniItem(item: ProposalThumbItem): MiniItem {
  return {
    id: item.id,
    label: item.label,
    glyph: item.glyph,
    color: item.color,
    photoUrl: item.photoUrl,
  };
}

function initialSelection(listings: ListingInfo[], highlightedItemId: string): Selection {
  const selection: Selection = {};
  for (const listing of listings) {
    const highlightedHave = listing.haves.some((have) => have.item.id === highlightedItemId);
    for (const option of listing.options) {
      if (highlightedHave && !selection[listing.listingId]?.length) {
        const defaultCandidateIds = defaultCandidateIdsForOption(option);
        if (defaultCandidateIds.length > 0) {
          selection[listing.listingId] = defaultCandidateIds;
          continue;
        }
      }
      for (const wish of option.wishes) {
        if (wish.candidates.some((candidate) => candidate.item.id === highlightedItemId)) {
          selection[listing.listingId] = [
            ...(selection[listing.listingId] ?? []),
            highlightedItemId,
          ];
        }
      }
    }
  }
  return selection;
}

function defaultCandidateIdsForOption(option: ListingOption) {
  const visibleWishes = option.wishes.filter((wish) => wish.candidates.length > 0);
  if (visibleWishes.length === 0) return [];
  if (option.logic === "and") {
    const ids: string[] = [];
    for (const wish of visibleWishes) {
      const id = wish.candidates[0]?.item.id;
      if (id && !ids.includes(id)) ids.push(id);
    }
    return ids;
  }
  const firstCandidate = visibleWishes[0]?.candidates[0]?.item.id;
  return firstCandidate ? [firstCandidate] : [];
}

function initialHaveSelection(listings: ListingInfo[], highlightedItemId: string): HaveSelection {
  const selection: HaveSelection = {};
  for (const listing of listings) {
    if (listing.haveLogic !== "or" || listing.haves.length < 2) continue;
    const highlighted = listing.haves.find((have) => have.item.id === highlightedItemId);
    const first = highlighted ?? listing.haves.find((have) => have.matched) ?? listing.haves[0];
    if (first) selection[listing.listingId] = [first.item.id];
  }
  return selection;
}

function firstVisualCandidatePopupTarget({
  myListings,
  partnerListings,
  highlightedItemId,
}: {
  myListings: ListingInfo[];
  partnerListings: ListingInfo[];
  highlightedItemId: string;
}): PopupTarget | null {
  const groups: { listings: ListingInfo[]; viewpoint: "mine" | "partner" }[] = [
    { listings: myListings, viewpoint: "mine" },
    { listings: partnerListings, viewpoint: "partner" },
  ];

  for (const group of groups) {
    for (const listing of group.listings) {
      const fallbackHave =
        listing.haves.find((have) => have.item.id === highlightedItemId) ??
        listing.haves.find((have) => have.matched) ??
        listing.haves[0];
      if (!fallbackHave) continue;

      const options = listing.options
        .filter((option) => !option.isCashOffer)
        .sort((a, b) => {
          if (a.matched !== b.matched) return Number(b.matched) - Number(a.matched);
          return a.position - b.position;
        });

      for (const option of options) {
        const wish = option.wishes.find((candidateWish) => candidateWish.candidates.length > 0);
        if (!wish) continue;
        return {
          listingId: listing.listingId,
          viewpoint: group.viewpoint,
          wishItem: wish.item,
          wishQty: wish.qty,
          candidates: wish.candidates,
          exchangeType: option.exchangeType,
          fallbackHave: fallbackHave.item,
        };
      }
    }
  }

  return null;
}

function aggregateSelection({
  myListings,
  partnerListings,
  selection,
  haveSelection,
}: {
  myListings: ListingInfo[];
  partnerListings: ListingInfo[];
  selection: Selection;
  haveSelection: HaveSelection;
}) {
  const listings = [...myListings, ...partnerListings];
  const byId = new Map(listings.map((listing) => [listing.listingId, listing] as const));
  const candidateById = new Map<string, MiniItem>();
  for (const listing of listings) {
    for (const option of listing.options) {
      for (const wish of option.wishes) {
        for (const candidate of wish.candidates) {
          candidateById.set(candidate.item.id, candidate.item);
        }
      }
    }
  }
  const givesItems: MiniItem[] = [];
  const receivesItems: MiniItem[] = [];
  const giveIds = new Set<string>();
  const receiveIds = new Set<string>();
  const add = (items: MiniItem[], ids: Set<string>, item: MiniItem) => {
    if (ids.has(item.id)) return;
    ids.add(item.id);
    items.push(item);
  };

  for (const [listingId, candidateIds] of Object.entries(selection)) {
    const listing = byId.get(listingId);
    if (!listing) continue;
    const haves =
      listing.haveLogic === "or" && listing.haves.length >= 2
        ? listing.haves.filter((have) =>
            (haveSelection[listingId] ?? []).includes(have.item.id),
          )
        : listing.haves;

    if (listing.isMyListing) {
      for (const have of haves) add(givesItems, giveIds, have.item);
      for (const candidateId of candidateIds) {
        const item = candidateById.get(candidateId);
        if (item) add(receivesItems, receiveIds, item);
      }
    } else {
      for (const candidateId of candidateIds) {
        const item = candidateById.get(candidateId);
        if (item) add(givesItems, giveIds, item);
      }
      for (const have of haves) add(receivesItems, receiveIds, have.item);
    }
  }

  return {
    givesItems,
    receivesItems,
    giveIds: [...giveIds],
    receiveIds: [...receiveIds],
    referencedListingIds: Object.keys(selection),
  };
}

function inferListingKind(priority: Priority, tag?: string): ListingKind {
  if (priority === "wish") return "simple";
  if (priority === "both") return "both";
  if (tag?.includes("相手")) return "partner";
  return "mine";
}

function parsePriority(value?: string): Priority {
  if (value === "both" || value === "oneSide" || value === "wish") return value;
  return "wish";
}

function one(value?: string | string[]) {
  return Array.isArray(value) ? value[0] : value;
}

function parseRouteIds(value?: string) {
  if (!value) return [];
  return value
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean);
}

function normalizeMatchType(value?: string) {
  if (
    value === "complete" ||
    value === "they_want_you" ||
    value === "you_want_them"
  ) {
    return value;
  }
  return "complete";
}

function groupBy<T>(items: T[], getKey: (item: T) => string) {
  const map = new Map<string, T[]>();
  for (const item of items) {
    const key = getKey(item);
    const current = map.get(key) ?? [];
    current.push(item);
    map.set(key, current);
  }
  return map;
}

function exchangeLabel(type: ExchangeType) {
  if (type === "same_kind") return "同種";
  if (type === "cross_kind") return "異種";
  return "同異種";
}

function exchangeChipStyle(type: ExchangeType) {
  if (type === "same_kind") return { backgroundColor: "#5fa884" };
  if (type === "cross_kind") return { backgroundColor: "#d9826b" };
  return { backgroundColor: megrumColors.lavender };
}

function alpha(hex: string, opacity: number) {
  const sanitized = hex.replace("#", "");
  const r = parseInt(sanitized.slice(0, 2), 16);
  const g = parseInt(sanitized.slice(2, 4), 16);
  const b = parseInt(sanitized.slice(4, 6), 16);
  return `rgba(${r},${g},${b},${opacity})`;
}

const styles = StyleSheet.create({
  root: {
    backgroundColor: megrumColors.background,
    flex: 1,
    overflow: "hidden",
  },
  swipeRail: {
    flex: 1,
    position: "relative",
  },
  swipePage: {
    backgroundColor: megrumColors.background,
    flex: 1,
  },
  previewPage: {
    backgroundColor: megrumColors.background,
    bottom: 0,
    position: "absolute",
    top: 0,
  },
  swapCover: {
    backgroundColor: megrumColors.background,
    bottom: 0,
    left: 0,
    position: "absolute",
    top: 0,
    zIndex: 10,
  },
  previewContent: {
    paddingBottom: 28,
  },
  header: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.96)",
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: 1,
    flexDirection: "row",
    gap: 12,
    paddingBottom: 12,
    paddingHorizontal: 18,
  },
  closeButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  closeText: {
    color: "rgba(58,50,74,0.55)",
    fontSize: 21,
    fontWeight: "900",
    lineHeight: 24,
  },
  headerCopy: {
    flex: 1,
  },
  headerTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  profileButton: {
    backgroundColor: "rgba(166,149,216,0.14)",
    borderColor: "rgba(166,149,216,0.24)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 11,
    paddingVertical: 8,
  },
  profileButtonText: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  content: {
    paddingHorizontal: 18,
    paddingTop: 16,
  },
  detailLoadingPanel: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 18,
    borderWidth: 1,
    justifyContent: "center",
    minHeight: 280,
    paddingHorizontal: 24,
    paddingVertical: 36,
  },
  detailLoadingTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
    marginTop: 14,
  },
  detailLoadingText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    marginTop: 6,
  },
  section: {
    marginBottom: 16,
  },
  sectionHeader: {
    borderRadius: 10,
    marginBottom: 8,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  sectionHeaderPlain: {
    backgroundColor: "transparent",
    paddingHorizontal: 0,
    paddingVertical: 2,
  },
  sectionTitle: {
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.4,
  },
  sectionTitlePlain: {
    color: megrumColors.ink,
    fontSize: 15,
    letterSpacing: 0,
  },
  sectionSubtitle: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    marginTop: 2,
  },
  listingTree: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    marginBottom: 12,
    overflow: "hidden",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 8,
  },
  listingHeader: {
    alignItems: "center",
    backgroundColor: megrumColors.background,
    borderBottomColor: "rgba(58,50,74,0.04)",
    borderBottomWidth: 1,
    flexDirection: "row",
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  listingHeaderText: {
    alignItems: "baseline",
    flex: 1,
    flexDirection: "row",
  },
  listingTitle: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.3,
  },
  listingOptionCount: {
    color: megrumColors.mutedInk,
    fontSize: 10,
  },
  cashPill: {
    backgroundColor: "rgba(122,154,138,0.08)",
    borderColor: "rgba(122,154,138,0.34)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  cashPillText: {
    color: "#7a9a8a",
    fontSize: 9.5,
    fontWeight: "800",
  },
  treeBody: {
    flexDirection: "row",
  },
  treeSideLeft: {
    borderRightColor: "rgba(58,50,74,0.04)",
    borderRightWidth: 1,
    flex: 1,
    paddingHorizontal: 10,
    paddingVertical: 10,
  },
  treeSideRight: {
    flex: 1,
    paddingHorizontal: 10,
    paddingVertical: 10,
  },
  ownerLabel: {
    alignItems: "center",
    flexDirection: "row",
    gap: 4,
    marginBottom: 7,
  },
  ownerLabelRight: {
    justifyContent: "flex-end",
  },
  ownerLabelText: {
    flexShrink: 1,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 0.3,
  },
  miniAvatar: {
    alignItems: "center",
    borderRadius: 999,
    height: 20,
    justifyContent: "center",
    width: 20,
  },
  miniAvatarText: {
    color: megrumColors.surface,
    fontSize: 10,
    fontWeight: "900",
  },
  optionList: {
    gap: 8,
  },
  optionGroup: {
    gap: 6,
  },
  optionGroupAnd: {
    backgroundColor: "rgba(166,149,216,0.03)",
    borderColor: megrumColors.lavender,
    borderRadius: 12,
    borderWidth: 2,
    padding: 6,
  },
  optionGroupOr: {
    backgroundColor: "rgba(166,149,216,0.02)",
    borderColor: "rgba(166,149,216,0.34)",
    borderRadius: 12,
    borderStyle: "dashed",
    borderWidth: 1,
    padding: 6,
  },
  optionGroupHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 5,
  },
  optionGroupBadge: {
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  optionGroupBadgeAnd: {
    backgroundColor: megrumColors.lavender,
  },
  optionGroupBadgeOr: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.34)",
    borderWidth: 1,
  },
  optionGroupBadgeText: {
    fontSize: 9,
    fontWeight: "900",
  },
  optionGroupBadgeTextAnd: {
    color: megrumColors.surface,
  },
  optionGroupBadgeTextOr: {
    color: megrumColors.lavender,
  },
  optionGroupSub: {
    color: megrumColors.mutedInk,
    flex: 1,
    fontSize: 9,
    fontWeight: "700",
  },
  optionWishes: {
    gap: 6,
  },
  wishRow: {
    backgroundColor: megrumColors.background,
    borderColor: "rgba(58,50,74,0.04)",
    borderRadius: 10,
    borderWidth: 1,
    overflow: "hidden",
  },
  wishButton: {
    alignItems: "center",
    flexDirection: "row",
    gap: 9,
    paddingHorizontal: 9,
    paddingVertical: 8,
  },
  wishPhotoWrap: {
    position: "relative",
  },
  wishText: {
    flex: 1,
    minWidth: 0,
  },
  wishTitleLine: {
    alignItems: "center",
    flexDirection: "row",
    gap: 3,
  },
  wishTargetIcon: {
    fontSize: 10,
  },
  wishTitle: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 11.5,
    fontWeight: "900",
  },
  wishQty: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
  },
  wishMeta: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    marginTop: 2,
  },
  chevron: {
    color: megrumColors.lavender,
    fontSize: 19,
    fontWeight: "900",
  },
  selectedCandidates: {
    borderTopColor: "rgba(58,50,74,0.04)",
    borderTopWidth: 1,
    paddingHorizontal: 9,
    paddingVertical: 7,
  },
  selectedCandidatesLabel: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "800",
    marginBottom: 5,
  },
  selectedCandidateStrip: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 6,
  },
  haveList: {
    alignItems: "center",
    gap: 8,
  },
  haveSelectable: {
    borderRadius: 10,
    padding: 2,
    position: "relative",
  },
  haveSelectableOn: {
    backgroundColor: "rgba(166,149,216,0.06)",
    borderColor: megrumColors.lavender,
    borderWidth: 2,
  },
  haveSelectableOff: {
    opacity: 0.5,
  },
  selectedBadge: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    height: 16,
    justifyContent: "center",
    position: "absolute",
    right: -3,
    top: -3,
    width: 16,
  },
  selectedBadgeText: {
    color: megrumColors.surface,
    fontSize: 10,
    fontWeight: "900",
  },
  hiddenButton: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  hiddenButtonText: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
  },
  hiddenButtonMuted: {
    color: "rgba(58,50,74,0.40)",
    fontSize: 10,
    fontWeight: "800",
  },
  logicPill: {
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 7,
    paddingVertical: 4,
  },
  logicPillAnd: {
    backgroundColor: megrumColors.lavender,
  },
  logicPillOr: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.34)",
    borderWidth: 1,
  },
  logicPillText: {
    fontSize: 9.5,
    fontWeight: "900",
  },
  logicPillTextAnd: {
    color: megrumColors.surface,
  },
  logicPillTextOr: {
    color: megrumColors.lavender,
  },
  unavailableArchive: {
    paddingTop: 2,
  },
  unavailableArchiveButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: 10,
    borderStyle: "dashed",
    borderWidth: 1,
    paddingHorizontal: 10,
    paddingVertical: 8,
  },
  unavailableArchiveText: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
  },
  unavailableArchiveBody: {
    backgroundColor: "rgba(58,50,74,0.02)",
    borderColor: "rgba(58,50,74,0.06)",
    borderRadius: 12,
    borderWidth: 1,
    gap: 8,
    marginTop: 8,
    padding: 8,
  },
  unavailableGroup: {
    gap: 5,
  },
  unavailableGroupTitle: {
    color: "rgba(58,50,74,0.42)",
    fontSize: 9,
    fontWeight: "800",
  },
  unavailableWishRow: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.70)",
    borderColor: "rgba(58,50,74,0.04)",
    borderRadius: 10,
    borderWidth: 1,
    flexDirection: "row",
    gap: 8,
    opacity: 0.62,
    paddingHorizontal: 8,
    paddingVertical: 7,
  },
  unavailableWishText: {
    flex: 1,
  },
  unavailableWishTitle: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
  },
  unavailableWishMeta: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    marginTop: 2,
  },
  exchangeChipSmall: {
    borderRadius: megrumRadii.pill,
    bottom: -4,
    paddingHorizontal: 4,
    paddingVertical: 1,
    position: "absolute",
    right: -4,
  },
  exchangeChipSmallText: {
    color: megrumColors.surface,
    fontSize: 8,
    fontWeight: "900",
  },
  simplePanel: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 16,
    borderWidth: 1,
    overflow: "hidden",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 8,
  },
  simpleHeader: {
    backgroundColor: megrumColors.background,
    borderBottomColor: "rgba(58,50,74,0.04)",
    borderBottomWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  simpleHeaderTitle: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.3,
  },
  simpleHeaderSub: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    marginTop: 2,
  },
  simpleBody: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
    padding: 12,
  },
  simpleSide: {
    borderRadius: 12,
    flex: 1,
    minHeight: 96,
    paddingHorizontal: 10,
    paddingVertical: 9,
  },
  simpleReceive: {
    backgroundColor: "rgba(243,197,212,0.08)",
  },
  simpleGive: {
    backgroundColor: "rgba(166,149,216,0.08)",
  },
  simpleReceiveTitle: {
    color: "#b66f87",
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 0.4,
  },
  simpleGiveTitle: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 0.4,
  },
  simpleMeta: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "700",
    marginBottom: 7,
    marginTop: 3,
  },
  simpleSwap: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.04)",
    borderRadius: 999,
    height: 32,
    justifyContent: "center",
    width: 32,
  },
  simpleSwapText: {
    color: megrumColors.mutedInk,
    fontSize: 14,
    fontWeight: "900",
  },
  emptyRelation: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 10,
    borderStyle: "dashed",
    borderWidth: 1,
    padding: 16,
  },
  emptyRelationText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    textAlign: "center",
  },
  summary: {
    backgroundColor: "rgba(166,149,216,0.04)",
    borderColor: "rgba(166,149,216,0.34)",
    borderRadius: 12,
    borderWidth: 1,
    marginTop: 2,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  summaryTitle: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 0.4,
    marginBottom: 7,
  },
  summaryLine: {
    alignItems: "center",
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  summarySide: {
    alignItems: "center",
    flexDirection: "row",
    gap: 5,
  },
  summaryBadge: {
    borderRadius: megrumRadii.pill,
    color: megrumColors.surface,
    fontSize: 8.5,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  summaryReceiveBadge: {
    backgroundColor: megrumColors.pink,
  },
  summaryGiveBadge: {
    backgroundColor: megrumColors.lavender,
  },
  summarySwap: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
  },
  thumbStrip: {
    flexDirection: "row",
    gap: 2,
  },
  thumbEmpty: {
    color: "rgba(58,50,74,0.30)",
    fontSize: 10,
    fontStyle: "italic",
  },
  thumbOverflow: {
    alignSelf: "center",
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "800",
  },
  itemPhoto: {
    alignItems: "center",
    borderRadius: 7,
    borderWidth: 1,
    justifyContent: "center",
    overflow: "hidden",
    position: "relative",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.12,
    shadowRadius: 3,
  },
  itemPhotoHighlighted: {
    borderColor: megrumColors.pink,
    borderWidth: 2,
    shadowColor: megrumColors.pink,
    shadowOpacity: 0.5,
    shadowRadius: 10,
  },
  itemPhotoImage: {
    height: "100%",
    width: "100%",
  },
  itemPhotoShine: {
    backgroundColor: "rgba(255,255,255,0.24)",
    borderRadius: 999,
    height: 40,
    position: "absolute",
    right: -10,
    top: -8,
    width: 40,
  },
  itemPhotoGlyph: {
    color: "rgba(255,255,255,0.96)",
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.28)",
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  qtyBadge: {
    backgroundColor: "rgba(0,0,0,0.70)",
    borderBottomLeftRadius: 4,
    position: "absolute",
    right: 0,
    top: 0,
    paddingHorizontal: 3,
  },
  qtyBadgeText: {
    color: megrumColors.surface,
    fontSize: 9,
    fontWeight: "900",
  },
  popupBackdrop: {
    backgroundColor: "rgba(0,0,0,0.55)",
    flex: 1,
    justifyContent: "flex-end",
  },
  popupPanel: {
    backgroundColor: megrumColors.surface,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    overflow: "hidden",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: -10 },
    shadowOpacity: 0.25,
    shadowRadius: 40,
  },
  popupHeader: {
    alignItems: "center",
    backgroundColor: megrumColors.background,
    borderBottomColor: "rgba(58,50,74,0.04)",
    borderBottomWidth: 1,
    flexDirection: "row",
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  popupTargetIcon: {
    fontSize: 12,
  },
  popupHeaderCopy: {
    flex: 1,
  },
  popupTitle: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "900",
  },
  popupSub: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    marginTop: 2,
  },
  popupClose: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.04)",
    borderRadius: 999,
    height: 28,
    justifyContent: "center",
    width: 28,
  },
  popupCloseText: {
    color: megrumColors.mutedInk,
    fontSize: 17,
    fontWeight: "900",
    lineHeight: 20,
  },
  popupBody: {
    flexDirection: "row",
    gap: 12,
    padding: 12,
  },
  popupWishSide: {
    alignItems: "center",
    width: 110,
  },
  exchangeChip: {
    borderRadius: megrumRadii.pill,
    marginTop: 7,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  exchangeChipText: {
    color: megrumColors.surface,
    fontSize: 9.5,
    fontWeight: "900",
  },
  popupFallback: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    marginTop: 5,
    maxWidth: 110,
    textAlign: "center",
  },
  popupCandidates: {
    flex: 1,
    minWidth: 0,
  },
  popupOwnerLine: {
    alignItems: "center",
    flexDirection: "row",
    gap: 5,
    marginBottom: 8,
  },
  popupOwnerText: {
    fontSize: 10,
    fontWeight: "900",
  },
  popupTapHint: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
  },
  candidateGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 6,
  },
  candidateButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderRadius: 10,
    minHeight: 82,
    padding: 4,
    position: "relative",
    width: "31%",
  },
  candidateButtonSelected: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderColor: megrumColors.lavender,
    borderWidth: 2,
  },
  candidateButtonHighlighted: {
    backgroundColor: "#fff7fb",
    borderColor: megrumColors.pink,
    borderWidth: 2,
  },
  candidateLabel: {
    color: megrumColors.ink,
    fontSize: 9,
    fontWeight: "800",
    marginTop: 3,
    maxWidth: 64,
  },
  sourceBadge: {
    backgroundColor: megrumColors.pink,
    borderRadius: megrumRadii.pill,
    left: -4,
    paddingHorizontal: 5,
    paddingVertical: 1,
    position: "absolute",
    top: -4,
  },
  sourceBadgeText: {
    color: megrumColors.surface,
    fontSize: 8.5,
    fontWeight: "900",
  },
  candidateCheck: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    height: 16,
    justifyContent: "center",
    position: "absolute",
    right: -3,
    top: -3,
    width: 16,
  },
  candidateCheckText: {
    color: megrumColors.surface,
    fontSize: 10,
    fontWeight: "900",
  },
  popupReturnButton: {
    backgroundColor: megrumColors.lavender,
    borderRadius: 10,
    marginHorizontal: 12,
    marginTop: 2,
    paddingVertical: 11,
  },
  popupReturnButtonText: {
    color: megrumColors.surface,
    fontSize: 12.5,
    fontWeight: "900",
    textAlign: "center",
  },
  footer: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.96)",
    borderTopColor: "rgba(58,50,74,0.08)",
    borderTopWidth: 1,
    flexDirection: "row",
    gap: 10,
    paddingHorizontal: 18,
    paddingTop: 12,
  },
  resetButton: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 10,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  resetButtonText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  primaryFooterButton: {
    backgroundColor: megrumColors.lavender,
    borderRadius: 12,
    flex: 1,
    paddingVertical: 12,
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.33,
    shadowRadius: 14,
  },
  primaryFooterButtonText: {
    color: megrumColors.surface,
    fontSize: 13.5,
    fontWeight: "900",
    letterSpacing: 0.3,
    textAlign: "center",
  },
});
