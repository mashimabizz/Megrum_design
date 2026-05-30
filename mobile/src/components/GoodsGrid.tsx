import { useEffect, useMemo, useRef, useState, type ComponentType, type ReactNode } from "react";
import { BlurView } from "expo-blur";
import {
  ActionSheetIOS,
  AccessibilityInfo,
  Animated,
  Easing,
  type GestureResponderEvent,
  Image,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  type StyleProp,
  Text,
  Vibration,
  View,
  type ViewStyle,
  useWindowDimensions,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { IconSymbol, type IconSymbolName } from "./IconSymbol";
import { formatHashTags } from "../lib/inventoryTags";
import { useImageReady } from "../lib/useImageReady";
import { megrumColors, megrumRadii } from "../theme/tokens";

export type ColumnCount = 3 | 4 | 5;

export type GoodsGridItem = {
  id: string;
  title: string;
  subtitle: string;
  glyph: string;
  hue: string;
  badge?: string;
  note?: string;
  photoUrl?: string | null;
  tagLabels?: string[];
};

export type SheetAction = {
  id: string;
  label: string;
  tone?: "default" | "danger" | "muted";
  onPress: () => void;
};

export type GoodsGridPressContext = {
  pageX: number;
  pageY: number;
};

export type SheetAnchor = GoodsGridPressContext;

export type SheetPreview = {
  glyph: string;
  hue: string;
  photoUrl?: string | null;
};

type GlassStyle = "clear" | "regular" | "none";

type IOSGlassViewProps = {
  children?: ReactNode;
  colorScheme?: "auto" | "light" | "dark";
  glassEffectStyle?:
    | GlassStyle
    | { style: GlassStyle; animate?: boolean; animationDuration?: number };
  isInteractive?: boolean;
  style?: StyleProp<ViewStyle>;
  tintColor?: string;
};

type IOSGlassContainerProps = {
  children?: ReactNode;
  spacing?: number;
  style?: StyleProp<ViewStyle>;
};

type IOSGlassKit = {
  GlassView: ComponentType<IOSGlassViewProps>;
  GlassContainer: ComponentType<IOSGlassContainerProps>;
};

let cachedGlassKit: IOSGlassKit | null | undefined;

function getIOSGlassKit() {
  if (Platform.OS !== "ios") return null;
  if (cachedGlassKit !== undefined) return cachedGlassKit;
  try {
    const glass = require("expo-glass-effect") as {
      GlassView: ComponentType<IOSGlassViewProps>;
      GlassContainer: ComponentType<IOSGlassContainerProps>;
      isGlassEffectAPIAvailable?: () => boolean;
      isLiquidGlassAvailable?: () => boolean;
    };
    const apiAvailable = glass.isGlassEffectAPIAvailable?.() ?? false;
    const liquidGlassAvailable = glass.isLiquidGlassAvailable?.() ?? false;
    cachedGlassKit =
      apiAvailable && liquidGlassAvailable
        ? {
            GlassView: glass.GlassView,
            GlassContainer: glass.GlassContainer,
          }
        : null;
  } catch {
    cachedGlassKit = null;
  }
  return cachedGlassKit;
}

export function ColumnSwitcher({
  value,
  onChange,
}: {
  value: ColumnCount;
  onChange: (next: ColumnCount) => void;
}) {
  const values: ColumnCount[] = [3, 4, 5];
  const nextValue = values[(values.indexOf(value) + 1) % values.length] ?? 3;

  return (
    <Pressable
      accessibilityLabel={`表示列数を${nextValue}列に変更`}
      accessibilityRole="button"
      onPress={() => onChange(nextValue)}
      style={({ pressed }) => [
        styles.columnSwitcher,
        pressed ? styles.columnSwitcherPressed : null,
      ]}
    >
      <View style={styles.columnIconRow}>
        {Array.from({ length: value }).map((_, index) => (
          <View key={`${value}-${index}`} style={styles.columnIconCell} />
        ))}
      </View>
    </Pressable>
  );
}

export function SectionTabs<T extends string>({
  value,
  tabs,
  onChange,
  position,
}: {
  value: T;
  tabs: { id: T; label: string; count: number; color: string }[];
  onChange: (next: T) => void;
  position?: number | Animated.Value | Animated.AnimatedInterpolation<number>;
}) {
  const [width, setWidth] = useState(0);
  const progress = useRef(new Animated.Value(0)).current;
  const activeIndex = Math.max(
    0,
    tabs.findIndex((tab) => tab.id === value),
  );
  const thumbWidth = width > 0 ? (width - 8) / Math.max(1, tabs.length) : 0;

  const animatedPosition =
    typeof position === "number" || !position ? progress : position;

  useEffect(() => {
    if (typeof position === "number") {
      progress.setValue(position);
      return;
    }
    if (position) return;
    Animated.spring(progress, {
      toValue: activeIndex,
      damping: 22,
      stiffness: 190,
      mass: 0.74,
      useNativeDriver: true,
    }).start();
  }, [activeIndex, position, progress]);

  const translateX =
    tabs.length > 1
      ? animatedPosition.interpolate({
          inputRange: tabs.map((_, index) => index),
          outputRange: tabs.map((_, index) => index * thumbWidth),
          extrapolate: "clamp",
        })
      : 0;

  return (
    <View
      onLayout={(event) => setWidth(event.nativeEvent.layout.width)}
      style={styles.sectionTabs}
    >
      {thumbWidth > 0 ? (
        <Animated.View
          pointerEvents="none"
          style={[
            styles.sectionTabThumb,
            {
              width: thumbWidth,
              transform: [{ translateX }],
            },
          ]}
        />
      ) : null}
      {tabs.map((tab) => {
        const active = value === tab.id;
        return (
          <Pressable
            key={tab.id}
            onPress={() => onChange(tab.id)}
            style={[
              styles.sectionTab,
              active ? styles.sectionTabActive : null,
            ]}
          >
            <Text
              numberOfLines={1}
              style={[
                styles.sectionTabLabel,
                active
                  ? styles.sectionTabLabelActive
                  : styles.sectionTabLabelInactive,
              ]}
            >
              {tab.label}
            </Text>
            <Text style={[styles.sectionTabCount, { color: tab.color }]}>
              {tab.count}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

export function GoodsGrid({
  items,
  columns,
  onPressItem,
  onLongPressItem,
  emptyLabel,
  addTileLabel,
  onPressAddTile,
  deletingIds = [],
  onItemFadeOutEnd,
  showTopRow = true,
  topRowMode = "title",
  showBottomStrip = true,
  showUnlinkedWarning = false,
}: {
  items: GoodsGridItem[];
  columns: ColumnCount;
  onPressItem: (item: GoodsGridItem, context: GoodsGridPressContext) => void;
  onLongPressItem?: (item: GoodsGridItem, context: GoodsGridPressContext) => void;
  emptyLabel: string;
  addTileLabel?: string;
  onPressAddTile?: () => void;
  deletingIds?: string[];
  onItemFadeOutEnd?: (id: string) => void;
  showTopRow?: boolean;
  topRowMode?: "title" | "tag";
  showBottomStrip?: boolean;
  showUnlinkedWarning?: boolean;
}) {
  const { width } = useWindowDimensions();
  const screenPadding = 36;
  const gap = columns === 3 ? 10 : columns === 4 ? 8 : 6;
  const tileWidth = (width - screenPadding - gap * (columns - 1)) / columns;
  const showAddTile = !!onPressAddTile;

  if (items.length === 0 && !showAddTile) {
    return (
      <View style={styles.emptyBox}>
        <Text style={styles.emptyText}>{emptyLabel}</Text>
      </View>
    );
  }

  return (
    <View style={[styles.grid, { gap }]}>
      {showAddTile ? (
        <AnimatedAddTile
          width={tileWidth}
          label={addTileLabel ?? "追加"}
          onPress={onPressAddTile}
        />
      ) : null}
      {items.map((item, index) => (
        <AnimatedGoodsTile
          key={item.id}
          item={item}
          width={tileWidth}
          delayMs={(showAddTile ? index + 1 : index) * 35}
          deleting={deletingIds.includes(item.id)}
          onFadeOutEnd={onItemFadeOutEnd}
          onPress={(context) => onPressItem(item, context)}
          onLongPress={
            onLongPressItem ? (context) => onLongPressItem(item, context) : undefined
          }
          showTopRow={showTopRow}
          topRowMode={topRowMode}
          showBottomStrip={showBottomStrip}
          showUnlinkedWarning={showUnlinkedWarning}
        />
      ))}
    </View>
  );
}

function AnimatedAddTile({
  width,
  label,
  onPress,
}: {
  width: number;
  label: string;
  onPress: () => void;
}) {
  const appear = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.spring(appear, {
      toValue: 1,
      damping: 18,
      stiffness: 160,
      mass: 0.72,
      useNativeDriver: true,
    }).start();
  }, [appear]);

  const translateY = appear.interpolate({
    inputRange: [0, 1],
    outputRange: [14, 0],
  });
  const scale = appear.interpolate({
    inputRange: [0, 1],
    outputRange: [0.96, 1],
  });

  return (
    <Animated.View
      style={{
        opacity: appear,
        transform: [{ translateY }, { scale }],
        width,
      }}
    >
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={label}
        onPress={onPress}
        style={[styles.addTile, { height: width * 1.34 }]}
      >
        <Text style={styles.addTilePlus}>＋</Text>
        <Text style={styles.addTileText}>{label}</Text>
      </Pressable>
    </Animated.View>
  );
}

function AnimatedGoodsTile({
  item,
  width,
  delayMs,
  deleting,
  onFadeOutEnd,
  onPress,
  onLongPress,
  showTopRow,
  topRowMode,
  showBottomStrip,
  showUnlinkedWarning,
}: {
  item: GoodsGridItem;
  width: number;
  delayMs: number;
  deleting?: boolean;
  onFadeOutEnd?: (id: string) => void;
  onPress: (context: GoodsGridPressContext) => void;
  onLongPress?: (context: GoodsGridPressContext) => void;
  showTopRow: boolean;
  topRowMode: "title" | "tag";
  showBottomStrip: boolean;
  showUnlinkedWarning: boolean;
}) {
  const appear = useRef(new Animated.Value(0)).current;
  const mountedAt = useRef(Date.now()).current;
  const hasAnimated = useRef(false);
  const imageReady = useImageReady(item.photoUrl);
  const unlinkedWarningVisible =
    showUnlinkedWarning && item.badge === "未紐付け";
  const tagLine = formatHashTags(item.tagLabels);
  const topRowLabel = topRowMode === "tag" ? tagLine ?? item.badge ?? "タグ未設定" : item.title;

  useEffect(() => {
    if (deleting || !imageReady || hasAnimated.current) return;
    const remainingDelay = Math.max(0, delayMs - (Date.now() - mountedAt));
    const timer = setTimeout(() => {
      hasAnimated.current = true;
      Animated.spring(appear, {
        toValue: 1,
        damping: 18,
        stiffness: 160,
        mass: 0.72,
        useNativeDriver: true,
      }).start();
    }, remainingDelay);

    return () => clearTimeout(timer);
  }, [appear, deleting, delayMs, imageReady, mountedAt]);

  useEffect(() => {
    if (!deleting) return;
    Animated.timing(appear, {
      toValue: 0,
      duration: 320,
      easing: Easing.in(Easing.cubic),
      useNativeDriver: true,
    }).start(({ finished }) => {
      if (finished) onFadeOutEnd?.(item.id);
    });
  }, [appear, deleting, item.id, onFadeOutEnd]);

  const translateY = appear.interpolate({
    inputRange: [0, 1],
    outputRange: [14, 0],
  });
  const scale = appear.interpolate({
    inputRange: [0, 1],
    outputRange: [0.96, 1],
  });

  return (
    <Animated.View
      pointerEvents={imageReady && !deleting ? "auto" : "none"}
      style={{
        opacity: appear,
        transform: [{ translateY }, { scale }],
        width,
      }}
    >
      <Pressable
        delayLongPress={500}
        onLongPress={
          onLongPress
            ? (event: GestureResponderEvent) => {
                Vibration.vibrate(8);
                onLongPress({
                  pageX: event.nativeEvent.pageX,
                  pageY: event.nativeEvent.pageY,
                });
              }
            : undefined
        }
        onPress={(event: GestureResponderEvent) =>
          onPress({
            pageX: event.nativeEvent.pageX,
            pageY: event.nativeEvent.pageY,
          })
        }
        style={styles.tilePressable}
      >
        <View
          style={[
            styles.tileImage,
            unlinkedWarningVisible ? styles.tileImageUnlinked : null,
            { height: width * 1.34 },
          ]}
        >
          {item.photoUrl ? (
            <Image
              source={{ uri: item.photoUrl }}
              resizeMode="cover"
              style={styles.tilePhoto}
            />
          ) : (
            <View style={[styles.tileImageFill, { backgroundColor: item.hue }]}>
              <View style={styles.tileShine} />
              <Text style={styles.tileGlyph}>{item.glyph}</Text>
            </View>
          )}
          {unlinkedWarningVisible ? (
            <View style={styles.tileUnlinkedWarning}>
              <Text numberOfLines={1} style={styles.tileUnlinkedWarningText}>
                ⚠️ 未紐付け
              </Text>
            </View>
          ) : null}
          {showTopRow ? (
            <View
              style={[
                styles.tileTopRow,
                topRowMode === "tag" ? styles.tileTopRowTag : null,
              ]}
            >
              <View
                style={[
                  styles.tileTitlePlate,
                  topRowMode === "tag" ? styles.tileTagPlate : null,
                ]}
              >
                <Text numberOfLines={1} style={styles.tileTitlePlateText}>
                  {topRowLabel}
                </Text>
              </View>
              {topRowMode === "title" && item.badge ? (
                <View
                  style={[
                    styles.tileBadge,
                    item.badge === "未紐付け" ? styles.tileBadgeWarn : null,
                  ]}
                >
                  <Text numberOfLines={1} style={styles.tileBadgeText}>
                    {item.badge}
                  </Text>
                </View>
              ) : null}
            </View>
          ) : null}
          {showBottomStrip ? (
            <View style={styles.tileBottomStrip}>
              <Text
                numberOfLines={1}
                style={[styles.tileSubtitle, !tagLine ? styles.tileSubtitleEmpty : null]}
              >
                {tagLine ?? "タグ未設定"}
              </Text>
            </View>
          ) : null}
        </View>
      </Pressable>
    </Animated.View>
  );
}

export function BottomOptionSheet({
  visible,
  title,
  subtitle,
  actions,
  onClose,
  presentation = "native",
  anchor,
  preview,
}: {
  visible: boolean;
  title: string;
  subtitle?: string;
  actions: SheetAction[];
  onClose: () => void;
  presentation?: "native" | "glass" | "quickActions";
  anchor?: SheetAnchor | null;
  preview?: SheetPreview | null;
}) {
  const insets = useSafeAreaInsets();
  const { height, width } = useWindowDimensions();
  const translateY = useRef(new Animated.Value(220)).current;
  const quickActionProgress = useRef(new Animated.Value(0)).current;
  const nativeSheetOpenRef = useRef(false);
  const glassMode = presentation === "glass";
  const quickActionMode = presentation === "quickActions";
  const glassKit = glassMode || quickActionMode ? getIOSGlassKit() : null;
  const useLiquidGlassPopover =
    quickActionMode || (glassMode && (Platform.OS !== "ios" || !!glassKit));
  const quickActions = useMemo(() => orderQuickActions(actions), [actions]);
  const [quickActionVisible, setQuickActionVisible] = useState(visible);
  const [reduceMotion, setReduceMotion] = useState(false);
  const [reduceTransparency, setReduceTransparency] = useState(false);
  const floatingPanelWidth = Math.min(318, width - 28);
  const floatingPanelHeight = actions.length > 2 ? 220 : 158;
  const anchorX = anchor?.pageX ?? width / 2;
  const anchorY = anchor?.pageY ?? height * 0.58;
  const quickMenuWidth = Math.min(286, width - 32);
  const quickRowHeight = 54;
  const quickHasDanger = quickActions.some((action) => action.tone === "danger");
  const quickMenuHeight =
    12 + quickActions.length * quickRowHeight + (quickHasDanger ? 8 : 0);
  const previewWidth = 86;
  const previewHeight = 116;
  const floatingLeft = Math.max(
    14,
    Math.min(width - floatingPanelWidth - 14, anchorX - floatingPanelWidth / 2),
  );
  const preferredTop =
    anchorY > height * 0.52 ? anchorY - floatingPanelHeight - 20 : anchorY + 16;
  const floatingTop = Math.max(
    insets.top + 12,
    Math.min(height - floatingPanelHeight - Math.max(insets.bottom, 12) - 18, preferredTop),
  );
  const quickLeft = clamp(anchorX - quickMenuWidth / 2, 16, width - quickMenuWidth - 16);
  const spaceBelow = height - anchorY - Math.max(insets.bottom, 10);
  const preferredQuickTop =
    spaceBelow > quickMenuHeight + previewHeight * 0.56 + 24
      ? anchorY + previewHeight * 0.48 + 12
      : anchorY - quickMenuHeight - previewHeight * 0.46 - 12;
  const quickTop = clamp(
    preferredQuickTop,
    insets.top + 16,
    height - quickMenuHeight - Math.max(insets.bottom, 12) - 16,
  );
  const previewLeft = clamp(anchorX - previewWidth / 2, 18, width - previewWidth - 18);
  const previewTop = clamp(
    anchorY - previewHeight / 2,
    insets.top + 18,
    height - previewHeight - Math.max(insets.bottom, 12) - 18,
  );
  const popoverScale = translateY.interpolate({
    inputRange: [0, 220],
    outputRange: [1, 0.92],
    extrapolate: "clamp",
  });
  const quickBackdropOpacity = quickActionProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [0, reduceTransparency ? 0.32 : 0.72],
  });
  const quickMenuScale = quickActionProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [reduceMotion ? 1 : 0.94, 1],
  });
  const quickPreviewScale = quickActionProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [reduceMotion ? 1 : 0.96, 1.045],
  });
  const quickMenuTranslateY = quickActionProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [reduceMotion ? 0 : 8, 0],
  });

  useEffect(() => {
    if (Platform.OS !== "ios" || useLiquidGlassPopover) return;
    if (!visible) {
      nativeSheetOpenRef.current = false;
      return;
    }
    if (nativeSheetOpenRef.current) return;

    nativeSheetOpenRef.current = true;
    const cancelButtonIndex = actions.length;
    const destructiveButtonIndex = actions.findIndex(
      (action) => action.tone === "danger",
    );
    ActionSheetIOS.showActionSheetWithOptions(
      {
        title,
        message: subtitle,
        options: [...actions.map((action) => action.label), "閉じる"],
        cancelButtonIndex,
        destructiveButtonIndex:
          destructiveButtonIndex >= 0 ? destructiveButtonIndex : undefined,
        userInterfaceStyle: "light",
        tintColor: megrumColors.lavender,
      },
      (buttonIndex) => {
        nativeSheetOpenRef.current = false;
        if (buttonIndex === cancelButtonIndex) {
          onClose();
          return;
        }
        actions[buttonIndex]?.onPress();
      },
    );
  }, [actions, onClose, subtitle, title, useLiquidGlassPopover, visible]);

  useEffect(() => {
    let mounted = true;
    AccessibilityInfo.isReduceMotionEnabled()
      .then((enabled) => {
        if (mounted) setReduceMotion(enabled);
      })
      .catch(() => undefined);
    const reduceMotionSubscription = AccessibilityInfo.addEventListener(
      "reduceMotionChanged",
      setReduceMotion,
    );

    const accessibilityExtras = AccessibilityInfo as typeof AccessibilityInfo & {
      isReduceTransparencyEnabled?: () => Promise<boolean>;
      addEventListener?: (
        eventName: "reduceTransparencyChanged",
        handler: (enabled: boolean) => void,
      ) => { remove: () => void };
    };
    accessibilityExtras.isReduceTransparencyEnabled?.()
      .then((enabled) => {
        if (mounted) setReduceTransparency(enabled);
      })
      .catch(() => undefined);
    const reduceTransparencySubscription = accessibilityExtras.addEventListener?.(
      "reduceTransparencyChanged",
      setReduceTransparency,
    );

    return () => {
      mounted = false;
      reduceMotionSubscription.remove();
      reduceTransparencySubscription?.remove();
    };
  }, []);

  useEffect(() => {
    Animated.spring(translateY, {
      toValue: visible ? 0 : glassMode ? 18 : 220,
      damping: 22,
      stiffness: 190,
      mass: 0.78,
      useNativeDriver: true,
    }).start();
  }, [translateY, visible]);

  useEffect(() => {
    if (!quickActionMode) return;
    if (visible) {
      setQuickActionVisible(true);
      quickActionProgress.setValue(0);
      Animated.spring(quickActionProgress, {
        toValue: 1,
        damping: reduceMotion ? 30 : 21,
        stiffness: reduceMotion ? 260 : 230,
        mass: 0.74,
        useNativeDriver: true,
      }).start();
      return;
    }

    Animated.timing(quickActionProgress, {
      toValue: 0,
      duration: reduceMotion ? 80 : 150,
      easing: Easing.out(Easing.cubic),
      useNativeDriver: true,
    }).start(({ finished }) => {
      if (finished) setQuickActionVisible(false);
    });
  }, [quickActionMode, quickActionProgress, reduceMotion, visible]);

  if (Platform.OS === "ios" && !useLiquidGlassPopover) return null;
  if (quickActionMode && !quickActionVisible) return null;

  return (
    <Modal
      visible={quickActionMode ? quickActionVisible : visible}
      transparent
      animationType={glassMode || quickActionMode ? "none" : "fade"}
      onRequestClose={onClose}
    >
      <View
        style={[
          styles.sheetRoot,
          glassMode ? styles.glassPopoverRoot : null,
          quickActionMode ? styles.quickActionRoot : null,
        ]}
      >
        {quickActionMode ? (
          <>
            <Animated.View
              pointerEvents="none"
              style={[styles.quickActionBackdropMaterial, { opacity: quickBackdropOpacity }]}
            >
              {reduceTransparency ? (
                <View style={styles.quickActionOpaqueBackdrop} />
              ) : (
                <BlurView
                  intensity={24}
                  style={StyleSheet.absoluteFill}
                  tint="systemThinMaterialLight"
                />
              )}
              <View style={styles.quickActionBackdropTint} />
            </Animated.View>
            <Pressable style={styles.sheetBackdrop} onPress={onClose} />
            <Animated.View
              pointerEvents="none"
              style={[
                styles.quickActionLiftedPreview,
                {
                  left: previewLeft,
                  opacity: quickActionProgress,
                  top: previewTop,
                  transform: [{ scale: quickPreviewScale }],
                  width: previewWidth,
                },
              ]}
            >
              <QuickActionPreviewCard preview={preview} title={title} />
            </Animated.View>
            <Animated.View
              style={[
                styles.quickActionMenuPanel,
                {
                  left: quickLeft,
                  opacity: quickActionProgress,
                  top: quickTop,
                  transform: [{ translateY: quickMenuTranslateY }, { scale: quickMenuScale }],
                  width: quickMenuWidth,
                },
              ]}
            >
              <QuickActionMenu
                actions={quickActions}
                glassKit={glassKit}
                onActionPress={(action) => {
                  Vibration.vibrate(5);
                  onClose();
                  setTimeout(action.onPress, reduceMotion ? 45 : 120);
                }}
                reduceTransparency={reduceTransparency}
              />
            </Animated.View>
          </>
        ) : (
          <>
            <Pressable
              style={[styles.sheetBackdrop, glassMode ? styles.glassPopoverBackdrop : null]}
              onPress={onClose}
            />
            <Animated.View
              style={[
                glassMode
                  ? [
                      styles.glassPopoverPanel,
                      {
                        left: floatingLeft,
                        top: floatingTop,
                        width: floatingPanelWidth,
                        transform: [{ translateY }, { scale: popoverScale }],
                      },
                    ]
                  : [
                      styles.sheetPanel,
                      {
                        paddingBottom: Math.max(insets.bottom, 12) + 10,
                        transform: [{ translateY }],
                      },
                    ],
              ]}
            >
              {glassMode ? (
                <GlassActionPopover
                  actions={actions}
                  glassKit={glassKit}
                  preview={preview}
                  subtitle={subtitle}
                  title={title}
                />
              ) : (
                <>
                  <View style={styles.sheetHandle} />
                  <Text style={styles.sheetTitle}>{title}</Text>
                  {subtitle ? (
                    <Text numberOfLines={2} style={styles.sheetSubtitle}>
                      {subtitle}
                    </Text>
                  ) : null}
                  <View style={styles.sheetActions}>
                    {actions.map((action) => (
                      <Pressable
                        key={action.id}
                        onPress={action.onPress}
                        style={[
                          styles.sheetAction,
                          action.tone === "danger"
                            ? styles.sheetActionDanger
                            : action.tone === "muted"
                              ? styles.sheetActionMuted
                              : styles.sheetActionDefault,
                        ]}
                      >
                        <Text
                          style={[
                            styles.sheetActionText,
                            action.tone === "danger"
                              ? styles.sheetActionTextDanger
                              : action.tone === "muted"
                                ? styles.sheetActionTextMuted
                                : styles.sheetActionTextDefault,
                          ]}
                        >
                          {action.label}
                        </Text>
                      </Pressable>
                    ))}
                  </View>
                </>
              )}
            </Animated.View>
          </>
        )}
      </View>
    </Modal>
  );
}

