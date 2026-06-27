import { NextResponse } from "next/server";

const allowedProviders = new Set(["google"]);
const allowedCallbackSchemes = new Set(["megrum", "megrum-preview"]);
const defaultScopes = "email profile";

export function GET(request: Request) {
  const requestURL = new URL(request.url);
  const provider = normalizedProvider(requestURL.searchParams.get("provider"));
  const redirectTo = normalizedNativeRedirectTo(
    requestURL.searchParams.get("redirect_to"),
  );
  const supabaseURL = normalizedSupabaseURL(
    process.env.NEXT_PUBLIC_SUPABASE_URL ?? process.env.MEGRUM_SUPABASE_URL,
  );

  if (!provider || !redirectTo) {
    return new NextResponse("Invalid OAuth request", { status: 400 });
  }

  if (!supabaseURL) {
    return new NextResponse("Supabase URL is not configured", { status: 500 });
  }

  const authorizeURL = new URL("/auth/v1/authorize", supabaseURL);
  authorizeURL.searchParams.set("provider", provider);
  authorizeURL.searchParams.set("redirect_to", redirectTo);
  authorizeURL.searchParams.set(
    "scopes",
    normalizedScopes(requestURL.searchParams.get("scopes")),
  );

  const response = NextResponse.redirect(authorizeURL);
  response.headers.set("cache-control", "no-store");
  return response;
}

function normalizedProvider(value: string | null) {
  const provider = value?.trim().toLowerCase();
  return provider && allowedProviders.has(provider) ? provider : null;
}

function normalizedNativeRedirectTo(value: string | null) {
  if (!value) return null;

  try {
    const url = new URL(value);
    const scheme = url.protocol.replace(/:$/, "");
    if (!allowedCallbackSchemes.has(scheme)) return null;
    if (url.hostname !== "auth" || url.pathname !== "/callback") return null;
    return `${scheme}://auth/callback`;
  } catch {
    return null;
  }
}

function normalizedSupabaseURL(value: string | undefined) {
  if (!value) return null;

  try {
    const url = new URL(value.trim());
    return url.protocol === "https:" && url.hostname ? url : null;
  } catch {
    return null;
  }
}

function normalizedScopes(value: string | null) {
  const scopes = (value ?? defaultScopes)
    .split(/[\s,]+/)
    .map((scope) => scope.trim())
    .filter(Boolean);

  return scopes.length > 0 ? scopes.join(" ") : defaultScopes;
}
