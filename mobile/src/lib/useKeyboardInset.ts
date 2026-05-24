import { useEffect, useState } from "react";
import { Dimensions, Keyboard, Platform, type KeyboardEvent } from "react-native";

function getKeyboardOverlap(event: KeyboardEvent) {
  const windowHeight = Dimensions.get("window").height;
  const keyboardTop = event.endCoordinates.screenY;
  const overlap = Math.max(0, windowHeight - keyboardTop);

  return overlap > 0 ? overlap : Math.max(0, event.endCoordinates.height);
}

export function useKeyboardInset() {
  const [keyboardInset, setKeyboardInset] = useState(0);

  useEffect(() => {
    const showEvent =
      Platform.OS === "ios" ? "keyboardWillChangeFrame" : "keyboardDidShow";
    const hideEvent = Platform.OS === "ios" ? "keyboardWillHide" : "keyboardDidHide";

    const showSubscription = Keyboard.addListener(showEvent, (event) => {
      setKeyboardInset(getKeyboardOverlap(event));
    });
    const hideSubscription = Keyboard.addListener(hideEvent, () => {
      setKeyboardInset(0);
    });

    return () => {
      showSubscription.remove();
      hideSubscription.remove();
    };
  }, []);

  return keyboardInset;
}
