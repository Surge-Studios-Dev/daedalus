# AI-RAIL.md · the AI feature rail

How every Surge app's AI surface is built: as a **cached backend callable
with a numeric quality gate**. Extracted from Ladle's import pipeline —
the one part of these apps that is genuinely per-app is the prompt and the
schema; everything around it (caching, keys, versioning, gating, cost
control) is universal infrastructure and ships in the brick's
`backend/src/ai/` + `backend/corpus/`.

> **Status.** The rail is stamped and working on a model mock: the
> `extract` callable runs cache read → model seam → awaited cache write
> end-to-end, key logic is unit-tested, and the corpus harness gates once
> `corpus.json` is real. Per app: wire a real model client (SEAM in
> `ai/extract.ts`), build the corpus, pass the M0 gate.

## Doctrine (each rule was a Ladle bill or bug)

1. **The app never calls a model.** Every AI surface is a callable in
   `backend/src/ai/` — keys, prompts, and costs live server-side where
   they can be cached, versioned, rate-limited, and fixed without a
   release.
2. **Every surface gets a cache key + TTL + pipeline version on day
   one.** Two users sharing the same link = one model call. Storage is
   ~free against 5-15¢ per extraction; the app gets *cheaper per active
   user as the cache grows*. Retrofitting caching after launch is just
   re-paying for every request until you do.
3. **Key on the canonical input.** Normalize URLs (tracking params,
   host aliases, youtu.be) and *resolve opaque short links before
   caching* — Ladle's TikTok imports fragmented the cache across
   `vm.tiktok.com` variants until keys were canonical. Name-keyed
   surfaces go through `slugKey` + an alias map for the same reason.
4. **`PIPELINE_VERSION` is the invalidation lever.** Long TTLs (90d+) are
   safe because posted content is immutable; bump the version on any
   quality-affecting change and old entries age out unread. Version 1
   carries no key suffix so a pre-launch cache seed stays valid.
5. **Await cache writes.** A fire-and-forget write vanishes when the
   Functions instance is reclaimed after the response. Half of Ladle's
   early "cache hits" were misses for exactly this.
6. **Guard against poisoned entries.** A transient upstream failure
   cached as success serves broken results until the TTL. `readCached`
   takes a `validate` hook; use it for any field a transient failure can
   blank.
7. **Tier the pipeline by cost, cheapest first.** Ladle's ladder:
   caption/oEmbed text (~free) → frame OCR + audio (~2¢) → full video
   (~5-10¢). Escalate only when the cheaper tier's output is thin.
8. **A/B model configs on the corpus, not on vibes.** Defaults matter:
   Gemini downsamples images to one tile unless `mediaResolution` is
   raised, and default thinking budgets are 2-3× latency/cost — but the
   hand-tuned "cheaper" video config LOST quantities on the corpus and
   defaults shipped. The corpus decides.
9. **Meter on success.** Charge the free-tier meter (`surge_meter`) the
   moment extraction succeeds server-side — the budget is spent even if
   the user discards the result. Failures never charge.
10. **Seed the cache before launch.** An idempotent seeder filling the
    cache with the head of expected traffic makes day-one imports instant
    and free (Ladle launched with ~600 pre-seeded entries).

## The M0 gate

The AI pipeline is the riskiest thing in the app, so it is milestone 0,
before any UI: build a **100+ item corpus** with expected outcomes
(including deliberate junk that must *fail*), wire
`backend/corpus/run_item.mjs` to the pipeline, and don't start screens
until `npm run corpus` gates green (default: ≥90% pass, p50 < 20s).
Ladle's M0 ran 110 items at 99-100% before a single screen existed, and
every prompt/model change after re-ran it. `corpus/README.md` has the
operating rules (serial types for rate-limited sources, disk-cached
fetches, filtered runs never gate).

## Architecture

| Piece | Home | Contents |
|---|---|---|
| Key helpers | `backend/src/ai/keys.ts` | `normalizeUrl`, `urlCacheKey` (sha1 + platform + version), `slugKey` + aliases, `isStale` — pure, unit-tested |
| Cache | `backend/src/ai/cache.ts` | `readCached` (TTL check, validate hook, best-effort hit counter, never throws) / `writeCached` (awaited, undefined-safe, logs-and-continues) |
| Choreography | `backend/src/ai/extract.ts` | `runExtract`: cache → `ModelClient` seam → awaited write; `PIPELINE_VERSION`; `MockModelClient` ships working |
| Callable | `backend/src/index.ts` | `extract`: auth + rate limit + `runExtract`, house callable conventions |
| Quality gate | `backend/corpus/` | harness (`run.mjs`), per-app pipeline seam (`run_item.mjs`), example corpus, operating rules |
| App side | (per app) | calls the callable, never a model; charges `surge_meter` on success; `surge_import_queue` feeds share-sheet inputs |

## Per-app rollout checklist

1. INTAKE pass 1 names the moat feature and its quality bar → that becomes
   the corpus's expectations.
2. Build `corpus.json` (100+ items, junk included); wire `run_item.mjs`.
3. Replace `MockModelClient` (add `@google/genai`, prompt + schema); pick
   tiers; A/B configs on the corpus.
4. Pass the M0 gate. Only then do screens consume the callable.
5. Before launch: seed the cache; re-run the corpus on every
   quality-affecting change and bump `PIPELINE_VERSION` with it.
