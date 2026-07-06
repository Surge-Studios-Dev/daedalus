# CLAUDE.md · {{name}}

Stamped from the Surge app factory (Daedalus). Universal infrastructure lives in
`lib/modules/` and is considered done; your job is `lib/features/`. Config comes
from `surge.manifest.yaml` — regenerate rather than hand-editing generated
wiring.

## Source of truth (in priority order)
1. `design/spec.md` — the product spec. Every screen has an ID (see its §3.2
   inventory); if a screen is not listed there, it does not exist. Spec §8 edge
   cases are acceptance criteria: each one becomes a test. Wins on product
   intent.
2. `surge.manifest.yaml` — config (tabs, gates, monetization, brand). Wins on
   wiring; regenerate rather than hand-editing generated files.
3. Still ambiguous → ask, don't invent.

## Stack (decided; do not relitigate)
Flutter stable, Dart 3.x. **Riverpod** (`flutter_riverpod`, no codegen yet).
**go_router**. UI from the shared **surge_ui** package (tokens + components).
Monetization model: **{{mon_model}}**, trial: **{{trial_type}}** ({{trial_days}}d),
entitlement: **{{entitlement}}**.

Firebase and RevenueCat ship as clearly-marked **`SEAM:`** mocks so the app runs
today. Wire them by replacing the seam bodies and uncommenting the deps in
`pubspec.yaml` — the state shapes stay the same, so nothing downstream changes.

## Layout
- `lib/app/` bootstrap, router, app root, generated `nav_config.dart`.
- `lib/modules/` universal, do not fork per feature: auth, onboarding, paywall
  (gate + entitlement), settings, telemetry, shell.
- `lib/features/<tab>/` the part you build. One themed stub per feature tab
  exists already; `feature_registry.dart` maps tab id -> screen (generated).
- `lib/core/` pure Dart, tested. `lib/models/` app models.

## Rules
- Gate paid value with `ref.gate(context, 'gateId', onSuccess)`. Never check the
  entitlement ad hoc.
- Style only via surge_ui: `context.tokens`, `SurgeText`, `SurgeSpace`, and the
  `Surge*` components. **Never hardcode a hex.** Need a new shared component?
  Search `surge_ui/catalog.json` first; if it's missing and reusable, add it
  there (see surge_ui/CONTRIBUTING.md), not inline here.
- Use the standard `Ev` telemetry events; add domain events on top, never rename
  the base set.
- Copy: sentence case; no dark patterns; no em dashes in user-facing copy.
- snake_case filenames. Every screen widget carries its spec ID in a doc
  comment (`/// COU-01 · Counters home`) and commits carry it too
  (`feat(COU-01): counters home`).
- Work spec-first: before building a screen, its §6 block must exist; before
  calling it done, its §8 edge cases must be tests. When implementation changes
  a spec decision, add a numbered deviation footnote at the affected spot —
  never rewrite history.
- Mark every launch placeholder with a grep-able `LAUNCH-TODO:` comment that
  names its checklist item, and make the checklist point back at the code.
  Retire the tag the moment the item ships.

## Debugging (evidence before theory)
- Screenshot the user's actual screen before theorizing (`adb shell screencap`
  on Android; simulator screenshot on iOS). One real capture ends a
  multi-round guessing game.
- Users report symptoms in their own vocabulary ("overflow", "it's broken").
  Map words to mechanisms with evidence, not assumption — and when a fix
  ships, verify the *user's* scenario end-to-end, not the reduced case.
- Headless-browser layout lies at phone sizes; verify web surfaces on a real
  device.
- Immutable published artifacts (cached images, message link previews) keep
  showing old bugs after the fix — say "reshare/refresh to see it" or the fix
  looks broken.

## Commands
```
flutter pub get
flutter analyze      # must be clean
flutter test
flutter run
```

## Before submission (non-negotiable)
Replace every feature stub with real functionality (stub-only fails Apple 4.3).
Account deletion, restore purchases, Sign in with Apple, and Privacy + Terms all
ship working from the template; keep them working. Run `scripts/forge.sh` first.
