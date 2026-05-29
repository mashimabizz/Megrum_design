import type { ReactNode } from "react";
import { Component } from "react";
import { StyleSheet, Text, View, type StyleProp, type ViewStyle } from "react-native";
import type {
  MeguriAnimalType,
  MeguriFurColor,
  MeguriHue,
} from "../../../app/(tabs)/encounters";
import { megrumColors } from "../../theme/tokens";

export type MeguriSceneMode =
  | "summary"
  | "approaching"
  | "dialogue"
  | "exiting"
  | "done";
export type MeguriIntroPhase = "camera" | "splash" | "walking" | "ready";

export type MeguriSceneResident = {
  animalType: MeguriAnimalType;
  furColor: MeguriFurColor;
  hue: MeguriHue;
  id: string;
  name: string;
};

type MeguriSceneProps = {
  activeId: string | null;
  completedIds: string[];
  introPhase?: MeguriIntroPhase;
  mode: MeguriSceneMode;
  onUnavailable?: () => void;
  presentation?: "home" | "intro" | "plaza" | "profile";
  residents: MeguriSceneResident[];
  self: MeguriSceneResident;
  focusedId?: string | null;
  smilingId?: string | null;
  speakingId?: string | null;
  speaking?: boolean;
  wavingId?: string | null;
};

type MeguriThreeBoundaryProps = {
  children: ReactNode;
  fallback: ReactNode;
  onError?: () => void;
};

type MeguriThreeBoundaryState = {
  failed: boolean;
};

export class MeguriThreeBoundary extends Component<
  MeguriThreeBoundaryProps,
  MeguriThreeBoundaryState
> {
  state: MeguriThreeBoundaryState = { failed: false };

  static getDerivedStateFromError() {
    return { failed: true };
  }

  componentDidCatch() {
    this.props.onError?.();
  }

  render() {
    if (this.state.failed) return this.props.fallback;
    return this.props.children;
  }
}

const furColors: Record<MeguriFurColor, string> = {
  cocoa: "#b78b70",
  cream: "#f0dfbd",
  gray: "#bfc3cb",
  lavender: "#b8a9e6",
  mint: "#a7d9c7",
  pink: "#f2b8cb",
  sky: "#a9d9ed",
};

const hueColors: Record<MeguriHue, string> = {
  butter: "#efd99b",
  lav: megrumColors.lavender,
  mint: "#a8dcc9",
  pink: megrumColors.pink,
  sky: megrumColors.sky,
};

const plazaSpots = [
  { left: "16%", top: "22%" },
  { left: "42%", top: "18%" },
  { left: "68%", top: "24%" },
  { left: "82%", top: "40%" },
  { left: "24%", top: "48%" },
  { left: "52%", top: "44%" },
  { left: "74%", top: "60%" },
  { left: "16%", top: "70%" },
  { left: "44%", top: "76%" },
  { left: "68%", top: "74%" },
] as const;

export function MeguriThreeScene({
  activeId,
  completedIds,
  focusedId = null,
  mode,
  presentation = "intro",
  residents,
  self,
  smilingId = null,
  speaking = false,
  speakingId = null,
  wavingId = null,
}: MeguriSceneProps) {
  const completed = new Set(completedIds);
  const visibleResidents = residents.filter((resident) => !completed.has(resident.id));
  const activeResident =
    visibleResidents.find((resident) => resident.id === activeId) ??
    visibleResidents.find((resident) => resident.id === focusedId) ??
    visibleResidents[0] ??
    null;

  if (presentation === "profile") {
    return (
      <View style={[styles.root, styles.profileRoot]}>
        <ResidentBadge
          active
          resident={activeResident ?? residents[0] ?? self}
          size="large"
          smiling
        />
      </View>
    );
  }

  if (presentation === "plaza") {
    return (
      <View style={[styles.root, styles.plazaRoot]}>
        <View style={styles.plazaGround} />
        <ResidentBadge
          active={!focusedId}
          resident={self}
          size="medium"
          style={styles.selfBadge}
        />
        {residents.slice(0, plazaSpots.length).map((resident, index) => {
          const focused = resident.id === focusedId;
          const spot = plazaSpots[index % plazaSpots.length];
          return (
            <ResidentBadge
              key={resident.id}
              active={focused}
              resident={resident}
              size={focused ? "large" : "medium"}
              smiling={resident.id === smilingId}
              style={[styles.plazaResident, { left: spot.left, top: spot.top }]}
              waving={resident.id === wavingId}
            />
          );
        })}
      </View>
    );
  }

  return (
    <View style={[styles.root, styles.summaryRoot]}>
      <View style={styles.sky} />
      <View style={styles.ground} />
      <View style={styles.selfRow}>
        <ResidentBadge resident={self} size="small" style={styles.summarySelf} />
      </View>
      <View style={styles.residentRow}>
        {visibleResidents.slice(0, 6).map((resident) => {
          const active = resident.id === activeResident?.id;
          return (
            <ResidentBadge
              key={resident.id}
              active={active}
              dimmed={mode === "done" && !active}
              resident={resident}
              size={active ? "large" : "medium"}
              smiling={resident.id === smilingId || (speaking && resident.id === speakingId)}
              waving={resident.id === wavingId}
            />
          );
        })}
      </View>
    </View>
  );
}

