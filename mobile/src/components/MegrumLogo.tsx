import { Image, StyleSheet, View } from "react-native";

const appIcon = require("../../assets/icon.png");

export function MegrumLogo({ size = 38 }: { size?: number }) {
  return (
    <View style={[styles.mark, { width: size, height: size, borderRadius: size * 0.37 }]}>
      <Image source={appIcon} resizeMode="cover" style={styles.image} />
    </View>
  );
}

const styles = StyleSheet.create({
  mark: {
    alignItems: "center",
    backgroundColor: "#fff",
    justifyContent: "center",
    overflow: "hidden",
    shadowColor: "#3a324a",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.16,
    shadowRadius: 18,
  },
  image: {
    height: "100%",
    width: "100%",
  },
});
