# ROADMAP.md · Review + forward plan

State of the Surge app factory as of 2026-07-01, and the phased plan to reach
the goal: **an app released within ~1 week of the idea being fleshed out**, with
app, backend, store approval, and web presence all produced from one manifest.
Companion to the [docs/ wiki](docs/README.md) (how everything works, with
diagrams), [FRAMEWORK.md](FRAMEWORK.md) (architecture decisions), and
[DAEDALUS.md](DAEDALUS.md) (the app contract).

---

## 1. What exists and is verified

All of the below **analyzes clean and passes tests** (44 tests across 8 suites,
re-verified for this review). The stamp pipeline is verified end to end: the
example manifest produces an app that analyzes clean and passes its smoke test;
a deliberately broken manifest is rejected with precise errors before stamping.

| Piece | Tier | Contents | Tests |
|---|---|---|---|
| `packages/surge_ui` v0.3.0 | 2 | Token contract, theme, 28 components, generated `catalog.json`, gallery app | 14 |
| `packages/surge_onboarding` | 3 | Data-driven first-run flow (integrated into foundation + brick) | 3 |
| `packages/surge_crud` | 3 | `CrudRepository<T>` + in-memory + Firestore impls | 2 |
| `packages/surge_rating` | 3 | `RatingService` + mock + in_app_review impl | 1 |
| `foundation/` | 1 | Blank canvas: auth, purchases, storage, analytics, crash reporting — all behind swappable service seams with working mocks; onboarding; settings stack; auth→onboarding→app routing | 9 |
| `bricks/daedalus` | factory | Stamps the foundation from a manifest: tabs/palette/providers/trial/entitlement templated, nav config + themed stubs + registry + smoke test + CI generated; fail-fast manifest validation in pre_gen | (stamp-verified) |
| `bricks/daedalus` backend | factory | Per-app deny-by-default firestore.rules (per-user isolation), Functions scaffold (account-deletion purge + callable pattern), rules unit tests, firebase.json/.firebaserc from the manifest | 4 (emulator-verified) |
| `tools/manifest_validator` | factory | Canonical schema rules + CLI | 6 |
| `tools/legal_gen` | factory | Privacy + ToS (md + JSON), Apple `PrivacyInfo.xcprivacy`, store privacy-label checklist — from `data_practices` | 8 |
| `tools/portfolio_gen` | factory | Manifest → portfolio-entry seed (narrative left as TODOs) | 1 |
| `tools/spec_gen` | factory | Manifest → `design/spec.md` skeleton (IDs, gates, monetization; template-parity-tested) | 5 |
| `tools/store_gen` | factory | Manifest `store` block → Fastlane deliver/supply metadata trees + limit warnings | 4 |
| `tools/ship_check` | factory | Pre-submission linter (stubs, seams, privacy manifest, ATT, secrets, legal, metadata limits); red/green report | 5 |
| `bricks/daedalus` fastlane | factory | Beta/release lanes (both stores) on `flutter build`, Appfile from manifest, Gemfile | (stamp-verified) |
| `INTAKE.md` + `templates/spec.template.md` | front door | Idea → manifest + spec pipeline with a definition of "fleshed out" | (via spec_gen) |
| `scripts/forge.sh` | factory | Provisioning: platform folders, flutterfire, icons, legal_gen, seam-flip + site-registration checklist | (syntax-checked) |
| `scripts/check_brick_sync.dart` | factory | Enforces the foundation <-> `__brick__` sync contract (divergent-file allowlist + signatures, root lint parity) in CI | (stamp + negative-tested) |
| `scripts/provision.sh` | factory | Cloud provisioning from manifest + provision.env: Firebase/GCP, auth providers, ASC record, keystore, RevenueCat graph, deploys | (dry-run verified; live at Phase 4) |
| `.github/workflows/ci.yml` | factory | All packages + catalog freshness + validator + legal_gen + hooks | — |
| Surge-Studios-Site | web | Master `/privacy` + `/terms` as the LLC umbrella with auto-updating covered-apps list; per-app `/<slug>/privacy|terms` from generated JSON; legal registry generator (`npm run build:legal`); Ladle in the portfolio | (build-verified) |

