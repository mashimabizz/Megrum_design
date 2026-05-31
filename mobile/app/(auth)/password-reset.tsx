import { useState } from "react";
import * as ExpoLinking from "expo-linking";
import { router } from "expo-router";
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { PrimaryButton } from "../../src/components/PrimaryButton";
import { Screen } from "../../src/components/Screen";
import { TextField } from "../../src/components/TextField";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

export default function PasswordResetScreen() {
  const [email, setEmail] = useState("");
  const [pending, setPending] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    const trimmedEmail = email.trim();
    setMessage(null);
    setError(null);
    if (!trimmedEmail || !trimmedEmail.includes("@")) {
      setError("有効なメールアドレスを入力してください");
      return;
    }
    if (!supabase) {
      setError("Supabaseの環境変数が未設定です");
      return;
    }

    setPending(true);
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(
      trimmedEmail,
      {
        redirectTo: ExpoLinking.createURL("/login"),
      },
    );
    setPending(false);
    if (resetError) {
      setError(resetError.message);
      return;
    }
    setMessage("パスワードリセット用のメールを送信しました。受信メールを確認してください。");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        style={styles.keyboard}
      >
        <View style={styles.header}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="戻る"
            onPress={() => router.replace("/login")}
            style={styles.backButton}
          >
            <Text style={styles.backText}>‹</Text>
          </Pressable>
          <Text style={styles.headerTitle}>パスワードリセット</Text>
          <View style={styles.headerSpacer} />
        </View>

        <View style={styles.copyBlock}>
          <Text style={styles.title}>パスワードを再設定します</Text>
          <Text style={styles.copy}>
            ご登録のメールアドレスを入力してください。{"\n"}
            パスワードリセット用のリンクをお送りします。
          </Text>
        </View>

        <View style={styles.form}>
          <TextField
            label="メールアドレス"
            value={email}
            onChangeText={setEmail}
            autoCapitalize="none"
            keyboardType="email-address"
            textContentType="emailAddress"
            placeholder="example@email.com"
          />
          {error ? <Text style={styles.error}>{error}</Text> : null}
          {message ? <Text style={styles.message}>{message}</Text> : null}
          <PrimaryButton
            loading={pending}
            disabled={!email.trim()}
            onPress={submit}
          >
            リセットメールを送信
          </PrimaryButton>
        </View>
      </KeyboardAvoidingView>
    </Screen>
  );
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
    fontSize: 17,
    fontWeight: "900",
  },
  headerSpacer: {
    width: 42,
  },
  copyBlock: {
    gap: 9,
  },
  title: {
    color: megrumColors.ink,
    fontSize: 24,
    fontWeight: "900",
    lineHeight: 31,
  },
  copy: {
    color: megrumColors.mutedInk,
    fontSize: 12.5,
    fontWeight: "800",
    lineHeight: 21,
  },
  form: {
    gap: 14,
  },
  error: {
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
  message: {
    backgroundColor: "rgba(117,191,139,0.12)",
    borderColor: "rgba(117,191,139,0.22)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    color: "#3f8c55",
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    padding: 12,
  },
});
