import { useEffect, useMemo, useState } from "react";
import * as ImagePicker from "expo-image-picker";
import {
  ActivityIndicator,
  Alert,
  ActionSheetIOS,
  Image,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { router, Stack } from "expo-router";
import { useAuth } from "../src/auth/AuthProvider";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { Screen } from "../src/components/Screen";
import { TextField } from "../src/components/TextField";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

type Gender = "female" | "male" | "other" | "no_answer";

type ProfileForm = {
  handle: string;
  displayName: string;
  gender: Gender | null;
  primaryArea: string;
  avatarUrl: string | null;
};

type UserProfileRow = {
  handle: string | null;
  display_name: string | null;
  gender: Gender | null;
  primary_area: string | null;
  avatar_url: string | null;
};

const GENDER_OPTIONS: { value: Gender; label: string }[] = [
  { value: "female", label: "女性" },
  { value: "male", label: "男性" },
  { value: "other", label: "その他" },
  { value: "no_answer", label: "回答しない" },
];

const PREFECTURES = [
  "北海道",
  "青森県",
  "岩手県",
  "宮城県",
  "秋田県",
  "山形県",
  "福島県",
  "茨城県",
  "栃木県",
  "群馬県",
  "埼玉県",
  "千葉県",
  "東京都",
  "神奈川県",
  "新潟県",
  "富山県",
  "石川県",
  "福井県",
  "山梨県",
  "長野県",
  "岐阜県",
  "静岡県",
  "愛知県",
  "三重県",
  "滋賀県",
  "京都府",
  "大阪府",
  "兵庫県",
  "奈良県",
  "和歌山県",
  "鳥取県",
  "島根県",
  "岡山県",
  "広島県",
  "山口県",
  "徳島県",
  "香川県",
  "愛媛県",
  "高知県",
  "福岡県",
  "佐賀県",
  "長崎県",
  "熊本県",
  "大分県",
  "宮崎県",
  "鹿児島県",
  "沖縄県",
] as const;

export default function ProfileEditScreen() {
  const { refreshProfile, user, previewMode } = useAuth();
  const [form, setForm] = useState<ProfileForm>(() => fallbackForm(user?.email));
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [uploadingAvatar, setUploadingAvatar] = useState(false);
  const [areaPickerOpen, setAreaPickerOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  const initial = useMemo(
    () => (form.displayName || form.handle || "?").slice(0, 1).toUpperCase(),
    [form.displayName, form.handle],
  );
  const shouldHoldFormForLoad = loading && !!supabase && !!user && !previewMode;

  useEffect(() => {
    if (!supabase || !user || previewMode) {
      setForm(fallbackForm(user?.email));
      setError(null);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);
    fetchProfile(user.id, user.email)
      .then((next) => {
        if (active) setForm(next);
      })
      .catch((loadError: unknown) => {
        if (!active) return;
        setError(loadError instanceof Error ? loadError.message : "読み込みに失敗しました");
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, user]);

  async function handleSave() {
    if (!user || !supabase || previewMode) {
      setError("ログイン後に保存できます");
      return;
    }
    const validation = validateForm(form);
    if (validation) {
      setError(validation);
      return;
    }

    setSaving(true);
    setError(null);
    setSaved(false);
    try {
      const handle = form.handle.trim().toLowerCase();
      const { data: duplicate, error: duplicateError } = await supabase
        .from("users")
        .select("id")
        .eq("handle", handle)
        .neq("id", user.id)
        .maybeSingle();
      if (duplicateError) throw duplicateError;
      if (duplicate) {
        setError("このハンドル名は既に使われています");
        return;
      }

      const { error: updateError } = await supabase
        .from("users")
        .update({
          handle,
          display_name: form.displayName.trim(),
          gender: form.gender,
          primary_area: form.primaryArea.trim() || null,
          avatar_url: form.avatarUrl,
        })
        .eq("id", user.id);
      if (updateError) throw updateError;
      await refreshProfile();
      setSaved(true);
      setTimeout(() => {
        if (router.canGoBack()) router.back();
      }, 350);
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : "保存に失敗しました");
    } finally {
      setSaving(false);
    }
  }

  function handlePickAvatar() {
    if (!user || !supabase || previewMode) {
      setError("ログイン後にアイコン画像を変更できます");
      return;
    }
    const title = form.avatarUrl ? "アイコン画像を変更" : "アイコン画像を選択";
    if (Platform.OS === "ios") {
      ActionSheetIOS.showActionSheetWithOptions(
        {
          title,
          message: "登録する画像を選んでください。",
          options: ["カメラで撮る", "写真を選ぶ", "閉じる"],
          cancelButtonIndex: 2,
          userInterfaceStyle: "light",
          tintColor: megrumColors.lavender,
        },
        (buttonIndex) => {
          if (buttonIndex === 0) void pickAvatar("camera");
          if (buttonIndex === 1) void pickAvatar("library");
        },
      );
      return;
    }

    Alert.alert(title, "登録する画像を選んでください。", [
      {
        text: "カメラで撮る",
        onPress: () => {
          void pickAvatar("camera");
        },
      },
      {
        text: "写真を選ぶ",
        onPress: () => {
          void pickAvatar("library");
        },
      },
      { text: "閉じる", style: "cancel" },
    ]);
  }

  async function pickAvatar(source: "camera" | "library") {
    if (!user || !supabase || previewMode) return;
    setUploadingAvatar(true);
    setError(null);
    try {
      const permission =
        source === "camera"
          ? await ImagePicker.requestCameraPermissionsAsync()
          : await ImagePicker.requestMediaLibraryPermissionsAsync();
      if (!permission.granted) {
        setError(source === "camera" ? "カメラの利用を許可してください" : "写真ライブラリの利用を許可してください");
        return;
      }
      const pickerOptions: ImagePicker.ImagePickerOptions = {
        allowsEditing: true,
        aspect: [1, 1],
        mediaTypes: ["images"],
        quality: 0.88,
      };
      const result =
        source === "camera"
          ? await ImagePicker.launchCameraAsync(pickerOptions)
          : await ImagePicker.launchImageLibraryAsync(pickerOptions);
      if (result.canceled || !result.assets[0]) return;
      const publicUrl = await uploadAvatar({
        userId: user.id,
        uri: result.assets[0].uri,
        mimeType: result.assets[0].mimeType,
        fileName: result.assets[0].fileName,
      });
      setForm((current) => ({ ...current, avatarUrl: publicUrl }));
    } catch (avatarError) {
      setError(avatarError instanceof Error ? avatarError.message : "アップロードに失敗しました");
    } finally {
      setUploadingAvatar(false);
    }
  }

  return (
    <Screen contentStyle={styles.screen} topInset={false}>
      <Stack.Screen
        options={{
          headerShown: true,
          title: "プロフィール編集",
          headerBackButtonDisplayMode: "minimal",
          headerBlurEffect: "systemMaterial",
          headerTintColor: megrumColors.lavender,
        }}
      />

      {shouldHoldFormForLoad ? (
        <Text style={styles.inlineNotice}>プロフィールを読み込み中…</Text>
      ) : (
        <>
      <View style={styles.avatarPanel}>
        <View style={styles.avatar}>
          {form.avatarUrl ? (
            <Image source={{ uri: form.avatarUrl }} style={styles.avatarImage} />
          ) : (
            <Text style={styles.avatarText}>{initial}</Text>
          )}
        </View>
        <View style={styles.avatarCopy}>
          <Text style={styles.avatarTitle}>アイコン画像</Text>
          <Text style={styles.avatarSub}>
            {uploadingAvatar
              ? "アップロード中…"
              : form.avatarUrl
                ? "タップして変更できます"
                : "画像を選んで切り抜き登録"}
          </Text>
        </View>
        <Pressable
          disabled={uploadingAvatar}
          onPress={handlePickAvatar}
          style={styles.avatarChange}
        >
          {uploadingAvatar ? (
            <ActivityIndicator color={megrumColors.lavender} size="small" />
          ) : (
            <Text style={styles.avatarChangeText}>
              {form.avatarUrl ? "変更" : "選択"}
            </Text>
          )}
        </Pressable>
        {form.avatarUrl ? (
          <Pressable
            disabled={uploadingAvatar}
            onPress={() => setForm((current) => ({ ...current, avatarUrl: null }))}
            style={styles.avatarDelete}
          >
            <Text style={styles.avatarDeleteText}>削除</Text>
          </Pressable>
        ) : null}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>基本情報</Text>
        <View style={styles.handleField}>
          <Text style={styles.handlePrefix}>@</Text>
          <TextField
            label="ハンドル名"
            value={form.handle}
            autoCapitalize="none"
            autoCorrect={false}
            onChangeText={(handle) =>
              setForm((current) => ({ ...current, handle }))
            }
            style={styles.handleInput}
          />
        </View>
        <TextField
          label="表示名"
          value={form.displayName}
          onChangeText={(displayName) =>
            setForm((current) => ({ ...current, displayName }))
          }
        />
      </View>

      <View style={styles.section}>
        <View style={styles.sectionHeadingRow}>
          <Text style={styles.sectionTitle}>公開情報</Text>
          <Text style={styles.sectionHint}>マッチング前に表示</Text>
        </View>
        <View style={styles.fieldBlock}>
          <Text style={styles.fieldLabel}>性別</Text>
        <View style={styles.genderGrid}>
          {GENDER_OPTIONS.map((option) => {
            const active = form.gender === option.value;
            return (
              <Pressable
                key={option.value}
                onPress={() =>
                  setForm((current) => ({
                    ...current,
                    gender: active ? null : option.value,
                  }))
                }
                style={[styles.genderChip, active ? styles.genderChipActive : null]}
              >
                <Text
                  style={[
                    styles.genderChipText,
                    active ? styles.genderChipTextActive : null,
                  ]}
                >
                  {option.label}
                </Text>
              </Pressable>
            );
          })}
        </View>
        </View>
        <View style={styles.fieldBlock}>
          <View style={styles.fieldLabelRow}>
            <Text style={styles.fieldLabel}>主な活動エリア（都道府県）</Text>
            <Text style={styles.fieldHint}>任意</Text>
          </View>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="主な活動エリアを選択"
            onPress={() => setAreaPickerOpen(true)}
            style={styles.areaSelect}
          >
            <Text
              style={[
                styles.areaSelectText,
                !form.primaryArea ? styles.areaSelectPlaceholder : null,
              ]}
            >
              {form.primaryArea || "指定なし"}
            </Text>
            <Text style={styles.areaSelectIcon}>⌄</Text>
          </Pressable>
        </View>
      </View>

      {loading ? <Text style={styles.inlineNotice}>プロフィールを読み込み中…</Text> : null}
      {saved ? <Text style={styles.inlineOk}>保存しました</Text> : null}
      {error ? <Text style={styles.inlineError}>{error}</Text> : null}

      <PrimaryButton loading={saving} onPress={handleSave}>
        保存する
      </PrimaryButton>

      <AreaPickerModal
        visible={areaPickerOpen}
        selected={form.primaryArea}
        onClose={() => setAreaPickerOpen(false)}
        onSelect={(primaryArea) => {
          setForm((current) => ({ ...current, primaryArea }));
          setAreaPickerOpen(false);
        }}
      />
        </>
      )}
    </Screen>
  );
}

function AreaPickerModal({
  visible,
  selected,
  onClose,
  onSelect,
}: {
  visible: boolean;
  selected: string;
  onClose: () => void;
  onSelect: (value: string) => void;
}) {
  const nativeSheet = Platform.OS === "ios";
  return (
    <Modal
      visible={visible}
      transparent={!nativeSheet}
      animationType={nativeSheet ? "slide" : "fade"}
      presentationStyle={nativeSheet ? "pageSheet" : "overFullScreen"}
      onRequestClose={onClose}
    >
      <View style={[styles.modalRoot, nativeSheet ? styles.nativeSheetRoot : null]}>
        {!nativeSheet ? <Pressable style={styles.modalBackdropPressArea} onPress={onClose} /> : null}
        <View style={[styles.areaSheet, nativeSheet ? styles.nativeAreaSheet : null]}>
          <View style={styles.sheetGrabber} />
          <View style={styles.sheetHeader}>
            <View>
              <Text style={styles.sheetTitle}>主な活動エリア</Text>
              <Text style={styles.sheetSub}>都道府県を選択してください</Text>
            </View>
            <Pressable accessibilityRole="button" onPress={onClose} style={styles.sheetClose}>
              <Text style={styles.sheetCloseText}>×</Text>
            </Pressable>
          </View>
          <ScrollView style={styles.areaList} contentContainerStyle={styles.areaListContent}>
            <AreaOption label="指定なし" active={!selected} onPress={() => onSelect("")} />
            {PREFECTURES.map((prefecture) => (
              <AreaOption
                key={prefecture}
                label={prefecture}
                active={selected === prefecture}
                onPress={() => onSelect(prefecture)}
              />
            ))}
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

function AreaOption({
  label,
  active,
  onPress,
}: {
  label: string;
  active: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={[styles.areaOption, active ? styles.areaOptionActive : null]}>
      <Text style={[styles.areaOptionText, active ? styles.areaOptionTextActive : null]}>
        {label}
      </Text>
      {active ? <Text style={styles.areaOptionCheck}>✓</Text> : null}
    </Pressable>
  );
}

async function fetchProfile(userId: string, email?: string): Promise<ProfileForm> {
  if (!supabase) return fallbackForm(email);
  const { data, error } = await supabase
    .from("users")
    .select("handle, display_name, gender, primary_area, avatar_url")
    .eq("id", userId)
    .maybeSingle();
  if (error) throw error;
  const row = data as UserProfileRow | null;
  return {
    handle: row?.handle ?? makeHandle(email),
    displayName: row?.display_name ?? "",
    gender: row?.gender ?? null,
    primaryArea: row?.primary_area ?? "",
    avatarUrl: row?.avatar_url ?? null,
  };
}

async function uploadAvatar(input: {
  userId: string;
  uri: string;
  mimeType?: string | null;
  fileName?: string | null;
}) {
  if (!supabase) throw new Error("Supabaseが未設定です");
  const ext = extensionFrom(input.fileName ?? input.uri, input.mimeType);
  const path = `${input.userId}/avatar_${Date.now()}.${ext}`;
  const response = await fetch(input.uri);
  const body = await response.arrayBuffer();
  const { error } = await supabase.storage.from("avatars").upload(path, body, {
    contentType: input.mimeType ?? "image/jpeg",
    upsert: false,
  });
  if (error) throw error;
  const { data } = supabase.storage.from("avatars").getPublicUrl(path);
  return data.publicUrl;
}

function extensionFrom(fileNameOrUri: string, mimeType?: string | null) {
  const fromName = fileNameOrUri.split("?")[0]?.split(".").pop()?.toLowerCase();
  if (fromName && /^[a-z0-9]{2,5}$/.test(fromName)) return fromName === "jpeg" ? "jpg" : fromName;
  if (mimeType?.includes("png")) return "png";
  if (mimeType?.includes("webp")) return "webp";
  return "jpg";
}

function fallbackForm(email?: string): ProfileForm {
  return {
    handle: makeHandle(email),
    displayName: email ? "michi" : "ゲスト",
    gender: null,
    primaryArea: "",
    avatarUrl: null,
  };
}

function validateForm(form: ProfileForm) {
  const handle = form.handle.trim().toLowerCase();
  const displayName = form.displayName.trim();
  if (!/^[a-z0-9_]{3,20}$/.test(handle)) {
    return "ハンドルは半角英数字・_ の3〜20文字で入力してください";
  }
  if (!displayName || displayName.length > 50) {
    return "表示名は1〜50文字で入力してください";
  }
  const primaryArea = form.primaryArea.trim();
  if (primaryArea && !PREFECTURES.includes(primaryArea as (typeof PREFECTURES)[number])) {
    return "活動エリアは都道府県から選択してください";
  }
  return null;
}

function makeHandle(email?: string) {
  if (!email) return "preview_hana";
  const local = email.split("@")[0]?.replace(/[^a-zA-Z0-9_]/g, "").toLowerCase();
  return local || "megrum_user";
}

const styles = StyleSheet.create({
  screen: {
    gap: 15,
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
  },
  backButton: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 44,
    justifyContent: "center",
    width: 44,
    ...megrumShadow,
  },
  backText: {
    color: megrumColors.ink,
    fontSize: 32,
    fontWeight: "800",
    lineHeight: 34,
  },
  headerCopy: {
    flex: 1,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 20,
    fontWeight: "900",
  },
  subtitle: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  avatarPanel: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    flexDirection: "row",
    gap: 13,
    padding: 15,
  },
  avatar: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 27,
    height: 64,
    justifyContent: "center",
    overflow: "hidden",
    width: 64,
  },
  avatarImage: {
    height: "100%",
    width: "100%",
  },
  avatarText: {
    color: megrumColors.surface,
    fontSize: 22,
    fontWeight: "900",
  },
  avatarCopy: {
    flex: 1,
  },
  avatarTitle: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "900",
  },
  avatarSub: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
    lineHeight: 15,
    marginTop: 3,
  },
  avatarChange: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.38)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    justifyContent: "center",
    minHeight: 34,
    minWidth: 52,
    paddingHorizontal: 11,
    paddingVertical: 7,
  },
  avatarChangeText: {
    color: megrumColors.lavender,
    fontSize: 10.5,
    fontWeight: "900",
  },
  avatarDelete: {
    backgroundColor: "rgba(217,130,107,0.12)",
    borderRadius: megrumRadii.pill,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  avatarDeleteText: {
    color: megrumColors.warn,
    fontSize: 10.5,
    fontWeight: "900",
  },
  section: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 12,
    padding: 15,
  },
  sectionTitle: {
    color: megrumColors.lavender,
    fontSize: 11.5,
    fontWeight: "900",
    letterSpacing: 0.4,
  },
  sectionHeadingRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
  },
  sectionHint: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
  },
  fieldBlock: {
    gap: 8,
  },
  fieldLabelRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 6,
  },
  fieldLabel: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  fieldHint: {
    color: megrumColors.mutedInk,
    fontSize: 10.5,
    fontWeight: "800",
  },
  handleField: {
    gap: 7,
  },
  handlePrefix: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "900",
    position: "absolute",
    right: 12,
    top: 0,
  },
  handleInput: {
    textTransform: "lowercase",
  },
  genderGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  genderChip: {
    backgroundColor: "rgba(58,50,74,0.05)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 9,
  },
  genderChipActive: {
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.lavender,
  },
  genderChipText: {
    color: megrumColors.ink,
    fontSize: 12,
    fontWeight: "900",
  },
  genderChipTextActive: {
    color: megrumColors.surface,
  },
  areaSelect: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    flexDirection: "row",
    justifyContent: "space-between",
    minHeight: 48,
    paddingHorizontal: 14,
  },
  areaSelectText: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "800",
  },
  areaSelectPlaceholder: {
    color: megrumColors.mutedInk,
  },
  areaSelectIcon: {
    color: megrumColors.lavender,
    fontSize: 18,
    fontWeight: "900",
  },
  modalRoot: {
    backgroundColor: "rgba(18,16,24,0.34)",
    flex: 1,
    justifyContent: "flex-end",
  },
  nativeSheetRoot: {
    backgroundColor: megrumColors.background,
    justifyContent: "flex-start",
  },
  modalBackdropPressArea: {
    ...StyleSheet.absoluteFillObject,
  },
  areaSheet: {
    backgroundColor: megrumColors.background,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    maxHeight: "78%",
    paddingBottom: 20,
    paddingHorizontal: 18,
    paddingTop: 10,
    ...megrumShadow,
  },
  nativeAreaSheet: {
    borderTopLeftRadius: 0,
    borderTopRightRadius: 0,
    elevation: 0,
    maxHeight: "100%",
    shadowOpacity: 0,
    shadowRadius: 0,
  },
  sheetGrabber: {
    alignSelf: "center",
    backgroundColor: "rgba(58,50,74,0.16)",
    borderRadius: megrumRadii.pill,
    height: 4,
    marginBottom: 14,
    width: 42,
  },
  sheetHeader: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 12,
  },
  sheetTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  sheetSub: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  sheetClose: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.pill,
    borderWidth: 1,
    height: 36,
    justifyContent: "center",
    width: 36,
  },
  sheetCloseText: {
    color: megrumColors.ink,
    fontSize: 20,
    fontWeight: "800",
    marginTop: -2,
  },
  areaList: {
    marginHorizontal: -2,
  },
  areaListContent: {
    gap: 8,
    paddingBottom: 12,
    paddingHorizontal: 2,
  },
  areaOption: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.lg,
    borderWidth: 1,
    flexDirection: "row",
    justifyContent: "space-between",
    minHeight: 46,
    paddingHorizontal: 14,
  },
  areaOptionActive: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderColor: "rgba(166,149,216,0.42)",
  },
  areaOptionText: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "800",
  },
  areaOptionTextActive: {
    color: megrumColors.lavender,
    fontWeight: "900",
  },
  areaOptionCheck: {
    color: megrumColors.lavender,
    fontSize: 16,
    fontWeight: "900",
  },
  inlineNotice: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
  },
  inlineOk: {
    color: megrumColors.ok,
    fontSize: 12,
    fontWeight: "900",
  },
  inlineError: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
  },
});
