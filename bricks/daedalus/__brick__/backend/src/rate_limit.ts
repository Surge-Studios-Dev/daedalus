import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

function ensureApp(): void {
  if (!getApps().some((a) => a.name === "[DEFAULT]")) {
    initializeApp();
  }
}

const COLLECTION = "rate_limits";

// Generous per-uid, per-action daily ceiling: high enough that no real user
// hits it, low enough to bound a single compromised/scripted account's
// abuse to "100/day". Interim defense-in-depth; the durable fix is App
// Check (enforceAppCheck: true) once it's wired client-side.
const DAILY_CAP = 100;

// Keep counter docs ~2 days so a TTL policy on `expireAt` can sweep them.
const TTL_MS = 2 * 24 * 60 * 60 * 1000;

/**
 * Throttle a uid to [DAILY_CAP] calls of [action] per UTC day. Throws
 * `resource-exhausted` once the cap is exceeded.
 *
 * Fails OPEN on any Firestore error: this is a cost backstop, not the
 * primary auth control (requireAuth is), so a counter outage must never
 * block a legitimate user. The cap error is raised outside the try/catch
 * so it is never swallowed by the fail-open path.
 */
export async function enforceRateLimit(
  uid: string | undefined,
  action: string,
): Promise<void> {
  if (!uid) return;
  const day = new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)
  let exceeded = false;
  try {
    ensureApp();
    const db = getFirestore();
    const ref = db.collection(COLLECTION).doc(`${uid}_${action}_${day}`);
    exceeded = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const count = (snap.exists ? (snap.data()?.count as number) : 0) ?? 0;
      if (count >= DAILY_CAP) return true;
      tx.set(
        ref,
        {
          uid,
          action,
          day,
          count: count + 1,
          expireAt: Timestamp.fromMillis(Date.now() + TTL_MS),
        },
        { merge: true },
      );
      return false;
    });
  } catch (err) {
    console.warn(
      `rate_limit check failed (failing open): ${(err as Error).message}`,
    );
    return;
  }
  if (exceeded) {
    throw new HttpsError(
      "resource-exhausted",
      "You've reached today's limit. Try again tomorrow.",
    );
  }
}
