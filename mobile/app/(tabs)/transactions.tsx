import { useEffect, useMemo, useRef, useState } from "react";
import { router, useLocalSearchParams } from "expo-router";
import SegmentedControl from "@react-native-segmented-control/segmented-control";
import {
  Animated,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Screen } from "../../src/components/Screen";
import { TransactionListSkeleton } from "../../src/components/SkeletonScreen";
import { useAuth } from "../../src/auth/AuthProvider";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

type TopTab = "pending" | "ongoing";
type PastFilter = "all" | "completed" | "cancelled" | "ended";

type TradeItem = {
  id: string;
  glyph: string;
  hue: string;
  label: string;
  cash?: boolean;
  photoUrl?: string | null;
};

type TransactionStatus =
  | "sent"
  | "negotiating"
  | "agreement_one_side"
  | "agreed"
  | "completed"
  | "cancelled"
  | "rejected"
  | "expired";

type Transaction = {
  id: string;
  partner: string;
  partnerAvatarUrl?: string | null;
  direction: "sent" | "received";
  status: TransactionStatus;
  needsAction: boolean;
  openDispute?: { id: string; ticketNo: string } | null;
  latestMessageFrom?: "me" | "partner" | null;
  receive: TradeItem[];
  give: TradeItem[];
  place: string;
  time: string;
  updated: string;
  note: string;
  stars?: number;
};

const TRANSACTIONS: Transaction[] = [
  {
    id: "tx-01",
    partner: "michilion",
    direction: "received",
    status: "negotiating",
    needsAction: true,
    receive: [
      { id: "r1", glyph: "S", hue: "#cbbcf4", label: "スア" },
      { id: "r2", glyph: "N", hue: "#a8d4e6", label: "ニンニン" },
    ],
    give: [{ id: "g1", glyph: "K", hue: "#f3c5d4", label: "カリナ" }],
    place: "横浜アリーナ 東口",
    time: "今日 17:30 - 18:00",
    updated: "3分前",
    note: "相手から返信が届いています",
  },
  {
    id: "tx-02",
    partner: "jhopesoda",
    direction: "sent",
    status: "agreement_one_side",
    needsAction: true,
    receive: [{ id: "r3", glyph: "V", hue: "#b7dceb", label: "V" }],
    give: [{ id: "g2", glyph: "J", hue: "#d5cff4", label: "ジョンウ" }],
    place: "守口市駅 改札前",
    time: "明日 16:00 - 17:00",
    updated: "12分前",
    note: "あなたの合意待ちです",
  },
  {
    id: "tx-03",
    partner: "megrum_lily",
    direction: "sent",
    status: "sent",
    needsAction: false,
    receive: [{ id: "r4", glyph: "W", hue: "#c8e8f2", label: "ウィンター" }],
    give: [{ id: "g3", glyph: "R", hue: "#f7d5df", label: "リノ" }],
    place: "全国候補",
    time: "候補確認中",
    updated: "1時間前",
    note: "相手の返信待ちです",
  },
  {
    id: "tx-04",
    partner: "karin_trade",
    direction: "received",
    status: "sent",
    needsAction: true,
    receive: [{ id: "r5", glyph: "K", hue: "#f3c5d4", label: "カリナ" }],
    give: [{ id: "g4", glyph: "S", hue: "#cbbcf4", label: "スア" }],
    place: "大阪城ホール 周辺",
    time: "5/18 19:00 - 19:30",
    updated: "2時間前",
    note: "新しい打診が届いています",
  },
  {
    id: "tx-05",
    partner: "winter_00",
    direction: "sent",
    status: "agreed",
    needsAction: false,
    receive: [{ id: "r6", glyph: "W", hue: "#a8d4e6", label: "ウィンター" }],
    give: [{ id: "g5", glyph: "N", hue: "#f3c5d4", label: "ニンニン" }],
    place: "横浜アリーナ 北口",
    time: "今日 18:15 - 18:45",
    updated: "5分前",
    note: "取引予定です。到着後にチャットで合流できます",
  },
  {
    id: "tx-06",
    partner: "suga_goods",
    direction: "received",
    status: "agreed",
    needsAction: true,
    receive: [{ id: "r7", glyph: "M", hue: "#d5cff4", label: "ミンギュ" }],
    give: [{ id: "g6", glyph: "J", hue: "#b7dceb", label: "ジョンウ" }],
    place: "幕張メッセ 2ホール前",
    time: "明日 14:00 - 14:30",
    updated: "20分前",
    note: "相違申告中です",
  },
  {
    id: "tx-07",
    partner: "moon_shop",
    direction: "sent",
    status: "completed",
    needsAction: false,
    receive: [{ id: "r8", glyph: "S", hue: "#cbbcf4", label: "スア" }],
    give: [{ id: "g7", glyph: "V", hue: "#b7dceb", label: "V" }],
    place: "横浜アリーナ",
    time: "5/10 17:30",
    updated: "5/10",
    note: "取引完了",
    stars: 5,
  },
  {
    id: "tx-08",
    partner: "nini_archive",
    direction: "received",
    status: "cancelled",
    needsAction: false,
    receive: [{ id: "r9", glyph: "N", hue: "#a8d4e6", label: "ニンニン" }],
    give: [{ id: "g8", glyph: "K", hue: "#f3c5d4", label: "カリナ" }],
    place: "梅田駅",
    time: "5/08 16:00",
    updated: "5/08",
    note: "キャンセル済み",
  },
];

const TOP_TABS = [
  { id: "pending" as const, label: "打診中", color: megrumColors.lavender },
  { id: "ongoing" as const, label: "進行中", color: megrumColors.sky },
];

