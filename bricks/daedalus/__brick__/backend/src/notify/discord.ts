/**
 * Discord transport: a dumb POST. Takes the webhook URL as an argument (no
 * env reads - that's triggers.ts's job), 10s timeout, warns on non-2xx.
 *
 * Notifications are best-effort and never throw: a Discord outage must never
 * fail the event that triggered it (a sign-in, a Firestore write, a
 * RevenueCat delivery that would otherwise retry).
 *
 * Rate limit is ~30 posts/min per webhook - fine for ops volumes; do not use
 * this for per-user fan-out.
 */

export interface DiscordEmbedField {
  name: string;
  value: string;
  inline?: boolean;
}

export interface DiscordEmbed {
  title: string;
  description?: string;
  color?: number;
  fields?: DiscordEmbedField[];
  timestamp?: string;
}

export async function postDiscord(
  webhookUrl: string | undefined,
  embed: DiscordEmbed,
): Promise<boolean> {
  if (!webhookUrl) return false;
  try {
    const res = await fetch(webhookUrl, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ embeds: [embed] }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) {
      console.warn(`[notify] Discord webhook responded ${res.status}`);
      return false;
    }
    return true;
  } catch (err) {
    console.warn("[notify] Discord webhook post failed:", err);
    return false;
  }
}