function QuickActionMenu({
  actions,
  glassKit,
  onActionPress,
  reduceTransparency,
}: {
  actions: SheetAction[];
  glassKit: IOSGlassKit | null;
  onActionPress: (action: SheetAction) => void;
  reduceTransparency: boolean;
}) {
  return (
    <QuickActionSurface glassKit={glassKit} reduceTransparency={reduceTransparency}>
      <View style={styles.quickActionInnerHighlight} pointerEvents="none" />
      {actions.map((action, index) => {
        const previous = actions[index - 1];
        const next = actions[index + 1];
        const startsDangerGroup = action.tone === "danger" && previous?.tone !== "danger";
        const showSeparator = !!next && next.tone === action.tone;

        return (
          <View key={action.id}>
            {startsDangerGroup ? <View style={styles.quickActionGroupGap} /> : null}
            <Pressable
              accessibilityLabel={action.label}
              accessibilityRole="button"
              onPress={() => onActionPress(action)}
              style={({ pressed }) => [
                styles.quickActionRow,
                pressed ? styles.quickActionRowPressed : null,
              ]}
            >
              <Text
                numberOfLines={2}
                style={[
                  styles.quickActionLabel,
                  action.tone === "danger"
                    ? styles.quickActionLabelDanger
                    : action.tone === "muted"
                      ? styles.quickActionLabelMuted
                      : null,
                ]}
              >
                {action.label}
              </Text>
              <IconSymbol
                color={
                  action.tone === "danger"
                    ? megrumColors.warn
                    : action.tone === "muted"
                      ? megrumColors.mutedInk
                      : megrumColors.ink
                }
                name={actionIconName(action)}
                size={18}
                style={styles.quickActionIcon}
              />
            </Pressable>
            {showSeparator ? <View style={styles.quickActionSeparator} /> : null}
          </View>
        );
      })}
    </QuickActionSurface>
  );
}

