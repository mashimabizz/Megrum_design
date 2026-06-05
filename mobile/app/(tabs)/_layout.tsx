import { useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import Constants from "expo-constants";
import { Redirect, router } from "expo-router";
import { Icon, Label, NativeTabs } from "expo-router/unstable-native-tabs";
import * as Updates from "expo-updates";
import {
  ActivityIndicator,
  Alert,
  Animated,
  Image,
  PanResponder,
  Pressable,
  StyleSheet,
  Text,
  View,
  useWindowDimensions,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useAuth } from "../../src/auth/AuthProvider";
import { IconSymbol, type IconSymbolName } from "../../src/components/IconSymbol";
import { ProfileDrawerProvider } from "../../src/components/ProfileDrawerContext";
import { fetchUnreadNotificationCount } from "../../src/lib/notifications";
import { supabase } from "../../src/lib/supabase";
import { megrumColors } from "../../src/theme/tokens";

const TAB_CONFIG = {
  index: {
    label: "ホーム",
    sf: { default: "house", selected: "house.fill" },
  },
  inventory: {
    label: "在庫",
    sf: { default: "shippingbox", selected: "shippingbox.fill" },
  },
  wishes: {
    label: "Wish",
    sf: { default: "heart", selected: "heart.fill" },
  },
  encounters: {
    label: "めぐり",
    sf: {
      default: "dot.radiowaves.left.and.right",
      selected: "dot.radiowaves.left.and.right",
    },
  },
  notifications: {
    label: "通知",
    sf: { default: "bell", selected: "bell.fill" },
  },
  transactions: {
    label: "やりとり",
    sf: {
      default: "arrow.left.arrow.right",
      selected: "arrow.left.arrow.right",
    },
  },
} as const;

export default function TabLayout() {
  const { configured, loading, needsOnboarding, onboardingPath, previewMode, profileLoading, session } =
    useAuth();

  if (loading || profileLoading) {
    return (
      <View
        style={{
          flex: 1,
          alignItems: "center",
          justifyContent: "center",
          backgroundColor: megrumColors.background,
        }}
      >
        <ActivityIndicator color={megrumColors.lavender} />
      </View>
    );
  }

  if (!previewMode && ((!configured) || (configured && !session))) {
    return <Redirect href="/welcome" />;
  }

  if (configured && session && needsOnboarding) {
    return <Redirect href={onboardingPath ?? "/onboarding/gender"} />;
  }

  return (
    <ProfileDrawerShell>
      <NativeTabs
        backgroundColor={null}
        blurEffect="systemDefault"
        iconColor={{
          default: "rgba(58,50,74,0.46)",
          selected: megrumColors.lavender,
        }}
        labelStyle={{
          default: {
            color: "rgba(58,50,74,0.56)",
            fontSize: 11,
            fontWeight: "700",
          },
          selected: {
            color: megrumColors.lavender,
            fontSize: 11,
            fontWeight: "800",
          },
        }}
        minimizeBehavior="onScrollDown"
        tintColor={megrumColors.lavender}
      >
        <NativeTabs.Trigger name="index">
          <Icon sf={TAB_CONFIG.index.sf} />
          <Label>{TAB_CONFIG.index.label}</Label>
        </NativeTabs.Trigger>
        <NativeTabs.Trigger name="inventory">
          <Icon sf={TAB_CONFIG.inventory.sf} />
          <Label>{TAB_CONFIG.inventory.label}</Label>
        </NativeTabs.Trigger>
        <NativeTabs.Trigger name="wishes">
          <Icon sf={TAB_CONFIG.wishes.sf} />
          <Label>{TAB_CONFIG.wishes.label}</Label>
        </NativeTabs.Trigger>
        <NativeTabs.Trigger name="transactions">
          <Icon sf={TAB_CONFIG.transactions.sf} />
          <Label>{TAB_CONFIG.transactions.label}</Label>
        </NativeTabs.Trigger>
        <NativeTabs.Trigger name="encounters">
          <Icon sf={TAB_CONFIG.encounters.sf} />
          <Label>{TAB_CONFIG.encounters.label}</Label>
        </NativeTabs.Trigger>
        <NativeTabs.Trigger hidden name="notifications" />
        <NativeTabs.Trigger hidden name="profile" />
      </NativeTabs>
    </ProfileDrawerShell>
  );
}

function ProfileDrawerShell({ children }: { children: ReactNode }) {
  const { width } = useWindowDimensions();
  const drawerWidth = Math.min(380, Math.max(320, width * 0.9));
  const openX = Math.min(drawerWidth - 34, width * 0.68);
  const screenX = useRef(new Animated.Value(0)).current;
  const [visible, setVisible] = useState(false);
  const [closing, setClosing] = useState(false);
  const [drawerInteractive, setDrawerInteractive] = useState(false);
  const visibleRef = useRef(false);
  const closingRef = useRef(false);
  const drawerInteractiveRef = useRef(false);

  useEffect(() => {
    visibleRef.current = visible;
  }, [visible]);

  function setDrawerInteractionEnabled(enabled: boolean) {
    if (drawerInteractiveRef.current === enabled) return;
    drawerInteractiveRef.current = enabled;
    setDrawerInteractive(enabled);
  }

  const openDrawer = () => {
    closingRef.current = false;
    setDrawerInteractionEnabled(false);
    setClosing(false);
    setVisible(true);
    screenX.stopAnimation();
    Animated.spring(screenX, {
      toValue: openX,
      damping: 25,
      stiffness: 190,
      mass: 0.82,
      useNativeDriver: false,
    }).start(({ finished }) => {
      if (finished) setDrawerInteractionEnabled(true);
    });
  };

  const closeDrawer = (afterClose?: () => void) => {
    let didFinalize = false;
    let fallbackTimer: ReturnType<typeof setTimeout> | null = null;
    const finalizeClose = () => {
      if (didFinalize) return;
      didFinalize = true;
      if (fallbackTimer) {
        clearTimeout(fallbackTimer);
        fallbackTimer = null;
      }
      closingRef.current = false;
      setClosing(false);
      setVisible(false);
      setDrawerInteractionEnabled(false);
      afterClose?.();
    };

    closingRef.current = true;
    setDrawerInteractionEnabled(false);
    setClosing(true);
    screenX.stopAnimation();
    if (afterClose) {
      fallbackTimer = setTimeout(finalizeClose, 420);
    }
    Animated.spring(screenX, {
      toValue: 0,
      damping: 25,
      stiffness: 190,
      mass: 0.82,
      useNativeDriver: false,
    }).start(({ finished }) => {
      if (finished || afterClose) finalizeClose();
    });
  };

  useEffect(() => {
    screenX.setValue(visibleRef.current ? openX : 0);
  }, [openX, screenX]);

  const edgePanResponder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => !visibleRef.current && !closingRef.current,
        onMoveShouldSetPanResponder: (_event, gesture) =>
          !visibleRef.current &&
          !closingRef.current &&
          gesture.dx > 5 &&
          Math.abs(gesture.dx) > Math.abs(gesture.dy),
        onPanResponderGrant: () => {
          closingRef.current = false;
          setDrawerInteractionEnabled(false);
          setClosing(false);
          setVisible(true);
          screenX.stopAnimation();
        },
        onPanResponderMove: (_event, gesture) => {
          const next = Math.min(openX, Math.max(0, gesture.dx));
          screenX.setValue(next);
        },
        onPanResponderRelease: (_event, gesture) => {
          if (gesture.dx > openX * 0.24 || gesture.vx > 0.35) {
            openDrawer();
            return;
          }
          closeDrawer();
        },
        onPanResponderTerminate: () => closeDrawer(),
      }),
    [openX, screenX],
  );

  const foregroundPanResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponderCapture: (_event, gesture) =>
          visibleRef.current &&
          Math.abs(gesture.dx) > 6 &&
          Math.abs(gesture.dx) > Math.abs(gesture.dy),
        onMoveShouldSetPanResponder: (_event, gesture) =>
          visibleRef.current &&
          Math.abs(gesture.dx) > 6 &&
          Math.abs(gesture.dx) > Math.abs(gesture.dy),
        onPanResponderGrant: () => {
          closingRef.current = false;
          setDrawerInteractionEnabled(false);
          setClosing(false);
          screenX.stopAnimation();
        },
        onPanResponderMove: (_event, gesture) => {
          const next = Math.min(openX, Math.max(0, openX + gesture.dx));
          screenX.setValue(next);
        },
        onPanResponderRelease: (_event, gesture) => {
          if (gesture.dx < -8 || gesture.vx < -0.18) {
            closeDrawer();
            return;
          }
          openDrawer();
        },
        onPanResponderTerminate: () => {
          if (closingRef.current) {
            closeDrawer();
            return;
          }
          openDrawer();
        },
      }),
    [openX, screenX],
  );

  const drawerPanResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponderCapture: (_event, gesture) =>
          visibleRef.current &&
          !closingRef.current &&
          drawerInteractiveRef.current &&
          gesture.dx < -6 &&
          Math.abs(gesture.dx) > Math.abs(gesture.dy) * 1.15,
        onMoveShouldSetPanResponder: (_event, gesture) =>
          visibleRef.current &&
          !closingRef.current &&
          drawerInteractiveRef.current &&
          gesture.dx < -6 &&
          Math.abs(gesture.dx) > Math.abs(gesture.dy) * 1.15,
        onPanResponderGrant: () => {
          closingRef.current = false;
          setDrawerInteractionEnabled(false);
          setClosing(false);
          screenX.stopAnimation();
        },
        onPanResponderMove: (_event, gesture) => {
          const next = Math.min(openX, Math.max(0, openX + gesture.dx));
          screenX.setValue(next);
        },
        onPanResponderRelease: (_event, gesture) => {
          if (gesture.dx < -openX * 0.18 || gesture.vx < -0.28) {
            closeDrawer();
            return;
          }
          openDrawer();
        },
        onPanResponderTerminate: () => {
          openDrawer();
        },
      }),
    [openX, screenX],
  );

  const drawerOpacity = screenX.interpolate({
    inputRange: [0, openX * 0.3, openX],
    outputRange: [0, 1, 1],
    extrapolate: "clamp",
  });
  const drawerParallax = screenX.interpolate({
    inputRange: [0, openX],
    outputRange: [-22, 0],
    extrapolate: "clamp",
  });
  const whiteoutOpacity = screenX.interpolate({
    inputRange: [0, openX],
    outputRange: [0, 0.82],
    extrapolate: "clamp",
  });
  const screenRadius = screenX.interpolate({
    inputRange: [0, openX],
    outputRange: [0, 68],
    extrapolate: "clamp",
  });
  const screenShadowOpacity = screenX.interpolate({
    inputRange: [0, openX],
    outputRange: [0, 0.24],
    extrapolate: "clamp",
  });

  return (
    <ProfileDrawerProvider openDrawer={openDrawer}>
      <View style={styles.drawerShellRoot}>
        <Animated.View
          pointerEvents={visible && !closing && drawerInteractive ? "auto" : "none"}
          style={[
            styles.drawerUnderlay,
            {
              opacity: drawerOpacity,
              width: drawerWidth,
              transform: [{ translateX: drawerParallax }],
            },
          ]}
          {...drawerPanResponder.panHandlers}
        >
          <ProfileDrawerContent onNavigate={closeDrawer} />
        </Animated.View>

        <Animated.View
          style={[
            styles.drawerForeground,
            {
              borderBottomLeftRadius: screenRadius,
              borderTopLeftRadius: screenRadius,
              shadowOpacity: screenShadowOpacity,
              transform: [{ translateX: screenX }],
            },
          ]}
          {...foregroundPanResponder.panHandlers}
        >
          <Animated.View
            style={[
              styles.drawerForegroundClip,
              {
                borderBottomLeftRadius: screenRadius,
                borderTopLeftRadius: screenRadius,
              },
            ]}
          >
            {children}
            <Animated.View
              pointerEvents="none"
              style={[styles.drawerWhiteout, { opacity: whiteoutOpacity }]}
            />
            {visible && !closing ? (
              <Pressable
                accessibilityLabel="メニューを閉じる"
                accessibilityRole="button"
                style={StyleSheet.absoluteFill}
                onPress={() => closeDrawer()}
              />
            ) : null}
          </Animated.View>
        </Animated.View>

        <View
          pointerEvents={visible || closing ? "none" : "auto"}
          style={styles.edgeSwipeHandle}
          {...edgePanResponder.panHandlers}
        />
      </View>
    </ProfileDrawerProvider>
  );
}

