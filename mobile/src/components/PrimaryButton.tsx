import type { PropsWithChildren } from "react";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  View,
  type PressableProps,
} from "react-native";
import { LiquidGlassSurface } from "./LiquidGlass";
import { megrumColors, megrumRadii } from "../theme/tokens";

type PrimaryButtonProps = PropsWithChildren<
  PressableProps & {
    loading?: boolean;
    variant?: "primary" | "secondary";
  }
>;

export function PrimaryButton({
  children,
  disabled,
  loading = false,
  variant = "primary",
  style,
  ...props
}: PrimaryButtonProps) {
  const isDisabled = disabled || loading;
  return (
    <Pressable
      {...props}
      disabled={isDisabled}
      style={({ pressed }) => [
        styles.button,
        variant === "secondary" ? styles.secondaryShell : styles.primaryShell,
        pressed && !isDisabled ? styles.pressed : null,
        isDisabled ? styles.disabled : null,
        typeof style === "function" ? style({ pressed }) : style,
      ]}
    >
      <LiquidGlassSurface
        pointerEvents="none"
        style={StyleSheet.absoluteFillObject}
        fallbackStyle={variant === "secondary" ? styles.secondary : styles.primary}
        tintColor={
          variant === "secondary"
            ? "rgba(255,255,255,0.32)"
            : "rgba(166,149,216,0.38)"
        }
      />
      <View style={styles.content}>
        {loading ? (
          <ActivityIndicator color={variant === "primary" ? "#fff" : megrumColors.lavender} />
        ) : (
          <Text
            style={[
              styles.label,
              variant === "secondary" ? styles.secondaryLabel : styles.primaryLabel,
            ]}
          >
            {children}
          </Text>
        )}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    minHeight: 50,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: megrumRadii.md,
    overflow: "hidden",
    paddingHorizontal: 18,
  },
  primaryShell: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.68)",
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.2,
    shadowRadius: 18,
  },
  secondaryShell: {
    borderWidth: 1,
    borderColor: "rgba(166,149,216,0.28)",
  },
  primary: {
    backgroundColor: megrumColors.lavender,
  },
  secondary: {
    borderWidth: 1.5,
    borderColor: "rgba(166,149,216,0.45)",
    backgroundColor: "#fff",
  },
  content: {
    alignItems: "center",
    justifyContent: "center",
    minHeight: 50,
  },
  pressed: {
    transform: [{ scale: 0.985 }],
    opacity: 0.92,
  },
  disabled: {
    opacity: 0.55,
  },
  label: {
    fontSize: 14,
    fontWeight: "900",
    letterSpacing: 0,
  },
  primaryLabel: {
    color: "#fff",
  },
  secondaryLabel: {
    color: megrumColors.lavender,
  },
});
