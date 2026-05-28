import { useEffect, useState } from "react";
import { router } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { PrimaryButton } from "../../src/components/PrimaryButton";
import { Screen } from "../../src/components/Screen";
import { useAuth } from "../../src/auth/AuthProvider";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

const PREFECTURE_GROUPS = [
  { region: "北海道・東北", prefs: ["北海道", "青森", "岩手", "宮城", "秋田", "山形", "福島"] },
  { region: "関東", prefs: ["東京", "神奈川", "千葉", "埼玉", "茨城", "栃木", "群馬"] },
  { region: "甲信越・北陸", prefs: ["新潟", "富山", "石川", "福井", "山梨", "長野"] },
  { region: "東海", prefs: ["静岡", "愛知", "岐阜", "三重"] },
  { region: "近畿", prefs: ["大阪", "兵庫", "京都", "滋賀", "奈良", "和歌山"] },
  { region: "中国", prefs: ["岡山", "広島", "山口", "鳥取", "島根"] },
  { region: "四国", prefs: ["徳島", "香川", "愛媛", "高知"] },
  { region: "九州・沖縄", prefs: ["福岡", "佐賀", "長崎", "熊本", "大分", "宮崎", "鹿児島", "沖縄"] },
];

export default function OnboardingAreaScreen() {
  const { refreshProfile, user } = useAuth();
  const [selected, setSelected] = useState<string[]>([]);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user || !supabase) return;
    supabase
      .from("users")
      .select("primary_area")
      .eq("id", user.id)
      .maybeSingle()
      .then(({ data }) => {
        const areas =
          typeof data?.primary_area === "string"
            ? data.primary_area.split(",").map((area: string) => area.trim()).filter(Boolean)
            : [];
        setSelected(areas);
      });
  }, [user]);

  function toggle(area: string) {
    setSelected((prev) =>
      prev.includes(area) ? prev.filter((item) => item !== area) : [...prev, area],
    );
  }

  async function complete(skip = false) {
    if (!user || !supabase) {
      router.replace("/login");
      return;
    }
    setPending(true);
    setError(null);
    const value = skip || selected.length === 0 ? null : selected.join(",");
    const { error: updateError } = await supabase
      .from("users")
      .update({ primary_area: value, account_status: "active" })
      .eq("id", user.id);
    setPending(false);
    if (updateError) {
      setError(updateError.message);
      return;
    }
    await refreshProfile();
    router.replace("/onboarding/done");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <Header title="プロフィール設定" sub="主な活動エリア（任意）" progress="4/4" backTo="/onboarding/members" />
      <ProgressDots current={3} />
      <Text style={styles.title}>よく行くエリアは？</Text>
      <Text style={styles.copy}>
        現地交換のマッチングに使います。{"\n"}
        ライブ・イベントごとの詳細はあとで設定できます。
      </Text>
      <View style={styles.infoBox}>
        <Text style={styles.infoText}>
          主な活動エリア（複数選択可）。ここで選んだエリアは、グッズ交換の打診時に相手の参考情報として表示されます。
        </Text>
      </View>
      <View style={styles.groups}>
        {PREFECTURE_GROUPS.map((group) => (
          <View key={group.region} style={styles.group}>
            <Text style={styles.region}>{group.region}</Text>
            <View style={styles.prefWrap}>
              {group.prefs.map((pref) => {
                const active = selected.includes(pref);
                return (
                  <Pressable
                    key={pref}
                    onPress={() => toggle(pref)}
                    style={[styles.prefChip, active ? styles.prefChipActive : null]}
                  >
                    <Text style={[styles.prefText, active ? styles.prefTextActive : null]}>
                      {pref}
                    </Text>
                  </Pressable>
                );
              })}
            </View>
          </View>
        ))}
      </View>
      <Text style={styles.selectedText}>
        選択中：{selected.length === 0 ? "—" : `${selected.length}件 ${selected.join(" / ")}`}
      </Text>
      {error ? <Text style={styles.error}>{error}</Text> : null}
      <View style={styles.footer}>
        <PrimaryButton loading={pending} onPress={() => complete(false)}>
          完了
        </PrimaryButton>
        <Pressable disabled={pending} onPress={() => complete(true)} style={styles.skipButton}>
          <Text style={styles.skipText}>あとで設定する</Text>
        </Pressable>
      </View>
    </Screen>
  );
}

function Header({ title, sub, progress, backTo }: { title: string; sub: string; progress: string; backTo: string }) {
  return (
    <View style={styles.header}>
      <Pressable onPress={() => router.replace(backTo)} style={styles.backButton}>
        <Text style={styles.backText}>‹</Text>
      </Pressable>
      <View style={styles.headerCopy}>
        <Text style={styles.headerTitle}>{title}</Text>
        <Text style={styles.headerSub}>{sub}</Text>
      </View>
      <Text style={styles.progressText}>{progress}</Text>
    </View>
  );
}

function ProgressDots({ current }: { current: number }) {
  return (
    <View style={styles.dots}>
      {[0, 1, 2, 3].map((index) => (
        <View key={index} style={[styles.dot, index <= current ? styles.dotActive : null]} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flexGrow: 1,
    gap: 13,
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
  },
  backText: {
    color: megrumColors.ink,
    fontSize: 30,
    fontWeight: "800",
    lineHeight: 32,
  },
  headerCopy: {
    flex: 1,
  },
  headerTitle: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  headerSub: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  progressText: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  dots: {
    flexDirection: "row",
    gap: 6,
    marginTop: 5,
  },
  dot: {
    backgroundColor: "rgba(58,50,74,0.12)",
    borderRadius: 999,
    flex: 1,
    height: 5,
  },
  dotActive: {
    backgroundColor: megrumColors.lavender,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 28,
  },
  copy: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 19,
  },
  infoBox: {
    backgroundColor: "rgba(168,212,230,0.12)",
    borderColor: "rgba(168,212,230,0.34)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    padding: 12,
  },
  infoText: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 18,
  },
  groups: {
    gap: 13,
  },
  group: {
    gap: 7,
  },
  region: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
  prefWrap: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 7,
  },
  prefChip: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1.5,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  prefChipActive: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderColor: megrumColors.lavender,
  },
  prefText: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  prefTextActive: {
    color: megrumColors.lavender,
  },
  selectedText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  error: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
  },
  footer: {
    gap: 8,
    paddingTop: 10,
  },
  skipButton: {
    alignItems: "center",
    paddingVertical: 12,
  },
  skipText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
  },
});
