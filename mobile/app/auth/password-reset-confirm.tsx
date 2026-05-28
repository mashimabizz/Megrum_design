import { useEffect, useMemo, useState } from "react";
import { router, useLocalSearchParams } from "expo-router";
import { StyleSheet, Text, View } from "react-native";
import { PrimaryButton } from "../../src/components/PrimaryButton";
import { RouteHeader } from "../../src/components/RouteHeader";
import { Screen } from "../../src/components/Screen";
import { TextField } from "../../src/components/TextField";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

export default function PasswordResetConfirmScreen() {
  const { code, error_description } = useLocalSearchParams<{
    code?: string | string[];
    error_description?: string | string[];
  }>();
  const authCode = Array.isArray(code) ? code[0] : code;
  const linkError = Array.isArray(error_description)
    ? error_description[0]
    : error_description;
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [pending, setPending] = useState(false);
  const [exchangeError, setExchangeError] = useState<string | null>(null);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [sessionReady, setSessionReady] = useState(false);
  const strength = useMemo(() => getPasswordStrength(password), [password]);
  const canSubmit = password.length >= 8 && password === confirm && sessionReady;

  useEffect(() => {
    if (!authCode || !supabase) return;
    let active = true;
    supabase.auth.exchangeCodeForSession(authCode).then(({ error }) => {
      if (!active) return;
      setExchangeError(error?.message ?? null);
      setSessionReady(!error);
    });
    return () => {
      active = false;
    };
  }, [authCode]);

  async function submit() {
    setSubmitError(null);
    if (password.length < 8) {
      setSubmitError("パスワードは8文字以上で入力してください");
      return;
    }
    if (password !== confirm) {
      setSubmitError("パスワードが一致しません");
      return;
    }
    if (!supabase) {
      setSubmitError("Supabaseの環境変数が未設定です");
      return;
    }

    setPending(true);
    const { error } = await supabase.auth.updateUser({ password });
    setPending(false);
    if (error) {
      setSubmitError(error.message);
      return;
    }
    router.replace("/login");
  }

  return (
    <Screen contentStyle={styles.screen}>
      <RouteHeader title="新しいパスワード" subtitle="8文字以上で設定してください" />
      <View style={styles.form}>
        <TextField
          label="新しいパスワード"
          onChangeText={setPassword}
          placeholder="8文字以上、英数字混在"
          secureTextEntry
          textContentType="newPassword"
          value={password}
        />
        <View style={styles.strengthRow}>
          {[1, 2, 3, 4].map((level) => (
            <View
              key={level}
              style={[
                styles.strengthBar,
                level <= strength.level ? { backgroundColor: strength.color } : null,
              ]}
            />
          ))}
          {strength.label ? (
            <Text style={[styles.strengthLabel, { color: strength.color }]}>
              {strength.label}
            </Text>
          ) : null}
        </View>
        <TextField
          label="新しいパスワード（確認）"
          onChangeText={setConfirm}
          placeholder="もう一度入力"
          secureTextEntry
          textContentType="newPassword"
          value={confirm}
        />
        {linkError || exchangeError || submitError ? (
          <Text style={styles.error}>{linkError ?? exchangeError ?? submitError}</Text>
        ) : null}
        {!sessionReady && !linkError && !exchangeError ? (
          <Text style={styles.helper}>リセットリンクを確認しています…</Text>
        ) : null}
        <PrimaryButton disabled={!canSubmit} loading={pending} onPress={submit}>
          パスワードを変更する
        </PrimaryButton>
      </View>
    </Screen>
  );
}

function getPasswordStrength(password: string) {
  if (!password) return { level: 0, label: "", color: "rgba(58,50,74,0.14)" };
  if (password.length < 8) return { level: 1, label: "弱い", color: megrumColors.warn };
  const hasLetter = /[a-zA-Z]/.test(password);
  const hasDigit = /\d/.test(password);
  const hasSymbol = /[^a-zA-Z\d]/.test(password);
  if (hasLetter && hasDigit && hasSymbol && password.length >= 12) {
    return { level: 4, label: "最強", color: megrumColors.ok };
  }
  if (hasLetter && hasDigit) return { level: 3, label: "強い", color: megrumColors.ok };
  if (hasLetter || hasDigit) return { level: 2, label: "普通", color: "#eab308" };
  return { level: 1, label: "弱い", color: megrumColors.warn };
}

const styles = StyleSheet.create({
  screen: {
    gap: 18,
  },
  form: {
    gap: 14,
  },
  strengthRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 5,
    marginTop: -6,
  },
  strengthBar: {
    backgroundColor: "rgba(58,50,74,0.14)",
    borderRadius: 999,
    flex: 1,
    height: 3,
  },
  strengthLabel: {
    fontSize: 10,
    fontWeight: "900",
    marginLeft: 4,
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
  helper: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
  },
});
