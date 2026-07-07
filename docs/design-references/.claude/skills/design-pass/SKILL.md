---
name: design-pass
description: Run a reference-anchored design pass over an app's screens - render the screen board, compare against docs/design-references/ and surge_ui/DESIGN.md, fix violations, re-render, repeat until a round is clean. Use when screens look average, before store screenshots, or after building a new screen group.
---

# /design-pass — the taste loop

You are polishing screens against REAL references, not from memory.
Ground truth: `docs/design-references/` (Read the images) and the rules
in `packages/surge_ui/DESIGN.md`. The app's screen board is your eyes.

## The loop (2 rounds minimum, stop on a clean round)

1. **Render**: `flutter test --update-goldens test/goldens/screen_board.dart`
   in the app. Read every changed screen PNG in BOTH modes.
2. **Anchor**: for each screen kind, Read the 1-2 closest references
   (match by suffix: `*-empty-state`, `*-hero`, `*-detail`, `*-list`).
   Ladle's set (`ladle/`) is the portfolio's shipped bar.
3. **Critique**: list violations of DESIGN.md's seven rules per screen,
   most damaging first. Name each screen's protagonist; if you can't,
   that IS the finding.
4. **Fix**: prefer surge_ui components (SurgeAtmosphere, SurgeStatTile,
   SurgeGlowOrb, SurgeFloatingNavBar) and the app's theme; never ad-hoc
   hex or one-off shadows. A composition used twice gets PROMOTED into
   surge_ui with a Catalog doc comment + `dart run tool/build_catalog.dart`.
5. **Re-render and LOOK again.** A fix you haven't seen is not a fix.

## Guardrails

- Respect the app's manifest palette + pack; you're composing, not
  rebranding. Display-font divergence is allowed with a reason (update
  `brand.fonts.display` in the manifest when you do).
- Keep the merge bar green (analyze/format/tests, goldens re-seeded).
- Screens must still match spec §6 blocks - polish never deletes states.
- Send before/after PNGs to the user at the end of the pass.