export default function TransactionsScreen() {
  const { user, previewMode } = useAuth();
  const params = useLocalSearchParams<{ archive?: string | string[] }>();
  const archiveParam = Array.isArray(params.archive) ? params.archive[0] : params.archive;
  const archiveMode = archiveParam === "completed";
  const [tab, setTab] = useState<TopTab>("pending");
  const [pastFilter, setPastFilter] = useState<PastFilter>(() =>
    archiveMode ? "completed" : "all",
  );
  const [transactions, setTransactions] = useState<Transaction[]>(() =>
    !supabase || previewMode ? TRANSACTIONS : [],
  );
  const [loading, setLoading] = useState(!!supabase && !previewMode);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [animatedTabs, setAnimatedTabs] = useState<Set<TopTab>>(
    () => new Set(),
  );
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const pagerRef = useRef<ScrollView>(null);
  const pagerPosition = useRef(new Animated.Value(0)).current;
  const pageWidth = Math.max(1, width - 36);
  const footerTabsBottomPadding = Math.max(insets.bottom, 12) + 68;

  useEffect(() => {
    if (!supabase || previewMode) {
      setTransactions(TRANSACTIONS);
      setLoading(false);
      setLoadError(null);
      return;
    }
    if (!user) {
      setTransactions([]);
      setLoading(false);
      setLoadError(null);
      return;
    }

    let active = true;
    setTransactions([]);
    setLoading(true);
    setLoadError(null);
    fetchTransactions(user.id)
      .then((rows) => {
        if (!active) return;
        setTransactions(rows.length > 0 ? rows : []);
      })
      .catch((error: unknown) => {
        if (!active) return;
        setTransactions([]);
        setLoadError(toErrorMessage(error, "読み込みに失敗しました"));
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, user]);

  const grouped = useMemo(() => {
    const pending = transactions.filter((tx) =>
      ["sent", "negotiating", "agreement_one_side"].includes(tx.status),
    );
    const ongoing = transactions.filter((tx) => tx.status === "agreed");
    const past = transactions.filter((tx) =>
      ["completed", "cancelled", "expired", "rejected"].includes(tx.status),
    );

    return { pending, ongoing, past };
  }, [transactions]);
  const counts = {
    pending: grouped.pending.length,
    ongoing: grouped.ongoing.length,
  };
  const pastCounts = useMemo(
    () => ({
      all: grouped.past.length,
      completed: grouped.past.filter((tx) => tx.status === "completed").length,
      cancelled: grouped.past.filter((tx) => tx.status === "cancelled").length,
      ended: grouped.past.filter((tx) =>
        tx.status === "expired" || tx.status === "rejected",
      ).length,
    }),
    [grouped.past],
  );
  const filteredPast =
    pastFilter === "all"
      ? grouped.past
      : pastFilter === "ended"
        ? grouped.past.filter((tx) =>
            tx.status === "expired" || tx.status === "rejected",
          )
        : grouped.past.filter((tx) => tx.status === pastFilter);
  const listForTab = (target: TopTab) => {
    if (target === "pending") return grouped.pending;
    return grouped.ongoing;
  };
  const list = listForTab(tab);
  const topTabs = TOP_TABS.map((item) => ({
    ...item,
    count: counts[item.id],
  }));
  const activeTabIndex = Math.max(
    0,
    TOP_TABS.findIndex((item) => item.id === tab),
  );

  useEffect(() => {
    if (list.length === 0 && !animatedTabs.has(tab)) {
      markTabAnimated(tab);
    }
  }, [animatedTabs, list.length, tab]);

  useEffect(() => {
    pagerRef.current?.scrollTo({
      x: activeTabIndex * pageWidth,
      animated: false,
    });
    pagerPosition.setValue(activeTabIndex);
  }, [pageWidth]);

  if (archiveMode) {
    return (
      <Screen bottomInset={false} scroll={false} contentStyle={styles.screenContent}>
        <ScrollView
          automaticallyAdjustsScrollIndicatorInsets
          contentInsetAdjustmentBehavior="automatic"
          showsVerticalScrollIndicator={false}
          style={styles.nativeTabScroll}
          contentContainerStyle={styles.nativeTabScrollContent}
          scrollEventThrottle={16}
        >
          <View style={styles.header}>
            <Text style={styles.kicker}>ARCHIVE</Text>
            <Text style={styles.title}>完了した取引</Text>
          </View>

          {loadError ? <Text style={styles.inlineError}>{loadError}</Text> : null}

          <PastFilterChips
            filter={pastFilter}
            counts={pastCounts}
            onChange={setPastFilter}
          />

          <View style={styles.listContent}>
            {loading ? (
              <TransactionListSkeleton count={4} />
            ) : filteredPast.length === 0 ? (
              <View style={styles.emptyBox}>
                <Text style={styles.emptyText}>完了した取引はまだありません</Text>
              </View>
            ) : (
              filteredPast.map((tx, index) => (
                <AnimatedTransactionCard
                  key={tx.id}
                  tx={tx}
                  index={index}
                  animate={false}
                  onPress={() => openTransactionDetail(tx)}
                />
              ))
            )}
          </View>
        </ScrollView>
      </Screen>
    );
  }

  return (
    <Screen bottomInset={false} scroll={false} contentStyle={styles.screenContent}>
      <ScrollView
        ref={pagerRef}
        bounces={false}
        directionalLockEnabled
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        style={styles.primaryPager}
        scrollEventThrottle={16}
        onMomentumScrollEnd={handlePagerSettled}
        onScroll={handlePagerScroll}
      >
        {TOP_TABS.map((item) => (
          <View key={item.id} style={[styles.primaryPage, { width: pageWidth }]}>
            <ScrollView
              automaticallyAdjustsScrollIndicatorInsets
              contentInsetAdjustmentBehavior="automatic"
              showsVerticalScrollIndicator={false}
              style={styles.nativeTabScroll}
              contentContainerStyle={styles.nativeTabScrollContent}
              scrollEventThrottle={16}
            >
              {loadError ? <Text style={styles.inlineError}>{loadError}</Text> : null}
              <View style={styles.listContent}>
                {loading ? <TransactionListSkeleton /> : renderListPage(item.id)}
              </View>
            </ScrollView>
          </View>
        ))}
      </ScrollView>
      <View style={[styles.footerTabsWrap, { paddingBottom: footerTabsBottomPadding }]}>
        <SegmentedControl
          values={topTabs.map((item) => `${item.label} ${item.count}`)}
          selectedIndex={Math.max(0, TOP_TABS.findIndex((item) => item.id === tab))}
          tintColor={megrumColors.lavender}
          onChange={(event) => {
            const next = TOP_TABS[event.nativeEvent.selectedSegmentIndex]?.id;
            if (next) selectTab(next);
          }}
          style={styles.footerSegmented}
        />
      </View>
    </Screen>
  );

  function renderListPage(pageTab: TopTab) {
    const pageList = listForTab(pageTab);
    const pageShouldAnimate = pageTab === tab && !animatedTabs.has(pageTab);
    if (pageList.length === 0) {
      return (
        <View style={styles.emptyBox}>
          <Text style={styles.emptyText}>{emptyLabel(pageTab)}</Text>
        </View>
      );
    }
    return pageList.map((tx, index) => (
      <AnimatedTransactionCard
        key={tx.id}
        tx={tx}
        index={index}
        animate={pageShouldAnimate}
        onAnimated={
          index === pageList.length - 1 ? () => markTabAnimated(pageTab) : undefined
        }
        onPress={() => openTransactionDetail(tx)}
      />
    ));
  }

  function markTabAnimated(target: TopTab) {
    setAnimatedTabs((current) => {
      if (current.has(target)) return current;
      const next = new Set(current);
      next.add(target);
      return next;
    });
  }

  function selectTab(next: TopTab) {
    setTab(next);
    const nextIndex = TOP_TABS.findIndex((item) => item.id === next);
    if (nextIndex < 0) return;
    pagerRef.current?.scrollTo({
      x: nextIndex * pageWidth,
      animated: true,
    });
  }

  function handlePagerScroll(event: NativeSyntheticEvent<NativeScrollEvent>) {
    pagerPosition.setValue(event.nativeEvent.contentOffset.x / pageWidth);
  }

  function handlePagerSettled(event: NativeSyntheticEvent<NativeScrollEvent>) {
    const nextIndex = Math.round(event.nativeEvent.contentOffset.x / pageWidth);
    const next = TOP_TABS[nextIndex]?.id;
    if (next && next !== tab) {
      setTab(next);
    }
  }
}

function openTransactionDetail(tx: Transaction) {
  if (tx.openDispute) {
    router.push({
      pathname: "/dispute-detail",
      params: { id: tx.openDispute.id },
    });
    return;
  }
  router.push({
    pathname: "/transaction-detail",
    params: {
      id: tx.id,
      partner: tx.partner,
      partnerAvatarUrl: tx.partnerAvatarUrl ?? "",
      direction: tx.direction,
      status: tx.status,
      place: tx.place,
      time: tx.time,
      note: tx.note,
      receive: JSON.stringify(tx.receive),
      give: JSON.stringify(tx.give),
    },
  });
}

type ProposalRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string;
  cash_offer: boolean | null;
  cash_amount: number | null;
  sender_have_ids: string[] | null;
  sender_have_qtys: number[] | null;
  receiver_have_ids: string[] | null;
  receiver_have_qtys: number[] | null;
  agreed_by_sender: boolean | null;
  agreed_by_receiver: boolean | null;
  meetup_start_at: string | null;
  meetup_end_at: string | null;
  meetup_place_name: string | null;
  created_at: string;
  last_action_at: string | null;
  completed_at?: string | null;
  message: string | null;
};

type UserRow = {
  id: string;
  handle: string | null;
  display_name: string | null;
  avatar_url?: string | null;
};

type InventoryRow = {
  id: string;
  title: string;
  photo_urls: string[] | null;
  hue?: number | string | null;
  group: { name: string | null } | { name: string | null }[] | null;
  character: { name: string | null } | { name: string | null }[] | null;
  goods_type: { name: string | null } | { name: string | null }[] | null;
};

type MessageSummaryRow = {
  proposal_id: string;
  sender_id: string;
  created_at: string;
};

type EvaluationRow = {
  proposal_id: string;
  stars: number | null;
};

type DisputeRow = {
  id: string;
  proposal_id: string;
  ticket_no: string | null;
  status: string | null;
};

async function fetchTransactions(userId: string): Promise<Transaction[]> {
  if (!supabase) return TRANSACTIONS;
  const proposalFields = [
    "id",
    "sender_id",
    "receiver_id",
    "status",
    "cash_offer",
    "cash_amount",
    "sender_have_ids",
    "sender_have_qtys",
    "receiver_have_ids",
    "receiver_have_qtys",
    "agreed_by_sender",
    "agreed_by_receiver",
    "meetup_start_at",
    "meetup_end_at",
    "meetup_place_name",
    "created_at",
    "last_action_at",
    "completed_at",
    "message",
  ];
  const proposals = await fetchProposalRows(userId, proposalFields);
  if (proposals.length === 0) return [];
  const proposalIds = proposals.map((row) => row.id);
  const completedIds = proposals
    .filter((row) => normalizeTransactionStatus(row.status) === "completed")
    .map((row) => row.id);

  const partnerIds = Array.from(
    new Set(
      proposals.map((row) =>
        row.sender_id === userId ? row.receiver_id : row.sender_id,
      ),
    ),
  );
  const itemIds = Array.from(
    new Set(
      proposals.flatMap((row) => [
        ...(row.sender_have_ids ?? []),
        ...(row.receiver_have_ids ?? []),
      ]),
    ),
  );

  const [
    users,
    { data: inventory },
    latestMessageFromByProposalId,
    myStarsByProposalId,
    openDisputeByProposalId,
  ] = await Promise.all([
    fetchPartnerUsers(partnerIds),
    itemIds.length > 0
      ? supabase
          .from("goods_inventory")
          .select(
            "id, title, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
          )
          .in("id", itemIds)
      : Promise.resolve({ data: [] }),
    fetchLatestMessageFromByProposalId(proposalIds, userId),
    fetchMyStarsByProposalId(completedIds, userId),
    fetchOpenDisputesByProposalId(proposalIds),
  ]);

  const usersById = new Map(
    users.map((user) => [user.id, user]),
  );
  const inventoryById = new Map(
    ((inventory as InventoryRow[] | null) ?? []).map((item) => [item.id, item]),
  );

  return proposals.map((row): Transaction => {
    const isSender = row.sender_id === userId;
    const partner = usersById.get(isSender ? row.receiver_id : row.sender_id);
    const receiverItems = row.cash_offer
      ? [toCashTradeItem(row.id, row.cash_amount)]
      : (row.receiver_have_ids ?? []).map((id) => toTradeItem(id, inventoryById.get(id)));
    const senderItems = (row.sender_have_ids ?? []).map((id) =>
      toTradeItem(id, inventoryById.get(id)),
    );
    const openDispute = openDisputeByProposalId.get(row.id) ?? null;
    const latestMessageFrom = latestMessageFromByProposalId.get(row.id) ?? null;
    return {
      id: row.id,
      partner: partner?.handle ?? partner?.display_name ?? "unknown",
      partnerAvatarUrl: partner?.avatar_url ?? null,
      direction: isSender ? "sent" : "received",
      status: normalizeTransactionStatus(row.status),
      needsAction: !!openDispute || needsActionFor(row, userId, latestMessageFrom),
      openDispute,
      latestMessageFrom,
      receive: isSender ? receiverItems : senderItems,
      give: isSender ? senderItems : receiverItems,
      place: row.meetup_place_name ?? "場所確認中",
      time: formatProposalTime(row.meetup_start_at, row.meetup_end_at),
      updated: formatRelative(row.last_action_at ?? row.created_at),
      note: noteFor(row, userId),
      stars: myStarsByProposalId.get(row.id) ?? undefined,
    };
  });
}

async function fetchPartnerUsers(partnerIds: string[]): Promise<UserRow[]> {
  if (!supabase || partnerIds.length === 0) return [];
  const selectableFields = ["id", "handle", "display_name", "avatar_url"];
  for (let attempt = 0; attempt < selectableFields.length; attempt += 1) {
    const { data, error } = await supabase
      .from("users")
      .select(selectableFields.join(", "))
      .in("id", partnerIds);
    const missingColumn = getMissingColumnName(error, "users");
    if (missingColumn && selectableFields.includes(missingColumn)) {
      selectableFields.splice(selectableFields.indexOf(missingColumn), 1);
      continue;
    }
    if (error) return [];
    return ((data as unknown as UserRow[] | null) ?? []);
  }
  return [];
}

async function fetchMyStarsByProposalId(
  proposalIds: string[],
  userId: string,
) {
  const result = new Map<string, number>();
  if (!supabase || proposalIds.length === 0) return result;
  const { data, error } = await supabase
    .from("user_evaluations")
    .select("proposal_id, stars")
    .eq("rater_id", userId)
    .in("proposal_id", proposalIds);
  if (error) return result;
  for (const row of ((data as EvaluationRow[] | null) ?? [])) {
    if (row.proposal_id && typeof row.stars === "number") {
      result.set(row.proposal_id, row.stars);
    }
  }
  return result;
}

async function fetchOpenDisputesByProposalId(proposalIds: string[]) {
  const result = new Map<string, { id: string; ticketNo: string }>();
  if (!supabase || proposalIds.length === 0) return result;
  const { data, error } = await supabase
    .from("disputes")
    .select("id, proposal_id, ticket_no, status")
    .in("proposal_id", proposalIds)
    .neq("status", "closed");
  if (error) return result;
  for (const row of ((data as DisputeRow[] | null) ?? [])) {
    if (!row.proposal_id) continue;
    result.set(row.proposal_id, {
      id: row.id,
      ticketNo: row.ticket_no ?? "申告中",
    });
  }
  return result;
}

async function fetchProposalRows(
  userId: string,
  fields: string[],
): Promise<ProposalRow[]> {
  if (!supabase) return [];
  const selectableFields = [...fields];
  for (let attempt = 0; attempt < fields.length; attempt += 1) {
    const { data, error } = await supabase
      .from("proposals")
      .select(selectableFields.join(", "))
      .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)
      .neq("status", "draft")
      .order("last_action_at", { ascending: false });
    const missingColumn = getMissingProposalColumn(error);
    if (missingColumn && selectableFields.includes(missingColumn)) {
      selectableFields.splice(selectableFields.indexOf(missingColumn), 1);
      continue;
    }
    if (error) throw error;
    return ((data as unknown as Record<string, unknown>[] | null) ?? []).map((row) => ({
      completed_at: null,
      message: null,
      ...row,
    })) as ProposalRow[];
  }
  return [];
}

