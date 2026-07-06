// RevenueCat promotional-entitlement grants for referral rewards.
//
// LAUNCH-TODO(revenuecat-secret): set REVENUECAT_SECRET in backend/.env
// (RevenueCat dashboard -> API keys -> secret key). Until it is set,
// reward days accrue as `creditDays` on referrals/{uid} and are granted
// when the key lands (the client retries claimEntitlementCredit on boot).
//
// RevenueCat app_user_id == Firebase uid: the app binds them on sign-in
// (Purchases.logIn(uid), the analytics identity law), so grants land on
// the right customer.

const RC_API = "https://api.revenuecat.com/v1";
const ENTITLEMENT = "{{entitlement}}";

// RevenueCat promotional durations are a fixed enum. Grants are made one
// best-fit chunk per claim (a fresh grant REPLACES the promotional expiry
// rather than stacking, so sequential same-call grants would clobber each
// other); leftover days stay banked and drain on later claims.
const CHUNKS: Array<{ days: number; duration: string }> = [
  { days: 365, duration: "yearly" },
  { days: 180, duration: "six_month" },
  { days: 90, duration: "three_month" },
  { days: 60, duration: "two_month" },
  { days: 30, duration: "monthly" },
  { days: 7, duration: "weekly" },
  { days: 3, duration: "three_day" },
  { days: 1, duration: "daily" },
];

export function rcConfigured(): boolean {
  return Boolean(process.env.REVENUECAT_SECRET);
}

function headers(): Record<string, string> {
  return {
    authorization: `Bearer ${process.env.REVENUECAT_SECRET}`,
    "content-type": "application/json",
  };
}

/** Largest grantable chunk that fits within [days]. Null when days < 1. */
export function bestChunk(
  days: number,
): { days: number; duration: string } | null {
  for (const chunk of CHUNKS) {
    if (days >= chunk.days) return chunk;
  }
  return null;
}

/**
 * True when the customer already has an active entitlement. Granting on
 * top of an active promotional grant would REPLACE its expiry (losing
 * time), and granting to a store subscriber is wasted - either way the
 * caller should keep the days banked (lapse credit doubles as win-back).
 * Fails closed (true) on API errors so credit is never burned during an
 * outage.
 */
export async function hasActiveEntitlement(uid: string): Promise<boolean> {
  try {
    const res = await fetch(
      `${RC_API}/subscribers/${encodeURIComponent(uid)}`,
      {
        headers: headers(),
        signal: AbortSignal.timeout(10_000),
      },
    );
    if (!res.ok) throw new Error(`rc subscriber ${res.status}`);
    const body = (await res.json()) as {
      subscriber?: {
        entitlements?: Record<string, { expires_date?: string | null }>;
      };
    };
    const ent = body.subscriber?.entitlements?.[ENTITLEMENT];
    if (!ent) return false;
    // expires_date null means lifetime.
    if (ent.expires_date == null) return true;
    return new Date(ent.expires_date).getTime() > Date.now();
  } catch (err) {
    console.warn(
      `hasActiveEntitlement failed (assuming active): ${(err as Error).message}`,
    );
    return true;
  }
}

/**
 * Grant a promotional entitlement. Returns true on success. Never throws -
 * a failed grant leaves the days banked.
 */
export async function grantPromotionalEntitlement(
  uid: string,
  duration: string,
): Promise<boolean> {
  try {
    const res = await fetch(
      `${RC_API}/subscribers/${encodeURIComponent(uid)}` +
        `/entitlements/${ENTITLEMENT}/promotional`,
      {
        method: "POST",
        headers: headers(),
        body: JSON.stringify({ duration }),
        signal: AbortSignal.timeout(10_000),
      },
    );
    if (!res.ok) throw new Error(`rc grant ${res.status}`);
    return true;
  } catch (err) {
    console.warn(
      `grantPromotionalEntitlement failed: ${(err as Error).message}`,
    );
    return false;
  }
}
