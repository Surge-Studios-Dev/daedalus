/**
 * {{name}} Cloud Functions.
 *
 * Starters that every Surge app keeps:
 *  - onAccountDeleted: when an auth user is deleted (the in-app "Delete
 *    account" flow), recursively purge their Firestore data. Required for the
 *    account-deletion story the privacy policy promises - client-side auth
 *    deletion alone would strand the data.
 *  - ping: the callable pattern (v2 onCall). Copy it for real endpoints; the
 *    client calls it via FirebaseFunctions.instance.httpsCallable('ping').
 *  - notify/: Discord ops notifications (installs, purchases, support) -
 *    dormant until the .env webhook URLs are set.
 *  - ai/: the AI rail (AI-RAIL.md) - the cached-extraction callable pattern
 *    (cache key + TTL + pipeline version) on a working model mock. The app
 *    NEVER calls a model directly; every AI surface is a callable here.
 *  - sharing/: the growth rail (SHARING.md) - share snapshots, referral
 *    codes and rewards, and the shareLink web/unfurl endpoint. The client
 *    side is packages/surge_share; `shares` / `referrals` / `referral_codes`
 *    are server-only per firestore.rules, so every client touch goes
 *    through these callables.
 *
 * Auth triggers only exist in the v1 API, so this file mixes v1 (trigger) and
 * v2 (callable) imports on purpose.
 */
import * as functionsV1 from "firebase-functions/v1";
import { onNewFatalIssuePublished } from "firebase-functions/v2/alerts/crashlytics";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

import { MockModelClient, runExtract } from "./ai/extract";
import { enforceRateLimit } from "./rate_limit";
import {
  claimEntitlementCredit as runClaimEntitlementCredit,
  ensureReferral,
  redeemReferral as runRedeemReferral,
} from "./sharing/referrals";
import {
  attachShareCard as runAttachShareCard,
  attachShareImage as runAttachShareImage,
  createShare as runCreateShare,
  CreateShareRequest,
  getShare as runGetShare,
  recordShareSave as runRecordShareSave,
  revokeShare as runRevokeShare,
} from "./sharing/shares";
import { handleShareLinkRequest } from "./sharing/web";

admin.initializeApp();

// Discord ops notifications (installs, purchases, support). Dormant until
// the webhook env vars are set - see notify/triggers.ts and .env.example.
export {
  onFeedbackCreated,
  onNewInstall,
  revenuecatWebhook,
} from "./notify/triggers";

export const onAccountDeleted = functionsV1.auth.user().onDelete(
  async (user) => {
    const db = admin.firestore();
    await db.recursiveDelete(db.doc(`users/${user.uid}`));
    // The referral record is personal data too. The code->uid lookup doc
    // goes with it (a dead code should stop resolving); shares are
    // deliberately kept - they are public snapshots the user chose to
    // publish, revocable in-app before deletion.
    const referral = await db.doc(`referrals/${user.uid}`).get();
    const code = referral.data()?.code as string | undefined;
    await db.recursiveDelete(db.doc(`referrals/${user.uid}`));
    if (code) {
      const canonical = code.toUpperCase().replace(/[^A-Z0-9]/g, "");
      await db.doc(`referral_codes/${canonical}`).delete().catch(() => undefined);
    }
  },
);

export const ping = onCall(async (request) => {
  return { pong: true, uid: request.auth?.uid ?? null };
});

// ---------------------------------------------------------------------------
// AI rail (AI-RAIL.md; corpus gate: backend/corpus).

/**
 * The cached AI extraction callable. Ships on MockModelClient so a stamped
 * app runs end-to-end; SEAM: swap in a real model client (add
 * `@google/genai`, build the prompt + schema per app) and bump
 * PIPELINE_VERSION in ai/extract.ts on quality-affecting changes. Charge
 * the app-side meter when this SUCCEEDS, not on save.
 */
export const extract = onCall<{ url?: string }>(
  { timeoutSeconds: 120, memory: "512MiB", region: "us-central1", invoker: "public" },
  async (request) => {
    requireAuth(request);
    await enforceRateLimit(request.auth?.uid, "extract");
    const url = request.data?.url?.trim();
    if (!url) throw new HttpsError("invalid-argument", "Share a link to extract.");
    return runExtract(url, new MockModelClient());
  },
);

// ---------------------------------------------------------------------------
// Sharing + referrals (SHARING.md; client: packages/surge_share).

function requireAuth(request: { auth?: unknown }): void {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to continue.");
  }
}

/** Throw invalid-argument when a base64 string exceeds [maxChars]. */
function rejectOversizedBase64(
  value: string | undefined,
  maxChars: number,
  label: string,
): void {
  if (value && value.length > maxChars) {
    throw new HttpsError("invalid-argument", `${label} is too large.`);
  }
}

/** Display name for share attribution: auth token name, else a friendly
 *  fallback (never the email - a share card is public). */
function callerName(request: { auth?: { token?: unknown } | null }): string {
  const token = request.auth?.token as Record<string, unknown> | undefined;
  const name = token?.name;
  return typeof name === "string" && name.trim() ? name.trim() : "a friend";
}

