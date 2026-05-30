import type { PropsWithChildren } from "react";
import {
  Keyboard,
  StyleSheet,
  TextInput,
  View,
  type GestureResponderEvent,
} from "react-native";

function dismissKeyboardWhenTouchLeavesInput(event: GestureResponderEvent) {
  const focusedInput = TextInput.State.currentlyFocusedInput();
  if (focusedInput && event.target !== focusedInput) {
    Keyboard.dismiss();
  }
  return false;
}

export function KeyboardDismissView({ children }: PropsWithChildren) {
  return (
    <View
      onStartShouldSetResponderCapture={dismissKeyboardWhenTouchLeavesInput}
      style={styles.root}
    >
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
});