function QuickActionSurface({
  children,
  glassKit,
  reduceTransparency,
}: {
  children: ReactNode;
  glassKit: IOSGlassKit | null;
  reduceTransparency: boolean;
}) {
  const GlassView = reduceTransparency ? null : glassKit?.GlassView;
  if (GlassView) {
    return (
      <GlassView
        colorScheme="light"
        glassEffectStyle={{
          style: "regular",
          animate: true,
          animationDuration: 0.2,
        }}
        isInteractive={false}
        style={styles.quickActionSurface}
        tintColor="rgba(255,255,255,0.34)"
      >
        {children}
      </GlassView>
    );
  }

  if (Platform.OS === "ios" && !reduceTransparency) {
    return (
      <BlurView
        intensity={62}
        style={[styles.quickActionSurface, styles.quickActionSurfaceBlurFallback]}
        tint="systemThinMaterialLight"
      >
        {children}
      </BlurView>
    );
  }

  return (
    <View style={[styles.quickActionSurface, styles.quickActionSurfaceOpaque]}>
      {children}
    </View>
  );
}

function QuickActionPreviewCard({
  preview,
  title,
}: {
  preview?: SheetPreview | null;
  title: string;
}) {
  return (
    <View style={styles.quickActionPreviewCard}>
      {preview?.photoUrl ? (
        <Image
          source={{ uri: preview.photoUrl }}
          resizeMode="cover"
          style={styles.quickActionPreviewImage}
        />
      ) : (
        <View
          style={[
            styles.quickActionPreviewFallback,
            { backgroundColor: preview?.hue ?? "rgba(166,149,216,0.26)" },
          ]}
        >
          <Text style={styles.quickActionPreviewGlyph}>
            {preview?.glyph || title.slice(0, 1) || "?"}
          </Text>
        </View>
      )}
      <View style={styles.quickActionPreviewPlate}>
        <Text numberOfLines={1} style={styles.quickActionPreviewTitle}>
          {title}
        </Text>
      </View>
    </View>
  );
}

