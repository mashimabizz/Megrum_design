import MapView, { Marker, type Region } from "react-native-maps";
import { StyleSheet, Text, View, type ViewStyle } from "react-native";
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
  const region: Region = {
    latitude: center.latitude,
    longitude: center.longitude,
    latitudeDelta: 0.012,
    longitudeDelta: 0.012,
  };

  return (
    <MapView
      initialRegion={region}
      region={interactive ? undefined : region}
      scrollEnabled={interactive}
      zoomEnabled={interactive}
      rotateEnabled={interactive}
      pitchEnabled={interactive}
      showsCompass={interactive}
      showsUserLocation={false}
      mapType="standard"
      style={[styles.map, { height }, style]}
      onPress={(event) => onPress?.(event.nativeEvent.coordinate)}
    >
      {markers.map((marker, index) => (
        <Marker
          key={marker.id}
          coordinate={marker.coordinate}
          title={marker.title}
          tracksViewChanges={false}
        >
          <View style={styles.pin}>
            <Text style={styles.pinText}>{marker.label ?? String(index + 1)}</Text>
          </View>
        </Marker>
      ))}
    </MapView>
  );
}

const styles = StyleSheet.create({
  map: {
    width: "100%",
  },
  pin: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.surface,
    borderRadius: 999,
    borderWidth: 3,
    height: 34,
    justifyContent: "center",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.22,
    shadowRadius: 10,
    width: 34,
  },
  pinText: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
  },
});
