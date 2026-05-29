import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/**
 * メール認証リンクのコールバック処理
 *
 * Supabase が送信した確認メールのリンクをクリックすると：
 *   https://megrum.jp/auth/callback?code=xxx
 * のようにアクセスされる。code を session に交換してユーザーをログイン状態にする。
 */
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  const error = searchParams.get("error");
  // デフォルト遷移先：認証完了画面（onboarding 完了済なら自動的に / へ）
  const next = searchParams.get("next") ?? "/auth/email-confirmed";

  if (next === "mobile") {
    return NextResponse.redirect(buildMobileAuthRedirect(searchParams));
  }

  if (code) {
    const supabase = await createClient();
    const { error, data } = await supabase.auth.exchangeCodeForSession(code);

    if (!error) {
      // メール認証完了 → account_status を 'registered' → 'verified' に同期
      // 既に onboarding/active のユーザーの再ログイン時は触らない
      if (data?.user) {
        await supabase
          .from("users")
          .update({
            account_status: "verified",
            email_verified_at: new Date().toISOString(),
          })
          .eq("id", data.user.id)
          .eq("account_status", "registered");
      }

      // 認証成功 → 元の遷移先 or ホームへ
      const forwardedHost = request.headers.get("x-forwarded-host");
      const isLocalEnv = process.env.NODE_ENV === "development";

      if (isLocalEnv) {
        return NextResponse.redirect(`${origin}${next}`);
      } else if (forwardedHost) {
        return NextResponse.redirect(`https://${forwardedHost}${next}`);
      } else {
        return NextResponse.redirect(`${origin}${next}`);
      }
    }
  }

  // エラー時はエラーページへ
  if (error) {
    return NextResponse.redirect(
      `${origin}/auth/auth-error?${searchParams.toString()}`,
    );
  }
  return NextResponse.redirect(`${origin}/auth/auth-error`);
}

function buildMobileAuthRedirect(searchParams: URLSearchParams) {
  const scheme = getMobileScheme(searchParams.get("scheme"));
  const params = new URLSearchParams();

  for (const key of ["code", "error", "error_code", "error_description"]) {
    const value = searchParams.get(key);
    if (value) params.set(key, value);
  }

  const query = params.toString();
  return `${scheme}:///auth/email-confirmed${query ? `?${query}` : ""}`;
}

function getMobileScheme(value: string | null) {
  return value === "megrum-preview" ? value : "megrum";
}
