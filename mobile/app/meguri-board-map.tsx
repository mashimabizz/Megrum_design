import { useCallback, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { router, useFocusEffect } from "expo-router";
import MapView, { Marker, type Region } from "react-native-maps";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useAuth } from "../src/auth/AuthProvider";
import { IconSymbol } from "../src/components/IconSymbol";
import {
  loadMeguriBoardMapThreads,
  meguriBoardAudienceLabel,
  type MeguriBoardThread,
  type MeguriBoardViewMode,
  type MeguriBoardViewerContext,
} from "../src/lib/meguriBoard";
import { getCurrentLocationContext, type MegrumCoordinate } from "../src/lib/locationContext";
import {
  displayMeguriBoardPrefecture,
  loadMeguriBoardDefaultPrefecture,
  normalizeMeguriBoardPrefecture,
} from "../src/lib/meguriBoardPreferences";
import { DEFAULT_MEGURI_PROFILE } from "../src/lib/meguriSettings";
import { megrumColors, megrumShadow } from "../src/theme/tokens";

const BOARD_ACCESS_RADIUS_M = 3000;
const FALLBACK_CENTER: MegrumCoordinate = {
  accuracy: null,
  latitude: 35.681236,
  longitude: 139.767125,
};

export default function MeguriBoardMapScreen() {
  const insets = useSafeAreaInsets();
  const { previewMode, profile, user } = useAuth();
  const [viewerContext, setViewerContext] = useState<MeguriBoardViewerContext>(() =>
    buildViewerContext({
      fallbackArea: profile?.primaryArea || DEFAULT_MEGURI_PROFILE.baseArea,
      viewerId: user?.id ?? "preview-me",
    }),
  );
  const [threads, setThreads] = useState<MeguriBoardThread[]>([]);
  const [loading, setLoading] = useState(true);

  const center = useMemo(
    () =>
      viewerContext.coordinate ??
      firstThreadCoordinate(threads) ??
      FALLBACK_CENTER,
    [threads, viewerContext.coordinate],
  );
  const region = useMemo<Region>(
    () => ({
      latitude: center.latitude,
      longitude: center.longitude,
      latitudeDelta: 0.042,
      longitudeDelta: 0.042,
    }),
    [center.latitude, center.longitude],
  );

  const loadThreads = useCallback(async () => {
    setLoading(true);
    const location = previewMode ? null : await getCurrentLocationContext().catch(() => null);
    const boardPrefecture = await loadMeguriBoardDefaultPrefecture(
      profile?.primaryArea || DEFAULT_MEGURI_PROFILE.baseArea,
    );
    const nextViewer = buildViewerContext({
      coordinate: location?.coordinate ?? null,
      fallbackArea: profile?.primaryArea || DEFAULT_MEGURI_PROFILE.baseArea,
      prefecture: boardPrefecture,
      spotLabel: location?.label ?? null,
      viewerId: user?.id ?? "preview-me",
    });
    setViewerContext(nextViewer);
    if (!user && !previewMode) {
      setThreads([]);
      setLoading(false);
      return;
    }
    const nextThreads = await loadMeguriBoardMapThreads(nextViewer, { previewMode }).catch(() => []);
    setThreads(nextThreads);
    setLoading(false);
  }, [previewMode, profile?.primaryArea, user]);

  useFocusEffect(
    useCallback(() => {
      void loadThreads();
    }, [loadThreads]),
  );

  function openThread(thread: MeguriBoardThread) {
    if (!canOpenThread(thread)) {
      Alert.alert("3km圏外の掲示板は見れません");
      return;
    }
    const viewMode = viewModeForThread(thread);
    router.push({
      pathname: "/meguri-board-thread",
      params: {
        id: thread.id,
        prefecture: viewerContext.prefecture || "",
        spotKey: viewerContext.spotKey || "",
        spotLabel: viewerContext.spotLabel || "",
        viewerLat: viewerContext.coordinate ? String(viewerContext.coordinate.latitude) : "",
        viewerLng: viewerContext.coordinate ? String(viewerContext.coordinate.longitude) : "",
        viewMode,
      },
    });
  }

  return (
    <View style={styles.root}>
      <MapView
        initialRegion={region}
        mapType="standard"
        showsCompass
        showsUserLocation
        style={StyleSheet.absoluteFillObject}
      >
        {threads.map((thread) =>
          thread.originLat !== null && thread.originLng !== null ? (
            <Marker
              key={thread.id}
              coordinate={{ latitude: thread.originLat, longitude: thread.originLng }}
              onPress={() => openThread(thread)}
            >
              <BoardMapMarker thread={thread} />
            </Marker>
          ) : null,
        )}
      </MapView>

      <View style={[styles.header, { paddingTop: Math.max(insets.top, 12) + 8 }]}>
        <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.roundButton}>
          <IconSymbol name="chevron-back" color={megrumColors.ink} size={20} />
        </Pressable>
        <View style={styles.headerCopy}>
          <Text style={styles.headerTitle}>掲示板マップ</Text>
          <Text numberOfLines={1} style={styles.headerSubtitle}>
            3km圏内または{displayMeguriBoardPrefecture(viewerContext.prefecture)}のスレッド
          </Text>
        </View>
      </View>

      {loading ? (
        <View style={styles.loadingCard}>
          <ActivityIndicator color={megrumColors.lavender} />
          <Text style={styles.loadingText}>掲示板を読み込み中…</Text>
        </View>
      ) : threads.length === 0 ? (
        <View style={styles.emptyCard}>
          <Text style={styles.emptyTitle}>地図に表示できるスレッドがありません</Text>
          <Text style={styles.emptyBody}>位置情報を許可すると、近くのスレッドを探しやすくなります。</Text>
        </View>
      ) : null}
    </View>
  );
}

