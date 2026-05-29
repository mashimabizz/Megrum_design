import { StyleSheet, Text, View, useWindowDimensions } from "react-native";
import { Screen } from "../src/components/Screen";
import { RouteHeader } from "../src/components/RouteHeader";
import {
  MEGURI_MAP_HEIGHT,
  MEGURI_MAP_REGION_COLORS,
  MEGURI_MAP_TILE_H,
  MEGURI_MAP_TILE_W,
  MEGURI_MAP_TILES,
  MEGURI_MAP_WIDTH,
  normalizePrefectureName,
} from "../src/data/japanPrefectures";
import { megrumColors, megrumShadow } from "../src/theme/tokens";
import { USERS, hueTint, type MeguriHue } from "./(tabs)/encounters";

const LOCKED_PREF_COLOR = "#dedbe6";
const LOCKED_PREF_TEXT = "rgba(58,50,74,0.42)";

type AreaStat = {
  count: number;
  hue: MeguriHue;
  name: string;
};

const AREA_STATS = buildAreaStats();
const UNLOCKED_AREAS = new Set(AREA_STATS.map((area) => area.name));
const TOP_AREAS = [...AREA_STATS].sort((a, b) => b.count - a.count).slice(0, 5);

export default function MeguriMapScreen() {
  const { width: viewportWidth } = useWindowDimensions();
  const mapScale = Math.min(1, (viewportWidth - 52) / MEGURI_MAP_WIDTH);
  const mapDisplayWidth = MEGURI_MAP_WIDTH * mapScale;
  const mapDisplayHeight = MEGURI_MAP_HEIGHT * mapScale;

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader title="めぐりマップ" />

      <View style={styles.summary}>
        <Text style={styles.kicker}>MAP</Text>
        <Text style={styles.title}>{UNLOCKED_AREAS.size} / 47 都道府県でめぐり</Text>
      </View>

      <View style={[styles.mapCard, { minHeight: mapDisplayHeight + 28 }]}>
        <View
          style={[
            styles.mapCanvas,
            { height: mapDisplayHeight, width: mapDisplayWidth },
          ]}
        >
          <View
            style={[
              styles.guideLine,
              styles.guideLineTopLeft,
              scaleBox(styles.guideLineTopLeft, mapScale),
            ]}
          />
          <View
            style={[
              styles.guideLine,
              styles.guideLineOkinawaA,
              scaleBox(styles.guideLineOkinawaA, mapScale),
            ]}
          />
          <View
            style={[
              styles.guideLine,
              styles.guideLineOkinawaB,
              scaleBox(styles.guideLineOkinawaB, mapScale),
            ]}
          />
          <View
            style={[
              styles.guideLine,
              styles.guideLineBottom,
              scaleBox(styles.guideLineBottom, mapScale),
            ]}
          />
          {MEGURI_MAP_TILES.map((pref) => {
            const stat = AREA_STATS.find((area) => area.name === pref.name);
            const unlocked = UNLOCKED_AREAS.has(pref.name);
            const color = unlocked ? MEGURI_MAP_REGION_COLORS[pref.region] : LOCKED_PREF_COLOR;
            const width = pref.w ?? MEGURI_MAP_TILE_W;
            const height = pref.h ?? MEGURI_MAP_TILE_H;
            const labelFontSize = width >= 60 ? 10.8 : height >= 60 ? 10.4 : 9.8;
            return (
              <View
                key={pref.name}
                style={[
                  styles.prefBlock,
                  unlocked ? styles.prefBlockUnlocked : null,
                  !unlocked ? styles.prefBlockLocked : null,
                  {
                    backgroundColor: color,
                    height: height * mapScale,
                    left: pref.x * mapScale,
                    top: pref.y * mapScale,
                    width: width * mapScale,
                  },
                ]}
              >
                <Text
                  adjustsFontSizeToFit
                  minimumFontScale={0.52}
                  numberOfLines={1}
                  style={[
                    styles.prefName,
                    {
                      color: unlocked ? "#fff" : LOCKED_PREF_TEXT,
                      fontSize: labelFontSize * mapScale,
                    },
                  ]}
                >
                  {pref.name}
                </Text>
                {stat ? (
                  <View
                    style={[
                      styles.unlockDot,
                      {
                        height: 13 * mapScale,
                        right: 2 * mapScale,
                        top: 2 * mapScale,
                        width: 13 * mapScale,
                      },
                    ]}
                  >
                    <Text style={[styles.unlockDotText, { fontSize: 7 * mapScale }]}>
                      {stat.count}
                    </Text>
                  </View>
                ) : null}
              </View>
            );
          })}
        </View>
      </View>

      <View style={styles.areaList}>
        {TOP_AREAS.map((area, index) => (
          <View key={area.name} style={styles.areaRow}>
            <Text style={styles.areaRank}>#{index + 1}</Text>
            <View style={styles.areaCopy}>
              <Text style={styles.areaName}>{area.name}</Text>
              <Text style={styles.areaMeta}>{area.count}回めぐりあいました</Text>
            </View>
            <View style={[styles.areaBadge, { backgroundColor: hueTint(area.hue, 0.36) }]}>
              <Text style={styles.areaBadgeText}>{area.count}</Text>
            </View>
          </View>
        ))}
      </View>
    </Screen>
  );
}

