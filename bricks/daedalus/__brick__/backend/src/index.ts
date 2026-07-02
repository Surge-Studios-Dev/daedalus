/**
 * {{name}} Cloud Functions.
 *
 * Two starters that every Surge app keeps:
 *  - onAccountDeleted: when an auth user is deleted (the in-app "Delete
 *    account" flow), recursively purge their Firestore data. Required for the
 *    account-deletion story the privacy policy promises - client-side auth
 *    deletion alone would strand the data.
 *  - ping: the callable pattern (v2 onCall). Copy it for real endpoints; the
 *    client calls it via FirebaseFunctions.instance.httpsCallable('ping').
 *
 * Auth triggers only exist in the v1 API, so this file mixes v1 (trigger) and
 * v2 (callable) imports on purpose.
 */
import * as functionsV1 from "firebase-functions/v1";
import { onNewFatalIssuePublished } from "firebase-functions/v2/alerts/crashlytics";
import { onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onAccountDeleted = functionsV1.auth.user().onDelete(
  async (user) => {
    const db = admin.firestore();
    await db.recursiveDelete(db.doc(`users/${user.uid}`));
  },
);

export const ping = onCall(async (request) => {
  return { pong: true, uid: request.auth?.uid ?? null };
});

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
