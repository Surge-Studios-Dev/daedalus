// Unit tests for the pure AI-rail layer - no emulator, no model. The
// Firestore cache I/O (cache.ts) never throws by contract and is exercised
// by the live pipeline this scaffold was extracted from; what lives here is
// every pure decision the cache keys make, because key fragmentation is a
// bill, not a bug report.
import assert from "node:assert/strict";

import {
  isStale,
  normalizeUrl,
  platformOf,
  slugKey,
  urlCacheKey,
} from "../../lib/ai/keys.js";

describe("normalizeUrl", () => {
  it("strips fragments and tracking params", () => {
    assert.equal(
      normalizeUrl("https://Example.com/recipe/?utm_source=x&fbclid=y#step-2"),
      "https://example.com/recipe",
    );
  });

  it("keeps meaningful params, sorted for stable keys", () => {
    assert.equal(
      normalizeUrl("https://example.com/watch?v=abc&t=30"),
      "https://example.com/watch?t=30&v=abc",
    );
  });

  it("normalizes the trailing slash even when a query follows", () => {
    assert.equal(
      normalizeUrl("https://example.com/recipe/?a=1"),
      normalizeUrl("https://example.com/recipe?a=1"),
    );
  });

  it("folds youtu.be and mobile hosts onto one canonical entry", () => {
    assert.equal(
      normalizeUrl("https://youtu.be/abc123"),
      "https://www.youtube.com/watch?v=abc123",
    );
    assert.equal(
      normalizeUrl("https://m.youtube.com/watch?v=abc123"),
      "https://www.youtube.com/watch?v=abc123",
    );
    assert.equal(
      normalizeUrl("https://m.tiktok.com/v/123"),
      "https://www.tiktok.com/v/123",
    );
  });

  it("returns unparseable input trimmed, not thrown", () => {
    assert.equal(normalizeUrl("  not a url  "), "not a url");
  });
});

describe("urlCacheKey", () => {
  it("cosmetically-different copies of one URL share a key", () => {
    const a = urlCacheKey("https://example.com/r/?utm_source=ig");
    const b = urlCacheKey("https://EXAMPLE.com/r");
    assert.equal(a, b);
  });

  it("carries a scannable platform suffix", () => {
    assert.match(urlCacheKey("https://www.tiktok.com/@u/video/1"), /-tiktok$/);
    assert.match(urlCacheKey("https://youtu.be/abc"), /-youtube$/);
    assert.match(urlCacheKey("https://myblog.com/r"), /-web$/);
  });

  it("version 1 keys carry no suffix so a pre-versioning seed stays valid", () => {
    const v1 = urlCacheKey("https://example.com/r", 1);
    const v2 = urlCacheKey("https://example.com/r", 2);
    assert.doesNotMatch(v1, /-v1$/);
    assert.match(v2, /-v2$/);
    assert.notEqual(v1, v2);
  });
});

describe("platformOf", () => {
  it("routes the major sources", () => {
    assert.equal(platformOf("https://vm.tiktok.com/ZM123/"), "tiktok");
    assert.equal(platformOf("https://www.instagram.com/reel/x/"), "instagram");
    assert.equal(platformOf("https://fb.watch/abc/"), "facebook");
    assert.equal(platformOf("https://smittenkitchen.com/x/"), "web");
  });
});

describe("slugKey", () => {
  it("normalizes punctuation, case, and ampersands", () => {
    assert.equal(slugKey("Mac & Cheese"), "mac-and-cheese");
    assert.equal(slugKey("  Shepherd's  Pie "), "shepherds-pie");
  });

  it("aliases fold synonyms onto one cache line", () => {
    const aliases = { "mac-n-cheese": "macaroni-and-cheese" };
    assert.equal(slugKey("mac n cheese", aliases), "macaroni-and-cheese");
    assert.equal(slugKey("lasagna", aliases), "lasagna");
  });
});

describe("isStale", () => {
  it("honors the TTL boundary", () => {
    const day = 86_400_000;
    const now = 100 * day;
    assert.equal(isStale(now - 89 * day, 90, now), false);
    assert.equal(isStale(now - 91 * day, 90, now), true);
  });
});
