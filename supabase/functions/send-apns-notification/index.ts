declare const Deno: {
  serve: (handler: (request: Request) => Response | Promise<Response>) => void;
  env: {
    get: (name: string) => string | undefined;
  };
};

type NotificationRow = {
  id: string;
  user_id: string;
  kind: string;
  title: string;
  body: string | null;
  link_path: string | null;
};

type NotificationDeviceRow = {
  id: string;
  native_device_token: string | null;
};

type APNsResult = {
  deviceID: string;
  deviceTokenSuffix: string;
  status: number;
  reason?: string;
  revoked: boolean;
};

type DispatchResult = {
  notificationID: string;
  attempted: number;
  delivered: number;
  revoked: number;
  results: APNsResult[];
};

type RuntimeConfig = {
  supabaseURL: string;
  serviceRoleKey: string;
  dispatchSecret?: string;
  apnsTeamID: string;
  apnsKeyID: string;
  apnsPrivateKey: string;
  apnsBundleID: string;
  apnsEnvironment: "development" | "production";
};

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
};

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  let config: RuntimeConfig;
  try {
    config = readConfig();
  } catch (error) {
    console.error("send-apns-notification configuration error", publicErrorCode(error));
    return jsonResponse({ error: "missing_configuration" }, 500);
  }

  if (!isAuthorized(request, config)) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  let notificationID: string;
  try {
    const payload = await request.json();
    notificationID = requireString(payload?.notification_id ?? payload?.notificationId, "notification_id");
  } catch (error) {
    return jsonResponse({ error: "invalid_payload", detail: publicErrorCode(error) }, 400);
  }

  try {
    const result = await dispatchNotification(notificationID, config);
    return jsonResponse(result, 200);
  } catch (error) {
    console.error("send-apns-notification dispatch failed", publicErrorCode(error));
    return jsonResponse({ error: "dispatch_failed", detail: publicErrorCode(error) }, 500);
  }
});

async function dispatchNotification(notificationID: string, config: RuntimeConfig): Promise<DispatchResult> {
  const notification = await loadNotification(notificationID, config);
  const [devices, unreadCount, jwt] = await Promise.all([
    loadAPNsDevices(notification.user_id, config),
    loadUnreadCount(notification.user_id, config),
    makeAPNsJWT(config),
  ]);

  const results: APNsResult[] = [];
  for (const device of devices) {
    if (!device.native_device_token) {
      continue;
    }
    const result = await sendAPNsNotification(notification, device, unreadCount, jwt, config);
    results.push(result);
    if (result.revoked) {
      await revokeDevice(device.id, config);
    }
  }

  return {
    notificationID,
    attempted: results.length,
    delivered: results.filter((result) => result.status >= 200 && result.status < 300).length,
    revoked: results.filter((result) => result.revoked).length,
    results,
  };
}

async function loadNotification(notificationID: string, config: RuntimeConfig): Promise<NotificationRow> {
  const rows = await supabaseFetch<NotificationRow[]>(
    `/rest/v1/notifications?select=id,user_id,kind,title,body,link_path&id=eq.${encodeURIComponent(notificationID)}&limit=1`,
    config,
  );
  const notification = rows[0];
  if (!notification) {
    throw new Error("notification_not_found");
  }
  return notification;
}

async function loadAPNsDevices(userID: string, config: RuntimeConfig): Promise<NotificationDeviceRow[]> {
  return await supabaseFetch<NotificationDeviceRow[]>(
    [
      "/rest/v1/notification_devices?select=id,native_device_token",
      `user_id=eq.${encodeURIComponent(userID)}`,
      "platform=eq.ios",
      "push_provider=eq.apns",
      "revoked_at=is.null",
      "native_device_token=not.is.null",
    ].join("&"),
    config,
  );
}

async function loadUnreadCount(userID: string, config: RuntimeConfig): Promise<number> {
  const response = await fetch(`${config.supabaseURL}/rest/v1/notifications?select=id&user_id=eq.${encodeURIComponent(userID)}&read_at=is.null`, {
    headers: {
      ...supabaseHeaders(config),
      prefer: "count=exact",
    },
  });
  if (!response.ok) {
    throw new Error(`unread_count_failed:${response.status}`);
  }
  const contentRange = response.headers.get("content-range");
  if (contentRange?.includes("/")) {
    const count = Number(contentRange.split("/").pop());
    if (Number.isFinite(count)) {
      return count;
    }
  }
  const rows = await response.json() as unknown[];
  return rows.length;
}

