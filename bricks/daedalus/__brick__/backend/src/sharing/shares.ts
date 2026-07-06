import { setTimeout as sleep } from "node:timers/promises";
import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { canonicalCode, newShareId } from "./codes";
import { buildShareLink } from "./links";
import { ensureReferral } from "./referrals";
import { sanitizeSnapshot } from "./sanitize";
import { parseDataUri, saveShareImage } from "./storage";

// Shares are snapshots by design (SHARING.md): they survive the original
// being edited or deleted, can be revoked, and never expose the owner's
// private data. The snapshot payload comes from the client (offline
// persistence means the server copy may lag) and is re-validated in
// sanitize.ts. Clients get no direct Firestore access to `shares` - all
// reads/writes go through these callables.
//
// Doc shape matches surge_share's ShareService wire contract: the parent
// doc carries metadata (LIGHT - it must land inside the unfurl poll
// window); item snapshots live in an `items` subcollection keyed by the
// CLIENT's index, so attachShareImage can address an item without the
// client replicating the sanitize filter.

const SHARES = "shares";
const MAX_ITEMS = 50;
const MAX_CARD_BASE64_CHARS = 4_000_000; // ~3 MB decoded PNG

function db() {
  if (!getApps().some((a) => a.name === "[DEFAULT]")) {
    initializeApp();
  }
  return getFirestore();
}

/** Firestore rejects `undefined` fields; a JSON round-trip drops them. */
function jsonClean<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T;
}

const CLIENT_SHARE_ID = /^[a-z0-9]{10,20}$/;
const SHARE_ID = /^[a-z0-9]{6,20}$/;

function itemDocId(i: number): string {
  return String(i).padStart(3, "0");
}

/**
 * Inline data: URI images can be megabytes - rehost to the share's Storage
 * folder so the share doc stays far under the 1MB Firestore cap.
 * Unrecoverable -> no image (placeholder art on the receiving end).
 */
async function rehostDataUriImage(
  shareId: string,
  name: string,
  image: string,
): Promise<string> {
  if (!image.startsWith("data:")) return image;
  const parsed = parseDataUri(image);
  if (!parsed) return "";
  try {
    return await saveShareImage(shareId, name, parsed.bytes, parsed.mime);
  } catch (err) {
    console.warn(`share image rehost failed: ${(err as Error).message}`);
    return "";
  }
}

export interface CreateShareRequest {
  /** App-defined shareable type id (manifest sharing.content). */
  type?: string;
  title?: string;
  /**
   * Pregenerated on device (surge_share newLocalShareId) so the app hands
   * the link to the system share sheet instantly and uploads this snapshot
   * in the background. Optional; validated, and the write is create-only
   * so a reused id can never overwrite an existing share.
   */
  shareId?: string;
  /** Sanitized-on-device snapshots; re-sanitized here (trust boundary). */
  items?: unknown;
  /** Branded share-card PNG rendered by the app. Optional legacy path. */
  cardPngBase64?: string;
}

export interface CreateShareResult {
  shareId: string;
  link: string;
  /** Items dropped from an oversized bundle, for honest UI. */
  droppedItems: number;
}

