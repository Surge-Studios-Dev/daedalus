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
