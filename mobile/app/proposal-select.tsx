import { router, useLocalSearchParams } from "expo-router";
import type { LocationGeocodedAddress } from "expo-location";
import SegmentedControl from "@react-native-segmented-control/segmented-control";
import { useEffect, useMemo, useRef, useState } from "react";
import {
  Animated,
  Image,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  useWindowDimensions,
  type GestureResponderEvent,
} from "react-native";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { Screen } from "../src/components/Screen";
import { ProposalChoiceSkeleton } from "../src/components/SkeletonScreen";
import { StatusPill } from "../src/components/StatusPill";
import { SectionTabs } from "../src/components/GoodsGrid";
import { useAuth } from "../src/auth/AuthProvider";
import {
  NativeMapPreview,
  type MapCoordinate,
} from "../src/components/NativeMapPreview";
import {
  buildProposalCatalogOverrides,
  buildProposalChoices,
  isUuid,
  parseProposalIdList,
  type ProposalChoiceItem,
  type ProposalInventoryRow,
} from "../src/data/proposalItems";
import { supabase } from "../src/lib/supabase";
import {
  exchangeMethodLabel,
  normalizeExchangeMethod,
  supportsHandExchange,
  type ExchangeMethod,
} from "../src/lib/mailingAddress";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type ProposalTab = "give" | "receive" | "meetup";

type MeetupCandidate = {
  id: string;
  dateId: string;
  dayIndex: number;
  startSlot: number;
  endSlot: number;
  place: string;
  coordinate: MapCoordinate;
};

type PlaceSuggestion = {
  label: string;
  coordinate: MapCoordinate;
};

type MeetupDay = {
  id: string;
  day: string;
  date: string;
  month: string;
  isToday: boolean;
};

type DragDraft = {
  dateId: string;
  dayIndex: number;
  startSlot: number;
  currentSlot: number;
};

type CalendarFrame = {
  pageX: number;
  pageY: number;
  width: number;
  height: number;
};

type CandidateEdit = {
  id: string;
  action: "move" | "resize-end";
  dateId: string;
  dayIndex: number;
  startSlot: number;
  endSlot: number;
};

type CandidateTouchState = {
  timer: ReturnType<typeof setTimeout>;
  mode: "pending" | "editing";
  id: string;
  action: "move" | "resize-end";
  startX: number;
  startY: number;
  originalDayIndex: number;
  originalDateId: string;
  originalStartSlot: number;
  originalEndSlot: number;
  pointerStartOffsetSlots: number;
};

type ProfileProposalInventoryScope = {
  giveIds: string[];
  receiveIds: string[];
};

type ScopedProposalInventoryRow = ProposalInventoryRow & {
  user_id: string | null;
};

type RevisionProposalContext = {
  proposalId: string;
  partnerId: string;
  giveIds: string[];
  receiveIds: string[];
  meetupCandidates: MeetupCandidate[];
  exchangeMethod: ExchangeMethod;
};

type RevisionProposalRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  status: string | null;
  sender_have_ids: string[] | null;
  receiver_have_ids: string[] | null;
  meetup_start_at: string | null;
  meetup_end_at: string | null;
  meetup_place_name: string | null;
  meetup_lat: number | string | null;
  meetup_lng: number | string | null;
  meetup_candidates: unknown;
  exchange_method: string | null;
};

type LocalModeSettingsRow = {
  enabled: boolean | null;
  aw_id: string | null;
  last_lat: number | string | null;
  last_lng: number | string | null;
};

type ActivityWindowLocationRow = {
  id: string;
  venue: string | null;
  center_lat: number | string | null;
  center_lng: number | string | null;
  start_at: string | null;
  end_at: string | null;
};

const DAYS = buildMeetupDays(0);
const HOURS = Array.from({ length: 24 }, (_, hour) => hour);
const SLOT_MINUTES = 15;
const SLOT_COUNT = 24 * (60 / SLOT_MINUTES);
const SLOT_HEIGHT = 16;
const HOUR_HEIGHT = SLOT_HEIGHT * (60 / SLOT_MINUTES);
const TIME_LABEL_WIDTH = 52;
const CALENDAR_TOP_PADDING = 16;
const CALENDAR_BOTTOM_PADDING = 72;
const LONG_PRESS_MS = 280;
const TOUCH_CANCEL_PX = 12;
const FALLBACK_COORDINATE = {
  latitude: 35.5075,
  longitude: 139.6174,
};
const PRESET_PLACES: PlaceSuggestion[] = [
  {
    label: "横浜アリーナ 北口",
    coordinate: FALLBACK_COORDINATE,
  },
  {
    label: "新横浜駅 中央改札",
    coordinate: {
      latitude: 35.5079,
      longitude: 139.6179,
    },
  },
];
const TAB_ORDER: ProposalTab[] = ["give", "receive", "meetup"];
const PROFILE_INVENTORY_CACHE_MS = 45_000;
const PROFILE_INVENTORY_LIMIT_PER_USER = 80;
const profileInventoryCache = new Map<
  string,
  {
    expiresAt: number;
    promise?: Promise<ScopedProposalInventoryRow[]>;
    rows?: ScopedProposalInventoryRow[];
  }
>();

