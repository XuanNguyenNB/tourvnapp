import {defineSecret} from "firebase-functions/params";
import {CallableRequest, HttpsError, onCall} from "firebase-functions/v2/https";

const geminiApiKey = defineSecret("GEMINI_API_KEY");
const defaultModel = "gemini-2.5-flash";

const callableOptions = {
  region: "asia-southeast1",
  timeoutSeconds: 120,
  memory: "1GiB" as const,
  secrets: [geminiApiKey],
};

type LocationContext = {
  id: string;
  name: string;
  category: string;
  tags: string[];
  rating?: number;
  address?: string;
};

type GeminiCallOptions = {
  prompt: string;
  systemInstruction?: string;
  model?: string;
  temperature?: number;
  responseMimeType?: string;
  maxOutputTokens?: number;
  useGoogleSearch?: boolean;
};

function requireAuthenticated(request: CallableRequest<unknown>): void {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
}

function requireAdmin(request: CallableRequest<unknown>): void {
  requireAuthenticated(request);
  if (request.auth?.token.admin !== true) {
    throw new HttpsError("permission-denied", "Admin access is required.");
  }
}

function asObject(data: unknown): Record<string, unknown> {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    throw new HttpsError("invalid-argument", "Request payload must be an object.");
  }
  return data as Record<string, unknown>;
}

