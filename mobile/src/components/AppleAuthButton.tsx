import { useEffect, useState } from "react";
import * as AppleAuthentication from "expo-apple-authentication";
import { router } from "expo-router";
import {
  ActivityIndicator,
  Platform,
  StyleSheet,
  View,
  type ViewStyle,
} from "react-native";
import { useAuth } from "../auth/AuthProvider";
import { megrumColors, megrumRadii } from "../theme/tokens";

type AppleAuthButtonProps = {
  disabled?: boolean;
  mode: "signIn" | "signUp";
  onError?: (message: string | null) => void;
  style?: ViewStyle;
};

export function AppleAuthButton({ disabled = false, mode, onError, style }: AppleAuthButtonProps) {
  const { configured, refreshProfile, signInWithAppleIdToken } = useAuth();
  const [available, setAvailable] = useState<boolean | null>(
    Platform.OS === "ios" ? null : false,
  );
  const [pending, setPending] = useState(false);

  useEffect(() => {
    let mounted = true;
    if (Platform.OS !== "ios") {
      setAvailable(false);
      return;
    }

    AppleAuthentication.isAvailableAsync()
      .then((result) => {
        if (mounted) setAvailable(result);
      })
      .catch(() => {
        if (mounted) setAvailable(false);
      });

    return () => {
      mounted = false;
    };
  }, []);

  if (!configured || available === false) return null;

  if (available === null) {
    return <View style={[styles.placeholder, style]} />;
  }

  const buttonType =
    mode === "signUp"
      ? AppleAuthentication.AppleAuthenticationButtonType.SIGN_UP
      : AppleAuthentication.AppleAuthenticationButtonType.SIGN_IN;

  async function handlePress() {
    if (disabled || pending) {
      onError?.("利用規約とプライバシーポリシーへの同意が必要です");
      return;
    }

    onError?.(null);
    setPending(true);
    try {
      const credential = await AppleAuthentication.signInAsync({
        requestedScopes: [
          AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
          AppleAuthentication.AppleAuthenticationScope.EMAIL,
        ],
      });

      if (!credential.identityToken) {
        onError?.("Apple IDの認証情報を取得できませんでした");
        return;
      }

      const error = await signInWithAppleIdToken(credential.identityToken);
      if (error) {
        onError?.(normalizeAppleAuthError(error));
        return;
      }
      const profile = await refreshProfile();
      const nextRoute =
        mode === "signUp" || !profile?.gender
          ? "/onboarding/gender"
          : !profile.hasOshi
            ? "/onboarding/oshi"
            : profile.accountStatus !== "active"
              ? "/onboarding/members"
              : "/";
      router.replace(nextRoute);
    } catch (error) {
      const code = typeof error === "object" && error && "code" in error ? error.code : null;
      if (code !== "ERR_REQUEST_CANCELED") {
        onError?.("Apple IDでの認証に失敗しました。もう一度お試しください");
      }
    } finally {
      setPending(false);
    }
  }

  return (
    <View style={[styles.wrapper, disabled ? styles.disabled : null, style]}>
      <AppleAuthentication.AppleAuthenticationButton
        buttonStyle={AppleAuthentication.AppleAuthenticationButtonStyle.BLACK}
        buttonType={buttonType}
        cornerRadius={megrumRadii.md}
        onPress={handlePress}
        style={styles.button}
      />
      {pending ? (
        <View style={styles.pendingOverlay}>
          <ActivityIndicator color="#fff" />
        </View>
      ) : null}
    </View>
  );
}

function normalizeAppleAuthError(message: string) {
  const lower = message.toLowerCase();
  if (lower.includes("provider") || lower.includes("apple")) {
    return "Apple IDログインがまだ有効化されていません。認証設定を確認してください";
  }
  if (lower.includes("invalid") || lower.includes("token")) {
    return "Apple IDの認証情報を確認できませんでした。もう一度お試しください";
  }
  return message;
}

const styles = StyleSheet.create({
  wrapper: {
    height: 50,
    position: "relative",
    width: "100%",
  },
  button: {
    height: 50,
    width: "100%",
  },
  disabled: {
    opacity: 0.55,
  },
  pendingOverlay: {
    alignItems: "center",
    backgroundColor: "rgba(0,0,0,0.18)",
    borderRadius: megrumRadii.md,
    bottom: 0,
    justifyContent: "center",
    left: 0,
    position: "absolute",
    right: 0,
    top: 0,
  },
  placeholder: {
    backgroundColor: megrumColors.surface,
    borderColor: "rgba(58,50,74,0.08)",
    borderRadius: megrumRadii.md,
    borderWidth: 1,
    height: 50,
  },
});
