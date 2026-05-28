const appJson = require("./app.json");

const variant = process.env.APP_VARIANT || process.env.EXPO_PUBLIC_APP_VARIANT || "development";
const isPreview = variant === "preview";
const projectId = appJson.expo.extra.eas.projectId;

module.exports = () => {
  const base = appJson.expo;

  return {
    ...base,
    name: isPreview ? "Megrum Preview" : base.name,
    scheme: isPreview ? "megrum-preview" : base.scheme,
    runtimeVersion: {
      policy: "appVersion",
    },
    updates: {
      url: `https://u.expo.dev/${projectId}`,
    },
    plugins: [
      ...(base.plugins ?? []),
      "expo-asset",
      "expo-camera",
      "expo-media-library",
    ],
    ios: {
      ...base.ios,
      bundleIdentifier: isPreview ? "tokyo.megrum.app.preview" : base.ios.bundleIdentifier,
      infoPlist: {
        ...base.ios.infoPlist,
        ...(isPreview ? { CFBundleDisplayName: "Megrum Preview" } : {}),
      },
    },
    extra: {
      ...base.extra,
      appVariant: variant,
    },
  };
};
