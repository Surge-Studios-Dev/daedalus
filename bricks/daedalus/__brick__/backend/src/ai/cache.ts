import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

import { isStale } from "./keys";

/**
 * Generic Firestore-backed cache for AI results (AI-RAIL.md). One doc per
 * cache key: { payload, writtenAt, hits }.
 *
 * The economics, from Ladle: storage is trivial (~5KB per entry at
 * $0.18/GB-month) against 5-15¢ per fresh extraction — a single hit pays
 * for years of storage, and the app gets CHEAPER per active user as the
 * cache grows. Posted content is immutable, so TTLs are long and the
 * pipeline version in the key is the real invalidation lever.
 */

function ensureApp(): void {
  if (getApps().length === 0) initializeApp();
}

interface CacheDoc {
  payload: unknown;
  writtenAt: Timestamp;
  hits?: number;
}

/**
 * Returns the cached payload for [key] when one exists, isn't stale, and
 * passes [validate]. Increments a best-effort hit counter as a side
 * effect. Never throws — a cache failure must not take down the
 * user-facing path.
 *
 * [validate] is the poisoned-entry guard: return false to treat a doc as
 * a miss. Ladle's video imports cached a transient empty-thumbnail
 * failure and served it for a month until a guard like this re-ran them.
 */
export async function readCached<T>(
  collection: string,
  key: string,
  ttlDays: number,
  validate?: (payload: T) => boolean,
): Promise<T | null> {
  if (!key) return null;
  try {
    ensureApp();
    const snap = await getFirestore().collection(collection).doc(key).get();
    if (!snap.exists) return null;
    const data = snap.data() as CacheDoc | undefined;
    if (!data || data.payload === undefined) return null;
    if (isStale(data.writtenAt.toDate().getTime(), ttlDays)) return null;
    const payload = data.payload as T;
    if (validate && !validate(payload)) return null;
    snap.ref.update({ hits: (data.hits ?? 0) + 1 }).catch(() => undefined);
    return payload;
  } catch {
    return null;
  }
}

/**
 * Persist a successful result. Overwrites any prior entry — freshest wins.
 * Logs-and-continues on failure so caching can't break the user path, but
 * MUST be awaited by the caller: a fire-and-forget write silently vanishes
 * when the Functions instance is reclaimed after the response (the reason
 * half of Ladle's early cache "hits" were misses).
 */
export async function writeCached(
  collection: string,
  key: string,
  payload: unknown,
): Promise<void> {
  if (!key || payload === undefined) return;
  try {
    ensureApp();
    // JSON round-trip drops undefined keys so the write can't throw on an
    // undefined Firestore value buried in the payload.
    const clean = JSON.parse(JSON.stringify(payload)) as unknown;
    await getFirestore().collection(collection).doc(key).set({
      payload: clean,
      writtenAt: Timestamp.now(),
      hits: 0,
    });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.warn(`ai cache write failed for "${key}": ${(err as Error).message}`);
  }
}
