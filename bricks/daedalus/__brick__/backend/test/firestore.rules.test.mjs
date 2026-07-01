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

describe("deny by default", () => {
  it("denies unmatched root collections even when authenticated", async () => {
    const db = env.authenticatedContext("alice").firestore();
    await assertFails(setDoc(doc(db, "anything/else"), { a: 1 }));
    await assertFails(getDoc(doc(db, "anything/else")));
  });
});