async function fetchLatestMessageFromByProposalId(
  proposalIds: string[],
  userId: string,
) {
  const result = new Map<string, "me" | "partner">();
  if (!supabase || proposalIds.length === 0) return result;

  const selectableFields = ["proposal_id", "sender_id", "created_at"];
  for (let attempt = 0; attempt < selectableFields.length; attempt += 1) {
    const { data, error } = await supabase
      .from("messages")
      .select(selectableFields.join(", "))
      .in("proposal_id", proposalIds)
      .order("created_at", { ascending: false });
    const missingColumn = getMissingColumnName(error, "messages");
    if (missingColumn && selectableFields.includes(missingColumn)) {
      selectableFields.splice(selectableFields.indexOf(missingColumn), 1);
      continue;
    }
    if (error) return result;
    for (const row of ((data as unknown as MessageSummaryRow[] | null) ?? [])) {
      if (result.has(row.proposal_id)) continue;
      result.set(row.proposal_id, row.sender_id === userId ? "me" : "partner");
    }
    return result;
  }
  return result;
}

function getMissingProposalColumn(error: { code?: string; message?: string } | null) {
  const message = error?.message ?? "";
  if (
    error?.code !== "PGRST204" &&
    error?.code !== "42703" &&
    !message.includes("schema cache") &&
    !message.includes("does not exist")
  ) {
    return null;
  }
  return (
    getMissingColumnName(error, "proposals")
  );
}

