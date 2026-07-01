# ROADMAP.md · Review + forward plan

State of the Surge app factory as of 2026-07-01, and the phased plan to reach
the goal: **an app released within ~1 week of the idea being fleshed out**, with
app, backend, store approval, and web presence all produced from one manifest.
Companion to [FRAMEWORK.md](FRAMEWORK.md) (architecture) and
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
| `tools/manifest_validator` | factory | Canonical schema rules + CLI | 6 |
| `tools/legal_gen` | factory | Privacy + ToS (md + JSON), Apple `PrivacyInfo.xcprivacy`, store privacy-label checklist — from `data_practices` | 8 |
| `tools/portfolio_gen` | factory | Manifest → portfolio-entry seed (narrative left as TODOs) | 1 |
| `scripts/forge.sh` | factory | Provisioning: platform folders, flutterfire, icons, legal_gen, seam-flip + site-registration checklist | (syntax-checked) |
| `scripts/check_brick_sync.dart` | factory | Enforces the foundation <-> `__brick__` sync contract (divergent-file allowlist + signatures, root lint parity) in CI | (stamp + negative-tested) |
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
| Store approval workflow | **Partial** (compliance assets yes; upload/signing/readiness-lint no) |
| Backend (rules/functions) | **Missing** (client-side surge_crud only) |
| Idea → spec front door | **Missing** (the biggest gap to the 1-week goal) |
| Live validation on device/Firebase/RevenueCat | **Deferred** (user-gated; all code paths ready) |

## 3. Debt register

| # | Debt | Risk | Fix |
|---|---|---|---|
| D1 | ~~Foundation↔brick sync is manual~~ | ~~High~~ | **Fixed (Phase 0)**: `scripts/check_brick_sync.dart` + CI job |
| D2 | ~~Stamped apps use **path deps** to `surge_*` packages~~ | ~~High at first external repo~~ | **Fixed (Phase 0)**: `use_git_deps` stamp var — path (default, workspace dev) or git ref (standalone repos). Git mode needs Daedalus **pushed** first; see brick README |
| D3 | ~~Validator rules duplicated (tools pkg + pre_gen inline mirror)~~ | ~~Medium~~ | **Fixed (Phase 0)**: hooks path-depend on manifest_validator; inline mirror deleted |
| D4 | `surge_crud` / `surge_rating` have no reference integration in foundation | Medium — Tier-3 plug-in contract only proven once (onboarding) | Add a small `notes` demo feature (crud) + a rate-us settings row (rating) |
| D5 | `app_gated` trial window not enforced (manifest supports one_time model; gate() ignores trial days); Remote Config + notifications flags unwired | Medium — contract promise unmet for one_time apps | Wire in Phase 5 (or when first one_time app appears) |
| D6 | Cross-promo module from DAEDALUS.md contract not built | Low — needs 2+ live apps to matter | Phase 5 |
| D7 | No golden tests; gallery verification is manual | Low | Add goldens when visual churn slows |
| D8 | ~~"Tally" example reads like a real product~~ | ~~Low~~ | **Fixed (Phase 0)**: marked fictional in the example manifest, root README, and examples/README |
| D9 | Store metadata block exists but nothing consumes it | Low until Phase 3 | Fastlane deliver/supply generation |
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

### Phase 1 — The front door: idea → spec · the highest-leverage unbuilt piece
The 1-week clock starts "after the idea is fleshed out" — and fleshing out is
where the human week actually goes today. Make it repeatable:
- `templates/spec.template.md` modeled on Ladle's `original-spec.md`: screens
  with IDs, edge cases as acceptance criteria, P0/P1/P2 scoping, copy rules.
- `INTAKE.md`: the question set that turns an idea into a manifest + spec
  skeleton (core loop, tabs, gates, model, data practices, domain disclaimer).
- `tools/spec_gen`: scaffolds the spec skeleton from a filled manifest
  (sections + screen IDs per tab, gate list, compliance checklist) so humans
  write product intent, not structure.
- Per-app CLAUDE.md template updated to the spec workflow (IDs in commits,
  edge cases as tests).

### Phase 2 — Backend safety rail · every app needs it; absent today
- Brick gains a `backend/` template: `firebase.json`, `.firebaserc`
  placeholder, deny-by-default `firestore.rules` with per-user isolation
  matching surge_crud's conventions, `firestore.indexes.json`, a TS Functions
  scaffold with one callable.
- Rules unit tests (@firebase/rules-unit-testing + emulator) wired into the
  per-app CI template.
- D4 closed: `notes` demo feature in foundation on `surge_crud`, covered by the
  rules template.

### Phase 3 — Release rail · turns forge's checklist into buttons
- Fastlane template (beta/release lanes; match + keystore notes).
- Store metadata generated from the manifest `store` block into
  deliver/supply structure (closes D9).
- `tools/ship_check` pre-submission linter: stubs remaining, legal registered
  on the site, ATT string when tracking, version bump, smoke test, PrivacyInfo
  in the Runner target. forge.sh runs it; red/green report.

### Phase 4 — Live validation · user-gated, can interleave any time
Firebase project (`flutterfire configure`, enable providers), platform config
for Apple/Google sign-in, RevenueCat app/entitlement/products, device run.
Execute the DoD: three-way sign-in, sandbox purchase + restore, account
deletion, events flowing. First real test of the mock→live flips.

### Phase 5 — Operate layer · after first launch
Analytics sink + portfolio dashboard; Remote Config + app_gated trial
enforcement (D5); cross-promo (D6); sunset playbook.

## 5. Sequencing rationale

0 → 1 → 2 → 3, with 4 whenever accounts/device are available (nothing blocks
on it, and nothing in 1–3 requires it). Phase 0 (done) de-risked everything
after it. Phase 1 attacks the actual bottleneck of the 1-week goal.
Phase 2 is the safety-critical layer no app should ship without. Phase 3
converts the remaining manual toil. The first real app should be built *during*
phases 2–4, using the factory in anger — that exercise, not more scaffolding,
is what will surface the next round of truth.
