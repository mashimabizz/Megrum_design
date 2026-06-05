import { router } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { megrumColors, megrumRadii } from "../theme/tokens";

export default function GroomMapScreen() {
  return (
    <View style={styles.root}>
      <View style={styles.card}>
        <Text style={styles.badge}>Web preview</Text>
        <Text style={styles.title}>グルームマップ</Text>
        <Text style={styles.copy}>
          この画面はネイティブ地図依存があるため、Webでは簡易表示にしています。
        </Text>
        <Pressable onPress={() => router.back()} style={styles.button}>
          <Text style={styles.buttonText}>戻る</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    alignItems: "center",
    backgroundColor: "#fbf9fc",
    flex: 1,
    justifyContent: "center",
    padding: 24,
  },
  card: {
    backgroundColor: "#fff",
    borderColor: "rgba(166,149,216,0.16)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    maxWidth: 420,
    padding: 24,
    width: "100%",
  },
  badge: {
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
  },
  title: {
    color: megrumColors.ink,
    fontSize: 24,
    fontWeight: "900",
    marginTop: 8,
  },
  copy: {
    color: megrumColors.mutedInk,
    fontSize: 14,
    fontWeight: "700",
    lineHeight: 22,
    marginTop: 10,
  },
  button: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 14,
    marginTop: 18,
    paddingVertical: 12,
  },
  buttonText: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "900",
  },
});
