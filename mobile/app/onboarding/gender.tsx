import { useEffect, useState } from "react";
import { router } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { PrimaryButton } from "../../src/components/PrimaryButton";
import { Screen } from "../../src/components/Screen";
import { useAuth } from "../../src/auth/AuthProvider";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

const OPTIONS = [
  { value: "female", label: "女性" },
  { value: "male", label: "男性" },
  { value: "other", label: "その他" },
  { value: "no_answer", label: "回答しない" },
];

export default function OnboardingGenderScreen() {
  const { user } = useAuth();
  const [selected, setSelected] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user || !supabase) return;
    supabase
      .from("users")
      .select("gender")
      .eq("id", user.id)
      .maybeSingle()
      .then(({ data }) => setSelected((data?.gender as string | null) ?? null));
  }, [user]);

  async function save() {
    if (!user || !supabase) {
      router.replace("/login");
      return;
    }
    if (!selected) {
      setError("性別を選択してください");
      return;
    }
    setPending(true);
    setError(null);
    const { error: updateError } = await supabase
      .from("users")
      .update({ gender: selected, account_status: "onboarding" })
      .eq("id", user.id);
    setPending(false);
    if (updateError) {
      setError(updateError.message);
      return;
    }
    router.push("/onboarding/oshi");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <OnboardingHeader title="プロフィール設定" sub="マッチングの安全性のため" progress="1/4" />
      <ProgressDots current={0} />
      <Text style={styles.title}>性別を教えてください</Text>
      <Text style={styles.copy}>
        マッチング前のプロフィールに表示されます。{"\n"}
        現地交換時の安全性のために必要な情報です。
      </Text>
      <View style={styles.options}>
        {OPTIONS.map((option) => {
          const active = selected === option.value;
          return (
            <Pressable
              key={option.value}
              accessibilityRole="radio"
              accessibilityState={{ checked: active }}
              onPress={() => setSelected(option.value)}
              style={[styles.option, active ? styles.optionActive : null]}
            >
              <View style={[styles.radio, active ? styles.radioActive : null]}>
                {active ? <View style={styles.radioDot} /> : null}
              </View>
              <Text style={styles.optionText}>{option.label}</Text>
            </Pressable>
          );
        })}
      </View>
      {error ? <Text style={styles.error}>{error}</Text> : null}
      <View style={styles.footer}>
        <PrimaryButton loading={pending} disabled={!selected} onPress={save}>
          次へ
        </PrimaryButton>
      </View>
    </Screen>
  );
}

function OnboardingHeader({
  title,
  sub,
  progress,
}: {
  title: string;
  sub: string;
  progress: string;
}) {
  return (
    <View style={styles.header}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="戻る"
        onPress={() => router.replace("/auth/email-confirmed")}
        style={styles.backButton}
      >
        <Text style={styles.backText}>‹</Text>
      </Pressable>
      <View style={styles.headerCopy}>
        <Text style={styles.headerTitle}>{title}</Text>
        <Text style={styles.headerSub}>{sub}</Text>
      </View>
      <Text style={styles.progressText}>{progress}</Text>
    </View>
  );
}

function ProgressDots({ current }: { current: number }) {
  return (
    <View style={styles.dots}>
      {[0, 1, 2, 3].map((index) => (
        <View
          key={index}
          style={[styles.dot, index <= current ? styles.dotActive : null]}
        />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flexGrow: 1,
    gap: 14,
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
    height: 42,
    justifyContent: "center",
    width: 42,
  },
  backText: {
    color: megrumColors.ink,
    fontSize: 30,
    fontWeight: "800",
    lineHeight: 32,
  },
  headerCopy: {
    flex: 1,
  },
  headerTitle: {
    color: megrumColors.ink,
    fontSize: 17,
    fontWeight: "900",
  },
  headerSub: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "800",
    marginTop: 2,
  },
  progressText: {
    backgroundColor: "rgba(166,149,216,0.12)",
    borderRadius: megrumRadii.pill,
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
    paddingHorizontal: 12,
    paddingVertical: 7,
  },
  dots: {
    flexDirection: "row",
    gap: 6,
    marginTop: 6,
  },
  dot: {
    backgroundColor: "rgba(58,50,74,0.12)",
    borderRadius: 999,
    flex: 1,
    height: 5,
  },
  dotActive: {
    backgroundColor: megrumColors.lavender,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 28,
    marginTop: 6,
  },
  copy: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 19,
  },
  options: {
    gap: 10,
    marginTop: 8,
  },
  option: {
    alignItems: "center",
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: 18,
    borderWidth: 1.5,
    flexDirection: "row",
    gap: 12,
    paddingHorizontal: 18,
    paddingVertical: 16,
  },
  optionActive: {
    backgroundColor: "rgba(166,149,216,0.08)",
    borderColor: megrumColors.lavender,
  },
  radio: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.15)",
    borderRadius: 11,
    borderWidth: 1.8,
    height: 22,
    justifyContent: "center",
    width: 22,
  },
  radioActive: {
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.lavender,
  },
  radioDot: {
    backgroundColor: megrumColors.surface,
    borderRadius: 4,
    height: 8,
    width: 8,
  },
  optionText: {
    color: megrumColors.ink,
    fontSize: 14,
    fontWeight: "900",
  },
  error: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
  },
  footer: {
    marginTop: "auto",
    paddingTop: 24,
  },
});
