# RUNBOOK.md · How an AI runs a new Surge app

This is the orchestrator for the whole pipeline: a state machine with
phases, gates, and pushback rules. If you are an AI session pointed at
Daedalus with an app idea, **this is the first file you read** and the
only one you need to read in full. Every other doc is loaded per-phase
via the context router below.

Two laws govern everything here:

1. **Gates are checklists, not vibes.** A phase is done when its exit
   gate is checked, not when the work "feels" done. You do not advance
   past an unchecked gate — you name what's missing and the smallest
   path to satisfying it.
2. **Pushback is a duty, not a mood.** When a pushback trigger fires,
   you challenge the human — once, clearly, citing the trigger. If they
   still want it, record the override and proceed. You are the factory's
   quality bar in conversation form; you are not a nag.

**Override protocol.** Any gate item or pushback can be overridden by
the human saying so explicitly. Record every override — in the manifest
as a comment during phases 0–2, in `.daedalus/state.yaml`'s log after
stamping — with one line: what was skipped and why. Silent skips are the
only forbidden move.

---

## The pipeline at a glance

```
Phase 0  INTAKE           idea -> validated surge.manifest.yaml
Phase 1  DESIGN DIRECTION references -> theme pack + brand block + positioning rule
Phase 2  SPEC             manifest -> approved spec §6 (screens) + §8 (edge cases)
Phase 3  STAMP & PROVE    scripts/new_app.sh -> green, board-reviewed app
Phase 4  BUILD            the stamped app's MILESTONES.md ladder (M0–M6)
Phase 5  SHIP             M7: forge.sh -> ship_check -> submitted
Phase C  CHANGE           live app -> tiered change loop
```

Phases 0–3 run in the Daedalus repo and this runbook is authoritative.
At the end of phase 3 authority **hands off** to the stamped app's own
`MILESTONES.md` + `.daedalus/state.yaml` — this file does not duplicate
the milestone ladder, it just tells you when you've left it behind.

**Human gates** (hard stops — never proceed on your own): INTAKE
answers themselves · design references · the assembled manifest · the
§6/§8 spec draft · the phase 3 screen-board review · a design-direction
tournament pick · store submission · a post-ship C2/C3 spec delta.
Everything else runs without asking.

**Executable arms.** Three skills run pieces of this pipeline;
the runbook is what sequences them:

| Skill | Runs | Phase |
|-------|------|-------|
| `/new-app` | INTAKE → manifest → spec draft → stamp & prove | 0–3 |
| `/design-pass` | reference-anchored taste loop over the screen board (tournament first if direction unset) | 1 review · M1 · after every M3 screen group |
| `/sim-drive` | real taps + truthful screenshots on the simulator | M3+ verification, pre-ship |

---

## Context router

Load per phase, not up front. A fresh session resuming mid-pipeline
reads: this file, then the row for the current phase, nothing else.

| Phase | Read | Skim only if needed |
|-------|------|---------------------|
| 0 INTAKE | `INTAKE.md` | `VISION.md` (what Surge builds and kills), `surge.manifest.schema.md` |
| 1 DESIGN | `INTAKE.md` pass 5 · `packages/surge_ui/DESIGN.md` (the taste rules) · `docs/design-references/` (Read the images) | theme packs in `surge_theme_pack.dart` · surge_ui gallery |
| 2 SPEC | `design/spec.md` skeleton (after `spec_gen`) | `FRAMEWORK.md` §screens · `examples/ember.spec-sections.md` (what done looks like) |
| 3 STAMP | `scripts/new_app.sh` output · stamped `README` | `DAEDALUS.md` (brick internals, only when a stamp fails) |
| 4 BUILD | stamped app's `.daedalus/state.yaml` then `MILESTONES.md` | `AI-RAIL.md` (M0 with an AI surface) · `docs/parallel-build.md` (M3 fan-out) · `docs/testing.md` · `examples/ladle/feature-slice/` (exemplar) |
| 5 SHIP | `tools/ship_check` output · `scripts/forge.sh` checklist | store_gen / legal_gen docs |
| C CHANGE | stamped app's `.daedalus/state.yaml` · the touched spec §6/§8 blocks | `INTAKE.md` (C3 only: the pass that owns the field) |

`ROADMAP.md` and `SHARING.md` are factory-development docs — never
required to run the pipeline.

---

## Phase 0 · INTAKE

**Entry:** a human with an idea. **Mode:** conversation, never a form —
work through `INTAKE.md`'s six passes in order, one pass at a time,
building the manifest in memory answer by answer. A form invites
one lazy sentence per field; an interviewer extracts the real answers.

Ask the questions in your own words, propose defaults where INTAKE
names them, and show the assembled `surge.manifest.yaml` at the end of
pass 6 for an explicit yes.

### Pushback triggers

