"use client";

import dynamic from "next/dynamic";
import {
  type MouseEvent,
  type PointerEvent,
  type TouchEvent,
  useEffect,
  useMemo,
  useRef,
  useState,
  useTransition,
} from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { PrimaryButton } from "@/components/auth/PrimaryButton";
import { createProposal, reviseProposal } from "../actions";

/* 提示物の選択フローでは MapTiler Streets を使う（SDK が window 必要） */
const ProposeMapPicker = dynamic(() => import("@/components/map/MapTilerPicker"), {
  ssr: false,
  loading: () => (
    <div className="flex h-full w-full items-center justify-center bg-[#e8eef0] text-[11px] text-[#3a324a8c]">
      地図を読み込み中…
    </div>
  ),
});

type MapPreviewMarker = {
  center: [number, number];
  label: string;
};

/* ─── types ─────────────────────────────────────────────── */

export type ProposeInv = {
  id: string;
  title: string;
  quantity: number;
  photoUrl: string | null;
  groupId: string | null;
  characterId: string | null;
  goodsTypeId: string;
  groupName: string | null;
  characterName: string | null;
  goodsTypeName: string | null;
  /** 相手 wish にヒット（mine 側）/ 自分 wish にヒット（theirs 側） */
  wishMatch?: boolean;
};

type Partner = {
  id: string;
  handle: string;
  displayName: string;
  primaryArea: string | null;
  localModeEnabled: boolean;
  localModeAW: {
    venue: string;
    centerLat: number | null;
    centerLng: number | null;
    startAt: string; // ISO
    endAt: string; // ISO
  } | null;
};

type Selectable = ProposeInv & {
  selected: boolean;
  selectedQty: number;
};
type MeetupMode = "today" | "scheduled";
type MeetupCandidate = {
  id: string;
  mode: MeetupMode;
  start: string;
  end: string;
  place: string;
  center: [number, number];
};
type MeetupCandidatePayload = {
  startAt: string;
  endAt: string;
  placeName: string;
  lat: number;
  lng: number;
  mode: MeetupMode;
};
type MeetupDragSelection = {
  dayIndex: number;
  startSlot: number;
  currentSlot: number;
};
type MeetupCandidateEdit = {
  id: string;
  action: "move" | "resize-end";
  originalDayIndex: number;
  dayIndex: number;
  startSlot: number;
  endSlot: number;
};
type MeetupCandidatePointerState = {
  id: string;
  action: "move" | "resize-end";
  pointerId: number;
  pointerType: string;
  startX: number;
  startY: number;
  originalDayIndex: number;
  originalStartSlot: number;
  originalEndSlot: number;
  pointerStartOffsetSlots: number;
  mode: "pending" | "editing";
  timer: number | null;
};

// iter138: "message" step は廃止（confirm でメッセージ入力可）
type Step = "select" | "confirm";
type Tab = "mine" | "theirs" | "meetup";
const PROPOSE_TAB_ORDER: Tab[] = ["mine", "theirs", "meetup"];

type Props = {
  partner: Partner;
  myInv: ProposeInv[];
  theirInv: ProposeInv[];
  matchType: "perfect" | "forward" | "backward";
  initialTab?: Tab;
  /** iter67.7：listing/option 経由打診の初期値プリフィル
   *  iter70-C：再打診の元 proposal id・既存 meetup・message も載せられる */
  initial?: {
    senderHaveIds: string[];
    senderHaveQtys: number[];
    receiverHaveIds: string[];
    receiverHaveQtys: number[];
    cashOffer?: { amount: number };
    listingId?: string;
    reviseFromProposalId?: string;
    meetupStartAt?: string;
    meetupEndAt?: string;
    meetupPlaceName?: string;
    meetupLat?: number;
    meetupLng?: number;
    meetupCandidates?: MeetupCandidatePayload[];
    message?: string;
  };
};

/* Tokyo Station fallback */
const FALLBACK_CENTER: [number, number] = [35.6812, 139.7671];
const MAX_MEETUP_CANDIDATES = 3;
const MEETUP_WEEK_DAYS = 5;
const MEETUP_CALENDAR_START_HOUR = 0;
const MEETUP_CALENDAR_END_HOUR = 24;
const MEETUP_SLOT_MINUTES = 15;
const MEETUP_SLOT_HEIGHT = 10;
const MEETUP_LONG_PRESS_MS = 320;
const MEETUP_TOUCH_CANCEL_PX = 10;
const MEETUP_SLOT_COUNT =
  ((MEETUP_CALENDAR_END_HOUR - MEETUP_CALENDAR_START_HOUR) * 60) /
  MEETUP_SLOT_MINUTES;
const MEETUP_TIMELINE_HEIGHT = MEETUP_SLOT_COUNT * MEETUP_SLOT_HEIGHT;
const MEETUP_CALENDAR_TOP_PADDING = 18;
const MEETUP_CALENDAR_BOTTOM_PADDING = 88;
const MEETUP_CALENDAR_DEFAULT_SCROLL_HOUR = 10;
const MEETUP_TIME_LABEL_WIDTH = 52;

type Place = { display_name: string; lat: string; lon: string; address?: Record<string, string> };

/* ─── helpers ───────────────────────────────────────────── */