export async function createShare(
  uid: string,
  ownerName: string,
  data: CreateShareRequest,
): Promise<CreateShareResult> {
  const type =
    typeof data.type === "string" && /^[a-z][a-z0-9_]{0,39}$/.test(data.type)
      ? data.type
      : "";
  if (!type) {
    throw new HttpsError("invalid-argument", "Provide a share type.");
  }
  const title =
    typeof data.title === "string" ? data.title.slice(0, 200).trim() : "";
  if (!title) {
    throw new HttpsError("invalid-argument", "Nothing shareable here.");
  }
  const shareId =
    typeof data.shareId === "string" && CLIENT_SHARE_ID.test(data.shareId)
      ? data.shareId
      : newShareId();

  // Kick the referral lookup off NOW so it overlaps the image rehosting
  // below - every ms off this callable is unfurl reliability (messengers
  // fetch the link preview the moment a message sends). The stray-catch
  // keeps a validation throw below from leaving an unhandled rejection.
  const referralPromise = ensureReferral(uid, ownerName);
  referralPromise.catch(() => undefined);

  const rawItems = Array.isArray(data.items) ? data.items : [];
  const droppedItems = Math.max(0, rawItems.length - MAX_ITEMS);
  // Item ids keep the CLIENT's index (gaps where sanitize dropped an item)
  // so attachShareImage can address an item by the index the client knows.
  const indexed = rawItems
    .slice(0, MAX_ITEMS)
    .map((raw, i) => ({ i, snap: sanitizeSnapshot(raw) }))
    .filter(
      (e): e is { i: number; snap: Record<string, unknown> } =>
        e.snap !== null,
    );

  // Inline data: URIs would blow the per-doc caps - rehost each to the
  // share's Storage folder. Current clients strip inline images before
  // calling (they arrive later via attachShareImage); this path still
  // serves payloads that carry them. Failures degrade to placeholder art,
  // never a failed share.
  await Promise.all(
    indexed.map(async ({ i, snap }) => {
      snap.image = await rehostDataUriImage(
        shareId,
        `i${itemDocId(i)}.jpg`,
        (snap.image as string) ?? "",
      );
    }),
  );

  // Every share link carries the sharer's referral code. Links are
  // deterministic self-hosted URLs (links.ts) - no mint API; the shareLink
  // HTTP function renders the unfurl page from the doc below.
  const referral = await referralPromise;
  const link = buildShareLink(shareId, canonicalCode(referral.code));
  const firstImage = indexed
    .map(({ snap }) => snap.image)
    .find((img) => typeof img === "string" && img.startsWith("http"));

  const firestore = db();
  const shareRef = firestore.collection(SHARES).doc(shareId);
  const base = {
    type,
    ownerUid: uid,
    ownerName: ownerName.slice(0, 80),
    ref: canonicalCode(referral.code),
    title,
    link,
    // Filled by attachShareCard AFTER the doc write: the doc must exist
    // the moment the link is sendable - unfurl bots race the background
    // upload, and a valid title + hero fallback beats a 404 in that
    // window.
    cardUrl: "",
    // First item's remote image: the /c/ endpoint's fallback when the
    // card never lands.
    heroImage: (firstImage as string) ?? "",
    itemCount: indexed.length,
    stats: { views: 0, saves: 0 },
    revoked: false,
    createdAt: FieldValue.serverTimestamp(),
  };
  // create(), never set(): the id may be client-supplied, and a reused id
  // must not overwrite (hijack) someone's existing share.
  try {
    const batch = firestore.batch();
    batch.create(shareRef, jsonClean(base));
    indexed.forEach(({ i, snap }) => {
      batch.set(
        shareRef.collection("items").doc(itemDocId(i)),
        jsonClean({ idx: i, ...snap }),
      );
    });
    await batch.commit();
  } catch (err) {
    const code = (err as { code?: number }).code;
    if (code === 6 /* ALREADY_EXISTS */) {
      throw new HttpsError(
        "already-exists",
        "That share id is taken. Try again.",
      );
    }
    throw err;
  }
  // Legacy single-call path: card carried in this request uploads after
  // the doc write (surge_share sends it separately via attachShareCard,
  // firing this callable card-less the instant Share is tapped).
  if (data.cardPngBase64) {
    await attachShareCard(uid, shareId, data.cardPngBase64);
  }
  return { shareId, link, droppedItems };
}

/**
 * Upload the branded card PNG for an existing share and point the doc
 * (and thus the link's og:image) at it. Split from createShare so the
 * share doc can be written before the card capture finishes - the link
 * must unfurl with a real title from the second it is sendable. Card
 * problems never break sharing: the page falls back to the hero image.
 */
export async function attachShareCard(
  uid: string,
  shareId: unknown,
  cardPngBase64: unknown,
): Promise<void> {
  if (typeof shareId !== "string" || !SHARE_ID.test(shareId)) {
    throw new HttpsError("invalid-argument", "Invalid share id.");
  }
  if (typeof cardPngBase64 !== "string" || cardPngBase64.length === 0) {
    throw new HttpsError("invalid-argument", "Provide cardPngBase64.");
  }
  if (cardPngBase64.length > MAX_CARD_BASE64_CHARS) {
    throw new HttpsError("invalid-argument", "Card image is too large.");
  }
  const ref = db().collection(SHARES).doc(shareId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "This share no longer exists.");
  }
  if (snap.data()?.ownerUid !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the owner can update a share.",
    );
  }
  try {
    const bytes = Buffer.from(cardPngBase64, "base64");
    if (bytes.byteLength === 0) return;
    const cardUrl = await saveShareImage(
      shareId,
      "card.png",
      bytes,
      "image/png",
    );
    await ref.update({ cardUrl });
  } catch (err) {
    console.warn(`share card upload failed: ${(err as Error).message}`);
  }
}

/**
 * Attach a stripped inline image to an existing share's item. Split from
 * createShare for the same reason as attachShareCard: a data: URI image is
 * megabytes on a phone uplink, and the share doc must land inside the
 * unfurl page's poll window - so the app writes the doc image-less and
 * uplinks each stripped image through here afterward. [index] is the
 * item's position in the client's payload. Fill-only: an item whose image
 * is already set is left untouched, so a retry can never mutate a share
 * that unfurl bots have already rendered.
 */
