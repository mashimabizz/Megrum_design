declare const Deno: {
  serve: (handler: (request: Request) => Response | Promise<Response>) => void;
  env: {
    get: (name: string) => string | undefined;
  };
};

type RuntimeConfig = {
  supabaseURL: string;
  serviceRoleKey: string;
  openAIAPIKey: string;
  openAIModel: string;
};

type SuggestionImage = {
  base64?: string;
  content_type?: string;
  contentType?: string;
  url?: string;
};

type SuggestionPayload = {
  images?: SuggestionImage[];
  group_name?: string;
  groupName?: string;
  member_name?: string;
  memberName?: string;
  goods_type_name?: string;
  goodsTypeName?: string;
  existing_candidate_names?: string[];
  existingCandidateNames?: string[];
};

type NormalizedPayload = {
  images: SuggestionImage[];
  groupName?: string;
  memberName?: string;
  goodsTypeName?: string;
  existingCandidateNames: string[];
};

type OpenAIContent = {
  type: "input_text" | "input_image";
  text?: string;
  image_url?: string;
};

const jsonHeaders = {
  "content-type": "application/json; charset=utf-8",
};
const maxImageCount = 3;
const maxImageBase64Length = 12_000_000;

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: jsonHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  let config: RuntimeConfig;
  try {
    config = readConfig();
  } catch (error) {
    return jsonResponse({ error: "missing_configuration", detail: messageOf(error) }, 500);
  }

  try {
    await requireAuthenticatedUser(request, config);
  } catch (error) {
    return jsonResponse({ error: "unauthorized", detail: messageOf(error) }, 401);
  }

  let payload: NormalizedPayload;
  try {
    payload = normalizePayload(await request.json() as SuggestionPayload);
  } catch (error) {
    return jsonResponse({ error: "invalid_payload", detail: messageOf(error) }, 400);
  }

  try {
    const suggestions = await suggestSeriesNames(payload, config);
    return jsonResponse({ suggestions }, 200);
  } catch (error) {
    return jsonResponse({ error: "suggestion_failed", detail: messageOf(error) }, 502);
  }
});

async function requireAuthenticatedUser(request: Request, config: RuntimeConfig): Promise<string> {
  const authorization = request.headers.get("authorization")?.trim();
  if (!authorization?.toLowerCase().startsWith("bearer ")) {
    throw new Error("authorization bearer token is required");
  }

  const response = await fetch(`${config.supabaseURL}/auth/v1/user`, {
    headers: {
      apikey: config.serviceRoleKey,
      authorization,
      accept: "application/json",
    },
  });
  if (!response.ok) {
    throw new Error(`auth_user_failed:${response.status}`);
  }
  const user = await response.json() as { id?: string };
  return requireString(user.id, "auth user id");
}

