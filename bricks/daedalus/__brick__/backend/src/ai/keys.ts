import { createHash } from "node:crypto";

/**
 * Pure cache-key helpers for the AI rail (AI-RAIL.md). Extracted from
 * Ladle's import pipeline, where cache-key fragmentation was a real bill:
 * every cosmetically-different copy of the same URL re-paid the full
 * extraction (Gemini + video fetch + thumbnail rehost, 5-15¢) until the
 * keys below made them collide.
 */

const TRACKING_PARAMS = new Set([
  "utm_source",
  "utm_medium",
  "utm_campaign",
  "utm_content",
  "utm_term",
  "fbclid",
  "mibextid",
  "gclid",
  "igshid",
  "igsh",
  "_t",
  "ref",
  "ref_src",
  "ref_url",
  "share_app_id",
  "share_link_id",
  "_r",
  "is_copy_url",
  "is_from_webapp",
  "sender_device",
  "sender_web_id",
]);

/**
 * Strip fragment + tracking params + trailing slash + lowercase host so
 * cosmetically-different copies of the same URL collide on the same cache
 * key. Returns the input on parse failure.
 */
export function normalizeUrl(input: string): string {
  try {
    const u = new URL(input.trim());
    u.hash = "";
    u.host = u.host.toLowerCase();
    // Fold host aliases + expand youtu.be so the same video shares one
    // cache entry instead of re-paying the pipeline per link variant.
    // Opaque short links (vm.tiktok.com) can only be resolved by following
    // the redirect, so they're left alone here — resolve them BEFORE
    // caching and key on the canonical URL (Ladle's TikTok cost lesson).
    if (u.host === "m.youtube.com" || u.host === "music.youtube.com") {
      u.host = "www.youtube.com";
    } else if (u.host === "m.tiktok.com") {
      u.host = "www.tiktok.com";
    } else if (u.host === "youtu.be") {
      const id = u.pathname.replace(/^\/+/, "").split("/")[0];
      if (id) {
        u.host = "www.youtube.com";
        u.pathname = "/watch";
        u.searchParams.set("v", id);
      }
    }
    // Normalize the trailing slash on the path itself, before the query is
    // reassembled: trimming the serialized URL misses ".../page/?a=1".
    u.pathname = u.pathname.replace(/\/+$/, "") || "/";
    const keep: [string, string][] = [];
    u.searchParams.forEach((value, key) => {
      if (!TRACKING_PARAMS.has(key.toLowerCase())) keep.push([key, value]);
    });
    keep.sort(([a], [b]) => a.localeCompare(b));
    u.search = "";
    for (const [k, v] of keep) u.searchParams.append(k, v);
    return u.toString();
  } catch {
    return input.trim();
  }
}

export type Platform = "tiktok" | "instagram" | "youtube" | "facebook" | "web";

/** Coarse source platform, derived from the URL on both read and write so
 *  neither side has to remember it. */
export function platformOf(url: string): Platform {
  const u = url.toLowerCase();
  if (u.includes("tiktok")) return "tiktok";
  if (u.includes("instagram")) return "instagram";
  if (/youtu\.be|youtube/.test(u)) return "youtube";
  if (/facebook\.com|fb\.watch/.test(u)) return "facebook";
  return "web";
}

/**
 * Cache key for a URL-keyed AI result: a 32-char sha1 prefix of the
 * normalized URL, a `-{platform}` suffix so docs are scannable in the
 * Firestore console, and a `-v{N}` suffix once [version] moves past 1.
 * Bumping the version is the invalidation lever after a quality-affecting
 * pipeline change — old entries are simply never read again.
 */
export function urlCacheKey(url: string, version = 1): string {
  const hash = createHash("sha1")
    .update(normalizeUrl(url))
    .digest("hex")
    .slice(0, 32);
  const suffix = version > 1 ? `-v${version}` : "";
  return `${hash}-${platformOf(url)}${suffix}`;
}

/**
 * Cache key for a name-keyed AI result ("mac & cheese" macros, a dish
 * shortlist): lowercased, apostrophes dropped, `&` folded to "and",
 * everything else dashed. [aliases] maps synonym slugs onto one canonical
 * entry ("mac-n-cheese" -> "macaroni-and-cheese") so near-identical
 * queries share a cache line instead of each paying a model call.
 */
export function slugKey(
  name: string,
  aliases: Record<string, string> = {},
): string {
  const slug = name
    .trim()
    .toLowerCase()
    .replace(/['’]/g, "")
    .replace(/&/g, " and ")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  return aliases[slug] ?? slug;
}

/** Whether a cache entry written at [writtenAtMs] has outlived [ttlDays]. */
export function isStale(
  writtenAtMs: number,
  ttlDays: number,
  nowMs: number = Date.now(),
): boolean {
  return nowMs - writtenAtMs > ttlDays * 86_400_000;
}
