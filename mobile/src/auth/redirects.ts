import Constants from "expo-constants";

const MOBILE_AUTH_CALLBACK_URL =
  process.env.EXPO_PUBLIC_AUTH_CALLBACK_URL ??
  "https://megrum.jp/auth/callback";

export function getMobileAuthEmailRedirectTo() {
  const separator = MOBILE_AUTH_CALLBACK_URL.includes("?") ? "&" : "?";
  return `${MOBILE_AUTH_CALLBACK_URL}${separator}next=mobile&scheme=${encodeURIComponent(
    getAppScheme(),
  )}`;
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