async function suggestSeriesNames(payload: NormalizedPayload, config: RuntimeConfig): Promise<string[]> {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      authorization: `Bearer ${config.openAIAPIKey}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: config.openAIModel,
      tools: [{ type: "web_search_preview" }],
      input: [
        {
          role: "user",
          content: [
            { type: "input_text", text: promptFor(payload) },
            ...payload.images.map(openAIImageContent),
          ],
        },
      ],
    }),
  });

  if (!response.ok) {
    throw new Error(`openai_failed:${response.status}:${await response.text()}`);
  }

  const body = await response.json();
  const text = extractResponseText(body);
  return parseSuggestions(text);
}

function normalizePayload(payload: SuggestionPayload): NormalizedPayload {
  const rawImages = Array.isArray(payload.images) ? payload.images.slice(0, maxImageCount) : [];
  const images = rawImages.filter((image) => {
    if (typeof image.url === "string" && image.url.trim().length > 0) {
      return true;
    }
    return typeof image.base64 === "string"
      && image.base64.trim().length > 0
      && image.base64.length <= maxImageBase64Length;
  });
  if (images.length === 0) {
    throw new Error("at least one image is required");
  }

  return {
    images,
    groupName: optionalString(payload.group_name ?? payload.groupName),
    memberName: optionalString(payload.member_name ?? payload.memberName),
    goodsTypeName: optionalString(payload.goods_type_name ?? payload.goodsTypeName),
    existingCandidateNames: normalizeNames(
      payload.existing_candidate_names ?? payload.existingCandidateNames ?? [],
      10,
    ),
  };
}

function openAIImageContent(image: SuggestionImage): OpenAIContent {
  if (typeof image.url === "string" && image.url.trim().length > 0) {
    return { type: "input_image", image_url: image.url.trim() };
  }
  const contentType = optionalString(image.content_type ?? image.contentType) ?? "image/jpeg";
  return {
    type: "input_image",
    image_url: `data:${contentType};base64,${requireString(image.base64, "image base64")}`,
  };
}

function promptFor(payload: NormalizedPayload): string {
  const context = [
    payload.groupName ? `グループ・作品: ${payload.groupName}` : undefined,
    payload.memberName ? `メンバー・キャラクター: ${payload.memberName}` : undefined,
    payload.goodsTypeName ? `グッズ種別: ${payload.goodsTypeName}` : undefined,
    payload.existingCandidateNames.length > 0
      ? `アプリ内の既存シリーズ候補: ${payload.existingCandidateNames.join(", ")}`
      : undefined,
  ].filter(Boolean).join("\n");

  return [
    "あなたは日本語の推し活グッズ分類アシスタントです。",
    "添付画像を手がかりに、グッズのシリーズ名・販売企画名・特典名として使えそうな候補を推定してください。",
    "必要に応じてWeb検索で画像や文脈を確認してください。",
    "グループ名、メンバー名、グッズ種別だけの一般名は候補にしないでください。",
    "候補は短く、アプリ内のシリーズタグとして自然な日本語または公式表記にしてください。",
    "確度が低い候補は出しすぎず、最大6件にしてください。",
    context ? `\n文脈:\n${context}` : "",
    '\n出力はJSONのみ: {"suggestions":["候補1","候補2"]}',
  ].join("\n");
}

function extractResponseText(body: unknown): string {
  if (isRecord(body) && typeof body.output_text === "string") {
    return body.output_text;
  }
  if (!isRecord(body) || !Array.isArray(body.output)) {
    return "";
  }

  const parts: string[] = [];
  for (const output of body.output) {
    if (!isRecord(output) || !Array.isArray(output.content)) {
      continue;
    }
    for (const content of output.content) {
      if (isRecord(content) && typeof content.text === "string") {
        parts.push(content.text);
      }
    }
  }
  return parts.join("\n");
}

function parseSuggestions(text: string): string[] {
  const trimmed = text.trim();
  const jsonText = trimmed.startsWith("{") ? trimmed : trimmed.match(/\{[\s\S]*\}/)?.[0];
  if (!jsonText) {
    return [];
  }
  const parsed = JSON.parse(jsonText) as { suggestions?: unknown; candidates?: unknown };
  const suggestionNames = Array.isArray(parsed.suggestions) ? parsed.suggestions : [];
  const candidateNames = Array.isArray(parsed.candidates)
    ? parsed.candidates.map((candidate) => {
      if (typeof candidate === "string") {
        return candidate;
      }
      if (isRecord(candidate) && typeof candidate.name === "string") {
        return candidate.name;
      }
      return "";
    })
    : [];
  return normalizeNames([...suggestionNames, ...candidateNames], 6);
}

function normalizeNames(names: unknown[], limit: number): string[] {
  const seen = new Set<string>();
  const result: string[] = [];
  for (const name of names) {
    if (result.length >= limit || typeof name !== "string") {
      continue;
    }
    const normalized = name.trim().replace(/^[#＃]+/g, "").trim().slice(0, 40);
    if (!normalized) {
      continue;
    }
    const key = normalized.toLocaleLowerCase();
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    result.push(normalized);
  }
  return result;
}

function readConfig(): RuntimeConfig {
  return {
    supabaseURL: requireEnv("SUPABASE_URL").replace(/\/$/g, ""),
    serviceRoleKey: requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
    openAIAPIKey: requireEnv("OPENAI_API_KEY"),
    openAIModel: optionalString(Deno.env.get("MEGRUM_SERIES_SUGGESTION_MODEL")) ?? "gpt-4.1-mini",
  };
}

function optionalString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
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

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
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