export default function ProposalSelectScreen() {
  const { user: authUser } = useAuth();
  const params = useLocalSearchParams<{
    tab?: ProposalTab | ProposalTab[];
    gives?: string | string[];
    receives?: string | string[];
    listings?: string | string[];
    candidateId?: string | string[];
    partnerId?: string | string[];
    partnerHandle?: string | string[];
    matchType?: string | string[];
    proposalId?: string | string[];
    revise?: string | string[];
    exchangeMethod?: string | string[];
  }>();
  const initialTab = parseTab(one(params.tab));
  const givesParam = one(params.gives);
  const receivesParam = one(params.receives);
  const listingsParam = one(params.listings);
  const candidateIdParam = one(params.candidateId);
  const partnerIdParam = one(params.partnerId);
  const partnerHandleParam = one(params.partnerHandle);
  const matchTypeParam = one(params.matchType);
  const proposalIdParam = one(params.proposalId);
  const reviseParam = one(params.revise);
  const exchangeMethodParam = one(params.exchangeMethod);
  const isRevisionMode = reviseParam === "1" && !!proposalIdParam;
  const [exchangeMethod, setExchangeMethod] = useState<ExchangeMethod>(() =>
    normalizeExchangeMethod(exchangeMethodParam),
  );
  const initialGiveIds = useMemo(
    () => parseProposalIdList(givesParam),
    [givesParam],
  );
  const initialReceiveIds = useMemo(
    () => parseProposalIdList(receivesParam),
    [receivesParam],
  );
  const [revisionContext, setRevisionContext] =
    useState<RevisionProposalContext | null>(null);
  const [revisionLoading, setRevisionLoading] = useState(false);
  const [revisionError, setRevisionError] = useState<string | null>(null);
  const candidateGiveIds = revisionContext?.giveIds ?? initialGiveIds;
  const candidateReceiveIds = revisionContext?.receiveIds ?? initialReceiveIds;
  const effectivePartnerIdParam = revisionContext?.partnerId ?? partnerIdParam;
  const initialGiveNeedsInventory =
    !!effectivePartnerIdParam &&
    (isRevisionMode || !hasSendableInventoryIds(candidateGiveIds));
  const initialReceiveNeedsInventory =
    !!effectivePartnerIdParam &&
    (isRevisionMode || !hasSendableInventoryIds(candidateReceiveIds));
  const usesProfileInventory =
    initialGiveNeedsInventory || initialReceiveNeedsInventory;
  const [profileInventoryScope, setProfileInventoryScope] =
    useState<ProfileProposalInventoryScope | null>(null);
  const [profileInventoryLoading, setProfileInventoryLoading] = useState(false);
  const [profileInventoryError, setProfileInventoryError] = useState<string | null>(null);
  const giveChoiceIds = initialGiveNeedsInventory
    ? profileInventoryScope?.giveIds ?? []
    : candidateGiveIds;
  const receiveChoiceIds = initialReceiveNeedsInventory
    ? profileInventoryScope?.receiveIds ?? []
    : candidateReceiveIds;
  const [catalogOverrides, setCatalogOverrides] = useState<
    ReturnType<typeof buildProposalCatalogOverrides>
  >(() => new Map());
  const giveChoices = useMemo(
    () =>
      buildProposalChoices(giveChoiceIds, "give", catalogOverrides, {
        includeFallback: !effectivePartnerIdParam,
      }),
    [catalogOverrides, effectivePartnerIdParam, giveChoiceIds],
  );
  const receiveChoices = useMemo(
    () =>
      buildProposalChoices(receiveChoiceIds, "receive", catalogOverrides, {
        includeFallback: !effectivePartnerIdParam,
      }),
    [catalogOverrides, effectivePartnerIdParam, receiveChoiceIds],
  );
  const [tab, setTab] = useState<ProposalTab>(initialTab);
  const [giveSelectedIds, setGiveSelectedIds] = useState<string[]>(() =>
    initialGiveNeedsInventory
      ? []
      : initialGiveIds.length > 0
      ? initialGiveIds
      : giveChoices[0]
        ? [giveChoices[0].id]
        : [],
  );
  const [receiveSelectedIds, setReceiveSelectedIds] = useState<string[]>(() =>
    initialReceiveNeedsInventory
      ? []
      : initialReceiveIds.length > 0
      ? initialReceiveIds
      : receiveChoices[0]
        ? [receiveChoices[0].id]
        : [],
  );
  const [meetupCandidates, setMeetupCandidates] = useState<MeetupCandidate[]>([]);
  const [activeMeetupId, setActiveMeetupId] = useState<string | null>(null);
  const [placeSheetId, setPlaceSheetId] = useState<string | null>(null);
  const tabSwipeRef = useRef<{
    startX: number;
    startY: number;
    tracking: boolean;
    swiping: boolean;
  } | null>(null);
  const autoMeetupAttemptedRef = useRef(false);
  const needsMeetup = supportsHandExchange(exchangeMethod);
  const meetupReady =
    meetupCandidates.length > 0 &&
    meetupCandidates.every((candidate) => candidate.place.trim().length > 0);
  const meetupHasTimeDraft = meetupCandidates.length > 0;

  useEffect(() => {
    if (!isRevisionMode) {
      setRevisionContext(null);
      setRevisionLoading(false);
      setRevisionError(null);
      return;
    }
    if (!proposalIdParam || !isUuid(proposalIdParam)) {
      setRevisionContext(null);
      setRevisionLoading(false);
      setRevisionError("打診情報を読み直してください");
      return;
    }
    if (!authUser) {
      setRevisionContext(null);
      setRevisionLoading(false);
      setRevisionError("ログイン状態を確認してください");
      return;
    }
    if (!supabase) {
      setRevisionContext(null);
      setRevisionLoading(false);
      setRevisionError(null);
      return;
    }

    let active = true;
    setRevisionLoading(true);
    setRevisionError(null);

    void (async () => {
      try {
        const { data, error } = await supabase
          .from("proposals")
          .select(
            "id, sender_id, receiver_id, status, sender_have_ids, receiver_have_ids, meetup_start_at, meetup_end_at, meetup_place_name, meetup_lat, meetup_lng, meetup_candidates, exchange_method",
          )
          .eq("id", proposalIdParam)
          .maybeSingle();
        if (error) throw error;
        const row = data as RevisionProposalRow | null;
        if (!row) throw new Error("打診が見つかりません");

        const isSender = row.sender_id === authUser.id;
        const isReceiver = row.receiver_id === authUser.id;
        if (!isSender && !isReceiver) {
          throw new Error("この打診には参加していません");
        }

        if (!active) return;
        setRevisionContext({
          proposalId: row.id,
          partnerId: isSender ? row.receiver_id : row.sender_id,
          giveIds: isSender
            ? safeStringArray(row.sender_have_ids)
            : safeStringArray(row.receiver_have_ids),
          receiveIds: isSender
            ? safeStringArray(row.receiver_have_ids)
            : safeStringArray(row.sender_have_ids),
          meetupCandidates: parseRevisionMeetupCandidates(row),
          exchangeMethod: normalizeExchangeMethod(row.exchange_method),
        });
      } catch (reason: unknown) {
        if (!active) return;
        setRevisionContext(null);
        setRevisionError(
          reason instanceof Error ? reason.message : "打診の条件を読み込めませんでした",
        );
      } finally {
        if (active) setRevisionLoading(false);
      }
    })();

    return () => {
      active = false;
    };
  }, [authUser?.id, isRevisionMode, proposalIdParam]);

  useEffect(() => {
    if (!revisionContext) return;
    setGiveSelectedIds(revisionContext.giveIds);
    setReceiveSelectedIds(revisionContext.receiveIds);
    setMeetupCandidates(revisionContext.meetupCandidates);
    setActiveMeetupId(revisionContext.meetupCandidates[0]?.id ?? null);
    setPlaceSheetId(null);
    setExchangeMethod(revisionContext.exchangeMethod);
  }, [revisionContext]);

  useEffect(() => {
    if (isRevisionMode || !needsMeetup || meetupCandidates.length > 0) return;
    if (autoMeetupAttemptedRef.current || !supabase) return;
    autoMeetupAttemptedRef.current = true;

    let active = true;
    void buildLocalModeAutoMeetupCandidate()
      .then((candidate) => {
        if (!active || !candidate) return;
        setMeetupCandidates([candidate]);
        setActiveMeetupId(candidate.id);
        setPlaceSheetId(null);
      })
      .catch(() => {
        // 自動候補は補助機能なので、失敗しても手動入力へフォールバックする。
      });

    return () => {
      active = false;
    };
  }, [isRevisionMode, meetupCandidates.length, needsMeetup]);

  useEffect(() => {
    if (!needsMeetup && tab === "meetup") {
      setTab("receive");
    }
  }, [needsMeetup, tab]);

  useEffect(() => {
    setGiveSelectedIds((current) => ensureChoiceSelection(current, giveChoices));
  }, [giveChoices]);

  useEffect(() => {
    setReceiveSelectedIds((current) =>
      ensureChoiceSelection(current, receiveChoices),
    );
  }, [receiveChoices]);

  useEffect(() => {
    if (!supabase) return;
    if (usesProfileInventory) return;
    const ids = Array.from(new Set([...candidateGiveIds, ...candidateReceiveIds]));
    if (ids.length === 0) {
      setCatalogOverrides(new Map());
      return;
    }

    let active = true;
    supabase
      .from("goods_inventory")
      .select(
        "id, title, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
      )
      .in("id", ids)
      .then(({ data }) => {
        if (!active) return;
        setCatalogOverrides(
          buildProposalCatalogOverrides((data as ProposalInventoryRow[] | null) ?? []),
        );
      });

    return () => {
      active = false;
    };
  }, [candidateGiveIds, candidateReceiveIds, usesProfileInventory]);

  useEffect(() => {
    if (!usesProfileInventory) {
      setProfileInventoryScope(null);
      setProfileInventoryLoading(false);
      setProfileInventoryError(null);
      return;
    }
    if (!supabase || !effectivePartnerIdParam) {
      setProfileInventoryScope(null);
      setProfileInventoryError(null);
      return;
    }
    if (!authUser) {
      setProfileInventoryScope(null);
      setProfileInventoryLoading(false);
      setProfileInventoryError("ログイン状態を確認してください");
      return;
    }
    if (!isUuid(effectivePartnerIdParam)) {
      setProfileInventoryScope({ giveIds: [], receiveIds: [] });
      setProfileInventoryLoading(false);
      setProfileInventoryError("相手情報を読み直してください");
      return;
    }

    let active = true;
    setProfileInventoryLoading(true);
    setProfileInventoryError(null);

    void (async () => {
      try {
        const rows = await loadProfileProposalInventoryRows(
          authUser.id,
          effectivePartnerIdParam,
        );
        const giveRows = rows.filter((row) => row.user_id === authUser.id);
        const receiveRows = rows.filter((row) => row.user_id === effectivePartnerIdParam);

        if (!active) return;
        setCatalogOverrides(buildProposalCatalogOverrides(rows));
        setProfileInventoryScope({
          giveIds: initialGiveNeedsInventory
            ? uniqueStrings([...candidateGiveIds, ...giveRows.map((row) => row.id)])
            : candidateGiveIds,
          receiveIds: initialReceiveNeedsInventory
            ? uniqueStrings([
                ...candidateReceiveIds,
                ...receiveRows.map((row) => row.id),
              ])
            : candidateReceiveIds,
        });
      } catch (reason: unknown) {
        if (!active) return;
        setCatalogOverrides(new Map());
        setProfileInventoryScope({ giveIds: [], receiveIds: [] });
        setProfileInventoryError(
          reason instanceof Error ? reason.message : "在庫候補を読み込めませんでした",
        );
      } finally {
        if (active) setProfileInventoryLoading(false);
      }
    })();

    return () => {
      active = false;
    };
  }, [
    candidateGiveIds,
    candidateReceiveIds,
    effectivePartnerIdParam,
    authUser?.id,
    initialGiveNeedsInventory,
    initialReceiveNeedsInventory,
    usesProfileInventory,
  ]);

  const tabs = useMemo(
    () => [
      {
        id: "give" as const,
        label: "私が出す",
        count: giveSelectedIds.length,
        color: megrumColors.lavender,
      },
      {
        id: "receive" as const,
        label: "受け取る",
        count: receiveSelectedIds.length,
        color: megrumColors.sky,
      },
      ...(needsMeetup
        ? [
            {
              id: "meetup" as const,
              label: "待ち合わせ",
              count: 1,
              color: megrumColors.pink,
            },
          ]
        : []),
    ],
    [giveSelectedIds.length, needsMeetup, receiveSelectedIds.length],
  );
  const giveSelectionMissing = giveSelectedIds.length === 0;
  const receiveSelectionMissing = receiveSelectedIds.length === 0;
  const itemSelectionMissing = giveSelectionMissing || receiveSelectionMissing;
  const primaryButtonDisabled =
    revisionLoading ||
    profileInventoryLoading ||
    !!revisionError ||
    itemSelectionMissing ||
    (needsMeetup && tab === "meetup" && !meetupReady);
  const primaryButtonLabel = (() => {
    if (revisionLoading) return "打診の条件を読み込んでいます";
    if (profileInventoryLoading) return "在庫を読み込んでいます";
    if (revisionError) return revisionError;
    if (giveSelectionMissing) return "私が出すものを選択してください";
    if (receiveSelectionMissing) return "受け取るものを選択してください";
    if (!needsMeetup) {
      return tab === "give"
        ? "受け取るものへ進む"
        : isRevisionMode
          ? "次へ：変更確認 →"
          : "次へ：送信確認 →";
    }
    if (tab !== "meetup") return "待ち合わせへ進む";
    if (meetupReady) {
      return isRevisionMode ? "次へ：変更確認 →" : "次へ：送信確認 →";
    }
    return meetupHasTimeDraft
      ? "場所未設定の候補があります"
      : "交換できる時間を設定してください";
  })();

  return (
    <Screen scroll={false} contentStyle={styles.screen}>
      <View style={styles.header}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="戻る"
          onPress={() => router.back()}
          style={styles.backButton}
        >
          <Text style={styles.backText}>‹</Text>
        </Pressable>
        <View style={styles.headerText}>
          <Text style={styles.kicker}>PROPOSAL</Text>
          <Text style={styles.title}>提示物の選択</Text>
        </View>
        <StatusPill label="STEP 1/2" tone="lavender" />
      </View>

      <View style={styles.methodCard}>
        <View style={styles.methodHeader}>
          <Text style={styles.methodTitle}>交換手段</Text>
          <Text style={styles.methodSub}>{exchangeMethodLabel(exchangeMethod)}</Text>
        </View>
        <SegmentedControl
          values={["現地交換", "郵送交換", "どちらもOK"]}
          selectedIndex={exchangeMethodToIndex(exchangeMethod)}
          tintColor={megrumColors.lavender}
          onChange={(event) =>
            setExchangeMethod(exchangeMethodFromIndex(event.nativeEvent.selectedSegmentIndex))
          }
        />
        <Text style={styles.methodHint}>
          {exchangeMethod === "mail"
            ? "郵送では待ち合わせ候補は不要です。送信前に住所登録を確認します。"
            : exchangeMethod === "both"
              ? "現地候補と住所登録の両方を確認します。相手とは合意までに受け渡し方法を調整できます。"
              : "現地交換では、送信前に待ち合わせ候補の入力が必要です。"}
        </Text>
      </View>

      <SectionTabs value={tab} tabs={tabs} onChange={setTab} />

      <View
        style={styles.paneHost}
        onTouchStart={handleTabSwipeStart}
        onTouchMove={handleTabSwipeMove}
        onTouchEnd={handleTabSwipeEnd}
        onTouchCancel={handleTabSwipeCancel}
      >
        {tab === "give" ? (
          <ChoicePane
            items={giveChoices}
            selectedIds={giveSelectedIds}
            loading={revisionLoading || (usesProfileInventory && profileInventoryLoading)}
            emptyText={
              profileInventoryError ?? "私が出せる譲る在庫がありません"
            }
            onToggle={(id) =>
              setGiveSelectedIds((current) => toggleChoiceId(current, id))
            }
          />
        ) : null}

        {tab === "receive" ? (
          <ChoicePane
            items={receiveChoices}
            selectedIds={receiveSelectedIds}
            loading={revisionLoading || (usesProfileInventory && profileInventoryLoading)}
            emptyText={
              profileInventoryError ?? "相手の譲る在庫がありません"
            }
            onToggle={(id) =>
              setReceiveSelectedIds((current) => toggleChoiceId(current, id))
            }
          />
        ) : null}

        {tab === "meetup" ? (
          <MeetupPane
            candidates={meetupCandidates}
            activeCandidateId={activeMeetupId}
            placeSheetId={placeSheetId}
            onSelectCandidate={setActiveMeetupId}
            onClosePlaceSheet={() => setPlaceSheetId(null)}
            onOpenPlaceSheet={(id) => {
              setActiveMeetupId(id);
              setPlaceSheetId(id);
            }}
            onAddCandidate={(dayIndex, dateId, startSlot, endSlot) => {
              const id = `candidate-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
              const candidate: MeetupCandidate = {
                id,
                dateId,
                dayIndex,
                startSlot,
                endSlot,
                place: "",
                coordinate: FALLBACK_COORDINATE,
              };
              setMeetupCandidates((current) => [...current, candidate]);
              setActiveMeetupId(id);
              setPlaceSheetId(id);
            }}
            onDeleteCandidate={(id) => {
              setMeetupCandidates((current) =>
                current.filter((candidate) => candidate.id !== id),
              );
              setActiveMeetupId((current) => (current === id ? null : current));
              setPlaceSheetId((current) => (current === id ? null : current));
            }}
            onUpdateCandidate={(id, patch) => {
              setMeetupCandidates((current) =>
                current.map((candidate) =>
                  candidate.id === id ? { ...candidate, ...patch } : candidate,
                ),
              );
            }}
          />
        ) : null}
      </View>

      <PrimaryButton
        onPress={() => {
          if (profileInventoryLoading || revisionLoading || revisionError) return;
          if (giveSelectedIds.length === 0) {
            setTab("give");
            return;
          }
          if (receiveSelectedIds.length === 0) {
            setTab("receive");
            return;
          }
          if (!needsMeetup) {
            if (tab !== "receive") {
              setTab("receive");
              return;
            }
          } else if (tab !== "meetup") {
            setTab("meetup");
            return;
          }
          router.push({
            pathname: "/proposal-confirm",
            params: {
              gives: giveSelectedIds.join(","),
              receives: receiveSelectedIds.join(","),
              ...(listingsParam ? { listings: listingsParam } : {}),
              ...(candidateIdParam ? { candidateId: candidateIdParam } : {}),
              ...(partnerIdParam ? { partnerId: partnerIdParam } : {}),
              ...(revisionContext?.partnerId
                ? { partnerId: revisionContext.partnerId }
                : {}),
              ...(partnerHandleParam ? { partnerHandle: partnerHandleParam } : {}),
              ...(matchTypeParam ? { matchType: matchTypeParam } : {}),
              ...(isRevisionMode && proposalIdParam
                ? { proposalId: proposalIdParam, revise: "1" }
                : {}),
              exchangeMethod,
              meetups: JSON.stringify(
                needsMeetup
                  ? meetupCandidates
                      .filter((candidate) => candidate.place.trim())
                      .map((candidate, index) => ({
                        id: candidate.id,
                        label: `候補${index + 1}`,
                        time: `${formatCandidateDate(candidate.dateId)} ${formatSlot(candidate.startSlot)} - ${formatSlot(candidate.endSlot)}`,
                        startAt: slotToIso(candidate.dateId, candidate.startSlot),
                        endAt: slotToIso(candidate.dateId, candidate.endSlot),
                        place: candidate.place,
                        latitude: candidate.coordinate.latitude,
                        longitude: candidate.coordinate.longitude,
                      }))
                  : [],
              ),
            },
          });
        }}
        disabled={primaryButtonDisabled}
      >
        {primaryButtonLabel}
      </PrimaryButton>
    </Screen>
  );

  function moveTabBySwipe(direction: 1 | -1) {
    if (tab === "meetup") return;
    const currentIndex = TAB_ORDER.indexOf(tab);
    const next = TAB_ORDER[currentIndex + direction];
    if (!next) return;
    setTab(next);
  }

  function handleTabSwipeStart(event: GestureResponderEvent) {
    const { pageX, pageY } = event.nativeEvent;
    tabSwipeRef.current = {
      startX: pageX,
      startY: pageY,
      tracking: tab !== "meetup",
      swiping: false,
    };
  }

  function handleTabSwipeMove(event: GestureResponderEvent) {
    const state = tabSwipeRef.current;
    if (!state?.tracking) return;
    const { pageX, pageY } = event.nativeEvent;
    const dx = pageX - state.startX;
    const dy = pageY - state.startY;
    const absX = Math.abs(dx);
    const absY = Math.abs(dy);
    if (!state.swiping) {
      if (absX > 14 && absX > absY * 1.25) {
        state.swiping = true;
      } else if (absY > 14 && absY > absX * 1.1) {
        state.tracking = false;
      }
    }
  }

  function handleTabSwipeEnd(event: GestureResponderEvent) {
    const state = tabSwipeRef.current;
    tabSwipeRef.current = null;
    if (!state?.tracking || !state.swiping) return;
    const { pageX, pageY } = event.nativeEvent;
    const dx = pageX - state.startX;
    const dy = pageY - state.startY;
    const absX = Math.abs(dx);
    const absY = Math.abs(dy);
    if (absX < 56 || absX < absY * 1.35) return;
    moveTabBySwipe(dx < 0 ? 1 : -1);
  }

  function handleTabSwipeCancel() {
    tabSwipeRef.current = null;
  }
}

async function loadProfileProposalInventoryRows(
  userId: string,
  partnerId: string,
): Promise<ScopedProposalInventoryRow[]> {
  if (!supabase) return [];
  const cacheKey = `${userId}:${partnerId}`;
  const now = Date.now();
  const cached = profileInventoryCache.get(cacheKey);
  if (cached?.rows && cached.expiresAt > now) {
    return cached.rows;
  }
  if (cached?.promise) {
    return cached.promise;
  }

  const promise = Promise.all([
    fetchProposalInventoryRowsForUser(userId),
    userId === partnerId
      ? Promise.resolve<ScopedProposalInventoryRow[]>([])
      : fetchProposalInventoryRowsForUser(partnerId),
  ]).then(([mineRows, partnerRows]) => [...mineRows, ...partnerRows]);

  profileInventoryCache.set(cacheKey, {
    expiresAt: now + PROFILE_INVENTORY_CACHE_MS,
    promise,
    rows: cached?.rows,
  });

  try {
    const rows = await promise;
    profileInventoryCache.set(cacheKey, {
      expiresAt: Date.now() + PROFILE_INVENTORY_CACHE_MS,
      rows,
    });
    return rows;
  } catch (error) {
    profileInventoryCache.delete(cacheKey);
    throw error;
  }
}

async function fetchProposalInventoryRowsForUser(
  userId: string,
): Promise<ScopedProposalInventoryRow[]> {
  if (!supabase) return [];
  const { data, error } = await supabase
    .from("goods_inventory")
    .select(
      "id, user_id, title, photo_urls, hue, group:groups_master(name), character:characters_master(name), goods_type:goods_types_master(name)",
    )
    .eq("user_id", userId)
    .eq("kind", "for_trade")
    .eq("status", "active")
    .order("created_at", { ascending: false })
    .limit(PROFILE_INVENTORY_LIMIT_PER_USER);
  if (error) throw error;
  return (data as ScopedProposalInventoryRow[] | null) ?? [];
}

function ChoicePane({
  items,
  selectedIds,
  loading,
  emptyText,
  onToggle,
}: {
  items: ProposalChoiceItem[];
  selectedIds: string[];
  loading?: boolean;
  emptyText?: string;
  onToggle: (id: string) => void;
}) {
  const selectedSet = useMemo(() => new Set(selectedIds), [selectedIds]);
  if (loading) {
    return <ProposalChoiceSkeleton />;
  }

  if (items.length === 0) {
    return (
      <View style={styles.choiceState}>
        <Text style={styles.choiceStateText}>
          {emptyText ?? "選択できるグッズがありません"}
        </Text>
      </View>
    );
  }

  return (
    <ScrollView
      showsVerticalScrollIndicator={false}
      contentContainerStyle={styles.choiceList}
    >
      {items.map((item) => {
        const selected = selectedSet.has(item.id);
        return (
          <Pressable
            key={item.id}
            onPress={() => onToggle(item.id)}
            style={[styles.choiceCard, selected ? styles.choiceCardSelected : null]}
          >
            <View style={[styles.choiceImage, { backgroundColor: item.hue }]}>
              {item.photoUrl ? (
                <Image source={{ uri: item.photoUrl }} style={styles.choicePhoto} />
              ) : (
                <>
                  <View style={styles.choiceShine} />
                  <Text style={styles.choiceGlyph}>{item.glyph}</Text>
                </>
              )}
            </View>
            <View style={styles.choiceCopy}>
              <Text numberOfLines={1} style={styles.choiceTitle}>
                {item.title}
              </Text>
              <Text numberOfLines={1} style={styles.choiceSubtitle}>
                {item.subtitle}
              </Text>
              <View style={styles.choiceHint}>
                <Text numberOfLines={1} style={styles.choiceHintText}>
                  {item.hint}
                </Text>
              </View>
            </View>
            <View style={[styles.checkCircle, selected ? styles.checkCircleOn : null]}>
              <Text style={[styles.checkText, selected ? styles.checkTextOn : null]}>
                {selected ? "✓" : ""}
              </Text>
            </View>
          </Pressable>
        );
      })}
    </ScrollView>
  );
}

function MeetupPane({
  candidates,
  activeCandidateId,
  placeSheetId,
  onSelectCandidate,
  onOpenPlaceSheet,
  onClosePlaceSheet,
  onAddCandidate,
  onDeleteCandidate,
  onUpdateCandidate,
}: {
  candidates: MeetupCandidate[];
  activeCandidateId: string | null;
  placeSheetId: string | null;
  onSelectCandidate: (id: string | null) => void;
  onOpenPlaceSheet: (id: string) => void;
  onClosePlaceSheet: () => void;
  onAddCandidate: (
    dayIndex: number,
    dateId: string,
    startSlot: number,
    endSlot: number,
  ) => void;
  onDeleteCandidate: (id: string) => void;
  onUpdateCandidate: (id: string, patch: Partial<MeetupCandidate>) => void;
}) {
  const { width } = useWindowDimensions();
  const scrollRef = useRef<ScrollView>(null);
  const [weekOffset, setWeekOffset] = useState(0);
  const days = useMemo(() => buildMeetupDays(weekOffset), [weekOffset]);
  const weekHeaderTouchRef = useRef<{
    startX: number;
    startY: number;
    swiping: boolean;
  } | null>(null);
  const touchPressRef = useRef<{
    timer: ReturnType<typeof setTimeout>;
    mode: "pending" | "scrolling" | "dragging" | "swiping";
    dayIndex: number;
    dateId: string;
    startSlot: number;
    startX: number;
    startY: number;
  } | null>(null);
  const candidateTouchRef = useRef<CandidateTouchState | null>(null);
  const candidateEditRef = useRef<CandidateEdit | null>(null);
  const calendarFrameRef = useRef<CalendarFrame | null>(null);
  const calendarGridRef = useRef<View>(null);
  const dragDraftRef = useRef<DragDraft | null>(null);
  const weekDragX = useRef(new Animated.Value(0)).current;
  const hintPulse = useRef(new Animated.Value(0)).current;
  const weekDragValueRef = useRef(0);
  const [dragDraft, setDragDraftState] = useState<DragDraft | null>(null);
  const [candidateEdit, setCandidateEditState] =
    useState<CandidateEdit | null>(null);
  const [calendarGestureLock, setCalendarGestureLock] = useState(false);
  const calendarWidth = width - 36;
  const dayWidth = (calendarWidth - TIME_LABEL_WIDTH) / days.length;
  const pagerWeeks = useMemo(
    () =>
      [-1, 0, 1].map((relative) => ({
        relative,
        days: buildMeetupDays(weekOffset + relative),
      })),
    [weekOffset],
  );
  const contentHeight =
    CALENDAR_TOP_PADDING + SLOT_COUNT * SLOT_HEIGHT + CALENDAR_BOTTOM_PADDING;
  const activeCandidate =
    candidates.find((candidate) => candidate.id === placeSheetId) ?? null;
  const previousCandidate = activeCandidate
    ? candidates
        .filter((candidate) => candidate.id !== activeCandidate.id)
        .reverse()
        .find((candidate) => candidate.place.trim()) ?? null
    : null;

  useEffect(() => {
    const timer = setTimeout(() => {
      scrollRef.current?.scrollTo({
        y: Math.max(0, calendarSlotTop(10 * 4) - 10),
        animated: false,
      });
    }, 60);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    const listenerId = weekDragX.addListener(({ value }) => {
      weekDragValueRef.current = value;
    });
    return () => {
      weekDragX.removeListener(listenerId);
    };
  }, [weekDragX]);

  useEffect(() => {
    if (candidates.length > 0 || dragDraft) {
      hintPulse.stopAnimation();
      hintPulse.setValue(0);
      return;
    }
    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(hintPulse, {
          toValue: 1,
          duration: 1250,
          useNativeDriver: true,
        }),
        Animated.timing(hintPulse, {
          toValue: 0,
          duration: 1250,
          useNativeDriver: true,
        }),
      ]),
    );
    animation.start();
    return () => {
      animation.stop();
    };
  }, [candidates.length, dragDraft, hintPulse]);

  useEffect(
    () => () => {
      clearTouchPress();
      clearCandidateTouch();
    },
    [],
  );

  function setDragDraft(next: DragDraft | null) {
    dragDraftRef.current = next;
    setDragDraftState(next);
  }

  function clearTouchPress() {
    if (touchPressRef.current) {
      clearTimeout(touchPressRef.current.timer);
    }
    touchPressRef.current = null;
  }

  function setCandidateEdit(next: CandidateEdit | null) {
    candidateEditRef.current = next;
    setCandidateEditState(next);
  }

  function clearCandidateTouch() {
    if (candidateTouchRef.current) {
      clearTimeout(candidateTouchRef.current.timer);
    }
    candidateTouchRef.current = null;
    setCandidateEdit(null);
    setCalendarGestureLock(false);
  }

  function measureCalendarFrame() {
    calendarGridRef.current?.measure((_, __, measuredWidth, measuredHeight, pageX, pageY) => {
      calendarFrameRef.current = {
        pageX,
        pageY,
        width: measuredWidth,
        height: measuredHeight,
      };
    });
  }

  function pointToCalendar(pageX: number, pageY: number) {
    const frame = calendarFrameRef.current;
    if (!frame) return null;
    const dayAreaLeft = frame.pageX + TIME_LABEL_WIDTH;
    const dayAreaWidth = Math.max(1, frame.width - TIME_LABEL_WIDTH);
    const rawDayIndex = Math.floor(
      ((pageX - dayAreaLeft) / dayAreaWidth) * days.length,
    );
    const dayIndex = Math.max(0, Math.min(days.length - 1, rawDayIndex));
    return {
      dayIndex,
      slot: slotFromCalendarY(pageY - frame.pageY),
    };
  }

  function setWeekDrag(dx: number) {
    const maxDrag = Math.max(1, calendarWidth);
    weekDragX.setValue(Math.max(-maxDrag, Math.min(maxDrag, dx)));
  }

  function resetWeekDrag(animated = true) {
    if (!animated) {
      weekDragX.setValue(0);
      return;
    }
    Animated.spring(weekDragX, {
      toValue: 0,
      damping: 18,
      stiffness: 220,
      mass: 0.72,
      useNativeDriver: true,
    }).start();
  }

  function commitWeekSwipe(direction: 1 | -1, dx: number) {
    const maxCarry = calendarWidth * 0.42;
    const carriedDx = Math.max(-maxCarry, Math.min(maxCarry, dx));
    onSelectCandidate(null);
    clearCandidateTouch();
    setDragDraft(null);
    weekDragX.setValue(carriedDx);
    setWeekOffset((current) => current + direction);
    requestAnimationFrame(() => {
      resetWeekDrag(true);
    });
  }

  function settleWeekSwipe(dx: number) {
    const threshold = Math.min(96, calendarWidth * 0.22);
    if (Math.abs(dx) > threshold) {
      commitWeekSwipe(dx < 0 ? 1 : -1, dx);
      return;
    }
    resetWeekDrag(true);
  }

  function handleWeekSwipeStart(event: GestureResponderEvent) {
    const { pageX, pageY } = event.nativeEvent;
    weekHeaderTouchRef.current = { startX: pageX, startY: pageY, swiping: false };
  }

  function handleWeekSwipeMove(event: GestureResponderEvent) {
    const start = weekHeaderTouchRef.current;
    if (!start) return;
    const { pageX, pageY } = event.nativeEvent;
    const dx = pageX - start.startX;
    const dy = pageY - start.startY;
    const absX = Math.abs(dx);
    const absY = Math.abs(dy);
    if (!start.swiping && absX > 10 && absX > absY * 1.08) {
      start.swiping = true;
    }
    if (start.swiping) {
      setWeekDrag(dx);
    }
  }

  function handleWeekSwipeEnd(event: GestureResponderEvent) {
    const start = weekHeaderTouchRef.current;
    weekHeaderTouchRef.current = null;
    if (!start) return;
    const { pageX, pageY } = event.nativeEvent;
    const dx = pageX - start.startX;
    const dy = pageY - start.startY;
    if (start.swiping || (Math.abs(dx) > 56 && Math.abs(dx) > Math.abs(dy) * 1.25)) {
      settleWeekSwipe(dx);
      return;
    }
    resetWeekDrag(true);
  }

  function beginCandidateEdit(state: CandidateTouchState) {
    clearTimeout(state.timer);
    candidateTouchRef.current = {
      ...state,
      mode: "editing",
    };
    setCalendarGestureLock(true);
    setCandidateEdit({
      id: state.id,
      action: state.action,
      dayIndex: state.originalDayIndex,
      dateId: state.originalDateId,
      startSlot: state.originalStartSlot,
      endSlot: state.originalEndSlot,
    });
  }

  function updateCandidateEdit(pageX: number, pageY: number) {
    const state = candidateTouchRef.current;
    if (!state || state.mode !== "editing") return;
    const point = pointToCalendar(pageX, pageY);
    if (!point) return;
    const duration = Math.max(
      1,
      state.originalEndSlot - state.originalStartSlot,
    );
    if (state.action === "move") {
      const startSlot = Math.max(
        0,
        Math.min(
          SLOT_COUNT - duration,
          point.slot - state.pointerStartOffsetSlots,
        ),
      );
      setCandidateEdit({
        id: state.id,
        action: state.action,
        dayIndex: point.dayIndex,
        dateId: days[point.dayIndex]?.id ?? state.originalDateId,
        startSlot,
        endSlot: startSlot + duration,
      });
      return;
    }
    const endSlot = Math.max(
      state.originalStartSlot + 1,
      Math.min(SLOT_COUNT, point.slot + 1),
    );
    setCandidateEdit({
      id: state.id,
      action: state.action,
      dayIndex: state.originalDayIndex,
      dateId: state.originalDateId,
      startSlot: state.originalStartSlot,
      endSlot,
    });
  }

  function handleCandidateTouchStart(
    event: GestureResponderEvent,
    candidate: MeetupCandidate,
    action: "move" | "resize-end",
  ) {
    event.stopPropagation();
    clearTouchPress();
    clearCandidateTouch();
    measureCalendarFrame();
    onSelectCandidate(candidate.id);
    const { pageX, pageY } = event.nativeEvent;
    const duration = Math.max(1, candidate.endSlot - candidate.startSlot);
    const point = pointToCalendar(pageX, pageY);
    const pointerStartOffsetSlots =
      action === "move" && point?.dayIndex === candidate.dayIndex
        ? Math.max(0, Math.min(duration - 1, point.slot - candidate.startSlot))
        : 0;
    const timer = setTimeout(() => {
      const state = candidateTouchRef.current;
      if (!state || state.id !== candidate.id || state.mode !== "pending") {
        return;
      }
      beginCandidateEdit(state);
    }, LONG_PRESS_MS);
    candidateTouchRef.current = {
      timer,
      mode: "pending",
      id: candidate.id,
      action,
      startX: pageX,
      startY: pageY,
      originalDayIndex: candidate.dayIndex,
      originalDateId: candidate.dateId,
      originalStartSlot: candidate.startSlot,
      originalEndSlot: candidate.endSlot,
      pointerStartOffsetSlots,
    };
  }

  function handleCandidateTouchMove(event: GestureResponderEvent) {
    const state = candidateTouchRef.current;
    if (!state) return;
    event.stopPropagation();
    const { pageX, pageY } = event.nativeEvent;
    if (state.mode === "pending") {
      const dx = pageX - state.startX;
      const dy = pageY - state.startY;
      if (Math.hypot(dx, dy) > TOUCH_CANCEL_PX) {
        clearCandidateTouch();
      }
      return;
    }
    updateCandidateEdit(pageX, pageY);
  }

  function handleCandidateTouchEnd(event: GestureResponderEvent) {
    const state = candidateTouchRef.current;
    if (!state) return;
    event.stopPropagation();
    if (state.mode === "editing") {
      updateCandidateEdit(event.nativeEvent.pageX, event.nativeEvent.pageY);
      const edit = candidateEditRef.current;
      if (edit) {
        onUpdateCandidate(edit.id, {
          dayIndex: edit.dayIndex,
          dateId: edit.dateId,
          startSlot: edit.startSlot,
          endSlot: edit.endSlot,
        });
      }
      clearCandidateTouch();
      return;
    }
    clearCandidateTouch();
    onOpenPlaceSheet(state.id);
  }

  function handleDayTouchStart(e: GestureResponderEvent, dayIndex: number) {
    e.stopPropagation();
    clearTouchPress();
    clearCandidateTouch();
    onSelectCandidate(null);
    const { locationY, pageX, pageY } = e.nativeEvent;
    const startSlot = slotFromLocationY(locationY);
    const dateId = days[dayIndex]?.id ?? DAYS[0].id;
    const timer = setTimeout(() => {
      const press = touchPressRef.current;
      if (!press || press.mode !== "pending") return;
      press.mode = "dragging";
      setCalendarGestureLock(true);
      const draft = {
        dayIndex,
        dateId: press.dateId,
        startSlot,
        currentSlot: Math.min(SLOT_COUNT - 1, startSlot + 1),
      };
      setDragDraft(draft);
    }, LONG_PRESS_MS);
    touchPressRef.current = {
      timer,
      mode: "pending",
      dayIndex,
      dateId,
      startSlot,
      startX: pageX,
      startY: pageY,
    };
  }

  function handleDayTouchMove(e: GestureResponderEvent) {
    const press = touchPressRef.current;
    if (!press) return;
    e.stopPropagation();
    const { locationY, pageX, pageY } = e.nativeEvent;
    const dx = pageX - press.startX;
    const dy = pageY - press.startY;
    const absX = Math.abs(dx);
    const absY = Math.abs(dy);
    if (press.mode === "swiping") {
      setCalendarGestureLock(true);
      setWeekDrag(dx);
      return;
    }
    if (press.mode === "pending" && absX > 10 && absX > absY * 1.08) {
      clearTimeout(press.timer);
      press.mode = "swiping";
      setCalendarGestureLock(true);
      setWeekDrag(dx);
      return;
    }
    if (press.mode === "pending" && Math.hypot(dx, dy) > TOUCH_CANCEL_PX) {
      clearTouchPress();
      return;
    }
    if (press.mode !== "dragging") return;
    const currentSlot = slotFromLocationY(locationY);
    setDragDraft({
      dayIndex: press.dayIndex,
      dateId: press.dateId,
      startSlot: press.startSlot,
      currentSlot,
    });
  }

  function handleDayTouchEnd(e: GestureResponderEvent) {
    e.stopPropagation();
    const draft = dragDraftRef.current;
    const press = touchPressRef.current;
    if (press?.mode === "swiping") {
      const dx = e.nativeEvent.pageX - press.startX;
      clearTouchPress();
      setDragDraft(null);
      settleWeekSwipe(dx || weekDragValueRef.current);
      setCalendarGestureLock(false);
      return;
    }
    clearTouchPress();
    if (!draft) {
      setDragDraft(null);
      if (press?.mode === "pending") {
        const startSlot = press.startSlot;
        onAddCandidate(
          press.dayIndex,
          press.dateId,
          startSlot,
          Math.min(SLOT_COUNT, startSlot + 2),
        );
      }
      return;
    }
    const releaseSlot = slotFromLocationY(e.nativeEvent.locationY);
    const nextDraft = {
      ...draft,
      currentSlot:
        releaseSlot === draft.startSlot ? draft.currentSlot : releaseSlot,
    };
    const range = normalizedDraftRange(nextDraft);
    onAddCandidate(
      nextDraft.dayIndex,
      nextDraft.dateId,
      range.startSlot,
      range.endSlot,
    );
    setDragDraft(null);
    setCalendarGestureLock(false);
  }

  function handleDayTouchCancel() {
    clearTouchPress();
    clearCandidateTouch();
    setDragDraft(null);
    setCalendarGestureLock(false);
    resetWeekDrag(true);
  }

  const preview = dragDraft
    ? {
        dayIndex: dragDraft.dayIndex,
        ...normalizedDraftRange(dragDraft),
      }
    : null;

  return (
    <View style={styles.meetupRoot}>
      <View
        style={styles.daysViewport}
        onTouchStart={handleWeekSwipeStart}
        onTouchMove={handleWeekSwipeMove}
        onTouchEnd={handleWeekSwipeEnd}
        onTouchCancel={() => {
          weekHeaderTouchRef.current = null;
          resetWeekDrag(true);
        }}
      >
        <Animated.View
          style={[
            styles.weekPager,
            {
              width: calendarWidth * 3,
              transform: [{ translateX: -calendarWidth }, { translateX: weekDragX }],
            },
          ]}
        >
          {pagerWeeks.map((week) => (
            <View
              key={`header-${week.relative}-${week.days[0]?.id ?? "week"}`}
              style={[styles.weekPage, { width: calendarWidth }]}
            >
              <View style={styles.dayTimeSpacer} />
              {week.days.map((day) => (
                <View
                  key={day.id}
                  style={[
                    styles.dayCell,
                    day.isToday ? styles.dayCellToday : null,
                  ]}
                >
                  <Text
                    style={[
                      styles.dayName,
                      day.isToday ? styles.dayNameToday : null,
                    ]}
                  >
                    {day.day}
                  </Text>
                  <Text
                    style={[
                      styles.dayDate,
                      day.isToday ? styles.dayDateToday : null,
                    ]}
                  >
                    {day.date}
                  </Text>
                </View>
              ))}
            </View>
          ))}
        </Animated.View>
      </View>

      <ScrollView
        ref={scrollRef}
        scrollEnabled={!calendarGestureLock && !dragDraft && !candidateEdit}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={[
          styles.calendarContent,
          { height: contentHeight },
        ]}
      >
        <Animated.View
          style={[
            styles.weekPager,
            {
              height: contentHeight,
              width: calendarWidth * 3,
              transform: [{ translateX: -calendarWidth }, { translateX: weekDragX }],
            },
          ]}
        >
          {pagerWeeks.map((week) => {
            const isCurrentWeek = week.relative === 0;
            return (
              <View
                key={`grid-${week.relative}-${week.days[0]?.id ?? "week"}`}
                pointerEvents={isCurrentWeek ? "auto" : "none"}
                style={[styles.calendarPage, { width: calendarWidth }]}
              >
                <View
                  ref={isCurrentWeek ? calendarGridRef : undefined}
                  collapsable={false}
                  onLayout={isCurrentWeek ? measureCalendarFrame : undefined}
                  style={[styles.calendarGrid, { height: contentHeight }]}
                >
                  <View style={[styles.timeAxis, { width: TIME_LABEL_WIDTH }]}>
                    {HOURS.map((hour) => (
                      <Text
                        key={hour}
                        style={[
                          styles.hourLabel,
                          {
                            top: calendarSlotTop(hour * 4) - 7,
                          },
                        ]}
                      >
                        {formatSlot(hour * 4)}
                      </Text>
                    ))}
                  </View>

                  {week.days.map((day, dayIndex) => (
                    <View
                      key={day.id}
                      style={[
                        styles.dayColumn,
                        {
                          left: TIME_LABEL_WIDTH + dayIndex * dayWidth,
                          width: dayWidth,
                        },
                      ]}
                      onTouchStart={
                        isCurrentWeek
                          ? (event) => handleDayTouchStart(event, dayIndex)
                          : undefined
                      }
                      onTouchMove={isCurrentWeek ? handleDayTouchMove : undefined}
                      onTouchEnd={isCurrentWeek ? handleDayTouchEnd : undefined}
                      onTouchCancel={
                        isCurrentWeek ? handleDayTouchCancel : undefined
                      }
                    >
                      {HOURS.map((hour) => (
                        <View
                          key={`${day.id}-${hour}`}
                          pointerEvents="none"
                          style={[
                            styles.calendarCell,
                            {
                              top: calendarSlotTop(hour * 4),
                              height: HOUR_HEIGHT,
                            },
                          ]}
                        />
                      ))}
                    </View>
                  ))}

                  {isCurrentWeek
                    ? candidates.map((candidate, index) => {
                        const visibleDayIndex = days.findIndex(
                          (day) => day.id === candidate.dateId,
                        );
                        if (visibleDayIndex < 0) return null;
                        const visibleCandidate = {
                          ...candidate,
                          dayIndex: visibleDayIndex,
                        };
                        const active = candidate.id === activeCandidateId;
                        const placeMissing = !candidate.place.trim();
                        const edit =
                          candidateEdit?.id === candidate.id ? candidateEdit : null;
                        const effective = edit ?? visibleCandidate;
                        const editing = !!edit;
                        return (
                          <Pressable
                            key={candidate.id}
                            delayLongPress={LONG_PRESS_MS}
                            onTouchStart={(event) =>
                              handleCandidateTouchStart(
                                event,
                                visibleCandidate,
                                "move",
                              )
                            }
                            onTouchMove={handleCandidateTouchMove}
                            onTouchEnd={handleCandidateTouchEnd}
                            onTouchCancel={clearCandidateTouch}
                            style={[
                              styles.candidateBlock,
                              active ? styles.candidateBlockActive : null,
                              placeMissing ? styles.candidateBlockMissing : null,
                              editing ? styles.candidateBlockEditing : null,
                              {
                                left:
                                  TIME_LABEL_WIDTH +
                                  effective.dayIndex * dayWidth +
                                  4,
                                top: calendarSlotTop(effective.startSlot) + 3,
                                width: dayWidth - 8,
                                height:
                                  Math.max(
                                    1,
                                    effective.endSlot - effective.startSlot,
                                  ) *
                                    SLOT_HEIGHT -
                                  6,
                              },
                            ]}
                          >
                            {placeMissing ? (
                              <View style={styles.candidateAlert}>
                                <Text style={styles.candidateAlertText}>!</Text>
                              </View>
                            ) : (
                              <Text numberOfLines={2} style={styles.candidatePlace}>
                                {candidate.place}
                              </Text>
                            )}
                            <Pressable
                              accessibilityLabel={`候補${index + 1}を削除`}
                              onPress={(event) => {
                                event.stopPropagation();
                                onDeleteCandidate(candidate.id);
                              }}
                              style={[
                                styles.candidateDelete,
                                placeMissing ? styles.candidateDeleteMissing : null,
                              ]}
                            >
                              <Text
                                style={[
                                  styles.candidateDeleteText,
                                  placeMissing
                                    ? styles.candidateDeleteTextMissing
                                    : null,
                                ]}
                              >
                                ×
                              </Text>
                            </Pressable>
                            <Pressable
                              accessibilityLabel={`候補${index + 1}の終了時間を変更`}
                              onTouchStart={(event) =>
                                handleCandidateTouchStart(
                                  event,
                                  visibleCandidate,
                                  "resize-end",
                                )
                              }
                              onTouchMove={handleCandidateTouchMove}
                              onTouchEnd={handleCandidateTouchEnd}
                              onTouchCancel={clearCandidateTouch}
                              style={[
                                styles.candidateResizeHandle,
                                placeMissing
                                  ? styles.candidateResizeHandleMissing
                                  : null,
                              ]}
                            />
                          </Pressable>
                        );
                      })
                    : null}

                  {isCurrentWeek && preview ? (
                    <View
                      pointerEvents="none"
                      style={[
                        styles.dragPreview,
                        {
                          left: TIME_LABEL_WIDTH + preview.dayIndex * dayWidth + 4,
                          top: calendarSlotTop(preview.startSlot) + 3,
                          width: dayWidth - 8,
                          height:
                            Math.max(1, preview.endSlot - preview.startSlot) *
                              SLOT_HEIGHT -
                            6,
                        },
                      ]}
                    />
                  ) : null}
                </View>
              </View>
            );
          })}
        </Animated.View>
      </ScrollView>

      {candidates.length === 0 && !preview ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.calendarHint,
            {
              opacity: hintPulse.interpolate({
                inputRange: [0, 1],
                outputRange: [0.92, 1],
              }),
              transform: [
                {
                  scale: hintPulse.interpolate({
                    inputRange: [0, 1],
                    outputRange: [1, 1.045],
                  }),
                },
              ],
            },
          ]}
        >
          <Text style={styles.calendarHintText}>
            長押しで時間帯を選択できるよ
          </Text>
        </Animated.View>
      ) : null}

      <PlaceSheet
        candidate={activeCandidate}
        previousCandidate={previousCandidate}
        onClose={onClosePlaceSheet}
        onUpdate={(patch) => {
          if (!activeCandidate) return;
          onUpdateCandidate(activeCandidate.id, patch);
        }}
      />
    </View>
  );
}

function PlaceSheet({
  candidate,
  previousCandidate,
  onClose,
  onUpdate,
}: {
  candidate: MeetupCandidate | null;
  previousCandidate: MeetupCandidate | null;
  onClose: () => void;
  onUpdate: (patch: Partial<MeetupCandidate>) => void;
}) {
  const [placeDraft, setPlaceDraft] = useState("");
  const [coordinateDraft, setCoordinateDraft] =
    useState<MapCoordinate>(FALLBACK_COORDINATE);
  const [placeSuggestions, setPlaceSuggestions] =
    useState<PlaceSuggestion[]>(PRESET_PLACES);
  const [resolvingPlace, setResolvingPlace] = useState(false);
  const [locationMessage, setLocationMessage] = useState<string | null>(null);
  const reverseRequestRef = useRef(0);

  useEffect(() => {
    if (!candidate) return;
    setPlaceDraft(candidate.place);
    setCoordinateDraft(candidate.coordinate);
    setPlaceSuggestions(
      candidate.place.trim()
        ? buildPlaceSuggestions(candidate.coordinate, candidate.place)
        : PRESET_PLACES,
    );
    setLocationMessage(null);
  }, [candidate]);

  if (!candidate) return null;

  function applyPreset(index: number) {
    const preset =
      placeSuggestions[index] ?? placeSuggestions[0] ?? PRESET_PLACES[0];
    setPlaceDraft(preset.label);
    setCoordinateDraft(preset.coordinate);
    setPlaceSuggestions(buildPlaceSuggestions(preset.coordinate, preset.label));
    setLocationMessage(null);
  }

  function confirm() {
    onUpdate({
      place:
        placeDraft.trim() ||
        placeSuggestions[0]?.label ||
        PRESET_PLACES[0].label,
      coordinate: coordinateDraft,
    });
    onClose();
  }

  async function resolvePlaceForCoordinate(
    coordinate: MapCoordinate,
    options: { fallbackLabel?: string } = {},
  ) {
    const requestId = reverseRequestRef.current + 1;
    reverseRequestRef.current = requestId;
    setResolvingPlace(true);
    setLocationMessage(null);
    try {
      const ExpoLocation = await import("expo-location");
      const addresses = await ExpoLocation.reverseGeocodeAsync(coordinate);
      if (reverseRequestRef.current !== requestId) return;
      const address = addresses[0];
      const label =
        labelFromGeocodedAddress(address) ??
        options.fallbackLabel ??
        coordinateLabel(coordinate);
      setPlaceDraft(label);
      setPlaceSuggestions(buildPlaceSuggestions(coordinate, label, address));
    } catch {
      if (reverseRequestRef.current !== requestId) return;
      const label = options.fallbackLabel ?? coordinateLabel(coordinate);
      setPlaceDraft(label);
      setPlaceSuggestions(buildPlaceSuggestions(coordinate, label));
      setLocationMessage("場所名を取得できませんでした");
    } finally {
      if (reverseRequestRef.current === requestId) {
        setResolvingPlace(false);
      }
    }
  }

  async function useCurrentLocation() {
    setLocationMessage(null);
    setResolvingPlace(true);
    try {
      const ExpoLocation = await import("expo-location");
      const permission = await ExpoLocation.requestForegroundPermissionsAsync();
      if (permission.status !== "granted") {
        setResolvingPlace(false);
        setLocationMessage("位置情報の許可が必要です");
        return;
      }
      const current = await ExpoLocation.getCurrentPositionAsync({
        accuracy: ExpoLocation.Accuracy.Balanced,
      });
      const coordinate = {
        latitude: current.coords.latitude,
        longitude: current.coords.longitude,
      };
      setCoordinateDraft(coordinate);
      setPlaceDraft("");
      setPlaceSuggestions(buildPlaceSuggestions(coordinate, "現在地周辺"));
      await resolvePlaceForCoordinate(coordinate, {
        fallbackLabel: "現在地周辺",
      });
    } catch {
      setResolvingPlace(false);
      setLocationMessage("現在地を取得できませんでした");
    }
  }

  function handleMapPress(coordinate: MapCoordinate) {
    setCoordinateDraft(coordinate);
    setPlaceDraft("");
    setPlaceSuggestions(buildPlaceSuggestions(coordinate, "選択した場所"));
    void resolvePlaceForCoordinate(coordinate, {
      fallbackLabel: "選択した場所",
    });
  }

  const nativeSheet = Platform.OS === "ios";
  const sheetContent = (
    <Pressable style={[styles.placeSheet, nativeSheet ? styles.placeNativeSheet : null]}>
          <View style={styles.placeHandle} />
          <View style={styles.placeHeader}>
            <View>
              <Text style={styles.placeKicker}>
                {formatCandidateRange(candidate)}
              </Text>
              <Text style={styles.placeTitle}>交換できる場所</Text>
            </View>
            <Pressable onPress={onClose} style={styles.placeClose}>
              <Text style={styles.placeCloseText}>×</Text>
            </Pressable>
          </View>

          <View style={styles.placeActions}>
            <Pressable onPress={useCurrentLocation} style={styles.placeAction}>
              <Text style={styles.placeActionText}>
                {resolvingPlace ? "取得中…" : "現在地を中心に"}
              </Text>
            </Pressable>
            <Pressable
              disabled={!previousCandidate}
              onPress={() => {
                if (!previousCandidate) return;
                setPlaceDraft(previousCandidate.place);
                setCoordinateDraft(previousCandidate.coordinate);
                setPlaceSuggestions(
                  buildPlaceSuggestions(
                    previousCandidate.coordinate,
                    previousCandidate.place,
                  ),
                );
                setLocationMessage("前の設定を適用しました");
              }}
              style={[
                styles.placeAction,
                styles.placeActionStrong,
                !previousCandidate ? styles.placeActionDisabled : null,
              ]}
            >
              <Text style={styles.placeActionStrongText}>前の設定と同じに</Text>
            </Pressable>
          </View>

          <TextInput
            value={placeDraft}
            onChangeText={(text) => {
              setPlaceDraft(text);
              setLocationMessage(null);
            }}
            placeholder={resolvingPlace ? "取得中…" : "交換できる場所"}
            placeholderTextColor="rgba(58,50,74,0.34)"
            style={styles.placeInput}
          />
          {locationMessage ? (
            <Text style={styles.placeMessage}>{locationMessage}</Text>
          ) : null}

          <View style={styles.placeMapWrap}>
            <NativeMapPreview
              key={`${coordinateDraft.latitude.toFixed(6)}-${coordinateDraft.longitude.toFixed(
                6,
              )}`}
              center={coordinateDraft}
              markers={[
                {
                  id: "selected",
                  coordinate: coordinateDraft,
                  label: "!",
                  title: placeDraft || "交換できる場所",
                },
              ]}
              interactive
              height={210}
              onPress={handleMapPress}
            />
          </View>

          <View style={styles.placePresetRow}>
            {placeSuggestions.slice(0, 2).map((preset, index) => (
              <Pressable
                key={`${preset.label}-${index}`}
                onPress={() => applyPreset(index)}
                style={styles.placePreset}
              >
                <Text numberOfLines={1} style={styles.placePresetText}>
                  {preset.label}
                </Text>
              </Pressable>
            ))}
          </View>

          <PrimaryButton onPress={confirm}>この場所にする</PrimaryButton>
    </Pressable>
  );

  return (
    <Modal
      visible
      transparent={!nativeSheet}
      animationType="slide"
      presentationStyle={nativeSheet ? "pageSheet" : "overFullScreen"}
      onRequestClose={onClose}
    >
      {nativeSheet ? (
        <View style={styles.placeNativeSheetRoot}>{sheetContent}</View>
      ) : (
        <Pressable style={styles.placeBackdrop} onPress={onClose}>
          {sheetContent}
      </Pressable>
      )}
    </Modal>
  );
}

function buildMeetupDays(weekOffset = 0): MeetupDay[] {
  const weekday = ["日", "月", "火", "水", "木", "金", "土"];
  const now = new Date();
  const base = new Date(now);
  base.setDate(now.getDate() + weekOffset * 5);
  const todayKey = dateKey(now);
  return Array.from({ length: 5 }, (_, index) => {
    const date = new Date(base);
    date.setDate(base.getDate() + index);
    return {
      id: dateKey(date),
      day: weekday[date.getDay()] ?? "",
      date: String(date.getDate()),
      month: `${date.getMonth() + 1}月`,
      isToday: dateKey(date) === todayKey,
    };
  });
}

function dateKey(date: Date) {
  return [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0"),
  ].join("-");
}

function slotFromLocationY(locationY: number) {
  return slotFromCalendarY(locationY);
}

function slotFromCalendarY(calendarY: number) {
  const raw = Math.floor((calendarY - CALENDAR_TOP_PADDING) / SLOT_HEIGHT);
  return Math.max(0, Math.min(SLOT_COUNT - 1, raw));
}

function normalizedDraftRange(draft: DragDraft) {
  const startSlot = Math.min(draft.startSlot, draft.currentSlot);
  const endSlot = Math.max(draft.startSlot, draft.currentSlot) + 1;
  return {
    startSlot: Math.max(0, Math.min(SLOT_COUNT - 1, startSlot)),
    endSlot: Math.max(1, Math.min(SLOT_COUNT, endSlot)),
  };
}

function calendarSlotTop(slot: number) {
  return CALENDAR_TOP_PADDING + slot * SLOT_HEIGHT;
}

function formatSlot(slot: number) {
  const minutes = Math.max(0, Math.min(24 * 60, slot * SLOT_MINUTES));
  const hour = Math.floor(minutes / 60);
  const minute = minutes % 60;
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function slotToIso(dateId: string, slot: number) {
  return new Date(`${dateId}T${formatSlot(slot)}:00+09:00`).toISOString();
}

function formatCandidateRange(candidate: MeetupCandidate) {
  return `${formatCandidateDate(candidate.dateId)} ${formatSlot(candidate.startSlot)} - ${formatSlot(candidate.endSlot)}`;
}

function formatCandidateDate(dateId: string) {
  const date = new Date(`${dateId}T00:00:00+09:00`);
  if (Number.isNaN(date.getTime())) return "";
  return `${date.getMonth() + 1}月${date.getDate()}日`;
}

function labelFromGeocodedAddress(
  address?: LocationGeocodedAddress | null,
) {
  if (!address) return null;
  const main =
    cleanAddressPart(address.name) ||
    cleanAddressPart(address.street) ||
    cleanAddressPart(address.district) ||
    cleanAddressPart(address.city) ||
    cleanAddressPart(address.region) ||
    cleanAddressPart(address.formattedAddress);
  return main;
}

function buildPlaceSuggestions(
  coordinate: MapCoordinate,
  label: string,
  address?: LocationGeocodedAddress | null,
): PlaceSuggestion[] {
  const primaryLabel = label.trim() || coordinateLabel(coordinate);
  const secondaryLabel =
    [
      cleanAddressPart(address?.district),
      cleanAddressPart(address?.city),
      cleanAddressPart(address?.region),
    ]
      .filter(Boolean)
      .join(" ") || "このピン周辺";
  const suggestions: PlaceSuggestion[] = [
    {
      label: primaryLabel,
      coordinate,
    },
    {
      label:
        secondaryLabel === primaryLabel
          ? `${primaryLabel} 周辺`
          : secondaryLabel,
      coordinate,
    },
  ];
  return suggestions.filter(
    (suggestion, index, array) =>
      array.findIndex((item) => item.label === suggestion.label) === index,
  );
}

function cleanAddressPart(value?: string | null) {
  const cleaned = value?.trim();
  return cleaned && cleaned !== "Unnamed Road" ? cleaned : null;
}

function coordinateLabel(coordinate: MapCoordinate) {
  return `選択地点 ${coordinate.latitude.toFixed(5)}, ${coordinate.longitude.toFixed(5)}`;
}

function one(value?: string | string[]) {
  if (Array.isArray(value)) {
    return value[0];
  }
  return value;
}

function parseTab(value?: string): ProposalTab {
  if (value === "receive" || value === "meetup") {
    return value;
  }
  return "give";
}

function exchangeMethodToIndex(method: ExchangeMethod) {
  if (method === "mail") return 1;
  if (method === "both") return 2;
  return 0;
}

function exchangeMethodFromIndex(index: number): ExchangeMethod {
  if (index === 1) return "mail";
  if (index === 2) return "both";
  return "hand";
}

async function buildLocalModeAutoMeetupCandidate(): Promise<MeetupCandidate | null> {
  if (!supabase) return null;
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: settingsData, error: settingsError } = await supabase
    .from("user_local_mode_settings")
    .select("enabled, aw_id, last_lat, last_lng")
    .eq("user_id", user.id)
    .maybeSingle();
  if (settingsError) return null;

  const settings = settingsData as LocalModeSettingsRow | null;
  if (!settings?.enabled) return null;

  const activityWindow = await fetchLocalModeActivityWindow(
    user.id,
    settings.aw_id,
  );
  const locationDraft = await getCurrentLocationDraft();
  const coordinate =
    locationDraft?.coordinate ??
    coordinateFromValues(settings.last_lat, settings.last_lng) ??
    coordinateFromValues(
      activityWindow?.center_lat ?? null,
      activityWindow?.center_lng ?? null,
    ) ??
    FALLBACK_COORDINATE;
  const range = buildCurrentMeetupRange(new Date());
  return {
    id: `candidate-auto-${Date.now()}`,
    ...range,
    place:
      locationDraft?.label ??
      cleanAddressPart(activityWindow?.venue) ??
      "現在地周辺",
    coordinate,
  };
}

async function fetchLocalModeActivityWindow(
  userId: string,
  awId?: string | null,
): Promise<ActivityWindowLocationRow | null> {
  if (!supabase) return null;
  let query = supabase
    .from("activity_windows")
    .select("id, venue, center_lat, center_lng, start_at, end_at")
    .eq("user_id", userId)
    .eq("status", "enabled")
    .limit(1);
  query = awId
    ? query.eq("id", awId)
    : query.order("start_at", { ascending: true });

  const { data, error } = await query;
  if (error) return null;
  return ((data as ActivityWindowLocationRow[] | null) ?? [])[0] ?? null;
}

async function getCurrentLocationDraft(): Promise<{
  coordinate: MapCoordinate;
  label: string | null;
} | null> {
  try {
    const ExpoLocation = await import("expo-location");
    const permission = await ExpoLocation.requestForegroundPermissionsAsync();
    if (permission.status !== "granted") return null;
    const current = await ExpoLocation.getCurrentPositionAsync({
      accuracy: ExpoLocation.Accuracy.Balanced,
    });
    const coordinate = {
      latitude: current.coords.latitude,
      longitude: current.coords.longitude,
    };
    let label: string | null = null;
    try {
      const addresses = await ExpoLocation.reverseGeocodeAsync(coordinate);
      label = labelFromGeocodedAddress(addresses[0]);
    } catch {
      label = null;
    }
    return {
      coordinate,
      label: label ?? "現在地周辺",
    };
  } catch {
    return null;
  }
}

function coordinateFromValues(
  latitude: number | string | null,
  longitude: number | string | null,
): MapCoordinate | null {
  const lat = Number(latitude);
  const lng = Number(longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  return { latitude: lat, longitude: lng };
}

function buildCurrentMeetupRange(now: Date) {
  const dateId = dateKey(now);
  const dayIndex = Math.max(
    0,
    DAYS.findIndex((day) => day.id === dateId),
  );
  const minutes = now.getHours() * 60 + now.getMinutes();
  const startSlot = Math.max(
    0,
    Math.min(SLOT_COUNT - 1, Math.floor(minutes / SLOT_MINUTES)),
  );
  const durationSlots = Math.max(1, Math.round(30 / SLOT_MINUTES));
  return {
    dateId: DAYS[dayIndex]?.id ?? dateId,
    dayIndex,
    startSlot,
    endSlot: Math.max(
      startSlot + 1,
      Math.min(SLOT_COUNT, startSlot + durationSlots),
    ),
  };
}

function safeStringArray(value: unknown): string[] {
  return Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string")
    : [];
}

function uniqueStrings(values: string[]) {
  return Array.from(new Set(values.filter(Boolean)));
}

function parseRevisionMeetupCandidates(
  row: RevisionProposalRow,
): MeetupCandidate[] {
  const fromJson = Array.isArray(row.meetup_candidates)
    ? row.meetup_candidates
        .map((raw, index) => meetupCandidateFromRaw(raw, index))
        .filter((candidate): candidate is MeetupCandidate => !!candidate)
    : [];
  if (fromJson.length > 0) return fromJson.slice(0, 3);
  const legacyCandidate = meetupCandidateFromRaw(
    {
      startAt: row.meetup_start_at,
      endAt: row.meetup_end_at,
      placeName: row.meetup_place_name,
      lat: row.meetup_lat,
      lng: row.meetup_lng,
    },
    0,
  );
  return legacyCandidate ? [legacyCandidate] : [];
}

function meetupCandidateFromRaw(
  value: unknown,
  index: number,
): MeetupCandidate | null {
  if (!value || typeof value !== "object") return null;
  const raw = value as Record<string, unknown>;
  const startAt = typeof raw.startAt === "string" ? raw.startAt : null;
  const endAt = typeof raw.endAt === "string" ? raw.endAt : null;
  const place =
    typeof raw.placeName === "string"
      ? raw.placeName
      : typeof raw.place === "string"
        ? raw.place
        : "";
  if (!startAt || !endAt) return null;
  const dateId = dateIdFromIso(startAt);
  const dayIndex = Math.max(
    0,
    DAYS.findIndex((day) => day.id === dateId),
  );
  const latitude = Number(raw.lat ?? raw.latitude);
  const longitude = Number(raw.lng ?? raw.longitude);
  const startSlot = slotFromIso(startAt);
  return {
    id: typeof raw.id === "string" ? raw.id : `candidate-${index + 1}`,
    dateId,
    dayIndex,
    startSlot,
    endSlot: Math.max(startSlot + 1, Math.min(SLOT_COUNT, slotFromIso(endAt))),
    place,
    coordinate: {
      latitude: Number.isFinite(latitude)
        ? latitude
        : FALLBACK_COORDINATE.latitude,
      longitude: Number.isFinite(longitude)
        ? longitude
        : FALLBACK_COORDINATE.longitude,
    },
  };
}

function dateIdFromIso(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return DAYS[0].id;
  const jst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  return [
    jst.getUTCFullYear(),
    String(jst.getUTCMonth() + 1).padStart(2, "0"),
    String(jst.getUTCDate()).padStart(2, "0"),
  ].join("-");
}

function slotFromIso(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 0;
  const jst = new Date(date.getTime() + 9 * 60 * 60 * 1000);
  const minutes = jst.getUTCHours() * 60 + jst.getUTCMinutes();
  return Math.max(0, Math.min(SLOT_COUNT, Math.round(minutes / SLOT_MINUTES)));
}

function hasSendableInventoryIds(ids: string[]) {
  return ids.length > 0 && ids.every(isUuid);
}

function ensureChoiceSelection(
  current: string[],
  choices: ProposalChoiceItem[],
) {
  const choiceIds = new Set(choices.map((choice) => choice.id));
  const valid = current.filter((id) => choiceIds.has(id));
  if (valid.length > 0) return valid;
  return choices[0] ? [choices[0].id] : [];
}

function toggleChoiceId(current: string[], id: string) {
  if (current.includes(id)) {
    return current.length > 1
      ? current.filter((selectedId) => selectedId !== id)
      : current;
  }
  return [...current, id];
}

const styles = StyleSheet.create({
  screen: {
    gap: 12,
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
  },
  backButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 42,
    justifyContent: "center",
    width: 42,
    ...megrumShadow,
  },
  backText: {
    color: megrumColors.ink,
    fontSize: 31,
    fontWeight: "700",
    lineHeight: 33,
  },
  headerText: {
    flex: 1,
  },
  kicker: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
    letterSpacing: 0.7,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 23,
    fontWeight: "900",
    lineHeight: 28,
  },
  paneHost: {
    flex: 1,
  },
  methodCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 10,
    padding: 14,
    ...megrumShadow,
  },
  methodHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  methodTitle: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "900",
  },
  methodSub: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  methodHint: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 17,
  },
  choiceList: {
    gap: 10,
    paddingBottom: 18,
  },
  choiceState: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.74)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    justifyContent: "center",
    minHeight: 168,
    padding: 18,
  },
  choiceStateText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 20,
    textAlign: "center",
  },
  choiceCard: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    flexDirection: "row",
    gap: 12,
    padding: 10,
  },
  choiceCardSelected: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderColor: "rgba(166,149,216,0.48)",
  },
  choiceImage: {
    alignItems: "center",
    borderRadius: 15,
    height: 82,
    justifyContent: "center",
    overflow: "hidden",
    width: 66,
  },
  choicePhoto: {
    height: "100%",
    width: "100%",
  },
  choiceShine: {
    backgroundColor: "rgba(255,255,255,0.25)",
    borderRadius: 999,
    height: 56,
    position: "absolute",
    right: -12,
    top: -10,
    width: 56,
  },
  choiceGlyph: {
    color: megrumColors.surface,
    fontSize: 27,
    fontWeight: "900",
  },
  choiceCopy: {
    flex: 1,
  },
  choiceTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  choiceSubtitle: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 3,
  },
  choiceHint: {
    alignSelf: "flex-start",
    backgroundColor: "rgba(168,212,230,0.22)",
    borderRadius: megrumRadii.pill,
    marginTop: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  choiceHintText: {
    color: "#3a7c93",
    fontSize: 10,
    fontWeight: "900",
  },
  checkCircle: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.16)",
    borderRadius: 999,
    borderWidth: 1,
    height: 26,
    justifyContent: "center",
    width: 26,
  },
  checkCircleOn: {
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.lavender,
  },
  checkText: {
    color: "transparent",
    fontSize: 14,
    fontWeight: "900",
  },
  checkTextOn: {
    color: megrumColors.surface,
  },
  meetupRoot: {
    backgroundColor: megrumColors.surface,
    borderTopColor: "rgba(58,50,74,0.08)",
    borderTopWidth: 1,
    flex: 1,
    overflow: "hidden",
    position: "relative",
  },
  daysViewport: {
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: 1,
    overflow: "hidden",
  },
  weekPager: {
    flexDirection: "row",
  },
  weekPage: {
    flexDirection: "row",
  },
  dayTimeSpacer: {
    width: TIME_LABEL_WIDTH,
  },
  dayCell: {
    alignItems: "center",
    flex: 1,
    paddingBottom: 9,
    paddingTop: 7,
  },
  dayCellToday: {
    backgroundColor: "rgba(166,149,216,0.10)",
  },
  dayName: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  dayNameToday: {
    color: megrumColors.lavender,
  },
  dayDate: {
    color: megrumColors.ink,
    fontSize: 24,
    fontWeight: "900",
    marginTop: 2,
  },
  dayDateToday: {
    color: megrumColors.lavender,
  },
  calendarContent: {
    paddingBottom: 36,
  },
  calendarGrid: {
    position: "relative",
  },
  calendarPage: {
    position: "relative",
  },
  timeAxis: {
    bottom: 0,
    left: 0,
    position: "absolute",
    top: 0,
  },
  hourLabel: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    position: "absolute",
    textAlign: "center",
    width: TIME_LABEL_WIDTH,
  },
  dayColumn: {
    borderLeftColor: "rgba(58,50,74,0.07)",
    borderLeftWidth: 1,
    bottom: 0,
    position: "absolute",
    top: 0,
  },
  calendarCell: {
    borderBottomColor: "rgba(58,50,74,0.055)",
    borderBottomWidth: 1,
    position: "absolute",
    width: "100%",
  },
  dragPreview: {
    backgroundColor: "rgba(36,167,242,0.20)",
    borderColor: "rgba(36,167,242,0.65)",
    borderRadius: 11,
    borderWidth: 1,
    position: "absolute",
  },
  candidateBlock: {
    alignItems: "center",
    backgroundColor: "rgba(75,151,224,0.22)",
    borderColor: "rgba(75,151,224,0.54)",
    borderRadius: 13,
    borderWidth: 1,
    justifyContent: "center",
    overflow: "hidden",
    position: "absolute",
    shadowColor: "#4b97e0",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.12,
    shadowRadius: 14,
  },
  candidateBlockActive: {
    borderColor: "rgba(166,149,216,0.88)",
    shadowColor: megrumColors.lavender,
    shadowOpacity: 0.2,
  },
  candidateBlockEditing: {
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 16 },
    shadowOpacity: 0.24,
    shadowRadius: 22,
    transform: [{ translateY: -4 }, { scale: 1.03 }],
    zIndex: 30,
  },
  candidateBlockMissing: {
    backgroundColor: "rgba(75,151,224,0.12)",
    borderColor: "rgba(230,149,67,0.58)",
    borderStyle: "dashed",
  },
  candidateAlert: {
    alignItems: "center",
    backgroundColor: "#f29d4b",
    borderRadius: 999,
    height: 25,
    justifyContent: "center",
    width: 25,
  },
  candidateAlertText: {
    color: megrumColors.surface,
    fontSize: 16,
    fontWeight: "900",
    lineHeight: 18,
    textAlign: "center",
  },
  candidatePlace: {
    color: "#256aa8",
    fontSize: 10.5,
    fontWeight: "900",
    lineHeight: 14,
    paddingHorizontal: 5,
    textAlign: "center",
  },
  candidateDelete: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.82)",
    borderRadius: 999,
    height: 20,
    justifyContent: "center",
    position: "absolute",
    right: 4,
    top: 4,
    width: 20,
  },
  candidateDeleteMissing: {
    backgroundColor: "rgba(242,157,75,0.16)",
  },
  candidateDeleteText: {
    color: "#256aa8",
    fontSize: 14,
    fontWeight: "900",
    lineHeight: 15,
  },
  candidateDeleteTextMissing: {
    color: "#d98232",
  },
  candidateResizeHandle: {
    backgroundColor: "rgba(255,255,255,0.62)",
    borderRadius: 999,
    bottom: 3,
    height: 5,
    left: 10,
    position: "absolute",
    right: 10,
  },
  candidateResizeHandleMissing: {
    backgroundColor: "rgba(242,157,75,0.48)",
  },
  calendarHint: {
    alignItems: "center",
    alignSelf: "center",
    backgroundColor: "rgba(24,22,32,0.34)",
    borderRadius: 999,
    justifyContent: "center",
    left: "50%",
    marginLeft: -110,
    marginTop: -24,
    paddingHorizontal: 18,
    paddingVertical: 12,
    position: "absolute",
    top: "46%",
    width: 220,
    zIndex: 40,
  },
  calendarHintText: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
    textAlign: "center",
  },
  placeBackdrop: {
    backgroundColor: "rgba(18,16,26,0.34)",
    flex: 1,
    justifyContent: "flex-end",
  },
  placeNativeSheetRoot: {
    backgroundColor: megrumColors.background,
    flex: 1,
    padding: 16,
  },
  placeSheet: {
    backgroundColor: megrumColors.surface,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    gap: 12,
    paddingBottom: 24,
    paddingHorizontal: 18,
    paddingTop: 10,
  },
  placeNativeSheet: {
    backgroundColor: megrumColors.background,
    borderTopLeftRadius: 0,
    borderTopRightRadius: 0,
    paddingHorizontal: 0,
  },
  placeHandle: {
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.18)",
    borderRadius: 999,
    height: 4,
    width: 42,
  },
  placeHeader: {
    alignItems: "flex-start",
    flexDirection: "row",
    gap: 12,
    justifyContent: "space-between",
  },
  placeKicker: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  placeTitle: {
    color: megrumColors.ink,
    fontSize: 21,
    fontWeight: "900",
    marginTop: 2,
  },
  placeClose: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    height: 34,
    justifyContent: "center",
    width: 34,
  },
  placeCloseText: {
    color: megrumColors.mutedInk,
    fontSize: 21,
    fontWeight: "900",
    lineHeight: 22,
  },
  placeActions: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
  },
  placeAction: {
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  placeActionText: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  placeActionStrong: {
    backgroundColor: "rgba(166,149,216,0.14)",
    borderColor: "rgba(166,149,216,0.28)",
    borderWidth: 1,
    marginLeft: "auto",
  },
  placeActionStrongText: {
    color: megrumColors.lavender,
    fontSize: 11.5,
    fontWeight: "900",
  },
  placeActionDisabled: {
    opacity: 0.45,
  },
  placeInput: {
    backgroundColor: "rgba(58,50,74,0.045)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 14,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "800",
    paddingHorizontal: 12,
    paddingVertical: 11,
  },
  placeMessage: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: -4,
  },
  placeMapWrap: {
    borderRadius: 18,
    overflow: "hidden",
  },
  placePresetRow: {
    flexDirection: "row",
    gap: 8,
  },
  placePreset: {
    backgroundColor: "rgba(168,212,230,0.16)",
    borderRadius: megrumRadii.pill,
    flex: 1,
    paddingHorizontal: 10,
    paddingVertical: 9,
  },
  placePresetText: {
    color: "#3478c7",
    fontSize: 11,
    fontWeight: "900",
    textAlign: "center",
  },
});
