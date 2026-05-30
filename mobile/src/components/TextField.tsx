import { StyleSheet, Text, TextInput, View, type TextInputProps } from "react-native";
import { LiquidGlassSurface } from "./LiquidGlass";
import { megrumColors, megrumRadii } from "../theme/tokens";

type TextFieldProps = TextInputProps & {
  label: string;
};

export function TextField({ label, style, ...props }: TextFieldProps) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <LiquidGlassSurface
        isInteractive
        style={styles.inputSurface}
        fallbackStyle={styles.inputSurfaceFallback}
        tintColor="rgba(255,255,255,0.22)"
      >
        <TextInput
          {...props}
          placeholderTextColor="rgba(58,50,74,0.35)"
          style={[styles.input, style]}
        />
      </LiquidGlassSurface>
    </View>
  );
}

const styles = StyleSheet.create({
  field: {
    gap: 6,
  },
  label: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  input: {
    minHeight: 48,
    backgroundColor: "transparent",
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "700",
    paddingHorizontal: 14,
    paddingVertical: 11,
  },
  inputSurface: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.68)",
    borderRadius: megrumRadii.md,
    overflow: "hidden",
  },
  inputSurfaceFallback: {
    backgroundColor: "#fff",
  },
});
