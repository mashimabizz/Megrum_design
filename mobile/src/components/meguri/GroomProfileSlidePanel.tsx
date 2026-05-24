import { useEffect, useMemo, useRef, useState } from "react";
import {
  Animated,
  Easing,
  PanResponder,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { IconSymbol } from "../IconSymbol";
import {
  MeguriThreeBoundary,
  MeguriThreeScene,
  type MeguriSceneResident,
} from "./MeguriThreeScene";
import { ihubColors, ihubShadow } from "../../theme/tokens";

type GroomProfileHue = "lav" | "sky" | "pink" | "mint" | "butter";
type GroomProfileAnimalType = "cat" | "fox" | "rabbit";
type GroomProfileFurColor =
  | "lavender"
  | "sky"
  | "pink"
  | "cream"
  | "mint"
  | "cocoa"
  | "gray";

export type GroomProfileUser = {
  id: string;
  name: string;
  animalType: GroomProfileAnimalType;
  furColor: GroomProfileFurColor;
  hue: GroomProfileHue;
  oshi: string;
  group: string;
  area: string;
  style: string;
  recent: string;
  hitokoto: string;
  count: number;
  since: string;
};

const PROFILE_SELF: MeguriSceneResident = {
  animalType: "rabbit",
  furColor: "lavender",
  hue: "lav",
  id: "me",
  name: "あなた",
};

const HUE_RGB: Record<GroomProfileHue, [number, number, number]> = {
  butter: [242, 199, 92],
  lav: [166, 149, 216],
  mint: [141, 216, 189],
  pink: [243, 197, 212],
  sky: [168, 212, 230],
};

export function GroomProfileSlidePanel({
  onClose,
  onReply,
  user,
}: {
  onClose: () => void;
  onReply?: () => void;
  user: GroomProfileUser | null;
}) {
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const slideX = useRef(new Animated.Value(width)).current;
  const [threeFailed, setThreeFailed] = useState(false);
  const resident = useMemo(() => (user ? toSceneResident(user) : null), [user]);

  function closePanel(afterClose?: () => void) {
    Animated.timing(slideX, {
      toValue: width,
      duration: 220,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start(({ finished }) => {
      if (!finished) return;
      onClose();
      afterClose?.();
    });
  }

  const panResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: (event, gesture) => {
          const fromLeftEdge = event.nativeEvent.pageX <= 36;
          const horizontal = gesture.dx > 8 && gesture.dx > Math.abs(gesture.dy) * 1.25;
          return fromLeftEdge && horizontal;
        },
        onPanResponderMove: (_, gesture) => {
          slideX.setValue(Math.max(0, Math.min(width, gesture.dx)));
        },
        onPanResponderRelease: (_, gesture) => {
          if (gesture.dx > 86 || gesture.vx > 0.75) {
            closePanel();
            return;
          }
          Animated.spring(slideX, {
            toValue: 0,
            damping: 22,
            stiffness: 230,
            useNativeDriver: true,
          }).start();
        },
        onPanResponderTerminate: () => {
          Animated.spring(slideX, {
            toValue: 0,
            damping: 22,
            stiffness: 230,
            useNativeDriver: true,
          }).start();
        },
      }),
    [slideX, width],
  );

  useEffect(() => {
    if (!user) return;
    setThreeFailed(false);
    slideX.setValue(width);
    Animated.timing(slideX, {
      toValue: 0,
      duration: 260,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start();
  }, [slideX, user?.id, width]);

  if (!user || !resident) return null;

  return (
    <Animated.View
      {...panResponder.panHandlers}
      style={[styles.panel, { transform: [{ translateX: slideX }] }]}
    >
      <View pointerEvents="none" style={styles.edgeHandle} />
      <ScrollView
        contentContainerStyle={[
          styles.content,
          { paddingBottom: Math.max(insets.bottom, 12) + 26, paddingTop: Math.max(insets.top, 12) + 12 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Pressable
            accessibilityLabel="グルームに戻る"
            accessibilityRole="button"
            onPress={() => closePanel()}
            style={styles.roundButton}
          >
            <IconSymbol name="chevron-back" color={ihubColors.ink} size={20} />
          </Pressable>
          <Text style={styles.headerTitle}>めぐりプロフィール</Text>
          <View style={styles.headerSpacer} />
        </View>

        <View style={styles.hero}>
          <View style={[styles.avatarStage, { backgroundColor: profileHueTint(user.hue, 0.22) }]}>
            {threeFailed ? (
              <FallbackAvatar user={user} />
            ) : (
              <MeguriThreeBoundary fallback={<FallbackAvatar user={user} />} onError={() => setThreeFailed(true)}>
                <MeguriThreeScene
                  activeId={null}
                  completedIds={[]}
                  focusedId={user.id}
                  introPhase="ready"
                  mode="summary"
                  onUnavailable={() => setThreeFailed(true)}
                  presentation="profile"
                  residents={[resident]}
                  self={PROFILE_SELF}
                  smilingId={user.id}
                />
              </MeguriThreeBoundary>
            )}
          </View>

          <View style={styles.identity}>
            <View style={[styles.hueDot, { backgroundColor: profileHueColor(user.hue) }]} />
            <Text style={styles.name}>{user.name}</Text>
            <Text style={styles.handle}>@{user.id}</Text>
          </View>
          <View style={[styles.basePill, { backgroundColor: profileHueTint(user.hue, 0.15) }]}>
            <IconSymbol name="sparkles-outline" color={profileHueColor(user.hue)} size={15} />
            <Text style={styles.baseText}>拠点: {user.area}</Text>
          </View>
        </View>

        <View style={styles.statsRow}>
          <StatTile label="めぐり回数" value={`${user.count}回`} hue={user.hue} />
          <StatTile label="前回" value={user.since} hue="sky" />
          <StatTile label="推し" value={user.oshi} hue="pink" />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>公開している情報</Text>
          <InfoRow label="グループ / 作品" value={user.group} />
          <InfoRow label="推し" value={user.oshi} />
          <InfoRow label="推し活スタイル" value={user.style} />
          <InfoRow label="今日のひとこと" value={user.hitokoto} />
          <InfoRow label="最近の公開メモ" value={user.recent} />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>あなたとのめぐり</Text>
          <View style={styles.timelineCard}>
            <View style={[styles.timelineIcon, { backgroundColor: profileHueTint(user.hue, 0.26) }]}>
              <IconSymbol name="sparkles-outline" color={profileHueColor(user.hue)} size={20} />
            </View>
            <View style={styles.timelineCopy}>
              <Text style={styles.timelineTitle}>{user.count}回めぐりあっています</Text>
              <Text style={styles.timelineText}>
                {user.area}を拠点に、{user.oshi}推しとして公開プロフィールを出しています。
              </Text>
            </View>
          </View>
        </View>

        {onReply ? (
          <Pressable
            accessibilityRole="button"
            onPress={() => closePanel(onReply)}
            style={styles.messageButton}
          >
            <IconSymbol name="mail-outline" color="#fff" size={18} />
            <Text style={styles.messageButtonText}>グルームに戻って返信</Text>
          </Pressable>
        ) : null}
      </ScrollView>
    </Animated.View>
  );
}

function toSceneResident(user: GroomProfileUser): MeguriSceneResident {
  return {
    animalType: user.animalType,
    furColor: user.furColor,
    hue: user.hue,
    id: user.id,
    name: user.name,
  };
}

function FallbackAvatar({ user }: { user: GroomProfileUser }) {
  return (
    <View style={styles.fallbackAvatar}>
      <View style={[styles.fallbackFace, { backgroundColor: profileHueTint(user.hue, 0.46) }]}>
        <Text style={styles.fallbackFaceText}>{user.name.slice(0, 1)}</Text>
      </View>
    </View>
  );
}

function StatTile({
  hue,
  label,
  value,
}: {
  hue: GroomProfileHue;
  label: string;
  value: string;
}) {
  return (
    <View style={[styles.statTile, { backgroundColor: profileHueTint(hue, 0.18) }]}>
      <Text numberOfLines={1} style={[styles.statValue, { color: profileHueColor(hue) }]}>
        {value}
      </Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.infoRow}>
      <Text style={styles.infoLabel}>{label}</Text>
      <Text style={styles.infoValue}>{value}</Text>
    </View>
  );
}

function profileHueColor(hue: GroomProfileHue) {
  const [r, g, b] = HUE_RGB[hue];
  return `rgb(${r},${g},${b})`;
}

function profileHueTint(hue: GroomProfileHue, alpha: number) {
  const [r, g, b] = HUE_RGB[hue];
  return `rgba(${r},${g},${b},${alpha})`;
}

const styles = StyleSheet.create({
  panel: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: ihubColors.background,
    zIndex: 24,
  },
  edgeHandle: {
    backgroundColor: "rgba(58,50,74,0.18)",
    borderRadius: 999,
    bottom: 0,
    left: 6,
    position: "absolute",
    top: 0,
    width: 3,
    zIndex: 2,
  },
  content: {
    gap: 14,
    paddingHorizontal: 18,
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  roundButton: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 999,
    borderWidth: 1,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  headerTitle: {
    color: ihubColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  headerSpacer: {
    width: 42,
  },
  hero: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 30,
    overflow: "hidden",
    paddingBottom: 18,
    ...ihubShadow,
  },
  avatarStage: {
    height: 280,
    width: "100%",
  },
  fallbackAvatar: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  fallbackFace: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.86)",
    borderRadius: 44,
    borderWidth: 4,
    height: 88,
    justifyContent: "center",
    width: 88,
  },
  fallbackFaceText: {
    color: ihubColors.ink,
    fontSize: 34,
    fontWeight: "900",
  },
  identity: {
    alignItems: "center",
    marginTop: 14,
  },
  hueDot: {
    borderColor: "#fff",
    borderRadius: 999,
    borderWidth: 3,
    height: 22,
    marginBottom: 6,
    width: 22,
  },
  name: {
    color: ihubColors.ink,
    fontSize: 26,
    fontWeight: "900",
  },
  handle: {
    color: ihubColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
    marginTop: 2,
  },
  basePill: {
    alignItems: "center",
    borderRadius: 999,
    flexDirection: "row",
    gap: 5,
    marginTop: 12,
    paddingHorizontal: 13,
    paddingVertical: 8,
  },
  baseText: {
    color: ihubColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  statsRow: {
    flexDirection: "row",
    gap: 9,
  },
  statTile: {
    borderRadius: 18,
    flex: 1,
    paddingHorizontal: 10,
    paddingVertical: 13,
  },
  statValue: {
    fontSize: 17,
    fontWeight: "900",
  },
  statLabel: {
    color: ihubColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 3,
  },
  section: {
    backgroundColor: "#fff",
    borderRadius: 24,
    gap: 10,
    padding: 16,
    ...ihubShadow,
  },
  sectionTitle: {
    color: ihubColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  infoRow: {
    borderTopColor: "rgba(58,50,74,0.07)",
    borderTopWidth: 1,
    gap: 3,
    paddingTop: 10,
  },
  infoLabel: {
    color: ihubColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  infoValue: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "800",
    lineHeight: 20,
  },
  timelineCard: {
    alignItems: "center",
    backgroundColor: "rgba(58,50,74,0.04)",
    borderRadius: 18,
    flexDirection: "row",
    gap: 12,
    padding: 12,
  },
  timelineIcon: {
    alignItems: "center",
    borderRadius: 999,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  timelineCopy: {
    flex: 1,
  },
  timelineTitle: {
    color: ihubColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  timelineText: {
    color: ihubColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 17,
    marginTop: 3,
  },
  messageButton: {
    alignItems: "center",
    backgroundColor: ihubColors.ink,
    borderRadius: 999,
    flexDirection: "row",
    gap: 8,
    justifyContent: "center",
    paddingVertical: 15,
  },
  messageButtonText: {
    color: "#fff",
    fontSize: 15,
    fontWeight: "900",
  },
});
