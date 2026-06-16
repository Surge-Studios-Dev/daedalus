# daedalus (Mason brick)

Stamps a launch-ready Flutter app from a `surge.manifest.yaml`. Universal
infrastructure (auth, nav, settings, paywall, telemetry, cross-promo) is filled
in; domain tabs are wired stubs.

## Use
```bash
mason add daedalus --path bricks/daedalus   # or from a brick registry
cd path/to/new-app-dir                   # must contain surge.manifest.yaml
mason make daedalus                      # pre_gen reads the manifest -> vars
```

## How it works
- `hooks/pre_gen.dart` reads `surge.manifest.yaml` and flattens it into every
  Mason var (palette -> Color literals, providers -> auth toggles, monetization
  -> model/trial, navigation.tabs -> the tab list). The manifest is the only
  thing a human edits.
- `__brick__/` is the templated app. `{{mustache}}` slots are filled from vars.
- `hooks/post_gen.dart` scaffolds one stub per non-builtin tab, writes
  `lib/features/feature_registry.dart` (tab id -> screen, read by the router),
  then runs `flutter pub get` and `dart format`.

## What is real vs skeleton in this brick
- Real / framework-light: tokens from palette, telemetry taxonomy, the
  model-agnostic `gate()` + `Entitlement` + `TrialWindow`, cross-promo slot,
  account deletion flow, the manifest->vars hooks, the feature-registry generation.
- Skeleton (correct shape, verify against installed versions, fill TODOs):
  bootstrap (Firebase/RevenueCat init), router (go_router 17 StatefulShellRoute),
  auth provider wiring, paywall offering/purchase rendering, sign-in UI.

Pin the `pubspec.yaml` versions to your verified set before relying on a build.
This brick has not been compiled; treat the skeleton files as scaffolding.
