// Referral reward math. Pure functions so the economy is unit-testable;
// the live numbers come from Firestore `config/referrals` (loadRewardConfig
// in referrals.ts) so they can be tuned without a deploy. The defaults
// mirror the manifest's `sharing.reward` studio defaults - keep them in
// step (SHARING.md).

export interface RewardConfig {
  /** Entitlement-credit days the invitee receives on redemption. */
  inviteeDays: number;
  /** Entitlement-credit days the sharer earns per successful referral. */
  perReferralDays: number;
  /** Lifetime cap on days a sharer can earn through referrals. */
  capDays: number;
}

export const DEFAULT_REWARD_CONFIG: RewardConfig = {
  inviteeDays: 7,
  perReferralDays: 7,
  capDays: 90,
};

/**
 * Days the sharer earns for one more successful referral, given how many
 * days they have already earned lifetime. The cap clamps, never splits: a
 * sharer at 87/90 with a 7-day reward earns the remaining 3.
 */
export function rewardForReferral(
  grantedLifetimeDays: number,
  cfg: RewardConfig = DEFAULT_REWARD_CONFIG,
): number {
  const earned =
    Number.isFinite(grantedLifetimeDays) && grantedLifetimeDays > 0
      ? grantedLifetimeDays
      : 0;
  const headroom = cfg.capDays - earned;
  if (headroom <= 0) return 0;
  return Math.min(cfg.perReferralDays, headroom);
}

/** Merge a partial config doc over the defaults, ignoring junk values. */
export function mergeRewardConfig(raw: unknown): RewardConfig {
  const cfg = { ...DEFAULT_REWARD_CONFIG };
  if (!raw || typeof raw !== "object") return cfg;
  const src = raw as Record<string, unknown>;
  for (const key of Object.keys(cfg) as (keyof RewardConfig)[]) {
    const v = src[key];
    if (typeof v === "number" && Number.isFinite(v) && v >= 0) {
      cfg[key] = Math.floor(v);
    }
  }
  return cfg;
}
