# Daedalus

> The master craftsman. Fabricates a launch-ready Flutter app from one blueprint.

The Surge app factory: the tooling that turns a single `surge.manifest.yaml`
into a launch-ready Flutter app, its store metadata, and (via the site repo) its
marketing pages. Producing a new app should be filling in a manifest plus the
domain stubs, not rebuilding plumbing.

## Contents
- `DAEDALUS.md` - what a launch-ready app contains; the design contract.
- `FRAMEWORK.md` - the shared-framework architecture (tiers, token contract,
  component-library conventions, distribution, promotion).
- `surge.manifest.schema.md` - the manifest schema (the single source of truth).
- `surge.manifest.example.yaml` - a complete worked example ("Tally", a
  fictional demo app - not a real product; the real one is
  `examples/ladle.manifest.yaml`).
- `packages/surge_ui/` - the shared UI toolbox (Tier 2): token contract, theme,
  component library, catalog, and gallery.
- `foundation/` - the blank canvas (Tier 1): a runnable app wired to `surge_ui`.
- `bricks/daedalus/` - the Mason brick that stamps the canvas from a manifest.
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
`packages/surge_ui`, `foundation/`, and the `bricks/daedalus` brick are built
and verified: the toolbox and canvas analyze clean with green tests, and a
`mason make` from the example manifest produces an app that analyzes clean.
Firebase, RevenueCat, and settings persistence ship as **working mocks** marked
`SEAM:` — the app runs today; wire the real integrations by replacing the seam
bodies and uncommenting the deps (see `foundation/README.md`). Cross-promo and
codegen from the original contract are not in the base yet. Pin `pubspec.yaml`
versions before a release build. Generated legal text is a draft to be reviewed,
not legal advice.