function getMissingColumnName(
  error: { code?: string; message?: string } | null,
  tableName: string,
) {
  const message = error?.message ?? "";
  return (
    message.match(new RegExp(`Could not find the '([^']+)' column of '${tableName}'`))?.[1] ??
    message.match(new RegExp(`column ${tableName}\\.([a-zA-Z0-9_]+) does not exist`))?.[1] ??
    message.match(/column "([a-zA-Z0-9_]+)" does not exist/)?.[1] ??
    null
  );
}

function toErrorMessage(error: unknown, fallback: string) {
  if (error instanceof Error) return error.message;
  if (
    typeof error === "object" &&
    error &&
    "message" in error &&
    typeof error.message === "string"
  ) {
    return error.message;
  }
  return fallback;
}

function toTradeItem(id: string, row?: InventoryRow): TradeItem {
  const label =
    pickName(row?.character) ?? pickName(row?.group) ?? row?.title ?? "グッズ";
  return {
    id,
    glyph: label.slice(0, 1),
    hue: normalizeHue(row?.hue, label),
    label,
    photoUrl: row?.photo_urls?.[0] ?? null,
  };
}

function toCashTradeItem(proposalId: string, amount: number | null): TradeItem {
  const label = `¥${amount?.toLocaleString() ?? "—"}`;
  return {
    id: `cash-${proposalId}`,
    cash: true,
    glyph: "¥",
    hue: "rgba(122,154,138,0.20)",
    label,
    photoUrl: null,
  };
}