| ID | Fires when | The challenge |
|----|-----------|---------------|
| P0-LOOP | Monetization is `subscription` but pass 1 found no compounding loop | "This is a utility. One-time price, or tell me what compounds." |
| P0-BAR | The quality bar names a feature, not a *behavior* incumbents fail | "What must be flawless — and who currently gets it wrong?" |
| P0-TABS | >5 tabs, or a tab isn't a place the user *returns to* | "That's a button, not a tab. Which two tabs merge?" |
| P0-SCREENS | Any tab lists >8 screens | "That's two tabs or a v2. What's P0?" |
| P0-GATE | A paid gate sits on the core loop's first lap | "Users must feel the loop before the wall. Gate depth, not entry." |
| P0-WHY | "Why will this beat what exists" has no honest answer | "Niche-the-giants-ignore is a valid answer — but write it down; it caps the marketing budget." |
| P0-SCOPE | The idea needs >1 novel/risky system (new device API + new AI surface + …) | "One moat per app. Which risk is *the* product? The rest is v2." |

Each trigger: challenge once, accept the human's call, record overrides.

### Exit gate

- [ ] All six INTAKE passes answered; manifest assembled and shown
- [ ] Human said yes to the assembled manifest (human gate)
- [ ] `cd tools/manifest_validator && dart run bin/validate.dart <file>` clean
- [ ] Name/slug checked: App Store search, domain, `slug://` collision
- [ ] Prices sanity-checked against 2–3 comparable apps
- [ ] Legal fields set (governing law, support email, content summary,
      disclaimers)
- [ ] Every override recorded as a manifest comment

---

## Phase 1 · DESIGN DIRECTION

The Ember lesson: a decent backend with an undesigned frontend is a
dead app. This phase exists so "the look" is decided from evidence
**before** anything is stamped, and can be checked against that
evidence forever after.

**Entry:** phase 0 gate passed. **Rule: references before look, no
exceptions.** Do not discuss palettes, fonts, or packs until the human
has provided 2–3 shipped apps (names or screenshots) this app should
feel like. If they have none, help them find candidates — but the
references are theirs to choose. File the screenshots into
`docs/design-references/` (per the naming rules in its README; an
approved per-app direction gets its own subfolder like `ladle/`) —
every later design pass anchors against these images.

The portfolio's taste law is `packages/surge_ui/DESIGN.md` (atmosphere,
protagonist, editorial type, glass/hairline/glow, neutral chrome with
color on the moving protagonist, the Ladle floating bar). This phase
chooses the app's identity *within* those rules; it does not relitigate
them. Rule 8 exists because Ember relapsed into the banned coral family
and then overcorrected to monochrome — read it before picking an accent.

### Reference derivation protocol

From the references, extract and write down (this becomes the brand
block plus the design half of the positioning rule):

1. **Temperature & surface** — warm/cool, flat/soft-depth/glassy,
   light-first or dark-first
2. **Density** — airy content app vs. dense utility; list row height,
   padding scale
3. **Shape language** — radius family, card vs. edge-to-edge lists
4. **Type feel** — geometric/humanist/serif display; quiet or loud
   hierarchy
5. **Accent behavior** — one hero color vs. semantic multi-color;
   where color is *allowed* to appear

Then map to a theme pack from `SurgeThemePack.all`. Current packs:
`soft_depth` (and `canvas`, which is **never a shipping look** — it is
the unthemed factory default). If no pack fits the references, flag
**"new pack needed in surge_ui"**, pick the nearest for now, and record
the gap. The default-AI palette family (tomato/coral on warm paper) is
banned outright.

Derive the rest of the brand block: accent / accent_soft / panel pulled
from or harmonized with the references (contrast-checked — `accent_soft`
is the deepened variant for grounds the accent can't carry white text
on), display + text fonts (bundled, not declared-and-defaulted), logo
mode, the app's own icon motif (never generic zap/star defaults), the
living element and its signature motion (Ember's flame — static theming
cannot express a theme), banned vocabulary.

**Direction contested or unclear? Tournament, don't iterate.** Solo
iteration converged on "terrible" twice on Ember; one tournament round
fixed it. Build 3 committed, self-contained variants of ONE hero screen
(each may break the theme), render side by side on the board, human
picks (human gate). The winner becomes the living spec. `/design-pass`
owns this mechanic — invoke it rather than improvising.

### Pushback triggers

| ID | Fires when | The challenge |
|----|-----------|---------------|
| P1-REF | Human wants to skip references ("just make it look good") | "That's how Ember happened. Three apps you admire — or screenshots. Two minutes." |
| P1-CANVAS | Human accepts the `canvas` default to move faster | "Canvas is scaffolding, not a look. Nearest real pack is ___ — confirm or give references." |
| P1-DRIFT | Chosen palette/fonts contradict the references provided | "Your references are calm and cool; this accent is hot. Which one is wrong?" |
| P1-RULE | No positioning rule survives pass 1 | "One sentence that settles design disputes in advance — what must this *read as*, and what must never leak in?" |

