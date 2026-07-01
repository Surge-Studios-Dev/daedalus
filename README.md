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
- `ROADMAP.md` - state of the factory + the phased plan.
- `INTAKE.md` - the questionnaire that turns an idea into a manifest + spec
  (the front door; the 1-week clock starts when it's done).
- `templates/spec.template.md` - the product-spec structure (modeled on the
  spec Ladle shipped from), section-parity-tested against `tools/spec_gen`.
- `surge.manifest.schema.md` - the manifest schema (the single source of truth).
- `surge.manifest.example.yaml` - a complete worked example ("Tally", a
  fictional demo app - not a real product; the real one is
  `examples/ladle.manifest.yaml`).
- `packages/surge_ui/` - the shared UI toolbox (Tier 2): token contract, theme,
  component library, catalog, and gallery.
- `foundation/` - the blank canvas (Tier 1): a runnable app wired to `surge_ui`.
- `bricks/daedalus/` - the Mason brick that stamps the canvas from a manifest.
- `tools/` - manifest_validator, spec_gen (manifest -> spec skeleton),
  legal_gen (privacy/ToS/Apple privacy manifest/store labels), store_gen
  (manifest -> Fastlane deliver/supply metadata with limit checks),
  ship_check (pre-submission linter), portfolio_gen (site portfolio entry).
- `scripts/forge.sh` - provisions a stamped app (Firebase, ids, icons, legal,
  and the manual launch checklist).

## Make a new app
```bash
# 0. Flesh out the idea: answer INTAKE.md -> write surge.manifest.yaml
mkdir my-new-app && cd my-new-app
cp ../Daedalus/surge.manifest.example.yaml surge.manifest.yaml   # then edit
(cd ../Daedalus/tools/manifest_validator && dart run bin/validate.dart ../../../my-new-app/surge.manifest.yaml)

# 1. Generate the spec skeleton, then WRITE it (Sections 1-6, 8, 10)
(cd ../Daedalus/tools/spec_gen && dart run bin/spec_gen.dart ../../../my-new-app/surge.manifest.yaml)

# 2. Stamp + provision (only after the spec says Status: final)
mason init && mason add daedalus --path ../Daedalus/bricks/daedalus
mason make daedalus -c vars.json   # pre_gen reads the manifest -> a configured app
bash ../Daedalus/scripts/forge.sh  # provision to shippable
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
