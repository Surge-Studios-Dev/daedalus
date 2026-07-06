/**
 * Pure formatters + filters for the Discord ops notifications. No I/O and
 * no env reads - everything here is unit-testable without mocks (see
 * test/unit/notify.test.mjs). Anonymize in the channel: short uids, capped
 * free text.
 */

import { DiscordEmbed, DiscordEmbedField } from "./discord";

// Internal-ops embeds; the colors just make the channels scannable.
const COLOR_INSTALL = 0x5865f2;
const COLOR_SUPPORT = 0xed4245;
const COLOR_RATING = 0xfee75c;
const COLOR_PURCHASE = 0x57f287;

/** First 8 chars of a uid - enough to correlate with the Firebase console
 *  without pasting whole uids into a chat channel. */
export function shortUid(uid: string | undefined): string {
  return (uid ?? "").slice(0, 8) || "unknown";
}

/** Cap [text] at [max] chars, ellipsis included in the cap. */
export function truncate(text: string, max = 500): string {
  if (text.length <= max) return text;
  return `${text.slice(0, max - 1)}…`;
}

/** There is no real-time store-download event; Firebase Auth user creation
 *  (first app open) is the standard proxy. The auth event carries no
 *  platform or device info, so this stays sparse. */
export function formatInstallEmbed(
  uid: string,
  creationTime?: string,
): DiscordEmbed {
  const created = creationTime ? new Date(creationTime) : null;
  return {
    title: "New install",
    color: COLOR_INSTALL,
    fields: [{ name: "User", value: shortUid(uid), inline: true }],
    ...(created && !isNaN(created.getTime())
      ? { timestamp: created.toISOString() }
      : {}),
  };
}

/** Shape of a users/{uid}/feedback doc. Client-written, so treat it as
 *  hostile: every field is unknown until proven a string. */
export interface FeedbackDoc {
  text?: unknown;
  source?: unknown;
  appVersion?: unknown;
  platform?: unknown;
}

export function formatFeedbackEmbed(
  data: FeedbackDoc,
  uid: string,
): DiscordEmbed {
  const source = typeof data.source === "string" ? data.source : "";
  const text = typeof data.text === "string" ? data.text : "";
  const fields: DiscordEmbedField[] = [
    { name: "User", value: shortUid(uid), inline: true },
  ];
  if (typeof data.platform === "string" && data.platform) {
    fields.push({ name: "Platform", value: data.platform, inline: true });
  }
  if (typeof data.appVersion === "string" && data.appVersion) {
    fields.push({ name: "App version", value: data.appVersion, inline: true });
  }
  return {
    title: source === "rating" ? "Feedback" : "Support request",
    description: truncate(text) || "(no text)",
    color: source === "rating" ? COLOR_RATING : COLOR_SUPPORT,
    fields,
  };
}

export type PurchaseKind =
  | "trial_started"
  | "trial_converted"
  | "purchase"
  | "test";

/** The subset of a RevenueCat webhook `event` object we read. */
export interface RevenueCatEvent {
  type?: string;
  period_type?: string;
  is_trial_conversion?: boolean;
  app_user_id?: string;
  product_id?: string;
  price?: number;
  price_in_purchased_currency?: number;
  currency?: string;
  store?: string;
  environment?: string;
}

/** Which RevenueCat events post to Discord. Deliberately narrow: the
 *  channel is for "someone paid us" moments, so plain renewals,
 *  cancellations, expirations, and billing noise all return null. TEST
 *  passes through so the dashboard's "Send test event" button verifies the
 *  pipe end to end. Leave RevenueCat's own event filter at "all" - filter
 *  here in tested code, keep the dashboard dumb. */
export function classifyRevenueCatEvent(
  e: RevenueCatEvent,
): PurchaseKind | null {
  switch (e.type) {
    case "INITIAL_PURCHASE":
      return e.period_type === "TRIAL" ? "trial_started" : "purchase";
    case "RENEWAL":
      return e.is_trial_conversion === true ? "trial_converted" : null;
    case "NON_RENEWING_PURCHASE":
      return "purchase";
    case "TEST":
      return "test";
    default:
      return null;
  }
}

const PURCHASE_TITLES: Record<PurchaseKind, string> = {
  trial_started: "Trial started",
  trial_converted: "Trial converted",
  purchase: "New purchase",
  test: "RevenueCat test event",
};

export function formatPurchaseEmbed(
  kind: PurchaseKind,
  e: RevenueCatEvent,
): DiscordEmbed {
  const fields: DiscordEmbedField[] = [];
  if (e.product_id) {
    fields.push({ name: "Product", value: e.product_id, inline: true });
  }
  if (e.store) {
    fields.push({ name: "Store", value: e.store, inline: true });
  }
  // Prefer the purchased-currency price; `price` is normalized USD.
  const price = e.price_in_purchased_currency ?? e.price;
  if (typeof price === "number") {
    fields.push({
      name: "Price",
      value: e.currency
        ? `${price.toFixed(2)} ${e.currency}`
        : price.toFixed(2),
      inline: true,
    });
  }
  // RevenueCat App User ID equals the Firebase uid (the app calls
  // Purchases.logIn(uid) - the analytics identity law).
  fields.push({ name: "User", value: shortUid(e.app_user_id), inline: true });
  return {
    // Pre-launch, sandbox is all the traffic there is; tag it, don't drop it.
    title:
      PURCHASE_TITLES[kind] +
      (e.environment === "SANDBOX" ? " [sandbox]" : ""),
    color: COLOR_PURCHASE,
    fields,
  };
}

/** Exact match on the raw Authorization header value the RevenueCat
 *  dashboard is configured to send. Fails closed: an unset secret rejects
 *  everything rather than letting an unconfigured endpoint accept all. */
export function isAuthorized(
  header: string | undefined,
  secret: string | undefined,
): boolean {
  if (!secret) return false;
  return header === secret;
}
