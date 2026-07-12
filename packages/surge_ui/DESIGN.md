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
7. **Chrome floats - and the toolbar IS Ladle's toolbar.** Nav is
   `SurgeFloatingNavBar`, which mirrors Ladle's shipped bar verbatim:
   64-high opaque bgBase pill, radius 32, hairline + lift shadow,
   icon-over-10pt-caption tabs (accentBase active / inkTertiary idle),
   and the center action as a 60px accent circle RAISED 18px above the
   bar with a 3px bgBase ring. Do not redesign it per app - two
   attempts (labeled bud-in-row, then wordless glass) both lost to
   Ladle's bar in situ (2026-07-08); the raised ring is what reads
   "crisp". An even number of slots reads uneven: tabs + raised center
   should total an ODD visual rhythm (2 tabs + action, 4 tabs +
   action). Filters/dates are chip rows; sheets have grabbers. Nothing
   full-bleed docks to the screen edge except the atmosphere itself.

## Rule 8 (added after Ember's coral relapse; amended after Ember's monochrome overcorrection)

**Chrome is neutral; color belongs to the protagonist - and the
protagonist MOVES.** Warm accents on warm/cream grounds recreate the
banned tomato-coral-on-warm-paper family no matter which hex you picked.
Crisp = white/near-white ground, ink chrome (bars, links, secondary
controls), hairlines, and the app's ONE thematic color reserved for its
living element (Ember: the flame), which carries a signature animation.
Static theming cannot express a fire theme; motion is part of identity,
not polish.

**Amendment (2026-07-08): neutral chrome never means a monochrome app.**
The first Ember pass read this rule literally and set light-mode
`accentBase` to ink - every CTA went near-black and the user's verdict
was "the design is essentially all white and black." Rule 8 constrains
WHERE color goes, never WHETHER the brand exists:

- `accentBase` stays the brand accent in BOTH modes. When the manifest
  accent can't carry white text on a white ground (Ember's #FFA85C),
  use the manifest's `accent_soft` - that deepened variant exists for
  exactly this - not ink.
- The primary button is the protagonist of any screen whose job is the
  action (rule 5 already says flat accent is for primary buttons ONLY;
  rule 8 does not overrule it - the two compose: accent buttons on
  neutral chrome).
- "Banned family" means warm-on-warm GROUNDS and large flat warm fills.
  A deepened brand accent on a white ground is the crisp look working,
  not a relapse.

## Mechanical checks (the pass fails a screen on any of these)

- Screen title or hero number not in the display face.
- More than one radial glow per screen, or glow alpha > 0.35.
- A hero screen on flat `bgBase` with no atmosphere.
- Any accent-filled region larger than a button that isn't the paywall CTA.
- A warm accent (red-orange-amber) on a warm/cream ground - the banned
  family, however derived.
- `accentBase` equal (or near-equal) to an ink/neutral in ANY mode - the
  app reads black-and-white; the brand accent (or its contrast-deepened
  `accent_soft`) must survive in both light and dark.
- A primary-action or tab icon that is a generic default (zap, star,
  circle) instead of the app's own motif from the manifest.
- An OAuth provider button restyled with app theming. Apple and Google
  fix how their buttons look (Apple: black + real Apple glyph; Google:
  white in both modes + multi-color G) - use the stamped
  `modules/auth/oauth_buttons.dart`, never a themed `SurgeButton` with
  `Icons.g_mobiledata` (the canonical wrong version, caught on Ember;
  Ladle's shipped implementation is the source).
- A "living element" (flame, moon, pulse) rendered with zero motion in
  the running app.
- Content inside the floating bar's NOTHING ZONE - the bar, the raised
  action's headroom, AND the clearance strip slightly above the flame's
  tip (`SurgeFloatingNavBar.clearance`). The bar's layout box includes
  all three, so the ambient MediaQuery inset covers the whole zone - but
  an explicit `padding:` on a screen-level scrollable silently DISCARDS
  that inset. Use `surgeScrollPadding(context, ...)` instead of
  `EdgeInsets.all/fromLTRB` on every screen-level ListView/SliverPadding
  (Ember, 2026-07-08: the flame's tip sat on the last row of every
  pushed screen), and never hand-position a fixed widget (bottom CTA,
  FAB, footer, badge) into the zone - flush contact with the flame tip
  counts as overlap (Ember, 2026-07-09: new screens kept parking
  widgets right on the tip). The atmosphere, section groups, and
  scrolling content passing BENEATH the bar are fine - fixed foreground
  widgets are not.
- Bottom half of a non-list screen >70% empty at 393×852 with fixtures.
- An empty state without a lit protagonist.

## How to run a pass

Render the screen board with fixtures, Read the PNGs NEXT TO the two
closest references from `docs/design-references/`, list rule violations,
fix, re-render. Two rounds minimum; stop when a round produces no new
violations. Promote any composition used twice into surge_ui.
