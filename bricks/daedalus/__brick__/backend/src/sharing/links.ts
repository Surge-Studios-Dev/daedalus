// Self-hosted share links (SHARING.md: don't buy link infrastructure).
// Links are deterministic URLs on our own domain, served by the shareLink
// HTTP function via Firebase Hosting rewrites: /s/{shareId} for shares,
// /i/{code} for bare invites. iOS Universal Links / Android App Links open
// the app directly when installed; everyone else gets the branded web card
// with store buttons and the invite code.
//
// The zero-DNS *.web.app default below must keep working FOREVER: links
// minted on it never die. A custom domain is set via SHARE_LINK_BASE in
// backend/.env - both hosts serve the same site and both stay listed in
// the app's intent-filter + entitlements.

const DEFAULT_BASE = "https://{{firebase_project}}.web.app";

export function linkBase(): string {
  return (process.env.SHARE_LINK_BASE || DEFAULT_BASE).replace(/\/+$/, "");
}

/** Share link. [ref] rides along for visibility; attribution actually
 *  reads the share doc, so the link works even with the param stripped. */
export function buildShareLink(shareId: string, ref?: string): string {
  const query = ref ? `?ref=${encodeURIComponent(ref)}` : "";
  return `${linkBase()}/s/${shareId}${query}`;
}

/** Bare invite link (no share attached, just the code). */
export function buildInviteLink(code: string): string {
  return `${linkBase()}/i/${encodeURIComponent(code)}`;
}
