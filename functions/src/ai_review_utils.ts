export type LocationContext = {
  id: string;
  name: string;
  category: string;
  tags: string[];
  rating?: number;
  address?: string;
  description?: string;
};

export type ReviewNormalizationOptions = {
  destinationId?: string;
  destinationName?: string;
  existingLocations: LocationContext[];
  articleStyle?: string;
  status?: string;
  aiPrompt?: string;
  aiProvider?: string;
};

const allowedReviewCategories = new Set(["food", "places", "stay"]);
const allowedArticleStyles = new Set(["review", "guide", "top-list", "tips"]);
const allowedReviewStatuses = new Set(["draft_ai", "preview_ai", "published"]);

function readOptionalString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function readOptionalStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter((item): item is string => typeof item === "string")
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}

function readOptionalObjectArray(value: unknown): Array<Record<string, unknown>> {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter((item): item is Record<string, unknown> => !!item && typeof item === "object" && !Array.isArray(item));
}

function uniqueStrings(values: string[]): string[] {
  return [...new Set(values)];
}

function clampIsoDate(value: unknown): string {
  const parsed = readOptionalString(value);
  if (!parsed) {
    return new Date().toISOString();
  }

  const date = new Date(parsed);
  return Number.isNaN(date.getTime()) ? new Date().toISOString() : date.toISOString();
}

function normalizeDomain(rawUrl: string | undefined): string | undefined {
  if (!rawUrl) return undefined;
  try {
    return new URL(rawUrl).hostname.replace(/^www\./, "");
  } catch {
    return undefined;
  }
}

function nonNegativeInteger(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return 0;
  }

  return Math.max(0, Math.round(value));
}

function preferredTitle(
  destinationName: string | undefined,
  articleStyle: string,
  index: number,
): string {
  const destination = destinationName ?? "Viet Nam";
  switch (articleStyle) {
    case "guide":
      return `Cam nang du lich ${destination} #${index}`;
    case "top-list":
      return `Top trai nghiem nen thu o ${destination} #${index}`;
    case "tips":
      return `Meo du lich ${destination} #${index}`;
    default:
      return `Review ${destination} #${index}`;
  }
}

function normalizeCategory(
  value: unknown,
  relatedLocationIds: string[],
  locationById: Map<string, LocationContext>,
): string {
  const directCategory = readOptionalString(value)?.toLowerCase();
  if (directCategory && allowedReviewCategories.has(directCategory)) {
    return directCategory;
  }

  for (const locationId of relatedLocationIds) {
    const category = locationById.get(locationId)?.category.toLowerCase();
    if (category && allowedReviewCategories.has(category)) {
      return category;
    }
  }

  return "places";
}

function ensureUniqueId(baseId: string, usedIds: Set<string>): string {
  let candidate = baseId;
  let suffix = 2;

  while (usedIds.has(candidate)) {
    candidate = `${baseId}-${suffix}`;
    suffix += 1;
  }

  usedIds.add(candidate);
  return candidate;
}

export function normalizeArticleStyle(style?: string): string {
  return style && allowedArticleStyles.has(style) ? style : "review";
}

function normalizeReviewStatus(status?: string): string {
  return status && allowedReviewStatuses.has(status) ? status : "draft_ai";
}

export function slugifyVietnamese(input: string, fallback = "ai-review"): string {
  const normalized = input
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[\u0111\u0110]/g, "d")
    .toLowerCase();

  const slug = normalized
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-{2,}/g, "-");

  return slug || fallback;
}

export function buildLocationContext(locations: LocationContext[]): string {
  if (locations.length === 0) {
    return "No existing location context is available. Use general travel knowledge only.";
  }

  const lines = locations.map((location) => {
    const description = location.description?.replace(/\s+/g, " ").trim();
    const safeDescription = description ? description.slice(0, 140) : "";
    return `- ID: "${location.id}" | ${location.name} | ${location.category} | ` +
      `${location.tags.join(", ")} | rating=${location.rating ?? "N/A"} | ` +
      `${location.address ?? ""} | ${safeDescription}`;
  });

  return [
    `The system already has ${locations.length} real locations. Use ONLY these IDs in relatedLocationIds:`,
    ...lines,
  ].join("\n");
}

