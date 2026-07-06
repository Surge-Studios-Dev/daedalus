# Testing — how a stamped app stays green

The conventions Ladle shipped with, generalized. The merge bar for every
change is mechanical: `flutter analyze` clean + `flutter test` green +
`dart format` applied (and `npm test` in `backend/` when it changed).
Hooks should enforce it; self-reports don't count.

## The pyramid, per stamped app

1. **Core logic first, tested first.** Anything in `lib/core/` is pure
   Dart with a unit test for every function and every spec Section 8 edge
   case, written BEFORE any UI consumes it. This ordering is load-bearing:
   Ladle's grocery/date/scaling math shipped bug-free because the tests
   existed before the screens did.
2. **Backend unit + rules tests** (`backend/`): pure decisions in
   `test/unit/`, Firestore security rules against the emulator. The AI
   pipeline additionally has the **corpus gate** (`backend/corpus/`,
   AI-RAIL.md) — a numeric pass-rate gate, not a vibe check.
3. **Widget/flow smoke tests**: the stamped `test/smoke_test.dart` boots
   the whole tree; grow one flow test per feature (the foundation's
   auth-redirect and settings tests are the pattern).
4. **Goldens** (`test/goldens/`): the most-used components in light +
   dark. The stamped scaffold skips until seeded, then arms itself.

## Spec Section 8 as a test suite

Section 8 of the spec (edge cases) is acceptance criteria, not
suggestions. The convention that kept Ladle honest:

- Every Section 8 case becomes a named test — put the case in the test
  name (`'incompatible units stack instead of merging (§8)'`) so coverage
  is greppable against the spec.
- Inject clock and settings (`today`, week-start) as parameters; never
  read `DateTime.now()` inside logic under test. `surge_core`'s date
  helpers exist so DST cases are testable at all.
- When a production bug is fixed, its regression test lands in the same
  commit and names the failure mode, not the ticket.

## Goldens

- Seed once per app: `flutter test --update-goldens test/goldens`, commit
  `test/goldens/images/`. Until seeded the suite skips, so a fresh stamp
  is green out of the box.
- Every case renders in BOTH themes via `buildSurgeTheme` — dark-mode-only
  ink bugs are the most common golden catch.
- Wrap cases in `RepaintBoundary` and golden the boundary, not the screen.
- Re-run `--update-goldens` only for INTENTIONAL visual changes; an
  unintended diff is the test working. Inspect `test/goldens/failures/`
  (isolated/masked diffs) before regenerating.
- Goldens are pixel-exact per renderer; generate and compare on the same
  platform (CI or the team's dev OS, pick one and stick to it).

## The screen board (visual QA against the design reference)

For whole-screen visual comparison — the "compared against the prototype,
light and dark" bar — Ladle used a dev-only contact sheet: a
`screen_board.dart` under `test/goldens/` that is deliberately NOT named
`*_test.dart` (so `flutter test` ignores it), built on the
[`golden_board`](https://github.com/Esagem/golden_board) harness. It
pumps every screen with seeded provider overrides + loaded fonts and
emits PNG snapshots plus a `contact_sheet.html` (gitignored) for
side-by-side review. Adopt it once an app has real screens; it is the
cheap substitute for a hand screenshot pass, and the fastest way for an
agent to SEE what it built.

## Rules that came from shipped test bugs

- **Stub platform channels headless tests touch** (wakelock, share
  channel): a `MissingPluginException` in a smoke test is a missing stub,
  not a flake. The share drain treats `MissingPluginException` as "no
  platform queue" for exactly this reason.
- **Seed `SharedPreferences.setMockInitialValues` per test**, including
  flags like `onboarded`, or first-run UI leaks into every flow test.
- **Golden suites load real fonts explicitly** (`FontLoader` in
  `setUpAll`); nothing else in `flutter test` does it for you.
- **Never gate on a filtered corpus run** — iterating with `--only=` is
  for fixing; the gate binds on the full corpus only (see
  `backend/corpus/README.md`).
