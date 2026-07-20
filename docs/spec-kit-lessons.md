# spec-kit-lessons.md · Applying spec-kit's lessons to Daedalus

**Status: implemented (2026-07-20).** All seven lessons landed as a commit
series — Phase C (L1), the §11/§12 triad (L2+L5), `spec_lint` (L4),
`tools/spec_coverage` (L3), brick markers (L6), the doc drift guard (L7) —
see ROADMAP Phase 5b and each core doc's changelog. Two deviations from the
designs below, both discovered mid-build: the raw-hex lint excludes §2/§9
(the palette-definition homes — spec_gen itself emits hex there), and the
manifest brand block had no `banned_vocabulary` field despite RUNBOOK/INTAKE
promising one, so it was added (schema + example + validator + spec_gen §5)
before the lint could read it. This doc now serves as the rationale record.

Source: a review of github/spec-kit — its templates, its full changelog arc
(v0.0.1 → v0.12.x), and practitioner reports. Daedalus independently arrived
at most of spec-kit's hard-won conclusions and enforces them better (hooks
and linters, not prose); only these seven mechanisms were worth importing.

---

## What we are deliberately NOT importing

- **A single constitution file.** Daedalus principles are scattered
  (DAEDALUS.md conventions, AI-RAIL doctrine, stamped CLAUDE.md rules) but
  each is backed by a hook, linter, or CI check. spec-kit's own changelog
  shows its constitution wasn't even loaded at implement time until v0.8.6.
  Enforcement beats consolidation; keep the hooks.
- **A discrete `/clarify` command.** Pushback-as-duty plus hard human gates
  already make clarification continuous. What's missing is only the
  *write-back* discipline (Lesson 5).
- **Per-feature plan phase** (research.md, data-model.md, contracts/). The
  stamp *is* the plan — architecture is amortized into the factory. Adding a
  planning ceremony per feature would be importing spec-kit's most-criticized
  overhead ("a sea of markdown documents").
- **Their TDD walk-back.** spec-kit softened test-first from NON-NEGOTIABLE
  to opt-in. Daedalus keeps M2-before-UI and §8-as-tests; that ordering is
  load-bearing here and the merge bar makes it cheap to honor.

---

## Lesson 1 · The CHANGE loop (brownfield)

**Why.** spec-kit's most persistent criticism: the full pipeline for every
change ("a 4-hour bug fix shouldn't need a PRD"). Its community spent a year
patching this with BrownKit, reconcile extensions, and a "lean preset."
Daedalus's pipeline terminates at M7 — the first live change to a shipped app
will be improvised. Define the loop before it's needed.

**Design.** New RUNBOOK section, **Phase C · CHANGE (live apps)**, after
Phase 5. Three tiers, keyed to what the change touches — the agent names the
tier at session start and logs it in `state.yaml`:

| Tier | Touches | Process |
|------|---------|---------|
| **C1 Patch** | Code only; no spec-visible behavior change (bug fix, copy tweak, refactor) | Merge bar. If observed behavior changes anyway: deviation footnote. One `state.yaml` log line. No human gate. |
| **C2 Slice** | A screen or behavior, within existing manifest scope | Draft the **delta only** — new/edited §6 blocks and §8 cases with new stable IDs registered in §3.2 → human approves the delta, not the whole spec → build with tests → re-capture the screen board → `/sim-drive` if chrome/navigation touched. |
| **C3 Manifest** | Anything in `surge.manifest.yaml` (tabs, gates, pricing, legal, brand) | Rerun only the INTAKE pass that owns the field → re-validate → regen derived artifacts (spec skeleton delta; legal_gen/store_gen if legal/store fields moved) → then C2 for the UI part. |

Pushback triggers:

| ID | Fires when | The challenge |
|----|-----------|---------------|
| PC-TIER | A "patch" edits the manifest or adds a screen | "That's a C3/C2, not a patch. Name the INTAKE pass / spec delta first." |
| PC-SCOPE | The change contradicts the positioning rule or spec §10 | "This is on the do-not-design list. Overturn §10 explicitly (dated) or park it." |

