import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { HttpsError } from "firebase-functions/v2/https";
import { canonicalCode, newReferralCode } from "./codes";
import { buildInviteLink } from "./links";
import { mergeRewardConfig, rewardForReferral, RewardConfig } from "./rewards";
import {
  bestChunk,
  grantPromotionalEntitlement,
  hasActiveEntitlement,
  rcConfigured,
} from "./revenuecat";

// Referral credit state lives in top-level `referrals/{uid}` - NOT inside
// the user's own tree - because user docs are owner-writable under the
// Firestore rules and credit days must not be client-forgeable. Rules give
// the owner read-only access (live badge updates); every write goes
// through these admin-SDK paths (money-shaped state, SHARING.md).

const REFERRALS = "referrals";
const CODES = "referral_codes";
const CONFIG_DOC = "config/referrals";

// A referral counts "at account creation". The code entry point stays
// visible a while after install, so accept codes from accounts up to this
// old before calling it farming.
const MAX_ACCOUNT_AGE_MS = 30 * 24 * 60 * 60 * 1000;

function db() {
  if (!getApps().some((a) => a.name === "[DEFAULT]")) {
    initializeApp();
  }
  return getFirestore();
}

export interface ReferralStatus {
  code: string;
  /** Self-hosted invite link for the invite card's share text. */
  inviteLink: string;
  lifetimeReferrals: number;
  creditDays: number;
  redeemedCode: boolean;
}

async function loadRewardConfig(): Promise<RewardConfig> {
  try {
    const snap = await db().doc(CONFIG_DOC).get();
    return mergeRewardConfig(snap.exists ? snap.data() : undefined);
  } catch {
    return mergeRewardConfig(undefined);
  }
}

function toStatus(data: FirebaseFirestore.DocumentData): ReferralStatus {
  const code = (data.code as string) ?? "";
  return {
    code,
    inviteLink: code ? buildInviteLink(canonicalCode(code)) : "",
    lifetimeReferrals: (data.lifetimeReferrals as number) ?? 0,
    creditDays: (data.creditDays as number) ?? 0,
    redeemedCode: Boolean(data.referredBy),
  };
}

/**
 * Get-or-create the caller's referral record. Code generation retries on
 * the (astronomically unlikely) canonical-code collision.
 */
export async function ensureReferral(
  uid: string,
  displayName: string | undefined,
): Promise<ReferralStatus> {
  const firestore = db();
  const ref = firestore.collection(REFERRALS).doc(uid);
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = newReferralCode(displayName);
    const codeRef = firestore.collection(CODES).doc(canonicalCode(code));
    try {
      const status = await firestore.runTransaction(async (tx) => {
        const existing = await tx.get(ref);
        if (existing.exists) return toStatus(existing.data()!);
        const taken = await tx.get(codeRef);
        if (taken.exists) return null; // collision - retry with a new code
        const data = {
          code,
          lifetimeReferrals: 0,
          creditDays: 0,
          grantedLifetimeDays: 0,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        };
        tx.set(ref, data);
        tx.set(codeRef, { uid, createdAt: FieldValue.serverTimestamp() });
        return toStatus(data);
      });
      if (status) return status;
    } catch (err) {
      if (attempt === 4) throw err;
    }
  }
  throw new HttpsError("internal", "Could not create a referral code.");
}

export interface RedeemResult {
  ok: true;
  /** Credit days the invitee just banked (surge_share reads this key). */
  creditDays: number;
}

/**
 * Redeem [rawCode] for the calling (invitee) account: credits the invitee
 * their welcome days and the sharer their per-referral reward (lifetime-
 * capped). One redemption per account, ever; self-redemption rejected;
 * accounts older than 30 days rejected.
 */
