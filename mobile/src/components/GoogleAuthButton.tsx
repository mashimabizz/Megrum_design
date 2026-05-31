import { useState } from "react";
import { useAuth } from "../auth/AuthProvider";
import { PrimaryButton } from "./PrimaryButton";

type GoogleAuthButtonProps = {
  disabled?: boolean;
  mode: "signIn" | "signUp";
  onError?: (message: string | null) => void;
};

export function GoogleAuthButton({
  disabled = false,
  mode,
  onError,
}: GoogleAuthButtonProps) {
  const { configured, signInWithGoogleOAuth } = useAuth();
  const [pending, setPending] = useState(false);

  if (!configured) return null;

  async function handlePress() {
    if (disabled || pending) {
      onError?.("利用規約とプライバシーポリシーへの同意が必要です");
      return;
    }

    onError?.(null);
    setPending(true);
    const error = await signInWithGoogleOAuth();
    setPending(false);
    if (error) {
      onError?.(normalizeGoogleAuthError(error));
      return;
    }
  }

  return (
    <PrimaryButton
      disabled={disabled}
      loading={pending}
      onPress={handlePress}
      variant="secondary"
    >
      {mode === "signUp" ? "Googleで新規登録" : "Googleでログイン"}
    </PrimaryButton>
  );
}

function normalizeGoogleAuthError(message: string) {
  const lower = message.toLowerCase();
  if (lower.includes("provider") || lower.includes("google")) {
    return "Googleログインがまだ有効化されていません。認証設定を確認してください";
  }
  if (lower.includes("redirect")) {
    return "Googleログインのリダイレクト設定を確認してください";
  }
  return message;
}