**Edits.**
- `RUNBOOK.md` — new Phase C section (~40 lines: tiers table, triggers, exit
  gate per tier); add `Phase C  CHANGE  live app -> tiered change loop` to
  the pipeline-at-a-glance block; prepend to "Resuming mid-pipeline":
  `0. state.yaml reads stage: live → Phase C; the change request sets the tier.`
- `bricks/daedalus/__brick__/.daedalus/state.yaml` — stage enum comment
  becomes `stamped -> m0 -> building -> hardening -> shipped -> live`
  (flip to `live` at first post-ship session).
- `bricks/daedalus/__brick__/CLAUDE.md` — short "Live changes (post-ship)"
  block: the three tiers in three lines, plus "state the tier before touching
  code."
- `docs/pipeline.md` — one paragraph + a Phase C node on the diagram.

**Effort.** An afternoon. Pure prose; no tooling.

---

## Lesson 2 · Assumptions log + "defaults, don't ask"

**Why.** spec-kit's early versions produced question-storms; the fix was:
cap questions, take informed defaults, but **log every guess** in a mandatory
Assumptions section, and enumerate topics agents must never ask about.
Daedalus has §11 (blocking questions) and "ask, don't invent" — but no home
for the middle case: the reasonable guess. Unlogged guesses are how specs and
apps drift apart silently.

**Design.**
- `templates/spec.template.md` — new section after §11:

  ```markdown
  ## 12. Assumptions

  Decisions made without asking. One line each:
  `- **A1 (date, phase):** assumption — basis — overturned by: <what would change it>`
  Overturning one: strike it here, add a deviation footnote at the affected spot.
  ```

- `tools/spec_gen/lib/spec_gen.dart` — emit the §12 header + guidance
  comment. (The parity test forces template and generator to move together —
  one commit for both.)
- `INTAKE.md` — a "Defaults (propose, don't ask)" box above Pass 1,
  consolidating the defaults currently scattered inline: Firebase
  `<slug>-prod`, `support@<domain>`, entitlement `pro`, notifications off in
  v1, remote config only if `app_gated` trial, cross-promo on, tracking off.
  The interview stays six passes; the box kills the low-value questions
  inside them.
- `bricks/daedalus/__brick__/CLAUDE.md` — amend source-of-truth item 3:
  "Still ambiguous → if it touches product intent (§1), money, or legal:
  ask. Otherwise take the obvious default and log it in spec §12
  Assumptions. Batch asks; more than 3 open questions in one session means
  stop and re-read the spec."
- `RUNBOOK.md` — Phases 0–1 (pre-spec): record assumptions as `# ASSUME:`
  manifest comments; Phase 2 gains a step: migrate them into §12 once the
  skeleton exists.

**Effort.** Small. One template+generator commit, two prose edits.

---

## Lesson 3 · `tools/spec_coverage` (the analyze analogue)

**Why.** spec-kit's most-praised command, `/analyze`, mechanically maps
requirements → tasks and flags zero-coverage requirements as CRITICAL.
Daedalus's ID discipline makes the same check nearly free — but today M6's
"every §8 edge case is a named test or has a written reason" is
self-reported, and the factory's own doctrine (merge_bar.sh) is that
*self-reports don't count*.

**Design.** New Dart tool `tools/spec_coverage`, mirroring ship_check's
shape (`bin/`, `lib/`, `test/`, `CheckResult(name, status, detail)`,
PASS/WARN/FAIL report, non-zero exit on FAIL). Reads `design/spec.md`,
`lib/`, `test/`.

Parsing:
- §3.2 inventory and §6 blocks: IDs via `^### ([A-Z]{2,4}-\d{2})` plus
  phase tags.
