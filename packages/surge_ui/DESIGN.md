# DESIGN.md · the taste rules

Distilled from `docs/design-references/` (moon/tides gradient-glass apps,
Ladle & RecMe's editorial paper, Giftful's dark cards). This is what a
design pass grades against. Rules, not suggestions — deviate only with a
written reason on the screen's spec block.

## The seven rules

1. **Atmosphere, never a dead fill.** Backgrounds are a wash: a vertical
   gradient of the surface ramp, plus at most one radial glow anchored to
   the screen's protagonist. `SurgeAtmosphere` does this from tokens; a
   flat `bgBase` Scaffold is a design-pass failure on hero screens.
2. **Every screen has a protagonist.** One element owns the screen — a
   glowing orb, a photo, a big numeral, an illustration. If you can't
   name the protagonist, the screen isn't designed yet. Everything else
   is supporting cast and must be visually quieter than it.
3. **Editorial type mixing.** Display serif (or the app's display face)
   for heroes, page titles, and BIG NUMBERS; the text face for everything
   else. Numbers people care about (streaks, temperatures, counts) get
   display treatment at ≥34pt — never body-size digits in a hero.
4. **Density over voids.** Facts render as tile grids (`SurgeStatTile`),
   2-up, glass panels — the moon-details pattern. Empty space is spent
   deliberately AROUND the protagonist; if a screen's bottom half is
   leftover void, promote secondary content into it or shrink the scroll.
5. **Glass, hairline, glow.** Cards are elevated panels: bgSubtle at
   slight translucency, hairline border, soft shadow; the accent appears
   as GLOW (radial, low alpha) and on protagonists — not as large flat
   fills. Flat accent is for primary buttons only.
6. **First-run is a promise, not an apology.** Empty states show the
   glowing protagonist-to-be + one line of invitation + one action
   (Giftful's illustration energy). Never a gray icon in a gray circle.
7. **Chrome floats.** Nav is the floating pill (`SurgeFloatingNavBar`);
   filters/dates are chip rows; sheets have grabbers. Nothing full-bleed
   docks to the screen edge except the atmosphere itself.

## Mechanical checks (the pass fails a screen on any of these)

- Screen title or hero number not in the display face.
- More than one radial glow per screen, or glow alpha > 0.35.
- A hero screen on flat `bgBase` with no atmosphere.
- Any accent-filled region larger than a button that isn't the paywall CTA.
- Bottom half of a non-list screen >70% empty at 393×852 with fixtures.
- An empty state without a lit protagonist.

## How to run a pass

Render the screen board with fixtures, Read the PNGs NEXT TO the two
closest references from `docs/design-references/`, list rule violations,
fix, re-render. Two rounds minimum; stop when a round produces no new
violations. Promote any composition used twice into surge_ui.
