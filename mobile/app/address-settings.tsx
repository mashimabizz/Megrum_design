import { useEffect, useMemo, useState } from "react";
import { router } from "expo-router";
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import { useAuth } from "../src/auth/AuthProvider";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import {
  fetchMailingAddress,
  formatMailingAddressError,
  formatMailingAddressSummary,
  upsertMailingAddress,
  type MailingAddressInput,
} from "../src/lib/mailingAddress";
import { megrumColors, megrumRadii, megrumShadow } from "../src/theme/tokens";

const EMPTY_FORM: MailingAddressInput = {
  recipientName: "",
  postalCode: "",
  prefecture: "",
  city: "",
  line1: "",
  line2: "",
  phoneNumber: "",
};

export default function AddressSettingsScreen() {
  const { exitPreview, previewMode, user } = useAuth();
  const [form, setForm] = useState<MailingAddressInput>(EMPTY_FORM);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user || previewMode) {
      setForm(EMPTY_FORM);
      setLoading(false);
      setError(null);
      return;
    }

    let active = true;
    setLoading(true);
    setError(null);
    fetchMailingAddress(user.id, { tolerateMissingSchema: true })
      .then((address) => {
        if (!active) return;
        if (!address) {
          setForm(EMPTY_FORM);
          return;
        }
        setForm({
          recipientName: address.recipientName,
          postalCode: address.postalCode,
          prefecture: address.prefecture,
          city: address.city,
          line1: address.line1,
          line2: address.line2,
          phoneNumber: address.phoneNumber,
        });
      })
      .catch((loadError) => {
        if (!active) return;
        setError(formatMailingAddressError(loadError));
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [previewMode, user]);

  const canSave = useMemo(
    () =>
      [
        form.recipientName,
        form.postalCode,
        form.prefecture,
        form.city,
        form.line1,
      ].every((value) => value.trim().length > 0) && form.postalCode.replace(/[^\d]/g, "").length >= 7,
    [form],
  );

  function update<K extends keyof MailingAddressInput>(
    key: K,
    value: MailingAddressInput[K],
  ) {
    setSaved(false);
    setError(null);
    setForm((current) => ({
      ...current,
      [key]:
        key === "postalCode"
          ? String(value).replace(/[^\d]/g, "").slice(0, 7)
          : key === "phoneNumber"
            ? String(value).replace(/[^\d-]/g, "").slice(0, 15)
            : value,
    }));
  }

  async function handleSave() {
    if (!user || previewMode || !canSave) return;
    setSaving(true);
    setSaved(false);
    setError(null);
    try {
      await upsertMailingAddress(user.id, form);
      setSaved(true);
      if (router.canGoBack()) {
        router.back();
        return;
      }
      router.replace("/(tabs)/profile");
    } catch (saveError) {
      setError(formatMailingAddressError(saveError));
    } finally {
      setSaving(false);
    }
  }

  if (previewMode || !user) {
    return (
      <Screen contentStyle={styles.screen}>
        <RouteHeader title="住所設定" subtitle="郵送交換で使う住所を登録" />
        <View style={styles.noticeCard}>
          <Text style={styles.noticeTitle}>ログインが必要です</Text>
          <Text style={styles.noticeText}>
            住所の登録は実アカウントに保存します。ログイン後に設定してください。
          </Text>
          <PrimaryButton
            onPress={() => {
              exitPreview();
              router.replace("/login");
            }}
          >
            ログインする
          </PrimaryButton>
        </View>
      </Screen>
    );
  }

  return (
    <Screen scroll={false} contentStyle={styles.screen}>
      <RouteHeader title="住所設定" subtitle="郵送交換で使う住所を登録" />
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        style={styles.body}
      >
        <View style={styles.tipCard}>
          <Text style={styles.tipTitle}>相手に見えるタイミング</Text>
          <Text style={styles.tipText}>
            郵送交換で合意が成立した後にだけ、当事者同士へ住所を表示します。
          </Text>
          <Text style={styles.tipSummary}>
            現在の表示: {formatMailingAddressSummary(form)}
          </Text>
        </View>

        {loading ? <ActivityIndicator color={megrumColors.lavender} /> : null}
        {error ? <Text style={styles.errorText}>{error}</Text> : null}
        {saved && !error ? <Text style={styles.savedText}>住所を保存しました</Text> : null}

        <View style={styles.formCard}>
          <Field
            label="宛名"
            placeholder="山田 花子"
            value={form.recipientName}
            onChangeText={(value) => update("recipientName", value)}
          />
          <Field
            label="郵便番号"
            placeholder="1234567"
            keyboardType="number-pad"
            value={form.postalCode}
            onChangeText={(value) => update("postalCode", value)}
          />
          <Field
            label="都道府県"
            placeholder="東京都"
            value={form.prefecture}
            onChangeText={(value) => update("prefecture", value)}
          />
          <Field
            label="市区町村"
            placeholder="渋谷区"
            value={form.city}
            onChangeText={(value) => update("city", value)}
          />
          <Field
            label="番地・建物名"
            placeholder="神南1-2-3 〇〇マンション 101"
            value={form.line1}
            onChangeText={(value) => update("line1", value)}
          />
          <Field
            label="補足住所（任意）"
            placeholder="部屋番号、会社名など"
            value={form.line2}
            onChangeText={(value) => update("line2", value)}
          />
          <Field
            label="電話番号（任意）"
            placeholder="09012345678"
            keyboardType="phone-pad"
            value={form.phoneNumber}
            onChangeText={(value) => update("phoneNumber", value)}
          />
        </View>

        <View style={styles.footer}>
          <PrimaryButton variant="secondary" onPress={() => router.back()}>
            戻る
          </PrimaryButton>
          <PrimaryButton disabled={!canSave} loading={saving} onPress={() => void handleSave()}>
            この住所を保存
          </PrimaryButton>
        </View>
      </KeyboardAvoidingView>
    </Screen>
  );
}

