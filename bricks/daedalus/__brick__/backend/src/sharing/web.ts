import { setTimeout as sleep } from "node:timers/promises";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import type { Request, Response } from "express";

// The web face of a share link (SHARING.md): the branded card image, the
// title, the invite code, and a route into the app or the store; nothing
// else. Bots fetch these pages for unfurls, so the OG tags are the
// product's face in every chat; humans only land here when the app ISN'T
// installed (installed devices open the app directly via Universal Links /
// App Links before any HTTP request).

// LAUNCH-TODO(store-urls): replace with the real App Store URL once the
// listing exists (the numeric id comes from App Store Connect). The Play
// URL is real - it 404s politely until the listing is live.
const APP_STORE_URL = "https://apps.apple.com/app/id000000000";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id={{package_android}}";

const APP_NAME = "{{name}}";
const TAGLINE = `{{tagline}}`;
const DEEP_LINK_SCHEME = "{{slug}}";

function db() {
  if (!getApps().some((a) => a.name === "[DEFAULT]")) {
    initializeApp();
  }
  return getFirestore();
}

/** Escape user content (titles, names) before it touches HTML. */
export function esc(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

interface PageData {
  title: string;
  description: string;
  /** og:image; empty renders the brand header only. */
  imageUrl: string;
  /** Invite code to surface with a copy button. Empty hides the block. */
  code: string;
  /** Deep link for the "Open in the app" button. */
  appUrl: string;
}

function page(d: PageData, canonicalUrl: string): string {
  // Inline everything: this page must render from a single response with
  // no asset pipeline. Neutral light palette; retheme per app if the page
  // ever becomes a real surface (it is a store hand-off, not a product).
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(d.title)} · ${esc(APP_NAME)}</title>
<meta property="og:site_name" content="${esc(APP_NAME)}">
<meta property="og:type" content="website">
<meta property="og:title" content="${esc(d.title)}">
<meta property="og:description" content="${esc(d.description)}">
${
  d.imageUrl
    ? `<meta property="og:image" content="${esc(d.imageUrl)}">
<meta property="og:image:type" content="image/png">
<meta property="og:image:width" content="1080">
<meta property="og:image:height" content="1080">`
    : ""
}
<meta property="og:url" content="${esc(canonicalUrl)}">
<meta name="twitter:card" content="${d.imageUrl ? "summary_large_image" : "summary"}">
<style>
  :root { color-scheme: light; }
  /* Block flow, not flex centering: a card taller than the viewport must
     scroll, never clip (SHARING.md web-card rules). */
  body { margin: 0; background: #F5F5F4; color: #1C1B1A;
    font: 16px/1.5 -apple-system, "Segoe UI", Roboto, sans-serif;
    padding: 24px 16px; }
  .card { max-width: 420px; margin: 0 auto; background: #FFFFFF;
    border-radius: 20px; overflow: hidden; box-shadow: 0 8px 32px rgba(28,27,26,.10); }
  /* The card PNG is square with the brand row at its BOTTOM: scale it
     down (never crop it) so the whole card - buttons included - fits a
     phone screen. */
  .card img.hero { display: block; width: min(100%, 42vh); max-height: 42vh;
    object-fit: cover; margin: 14px auto 0; border-radius: 12px; }
  .body { padding: 20px 24px 24px; }
  h1 { font-size: 22px; line-height: 1.25; margin: 0 0 4px; overflow-wrap: break-word; }
  .sub { color: #6B6862; font-size: 14px; margin: 0 0 16px; }
  .btn { display: block; text-align: center; text-decoration: none;
    border-radius: 12px; padding: 14px 16px; font-weight: 600; margin-bottom: 8px; }
  .primary { background: #1C1B1A; color: #fff; }
  .ghost { color: #1C1B1A; }
  .code-box { background: #F5F5F4; border-radius: 12px; padding: 12px 16px;
    margin: 0 0 16px; display: flex; align-items: center; justify-content: space-between; }
  .code { font-size: 18px; font-weight: 700; letter-spacing: 2px; }
  .code-hint { color: #6B6862; font-size: 12px; }
  .copy { border: 0; background: none; color: #1C1B1A; font-weight: 600;
    font-size: 14px; cursor: pointer; padding: 4px 0 4px 12px; }
  .brand { display: flex; align-items: center; gap: 8px; padding: 16px 24px 0;
    font-weight: 700; font-size: 17px; }
  /* Served as a static file by the same Hosting site as this page;
     forge.sh copies the launcher icon there (brand-mark step). */
  .brand img { width: 28px; height: 28px; }
</style>
</head>
<body>
<main class="card">
  ${
    d.imageUrl
      ? // The card PNG carries its own brand row; adding one above would
        // double it.
        `<img class="hero" src="${esc(d.imageUrl)}" alt="">`
      : `<div class="brand"><img src="/brand-mark.png" alt="" onerror="this.style.display='none'"> ${esc(APP_NAME)}</div>`
  }
  <div class="body">
    <h1>${esc(d.title)}</h1>
    <p class="sub">${esc(d.description)}</p>
    ${
      d.code
        ? `<div class="code-box">
      <div><div class="code">${esc(d.code)}</div>
      <div class="code-hint">Enter this invite code in ${esc(APP_NAME)} for a reward</div></div>
      <button class="copy" onclick="navigator.clipboard&&navigator.clipboard.writeText('${esc(d.code)}');this.textContent='Copied'">Copy</button>
    </div>`
        : ""
    }
    <a class="btn primary" href="${esc(PLAY_STORE_URL)}" id="store">Get ${esc(APP_NAME)}</a>
    ${d.appUrl ? `<a class="btn ghost" href="${esc(d.appUrl)}">Open in the app</a>` : ""}
  </div>
</main>
<script>
  // Send iOS visitors to the App Store instead of Play. Installed devices
  // never reach this page (Universal Links intercept), so no auto-launch
  // trickery is needed.
  if (/iPhone|iPad|iPod/.test(navigator.userAgent)) {
    document.getElementById('store').href = ${JSON.stringify(APP_STORE_URL)};
  }
</script>
</body>
</html>`;
}

function send(
  res: Response,
  status: number,
  html: string,
  { cacheable = false } = {},
): void {
  res
    .status(status)
    .set("content-type", "text/html; charset=utf-8")
    // Only COMPLETE share pages may be cached (unfurl bots hammer links
    // when a chat lights up). Failures and not-ready pages must be
    // no-store: shares upload in the background right after the link is
    // sent, and a CDN-cached 404 from that race window poisons the link's
    // preview for every fetcher that follows.
    .set("cache-control", cacheable ? "public, max-age=300" : "no-store")
    .send(html);
}

const GONE: PageData = {
  title: "This shared link is no longer available",
  description: "The person who shared it may have removed it.",
  imageUrl: "",
  code: "",
  appUrl: "",
};

/**
 * Serve the share's card PNG from a STABLE URL: /c/{shareId}.png. This is
 * what og:image points at, and it's the fix for the unfurl race - the
 * card uploads in the background AFTER the link is sendable, and
 * messengers fetch previews at send time and never refetch. Instead of
 * racing them, this endpoint WAITS (short poll, well within a preview
 * fetcher's patience) for the card to land, so the preview image is the
 * branded card by construction. Falls back to the share's hero image,
 * then 404.
 */
async function serveCardImage(
  req: Request,
  res: Response,
  shareId: string,
): Promise<void> {
  db(); // ensures the admin app exists before getStorage()
  const bucket = getStorage().bucket(
    process.env.STORAGE_BUCKET || "{{firebase_project}}.firebasestorage.app",
  );
  const file = bucket.file(`shares/${shareId}/card.png`);
  for (let attempt = 0; attempt < 16; attempt++) {
    try {
      const [exists] = await file.exists();
      if (exists) {
        res
          .status(200)
          .set("content-type", "image/png")
          // The card never changes once written; cache hard.
          .set("cache-control", "public, max-age=31536000, immutable");
        file.createReadStream().pipe(res);
        return;
      }
    } catch (err) {
      console.warn(`card exists check failed: ${(err as Error).message}`);
      break;
    }
    await sleep(500);
  }
  // No card (upload failed or share is card-less): hand the fetcher the
  // hero image instead - uncached, so a later fetch can still upgrade.
  try {
    const snap = await db().collection("shares").doc(shareId).get();
    const hero = snap.data()?.heroImage;
    if (typeof hero === "string" && hero.startsWith("http")) {
      res.status(302).set("cache-control", "no-store").redirect(hero);
      return;
    }
  } catch {
    /* fall through to 404 */
  }
  res.status(404).set("cache-control", "no-store").send("");
}

/**
 * Router for the Hosting rewrites: /s/{shareId}, /i/{code}, and the
 * card-image endpoint /c/{shareId}.png.
 */
export async function handleShareLinkRequest(
  req: Request,
  res: Response,
): Promise<void> {
  const cardMatch = /^\/c\/([a-z0-9]{6,20})\.png$/.exec(req.path);
  if (cardMatch) {
    await serveCardImage(req, res, cardMatch[1]);
    return;
  }
  const match = /^\/(s|i)\/([A-Za-z0-9-]{2,24})\/?$/.exec(req.path);
  if (!match) {
    send(res, 404, page(GONE, linkOrigin(req)));
    return;
  }
  const [, kind, id] = match;
  if (kind === "i") {
    send(
      res,
      200,
      page(
        {
          title: `You're invited to ${APP_NAME}`,
          description: TAGLINE || `Join me on ${APP_NAME}.`,
          imageUrl: "",
          code: id.toUpperCase(),
          appUrl: "",
        },
        `${linkOrigin(req)}${req.path}`,
      ),
      { cacheable: true },
    );
    return;
  }
  try {
    const ref = db().collection("shares").doc(id.toLowerCase());
    let snap = await ref.get();
    // The doc write races the first unfurl fetch: the link is sendable
    // the instant Share is tapped, while createShare lands in the
    // background. Messengers fetch a preview ONCE per message, so a
    // premature GONE here breaks that message's preview forever - wait
    // briefly for the doc instead. Genuinely dead links pay a few seconds
    // before the dead-end page; live ones skip the loop.
    for (let attempt = 0; !snap.exists && attempt < 12; attempt++) {
      await sleep(500);
      snap = await ref.get();
    }
    const data = snap.data();
    if (!snap.exists || !data || data.revoked) {
      send(res, 404, page(GONE, linkOrigin(req)));
      return;
    }
    const count = (data.itemCount as number) ?? 0;
    const countText = count > 1 ? `${count} items · ` : "";
    send(
      res,
      200,
      page(
        {
          title: data.title ?? `Shared from ${APP_NAME}`,
          description: `${countText}shared by ${data.ownerName || "a friend"}`,
          // Stable card endpoint: waits for the background card upload,
          // so the unfurl image is the branded card no matter how fast
          // the message was sent (with its own hero fallback inside).
          imageUrl: `${linkOrigin(req)}/c/${id.toLowerCase()}.png`,
          code: data.ref ?? "",
          appUrl: `${DEEP_LINK_SCHEME}://shared/${id.toLowerCase()}`,
        },
        `${linkOrigin(req)}${req.path}`,
      ),
      // The og:image URL is constant, so the page itself is safely
      // cacheable from the moment the doc exists.
      { cacheable: true },
    );
  } catch (err) {
    console.error(`shareLink render failed: ${(err as Error).message}`);
    send(res, 500, page(GONE, linkOrigin(req)));
  }
}

function linkOrigin(req: Request): string {
  const host = req.get("x-forwarded-host") ?? req.get("host") ?? "";
  return host ? `https://${host}` : "";
}
