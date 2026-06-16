# CLAUDE.md · {{name}}

Stamped from the Surge app template. Universal infra is in `lib/modules/` and is
considered done; your job is `lib/features/`. The source of truth for config is
`surge.manifest.yaml`; regenerate rather than hand-editing generated wiring.

## Stack (decided; do not relitigate)
Flutter stable, Dart 3.x. Riverpod + codegen. go_router. freezed. Firebase
(Auth, Firestore, Functions, Crashlytics, Analytics{{#remote_config}}, Remote Config{{/remote_config}}).
RevenueCat (`purchases_flutter`). Monetization model: **{{mon_model}}**, trial: **{{trial_type}}** ({{trial_days}}d).

## Layout
- `lib/modules/` universal, do not fork per feature: auth, paywall (gate + entitlement), settings, telemetry, crosspromo, ui.
- `lib/features/<tab>/` the part you build. One stub per non-builtin tab exists already.
- `lib/core/` pure Dart, tested. `lib/models/` freezed.

## Rules
- Gate paid value with `gate(context, Gates.x, onSuccess)`. Never check entitlements ad hoc.
- Read colors from `Theme.of(context).extension<AppTokens>()`. Never hardcode a hex.
- Use the standard `Telemetry` events; add domain events on top, never rename the base set.
- Copy: sentence case; no dark patterns; no em dashes in user-facing copy.
- snake_case filenames. Every screen carries its id in a doc comment.

## Before submission (non-negotiable)
Replace every feature stub with real functionality (stub-only fails Apple 4.3).
Account deletion, restore purchases, Sign in with Apple, Privacy + Terms all ship
working from the template; keep them working. Run `scripts/forge.sh` first.