export function reviewStyleInstructions(style: string): string {
  switch (normalizeArticleStyle(style)) {
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

export function normalizeReviewDraft(
  draft: Record<string, unknown>,
  options: ReviewNormalizationOptions,
  usedIds?: Set<string>,
  index = 1,
): Record<string, unknown> {
  const locationById = new Map(options.existingLocations.map((location) => [location.id, location]));
  const relatedLocationIds = uniqueStrings(
    readOptionalStringArray(draft.relatedLocationIds).filter((id) => locationById.has(id)),
  );
  const articleStyle = normalizeArticleStyle(options.articleStyle);
  const title = readOptionalString(draft.title) ??
    preferredTitle(options.destinationName, articleStyle, index);
  const slug = slugifyVietnamese(readOptionalString(draft.slug) ?? title);
  const idBase = slugifyVietnamese(readOptionalString(draft.id) ?? title, slug);
  const id = usedIds ? ensureUniqueId(idBase, usedIds) : idBase;
  const aiSummary = readOptionalString(draft.aiSummary);
  const aiAngle = readOptionalString(draft.aiAngle);
  const aiOutline = uniqueStrings(readOptionalStringArray(draft.aiOutline));
  const sourceReferences = normalizeSourceReferences(
    draft.sourceReferences,
    draft.citations,
    draft.search_results,
  );
  const heroImageCandidates = normalizeImageCandidates(
    draft.heroImageCandidates ?? draft.images,
  );
  const heroImage = readOptionalString(draft.heroImage) ?? heroImageCandidates[0]?.imageUrl ?? "";
  const heroImageSourceUrl = readOptionalString(draft.heroImageSourceUrl) ?? heroImageCandidates[0]?.sourceUrl;
  const fullText = readOptionalString(draft.fullText) ?? aiSummary ?? aiOutline.map((item) => `- ${item}`).join("\n");
  const status = normalizeReviewStatus(options.status ?? readOptionalString(draft.status));

  return {
    id,
    heroImage,
    title,
    authorId: "ai-writer",
    authorName: "Bien tap vien AI TourVN",
    authorAvatar: readOptionalString(draft.authorAvatar) ?? "",
    fullText,
    createdAt: clampIsoDate(draft.createdAt),
    likeCount: nonNegativeInteger(draft.likeCount),
    commentCount: nonNegativeInteger(draft.commentCount),
    saveCount: nonNegativeInteger(draft.saveCount),
    relatedLocationIds,
    destinationId: options.destinationId ?? readOptionalString(draft.destinationId) ?? null,
    destinationName: options.destinationName ?? readOptionalString(draft.destinationName) ?? null,
    category: normalizeCategory(draft.category, relatedLocationIds, locationById),
    slug,
    status,
    aiSummary: aiSummary ?? null,
    aiAngle: aiAngle ?? null,
    aiOutline,
    sourceReferences,
    heroImageCandidates,
    heroImageSourceUrl: heroImageSourceUrl ?? null,
    aiPrompt: options.aiPrompt ?? readOptionalString(draft.aiPrompt) ?? null,
    aiProvider: options.aiProvider ?? readOptionalString(draft.aiProvider) ?? "perplexity",
  };
}

export function normalizeReviewDraftArray(
  drafts: Array<Record<string, unknown>>,
  options: ReviewNormalizationOptions,
): Array<Record<string, unknown>> {
  const usedIds = new Set<string>();
  return drafts.map((draft, index) =>
    normalizeReviewDraft(draft, options, usedIds, index + 1),
  );
}

function normalizeSourceReferences(
  value: unknown,
  citations: unknown,
  searchResults: unknown,
): Array<Record<string, unknown>> {
  const direct = readOptionalObjectArray(value)
    .map((item) => {
      const url = readOptionalString(item.url);
      if (!url) return null;
      return {
        title: readOptionalString(item.title) ?? url,
        url,
        date: readOptionalString(item.date) ?? null,
        domain: readOptionalString(item.domain) ?? normalizeDomain(url) ?? null,
      };
    })
    .filter((item) => item !== null) as Array<Record<string, unknown>>;

  if (direct.length > 0) {
    return direct;
  }

  const fromSearch = readOptionalObjectArray(searchResults)
    .map((item) => {
      const url = readOptionalString(item.url);
      if (!url) return null;
      return {
        title: readOptionalString(item.title) ?? url,
        url,
        date: readOptionalString(item.date) ?? null,
        domain: readOptionalString(item.domain) ?? normalizeDomain(url) ?? null,
      };
    })
    .filter((item) => item !== null) as Array<Record<string, unknown>>;

  if (fromSearch.length > 0) {
    return fromSearch;
  }

  return readOptionalStringArray(citations).map((url) => ({
    title: url,
    url,
    date: null,
    domain: normalizeDomain(url) ?? null,
  }));
}

function normalizeImageCandidates(value: unknown): Array<Record<string, unknown>> {
  return readOptionalObjectArray(value)
    .map((item) => {
      const imageUrl = readOptionalString(item.imageUrl) ??
        readOptionalString(item.image_url);
      const sourceUrl = readOptionalString(item.sourceUrl) ??
        readOptionalString(item.source_url) ??
        readOptionalString(item.origin_url);
      if (!imageUrl || !sourceUrl) {
        return null;
      }
      return {
        imageUrl,
        sourceUrl,
        title: readOptionalString(item.title) ?? sourceUrl,
        domain: readOptionalString(item.domain) ?? normalizeDomain(sourceUrl) ?? null,
      };
    })
    .filter((item) => item !== null) as Array<Record<string, unknown>>;
}