export function ProfileDrawerVisualSnapshot() {
  const { width } = useWindowDimensions();
  const drawerWidth = Math.min(380, Math.max(320, width * 0.9));
  const openX = Math.min(drawerWidth - 34, width * 0.68);

  return (
    <View style={styles.drawerShellRoot}>
      <View
        style={[
          styles.drawerUnderlay,
          {
            opacity: 1,
            width: drawerWidth,
            transform: [{ translateX: 0 }],
          },
        ]}
      >
        <ProfileDrawerContent onNavigate={() => {}} />
      </View>

      <View
        style={[
          styles.drawerForeground,
          {
            borderBottomLeftRadius: 68,
            borderTopLeftRadius: 68,
            shadowOpacity: 0.24,
            transform: [{ translateX: openX }],
          },
        ]}
      >
        <View
          style={[
            styles.drawerForegroundClip,
            {
              borderBottomLeftRadius: 68,
              borderTopLeftRadius: 68,
            },
          ]}
        >
          <View style={styles.drawerVisualForeground}>
            <Text style={styles.drawerVisualKicker}>ON SITE</Text>
            <Text style={styles.drawerVisualTitle}>現地交換</Text>
            <Text style={styles.drawerVisualMeta}>東京都内イベント・4:25 PM</Text>
            <View style={styles.drawerVisualCard}>
              <View style={styles.drawerVisualThumb} />
              <View>
                <Text style={styles.drawerVisualCardTitle}>ランダムトレカ A</Text>
                <Text style={styles.drawerVisualCardMeta}>交換候補・2点</Text>
              </View>
            </View>
          </View>
          <View style={[styles.drawerWhiteout, { opacity: 0.82 }]} />
        </View>
      </View>
    </View>
  );
}

