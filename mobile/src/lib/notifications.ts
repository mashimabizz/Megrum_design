import Constants from "expo-constants";
import * as Notifications from "expo-notifications";
import { Platform } from "react-native";
import { hasSupabaseConfig, supabase } from "./supabase";

export type RegisteredPushDevice = {
  id: string | null;
  token: string;
};

export type NotificationResponseData = {
  linkPath: string | null;
  notificationId: string | null;
};

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldPlaySound: true,
    shouldSetBadge: true,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

export async function requestExpoPushToken(): Promise<string | null> {
  try {
    const { status: existingStatus } =
      await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== "granted") {
      const { status } = await Notifications.requestPermissionsAsync();
      finalStatus = status;
    }

    if (finalStatus !== "granted") return null;

    if (Platform.OS === "android") {
      await Notifications.setNotificationChannelAsync("default", {
        name: "default",
        importance: Notifications.AndroidImportance.DEFAULT,
      });
    }

    const projectId =
      Constants.expoConfig?.extra?.eas?.projectId ??
      Constants.easConfig?.projectId;
    const token = await Notifications.getExpoPushTokenAsync(
      projectId ? { projectId } : undefined,
    );

    return token.data;
  } catch (error) {
    console.warn("Failed to request Expo push token", error);
    return null;
  }
}

export async function registerExpoPushTokenForUser(
  userId: string,
): Promise<RegisteredPushDevice | null> {
  if (!supabase || !hasSupabaseConfig || !userId) return null;
  const enabled = await getPushNotificationsEnabled(userId);
  if (!enabled) return null;

  const token = await requestExpoPushToken();
  if (!token) return null;

  const { data, error } = await supabase
    .from("notification_devices")
    .upsert(
      {
        app_version: Constants.expoConfig?.version ?? null,
        expo_push_token: token,
        last_seen_at: new Date().toISOString(),
        platform: notificationPlatform(),
        revoked_at: null,
        user_id: userId,
      },
      { onConflict: "user_id,expo_push_token" },
    )
    .select("id")
    .maybeSingle();

  if (error) {
    console.warn("Failed to register notification device", error.message);
    return { id: null, token };
  }

  return { id: typeof data?.id === "string" ? data.id : null, token };
}

export async function revokeExpoPushTokenForUser(userId: string, token: string) {
  if (!supabase || !hasSupabaseConfig || !userId || !token) return;
  const { error } = await supabase
    .from("notification_devices")
    .update({ revoked_at: new Date().toISOString() })
    .eq("user_id", userId)
    .eq("expo_push_token", token);
  if (error) {
    console.warn("Failed to revoke notification device", error.message);
  }
}

export async function getPushNotificationsEnabled(userId: string) {
  if (!supabase || !hasSupabaseConfig || !userId) return false;
  const { data, error } = await supabase
    .from("user_notification_settings")
    .select("push_enabled")
    .eq("user_id", userId)
    .maybeSingle();
  if (error) {
    console.warn("Failed to load push notification setting", error.message);
    return true;
  }
  return (data?.push_enabled as boolean | undefined) ?? true;
}

export async function setPushNotificationsEnabled(userId: string, enabled: boolean) {
  if (!supabase || !hasSupabaseConfig || !userId) return;
  const { error } = await supabase
    .from("user_notification_settings")
    .upsert(
      {
        push_enabled: enabled,
        user_id: userId,
      },
      { onConflict: "user_id" },
    );
  if (error) throw error;
}

export async function fetchUnreadNotificationCount(userId: string) {
  if (!supabase || !hasSupabaseConfig || !userId) return 0;
  const { count, error } = await supabase
    .from("notifications")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .is("read_at", null);
  if (error) throw error;
  return count ?? 0;
}

export async function markNotificationRead(userId: string, notificationId: string) {
  if (!supabase || !hasSupabaseConfig || !userId || !notificationId) return;
  const { error } = await supabase
    .from("notifications")
    .update({ read_at: new Date().toISOString() })
    .eq("id", notificationId)
    .eq("user_id", userId);
  if (error) throw error;
}

export async function setMobileNotificationBadgeCount(count: number) {
  try {
    await Notifications.setBadgeCountAsync(Math.max(0, count));
  } catch (error) {
    console.warn("Failed to set notification badge count", error);
  }
}

export function getNotificationResponseData(
  response: Notifications.NotificationResponse,
): NotificationResponseData {
  const data = response.notification.request.content.data as Record<string, unknown>;
  const linkPath =
    typeof data.linkPath === "string"
      ? data.linkPath
      : typeof data.link_path === "string"
        ? data.link_path
        : null;
  const notificationId =
    typeof data.notificationId === "string"
      ? data.notificationId
      : typeof data.notification_id === "string"
        ? data.notification_id
        : null;
  return { linkPath, notificationId };
}

function notificationPlatform() {
  if (Platform.OS === "ios") return "ios";
  if (Platform.OS === "android") return "android";
  return "web";
}
