import { useCallback, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  Image,
  Modal,
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
  fetchGroomMapPosts,
  isUuidLike,
  markGroomPostViewed,
  type GroomRemotePost,
} from "../src/lib/groom";
import { getCurrentLocationContext, type MegrumCoordinate } from "../src/lib/locationContext";
import { megrumColors, megrumShadow } from "../src/theme/tokens";

const GROOM_ACCESS_RADIUS_M = 1000;
const FALLBACK_CENTER: MegrumCoordinate = {
  accuracy: null,
  latitude: 35.681236,
  longitude: 139.767125,
};

export default function GroomMapScreen() {
  const insets = useSafeAreaInsets();
  const { previewMode, user } = useAuth();
  const [viewerCoordinate, setViewerCoordinate] = useState<MegrumCoordinate | null>(null);
  const [posts, setPosts] = useState<GroomRemotePost[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedPost, setSelectedPost] = useState<GroomRemotePost | null>(null);

  const center = useMemo(
    () =>
      viewerCoordinate ??
      firstPostCoordinate(posts) ??
      FALLBACK_CENTER,
    [posts, viewerCoordinate],
  );

  const region = useMemo<Region>(
    () => ({
      latitude: center.latitude,
      longitude: center.longitude,
      latitudeDelta: 0.018,
      longitudeDelta: 0.018,
    }),
    [center.latitude, center.longitude],
  );

  const loadPosts = useCallback(async () => {
    setLoading(true);
    const location = previewMode ? null : await getCurrentLocationContext().catch(() => null);
    const coordinate = location?.coordinate ?? null;
    setViewerCoordinate(coordinate);
    if (!user || previewMode) {
      setPosts([]);
      setLoading(false);
      return;
    }
    const nextPosts = await fetchGroomMapPosts(user.id, coordinate).catch(() => []);
    setPosts(nextPosts);
    setLoading(false);
  }, [previewMode, user]);

  useFocusEffect(
    useCallback(() => {
      void loadPosts();
    }, [loadPosts]),
  );

  function openPost(post: GroomRemotePost) {
    if (!canOpenGroom(post)) {
      Alert.alert("1km圏外のグルームは見れません");
      return;
    }
    setSelectedPost(post);
    if (user && isUuidLike(post.id)) {
      markGroomPostViewed(user.id, post.id).catch(() => undefined);
    }
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
        {posts.map((post) =>
          post.originLat !== null && post.originLng !== null ? (
            <Marker
              key={post.id}
              coordinate={{ latitude: post.originLat, longitude: post.originLng }}
              onPress={() => openPost(post)}
            >
              <GroomMapMarker post={post} />
            </Marker>
          ) : null,
        )}
      </MapView>

      <View style={[styles.header, { paddingTop: Math.max(insets.top, 12) + 8 }]}>
        <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.roundButton}>
          <IconSymbol name="chevron-back" color={megrumColors.ink} size={20} />
        </Pressable>
        <View style={styles.headerCopy}>
          <Text style={styles.headerTitle}>グルームマップ</Text>
          <Text numberOfLines={1} style={styles.headerSubtitle}>
            1km圏内の投稿だけ開けます
          </Text>
        </View>
      </View>

      {loading ? (
        <View style={styles.loadingCard}>
          <ActivityIndicator color={megrumColors.lavender} />
          <Text style={styles.loadingText}>グルームを読み込み中…</Text>
        </View>
      ) : posts.length === 0 ? (
        <View style={styles.emptyCard}>
          <Text style={styles.emptyTitle}>表示できるグルームがありません</Text>
          <Text style={styles.emptyBody}>位置情報を許可すると、近くの投稿を地図で見られます。</Text>
        </View>
      ) : null}

      <Modal
        animationType="fade"
        transparent
        visible={!!selectedPost}
        onRequestClose={() => setSelectedPost(null)}
      >
        <View style={styles.viewerLayer}>
          <Pressable style={styles.viewerBackdrop} onPress={() => setSelectedPost(null)} />
          {selectedPost ? (
            <View style={[styles.viewerCard, { marginBottom: Math.max(insets.bottom, 12) + 16 }]}>
              <Image source={{ uri: selectedPost.imageUrl }} resizeMode="cover" style={styles.viewerImage} />
              <View style={styles.viewerCopy}>
                <Text numberOfLines={1} style={styles.viewerTitle}>
                  {selectedPost.author.displayName}
                </Text>
                {selectedPost.caption ? (
                  <Text numberOfLines={2} style={styles.viewerCaption}>
                    {selectedPost.caption}
                  </Text>
                ) : null}
                <Text style={styles.viewerMeta}>
                  {formatDistance(selectedPost.distanceMeters)} / {selectedPost.placeHint}
                </Text>
              </View>
            </View>
          ) : null}
        </View>
      </Modal>
    </View>
  );
}

