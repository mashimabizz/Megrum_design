import { useState } from "react";
import { router, useLocalSearchParams } from "expo-router";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { PrimaryButton } from "../../src/components/PrimaryButton";
import { Screen } from "../../src/components/Screen";
import { getMobileAuthEmailRedirectTo } from "../../src/auth/redirects";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii, megrumShadow } from "../../src/theme/tokens";

export default function VerifyEmailScreen() {
  const { email } = useLocalSearchParams<{ email?: string | string[] }>();
  const address = Array.isArray(email) ? email[0] : email;
  const [pending, setPending] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  async function resend() {
    if (!address || !supabase) return;
    setPending(true);
    const { error } = await supabase.auth.resend({
      type: "signup",
      email: address,
      options: {
        emailRedirectTo: getMobileAuthEmailRedirectTo(),
      },
    });
    setPending(false);
    setNotice(error ? error.message : "確認メールを再送しました");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <AuthHeader title="メール認証" backTo="/signup" />
      <View style={styles.center}>
        <View style={styles.mailCircle}>
          <Text style={styles.mailIcon}>✉</Text>
        </View>
        <Text style={styles.title}>確認メールを送りました</Text>
        <Text style={styles.copy}>
          下記のメールアドレスに認証用のリンクを送りました。{"\n"}
          メール内のリンクをタップして、認証を完了してください。
        </Text>
        {address ? <Text style={styles.email}>{address}</Text> : null}
        <View style={styles.note}>
          <Text style={styles.noteText}>
            メールが届かない場合は、迷惑メールフォルダも確認してください。
          </Text>
        </View>
        {notice ? <Text style={styles.notice}>{notice}</Text> : null}
      </View>
      <View style={styles.actions}>
        {address ? (
          <PrimaryButton variant="secondary" loading={pending} onPress={resend}>
            確認メールを再送する
          </PrimaryButton>
        ) : null}
        <Pressable onPress={() => router.replace("/signup")} style={styles.linkButton}>
          <Text style={styles.linkText}>メールアドレスを変更する</Text>
        </Pressable>
        <PrimaryButton onPress={() => router.replace("/login")}>
          認証済みならログインへ
        </PrimaryButton>
      </View>
    </Screen>
  );
}

function AuthHeader({ title, backTo }: { title: string; backTo: string }) {
  return (
    <View style={styles.header}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="戻る"
        onPress={() => router.replace(backTo)}
        style={styles.backButton}
      >
        <Text style={styles.backText}>‹</Text>
      </Pressable>
      <Text style={styles.headerTitle}>{title}</Text>
      <View style={styles.headerSpacer} />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flexGrow: 1,
    justifyContent: "space-between",
  },
  header: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "space-between",
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
  headerTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  headerSpacer: {
    width: 42,
  },
  center: {
    alignItems: "center",
    paddingTop: 42,
  },
  mailCircle: {
    alignItems: "center",
    backgroundColor: "rgba(166,149,216,0.14)",
    borderRadius: 40,
    height: 80,
    justifyContent: "center",
    width: 80,
    ...megrumShadow,
  },
  mailIcon: {
    color: megrumColors.lavender,
    fontSize: 36,
    fontWeight: "900",
  },
  title: {
    color: megrumColors.ink,
    fontSize: 20,
    fontWeight: "900",
    marginTop: 22,
  },
  copy: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "800",
    lineHeight: 21,
    marginTop: 10,
    textAlign: "center",
  },
  email: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.10)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    color: megrumColors.ink,
    fontSize: 13,
    fontWeight: "900",
    marginTop: 20,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  note: {
    backgroundColor: "rgba(243,197,212,0.42)",
    borderRadius: megrumRadii.md,
    marginTop: 22,
    padding: 13,
  },
  noteText: {
    color: megrumColors.ink,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 18,
  },
  notice: {
    color: megrumColors.ok,
    fontSize: 12,
    fontWeight: "900",
    marginTop: 14,
  },
  actions: {
    gap: 10,
  },
  linkButton: {
    alignItems: "center",
    paddingVertical: 10,
  },
  linkText: {
    color: megrumColors.lavender,
    fontSize: 13,
    fontWeight: "900",
  },
});
