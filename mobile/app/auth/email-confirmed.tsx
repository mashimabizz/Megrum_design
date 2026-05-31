import { useEffect, useState } from "react";
import { router, useLocalSearchParams } from "expo-router";
import { StyleSheet, Text, View } from "react-native";
import { PrimaryButton } from "../../src/components/PrimaryButton";
import { Screen } from "../../src/components/Screen";
import { useAuth } from "../../src/auth/AuthProvider";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumShadow } from "../../src/theme/tokens";

export default function EmailConfirmedScreen() {
  const { onboardingPath, refreshProfile, user } = useAuth();
  const { code, error_description, provider } = useLocalSearchParams<{
    code?: string | string[];
    error_description?: string | string[];
    provider?: string | string[];
  }>();
  const authCode = Array.isArray(code) ? code[0] : code;
  const providerParam = Array.isArray(provider) ? provider[0] : provider;
  const isGoogleAuth = providerParam === "google";
  const linkError = Array.isArray(error_description)
    ? error_description[0]
    : error_description;
  const [exchangeError, setExchangeError] = useState<string | null>(null);

  useEffect(() => {
    if (!authCode || !supabase) return;
    const client = supabase;
    let active = true;
    client.auth.exchangeCodeForSession(authCode).then(async ({ data, error }) => {
      if (!active) return;
      setExchangeError(error?.message ?? null);
      if (!error && data.user) {
        await client
          .from("users")
          .update({
            account_status: "verified",
            email_verified_at: new Date().toISOString(),
          })
          .eq("id", data.user.id)
          .eq("account_status", "registered");
        await refreshProfile();
      }
    });
    return () => {
      active = false;
    };
  }, [authCode, refreshProfile]);

  return (
    <Screen contentStyle={styles.screen}>
      <View style={styles.center}>
        <View style={styles.checkCircle}>
          <Text style={styles.check}>✓</Text>
        </View>
        <Text style={styles.title}>認証完了！</Text>
        <Text style={styles.copy}>
          {isGoogleAuth
            ? "Googleアカウントで認証できました。"
            : "メールアドレスの認証が完了しました。"}
          {"\n"}続けてプロフィールを設定しましょう。
        </Text>
        {linkError || exchangeError ? (
          <Text style={styles.errorText}>{linkError ?? exchangeError}</Text>
        ) : null}
      </View>
      <PrimaryButton
        onPress={() =>
          router.replace(user ? onboardingPath ?? "/onboarding/gender" : "/login")
        }
      >
        {user ? "プロフィール設定へ進む" : "ログインして続ける"}
      </PrimaryButton>
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: {
    flexGrow: 1,
    justifyContent: "space-between",
    paddingBottom: 34,
    paddingTop: 68,
  },
  center: {
    alignItems: "center",
    flex: 1,
    justifyContent: "center",
  },
  checkCircle: {
    alignItems: "center",
    backgroundColor: megrumColors.lavender,
    borderRadius: 48,
    height: 96,
    justifyContent: "center",
    width: 96,
    ...megrumShadow,
  },
  check: {
    color: megrumColors.surface,
    fontSize: 52,
    fontWeight: "900",
    lineHeight: 58,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 24,
    fontWeight: "900",
    marginTop: 26,
  },
  copy: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 22,
    marginTop: 12,
    textAlign: "center",
  },
  errorText: {
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    marginTop: 16,
    textAlign: "center",
  },
});
