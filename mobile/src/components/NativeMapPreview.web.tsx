import { Pressable, StyleSheet, Text, View, type ViewStyle } from "react-native";
import { megrumColors } from "../theme/tokens";

export type MapCoordinate = {
  latitude: number;
  longitude: number;
};

export type NativeMapMarker = {
  id: string;
  coordinate: MapCoordinate;
  title?: string;
  label?: string;
};

type NativeMapPreviewProps = {
  center: MapCoordinate;
  markers?: NativeMapMarker[];
  interactive?: boolean;
  height?: number;
  style?: ViewStyle;
  onPress?: (coordinate: MapCoordinate) => void;
};

export function NativeMapPreview({
  center,
  markers = [],
  interactive = false,
  height = 204,
  style,
  onPress,
}: NativeMapPreviewProps) {
  return (
    <Pressable
      disabled={!interactive || !onPress}
      onPress={() => onPress?.(center)}
      style={[styles.webFallback, { height }, style]}
    >
      <View style={styles.webGrid} />
      <View style={styles.webLabelRow}>
        <Text style={styles.webCaption}>地図プレビュー</Text>
        <Text style={styles.webCoords}>
          {center.latitude.toFixed(4)}, {center.longitude.toFixed(4)}
        </Text>
      </View>
      {markers.map((marker, index) => (
        <View
          key={marker.id}
          style={[
            styles.webMarker,
            {
              left: `${24 + ((index * 19) % 52)}%`,
              top: `${32 + ((index * 13) % 34)}%`,
            },
          ]}
        >
          <Text style={styles.pinText}>{marker.label ?? String(index + 1)}</Text>
        </View>
      ))}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  webFallback: {
    backgroundColor: "#eef5fb",
    borderColor: "rgba(166,149,216,0.18)",
    borderRadius: 20,
    borderWidth: 1,
    overflow: "hidden",
    position: "relative",
    width: "100%",
  },
  webGrid: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#eef5fb",
    opacity: 0.9,
  },
  webLabelRow: {
    alignItems: "flex-start",
    left: 14,
    position: "absolute",
    top: 12,
  },
  webCaption: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  webCoords: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "700",
    marginTop: 2,
  },
  webMarker: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.surface,
    borderRadius: 999,
    borderWidth: 3,
    height: 34,
    justifyContent: "center",
    position: "absolute",
    width: 34,
  },
  pinText: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
  },
});
