import type { PropsWithChildren } from "react";
import {
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  type ViewStyle,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useKeyboardInset } from "../lib/useKeyboardInset";
import { megrumColors } from "../theme/tokens";

type ScreenProps = PropsWithChildren<{
  bottomInset?: boolean;
  scroll?: boolean;
  contentStyle?: ViewStyle;
  keyboardAware?: boolean;
  topInset?: boolean;
  topPadding?: number;
}>;

export function Screen({
  bottomInset = true,
  children,
  keyboardAware = true,
  scroll = true,
  contentStyle,
  topInset = true,
  topPadding,
}: ScreenProps) {
  const insets = useSafeAreaInsets();
  const keyboardInset = useKeyboardInset();
  const paddingTop = topPadding ?? (topInset ? Math.max(insets.top, 18) + 14 : 14);
  const keyboardPadding = keyboardAware && Platform.OS !== "ios" ? keyboardInset : 0;
  const paddingBottom = (bottomInset ? Math.max(insets.bottom, 12) + 96 : 0) + keyboardPadding;

  if (scroll) {
    return (
      <ScrollView
        automaticallyAdjustKeyboardInsets={keyboardAware}
        automaticallyAdjustsScrollIndicatorInsets
        contentInsetAdjustmentBehavior="automatic"
        keyboardDismissMode="interactive"
        keyboardShouldPersistTaps="handled"
        style={styles.root}
        contentContainerStyle={[
          styles.content,
          { paddingTop, paddingBottom },
          contentStyle,
        ]}
      >
        {children}
      </ScrollView>
    );
  }

  return (
    <KeyboardAvoidingView
      behavior={keyboardAware && Platform.OS === "ios" ? "padding" : undefined}
      enabled={keyboardAware}
      style={[
        styles.root,
        styles.content,
        { paddingTop, paddingBottom },
        contentStyle,
      ]}
    >
      {children}
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: megrumColors.background,
  },
  content: {
    paddingHorizontal: 18,
  },
});
