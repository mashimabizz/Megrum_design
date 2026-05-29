import { StyleSheet, Text, View } from "react-native";
import { Screen } from "../src/components/Screen";
import { RouteHeader } from "../src/components/RouteHeader";
import { IconSymbol } from "../src/components/IconSymbol";
import { megrumColors, megrumShadow } from "../src/theme/tokens";
import { ACHIEVEMENTS, hueColor, hueTint } from "./(tabs)/encounters";

export default function MeguriAchievementsScreen() {
  const unlocked = ACHIEVEMENTS.filter((item) => item.unlocked).length;

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader title="実績" subtitle="めぐりあった体験が残ります" />

      <View style={styles.hero}>
        <Text style={styles.kicker}>ACHIEVEMENTS</Text>
        <View style={styles.progressRing}>
          <Text style={styles.big}>{unlocked}</Text>
          <Text style={styles.total}>/ {ACHIEVEMENTS.length}</Text>
        </View>
        <Text style={styles.title}>個の実績を解除しました</Text>
      </View>

      <View style={styles.summaryRow}>
        <SummaryTile label="今日" value="1" hue="butter" />
        <SummaryTile label="再めぐり" value="3" hue="lav" />
        <SummaryTile label="メッセージ" value="1" hue="pink" />
      </View>

      <View style={styles.list}>
        {ACHIEVEMENTS.map((achievement) => (
          <View
            key={achievement.id}
            style={[
              styles.card,
              {
                backgroundColor: achievement.unlocked
                  ? hueTint(achievement.hue, 0.22)
                  : "rgba(58,50,74,0.05)",
              },
            ]}
          >
            <View
              style={[
                styles.icon,
                {
                  backgroundColor: achievement.unlocked
                    ? hueColor(achievement.hue)
                    : "rgba(58,50,74,0.12)",
                },
              ]}
            >
              <IconSymbol
                name={achievement.unlocked ? "checkmark-circle-outline" : "lock-closed-outline"}
                color={achievement.unlocked ? "#fff" : "rgba(58,50,74,0.44)"}
                size={22}
              />
            </View>
            <View style={styles.copy}>
              <Text style={styles.cardTitle}>{achievement.title}</Text>
              <Text style={styles.cardText}>{achievement.description}</Text>
            </View>
            <Text style={styles.cardStatus}>{achievement.unlocked ? "解除済み" : "未解除"}</Text>
          </View>
        ))}
      </View>
    </Screen>
  );
}

function SummaryTile({ hue, label, value }: { hue: "butter" | "lav" | "pink"; label: string; value: string }) {
  return (
    <View style={[styles.summaryTile, { backgroundColor: hueTint(hue, 0.18) }]}>
      <Text style={[styles.summaryValue, { color: hueColor(hue) }]}>{value}</Text>
      <Text style={styles.summaryLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { gap: 16 },
  hero: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 32,
    padding: 26,
    ...megrumShadow,
  },
  kicker: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.8,
  },
  progressRing: {
    alignItems: "baseline",
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: 46,
    borderWidth: 8,
    flexDirection: "row",
    height: 112,
    justifyContent: "center",
    marginTop: 14,
    width: 112,
  },
  big: {
    color: megrumColors.ink,
    fontSize: 50,
    fontWeight: "900",
    lineHeight: 92,
  },
  total: {
    color: megrumColors.mutedInk,
    fontSize: 14,
    fontWeight: "900",
  },
  title: {
    color: megrumColors.mutedInk,
    fontSize: 14,
    fontWeight: "900",
    marginTop: 10,
  },
  summaryRow: {
    flexDirection: "row",
    gap: 10,
  },
  summaryTile: {
    borderRadius: 18,
    flex: 1,
    padding: 14,
  },
  summaryValue: {
    fontSize: 28,
    fontWeight: "900",
  },
  summaryLabel: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  list: {
    gap: 12,
  },
  card: {
    alignItems: "center",
    borderRadius: 24,
    flexDirection: "row",
    gap: 14,
    padding: 16,
  },
  icon: {
    alignItems: "center",
    borderRadius: 19,
    height: 46,
    justifyContent: "center",
    width: 46,
  },
  copy: { flex: 1 },
  cardTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  cardText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    marginTop: 4,
  },
  cardStatus: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "900",
  },
});
