import { useEffect, useMemo, useState } from "react";
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { IconSymbol } from "../src/components/IconSymbol";
import { MeguriAvatarFace } from "../src/components/meguri/MeguriAvatarFace";
import { megrumColors, megrumShadow } from "../src/theme/tokens";
import {
  DEFAULT_MEGURI_AVATAR,
  loadMeguriAvatarSettings,
  saveMeguriAvatarSettings,
  type MeguriAvatarSettings,
} from "../src/lib/meguriSettings";

const ANIMALS: Array<{ id: MeguriAvatarSettings["animalType"]; label: string }> = [
  { id: "cat", label: "ねこ" },
  { id: "fox", label: "きつね" },
  { id: "rabbit", label: "うさぎ" },
];

const FURS: Array<{ id: MeguriAvatarSettings["furColor"]; label: string; color: string; hue: MeguriAvatarSettings["hue"] }> = [
  { id: "lavender", label: "ラベンダー", color: "#b8a9e6", hue: "lav" },
  { id: "sky", label: "スカイ", color: "#a9d9ed", hue: "sky" },
  { id: "pink", label: "ピンク", color: "#f2b8cb", hue: "pink" },
  { id: "mint", label: "ミント", color: "#a7d9c7", hue: "mint" },
  { id: "cream", label: "クリーム", color: "#f0dfbd", hue: "butter" },
  { id: "cocoa", label: "ココア", color: "#b78b70", hue: "butter" },
  { id: "gray", label: "グレー", color: "#bfc3cb", hue: "sky" },
];

export default function MeguriAvatarEditScreen() {
  const insets = useSafeAreaInsets();
  const [settings, setSettings] = useState<MeguriAvatarSettings | null>(null);
  const selectedAnimalLabel = useMemo(
    () => ANIMALS.find((animal) => animal.id === settings?.animalType)?.label ?? "アバター",
    [settings?.animalType],
  );
  const selectedFurLabel = useMemo(
    () => FURS.find((fur) => fur.id === settings?.furColor)?.label ?? "",
    [settings?.furColor],
  );

  useEffect(() => {
    loadMeguriAvatarSettings().then(setSettings).catch(() => setSettings(DEFAULT_MEGURI_AVATAR));
  }, []);

  function chooseFur(fur: (typeof FURS)[number]) {
    setSettings((current) => current ? ({ ...current, furColor: fur.id, hue: fur.hue }) : current);
  }

  async function save() {
    if (!settings) return;
    await saveMeguriAvatarSettings(settings);
    router.back();
  }

  return (
    <View style={styles.root}>
      <ScrollView
        contentContainerStyle={[
          styles.content,
          { paddingTop: Math.max(insets.top, 12) + 12, paddingBottom: Math.max(insets.bottom, 12) + 24 },
        ]}
      >
        <View style={styles.header}>
          <Pressable onPress={() => router.back()} style={styles.roundButton}>
            <IconSymbol name="chevron-back" color={megrumColors.ink} size={20} />
          </Pressable>
          <Text style={styles.headerTitle}>アバター編集</Text>
          <Pressable onPress={save} style={styles.saveButton}>
            <Text style={styles.saveText}>保存</Text>
          </Pressable>
        </View>

        <View style={styles.preview}>
          {!settings ? (
            <ActivityIndicator color={megrumColors.lavender} />
          ) : (
            <View style={styles.previewInner}>
              <View style={styles.previewHalo} />
              <MeguriAvatarFace
                animalType={settings.animalType}
                furColor={settings.furColor}
                hue={settings.hue}
                size={160}
              />
              <Text style={styles.previewLabel}>{selectedAnimalLabel}</Text>
              <Text style={styles.previewMeta}>{selectedFurLabel}</Text>
            </View>
          )}
        </View>

        <Text style={styles.sectionTitle}>どうぶつ</Text>
        <View style={styles.segmentRow}>
          {ANIMALS.map((animal) => (
            <Pressable
              key={animal.id}
              disabled={!settings}
              onPress={() => setSettings((current) => current ? ({ ...current, animalType: animal.id }) : current)}
              style={[styles.segment, settings?.animalType === animal.id ? styles.segmentActive : null]}
            >
              <Text style={[styles.segmentText, settings?.animalType === animal.id ? styles.segmentTextActive : null]}>
                {animal.label}
              </Text>
            </Pressable>
          ))}
        </View>

        <Text style={styles.sectionTitle}>毛色</Text>
        <View style={styles.swatchGrid}>
          {FURS.map((fur) => (
            <Pressable
              key={fur.id}
              disabled={!settings}
              onPress={() => chooseFur(fur)}
              style={[styles.swatchItem, settings?.furColor === fur.id ? styles.swatchItemActive : null]}
            >
              <View style={[styles.swatch, { backgroundColor: fur.color }]} />
              <Text style={styles.swatchLabel}>{fur.label}</Text>
            </Pressable>
          ))}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    backgroundColor: megrumColors.background,
    flex: 1,
  },
  content: {
    gap: 15,
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
    borderRadius: 999,
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  headerTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  saveButton: {
    backgroundColor: megrumColors.ink,
    borderRadius: 999,
    paddingHorizontal: 15,
    paddingVertical: 10,
  },
  saveText: {
    color: "#fff",
    fontSize: 12,
    fontWeight: "900",
  },
  preview: {
    alignItems: "center",
    backgroundColor: "#c9f1ff",
    borderRadius: 28,
    height: 310,
    justifyContent: "center",
    overflow: "hidden",
    ...megrumShadow,
  },
  previewInner: {
    alignItems: "center",
    gap: 6,
  },
  previewHalo: {
    backgroundColor: "rgba(255,255,255,0.42)",
    borderRadius: 999,
    height: 188,
    position: "absolute",
    width: 188,
  },
  previewLabel: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
    marginTop: 14,
  },
  previewMeta: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
  sectionTitle: {
    color: megrumColors.ink,
    fontSize: 16,
    fontWeight: "900",
    paddingHorizontal: 4,
  },
  segmentRow: {
    flexDirection: "row",
    gap: 8,
  },
  segment: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderRadius: 999,
    flex: 1,
    paddingVertical: 12,
  },
  segmentActive: {
    backgroundColor: megrumColors.ink,
  },
  segmentText: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  segmentTextActive: {
    color: "#fff",
  },
  swatchGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 9,
  },
  swatchItem: {
    alignItems: "center",
    backgroundColor: "#fff",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1,
    gap: 6,
    padding: 10,
    width: "31.7%",
  },
  swatchItemActive: {
    borderColor: megrumColors.lavender,
    borderWidth: 2,
  },
  swatch: {
    borderColor: "#fff",
    borderRadius: 999,
    borderWidth: 2,
    height: 36,
    width: 36,
  },
  swatchLabel: {
    color: megrumColors.ink,
    fontSize: 10.5,
    fontWeight: "900",
  },
});
