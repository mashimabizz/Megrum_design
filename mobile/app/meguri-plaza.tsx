import { useEffect, useMemo, useState } from "react";
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { IconSymbol } from "../src/components/IconSymbol";
import { Screen } from "../src/components/Screen";
import {
  MeguriThreeBoundary,
  MeguriThreeScene,
  type MeguriSceneResident,
} from "../src/components/meguri/MeguriThreeScene";
import { megrumColors } from "../src/theme/tokens";
import { USERS, WalkingCard, hueColor, type MeguriUser } from "./(tabs)/encounters";
import {
  DEFAULT_MEGURI_AVATAR,
  DEFAULT_MEGURI_PROFILE,
  loadMeguriAvatarSettings,
  loadMeguriProfileSettings,
} from "../src/lib/meguriSettings";

const TOUCH_SPOTS = [
  { left: "12%", top: "19%", bubbleLeft: "7%", bubbleTop: "10%" },
  { left: "39%", top: "15%", bubbleLeft: "27%", bubbleTop: "7%" },
  { left: "66%", top: "18%", bubbleLeft: "51%", bubbleTop: "9%" },
  { left: "86%", top: "30%", bubbleLeft: "60%", bubbleTop: "19%" },
  { left: "20%", top: "43%", bubbleLeft: "10%", bubbleTop: "32%" },
  { left: "50%", top: "39%", bubbleLeft: "37%", bubbleTop: "28%" },
  { left: "78%", top: "47%", bubbleLeft: "58%", bubbleTop: "36%" },
  { left: "12%", top: "66%", bubbleLeft: "7%", bubbleTop: "54%" },
  { left: "40%", top: "70%", bubbleLeft: "28%", bubbleTop: "58%" },
  { left: "70%", top: "68%", bubbleLeft: "53%", bubbleTop: "56%" },
] as const;

export default function MeguriPlazaScreen() {
  const insets = useSafeAreaInsets();
  const plazaUsers = useMemo(() => USERS.slice(0, 10), []);
  const residents = useMemo(() => plazaUsers.map(toPlazaResident), [plazaUsers]);
  const [threeFailed, setThreeFailed] = useState(false);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [selfScene, setSelfScene] = useState<MeguriSceneResident | null>(null);
  const selectedUser = plazaUsers.find((user) => user.id === selectedId) ?? null;
  const selectedIndex = selectedUser
    ? Math.max(0, plazaUsers.findIndex((user) => user.id === selectedUser.id))
    : -1;
  const selectedSpot = selectedIndex >= 0 ? TOUCH_SPOTS[selectedIndex % TOUCH_SPOTS.length] : null;

  function openDetail(user: MeguriUser) {
    router.push({
      pathname: "/meguri-profile",
      params: { id: user.id },
    });
  }

  useEffect(() => {
    let mounted = true;
    Promise.all([loadMeguriAvatarSettings(), loadMeguriProfileSettings()])
      .then(([avatar, profile]) => {
        if (!mounted) return;
        setSelfScene({
          animalType: avatar.animalType ?? DEFAULT_MEGURI_AVATAR.animalType,
          furColor: avatar.furColor ?? DEFAULT_MEGURI_AVATAR.furColor,
          hue: avatar.hue ?? DEFAULT_MEGURI_AVATAR.hue,
          id: "me",
          name: profile.displayName || DEFAULT_MEGURI_PROFILE.displayName,
        });
      })
      .catch(() => {
        if (!mounted) return;
        setSelfScene({
          animalType: DEFAULT_MEGURI_AVATAR.animalType,
          furColor: DEFAULT_MEGURI_AVATAR.furColor,
          hue: DEFAULT_MEGURI_AVATAR.hue,
          id: "me",
          name: DEFAULT_MEGURI_PROFILE.displayName,
        });
      });
    return () => {
      mounted = false;
    };
  }, []);

  return (
    <Screen
      bottomInset={false}
      contentStyle={styles.screen}
      scroll={false}
      topInset={false}
    >
      <View style={styles.scene}>
        {!selfScene ? (
          <View style={styles.sceneLoading}>
            <ActivityIndicator color={megrumColors.lavender} />
          </View>
        ) : threeFailed ? (
          <View style={styles.sceneLoading}>
            <ActivityIndicator color={megrumColors.lavender} />
          </View>
        ) : (
          <MeguriThreeBoundary
            fallback={
              <View style={styles.sceneLoading}>
                <ActivityIndicator color={megrumColors.lavender} />
              </View>
            }
            onError={() => setThreeFailed(true)}
          >
            <MeguriThreeScene
              activeId={null}
              completedIds={[]}
              focusedId={selectedId}
              introPhase="ready"
              mode="summary"
              onUnavailable={() => setThreeFailed(true)}
              presentation="plaza"
              residents={residents}
              self={selfScene}
              smilingId={selectedId}
            />
          </MeguriThreeBoundary>
        )}

        <View pointerEvents="box-none" style={styles.touchLayer}>
          {plazaUsers.map((user, index) => {
            const spot = TOUCH_SPOTS[index % TOUCH_SPOTS.length];
            const selected = user.id === selectedId;
            return (
              <Pressable
                key={user.id}
                accessibilityLabel={`${user.name}のキャラクター`}
                accessibilityRole="button"
                onPress={() => setSelectedId(user.id)}
                style={[styles.hotspot, { left: spot.left, top: spot.top }]}
              >
                {selected ? <View style={styles.focusRing} /> : null}
              </Pressable>
            );
          })}
        </View>

        {selectedUser && selectedSpot ? (
          <View
            style={[
              styles.detailBubble,
              { left: selectedSpot.bubbleLeft, top: selectedSpot.bubbleTop },
            ]}
          >
            <Text numberOfLines={1} style={styles.detailName}>
              {selectedUser.name}
            </Text>
            <Text numberOfLines={1} style={styles.detailMeta}>
              {selectedUser.oshi}推し / {selectedUser.area}
            </Text>
            <Pressable onPress={() => openDetail(selectedUser)} style={styles.detailButton}>
              <Text style={styles.detailButtonText}>詳細を見る</Text>
              <IconSymbol name="chevron-forward" color="#fff" size={14} />
            </Pressable>
            <View style={styles.bubbleTail} />
          </View>
        ) : null}

        <View pointerEvents="box-none" style={[styles.topBar, { paddingTop: Math.max(insets.top, 12) }]}>
          <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.roundButton}>
            <IconSymbol name="chevron-back" color={megrumColors.ink} size={20} />
          </Pressable>
          <View style={styles.titlePill}>
            <Text style={styles.title}>めぐり広場</Text>
          </View>
        </View>
      </View>
    </Screen>
  );
}

