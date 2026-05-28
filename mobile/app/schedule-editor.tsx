import { useEffect, useState } from "react";
import { router, useLocalSearchParams } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import { TextField } from "../src/components/TextField";
import { useAuth } from "../src/auth/AuthProvider";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii } from "../src/theme/tokens";

export default function ScheduleEditorScreen() {
  const params = useLocalSearchParams<{ id?: string | string[] }>();
  const scheduleId = Array.isArray(params.id) ? params.id[0] : params.id;
  const mode = scheduleId ? "edit" : "create";
  const { previewMode, user } = useAuth();
  const [title, setTitle] = useState("");
  const [startAt, setStartAt] = useState(formatLocalInput(new Date()));
  const [endAt, setEndAt] = useState(formatLocalInput(new Date(Date.now() + 2 * 60 * 60 * 1000)));
  const [allDay, setAllDay] = useState(false);
  const [note, setNote] = useState("");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!scheduleId || !supabase || !user || previewMode) return;
    let active = true;
    supabase
      .from("schedules")
      .select("title, start_at, end_at, all_day, note")
      .eq("id", scheduleId)
      .eq("user_id", user.id)
      .maybeSingle()
      .then(({ data, error }) => {
        if (!active) return;
        if (error) {
          setError(error.message);
          return;
        }
        if (!data) {
          setError("予定が見つかりません");
          return;
        }
        setTitle((data.title as string | null) ?? "");
        setStartAt(formatLocalInput(new Date(data.start_at as string)));
        setEndAt(formatLocalInput(new Date(data.end_at as string)));
        setAllDay(Boolean(data.all_day));
        setNote((data.note as string | null) ?? "");
      });

    return () => {
      active = false;
    };
  }, [previewMode, scheduleId, user]);

  async function submit() {
    setError(null);
    const trimmedTitle = title.trim();
    if (!trimmedTitle) {
      setError("タイトルを入力してください");
      return;
    }
    const startDate = parseLocalInput(startAt, allDay, false);
    const endDate = parseLocalInput(endAt, allDay, true);
    if (!startDate || !endDate) {
      setError(allDay ? "日付は YYYY-MM-DD 形式で入力してください" : "日時は YYYY-MM-DD HH:mm 形式で入力してください");
      return;
    }
    if (endDate.getTime() <= startDate.getTime()) {
      setError("終了は開始より後にしてください");
      return;
    }
    if (!supabase || !user || previewMode) {
      router.replace("/schedules");
      return;
    }

    setPending(true);
    const payload = {
      title: trimmedTitle,
      start_at: startDate.toISOString(),
      end_at: endDate.toISOString(),
      all_day: allDay,
      note: note.trim() || null,
    };
    const result =
      mode === "create"
        ? await supabase.from("schedules").insert({ ...payload, user_id: user.id })
        : await supabase
            .from("schedules")
            .update(payload)
            .eq("id", scheduleId)
            .eq("user_id", user.id);
    setPending(false);
    if (result.error) {
      setError(result.error.message);
      return;
    }
    router.replace("/schedules");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader
        title={mode === "create" ? "予定を追加" : "予定を編集"}
        subtitle="打診時のカレンダー公開で使う個人予定"
      />

      <View style={styles.form}>
        <TextField
          label="タイトル"
          onChangeText={setTitle}
          placeholder="例: 出張・友人ランチ・ライブ参戦"
          value={title}
        />
        <View style={styles.toggleRow}>
          <Pressable
            accessibilityRole="checkbox"
            accessibilityState={{ checked: allDay }}
            onPress={() => setAllDay((current) => !current)}
            style={[styles.checkbox, allDay ? styles.checkboxOn : null]}
          >
            {allDay ? <Text style={styles.check}>✓</Text> : null}
          </Pressable>
          <Text style={styles.toggleLabel}>終日</Text>
        </View>
        <TextField
          label="開始"
          onChangeText={setStartAt}
          placeholder={allDay ? "YYYY-MM-DD" : "YYYY-MM-DD HH:mm"}
          value={allDay ? startAt.slice(0, 10) : startAt}
        />
        <TextField
          label="終了"
          onChangeText={setEndAt}
          placeholder={allDay ? "YYYY-MM-DD" : "YYYY-MM-DD HH:mm"}
          value={allDay ? endAt.slice(0, 10) : endAt}
        />
        <TextField
          label={`メモ（任意） ${note.length} / 500`}
          multiline
          numberOfLines={3}
          onChangeText={(value) => setNote(value.slice(0, 500))}
          placeholder="補足メモ"
          value={note}
        />
      </View>

      {error ? <Text style={styles.error}>{error}</Text> : null}
      <PrimaryButton loading={pending} onPress={submit}>
        {mode === "create" ? "予定を追加" : "変更を保存"}
      </PrimaryButton>
    </Screen>
  );
}

function formatLocalInput(date: Date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  const hour = String(date.getHours()).padStart(2, "0");
  const minute = String(date.getMinutes()).padStart(2, "0");
  return `${year}-${month}-${day} ${hour}:${minute}`;
}

function parseLocalInput(value: string, allDay: boolean, endOfDay: boolean) {
  const trimmed = value.trim();
  if (allDay) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) return null;
    const suffix = endOfDay ? "T23:59:00" : "T00:00:00";
    const date = new Date(`${trimmed}${suffix}`);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  const normalized = trimmed.replace(" ", "T");
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(normalized)) return null;
  const date = new Date(`${normalized}:00`);
  return Number.isNaN(date.getTime()) ? null : date;
}

const styles = StyleSheet.create({
  screen: {
    gap: 18,
  },
  form: {
    gap: 13,
  },
  toggleRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
  },
  checkbox: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.20)",
    borderRadius: 5,
    borderWidth: 1.5,
    height: 22,
    justifyContent: "center",
    width: 22,
  },
  checkboxOn: {
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.lavender,
  },
  check: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
  },
  toggleLabel: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "800",
  },
  error: {
    backgroundColor: "rgba(217,130,107,0.10)",
    borderColor: "rgba(217,130,107,0.22)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    padding: 12,
  },
});