function scaleBox(
  box: { height?: number; left?: number; top?: number; width?: number },
  scale: number,
) {
  return {
    height: typeof box.height === "number" ? Math.max(1, box.height * scale) : undefined,
    left: typeof box.left === "number" ? box.left * scale : undefined,
    top: typeof box.top === "number" ? box.top * scale : undefined,
    width: typeof box.width === "number" ? box.width * scale : undefined,
  };
}

function buildAreaStats(): AreaStat[] {
  const stats = new Map<string, AreaStat>();
  for (const user of USERS) {
    const name = normalizePrefectureName(user.area);
    const current = stats.get(name);
    if (current) {
      current.count += user.count;
      continue;
    }
    stats.set(name, {
      count: user.count,
      hue: user.hue,
      name,
    });
  }
  return [...stats.values()];
}

const styles = StyleSheet.create({
  screen: { gap: 16 },
  summary: {
    backgroundColor: hueTint("sky", 0.2),
    borderRadius: 28,
    padding: 20,
  },
  kicker: {
    color: megrumColors.sky,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.6,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 29,
    fontWeight: "900",
    lineHeight: 35,
    marginTop: 8,
  },
  mapCard: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 30,
    minHeight: MEGURI_MAP_HEIGHT + 28,
    overflow: "hidden",
    paddingVertical: 14,
    position: "relative",
    ...megrumShadow,
  },
  mapCanvas: {
    backgroundColor: "#fff",
    height: MEGURI_MAP_HEIGHT,
    position: "relative",
    width: MEGURI_MAP_WIDTH,
  },
  guideLine: {
    backgroundColor: "rgba(58,50,74,0.16)",
    position: "absolute",
  },
  guideLineTopLeft: {
    height: 1,
    left: 58,
    top: 40,
    transform: [{ rotate: "48deg" }],
    width: 92,
  },
  guideLineOkinawaA: {
    height: 1.5,
    left: 0,
    top: 268,
    width: 46,
  },
  guideLineOkinawaB: {
    height: 1.5,
    left: 32,
    top: 248,
    transform: [{ rotate: "-49deg" }],
    width: 72,
  },
  guideLineBottom: {
    height: 1,
    left: 56,
    top: 520,
    transform: [{ rotate: "-48deg" }],
    width: 80,
  },
  prefBlock: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.92)",
    borderRadius: 5,
    borderWidth: 1.2,
    justifyContent: "center",
    position: "absolute",
    shadowColor: "#3a324a",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.07,
    shadowRadius: 5,
  },
  prefBlockUnlocked: {
    borderColor: "#fff",
    shadowOpacity: 0.14,
    shadowRadius: 8,
  },
  prefBlockLocked: {
    borderColor: "rgba(255,255,255,0.82)",
    shadowOpacity: 0.02,
    shadowRadius: 3,
  },
  prefName: {
    color: "#fff",
    fontSize: 9.8,
    fontWeight: "900",
    textAlign: "center",
  },
  unlockDot: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.94)",
    borderRadius: 999,
    height: 13,
    justifyContent: "center",
    position: "absolute",
    right: 2,
    top: 2,
    width: 13,
  },
  unlockDotText: {
    color: megrumColors.ink,
    fontSize: 7,
    fontWeight: "900",
  },
  areaList: {
    backgroundColor: "rgba(255,255,255,0.86)",
    borderRadius: 26,
    gap: 10,
    padding: 14,
  },
  areaRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
    padding: 10,
  },
  areaRank: {
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
    width: 32,
  },
  areaCopy: { flex: 1 },
  areaName: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  areaMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  areaBadge: {
    alignItems: "center",
    borderRadius: 15,
    height: 34,
    justifyContent: "center",
    width: 44,
  },
  areaBadgeText: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
});
