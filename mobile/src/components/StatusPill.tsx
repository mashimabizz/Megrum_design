import { StyleSheet, Text, View } from "react-native";
import { megrumColors, megrumRadii } from "../theme/tokens";

type Tone = "lavender" | "sky" | "pink" | "ok";

const toneStyles: Record<Tone, { bg: string; fg: string }> = {
  lavender: { bg: "rgba(166,149,216,0.16)", fg: megrumColors.lavender },
  sky: { bg: "rgba(168,212,230,0.22)", fg: "#3a7c93" },
  pink: { bg: "rgba(243,197,212,0.24)", fg: "#b45f7c" },
  ok: { bg: "rgba(34,197,94,0.12)", fg: megrumColors.ok },
};

export function StatusPill({
  label,
  tone = "lavender",
}: {
  label: string;
  tone?: Tone;
}) {
  return (
    <View style={[styles.pill, { backgroundColor: toneStyles[tone].bg }]}>
      <Text style={[styles.label, { color: toneStyles[tone].fg }]}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    alignSelf: "flex-start",
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  label: {
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0,
  },
});
