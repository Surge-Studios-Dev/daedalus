---
name: design-pass
description: Run a reference-anchored design pass over an app's screens - render the screen board, compare against docs/design-references/ and surge_ui/DESIGN.md, fix violations, re-render until a round is clean. If no human-picked direction exists yet, run a variant tournament first. Use when screens look average, before store screenshots, or after building a new screen group.
---

# /design-pass — the taste loop

You are polishing screens against REAL references, not from memory.
Ground truth: `docs/design-references/` (Read the images) and the rules
in `packages/surge_ui/DESIGN.md`. The app's screen board is your eyes.

## Direction not set yet? Run a TOURNAMENT first

Solo iteration converged on "terrible" twice on Ember; one tournament
round fixed it. If the app has no human-picked direction (or the human
says it looks wrong), do NOT iterate in place: build 3 committed,
self-contained variants of ONE hero screen (each may break the theme -
own palette/type/content strategy), render side by side on the board,
and have the human pick. The winner's variant file becomes the living
spec; rebuild the theme + screens to it, then resume the loop below.

## The loop (2 rounds minimum, stop on a clean round)

1. **Render**: `flutter test --update-goldens test/goldens/screen_board.dart`
   in the app. Read every changed screen PNG in BOTH modes.
2. **Anchor**: for each screen kind, Read the 1-2 closest references
   (match by suffix: `*-empty-state`, `*-hero`, `*-detail`, `*-list`).
   Ladle's set (`ladle/`) is the portfolio's shipped bar.
3. **Critique**: list violations of DESIGN.md's rules per screen, most
   damaging first. Name each screen's protagonist; if you can't, that IS
   the finding.
4. **Fix**: prefer surge_ui components and the app's theme; never ad-hoc
   hex or one-off shadows outside a tournament variant. A composition
   used twice gets PROMOTED into surge_ui with a Catalog doc comment +
   `dart run tool/build_catalog.dart`.
5. **Re-render and LOOK again.** A fix you haven't seen is not a fix.

## Guardrails

- Respect the human-picked direction; you're composing, not rebranding.
  Display-font divergence updates `brand.fonts.display` in the manifest.
- Keep the merge bar green; goldens re-seeded on intentional changes.
- Screens must still match spec §6 blocks - polish never deletes states.
- Send before/after PNGs to the user at the end of every pass.
