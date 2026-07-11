declare const Deno: {
  serve: (handler: (request: Request) => Response | Promise<Response>) => void;
  env: {
    get: (name: string) => string | undefined;
  };
};

// iter1226.462: めぐりメッセージの画像は送信から14日で有効期限切れ＝削除する。
// storage.objects への直接SQL削除は禁止されているため、この Edge Function が
// service role で Storage API 経由の削除と image_url の無効化を行う。
// 呼び出し元は pg_cron（public.expire_meguri_message_media → net.http_post）。
// 認証は APNs 配送と同じディスパッチシークレット（MEGRUM_APNS_DISPATCH_SECRET）を共用する。

const BUCKET = "meguri-message-media";
const RETENTION_DAYS = 14;
const BATCH_SIZE = 100;
const MAX_BATCHES = 20;

type ExpiredMessageRow = {
  id: string;
  image_path: string | null;
};

type RuntimeConfig = {
  supabaseURL: string;
  serviceRoleKey: string;
  dispatchSecret?: string;
};

Deno.serve(async (request) => {
  const config = loadConfig();

  const providedSecret = request.headers.get("x-megrum-dispatch-secret")?.trim();
  if (config.dispatchSecret && providedSecret !== config.dispatchSecret) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  const cutoff = new Date(Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000).toISOString();
  let removedObjects = 0;
  let clearedMessages = 0;

  try {
    for (let batch = 0; batch < MAX_BATCHES; batch += 1) {
      const rows = await fetchExpiredImageMessages(config, cutoff);
      if (rows.length === 0) {
        break;
      }

      const paths = rows
        .map((row) => row.image_path)
        .filter((path): path is string => typeof path === "string" && path.length > 0);
      if (paths.length > 0) {
        await removeStorageObjects(config, paths);
        removedObjects += paths.length;
      }

      await clearImageURLs(config, rows.map((row) => row.id));
      clearedMessages += rows.length;

      if (rows.length < BATCH_SIZE) {
        break;
      }
    }
  } catch (error) {
    console.error("expire-meguri-message-media failed", `${error}`);
    return jsonResponse(
      { error: "expiry_failed", removedObjects, clearedMessages },
      500,
    );
  }

  return jsonResponse({ ok: true, removedObjects, clearedMessages });
});

async function fetchExpiredImageMessages(
  config: RuntimeConfig,
  cutoff: string,
): Promise<ExpiredMessageRow[]> {
  const query = [
    "select=id,image_path",
    "message_type=eq.image",
    "image_url=not.is.null",
    `created_at=lt.${encodeURIComponent(cutoff)}`,
    `limit=${BATCH_SIZE}`,
  ].join("&");
  const response = await fetch(`${config.supabaseURL}/rest/v1/meguri_messages?${query}`, {
    headers: serviceHeaders(config),
  });
  if (!response.ok) {
    throw new Error(`fetch_expired_failed status=${response.status}`);
  }
  return (await response.json()) as ExpiredMessageRow[];
}

async function removeStorageObjects(config: RuntimeConfig, paths: string[]): Promise<void> {
  const response = await fetch(`${config.supabaseURL}/storage/v1/object/${BUCKET}`, {
    method: "DELETE",
    headers: {
      ...serviceHeaders(config),
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ prefixes: paths }),
  });
  // 404（既に消えている）は成功扱いにする。
  if (!response.ok && response.status !== 404) {
    throw new Error(`storage_remove_failed status=${response.status}`);
  }
}

async function clearImageURLs(config: RuntimeConfig, ids: string[]): Promise<void> {
  if (ids.length === 0) {
    return;
  }
  const idList = ids.map((id) => `"${id}"`).join(",");
  const response = await fetch(
    `${config.supabaseURL}/rest/v1/meguri_messages?id=in.(${encodeURIComponent(idList)})`,
    {
      method: "PATCH",
      headers: {
        ...serviceHeaders(config),
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({ image_url: null }),
    },
  );
  if (!response.ok) {
    throw new Error(`clear_image_urls_failed status=${response.status}`);
  }
}

function serviceHeaders(config: RuntimeConfig): Record<string, string> {
  return {
    apikey: config.serviceRoleKey,
    Authorization: `Bearer ${config.serviceRoleKey}`,
  };
}

function loadConfig(): RuntimeConfig {
  return {
    supabaseURL: requireEnv("SUPABASE_URL").replace(/\/$/g, ""),
    serviceRoleKey: requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
    dispatchSecret: Deno.env.get("MEGRUM_APNS_DISPATCH_SECRET")?.trim(),
  };
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new Error(`missing_env_${name}`);
  }
  return value;
}

function jsonResponse(payload: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
