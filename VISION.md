# VISION.md · Why Daedalus exists

> **One fleshed-out idea becomes a live, store-approved, revenue-ready app in a
> week — because everything that isn't the idea is already built.**

Daedalus is the Surge app factory. Its vision is a studio where the marginal
cost of launching an app approaches the cost of having the idea: fill in a
manifest, write the spec, replace the stubs with the product, and ship. The
app, its backend, its legal pages, its store metadata, and its marketing
presence all fabricate from a single `surge.manifest.yaml`. Nothing that every
app needs is ever built twice.

## The world this creates

- **Ideas are cheap to test in production.** When idea-to-store is one week,
  the portfolio strategy works: launch many small, real products, let the
  market vote, and double down on winners. Daedalus turns "should we build
  this?" from a quarter-long bet into a week-long experiment.
- **Plumbing is a solved problem.** Auth, paywalls, settings, telemetry,
  compliance, onboarding, and release lanes are built once, tested once, and
  stamped everywhere. Studio effort goes into the 20% that differentiates a
  product, never the 80% every app shares.
- **Apps are killable.** Every stamped app is a standalone repo with no
  dependency graph to untangle. Ending an experiment is deleting a repo. The
  factory makes starting cheap *and* stopping cheap, which is what makes
  honest portfolio pruning possible.
- **The portfolio compounds.** Shared telemetry means one dashboard reads
  every app with zero per-app wiring. Cross-promo makes each launch an
  acquisition channel for the next. Components promoted from real apps make
  the toolbox richer with every ship. App #10 is faster and better than app #1
  because of apps #1 through #9.
- **Compliance is a property, not a phase.** Account deletion, Sign in with
  Apple, restore purchases, privacy manifests, and legal pages ship working in
  the base. Store rejection risk is engineered out before a feature is
  written, and re-verified by `ship_check` before every submission.

## What Daedalus is not

The factory is the plumbing, never the product. A stamped app is deliberately
unshippable as bare stubs; the differentiated functionality is always human
work, and the one-week clock exists to protect that work, not replace it.
Daedalus succeeds when the only hard part left is the part worth doing.

## How we'll know it's working

- Idea fleshed out (INTAKE complete) → app live in both stores in ~1 week,
  repeatedly, across multiple apps.
- Zero per-app hours spent on auth, settings, paywalls, telemetry wiring,
  legal drafting, or store-metadata assembly.
- A fix to a shared module lands in every app as a version bump, not a
  five-repo patch tour.
- At least one app killed cleanly and one component promoted into
  `surge_ui` — proof the loop runs in both directions.

Companions: [DAEDALUS.md](DAEDALUS.md) (the app contract),
[FRAMEWORK.md](FRAMEWORK.md) (the architecture), [ROADMAP.md](ROADMAP.md)
(the phased plan toward this vision).
