import { router, Stack, useLocalSearchParams } from "expo-router";
import { useEffect, useMemo, useState } from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
} from "react-native";
import { useAuth } from "../src/auth/AuthProvider";
import { Screen } from "../src/components/Screen";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type ScheduleOwner = "me" | "partner";
type CalendarMode = "week" | "month";

type ScheduleOverlayItem = {
  id: string;
  userId: string;
  owner: ScheduleOwner;
  title: string;
  placeName: string | null;
  startAt: string;
  endAt: string;
  allDay: boolean;
};

type ScheduleRow = {
  id: string;
  user_id: string;
  title: string;
  start_at: string;
  end_at: string;
  all_day: boolean;
  place_name?: string | null;
};

type CalendarDay = {
  id: string;
  day: string;
  date: string;
  month: string;
  isToday: boolean;
  isOutsideMonth: boolean;
};

type WeekScheduleBlock = ScheduleOverlayItem & {
  dateId: string;
  dayIndex: number;
  startSlot: number;
  endSlot: number;
};

const PREVIEW_ITEMS: ScheduleOverlayItem[] = [
  {
    id: "preview-me",
    userId: "me",
    owner: "me",
    title: "ライブ参戦",
    placeName: "横浜アリーナ",
    startAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
    endAt: new Date(Date.now() + 3 * 60 * 60 * 1000).toISOString(),
    allDay: false,
  },
  {
    id: "preview-partner",
    userId: "partner",
    owner: "partner",
    title: "物販待機",
    placeName: "会場周辺",
    startAt: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
    endAt: new Date(Date.now() + 4 * 60 * 60 * 1000).toISOString(),
    allDay: false,
  },
];

const HOURS = Array.from({ length: 24 }, (_, hour) => hour);
const WEEK_DAY_COUNT = 5;
const MONTH_CELL_COUNT = 42;
const SLOT_MINUTES = 15;
const SLOTS_PER_HOUR = 60 / SLOT_MINUTES;
const SLOT_COUNT = 24 * SLOTS_PER_HOUR;
const SLOT_HEIGHT = 15;
const HOUR_HEIGHT = SLOT_HEIGHT * SLOTS_PER_HOUR;
const TIME_LABEL_WIDTH = 50;
const CALENDAR_TOP_PADDING = 14;
const CALENDAR_BOTTOM_PADDING = 62;

