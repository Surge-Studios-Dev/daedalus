---
name: new-app
description: Run the Daedalus front door end to end - the INTAKE conversation to a validated surge.manifest.yaml, draft spec §6/§8 for approval, then stamp and prove a running app via scripts/new_app.sh. Use when the user brings an app idea, says "new app", or asks to run INTAKE.
---

# /new-app — idea to running app

You are running the Daedalus pipeline's front door. The human brings an
idea; you leave them with a stamped, analyzed, green app and an approved
spec. Stay conversational in the interview, deterministic in the tail.

## 1. INTAKE (conversational — do not turn it into a form)

Work through `INTAKE.md`'s six passes in order. Rules that matter:

- Pass 1: push for the one-liner, the core loop, and the QUALITY BAR — the
  quality bar becomes the corpus expectations in M0 (AI-RAIL.md).
- Pass 5: **references before look, no exceptions.** Ask for 2-3 shipped
  apps (screenshots welcome). The default-AI palette family (tomato/coral
  on warm paper) is banned; `canvas` is never a shipping look. Pick the
  theme pack the references point at; if none fits, flag "new pack needed
  in surge_ui" and pick the nearest for now.
- Answer-by-answer, build up the manifest in memory; show the assembled
  `surge.manifest.yaml` at the end of pass 6 and get a yes.

## 2. Validate + name-check

- Write the manifest to a working file; run
  `cd tools/manifest_validator && dart run bin/validate.dart <file>` until
  clean.
- Run the INTAKE output checklist (name/slug collisions, prices
  sanity-checked, legal fields set). Report anything skipped — don't
  silently pass it.

## 3. Draft spec §6 + §8 FOR APPROVAL (human gate)

`spec_gen` fills the skeleton's structure; sections 6 (screen specs) and 8
(edge cases) are the human-authored heart. Draft them yourself from the
INTAKE answers — every P0 screen gets a §6 block with a stable ID, every
feature tab gets 5+ §8 edge cases — and present the draft to the user for
approval. **STOP until approved.** Drafting-for-review is the speedup;
skipping review is how specs go wrong. (Note: `new_app.sh` runs spec_gen
with the default no-overwrite; apply the approved §6/§8 to the generated
`design/spec.md` after stamping.)

## 4. Stamp and prove

```
scripts/new_app.sh <manifest> [output_dir]
```

Validates, stamps into a sibling directory, generates the spec skeleton,
and runs analyze + test on the stamp. If it exits non-zero, fix and rerun —
never hand over a red stamp. Then merge the approved §6/§8 into
`design/spec.md`, `flutter run` to show the pattern screens, and point the
user at the stamped app's `MILESTONES.md` + `.daedalus/state.yaml` (M0 is
next: the moat gate).

## Human gates in this flow

INTAKE answers themselves, the design references, the assembled manifest
(step 1 exit), and the §6/§8 draft (step 3). Everything else runs without
asking.
