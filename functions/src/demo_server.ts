import {createServer, type IncomingMessage, type ServerResponse} from "node:http";
import {readFileSync, existsSync} from "node:fs";
import {resolve} from "node:path";
import {
  buildLocationContext,
  type LocationContext,
  normalizeArticleStyle,
  normalizeReviewDraft,
  normalizeReviewDraftArray,
  reviewStyleInstructions,
} from "./ai_review_utils";

class ApiError extends Error {
  constructor(
    readonly statusCode: number,
    message: string,
  ) {
    super(message);
  }
}

function loadEnvFile(): void {
  const candidatePaths = [
    resolve(process.cwd(), ".env"),
    resolve(process.cwd(), "..", ".env"),
  ];

  for (const envPath of candidatePaths) {
    if (!existsSync(envPath)) continue;

    const raw = readFileSync(envPath, "utf8");
    for (const line of raw.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) continue;

      const separatorIndex = trimmed.indexOf("=");
      if (separatorIndex <= 0) continue;

      const key = trimmed.slice(0, separatorIndex).trim();
      const value = trimmed.slice(separatorIndex + 1).trim();
      if (!process.env[key]) {
        process.env[key] = value;
      }
    }

    return;
  }
}

loadEnvFile();

const defaultModel = process.env.AI_PROXY_MODEL?.trim() || "gpt-5.4";
const defaultPort = Number(process.env.AI_SERVER_PORT ?? "8787");
const defaultHost = process.env.AI_SERVER_HOST?.trim() || "0.0.0.0";
const cliProxyBaseUrl = normalizeBaseUrl(
  process.env.AI_PROXY_BASE_URL ?? "http://127.0.0.1:8317",
);
const cliProxyApiKey = process.env.AI_PROXY_API_KEY?.trim() || "your-api-key-1";
const fallbackModels = parseFallbackModels(process.env.AI_PROXY_FALLBACK_MODELS);
const perplexityBaseUrl = normalizeBaseUrl(
  process.env.PERPLEXITY_BASE_URL ?? "https://api.perplexity.ai",
);
const perplexityApiKey = process.env.PERPLEXITY_API_KEY?.trim();
const perplexityModel = process.env.PERPLEXITY_MODEL?.trim() || "sonar-pro";
const deepseekBaseUrl = normalizeBaseUrl(
  process.env.DEEPSEEK_BASE_URL ?? "https://api.deepseek.com",
);
const deepseekApiKey = process.env.DEEPSEEK_API_KEY?.trim() || "sk-208e0237f1334590b10a4205060bb8e3";
const deepseekModel = process.env.DEEPSEEK_MODEL?.trim() || "deepseek-chat";
const hasAnyAiProvider = !!(perplexityApiKey || deepseekApiKey);
const reviewSearchDomainFilter = [
  "-facebook.com",
  "-instagram.com",
  "-twitter.com",
  "-x.com",
  "-reddit.com",
];
const reviewImageDomainFilter = [
  "-shutterstock.com",
  "-gettyimages.com",
  "-alamy.com",
  "-pinterest.com",
];

function normalizeBaseUrl(value: string): string {
  const trimmed = value.trim();
  return trimmed.endsWith("/") ? trimmed.slice(0, -1) : trimmed;
}

function parseFallbackModels(value: string | undefined): string[] {
  const defaults = [
    "gpt-5.2",
    "gpt-5.1",
    "gpt-5",
    "gpt-5.2-codex",
    "gpt-5.1-codex",
    "gpt-5-codex",
  ];
  const raw = value?.trim();
  if (!raw) {
    return defaults;
  }

  const seen = new Set<string>();
  const parsed = raw
    .split(",")
    .map((item) => item.trim())
    .filter((item) => item.length > 0)
    .filter((item) => {
      if (seen.has(item)) return false;
      seen.add(item);
      return true;
    });

  return parsed.length > 0 ? parsed : defaults;
}

type AiTextCallOptions = {
  prompt: string;
  systemInstruction?: string;
  model?: string;
  temperature?: number;
  maxOutputTokens?: number;
};

type PerplexityMessage = {
  role: "system" | "user" | "assistant";
  content: string;
};

type PerplexityChatOptions = {
  messages: PerplexityMessage[];
  temperature?: number;
  returnImages?: boolean;
  searchDomainFilter?: string[];
  imageDomainFilter?: string[];
};

function asObject(data: unknown): Record<string, unknown> {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new ApiError(400, "Request payload must be an object.");
  }
  return data as Record<string, unknown>;
}

function readString(data: Record<string, unknown>, key: string): string {
  const value = data[key];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new ApiError(400, `${key} must be a non-empty string.`);
  }
  return value.trim();
}

function readOptionalString(
  data: Record<string, unknown>,
  key: string,
): string | undefined {
  const value = data[key];
  if (value == null) {
    return undefined;
  }
  if (typeof value !== "string") {
    throw new ApiError(400, `${key} must be a string.`);
  }
  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed;
}

function readInteger(
  data: Record<string, unknown>,
  key: string,
  fallback: number,
  min: number,
  max: number,
): number {
  const value = data[key];
  if (value == null) {
    return fallback;
  }
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new ApiError(400, `${key} must be a number.`);
  }
  const normalized = Math.round(value);
  return Math.min(Math.max(normalized, min), max);
}

function readStringArray(value: unknown, fieldName: string): string[] {
  if (value == null) {
    return [];
  }
  if (!Array.isArray(value)) {
    throw new ApiError(400, `${fieldName} must be an array.`);
  }
  return value.map((item, index) => {
    if (typeof item !== "string") {
      throw new ApiError(
        400,
        `${fieldName}[${index}] must be a string.`,
      );
    }
    return item;
  });
}

