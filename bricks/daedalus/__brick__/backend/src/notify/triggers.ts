/**
 * Discord ops-notification triggers (WEBHOOK-NOTIFICATIONS doctrine). The
 * only notify file that reads process.env; one export per trigger. The
 * three cover the general patterns for any future notification: an auth
 * lifecycle event, an inbound third-party webhook, and a Firestore write.
 *
 * Unset config = skip, not crash: each trigger reads its webhook URL at
 * call time; emulator and CI runs work with an empty .env. Fill
 * DISCORD_WEBHOOK_* / REVENUECAT_WEBHOOK_AUTH (see ../.env.example) to
 * activate - no code changes, no manifest field.
 *
 * Region note: if the Firestore database is a multi-region (nam5/eur3),
 * the FUNCTION region must still be a real region (us-central1) - nam5 is
 * a Firestore location, not a Cloud Run region, and using it fails deploy.
 */
import * as functionsV1 from "firebase-functions/v1";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";

import { postDiscord } from "./discord";
import {
  classifyRevenueCatEvent,
  formatFeedbackEmbed,
  formatInstallEmbed,
  formatPurchaseEmbed,
  isAuthorized,
  RevenueCatEvent,
} from "./format";

/**
 * Install proxy: there is no push event for a store download, so Firebase
 * Auth user creation (first app open) is the standard proxy - it fires
 * exactly once per fresh install when the app signs users in (even
 * anonymously) on first launch. v2 has no non-blocking auth trigger
 * (beforeUserCreated is blocking and adds latency to every sign-in), so
 * this stays on the v1 API; v1 and v2 exports coexist fine.
 */
export const onNewInstall = functionsV1
  .region("us-central1")
  .auth.user()
  .onCreate(async (user) => {
    await postDiscord(
      process.env.DISCORD_WEBHOOK_INSTALLS,
      formatInstallEmbed(user.uid, user.metadata?.creationTime),
    );
  });

/**
 * RevenueCat is the source of truth for purchases (receipts settle
 * server-side; the client deliberately emits no conversion events).
 * Dashboard -> Project -> Integrations -> Webhooks: endpoint URL + an
 * Authorization header value sent verbatim on every delivery.
 *
 * firebase-tools does not reliably apply invoker:"public" to v2 functions;
 * after the first deploy run
 *   gcloud run services add-iam-policy-binding revenuecatwebhook \
 *     --region=us-central1 --member=allUsers --role=roles/run.invoker
 */
export const revenuecatWebhook = onRequest(
  { region: "us-central1", invoker: "public", timeoutSeconds: 30 },
  async (req, res) => {
    if (
      !isAuthorized(
        req.get("authorization"),
        process.env.REVENUECAT_WEBHOOK_AUTH,
      )
    ) {
      res.status(401).send("unauthorized");
      return;
    }
    const event = (req.body?.event ?? {}) as RevenueCatEvent;
    const kind = classifyRevenueCatEvent(event);
    if (kind) {
      await postDiscord(
        process.env.DISCORD_WEBHOOK_PURCHASES,
        formatPurchaseEmbed(kind, event),
      );
    }
    // ALWAYS 200 when authorized - RevenueCat retries non-2xx deliveries.
    res.status(200).send("ok");
  },
);

/**
 * Firestore-write pattern: anything the app records as a document (support
 * requests, feedback, waitlist signups). The path matches the rules-isolated
 * per-user tree; point new triggers at their own collections. The doc is
 * client-written - the formatter type-checks every field and truncates free
 * text.
 *
 * App-side: don't await the Firestore server ack before showing success;
 * with offline persistence the local write is durable immediately. The
 * trigger fires when the write syncs.
 */
export const onFeedbackCreated = onDocumentCreated(
  { document: "users/{uid}/feedback/{feedbackId}", region: "us-central1" },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    await postDiscord(
      process.env.DISCORD_WEBHOOK_SUPPORT,
      formatFeedbackEmbed(data, event.params.uid),
    );
  },
);
