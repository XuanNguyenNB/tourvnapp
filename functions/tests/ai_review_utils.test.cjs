const test = require("node:test");
const assert = require("node:assert/strict");

const {
  normalizeArticleStyle,
  normalizeReviewDraft,
  normalizeReviewDraftArray,
} = require("../lib/ai_review_utils.js");

test("normalizeReviewDraft keeps only real location ids and forces admin fields", () => {
  const draft = {
    id: "bad custom id",
    title: "Review Phu Quoc 3N2D",
    authorName: "Random Author",
    fullText: "## Tong quan\n\nNoi dung review chi tiet.",
    relatedLocationIds: ["loc-food", "fake-id", "loc-food"],
    destinationId: "wrong-destination",
    category: "unknown",
    status: "published",
  };

  const normalized = normalizeReviewDraft(draft, {
    destinationId: "phu-quoc",
    destinationName: "Phu Quoc",
    articleStyle: "review",
    existingLocations: [
      {
        id: "loc-food",
        name: "Quan oc",
        category: "food",
        tags: ["hai-san"],
      },
    ],
  });

  assert.equal(normalized.id, "bad-custom-id");
  assert.equal(normalized.slug, "review-phu-quoc-3n2d");
  assert.equal(normalized.destinationId, "phu-quoc");
  assert.equal(normalized.destinationName, "Phu Quoc");
  assert.deepEqual(normalized.relatedLocationIds, ["loc-food"]);
  assert.equal(normalized.category, "food");
  assert.equal(normalized.authorId, "ai-writer");
  assert.equal(normalized.authorName, "Bien tap vien AI TourVN");
  assert.equal(normalized.status, "draft_ai");
});

test("normalizeReviewDraftArray makes duplicate titles unique", () => {
  const drafts = [
    {
      title: "Top quan an o Da Lat",
      fullText: "## Mon ngon\n\nGioi thieu.",
      relatedLocationIds: ["loc-1"],
    },
    {
      title: "Top quan an o Da Lat",
      fullText: "## Quan ca phe\n\nNoi dung khac.",
      relatedLocationIds: ["loc-2"],
    },
  ];

  const normalized = normalizeReviewDraftArray(drafts, {
    destinationId: "da-lat",
    destinationName: "Da Lat",
    articleStyle: "top-list",
    existingLocations: [
      {id: "loc-1", name: "Banh can", category: "food", tags: []},
      {id: "loc-2", name: "Tiem ca phe", category: "food", tags: []},
    ],
  });

  assert.equal(normalized[0].id, "top-quan-an-o-da-lat");
  assert.equal(normalized[1].id, "top-quan-an-o-da-lat-2");
  assert.equal(normalized[0].slug, "top-quan-an-o-da-lat");
  assert.equal(normalized[1].slug, "top-quan-an-o-da-lat");
  assert.deepEqual(normalized[0].relatedLocationIds, ["loc-1"]);
  assert.deepEqual(normalized[1].relatedLocationIds, ["loc-2"]);
});

test("normalizeArticleStyle falls back to review for unknown values", () => {
  assert.equal(normalizeArticleStyle("guide"), "guide");
  assert.equal(normalizeArticleStyle("not-supported"), "review");
  assert.equal(normalizeArticleStyle(undefined), "review");
});
