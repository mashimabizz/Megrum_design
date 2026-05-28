import { useState } from "react";
import * as Linking from "expo-linking";
import { StyleSheet, Text, View } from "react-native";
import { PrimaryButton } from "../src/components/PrimaryButton";
import { RouteHeader } from "../src/components/RouteHeader";
import { Screen } from "../src/components/Screen";
import { TextField } from "../src/components/TextField";
import { supabase } from "../src/lib/supabase";
import { megrumColors, megrumRadii } from "../src/theme/tokens";

export default function PasswordResetScreen() {
  const [email, setEmail] = useState("");
  const [pending, setPending] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    setError(null);
    setMessage(null);
    const trimmed = email.trim();
    if (!trimmed.includes("@")) {
      setError("有効なメールアドレスを入力してください");
      return;
    }
    if (!supabase) {
      setError("Supabaseの環境変数が未設定です");
      return;
    }

    setPending(true);
    const { error } = await supabase.auth.resetPasswordForEmail(trimmed, {
      redirectTo: Linking.createURL("/auth/password-reset-confirm"),
    });
    setPending(false);
    if (error) {
      setError(error.message);
      return;
    }
    setMessage("リセットメールを送信しました。受信メールのリンクを開いてください。");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader title="パスワード再設定" subtitle="登録メールにリセットリンクを送信" />
      <View style={styles.form}>
        <TextField
          autoCapitalize="none"
          keyboardType="email-address"
          label="メールアドレス"
          onChangeText={setEmail}
          placeholder="example@email.com"
          textContentType="emailAddress"
          value={email}
        />
        {error ? <Text style={styles.error}>{error}</Text> : null}
        {message ? <Text style={styles.message}>{message}</Text> : null}
        <PrimaryButton loading={pending} onPress={submit}>
          リセットメールを送信
        </PrimaryButton>
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  screen: {
    gap: 18,
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
    backgroundColor: "rgba(34,197,94,0.10)",
    borderColor: "rgba(34,197,94,0.24)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    color: "#15803d",
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 18,
    padding: 12,
  },
});
