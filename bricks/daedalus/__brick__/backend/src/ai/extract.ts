import { readCached, writeCached } from "./cache";
import { urlCacheKey } from "./keys";

/**
 * The cached-extraction choreography (AI-RAIL.md): cache read -> model
 * call -> AWAITED cache write. Every AI surface goes through this shape;
 * the model behind it is a seam.
 */

/**
 * Bump after a quality-affecting pipeline change (new prompt, better
 * model, fixed parser). Old entries are never read again and age out via
 * the TTL. Version 1 keys carry no suffix, so a pre-versioning cache
 * (including a launch seed) stays valid.
 */
export const PIPELINE_VERSION = 1;

const COLLECTION = "ai_cache";

/**
 * Posted videos and published pages are immutable, so cached extractions
 * don't go stale on their own — the TTL exists to eventually pick up
 * pipeline improvements. With PIPELINE_VERSION as the explicit
 * invalidation lever the TTL can be long: a viral link stays free and
 * instant for a whole season instead of re-paying extraction monthly.
 */
const TTL_DAYS = 90;

/** SEAM: the model behind the extraction. The mock ships working so a
 *  stamped app runs end-to-end; swap in a real client (Gemini via
 *  `@google/genai`, prompt + schema per app) when the AI surface is built.
 *  Decide the model tier per surface by A/B on the corpus, not by
 *  assumption — Ladle's video pipeline WON on API defaults over a
 *  hand-tuned low-res/think-capped config. */
export interface ModelClient {
  extract(url: string): Promise<Record<string, unknown>>;
}

export class MockModelClient implements ModelClient {
  async extract(url: string): Promise<Record<string, unknown>> {
    return {
      ok: true,
      source: url,
      title: "Mock extraction",
      note: "SEAM: replace MockModelClient with a real model client.",
    };
  }
}

export interface ExtractResult {
  cached: boolean;
  payload: Record<string, unknown>;
}

/**
 * Extract [url] through the cache: two users sharing the same link = one
 * model call. The write is awaited on purpose — fire-and-forget writes
 * vanish when the Functions instance is reclaimed after the response.
 */
export async function runExtract(
  url: string,
  model: ModelClient,
): Promise<ExtractResult> {
  const key = urlCacheKey(url, PIPELINE_VERSION);
  const cached = await readCached<Record<string, unknown>>(
    COLLECTION,
    key,
    TTL_DAYS,
  );
  if (cached) return { cached: true, payload: cached };
  const payload = await model.extract(url);
  await writeCached(COLLECTION, key, payload);
  return { cached: false, payload };
}
