import { StyleSheet, Text, TextInput, View, type TextInputProps } from "react-native";
import { megrumColors, megrumRadii } from "../theme/tokens";

type TextFieldProps = TextInputProps & {
  label: string;
};

export function TextField({ label, style, ...props }: TextFieldProps) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        {...props}
        placeholderTextColor="rgba(58,50,74,0.35)"
        style={[styles.input, style]}
      />
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
    borderWidth: 1,
    borderColor: "rgba(58,50,74,0.12)",
    borderRadius: megrumRadii.md,
    backgroundColor: "#fff",
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "700",
    paddingHorizontal: 14,
  },
});
