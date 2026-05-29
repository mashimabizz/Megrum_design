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

  if ((!configured && !previewMode) || (configured && !session)) {
    return <Redirect href="/welcome" />;
  }

  if (configured && session && needsOnboarding) {
    return <Redirect href={onboardingPath ?? "/onboarding/gender"} />;
  }

  return (
    <>
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
      <ProfileDrawerOverlay />
    </>
  );
}

function ProfileDrawerOverlay() {
  const { width } = useWindowDimensions();
  const drawerWidth = Math.min(360, Math.max(300, width * 0.82));
  const translateX = useRef(new Animated.Value(-drawerWidth)).current;
  const [visible, setVisible] = useState(false);
  const visibleRef = useRef(false);

  useEffect(() => {
    visibleRef.current = visible;
  }, [visible]);

  const openDrawer = () => {
    setVisible(true);
    translateX.stopAnimation();
    Animated.spring(translateX, {
      toValue: 0,
      damping: 24,
      stiffness: 210,
      mass: 0.82,
      useNativeDriver: true,
    }).start();
  };

  const closeDrawer = (afterClose?: () => void) => {
    translateX.stopAnimation();
    Animated.spring(translateX, {
      toValue: -drawerWidth,
      damping: 24,
      stiffness: 210,
      mass: 0.82,
      useNativeDriver: true,
    }).start(({ finished }) => {
      if (finished) {
        setVisible(false);
        afterClose?.();
      }
    });
  };

  useEffect(() => {
    translateX.setValue(visibleRef.current ? 0 : -drawerWidth);
  }, [drawerWidth, translateX]);

  const edgePanResponder = useMemo(
    () =>
      PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: (_event, gesture) =>
          gesture.dx > 5 && Math.abs(gesture.dx) > Math.abs(gesture.dy),
        onPanResponderGrant: () => {
          setVisible(true);
          translateX.stopAnimation();
        },
        onPanResponderMove: (_event, gesture) => {
          const next = Math.min(0, Math.max(-drawerWidth, -drawerWidth + gesture.dx));
          translateX.setValue(next);
        },
        onPanResponderRelease: (_event, gesture) => {
          if (gesture.dx > drawerWidth * 0.24 || gesture.vx > 0.35) {
            openDrawer();
            return;
          }
          closeDrawer();
        },
        onPanResponderTerminate: () => closeDrawer(),
      }),
    [drawerWidth, translateX],
  );

  const drawerPanResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: (_event, gesture) =>
          gesture.dx < -6 && Math.abs(gesture.dx) > Math.abs(gesture.dy),
        onPanResponderMove: (_event, gesture) => {
          const next = Math.min(0, Math.max(-drawerWidth, gesture.dx));
          translateX.setValue(next);
        },
        onPanResponderRelease: (_event, gesture) => {
          if (gesture.dx < -drawerWidth * 0.22 || gesture.vx < -0.35) {
            closeDrawer();
            return;
          }
          openDrawer();
        },
      }),
    [drawerWidth, translateX],
  );

  const backdropOpacity = translateX.interpolate({
    inputRange: [-drawerWidth, 0],
    outputRange: [0, 0.26],
    extrapolate: "clamp",
  });

  return (
    <View pointerEvents="box-none" style={styles.drawerOverlayRoot}>
      <View style={styles.edgeSwipeHandle} {...edgePanResponder.panHandlers} />
      {visible ? (
        <Animated.View
          pointerEvents="auto"
          style={[styles.drawerBackdrop, { opacity: backdropOpacity }]}
        >
          <Pressable style={StyleSheet.absoluteFill} onPress={() => closeDrawer()} />
        </Animated.View>
      ) : null}
      <Animated.View
        pointerEvents={visible ? "auto" : "none"}
        style={[
          styles.profileDrawer,
          { width: drawerWidth, transform: [{ translateX }] },
        ]}
        {...drawerPanResponder.panHandlers}
      >
        <ProfileDrawerContent onNavigate={closeDrawer} />
      </Animated.View>
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

  function go(path: Parameters<typeof router.push>[0]) {
    router.push(path);
    onNavigate();
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
    <View style={[styles.drawerContent, { paddingTop: insets.top + 20, paddingBottom: insets.bottom + 20 }]}>
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
      <IconSymbol name={icon} color={megrumColors.ink} size={compact ? 18 : 24} />
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
  drawerOverlayRoot: {
    ...StyleSheet.absoluteFillObject,
    zIndex: 40,
  },
  edgeSwipeHandle: {
    bottom: 0,
    left: 0,
    position: "absolute",
    top: 0,
    width: 22,
    zIndex: 20,
  },
  drawerBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: megrumColors.ink,
    zIndex: 30,
  },
  profileDrawer: {
    backgroundColor: megrumColors.surface,
    bottom: 0,
    left: 0,
    position: "absolute",
    top: 0,
    zIndex: 31,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 18, height: 0 },
    shadowOpacity: 0.18,
    shadowRadius: 28,
  },
  drawerContent: {
    flex: 1,
    paddingHorizontal: 26,
  },
  drawerProfile: {
    gap: 5,
    marginBottom: 26,
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
    fontSize: 24,
    fontWeight: "900",
    letterSpacing: 0,
  },
  drawerHandle: {
    color: megrumColors.mutedInk,
    fontSize: 16,
    fontWeight: "800",
  },
  drawerArea: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "800",
    marginTop: 6,
  },
  drawerMenu: {
    gap: 11,
  },
  drawerMenuCompact: {
    gap: 7,
  },
  drawerItem: {
    alignItems: "center",
    borderRadius: 16,
    flexDirection: "row",
    gap: 20,
    minHeight: 50,
    paddingHorizontal: 3,
  },
  drawerItemCompact: {
    gap: 16,
    minHeight: 42,
  },
  drawerItemPressed: {
    backgroundColor: "rgba(58,50,74,0.05)",
  },
  drawerItemDisabled: {
    opacity: 0.62,
  },
  drawerItemText: {
    color: megrumColors.ink,
    fontSize: 24,
    fontWeight: "900",
    letterSpacing: 0,
  },
  drawerItemAccessory: {
    marginLeft: "auto",
  },
  drawerItemTextCompact: {
    fontSize: 17,
    fontWeight: "800",
  },
  drawerDivider: {
    backgroundColor: "rgba(58,50,74,0.12)",
    height: StyleSheet.hairlineWidth,
    marginVertical: 24,
  },
});
