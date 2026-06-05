import { useCallback, useEffect, useRef } from "react";
import { Stack, router } from "expo-router";
import * as Notifications from "expo-notifications";
import { StatusBar } from "expo-status-bar";
import { ActivityIndicator, Platform, View } from "react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { AuthProvider, useAuth } from "../src/auth/AuthProvider";
import { KeyboardDismissView } from "../src/components/KeyboardDismissView";
import { routeFromNotificationLinkPath } from "../src/lib/notificationRoutes";
import {
  fetchUnreadNotificationCount,
  getNotificationResponseData,
  markNotificationRead,
  registerExpoPushTokenForUser,
  revokeExpoPushTokenForUser,
  setMobileNotificationBadgeCount,
} from "../src/lib/notifications";
import { supabase } from "../src/lib/supabase";
import { megrumColors } from "../src/theme/tokens";

export default function RootLayout() {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <NotificationBootstrap />
        <KeyboardDismissView>
          <StatusBar style="dark" />
          <RootNavigator />
        </KeyboardDismissView>
      </AuthProvider>
    </SafeAreaProvider>
  );
}

function NotificationBootstrap() {
  const { previewMode, user } = useAuth();
  const handledResponses = useRef<Set<string>>(new Set());
  const notificationsAvailable = Platform.OS !== "web";

  const syncBadge = useCallback(async () => {
    if (!user?.id || previewMode) {
      await setMobileNotificationBadgeCount(0);
      return;
    }
    try {
      const count = await fetchUnreadNotificationCount(user.id);
      await setMobileNotificationBadgeCount(count);
    } catch (error) {
      console.warn("Failed to sync notification badge", error);
    }
  }, [previewMode, user?.id]);

  const handleNotificationResponse = useCallback(
    (response: Notifications.NotificationResponse) => {
      const { linkPath, notificationId } = getNotificationResponseData(response);
      const responseKey = [
        response.notification.request.identifier,
        notificationId,
        linkPath,
      ].join(":");
      if (handledResponses.current.has(responseKey)) return;
      handledResponses.current.add(responseKey);

      if (user?.id && notificationId) {
        markNotificationRead(user.id, notificationId)
          .then(syncBadge)
          .catch((error) => console.warn("Failed to mark notification read", error));
      }

      const route = routeFromNotificationLinkPath(linkPath);
      if (route) router.push(route);
    },
    [syncBadge, user?.id],
  );

  useEffect(() => {
    if (!notificationsAvailable) return;
    const subscription = Notifications.addNotificationResponseReceivedListener(
      handleNotificationResponse,
    );
    Notifications.getLastNotificationResponseAsync()
      .then((response) => {
        if (response) handleNotificationResponse(response);
      })
      .catch((error) => console.warn("Failed to read last notification response", error));
    return () => {
      subscription.remove();
    };
  }, [handleNotificationResponse, notificationsAvailable]);

  useEffect(() => {
    if (!notificationsAvailable) return;
    if (!user?.id || previewMode) {
      void setMobileNotificationBadgeCount(0);
      return;
    }

    let active = true;
    let registeredToken: string | null = null;

    registerExpoPushTokenForUser(user.id)
      .then((device) => {
        if (!active) return;
        registeredToken = device?.token ?? null;
      })
      .catch((error) => console.warn("Failed to register push token", error));

    return () => {
      active = false;
      if (registeredToken) {
        void revokeExpoPushTokenForUser(user.id, registeredToken);
      }
    };
  }, [notificationsAvailable, previewMode, user?.id]);

  useEffect(() => {
    if (!notificationsAvailable) return;
    const client = supabase;
    if (!client || !user?.id || previewMode) {
      void setMobileNotificationBadgeCount(0);
      return;
    }

    void syncBadge();
    const channel = client
      .channel(`mobile-notifications:${user.id}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          filter: `user_id=eq.${user.id}`,
          schema: "public",
          table: "notifications",
        },
        () => {
          void syncBadge();
        },
      )
      .subscribe();

    return () => {
      void client.removeChannel(channel);
    };
  }, [notificationsAvailable, previewMode, syncBadge, user?.id]);

  return null;
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