function toPlazaResident(user: MeguriUser): MeguriSceneResident {
  return {
    animalType: user.animalType,
    furColor: user.furColor,
    hue: user.hue,
    id: user.id,
    name: user.name,
  };
}

function PlazaFallback({
  onOpenDetail,
  onSelect,
  selectedId,
  users,
}: {
  onOpenDetail: (user: MeguriUser) => void;
  onSelect: (id: string) => void;
  selectedId: string | null;
  users: MeguriUser[];
}) {
  return (
    <View style={styles.fallbackMap}>
      <View style={styles.fallbackGround} />
      {users.map((user, index) => {
        const spot = TOUCH_SPOTS[index % TOUCH_SPOTS.length];
        const selected = selectedId === user.id;
        return (
          <Pressable
            key={user.id}
            accessibilityRole="button"
            onLongPress={() => onOpenDetail(user)}
            onPress={() => onSelect(user.id)}
            style={[
              styles.fallbackPerson,
              { left: spot.left, top: spot.top },
              selected ? styles.fallbackPersonSelected : null,
            ]}
          >
            <WalkingCard user={user} size={selected ? 78 : 66} active={selected} />
            <View style={[styles.countBadge, { backgroundColor: hueColor(user.hue) }]}>
              <Text style={styles.countText}>{user.count}回</Text>
            </View>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    paddingHorizontal: 0,
  },
  scene: {
    backgroundColor: "#bff0c4",
    flex: 1,
    overflow: "hidden",
    position: "relative",
  },
  sceneLoading: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  touchLayer: {
    ...StyleSheet.absoluteFillObject,
  },
  hotspot: {
    alignItems: "center",
    height: 102,
    justifyContent: "center",
    marginLeft: -40,
    marginTop: -50,
    position: "absolute",
    width: 80,
  },
  focusRing: {
    borderColor: "#fff",
    borderRadius: 22,
    borderWidth: 3,
    height: 54,
    shadowColor: "#2b9b5f",
    shadowOpacity: 0.28,
    shadowRadius: 10,
    width: 54,
  },
  topBar: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
    left: 14,
    position: "absolute",
    right: 14,
    top: 0,
  },
  roundButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.82)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 999,
    borderWidth: 1,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  titlePill: {
    backgroundColor: "rgba(255,255,255,0.86)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 20,
    borderWidth: 1,
    flexShrink: 1,
    paddingHorizontal: 14,
    paddingVertical: 9,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  detailBubble: {
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1,
    padding: 10,
    position: "absolute",
    shadowColor: "#342a43",
    shadowOffset: { height: 8, width: 0 },
    shadowOpacity: 0.14,
    shadowRadius: 18,
    width: 150,
  },
  detailName: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  detailMeta: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 2,
  },
  detailButton: {
    alignItems: "center",
    alignSelf: "flex-start",
    backgroundColor: megrumColors.ink,
    borderRadius: 999,
    flexDirection: "row",
    gap: 2,
    marginTop: 8,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  detailButtonText: {
    color: "#fff",
    fontSize: 11,
    fontWeight: "900",
  },
  bubbleTail: {
    backgroundColor: "#fff",
    borderBottomColor: "rgba(58,50,74,0.08)",
    borderBottomWidth: 1,
    borderRightColor: "rgba(58,50,74,0.08)",
    borderRightWidth: 1,
    bottom: -7,
    height: 14,
    left: 22,
    position: "absolute",
    transform: [{ rotate: "45deg" }],
    width: 14,
  },
  fallbackMap: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#bff0c4",
    overflow: "hidden",
  },
  fallbackGround: {
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
  fallbackPerson: {
    alignItems: "center",
    marginLeft: -42,
    marginTop: -46,
    position: "absolute",
  },
  fallbackPersonSelected: {
    transform: [{ scale: 1.06 }],
  },
  countBadge: {
    borderColor: "#fff",
    borderRadius: 999,
    borderWidth: 2,
    marginTop: -8,
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  countText: {
    color: "#fff",
    fontSize: 10,
    fontWeight: "900",
  },
});