function GlassActionPopover({
  actions,
  glassKit,
  preview,
  subtitle,
  title,
}: {
  actions: SheetAction[];
  glassKit: IOSGlassKit | null;
  preview?: SheetPreview | null;
  subtitle?: string;
  title: string;
}) {
  const Container = glassKit?.GlassContainer ?? View;

  return (
    <Container spacing={8} style={styles.glassPopoverContainer}>
      <LiquidGlassSurface
        glassKit={glassKit}
        isInteractive={false}
        style={styles.glassPopoverPreviewSurface}
      >
        <View style={styles.glassPopoverPreview}>
          <GoodsPreviewMedia preview={preview} title={title} />
          <View style={styles.glassPopoverCopy}>
            <Text numberOfLines={1} style={styles.glassPopoverTitle}>
              {title}
            </Text>
            {subtitle ? (
              <Text numberOfLines={2} style={styles.glassPopoverSubtitle}>
                {subtitle}
              </Text>
            ) : null}
          </View>
        </View>
      </LiquidGlassSurface>
      <View style={styles.glassFloatingActions}>
        {actions.map((action) => (
          <Pressable
            accessibilityRole="button"
            key={action.id}
            onPress={action.onPress}
            style={({ pressed }) => [
              styles.glassFloatingActionPressable,
              pressed ? styles.glassFloatingActionPressed : null,
            ]}
          >
            <LiquidGlassSurface
              glassKit={glassKit}
              style={[
                styles.glassFloatingActionSurface,
                action.tone === "danger"
                  ? styles.glassFloatingActionSurfaceDanger
                  : null,
              ]}
              tintColor={
                action.tone === "danger"
                  ? "rgba(255,236,232,0.38)"
                  : "rgba(255,255,255,0.30)"
              }
            >
              <IconSymbol
                color={
                  action.tone === "danger"
                    ? megrumColors.warn
                    : action.tone === "muted"
                      ? megrumColors.mutedInk
                      : megrumColors.ink
                }
                name={actionIconName(action)}
                size={19}
              />
              <Text
                numberOfLines={1}
                style={[
                  styles.glassFloatingActionText,
                  action.tone === "danger"
                    ? styles.glassFloatingActionTextDanger
                    : action.tone === "muted"
                      ? styles.glassFloatingActionTextMuted
                      : null,
                ]}
              >
                {action.label}
              </Text>
            </LiquidGlassSurface>
          </Pressable>
        ))}
      </View>
    </Container>
  );
}

