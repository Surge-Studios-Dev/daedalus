# Changelog

## 0.3.0

Finishing the Ladle harvest — the last universal pieces.

- `SurgeBadge` (generalizes Ladle's PlusChip/SaveChip into semantic status pills).
- `SurgeMagicCta` — the animated AI/auto option pill.
- `SurgeLoadingLabel` — hopping-dots wait affordance.
- `SurgePlaceholder` — hatched image placeholder.
- `SurgeToast` + `showSurgeToast` + `dismissCurrentSurgeToast` — overlay toasts.
- `showSurgeActionMenu` + `SurgeActionMenuItem` — context menu as a sheet.
- catalog.json + gallery updated; 28 components indexed.
- Skipped (domain, stayed in Ladle): falling-ladle loading, macro bars, recipe/
  quantity widgets, wordmark.

## 0.2.0

Second harvest from Ladle — selection, chips, feedback, and overlays.

- Chips: `SurgeFilterChip`, `SurgeTagChip`.
- Selection: `SurgeToggle`, `SurgeSegmented`, `SurgeStepper` (+ `surgeStepValue`).
- Feedback: `SurgeSpinner`, `SurgeBanner` (+ `SurgeBannerKind`),
  `SurgeProgressBar`, `SurgeIndeterminateBar`, `SurgeSkeleton`,
  `SurgeEmptyState`.
- Overlays: `SurgeSheet` (+ `SurgeSheetDetent`), `showSurgeSheet`,
  `showSurgeConfirm`.
- App-specific dependencies dropped on the way in: Ladle's `Haptics` →
  `HapticFeedback`, lucide icons → Material icons.
- catalog.json + gallery updated for all of the above.

## 0.1.0

First slice, extracted and generalized from Ladle.

- `SurgeTokens` universal token contract with neutral light/dark defaults;
  `SurgeRadii`, `SurgeSpace`, `context.tokens`.
- `SurgeText` type scale + `.tnum` tabular figures.
- `buildSurgeTheme()` theme builder (palette + font family overridable).
- Components: `SurgeButton` (primary/secondary/destructive/ghost/small),
  `SurgeIconButton`, `SurgeTextField`, `SurgeSearchField`, `SurgeIconTile`,
  `SurgeListRow`, `SurgeGroupSection`, `SurgeGroupRow`, `SurgeCard`,
  `SurgeActionCard`, `SurgePressable`.
- `catalog.json` machine index + `gallery/` visual catalog.
- Widget tests covering button behavior, input changes, toggle rows, and
  dark-theme rendering.