function needsActionFor(
  row: ProposalRow,
  userId: string,
  latestMessageFrom: "me" | "partner" | null,
) {
  const isSender = row.sender_id === userId;
  if (row.status === "sent") return !isSender;
  if (row.status === "negotiating") {
    if (latestMessageFrom) return latestMessageFrom === "partner";
    return !isSender;
  }
  if (row.status === "agreement_one_side") {
    return isSender ? !row.agreed_by_sender : !row.agreed_by_receiver;
  }
  return false;
}

function noteFor(row: ProposalRow, userId: string) {
  if (row.status === "sent") {
    return row.sender_id === userId
      ? "相手の返信待ちです"
      : "新しい打診が届いています";
  }
  if (row.status === "negotiating") return "条件調整中です";
  if (row.status === "agreement_one_side") return "合意待ちです";
  if (row.status === "agreed") return "取引予定です";
  if (row.status === "completed") return "取引完了";
  if (row.status === "expired") return "期限切れ";
  if (row.status === "rejected") return "見送り済み";
  return "キャンセル済み";
}

function normalizeTransactionStatus(status: string): TransactionStatus {
  if (
    status === "sent" ||
    status === "negotiating" ||
    status === "agreement_one_side" ||
    status === "agreed" ||
    status === "completed" ||
    status === "cancelled" ||
    status === "rejected" ||
    status === "expired"
  ) {
    return status;
  }
  return "cancelled";
}

function formatProposalTime(startAt: string | null, endAt: string | null) {
  if (!startAt) return "候補確認中";
  const start = new Date(startAt);
  const end = endAt ? new Date(endAt) : null;
  const date = `${start.getMonth() + 1}/${start.getDate()}`;
  const startTime = `${String(start.getHours()).padStart(2, "0")}:${String(start.getMinutes()).padStart(2, "0")}`;
  const endTime = end
    ? ` - ${String(end.getHours()).padStart(2, "0")}:${String(end.getMinutes()).padStart(2, "0")}`
    : "";
  return `${date} ${startTime}${endTime}`;
}

