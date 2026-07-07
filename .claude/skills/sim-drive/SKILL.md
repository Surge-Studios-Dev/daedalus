---
name: sim-drive
description: Drive the real app on an iOS simulator with real taps and truthful screenshots - the agent's hands and eyes for judging actual running UI, not the golden board. Use to verify flows end-to-end, catch what static goldens miss (splash/icon glyphs, floating chrome, real backend states), or reproduce a user-reported screen.
---

# /sim-drive — hands and eyes on the running app

The screen board proofs THEMED WIDGETS; this drives the REAL app (real
backend, real navigation, real splash) and captures the TRUE screen.
Reference implementation: Ember (`integration_test/drive_test.dart`,
`test_driver/integration_driver.dart`, `scripts/drive.sh`).

## The pattern

1. `integration_test/drive_test.dart`: a state-aware walk - READ the
   screen before acting (fresh installs open on onboarding; app data may
   persist auth/groups; branch on what finders actually see). Print
   `DRIVE-SHOT:<name>` at checkpoints.
2. `scripts/drive.sh <sim-udid>`: runs `flutter drive`, tails the log,
   and snaps `xcrun simctl io screenshot` at every marker into
   build/drive/. Downscale before Reading (`sips -Z 700`) - full-res sim
   shots can be rejected by the image pipeline.
3. Read every PNG. Judge like a user. Fix. Rerun.

## Hard-won rules

- `binding.takeScreenshot` on iOS returns the LAUNCH SURFACE, not the
  live frame - always screenshot from OUTSIDE via simctl.
- Restore `FlutterError.onError` after calling the app's bootstrap
  (Crashlytics rerouting violates the test binding's contract).
- Never `pumpAndSettle` bare with looping animations; use a bounded
  settle (catch the timeout) + fixed pumps.
- Asset generators (icons/splash) run under flutter_test: LOAD FONTS or
  ship tofu boxes - Ember's first store icon was a broken glyph square.
- Real-backend drives leave real data: pre-clean the e2e account via the
  Auth REST API and expect persisted state on reruns (state-aware walks
  handle it; assuming a fresh world does not).
- fb-idb is dead for this (client broken on modern Python; companion
  needs an Xcode CLT install). Don't retry it blindly.

Motion check: `xcrun simctl io <udid> recordVideo out.mov` + frame
extraction views an animation as stills - crude but real.
