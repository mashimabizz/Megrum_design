import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { ActivityIndicator, View } from "react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { AuthProvider, useAuth } from "../src/auth/AuthProvider";
import { KeyboardDismissView } from "../src/components/KeyboardDismissView";
import { megrumColors } from "../src/theme/tokens";

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <KeyboardDismissView>
          <StatusBar style="dark" />
          <RootNavigator />
        </KeyboardDismissView>
      </AuthProvider>
    </SafeAreaProvider>
  );
}

function RootNavigator() {
  const { loading, profileLoading } = useAuth();

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

  return (
    <Stack
      screenOptions={{
        headerShown: false,
        animation: "slide_from_right",
        contentStyle: { backgroundColor: megrumColors.background },
      }}
    >
      <Stack.Screen name="(tabs)" options={{ gestureEnabled: false }} />
      <Stack.Screen name="(auth)" />
    </Stack>
  );
}
