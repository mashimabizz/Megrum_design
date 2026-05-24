import { StyleSheet, View } from "react-native";

type MeguriAvatarAnimalType = "cat" | "fox" | "rabbit";
type MeguriAvatarHue = "butter" | "lav" | "mint" | "pink" | "sky";
type MeguriAvatarFurColor =
  | "cocoa"
  | "cream"
  | "gray"
  | "lavender"
  | "mint"
  | "pink"
  | "sky";

type MeguriAvatarFaceProps = {
  animalType: MeguriAvatarAnimalType;
  furColor?: MeguriAvatarFurColor;
  hue: MeguriAvatarHue;
  size?: number;
};

const hueColors: Record<MeguriAvatarHue, string> = {
  butter: "#f2c75c",
  lav: "#a695d8",
  mint: "#8dd8bd",
  pink: "#f3c5d4",
  sky: "#a8d4e6",
};

const furColors: Record<MeguriAvatarFurColor, string> = {
  cocoa: "#c49a7d",
  cream: "#fff0c9",
  gray: "#dce2ec",
  lavender: "#d8ccef",
  mint: "#d8f1e8",
  pink: "#f8dce8",
  sky: "#d5edf7",
};

export function MeguriAvatarFace({
  animalType,
  furColor = "cream",
  hue,
  size = 52,
}: MeguriAvatarFaceProps) {
  const accent = hueColors[hue];
  const fur = furColors[furColor];
  const isRabbit = animalType === "rabbit";
  const isFox = animalType === "fox";
  return (
    <View style={[styles.root, { height: size, width: size }]}>
      {isRabbit ? (
        <>
          <View
            style={[
              styles.rabbitEar,
              styles.rabbitEarLeft,
              {
                backgroundColor: fur,
                height: size * 0.56,
                width: size * 0.2,
              },
            ]}
          >
            <View style={[styles.rabbitEarInner, { backgroundColor: accent }]} />
          </View>
          <View
            style={[
              styles.rabbitEar,
              styles.rabbitEarRight,
              {
                backgroundColor: fur,
                height: size * 0.56,
                width: size * 0.2,
              },
            ]}
          >
            <View style={[styles.rabbitEarInner, { backgroundColor: accent }]} />
          </View>
        </>
      ) : (
        <>
          <View
            style={[
              styles.triangleEar,
              styles.triangleEarLeft,
              {
                borderBottomColor: fur,
                borderBottomWidth: isFox ? size * 0.28 : size * 0.24,
                borderLeftWidth: size * 0.15,
                borderRightWidth: size * 0.15,
              },
            ]}
          />
          <View
            style={[
              styles.triangleEar,
              styles.triangleEarRight,
              {
                borderBottomColor: fur,
                borderBottomWidth: isFox ? size * 0.28 : size * 0.24,
                borderLeftWidth: size * 0.15,
                borderRightWidth: size * 0.15,
              },
            ]}
          />
        </>
      )}
      <View
        style={[
          styles.face,
          {
            backgroundColor: fur,
            borderColor: accent,
            borderRadius: size * 0.38,
            height: size * 0.78,
            top: size * 0.16,
            width: size * 0.82,
          },
        ]}
      >
        <View style={[styles.eye, styles.eyeLeft, { backgroundColor: accent }]} />
        <View style={[styles.eye, styles.eyeRight, { backgroundColor: accent }]} />
        {isFox ? <View style={styles.foxBlaze} /> : null}
        <View style={styles.muzzle}>
          <View style={[styles.nose, { backgroundColor: isRabbit ? "#f48aa2" : "#403246" }]} />
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    alignItems: "center",
    justifyContent: "center",
    position: "relative",
  },
  rabbitEar: {
    borderColor: "rgba(255,255,255,0.72)",
    borderRadius: 999,
    borderWidth: 1,
    overflow: "hidden",
    position: "absolute",
    top: 0,
  },
  rabbitEarLeft: {
    left: "24%",
    transform: [{ rotate: "-14deg" }],
  },
  rabbitEarRight: {
    right: "24%",
    transform: [{ rotate: "14deg" }],
  },
  rabbitEarInner: {
    alignSelf: "center",
    borderRadius: 999,
    height: "62%",
    marginTop: "22%",
    opacity: 0.36,
    width: "42%",
  },
  triangleEar: {
    borderLeftColor: "transparent",
    borderRightColor: "transparent",
    borderStyle: "solid",
    height: 0,
    position: "absolute",
    top: "5%",
    width: 0,
  },
  triangleEarLeft: {
    left: "14%",
    transform: [{ rotate: "-20deg" }],
  },
  triangleEarRight: {
    right: "14%",
    transform: [{ rotate: "20deg" }],
  },
  face: {
    alignItems: "center",
    borderWidth: 1,
    justifyContent: "center",
    overflow: "hidden",
    position: "absolute",
  },
  eye: {
    borderRadius: 999,
    height: "19%",
    opacity: 0.9,
    position: "absolute",
    top: "36%",
    width: "14%",
  },
  eyeLeft: {
    left: "25%",
  },
  eyeRight: {
    right: "25%",
  },
  foxBlaze: {
    backgroundColor: "rgba(255,255,255,0.78)",
    borderBottomLeftRadius: 16,
    borderBottomRightRadius: 16,
    height: "48%",
    position: "absolute",
    top: 0,
    transform: [{ rotate: "45deg" }],
    width: "38%",
  },
  muzzle: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.62)",
    borderRadius: 999,
    bottom: "16%",
    height: "24%",
    justifyContent: "center",
    position: "absolute",
    width: "42%",
  },
  nose: {
    borderRadius: 999,
    height: 5,
    width: 7,
  },
});