- §8 bullets; a line ending `— waived: <reason>` counts as waived (this is
  M6's "written reason", moved from chat into the spec where it's greppable).

Checks:
1. Every P0 §6 ID has a `/// <ID>` doc comment in `lib/` — screen built.
2. Every P0 §6 ID appears under `test/goldens/` — screen on the board.
3. Every §8 line has a matching test name (normalized-substring match, plus
   the `(§8)` suffix convention) or a waiver — else FAIL, listing the lines.
4. Reverse orphans: `/// XX-NN` IDs in `lib/` absent from §3.2 → FAIL ("if a
   screen isn't listed, it doesn't exist" — enforced in both directions).
5. WARN: P1/P2 screen IDs found in code (built ahead of phase).

Output ends with one summary line:
`coverage: 14/14 P0 screens · §8 41 tested / 2 waived / 0 missing`.

**Wiring.**
- `MILESTONES.md` (brick) M6 first criterion becomes:
  `- [ ] dart run spec_coverage green — replaces the by-hand §8 sweep;
  waivers live in the spec, not chat`.
- `state.yaml` (brick) gates gains
  `coverage: pending # spec_coverage green (§6 IDs in code+board, §8 tested or waived)`.
- `tools/ship_check` adds a `spec coverage` check that calls the library (path
  dependency) — the definition of done includes it, no overrides, same as the
  rest of ship_check.
- Phase C (Lesson 1): C2 changes run it scoped to the touched IDs.

**Effort.** The biggest item — about a day including its own test fixture
(mini spec + fake `lib/`/`test/` tree). The parser is regex-grade and leans
on conventions spec_gen already emits.

---

## Lesson 4 · Spec lint ("unit tests for English")

**Why.** spec-kit self-validates a spec against a quality checklist (up to 3
iterations) *before* the human sees it; checklist items interrogate the text
("is the vague term quantified?"), not the system. P2-RUBBER guards against
the human rubber-stamping; nothing yet guards against the draft being
rubber-stampable.

**Design.** Second binary in the spec_gen package — `bin/spec_lint.dart`
(shares the section parser). Checks:

- Every §6 block carries all five format headers (Purpose / Layout /
  Interactions / States / Navigation); States covers loading + empty + error.
- ≥5 §8 items per feature tab (machine-checks the existing gate language).
- Vague adjectives flagged when no number shares the sentence: fast, smooth,
  snappy, intuitive, robust, graceful, seamless, properly, correctly.
- Leftover `**TODO**` markers in §1–6/§8; raw hex anywhere (§0 rule).
- Banned vocabulary from the manifest's `brand` block appearing in spec copy
  (the lint reads `surge.manifest.yaml` — a check spec-kit can't do).
- Status may read "final" only with zero TODOs.

Waiver: `<!-- lint-waive: reason -->` on the preceding line.

**Wiring.** `RUNBOOK.md` Phase 2: new step — draft → `spec_lint` → fix →
re-lint until clean → *then* present for approval; exit gate adds
`- [ ] spec_lint clean (waivers recorded)`. P2-RUBBER's challenge upgrades
to: present the lint output alongside the two least-sure blocks.

**Effort.** Half a day; parsing shared with Lesson 3.

---

## Lesson 5 · Clarifications write-back

**Why.** spec-kit's clarify discipline: every answer is *immediately*
integrated into the affected section and logged as a dated `Q → A`, leaving
"no obsolete contradictory text." Daedalus records overrides, but answers
given in spec review or mid-build live only in chat and evaporate.

**Design.** §11 restructures into two lists:

```markdown
## 11. Open questions

### Open        <!-- only questions that block a P0 decision (unchanged) -->
### Resolved    <!-- - 2026-07-19 — Q: … → A: … → updated: §6 LIB-02 -->
```

Rule (stamped CLAUDE.md + RUNBOOK Phase 2): when the human answers anything,
make both edits in the same commit — update the affected block, move the
question to Resolved with date and answer. **An answer that lives only in
chat doesn't exist.**

This completes a clean triad, one home per case:

| Case | Home |
|------|------|
| Asked and answered | §11 Resolved |
| Never asked, guessed | §12 Assumptions (Lesson 2) |
| Decision overturned by implementation | Deviation footnote (existing) |

**Edits.** Template §11 + spec_gen §11 guidance (same parity-test commit as
Lesson 2), one CLAUDE.md rule, one RUNBOOK Phase 2 line.

**Effort.** An hour, if landed with Lesson 2.

---

## Lesson 6 · Managed markers for fleet propagation

**Why.** spec-kit spent months replacing fragile string-munging of agent
context files with marker-based upsert (`<!-- SPECKIT START/END -->`, v0.7.3).
ROADMAP Phase 6 item 6 (fleet propagation) will hit the identical problem:
updating stamped `CLAUDE.md` / `.claude/` across live app repos *after* apps
have added their own notes. Adopt the mechanism at stamp time, now, so every
app born from today's brick is fleet-updatable later.

**Design.**
- `bricks/daedalus/__brick__/CLAUDE.md` — wrap each factory-owned section in
  `<!-- DAEDALUS:BEGIN <section-id> -->` / `<!-- DAEDALUS:END <section-id> -->`
  (source-of-truth, session-rules, eyes, stack, layout, parallel, rules,
  debugging, commands, submission). Append an unmarked `## App notes` section
  explicitly owned by the app and never touched by fleet updates.
- Same markers in `.claude/settings.json`-adjacent docs if any grow; hooks
  are whole-file factory-owned (replace outright).
- `MILESTONES.md` is **not** blindly upsertable — apps check its boxes. Note
  in ROADMAP item 6: the fleet tool must preserve `[x]` state when updating
  criteria text.
- Amend ROADMAP Phase 6 item 6 to name the mechanism.

**Effort.** An hour now; saves the fleet tool a redesign later.

---

## Lesson 7 · Doc drift guard

**Why.** spec-kit's constitution carries a Sync Impact Report on every
amendment (downstream docs updated vs. pending). The repo-level lesson:
doc-to-doc consistency needs *a* mechanism. Observed drift here: ROADMAP
Phase 6 item 5 lists the agent layer as "not yet built" while
`state.yaml`, `merge_bar.sh`, `/new-app`, `/design-pass`, and `/sim-drive`
all exist in the tree.

**Design.**
- Core docs (RUNBOOK, INTAKE, DAEDALUS, FRAMEWORK, AI-RAIL,
  surge.manifest.schema.md) get a one-line footer —
  `*Verified against code: 2026-07-19*` — plus a tiny `## Changelog`
  (newest-first one-liners, meaning changes only: spec-kit's sync report at
  1% of the ceremony).
- `scripts/doctor.sh` — new section parsing the footers; WARN when a date is
  >90 days old. Never FAIL (doctor's contract: FAIL only on environment
  traps).
- `RUNBOOK.md` Phase 5 retro ritual gains one line: "bump *Verified against
  code* on every core doc the retro touched."
- Immediate housekeeping when this lands: correct ROADMAP Phase 6 item 5.

**Effort.** An hour.

---

## Suggested order

| # | Item | Effort | Land before |
|---|------|--------|-------------|
| 1 | L1 CHANGE loop | afternoon | the first live change to a shipped app |
| 2 | L2 + L5 template triad (§11/§12 + rules) | ~2h, one commit | the next Phase 2 run |
| 3 | L4 spec_lint | half day | the next Phase 2 run |
| 4 | L3 spec_coverage | ~1 day | the next M6 |
| 5 | L6 markers | 1h | the next brick change / next stamp |
| 6 | L7 doc guard | 1h | whenever |

L2 and L5 share the template + spec_gen parity edit — land together. L3 and
L4 share a parser — build L4 first, extract the parser, reuse it.