async function sendAPNsNotification(
  notification: NotificationRow,
  device: NotificationDeviceRow,
  unreadCount: number,
  jwt: string,
  config: RuntimeConfig,
): Promise<APNsResult> {
  const deviceToken = requireString(device.native_device_token, "native_device_token");
  const payload = {
    aps: {
      alert: {
        title: notification.title,
        body: notification.body ?? "",
      },
      badge: unreadCount,
      sound: "default",
    },
    notificationId: notification.id,
    kind: notification.kind,
    linkPath: notification.link_path ?? "/notifications",
  };

  const response = await fetch(`${apnsBaseURL(config)}/3/device/${encodeURIComponent(deviceToken)}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${jwt}`,
      "apns-topic": config.apnsBundleID,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const apnsBody = response.status === 200 ? undefined : await parseAPNsReason(response);
  const reason = apnsBody?.reason;
  return {
    deviceID: device.id,
    deviceTokenSuffix: deviceToken.slice(-8),
    status: response.status,
    reason,
    revoked: response.status === 410 || reason === "BadDeviceToken" || reason === "Unregistered",
  };
}

async function revokeDevice(deviceID: string, config: RuntimeConfig): Promise<void> {
  const response = await fetch(
    `${config.supabaseURL}/rest/v1/notification_devices?id=eq.${encodeURIComponent(deviceID)}`,
    {
      method: "PATCH",
      headers: {
        ...supabaseHeaders(config),
        prefer: "return=minimal",
      },
      body: JSON.stringify({ revoked_at: new Date().toISOString() }),
    },
  );
  if (!response.ok) {
    throw new Error(`device_revoke_failed:${response.status}`);
  }
}

async function supabaseFetch<T>(path: string, config: RuntimeConfig): Promise<T> {
  const response = await fetch(`${config.supabaseURL}${path}`, {
    headers: supabaseHeaders(config),
  });
  if (!response.ok) {
    throw new Error(`supabase_fetch_failed:${response.status}`);
  }
  return await response.json() as T;
}

function supabaseHeaders(config: RuntimeConfig): HeadersInit {
  return {
    apikey: config.serviceRoleKey,
    authorization: `Bearer ${config.serviceRoleKey}`,
    accept: "application/json",
    "content-type": "application/json",
  };
}

async function makeAPNsJWT(config: RuntimeConfig): Promise<string> {
  const header = base64URLJSON({ alg: "ES256", kid: config.apnsKeyID });
  const claims = base64URLJSON({
    iss: config.apnsTeamID,
    iat: Math.floor(Date.now() / 1000),
  });
  const unsignedToken = `${header}.${claims}`;
  const key = await importAPNsPrivateKey(config.apnsPrivateKey);
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(unsignedToken),
  );
  return `${unsignedToken}.${base64URLBytes(new Uint8Array(signature))}`;
}

async function importAPNsPrivateKey(privateKey: string): Promise<CryptoKey> {
  const normalized = privateKey.replaceAll("\\n", "\n");
  const base64 = normalized
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const binary = Uint8Array.from(atob(base64), (character) => character.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}

function base64URLJSON(value: unknown): string {
  return base64URLBytes(new TextEncoder().encode(JSON.stringify(value)));
}

function base64URLBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary)
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replace(/=+$/g, "");
}

async function parseAPNsReason(response: Response): Promise<{ reason?: string }> {
  try {
    return await response.json() as { reason?: string };
  } catch {
    return {};
  }
}

function apnsBaseURL(config: RuntimeConfig): string {
  return config.apnsEnvironment === "production"
    ? "https://api.push.apple.com"
    : "https://api.sandbox.push.apple.com";
}

function readConfig(): RuntimeConfig {
  return {
    supabaseURL: requireEnv("SUPABASE_URL").replace(/\/$/g, ""),
    serviceRoleKey: requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
    dispatchSecret: Deno.env.get("MEGRUM_APNS_DISPATCH_SECRET")?.trim(),
    apnsTeamID: requireEnv("MEGRUM_APNS_TEAM_ID"),
    apnsKeyID: requireEnv("MEGRUM_APNS_KEY_ID"),
    apnsPrivateKey: requireEnv("MEGRUM_APNS_PRIVATE_KEY"),
    apnsBundleID: requireEnv("MEGRUM_APNS_BUNDLE_ID"),
    apnsEnvironment: readAPNsEnvironment(),
  };
}

function readAPNsEnvironment(): "development" | "production" {
  const value = Deno.env.get("MEGRUM_APNS_ENVIRONMENT")?.trim().toLowerCase();
  if (!value || value === "production" || value === "prod") {
    return "production";
  }
  if (value === "development" || value === "sandbox" || value === "dev") {
    return "development";
  }
  throw new Error("MEGRUM_APNS_ENVIRONMENT must be production or development");
}

function isAuthorized(request: Request, config: RuntimeConfig): boolean {
  const secret = request.headers.get("x-megrum-dispatch-secret")?.trim();
  if (config.dispatchSecret && secret === config.dispatchSecret) {
    return true;
  }

  const authorization = request.headers.get("authorization")?.trim();
  return authorization === `Bearer ${config.serviceRoleKey}`;
}

function requireEnv(name: string): string {
  return requireString(Deno.env.get(name), name);
}

function requireString(value: unknown, name: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(`${name} is required`);
  }
  return value.trim();
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function publicErrorCode(error: unknown): string {
  const message = messageOf(error);
  if (message === "notification_not_found") {
    return message;
  }
  for (const prefix of [
    "unread_count_failed",
    "device_revoke_failed",
    "supabase_fetch_failed",
  ]) {
    if (message.startsWith(`${prefix}:`)) {
      return prefix;
    }
  }
  if (message.endsWith(" is required")) {
    return "required_value_missing";
  }
  if (message.startsWith("MEGRUM_APNS_ENVIRONMENT")) {
    return "configuration_invalid";
  }
  return "dispatch_error";
}