function BoardMapMarker({ thread }: { thread: MeguriBoardThread }) {
  const accessible = canOpenThread(thread);
  return (
    <View style={styles.markerWrap}>
      <View style={[styles.markerBubble, !accessible ? styles.markerBubbleMuted : null]}>
        <Text numberOfLines={1} style={styles.markerTitle}>
          {thread.title}
        </Text>
        <Text numberOfLines={1} style={styles.markerMeta}>
          {meguriBoardAudienceLabel(thread.audienceScope)}
        </Text>
      </View>
      <View style={[styles.markerTail, !accessible ? styles.markerTailMuted : null]} />
      <View style={[styles.markerDot, !accessible ? styles.markerDotMuted : null]}>
        <IconSymbol name="document-text-outline" color="#fff" size={17} />
      </View>
    </View>
  );
}

function canOpenThread(thread: MeguriBoardThread) {
  if (thread.mine || thread.audienceScope === "same_prefecture" || thread.audienceScope === "global") {
    return true;
  }
  return thread.distanceMeters !== null && thread.distanceMeters <= BOARD_ACCESS_RADIUS_M;
}

function viewModeForThread(thread: MeguriBoardThread): MeguriBoardViewMode {
  if (thread.audienceScope === "same_prefecture" || thread.audienceScope === "global") {
    return "same_prefecture";
  }
  return "nearby_3km";
}

function buildViewerContext(input: {
  coordinate?: MegrumCoordinate | null;
  fallbackArea: string | null;
  prefecture?: string | null;
  spotLabel?: string | null;
  viewerId?: string | null;
}): MeguriBoardViewerContext {
  const prefecture =
    normalizeMeguriBoardPrefecture(input.prefecture) ||
    normalizeMeguriBoardPrefecture(input.fallbackArea) ||
    normalizeMeguriBoardPrefecture(DEFAULT_MEGURI_PROFILE.baseArea) ||
    "東京";
  const spotLabel = input.spotLabel || `${displayMeguriBoardPrefecture(prefecture)}のめぐりスポット`;
  return {
    coordinate: input.coordinate ?? null,
    prefecture,
    spotKey: `${prefecture.replace(/\s+/g, "-")}-meguri-board`,
    spotLabel,
    viewerId: input.viewerId,
  };
}

function firstThreadCoordinate(threads: MeguriBoardThread[]) {
  const first = threads.find((thread) => thread.originLat !== null && thread.originLng !== null);
  if (!first || first.originLat === null || first.originLng === null) return null;
  return {
    accuracy: null,
    latitude: first.originLat,
    longitude: first.originLng,
  };
}

const styles = StyleSheet.create({
  root: {
    backgroundColor: megrumColors.background,
    flex: 1,
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    gap: 11,
    left: 16,
    position: "absolute",
    right: 16,
    top: 0,
    zIndex: 5,
  },
  roundButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.92)",
    borderRadius: 18,
    height: 42,
    justifyContent: "center",
    width: 42,
    ...megrumShadow,
  },
  headerCopy: {
    backgroundColor: "rgba(255,255,255,0.92)",
    borderRadius: 18,
    flex: 1,
    gap: 2,
    paddingHorizontal: 14,
    paddingVertical: 9,
    ...megrumShadow,
  },
  headerTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  headerSubtitle: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
  markerWrap: {
    alignItems: "center",
    maxWidth: 156,
  },
  markerBubble: {
    backgroundColor: megrumColors.lavender,
    borderColor: "#fff",
    borderRadius: 18,
    borderWidth: 2,
    minWidth: 118,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  markerBubbleMuted: {
    backgroundColor: "rgba(58,50,74,0.62)",
  },
  markerTitle: {
    color: "#fff",
    fontSize: 11,
    fontWeight: "900",
  },
  markerMeta: {
    color: "rgba(255,255,255,0.82)",
    fontSize: 9.5,
    fontWeight: "800",
    marginTop: 2,
  },
  markerTail: {
    borderLeftColor: "transparent",
    borderLeftWidth: 8,
    borderRightColor: "transparent",
    borderRightWidth: 8,
    borderTopColor: megrumColors.lavender,
    borderTopWidth: 9,
    marginTop: -1,
  },
  markerTailMuted: {
    borderTopColor: "rgba(58,50,74,0.62)",
  },
  markerDot: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderColor: "#fff",
    borderRadius: 999,
    borderWidth: 2,
    height: 36,
    justifyContent: "center",
    marginTop: -2,
    width: 36,
  },
  markerDotMuted: {
    backgroundColor: "rgba(58,50,74,0.62)",
  },
  loadingCard: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.94)",
    borderRadius: 18,
    flexDirection: "row",
    gap: 10,
    left: 16,
    paddingHorizontal: 14,
    paddingVertical: 12,
    position: "absolute",
    right: 16,
    top: 118,
    ...megrumShadow,
  },
  loadingText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  emptyCard: {
    backgroundColor: "rgba(255,255,255,0.94)",
    borderRadius: 20,
    left: 16,
    padding: 16,
    position: "absolute",
    right: 16,
    top: 118,
    ...megrumShadow,
  },
  emptyTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  emptyBody: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 18,
    marginTop: 5,
  },
});
