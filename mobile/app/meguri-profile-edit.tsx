import { useEffect, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import { router } from "expo-router";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { IconSymbol } from "../src/components/IconSymbol";
import { megrumColors, megrumShadow } from "../src/theme/tokens";
import {
  DEFAULT_MEGURI_PROFILE,
  loadMeguriProfileSettings,
  saveMeguriProfileSettings,
  type MeguriProfileSettings,
} from "../src/lib/meguriSettings";

export default function MeguriProfileEditScreen() {
  const insets = useSafeAreaInsets();
  const [settings, setSettings] = useState<MeguriProfileSettings>(DEFAULT_MEGURI_PROFILE);

  useEffect(() => {
    loadMeguriProfileSettings().then(setSettings).catch(() => undefined);
  }, []);

  function update<K extends keyof MeguriProfileSettings>(key: K, value: MeguriProfileSettings[K]) {
    setSettings((current) => ({ ...current, [key]: value }));
  }

  async function save() {
    await saveMeguriProfileSettings(settings);
    router.back();
  }

  return (
    <View style={styles.root}>
      <ScrollView
        contentContainerStyle={[
          styles.content,
          { paddingTop: Math.max(insets.top, 12) + 12, paddingBottom: Math.max(insets.bottom, 12) + 24 },
        ]}
        keyboardShouldPersistTaps="handled"
      >
        <View style={styles.header}>
          <Pressable onPress={() => router.back()} style={styles.roundButton}>
            <IconSymbol name="chevron-back" color={megrumColors.ink} size={20} />
          </Pressable>
          <Text style={styles.headerTitle}>プロフィール編集</Text>
          <Pressable onPress={save} style={styles.saveButton}>
            <Text style={styles.saveText}>保存</Text>
          </Pressable>
        </View>

        <View style={styles.card}>
          <Field
            label="めぐりで表示する名前"
            maxLength={20}
            onChangeText={(value) => update("displayName", value)}
            value={settings.displayName}
          />
          <Field
            label="拠点"
            maxLength={12}
            onChangeText={(value) => update("baseArea", value)}
            value={settings.baseArea}
          />
          <Field
            label="公開メモ"
            maxLength={80}
            multiline
            onChangeText={(value) => update("publicMemo", value)}
            value={settings.publicMemo}
          />
          <Field
            label="別れ際のメッセージ"
            maxLength={40}
            onChangeText={(value) => update("farewellMessage", value)}
            value={settings.farewellMessage}
          />
        </View>

        <View style={styles.preview}>
          <Text style={styles.previewKicker}>公開プレビュー</Text>
          <Text style={styles.previewName}>{settings.displayName || "あなた"}</Text>
          <Text style={styles.previewMeta}>拠点: {settings.baseArea || "未設定"}</Text>
          <Text style={styles.previewFarewell}>別れ際: {settings.farewellMessage || "未設定"}</Text>
        </View>
      </ScrollView>
    </View>
  );
}

function Field({
  label,
  maxLength,
  multiline = false,
  onChangeText,
  value,
}: {
  label: string;
  maxLength: number;
  multiline?: boolean;
  onChangeText: (value: string) => void;
  value: string;
}) {
  return (
    <View style={styles.field}>
      <View style={styles.fieldTop}>
        <Text style={styles.label}>{label}</Text>
        <Text style={styles.count}>{value.length} / {maxLength}</Text>
      </View>
      <TextInput
        maxLength={maxLength}
        multiline={multiline}
        onChangeText={onChangeText}
        placeholder="入力してください"
        placeholderTextColor="rgba(58,50,74,0.34)"
        style={[styles.input, multiline ? styles.inputMultiline : null]}
        value={value}
      />
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
  card: {
    backgroundColor: "#fff",
    borderRadius: 24,
    gap: 14,
    padding: 16,
    ...megrumShadow,
  },
  field: {
    gap: 7,
  },
  fieldTop: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  label: {
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
  },
  count: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
  },
  input: {
    backgroundColor: "rgba(58,50,74,0.05)",
    borderRadius: 16,
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "800",
    minHeight: 44,
    paddingHorizontal: 13,
    paddingVertical: 10,
  },
  inputMultiline: {
    minHeight: 82,
    textAlignVertical: "top",
  },
  preview: {
    backgroundColor: "#fff",
    borderRadius: 24,
    padding: 18,
    ...megrumShadow,
  },
  previewKicker: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    letterSpacing: 1.2,
  },
  previewName: {
    color: megrumColors.ink,
    fontSize: 24,
    fontWeight: "900",
    marginTop: 8,
  },
  previewMeta: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 2,
  },
  previewBubble: {
    backgroundColor: "rgba(166,149,216,0.14)",
    borderRadius: 16,
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "800",
    lineHeight: 21,
    marginTop: 14,
    overflow: "hidden",
    padding: 12,
  },
  previewFarewell: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 12,
  },
});
