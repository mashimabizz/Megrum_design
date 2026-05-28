import { useMemo, useState } from "react";
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { router, useLocalSearchParams } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { IconSymbol } from "../src/components/IconSymbol";
import {
  MeguriThreeBoundary,
  MeguriThreeScene,
  type MeguriSceneResident,
} from "../src/components/meguri/MeguriThreeScene";
import { megrumColors, megrumShadow } from "../src/theme/tokens";
import { USERS, hueColor, hueTint, type MeguriUser } from "./(tabs)/encounters";

const PROFILE_SELF: MeguriSceneResident = {
  animalType: "rabbit",
  furColor: "lavender",
  hue: "lav",
  id: "me",
  name: "あなた",
};

export default function MeguriProfileScreen() {
  const insets = useSafeAreaInsets();
  const params = useLocalSearchParams<{ id?: string | string[] }>();
  const profileId = Array.isArray(params.id) ? params.id[0] : params.id;
  const user = useMemo(() => USERS.find((item) => item.id === profileId) ?? null, [profileId]);
  const resident = useMemo(() => (user ? toSceneResident(user) : null), [user]);
  const [threeFailed, setThreeFailed] = useState(false);

  function openMessage() {
    if (!user) return;
    router.push({
      pathname: "/meguri-letters",
      params: { userId: user.id },
    });
  }

  if (!user || !resident) {
    return (
      <View style={styles.root}>
        <ScrollView
          contentContainerStyle={[
            styles.content,
            { paddingBottom: Math.max(insets.bottom, 12) + 26, paddingTop: Math.max(insets.top, 12) + 12 },
          ]}
          showsVerticalScrollIndicator={false}
        >
          <View style={styles.header}>
            <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.roundButton}>
              <IconSymbol name="chevron-back" color={megrumColors.ink} size={20} />
            </Pressable>
            <Text style={styles.headerTitle}>めぐりプロフィール</Text>
            <View style={styles.headerSpacer} />
          </View>
          <View style={styles.emptyProfile}>
            <Text style={styles.emptyProfileTitle}>プロフィールを表示できませんでした</Text>
            <Text style={styles.emptyProfileText}>相手の情報を読み込めるまで、別のプロフィールは表示しません。</Text>
          </View>
        </ScrollView>
      </View>
    );
  }

  return (
    <View style={styles.root}>
      <ScrollView
        contentContainerStyle={[
          styles.content,
          { paddingBottom: Math.max(insets.bottom, 12) + 26, paddingTop: Math.max(insets.top, 12) + 12 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.roundButton}>
            <IconSymbol name="chevron-back" color={megrumColors.ink} size={20} />
          </Pressable>
          <Text style={styles.headerTitle}>めぐりプロフィール</Text>
          <View style={styles.headerSpacer} />
        </View>

        <View style={styles.hero}>
          <View style={styles.avatarStage}>
            {threeFailed ? (
              <View style={styles.fallbackAvatar}>
                <ActivityIndicator color={megrumColors.lavender} />
              </View>
            ) : (
              <MeguriThreeBoundary
                fallback={
                  <View style={styles.fallbackAvatar}>
                    <ActivityIndicator color={megrumColors.lavender} />
                  </View>
                }
                onError={() => setThreeFailed(true)}
              >
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
            <View style={[styles.hueDot, { backgroundColor: hueColor(user.hue) }]} />
            <Text style={styles.name}>{user.name}</Text>
            <Text style={styles.handle}>@{user.id}</Text>
          </View>
          <View style={styles.basePill}>
            <IconSymbol name="sparkles-outline" color={megrumColors.lavender} size={15} />
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
            <View style={[styles.timelineIcon, { backgroundColor: hueTint(user.hue, 0.28) }]}>
              <IconSymbol name="sparkles-outline" color={hueColor(user.hue)} size={20} />
            </View>
            <View style={styles.timelineCopy}>
              <Text style={styles.timelineTitle}>{user.count}回めぐりあっています</Text>
              <Text style={styles.timelineText}>
                {user.area}を拠点に、{user.oshi}推しとして公開プロフィールを出しています。
              </Text>
            </View>
          </View>
        </View>

        <Pressable accessibilityRole="button" onPress={openMessage} style={styles.messageButton}>
          <IconSymbol name="mail-outline" color="#fff" size={18} />
          <Text style={styles.messageButtonText}>メッセージを送る</Text>
        </Pressable>
      </ScrollView>
    </View>
  );
}

function toSceneResident(user: MeguriUser): MeguriSceneResident {
  return {
    animalType: user.animalType,
    furColor: user.furColor,
    hue: user.hue,
    id: user.id,
    name: user.name,
  };
}

function StatTile({
  hue,
  label,
  value,
}: {
  hue: MeguriUser["hue"];
  label: string;
  value: string;
}) {
  return (
    <View style={[styles.statTile, { backgroundColor: hueTint(hue, 0.18) }]}>
      <Text numberOfLines={1} style={[styles.statValue, { color: hueColor(hue) }]}>
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

const styles = StyleSheet.create({
  root: {
    backgroundColor: megrumColors.background,
    flex: 1,
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
    color: megrumColors.ink,
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
    ...megrumShadow,
  },
  avatarStage: {
    backgroundColor: "#c9f1ff",
    height: 280,
    width: "100%",
  },
  fallbackAvatar: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  emptyProfile: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 26,
    marginTop: 18,
    paddingHorizontal: 24,
    paddingVertical: 44,
    ...megrumShadow,
  },
  emptyProfileTitle: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  emptyProfileText: {
    color: "rgba(58,50,74,0.56)",
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 20,
    marginTop: 8,
    textAlign: "center",
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
    color: megrumColors.ink,
    fontSize: 26,
    fontWeight: "900",
  },
  handle: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
    marginTop: 2,
  },
  basePill: {
    alignItems: "center",
    backgroundColor: hueTint("lav", 0.16),
    borderRadius: 999,
    flexDirection: "row",
    gap: 5,
    marginTop: 12,
    paddingHorizontal: 13,
    paddingVertical: 8,
  },
  baseText: {
    color: megrumColors.ink,
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
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    marginTop: 3,
  },
  section: {
    backgroundColor: "#fff",
    borderRadius: 24,
    gap: 10,
    padding: 16,
    ...megrumShadow,
  },
  sectionTitle: {
    color: megrumColors.ink,
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
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "900",
  },
  infoValue: {
    color: megrumColors.ink,
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
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  timelineText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 17,
    marginTop: 3,
  },
  messageButton: {
    alignItems: "center",
    backgroundColor: megrumColors.ink,
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
