import { LinearGradient } from "expo-linear-gradient";
import { type ReactNode } from "react";
import { StyleSheet, View, type StyleProp, type ViewStyle } from "react-native";
import { megrumColors } from "../theme/tokens";

const outgoingGradientColors = [
  megrumColors.lavender,
  "#a7a3dd",
  "#a8b4e4",
  "#a8c5e9",
  megrumColors.sky,
] as const;

const outgoingGradientLocations = [0, 0.26, 0.52, 0.78, 1] as const;

type ChatGradientBubbleProps = {
  children: ReactNode;
  mine?: boolean;
  style?: StyleProp<ViewStyle>;
};

export function ChatGradientBubble({
  children,
  mine = false,
  style,
}: ChatGradientBubbleProps) {
  if (!mine) {
    return (
      <View style={[styles.shell, styles.theirShell, style]}>
        <View style={styles.content}>{children}</View>
      </View>
    );
  }

  return (
    <LinearGradient
      colors={outgoingGradientColors}
      end={{ x: 0.96, y: 0.62 }}
      locations={outgoingGradientLocations}
      start={{ x: 0.04, y: 0.38 }}
      style={[styles.shell, style]}
    >
      <View style={styles.content}>{children}</View>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  shell: {
    overflow: "hidden",
  },
  theirShell: {
    backgroundColor: "#fff",
  },
  content: {
    position: "relative",
  },
});