function readOptionalObjectArray(value: unknown): Array<Record<string, unknown>> {
  if (!Array.isArray(value)) {
    return [];
  }
  return value
    .filter((item): item is Record<string, unknown> =>
      !!item && typeof item === "object" && !Array.isArray(item),
    );
}

function readLocationContextList(value: unknown): LocationContext[] {
  if (value == null) {
    return [];
  }
  if (!Array.isArray(value)) {
    throw new ApiError(400, "existingLocations must be an array.");
  }

  return value.map((item, index) => {
    const entry = asObject(item);
    const rating = entry.rating;
    if (rating != null && typeof rating !== "number") {
      throw new ApiError(
        400,
        `existingLocations[${index}].rating must be a number.`,
      );
    }

    return {
      id: readString(entry, "id"),
      name: readString(entry, "name"),
      category: readString(entry, "category"),
      tags: readStringArray(entry.tags, `existingLocations[${index}].tags`),
      rating: typeof rating === "number" ? rating : undefined,
      address: readOptionalString(entry, "address"),
      description: readOptionalString(entry, "description"),
    };
  });
}

function buildOpenAiMessages(
  options: AiTextCallOptions,
): Array<Record<string, string>> {
  const messages: Array<Record<string, string>> = [];
  if (options.systemInstruction?.trim()) {
    messages.push({
      role: "system",
      content: options.systemInstruction.trim(),
    });
  }
  messages.push({
    role: "user",
    content: options.prompt,
  });
  return messages;
}

function extractSseDataLines(payload: string): string[] {
  return payload
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.startsWith("data:"))
    .map((line) => line.slice(5).trim())
    .filter((line) => line.length > 0 && line !== "[DONE]");
}

function collectTextFromOpenAiStream(payload: string): string {
  let combined = "";

  for (const dataLine of extractSseDataLines(payload)) {
    try {
      const chunk = JSON.parse(dataLine) as Record<string, unknown>;
      const choices = Array.isArray(chunk.choices) ? chunk.choices : [];
      for (const choice of choices) {
        const delta = asMaybeObject(asMaybeObject(choice)?.delta);
        const content = delta?.content;
        if (typeof content === "string") {
          combined += content;
        }
      }
    } catch {
      continue;
    }
  }

  return combined.trim();
}

async function callOpenAiText(options: AiTextCallOptions): Promise<string> {
  const requestedModel = options.model ?? defaultModel;
  const candidateModels = Array.from(
    new Set([requestedModel, ...fallbackModels]),
  );

  let lastError: ApiError | null = null;

  for (const model of candidateModels) {
    const payload = JSON.stringify({
      model,
      messages: buildOpenAiMessages(options),
      temperature: options.temperature ?? 0.4,
      max_completion_tokens: options.maxOutputTokens,
      stream: true,
    });

    const response = await fetch(
      `${cliProxyBaseUrl}/v1/chat/completions`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${cliProxyApiKey}`,
        },
        body: payload,
      },
    );

    if (response.ok) {
      const rawText = await response.text();
      const content = collectTextFromOpenAiStream(rawText);
      if (content.length > 0) {
        return content;
      }

      lastError = new ApiError(
        502,
        `CLIProxyAPI did not return text content for model ${model}.`,
      );
      continue;
    }

    const errorText = await response.text();
    lastError = mapProxyError(response.status, errorText);

    if (!shouldRetryWithFallback(response.status, errorText, model)) {
      throw lastError;
    }

    console.warn(
      `[AI demo server] model ${model} unavailable, retrying fallback...`,
    );
  }

  throw lastError ?? new ApiError(500, "CLIProxyAPI request failed.");
}

async function callPerplexityChat(
  options: PerplexityChatOptions,
): Promise<Record<string, unknown>> {
  if (!perplexityApiKey) {
    throw new ApiError(
      503,
      "PERPLEXITY_API_KEY is not configured for AI review generation.",
    );
  }

  const response = await fetch(`${perplexityBaseUrl}/chat/completions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${perplexityApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: perplexityModel,
      messages: options.messages,
      return_images: options.returnImages ?? false,
      search_domain_filter: options.searchDomainFilter ?? reviewSearchDomainFilter,
      image_domain_filter: options.imageDomainFilter ?? reviewImageDomainFilter,
      temperature: options.temperature ?? 0.3,
    }),
  });

  const rawText = await response.text();
  let data: Record<string, unknown>;
  try {
    data = JSON.parse(rawText) as Record<string, unknown>;
  } catch (error) {
    throw new ApiError(
      502,
      `Perplexity returned invalid JSON payload: ${error}`,
    );
  }

  if (!response.ok) {
    const errorMessage = asMaybeObject(data.error)?.message;
    if (typeof errorMessage === "string" && errorMessage.trim().length > 0) {
      throw new ApiError(response.status, errorMessage);
    }
    throw new ApiError(
      response.status,
      `Perplexity request failed with status ${response.status}.`,
    );
  }

  return data;
}

async function callDeepSeekChat(
  messages: Array<{role: string; content: string}>,
  temperature = 0.4,
): Promise<string> {
  if (!deepseekApiKey) {
    throw new ApiError(503, "DEEPSEEK_API_KEY is not configured.");
  }

  const response = await fetch(`${deepseekBaseUrl}/chat/completions`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${deepseekApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: deepseekModel,
      messages,
      temperature,
      max_tokens: 4096,
    }),
  });

  const rawText = await response.text();
  if (!response.ok) {
    throw new ApiError(
      response.status,
      `DeepSeek request failed (${response.status}): ${rawText.slice(0, 300)}`,
    );
  }

  let data: Record<string, unknown>;
  try {
    data = JSON.parse(rawText) as Record<string, unknown>;
  } catch {
    throw new ApiError(502, "DeepSeek returned invalid JSON.");
  }

  const choices = Array.isArray(data.choices) ? data.choices : [];
  const firstChoice = asMaybeObject(choices[0]);
  const message = asMaybeObject(firstChoice?.message);
  const content = message?.content;
  if (typeof content === "string" && content.trim().length > 0) {
    return content.trim();
  }

  throw new ApiError(502, "DeepSeek did not return text content.");
}

