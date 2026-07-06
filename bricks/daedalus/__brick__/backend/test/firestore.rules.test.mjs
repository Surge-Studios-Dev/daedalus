// Firestore rules unit tests. Run via `npm test` (wraps
// `firebase emulators:exec` so the Firestore emulator is up; needs Java).
// These four cases pin the security contract; add one test per new rule.
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { readFileSync } from "node:fs";
import { doc, getDoc, setDoc } from "firebase/firestore";

// Resolve firestore.rules from the app root regardless of mocha's cwd.
const rules = readFileSync(
  new URL("../../firestore.rules", import.meta.url),
  "utf8",
);

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-rules",
    firestore: { rules },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

describe("users/{uid} isolation", () => {
  it("denies unauthenticated access", async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, "users/alice")));
    await assertFails(setDoc(doc(db, "users/alice"), { name: "x" }));
  });

  it("lets the owner read and write their doc and subcollections", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertSucceeds(setDoc(doc(db, "users/alice"), { seeded: true }));
    await assertSucceeds(
      setDoc(doc(db, "users/alice/notes/n1"), { text: "hi" }),
    );
    await assertSucceeds(getDoc(doc(db, "users/alice/notes/n1")));
  });

  it("denies other users, even authenticated ones", async () => {
    const db = env.authenticatedContext("bob").firestore();
    await assertFails(getDoc(doc(db, "users/alice")));
    await assertFails(setDoc(doc(db, "users/alice/notes/n1"), { text: "x" }));
  });
});

describe("sharing collections (money-shaped state, SHARING.md)", () => {
  it("shares are server-only, parent doc and items alike", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(getDoc(doc(db, "shares/abc123defg45")));
    await assertFails(setDoc(doc(db, "shares/abc123defg45"), { title: "x" }));
    await assertFails(
      setDoc(doc(db, "shares/abc123defg45/items/000"), { idx: 0 }),
    );
  });

  it("referrals/{uid}: owner reads, nobody writes", async () => {
    // Seed as admin (rules-bypassing), like the server would.
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "referrals/alice"), {
        code: "ALI-2345",
        creditDays: 7,
      });
    });
    const alice = env.authenticatedContext("alice").firestore();
    await assertSucceeds(getDoc(doc(alice, "referrals/alice")));
    // Money-shaped: even the owner cannot write their own credit.
    await assertFails(
      setDoc(doc(alice, "referrals/alice"), { creditDays: 9999 }),
    );
    const bob = env.authenticatedContext("bob").firestore();
    await assertFails(getDoc(doc(bob, "referrals/alice")));
  });

  it("referral_codes and rate_limits are locked to everyone", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(getDoc(doc(db, "referral_codes/ALI2345")));
    await assertFails(setDoc(doc(db, "referral_codes/MINE"), { uid: "alice" }));
    await assertFails(setDoc(doc(db, "rate_limits/alice_x_2026-01-01"), { count: 0 }));
  });
});

describe("deny by default", () => {
  it("denies unmatched root collections even when authenticated", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(setDoc(doc(db, "anything/else"), { a: 1 }));
    await assertFails(getDoc(doc(db, "anything/else")));
  });
});
