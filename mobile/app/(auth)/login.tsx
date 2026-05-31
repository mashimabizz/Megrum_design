import { useState } from "react";
import { router } from "expo-router";
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { MegrumLogo } from "../../src/components/MegrumLogo";
import { AppleAuthButton } from "../../src/components/AppleAuthButton";
import { GoogleAuthButton } from "../../src/components/GoogleAuthButton";
import { PrimaryButton } from "../../src/components/PrimaryButton";
import { Screen } from "../../src/components/Screen";
import { TextField } from "../../src/components/TextField";
import { useAuth } from "../../src/auth/AuthProvider";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

export default function LoginScreen() {
  const { configured, enterPreview, signIn } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [pending, setPending] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  async function submit() {
    setMessage(null);
    const trimmedEmail = email.trim();
    if (!trimmedEmail || !password) {
      setMessage("メールアドレスとパスワードを入力してください");
      return;
    }

    setPending(true);
    const error = await signIn(trimmedEmail, password);
    setPending(false);
    if (error) {
      setMessage(normalizeAuthError(error));
      return;
    }
    router.replace("/");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        style={styles.keyboard}
      >
        <AuthHeader title="ログイン" backTo="/welcome" />

        <View style={styles.brand}>
          <MegrumLogo size={60} />
          <Text style={styles.welcome}>おかえりなさい</Text>
          <Text style={styles.webAccountNote}>
            Web版と同じメールアドレス・パスワードでログインできます
          </Text>
        </View>

        {configured ? (
          <>
            <View style={styles.form}>
              <TextField
                label="メールアドレス"
                value={email}
                onChangeText={setEmail}
                autoComplete="email"
                autoCapitalize="none"
                autoCorrect={false}
                keyboardType="email-address"
                textContentType="emailAddress"
                placeholder="example@email.com"
              />
              <TextField
                label="パスワード"
                value={password}
                onChangeText={setPassword}
                autoComplete="password"
                secureTextEntry
                textContentType="password"
                placeholder="パスワードを入力"
              />
              <Pressable onPress={() => router.push("/password-reset")}>
                <Text style={styles.forgot}>パスワードを忘れた方</Text>
              </Pressable>
              {message ? <Text style={styles.message}>{message}</Text> : null}
              <PrimaryButton
                loading={pending}
                disabled={!email.trim() || !password}
                onPress={submit}
              >
                メールアドレスでログイン
              </PrimaryButton>
            </View>

            <View style={styles.divider}>
              <View style={styles.dividerLine} />
              <Text style={styles.dividerText}>または</Text>
              <View style={styles.dividerLine} />
            </View>
            <AppleAuthButton mode="signIn" onError={setMessage} />
            <GoogleAuthButton mode="signIn" onError={setMessage} />

            <View style={styles.signupRow}>
              <Text style={styles.signupText}>アカウントをお持ちでない方は </Text>
              <Pressable onPress={() => router.push("/signup")}>
                <Text style={styles.signupLink}>新規登録</Text>
              </Pressable>
            </View>
          </>
        ) : (
          <View style={styles.envBox}>
            <Text style={styles.envTitle}>Supabase設定待ち</Text>
            <Text style={styles.envText}>
              mobile/.env.local に Supabase の公開URLと publishable key を入れるとログインできます。
            </Text>
            <PrimaryButton
              variant="secondary"
              onPress={() => {
                enterPreview();
              }}
            >
              画面だけプレビューする
            </PrimaryButton>
          </View>
        )}
      </KeyboardAvoidingView>
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

function normalizeAuthError(error: string) {
  if (error.includes("Invalid login credentials")) {
    return "メールアドレスまたはパスワードが正しくありません";
  }
  if (error.includes("Email not confirmed")) {
    return "メール認証が完了していません。受信メールを確認してください";
  }
  return error;
}

const styles = StyleSheet.create({
  screen: {
    flexGrow: 1,
  },
  keyboard: {
    gap: 24,
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
  brand: {
    alignItems: "center",
    marginBottom: 4,
  },
  welcome: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    marginTop: 14,
  },
  webAccountNote: {
    color: megrumColors.mutedInk,
    fontSize: 11.5,
    fontWeight: "800",
    lineHeight: 18,
    marginTop: 7,
    textAlign: "center",
  },
  form: {
    gap: 14,
  },
  forgot: {
    color: megrumColors.lavender,
    fontSize: 12,
    fontWeight: "900",
    textAlign: "right",
  },
  message: {
    backgroundColor: "rgba(217,130,107,0.10)",
    borderColor: "rgba(217,130,107,0.22)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    color: megrumColors.warn,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    padding: 12,
  },
  divider: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
    marginTop: -4,
  },
  dividerLine: {
    backgroundColor: "rgba(58,50,74,0.12)",
    flex: 1,
    height: 1,
  },
  dividerText: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "700",
  },
  signupRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "center",
  },
  signupText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "700",
  },
  signupLink: {
    color: megrumColors.lavender,
    fontSize: 13,
    fontWeight: "900",
  },
  envBox: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.xl,
    borderWidth: 1,
    gap: 12,
    padding: 18,
  },
  envTitle: {
    color: megrumColors.ink,
    fontSize: 18,
    fontWeight: "900",
  },
  envText: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 19,
  },
});
