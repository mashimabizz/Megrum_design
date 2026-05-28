import { useMemo, useState } from "react";
import { router, useLocalSearchParams } from "expo-router";
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
import { useAuth } from "../../src/auth/AuthProvider";
import { supabase } from "../../src/lib/supabase";
import { megrumColors, megrumRadii } from "../../src/theme/tokens";

type FieldErrors = Partial<Record<"handle" | "email" | "password" | "confirm" | "terms", string>>;

export default function SignUpScreen() {
  const params = useLocalSearchParams<{ terms?: string }>();
  const { signUp } = useAuth();
  const [handle, setHandle] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [terms, setTerms] = useState(() => params.terms === "1");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({});
  const strength = useMemo(() => getPasswordStrength(password), [password]);
  const normalizedHandle = handle.trim().toLowerCase();
  const canSubmit =
    /^[a-z0-9_]{3,20}$/.test(normalizedHandle) &&
    email.includes("@") &&
    password.length >= 8 &&
    password === confirm &&
    terms;

  async function submit() {
    const nextErrors: FieldErrors = {};
    setError(null);
    setFieldErrors({});

    if (!/^[a-z0-9_]{3,20}$/.test(normalizedHandle)) {
      nextErrors.handle = "ハンドル名は3〜20文字、英小文字・数字・_のみ";
    }
    if (!email.includes("@")) {
      nextErrors.email = "有効なメールアドレスを入力してください";
    }
    if (password.length < 8) {
      nextErrors.password = "パスワードは8文字以上で入力してください";
    }
    if (password !== confirm) {
      nextErrors.confirm = "パスワードが一致しません";
    }
    if (!terms) {
      nextErrors.terms = "利用規約とプライバシーポリシーへの同意が必要です";
    }
    if (Object.keys(nextErrors).length > 0) {
      setFieldErrors(nextErrors);
      return;
    }

    setPending(true);
    if (supabase) {
      const { data } = await supabase
        .from("users")
        .select("id")
        .eq("handle", normalizedHandle)
        .maybeSingle();
      if (data) {
        setPending(false);
        setFieldErrors({ handle: "このハンドル名は既に使われています" });
        return;
      }
    }

    const result = await signUp(email.trim(), password, {
      handle: normalizedHandle,
      displayName: normalizedHandle,
    });
    setPending(false);
    if (result) {
      setError(normalizeSignUpError(result));
      return;
    }
    router.push({ pathname: "/verify-email", params: { email: email.trim() } });
  }

  return (
    <Screen contentStyle={styles.screen}>
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        style={styles.keyboard}
      >
        <AuthHeader title="新規登録" backTo="/welcome" />
        <View>
          <Text style={styles.title}>はじめまして</Text>
          <Text style={styles.lead}>
            メールアドレスとパスワードを設定して、Megrum を始めましょう
          </Text>
        </View>

        <View style={styles.form}>
          <TextField
            label="ハンドル名"
            value={handle}
            onChangeText={(value) => setHandle(value.toLowerCase())}
            autoCapitalize="none"
            placeholder="megrum_xx"
          />
          <Text style={styles.hint}>@から始まる英数字、後から変更可能</Text>
          {fieldErrors.handle ? <Text style={styles.fieldError}>{fieldErrors.handle}</Text> : null}

          <TextField
            label="メールアドレス"
            value={email}
            onChangeText={setEmail}
            autoCapitalize="none"
            keyboardType="email-address"
            textContentType="emailAddress"
            placeholder="example@email.com"
          />
          {fieldErrors.email ? <Text style={styles.fieldError}>{fieldErrors.email}</Text> : null}

          <TextField
            label="パスワード"
            value={password}
            onChangeText={setPassword}
            secureTextEntry
            textContentType="newPassword"
            placeholder="8文字以上、英数字混在"
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
          {fieldErrors.password ? <Text style={styles.fieldError}>{fieldErrors.password}</Text> : null}

          <TextField
            label="パスワード（確認）"
            value={confirm}
            onChangeText={setConfirm}
            secureTextEntry
            textContentType="newPassword"
            placeholder="もう一度入力"
          />
          {fieldErrors.confirm ? <Text style={styles.fieldError}>{fieldErrors.confirm}</Text> : null}

          <Pressable
            accessibilityRole="checkbox"
            accessibilityState={{ checked: terms }}
            onPress={() => setTerms((value) => !value)}
            style={styles.termsRow}
          >
            <View style={[styles.checkbox, terms ? styles.checkboxActive : null]}>
              {terms ? <Text style={styles.checkText}>✓</Text> : null}
            </View>
            <Text style={styles.termsText}>
              利用規約とプライバシーポリシーに同意します
            </Text>
          </Pressable>
          {fieldErrors.terms ? <Text style={styles.fieldError}>{fieldErrors.terms}</Text> : null}
          {error ? <Text style={styles.error}>{error}</Text> : null}

          <PrimaryButton loading={pending} disabled={!canSubmit} onPress={submit}>
            次へ
          </PrimaryButton>
          <View style={styles.loginRow}>
            <Text style={styles.loginText}>すでにアカウントをお持ちの方は </Text>
            <Pressable onPress={() => router.replace("/login")}>
              <Text style={styles.loginLink}>ログイン</Text>
            </Pressable>
          </View>
        </View>
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

function normalizeSignUpError(message: string) {
  if (message.toLowerCase().includes("already")) {
    return "このメールアドレスは既に登録されています。ログインしてください";
  }
  return message;
}

const styles = StyleSheet.create({
  screen: {
    flexGrow: 1,
  },
  keyboard: {
    gap: 22,
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
  title: {
    color: megrumColors.ink,
    fontSize: 22,
    fontWeight: "900",
    lineHeight: 28,
  },
  lead: {
    color: megrumColors.mutedInk,
    fontSize: 12,
    fontWeight: "800",
    lineHeight: 19,
    marginTop: 6,
  },
  form: {
    gap: 11,
  },
  hint: {
    color: megrumColors.mutedInk,
    fontSize: 11,
    fontWeight: "700",
    marginTop: -6,
  },
  fieldError: {
    color: megrumColors.warn,
    fontSize: 11,
    fontWeight: "800",
    marginTop: -4,
  },
  strengthRow: {
    alignItems: "center",
    flexDirection: "row",
    gap: 5,
    marginTop: -4,
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
  termsRow: {
    alignItems: "flex-start",
    flexDirection: "row",
    gap: 10,
    paddingTop: 2,
  },
  checkbox: {
    alignItems: "center",
    borderColor: "rgba(58,50,74,0.20)",
    borderRadius: 5,
    borderWidth: 1.5,
    height: 20,
    justifyContent: "center",
    marginTop: 1,
    width: 20,
  },
  checkboxActive: {
    backgroundColor: megrumColors.lavender,
    borderColor: megrumColors.lavender,
  },
  checkText: {
    color: megrumColors.surface,
    fontSize: 13,
    fontWeight: "900",
  },
  termsText: {
    color: megrumColors.ink,
    flex: 1,
    fontSize: 13,
    fontWeight: "700",
    lineHeight: 20,
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
  divider: {
    alignItems: "center",
    flexDirection: "row",
    gap: 12,
    marginVertical: 2,
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
  loginRow: {
    alignItems: "center",
    flexDirection: "row",
    justifyContent: "center",
    paddingTop: 4,
  },
  loginText: {
    color: megrumColors.mutedInk,
    fontSize: 13,
    fontWeight: "700",
  },
  loginLink: {
    color: megrumColors.lavender,
    fontSize: 13,
    fontWeight: "900",
  },
});