function ResidentBadge({
  active = false,
  dimmed = false,
  resident,
  size,
  smiling = false,
  style,
  waving = false,
}: {
  active?: boolean;
  dimmed?: boolean;
  resident: MeguriSceneResident;
  size: "small" | "medium" | "large";
  smiling?: boolean;
  style?: StyleProp<ViewStyle>;
  waving?: boolean;
}) {
  const sizePx = size === "large" ? 84 : size === "medium" ? 62 : 44;
  const accent = hueColors[resident.hue];
  const fur = furColors[resident.furColor];
  return (
    <View
      style={[
        styles.badgeWrap,
        active ? styles.badgeWrapActive : null,
        dimmed ? styles.badgeWrapDimmed : null,
        style,
      ]}
    >
      <View style={[styles.badgeShadow, { width: sizePx * 0.78 }]} />
      <View
        style={[
          styles.badge,
          {
            backgroundColor: fur,
            borderColor: accent,
            borderRadius: Math.round(sizePx * 0.28),
            height: sizePx,
            width: sizePx,
          },
        ]}
      >
        <View style={[styles.badgePattern, { backgroundColor: accent }]} />
        <Text
          allowFontScaling={false}
          style={[styles.badgeInitial, { fontSize: Math.round(sizePx * 0.38) }]}
        >
          {resident.name.slice(0, 1)}
        </Text>
        {smiling ? <View style={[styles.moodDot, { backgroundColor: accent }]} /> : null}
        {waving ? <Text style={styles.waveMark}>+</Text> : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    overflow: "hidden",
  },
  summaryRoot: {
    backgroundColor: "#c9f1ff",
    justifyContent: "flex-end",
  },
  sky: {
    backgroundColor: "rgba(255,255,255,0.58)",
    borderRadius: 999,
    height: 22,
    left: 28,
    position: "absolute",
    top: 26,
    width: 94,
  },
  ground: {
    backgroundColor: "#bfecc2",
    borderTopLeftRadius: 140,
    borderTopRightRadius: 140,
    bottom: -42,
    height: 124,
    left: -24,
    position: "absolute",
    right: -24,
  },
  selfRow: {
    alignItems: "center",
    left: 16,
    position: "absolute",
    top: 22,
  },
  summarySelf: {
    opacity: 0.82,
  },
  residentRow: {
    alignItems: "flex-end",
    flexDirection: "row",
    gap: 10,
    justifyContent: "center",
    paddingBottom: 22,
    paddingHorizontal: 16,
  },
  profileRoot: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.28)",
    justifyContent: "center",
  },
  plazaRoot: {
    backgroundColor: "#bff0c4",
  },
  plazaGround: {
    backgroundColor: "rgba(255,255,255,0.22)",
    borderColor: "rgba(81,181,112,0.28)",
    borderRadius: 999,
    borderWidth: 2,
    height: "62%",
    left: "-8%",
    position: "absolute",
    top: "22%",
    width: "116%",
  },
  selfBadge: {
    left: "8%",
    position: "absolute",
    top: "54%",
  },
  plazaResident: {
    marginLeft: -34,
    marginTop: -34,
    position: "absolute",
  },
  badgeWrap: {
    alignItems: "center",
    justifyContent: "flex-end",
  },
  badgeWrapActive: {
    transform: [{ translateY: -7 }, { scale: 1.05 }],
  },
  badgeWrapDimmed: {
    opacity: 0.52,
  },
  badgeShadow: {
    backgroundColor: "rgba(58,50,74,0.16)",
    borderRadius: 999,
    bottom: -4,
    height: 7,
    position: "absolute",
  },
  badge: {
    alignItems: "center",
    borderWidth: 2,
    justifyContent: "center",
    overflow: "hidden",
  },
  badgePattern: {
    height: "100%",
    opacity: 0.16,
    position: "absolute",
    width: "100%",
  },
  badgeInitial: {
    color: "#fff",
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.28)",
    textShadowOffset: { height: 1, width: 0 },
    textShadowRadius: 2,
  },
  moodDot: {
    borderColor: "#fff",
    borderRadius: 999,
    borderWidth: 2,
    bottom: 6,
    height: 13,
    position: "absolute",
    right: 6,
    width: 13,
  },
  waveMark: {
    color: "#fff",
    fontSize: 14,
    fontWeight: "900",
    position: "absolute",
    right: 7,
    top: 4,
  },
});
