import type { PropsWithChildren } from "react";
import {
  ScrollView,
  StyleSheet,
  View,
  type ViewStyle,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { megrumColors } from "../theme/tokens";

type ScreenProps = PropsWithChildren<{
  bottomInset?: boolean;
  scroll?: boolean;
  contentStyle?: ViewStyle;
  topInset?: boolean;
  topPadding?: number;
}>;

export function Screen({
  bottomInset = true,
  children,
  scroll = true,
  contentStyle,
  topInset = true,
  topPadding,
}: ScreenProps) {
  const insets = useSafeAreaInsets();
  const paddingTop = topPadding ?? (topInset ? Math.max(insets.top, 18) + 14 : 14);
  const paddingBottom = bottomInset ? Math.max(insets.bottom, 12) + 96 : 0;

  if (scroll) {
    return (
      <ScrollView
        automaticallyAdjustsScrollIndicatorInsets
        contentInsetAdjustmentBehavior="automatic"
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
    <View
      style={[
        styles.root,
        styles.content,
        { paddingTop, paddingBottom },
        contentStyle,
      ]}
    >
      {children}
    </View>
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
