import type { PropsWithChildren } from "react";
import { StyleSheet, Text, View } from "react-native";
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
    <View style={styles.card}>
      {eyebrow ? <Text style={styles.eyebrow}>{eyebrow}</Text> : null}
      <Text style={styles.title}>{title}</Text>
      {body ? <Text style={styles.body}>{body}</Text> : null}
      {children ? <View style={styles.children}>{children}</View> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    backgroundColor: megrumColors.surface,
    padding: 16,
    ...megrumShadow,
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