function Field({
  label,
  ...inputProps
}: {
  label: string;
  keyboardType?: "default" | "number-pad" | "phone-pad";
  onChangeText: (value: string) => void;
  placeholder: string;
  value: string;
}) {
  return (
    <View style={styles.field}>
      <Text style={styles.fieldLabel}>{label}</Text>
      <TextInput
        {...inputProps}
        autoCapitalize="none"
        autoCorrect={false}
        placeholderTextColor="rgba(58,50,74,0.34)"
        style={styles.input}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    gap: 14,
  },
  body: {
    flex: 1,
    gap: 14,
  },
  noticeCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(166,149,216,0.2)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 10,
    padding: 16,
    ...megrumShadow,
  },
  noticeTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  noticeText: {
    color: megrumColors.mutedInk,
    fontSize: 12.5,
    fontWeight: "800",
    lineHeight: 19,
  },
  tipCard: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderColor: "rgba(166,149,216,0.22)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 6,
    padding: 14,
  },
  tipTitle: {
    color: megrumColors.ink,
    fontSize: 13.5,
    fontWeight: "900",
  },
  tipText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    lineHeight: 17,
  },
  tipSummary: {
    color: megrumColors.lavender,
    fontSize: 11,
    fontWeight: "900",
    lineHeight: 17,
  },
  formCard: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 12,
    padding: 14,
    ...megrumShadow,
  },
  field: {
    gap: 6,
  },
  fieldLabel: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "900",
  },
  input: {
    backgroundColor: "rgba(58,50,74,0.04)",
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "700",
    minHeight: 48,
    paddingHorizontal: 14,
    paddingVertical: 12,
  },
  errorText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "900",
    lineHeight: 18,
  },
  savedText: {
    color: megrumColors.ok,
    fontSize: 12,
    fontWeight: "900",
    lineHeight: 18,
  },
  footer: {
    gap: 10,
    marginTop: "auto",
    paddingBottom: 8,
  },
});
