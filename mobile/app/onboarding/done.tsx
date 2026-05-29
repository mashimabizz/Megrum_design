import { useEffect, useState } from "react";
import { router } from "expo-router";
import { StyleSheet, Text, View } from "react-native";
import { PrimaryButton } from "../../src/components/PrimaryButton";
import { Screen } from "../../src/components/Screen";
import { useAuth } from "../../src/auth/AuthProvider";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../../src/theme/tokens";

type Summary = {
  displayName: string;
  area: string | null;
  oshi: string;
};

export default function OnboardingDoneScreen() {
  const { user } = useAuth();
  const [summary, setSummary] = useState<Summary>({
    displayName: "Megrumユーザー",
    area: null,
    oshi: "推し設定済み",
  });

  useEffect(() => {
    if (!user || !supabase) return;
    Promise.all([
      supabase
        .from("users")
        .select("display_name, handle, primary_area")
        .eq("id", user.id)
        .maybeSingle(),
      supabase
        .from("user_oshi")
        .select("group:groups_master(name), oshi_request:oshi_requests(requested_name)")
        .eq("user_id", user.id)
        .order("priority", { ascending: true })
        .limit(3),
    ]).then(([profileRes, oshiRes]) => {
      const profile = profileRes.data as Record<string, unknown> | null;
      const oshiNames = ((oshiRes.data as Record<string, unknown>[] | null) ?? [])
        .map((row) => {
          const group = pickName(row.group as RelationName | undefined);
          const request = pickRequest(row.oshi_request as RequestRelation | undefined);
          return group ?? request;
        })
        .filter((name): name is string => !!name);
      setSummary({
        displayName: String(profile?.display_name ?? profile?.handle ?? "Megrumユーザー"),
        area: typeof profile?.primary_area === "string" ? profile.primary_area : null,
        oshi: oshiNames.length > 0 ? oshiNames.join(" / ") : "推し未設定",
      });
    });
  }, [user]);

  return (
    <Screen contentStyle={styles.screen}>
      <View style={styles.center}>
        <View style={styles.checkCircle}>
          <Text style={styles.check}>✓</Text>
        </View>
        <Text style={styles.title}>{summary.displayName}さんのプロフィール設定が完了しました</Text>
        <View style={styles.summaryCard}>
          <SummaryRow label="推し" value={summary.oshi} />
          <SummaryRow label="エリア" value={summary.area ?? "あとで設定"} />
        </View>
      </View>
      <PrimaryButton onPress={() => router.replace("/(tabs)")}>
        ホームへ
      </PrimaryButton>
    </Screen>
  );
}

function SummaryRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.summaryRow}>
      <Text style={styles.summaryLabel}>{label}</Text>
      <Text numberOfLines={2} style={styles.summaryValue}>{value}</Text>
    </View>
  );
}

type RelationName = { name?: string | null } | { name?: string | null }[] | null;
type RequestRelation = { requested_name?: string | null } | { requested_name?: string | null }[] | null;

function pickName(value: RelationName | undefined) {
  if (!value) return null;
  const item = Array.isArray(value) ? value[0] : value;
  return item?.name ?? null;
}

function pickRequest(value: RequestRelation | undefined) {
  if (!value) return null;
  const item = Array.isArray(value) ? value[0] : value;
  return item?.requested_name ?? null;
}

const styles = StyleSheet.create({
  screen: {
    flexGrow: 1,
    justifyContent: "space-between",
    paddingBottom: 34,
    paddingTop: 64,
  },
  center: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  checkCircle: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 48,
    height: 96,
    justifyContent: "center",
    width: 96,
    ...megrumShadow,
  },
  check: {
    color: megrumColors.surface,
    fontSize: 52,
    fontWeight: "900",
    lineHeight: 58,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 30,
    marginTop: 26,
    textAlign: "center",
  },
  summaryCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 12,
    marginTop: 26,
    padding: 16,
    width: "100%",
  },
  summaryRow: {
    flexDirection: "row",
    gap: 12,
  },
  summaryLabel: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
    width: 58,
  },
  summaryValue: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 13,
    fontWeight: "900",
    lineHeight: 19,
  },
});
