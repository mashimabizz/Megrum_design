import { Pressable, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { IconSymbol } from "../src/components/IconSymbol";
import { Screen } from "../src/components/Screen";
import { RouteHeader } from "../src/components/RouteHeader";
import { megrumColors, megrumShadow } from "../src/theme/tokens";
import { USERS, WalkingCard, hueColor, hueTint } from "./(tabs)/encounters";

const BREAKDOWN = [
  { label: "同担", value: 3, hue: "lav" as const },
  { label: "初めてのエリア", value: 1, hue: "sky" as const },
  { label: "メッセージ", value: 1, hue: "pink" as const },
];

export default function MeguriReportScreen() {
  const router = useRouter();
  const today = USERS.slice(0, 5);
  const featured = today[1];

  return (
    <Screen contentStyle={styles.screen}>
      <View style={styles.glowTop} />
      <RouteHeader title="今日のレポート" subtitle="11月14日(金) のめぐり" />

      <View style={styles.heroTitle}>
        <Text style={styles.kicker}>DAILY REPORT</Text>
        <Text style={styles.pageTitle}>今日のめぐり</Text>
      </View>

      <View style={styles.numberCard}>
        <View>
          <Text style={styles.numberLabel}>めぐりあった人</Text>
          <View style={styles.numberRow}>
            <Text style={styles.big}>5</Text>
            <Text style={styles.unit}>人</Text>
          </View>
        </View>
        <View style={styles.miniPile}>
          {today.slice(0, 3).map((user, index) => (
            <View key={user.id} style={[styles.pileItem, { marginLeft: index === 0 ? 0 : -22, zIndex: 4 - index }]}>
              <WalkingCard user={user} size={48} />
            </View>
          ))}
        </View>
      </View>

      <View style={styles.breakdown}>
        {BREAKDOWN.map((item) => (
          <View key={item.label} style={[styles.breakdownTile, { backgroundColor: hueTint(item.hue, 0.18) }]}>
            <Text style={[styles.breakdownValue, { color: hueColor(item.hue) }]}>{item.value}</Text>
            <Text style={styles.breakdownLabel}>{item.label}</Text>
          </View>
        ))}
      </View>

      <Text style={styles.sectionTitle}>今日のカード</Text>
      <View style={styles.featureCard}>
        <WalkingCard user={featured} size={78} active />
        <View style={styles.featureCopy}>
          <Text style={styles.featureName}>@{featured.id} さん</Text>
          <Text style={styles.featureMeta}>
            {featured.oshi}推し · {featured.area}
          </Text>
          <Text style={styles.featureBubble}>「{featured.hitokoto}」</Text>
        </View>
      </View>

      <Pressable onPress={() => router.push("/meguri-achievements")} style={styles.achievement}>
        <View style={styles.achievementIcon}>
          <IconSymbol name="star-outline" color="#8a6e2c" size={18} />
        </View>
        <View style={styles.achievementCopy}>
          <Text style={styles.achievementTitle}>新しい実績を達成</Text>
          <Text style={styles.achievementText}>「再めぐり達成」</Text>
        </View>
        <IconSymbol name="chevron-forward" color="rgba(58,50,74,0.44)" size={16} />
      </Pressable>

      <Pressable onPress={() => router.push("/meguri-share")} style={styles.primary}>
        <IconSymbol name="sparkles-outline" color="#fff" size={16} />
        <Text style={styles.primaryText}>匿名で画像をシェア</Text>
      </Pressable>
      <Pressable onPress={() => router.push("/meguri-map")} style={styles.secondary}>
        <Text style={styles.secondaryText}>マップを見る</Text>
      </Pressable>
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: { gap: 16, overflow: "hidden" },
  glowTop: {
    backgroundColor: "rgba(243,197,212,0.22)",
    borderRadius: 999,
    height: 220,
    position: "absolute",
    right: -90,
    top: -70,
    width: 260,
  },
  heroTitle: {
    paddingHorizontal: 6,
  },
  kicker: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.8,
  },
  pageTitle: {
    color: megrumColors.ink,
    fontSize: 36,
    fontWeight: "900",
    lineHeight: 43,
    marginTop: 5,
  },
  numberCard: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 26,
    flexDirection: "row",
    justifyContent: "space-between",
    minHeight: 136,
    padding: 22,
    ...megrumShadow,
  },
  numberLabel: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 0.6,
  },
  numberRow: {
    alignItems: "baseline",
    flexDirection: "row",
    gap: 4,
    marginTop: 5,
  },
  big: {
    color: megrumColors.ink,
    fontSize: 58,
    fontWeight: "900",
    lineHeight: 62,
  },
  unit: {
    color: megrumColors.lavender,
    fontSize: 20,
    fontWeight: "900",
  },
  miniPile: {
    alignItems: "center",
    flexDirection: "row",
  },
  pileItem: {
    transform: [{ scale: 0.92 }],
  },
  breakdown: {
    flexDirection: "row",
    gap: 10,
  },
  breakdownTile: {
    borderRadius: 19,
    flex: 1,
    minHeight: 92,
    padding: 14,
  },
  breakdownValue: {
    fontSize: 31,
    fontWeight: "900",
    lineHeight: 35,
  },
  breakdownLabel: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
    lineHeight: 16,
    marginTop: "auto",
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
    marginTop: 4,
    paddingHorizontal: 6,
  },
  featureCard: {
    alignItems: "flex-start",
    backgroundColor: "#fff",
    borderRadius: 24,
    flexDirection: "row",
    gap: 14,
    padding: 18,
    ...megrumShadow,
  },
  featureCopy: {
    flex: 1,
    paddingTop: 4,
  },
  featureName: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  featureMeta: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 2,
  },
  featureBubble: {
    backgroundColor: hueTint("lav", 0.18),
    borderRadius: 14,
    color: megrumColors.ink,
    fontSize: 12.5,
    fontWeight: "800",
    lineHeight: 19,
    marginTop: 10,
    overflow: "hidden",
    padding: 11,
  },
  achievement: {
    alignItems: "center",
    backgroundColor: "#f8e8b2",
    borderRadius: 18,
    flexDirection: "row",
    gap: 12,
    padding: 15,
  },
  achievementIcon: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.72)",
    borderRadius: 13,
    height: 40,
    justifyContent: "center",
    width: 40,
  },
  achievementCopy: {
    flex: 1,
  },
  achievementTitle: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "900",
  },
  achievementText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 2,
  },
  primary: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    flexDirection: "row",
    gap: 8,
    justifyContent: "center",
    paddingVertical: 15,
  },
  primaryText: {
    color: "#fff",
    fontSize: 15,
    fontWeight: "900",
  },
  secondary: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 999,
    borderWidth: 1,
    paddingVertical: 14,
  },
  secondaryText: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
});
