import Constants from "expo-constants";

const MOBILE_AUTH_CALLBACK_URL =
  process.env.EXPO_PUBLIC_AUTH_CALLBACK_URL ??
  "https://megrum.jp/auth/callback";

export function getMobileAuthEmailRedirectTo() {
  return buildMobileAuthRedirectTo();
}

export function getMobileAuthOAuthRedirectTo(provider: "google") {
  return buildMobileAuthRedirectTo({ provider });
}

function buildMobileAuthRedirectTo(extraParams?: Record<string, string>) {
  const separator = MOBILE_AUTH_CALLBACK_URL.includes("?") ? "&" : "?";
  const params = new URLSearchParams({
    next: "mobile",
    scheme: getAppScheme(),
    ...extraParams,
  });
  return `${MOBILE_AUTH_CALLBACK_URL}${separator}${params.toString()}`;
}

function getAppScheme() {
  const configuredScheme = Constants.expoConfig?.scheme;
  if (Array.isArray(configuredScheme) && configuredScheme[0]) {
    return configuredScheme[0];
  }
  if (typeof configuredScheme === "string" && configuredScheme) {
    return configuredScheme;
  }
  return Constants.expoConfig?.extra?.appVariant === "preview"
    ? "megrum-preview"
    : "megrum";
}