function readString(data: Record<string, unknown>, key: string): string {
  const value = data[key];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${key} must be a non-empty string.`);
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
    throw new HttpsError("invalid-argument", `${key} must be a string.`);
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
    throw new HttpsError("invalid-argument", `${key} must be a number.`);
  }
  const normalized = Math.round(value);
  return Math.min(Math.max(normalized, min), max);
}

function readStringArray(value: unknown, fieldName: string): string[] {
  if (value == null) {
    return [];
  }
  if (!Array.isArray(value)) {
    throw new HttpsError("invalid-argument", `${fieldName} must be an array.`);
  }
  return value.map((item, index) => {
    if (typeof item !== "string") {
      throw new HttpsError(
        "invalid-argument",
        `${fieldName}[${index}] must be a string.`,
      );
    }
    return item;
  });
}

function readLocationContextList(value: unknown): LocationContext[] {
  if (value == null) {
    return [];
  }
  if (!Array.isArray(value)) {
    throw new HttpsError("invalid-argument", "existingLocations must be an array.");
  }

  return value.map((item, index) => {
    const entry = asObject(item);
    const rating = entry.rating;
    if (rating != null && typeof rating !== "number") {
      throw new HttpsError(
        "invalid-argument",
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
    };
  });
}

async function callGeminiText(options: GeminiCallOptions): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${options.model ?? defaultModel}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": geminiApiKey.value(),
      },
      body: JSON.stringify(buildGeminiPayload(options)),
    },
  );

  if (!response.ok) {
    const errorText = await response.text();
    throw mapGeminiError(response.status, errorText);
  }

  const data = await response.json() as Record<string, unknown>;
  return extractTextFromGeminiResponse(data);
}

function buildGeminiPayload(options: GeminiCallOptions): Record<string, unknown> {
  const generationConfig: Record<string, unknown> = {
    temperature: options.temperature ?? 0.5,
  };

  if (options.maxOutputTokens != null) {
    generationConfig.maxOutputTokens = options.maxOutputTokens;
  }

  if (options.responseMimeType != null) {
    generationConfig.responseMimeType = options.responseMimeType;
  }

  const payload: Record<string, unknown> = {
    contents: [
      {
        role: "user",
        parts: [{text: options.prompt}],
      },
    ],
    generationConfig,
  };

  if (options.systemInstruction) {
    payload.system_instruction = {
      parts: [{text: options.systemInstruction}],
    };
  }

  if (options.useGoogleSearch) {
    payload.tools = [{google_search: {}}];
  }

  return payload;
}

function extractTextFromGeminiResponse(
  data: Record<string, unknown>,
): string {
  const candidates = Array.isArray(data.candidates) ? data.candidates : [];

  for (const candidate of candidates) {
    const content = asMaybeObject(candidate)?.content;
    const parts = Array.isArray(asMaybeObject(content)?.parts)
      ? (asMaybeObject(content)?.parts as Array<unknown>)
      : [];

    for (const part of parts) {
      const text = asMaybeObject(part)?.text;
      if (typeof text === "string" && text.trim().length > 0) {
        return text;
      }
    }
  }

  throw new HttpsError("internal", "Gemini response did not include text output.");
}

function asMaybeObject(value: unknown): Record<string, unknown> | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return undefined;
  }
  return value as Record<string, unknown>;
}

function mapGeminiError(status: number, body: string): HttpsError {
  if (status === 400) {
    return new HttpsError("invalid-argument", `Gemini rejected the request: ${body}`);
  }
  if (status === 401 || status === 403) {
    return new HttpsError("permission-denied", "Gemini credentials were rejected.");
  }
  if (status === 429) {
    return new HttpsError("resource-exhausted", "Gemini quota is temporarily exhausted.");
  }
  if (status >= 500) {
    return new HttpsError("unavailable", `Gemini backend error: ${body}`);
  }
  return new HttpsError("internal", `Gemini request failed: ${body}`);
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

function parseJsonObject(raw: string): Record<string, unknown> {
  try {
    return JSON.parse(stripCodeFence(raw)) as Record<string, unknown>;
  } catch (error) {
    throw new HttpsError("internal", `Model returned invalid JSON object: ${error}`);
  }
}

function parseJsonArray(raw: string): Array<Record<string, unknown>> {
  try {
    return JSON.parse(stripCodeFence(raw)) as Array<Record<string, unknown>>;
  } catch (error) {
    throw new HttpsError("internal", `Model returned invalid JSON array: ${error}`);
  }
}

function buildLocationContext(locations: LocationContext[]): string {
  if (locations.length === 0) {
    return "No existing location context is available. Use general travel knowledge only.";
  }

  const lines = locations.map((location) =>
    `- ID: "${location.id}" | ${location.name} | ${location.category} | ` +
    `${location.tags.join(", ")} | rating=${location.rating ?? "N/A"} | ${location.address ?? ""}`,
  );

  return [
    `The system already has ${locations.length} real locations. Use ONLY these IDs in relatedLocationIds:`,
    ...lines,
  ].join("\n");
}

function reviewStyleInstructions(style: string): string {
  switch (style) {
  case "guide":
    return [
      "Style: detailed guide (1000-1500 words).",
      "Use sections for overview, transport, must-visit spots, food, and practical tips.",
      "Include realistic timings, price hints, and itinerary ideas.",
    ].join("\n");
  case "top-list":
    return [
      "Style: top list (600-1000 words).",
      "Use numbered sections and make each location easy to skim.",
      "Include concise highlights and price references.",
    ].join("\n");
  case "tips":
    return [
      "Style: practical travel tips (500-800 words).",
      "Focus on preparation, saving money, local experience, and important cautions.",
      "Keep the writing actionable.",
    ].join("\n");
  default:
    return [
      "Style: first-hand review (800-1200 words).",
      "Write with vivid, personal-feeling details and practical tips.",
      "Include at least 3 Markdown headings starting with ##.",
    ].join("\n");
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
        "User-Agent": "TourVN Firebase Functions",
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

export const generateDestinationDraft = onCall(callableOptions, async (request) => {
  requireAdmin(request);
  const data = asObject(request.data);
  const prompt = readString(data, "prompt");

  const systemInstruction = `
You are a Vietnam travel expert. Create destination data for the admin panel.
Return pure JSON only, no markdown fences:
{
  "id": "slug-id-from-name",
  "name": "Vietnamese destination name",
  "heroImage": "",
  "description": "Vietnamese description between 200 and 400 words",
  "countryCode": "VN",
  "status": "draft_ai"
}
Rules:
- The name and description must be in Vietnamese.
- The id must be URL-safe lowercase kebab-case.
- Do not add extra fields or explanations.
`;

  const text = await callGeminiText({
    prompt: `Create destination content for: ${prompt}`,
    systemInstruction,
    useGoogleSearch: true,
  });

  return parseJsonObject(text);
});

export const generateLocationDrafts = onCall(callableOptions, async (request) => {
  requireAdmin(request);
  const data = asObject(request.data);
  const destinationId = readString(data, "destinationId");
  const destinationName = readString(data, "destinationName");
  const prompt = readString(data, "prompt");
  const count = readInteger(data, "count", 5, 1, 10);

  const systemInstruction = `
You are a Vietnam travel expert. Create ${count} concrete travel locations for "${destinationName}".
Return pure JSON only as an array, no markdown:
[
  {
    "id": "slug-id-from-name",
    "destinationId": "${destinationId}",
    "destinationName": "${destinationName}",
    "name": "Vietnamese location name",
    "image": "",
    "category": "food" or "places" or "stay",
    "address": "Specific address",
    "description": "Vietnamese description, 50-100 words",
    "priceRange": "$" or "$$" or "$$$",
    "rating": 4.5,
    "latitude": null,
    "longitude": null,
    "tags": ["romantic", "family-friendly"],
    "searchKeywords": ["keyword 1", "keyword 2"],
    "estimatedDurationMin": 60,
    "status": "draft_ai"
  }
]
Rules:
- Write the user-facing text in Vietnamese.
- Choose 2-4 relevant tags.
- Do not add extra fields or explanations.
`;

  const rawLocations = parseJsonArray(await callGeminiText({
    prompt: `Create ${count} locations for: ${prompt}`,
    systemInstruction,
    useGoogleSearch: true,
  }));

  const enrichedLocations = [];
  for (const location of rawLocations) {
    const locationName = typeof location.name === "string" ? location.name : "";
    const address = typeof location.address === "string" ? location.address : "";
    const primaryQuery = [locationName, destinationName].filter(Boolean).join(", ");
    const primaryGps = locationName ? await fetchGpsFromNominatim(primaryQuery) : {};
    const fallbackGps = !primaryGps.latitude && address
      ? await fetchGpsFromNominatim(address)
      : {};

    enrichedLocations.push({
      ...location,
      latitude: primaryGps.latitude ?? fallbackGps.latitude ?? location.latitude ?? null,
      longitude: primaryGps.longitude ?? fallbackGps.longitude ?? location.longitude ?? null,
    });
  }

  return enrichedLocations;
});

export const generateReviewDraft = onCall(callableOptions, async (request) => {
  requireAdmin(request);
  const data = asObject(request.data);
  const prompt = readString(data, "prompt");
  const destinationId = readOptionalString(data, "destinationId");
  const destinationName = readOptionalString(data, "destinationName");
  const articleStyle = readOptionalString(data, "articleStyle") ?? "review";
  const existingLocations = readLocationContextList(data.existingLocations);

  const destinationContext = destinationId
    ? `Destination: ${destinationName ?? destinationId} (ID: ${destinationId})`
    : "Destination: flexible / unspecified";

  const systemInstruction = `
You are a professional Vietnamese travel blogger.
${destinationContext}
${buildLocationContext(existingLocations)}
${reviewStyleInstructions(articleStyle)}

Return pure JSON only, no markdown fences:
{
  "id": "slug-from-title",
  "heroImage": "",
  "title": "Vietnamese click-worthy title",
  "authorId": "ai-writer",
  "authorName": "AI Travel Writer",
  "authorAvatar": "",
  "fullText": "Markdown article in Vietnamese with at least 3 ## headings",
  "createdAt": "${new Date().toISOString()}",
  "likeCount": 0,
  "commentCount": 0,
  "saveCount": 0,
  "relatedLocationIds": ["real-location-id-1"],
  "destinationId": ${destinationId ? `"${destinationId}"` : "null"},
  "destinationName": ${destinationName ? `"${destinationName}"` : "null"},
  "category": "food or places or stay",
  "slug": "slug-from-title",
  "status": "draft_ai"
}
Rules:
- Write all user-facing text in Vietnamese.
- relatedLocationIds may only contain IDs from the provided location context.
- If no real locations were provided, use an empty array for relatedLocationIds.
- Do not add extra fields or explanations.
`;

  const text = await callGeminiText({
    prompt: `Write a ${articleStyle} travel article for: ${prompt}`,
    systemInstruction,
    useGoogleSearch: true,
  });

  return parseJsonObject(text);
});

export const generateReviewDrafts = onCall(callableOptions, async (request) => {
  requireAdmin(request);
  const data = asObject(request.data);
  const destinationName = readString(data, "destinationName");
  const destinationId = readString(data, "destinationId");
  const count = readInteger(data, "count", 3, 1, 5);
  const existingLocations = readLocationContextList(data.existingLocations);

  const systemInstruction = `
You are a team of Vietnamese travel bloggers. Create ${count} DISTINCT articles for "${destinationName}".
${buildLocationContext(existingLocations)}

Return pure JSON only as an array, no markdown fences:
[
  {
    "id": "slug-from-title",
    "heroImage": "",
    "title": "Vietnamese title",
    "authorId": "ai-writer",
    "authorName": "AI Travel Writer",
    "authorAvatar": "",
    "fullText": "Markdown article in Vietnamese with at least 3 ## headings",
    "createdAt": "${new Date().toISOString()}",
    "likeCount": 0,
    "commentCount": 0,
    "saveCount": 0,
    "relatedLocationIds": ["real-location-id-1"],
    "destinationId": "${destinationId}",
    "destinationName": "${destinationName}",
    "category": "food or places or stay",
    "slug": "slug-from-title",
    "status": "draft_ai"
  }
]
Rules:
- Each article must differ in style, angle, and chosen subset of locations.
- Write all user-facing text in Vietnamese.
- Use only IDs from the supplied location context in relatedLocationIds.
- Do not add extra fields or explanations.
`;

  const text = await callGeminiText({
    prompt: `Create ${count} travel articles for ${destinationName}.`,
    systemInstruction,
    useGoogleSearch: true,
  });

  return parseJsonArray(text);
});

export const enrichAutoPlan = onCall(callableOptions, async (request) => {
  requireAuthenticated(request);
  const data = asObject(request.data);
  const prompt = readString(data, "prompt");

  const text = await callGeminiText({
    prompt,
    responseMimeType: "application/json",
    temperature: 0.4,
    maxOutputTokens: 2048,
  });

  return parseJsonObject(text);
});

export const generateStopTip = onCall(callableOptions, async (request) => {
  requireAuthenticated(request);
  const data = asObject(request.data);
  const locationName = readString(data, "locationName");
  const category = readString(data, "category");
  const startTimeLabel = readString(data, "startTimeLabel");
  const endTimeLabel = readString(data, "endTimeLabel");
  const durationMin = readInteger(data, "durationMin", 60, 10, 720);

  const prompt = [
    "You are a Vietnamese local guide.",
    `Location: ${locationName} (${category}).`,
    `Visit time: ${startTimeLabel} - ${endTimeLabel} (${durationMin} minutes).`,
    "Write 2-3 short sentences in Vietnamese with practical advice, what to do, and one useful caution if relevant.",
    "Return plain text only.",
  ].join(" ");

  const text = await callGeminiText({
    prompt,
    temperature: 0.6,
    maxOutputTokens: 180,
  });

  return stripCodeFence(text);
});
