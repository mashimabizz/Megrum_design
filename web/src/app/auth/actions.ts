"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

/**
 * 認証 Server Actions
 *
 * Phase 0b-2 で実装。
 * Webは管理者コンソール専用のため、通常ユーザー新規登録は提供しない。
 */

// バリデーションエラー型
type AuthResult = {
  error?: string;
  fieldErrors?: Record<string, string>;
};

// ----------------------------------------------------------------------
// login: メアド + パスワードでログイン
// ----------------------------------------------------------------------
export async function login(formData: FormData): Promise<AuthResult> {
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");

  if (!email || !password) {
    return { error: "メールアドレスとパスワードを入力してください" };
  }

  const supabase = await createClient();

  const { error } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    if (error.message.includes("Invalid login credentials")) {
      return { error: "メールアドレスまたはパスワードが正しくありません" };
    }
    if (error.message.includes("Email not confirmed")) {
      return { error: "メール認証が完了していません。受信メールを確認してください" };
    }
    return { error: error.message };
  }

  revalidatePath("/", "layout");
  redirect("/admin");
}

// ----------------------------------------------------------------------
// logout: ログアウト
// ----------------------------------------------------------------------
export async function logout(): Promise<void> {
  const supabase = await createClient();
  await supabase.auth.signOut();
  revalidatePath("/", "layout");
  redirect("/login");
}

// ----------------------------------------------------------------------
// signInWithGoogle: Google OAuth でログイン or 新規登録
// ----------------------------------------------------------------------
export async function signInWithGoogle(): Promise<AuthResult> {
  const supabase = await createClient();

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: "google",
    options: {
      redirectTo: `${getBaseUrl()}/auth/callback`,
      queryParams: {
        access_type: "offline",
        prompt: "consent",
      },
    },
  });

  if (error) {
    return { error: error.message };
  }

  // signInWithOAuth は url を返す → そこに redirect
  if (data?.url) {
    redirect(data.url);
  }

  return {};
}

// ----------------------------------------------------------------------
// passwordReset: パスワードリセット用メールを送信
// ----------------------------------------------------------------------
export async function passwordReset(formData: FormData): Promise<AuthResult> {
  const email = String(formData.get("email") ?? "").trim();

  if (!email || !email.includes("@")) {
    return {
      fieldErrors: { email: "有効なメールアドレスを入力してください" },
    };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${getBaseUrl()}/auth/password-reset-confirm`,
  });

  if (error) {
    if (error.message.includes("rate limit")) {
      return {
        error: "送信間隔が短すぎます。しばらく待ってから再度試してください",
      };
    }
    return { error: error.message };
  }

  redirect("/login?password_reset=sent");
}

// ----------------------------------------------------------------------
// setNewPassword: パスワードリセット後の新しいパスワードを設定
// ----------------------------------------------------------------------
export async function setNewPassword(
  password: string,
): Promise<AuthResult> {
  if (!password || password.length < 8) {
    return {
      fieldErrors: { password: "パスワードは 8 文字以上で入力してください" },
    };
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.updateUser({ password });

  if (error) {
    if (error.message.includes("New password should be different")) {
      return {
        fieldErrors: {
          password: "現在と同じパスワードは設定できません",
        },
      };
    }
    return { error: error.message };
  }

  return {};
}

// ----------------------------------------------------------------------
// ベース URL（リダイレクト先）
// ----------------------------------------------------------------------
function getBaseUrl(): string {
  // Vercel 本番: https://megrum.jp（カスタムドメイン）
  // Vercel Preview: https://xxxxx.vercel.app
  // ローカル: http://localhost:3000
  if (process.env.NEXT_PUBLIC_APP_URL) {
    return process.env.NEXT_PUBLIC_APP_URL;
  }
  if (process.env.VERCEL_URL) {
    return `https://${process.env.VERCEL_URL}`;
  }
  return "http://localhost:3000";
}
