# CLAUDE.md · {{name}}

Stamped from the Surge app factory (Daedalus). Universal infrastructure lives in
`lib/modules/` and is considered done; your job is `lib/features/`. Config comes
from `surge.manifest.yaml` — regenerate rather than hand-editing generated
wiring.

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
- snake_case filenames. Every screen carries its id in a doc comment.

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
