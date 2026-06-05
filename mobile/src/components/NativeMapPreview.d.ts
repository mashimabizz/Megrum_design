import type { ComponentType } from "react";
import type { ViewStyle } from "react-native";

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

export type NativeMapPreviewProps = {
  center: MapCoordinate;
  markers?: NativeMapMarker[];
  interactive?: boolean;
  height?: number;
  style?: ViewStyle;
  onPress?: (coordinate: MapCoordinate) => void;
};

export declare const NativeMapPreview: ComponentType<NativeMapPreviewProps>;

export default NativeMapPreview;