**The seam pattern is the framework's spine.** Auth, purchases, storage,
analytics, and crash reporting all follow one contract: *interface → mock
default → real implementation → swapped by one flag in bootstrap → proven by a
backend-swap test*. Every stamped app runs on mocks out of the box; each real
backend is a one-line flip plus console setup.

**Drift check:** foundation/lib vs `__brick__/lib` differ in exactly the 6
deliberately divergent files (4 mustache-templated: app, bootstrap, sign-in,
paywall; 2 forked onto the generated nav config: router, tab shell) plus
`features/home` (post_gen generates per-tab stubs). Since Phase 0 this is
**enforced**: `scripts/check_brick_sync.dart` runs in CI and fails on any
unexplained difference, clobbered template, or missing mirror file.

## 2. Scorecard against the original vision

| Pillar | Status |
|---|---|
| Blank canvas with essentials | **Done, verified** |
| Searchable, documented component toolbox | **Done** (28 components; header→catalog generated; gallery) |
| Modular systems fill the canvas | **Proven** (onboarding integrated; crud + rating built, not yet integrated) |
| Promotion path (custom → library) | **Defined** (CONTRIBUTING bar; not yet exercised by a real app) |
| One manifest drives app | **Done, verified** |
| One manifest drives legal/compliance | **Done** (privacy, ToS, Apple privacy manifest, store labels) |
| One manifest drives the website | **Partial** (legal fully automated; portfolio semi-automated; no per-app marketing page template) |
| Store approval workflow | **Done to the signing line** (compliance assets, metadata, upload lanes, readiness linter; signing/accounts are Phase 4's human step) |
| Backend (rules/functions) | **Done** (deny-by-default rules + tested; Functions scaffold with account purge; Phase 2) |
| Idea → spec front door | **Done** (INTAKE → manifest → spec_gen skeleton → written spec; Phase 1) |
| Live validation on device/Firebase/RevenueCat | **Deferred** (user-gated; all code paths ready) |

## 3. Debt register

| # | Debt | Risk | Fix |
|---|---|---|---|
| D1 | ~~Foundation↔brick sync is manual~~ | ~~High~~ | **Fixed (Phase 0)**: `scripts/check_brick_sync.dart` + CI job |
| D2 | ~~Stamped apps use **path deps** to `surge_*` packages~~ | ~~High at first external repo~~ | **Fixed (Phase 0)**: `use_git_deps` stamp var — path (default, workspace dev) or git ref (standalone repos). Git mode needs Daedalus **pushed** first; see brick README |
| D3 | ~~Validator rules duplicated (tools pkg + pre_gen inline mirror)~~ | ~~Medium~~ | **Fixed (Phase 0)**: hooks path-depend on manifest_validator; inline mirror deleted |
| D4 | ~~`surge_crud` / `surge_rating` have no reference integration~~ | ~~Medium~~ | **Fixed (Phase 2)**: `features/notes` CRUD reference (foundation-only) + rate-us settings row (stamped everywhere) |
| D5 | `app_gated` trial window not enforced (manifest supports one_time model; gate() ignores trial days); Remote Config + notifications flags unwired | Medium — contract promise unmet for one_time apps | Wire in Phase 5 (or when first one_time app appears) |
| D6 | Cross-promo module from DAEDALUS.md contract not built | Low — needs 2+ live apps to matter | Phase 5 |
| D7 | No golden tests; gallery verification is manual | Low | Add goldens when visual churn slows |
| D8 | ~~"Tally" example reads like a real product~~ | ~~Low~~ | **Fixed (Phase 0)**: marked fictional in the example manifest, root README, and examples/README |
| D9 | ~~Store metadata block exists but nothing consumes it~~ | ~~Low~~ | **Fixed (Phase 3)**: `tools/store_gen` → deliver/supply trees + limit checks |
| D10 | Loose version pins (many "newer available" warnings) | Low | Pin before first release build |

## 4. Forward plan

### Phase 0 — Consolidation (protect what's built) · ✅ done 2026-07-01
- D1: `scripts/check_brick_sync.dart` (mirror set + divergent allowlist with
  per-file signatures + root lint parity) wired into CI; negative-tested.
- D2: `use_git_deps` / `surge_git_url` / `surge_git_ref` stamp vars. Path deps
  stay the default (workspace dev); git mode renders pinned git refs for
  standalone repos and is verified render-correct. **Prereq to use it: commit
  and push Daedalus** — origin/main is one old commit that predates the
  packages, so git-mode `pub get` correctly fails against it today.
- D3: hooks import `manifest_validator` via path dep; the inline rule mirror
  (119 lines) is deleted. One rule set, one test suite.
- D8: Tally marked fictional in `surge.manifest.example.yaml`, the root
  README, and a new `examples/README.md`.
- Bonus fixes surfaced by the new checks:
  - The brick shipped **no `analysis_options.yaml`** — stamped apps analyzed
    under weaker lints than the foundation. Added + enforced via root parity.
  - That exposed post_gen's blanket `dart format .` reformatting the mirrored
    files (tripping the now-active lints); it now formats only the files it
    generates, and emits nav_config with trailing commas.
  - The stamped app's `ci.yml` was never actually rendered by mustache — a
    literal `${{ }}` in a comment is an invalid empty mustache tag, which made
    mason fall back to a raw copy. Comment reworded; conditional
    path-vs-git-deps note now renders correctly.
  - CI tooling job now also covers `portfolio_gen` (was missing).

### Phase 1 — The front door: idea → spec · ✅ done 2026-07-01
The 1-week clock starts "after the idea is fleshed out" — fleshing out is now
a repeatable pipeline (idea → INTAKE → manifest → spec skeleton → written
spec → stamp):
- `templates/spec.template.md`: the structure Ladle shipped from — screen IDs,
  positioning rule / core loop / quality bar up front, gating table, edge
  cases as acceptance criteria (§8), P0/P1/P2 phases, out-of-scope list.
- `INTAKE.md`: six-pass question set (idea, shape, money, data & risk, brand,
  ops), every answer mapped to a manifest field or spec section, with the
  "fleshed out" definition of done.
- `tools/spec_gen` (5 tests): manifest → `design/spec.md` skeleton. Fills tab
  map, screen inventory with stable IDs (reserved factory prefixes + derived
  per-tab prefixes, collision-safe), gating table wired to `?src={gateId}`,
  monetization mechanics incl. trial contract, deep links, brand — humans
  write intent at `**TODO**` markers. Section headers are parity-tested
  against the template so the two can't drift. Refuses to overwrite a written
  spec without `--force`.
- Per-app CLAUDE.md template: spec is source-of-truth #1, screen IDs in doc
  comments and commits, §8 edge cases become tests, spec-first working rule.

### Phase 2 — Backend safety rail · ✅ done 2026-07-01
- Every stamp now ships a backend: `firebase.json`, `.firebaserc` (project id
  from the manifest), deny-by-default `firestore.rules` with per-user
  isolation at `users/{uid}/...` (carrying Ladle's parent-doc/`{document=**}`
  lesson, plus commented server-only and shaped-shared-write patterns), and
  `firestore.indexes.json`.
- `backend/` npm package: TS Functions (`onAccountDeleted` recursively purges
  a deleted user's Firestore data — the account-deletion promise the privacy
  policy makes; `ping` shows the v2 callable pattern) + 4 rules unit tests
  pinning the security contract (unauthed denied, owner allowed incl.
  subcollections, cross-user denied, deny-by-default). Verified locally under
  the real emulator (npm install + tsc build + 4/4 green); the stamped app's
  CI runs them per push.
- D4 closed both ways: `foundation/lib/features/notes` is the living
  CrudRepository reference (in-memory default → per-user Firestore at exactly
  the rules-isolated path when useFirebase flips; NTS-01, widget-tested), and
  settings gained a "Rate this app" row on the surge_rating seam (mock in
  tests, InAppReview on devices; stamped into every app).
- forge.sh: backend step + deploy-rules-BEFORE-useFirebase ordering in the
  launch checklist.

### Phase 3 — Release rail · ✅ done 2026-07-01
- `tools/store_gen` (4 tests): manifest `store` block → Fastlane deliver
  (iOS) + supply (Play) metadata trees, with store character-limit warnings
  instead of silent truncation (closes D9). Its first run caught a real bug:
  the example tagline was 31 chars — one over Apple's subtitle limit.
- Brick ships `fastlane/` (beta/release lanes for both platforms built on
  `flutter build ipa`/`appbundle`, Appfile pre-filled from the manifest,
  Gemfile). Store copy is regenerated from the manifest, never hand-edited.
- `tools/ship_check` (5 tests): the pre-submission linter — feature stubs
  remaining (Apple 4.3), seams still on mocks, placeholder firebase_options,
  PrivacyInfo present AND referenced by the Runner target, ATT string when
  tracking, hardcoded-key hygiene, legal artifacts, metadata limits, version,
  backend presence, optional `--run-tests`. Red/green report, exit 1 on
  blockers. Verified against a fresh stamp: 6 truthful day-0 blockers,
  5 passes.
- forge.sh: store_gen step (4a) + ship check as the closing step ("red items
  = the remaining to-do list") + release-lanes checklist section.

### Phase 3.5 — Provisioning rail · ✅ built 2026-07-01 (skeleton-honest)
`scripts/provision.sh`: the cloud consoles, scripted. Firebase/GCP project
creation + API enablement + billing link + Firestore db (firebase/gcloud
CLIs), auth providers straight from `auth.providers` (Identity Toolkit admin
API), ASC bundle id + app record + capabilities (fastlane produce), Android
upload keystore + key.properties, the full RevenueCat v2 object graph from
the monetization block (project → store apps → entitlement → products →
offering → packages → attach), and rules/functions deploy. Credentials via
gitignored `provision.env` (studio-wide `~/.surge/` + per-app), every step
soft-degrades to a note, `--dry-run` prints the exact plan (verified against
the example manifest). Irreducible manual core: Play "Create app" click, the
two privacy questionnaires (answers pre-generated), store-side products,
screenshots, and one-time studio enrollments. **Proven at Phase 4's first
live run** — expect flag/payload adjustments there.

### Phase 4 — Live validation · user-gated, can interleave any time
Firebase project (`flutterfire configure`, enable providers), platform config
for Apple/Google sign-in, RevenueCat app/entitlement/products, device run.
Execute the DoD: three-way sign-in, sandbox purchase + restore, account
deletion, events flowing. First real test of the mock→live flips.

### Phase 5 — Operate layer · after first launch
Analytics sink + portfolio dashboard; Remote Config + app_gated trial
enforcement (D5); cross-promo (D6); sunset playbook.

## 5. Sequencing rationale

Phases 0–3 are done: the factory is protected, the front door exists, every
stamp ships a tested backend safety rail, and the release rail runs from
manifest to store-ready metadata with a linter standing at the submission
gate. What remains is Phase 4 (live validation — your accounts + a device;
nothing blocks on it) and Phase 5 (operate layer, post-first-launch). The
scaffolding era is over: run INTAKE.md on the next real idea and take it
through the pipeline — building an actual app is what surfaces the next
round of truth, and Phase 4 happens naturally along the way.
