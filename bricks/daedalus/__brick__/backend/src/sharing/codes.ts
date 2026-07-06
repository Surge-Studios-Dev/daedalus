import { randomBytes } from "node:crypto";

// Alphabet for generated ids/codes: no 0/O/1/I/L lookalikes so codes
// survive being read aloud or retyped from a screenshot.
const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";

/** Random string of [length] chars from the unambiguous alphabet. */
export function randomCode(length: number): string {
  const bytes = randomBytes(length);
  let out = "";
  for (let i = 0; i < length; i++) {
    out += CODE_ALPHABET[bytes[i] % CODE_ALPHABET.length];
  }
  return out;
}

/** Share ids are lowercase and URL-safe: 12 chars ~= 59 bits of entropy.
 *  Matches surge_share's client-side newLocalShareId(). */
export function newShareId(): string {
  return randomCode(12).toLowerCase();
}

/**
 * Human-facing referral code like "ELI-4F2K": a letters-only prefix from
 * the display name (fallback SRG) + 4 random chars. Uniqueness is the
 * caller's job (retry with a fresh suffix on collision).
 */
export function newReferralCode(displayName: string | undefined): string {
  const letters = (displayName ?? "")
    .toUpperCase()
    .replace(/[^A-Z]/g, "")
    // Map lookalikes out of the prefix too so the whole code stays typable.
    .replace(/[OIL]/g, "");
  const prefix = (letters + "SRG").slice(0, 3);
  return `${prefix}-${randomCode(4)}`;
}

/**
 * Canonical form used as the lookup key: uppercase alphanumerics only, so
 * "eli-4f2k", "ELI 4F2K" and "ELI-4F2K" all resolve to the same doc.
 */
export function canonicalCode(input: string): string {
  return input.toUpperCase().replace(/[^A-Z0-9]/g, "");
}
