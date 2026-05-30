import type { PropsWithChildren } from "react";
import { StyleSheet, Text, View } from "react-native";
import { LiquidGlassSurface } from "./LiquidGlass";
import { megrumColors, megrumRadii, megrumShadow } from "../theme/tokens";

type FoundationCardProps = PropsWithChildren<{
  eyebrow?: string;
  title: string;
  body?: string;
}>;

export function FoundationCard({
  eyebrow,
  title,
  body,
  children,
}: FoundationCardProps) {
  return (
    <LiquidGlassSurface
      isInteractive
      style={styles.card}
      fallbackStyle={styles.cardFallback}
      tintColor="rgba(255,255,255,0.30)"
    >
      {eyebrow ? <Text style={styles.eyebrow}>{eyebrow}</Text> : null}
      <Text style={styles.title}>{title}</Text>
      {body ? <Text style={styles.body}>{body}</Text> : null}
      {children ? <View style={styles.children}>{children}</View> : null}
    </LiquidGlassSurface>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.72)",
    borderRadius: megrumRadii.lg,
    overflow: "hidden",
    padding: 16,
    ...megrumShadow,
  },
  cardFallback: {
    backgroundColor: megrumColors.surface,
  },
  eyebrow: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 0.6,
    marginBottom: 5,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
    letterSpacing: 0,
  },
  body: {
    color: megrumColors.mutedInk,
    fontSize: 12.5,
    fontWeight: "600",
    lineHeight: 19,
    marginTop: 8,
  },
  children: {
    marginTop: 14,
  },
});
