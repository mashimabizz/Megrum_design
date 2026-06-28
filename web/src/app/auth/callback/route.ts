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
  // Webは管理者コンソール専用。認証後はadminへ戻す。
  const next = searchParams.get("next") ?? "/admin";

  if (next === "mobile") {
    return handleMobileAuthCallback(searchParams);
  }

  if (code) {
    const supabase = await createClient();
    const { error, data } = await supabase.auth.exchangeCodeForSession(code);

    if (!error) {
      if (data?.user) {
        await markRegisteredUserVerified(supabase, data.user.id);
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

async function handleMobileAuthCallback(searchParams: URLSearchParams) {
  const code = searchParams.get("code");
  const error = searchParams.get("error");

  if (error || !code) {
    if (!error && !code) {
      return buildMobileFragmentBridgeResponse(searchParams);
    }
    return NextResponse.redirect(buildMobileAuthRedirect(searchParams));
  }

  const supabase = await createClient();
  const { error: exchangeError, data } = await supabase.auth.exchangeCodeForSession(code);

  if (exchangeError || !data?.session) {
    return NextResponse.redirect(
      buildMobileAuthRedirect(
        searchParams,
        undefined,
        exchangeError?.message ?? "auth_callback_failed",
      ),
    );
  }

  if (data.user) {
    await markRegisteredUserVerified(supabase, data.user.id);
  }

  return NextResponse.redirect(buildMobileAuthRedirect(searchParams, data.session));
}

async function markRegisteredUserVerified(
  supabase: Awaited<ReturnType<typeof createClient>>,
  userId: string,
) {
  // メール認証完了 → account_status を 'registered' → 'verified' に同期。
  // 既に onboarding/active のユーザーの再ログイン時は触らない。
  await supabase
    .from("users")
    .update({
      account_status: "verified",
      email_verified_at: new Date().toISOString(),
    })
    .eq("id", userId)
    .eq("account_status", "registered");
}

function buildMobileAuthRedirect(
  searchParams: URLSearchParams,
  session?: {
    access_token: string;
    refresh_token?: string;
    expires_in?: number;
    expires_at?: number;
    token_type?: string;
  },
  fallbackError?: string,
) {
  const scheme = getMobileScheme(searchParams.get("scheme"));
  const params = new URLSearchParams();

  if (session) {
    params.set("access_token", session.access_token);
    if (session.refresh_token) params.set("refresh_token", session.refresh_token);
    if (session.expires_in) params.set("expires_in", String(session.expires_in));
    if (session.expires_at) params.set("expires_at", String(session.expires_at));
    if (session.token_type) params.set("token_type", session.token_type);
  }

  for (const key of ["error", "error_code", "error_description", "provider"]) {
    const value = searchParams.get(key);
    if (value) params.set(key, value);
  }
  if (!session && fallbackError) params.set("error_description", fallbackError);

  const serialized = params.toString();
  return `${scheme}://auth/callback${serialized ? `#${serialized}` : ""}`;
}

function buildMobileFragmentBridgeResponse(searchParams: URLSearchParams) {
  const target = `${getMobileScheme(searchParams.get("scheme"))}://auth/callback`;
  const html = `<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Megrum</title>
</head>
<body>
  <script>
    const target = ${JSON.stringify(target)};
    const hash = window.location.hash || "";
    if (hash.length > 1) {
      window.location.replace(target + hash);
    } else {
      window.location.replace(target + "#error_description=auth_callback_missing_session");
    }
  </script>
</body>
</html>`;

  return new NextResponse(html, {
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

function getMobileScheme(value: string | null) {
  return value === "megrum-preview" ? value : "megrum";
}
