// Share snapshots are client-supplied (offline persistence means the
// server copy may lag; the client's object is the truth). That makes this
// module the trust boundary: everything is re-validated, capped, and
// rebuilt value-by-value so a hostile payload can't stuff oversized
// strings, deep nesting, or a >1MB doc into the public `shares` data.
//
// This sanitizer is GENERIC: it enforces structural caps, not domain
// shape. SEAM: when your app's share payload settles, add a domain
// sanitizer on top that rebuilds only the fields your snapshot actually
// has (see Ladle's sanitize.ts for the pattern - whitelisted keys,
// enum-checked values, per-field caps).

export interface SanitizeLimits {
  /** Serialized-JSON budget per item (data: images excluded - rehosted). */
  maxItemBytes: number;
  maxStringChars: number;
  maxArrayLength: number;
  maxDepth: number;
  maxKeys: number;
}

export const DEFAULT_LIMITS: SanitizeLimits = {
  maxItemBytes: 30_000,
  maxStringChars: 2_000,
  maxArrayLength: 150,
  maxDepth: 4,
  maxKeys: 40,
};

// Remote/Storage URLs only at this cap; data: URIs pass through untrimmed
// (a trimmed base64 URI is garbage) because the caller rehosts them to
// Storage before the doc is written.
const MAX_URL = 2048;

function clean(
  value: unknown,
  limits: SanitizeLimits,
  depth: number,
): unknown {
  if (typeof value === "string") {
    return value.slice(0, limits.maxStringChars).trim();
  }
  if (typeof value === "number") {
    if (!Number.isFinite(value)) return 0;
    return Math.max(-1e9, Math.min(1e9, value));
  }
  if (typeof value === "boolean") return value;
  if (Array.isArray(value)) {
    if (depth >= limits.maxDepth) return [];
    return value
      .slice(0, limits.maxArrayLength)
      .map((v) => clean(v, limits, depth + 1))
      .filter((v) => v !== null);
  }
  if (value && typeof value === "object") {
    if (depth >= limits.maxDepth) return null;
    const out: Record<string, unknown> = {};
    let keys = 0;
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      if (keys >= limits.maxKeys) break;
      const cleaned = clean(v, limits, depth + 1);
      if (cleaned === null) continue;
      out[k.slice(0, 64)] = cleaned;
      keys++;
    }
    return out;
  }
  return null; // undefined, functions, symbols, bigints: dropped
}

/**
 * Rebuild an item snapshot from an untrusted payload. Returns null when
 * the payload is not an object or blows the size budget even after caps
 * (nothing worth sharing). The top-level `image` field is special-cased:
 * a data: URI passes untrimmed for rehosting; anything else must be an
 * http(s) URL within the URL cap or it is blanked.
 */
export function sanitizeSnapshot(
  raw: unknown,
  limits: SanitizeLimits = DEFAULT_LIMITS,
): Record<string, unknown> | null {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) return null;
  const rebuilt = clean(raw, limits, 0) as Record<string, unknown>;
  const rawImage = (raw as Record<string, unknown>).image;
  let image = "";
  if (typeof rawImage === "string") {
    if (rawImage.startsWith("data:")) {
      image = rawImage;
    } else if (/^https?:\/\//.test(rawImage) && rawImage.length <= MAX_URL) {
      image = rawImage;
    }
  }
  rebuilt.image = image;
  const { image: _img, ...measured } = rebuilt;
  if (JSON.stringify(measured).length > limits.maxItemBytes) return null;
  return rebuilt;
}
