import { Redirect, Stack } from "expo-router";
import { ActivityIndicator, View } from "react-native";
import { useAuth } from "../../src/auth/AuthProvider";
import { megrumColors } from "../../src/theme/tokens";

export default function AuthLayout() {
  const { configured, loading, needsOnboarding, onboardingPath, previewMode, profileLoading, session } =
    useAuth();

  if (loading || profileLoading) {
    return (
      <View
        style={{
          flex: 1,
          alignItems: "center",
          justifyContent: "center",
          backgroundColor: megrumColors.background,
        }}
      >
        <ActivityIndicator color={megrumColors.lavender} />
      </View>
    );
  }

  if (configured && session) {
    if (needsOnboarding) {
      return <Redirect href={onboardingPath ?? "/onboarding/gender"} />;
    }
    return <Redirect href="/" />;
  }

  if (previewMode) {
    return <Redirect href="/" />;
  }

  return (
    <Stack
      screenOptions={{
        headerShown: false,
        animation: "fade",
        contentStyle: { backgroundColor: megrumColors.background },
      }}
    />
  );
}
