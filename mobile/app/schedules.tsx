import { useEffect, useMemo, useRef, useState } from "react";
import {
  Animated,
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
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import { useAuth } from "../src/auth/AuthProvider";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type ScheduleItem = {
  id: string;
  title: string;
  placeName: string | null;
  startAt: string;
  endAt: string;
  allDay: boolean;
  note: string | null;
};

type ScheduleBlock = {
  id: string;
  title: string;
  placeName: string | null;
  dateId: string;
  dayIndex: number;
  startSlot: number;
  endSlot: number;
};

type ScheduleDraft = {
  id: string | null;
  title: string;
  placeName: string;
  dateId: string;
  startSlot: number;
  endSlot: number;
  allDay: boolean;
  note: string;
};

type CalendarDay = {
  id: string;
  day: string;
  date: string;
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

type BlockEdit = {
  id: string;
  action: "move" | "resize-end";
  dateId: string;
  dayIndex: number;
  startSlot: number;
  endSlot: number;
};

type BlockTouchState = {
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

const SLOT_MINUTES = 15;
const SLOT_COUNT = 24 * (60 / SLOT_MINUTES);
const SLOT_HEIGHT = 16;
const HOUR_HEIGHT = SLOT_HEIGHT * (60 / SLOT_MINUTES);
const TIME_LABEL_WIDTH = 52;
const CALENDAR_TOP_PADDING = 16;
const CALENDAR_BOTTOM_PADDING = 72;
const LONG_PRESS_MS = 280;
const TOUCH_CANCEL_PX = 12;
const HOURS = Array.from({ length: 24 }, (_, hour) => hour);

const PREVIEW_SCHEDULES: ScheduleItem[] = [
  {
    id: "preview-schedule-1",
    title: "ライブ参戦",
    placeName: "横浜アリーナ",
    startAt: new Date(Date.now() + 1000 * 60 * 60 * 24).toISOString(),
    endAt: new Date(Date.now() + 1000 * 60 * 60 * 30).toISOString(),
    allDay: false,
    note: "会場周辺にいる予定",
  },
];

export default function SchedulesScreen() {
  const { previewMode, user } = useAuth();
  const [items, setItems] = useState<ScheduleItem[]>(() =>
    !supabase || previewMode ? PREVIEW_SCHEDULES : [],
  );
  const [loading, setLoading] = useState(!!supabase && !previewMode);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [draft, setDraft] = useState<ScheduleDraft | null>(null);

  useEffect(() => {
    if (!supabase || previewMode) {
      setItems(PREVIEW_SCHEDULES);
      setLoading(false);
      setError(null);
      return;
    }
    if (!user) {
      setItems([]);
      setLoading(false);
      setError(null);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);
    fetchSchedules(user.id)
      .then((next) => {
        if (active) setItems(next);
      })
      .catch((reason: unknown) => {
        if (!active) return;
        setError(reason instanceof Error ? reason.message : "スケジュールを読み込めませんでした");
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, user]);

  function openNewDraft(
    _dayIndex: number,
    dateId: string,
    startSlot: number,
    endSlot: number,
  ) {
    setError(null);
    setDraft({
      id: null,
      title: "",
      placeName: "",
      dateId,
      startSlot,
      endSlot,
      allDay: false,
      note: "",
    });
  }

  function openExistingDraft(block: ScheduleBlock) {
    const source = items.find((item) => item.id === block.id);
    setError(null);
    setDraft({
      id: block.id,
      title: block.title,
      placeName: source?.placeName ?? "",
      dateId: block.dateId,
      startSlot: block.startSlot,
      endSlot: block.endSlot,
      allDay: source?.allDay ?? false,
      note: source?.note ?? "",
    });
  }

  async function saveDraft(next: ScheduleDraft) {
    const title = next.title.trim();
    if (!title) {
      setError("予定名を入力してください");
      return;
    }
    setError(null);
    setSaving(true);
    const payload = {
      title,
      place_name: next.placeName.trim() || null,
      start_at: slotToIso(next.dateId, next.startSlot),
      end_at: slotToIso(next.dateId, next.endSlot),
      all_day: next.allDay,
      note: next.note.trim() || null,
    };

    if (!supabase || !user || previewMode) {
      const localItem = rowToScheduleItem({
        id: next.id ?? `preview-schedule-${Date.now()}`,
        title: payload.title,
        place_name: payload.place_name,
        start_at: payload.start_at,
        end_at: payload.end_at,
        all_day: payload.all_day,
        note: payload.note,
      });
      setItems((current) =>
        next.id
          ? current.map((item) => (item.id === next.id ? localItem : item))
          : [...current, localItem],
      );
      setSaving(false);
      setDraft(null);
      return;
    }

    const result = await saveScheduleRow(next.id, user.id, payload);

    setSaving(false);
    if (result.error) {
      setError(result.error.message);
      return;
    }
    if (!result.data) {
      setError("スケジュールを保存できませんでした");
      return;
    }
    const saved = rowToScheduleItem(result.data as unknown as ScheduleRow);
    setItems((current) =>
      next.id
        ? current.map((item) => (item.id === saved.id ? saved : item))
        : [...current, saved],
    );
    setDraft(null);
  }

  async function deleteSchedule(id: string) {
    const snapshot = items;
    setItems((current) => current.filter((item) => item.id !== id));
    setDraft(null);
    if (!supabase || !user || previewMode) return;
    const { error: deleteError } = await supabase
      .from("schedules")
      .delete()
      .eq("id", id)
      .eq("user_id", user.id);
    if (deleteError) {
      setItems(snapshot);
      setError(deleteError.message);
    }
  }

  async function updateScheduleTime(
    id: string,
    dateId: string,
    startSlot: number,
    endSlot: number,
  ) {
    const snapshot = items;
    const patch = {
      startAt: slotToIso(dateId, startSlot),
      endAt: slotToIso(dateId, endSlot),
      allDay: false,
    };
    setItems((current) =>
      current.map((item) => (item.id === id ? { ...item, ...patch } : item)),
    );
    if (!supabase || !user || previewMode) return;
    const { error: updateError } = await supabase
      .from("schedules")
      .update({
        start_at: patch.startAt,
        end_at: patch.endAt,
        all_day: false,
      })
      .eq("id", id)
      .eq("user_id", user.id);
    if (updateError) {
      setItems(snapshot);
      setError(updateError.message);
    }
  }

  return (
    <Screen scroll={false} contentStyle={styles.screen}>
      <RouteHeader title="スケジュール" />

      <View style={styles.benefitBox}>
        <Text style={styles.benefitTitle}>交換候補を合わせやすくする</Text>
        <Text style={styles.benefitText}>
          スケジュールを設定しておくと、グッズ交換で相手があなたの予定に合わせて交換候補を提示しやすくなります。
        </Text>
      </View>

      {loading ? <Text style={styles.loadingText}>読み込み中…</Text> : null}
      {error ? <Text style={styles.inlineError}>{error}</Text> : null}

      <ScheduleCalendar
        items={items}
        onCreateTime={openNewDraft}
        onOpenSchedule={openExistingDraft}
        onUpdateTime={updateScheduleTime}
      />

      <ScheduleSheet
        draft={draft}
        loading={saving}
        onChange={setDraft}
        onClose={() => setDraft(null)}
        onDelete={draft?.id ? () => deleteSchedule(draft.id as string) : undefined}
        onSave={saveDraft}
      />
    </Screen>
  );
}

function ScheduleCalendar({
  items,
  onCreateTime,
  onOpenSchedule,
  onUpdateTime,
}: {
  items: ScheduleItem[];
  onCreateTime: (
    dayIndex: number,
    dateId: string,
    startSlot: number,
    endSlot: number,
  ) => void;
  onOpenSchedule: (block: ScheduleBlock) => void;
  onUpdateTime: (
    id: string,
    dateId: string,
    startSlot: number,
    endSlot: number,
  ) => void;
}) {
  const { width } = useWindowDimensions();
  const scrollRef = useRef<ScrollView>(null);
  const [weekOffset, setWeekOffset] = useState(0);
  const days = useMemo(() => buildCalendarDays(weekOffset), [weekOffset]);
  const weekHeaderTouchRef = useRef<{
    startX: number;
    startY: number;
    swiping: boolean;
  } | null>(null);
  const touchPressRef = useRef<{
    timer: ReturnType<typeof setTimeout>;
    mode: "pending" | "dragging" | "swiping";
    dayIndex: number;
    dateId: string;
    startSlot: number;
    startX: number;
    startY: number;
  } | null>(null);
  const blockTouchRef = useRef<BlockTouchState | null>(null);
  const blockEditRef = useRef<BlockEdit | null>(null);
  const calendarFrameRef = useRef<CalendarFrame | null>(null);
  const calendarGridRef = useRef<View>(null);
  const dragDraftRef = useRef<DragDraft | null>(null);
  const weekDragX = useRef(new Animated.Value(0)).current;
  const hintPulse = useRef(new Animated.Value(0)).current;
  const weekDragValueRef = useRef(0);
  const [dragDraft, setDragDraftState] = useState<DragDraft | null>(null);
  const [blockEdit, setBlockEditState] = useState<BlockEdit | null>(null);
  const [calendarGestureLock, setCalendarGestureLock] = useState(false);
  const [activeBlockId, setActiveBlockId] = useState<string | null>(null);
  const calendarWidth = width - 36;
  const dayWidth = (calendarWidth - TIME_LABEL_WIDTH) / days.length;
  const pagerWeeks = useMemo(
    () =>
      [-1, 0, 1].map((relative) => ({
        relative,
        days: buildCalendarDays(weekOffset + relative),
      })),
    [weekOffset],
  );
  const contentHeight =
    CALENDAR_TOP_PADDING + SLOT_COUNT * SLOT_HEIGHT + CALENDAR_BOTTOM_PADDING;
  const blocks = useMemo(
    () =>
      items
        .map((item) => scheduleToBlock(item, days))
        .filter((block): block is ScheduleBlock => !!block),
    [days, items],
  );

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
    if (blocks.length > 0 || dragDraft) {
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
  }, [blocks.length, dragDraft, hintPulse]);

  useEffect(
    () => () => {
      clearTouchPress();
      clearBlockTouch();
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

  function setBlockEdit(next: BlockEdit | null) {
    blockEditRef.current = next;
    setBlockEditState(next);
  }

  function clearBlockTouch() {
    if (blockTouchRef.current) {
      clearTimeout(blockTouchRef.current.timer);
    }
    blockTouchRef.current = null;
    setBlockEdit(null);
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
    setActiveBlockId(null);
    clearBlockTouch();
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

  function beginBlockEdit(state: BlockTouchState) {
    clearTimeout(state.timer);
    blockTouchRef.current = {
      ...state,
      mode: "editing",
    };
    setCalendarGestureLock(true);
    setBlockEdit({
      id: state.id,
      action: state.action,
      dayIndex: state.originalDayIndex,
      dateId: state.originalDateId,
      startSlot: state.originalStartSlot,
      endSlot: state.originalEndSlot,
    });
  }

  function updateBlockEdit(pageX: number, pageY: number) {
    const state = blockTouchRef.current;
    if (!state || state.mode !== "editing") return;
    const point = pointToCalendar(pageX, pageY);
    if (!point) return;
    const duration = Math.max(1, state.originalEndSlot - state.originalStartSlot);
    if (state.action === "move") {
      const startSlot = Math.max(
        0,
        Math.min(SLOT_COUNT - duration, point.slot - state.pointerStartOffsetSlots),
      );
      setBlockEdit({
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
    setBlockEdit({
      id: state.id,
      action: state.action,
      dayIndex: state.originalDayIndex,
      dateId: state.originalDateId,
      startSlot: state.originalStartSlot,
      endSlot,
    });
  }

  function handleBlockTouchStart(
    event: GestureResponderEvent,
    block: ScheduleBlock,
    action: "move" | "resize-end",
  ) {
    event.stopPropagation();
    clearTouchPress();
    clearBlockTouch();
    measureCalendarFrame();
    setActiveBlockId(block.id);
    const { pageX, pageY } = event.nativeEvent;
    const duration = Math.max(1, block.endSlot - block.startSlot);
    const point = pointToCalendar(pageX, pageY);
    const pointerStartOffsetSlots =
      action === "move" && point?.dayIndex === block.dayIndex
        ? Math.max(0, Math.min(duration - 1, point.slot - block.startSlot))
        : 0;
    const timer = setTimeout(() => {
      const state = blockTouchRef.current;
      if (!state || state.id !== block.id || state.mode !== "pending") return;
      beginBlockEdit(state);
    }, LONG_PRESS_MS);
    blockTouchRef.current = {
      timer,
      mode: "pending",
      id: block.id,
      action,
      startX: pageX,
      startY: pageY,
      originalDayIndex: block.dayIndex,
      originalDateId: block.dateId,
      originalStartSlot: block.startSlot,
      originalEndSlot: block.endSlot,
      pointerStartOffsetSlots,
    };
  }

  function handleBlockTouchMove(event: GestureResponderEvent) {
    const state = blockTouchRef.current;
    if (!state) return;
    event.stopPropagation();
    const { pageX, pageY } = event.nativeEvent;
    if (state.mode === "pending") {
      const dx = pageX - state.startX;
      const dy = pageY - state.startY;
      if (Math.hypot(dx, dy) > TOUCH_CANCEL_PX) {
        clearBlockTouch();
      }
      return;
    }
    updateBlockEdit(pageX, pageY);
  }

  function handleBlockTouchEnd(event: GestureResponderEvent, block: ScheduleBlock) {
    const state = blockTouchRef.current;
    if (!state) return;
    event.stopPropagation();
    if (state.mode === "editing") {
      updateBlockEdit(event.nativeEvent.pageX, event.nativeEvent.pageY);
      const edit = blockEditRef.current;
      if (edit) {
        onUpdateTime(edit.id, edit.dateId, edit.startSlot, edit.endSlot);
      }
      clearBlockTouch();
      return;
    }
    clearBlockTouch();
    onOpenSchedule(block);
  }

  function handleDayTouchStart(e: GestureResponderEvent, dayIndex: number) {
    e.stopPropagation();
    clearTouchPress();
    clearBlockTouch();
    setActiveBlockId(null);
    const { locationY, pageX, pageY } = e.nativeEvent;
    const startSlot = slotFromLocationY(locationY);
    const dateId = days[dayIndex]?.id ?? dateKey(new Date());
    const timer = setTimeout(() => {
      const press = touchPressRef.current;
      if (!press || press.mode !== "pending") return;
      press.mode = "dragging";
      setCalendarGestureLock(true);
      setDragDraft({
        dayIndex,
        dateId: press.dateId,
        startSlot,
        currentSlot: Math.min(SLOT_COUNT - 1, startSlot + 1),
      });
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
    setDragDraft({
      dayIndex: press.dayIndex,
      dateId: press.dateId,
      startSlot: press.startSlot,
      currentSlot: slotFromLocationY(locationY),
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
        onCreateTime(
          press.dayIndex,
          press.dateId,
          press.startSlot,
          Math.min(SLOT_COUNT, press.startSlot + 2),
        );
      }
      return;
    }
    const releaseSlot = slotFromLocationY(e.nativeEvent.locationY);
    const nextDraft = {
      ...draft,
      currentSlot: releaseSlot === draft.startSlot ? draft.currentSlot : releaseSlot,
    };
    const range = normalizedDraftRange(nextDraft);
    onCreateTime(nextDraft.dayIndex, nextDraft.dateId, range.startSlot, range.endSlot);
    setDragDraft(null);
    setCalendarGestureLock(false);
  }

  function handleDayTouchCancel() {
    clearTouchPress();
    clearBlockTouch();
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
    <View style={styles.calendarRoot}>
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
                  style={[styles.dayCell, day.isToday ? styles.dayCellToday : null]}
                >
                  <Text style={[styles.dayName, day.isToday ? styles.dayNameToday : null]}>
                    {day.day}
                  </Text>
                  <Text style={[styles.dayDate, day.isToday ? styles.dayDateToday : null]}>
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
        scrollEnabled={!calendarGestureLock && !dragDraft && !blockEdit}
        showsVerticalScrollIndicator={false}
        contentContainerStyle={[styles.calendarContent, { height: contentHeight }]}
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
                        style={[styles.hourLabel, { top: calendarSlotTop(hour * 4) - 7 }]}
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
                        isCurrentWeek ? (event) => handleDayTouchStart(event, dayIndex) : undefined
                      }
                      onTouchMove={isCurrentWeek ? handleDayTouchMove : undefined}
                      onTouchEnd={isCurrentWeek ? handleDayTouchEnd : undefined}
                      onTouchCancel={isCurrentWeek ? handleDayTouchCancel : undefined}
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
                    ? blocks.map((block) => {
                        const visibleDayIndex = days.findIndex((day) => day.id === block.dateId);
                        if (visibleDayIndex < 0) return null;
                        const visibleBlock = {
                          ...block,
                          dayIndex: visibleDayIndex,
                        };
                        const active = block.id === activeBlockId;
                        const edit = blockEdit?.id === block.id ? blockEdit : null;
                        const effective = edit ?? visibleBlock;
                        const editing = !!edit;
                        return (
                          <Pressable
                            key={block.id}
                            onTouchStart={(event) =>
                              handleBlockTouchStart(event, visibleBlock, "move")
                            }
                            onTouchMove={handleBlockTouchMove}
                            onTouchEnd={(event) => handleBlockTouchEnd(event, visibleBlock)}
                            onTouchCancel={clearBlockTouch}
                            style={[
                              styles.scheduleBlock,
                              active ? styles.scheduleBlockActive : null,
                              editing ? styles.scheduleBlockEditing : null,
                              {
                                left: TIME_LABEL_WIDTH + effective.dayIndex * dayWidth + 4,
                                top: calendarSlotTop(effective.startSlot) + 3,
                                width: dayWidth - 8,
                                height:
                                  Math.max(1, effective.endSlot - effective.startSlot) *
                                    SLOT_HEIGHT -
                                  6,
                              },
                            ]}
                          >
                            <Text numberOfLines={2} style={styles.scheduleBlockTitle}>
                              {block.title}
                            </Text>
                            <Text numberOfLines={1} style={styles.scheduleBlockTime}>
                              {formatSlot(block.startSlot)}-{formatSlot(block.endSlot)}
                            </Text>
                            {block.placeName ? (
                              <Text numberOfLines={1} style={styles.scheduleBlockPlace}>
                                {block.placeName}
                              </Text>
                            ) : null}
                            <Pressable
                              accessibilityLabel={`${block.title}の終了時間を変更`}
                              onTouchStart={(event) =>
                                handleBlockTouchStart(event, visibleBlock, "resize-end")
                              }
                              onTouchMove={handleBlockTouchMove}
                              onTouchEnd={(event) => handleBlockTouchEnd(event, visibleBlock)}
                              onTouchCancel={clearBlockTouch}
                              style={styles.scheduleResizeHandle}
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

      {blocks.length === 0 && !preview ? (
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
          <Text style={styles.calendarHintText}>長押しで時間帯を選択できるよ</Text>
        </Animated.View>
      ) : null}
    </View>
  );
}

function ScheduleSheet({
  draft,
  loading,
  onChange,
  onClose,
  onDelete,
  onSave,
}: {
  draft: ScheduleDraft | null;
  loading: boolean;
  onChange: (draft: ScheduleDraft | null) => void;
  onClose: () => void;
  onDelete?: () => void;
  onSave: (draft: ScheduleDraft) => void;
}) {
  if (!draft) return null;

  const nativeSheet = Platform.OS === "ios";
  const sheetContent = (
    <Pressable style={[styles.scheduleSheet, nativeSheet ? styles.scheduleNativeSheet : null]}>
      <View style={styles.sheetHandle} />
      <View style={styles.sheetHeader}>
        <View style={styles.sheetHeaderCopy}>
          <Text style={styles.sheetKicker}>{formatDraftRange(draft)}</Text>
          <Text style={styles.sheetTitle}>{draft.id ? "予定を編集" : "予定を追加"}</Text>
        </View>
        <Pressable accessibilityRole="button" onPress={onClose} style={styles.sheetClose}>
          <Text style={styles.sheetCloseText}>×</Text>
        </Pressable>
      </View>

      <View style={styles.fieldGroup}>
        <Text style={styles.fieldLabel}>予定名</Text>
        <TextInput
          value={draft.title}
          onChangeText={(title) => onChange({ ...draft, title })}
          placeholder="例: ライブ参戦・仕事・友人とランチ"
          placeholderTextColor="rgba(58,50,74,0.34)"
          style={styles.sheetInput}
        />
      </View>

      <View style={styles.fieldGroup}>
        <Text style={styles.fieldLabel}>場所</Text>
        <TextInput
          value={draft.placeName}
          onChangeText={(placeName) => onChange({ ...draft, placeName })}
          placeholder="例: 横浜アリーナ 北口"
          placeholderTextColor="rgba(58,50,74,0.34)"
          style={styles.sheetInput}
        />
      </View>

      <PrimaryButton loading={loading} onPress={() => onSave(draft)}>
        {draft.id ? "変更を保存" : "この予定を追加"}
      </PrimaryButton>

      {onDelete ? (
        <Pressable accessibilityRole="button" onPress={onDelete} style={styles.deleteButton}>
          <Text style={styles.deleteButtonText}>この予定を削除</Text>
        </Pressable>
      ) : null}
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
        <View style={styles.scheduleNativeSheetRoot}>{sheetContent}</View>
      ) : (
        <Pressable style={styles.sheetBackdrop} onPress={onClose}>
          {sheetContent}
        </Pressable>
      )}
    </Modal>
  );
}

type ScheduleRow = {
  id: string;
  title: string;
  place_name?: string | null;
  start_at: string;
  end_at: string;
  all_day: boolean;
  note: string | null;
};

async function fetchSchedules(userId: string): Promise<ScheduleItem[]> {
  if (!supabase) return [];
  const rich = await supabase
    .from("schedules")
    .select("id, title, place_name, start_at, end_at, all_day, note")
    .eq("user_id", userId)
    .order("start_at", { ascending: true });
  if (!rich.error) return ((rich.data as ScheduleRow[] | null) ?? []).map(rowToScheduleItem);
  if (!isMissingPlaceNameError(rich.error)) throw rich.error;
  const fallback = await supabase
    .from("schedules")
    .select("id, title, start_at, end_at, all_day, note")
    .eq("user_id", userId)
    .order("start_at", { ascending: true });
  if (fallback.error) throw fallback.error;
  return ((fallback.data as ScheduleRow[] | null) ?? []).map(rowToScheduleItem);
}

async function saveScheduleRow(
  id: string | null,
  userId: string,
  payload: {
    title: string;
    place_name: string | null;
    start_at: string;
    end_at: string;
    all_day: boolean;
    note: string | null;
  },
) {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const client = supabase;
  const selectRich = "id, title, place_name, start_at, end_at, all_day, note";
  const selectFallback = "id, title, start_at, end_at, all_day, note";
  const run = (nextPayload: typeof payload | Omit<typeof payload, "place_name">, select: string) =>
    id
      ? client
          .from("schedules")
          .update(nextPayload)
          .eq("id", id)
          .eq("user_id", userId)
          .select(select)
          .maybeSingle()
      : client
          .from("schedules")
          .insert({ ...nextPayload, user_id: userId })
          .select(select)
          .single();
  const rich = await run(payload, selectRich);
  if (!rich.error || !isMissingPlaceNameError(rich.error)) return rich;
  const { place_name: _placeName, ...fallbackPayload } = payload;
  return run(fallbackPayload, selectFallback);
}

function rowToScheduleItem(row: ScheduleRow): ScheduleItem {
  return {
    id: row.id,
    title: row.title,
    placeName: row.place_name ?? null,
    startAt: row.start_at,
    endAt: row.end_at,
    allDay: row.all_day,
    note: row.note,
  };
}

function isMissingPlaceNameError(error: { message?: string; details?: string | null }) {
  const message = `${error.message ?? ""} ${error.details ?? ""}`.toLowerCase();
  return message.includes("place_name") && message.includes("column");
}

function scheduleToBlock(item: ScheduleItem, days: CalendarDay[]) {
  const start = new Date(item.startAt);
  const end = new Date(item.endAt);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return null;
  const dateId = dateKey(start);
  const dayIndex = days.findIndex((day) => day.id === dateId);
  if (dayIndex < 0) return null;
  const startSlot = item.allDay ? 0 : dateToSlot(start, "floor");
  const endSlot = item.allDay ? SLOT_COUNT : dateToSlot(end, "ceil");
  return {
    id: item.id,
    title: item.title,
    placeName: item.placeName,
    dateId,
    dayIndex,
    startSlot,
    endSlot: Math.max(startSlot + 1, Math.min(SLOT_COUNT, endSlot)),
  };
}

function buildCalendarDays(weekOffset = 0): CalendarDay[] {
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

function dateToSlot(date: Date, round: "floor" | "ceil") {
  const totalMinutes = date.getHours() * 60 + date.getMinutes();
  const raw = totalMinutes / SLOT_MINUTES;
  const slot = round === "ceil" ? Math.ceil(raw) : Math.floor(raw);
  return Math.max(0, Math.min(SLOT_COUNT, slot));
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

function formatDraftRange(draft: ScheduleDraft) {
  return `${formatCalendarDate(draft.dateId)} ${formatSlot(draft.startSlot)} - ${formatSlot(draft.endSlot)}`;
}

function formatCalendarDate(dateId: string) {
  const date = new Date(`${dateId}T00:00:00+09:00`);
  if (Number.isNaN(date.getTime())) return "";
  return `${date.getMonth() + 1}月${date.getDate()}日`;
}

const styles = StyleSheet.create({
  screen: {
    gap: 12,
  },
  benefitBox: {
    backgroundColor: "rgba(166,149,216,0.10)",
    borderColor: "rgba(166,149,216,0.20)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    paddingHorizontal: 15,
    paddingVertical: 13,
  },
  benefitTitle: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  benefitText: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 18,
    marginTop: 5,
  },
  loadingText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  inlineError: {
    backgroundColor: "rgba(217,130,107,0.10)",
    borderColor: "rgba(217,130,107,0.22)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    padding: 11,
  },
  calendarRoot: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 22,
    borderWidth: 1,
    flex: 1,
    overflow: "hidden",
    position: "relative",
    ...megrumShadow,
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
  scheduleBlock: {
    alignItems: "center",
    backgroundColor: "rgba(75,151,224,0.22)",
    borderColor: "rgba(75,151,224,0.54)",
    borderRadius: 13,
    borderWidth: 1,
    justifyContent: "center",
    overflow: "hidden",
    paddingHorizontal: 5,
    position: "absolute",
    shadowColor: "#4b97e0",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.12,
    shadowRadius: 14,
  },
  scheduleBlockActive: {
    borderColor: "rgba(166,149,216,0.88)",
    shadowColor: megrumColors.lavender,
    shadowOpacity: 0.2,
  },
  scheduleBlockEditing: {
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 16 },
    shadowOpacity: 0.24,
    shadowRadius: 22,
    transform: [{ translateY: -4 }, { scale: 1.03 }],
    zIndex: 30,
  },
  scheduleBlockTitle: {
    color: "#256aa8",
    fontSize: 10.5,
    fontWeight: "900",
    lineHeight: 14,
    textAlign: "center",
  },
  scheduleBlockTime: {
    color: "rgba(37,106,168,0.74)",
    fontSize: 9,
    fontWeight: "900",
    marginTop: 2,
    textAlign: "center",
  },
  scheduleBlockPlace: {
    color: "rgba(37,106,168,0.70)",
    fontSize: 8.5,
    fontWeight: "800",
    marginTop: 1,
    textAlign: "center",
  },
  scheduleResizeHandle: {
    backgroundColor: "rgba(255,255,255,0.62)",
    borderRadius: 999,
    bottom: 3,
    height: 5,
    left: 10,
    position: "absolute",
    right: 10,
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
  sheetBackdrop: {
    backgroundColor: "rgba(18,16,26,0.34)",
    flex: 1,
    justifyContent: "flex-end",
  },
  scheduleNativeSheetRoot: {
    backgroundColor: megrumColors.background,
    flex: 1,
    padding: 16,
  },
  scheduleSheet: {
    backgroundColor: megrumColors.surface,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    gap: 13,
    paddingBottom: 24,
    paddingHorizontal: 18,
    paddingTop: 10,
  },
  scheduleNativeSheet: {
    backgroundColor: megrumColors.background,
    borderTopLeftRadius: 0,
    borderTopRightRadius: 0,
    paddingHorizontal: 0,
  },
  sheetHandle: {
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.18)",
    borderRadius: 999,
    height: 4,
    width: 42,
  },
  sheetHeader: {
    alignItems: "flex-start",
    flexDirection: "row",
    gap: 12,
    justifyContent: "space-between",
  },
  sheetHeaderCopy: {
    flex: 1,
  },
  sheetKicker: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
  },
  sheetTitle: {
    color: megrumColors.ink,
    fontSize: 21,
    fontWeight: "900",
    marginTop: 2,
  },
  sheetClose: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.06)",
    borderRadius: 999,
    height: 34,
    justifyContent: "center",
    width: 34,
  },
  sheetCloseText: {
    color: megrumColors.mutedInk,
    fontSize: 21,
    fontWeight: "900",
    lineHeight: 22,
  },
  fieldGroup: {
    gap: 7,
  },
  fieldLabel: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  sheetInput: {
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
  deleteButton: {
    alignItems: "center",
    borderColor: "rgba(217,130,107,0.22)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingVertical: 11,
  },
  deleteButtonText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
  },
});
