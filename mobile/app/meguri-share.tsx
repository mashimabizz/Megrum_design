import { useState } from "react";
import { Pressable, Share, StyleSheet, Text, View } from "react-native";
import { IconSymbol } from "../src/components/IconSymbol";
import { Screen } from "../src/components/Screen";
import { RouteHeader } from "../src/components/RouteHeader";
import { megrumColors, megrumShadow } from "../src/theme/tokens";
import { USERS, WalkingCard, hueTint } from "./(tabs)/encounters";

const OPTIONS = [
  "人数を表示",
  "推しジャンルを表示",
  "ざっくりエリアを表示",
  "実績を表示",
];

const BGS = [
  { id: "lav", color: "#efe2fb" },
  { id: "pink", color: "#f9d4e0" },
  { id: "sky", color: "#cee5f1" },
  { id: "ink", color: "#3a3645" },
];

export default function MeguriShareScreen() {
  const [background, setBackground] = useState("lav");
  const [options, setOptions] = useState(() => Object.fromEntries(OPTIONS.map((item) => [item, true])));
  const dark = background === "ink";
  const bgColor = BGS.find((item) => item.id === background)?.color ?? "#efe2fb";

  async function share() {
    const details = [
      options["人数を表示"] ? "今日、同担3人とめぐりあいました。" : "今日もめぐりがありました。",
      options["ざっくりエリアを表示"] ? "関東・東京エリア" : null,
      options["実績を表示"] ? "実績「再めぐり達成」" : null,
    ].filter(Boolean);
    await Share.share({
      message: `Megrum\n${details.join("\n")}`,
    });
  }

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader title="匿名シェア画像" subtitle="SHARE" />

      <View style={[styles.poster, { backgroundColor: bgColor }]}>
        <Text style={[styles.kicker, dark ? styles.darkMuted : null]}>MEGRUM</Text>
        <Text style={[styles.title, dark ? styles.darkText : null]}>
          今日、<Text style={styles.highlight}>同担3人</Text>{"\n"}とめぐりあいました。
        </Text>
        <Text style={[styles.area, dark ? styles.darkMuted : null]}>関東 · 東京エリア</Text>
        <View style={styles.walkers}>
          {USERS.slice(0, 3).map((user, index) => (
            <View key={user.id} style={[styles.walker, { marginLeft: index === 0 ? 0 : -18, transform: [{ rotate: `${(index - 1) * 6}deg` }] }]}>
              <WalkingCard user={user} size={60} />
            </View>
          ))}
        </View>
        <View style={[styles.achievement, dark ? styles.achievementDark : null]}>
          <IconSymbol name="star-outline" color={dark ? "#fff" : megrumColors.lavender} size={13} />
          <Text style={[styles.achievementText, dark ? styles.darkText : null]}>実績「再めぐり達成」</Text>
        </View>
        <Text style={[styles.brand, dark ? styles.darkMuted : null]}>Megrum</Text>
      </View>

      <View style={styles.optionList}>
        {OPTIONS.map((option) => (
          <ToggleLine
            key={option}
            label={option}
            on={Boolean(options[option])}
            onToggle={() => setOptions((current) => ({ ...current, [option]: !current[option] }))}
          />
        ))}
      </View>

      <Text style={styles.sectionTitle}>背景</Text>
      <View style={styles.swatches}>
        {BGS.map((item) => (
          <Pressable
            key={item.id}
            onPress={() => setBackground(item.id)}
            style={[
              styles.swatch,
              { backgroundColor: item.color },
              background === item.id ? styles.swatchActive : null,
            ]}
          />
        ))}
      </View>

      <Pressable onPress={share} style={styles.primary}>
        <IconSymbol name="sparkles-outline" color="#fff" size={16} />
        <Text style={styles.primaryText}>シェアする</Text>
      </Pressable>
      <Text style={styles.safety}>相手の名前・顔・正確な位置・時刻は画像に含まれません。</Text>
    </Screen>
  );
}

function ToggleLine({ label, on, onToggle }: { label: string; on: boolean; onToggle: () => void }) {
  return (
    <Pressable onPress={onToggle} style={styles.toggleLine}>
      <Text style={styles.toggleLabel}>{label}</Text>
      <View style={[styles.toggle, on ? styles.toggleOn : null]}>
        <View style={[styles.knob, on ? styles.knobOn : null]} />
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: { gap: 16 },
  poster: {
    aspectRatio: 1,
    borderRadius: 28,
    justifyContent: "space-between",
    overflow: "hidden",
    padding: 26,
    ...megrumShadow,
  },
  kicker: {
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 2,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 32,
    fontWeight: "900",
    lineHeight: 39,
    marginTop: 8,
  },
  highlight: {
    color: megrumColors.lavender,
  },
  area: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
    marginTop: 8,
  },
  walkers: {
    alignItems: "flex-end",
    flexDirection: "row",
    justifyContent: "flex-end",
    marginTop: 20,
  },
  walker: {
    alignItems: "center",
  },
  achievement: {
    alignItems: "center",
    alignSelf: "flex-start",
    backgroundColor: "rgba(255,255,255,0.86)",
    borderRadius: 999,
    flexDirection: "row",
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  achievementDark: {
    backgroundColor: "rgba(255,255,255,0.12)",
  },
  achievementText: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  brand: {
    alignSelf: "flex-end",
    color: megrumColors.lavender,
    fontSize: 13,
    fontWeight: "900",
  },
  darkText: {
    color: "#fff",
  },
  darkMuted: {
    color: "rgba(255,255,255,0.72)",
  },
  optionList: {
    gap: 8,
  },
  toggleLine: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 16,
    flexDirection: "row",
    gap: 12,
    padding: 14,
  },
  toggleLabel: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 14,
    fontWeight: "900",
  },
  toggle: {
    backgroundColor: "rgba(58,50,74,0.14)",
    borderRadius: 999,
    height: 30,
    padding: 3,
    width: 52,
  },
  toggleOn: {
    backgroundColor: megrumColors.lavender,
  },
  knob: {
    backgroundColor: "#fff",
    borderRadius: 999,
    height: 24,
    width: 24,
  },
  knobOn: {
    transform: [{ translateX: 22 }],
  },
  sectionTitle: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1.2,
    paddingHorizontal: 6,
  },
  swatches: {
    flexDirection: "row",
    gap: 10,
  },
  swatch: {
    aspectRatio: 1,
    borderColor: "transparent",
    borderRadius: 16,
    borderWidth: 2,
    flex: 1,
  },
  swatchActive: {
    borderColor: megrumColors.lavender,
  },
  primary: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    flexDirection: "row",
    gap: 8,
    justifyContent: "center",
    paddingVertical: 16,
  },
  primaryText: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "900",
  },
  safety: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 18,
    textAlign: "center",
  },
});