function ProfileDrawerContent({
  onNavigate,
}: {
  onNavigate: (afterClose?: () => void) => void;
}) {
  const insets = useSafeAreaInsets();
  const { profile, previewMode, user, signOut, exitPreview } = useAuth();
  const [updateChecking, setUpdateChecking] = useState(false);
  const [unreadNotificationCount, setUnreadNotificationCount] = useState(previewMode ? 3 : 0);
  const metadata = user?.user_metadata as Record<string, unknown> | undefined;
  const appVariant = String(Constants.expoConfig?.extra?.appVariant ?? "");
  const canApplyPreviewUpdate = appVariant === "preview" || Updates.channel === "preview";
  const displayName =
    profile?.displayName ??
    stringMeta(metadata?.display_name) ??
    stringMeta(metadata?.name) ??
    user?.email?.split("@")[0] ??
    "Megrum";
  const handle =
    profile?.handle ??
    stringMeta(metadata?.handle) ??
    user?.email?.split("@")[0] ??
    "preview_hana";
  const avatarUrl =
    profile?.avatarUrl ??
    stringMeta(metadata?.avatar_url) ??
    stringMeta(metadata?.picture);
  const area = profile?.primaryArea ?? "エリア未設定";

  useEffect(() => {
    if (previewMode) {
      setUnreadNotificationCount(3);
      return;
    }
    const client = supabase;
    if (!client || !user?.id) {
      setUnreadNotificationCount(0);
      return;
    }

    let active = true;
    const refresh = () => {
      fetchUnreadNotificationCount(user.id)
        .then((count) => {
          if (active) setUnreadNotificationCount(count);
        })
        .catch(() => {
          if (active) setUnreadNotificationCount(0);
        });
    };
    refresh();
    const channel = client
      .channel(`drawer-notifications:${user.id}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          filter: `user_id=eq.${user.id}`,
          schema: "public",
          table: "notifications",
        },
        refresh,
      )
      .subscribe();

    return () => {
      active = false;
      void client.removeChannel(channel);
    };
  }, [previewMode, user?.id]);

  function go(path: Parameters<typeof router.push>[0]) {
    onNavigate(() => {
      router.push(path);
    });
  }

  function openNotifications() {
    go("/notifications");
  }

  async function handleSignOut() {
    onNavigate();
    if (previewMode) {
      exitPreview();
      router.replace("/welcome");
      return;
    }
    const error = await signOut();
    if (!error) router.replace("/welcome");
  }

  async function handleApplyLatestUpdate() {
    if (updateChecking) return;
    setUpdateChecking(true);
    try {
      const update = await Updates.checkForUpdateAsync();
      if (!update.isAvailable) {
        Alert.alert("最新です", "このプレビュー版はすでに最新の内容です。");
        return;
      }
      await Updates.fetchUpdateAsync();
      await Updates.reloadAsync();
    } catch (error) {
      console.warn("Failed to apply preview update", error);
      Alert.alert(
        "更新を確認できませんでした",
        "通信状況を確認して、もう一度お試しください。",
      );
    } finally {
      setUpdateChecking(false);
    }
  }

  return (
    <View style={[styles.drawerContent, { paddingTop: insets.top + 28, paddingBottom: insets.bottom + 20 }]}>
      <View style={styles.drawerProfile}>
        <View style={styles.drawerAvatar}>
          {avatarUrl ? (
            <Image source={{ uri: avatarUrl }} style={styles.drawerAvatarImage} />
          ) : (
            <Text style={styles.drawerAvatarText}>{displayName.slice(0, 1)}</Text>
          )}
        </View>
        <Text numberOfLines={1} style={styles.drawerName}>{displayName}</Text>
        <Text numberOfLines={1} style={styles.drawerHandle}>@{handle.replace(/^@/, "")}</Text>
        <Text numberOfLines={1} style={styles.drawerArea}>{area}</Text>
      </View>

      <View style={styles.drawerMenu}>
        <DrawerItem icon="star-outline" label="プロフィール" onPress={() => go("/me")} />
        <DrawerItem
          accessory={<DrawerNotificationBadge count={unreadNotificationCount} />}
          icon="notifications-outline"
          label="通知"
          onPress={openNotifications}
        />
        <DrawerItem icon="create-outline" label="プロフィール編集" onPress={() => go("/profile-edit")} />
        <DrawerItem icon="sparkles-outline" label="推し設定" onPress={() => go("/oshi-settings")} />
        <DrawerItem icon="calendar-outline" label="スケジュール" onPress={() => go("/schedules")} />
        <DrawerItem
          icon="checkmark-circle-outline"
          label="完了した取引"
          onPress={() =>
            go({
              pathname: "/transactions",
              params: { archive: "completed" },
            })
          }
        />
      </View>

      <View style={styles.drawerDivider} />

      <View style={styles.drawerMenuCompact}>
        {canApplyPreviewUpdate ? (
          <DrawerItem
            compact
            accessory={updateChecking ? <ActivityIndicator color={megrumColors.lavender} size="small" /> : null}
            disabled={updateChecking}
            icon={updateChecking ? "time-outline" : "arrow-clockwise"}
            label={updateChecking ? "更新を確認中…" : "最新の更新を反映"}
            onPress={() => {
              void handleApplyLatestUpdate();
            }}
          />
        ) : null}
        <DrawerItem compact icon="shield-checkmark-outline" label="設定とプライバシー" onPress={() => go("/settings-privacy")} />
        <DrawerItem compact icon="document-text-outline" label="ヘルプ" onPress={() => go("/help")} />
        <DrawerItem compact icon="ban-outline" label={previewMode ? "プレビューを終了" : "ログアウト"} onPress={handleSignOut} />
      </View>
    </View>
  );
}

function DrawerNotificationBadge({ count }: { count: number }) {
  if (count <= 0) return null;
  return (
    <View style={styles.drawerBadge}>
      <Text style={styles.drawerBadgeText}>{count > 99 ? "99+" : count}</Text>
    </View>
  );
}

function DrawerItem({
  accessory,
  compact,
  disabled,
  icon,
  label,
  onPress,
}: {
  accessory?: ReactNode;
  compact?: boolean;
  disabled?: boolean;
  icon: IconSymbolName;
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.drawerItem,
        compact ? styles.drawerItemCompact : null,
        disabled ? styles.drawerItemDisabled : null,
        pressed ? styles.drawerItemPressed : null,
      ]}
    >
      <IconSymbol name={icon} color={megrumColors.ink} size={compact ? 21 : 25} />
      <Text style={[styles.drawerItemText, compact ? styles.drawerItemTextCompact : null]}>
        {label}
      </Text>
      {accessory ? <View style={styles.drawerItemAccessory}>{accessory}</View> : null}
    </Pressable>
  );
}

function stringMeta(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

const styles = StyleSheet.create({
  drawerShellRoot: {
    backgroundColor: megrumColors.surface,
    flex: 1,
  },
  edgeSwipeHandle: {
    bottom: 0,
    left: 0,
    position: "absolute",
    top: 0,
    width: 24,
    zIndex: 40,
  },
  drawerUnderlay: {
    backgroundColor: megrumColors.surface,
    bottom: 0,
    left: 0,
    position: "absolute",
    top: 0,
    zIndex: 1,
  },
  drawerForeground: {
    backgroundColor: megrumColors.background,
    flex: 1,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: -30, height: 0 },
    shadowRadius: 46,
    zIndex: 2,
  },
  drawerForegroundClip: {
    backgroundColor: megrumColors.background,
    flex: 1,
    overflow: "hidden",
  },
  drawerWhiteout: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#fff",
    zIndex: 3,
  },
  drawerContent: {
    flex: 1,
    paddingHorizontal: 24,
  },
  drawerProfile: {
    gap: 5,
    marginBottom: 22,
  },
  drawerAvatar: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    borderRadius: 32,
    height: 64,
    justifyContent: "center",
    marginBottom: 9,
    overflow: "hidden",
    width: 64,
  },
  drawerAvatarImage: {
    height: "100%",
    width: "100%",
  },
  drawerAvatarText: {
    color: megrumColors.ink,
    fontSize: 24,
    fontWeight: "900",
  },
  drawerName: {
    color: megrumColors.ink,
    fontSize: 26,
    fontWeight: "900",
    letterSpacing: 0,
  },
  drawerHandle: {
    color: megrumColors.mutedInk,
    fontSize: 18,
    fontWeight: "800",
  },
  drawerArea: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "800",
    marginTop: 6,
  },
  drawerMenu: {
    gap: 5,
  },
  drawerMenuCompact: {
    gap: 4,
  },
  drawerItem: {
    alignItems: "center",
    borderRadius: 16,
    flexDirection: "row",
    gap: 18,
    minHeight: 46,
    paddingHorizontal: 3,
  },
  drawerItemCompact: {
    gap: 16,
    minHeight: 40,
  },
  drawerItemPressed: {
    backgroundColor: "rgba(58,50,74,0.05)",
  },
  drawerItemDisabled: {
    opacity: 0.62,
  },
  drawerItemText: {
    color: megrumColors.ink,
    flex: 1,
    flexShrink: 1,
    fontSize: 20,
    fontWeight: "900",
    letterSpacing: 0,
    minWidth: 0,
  },
  drawerItemAccessory: {
    marginLeft: "auto",
  },
  drawerBadge: {
    alignItems: "center",
    backgroundColor: megrumColors.warn,
    borderRadius: 999,
    minWidth: 24,
    paddingHorizontal: 7,
    paddingVertical: 3,
  },
  drawerBadgeText: {
    color: "#fff",
    fontSize: 11,
    fontWeight: "900",
    lineHeight: 14,
  },
  drawerItemTextCompact: {
    fontSize: 16.5,
    fontWeight: "800",
  },
  drawerDivider: {
    backgroundColor: "rgba(58,50,74,0.12)",
    height: StyleSheet.hairlineWidth,
    marginVertical: 20,
  },
  drawerVisualForeground: {
    backgroundColor: megrumColors.background,
    flex: 1,
    gap: 18,
    paddingHorizontal: 42,
    paddingTop: 132,
  },
  drawerVisualKicker: {
    alignSelf: "flex-start",
    backgroundColor: "rgba(166,149,216,0.14)",
    borderRadius: 999,
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1.4,
    paddingHorizontal: 13,
    paddingVertical: 7,
  },
  drawerVisualTitle: {
    color: megrumColors.ink,
    fontSize: 36,
    fontWeight: "900",
  },
  drawerVisualMeta: {
    color: megrumColors.mutedInk,
    fontSize: 19,
    fontWeight: "800",
  },
  drawerVisualCard: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 28,
    flexDirection: "row",
    gap: 16,
    marginTop: 22,
    padding: 18,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 14 },
    shadowOpacity: 0.12,
    shadowRadius: 30,
  },
  drawerVisualThumb: {
    backgroundColor: "rgba(168,212,230,0.42)",
    borderRadius: 22,
    height: 92,
    width: 92,
  },
  drawerVisualCardTitle: {
    color: megrumColors.ink,
    fontSize: 19,
    fontWeight: "900",
  },
  drawerVisualCardMeta: {
    color: megrumColors.mutedInk,
    fontSize: 14,
    fontWeight: "800",
    marginTop: 5,
  },
});
