import { useEffect, useRef, useState, type ReactNode } from "react";
import { Animated, Pressable, StyleSheet, Text, View } from "react-native";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import { useAuth } from "../src/auth/AuthProvider";
import { IconSymbol, type IconSymbolName } from "../src/components/IconSymbol";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii } from "../src/theme/tokens";

export default function NotificationSettingsScreen() {
  const { previewMode, user } = useAuth();
  const [emailEnabled, setEmailEnabled] = useState(true);
  const [saved, setSaved] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!supabase || !user || previewMode) {
      setEmailEnabled(true);
      setError(null);
      return;
    }

    let active = true;
    supabase
      .from("user_notification_settings")
      .select("email_enabled")
      .eq("user_id", user.id)
      .maybeSingle()
      .then(({ data, error }) => {
        if (!active) return;
        if (error) {
          setError(error.message);
          return;
        }
        setEmailEnabled((data?.email_enabled as boolean | undefined) ?? true);
      });

    return () => {
      active = false;
    };
  }, [previewMode, user]);

  async function toggleEmail() {
    const next = !emailEnabled;
    setEmailEnabled(next);
    setSaved(false);
    setError(null);
    if (!supabase || !user || previewMode) {
      setSaved(true);
      return;
    }

    setPending(true);
    const { error } = await supabase
      .from("user_notification_settings")
      .upsert(
        {
          user_id: user.id,
          email_enabled: next,
        },
        { onConflict: "user_id" },
      );
    setPending(false);
    if (error) {
      setEmailEnabled(!next);
      setError(error.message);
      return;
    }
    setSaved(true);
  }

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader title="通知設定" subtitle="チャネルごとのON/OFFを切替" />

      <SettingsSection label="アプリ内通知" sub="ホームのベルと通知一覧で確認">
        <SettingsRow
          icon="notifications-outline"
          title="アプリ内通知"
          sub="常時ON（無効化できません）"
          control={<View style={styles.onBadge}><Text style={styles.onBadgeText}>ON</Text></View>}
        />
      </SettingsSection>

      <SettingsSection
        label="メール通知"
        sub={user?.email ? `送信先：${user.email}` : "メールアドレス未設定"}
      >
        <SettingsRow
          icon="mail-outline"
          title="メール通知"
          sub="重要イベント（打診着信・合意・申告など）をメールで通知"
          control={
            <Toggle disabled={pending} on={emailEnabled} onPress={toggleEmail} />
          }
        />
      </SettingsSection>

      <View style={styles.noteBox}>
        <Text style={styles.noteTitle}>メール送信について</Text>
        <Text style={styles.noteText}>
          現在は設定の保存のみ動作します。実際のメール送信機能は次フェーズで対応します。
        </Text>
      </View>

      {saved && !error ? (
        <Text style={styles.savedText}>設定を保存しました</Text>
      ) : null}
      {error ? <Text style={styles.errorText}>{error}</Text> : null}
    </Screen>
  );
}

function SettingsSection({
  children,
  label,
  sub,
}: {
  children: ReactNode;
  label: string;
  sub?: string;
}) {
  return (
    <View style={styles.section}>
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionLabel}>{label}</Text>
        {sub ? <Text style={styles.sectionSub}>{sub}</Text> : null}
      </View>
      <View style={styles.sectionCard}>{children}</View>
    </View>
  );
}

function SettingsRow({
  control,
  icon,
  sub,
  title,
}: {
  control: ReactNode;
  icon: IconSymbolName;
  sub?: string;
  title: string;
}) {
  return (
    <View style={styles.row}>
      <View style={styles.rowIcon}>
        <IconSymbol name={icon} size={19} color={megrumColors.lavender} />
      </View>
      <View style={styles.rowCopy}>
        <Text style={styles.rowTitle}>{title}</Text>
        {sub ? <Text style={styles.rowSub}>{sub}</Text> : null}
      </View>
      {control}
    </View>
  );
}

function Toggle({
  disabled,
  on,
  onPress,
}: {
  disabled?: boolean;
  on: boolean;
  onPress: () => void;
}) {
  const progress = useRef(new Animated.Value(on ? 1 : 0)).current;

  useEffect(() => {
    Animated.spring(progress, {
      toValue: on ? 1 : 0,
      damping: 18,
      stiffness: 220,
      useNativeDriver: true,
    }).start();
  }, [on, progress]);

  const translateX = progress.interpolate({
    inputRange: [0, 1],
    outputRange: [3, 21],
  });

  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityState={{ checked: on, disabled }}
      disabled={disabled}
      onPress={onPress}
      style={[styles.toggle, on ? styles.toggleOn : styles.toggleOff, disabled ? styles.disabled : null]}
    >
      <Animated.View style={[styles.knob, { transform: [{ translateX }] }]} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: {
    gap: 16,
  },
  section: {
    gap: 7,
  },
  sectionHeader: {
    gap: 2,
    paddingHorizontal: 2,
  },
  sectionLabel: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
    letterSpacing: 0.4,
  },
  sectionSub: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "700",
  },
  sectionCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    overflow: "hidden",
  },
  row: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
    paddingHorizontal: 14,
    paddingVertical: 13,
  },
  rowIcon: {
    alignItems: "center",
    height: 30,
    justifyContent: "center",
    width: 30,
  },
  rowCopy: {
    flex: 1,
  },
  rowTitle: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  rowSub: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "700",
    lineHeight: 15,
    marginTop: 2,
  },
  onBadge: {
    backgroundColor: megrumColors.ok,
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 8,
    paddingVertical: 2,
  },
  onBadgeText: {
    color: megrumColors.surface,
    fontSize: 9.5,
    fontWeight: "900",
  },
  toggle: {
    borderRadius: megrumRadii.pill,
    height: 26,
    justifyContent: "center",
    width: 44,
  },
  toggleOn: {
    backgroundColor: megrumColors.ok,
  },
  toggleOff: {
    backgroundColor: "rgba(58,50,74,0.22)",
  },
  knob: {
    backgroundColor: megrumColors.surface,
    borderRadius: megrumRadii.pill,
    height: 20,
    width: 20,
  },
  disabled: {
    opacity: 0.55,
  },
  noteBox: {
    backgroundColor: "rgba(166,149,216,0.05)",
    borderRadius: 10,
    padding: 12,
  },
  noteTitle: {
    color: megrumColors.ink,
    fontSize: 11,
    fontWeight: "900",
  },
  noteText: {
    color: megrumColors.ink,
    fontSize: 10.5,
    fontWeight: "700",
    lineHeight: 16,
    marginTop: 3,
  },
  savedText: {
    backgroundColor: "rgba(34,197,94,0.10)",
    borderColor: "rgba(34,197,94,0.24)",
    borderRadius: 10,
    borderWidth: 1,
    color: "#15803d",
    fontSize: 11,
    fontWeight: "900",
    padding: 10,
    textAlign: "center",
  },
  errorText: {
    backgroundColor: "rgba(217,130,107,0.10)",
    borderColor: "rgba(217,130,107,0.22)",
    borderRadius: 10,
    borderWidth: 1,
    color: megrumColors.warn,
    fontSize: 11,
    fontWeight: "800",
    padding: 10,
    textAlign: "center",
  },
});
