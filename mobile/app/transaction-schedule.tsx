import { router, Stack, useLocalSearchParams } from "expo-router";
import { useEffect, useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { Screen } from "../src/components/Screen";
import { useAuth } from "../src/auth/AuthProvider";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type ScheduleOwner = "me" | "partner";

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

export default function TransactionScheduleScreen() {
  const params = useLocalSearchParams<{
    proposalId?: string | string[];
    partnerId?: string | string[];
  }>();
  const partnerId = one(params.partnerId);
  const { previewMode, user } = useAuth();
  const [items, setItems] = useState<ScheduleOverlayItem[]>(() =>
    previewMode || !supabase ? PREVIEW_ITEMS : [],
  );
  const [loading, setLoading] = useState(!!supabase && !previewMode);
  const [error, setError] = useState<string | null>(null);

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

  const grouped = useMemo(() => groupSchedulesByDay(items), [items]);

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

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.timelineContent}
      >
        {grouped.length > 0 ? (
          grouped.map((day) => (
            <View key={day.id} style={styles.daySection}>
              <View style={styles.dayHeader}>
                <Text style={styles.dayTitle}>{day.label}</Text>
                <Text style={styles.dayCount}>{day.items.length}件</Text>
              </View>
              <View style={styles.dayItems}>
                {day.items.map((item) => (
                  <View
                    key={item.id}
                    style={[
                      styles.scheduleCard,
                      item.owner === "me" ? styles.scheduleCardMe : styles.scheduleCardPartner,
                    ]}
                  >
                    <View style={styles.scheduleCardHeader}>
                      <Text style={styles.scheduleTime}>
                        {formatScheduleRange(item.startAt, item.endAt, item.allDay)}
                      </Text>
                      <Text
                        style={[
                          styles.ownerBadge,
                          item.owner === "me" ? styles.ownerBadgeMe : styles.ownerBadgePartner,
                        ]}
                      >
                        {item.owner === "me" ? "あなた" : "相手"}
                      </Text>
                    </View>
                    <Text style={styles.scheduleTitle}>{item.title}</Text>
                    {item.placeName ? (
                      <Text style={styles.schedulePlace}>{item.placeName}</Text>
                    ) : null}
                  </View>
                ))}
              </View>
            </View>
          ))
        ) : (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyTitle}>表示できる予定がありません</Text>
            <Text style={styles.emptyBody}>
              自分の予定を更新するか、打診時にスケジュール共有が有効か確認してください。
            </Text>
          </View>
        )}
      </ScrollView>
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

function groupSchedulesByDay(items: ScheduleOverlayItem[]) {
  const map = new Map<string, ScheduleOverlayItem[]>();
  items.forEach((item) => {
    const key = dateKey(new Date(item.startAt));
    map.set(key, [...(map.get(key) ?? []), item]);
  });
  return Array.from(map.entries()).map(([id, dayItems]) => ({
    id,
    label: formatDayLabel(id),
    items: dayItems.sort((a, b) => new Date(a.startAt).getTime() - new Date(b.startAt).getTime()),
  }));
}

function formatDayLabel(dateId: string) {
  const date = new Date(`${dateId}T00:00:00+09:00`);
  if (Number.isNaN(date.getTime())) return dateId;
  const weekdays = ["日", "月", "火", "水", "木", "金", "土"];
  return `${date.getMonth() + 1}月${date.getDate()}日（${weekdays[date.getDay()]}）`;
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
  timelineContent: {
    gap: 14,
    paddingBottom: 22,
  },
  daySection: {
    gap: 8,
  },
  dayHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  dayTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  dayCount: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  dayItems: {
    gap: 8,
  },
  scheduleCard: {
    backgroundColor: megrumColors.surface,
    borderRadius: 14,
    borderWidth: 1,
    gap: 5,
    padding: 12,
  },
  scheduleCardMe: {
    borderColor: "rgba(166,149,216,0.36)",
  },
  scheduleCardPartner: {
    borderColor: "rgba(168,212,230,0.55)",
  },
  scheduleCardHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  scheduleTime: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  ownerBadge: {
    borderRadius: megrumRadii.pill,
    fontSize: 10,
    fontWeight: "900",
    overflow: "hidden",
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  ownerBadgeMe: {
    backgroundColor: "rgba(166,149,216,0.12)",
    color: megrumColors.lavender,
  },
  ownerBadgePartner: {
    backgroundColor: "rgba(168,212,230,0.20)",
    color: "#5c8da8",
  },
  scheduleTitle: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  schedulePlace: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  emptyCard: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.035)",
    borderRadius: 16,
    gap: 6,
    padding: 18,
  },
  emptyTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  emptyBody: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "700",
    lineHeight: 18,
    textAlign: "center",
  },
});