### Exit gate

- [ ] 2–3 references on record (names + what was taken from each)
- [ ] Theme pack chosen (not `canvas`) — or "new pack needed" flagged
      with the nearest pack selected
- [ ] Brand block complete in the manifest: palette (contrast-checked),
      fonts, logo mode, banned vocabulary
- [ ] Positioning rule written — one sentence, disputes-settling
- [ ] Manifest re-validates

---

## Phase 2 · SPEC

**Entry:** phase 1 gate passed. Run `tools/spec_gen` to generate the
`design/spec.md` skeleton, then **draft the human-authored heart
yourself** from the INTAKE answers:

- **§6** — a block per P0 screen with a stable ID: layout archetype,
  states (loading/empty/error/populated), primary action, gate points
- **§8** — 5+ edge cases per feature tab, written as testable
  sentences (they become M2/M6 tests verbatim)

Present the complete draft for approval. **STOP until approved.**
Drafting-for-review is the speedup; skipping review is how specs go
wrong. Apply requested changes and re-present; do not advance on
"looks fine I guess" — get an explicit yes.

### Pushback triggers

| ID | Fires when | The challenge |
|----|-----------|---------------|
| P2-RUBBER | Human approves instantly without reading (<1 min on a multi-screen spec) | "This draft is my guess at your product. The two blocks I'm least sure about are ___ and ___ — read at least those." |
| P2-EDGE | A feature tab can't produce 5 edge cases | "If it has no edge cases it isn't a feature — fold it into another tab or cut it." |
| P2-CREEP | Draft review adds new screens/features beyond the manifest | "That's a manifest change. Back to INTAKE for that field, or park it as P1." |

### Exit gate

- [ ] Spec §1–5 and §10 written; §6 block per P0 screen (stable IDs);
      §8 with 5+ edge cases per feature tab
- [ ] Human explicitly approved the §6/§8 draft (human gate)
- [ ] Approved draft saved where phase 3 can merge it after stamping

---

## Phase 3 · STAMP & PROVE

**Entry:** phase 2 gate passed.

```
scripts/new_app.sh <manifest> [output_dir]
```

Validates, stamps into a sibling directory, generates the spec
skeleton, runs analyze + test. If it exits non-zero: fix and rerun —
**never hand over a red stamp**. Then:

1. Merge the approved §6/§8 into the stamp's `design/spec.md`
   (`new_app.sh` runs spec_gen no-overwrite)
2. Capture the screen board
   (`flutter test --update-goldens test/goldens/screen_board.dart`)
   and open the contact sheet, light + dark
3. **The board review (human gate):** the human looks at the contact
   sheet next to the phase 1 references and answers one question —
   *"does this look like a small real product with fake domain data,
   or a template?"* Template → run `/design-pass` (it grades against
   DESIGN.md's mechanical checks) now, while it's cheap. This is the
   gate that would have caught Ember.
4. `flutter run` to walk the pattern screens live

### Exit gate

- [ ] `new_app.sh` green (validate, stamp, analyze, test)
- [ ] Approved §6/§8 merged into the stamped `design/spec.md`
- [ ] Screen board captured in both modes; human passed the board
      review against the references
- [ ] Fixtures show populated, plausible data — no gray voids, no
      "wired stub" copy on P0 tabs
- [ ] Stamped app's `.daedalus/state.yaml` reads `stage: stamped`,
      `milestone: M0`; handoff noted in its log

**Handoff:** from here the stamped app's `MILESTONES.md` and
`.daedalus/state.yaml` are authoritative. Sessions open in the app
repo, read `state.yaml` first, and update it before ending.

---

## Phase 4 · BUILD (delegated to MILESTONES.md)

This runbook does not restate the ladder — M0 (prove the moat) through
M6 (hardening) live in the stamped app, in risk order, one milestone
(or one M3 screen group) per session. What this runbook adds is the
**session discipline** and the cross-cutting pushback rules:

**Session shape.** Read `state.yaml` → work the active milestone → run
its exit criteria → update `state.yaml` (gates + one log line) → end.
A milestone is done when its criteria are checked, not when its code
exists. The merge bar (analyze + tests + format) is a committed hook,
always on, never negotiable.

**The two verification instruments** — know which one you need:

- **Screen board + `/design-pass`** proofs *themed widgets* with
  fixtures. Run after every M3 screen group and at M1; two rounds
  minimum, stop on a clean round.
- **`/sim-drive`** proofs the *real running app* — splash, icons,
  floating chrome, real backend states, motion. Goldens cannot see
  these. Run before calling M3 groups done and always before M7.