export async function attachShareImage(
  uid: string,
  shareId: unknown,
  index: unknown,
  imageDataUri: unknown,
): Promise<void> {
  if (typeof shareId !== "string" || !SHARE_ID.test(shareId)) {
    throw new HttpsError("invalid-argument", "Invalid share id.");
  }
  const idx = typeof index === "number" && Number.isInteger(index) ? index : -1;
  if (idx < 0 || idx >= MAX_ITEMS) {
    throw new HttpsError("invalid-argument", "Invalid image index.");
  }
  const parsed =
    typeof imageDataUri === "string" ? parseDataUri(imageDataUri) : null;
  if (!parsed) {
    throw new HttpsError("invalid-argument", "Provide a data: URI image.");
  }
  const ref = db().collection(SHARES).doc(shareId);
  const snap = await ref.get();
  const data = snap.data();
  if (!snap.exists || !data) {
    throw new HttpsError("not-found", "This share no longer exists.");
  }
  if (data.ownerUid !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the owner can update a share.",
    );
  }
  // Storage/update failures are swallowed like the card's: a missing image
  // degrades to placeholder art, never a failed share.
  try {
    const itemRef = ref.collection("items").doc(itemDocId(idx));
    const itemSnap = await itemRef.get();
    if (!itemSnap.exists || itemSnap.data()?.image) return;
    const url = await saveShareImage(
      shareId,
      `i${itemDocId(idx)}.jpg`,
      parsed.bytes,
      parsed.mime,
    );
    await itemRef.update({ image: url });
    // First item's image doubles as the card fallback on the parent doc.
    if (!data.heroImage) {
      await ref.update({ heroImage: url }).catch(() => undefined);
    }
  } catch (err) {
    console.warn(`share image upload failed: ${(err as Error).message}`);
  }
}

export interface ShareViewResult {
  shareId: string;
  type: string;
  ownerName: string;
  ref: string;
  title: string;
  createdAtMs: number;
  items: Record<string, unknown>[];
  stats: { views: number; saves: number };
}

export type GetShareResult =
  | { ok: true; share: ShareViewResult }
  | { ok: false; reason: "gone" };

export async function getShare(shareId: string): Promise<GetShareResult> {
  if (typeof shareId !== "string" || !SHARE_ID.test(shareId)) {
    throw new HttpsError("invalid-argument", "Invalid share id.");
  }
  const firestore = db();
  const ref = firestore.collection(SHARES).doc(shareId);
  let snap = await ref.get();
  // Same race as the web page: a receiver can tap a just-sent link before
  // the background doc write lands. Give it a moment before declaring the
  // share gone (the preview screen shows its spinner meanwhile).
  for (let attempt = 0; !snap.exists && attempt < 6; attempt++) {
    await sleep(500);
    snap = await ref.get();
  }
  const data = snap.data();
  if (!snap.exists || !data || data.revoked) {
    return { ok: false, reason: "gone" };
  }
  // View count is best-effort telemetry; never let it fail the read.
  ref
    .update({ "stats.views": FieldValue.increment(1) })
    .catch(() => undefined);
  const items = await ref.collection("items").orderBy("idx").get();
  return {
    ok: true,
    share: {
      shareId,
      type: data.type ?? "",
      ownerName: data.ownerName ?? "",
      ref: data.ref ?? "",
      title: data.title ?? "",
      createdAtMs: data.createdAt?.toMillis?.() ?? 0,
      items: items.docs.map((d) => {
        const item = d.data() as Record<string, unknown> & { idx?: number };
        delete item.idx;
        return item;
      }),
      stats: {
        views: data.stats?.views ?? 0,
        saves: data.stats?.saves ?? 0,
      },
    },
  };
}

/** Bump the saves counter when a receiver saves the share. */
export async function recordShareSave(shareId: string): Promise<void> {
  if (typeof shareId !== "string" || !SHARE_ID.test(shareId)) return;
  await db()
    .collection(SHARES)
    .doc(shareId)
    .update({ "stats.saves": FieldValue.increment(1) })
    .catch(() => undefined);
}

export async function revokeShare(uid: string, shareId: string): Promise<void> {
  if (typeof shareId !== "string" || !SHARE_ID.test(shareId)) {
    throw new HttpsError("invalid-argument", "Invalid share id.");
  }
  const firestore = db();
  const ref = firestore.collection(SHARES).doc(shareId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "This shared link no longer exists.");
  }
  if (snap.data()?.ownerUid !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the owner can revoke a share.",
    );
  }
  await ref.update({ revoked: true, revokedAt: FieldValue.serverTimestamp() });
}
