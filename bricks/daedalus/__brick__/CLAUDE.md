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

## Session working rules
- **Read `.daedalus/state.yaml` and `MILESTONES.md` first**, before any other
  file. Work only the active milestone, one milestone (or one M3 screen group)
  per session. Update the state file (stage, gates, one log line) before
  ending.
- Anything touching >1 file: present a plan (files, approach) before writing
  code. New packages must be justified against the stack below.
- The merge bar — analyze clean + formatted + tests green — is enforced by the
  committed `.claude/hooks/merge_bar.sh` on every `git commit`. Don't fight
  it; a blocked commit means fix the failure, not bypass the hook.
- Commit per completed screen/module with the spec ID in the message
  (`feat(COU-01): counters home`).
- Human gates — STOP and ask rather than proceeding: spec §6/§8 approval,
  design direction changes, anything touching money or store submission.

## Eyes (never build UI blind)
- **Screen board**: `flutter test --update-goldens test/goldens/screen_board.dart`
  renders every screen to light/dark PNGs + `test/goldens/contact_sheet.html`,
  headlessly, seeded from `lib/dev/fixtures.dart`. Run it after every visual
  change and LOOK at it (Read the PNGs) before calling UI done. Add specs for
  new screens and presented sheets as they land; grow the fixtures with the
  real models.
- **Component goldens**: `flutter test --update-goldens test/goldens` seeds;
  after that, an unintended golden diff is the test working.
- UI is not "done" until compared against the design reference in BOTH modes.
- Optional deeper loop: a Flutter MCP toolkit (hot reload + widget snapshots
  against the running app) can be wired in `.mcp.json`; the screen board is
  the dependency-free baseline every stamp has.

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
- `lib/features/<tab>/` the part you build. Each feature tab starts as a
  WORKING pattern vertical (model + CrudRepository seam + searchable list ->
  editor sheet -> delete) — reshape it into the real spec §6 feature instead
  of writing screens from scratch. `feature_registry.dart` maps tab id ->
  screen (generated).
- `lib/core/` pure Dart, tested BEFORE any UI consumes it. `lib/models/` app
  models. `lib/dev/fixtures.dart` seed data (screen board, tests,
  screenshots — one seam, keep it current).
- Design personality: theme pack `{{theme_pack}}` + the manifest palette.
  Never restyle ad hoc — change the pack/palette, or propose a new pack in
  surge_ui.

## Parallel build (M3 only)
After M2 locks core logic, feature tabs are independent. To parallelize:
one agent per screen group in its own git worktree, each obeying this file
and the merge bar, plus one integrator session that merges, re-runs the full
suite, and re-captures the screen board. The fan-out playbook lives in the
Daedalus repo at `docs/parallel-build.md`.

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

## Live changes (post-ship)
Once `state.yaml` reads `stage: live`, state the tier before touching code and
log it in `state.yaml`:
- **C1 Patch** — code only, no spec-visible behavior change: merge bar, one log
  line; deviation footnote if behavior moved anyway.
- **C2 Slice** — a screen/behavior within manifest scope: draft the §6/§8 delta
  (new IDs registered in §3.2), human approves the delta, build with tests,
  re-capture the board.
- **C3 Manifest** — anything in `surge.manifest.yaml`: rerun the owning INTAKE
  pass, re-validate, regen derived artifacts, then C2 for the UI part.

The full loop (triggers, exit gates) is the Daedalus RUNBOOK's Phase C.
