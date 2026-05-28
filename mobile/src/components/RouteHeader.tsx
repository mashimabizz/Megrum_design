import type { ReactNode } from "react";
import { router } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { megrumColors, megrumRadii } from "../theme/tokens";

type RouteHeaderProps = {
  right?: ReactNode;
  subtitle?: string;
  title: string;
};

export function RouteHeader({ right, subtitle, title }: RouteHeaderProps) {
  return (
    <View style={styles.header}>
      <Pressable
        accessibilityLabel="戻る"
        accessibilityRole="button"
        onPress={() => {
          if (router.canGoBack()) {
            router.back();
          } else {
            router.replace("/");
          }
        }}
        style={styles.backButton}
      >
        <Text style={styles.backText}>‹</Text>
      </Pressable>
      <View style={styles.copy}>
        <Text numberOfLines={1} style={styles.title}>
          {title}
        </Text>
        {subtitle ? (
          <Text numberOfLines={1} style={styles.subtitle}>
            {subtitle}
          </Text>
        ) : null}
      </View>
      <View style={styles.right}>{right}</View>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.58)",
    borderColor: "rgba(255,255,255,0.78)",
    borderRadius: 24,
    borderWidth: 1,
    flexDirection: "row",
    gap: 10,
    padding: 6,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.08,
    shadowRadius: 22,
  },
  backButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.86)",
    borderColor: "rgba(255,255,255,0.9)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 38,
    justifyContent: "center",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    width: 38,
  },
  backText: {
    color: megrumColors.ink,
    fontSize: 29,
    fontWeight: "800",
    lineHeight: 30,
  },
  copy: {
    flex: 1,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 19,
    fontWeight: "900",
    lineHeight: 24,
  },
  subtitle: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  right: {
    alignItems: "flex-end",
    minWidth: 38,
  },
});