function GoodsPreviewMedia({
  preview,
  title,
}: {
  preview?: SheetPreview | null;
  title: string;
}) {
  if (preview?.photoUrl) {
    return (
      <Image
        source={{ uri: preview.photoUrl }}
        resizeMode="cover"
        style={styles.glassPopoverPreviewImage}
      />
    );
  }

  return (
    <View
      style={[
        styles.glassPopoverPreviewOrb,
        { backgroundColor: preview?.hue ?? "rgba(166,149,216,0.24)" },
      ]}
    >
      <Text style={styles.glassPopoverPreviewText}>
        {preview?.glyph || title.slice(0, 1) || "?"}
      </Text>
    </View>
  );
}

function LiquidGlassSurface({
  children,
  glassKit,
  isInteractive = true,
  style,
  tintColor = "rgba(255,255,255,0.28)",
}: {
  children: ReactNode;
  glassKit: IOSGlassKit | null;
  isInteractive?: boolean;
  style: StyleProp<ViewStyle>;
  tintColor?: string;
}) {
  const GlassView = glassKit?.GlassView;
  if (GlassView) {
    return (
      <GlassView
        colorScheme="light"
        glassEffectStyle={{
          style: "regular",
          animate: true,
          animationDuration: 0.22,
        }}
        isInteractive={isInteractive}
        style={style}
        tintColor={tintColor}
      >
        {children}
      </GlassView>
    );
  }
  return <View style={[style, styles.nonIOSPopoverSurface]}>{children}</View>;
}