function GroomMapMarker({ post }: { post: GroomRemotePost }) {
  const inRange = canOpenGroom(post);
  return (
    <View style={styles.markerWrap}>
      <View style={[styles.markerImageShell, !inRange ? styles.markerImageShellMuted : null]}>
        <Image source={{ uri: post.imageUrl }} resizeMode="cover" style={styles.markerImage} />
      </View>
      {inRange ? (
        <>
          <View style={styles.markerTail} />
          <View style={styles.markerLabel}>
            <Text numberOfLines={1} style={styles.markerLabelText}>
              {post.author.displayName}
            </Text>
          </View>
        </>
      ) : null}
    </View>
  );
}

function canOpenGroom(post: GroomRemotePost) {
  return post.mine || (post.distanceMeters !== null && post.distanceMeters <= GROOM_ACCESS_RADIUS_M);
}

function firstPostCoordinate(posts: GroomRemotePost[]) {
  const first = posts.find((post) => post.originLat !== null && post.originLng !== null);
  if (!first || first.originLat === null || first.originLng === null) return null;
  return {
    accuracy: null,
    latitude: first.originLat,
    longitude: first.originLng,
  };
}

function formatDistance(value: number | null) {
  if (value === null) return "距離未取得";
  if (value < 1000) return `${Math.max(10, Math.round(value / 10) * 10)}m`;
  return `${(value / 1000).toFixed(value < 10000 ? 1 : 0)}km`;
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
    minWidth: 76,
  },
  markerImageShell: {
    backgroundColor: "#fff",
    borderColor: megrumColors.lavender,
    borderRadius: 999,
    borderWidth: 3,
    height: 58,
    overflow: "hidden",
    width: 58,
  },
  markerImageShellMuted: {
    borderColor: "rgba(58,50,74,0.24)",
    opacity: 0.78,
  },
  markerImage: {
    height: "100%",
    width: "100%",
  },
  markerTail: {
    borderLeftColor: "transparent",
    borderLeftWidth: 8,
    borderRightColor: "transparent",
    borderRightWidth: 8,
    borderTopColor: megrumColors.lavender,
    borderTopWidth: 9,
    marginTop: -2,
  },
  markerLabel: {
    backgroundColor: megrumColors.lavender,
    borderRadius: 999,
    marginTop: -1,
    maxWidth: 96,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  markerLabelText: {
    color: "#fff",
    fontSize: 10,
    fontWeight: "900",
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
  viewerLayer: {
    flex: 1,
    justifyContent: "flex-end",
  },
  viewerBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(20,18,28,0.48)",
  },
  viewerCard: {
    backgroundColor: "#fff",
    borderRadius: 28,
    marginHorizontal: 16,
    overflow: "hidden",
    ...megrumShadow,
  },
  viewerImage: {
    aspectRatio: 0.78,
    width: "100%",
  },
  viewerCopy: {
    gap: 5,
    padding: 16,
  },
  viewerTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  viewerCaption: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 19,
  },
  viewerMeta: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
  },
});