function shouldRetryWithFallback(
  status: number,
  body: string,
  model: string,
): boolean {
  if (status === 404) {
    return true;
  }

  if (status === 429 || status >= 500) {
    return true;
  }

  if (status !== 400) {
    return false;
  }

  const normalized = body.toLowerCase();
  return normalized.includes(model.toLowerCase()) ||
    normalized.includes("model") ||
    normalized.includes("not found") ||
    normalized.includes("unsupported");
}

function asMaybeObject(value: unknown): Record<string, unknown> | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return undefined;
  }
  return value as Record<string, unknown>;
}

function mapProxyError(status: number, body: string): ApiError {
  if (status === 400) {
    return new ApiError(400, `CLIProxyAPI rejected the request: ${body}`);
  }
  if (status === 401 || status === 403) {
    return new ApiError(
      403,
      "CLIProxyAPI credentials were rejected. Check AI_PROXY_API_KEY.",
    );
  }
  if (status === 429) {
    return new ApiError(429, "CLIProxyAPI quota is temporarily exhausted.");
  }
  if (status >= 500) {
    return new ApiError(503, `CLIProxyAPI backend error: ${body}`);
  }
  return new ApiError(500, `CLIProxyAPI request failed: ${body}`);
}

function stripCodeFence(raw: string): string {
  let cleaned = raw.trim();
  if (cleaned.startsWith("```json")) {
    cleaned = cleaned.replace(/^```json\s*/i, "");
  } else if (cleaned.startsWith("```")) {
    cleaned = cleaned.replace(/^```\w*\s*/i, "");
  }

  if (cleaned.endsWith("```")) {
    cleaned = cleaned.replace(/\s*```$/i, "");
  }

  return cleaned.trim();
}

function tryParseJson<T>(raw: string): T | undefined {
  try {
    return JSON.parse(raw) as T;
  } catch {
    return undefined;
  }
}

function extractJsonFragment(
  raw: string,
  openChar: "{" | "[",
  closeChar: "}" | "]",
): string | undefined {
  const startIndex = raw.indexOf(openChar);
  if (startIndex < 0) {
    return undefined;
  }

  let depth = 0;
  let inString = false;
  let escaped = false;

  for (let index = startIndex; index < raw.length; index += 1) {
    const char = raw[index];

    if (inString) {
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char === "\\") {
        escaped = true;
        continue;
      }
      if (char === "\"") {
        inString = false;
      }
      continue;
    }

    if (char === "\"") {
      inString = true;
      continue;
    }

    if (char === openChar) {
      depth += 1;
      continue;
    }

    if (char === closeChar) {
      depth -= 1;
      if (depth === 0) {
        return raw.slice(startIndex, index + 1);
      }
    }
  }

  return undefined;
}

function parseJsonObject(raw: string): Record<string, unknown> {
  const cleaned = stripCodeFence(raw);

  // Strategy 1: Direct parse after stripping code fences
  const direct = tryParseJson<Record<string, unknown>>(cleaned);
  if (direct && typeof direct === "object" && !Array.isArray(direct)) {
    return direct;
  }

  // Strategy 2: Extract JSON object fragment from mixed text
  const extracted = extractJsonFragment(cleaned, "{", "}");
  if (extracted) {
    const recovered = tryParseJson<Record<string, unknown>>(extracted);
    if (recovered && typeof recovered === "object" && !Array.isArray(recovered)) {
      return recovered;
    }

    // Strategy 3: Try to repair minor issues (trailing commas, unclosed strings)
    const repaired = tryRepairJson(extracted);
    if (repaired) {
      const repairedParsed = tryParseJson<Record<string, unknown>>(repaired);
      if (repairedParsed && typeof repairedParsed === "object" && !Array.isArray(repairedParsed)) {
        console.warn("[parseJsonObject] recovered via JSON repair");
        return repairedParsed;
      }
    }
  }

  // Strategy 4: Try to find any { } in the original raw string too
  const extractedFromRaw = extractJsonFragment(raw, "{", "}");
  if (extractedFromRaw && extractedFromRaw !== extracted) {
    const rawRecovered = tryParseJson<Record<string, unknown>>(extractedFromRaw);
    if (rawRecovered && typeof rawRecovered === "object" && !Array.isArray(rawRecovered)) {
      return rawRecovered;
    }
  }

  // Log for debugging
  console.error("[parseJsonObject] FAILED to parse JSON object. Raw length:",
    raw.length, "First 500 chars:", raw.slice(0, 500));

  throw new ApiError(
    500,
    "Mô hình chưa trả đúng JSON cho object. Hãy chọn đủ ngữ cảnh rồi thử lại.",
  );
}

function tryRepairJson(raw: string): string | undefined {
  let repaired = raw.trim();

  // Remove trailing commas before } or ]
  repaired = repaired.replace(/,\s*([\]}])/g, "$1");

  // Try to close unclosed strings (if last char is not } or ])
  if (!repaired.endsWith("}") && !repaired.endsWith("]")) {
    // Attempt to close the JSON - find and balance braces
    let openBraces = 0;
    let openBrackets = 0;
    for (const ch of repaired) {
      if (ch === "{") openBraces++;
      if (ch === "}") openBraces--;
      if (ch === "[") openBrackets++;
      if (ch === "]") openBrackets--;
    }
    // Add missing closing
    while (openBrackets > 0) {
      repaired += "]";
      openBrackets--;
    }
    while (openBraces > 0) {
      repaired += "}";
      openBraces--;
    }
  }

  // If unchanged, no point retrying
  if (repaired === raw.trim()) return undefined;
  return repaired;
}

function parseJsonArray(raw: string): Array<Record<string, unknown>> {
  const cleaned = stripCodeFence(raw);
  const direct = tryParseJson<Array<Record<string, unknown>>>(cleaned);
  if (Array.isArray(direct)) {
    return direct;
  }

  const extracted = extractJsonFragment(cleaned, "[", "]");
  if (extracted) {
    const recovered = tryParseJson<Array<Record<string, unknown>>>(extracted);
    if (Array.isArray(recovered)) {
      return recovered;
    }

    const repaired = tryRepairJson(extracted);
    if (repaired) {
      const repairedParsed = tryParseJson<Array<Record<string, unknown>>>(repaired);
      if (Array.isArray(repairedParsed)) {
        console.warn("[parseJsonArray] recovered via JSON repair");
        return repairedParsed;
      }
    }
  }

  console.error("[parseJsonArray] FAILED to parse JSON array. Raw length:",
    raw.length, "First 500 chars:", raw.slice(0, 500));

  throw new ApiError(
    500,
    "Mô hình chưa trả đúng JSON cho danh sách. Hãy thử lại với brief ngắn hơn.",
  );
}

function extractPerplexityText(data: Record<string, unknown>): string {
  const choices = Array.isArray(data.choices) ? data.choices : [];
  const first = asMaybeObject(choices[0]);
  const message = asMaybeObject(first?.message);
  const content = message?.content;
  if (typeof content === "string" && content.trim().length > 0) {
    return content;
  }
  throw new ApiError(502, "Perplexity response did not include assistant content.");
}

function extractPerplexitySearchResults(
  data: Record<string, unknown>,
): Array<Record<string, unknown>> {
  const results = Array.isArray(data.search_results) ? data.search_results : [];
  return results
    .map((item) => asMaybeObject(item))
    .filter((item): item is Record<string, unknown> => item !== undefined)
    .map((item) => ({
      title: typeof item.title === "string" ? item.title.trim() : "",
      url: typeof item.url === "string" ? item.url.trim() : "",
      date: typeof item.date === "string" ? item.date.trim() : null,
      domain: normalizeHostname(typeof item.url === "string" ? item.url : undefined) ?? null,
    }))
    .filter((item) => item.url.length > 0);
}

function extractPerplexityImageCandidates(
  data: Record<string, unknown>,
): Array<Record<string, unknown>> {
  const images = Array.isArray(data.images) ? data.images : [];
  return images
    .map((item) => asMaybeObject(item))
    .filter((item): item is Record<string, unknown> => item !== undefined)
    .map((item) => {
      const imageUrl = typeof item.image_url === "string"
        ? item.image_url.trim()
        : typeof item.imageUrl === "string"
          ? item.imageUrl.trim()
          : "";
      const sourceUrl = typeof item.origin_url === "string"
        ? item.origin_url.trim()
        : typeof item.source_url === "string"
          ? item.source_url.trim()
          : typeof item.sourceUrl === "string"
            ? item.sourceUrl.trim()
            : "";

      return {
        imageUrl,
        sourceUrl,
        title: typeof item.title === "string" && item.title.trim().length > 0
          ? item.title.trim()
          : sourceUrl,
        domain: normalizeHostname(sourceUrl) ?? null,
      };
    })
    .filter((item) => item.imageUrl.length > 0 && item.sourceUrl.length > 0);
}

function normalizeHostname(value: string | undefined): string | undefined {
  if (!value || value.trim().length === 0) return undefined;
  try {
    return new URL(value).hostname.replace(/^www\./, "");
  } catch {
    return undefined;
  }
}

async function fetchGpsFromNominatim(
  query: string,
): Promise<{latitude?: number; longitude?: number}> {
  try {
    const url = new URL("https://nominatim.openstreetmap.org/search");
    url.searchParams.set("q", query);
    url.searchParams.set("format", "json");
    url.searchParams.set("limit", "1");

    const response = await fetch(url, {
      headers: {
        "User-Agent": "TourVN Demo AI Server",
      },
    });

    if (!response.ok) {
      return {};
    }

    const data = await response.json() as Array<Record<string, unknown>>;
    const first = data[0];
    if (!first) {
      return {};
    }

    const latitude = Number(first.lat);
    const longitude = Number(first.lon);
    if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
      return {latitude, longitude};
    }

    return {};
  } catch {
    return {};
  }
}

async function handleGenerateDestinationDraft(rawData: unknown) {
  const data = asObject(rawData);
  const prompt = readString(data, "prompt");

  const response = await callPerplexityChat({
    messages: [
      {
        role: "system",
        content: [
          "Bạn là chuyên gia du lịch Việt Nam. Tạo dữ liệu điểm đến cho admin panel.",
          "Trả về JSON thuần, không markdown fence, không giải thích ngoài JSON.",
          `Schema bắt buộc:\n{\n  "id": "slug-id-tu-ten",\n  "name": "Tên điểm đến tiếng Việt",\n  "heroImage": "",\n  "description": "Mô tả tiếng Việt 200-400 từ",\n  "countryCode": "VN",\n  "status": "draft_ai"\n}`,
          "Quy tắc:",
          "- Tên và mô tả phải bằng tiếng Việt có dấu.",
          "- id phải URL-safe lowercase kebab-case.",
          "- Không thêm trường hay giải thích ngoài JSON.",
        ].join("\n"),
      },
      {
        role: "user",
        content: `Tạo nội dung điểm đến cho: ${prompt}`,
      },
    ],
    temperature: 0.3,
    returnImages: true,
    searchDomainFilter: [],
    imageDomainFilter: [],
  });

  const result = parseJsonObject(extractPerplexityText(response));

  // Auto-fill heroImage from Perplexity images if empty
  const currentHero = typeof result.heroImage === "string" ? result.heroImage.trim() : "";
  if (!currentHero) {
    const imageCandidates = extractPerplexityImageCandidates(response);
    if (imageCandidates.length > 0) {
      result.heroImage = imageCandidates[0].imageUrl;
      result._imageCandidates = imageCandidates.slice(0, 5);
    } else {
      // Fallback: try to fetch an image using a separate Perplexity call
      const destName = typeof result.name === "string" ? result.name : prompt;
      const fallbackImage = await fetchImageForDestination(destName);
      if (fallbackImage) {
        result.heroImage = fallbackImage;
      }
    }
  }

  return result;
}

async function fetchImageForDestination(name: string): Promise<string | undefined> {
  try {
    const imageResponse = await callPerplexityChat({
      messages: [
        {
          role: "system",
          content: "Return only the direct URL to a high-quality photo of the requested place. No explanation, no JSON, just the URL.",
        },
        {
          role: "user",
          content: `Ảnh đẹp nhất của ${name} Việt Nam`,
        },
      ],
      returnImages: true,
      searchDomainFilter: [],
      imageDomainFilter: [],
      temperature: 0.1,
    });

    const candidates = extractPerplexityImageCandidates(imageResponse);
    if (candidates.length > 0) {
      return candidates[0].imageUrl as string;
    }
    return undefined;
  } catch {
    return undefined;
  }
}

async function handleGenerateLocationDrafts(rawData: unknown) {
  const data = asObject(rawData);
  const destinationId = readString(data, "destinationId");
  const destinationName = readString(data, "destinationName");
  const prompt = readString(data, "prompt");
  const count = readInteger(data, "count", 5, 1, 10);

  const response = await callPerplexityChat({
    messages: [
      {
        role: "system",
        content: [
          `Bạn là chuyên gia du lịch Việt Nam. Tạo ${count} địa điểm du lịch cụ thể cho "${destinationName}".`,
          "Trả về JSON thuần dạng array, không markdown fence, không giải thích ngoài JSON.",
          `Schema bắt buộc:\n[\n  {\n    "id": "slug-id-tu-ten",\n    "destinationId": "${destinationId}",\n    "destinationName": "${destinationName}",\n    "name": "Tên địa điểm tiếng Việt",\n    "image": "",\n    "category": "food" hoặc "places" hoặc "stay",\n    "address": "Địa chỉ cụ thể",\n    "description": "Mô tả tiếng Việt 50-100 từ",\n    "priceRange": "$" hoặc "$$" hoặc "$$$",\n    "rating": 4.5,\n    "latitude": null,\n    "longitude": null,\n    "tags": ["romantic", "family-friendly"],\n    "searchKeywords": ["từ khóa 1", "từ khóa 2"],\n    "estimatedDurationMin": 60,\n    "status": "draft_ai"\n  }\n]`,
          "Quy tắc:",
          "- Nội dung hiển thị phải bằng tiếng Việt có dấu.",
          "- Chọn 2-4 tags phù hợp.",
          "- Không thêm trường hay giải thích ngoài JSON.",
        ].join("\n"),
      },
      {
        role: "user",
        content: `Tạo ${count} địa điểm cho: ${prompt}`,
      },
    ],
    temperature: 0.3,
    returnImages: true,
    searchDomainFilter: [],
    imageDomainFilter: [],
  });

  const rawLocations = parseJsonArray(extractPerplexityText(response));
  const imageCandidates = extractPerplexityImageCandidates(response);

  const enrichedLocations = [];
  let imageIndex = 0;
  for (const location of rawLocations) {
    const locationName = typeof location.name === "string" ? location.name : "";
    const address = typeof location.address === "string" ? location.address : "";
    const primaryQuery = [locationName, destinationName].filter(Boolean).join(", ");
    const primaryGps = locationName ? await fetchGpsFromNominatim(primaryQuery) : {};
    const fallbackGps = !primaryGps.latitude && address
      ? await fetchGpsFromNominatim(address)
      : {};

    // Auto-fill image from Perplexity image candidates
    const currentImage = typeof location.image === "string" ? location.image.trim() : "";
    let assignedImage = currentImage;
    if (!assignedImage && imageIndex < imageCandidates.length) {
      assignedImage = imageCandidates[imageIndex].imageUrl as string;
      imageIndex++;
    }

    enrichedLocations.push({
      ...location,
      image: assignedImage || "",
      latitude: primaryGps.latitude ?? fallbackGps.latitude ?? location.latitude ?? null,
      longitude: primaryGps.longitude ?? fallbackGps.longitude ?? location.longitude ?? null,
    });
  }

  return enrichedLocations;
}

function readDraftSourceReferences(
  value: unknown,
): Array<Record<string, unknown>> {
  return readOptionalObjectArray(value)
    .map((item) => {
      const url = readOptionalString(item, "url");
      if (!url) return null;
      return {
        title: readOptionalString(item, "title") ?? url,
        url,
        date: readOptionalString(item, "date") ?? null,
        domain: readOptionalString(item, "domain") ?? normalizeHostname(url) ?? null,
      };
    })
    .filter((item) => item !== null) as Array<Record<string, unknown>>;
}

function readDraftImageCandidates(
  value: unknown,
): Array<Record<string, unknown>> {
  return readOptionalObjectArray(value)
    .map((item) => {
      const imageUrl = readOptionalString(item, "imageUrl") ??
        readOptionalString(item, "image_url");
      const sourceUrl = readOptionalString(item, "sourceUrl") ??
        readOptionalString(item, "source_url") ??
        readOptionalString(item, "origin_url");
      if (!imageUrl || !sourceUrl) return null;
      return {
        imageUrl,
        sourceUrl,
        title: readOptionalString(item, "title") ?? sourceUrl,
        domain: readOptionalString(item, "domain") ?? normalizeHostname(sourceUrl) ?? null,
      };
    })
    .filter((item) => item !== null) as Array<Record<string, unknown>>;
}

function mergeByUrl(
  primary: Array<Record<string, unknown>>,
  secondary: Array<Record<string, unknown>>,
  key: "url" | "sourceUrl",
): Array<Record<string, unknown>> {
  const merged: Array<Record<string, unknown>> = [];
  const seen = new Set<string>();

  for (const item of [...primary, ...secondary]) {
    const rawValue = item[key];
    const url = typeof rawValue === "string" ? rawValue.trim() : "";
    if (!url || seen.has(url)) continue;
    seen.add(url);
    merged.push(item);
  }

  return merged;
}

async function generateReviewViaPerplexity(options: {
  prompt: string;
  destinationId?: string;
  destinationName?: string;
  existingLocations: LocationContext[];
  articleStyle: string;
  status: "draft_ai" | "preview_ai";
  draftReview?: Record<string, unknown>;
  variantHint?: string;
}): Promise<Record<string, unknown>> {
  const destinationLabel = options.destinationName ?? options.destinationId ?? "Việt Nam";
  const baseDraft = options.draftReview;
  const existingId = baseDraft ? readOptionalString(baseDraft, "id") : undefined;
  const existingSlug = baseDraft ? readOptionalString(baseDraft, "slug") : undefined;
  const existingSummary = baseDraft ? readOptionalString(baseDraft, "aiSummary") : undefined;
  const existingAngle = baseDraft ? readOptionalString(baseDraft, "aiAngle") : undefined;
  const existingTitle = baseDraft ? readOptionalString(baseDraft, "title") : undefined;
  const existingHeroImage = baseDraft ? readOptionalString(baseDraft, "heroImage") : undefined;
  const existingHeroImageSourceUrl = baseDraft
    ? readOptionalString(baseDraft, "heroImageSourceUrl")
    : undefined;
  const existingCategory = baseDraft ? readOptionalString(baseDraft, "category") : undefined;
  const existingRelatedLocationIds = baseDraft
    ? readStringArray(baseDraft.relatedLocationIds, "draftReview.relatedLocationIds")
    : [];
  const existingOutline = baseDraft
    ? readStringArray(baseDraft.aiOutline, "draftReview.aiOutline")
    : [];
  const baseReferences = baseDraft
    ? readDraftSourceReferences(baseDraft.sourceReferences)
    : [];
  const baseImageCandidates = baseDraft
    ? readDraftImageCandidates(baseDraft.heroImageCandidates)
    : [];

  const responseShape = options.status === "draft_ai"
    ? `{
  "id": "slug-from-title",
  "title": "Tiêu đề bài viết tiếng Việt",
  "aiSummary": "Tóm tắt 2-3 câu bằng tiếng Việt",
  "aiAngle": "Góc tiếp cận bài viết bằng tiếng Việt",
  "aiOutline": ["Ý 1", "Ý 2", "Ý 3"],
  "relatedLocationIds": ["real-location-id-1"],
  "category": "food or places or stay",
  "fullText": "Tóm tắt ngắn để admin xem nhanh"
}`
    : `{
  "id": "slug-from-title",
  "title": "Tiêu đề bài viết tiếng Việt",
  "aiSummary": "Tóm tắt ngắn của bài viết",
  "aiAngle": "Góc tiếp cận bài viết",
  "aiOutline": ["Ý 1", "Ý 2", "Ý 3"],
  "heroImage": "",
  "fullText": "Markdown article in Vietnamese with at least 3 ## headings",
  "relatedLocationIds": ["real-location-id-1"],
  "category": "food or places or stay"
}`;

  const workflowInstruction = options.status === "draft_ai"
    ? [
        "Bạn đang ở bước 1 của quy trình biên tập AI.",
        "Hãy tạo outline pack để admin duyệt nhanh trước khi mở rộng thành bài preview dài.",
        "Không viết bài quá dài.",
      ].join("\n")
    : [
        "Bạn đang ở bước 2 của quy trình biên tập AI.",
        "Hãy mở rộng bản outline đã được duyệt thành bài preview hoàn chỉnh, giàu thông tin và phù hợp để xuất bản.",
        "Bài viết phải có ít nhất 3 heading Markdown bắt đầu bằng ##.",
      ].join("\n");

  const messages: PerplexityMessage[] = [
    {
      role: "system",
      content: [
        "Bạn là biên tập viên du lịch Việt Nam của TourVN.",
        `Điểm đến chính: ${destinationLabel}.`,
        workflowInstruction,
        buildLocationContext(options.existingLocations),
        reviewStyleInstructions(options.articleStyle),
        "Chỉ dùng relatedLocationIds từ danh sách location có sẵn của hệ thống.",
        "Giữ mọi nội dung hiển thị cho người dùng bằng tiếng Việt có dấu.",
        "Trả về JSON thuần, không thêm markdown fence, không giải thích ngoài JSON.",
        `Schema bắt buộc:\n${responseShape}`,
      ].join("\n\n"),
    },
    {
      role: "user",
      content: [
        `Brief admin: ${options.prompt}`,
        options.variantHint ? `Biến thể bài viết: ${options.variantHint}` : "",
        existingTitle ? `Tiêu đề đã duyệt: ${existingTitle}` : "",
        existingSummary ? `Tóm tắt đã duyệt: ${existingSummary}` : "",
        existingAngle ? `Góc bài đã duyệt: ${existingAngle}` : "",
        existingOutline.length > 0
          ? `Outline đã duyệt:\n- ${existingOutline.join("\n- ")}`
          : "",
      ].filter(Boolean).join("\n\n"),
    },
  ];

  const response = await callPerplexityChat({
    messages,
    returnImages: true,
    temperature: options.status === "draft_ai" ? 0.2 : 0.55,
  });

  const generated = parseJsonObject(extractPerplexityText(response));
  const searchResults = extractPerplexitySearchResults(response);
  const imageCandidates = extractPerplexityImageCandidates(response);

  const mergedReferences = mergeByUrl(baseReferences, searchResults, "url");
  const mergedImageCandidates = mergeByUrl(
    baseImageCandidates,
    imageCandidates,
    "sourceUrl",
  );
  const resolvedId = baseDraft ? existingId ?? readOptionalString(generated, "id") :
    readOptionalString(generated, "id") ?? existingId;
  const resolvedSlug = baseDraft
    ? existingSlug ?? readOptionalString(generated, "slug")
    : readOptionalString(generated, "slug") ?? existingSlug;

  return normalizeReviewDraft(
    {
      ...generated,
      id: resolvedId,
      slug: resolvedSlug,
      title: readOptionalString(generated, "title") ?? existingTitle,
      aiSummary: readOptionalString(generated, "aiSummary") ?? existingSummary,
      aiAngle: readOptionalString(generated, "aiAngle") ?? existingAngle,
      aiOutline: readStringArray(generated.aiOutline, "generated.aiOutline").length > 0
        ? generated.aiOutline
        : existingOutline,
      relatedLocationIds: readStringArray(
        generated.relatedLocationIds,
        "generated.relatedLocationIds",
      ).length > 0
        ? generated.relatedLocationIds
        : existingRelatedLocationIds,
      category: readOptionalString(generated, "category") ?? existingCategory,
      heroImage: readOptionalString(generated, "heroImage") ?? existingHeroImage,
      sourceReferences: mergedReferences,
      heroImageCandidates: mergedImageCandidates,
      heroImageSourceUrl: readOptionalString(generated, "heroImageSourceUrl") ??
        (mergedImageCandidates[0]?.sourceUrl as string | undefined) ??
        existingHeroImageSourceUrl,
      aiPrompt: options.prompt,
      aiProvider: `perplexity:${perplexityModel}`,
      status: options.status,
    },
    {
      destinationId: options.destinationId,
      destinationName: options.destinationName,
      existingLocations: options.existingLocations,
      articleStyle: options.articleStyle,
      status: options.status,
      aiPrompt: options.prompt,
      aiProvider: `perplexity:${perplexityModel}`,
    },
  );
}

async function handleGenerateReviewDraft(rawData: unknown) {
  const data = asObject(rawData);
  const prompt = readString(data, "prompt");
  const destinationId = readOptionalString(data, "destinationId");
  const destinationName = readOptionalString(data, "destinationName");
  if (!destinationId || !destinationName) {
    throw new ApiError(
      400,
      "Vui lòng chọn điểm đến trước khi tạo bài viết AI.",
    );
  }
  const articleStyle = normalizeArticleStyle(readOptionalString(data, "articleStyle"));
  const existingLocations = readLocationContextList(data.existingLocations);
  return generateReviewViaPerplexity({
    prompt,
    destinationId,
    destinationName,
    existingLocations,
    articleStyle,
    status: "draft_ai",
  });
}

async function handleGenerateReviewDrafts(rawData: unknown) {
  const data = asObject(rawData);
  const prompt = readString(data, "prompt");
  const destinationName = readString(data, "destinationName");
  const destinationId = readString(data, "destinationId");
  const count = readInteger(data, "count", 3, 1, 5);
  const existingLocations = readLocationContextList(data.existingLocations);
  const articleStyle = normalizeArticleStyle(readOptionalString(data, "articleStyle"));
  const drafts: Array<Record<string, unknown>> = [];
  for (let index = 0; index < count; index += 1) {
    drafts.push(await generateReviewViaPerplexity({
      prompt,
      destinationId,
      destinationName,
      existingLocations,
      articleStyle,
      status: "preview_ai",
      variantHint: `Bài số ${index + 1}/${count} phải khác góc nhìn và khác lựa chọn điểm nhấn.`,
    }));
  }

  return normalizeReviewDraftArray(drafts, {
    destinationId,
    destinationName,
    existingLocations,
    articleStyle,
    status: "preview_ai",
    aiPrompt: prompt,
    aiProvider: `perplexity:${perplexityModel}`,
  });
}

async function handleExpandReviewDraft(rawData: unknown) {
  const data = asObject(rawData);
  const prompt = readOptionalString(data, "prompt") ?? "";
  const draftReview = asObject(data.draftReview);
  const destinationId = readOptionalString(data, "destinationId") ??
    readOptionalString(draftReview, "destinationId");
  const destinationName = readOptionalString(data, "destinationName") ??
    readOptionalString(draftReview, "destinationName");
  const articleStyle = normalizeArticleStyle(
    readOptionalString(data, "articleStyle"),
  );
  const existingLocations = readLocationContextList(data.existingLocations);

  return generateReviewViaPerplexity({
    prompt: prompt || readOptionalString(draftReview, "aiPrompt") || `Mở rộng bài viết về ${destinationName ?? destinationId ?? "điểm đến đã chọn"}`,
    destinationId,
    destinationName,
    existingLocations,
    articleStyle,
    status: "preview_ai",
    draftReview,
  });
}

async function handleEnrichAutoPlan(rawData: unknown) {
  const data = asObject(rawData);
  const prompt = readString(data, "prompt");

  const systemMsg = [
    "Bạn là trợ lý lập lịch trình du lịch Việt Nam.",
    "Trả về JSON thuần, không markdown fence, không giải thích ngoài JSON.",
  ].join("\n");

  // Try Perplexity first, fallback to DeepSeek
  if (perplexityApiKey) {
    try {
      const response = await callPerplexityChat({
        messages: [
          {role: "system", content: systemMsg},
          {role: "user", content: prompt},
        ],
        temperature: 0.4,
      });
      return parseJsonObject(extractPerplexityText(response));
    } catch (error) {
      console.warn("[AI demo server] Perplexity failed for enrichAutoPlan, trying DeepSeek...", error);
    }
  }

  // DeepSeek fallback
  const text = await callDeepSeekChat(
    [
      {role: "system", content: systemMsg},
      {role: "user", content: prompt},
    ],
    0.4,
  );
  return parseJsonObject(stripCodeFence(text));
}

async function handleGenerateStopTip(rawData: unknown) {
  const data = asObject(rawData);
  const locationName = readString(data, "locationName");
  const category = readString(data, "category");
  const startTimeLabel = readString(data, "startTimeLabel");
  const endTimeLabel = readString(data, "endTimeLabel");
  const durationMin = readInteger(data, "durationMin", 60, 10, 720);

  const systemMsg = "Bạn là hướng dẫn viên du lịch địa phương Việt Nam. Viết lời khuyên ngắn gọn bằng tiếng Việt. Trả về plain text, không markdown.";
  const userMsg = [
    `Địa điểm: ${locationName} (${category}).`,
    `Thời gian tham quan: ${startTimeLabel} - ${endTimeLabel} (${durationMin} phút).`,
    "Viết 2-3 câu ngắn bằng tiếng Việt với lời khuyên thực tế, nên làm gì, và một lưu ý hữu ích nếu liên quan.",
  ].join(" ");

  // Try Perplexity first, fallback to DeepSeek
  if (perplexityApiKey) {
    try {
      const response = await callPerplexityChat({
        messages: [
          {role: "system", content: systemMsg},
          {role: "user", content: userMsg},
        ],
        temperature: 0.6,
      });
      return stripCodeFence(extractPerplexityText(response));
    } catch (error) {
      console.warn("[AI demo server] Perplexity failed for generateStopTip, trying DeepSeek...", error);
    }
  }

  // DeepSeek fallback
  const text = await callDeepSeekChat(
    [
      {role: "system", content: systemMsg},
      {role: "user", content: userMsg},
    ],
    0.6,
  );
  return stripCodeFence(text);
}

const routeHandlers: Record<string, (data: unknown) => Promise<unknown>> = {
  "/generateDestinationDraft": handleGenerateDestinationDraft,
  "/generateLocationDrafts": handleGenerateLocationDrafts,
  "/generateReviewDraft": handleGenerateReviewDraft,
  "/generateReviewDrafts": handleGenerateReviewDrafts,
  "/expandReviewDraft": handleExpandReviewDraft,
  "/enrichAutoPlan": handleEnrichAutoPlan,
  "/generateStopTip": handleGenerateStopTip,
};

function setCorsHeaders(response: ServerResponse): void {
  response.setHeader("Access-Control-Allow-Origin", "*");
  response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  response.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

async function readJsonBody(request: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  for await (const chunk of request) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }

  const raw = Buffer.concat(chunks).toString("utf8").trim();
  if (!raw) return {};

  try {
    return JSON.parse(raw);
  } catch {
    throw new ApiError(400, "Request body must be valid JSON.");
  }
}

function sendJson(
  response: ServerResponse,
  statusCode: number,
  body: Record<string, unknown>,
): void {
  setCorsHeaders(response);
  response.statusCode = statusCode;
  response.setHeader("Content-Type", "application/json; charset=utf-8");
  response.end(JSON.stringify(body));
}

const server = createServer(async (request, response) => {
  setCorsHeaders(response);

  if (request.method === "OPTIONS") {
    response.statusCode = 204;
    response.end();
    return;
  }

  if (!request.url) {
    sendJson(response, 404, {error: "Not found"});
    return;
  }

  const url = new URL(request.url, `http://${request.headers.host ?? "127.0.0.1"}`);
  if (request.method === "GET" && url.pathname === "/health") {
    const providers: string[] = [];
    if (perplexityApiKey) providers.push(`perplexity:${perplexityModel}`);
    if (deepseekApiKey) providers.push(`deepseek:${deepseekModel}`);
    sendJson(response, 200, {
      status: hasAnyAiProvider ? "ok" : "offline",
      upstream: perplexityApiKey ? perplexityBaseUrl : deepseekBaseUrl,
      model: providers.join(" + ") || "none",
    });
    return;
  }

  if (request.method !== "POST") {
    sendJson(response, 404, {error: "Not found"});
    return;
  }

  const handler = routeHandlers[url.pathname];
  if (!handler) {
    sendJson(response, 404, {error: `Unknown route: ${url.pathname}`});
    return;
  }

  try {
    const payload = await readJsonBody(request);
    const data = await handler(payload);
    sendJson(response, 200, {data});
  } catch (error) {
    if (error instanceof ApiError) {
      sendJson(response, error.statusCode, {error: error.message});
      return;
    }

    console.error(`[AI demo server] ${url.pathname} failed`, error);
    sendJson(response, 500, {
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(defaultPort, defaultHost, () => {
  console.log(
    `[AI demo server] listening on http://${defaultHost}:${defaultPort} ` +
      `-> Perplexity Sonar (${perplexityModel})`,
  );
});