export default function TransactionScheduleScreen() {
  const params = useLocalSearchParams<{
    partnerId?: string | string[];
  }>();
  const partnerId = one(params.partnerId);
  const { previewMode, user } = useAuth();
  const { width } = useWindowDimensions();
  const [items, setItems] = useState<ScheduleOverlayItem[]>(() =>
    previewMode || !supabase ? PREVIEW_ITEMS : [],
  );
  const [loading, setLoading] = useState(!!supabase && !previewMode);
  const [error, setError] = useState<string | null>(null);
  const [calendarMode, setCalendarMode] = useState<CalendarMode>("week");
  const [weekOffset, setWeekOffset] = useState(0);
  const [monthOffset, setMonthOffset] = useState(0);

  useEffect(() => {
    if (!supabase || previewMode) {
      setItems(PREVIEW_ITEMS);
      setLoading(false);
      setError(null);
      return;
    }
    if (!user || !partnerId) {
      setItems([]);
      setLoading(false);
      setError("相手のスケジュールを読み込めませんでした");
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);
    fetchScheduleOverlay(user.id, partnerId)
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
  }, [partnerId, previewMode, user?.id]);

  const weekDays = useMemo(() => buildCalendarWeekDays(weekOffset), [weekOffset]);
  const monthDays = useMemo(() => buildCalendarMonthDays(monthOffset), [monthOffset]);
  const calendarWidth = Math.max(260, width - 52);
  const calendarContentHeight = CALENDAR_TOP_PADDING + SLOT_COUNT * SLOT_HEIGHT + CALENDAR_BOTTOM_PADDING;

  const focusDayInWeek = (dateId: string) => {
    setWeekOffset(weekOffsetForDateId(dateId));
    setMonthOffset(monthOffsetForDateId(dateId));
    setCalendarMode("week");
  };

  return (
    <Screen scroll={false} contentStyle={styles.screen}>
      <Stack.Screen
        options={{
          title: "スケジュール",
          headerRight: () => (
            <Pressable
              accessibilityRole="button"
              onPress={() => router.push("/schedules")}
              style={styles.headerButton}
            >
              <Text style={styles.headerButtonText}>更新</Text>
            </Pressable>
          ),
        }}
      />
      <View style={styles.summaryCard}>
        <Text style={styles.summaryTitle}>自分と相手の予定</Text>
        <Text style={styles.summaryBody}>
          重なっている時間を見ながら、次の待ち合わせ候補を決められます。
        </Text>
        <View style={styles.legendRow}>
          <LegendDot owner="me" label="あなた" />
          <LegendDot owner="partner" label="相手" />
        </View>
      </View>

      {loading ? <Text style={styles.loadingText}>読み込み中…</Text> : null}
      {error ? <Text style={styles.errorText}>{error}</Text> : null}

      <View style={styles.calendarCard}>
        <View style={styles.calendarToolbar}>
          <View style={styles.rangeControls}>
            <Pressable
              accessibilityRole="button"
              onPress={() =>
                calendarMode === "week"
                  ? setWeekOffset((current) => current - 1)
                  : setMonthOffset((current) => current - 1)
              }
              style={styles.rangeButton}
            >
              <Text style={styles.rangeButtonText}>‹</Text>
            </Pressable>
            <Text style={styles.rangeTitle}>
              {calendarMode === "week" ? formatWeekRange(weekDays) : formatMonthTitle(monthOffset)}
            </Text>
            <Pressable
              accessibilityRole="button"
              onPress={() =>
                calendarMode === "week"
                  ? setWeekOffset((current) => current + 1)
                  : setMonthOffset((current) => current + 1)
              }
              style={styles.rangeButton}
            >
              <Text style={styles.rangeButtonText}>›</Text>
            </Pressable>
          </View>
          <View style={styles.calendarModeToggle}>
            {(["week", "month"] as const).map((mode) => {
              const active = calendarMode === mode;
              return (
                <Pressable
                  accessibilityRole="button"
                  key={mode}
                  onPress={() => setCalendarMode(mode)}
                  style={[styles.calendarModeButton, active ? styles.calendarModeButtonActive : null]}
                >
                  <Text style={[styles.calendarModeButtonText, active ? styles.calendarModeButtonTextActive : null]}>
                    {mode === "week" ? "週" : "月"}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </View>

        {!loading && !error && items.length === 0 ? (
          <View style={styles.inlineEmpty}>
            <Text style={styles.inlineEmptyTitle}>表示できる予定がありません</Text>
            <Text style={styles.inlineEmptyBody}>
              自分の予定を更新するか、打診時にスケジュール共有が有効か確認してください。
            </Text>
          </View>
        ) : null}

        {calendarMode === "week" ? (
          <WeekScheduleCalendar
            calendarWidth={calendarWidth}
            contentHeight={calendarContentHeight}
            days={weekDays}
            items={items}
          />
        ) : (
          <MonthSchedulePanel days={monthDays} items={items} onSelectDay={focusDayInWeek} />
        )}
      </View>
    </Screen>
  );
}

function LegendDot({ owner, label }: { owner: ScheduleOwner; label: string }) {
  return (
    <View style={styles.legendItem}>
      <View style={[styles.legendDot, owner === "me" ? styles.legendDotMe : styles.legendDotPartner]} />
      <Text style={styles.legendText}>{label}</Text>
    </View>
  );
}

function WeekScheduleCalendar({
  calendarWidth,
  contentHeight,
  days,
  items,
}: {
  calendarWidth: number;
  contentHeight: number;
  days: CalendarDay[];
  items: ScheduleOverlayItem[];
}) {
  const dayWidth = (calendarWidth - TIME_LABEL_WIDTH) / days.length;
  const blocks = useMemo(() => buildWeekScheduleBlocks(items, days), [items, days]);

  return (
    <View style={styles.weekCalendar}>
      <View style={[styles.daysHeader, { width: calendarWidth }]}>
        <View style={{ width: TIME_LABEL_WIDTH }} />
        {days.map((day) => (
          <View key={day.id} style={[styles.dayHeaderCell, day.isToday ? styles.dayHeaderCellToday : null]}>
            <Text style={[styles.dayHeaderName, day.isToday ? styles.dayHeaderNameToday : null]}>{day.day}</Text>
            <Text style={[styles.dayHeaderDate, day.isToday ? styles.dayHeaderDateToday : null]}>{day.date}</Text>
          </View>
        ))}
      </View>
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ height: contentHeight }}>
        <View style={[styles.calendarGrid, { height: contentHeight, width: calendarWidth }]}>
          <View style={[styles.timeAxis, { width: TIME_LABEL_WIDTH }]}>
            {HOURS.map((hour) => (
              <Text
                key={hour}
                style={[
                  styles.hourLabel,
                  {
                    top: CALENDAR_TOP_PADDING + hour * HOUR_HEIGHT - 5,
                  },
                ]}
              >
                {String(hour).padStart(2, "0")}:00
              </Text>
            ))}
          </View>
          {days.map((day, dayIndex) => (
            <View
              key={day.id}
              style={[
                styles.dayColumn,
                {
                  height: contentHeight,
                  left: TIME_LABEL_WIDTH + dayIndex * dayWidth,
                  width: dayWidth,
                },
              ]}
            >
              {HOURS.map((hour) => (
                <View
                  key={`${day.id}-${hour}`}
                  style={[
                    styles.hourCell,
                    {
                      height: HOUR_HEIGHT,
                      top: CALENDAR_TOP_PADDING + hour * HOUR_HEIGHT,
                    },
                  ]}
                />
              ))}
            </View>
          ))}
          {blocks.map((block) => {
            const top = CALENDAR_TOP_PADDING + block.startSlot * SLOT_HEIGHT + 2;
            const height = Math.max((block.endSlot - block.startSlot) * SLOT_HEIGHT - 4, 34);
            return (
              <View
                key={`${block.id}-${block.dateId}`}
                pointerEvents="none"
                style={[
                  styles.scheduleBlock,
                  block.owner === "me" ? styles.scheduleBlockMe : styles.scheduleBlockPartner,
                  {
                    height,
                    left: TIME_LABEL_WIDTH + block.dayIndex * dayWidth + 4,
                    top,
                    width: dayWidth - 8,
                  },
                ]}
              >
                <Text style={styles.scheduleBlockOwner}>{block.owner === "me" ? "あなた" : "相手"}</Text>
                <Text numberOfLines={1} style={styles.scheduleBlockTitle}>
                  {block.title}
                </Text>
                <Text numberOfLines={1} style={styles.scheduleBlockTime}>
                  {formatScheduleRange(block.startAt, block.endAt, block.allDay)}
                </Text>
                {block.placeName ? (
                  <Text numberOfLines={1} style={styles.scheduleBlockPlace}>
                    {block.placeName}
                  </Text>
                ) : null}
              </View>
            );
          })}
        </View>
      </ScrollView>
    </View>
  );
}

function MonthSchedulePanel({
  days,
  items,
  onSelectDay,
}: {
  days: CalendarDay[];
  items: ScheduleOverlayItem[];
  onSelectDay: (dateId: string) => void;
}) {
  const grouped = useMemo(() => groupScheduleOverlaysByDate(items), [items]);
  const weekdays = ["日", "月", "火", "水", "木", "金", "土"];

  return (
    <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.monthPanel}>
      <View style={styles.monthWeekdayRow}>
        {weekdays.map((weekday) => (
          <Text key={weekday} style={styles.monthWeekday}>
            {weekday}
          </Text>
        ))}
      </View>
      <View style={styles.monthGrid}>
        {days.map((day) => {
          const dayItems = grouped.get(day.id) ?? [];
          return (
            <Pressable
              accessibilityRole="button"
              key={day.id}
              onPress={() => onSelectDay(day.id)}
              style={[
                styles.monthDayCell,
                day.isOutsideMonth ? styles.monthDayCellOutside : null,
                day.isToday ? styles.monthDayCellToday : null,
              ]}
            >
              <Text
                style={[
                  styles.monthDayNumber,
                  day.isOutsideMonth ? styles.monthDayNumberOutside : null,
                  day.isToday ? styles.monthDayNumberToday : null,
                ]}
              >
                {day.date}
              </Text>
              <View style={styles.monthScheduleStack}>
                {dayItems.slice(0, 3).map((item) => (
                  <View
                    key={item.id}
                    style={[
                      styles.monthSchedulePill,
                      item.owner === "me" ? styles.monthSchedulePillMe : styles.monthSchedulePillPartner,
                    ]}
                  >
                    <Text numberOfLines={1} style={styles.monthSchedulePillText}>
                      {formatMonthScheduleLabel(item)}
                    </Text>
                  </View>
                ))}
                {dayItems.length > 3 ? (
                  <Text style={styles.monthMoreText}>+{dayItems.length - 3}</Text>
                ) : null}
              </View>
            </Pressable>
          );
        })}
      </View>
    </ScrollView>
  );
}

async function fetchScheduleOverlay(
  userId: string,
  partnerId: string,
): Promise<ScheduleOverlayItem[]> {
  if (!supabase) return [];
  const ownerIds = Array.from(new Set([userId, partnerId]));
  const rows = await selectScheduleRows(ownerIds);
  return rows
    .map((row) => ({
      id: row.id,
      userId: row.user_id,
      owner: (row.user_id === userId ? "me" : "partner") as ScheduleOwner,
      title: row.title,
      placeName: row.place_name ?? null,
      startAt: row.start_at,
      endAt: row.end_at,
      allDay: row.all_day,
    }))
    .sort((a, b) => new Date(a.startAt).getTime() - new Date(b.startAt).getTime());
}

async function selectScheduleRows(userIds: string[]) {
  if (!supabase) return [];
  const rich = await supabase
    .from("schedules")
    .select("id, user_id, title, start_at, end_at, all_day, place_name")
    .in("user_id", userIds)
    .order("start_at", { ascending: true });
  if (!rich.error) return (rich.data as ScheduleRow[] | null) ?? [];
  if (!isMissingPlaceNameError(rich.error)) throw rich.error;
  const fallback = await supabase
    .from("schedules")
    .select("id, user_id, title, start_at, end_at, all_day")
    .in("user_id", userIds)
    .order("start_at", { ascending: true });
  if (fallback.error) throw fallback.error;
  return (fallback.data as ScheduleRow[] | null) ?? [];
}

function buildCalendarWeekDays(weekOffset: number): CalendarDay[] {
  const weekdays = ["日", "月", "火", "水", "木", "金", "土"];
  const now = new Date();
  const todayId = dateKey(now);
  const base = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  base.setDate(base.getDate() + weekOffset * WEEK_DAY_COUNT);
  return Array.from({ length: WEEK_DAY_COUNT }, (_, index) => {
    const date = new Date(base);
    date.setDate(base.getDate() + index);
    const id = dateKey(date);
    return {
      id,
      day: weekdays[date.getDay()],
      date: String(date.getDate()),
      month: `${date.getMonth() + 1}月`,
      isToday: id === todayId,
      isOutsideMonth: false,
    };
  });
}

function buildCalendarMonthDays(monthOffset: number): CalendarDay[] {
  const weekdays = ["日", "月", "火", "水", "木", "金", "土"];
  const now = new Date();
  const todayId = dateKey(now);
  const firstOfMonth = new Date(now.getFullYear(), now.getMonth() + monthOffset, 1);
  const start = new Date(firstOfMonth);
  start.setDate(firstOfMonth.getDate() - firstOfMonth.getDay());
  return Array.from({ length: MONTH_CELL_COUNT }, (_, index) => {
    const date = new Date(start);
    date.setDate(start.getDate() + index);
    const id = dateKey(date);
    return {
      id,
      day: weekdays[date.getDay()],
      date: String(date.getDate()),
      month: `${date.getMonth() + 1}月`,
      isToday: id === todayId,
      isOutsideMonth: date.getMonth() !== firstOfMonth.getMonth(),
    };
  });
}

function buildWeekScheduleBlocks(items: ScheduleOverlayItem[], days: CalendarDay[]): WeekScheduleBlock[] {
  const dayIndexById = new Map(days.map((day, index) => [day.id, index]));
  const blocks: WeekScheduleBlock[] = [];
  items.forEach((item) => {
    const start = new Date(item.startAt);
    const end = new Date(item.endAt);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return;
    const dateId = dateKey(start);
    const dayIndex = dayIndexById.get(dateId);
    if (dayIndex === undefined) return;
    const startSlot = item.allDay ? 0 : Math.max(0, Math.min(SLOT_COUNT - 1, slotFromDate(start)));
    const endSlot = item.allDay ? SLOT_COUNT : Math.max(startSlot + 1, Math.min(SLOT_COUNT, slotFromDate(end)));
    blocks.push({
      ...item,
      dateId,
      dayIndex,
      startSlot,
      endSlot,
    });
  });
  return blocks.sort((a, b) => a.dayIndex - b.dayIndex || a.startSlot - b.startSlot);
}

function groupScheduleOverlaysByDate(items: ScheduleOverlayItem[]) {
  const map = new Map<string, ScheduleOverlayItem[]>();
  items.forEach((item) => {
    const key = dateKey(new Date(item.startAt));
    map.set(key, [...(map.get(key) ?? []), item]);
  });
  map.forEach((dayItems, key) => {
    map.set(
      key,
      dayItems.sort((a, b) => new Date(a.startAt).getTime() - new Date(b.startAt).getTime()),
    );
  });
  return map;
}

function slotFromDate(date: Date) {
  return date.getHours() * SLOTS_PER_HOUR + Math.floor(date.getMinutes() / SLOT_MINUTES);
}

function weekOffsetForDateId(dateId: string) {
  const target = parseLocalDate(dateId);
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const diffDays = Math.floor((target.getTime() - today.getTime()) / (24 * 60 * 60 * 1000));
  return Math.floor(diffDays / WEEK_DAY_COUNT);
}

function monthOffsetForDateId(dateId: string) {
  const target = parseLocalDate(dateId);
  const now = new Date();
  return (target.getFullYear() - now.getFullYear()) * 12 + target.getMonth() - now.getMonth();
}

function parseLocalDate(dateId: string) {
  const [year, month, day] = dateId.split("-").map((part) => Number(part));
  return new Date(year, month - 1, day);
}

function formatWeekRange(days: CalendarDay[]) {
  const first = days[0];
  const last = days[days.length - 1];
  if (!first || !last) return "";
  return `${first.month}${first.date}日 - ${last.month}${last.date}日`;
}

function formatMonthTitle(monthOffset: number) {
  const now = new Date();
  const date = new Date(now.getFullYear(), now.getMonth() + monthOffset, 1);
  return `${date.getFullYear()}年${date.getMonth() + 1}月`;
}

function formatMonthScheduleLabel(item: ScheduleOverlayItem) {
  const ownerLabel = item.owner === "me" ? "自分" : "相手";
  const place = item.placeName ? `・${item.placeName}` : "";
  return `${ownerLabel} ${item.title}${place}`;
}

function formatScheduleRange(startAt: string, endAt: string, allDay: boolean) {
  if (allDay) return "終日";
  const start = new Date(startAt);
  const end = new Date(endAt);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return "";
  return `${formatClock(start)} - ${formatClock(end)}`;
}

function formatClock(date: Date) {
  return `${String(date.getHours()).padStart(2, "0")}:${String(date.getMinutes()).padStart(2, "0")}`;
}

function dateKey(date: Date) {
  return [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0"),
  ].join("-");
}

function one(value?: string | string[]) {
  return Array.isArray(value) ? value[0] : value;
}

function isMissingPlaceNameError(error: { message?: string; details?: string | null }) {
  const message = `${error.message ?? ""} ${error.details ?? ""}`.toLowerCase();
  return message.includes("place_name") && message.includes("column");
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    gap: 12,
  },
  headerButton: {
    paddingHorizontal: 8,
    paddingVertical: 6,
  },
  headerButtonText: {
    color: megrumColors.lavender,
    fontSize: 14,
    fontWeight: "900",
  },
  summaryCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 18,
    borderWidth: 1,
    gap: 8,
    padding: 14,
    ...megrumShadow,
  },
  summaryTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  summaryBody: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 18,
  },
  legendRow: {
    flexDirection: "row",
    gap: 12,
  },
  legendItem: {
    alignItems: "center",
    flexDirection: "row",
    gap: 6,
  },
  legendDot: {
    borderRadius: 999,
    height: 10,
    width: 10,
  },
  legendDotMe: {
    backgroundColor: megrumColors.lavender,
  },
  legendDotPartner: {
    backgroundColor: megrumColors.sky,
  },
  legendText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  loadingText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  errorText: {
    backgroundColor: "rgba(217,130,107,0.10)",
    borderRadius: megrumRadii.md,
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    padding: 10,
  },
  calendarCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.14)",
    borderRadius: 20,
    borderWidth: 1,
    flex: 1,
    gap: 10,
    overflow: "hidden",
    paddingHorizontal: 8,
    paddingTop: 10,
    ...megrumShadow,
  },
  calendarToolbar: {
    alignItems: "center",
    flexDirection: "row",
    gap: 8,
    justifyContent: "space-between",
    paddingHorizontal: 4,
  },
  rangeControls: {
    alignItems: "center",
    flex: 1,
    flexDirection: "row",
    gap: 8,
  },
  rangeButton: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.055)",
    borderRadius: 999,
    height: 30,
    justifyContent: "center",
    width: 30,
  },
  rangeButtonText: {
    color: megrumColors.ink,
    fontSize: 24,
    fontWeight: "800",
    lineHeight: 26,
  },
  rangeTitle: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 13,
    fontWeight: "900",
  },
  calendarModeToggle: {
    backgroundColor: "rgba(58,50,74,0.08)",
    borderRadius: 999,
    flexDirection: "row",
    padding: 3,
  },
  calendarModeButton: {
    alignItems: "center",
    borderRadius: 999,
    height: 30,
    justifyContent: "center",
    width: 36,
  },
  calendarModeButtonActive: {
    backgroundColor: megrumColors.lavender,
  },
  calendarModeButtonText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
  },
  calendarModeButtonTextActive: {
    color: "#fff",
  },
  inlineEmpty: {
    backgroundColor: "rgba(58,50,74,0.035)",
    borderRadius: 14,
    gap: 4,
    marginHorizontal: 4,
    padding: 10,
  },
  inlineEmptyTitle: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  inlineEmptyBody: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "700",
    lineHeight: 16,
  },
  weekCalendar: {
    flex: 1,
    gap: 6,
  },
  daysHeader: {
    alignItems: "stretch",
    flexDirection: "row",
  },
  dayHeaderCell: {
    alignItems: "center",
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: 1,
    flex: 1,
    gap: 2,
    paddingBottom: 7,
    paddingTop: 2,
  },
  dayHeaderCellToday: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderRadius: 12,
  },
  dayHeaderName: {
    color: megrumColors.mutedInk,
    fontSize: 10,
    fontWeight: "900",
  },
  dayHeaderNameToday: {
    color: megrumColors.lavender,
  },
  dayHeaderDate: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
    lineHeight: 20,
  },
  dayHeaderDateToday: {
    color: megrumColors.lavender,
  },
  calendarGrid: {
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
    fontSize: 10,
    fontWeight: "800",
    left: 0,
    position: "absolute",
  },
  dayColumn: {
    borderLeftColor: "rgba(58,50,74,0.08)",
    borderLeftWidth: 1,
    position: "absolute",
    top: 0,
  },
  hourCell: {
    borderTopColor: "rgba(58,50,74,0.055)",
    borderTopWidth: 1,
    left: 0,
    position: "absolute",
    right: 0,
  },
  scheduleBlock: {
    borderRadius: 10,
    gap: 1,
    overflow: "hidden",
    paddingHorizontal: 6,
    paddingVertical: 5,
    position: "absolute",
  },
  scheduleBlockMe: {
    backgroundColor: "rgba(166,149,216,0.86)",
  },
  scheduleBlockPartner: {
    backgroundColor: "rgba(168,212,230,0.92)",
  },
  scheduleBlockOwner: {
    color: "#fff",
    fontSize: 9,
    fontWeight: "900",
  },
  scheduleBlockTitle: {
    color: "#fff",
    fontSize: 10.5,
    fontWeight: "900",
  },
  scheduleBlockTime: {
    color: "rgba(255,255,255,0.86)",
    fontSize: 9,
    fontWeight: "800",
  },
  scheduleBlockPlace: {
    color: "rgba(255,255,255,0.82)",
    fontSize: 9,
    fontWeight: "800",
  },
  monthPanel: {
    paddingBottom: 18,
  },
  monthWeekdayRow: {
    flexDirection: "row",
    paddingHorizontal: 2,
  },
  monthWeekday: {
    color: megrumColors.mutedInk,
    flex: 1,
    fontSize: 10,
    fontWeight: "900",
    paddingBottom: 5,
    textAlign: "center",
  },
  monthGrid: {
    borderLeftColor: "rgba(58,50,74,0.06)",
    borderLeftWidth: 1,
    borderTopColor: "rgba(58,50,74,0.06)",
    borderTopWidth: 1,
    flexDirection: "row",
    flexWrap: "wrap",
  },
  monthDayCell: {
    backgroundColor: megrumColors.surface,
    borderBottomColor: "rgba(58,50,74,0.06)",
    borderBottomWidth: 1,
    borderRightColor: "rgba(58,50,74,0.06)",
    borderRightWidth: 1,
    minHeight: 86,
    padding: 5,
    width: `${100 / 7}%`,
  },
  monthDayCellOutside: {
    backgroundColor: "rgba(58,50,74,0.025)",
  },
  monthDayCellToday: {
    backgroundColor: "rgba(166,149,216,0.08)",
  },
  monthDayNumber: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  monthDayNumberOutside: {
    color: "rgba(58,50,74,0.32)",
  },
  monthDayNumberToday: {
    color: megrumColors.lavender,
  },
  monthScheduleStack: {
    gap: 3,
    marginTop: 4,
  },
  monthSchedulePill: {
    borderRadius: 7,
    paddingHorizontal: 4,
    paddingVertical: 2,
  },
  monthSchedulePillMe: {
    backgroundColor: "rgba(166,149,216,0.84)",
  },
  monthSchedulePillPartner: {
    backgroundColor: "rgba(168,212,230,0.90)",
  },
  monthSchedulePillText: {
    color: "#fff",
    fontSize: 8.5,
    fontWeight: "900",
  },
  monthMoreText: {
    color: megrumColors.mutedInk,
    fontSize: 9,
    fontWeight: "900",
  },
});