const SHARE_OPTS = {
  timeoutSeconds: 30,
  memory: "256MiB",
  region: "us-central1",
  invoker: "public",
} as const;

export const createShare = onCall<CreateShareRequest>(
  // 60s: a bundle share may rehost dozens of inline images.
  { ...SHARE_OPTS, timeoutSeconds: 60 },
  async (request) => {
    requireAuth(request);
    await enforceRateLimit(request.auth?.uid, "createShare");
    rejectOversizedBase64(request.data?.cardPngBase64, 4_000_000, "Card image");
    return runCreateShare(
      request.auth!.uid,
      callerName(request),
      request.data ?? {},
    );
  },
);

export const getShare = onCall<{ shareId?: string }>(
  SHARE_OPTS,
  async (request) => {
    requireAuth(request);
    await enforceRateLimit(request.auth?.uid, "getShare");
    return runGetShare(request.data?.shareId ?? "");
  },
);

export const attachShareCard = onCall<{
  shareId?: string;
  cardPngBase64?: string;
}>({ ...SHARE_OPTS, timeoutSeconds: 60 }, async (request) => {
  requireAuth(request);
  await enforceRateLimit(request.auth?.uid, "attachCard");
  rejectOversizedBase64(request.data?.cardPngBase64, 4_000_000, "Card image");
  await runAttachShareCard(
    request.auth!.uid,
    request.data?.shareId,
    request.data?.cardPngBase64,
  );
  return { ok: true };
});

export const attachShareImage = onCall<{
  shareId?: string;
  index?: number;
  imageDataUri?: string;
}>(
  // 120s: this callable exists to carry a megabytes-scale inline image
  // over a slow phone uplink WITHOUT gating the share doc on it
  // (createShare arrives image-stripped from surge_share).
  { ...SHARE_OPTS, timeoutSeconds: 120 },
  async (request) => {
    requireAuth(request);
    await enforceRateLimit(request.auth?.uid, "attachImage");
    rejectOversizedBase64(
      request.data?.imageDataUri,
      12_000_000,
      "Share image",
    );
    await runAttachShareImage(
      request.auth!.uid,
      request.data?.shareId,
      request.data?.index,
      request.data?.imageDataUri,
    );
    return { ok: true };
  },
);

export const recordShareSave = onCall<{ shareId?: string }>(
  SHARE_OPTS,
  async (request) => {
    requireAuth(request);
    await enforceRateLimit(request.auth?.uid, "recordSave");
    await runRecordShareSave(request.data?.shareId ?? "");
    return { ok: true };
  },
);

export const revokeShare = onCall<{ shareId?: string }>(
  SHARE_OPTS,
  async (request) => {
    requireAuth(request);
    await enforceRateLimit(request.auth?.uid, "revokeShare");
    await runRevokeShare(request.auth!.uid, request.data?.shareId ?? "");
    return { ok: true };
  },
);

export const getReferralStatus = onCall<Record<string, never>>(
  { ...SHARE_OPTS, timeoutSeconds: 20 },
  async (request) => {
    requireAuth(request);
    await enforceRateLimit(request.auth?.uid, "referralStatus");
    return ensureReferral(request.auth!.uid, callerName(request));
  },
);

export const redeemReferral = onCall<{ code?: string }>(
  SHARE_OPTS,
  async (request) => {
    requireAuth(request);
    // Tight in spirit: a legitimate user redeems once; retries are typos.
    await enforceRateLimit(request.auth?.uid, "redeemReferral");
    return runRedeemReferral(
      request.auth!.uid,
      callerName(request),
      request.data?.code ?? "",
    );
  },
);

export const claimEntitlementCredit = onCall<Record<string, never>>(
  SHARE_OPTS,
  async (request) => {
    requireAuth(request);
    await enforceRateLimit(request.auth?.uid, "claimCredit");
    return runClaimEntitlementCredit(request.auth!.uid);
  },
);

/**
 * The web face of every share link, wired by the firebase.json rewrites:
 * /s/{shareId} (share page), /i/{code} (invite page), /c/{id}.png (stable
 * og:image endpoint). See sharing/web.ts for the unfurl contract.
 */
export const shareLink = onRequest(
  { region: "us-central1", invoker: "public", timeoutSeconds: 30 },
  handleShareLinkRequest,
);

/**
 * Crashlytics -> PostHog bridge: fatal issues appear on the product
 * dashboard as `crash_fatal_issue`, so quality lives next to behavior
 * (see ANALYTICS.md). Set POSTHOG_PROJECT_KEY (and optionally POSTHOG_HOST)
 * in the Functions env; without it this is a no-op.
 */
export const onFatalIssue = onNewFatalIssuePublished(async (event) => {
  const key = process.env.POSTHOG_PROJECT_KEY;
  if (!key) return;
  const host = process.env.POSTHOG_HOST ?? "https://us.i.posthog.com";
  const issue = event.data.payload.issue;
  await fetch(`${host}/i/v0/e/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      api_key: key,
      event: "crash_fatal_issue",
      distinct_id: "crashlytics",
      properties: {
        issue_id: issue.id,
        issue_title: issue.title,
        app_version: issue.appVersion,
      },
    }),
  });
});