function formatRelative(value: string) {
  const diff = Date.now() - new Date(value).getTime();
  const minutes = Math.max(0, Math.floor(diff / 60000));
  if (minutes < 1) return "たった今";
  if (minutes < 60) return `${minutes}分前`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}時間前`;
  return `${Math.floor(hours / 24)}日前`;
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

function AnimatedTransactionCard({
  tx,
  index,
  animate,
  onAnimated,
  onPress,
}: {
  tx: Transaction;
  index: number;
  animate: boolean;
  onAnimated?: () => void;
  onPress: () => void;
}) {
  const appear = useMemo(() => new Animated.Value(0), []);

  useEffect(() => {
    if (!animate) return;
    const timer = setTimeout(() => {
      Animated.spring(appear, {
        toValue: 1,
        damping: 19,
        stiffness: 165,
        mass: 0.78,
        useNativeDriver: true,
      }).start(({ finished }) => {
        if (finished) onAnimated?.();
      });
    }, index * 72);

    return () => clearTimeout(timer);
  }, [animate, appear, index, onAnimated]);

  if (!animate) {
    return <TransactionCard tx={tx} onPress={onPress} />;
  }

  const translateY = appear.interpolate({
    inputRange: [0, 1],
    outputRange: [18, 0],
  });

  return (
    <Animated.View
      style={{
        opacity: appear,
        transform: [{ translateY }],
      }}
    >
      <TransactionCard tx={tx} onPress={onPress} />
    </Animated.View>
  );
}

function PastFilterChips({
  filter,
  counts,
  onChange,
}: {
  filter: PastFilter;
  counts: Record<PastFilter, number>;
  onChange: (filter: PastFilter) => void;
}) {
  const chips = [
    { id: "all" as const, label: "すべて", count: counts.all },
    { id: "completed" as const, label: "完了", count: counts.completed },
    { id: "cancelled" as const, label: "キャンセル", count: counts.cancelled },
    { id: "ended" as const, label: "終了", count: counts.ended },
  ];
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      style={styles.filterScroller}
      contentContainerStyle={styles.filterChips}
    >
      {chips.map((chip) => {
        const active = filter === chip.id;
        return (
          <Pressable
            key={chip.id}
            onPress={() => onChange(chip.id)}
            style={[styles.filterChip, active ? styles.filterChipActive : null]}
          >
            <Text
              numberOfLines={1}
              style={[
                styles.filterChipText,
                active ? styles.filterChipTextActive : null,
              ]}
            >
              {chip.label}
            </Text>
            <View style={[styles.filterCountBadge, active ? styles.filterCountBadgeActive : null]}>
              <Text
                style={[
                  styles.filterCountText,
                  active ? styles.filterCountTextActive : null,
                ]}
              >
                {chip.count}
              </Text>
            </View>
          </Pressable>
        );
      })}
    </ScrollView>
  );
}

function CompactTabs<T extends string>({
  value,
  tabs,
  position,
  onChange,
}: {
  value: T;
  tabs: { id: T; label: string; count: number; color: string }[];
  position?: number | Animated.Value | Animated.AnimatedInterpolation<number>;
  onChange: (next: T) => void;
}) {
  const [width, setWidth] = useState(0);
  const progress = useRef(new Animated.Value(0)).current;
  const activeIndex = Math.max(0, tabs.findIndex((tab) => tab.id === value));
  const thumbWidth = width > 0 ? (width - 6) / Math.max(1, tabs.length) : 0;
  const animatedPosition =
    typeof position === "number" || !position ? progress : position;

  useEffect(() => {
    if (typeof position === "number") {
      progress.setValue(position);
      return;
    }
    if (position) return;
    Animated.spring(progress, {
      toValue: activeIndex,
      damping: 22,
      stiffness: 190,
      mass: 0.74,
      useNativeDriver: true,
    }).start();
  }, [activeIndex, position, progress]);

  const translateX =
    tabs.length > 1
      ? animatedPosition.interpolate({
          inputRange: tabs.map((_, index) => index),
          outputRange: tabs.map((_, index) => index * thumbWidth),
          extrapolate: "clamp",
        })
      : 0;

  return (
    <View
      onLayout={(event) => setWidth(event.nativeEvent.layout.width)}
      style={styles.compactTabs}
    >
      {thumbWidth > 0 ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.compactTabThumb,
            {
              width: thumbWidth,
              transform: [{ translateX }],
            },
          ]}
        />
      ) : null}
      {tabs.map((tab) => {
        const active = tab.id === value;
        return (
          <Pressable
            key={tab.id}
            accessibilityRole="button"
            accessibilityState={{ selected: active }}
            onPress={() => onChange(tab.id)}
            style={styles.compactTab}
          >
            <Text
              numberOfLines={1}
              style={[
                styles.compactTabLabel,
                active ? styles.compactTabLabelActive : null,
              ]}
            >
              {tab.label}
            </Text>
            <Text style={[styles.compactTabCount, { color: tab.color }]}>
              {tab.count}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

function TransactionCard({
  tx,
  onPress,
}: {
  tx: Transaction;
  onPress: () => void;
}) {
  const tone = tx.needsAction ? "action" : tx.status === "agreed" ? "live" : "idle";
  const statusText = statusLabel(tx);
  const responseText = pendingResponseLabel(tx);

  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.card,
        tone === "action"
          ? styles.cardAction
          : tone === "live"
            ? styles.cardLive
            : styles.cardIdle,
      ]}
    >
      {tx.needsAction ? <View style={styles.cardAccent} /> : null}
      <View style={styles.cardHeader}>
        <View style={styles.avatar}>
          {tx.partnerAvatarUrl ? (
            <Image source={{ uri: tx.partnerAvatarUrl }} style={styles.avatarImage} />
          ) : (
            <Text style={styles.avatarText}>{tx.partner[0]?.toUpperCase()}</Text>
          )}
        </View>
        <View style={styles.partnerBlock}>
          <Text numberOfLines={1} style={styles.partner}>
            @{tx.partner}
          </Text>
          <Text numberOfLines={1} style={styles.updated}>
            {tx.updated}
          </Text>
        </View>
        <View
          style={[
            styles.directionBadge,
            tx.direction === "received"
              ? styles.directionReceived
              : styles.directionSent,
          ]}
        >
          <Text
            style={[
              styles.directionText,
              tx.direction === "received"
                ? styles.directionTextReceived
                : styles.directionTextSent,
            ]}
          >
            {tx.direction === "received" ? "届いた" : "送った"}
          </Text>
        </View>
      </View>

      <View style={styles.statusLine}>
        <View
          style={[
            styles.statusPill,
            tone === "action"
              ? styles.statusPillAction
              : tone === "live"
                ? styles.statusPillLive
                : styles.statusPillIdle,
          ]}
        >
          <Text
            style={[
              styles.statusPillText,
              tone === "action"
                ? styles.statusPillTextAction
                : tone === "live"
                  ? styles.statusPillTextLive
                  : styles.statusPillTextIdle,
            ]}
          >
            {statusText}
          </Text>
        </View>
        {responseText ? (
          <View
            style={[
              styles.responsePill,
              tx.needsAction ? styles.responsePillAction : styles.responsePillWaiting,
            ]}
          >
            <Text
              style={[
                styles.responsePillText,
                tx.needsAction
                  ? styles.responsePillTextAction
                  : styles.responsePillTextWaiting,
              ]}
            >
              {responseText}
            </Text>
          </View>
        ) : null}
        {tx.stars ? <Text style={styles.stars}>★ {tx.stars}</Text> : null}
        {tx.openDispute ? (
          <Text numberOfLines={1} style={styles.disputeText}>
            {tx.openDispute.ticketNo}
          </Text>
        ) : null}
      </View>

      <View style={styles.tradePair}>
        <TradePreview label="受け取る" items={tx.receive} />
        <View style={styles.arrows}>
          <Text style={styles.arrowText}>→</Text>
          <Text style={styles.arrowTextMuted}>←</Text>
        </View>
        <TradePreview label="私が出す" items={tx.give} right />
      </View>

      <View style={styles.meetupLine}>
        <Text numberOfLines={1} style={styles.meetupText}>
          {tx.time}
        </Text>
        <Text numberOfLines={1} style={styles.meetupPlace}>
          {tx.place}
        </Text>
      </View>
    </Pressable>
  );
}

function TradePreview({
  label,
  items,
  right,
}: {
  label: string;
  items: TradeItem[];
  right?: boolean;
}) {
  return (
    <View style={styles.tradeSide}>
      <Text style={[styles.tradeLabel, right ? styles.tradeLabelRight : null]}>
        {label}
      </Text>
      <View style={[styles.tradeItems, right ? styles.tradeItemsRight : null]}>
        {items.slice(0, 3).map((item) => (
          <View
            key={item.id}
            style={[
              styles.tradeItem,
              { backgroundColor: item.hue },
              item.cash ? styles.tradeItemCash : null,
            ]}
          >
            {item.photoUrl ? (
              <Image source={{ uri: item.photoUrl }} style={styles.tradeItemImage} />
            ) : (
              <Text style={[styles.tradeItemText, item.cash ? styles.tradeItemCashText : null]}>
                {item.glyph}
              </Text>
            )}
          </View>
        ))}
      </View>
    </View>
  );
}

function statusLabel(tx: Transaction) {
  if (tx.status === "sent") return tx.needsAction ? "新着打診" : "送信済み";
  if (tx.status === "negotiating") {
    return tx.needsAction ? "返信が届いています" : "ネゴ中";
  }
  if (tx.status === "agreement_one_side") {
    return tx.needsAction ? "合意待ち" : "相手の合意待ち";
  }
  if (tx.status === "agreed") return tx.needsAction ? "要確認" : "取引予定";
  if (tx.status === "completed") return "完了";
  if (tx.status === "cancelled") return "キャンセル";
  if (tx.status === "rejected") return "見送り";
  return "期限切れ";
}

function pendingResponseLabel(tx: Transaction) {
  if (!["sent", "negotiating", "agreement_one_side"].includes(tx.status)) {
    return null;
  }
  return tx.needsAction ? "要対応" : "相手待ち";
}

function emptyLabel(tab: TopTab) {
  if (tab === "pending") return "打診中のやりとりはありません";
  if (tab === "ongoing") return "進行中の取引はありません";
  return "取引はまだありません";
}

const styles = StyleSheet.create({
  screenContent: {
    paddingHorizontal: 18,
  },
  nativeTabScroll: {
    flex: 1,
  },
  nativeTabScrollContent: {
    gap: 12,
    paddingBottom: 24,
  },
  header: {
    gap: 2,
  },
  kicker: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.6,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 25,
    fontWeight: "900",
    letterSpacing: 0,
    lineHeight: 30,
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
  primaryPager: {
    flex: 1,
    marginTop: -2,
  },
  primaryPage: {
    flex: 1,
  },
  footerTabsWrap: {
    backgroundColor: "transparent",
    paddingBottom: 8,
    paddingTop: 8,
  },
  footerSegmented: {
    height: 36,
  },
  compactTabs: {
    backgroundColor: "rgba(255,255,255,0.58)",
    borderColor: "rgba(255,255,255,0.8)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    flexDirection: "row",
    marginBottom: 2,
    minHeight: 32,
    padding: 3,
    position: "relative",
  },
  compactTabThumb: {
    backgroundColor: "rgba(255,255,255,0.94)",
    borderColor: "rgba(255,255,255,0.94)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    bottom: 3,
    left: 3,
    position: "absolute",
    top: 3,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
  },
  compactTab: {
    alignItems: "center",
    borderRadius: megrumRadii.pill,
    flex: 1,
    flexDirection: "row",
    gap: 4,
    justifyContent: "center",
    minHeight: 28,
    paddingHorizontal: 5,
    paddingVertical: 4,
    zIndex: 1,
  },
  compactTabLabel: {
    color: "rgba(58,50,74,0.55)",
    fontSize: 10.5,
    fontWeight: "900",
    includeFontPadding: false,
    lineHeight: 13,
  },
  compactTabLabelActive: {
    color: megrumColors.ink,
  },
  compactTabCount: {
    fontSize: 9.5,
    fontWeight: "900",
    includeFontPadding: false,
    lineHeight: 12,
  },
  listContent: {
    gap: 10,
    paddingBottom: 24,
  },
  filterChips: {
    alignItems: "center",
    gap: 7,
    paddingBottom: 1,
    paddingRight: 18,
  },
  filterScroller: {
    flexGrow: 0,
    maxHeight: 52,
    minHeight: 44,
  },
  filterChip: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    flexDirection: "row",
    flexShrink: 0,
    gap: 7,
    justifyContent: "center",
    minHeight: 38,
    minWidth: 68,
    paddingHorizontal: 13,
    paddingVertical: 8,
  },
  filterChipActive: {
    backgroundColor: megrumColors.ink,
    borderColor: megrumColors.ink,
  },
  filterChipText: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
    includeFontPadding: false,
    lineHeight: 15,
  },
  filterChipTextActive: {
    color: megrumColors.surface,
  },
  filterCountBadge: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: megrumRadii.pill,
    height: 20,
    justifyContent: "center",
    minWidth: 24,
    paddingHorizontal: 7,
  },
  filterCountBadgeActive: {
    backgroundColor: "rgba(255,255,255,0.22)",
  },
  filterCountText: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
    includeFontPadding: false,
    lineHeight: 12,
  },
  filterCountTextActive: {
    color: megrumColors.surface,
  },
  emptyBox: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: megrumRadii.lg,
    borderStyle: "dashed",
    borderWidth: 1,
    justifyContent: "center",
    minHeight: 170,
    padding: 18,
  },
  emptyText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  meguriList: {
    gap: 9,
    paddingBottom: 28,
  },
  meguriLoadingBox: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: megrumRadii.lg,
    justifyContent: "center",
    minHeight: 170,
    padding: 18,
  },
  meguriLoadingText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 10,
  },
  meguriRow: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1,
    flexDirection: "row",
    gap: 11,
    minHeight: 76,
    paddingHorizontal: 12,
    paddingVertical: 10,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.06,
    shadowRadius: 14,
  },
  meguriRowUnreplied: {
    borderColor: "rgba(235,84,112,0.58)",
    borderWidth: 1.5,
    shadowColor: "#eb5470",
    shadowOpacity: 0.13,
    shadowRadius: 18,
  },
  meguriRowPressed: {
    backgroundColor: "rgba(166,149,216,0.08)",
    transform: [{ scale: 0.992 }],
  },
  meguriAvatar: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.86)",
    borderRadius: 26,
    borderWidth: 2,
    height: 52,
    justifyContent: "center",
    width: 52,
  },
  meguriAvatarText: {
    color: megrumColors.ink,
    fontSize: 20,
    fontWeight: "900",
  },
  meguriCopy: {
    flex: 1,
    gap: 3,
    minWidth: 0,
  },
  meguriNameLine: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  meguriName: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 15.5,
    fontWeight: "900",
  },
  meguriTime: {
    color: "rgba(58,50,74,0.46)",
    fontSize: 10.5,
    fontWeight: "800",
    textAlign: "right",
  },
  meguriMetaColumn: {
    alignItems: "flex-end",
    alignSelf: "stretch",
    justifyContent: "flex-start",
    minWidth: 42,
    paddingTop: 2,
    gap: 7,
  },
  meguriPreview: {
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "800",
  },
  meguriPendingWord: {
    color: "#eb5470",
    fontWeight: "900",
  },
  meguriPendingMessage: {
    color: megrumColors.ink,
    fontWeight: "900",
  },
  meguriSentPreview: {
    color: "rgba(58,50,74,0.68)",
    fontWeight: "700",
  },
  meguriUnread: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    minWidth: 25,
    paddingHorizontal: 7,
    paddingVertical: 4,
  },
  meguriUnreadText: {
    color: megrumColors.surface,
    fontSize: 11,
    fontWeight: "900",
  },
  card: {
    backgroundColor: megrumColors.surface,
    borderRadius: 17,
    borderWidth: 1,
    overflow: "hidden",
    padding: 12,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 16,
  },
  cardAction: {
    borderColor: "rgba(217,130,107,0.24)",
  },
  cardLive: {
    borderColor: "rgba(168,212,230,0.36)",
  },
  cardIdle: {
    borderColor: "rgba(58,50,74,0.08)",
  },
  cardAccent: {
    backgroundColor: megrumColors.warn,
    borderBottomRightRadius: 3,
    borderTopRightRadius: 3,
    bottom: 12,
    left: 0,
    position: "absolute",
    top: 12,
    width: 3,
  },
  cardHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  avatar: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    borderRadius: 12,
    height: 34,
    justifyContent: "center",
    overflow: "hidden",
    width: 34,
  },
  avatarImage: {
    height: "100%",
    width: "100%",
  },
  avatarText: {
    color: megrumColors.lavender,
    fontSize: 14,
    fontWeight: "900",
  },
  partnerBlock: {
    flex: 1,
  },
  partner: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  updated: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "700",
    marginTop: 1,
  },
  directionBadge: {
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  directionReceived: {
    backgroundColor: "rgba(166,149,216,0.14)",
  },
  directionSent: {
    backgroundColor: "rgba(168,212,230,0.22)",
  },
  directionText: {
    fontSize: 9.5,
    fontWeight: "900",
  },
  directionTextReceived: {
    color: megrumColors.lavender,
  },
  directionTextSent: {
    color: "#3a7c93",
  },
  statusLine: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
    marginTop: 9,
  },
  statusPill: {
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 9,
    paddingVertical: 4,
  },
  statusPillAction: {
    backgroundColor: "rgba(217,130,107,0.12)",
  },
  statusPillLive: {
    backgroundColor: "rgba(168,212,230,0.22)",
  },
  statusPillIdle: {
    backgroundColor: "rgba(58,50,74,0.06)",
  },
  statusPillText: {
    fontSize: 10.5,
    fontWeight: "900",
  },
  statusPillTextAction: {
    color: megrumColors.warn,
  },
  statusPillTextLive: {
    color: "#3a7c93",
  },
  statusPillTextIdle: {
    color: megrumColors.ink,
  },
  responsePill: {
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  responsePillAction: {
    backgroundColor: "rgba(217,130,107,0.10)",
  },
  responsePillWaiting: {
    backgroundColor: "rgba(168,212,230,0.18)",
  },
  responsePillText: {
    fontSize: 10,
    fontWeight: "900",
  },
  responsePillTextAction: {
    color: megrumColors.warn,
  },
  responsePillTextWaiting: {
    color: "#3a7c93",
  },
  stars: {
    color: "#caa04f",
    fontSize: 10.5,
    fontWeight: "900",
  },
  disputeText: {
    backgroundColor: "rgba(217,130,107,0.12)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.warn,
    fontSize: 10,
    fontWeight: "900",
    marginLeft: "auto",
    maxWidth: 92,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  tradePair: {
    alignItems: "center",
    backgroundColor: "rgba(168,212,230,0.10)",
    borderRadius: 15,
    flexDirection: "row",
    gap: 8,
    marginTop: 9,
    padding: 9,
  },
  tradeSide: {
    flex: 1,
  },
  tradeLabel: {
    color: megrumColors.mutedInk,
    fontSize: 9.5,
    fontWeight: "900",
    marginBottom: 6,
  },
  tradeLabelRight: {
    textAlign: "right",
  },
  tradeItems: {
    flexDirection: "row",
    gap: 5,
  },
  tradeItemsRight: {
    justifyContent: "flex-end",
  },
  tradeItem: {
    alignItems: "center",
    borderRadius: 8,
    height: 42,
    justifyContent: "center",
    overflow: "hidden",
    width: 32,
  },
  tradeItemCash: {
    borderColor: "rgba(122,154,138,0.42)",
    borderWidth: 1,
  },
  tradeItemImage: {
    height: "100%",
    width: "100%",
  },
  tradeItemText: {
    color: megrumColors.surface,
    fontSize: 16,
    fontWeight: "900",
  },
  tradeItemCashText: {
    color: "#5f806d",
  },
  arrows: {
    alignItems: "center",
    width: 22,
  },
  arrowText: {
    color: megrumColors.lavender,
    fontSize: 16,
    fontWeight: "900",
    lineHeight: 16,
  },
  arrowTextMuted: {
    color: megrumColors.sky,
    fontSize: 16,
    fontWeight: "900",
    lineHeight: 16,
  },
  meetupLine: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
    marginTop: 9,
  },
  meetupText: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 10.5,
    fontWeight: "900",
  },
  meetupPlace: {
    color: megrumColors.mutedInk,
    flex: 1,
    fontSize: 10.5,
    fontWeight: "700",
    textAlign: "right",
  },
});