export async function redeemReferral(
  inviteeUid: string,
  inviteeName: string | undefined,
  rawCode: string,
): Promise<RedeemResult> {
  const canonical = canonicalCode(rawCode ?? "");
  if (canonical.length < 6 || canonical.length > 12) {
    throw new HttpsError("invalid-argument", "That doesn't look like a code.");
  }
  const firestore = db();
  const codeSnap = await firestore.collection(CODES).doc(canonical).get();
  const sharerUid = codeSnap.exists ? (codeSnap.data()?.uid as string) : "";
  if (!sharerUid) {
    throw new HttpsError("not-found", "We couldn't find that code.");
  }
  if (sharerUid === inviteeUid) {
    throw new HttpsError(
      "failed-precondition",
      "That's your own code. Share it with a friend instead.",
    );
  }
  // Soft freshness gate; fail open if the Auth lookup hiccups - the
  // once-per-account rule below is the hard guard.
  try {
    const user = await getAuth().getUser(inviteeUid);
    const created = Date.parse(user.metadata.creationTime);
    if (
      Number.isFinite(created) &&
      Date.now() - created > MAX_ACCOUNT_AGE_MS
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Invite codes are for new accounts.",
      );
    }
  } catch (err) {
    if (err instanceof HttpsError) throw err;
  }
  // Both records must exist before the credit transaction (creation does
  // its own uniqueness dance that can't nest inside this transaction).
  await ensureReferral(inviteeUid, inviteeName);
  const cfg = await loadRewardConfig();
  const inviteeRef = firestore.collection(REFERRALS).doc(inviteeUid);
  const sharerRef = firestore.collection(REFERRALS).doc(sharerUid);
  const sharerDays = await firestore.runTransaction(async (tx) => {
    const [invitee, sharer] = await Promise.all([
      tx.get(inviteeRef),
      tx.get(sharerRef),
    ]);
    if (invitee.data()?.referredBy) {
      throw new HttpsError(
        "failed-precondition",
        "This account has already used an invite code.",
      );
    }
    const earned = (sharer.data()?.grantedLifetimeDays as number) ?? 0;
    const reward = rewardForReferral(earned, cfg);
    tx.set(
      inviteeRef,
      {
        referredBy: canonical,
        referredByUid: sharerUid,
        creditDays: FieldValue.increment(cfg.inviteeDays),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    tx.set(
      sharerRef,
      {
        lifetimeReferrals: FieldValue.increment(1),
        creditDays: FieldValue.increment(reward),
        grantedLifetimeDays: FieldValue.increment(reward),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return reward;
  });
  if (sharerDays > 0) {
    // Best-effort instant grant for the sharer; on any failure the days
    // stay banked and drain on their next claim (app boot).
    try {
      await claimEntitlementCredit(sharerUid);
    } catch (err) {
      console.warn(`post-redeem claim failed: ${(err as Error).message}`);
    }
  }
  return { ok: true, creditDays: cfg.inviteeDays };
}

export interface ClaimResult {
  grantedDays: number;
  remainingDays: number;
  /** True when the claim was skipped because the entitlement is active. */
  entitlementActive: boolean;
}

/**
 * Convert banked creditDays into a RevenueCat promotional grant. One
 * best-fit chunk per call (grants replace promotional expiry rather than
 * stack); the client re-calls on boot until the bank drains. No-ops when
 * RevenueCat is unconfigured or the entitlement is already active.
 */
export async function claimEntitlementCredit(uid: string): Promise<ClaimResult> {
  const firestore = db();
  const ref = firestore.collection(REFERRALS).doc(uid);
  const snap = await ref.get();
  const days = (snap.data()?.creditDays as number) ?? 0;
  if (days < 1) {
    return { grantedDays: 0, remainingDays: 0, entitlementActive: false };
  }
  if (!rcConfigured()) {
    return { grantedDays: 0, remainingDays: days, entitlementActive: false };
  }
  if (await hasActiveEntitlement(uid)) {
    return { grantedDays: 0, remainingDays: days, entitlementActive: true };
  }
  const chunk = bestChunk(days);
  if (!chunk) {
    return { grantedDays: 0, remainingDays: days, entitlementActive: false };
  }
  const granted = await grantPromotionalEntitlement(uid, chunk.duration);
  if (!granted) {
    return { grantedDays: 0, remainingDays: days, entitlementActive: false };
  }
  await firestore.runTransaction(async (tx) => {
    const cur = await tx.get(ref);
    const remaining = Math.max(
      0,
      ((cur.data()?.creditDays as number) ?? 0) - chunk.days,
    );
    tx.set(
      ref,
      { creditDays: remaining, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  });
  return {
    grantedDays: chunk.days,
    remainingDays: Math.max(0, days - chunk.days),
    entitlementActive: false,
  };
}
