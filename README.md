# Daedalus

> The master craftsman. Fabricates a launch-ready Flutter app from one blueprint.

The Surge app factory: the tooling that turns a single `surge.manifest.yaml`
into a launch-ready Flutter app, its store metadata, and (via the site repo) its
marketing pages. Producing a new app should be filling in a manifest plus the
domain stubs, not rebuilding plumbing.

## Contents
- `DAEDALUS.md` - what a launch-ready app contains; the design contract.
- `surge.manifest.schema.md` - the manifest schema (the single source of truth).
- `surge.manifest.example.yaml` - a complete worked example (the Tally app).
- `bricks/daedalus/` - the Mason brick that stamps an app from a manifest.
- `scripts/forge.sh` - provisions a stamped app (Firebase, ids, icons, legal,
  and the manual launch checklist).

## Make a new app
```bash
mkdir my-new-app && cd my-new-app
cp ../daedalus/surge.manifest.example.yaml surge.manifest.yaml   # then edit
mason add daedalus --git-url <this repo url> --git-path bricks/daedalus
mason make daedalus          # pre_gen reads the manifest -> a configured app
bash scripts/forge.sh      # provision to shippable
```

## Status / caveats
The brick's framework-light modules (tokens, telemetry, the model-agnostic
`gate()`, cross-promo, account deletion, the manifest->vars hooks) are written.
The framework-heavy wiring (bootstrap, router, auth providers, paywall
rendering) is honest skeleton: correct shape, marked TODOs, verify against the
installed go_router / Riverpod / RevenueCat versions. None of it has been
compiled. Pin `pubspec.yaml` versions before relying on a build. Generated legal
text is a draft to be reviewed, not legal advice.