function actionIconName(action: SheetAction): IconSymbolName {
  if (action.label.includes("詳細")) return "search-outline";
  if (action.id.includes("edit")) return "create-outline";
  if (action.id.includes("move")) return "arrow-forward";
  if (action.id.includes("delete")) return "warning-outline";
  if (action.id.includes("close")) return "close";
  return "ellipsis-horizontal";
}

function orderQuickActions(actions: SheetAction[]) {
  const regular = actions.filter((action) => action.tone !== "danger");
  const danger = actions.filter((action) => action.tone === "danger");
  return [...regular, ...danger];
}

function clamp(value: number, min: number, max: number) {
  if (max < min) return min;
  return Math.max(min, Math.min(max, value));
}

export function FloatingAddButton({
  align = "right",
  label,
  onPress,
}: {
  align?: "left" | "right";
  label: string;
  onPress: () => void;
}) {
  const insets = useSafeAreaInsets();

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={[
        styles.floatingAdd,
        {
          bottom: Math.max(insets.bottom, 10) + 92,
          left: align === "left" ? 20 : undefined,
          right: align === "right" ? 20 : undefined,
        },
      ]}
    >
      <Text style={styles.floatingAddText}>+</Text>
    </Pressable>
  );
}

export function FilterChips({
  chips,
}: {
  chips: { id: string; label: string; active?: boolean }[];
}) {
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.filterChips}
    >
      {chips.map((chip) => (
        <View
          key={chip.id}
          style={[
            styles.filterChip,
            chip.active ? styles.filterChipActive : null,
          ]}
        >
          <Text
            style={[
              styles.filterChipText,
              chip.active ? styles.filterChipTextActive : null,
            ]}
          >
            {chip.label}
          </Text>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  columnSwitcher: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.62)",
    borderColor: "rgba(255,255,255,0.84)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 34,
    justifyContent: "center",
    minWidth: 46,
    paddingHorizontal: 9,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.07,
    shadowRadius: 14,
  },
  columnSwitcherPressed: {
    opacity: 0.78,
    transform: [{ scale: 0.96 }],
  },
  columnIconRow: {
    flexDirection: "row",
    gap: 3,
  },
  columnIconCell: {
    backgroundColor: megrumColors.lavender,
    borderRadius: 2.5,
    height: 9,
    width: 9,
  },
  sectionTabs: {
    backgroundColor: "rgba(255,255,255,0.58)",
    borderColor: "rgba(255,255,255,0.8)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    flexDirection: "row",
    padding: 4,
    position: "relative",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.08,
    shadowRadius: 18,
  },
  sectionTabThumb: {
    backgroundColor: "rgba(255,255,255,0.92)",
    borderColor: "rgba(255,255,255,0.92)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    bottom: 4,
    left: 4,
    position: "absolute",
    top: 4,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 5 },
    shadowOpacity: 0.13,
    shadowRadius: 12,
  },
  sectionTab: {
    alignItems: "center",
    borderRadius: megrumRadii.pill,
    flex: 1,
    flexDirection: "row",
    gap: 4,
    justifyContent: "center",
    minHeight: 36,
    paddingHorizontal: 5,
    paddingVertical: 8,
    zIndex: 1,
  },
  sectionTabActive: {
    backgroundColor: "transparent",
  },
  sectionTabLabel: {
    fontSize: 11.5,
    fontWeight: "900",
  },
  sectionTabLabelActive: {
    color: megrumColors.ink,
  },
  sectionTabLabelInactive: {
    color: "rgba(58,50,74,0.55)",
  },
  sectionTabCount: {
    fontSize: 10,
    fontWeight: "900",
  },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    paddingBottom: 18,
  },
  addTile: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.54)",
    borderRadius: 13,
    borderStyle: "dashed",
    borderWidth: 1.5,
    justifyContent: "center",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 3, height: 6 },
    shadowOpacity: 0.06,
    shadowRadius: 9,
  },
  addTilePlus: {
    color: megrumColors.lavender,
    fontSize: 27,
    fontWeight: "800",
    lineHeight: 31,
  },
  addTileText: {
    color: megrumColors.lavender,
    fontSize: 10,
    fontWeight: "900",
    marginTop: 2,
  },
  emptyBox: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: megrumRadii.lg,
    borderStyle: "dashed",
    borderWidth: 1,
    justifyContent: "center",
    minHeight: 170,
    padding: 18,
  },
  emptyText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  tilePressable: {
    borderRadius: 13,
  },
  tileImage: {
    backgroundColor: "rgba(58,50,74,0.05)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 13,
    borderWidth: 1,
    overflow: "hidden",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 3, height: 6 },
    shadowOpacity: 0.08,
    shadowRadius: 9,
  },
  tileImageUnlinked: {
    borderColor: "#e0a847",
    borderWidth: 2,
    shadowColor: "#e0a847",
    shadowOpacity: 0.2,
  },
  tileImageFill: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  tilePhoto: {
    height: "100%",
    width: "100%",
  },
  tileShine: {
    backgroundColor: "rgba(255,255,255,0.26)",
    borderRadius: 999,
    height: 58,
    position: "absolute",
    right: -17,
    top: -12,
    width: 58,
  },
  tileGlyph: {
    color: megrumColors.surface,
    fontSize: 32,
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.16)",
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 5,
  },
  tileTopRow: {
    alignItems: "flex-start",
    flexDirection: "row",
    gap: 4,
    left: 6,
    position: "absolute",
    right: 6,
    top: 6,
  },
  tileTopRowTag: {
    justifyContent: "flex-end",
  },
  tileTitlePlate: {
    backgroundColor: "rgba(255,255,255,0.86)",
    borderRadius: 6,
    flex: 1,
    minWidth: 0,
    paddingHorizontal: 6,
    paddingVertical: 3,
  },
  tileTagPlate: {
    flex: 0,
    maxWidth: "78%",
  },
  tileTitlePlateText: {
    color: megrumColors.ink,
    fontSize: 9,
    fontWeight: "900",
  },
  tileBadge: {
    backgroundColor: megrumColors.lavender,
    borderRadius: 6,
    flexShrink: 0,
    maxWidth: "50%",
    paddingHorizontal: 6,
    paddingVertical: 3,
  },
  tileBadgeWarn: {
    backgroundColor: megrumColors.warn,
  },
  tileBadgeText: {
    color: megrumColors.surface,
    fontSize: 8.5,
    fontWeight: "900",
  },
  tileUnlinkedWarning: {
    backgroundColor: "rgba(255,246,210,0.96)",
    borderColor: "rgba(224,168,71,0.58)",
    borderRadius: 7,
    borderWidth: 1,
    left: 6,
    maxWidth: "86%",
    paddingHorizontal: 6,
    paddingVertical: 3,
    position: "absolute",
    top: 6,
  },
  tileUnlinkedWarningText: {
    color: "#815900",
    fontSize: 8.5,
    fontWeight: "900",
  },
  tileBottomStrip: {
    backgroundColor: "rgba(255,255,255,0.92)",
    bottom: 0,
    left: 0,
    paddingHorizontal: 7,
    paddingBottom: 6,
    paddingTop: 14,
    position: "absolute",
    right: 0,
  },
  tileSubtitle: {
    color: megrumColors.ink,
    fontSize: 9.5,
    fontWeight: "900",
  },
  tileSubtitleEmpty: {
    color: "rgba(58,50,74,0.42)",
  },
  sheetRoot: {
    backgroundColor: "rgba(20,16,29,0.36)",
    flex: 1,
    justifyContent: "flex-end",
  },
  sheetBackdrop: {
    bottom: 0,
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
  },
  glassPopoverRoot: {
    backgroundColor: "transparent",
    justifyContent: "flex-start",
  },
  glassPopoverBackdrop: {
    backgroundColor: "transparent",
  },
  quickActionRoot: {
    backgroundColor: "transparent",
    justifyContent: "flex-start",
  },
  quickActionBackdropMaterial: {
    ...StyleSheet.absoluteFillObject,
  },
  quickActionOpaqueBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(251,249,252,0.94)",
  },
  quickActionBackdropTint: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(18,14,29,0.18)",
  },
  quickActionLiftedPreview: {
    position: "absolute",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 16 },
    shadowOpacity: 0.22,
    shadowRadius: 26,
  },
  quickActionPreviewCard: {
    backgroundColor: "rgba(255,255,255,0.86)",
    borderColor: "rgba(255,255,255,0.78)",
    borderRadius: 18,
    borderWidth: 1,
    height: 116,
    overflow: "hidden",
  },
  quickActionPreviewImage: {
    flex: 1,
    width: "100%",
  },
  quickActionPreviewFallback: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  quickActionPreviewGlyph: {
    color: megrumColors.surface,
    fontSize: 30,
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.20)",
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 5,
  },
  quickActionPreviewPlate: {
    backgroundColor: "rgba(255,255,255,0.94)",
    bottom: 0,
    left: 0,
    paddingHorizontal: 7,
    paddingVertical: 5,
    position: "absolute",
    right: 0,
  },
  quickActionPreviewTitle: {
    color: megrumColors.ink,
    fontSize: 10,
    fontWeight: "900",
    lineHeight: 13,
  },
  quickActionMenuPanel: {
    position: "absolute",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 19 },
    shadowOpacity: 0.2,
    shadowRadius: 34,
  },
  quickActionSurface: {
    borderColor: "rgba(255,255,255,0.64)",
    borderRadius: 25,
    borderWidth: 1,
    overflow: "hidden",
    paddingVertical: 6,
    position: "relative",
  },
  quickActionSurfaceBlurFallback: {
    backgroundColor: "rgba(255,255,255,0.46)",
  },
  quickActionSurfaceOpaque: {
    backgroundColor: "rgba(255,255,255,0.98)",
  },
  quickActionInnerHighlight: {
    borderColor: "rgba(255,255,255,0.52)",
    borderRadius: 24,
    borderWidth: 1,
    bottom: 1,
    left: 1,
    position: "absolute",
    right: 1,
    top: 1,
  },
  quickActionRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 14,
    justifyContent: "space-between",
    minHeight: 54,
    paddingHorizontal: 17,
    paddingVertical: 11,
  },
  quickActionRowPressed: {
    backgroundColor: "rgba(166,149,216,0.14)",
  },
  quickActionLabel: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 15,
    fontWeight: "800",
    lineHeight: 20,
  },
  quickActionLabelDanger: {
    color: megrumColors.warn,
  },
  quickActionLabelMuted: {
    color: megrumColors.mutedInk,
  },
  quickActionIcon: {
    minWidth: 20,
  },
  quickActionSeparator: {
    backgroundColor: "rgba(58,50,74,0.10)",
    height: StyleSheet.hairlineWidth,
    marginLeft: 17,
  },
  quickActionGroupGap: {
    backgroundColor: "rgba(58,50,74,0.08)",
    height: 8,
    marginVertical: 2,
  },
  glassPopoverPanel: {
    position: "absolute",
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 18 },
    shadowOpacity: 0.18,
    shadowRadius: 30,
  },
  glassPopoverContainer: {
    gap: 8,
  },
  glassPopoverPreviewSurface: {
    borderRadius: 24,
    minHeight: 74,
    overflow: "hidden",
    paddingHorizontal: 10,
    paddingVertical: 10,
  },
  nonIOSPopoverSurface: {
    backgroundColor: "rgba(255,255,255,0.96)",
  },
  glassPopoverPreview: {
    alignItems: "center",
    flexDirection: "row",
    gap: 10,
  },
  glassPopoverPreviewImage: {
    borderRadius: 17,
    height: 54,
    width: 43,
  },
  glassPopoverPreviewOrb: {
    alignItems: "center",
    borderColor: "rgba(255,255,255,0.62)",
    borderRadius: 17,
    borderWidth: 1,
    height: 54,
    justifyContent: "center",
    width: 43,
  },
  glassPopoverPreviewText: {
    color: megrumColors.surface,
    fontSize: 17,
    fontWeight: "900",
    textShadowColor: "rgba(58,50,74,0.22)",
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 4,
  },
  glassPopoverCopy: {
    flex: 1,
    minWidth: 0,
  },
  glassPopoverTitle: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
    lineHeight: 18,
  },
  glassPopoverSubtitle: {
    color: "rgba(58,50,74,0.62)",
    fontSize: 10.5,
    fontWeight: "700",
    lineHeight: 15,
    marginTop: 2,
  },
  glassFloatingActions: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  glassFloatingActionPressable: {
    flexBasis: "23%",
    flexGrow: 1,
    minWidth: 68,
  },
  glassFloatingActionPressed: {
    transform: [{ scale: 0.96 }],
  },
  glassFloatingActionSurface: {
    alignItems: "center",
    borderRadius: 22,
    gap: 4,
    minHeight: 72,
    overflow: "hidden",
    paddingHorizontal: 8,
    paddingVertical: 10,
  },
  glassFloatingActionSurfaceDanger: {
    borderColor: "rgba(217,130,107,0.18)",
    borderWidth: 1,
  },
  glassFloatingActionText: {
    color: megrumColors.ink,
    fontSize: 9.5,
    fontWeight: "800",
    lineHeight: 13,
    textAlign: "center",
  },
  glassFloatingActionTextDanger: {
    color: megrumColors.warn,
  },
  glassFloatingActionTextMuted: {
    color: megrumColors.mutedInk,
  },
  glassSheetRoot: {
    backgroundColor: "rgba(20,16,29,0.12)",
    justifyContent: "flex-end",
  },
  glassSheetBackdrop: {
    backgroundColor: "rgba(12,10,18,0.10)",
  },
  sheetPanel: {
    backgroundColor: "rgba(255,255,255,0.96)",
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingHorizontal: 18,
    paddingTop: 10,
  },
  glassSheetPanel: {
    paddingHorizontal: 14,
    paddingTop: 0,
  },
  glassSheetSurface: {
    borderColor: "rgba(255,255,255,0.58)",
    borderRadius: 30,
    borderWidth: 1,
    overflow: "hidden",
    paddingHorizontal: 14,
    paddingTop: 10,
    shadowColor: megrumColors.ink,
    shadowOffset: { width: 0, height: 18 },
    shadowOpacity: 0.18,
    shadowRadius: 30,
  },
  glassFallbackSurface: {
    backgroundColor: "rgba(255,255,255,0.58)",
  },
  glassSheetHandle: {
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.16)",
    borderRadius: 999,
    height: 4,
    marginBottom: 12,
    width: 42,
  },
  glassSheetHeader: {
    alignItems: "center",
    flexDirection: "row",
    gap: 11,
    paddingBottom: 12,
  },
  glassSheetPreviewOrb: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.18)",
    borderColor: "rgba(255,255,255,0.74)",
    borderRadius: 18,
    borderWidth: 1,
    height: 44,
    justifyContent: "center",
    width: 44,
  },
  glassSheetPreviewText: {
    color: megrumColors.lavender,
    fontSize: 16,
    fontWeight: "900",
  },
  glassSheetTitleCopy: {
    flex: 1,
    minWidth: 0,
  },
  glassSheetTitle: {
    color: megrumColors.ink,
    fontSize: 15,
    fontWeight: "900",
  },
  glassSheetSubtitle: {
    color: "rgba(58,50,74,0.62)",
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 16,
    marginTop: 2,
  },
  glassActionGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 9,
    paddingBottom: 2,
  },
  glassActionButton: {
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.50)",
    borderColor: "rgba(255,255,255,0.64)",
    borderRadius: 18,
    borderWidth: 1,
    flexBasis: "48%",
    flexDirection: "row",
    gap: 9,
    minHeight: 54,
    paddingHorizontal: 11,
  },
  glassActionButtonDanger: {
    backgroundColor: "rgba(255,246,242,0.54)",
    borderColor: "rgba(217,130,107,0.20)",
  },
  glassActionButtonMuted: {
    backgroundColor: "rgba(255,255,255,0.34)",
  },
  glassActionButtonPressed: {
    opacity: 0.78,
    transform: [{ scale: 0.98 }],
  },
  glassActionIcon: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.16)",
    borderRadius: 13,
    height: 30,
    justifyContent: "center",
    width: 30,
  },
  glassActionIconDanger: {
    backgroundColor: "rgba(217,130,107,0.14)",
  },
  glassActionIconMuted: {
    backgroundColor: "rgba(58,50,74,0.08)",
  },
  glassActionText: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 12,
    fontWeight: "900",
  },
  glassActionTextDanger: {
    color: megrumColors.warn,
  },
  glassActionTextMuted: {
    color: megrumColors.mutedInk,
  },
  sheetHandle: {
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.18)",
    borderRadius: 999,
    height: 4,
    marginBottom: 14,
    width: 42,
  },
  sheetTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
  },
  sheetSubtitle: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "700",
    lineHeight: 17,
    marginTop: 4,
  },
  sheetActions: {
    gap: 8,
    marginTop: 14,
  },
  sheetAction: {
    alignItems: "center",
    borderRadius: 15,
    paddingVertical: 14,
  },
  sheetActionDefault: {
    backgroundColor: "rgba(166,149,216,0.14)",
  },
  sheetActionDanger: {
    backgroundColor: "rgba(217,130,107,0.12)",
  },
  sheetActionMuted: {
    backgroundColor: "rgba(58,50,74,0.06)",
  },
  sheetActionText: {
    fontSize: 14,
    fontWeight: "900",
  },
  sheetActionTextDefault: {
    color: megrumColors.lavender,
  },
  sheetActionTextDanger: {
    color: megrumColors.warn,
  },
  sheetActionTextMuted: {
    color: megrumColors.ink,
  },
  floatingAdd: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderColor: "rgba(255,255,255,0.92)",
    borderRadius: 30,
    borderWidth: 1,
    height: 58,
    justifyContent: "center",
    position: "absolute",
    shadowColor: megrumColors.lavender,
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.32,
    shadowRadius: 22,
    width: 58,
  },
  floatingAddText: {
    color: megrumColors.surface,
    fontSize: 30,
    fontWeight: "700",
    lineHeight: 34,
  },
  filterChips: {
    gap: 7,
    paddingRight: 18,
  },
  filterChip: {
    backgroundColor: "rgba(58,50,74,0.05)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  filterChipActive: {
    backgroundColor: "rgba(166,149,216,0.14)",
    borderColor: "rgba(166,149,216,0.34)",
  },
  filterChipText: {
    color: "rgba(58,50,74,0.58)",
    fontSize: 10.5,
    fontWeight: "900",
  },
  filterChipTextActive: {
    color: megrumColors.lavender,
  },
});