function formatTokyoLocalFromDate(date: Date): string {
  const parts = new Intl.DateTimeFormat("ja-JP-u-ca-gregory", {
    timeZone: "Asia/Tokyo",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const get = (type: string) =>
    parts.find((part) => part.type === type)?.value ?? "00";
  return `${get("year")}-${get("month")}-${get("day")}T${get("hour")}:${get("minute")}`;
}

function parseTokyoLocal(s: string): Date {
  const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/.exec(s);
  if (!m) return new Date(s);
  const [, y, mo, d, h, mi] = m;
  return new Date(
    Date.UTC(
      Number(y),
      Number(mo) - 1,
      Number(d),
      Number(h) - 9,
      Number(mi),
    ),
  );
}

function roundUpTokyoLocal(minutes = 30, base = new Date()): string {
  const d = new Date(base.getTime());
  const next = Math.ceil(d.getMinutes() / minutes) * minutes;
  d.setMinutes(next, 0, 0);
  return formatTokyoLocalFromDate(d);
}

function addDaysToDateKey(dateKey: string, days: number): string {
  const [year, month, day] = dateKey.split("-").map(Number);
  const d = new Date(Date.UTC(year, month - 1, day + days));
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}-${String(d.getUTCDate()).padStart(2, "0")}`;
}

function buildMeetupWeekDateKeys(anchorLocal?: string): string[] {
  const anchorDateKey = (anchorLocal || roundUpTokyoLocal()).slice(0, 10);
  return Array.from({ length: MEETUP_WEEK_DAYS }, (_, index) =>
    addDaysToDateKey(anchorDateKey, index),
  );
}

function buildMeetupWeekDateKeysFromDateKey(dateKey: string): string[] {
  return Array.from({ length: MEETUP_WEEK_DAYS }, (_, index) =>
    addDaysToDateKey(dateKey, index),
  );
}

function formatDateKeyWeekday(dateKey: string): string {
  const [year, month, day] = dateKey.split("-").map(Number);
  const d = new Date(Date.UTC(year, month - 1, day));
  return "日月火水木金土"[d.getUTCDay()];
}

function formatDateKeyDayNumber(dateKey: string): string {
  const [, , day] = dateKey.split("-");
  return String(Number(day));
}

function slotToTokyoLocal(dateKey: string, slot: number): string {
  const minutes =
    MEETUP_CALENDAR_START_HOUR * 60 + slot * MEETUP_SLOT_MINUTES;
  const hour = Math.floor(minutes / 60);
  const minute = minutes % 60;
  return `${dateKey}T${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function nowTokyoParts() {
  const p = splitTokyoLocal(formatTokyoLocalFromDate(new Date()));
  if (!p) return null;
  return {
    ...p,
    minutes: Number(p.h) * 60 + Number(p.mi),
  };
}

function localToCalendarSlot(local: string): number | null {
  const p = splitTokyoLocal(local);
  if (!p) return null;
  const minutes = Number(p.h) * 60 + Number(p.mi);
  return Math.round(
    (minutes - MEETUP_CALENDAR_START_HOUR * 60) / MEETUP_SLOT_MINUTES,
  );
}

function calendarSlotTop(slot: number): number {
  return MEETUP_CALENDAR_TOP_PADDING + slot * MEETUP_SLOT_HEIGHT;
}

function calendarClientYToSlot(clientY: number, rectTop: number): number {
  const y = Math.max(
    0,
    Math.min(
      MEETUP_TIMELINE_HEIGHT + MEETUP_CALENDAR_BOTTOM_PADDING - 1,
      clientY - rectTop - MEETUP_CALENDAR_TOP_PADDING,
    ),
  );
  return Math.max(
    0,
    Math.min(MEETUP_SLOT_COUNT - 1, Math.floor(y / MEETUP_SLOT_HEIGHT)),
  );
}

function candidateHasTime(candidate: MeetupCandidate): boolean {
  return (
    !!candidate.start &&
    !!candidate.end &&
    new Date(localToIso(candidate.end)) > new Date(localToIso(candidate.start))
  );
}

function candidateHasAnyInput(candidate: MeetupCandidate): boolean {
  return candidateHasTime(candidate) || !!candidate.place.trim();
}

/** ISO → JST datetime-local（YYYY-MM-DDTHH:mm） */
function isoToLocal(iso: string): string {
  return formatTokyoLocalFromDate(new Date(iso));
}
/** JST datetime-local → ISO */
function localToIso(s: string): string {
  if (!s) return "";
  return parseTokyoLocal(s).toISOString();
}
/** wishMatch を先頭にソート（同フラグ内は元の順） */
function sortByWishFirst<T extends { wishMatch?: boolean }>(arr: T[]): T[] {
  return [...arr].sort((a, b) => {
    const aw = a.wishMatch ? 1 : 0;
    const bw = b.wishMatch ? 1 : 0;
    return bw - aw;
  });
}

/**
 * iter110: 関係図で選んだ項目（preselectedIds に含まれる）を最上位、
 * 次に wishMatch、次に残り の順でソート
 */
function sortBySelectionFirst<T extends { id: string; wishMatch?: boolean }>(
  arr: T[],
  preselectedIds: Set<string>,
): T[] {
  return [...arr].sort((a, b) => {
    const aSel = preselectedIds.has(a.id) ? 1 : 0;
    const bSel = preselectedIds.has(b.id) ? 1 : 0;
    if (aSel !== bSel) return bSel - aSel;
    const aw = a.wishMatch ? 1 : 0;
    const bw = b.wishMatch ? 1 : 0;
    return bw - aw;
  });
}

function splitTokyoLocal(local: string) {
  const m = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/.exec(local);
  if (!m) return null;
  return {
    y: Number(m[1]),
    mo: Number(m[2]),
    d: Number(m[3]),
    h: m[4],
    mi: m[5],
    dateKey: `${m[1]}-${m[2]}-${m[3]}`,
  };
}

function formatRange(startLocal: string, endLocal: string): string {
  if (!startLocal || !endLocal) return "";
  const s = splitTokyoLocal(startLocal);
  const e = splitTokyoLocal(endLocal);
  if (!s || !e) return "";
  const sameDay = s.dateKey === e.dateKey;
  const dateFmt = (p: NonNullable<ReturnType<typeof splitTokyoLocal>>) =>
    `${p.mo}/${p.d}(${"日月火水木金土"[new Date(Date.UTC(p.y, p.mo - 1, p.d)).getUTCDay()]})`;
  const timeFmt = (p: NonNullable<ReturnType<typeof splitTokyoLocal>>) =>
    `${p.h}:${p.mi}`;
  return sameDay
    ? `${dateFmt(s)} ${timeFmt(s)}〜${timeFmt(e)}`
    : `${dateFmt(s)} ${timeFmt(s)} 〜 ${dateFmt(e)} ${timeFmt(e)}`;
}

function meetupCandidateIsSet(candidate: MeetupCandidate): boolean {
  return (
    candidateHasTime(candidate) &&
    !!candidate.place.trim() &&
    new Date(localToIso(candidate.end)) > new Date(localToIso(candidate.start))
  );
}

function meetupCandidateIsIncomplete(candidate: MeetupCandidate): boolean {
  return candidateHasAnyInput(candidate) && !meetupCandidateIsSet(candidate);
}

function meetupCandidateIsEmpty(candidate: MeetupCandidate): boolean {
  return !candidateHasAnyInput(candidate);
}

function findNextMeetupCandidateId(candidates: MeetupCandidate[]): string | null {
  for (let index = 1; index <= MAX_MEETUP_CANDIDATES; index += 1) {
    const id = `candidate-${index}`;
    if (!candidates.some((candidate) => candidate.id === id)) return id;
  }
  return null;
}

function toMeetupPayload(
  candidate: MeetupCandidate,
): MeetupCandidatePayload {
  return {
    startAt: localToIso(candidate.start),
    endAt: localToIso(candidate.end),
    placeName: candidate.place.trim(),
    lat: candidate.center[0],
    lng: candidate.center[1],
    mode: candidate.mode,
  };
}

function labelFromAddress(p: Place): string {
  if (!p.address) return p.display_name.split(",")[0] ?? p.display_name;
  const a = p.address;
  return (
    a.amenity ||
    a.attraction ||
    a.shop ||
    a.station ||
    a.railway ||
    a.building ||
    a.tourism ||
    a.leisure ||
    a.suburb ||
    p.display_name.split(",")[0] ||
    p.display_name
  );
}

function shouldIgnoreProposeSwipe(target: EventTarget | null): boolean {
  if (!(target instanceof Element)) return false;
  return Boolean(
    target.closest(
      "input, textarea, select, [contenteditable='true'], [data-propose-swipe-ignore], .leaflet-container, .maplibregl-map",
    ),
  );
}

/* ─── main component ────────────────────────────────────── */

export function ProposeFlow({
  partner,
  myInv,
  theirInv,
  matchType,
  initialTab = "mine",
  initial,
}: Props) {
  const router = useRouter();

  /* ── 提示物 state（initial があれば優先、なければ wishMatch pre-check） ── */
  const initialSenderIdSet = useMemo(
    () => new Set(initial?.senderHaveIds ?? []),
    [initial],
  );
  const initialReceiverIdSet = useMemo(
    () => new Set(initial?.receiverHaveIds ?? []),
    [initial],
  );
  const initialSenderQtyById = useMemo(() => {
    const m = new Map<string, number>();
    if (initial) {
      initial.senderHaveIds.forEach((id, i) => {
        m.set(id, initial.senderHaveQtys[i] ?? 1);
      });
    }
    return m;
  }, [initial]);
  const initialReceiverQtyById = useMemo(() => {
    const m = new Map<string, number>();
    if (initial) {
      initial.receiverHaveIds.forEach((id, i) => {
        m.set(id, initial.receiverHaveQtys[i] ?? 1);
      });
    }
    return m;
  }, [initial]);

  // iter110: 関係図で選んだ項目を最上位に
  //   initial がある（関係図経由）→ initialSenderIdSet/initialReceiverIdSet 優先
  //   なし → 従来通り wishMatch 優先
  const myItemsSorted = initial
    ? sortBySelectionFirst(myInv, initialSenderIdSet)
    : sortByWishFirst(myInv);
  const theirItemsSorted = initial
    ? sortBySelectionFirst(theirInv, initialReceiverIdSet)
    : sortByWishFirst(theirInv);

  const [myItems, setMyItems] = useState<Selectable[]>(() =>
    myItemsSorted.map((i) => {
      const checked = initial
        ? initialSenderIdSet.has(i.id)
        : (matchType === "perfect" || matchType === "forward") &&
          i.wishMatch === true;
      const qty = checked
        ? initialSenderQtyById.get(i.id) ?? i.quantity
        : 1;
      return {
        ...i,
        selected: checked,
        selectedQty: qty,
      };
    }),
  );
  const [theirItems, setTheirItems] = useState<Selectable[]>(() =>
    theirItemsSorted.map((i) => {
      const checked = initial
        ? initialReceiverIdSet.has(i.id)
        : (matchType === "perfect" || matchType === "backward") &&
          i.wishMatch === true;
      const qty = checked
        ? initialReceiverQtyById.get(i.id) ?? i.quantity
        : 1;
      return {
        ...i,
        selected: checked,
        selectedQty: qty,
      };
    }),
  );

  /* ── 定価交換モード（initial.cashOffer があれば true） ── */
  const cashOffer = initial?.cashOffer;
  const isCashMode = !!cashOffer;

  /* ── 待ち合わせ state（時間帯 + 地図） ──
     iter70-C: 再打診の場合は元 proposal の値を最優先 */
  const initStart = initial?.meetupStartAt
    ? isoToLocal(initial.meetupStartAt)
    : "";
  const initEnd = initial?.meetupEndAt
    ? isoToLocal(initial.meetupEndAt)
    : "";
  const initPlace = initial?.meetupPlaceName ?? "";
  const initLat =
    initial?.meetupLat ??
    partner.localModeAW?.centerLat ??
    FALLBACK_CENTER[0];
  const initLng =
    initial?.meetupLng ??
    partner.localModeAW?.centerLng ??
    FALLBACK_CENTER[1];

  const buildInitialMeetupCandidates = (): MeetupCandidate[] => {
    const fromInitial =
      initial?.meetupCandidates
        ?.slice(0, MAX_MEETUP_CANDIDATES)
        .map((candidate, index) => ({
          id: `candidate-${index + 1}`,
          mode: candidate.mode,
          start: isoToLocal(candidate.startAt),
          end: isoToLocal(candidate.endAt),
          place: candidate.placeName,
          center: [candidate.lat, candidate.lng] as [number, number],
        })) ?? [];
    if (fromInitial.length > 0) return fromInitial;
    if (initStart && initEnd) {
      return [
        {
          id: "candidate-1",
          mode:
            initStart.slice(0, 10) === roundUpTokyoLocal().slice(0, 10)
              ? "today"
              : "scheduled",
          start: initStart,
          end: initEnd,
          place: initPlace,
          center: [initLat, initLng],
        },
      ];
    }

    // 新規打診では、見えない時間入り候補を作らず空の候補1から始める。
    return [
      {
        id: "candidate-1",
        mode: partner.localModeEnabled ? "today" : "scheduled",
        start: "",
        end: "",
        place: "",
        center: [initLat, initLng],
      },
    ];
  };

  const [meetupCandidates, setMeetupCandidates] =
    useState<MeetupCandidate[]>(buildInitialMeetupCandidates);
  const [activeMeetupId, setActiveMeetupId] = useState("candidate-1");
  const activeMeetup =
    meetupCandidates.find((candidate) => candidate.id === activeMeetupId) ??
    meetupCandidates[0];
  const meetupPlace = activeMeetup?.place ?? "";
  const meetupCenter = activeMeetup?.center ?? FALLBACK_CENTER;
  const previousMeetupForActive = useMemo(() => {
    const activeIndex = meetupCandidates.findIndex(
      (candidate) => candidate.id === activeMeetupId,
    );
    if (activeIndex <= 0) return null;
    for (let index = activeIndex - 1; index >= 0; index -= 1) {
      const candidate = meetupCandidates[index];
      if (candidate?.place.trim()) return candidate;
    }
    return null;
  }, [activeMeetupId, meetupCandidates]);

  /** ユーザーが place 入力欄を直接編集している間は reverse-geocode で上書きしない */
  const placeManuallyEditedRef = useRef(false);
  /** 地図移動が「ユーザー操作由来」かを管理 */
  const skipReverseRef = useRef(true); // 初回 mount は reverse しない（pre-fill 値を尊重）
  const [reverseFetching, setReverseFetching] = useState(false);

  /* 地図検索 */
  const [searchQ, setSearchQ] = useState("");
  const [searchResults, setSearchResults] = useState<Place[]>([]);
  const [searching, setSearching] = useState(false);
  const [showResults, setShowResults] = useState(false);

  /* ── ステップ・タブ ── */
  const [step, setStep] = useState<Step>("select");
  const [tab, setTab] = useState<Tab>(initialTab);
  const swipeStateRef = useRef<{
    startX: number;
    startY: number;
    tracking: boolean;
    swiping: boolean;
  } | null>(null);
  const suppressClickRef = useRef(false);
  const suppressClickTimerRef = useRef<number | null>(null);

  /* ── メッセージ（iter138: tone / 自動テンプレ廃止、空文字スタート） ── */
  const [exposeCalendar, setExposeCalendar] = useState(true); // iter138: デフォルト ON
  const [message, setMessage] = useState<string>(initial?.message ?? "");

  /* ── 送信状態 ── */
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [submitComplete, setSubmitComplete] = useState(false);
  const meetupCalendarActive = step === "select" && tab === "meetup";

  /* ── derived ── */
  const myCount = myItems
    .filter((i) => i.selected)
    .reduce((s, i) => s + i.selectedQty, 0);
  const theirCount = theirItems
    .filter((i) => i.selected)
    .reduce((s, i) => s + i.selectedQty, 0);

  const validMeetupCandidates = meetupCandidates.filter(meetupCandidateIsSet);
  const incompleteMeetupCandidates = meetupCandidates.filter(
    meetupCandidateIsIncomplete,
  );
  const primaryMeetup = validMeetupCandidates[0];
  const meetupSet = validMeetupCandidates.length > 0;
  const meetupReady = meetupSet && incompleteMeetupCandidates.length === 0;
  const meetupHasTimeDraft = meetupCandidates.some(candidateHasTime);

  // 定価交換モードでは receivers (相手の譲) は要らない（金銭で受け取る/支払う）
  const canProceedSelect = isCashMode
    ? myCount > 0 && meetupReady
    : myCount > 0 && theirCount > 0 && meetupReady;

  // iter138: 自動テンプレ廃止。メッセージは confirm 画面で任意入力。

  function updateActiveMeetup(patch: Partial<MeetupCandidate>) {
    setMeetupCandidates((prev) =>
      prev.map((candidate) =>
        candidate.id === activeMeetupId
          ? {
              ...candidate,
              ...patch,
            }
          : candidate,
      ),
    );
  }

  function selectMeetupCandidate(id: string) {
    skipReverseRef.current = true;
    placeManuallyEditedRef.current = false;
    setActiveMeetupId(id);
  }

  function setActiveMeetupTimeRange(start: string, end: string) {
    const mode: MeetupMode =
      start.slice(0, 10) === roundUpTokyoLocal().slice(0, 10)
        ? "today"
        : "scheduled";
    const activeCandidate =
      meetupCandidates.find((candidate) => candidate.id === activeMeetupId) ??
      meetupCandidates[0];
    const emptyCandidate = meetupCandidates.find(
      (candidate) =>
        candidate.id !== activeMeetupId && meetupCandidateIsEmpty(candidate),
    );
    const shouldCreateNext =
      activeCandidate &&
      candidateHasTime(activeCandidate) &&
      !emptyCandidate &&
      meetupCandidates.length < MAX_MEETUP_CANDIDATES;
    const nextCandidateId = shouldCreateNext
      ? findNextMeetupCandidateId(meetupCandidates)
      : null;
    const targetCandidateId =
      activeCandidate && !candidateHasTime(activeCandidate)
        ? activeCandidate.id
        : emptyCandidate?.id ?? nextCandidateId ?? activeCandidate?.id ?? activeMeetupId;
    const center = activeCandidate?.center ?? FALLBACK_CENTER;

    skipReverseRef.current = true;
    setActiveMeetupId(targetCandidateId);
    setMeetupCandidates((prev) => {
      const patch = {
        mode,
        start,
        end,
        place: "",
      };
      if (nextCandidateId && targetCandidateId === nextCandidateId) {
        return [
          ...prev,
          {
            id: nextCandidateId,
            ...patch,
            center,
          },
        ];
      }
      return prev.map((candidate) =>
        candidate.id === targetCandidateId
          ? {
              ...candidate,
              ...patch,
            }
          : candidate,
      );
    });
    placeManuallyEditedRef.current = false;
  }

  function moveMeetupCandidateTimeRange(id: string, start: string, end: string) {
    const mode: MeetupMode =
      start.slice(0, 10) === roundUpTokyoLocal().slice(0, 10)
        ? "today"
        : "scheduled";
    skipReverseRef.current = true;
    setActiveMeetupId(id);
    setMeetupCandidates((prev) =>
      prev.map((candidate) =>
        candidate.id === id
          ? {
              ...candidate,
              mode,
              start,
              end,
            }
          : candidate,
      ),
    );
    placeManuallyEditedRef.current = false;
  }

  function deleteMeetupCandidate(id: string) {
    const deletedIndex = meetupCandidates.findIndex(
      (candidate) => candidate.id === id,
    );
    if (deletedIndex < 0) return;

    const deleted = meetupCandidates[deletedIndex];
    const remaining = meetupCandidates.filter((candidate) => candidate.id !== id);
    if (remaining.length === 0) {
      const blankCandidate: MeetupCandidate = {
        id: "candidate-1",
        mode: partner.localModeEnabled ? "today" : "scheduled",
        start: "",
        end: "",
        place: "",
        center: deleted?.center ?? FALLBACK_CENTER,
      };
      setMeetupCandidates([blankCandidate]);
      setActiveMeetupId(blankCandidate.id);
      placeManuallyEditedRef.current = false;
      skipReverseRef.current = true;
      return;
    }

    const renumbered = remaining.map((candidate, index) => ({
      ...candidate,
      id: `candidate-${index + 1}`,
    }));
    const nextActiveIndex =
      id === activeMeetupId
        ? Math.min(deletedIndex, renumbered.length - 1)
        : Math.max(
            0,
            remaining.findIndex((candidate) => candidate.id === activeMeetupId),
          );
    setMeetupCandidates(renumbered);
    setActiveMeetupId(renumbered[nextActiveIndex]?.id ?? renumbered[0].id);
    placeManuallyEditedRef.current = false;
    skipReverseRef.current = true;
  }

  function usePreviousPlaceForActiveCandidate() {
    if (!previousMeetupForActive) return;
    skipReverseRef.current = true;
    placeManuallyEditedRef.current = false;
    setMeetupCandidates((prev) =>
      prev.map((candidate) =>
        candidate.id === activeMeetupId
          ? {
              ...candidate,
              place: previousMeetupForActive.place,
              center: previousMeetupForActive.center,
            }
          : candidate,
      ),
    );
  }

  /* 地図中心が動いた時の reverse geocoding（自動で場所名を埋める） */
  const reverseAbortRef = useRef<AbortController | null>(null);
  useEffect(() => {
    if (skipReverseRef.current) {
      // 初回 mount or 検索結果から選んだ直後など、自動 reverse をスキップしたい時
      skipReverseRef.current = false;
      return;
    }
    if (placeManuallyEditedRef.current) return; // 手入力モード中は触らない

    const handle = setTimeout(async () => {
      reverseAbortRef.current?.abort();
      const ctrl = new AbortController();
      reverseAbortRef.current = ctrl;
      setReverseFetching(true);
      try {
        const res = await fetch(
          `/api/geocode?lat=${meetupCenter[0]}&lon=${meetupCenter[1]}`,
          { signal: ctrl.signal },
        );
        const data = await res.json();
        if (data && typeof data === "object" && !Array.isArray(data)) {
          const label = labelFromAddress(data as Place);
          if (label) {
            setMeetupCandidates((prev) =>
              prev.map((candidate) =>
                candidate.id === activeMeetupId
                  ? {
                      ...candidate,
                      place: label,
                    }
                  : candidate,
              ),
            );
          }
        }
      } catch {
        // ignore（abort or network error）
      } finally {
        setReverseFetching(false);
      }
    }, 600); // ピンドラッグ中の連続イベントを debounce
    return () => clearTimeout(handle);
  }, [activeMeetupId, meetupCenter]);

  /* 場所検索 debounce */
  const searchAbortRef = useRef<AbortController | null>(null);
  function handleSearchQChange(value: string) {
    setSearchQ(value);
    if (value.trim().length >= 2) return;
    searchAbortRef.current?.abort();
    setSearchResults([]);
    setShowResults(false);
  }

  useEffect(() => {
    const q = searchQ.trim();
    if (q.length < 2) return;
    const handle = setTimeout(async () => {
      searchAbortRef.current?.abort();
      const ctrl = new AbortController();
      searchAbortRef.current = ctrl;
      setSearching(true);
      try {
        const res = await fetch(`/api/geocode?q=${encodeURIComponent(q)}`, {
          signal: ctrl.signal,
        });
        const data = (await res.json()) as Place[] | { error: string };
        if (Array.isArray(data)) {
          setSearchResults(data);
          setShowResults(true);
        }
      } catch {
        // ignore (abort or network)
      } finally {
        setSearching(false);
      }
    }, 350);
    return () => clearTimeout(handle);
  }, [searchQ]);

  function pickPlace(p: Place) {
    const lat = parseFloat(p.lat);
    const lon = parseFloat(p.lon);
    if (Number.isFinite(lat) && Number.isFinite(lon)) {
      // 検索結果由来の label は reverse geocode より信頼できるので確定させる
      placeManuallyEditedRef.current = false;
      skipReverseRef.current = true;
      updateActiveMeetup({
        center: [lat, lon],
        place: labelFromAddress(p),
      });
      setSearchQ("");
      setShowResults(false);
    }
  }

  function useCurrentLocation() {
    if (typeof window === "undefined" || !navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        // 現在地ジャンプは reverse で名前を取り直す
        placeManuallyEditedRef.current = false;
        skipReverseRef.current = false;
        updateActiveMeetup({
          center: [pos.coords.latitude, pos.coords.longitude],
        });
      },
      () => {},
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  /** 地図ピン操作（drag / click） */
  function handleMapCenterChange(lat: number, lng: number) {
    placeManuallyEditedRef.current = false; // 地図動かしたら自動 reverse を許可
    skipReverseRef.current = false;
    updateActiveMeetup({ center: [lat, lng] });
  }

  /** place 入力欄を手動で編集 */
  function handlePlaceInputChange(value: string) {
    placeManuallyEditedRef.current = true;
    updateActiveMeetup({ place: value });
  }

  /* ── handlers ── */

  function clearSuppressClickTimer() {
    if (suppressClickTimerRef.current && typeof window !== "undefined") {
      window.clearTimeout(suppressClickTimerRef.current);
      suppressClickTimerRef.current = null;
    }
  }

  function suppressNextClick() {
    suppressClickRef.current = true;
    clearSuppressClickTimer();
    if (typeof window === "undefined") return;
    suppressClickTimerRef.current = window.setTimeout(() => {
      suppressClickRef.current = false;
      suppressClickTimerRef.current = null;
    }, 360);
  }

  useEffect(() => {
    return () => clearSuppressClickTimer();
  }, []);

  function moveTabBySwipe(direction: 1 | -1): boolean {
    const currentIndex = PROPOSE_TAB_ORDER.indexOf(tab);
    const next = PROPOSE_TAB_ORDER[currentIndex + direction];
    if (!next) return false;
    setTab(next);
    return true;
  }

  function handleTabSwipeStart(e: TouchEvent<HTMLDivElement>) {
    if (step !== "select" || e.touches.length !== 1) return;
    if (shouldIgnoreProposeSwipe(e.target)) return;
    const touch = e.touches[0];
    swipeStateRef.current = {
      startX: touch.clientX,
      startY: touch.clientY,
      tracking: true,
      swiping: false,
    };
  }

  function handleTabSwipeMove(e: TouchEvent<HTMLDivElement>) {
    const state = swipeStateRef.current;
    if (!state?.tracking || e.touches.length !== 1) return;

    const touch = e.touches[0];
    const dx = touch.clientX - state.startX;
    const dy = touch.clientY - state.startY;
    const absX = Math.abs(dx);
    const absY = Math.abs(dy);

    if (!state.swiping) {
      if (absX > 14 && absX > absY * 1.25) {
        state.swiping = true;
      } else if (absY > 14 && absY > absX * 1.1) {
        state.tracking = false;
        return;
      }
    }

    if (state.swiping) e.preventDefault();
  }

  function handleTabSwipeEnd(e: TouchEvent<HTMLDivElement>) {
    const state = swipeStateRef.current;
    swipeStateRef.current = null;
    if (!state?.tracking || !state.swiping) return;

    const touch = e.changedTouches[0];
    if (!touch) return;
    const dx = touch.clientX - state.startX;
    const dy = touch.clientY - state.startY;
    const absX = Math.abs(dx);
    const absY = Math.abs(dy);
    if (absX < 56 || absX < absY * 1.35) return;

    const moved = moveTabBySwipe(dx < 0 ? 1 : -1);
    if (moved) {
      e.preventDefault();
      suppressNextClick();
    }
  }

  function handleTabSwipeCancel() {
    swipeStateRef.current = null;
  }

  function handleSwipeClickCapture(e: MouseEvent<HTMLDivElement>) {
    if (!suppressClickRef.current) return;
    suppressClickRef.current = false;
    e.preventDefault();
    e.stopPropagation();
  }

  function toggleItem(side: "mine" | "theirs", id: string) {
    const update = (items: Selectable[]) =>
      items.map((i) => {
        if (i.id !== id) return i;
        const ns = !i.selected;
        return {
          ...i,
          selected: ns,
          selectedQty: ns ? i.quantity : 1,
        };
      });
    if (side === "mine") setMyItems(update);
    else setTheirItems(update);
  }

  function updateQty(side: "mine" | "theirs", id: string, delta: number) {
    const update = (items: Selectable[]) =>
      items.map((i) => {
        if (i.id !== id) return i;
        const newQty = Math.max(1, Math.min(i.quantity, i.selectedQty + delta));
        return { ...i, selectedQty: newQty };
      });
    if (side === "mine") setMyItems(update);
    else setTheirItems(update);
  }

  function handleSubmit() {
    setError(null);
    const incompleteIndex = meetupCandidates.findIndex(
      meetupCandidateIsIncomplete,
    );
    if (incompleteIndex >= 0) {
      const incomplete = meetupCandidates[incompleteIndex];
      setError(
        candidateHasTime(incomplete)
          ? `候補${incompleteIndex + 1} の場所を設定してください`
          : `候補${incompleteIndex + 1} の交換できる時間を設定してください`,
      );
      setTab("meetup");
      setStep("select");
      return;
    }
    if (!primaryMeetup) {
      setError("交換できる候補を 1 件以上設定してください");
      setTab("meetup");
      setStep("select");
      return;
    }
    const primaryMeetupPayload = toMeetupPayload(primaryMeetup);
    const meetupPayloads = validMeetupCandidates
      .slice(0, 3)
      .map(toMeetupPayload);
    startTransition(async () => {
      const senderHaveIds: string[] = [];
      const senderHaveQtys: number[] = [];
      myItems
        .filter((i) => i.selected)
        .forEach((i) => {
          senderHaveIds.push(i.id);
          senderHaveQtys.push(i.selectedQty);
        });
      const receiverHaveIds: string[] = [];
      const receiverHaveQtys: number[] = [];
      theirItems
        .filter((i) => i.selected)
        .forEach((i) => {
          receiverHaveIds.push(i.id);
          receiverHaveQtys.push(i.selectedQty);
        });

      // iter71-C：再打診の場合は同じ proposal を update + diff を system message に
      if (initial?.reviseFromProposalId) {
        const r = await reviseProposal({
          id: initial.reviseFromProposalId,
          meSenderHaveIds: senderHaveIds,
          meSenderHaveQtys: senderHaveQtys,
          meReceiverHaveIds: isCashMode ? [] : receiverHaveIds,
          meReceiverHaveQtys: isCashMode ? [] : receiverHaveQtys,
          message,
          meetupStartAt: primaryMeetupPayload.startAt,
          meetupEndAt: primaryMeetupPayload.endAt,
          meetupPlaceName: primaryMeetupPayload.placeName,
          meetupLat: primaryMeetupPayload.lat,
          meetupLng: primaryMeetupPayload.lng,
          meetupCandidates: meetupPayloads,
          cashOffer: isCashMode,
          cashAmount: cashOffer?.amount ?? null,
        });
        if (r?.error) {
          setError(r.error);
          return;
        }
        // 同じチャットに戻る
        router.push(`/transactions/${initial.reviseFromProposalId}`);
        return;
      }

      const r = await createProposal({
        receiverId: partner.id,
        matchType,
        senderHaveIds,
        senderHaveQtys,
        // 定価交換モードでは receiver 側は空配列で送信
        receiverHaveIds: isCashMode ? [] : receiverHaveIds,
        receiverHaveQtys: isCashMode ? [] : receiverHaveQtys,
        message,
        // iter138: tone 廃止 → DB 互換のため "standard" で固定送信
        messageTone: "standard",
        meetupStartAt: primaryMeetupPayload.startAt,
        meetupEndAt: primaryMeetupPayload.endAt,
        meetupPlaceName: primaryMeetupPayload.placeName,
        meetupLat: primaryMeetupPayload.lat,
        meetupLng: primaryMeetupPayload.lng,
        meetupCandidates: meetupPayloads,
        exposeCalendar,
        listingId: initial?.listingId ?? null,
        cashOffer: isCashMode,
        cashAmount: cashOffer?.amount ?? null,
      });
      if (r?.error) {
        setError(r.error);
        return;
      }
      setSubmitComplete(true);
    });
  }

  /* ─── render ─── */

  if (submitComplete) {
    return <ProposalComplete partnerHandle={partner.handle} />;
  }

  return (
    <main
      className={`flex flex-1 flex-col bg-[#fbf9fc] text-[#3a324a] ${
        meetupCalendarActive ? "h-[100dvh] overflow-hidden" : "pb-[112px]"
      }`}
    >
      {/* Header */}
      <header className="sticky top-0 z-10 border-b border-[#3a324a14] bg-white/90 px-[18px] pb-3 pt-12 backdrop-blur-xl">
        <div className="mx-auto flex max-w-md items-center gap-3">
          {step === "select" ? (
            <Link href="/" aria-label="戻る" className="flex-shrink-0">
              <ChevronLeft />
            </Link>
          ) : (
            <button
              type="button"
              aria-label="戻る"
              onClick={() => setStep("select")}
              className="flex-shrink-0"
            >
              <ChevronLeft />
            </button>
          )}
          <div className="flex-1">
            <div className="text-[15px] font-bold text-gray-900">
              {step === "select" ? "提示物の選択" : "送信確認"}
            </div>
            <div className="mt-0.5 text-[11px] text-[#3a324a8c]">
              @{partner.handle}
              {partner.primaryArea ? ` ・${partner.primaryArea}` : ""}
            </div>
          </div>
          {/* iter138: STEP X/2 に変更（message ステップ廃止） */}
          <span className="rounded-full bg-[#a695d814] px-2.5 py-1 text-[10.5px] font-extrabold tracking-[0.3px] text-[#a695d8]">
            STEP {step === "select" ? 1 : 2}/2
          </span>
        </div>

        {/* 定価交換モードバナー */}
        {isCashMode && (
          <div className="-mx-[18px] mt-2 flex items-center gap-2 border-b border-[#7a9a8a33] bg-[#7a9a8a14] px-[18px] py-2">
            <span className="text-[14px]">💴</span>
            <div className="flex-1 text-[11.5px] font-bold leading-snug text-[#3a324a]">
              定価交換モード（個別募集の選択肢から）
              <span className="ml-1.5 text-[10.5px] font-normal text-[#3a324a8c]">
                受け取り＝¥{cashOffer?.amount.toLocaleString()}
              </span>
            </div>
          </div>
        )}

        {step === "select" && (
          // iter137: PC でタブが横一杯に広がっていた問題を修正
          //   外側 div を mx-auto max-w-md でスマホ幅に固定
          <div className="-mx-[18px] mt-3 border-b border-[#3a324a14]">
            <div className="mx-auto flex max-w-md px-3">
            {(
              [
                { id: "mine", label: "私が出す", count: myCount },
                {
                  id: "theirs",
                  label: isCashMode
                    ? `受け取り ¥${cashOffer?.amount.toLocaleString()}`
                    : "受け取る",
                  count: isCashMode ? "💴" : theirCount,
                },
                {
                  id: "meetup",
                  label: "待ち合わせ",
                  count: meetupReady ? "✓" : "!",
                  state: true as boolean,
                },
              ] as const
            ).map((tt) => {
              const active = tab === tt.id;
              const stateBadge = "state" in tt && tt.state;
              return (
                <button
                  key={tt.id}
                  type="button"
                  onClick={() => setTab(tt.id)}
                  className={`flex flex-1 items-center justify-center gap-1.5 border-b-[2.5px] px-1 py-2.5 text-[12.5px] ${
                    active
                      ? "border-[#a695d8] font-extrabold text-[#a695d8]"
                      : "border-transparent font-semibold text-[#3a324a8c]"
                  }`}
                >
                  {tt.label}
                  <span
                    className={`min-w-[18px] rounded-full px-1.5 py-0.5 text-center text-[10px] font-extrabold tabular-nums ${
                      stateBadge
                        ? meetupReady
                          ? "bg-[#7a9a8a] text-white"
                          : "bg-[#d9826b33] text-[#d9826b]"
                        : active
                          ? "bg-[#a695d8] text-white"
                          : "bg-[#3a324a08] text-[#3a324a8c]"
                    }`}
                  >
                    {tt.count}
                  </span>
                </button>
              );
            })}
            </div>
          </div>
        )}
      </header>

      <div
        className={`mx-auto w-full max-w-md flex-1 px-[18px] pt-3.5 [touch-action:pan-y] ${
          meetupCalendarActive ? "min-h-0 overflow-hidden" : ""
        }`}
        onTouchStart={handleTabSwipeStart}
        onTouchMove={handleTabSwipeMove}
        onTouchEnd={handleTabSwipeEnd}
        onTouchCancel={handleTabSwipeCancel}
        onClickCapture={handleSwipeClickCapture}
      >
        {step === "select" && tab === "meetup" && (
          <MeetupTab
            meetupCandidates={meetupCandidates}
            activeMeetupId={activeMeetupId}
            onSelectCandidate={selectMeetupCandidate}
            onTimeRangeSelect={setActiveMeetupTimeRange}
            onMoveCandidateTimeRange={moveMeetupCandidateTimeRange}
            onDeleteCandidate={deleteMeetupCandidate}
            onUsePreviousPlace={usePreviousPlaceForActiveCandidate}
            canUsePreviousPlace={!!previousMeetupForActive}
            previousPlaceName={previousMeetupForActive?.place ?? ""}
            meetupPlace={meetupPlace}
            onPlaceInputChange={handlePlaceInputChange}
            meetupCenter={meetupCenter}
            onMapCenterChange={handleMapCenterChange}
            reverseFetching={reverseFetching}
            searchQ={searchQ}
            setSearchQ={handleSearchQChange}
            searchResults={searchResults}
            searching={searching}
            showResults={showResults}
            setShowResults={setShowResults}
            pickPlace={pickPlace}
            useCurrentLocation={useCurrentLocation}
          />
        )}

        {step === "select" && tab !== "meetup" && (
          <>
            {isCashMode && tab === "theirs" ? (
              <div className="rounded-[14px] border-[1.5px] border-[#7a9a8a] bg-[#7a9a8a0a] p-5 text-center">
                <div className="text-[24px]">💴</div>
                <div className="mt-1 text-[14px] font-extrabold text-[#3a324a]">
                  定価交換 ¥{cashOffer?.amount.toLocaleString()}
                </div>
                <div className="mt-2 text-[11.5px] leading-relaxed text-[#3a324a8c]">
                  この打診は <b>金銭での取引</b> です。
                  <br />
                  受け取るアイテムの選択は不要です。
                </div>
              </div>
            ) : (
              <ItemTab
                tab={tab}
                partnerHandle={partner.handle}
                items={tab === "mine" ? myItems : theirItems}
                onToggle={(id) => toggleItem(tab, id)}
                onQty={(id, d) => updateQty(tab, id, d)}
              />
            )}
          </>
        )}

        {/* iter138: message step は廃止 ─ confirm 内でメッセージ + 共有設定を入力 */}

        {step === "confirm" && (
          <ConfirmStep
            partnerHandle={partner.handle}
            myItems={myItems.filter((i) => i.selected)}
            theirItems={theirItems.filter((i) => i.selected)}
            meetupCandidates={validMeetupCandidates}
            message={message}
            onMessageChange={setMessage}
            exposeCalendar={exposeCalendar}
            onExposeCalendarChange={setExposeCalendar}
            error={error}
          />
        )}
      </div>

      {/* Bottom CTA — オーナー指示で 3 行 summary は廃止、CTA だけ */}
      <div className="fixed inset-x-0 bottom-0 z-20 border-t border-[#3a324a14] bg-white/95 px-[18px] pb-7 pt-3 backdrop-blur-xl">
        <div className="mx-auto w-full max-w-md">
          {step === "select" && (
            <button
              type="button"
              disabled={!canProceedSelect}
              onClick={() => setStep("confirm")}
              className="block w-full rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-6 py-[14px] text-center text-sm font-bold tracking-[0.3px] text-white shadow-[0_4px_14px_rgba(166,149,216,0.33)] disabled:cursor-not-allowed disabled:opacity-50 disabled:shadow-none"
            >
              {canProceedSelect
                ? "次へ：送信確認 →"
                : myCount === 0 || theirCount === 0
                  ? "提示物を両方から選んでください"
                  : meetupHasTimeDraft
                    ? "場所未設定の候補があります"
                    : "交換できる時間を設定してください"}
            </button>
          )}
          {step === "confirm" && (
            <PrimaryButton
              type="button"
              pending={pending}
              pendingLabel="送信中…"
              onClick={handleSubmit}
            >
              この内容で打診を送信
            </PrimaryButton>
          )}
        </div>
      </div>
    </main>
  );
}

/* ─── sub-components ────────────────────────────────────── */

function ProposalComplete({ partnerHandle }: { partnerHandle: string }) {
  return (
    <main className="flex flex-1 flex-col bg-[#fbf9fc] px-[22px] pb-[max(env(safe-area-inset-bottom),28px)] pt-16 text-[#3a324a]">
      <div className="mx-auto flex w-full max-w-md flex-1 flex-col items-center justify-center">
        <div className="relative mb-7 flex h-[178px] w-[178px] items-center justify-center">
          <span className="absolute left-5 top-2 h-3 w-3 rounded-full bg-[#f3c5d4] shadow-[0_0_16px_rgba(243,197,212,0.62)]" />
          <span className="absolute right-4 top-8 h-2.5 w-2.5 rounded-full bg-[#a8d4e6] shadow-[0_0_14px_rgba(168,212,230,0.72)]" />
          <span className="absolute bottom-7 left-2 h-2 w-2 rounded-full bg-[#a695d8] shadow-[0_0_14px_rgba(166,149,216,0.72)]" />
          <span className="absolute bottom-3 right-8 h-3.5 w-3.5 rounded-full bg-[#f3c5d4] shadow-[0_0_18px_rgba(243,197,212,0.55)]" />
          <div className="absolute inset-6 rounded-full bg-[conic-gradient(from_210deg,#a695d8,#f3c5d4,#a8d4e6,#a695d8)] opacity-80 blur-[18px]" />
          <div className="relative flex h-[112px] w-[112px] items-center justify-center rounded-full border border-white/70 bg-white shadow-[0_18px_48px_rgba(166,149,216,0.28)]">
            <svg width="54" height="54" viewBox="0 0 54 54" aria-hidden="true">
              <path
                d="M15 28.5 23.2 37 40 18"
                fill="none"
                stroke="#a695d8"
                strokeWidth="5.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </div>
        </div>

        <div className="text-center">
          <h1 className="text-[24px] font-extrabold tracking-[0.2px] text-gray-900">
            打診が完了しました
          </h1>
          <p className="mt-2 text-[13px] leading-relaxed text-[#3a324a8c]">
            @{partnerHandle} に打診を送りました。返事が届いたら通知と打診一覧で確認できます。
          </p>
        </div>

        <div className="mt-8 grid w-full gap-2.5">
          <Link
            href="/"
            className="block rounded-[14px] border border-[#3a324a14] bg-white px-6 py-[14px] text-center text-[13.5px] font-extrabold text-[#3a324a] shadow-[0_4px_14px_rgba(58,50,74,0.06)] active:scale-[0.98]"
          >
            まだ他に探す
          </Link>
          <Link
            href="/proposals"
            className="block rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-6 py-[14px] text-center text-[13.5px] font-extrabold tracking-[0.3px] text-white shadow-[0_6px_18px_rgba(166,149,216,0.34)] active:scale-[0.98]"
          >
            打診一覧に飛ぶ
          </Link>
        </div>
      </div>
    </main>
  );
}

function ChevronLeft() {
  return (
    <svg width="10" height="16" viewBox="0 0 10 16">
      <path
        d="M8 1L2 8l6 7"
        stroke="#1a1a26"
        strokeWidth="1.6"
        fill="none"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function ItemTab({
  tab,
  partnerHandle,
  items,
  onToggle,
  onQty,
}: {
  tab: "mine" | "theirs";
  partnerHandle: string;
  items: Selectable[];
  onToggle: (id: string) => void;
  onQty: (id: string, delta: number) => void;
}) {
  const sectionLabel =
    tab === "mine"
      ? "あなたの在庫（譲る候補）"
      : `@${partnerHandle} の譲一覧`;
  const wishMatchLabel =
    tab === "mine" ? "相手がほしいものかも？" : "私がほしいものかも？";

  return (
    <>
      <div className="mb-2 px-1 text-[11px] font-bold tracking-[0.4px] text-[#3a324a8c]">
        {sectionLabel} ({items.length}件)
      </div>

      {items.length === 0 ? (
        <div className="rounded-[14px] border border-[#3a324a14] bg-white px-5 py-10 text-center text-[12px] leading-relaxed text-[#3a324a8c]">
          該当アイテムがありません
        </div>
      ) : (
        items.map((it) => (
          <ItemRow
            key={it.id}
            it={it}
            wishMatchLabel={wishMatchLabel}
            onToggle={() => onToggle(it.id)}
            onQty={(d) => onQty(it.id, d)}
          />
        ))
      )}
    </>
  );
}

function ItemRow({
  it,
  wishMatchLabel,
  onToggle,
  onQty,
}: {
  it: Selectable;
  wishMatchLabel: string;
  onToggle: () => void;
  onQty: (delta: number) => void;
}) {
  const stepperVisible = it.selected && it.quantity > 1;
  const hue =
    Math.abs(
      (it.characterId ?? it.groupId ?? it.id)
        .split("")
        .reduce((s, c) => s + c.charCodeAt(0), 0),
    ) % 360;

  return (
    <button
      type="button"
      onClick={onToggle}
      className={`mb-2 flex w-full items-center gap-3 rounded-[12px] bg-white px-3.5 py-3 text-left transition-shadow ${
        it.selected
          ? "border-[1.5px] border-[#a695d8] shadow-[0_4px_12px_rgba(166,149,216,0.13)]"
          : "border-[0.5px] border-[#3a324a14]"
      }`}
    >
      <span
        className={`flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-[5px] border-[1.8px] ${
          it.selected
            ? "border-[#a695d8] bg-[#a695d8]"
            : "border-[#3a324a14] bg-white"
        }`}
      >
        {it.selected && (
          <svg width="11" height="11" viewBox="0 0 11 11">
            <path
              d="M2 5.5L4.5 8L9 3"
              stroke="#fff"
              strokeWidth="1.8"
              fill="none"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        )}
      </span>

      <span
        className="block h-12 w-9 flex-shrink-0 overflow-hidden rounded-md"
        style={{
          background: it.photoUrl
            ? "#3a324a"
            : `repeating-linear-gradient(135deg, hsl(${hue}, 35%, 78%) 0 5px, hsl(${hue}, 35%, 70%) 5px 10px)`,
        }}
      >
        {it.photoUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={it.photoUrl}
            alt=""
            className="block h-full w-full object-cover"
          />
        )}
      </span>

      <span className="min-w-0 flex-1">
        <span className="flex flex-wrap items-center gap-1">
          <span className="text-[13px] font-bold leading-tight">
            {it.title}
          </span>
          {it.wishMatch && (
            <span className="rounded-full bg-[linear-gradient(135deg,#a695d8,#f3c5d4)] px-1.5 py-0.5 text-[9px] font-extrabold tracking-[0.3px] text-white">
              {wishMatchLabel}
            </span>
          )}
        </span>
        <span className="mt-0.5 block text-[10.5px] tabular-nums text-[#3a324a8c]">
          {[it.groupName, it.characterName, it.goodsTypeName]
            .filter(Boolean)
            .join(" / ") || "—"}
          {" ・ 在庫 ×"}
          {it.quantity}
          {it.quantity === 1 && it.selected && (
            <span className="ml-1.5 font-bold text-[#a695d8]">選択中 ×1</span>
          )}
        </span>
      </span>

      {stepperVisible && (
        <span
          className="flex flex-shrink-0 items-center gap-0 rounded-full bg-[#3a324a08] p-[3px]"
          onClick={(e) => e.stopPropagation()}
        >
          <button
            type="button"
            disabled={it.selectedQty <= 1}
            onClick={() => onQty(-1)}
            className="flex h-6 w-6 items-center justify-center rounded-full bg-[#a695d8] text-base font-bold leading-none text-white disabled:bg-white disabled:text-[#3a324a4d]"
          >
            −
          </button>
          <span className="min-w-[28px] px-1 text-center text-[12.5px] font-extrabold tabular-nums">
            {it.selectedQty}
            <span className="ml-0.5 text-[9px] font-semibold text-[#3a324a8c]">
              /{it.quantity}
            </span>
          </span>
          <button
            type="button"
            disabled={it.selectedQty >= it.quantity}
            onClick={() => onQty(1)}
            className="flex h-6 w-6 items-center justify-center rounded-full bg-[#a695d8] text-base font-bold leading-none text-white disabled:bg-white disabled:text-[#3a324a4d]"
          >
            ＋
          </button>
        </span>
      )}
    </button>
  );
}

function getCalendarBlock(
  candidate: MeetupCandidate,
  weekDateKeys: string[],
):
  | {
      dayIndex: number;
      top: number;
      height: number;
    }
  | null {
  if (!candidateHasTime(candidate)) return null;
  const start = splitTokyoLocal(candidate.start);
  const end = splitTokyoLocal(candidate.end);
  if (!start || !end || start.dateKey !== end.dateKey) return null;
  const dayIndex = weekDateKeys.indexOf(start.dateKey);
  if (dayIndex < 0) return null;
  const startSlot = localToCalendarSlot(candidate.start);
  const endSlot = localToCalendarSlot(candidate.end);
  if (startSlot == null || endSlot == null) return null;
  const clampedStart = Math.max(0, Math.min(MEETUP_SLOT_COUNT, startSlot));
  const clampedEnd = Math.max(0, Math.min(MEETUP_SLOT_COUNT, endSlot));
  if (clampedEnd <= 0 || clampedStart >= MEETUP_SLOT_COUNT) return null;
  return {
    dayIndex,
    top: calendarSlotTop(clampedStart),
    height: Math.max(
      MEETUP_SLOT_HEIGHT,
      (clampedEnd - clampedStart) * MEETUP_SLOT_HEIGHT,
    ),
  };
}

function MeetupTab({
  meetupCandidates,
  activeMeetupId,
  onSelectCandidate,
  onTimeRangeSelect,
  onMoveCandidateTimeRange,
  onDeleteCandidate,
  onUsePreviousPlace,
  canUsePreviousPlace,
  previousPlaceName,
  meetupPlace,
  onPlaceInputChange,
  meetupCenter,
  onMapCenterChange,
  reverseFetching,
  searchQ,
  setSearchQ,
  searchResults,
  searching,
  showResults,
  setShowResults,
  pickPlace,
  useCurrentLocation,
}: {
  meetupCandidates: MeetupCandidate[];
  activeMeetupId: string;
  onSelectCandidate: (id: string) => void;
  onTimeRangeSelect: (start: string, end: string) => void;
  onMoveCandidateTimeRange: (id: string, start: string, end: string) => void;
  onDeleteCandidate: (id: string) => void;
  onUsePreviousPlace: () => void;
  canUsePreviousPlace: boolean;
  previousPlaceName: string;
  meetupPlace: string;
  onPlaceInputChange: (s: string) => void;
  meetupCenter: [number, number];
  onMapCenterChange: (lat: number, lng: number) => void;
  reverseFetching: boolean;
  searchQ: string;
  setSearchQ: (s: string) => void;
  searchResults: Place[];
  searching: boolean;
  showResults: boolean;
  setShowResults: (b: boolean) => void;
  pickPlace: (p: Place) => void;
  useCurrentLocation: () => void;
}) {
  const [placeSheetOpen, setPlaceSheetOpen] = useState(false);
  const activeCandidate =
    meetupCandidates.find((candidate) => candidate.id === activeMeetupId) ??
    meetupCandidates[0];
  const activeIndex = Math.max(
    0,
    meetupCandidates.findIndex((candidate) => candidate.id === activeMeetupId),
  );
  const [calendarWeekStartKey, setCalendarWeekStartKey] = useState(
    () => buildMeetupWeekDateKeys(activeCandidate?.start)[0],
  );
  const weekDateKeys = useMemo(
    () => buildMeetupWeekDateKeysFromDateKey(calendarWeekStartKey),
    [calendarWeekStartKey],
  );

  function openPlaceSheet(candidateId: string) {
    onSelectCandidate(candidateId);
    setPlaceSheetOpen(true);
  }

  function handleTimeRangeSelect(start: string, end: string) {
    onTimeRangeSelect(start, end);
  }

  function shiftCalendarWeek(direction: 1 | -1) {
    setCalendarWeekStartKey((current) =>
      addDaysToDateKey(current, direction * MEETUP_WEEK_DAYS),
    );
  }

  return (
    <div className="-mx-[18px] -mt-3.5 h-full overflow-hidden bg-white">
      <WeekMeetupCalendar
        candidates={meetupCandidates}
        activeMeetupId={activeMeetupId}
        weekDateKeys={weekDateKeys}
        onSelectCandidate={onSelectCandidate}
        onTimeRangeSelect={handleTimeRangeSelect}
        onMoveCandidateTimeRange={onMoveCandidateTimeRange}
        onOpenPlaceSheet={openPlaceSheet}
        onDeleteCandidate={onDeleteCandidate}
        onShiftWeek={shiftCalendarWeek}
      />

      {placeSheetOpen && activeCandidate && (
        <PlacePickerSheet
          candidateLabel={`候補${activeIndex + 1}`}
          timeLabel={
            activeCandidate.start && activeCandidate.end
              ? formatRange(activeCandidate.start, activeCandidate.end)
              : "時間未設定"
          }
          meetupPlace={meetupPlace}
          onPlaceInputChange={onPlaceInputChange}
          meetupCenter={meetupCenter}
          onMapCenterChange={onMapCenterChange}
          reverseFetching={reverseFetching}
          searchQ={searchQ}
          setSearchQ={setSearchQ}
          searchResults={searchResults}
          searching={searching}
          showResults={showResults}
          setShowResults={setShowResults}
          pickPlace={pickPlace}
          useCurrentLocation={useCurrentLocation}
          onUsePreviousPlace={onUsePreviousPlace}
          canUsePreviousPlace={canUsePreviousPlace}
          previousPlaceName={previousPlaceName}
          onClose={() => setPlaceSheetOpen(false)}
        />
      )}
    </div>
  );
}

function WeekMeetupCalendar({
  candidates,
  activeMeetupId,
  weekDateKeys,
  onSelectCandidate,
  onTimeRangeSelect,
  onMoveCandidateTimeRange,
  onOpenPlaceSheet,
  onDeleteCandidate,
  onShiftWeek,
}: {
  candidates: MeetupCandidate[];
  activeMeetupId: string;
  weekDateKeys: string[];
  onSelectCandidate: (id: string) => void;
  onTimeRangeSelect: (start: string, end: string) => void;
  onMoveCandidateTimeRange: (id: string, start: string, end: string) => void;
  onOpenPlaceSheet: (id: string) => void;
  onDeleteCandidate: (id: string) => void;
  onShiftWeek: (direction: 1 | -1) => void;
}) {
  const [drag, setDrag] = useState<MeetupDragSelection | null>(null);
  const dragRef = useRef<MeetupDragSelection | null>(null);
  const [candidateEdit, setCandidateEdit] =
    useState<MeetupCandidateEdit | null>(null);
  const candidateEditRef = useRef<MeetupCandidateEdit | null>(null);
  const persistedCandidateEditKeyRef = useRef<string | null>(null);
  const candidatePointerRef = useRef<MeetupCandidatePointerState | null>(null);
  const [nowParts, setNowParts] = useState(nowTokyoParts);
  const scrollRef = useRef<HTMLDivElement | null>(null);
  const gridRef = useRef<HTMLDivElement | null>(null);
  const didInitialScrollRef = useRef(false);
  const calendarSwipeRef = useRef<{
    startX: number;
    startY: number;
  } | null>(null);
  const touchPressRef = useRef<{
    timer: number;
    mode: "pending" | "scrolling" | "dragging";
    dayIndex: number;
    startSlot: number;
    identifier: number;
    startX: number;
    startY: number;
    scrollTop: number;
  } | null>(null);

  function clearTouchPress() {
    if (typeof window !== "undefined" && touchPressRef.current) {
      window.clearTimeout(touchPressRef.current.timer);
    }
    touchPressRef.current = null;
  }

  function clearCandidatePointer() {
    if (
      typeof window !== "undefined" &&
      candidatePointerRef.current?.timer != null
    ) {
      window.clearTimeout(candidatePointerRef.current.timer);
    }
    candidatePointerRef.current = null;
    candidateEditRef.current = null;
    setCandidateEdit(null);
  }

  useEffect(() => {
    return () => {
      clearTouchPress();
      clearCandidatePointer();
    };
  }, []);

  useEffect(() => {
    if (didInitialScrollRef.current) return;
    didInitialScrollRef.current = true;
    window.requestAnimationFrame(() => {
      if (!scrollRef.current) return;
      scrollRef.current.scrollTop =
        calendarSlotTop(
          ((MEETUP_CALENDAR_DEFAULT_SCROLL_HOUR - MEETUP_CALENDAR_START_HOUR) *
            60) /
            MEETUP_SLOT_MINUTES,
        ) - 8;
    });
  }, []);

  useEffect(() => {
    const timer = window.setInterval(() => {
      setNowParts(nowTokyoParts());
    }, 60_000);
    return () => window.clearInterval(timer);
  }, []);

  function setDragSelection(selection: MeetupDragSelection | null) {
    dragRef.current = selection;
    setDrag(selection);
  }

  function candidateEditKey(edit: MeetupCandidateEdit): string {
    return [
      edit.id,
      edit.action,
      edit.originalDayIndex,
      edit.dayIndex,
      edit.startSlot,
      edit.endSlot,
    ].join(":");
  }

  function persistCandidateEditing(edit: MeetupCandidateEdit) {
    const dateKey = weekDateKeys[edit.dayIndex];
    if (!dateKey) return;
    const key = candidateEditKey(edit);
    if (persistedCandidateEditKeyRef.current === key) return;
    persistedCandidateEditKeyRef.current = key;
    onMoveCandidateTimeRange(
      edit.id,
      slotToTokyoLocal(dateKey, edit.startSlot),
      slotToTokyoLocal(dateKey, edit.endSlot),
    );
  }

  function setCandidateEditing(
    edit: MeetupCandidateEdit | null,
    options?: { persist?: boolean },
  ) {
    candidateEditRef.current = edit;
    setCandidateEdit(edit);
    if (edit && options?.persist) persistCandidateEditing(edit);
  }

  function updateDragSelection(currentSlot: number) {
    const prev = dragRef.current;
    if (!prev) return;
    setDragSelection({ ...prev, currentSlot });
  }

  function pointToCalendarSlot(clientX: number, clientY: number) {
    const el = gridRef.current;
    if (!el) return null;
    const rect = el.getBoundingClientRect();
    const dayAreaLeft = rect.left + MEETUP_TIME_LABEL_WIDTH;
    const dayAreaWidth = rect.width - MEETUP_TIME_LABEL_WIDTH;
    const dayWidth = dayAreaWidth / MEETUP_WEEK_DAYS;
    const rawDay = Math.floor((clientX - dayAreaLeft) / dayWidth);
    const dayIndex = Math.max(0, Math.min(MEETUP_WEEK_DAYS - 1, rawDay));
    return {
      dayIndex,
      slot: calendarClientYToSlot(clientY, rect.top),
    };
  }

  function slotFromPointer(
    e: PointerEvent<HTMLDivElement>,
    el: HTMLDivElement,
  ): number {
    const rect = el.getBoundingClientRect();
    return calendarClientYToSlot(e.clientY, rect.top);
  }

  function slotFromTouch(touch: { clientY: number }, el: HTMLDivElement): number {
    const rect = el.getBoundingClientRect();
    return calendarClientYToSlot(touch.clientY, rect.top);
  }

  function findTouch(
    touches: {
      length: number;
      item: (
        index: number,
      ) => { identifier: number; clientX: number; clientY: number } | null;
    },
    identifier: number,
  ): { identifier: number; clientX: number; clientY: number } | null {
    for (let i = 0; i < touches.length; i += 1) {
      const touch = touches.item(i);
      if (touch?.identifier === identifier) return touch;
    }
    return null;
  }

  function normalizedDragRange(selection: MeetupDragSelection) {
    const startSlot = Math.min(selection.startSlot, selection.currentSlot);
    const endSlot = Math.max(selection.startSlot, selection.currentSlot) + 1;
    return { startSlot, endSlot };
  }

  function commitDrag(selection: MeetupDragSelection) {
    const { startSlot, endSlot } = normalizedDragRange(selection);
    const dateKey = weekDateKeys[selection.dayIndex];
    onTimeRangeSelect(
      slotToTokyoLocal(dateKey, startSlot),
      slotToTokyoLocal(dateKey, endSlot),
    );
  }

  function startCandidateEditing(state: MeetupCandidatePointerState) {
    if (state.timer != null && typeof window !== "undefined") {
      window.clearTimeout(state.timer);
    }
    const durationSlots = Math.max(
      1,
      state.originalEndSlot - state.originalStartSlot,
    );
    const edit: MeetupCandidateEdit = {
      id: state.id,
      action: state.action,
      originalDayIndex: state.originalDayIndex,
      dayIndex: state.originalDayIndex,
      startSlot: state.originalStartSlot,
      endSlot: state.originalEndSlot,
    };
    candidatePointerRef.current = {
      ...state,
      mode: "editing",
      timer: null,
      pointerStartOffsetSlots: Math.max(
        0,
        Math.min(durationSlots - 1, state.pointerStartOffsetSlots),
      ),
    };
    setCandidateEditing(edit);
  }

  function updateCandidateEditing(clientX: number, clientY: number) {
    const state = candidatePointerRef.current;
    if (!state || state.mode !== "editing") return;
    const point = pointToCalendarSlot(clientX, clientY);
    if (!point) return;
    const durationSlots = Math.max(
      1,
      state.originalEndSlot - state.originalStartSlot,
    );

    if (state.action === "move") {
      const startSlot = Math.max(
        0,
        Math.min(
          MEETUP_SLOT_COUNT - durationSlots,
          point.slot - state.pointerStartOffsetSlots,
        ),
      );
      setCandidateEditing({
        id: state.id,
        action: state.action,
        originalDayIndex: state.originalDayIndex,
        dayIndex: point.dayIndex,
        startSlot,
        endSlot: startSlot + durationSlots,
      }, { persist: true });
      return;
    }

    const endSlot = Math.max(
      state.originalStartSlot + 1,
      Math.min(MEETUP_SLOT_COUNT, point.slot + 1),
    );
    setCandidateEditing({
      id: state.id,
      action: state.action,
      originalDayIndex: state.originalDayIndex,
      dayIndex: state.originalDayIndex,
      startSlot: state.originalStartSlot,
      endSlot,
    }, { persist: true });
  }

  function commitCandidateEditing() {
    const edit = candidateEditRef.current;
    if (!edit) return;
    persistCandidateEditing(edit);
  }

  function handleCandidatePointerDown(
    e: PointerEvent<HTMLElement>,
    candidate: MeetupCandidate,
    action: "move" | "resize-end",
  ) {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    e.stopPropagation();
    const start = splitTokyoLocal(candidate.start);
    const end = splitTokyoLocal(candidate.end);
    const startSlot = localToCalendarSlot(candidate.start);
    const endSlot = localToCalendarSlot(candidate.end);
    if (!start || !end || startSlot == null || endSlot == null) return;
    const dayIndex = weekDateKeys.indexOf(start.dateKey);
    if (dayIndex < 0) return;
    if (candidatePointerRef.current?.timer != null && typeof window !== "undefined") {
      window.clearTimeout(candidatePointerRef.current.timer);
    }
    onSelectCandidate(candidate.id);
    const point = pointToCalendarSlot(e.clientX, e.clientY);
    const timer =
      e.pointerType === "touch" && typeof window !== "undefined"
        ? window.setTimeout(() => {
            const state = candidatePointerRef.current;
            if (!state || state.id !== candidate.id || state.mode !== "pending") {
              return;
            }
            startCandidateEditing(state);
          }, MEETUP_LONG_PRESS_MS)
        : null;
    const state: MeetupCandidatePointerState = {
      id: candidate.id,
      action,
      pointerId: e.pointerId,
      pointerType: e.pointerType,
      startX: e.clientX,
      startY: e.clientY,
      originalDayIndex: dayIndex,
      originalStartSlot: Math.max(0, Math.min(MEETUP_SLOT_COUNT - 1, startSlot)),
      originalEndSlot: Math.max(1, Math.min(MEETUP_SLOT_COUNT, endSlot)),
      pointerStartOffsetSlots:
        point && point.dayIndex === dayIndex
          ? point.slot - startSlot
          : 0,
      mode:
        action === "resize-end" && e.pointerType !== "touch"
          ? "editing"
          : "pending",
      timer,
    };
    candidatePointerRef.current = state;
    e.currentTarget.setPointerCapture(e.pointerId);
    if (state.mode === "editing") {
      e.preventDefault();
      startCandidateEditing(state);
    }
  }

  function handleCandidatePointerMove(e: PointerEvent<HTMLElement>) {
    const state = candidatePointerRef.current;
    if (!state || state.pointerId !== e.pointerId) return;
    e.stopPropagation();
    const dx = e.clientX - state.startX;
    const dy = e.clientY - state.startY;
    if (state.mode === "pending") {
      if (
        state.pointerType === "touch" &&
        Math.hypot(dx, dy) > MEETUP_TOUCH_CANCEL_PX
      ) {
        clearCandidatePointer();
        return;
      }
      if (state.pointerType !== "touch" && Math.hypot(dx, dy) > 4) {
        startCandidateEditing(state);
      } else {
        return;
      }
    }
    e.preventDefault();
    updateCandidateEditing(e.clientX, e.clientY);
  }

  function handleCandidatePointerUp(e: PointerEvent<HTMLElement>) {
    const state = candidatePointerRef.current;
    if (!state || state.pointerId !== e.pointerId) return;
    e.stopPropagation();
    const wasEditing = state.mode === "editing" || !!candidateEditRef.current;
    if (wasEditing) {
      e.preventDefault();
      updateCandidateEditing(e.clientX, e.clientY);
      commitCandidateEditing();
    } else {
      onOpenPlaceSheet(state.id);
    }
    clearCandidatePointer();
  }

  function handleCandidatePointerCancel(e: PointerEvent<HTMLElement>) {
    const state = candidatePointerRef.current;
    if (!state || state.pointerId !== e.pointerId) return;
    e.stopPropagation();
    if (state.mode === "editing" || candidateEditRef.current) {
      commitCandidateEditing();
    }
    clearCandidatePointer();
  }

  function handlePointerDown(
    e: PointerEvent<HTMLDivElement>,
    dayIndex: number,
  ) {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    if (e.pointerType === "touch") return;
    e.preventDefault();
    e.currentTarget.setPointerCapture(e.pointerId);
    const slot = slotFromPointer(e, e.currentTarget);
    setDragSelection({ dayIndex, startSlot: slot, currentSlot: slot });
  }

  function handlePointerMove(e: PointerEvent<HTMLDivElement>) {
    if (!dragRef.current) return;
    if (e.pointerType !== "touch") e.preventDefault();
    const slot = slotFromPointer(e, e.currentTarget);
    updateDragSelection(slot);
  }

  function handlePointerUp(e: PointerEvent<HTMLDivElement>) {
    const selection = dragRef.current;
    if (!selection) return;
    if (e.pointerType !== "touch") e.preventDefault();
    const next = {
      ...selection,
      currentSlot: slotFromPointer(e, e.currentTarget),
    };
    commitDrag(next);
    setDragSelection(null);
  }

  function handleDayTouchStart(
    e: TouchEvent<HTMLDivElement>,
    dayIndex: number,
  ) {
    if (e.touches.length !== 1 || typeof window === "undefined") return;
    clearTouchPress();
    const touch = e.touches[0];
    const target = e.currentTarget;
    const startSlot = slotFromTouch(touch, target);
    const timer = window.setTimeout(() => {
      if (!touchPressRef.current || touchPressRef.current.mode !== "pending") {
        return;
      }
      touchPressRef.current.mode = "dragging";
      setDragSelection({ dayIndex, startSlot, currentSlot: startSlot });
    }, MEETUP_LONG_PRESS_MS);
    touchPressRef.current = {
      timer,
      mode: "pending",
      dayIndex,
      startSlot,
      identifier: touch.identifier,
      startX: touch.clientX,
      startY: touch.clientY,
      scrollTop: scrollRef.current?.scrollTop ?? 0,
    };
  }

  function handleDayTouchMove(e: TouchEvent<HTMLDivElement>) {
    const press = touchPressRef.current;
    if (press) {
      const touch = findTouch(e.touches, press.identifier);
      if (!touch) {
        clearTouchPress();
        return;
      }
      const dx = touch.clientX - press.startX;
      const dy = touch.clientY - press.startY;
      if (press.mode === "pending") {
        if (
          Math.hypot(dx, dy) > MEETUP_TOUCH_CANCEL_PX ||
          Math.abs(dy) > MEETUP_TOUCH_CANCEL_PX
        ) {
          window.clearTimeout(press.timer);
          if (Math.abs(dy) > Math.abs(dx)) {
            press.mode = "scrolling";
          } else {
            clearTouchPress();
            return;
          }
        }
      }

      if (press.mode === "scrolling") {
        if (scrollRef.current) {
          scrollRef.current.scrollTop = press.scrollTop - dy;
        }
        e.preventDefault();
        return;
      }

      if (press.mode === "dragging") {
        e.preventDefault();
        e.stopPropagation();
        updateDragSelection(slotFromTouch(touch, e.currentTarget));
        return;
      }
    }

    if (!dragRef.current) return;
    const touch = e.touches[0];
    if (!touch) return;
    e.preventDefault();
    e.stopPropagation();
    updateDragSelection(slotFromTouch(touch, e.currentTarget));
  }

  function handleDayTouchEnd(e: TouchEvent<HTMLDivElement>) {
    const selection = dragRef.current;
    const press = touchPressRef.current;
    clearTouchPress();
    if (!selection || press?.mode !== "dragging") {
      setDragSelection(null);
      return;
    }
    const touch =
      findTouch(e.changedTouches, press.identifier) ?? e.changedTouches[0];
    if (!touch) return;
    e.preventDefault();
    e.stopPropagation();
    const next = {
      ...selection,
      currentSlot: slotFromTouch(touch, e.currentTarget),
    };
    commitDrag(next);
    setDragSelection(null);
  }

  function handleDayTouchCancel() {
    clearTouchPress();
    setDragSelection(null);
  }

  const preview =
    drag == null
      ? null
      : {
          dayIndex: drag.dayIndex,
          ...normalizedDragRange(drag),
        };
  const todayIndex = nowParts ? weekDateKeys.indexOf(nowParts.dateKey) : -1;
  const currentTimeTop =
    nowParts && todayIndex >= 0
      ? calendarSlotTop(
          (nowParts.minutes - MEETUP_CALENDAR_START_HOUR * 60) /
            MEETUP_SLOT_MINUTES,
        )
      : null;
  const showCurrentTime =
    currentTimeTop != null &&
    currentTimeTop >= MEETUP_CALENDAR_TOP_PADDING &&
    currentTimeTop <= MEETUP_CALENDAR_TOP_PADDING + MEETUP_TIMELINE_HEIGHT;
  const showEmptyHint =
    !preview && !candidateEdit && !candidates.some(candidateHasTime);

  function handleCalendarTouchStart(e: TouchEvent<HTMLDivElement>) {
    if (e.touches.length !== 1) return;
    const touch = e.touches[0];
    calendarSwipeRef.current = {
      startX: touch.clientX,
      startY: touch.clientY,
    };
  }

  function handleCalendarTouchEnd(e: TouchEvent<HTMLDivElement>) {
    const state = calendarSwipeRef.current;
    calendarSwipeRef.current = null;
    const touch = e.changedTouches[0];
    if (!state || !touch) return;
    const dx = touch.clientX - state.startX;
    const dy = touch.clientY - state.startY;
    if (Math.abs(dx) < 58 || Math.abs(dx) < Math.abs(dy) * 1.4) return;
    onShiftWeek(dx < 0 ? 1 : -1);
  }

  return (
    <div
      data-propose-swipe-ignore
      className="h-full select-none bg-white [-webkit-touch-callout:none] [-webkit-user-select:none]"
      onTouchStart={handleCalendarTouchStart}
      onTouchEnd={handleCalendarTouchEnd}
      onContextMenu={(e) => e.preventDefault()}
      onSelect={(e) => e.preventDefault()}
    >
      <style>{`
        @keyframes megrum-meetup-hint-breathe {
          0%, 100% { transform: scale(0.985); opacity: 0.82; }
          50% { transform: scale(1.035); opacity: 0.94; }
        }
      `}</style>
      <div className="relative h-[calc(100dvh-250px)] min-h-0">
        <div
          ref={scrollRef}
          className="h-full overflow-y-auto overscroll-y-contain [-webkit-overflow-scrolling:touch]"
        >
          <div className="sticky top-0 z-20 grid grid-cols-[52px_repeat(5,minmax(0,1fr))] border-b border-[#3a324a12] bg-white shadow-[0_2px_8px_rgba(58,50,74,0.05)]">
            <div />
            {weekDateKeys.map((dateKey, index) => (
              <div
                key={dateKey}
                className={`px-0.5 pb-2 pt-3 text-center ${
                  index === todayIndex
                    ? "bg-[#a695d814] text-[#a695d8]"
                    : index === 0
                      ? "text-[#a695d8]"
                      : "text-[#3a324acc]"
                }`}
              >
                <div className="text-[10px] font-extrabold">
                  {formatDateKeyWeekday(dateKey)}
                </div>
                <div className="mt-1 text-[22px] font-semibold leading-none tabular-nums">
                  {formatDateKeyDayNumber(dateKey)}
                </div>
              </div>
            ))}
          </div>
          <div
            ref={gridRef}
            className="relative grid grid-cols-[52px_repeat(5,minmax(0,1fr))] border-t-2 border-[#24a7f2]"
            style={{
              height:
                MEETUP_CALENDAR_TOP_PADDING +
                MEETUP_TIMELINE_HEIGHT +
                MEETUP_CALENDAR_BOTTOM_PADDING,
            }}
          >
        <div className="relative border-r border-[#3a324a12] bg-white">
          {Array.from(
            {
              length:
                MEETUP_CALENDAR_END_HOUR - MEETUP_CALENDAR_START_HOUR + 1,
            },
            (_, index) => MEETUP_CALENDAR_START_HOUR + index,
          ).map((hour) => (
            <div
              key={hour}
              className="absolute right-2 text-[11px] font-semibold text-[#3a324a8c]"
              style={{
                top:
                  (hour - MEETUP_CALENDAR_START_HOUR) *
                    (60 / MEETUP_SLOT_MINUTES) *
                    MEETUP_SLOT_HEIGHT +
                  MEETUP_CALENDAR_TOP_PADDING -
                  5,
              }}
            >
              {hour}:00
            </div>
          ))}
          {showCurrentTime && (
            <div
              className="absolute right-1 z-20 -translate-y-1/2 rounded-full bg-[#a695d8] px-1.5 py-[1px] text-[8.5px] font-extrabold leading-tight text-white shadow-[0_2px_6px_rgba(166,149,216,0.28)]"
              style={{ top: currentTimeTop ?? 0 }}
            >
              今
            </div>
          )}
        </div>
        {weekDateKeys.map((dateKey, dayIndex) => (
          <div
            key={dateKey}
            className={`relative select-none border-r border-[#3a324a0d] last:border-r-0 [-webkit-touch-callout:none] [-webkit-user-select:none] ${
              dayIndex === todayIndex ? "bg-[#a695d80a]" : ""
            }`}
            onPointerDown={(e) => handlePointerDown(e, dayIndex)}
            onPointerMove={handlePointerMove}
            onPointerUp={handlePointerUp}
            onPointerCancel={() => {
              clearTouchPress();
              setDragSelection(null);
            }}
            onTouchStart={(e) => handleDayTouchStart(e, dayIndex)}
            onTouchMove={handleDayTouchMove}
            onTouchEnd={handleDayTouchEnd}
            onTouchCancel={handleDayTouchCancel}
            style={{ touchAction: "none" }}
          >
            {Array.from({ length: MEETUP_SLOT_COUNT / 4 }, (_, hourIndex) => (
              <div
                key={hourIndex}
                className="absolute inset-x-0 border-t border-[#3a324a0a]"
                style={{
                  top:
                    MEETUP_CALENDAR_TOP_PADDING +
                    hourIndex * 4 * MEETUP_SLOT_HEIGHT,
                }}
              />
            ))}
            {showCurrentTime && dayIndex === todayIndex && (
              <div
                className="pointer-events-none absolute left-0 right-0 z-20 border-t-2 border-[#a695d8] shadow-[0_0_8px_rgba(166,149,216,0.38)]"
                style={{ top: currentTimeTop ?? 0 }}
              >
                <span className="absolute -left-[3px] top-[-4px] h-2 w-2 rounded-full bg-[#a695d8]" />
              </div>
            )}
            {candidates.map((candidate, index) => {
              const edit =
                candidateEdit?.id === candidate.id ? candidateEdit : null;
              const block = edit
                ? {
                    dayIndex: edit.originalDayIndex,
                    top: calendarSlotTop(edit.startSlot),
                    height: Math.max(
                      MEETUP_SLOT_HEIGHT,
                      (edit.endSlot - edit.startSlot) * MEETUP_SLOT_HEIGHT,
                    ),
                  }
                : getCalendarBlock(candidate, weekDateKeys);
              if (!block || block.dayIndex !== dayIndex) return null;
              const active = candidate.id === activeMeetupId;
              const placeMissing = !candidate.place.trim();
              const dayShift = edit ? edit.dayIndex - edit.originalDayIndex : 0;
              const liftTransform = edit ? "translateY(-4px) scale(1.035)" : "";
              const dayShiftTransform = dayShift
                ? `translateX(calc(${dayShift * 100}% + ${dayShift * 8}px))`
                : "";
              const candidateTransform =
                [dayShiftTransform, liftTransform].filter(Boolean).join(" ") ||
                undefined;
              return (
                <div
                  key={candidate.id}
                  role="button"
                  tabIndex={0}
                  onPointerDown={(e) =>
                    handleCandidatePointerDown(e, candidate, "move")
                  }
                  onPointerMove={handleCandidatePointerMove}
                  onPointerUp={handleCandidatePointerUp}
                  onPointerCancel={handleCandidatePointerCancel}
                  onTouchStart={(e) => e.stopPropagation()}
                  onTouchMove={(e) => e.stopPropagation()}
                  onTouchEnd={(e) => e.stopPropagation()}
                  onTouchCancel={(e) => e.stopPropagation()}
                  onKeyDown={(e) => {
                    if (e.key !== "Enter" && e.key !== " ") return;
                    e.preventDefault();
                    onSelectCandidate(candidate.id);
                    onOpenPlaceSheet(candidate.id);
                  }}
                  className={`absolute left-[4px] right-[4px] flex items-center rounded-[8px] border py-1 pl-1.5 pr-5 text-left text-[8.5px] font-extrabold leading-tight transition-[transform,box-shadow,filter] duration-200 ease-out will-change-transform ${
                    edit
                      ? "shadow-[0_18px_34px_rgba(58,50,74,0.24)] brightness-[1.04]"
                      : "shadow-[0_4px_12px_rgba(36,167,242,0.18)]"
                  } ${
                    active ? "ring-2 ring-[#a8d4e6]" : ""
                  } ${
                    placeMissing
                      ? "border-[#fb923c] bg-[#fff7ed] text-[#9a3412] ring-2 ring-[#fb923c33]"
                      : "border-[#24a7f2] bg-[#24a7f2] text-white"
                  }`}
                  style={{
                    top: block.top,
                    height: block.height,
                    touchAction: "none",
                    transform: candidateTransform,
                    transformOrigin: "center center",
                    zIndex: edit ? 35 : undefined,
                  }}
                >
                  {placeMissing ? (
                    <span className="pointer-events-none absolute left-1/2 top-1/2 flex h-[18px] w-[18px] -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full bg-[#fb923c] text-[11px] font-black leading-none text-white shadow-[0_2px_7px_rgba(251,146,60,0.34)]">
                      !
                    </span>
                  ) : (
                    <span className="block min-w-0 truncate font-bold">
                      {candidate.place}
                    </span>
                  )}
                  <button
                    type="button"
                    aria-label={`候補${index + 1}を削除`}
                    onPointerDown={(e) => e.stopPropagation()}
                    onClick={(e) => {
                      e.stopPropagation();
                      onDeleteCandidate(candidate.id);
                    }}
                    className={`absolute right-1 top-1 flex h-4 w-4 items-center justify-center rounded-full text-[10px] font-black leading-none ${
                      placeMissing
                        ? "bg-[#9a3412]/12 text-[#9a3412]"
                        : "bg-white/22 text-white"
                    }`}
                  >
                    ×
                  </button>
                  <span
                    role="separator"
                    aria-label={`候補${index + 1}の終了時間を変更`}
                    onPointerDown={(e) =>
                      handleCandidatePointerDown(e, candidate, "resize-end")
                    }
                    onPointerMove={handleCandidatePointerMove}
                    onPointerUp={handleCandidatePointerUp}
                    onPointerCancel={handleCandidatePointerCancel}
                    className={`absolute inset-x-2 bottom-[2px] h-[5px] cursor-ns-resize rounded-full ${
                      placeMissing ? "bg-[#fb923c66]" : "bg-white/55"
                    }`}
                    style={{ touchAction: "none" }}
                  />
                </div>
              );
            })}
            {preview && preview.dayIndex === dayIndex && (
              <div
                className="pointer-events-none absolute left-[4px] right-[4px] rounded-[7px] border border-[#24a7f2] bg-[#24a7f233]"
                style={{
                  top: calendarSlotTop(preview.startSlot),
                  height:
                    (preview.endSlot - preview.startSlot) * MEETUP_SLOT_HEIGHT,
                }}
              />
            )}
          </div>
        ))}
          </div>
        </div>
        {showEmptyHint && (
          <div className="pointer-events-none absolute bottom-0 left-[52px] right-0 top-[58px] z-30 flex items-center justify-center px-4">
            <div className="w-full max-w-[248px] rounded-[22px] bg-black/58 px-5 py-4 text-center shadow-[0_18px_42px_rgba(0,0,0,0.20)] [animation:megrum-meetup-hint-breathe_2.6s_ease-in-out_infinite]">
              <p className="text-[13px] font-extrabold leading-snug text-white">
                長押しで時間を選択できるよ
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function PlacePickerSheet({
  candidateLabel,
  timeLabel,
  meetupPlace,
  onPlaceInputChange,
  meetupCenter,
  onMapCenterChange,
  reverseFetching,
  searchQ,
  setSearchQ,
  searchResults,
  searching,
  showResults,
  setShowResults,
  pickPlace,
  useCurrentLocation,
  onUsePreviousPlace,
  canUsePreviousPlace,
  previousPlaceName,
  onClose,
}: {
  candidateLabel: string;
  timeLabel: string;
  meetupPlace: string;
  onPlaceInputChange: (s: string) => void;
  meetupCenter: [number, number];
  onMapCenterChange: (lat: number, lng: number) => void;
  reverseFetching: boolean;
  searchQ: string;
  setSearchQ: (s: string) => void;
  searchResults: Place[];
  searching: boolean;
  showResults: boolean;
  setShowResults: (b: boolean) => void;
  pickPlace: (p: Place) => void;
  useCurrentLocation: () => void;
  onUsePreviousPlace: () => void;
  canUsePreviousPlace: boolean;
  previousPlaceName: string;
  onClose: () => void;
}) {
  const placeSet = !!meetupPlace.trim();
  const [previousAppliedPlace, setPreviousAppliedPlace] = useState<
    string | null
  >(null);
  const previousApplied = placeSet && previousAppliedPlace === meetupPlace;

  function handleUsePreviousPlace() {
    if (!canUsePreviousPlace) return;
    onUsePreviousPlace();
    setPreviousAppliedPlace(previousPlaceName);
  }

  return (
    <div
      data-propose-swipe-ignore
      className="fixed inset-0 z-40 flex items-end bg-[#1a1624]/32 px-3 pb-[max(env(safe-area-inset-bottom),12px)] pt-10 backdrop-blur-[2px]"
      onPointerDown={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div className="mx-auto w-full max-w-md overflow-hidden rounded-[22px] bg-white shadow-[0_-16px_46px_rgba(58,50,74,0.22)]">
        <div className="flex items-start justify-between gap-3 border-b border-[#3a324a12] px-4 pb-3 pt-4">
          <div className="min-w-0">
            <div className="text-[10.5px] font-extrabold text-[#a695d8]">
              {candidateLabel}
            </div>
            <div className="mt-0.5 truncate text-[13px] font-extrabold text-[#3a324a]">
              {timeLabel}
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-full bg-[#3a324a08] px-3 py-1.5 text-[11px] font-extrabold text-[#3a324a8c]"
          >
            閉じる
          </button>
        </div>

        <div className="max-h-[72vh] overflow-y-auto px-4 py-3">
          <div className="mb-1 flex items-center justify-between gap-2 px-0.5">
            <span className="text-[9.5px] font-bold tracking-[0.4px] text-[#3a324a8c]">
              交換できる場所
            </span>
          </div>
          <input
            type="text"
            value={meetupPlace}
            onChange={(e) => onPlaceInputChange(e.target.value)}
            maxLength={120}
            placeholder={reverseFetching ? "取得中…" : "場所未設定"}
            className={`mb-2 block w-full rounded-lg border-[0.5px] border-[#3a324a14] bg-[#fbf9fc] px-3 py-2.5 text-[12px] font-semibold text-[#3a324a] focus:border-[#a695d8] focus:outline-none ${
              reverseFetching
                ? "placeholder:text-[#a695d8]"
                : "placeholder:text-[#d9826b]"
            }`}
          />

          <div className="relative mb-2">
            <input
              type="text"
              value={searchQ}
              onChange={(e) => setSearchQ(e.target.value)}
              onFocus={() => searchResults.length && setShowResults(true)}
              placeholder="🔍 駅・施設名で検索"
              className="block w-full rounded-lg border-[0.5px] border-[#3a324a14] bg-white px-3 py-2.5 text-[12px] text-[#3a324a] placeholder:text-[#3a324a4d] focus:border-[#a695d8] focus:outline-none"
            />
            {searching && (
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] text-[#3a324a8c]">
                …
              </span>
            )}
            {showResults && searchResults.length > 0 && (
              <div className="absolute left-0 right-0 top-full z-30 mt-1 max-h-52 overflow-y-auto rounded-lg border border-[#3a324a14] bg-white shadow-[0_8px_20px_rgba(58,50,74,0.12)]">
                {searchResults.slice(0, 10).map((p, i) => (
                  <button
                    key={`${p.lat}-${p.lon}-${i}`}
                    type="button"
                    onClick={() => pickPlace(p)}
                    className="block w-full border-b border-[#3a324a08] px-3 py-2 text-left last:border-0 hover:bg-[#a695d80a]"
                  >
                    <div className="text-[12px] font-semibold text-[#3a324a]">
                      {labelFromAddress(p)}
                    </div>
                    <div className="mt-0.5 truncate text-[10px] text-[#3a324a8c]">
                      {p.display_name}
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>

          <div className="mb-2 flex items-center justify-between gap-2">
            <button
              type="button"
              onClick={useCurrentLocation}
              className="flex min-w-0 items-center gap-1.5 rounded-full border border-[#a695d855] bg-white px-3 py-1.5 text-[10.5px] font-bold text-[#a695d8] shadow-sm active:scale-[0.97]"
            >
              📍 現在地を中心に
            </button>
            {canUsePreviousPlace && (
              <button
                type="button"
                onClick={handleUsePreviousPlace}
                className={`flex-shrink-0 rounded-full px-3.5 py-2 text-[10.5px] font-extrabold shadow-[0_5px_14px_rgba(36,167,242,0.24)] transition-colors active:scale-[0.97] ${
                  previousApplied
                    ? "border border-[#7a9a8a] bg-[#7a9a8a] text-white"
                    : "border border-[#1b91db] bg-[#24a7f2] text-white"
                }`}
              >
                {previousApplied ? "適用済み" : "前の設定と同じに"}
              </button>
            )}
          </div>

          <div className="overflow-hidden rounded-[12px] border-[0.5px] border-[#3a324a14] bg-[#e8eef0]">
            <div className="h-[240px] w-full">
              <ProposeMapPicker
                center={meetupCenter}
                radiusM={120}
                onCenterChange={onMapCenterChange}
                className="h-full w-full"
              />
            </div>
          </div>
        </div>

        <div className="border-t border-[#3a324a12] px-4 pb-4 pt-3">
          <button
            type="button"
            disabled={!placeSet}
            onClick={onClose}
            className="w-full rounded-[14px] bg-[linear-gradient(135deg,#a695d8,#a8d4e6)] px-5 py-3.5 text-[13px] font-extrabold text-white shadow-[0_6px_18px_rgba(166,149,216,0.28)] disabled:opacity-45 disabled:shadow-none"
          >
            この場所で設定
          </button>
        </div>
      </div>
    </div>
  );
}

function ConfirmStep({
  partnerHandle,
  myItems,
  theirItems,
  meetupCandidates,
  message,
  onMessageChange,
  exposeCalendar,
  onExposeCalendarChange,
  error,
}: {
  partnerHandle: string;
  myItems: Selectable[];
  theirItems: Selectable[];
  meetupCandidates: MeetupCandidate[];
  message: string;
  onMessageChange: (m: string) => void;
  exposeCalendar: boolean;
  onExposeCalendarChange: (b: boolean) => void;
  error: string | null;
}) {
  return (
    <>
      <div className="mb-3 rounded-[10px] bg-[#a695d810] px-3 py-2.5 text-[11.5px] leading-relaxed text-[#3a324a]">
        <span className="mr-1.5 inline-block rounded-full bg-white px-1.5 py-0.5 text-[9.5px] font-extrabold tracking-[0.4px] text-[#a695d8]">
          📨 送信確認
        </span>
        @{partnerHandle} に下記の内容で打診を送ります。送信後 7 日間が応答期限です。
      </div>

      {/* 交換内容（マッチパネル風グリッド：相手の譲 ↔ 私の譲） */}
      <Section label="交換内容">
        <div className="grid grid-cols-[1fr_auto_1fr] items-start gap-2.5 rounded-[14px] bg-[#a8d4e614] p-2.5">
          <SidePanel
            label={`相手の譲（${theirItems.length}）`}
            items={theirItems}
            align="left"
          />
          <div className="flex flex-col items-center gap-1 pt-4">
            <ArrowDot color="#a695d8" dir="right" />
            <ArrowDot color="#a8d4e6" dir="left" />
          </div>
          <SidePanel
            label={`あなたの譲（${myItems.length}）`}
            items={myItems}
            align="right"
            accent="#f3c5d4cc"
          />
        </div>
      </Section>

      {/* 待ち合わせ：交換できる候補 */}
      <Section label="交換できる候補">
        <MeetupPlanPreview candidates={meetupCandidates} />
      </Section>

      {/* iter138: メッセージ入力（任意・空でも送信可能）+ スケジュール共有トグル */}
      <Section label="メッセージ（任意）" hint={`${message.length} / 400`}>
        <textarea
          value={message}
          onChange={(e) => onMessageChange(e.target.value)}
          rows={5}
          maxLength={400}
          className="block w-full resize-none rounded-[14px] border-[0.5px] border-[#3a324a14] bg-white p-3 text-[13px] leading-relaxed text-[#3a324a] placeholder:text-[#3a324a4d] focus:border-[#a695d8] focus:outline-none"
        />
      </Section>

      <Section label="スケジュール共有">
        <button
          type="button"
          onClick={() => onExposeCalendarChange(!exposeCalendar)}
          className={`flex w-full items-start gap-2.5 rounded-[14px] p-3 text-left transition-colors ${
            exposeCalendar
              ? "border-[1.5px] border-[#a695d8] bg-[#a695d810]"
              : "border-[0.5px] border-[#3a324a14] bg-white"
          }`}
        >
          <span
            className={`mt-0.5 flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-full border-[1.5px] ${
              exposeCalendar
                ? "border-[#a695d8] bg-[#a695d8]"
                : "border-[#3a324a14] bg-white"
            }`}
          >
            {exposeCalendar && (
              <svg width="11" height="11" viewBox="0 0 11 11">
                <path
                  d="M2 5.5L4.5 8L9 3"
                  stroke="#fff"
                  strokeWidth="2"
                  fill="none"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            )}
          </span>
          <span className="flex-1">
            <span className="block text-[12.5px] font-bold text-[#3a324a]">
              スケジュールを共有する
              <span className="ml-1 text-[10px] font-normal text-[#3a324a8c]">
                {exposeCalendar ? "ON" : "OFF"}
              </span>
            </span>
            <span className="mt-0.5 block text-[10.5px] leading-snug text-[#3a324a8c]">
              あなたの予定（取引以外も含む）が相手に表示されます。日時を相談するときに便利。
            </span>
          </span>
        </button>
      </Section>

      {error && (
        <div className="mt-3 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}
    </>
  );
}

function getMeetupMapCenter(candidates: MeetupCandidate[]): [number, number] {
  if (candidates.length === 0) return FALLBACK_CENTER;
  const sum = candidates.reduce(
    (acc, candidate) => ({
      lat: acc.lat + candidate.center[0],
      lng: acc.lng + candidate.center[1],
    }),
    { lat: 0, lng: 0 },
  );
  return [sum.lat / candidates.length, sum.lng / candidates.length];
}

function getMeetupPreviewMarkers(
  candidates: MeetupCandidate[],
): MapPreviewMarker[] {
  return candidates.map((candidate, index) => ({
    center: candidate.center,
    label: String(index + 1),
  }));
}

function MeetupPlanPreview({
  candidates,
}: {
  candidates: MeetupCandidate[];
}) {
  const markers = getMeetupPreviewMarkers(candidates);
  const mapCenter = getMeetupMapCenter(candidates);

  return (
    <div className="overflow-hidden rounded-[18px] border border-[#3a324a14] bg-white shadow-[0_8px_24px_rgba(58,50,74,0.07)]">
      <div className="flex items-center justify-between gap-2 border-b border-[#3a324a12] bg-[linear-gradient(135deg,#fbf9fc,#ffffff)] px-3 py-2.5">
        <div className="min-w-0 text-[12px] font-extrabold text-[#3a324a]">
          待ち合わせ候補
        </div>
        <div className="rounded-full bg-[#a695d814] px-2 py-1 text-[9.5px] font-extrabold text-[#a695d8]">
          {candidates.length}件
        </div>
      </div>

      <div className="h-[210px] w-full border-b border-[#3a324a12] bg-[#e8eef0]">
        <ProposeMapPicker
          center={mapCenter}
          radiusM={120}
          markers={markers}
          interactive={false}
          onCenterChange={() => {}}
          className="h-full w-full"
        />
      </div>

      <div className="grid gap-1.5 px-3 py-2.5">
        {candidates.map((candidate, index) => (
          <div key={candidate.id} className="flex items-start gap-2">
            <span className="mt-0.5 flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-full bg-[#a695d8] text-[10px] font-extrabold text-white">
              {index + 1}
            </span>
            <div className="min-w-0 flex-1">
              <div className="truncate text-[11.5px] font-extrabold tabular-nums text-[#3a324a]">
                {formatRange(candidate.start, candidate.end)}
              </div>
              <div className="truncate text-[10.5px] font-bold text-[#3a324a8c]">
                {candidate.place}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

/** 1 アイテム = 写真 or イニシャルの縦長カード */
function Tcg({ item, accent }: { item: Selectable; accent?: string }) {
  const hue =
    Math.abs(
      (item.characterId ?? item.groupId ?? item.id)
        .split("")
        .reduce((s, c) => s + c.charCodeAt(0), 0),
    ) % 360;
  const stripeBg = `repeating-linear-gradient(135deg, hsl(${hue}, 28%, 86%) 0 5px, hsl(${hue}, 28%, 78%) 5px 10px)`;
  const initialShadow = `0 1px 3px hsla(${hue}, 30%, 30%, 0.5)`;
  const hasPhoto = !!item.photoUrl;
  const label =
    item.characterName ?? item.groupName ?? item.title ?? "?";

  return (
    <div
      className="relative overflow-hidden rounded-md border border-white/40 shadow-[0_1px_3px_rgba(58,50,74,0.15)]"
      style={{
        width: 36,
        height: 48,
        background: hasPhoto ? "#3a324a" : stripeBg,
      }}
      title={`${label}${item.goodsTypeName ? ` · ${item.goodsTypeName}` : ""} ×${item.selectedQty}`}
    >
      {hasPhoto && (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={item.photoUrl!}
          alt={label}
          className="absolute inset-0 h-full w-full object-cover"
          loading="lazy"
        />
      )}
      {!hasPhoto && (
        <div
          className="absolute inset-0 flex items-center justify-center text-[16px] font-extrabold text-white/95"
          style={{ textShadow: initialShadow }}
        >
          {label[0] || "?"}
        </div>
      )}
      {accent && !hasPhoto && (
        <div
          className="absolute inset-x-0 bottom-0 h-1"
          style={{ background: accent }}
        />
      )}
      {item.selectedQty > 1 && (
        <div className="absolute right-0.5 top-0.5 rounded-sm bg-black/55 px-1 text-[8px] font-extrabold leading-tight text-white">
          ×{item.selectedQty}
        </div>
      )}
    </div>
  );
}

function SidePanel({
  label,
  items,
  align,
  accent,
}: {
  label: string;
  items: Selectable[];
  align: "left" | "right";
  accent?: string;
}) {
  return (
    <div>
      <div
        className={`mb-1.5 px-1 text-[9.5px] font-bold tracking-[0.6px] text-[#3a324a8c] ${
          align === "right" ? "text-right" : "text-left"
        }`}
      >
        {label}
      </div>
      {items.length === 0 ? (
        <div
          className={`px-1 text-[10px] italic text-[#3a324a4d] ${
            align === "right" ? "text-right" : "text-left"
          }`}
        >
          —
        </div>
      ) : (
        <div
          className={`flex flex-wrap gap-1 px-1 ${
            align === "right" ? "justify-end" : "justify-start"
          }`}
        >
          {items.map((it) => (
            <Tcg key={it.id} item={it} accent={accent} />
          ))}
        </div>
      )}
    </div>
  );
}

function ArrowDot({
  color,
  dir,
}: {
  color: string;
  dir: "left" | "right";
}) {
  return (
    <div
      className="flex h-5 w-5 items-center justify-center rounded-full text-white"
      style={{
        background: color,
        boxShadow: `0 2px 5px ${color}80`,
      }}
    >
      <svg width="10" height="10" viewBox="0 0 10 10">
        {dir === "right" ? (
          <path
            d="M2 5h6m-2-2l2 2-2 2"
            stroke="#fff"
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
            fill="none"
          />
        ) : (
          <path
            d="M8 5H2m2-2L2 5l2 2"
            stroke="#fff"
            strokeWidth="1.6"
            strokeLinecap="round"
            strokeLinejoin="round"
            fill="none"
          />
        )}
      </svg>
    </div>
  );
}

function Section({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mb-3.5">
      <div className="mb-1.5 flex items-baseline justify-between px-1">
        <span className="text-[10.5px] font-bold uppercase tracking-[0.6px] text-[#3a324a8c]">
          {label}
        </span>
        {hint && (
          <span className="text-[9.5px] font-bold text-[#a695d8]">{hint}</span>
        )}
      </div>
      {children}
    </div>
  );
}