### Pushback triggers (any milestone)

| ID | Fires when | The challenge |
|----|-----------|---------------|
| P4-SKIP | Human wants UI before M0/M2 ("let's see screens first") | "The moat unproven is the app unproven. M0 is a harness and a number — usually one session." |
| P4-RAW | New UI reaches for raw `Container`/`ListTile`/hex instead of catalog components and tokens | "Catalog first. If the catalog can't do it, that's a promotion candidate, not an inline hack." |
| P4-BLANK | A pattern screen is deleted for a blank `Scaffold` | "Reshape, don't raze — the chrome (states, gates, fixtures) is the factory's half of the work." |
| P4-BOARD | A screen group merges without re-capturing the screen board | "Board or it didn't happen. Two minutes, both modes, compare to the references." |
| P4-CREEP | Mid-build feature ideas | "Park it: P1 list or manifest change. The 1-week clock only survives if scope is fixed at stamp." |

---

## Phase 5 · SHIP (M7)

**Entry:** M0–M6 checked in the stamped app.

- [ ] `scripts/forge.sh` run; every LAUNCH-TODO retired or explicitly
      accepted
- [ ] `tools/ship_check` green — no overrides on this one; ship_check
      *is* the definition of done
- [ ] Store screenshots generated from the screen board; metadata
      reviewed against store_gen output
- [ ] Legal drafts reviewed by a human — generated policies are drafts,
      not counsel
- [ ] Provisioning: Firebase live seams flipped, RevenueCat products
      real, one sandbox purchase + restore verified on device
- [ ] Human confirms submission (human gate) · submitted ·
      `state.yaml` stage → `shipped`

**Post-ship, one ritual:** write the retro — what the factory made
easy, what it made hard, cycle time in calendar days vs. the 1-week
target. Factory gaps become ROADMAP items; app learnings become
promotion candidates. This closes the loop that turned Ladle into
Daedalus in the first place.

---

## Phase C · CHANGE (live apps)

**Entry:** the app is shipped and a change request arrives. The first
post-ship session flips `.daedalus/state.yaml` to `stage: live`; every
later session starts here. The full pipeline exists to ship v1 — a
4-hour bug fix does not need a PRD, and it doesn't get to skip the spec
either. The move: **name the tier at session start, log it in
`state.yaml`** (one line: date, tier, what changed), then run the
tier's process. The tier is keyed to what the change *touches*, not
how big it feels.

| Tier | Touches | Process |
|------|---------|---------|
| **C1 Patch** | Code only; no spec-visible behavior change (bug fix, copy tweak, refactor) | Merge bar. If observed behavior changes anyway: deviation footnote. One `state.yaml` log line. No human gate. |
| **C2 Slice** | A screen or behavior, within existing manifest scope | Draft the **delta only** — new/edited §6 blocks and §8 cases with new stable IDs registered in §3.2 → human approves the delta, not the whole spec (human gate) → build with tests → re-capture the screen board → `/sim-drive` if chrome/navigation touched. |
| **C3 Manifest** | Anything in `surge.manifest.yaml` (tabs, gates, pricing, legal, brand) | Rerun only the INTAKE pass that owns the field → re-validate → regen derived artifacts (spec skeleton delta; legal_gen/store_gen if legal/store fields moved) → then C2 for the UI part. |

### Pushback triggers

| ID | Fires when | The challenge |
|----|-----------|---------------|
| PC-TIER | A "patch" edits the manifest or adds a screen | "That's a C3/C2, not a patch. Name the INTAKE pass / spec delta first." |
| PC-SCOPE | The change contradicts the positioning rule or spec §10 | "This is on the do-not-design list. Overturn §10 explicitly (dated) or park it." |

### Exit gate (per tier)

- [ ] **C1:** merge bar green · one `state.yaml` log line (tier + what
      changed) · deviation footnote if observed behavior moved
- [ ] **C2:** delta approved by the human · new §8 cases are tests ·
      screen board re-captured in both modes · `/sim-drive` run if
      chrome/navigation touched · `state.yaml` log line
- [ ] **C3:** manifest re-validates · derived artifacts regenerated ·
      then the C2 gate for the UI part

---

## Resuming mid-pipeline

A fresh session determines its phase in this order:

0. `state.yaml` reads `stage: live` → Phase C; the change request sets
   the tier.
1. Stamped app exists with `.daedalus/state.yaml` → phase 4/5; the
   state file says exactly where. This runbook is context, not law.
2. Approved spec §6/§8 exists but no stamp → phase 3.
3. Validated manifest with a complete brand block → phase 2.
   Brand block missing or `canvas` → phase 1.
4. Otherwise → phase 0, and the conversation starts with the idea.

Never redo a passed gate; never trust an unchecked one.
