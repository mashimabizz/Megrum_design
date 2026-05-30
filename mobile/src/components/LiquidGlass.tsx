import { BlurView, type BlurTint } from "expo-blur";
import type {
  GlassContainerProps,
  GlassViewProps,
} from "expo-glass-effect";
import type { ComponentType, PropsWithChildren } from "react";
import {
  Platform,
  View,
  type StyleProp,
  type ViewProps,
  type ViewStyle,
} from "react-native";

type GlassEffectModule = {
  GlassContainer: ComponentType<GlassContainerProps>;
  GlassView: ComponentType<GlassViewProps>;
  isGlassEffectAPIAvailable?: () => boolean;
  isLiquidGlassAvailable?: () => boolean;
};

type LiquidGlassKit = {
  GlassContainer: ComponentType<GlassContainerProps>;
  GlassView: ComponentType<GlassViewProps>;
};

type LiquidGlassSurfaceProps = PropsWithChildren<{
  blurIntensity?: number;
  blurTint?: BlurTint;
  colorScheme?: GlassViewProps["colorScheme"];
  fallbackStyle?: StyleProp<ViewStyle>;
  glassEffectStyle?: GlassViewProps["glassEffectStyle"];
  isInteractive?: boolean;
  pointerEvents?: ViewProps["pointerEvents"];
  style?: StyleProp<ViewStyle>;
  tintColor?: string;
}>;

let cachedGlassKit: LiquidGlassKit | null | undefined;

export function getLiquidGlassKit() {
  if (Platform.OS !== "ios") return null;
  if (cachedGlassKit !== undefined) return cachedGlassKit;
  try {
    const glass = require("expo-glass-effect") as GlassEffectModule;
    const apiAvailable = glass.isGlassEffectAPIAvailable?.() ?? false;
    const liquidAvailable = glass.isLiquidGlassAvailable?.() ?? false;
    cachedGlassKit =
      apiAvailable && liquidAvailable
        ? {
            GlassContainer: glass.GlassContainer,
            GlassView: glass.GlassView,
          }
        : null;
  } catch {
    cachedGlassKit = null;
  }
  return cachedGlassKit;
}

export function isNativeLiquidGlassAvailable() {
  return !!getLiquidGlassKit();
}

export function LiquidGlassSurface({
  blurIntensity = 54,
  blurTint = "systemThinMaterialLight",
  children,
  colorScheme = "light",
  fallbackStyle,
  glassEffectStyle = {
    style: "regular",
    animate: true,
    animationDuration: 0.2,
  },
  isInteractive = false,
  pointerEvents,
  style,
  tintColor = "rgba(255,255,255,0.24)",
}: LiquidGlassSurfaceProps) {
  const GlassView = getLiquidGlassKit()?.GlassView;
  if (GlassView) {
    return (
      <GlassView
        colorScheme={colorScheme}
        glassEffectStyle={glassEffectStyle}
        isInteractive={isInteractive}
        pointerEvents={pointerEvents}
        style={style}
        tintColor={tintColor}
      >
        {children}
      </GlassView>
    );
  }
  if (Platform.OS === "ios") {
    return (
      <BlurView
        intensity={blurIntensity}
        pointerEvents={pointerEvents}
        style={[style, fallbackStyle]}
        tint={blurTint}
      >
        {children}
      </BlurView>
    );
  }
  return (
    <View pointerEvents={pointerEvents} style={[style, fallbackStyle]}>
      {children}
    </View>
  );
}
