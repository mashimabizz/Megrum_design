import type { PropsWithChildren } from "react";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  type PressableProps,
} from "react-native";
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
        variant === "secondary" ? styles.secondary : styles.primary,
        pressed && !isDisabled ? styles.pressed : null,
        isDisabled ? styles.disabled : null,
        typeof style === "function" ? style({ pressed }) : style,
      ]}
    >
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
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    minHeight: 50,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: megrumRadii.md,
    paddingHorizontal: 18,
  },
  primary: {
    backgroundColor: megrumColors.lavender,
  },
  secondary: {
    borderWidth: 1.5,
    borderColor: "rgba(166,149,216,0.45)",
    backgroundColor: "#fff",
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
