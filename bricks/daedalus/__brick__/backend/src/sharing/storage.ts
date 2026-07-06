import { randomUUID } from "node:crypto";
import { getApps, initializeApp } from "firebase-admin/app";
import { getStorage } from "firebase-admin/storage";

// Tokened-download-URL pattern: a Firebase download token makes the object
// publicly fetchable via its URL without object ACLs, which uniform
// bucket-level access forbids. Share images must be public - the card PNG
// doubles as the share link's og:image.

const BUCKET = () =>
  process.env.STORAGE_BUCKET || "{{firebase_project}}.firebasestorage.app";

function ensureApp(): void {
  if (!getApps().some((a) => a.name === "[DEFAULT]")) {
    initializeApp({ storageBucket: BUCKET() });
  }
}

/**
 * Save an image under shares/{shareId}/ and return its public download
 * URL. Throws on Storage failure - callers decide whether the image is
 * essential (card: no, drop it) or not.
 */
export async function saveShareImage(
  shareId: string,
  name: string,
  bytes: Buffer,
  contentType: string,
): Promise<string> {
  ensureApp();
  const bucket = getStorage().bucket(BUCKET());
  const objectPath = `shares/${shareId}/${name}`;
  const file = bucket.file(objectPath);
  const token = randomUUID();
  await file.save(bytes, {
    metadata: {
      contentType,
      cacheControl: "public,max-age=31536000",
      metadata: { firebaseStorageDownloadTokens: token },
    },
    resumable: false,
  });
  return (
    `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
    `${encodeURIComponent(objectPath)}?alt=media&token=${token}`
  );
}

/** Parse a `data:<mime>;base64,` URI. Null for anything else. */
export function parseDataUri(
  uri: string,
): { bytes: Buffer; mime: string } | null {
  if (!uri.startsWith("data:")) return null;
  const m = /^data:([^;,]*);base64,(.*)$/s.exec(uri);
  if (!m) return null;
  const bytes = Buffer.from(m[2], "base64");
  if (bytes.byteLength === 0) return null;
  return { bytes, mime: m[1] || "image/jpeg" };
}
