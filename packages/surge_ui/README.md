# surge_ui

The Surge Studios shared UI toolbox: the **token contract**, the **theme
builder**, and the **presentational component library** every Surge app composes
from. This is Tier 2 in [`../../FRAMEWORK.md`](../../FRAMEWORK.md).

Components depend only on `SurgeTokens`. They carry **no domain logic and no
state management** — that is what makes them reusable across every app.

## Use it

```yaml
# app pubspec.yaml
dependencies:
  surge_ui:
    path: ../packages/surge_ui   # or a git/hosted ref once published
```

```dart
import 'package:surge_ui/surge_ui.dart';

MaterialApp(
  theme: buildSurgeTheme(Brightness.light),
  darkTheme: buildSurgeTheme(Brightness.dark),
  home: Scaffold(
    body: Center(
      child: SurgeButton.primary('Get started', onPressed: () {}),
    ),
  ),
);
```

Override the palette per app (values usually come from `surge.manifest.yaml`):

```dart
buildSurgeTheme(
  Brightness.light,
  tokens: SurgeTokens.light.copyWith(accentBase: const Color(0xFF1F4D3B)),
  fontFamily: 'Inter',
);
```

## Find a component

- **Browse:** run the gallery — `cd gallery && flutter run` — every component in
  light and dark with a theme toggle.
- **Search:** [`catalog.json`](catalog.json) is the machine index. Grep it for a
  tag or read `whenToUse` to decide between a component and custom code. Always
  search here **before** writing new UI.

## What's inside

| File | Contents |
|---|---|
| `lib/src/tokens/surge_tokens.dart` | `SurgeTokens` contract, neutral light/dark defaults, `SurgeRadii`, `SurgeSpace`, `context.tokens` |
| `lib/src/tokens/surge_text.dart` | `SurgeText` type scale, `.tnum` tabular figures |
| `lib/src/theme/surge_theme.dart` | `buildSurgeTheme()` |
| `lib/src/components/` | the components (buttons, inputs, rows, cards) |
| `catalog.json` | searchable machine index |
| `gallery/` | visual catalog app |

## Rules

- **Never hardcode a hex in a component.** Use `context.tokens`.
- **Token-only dependencies.** No app tokens, no domain models, no Riverpod.
- Every public component carries a `Catalog:` doc header and a `catalog.json`
  entry (see [CATALOG.md](CATALOG.md)).
- Adding or promoting a component follows [CONTRIBUTING.md](CONTRIBUTING.md).

## Status

v0.3.0 — the token contract, theme, and the harvested Ladle component set:
buttons (+ magic CTA), inputs, rows, cards, chips, badges, selection (toggle,
segmented, stepper), feedback (spinner, banner, progress, skeleton, loading
label, empty state), media placeholder, and overlays (sheet, confirm, toast,
action menu). 28 components, indexed in `catalog.json` and demoed in `gallery/`.
Analyzes clean; covered by widget tests. Grows as patterns are promoted out of
shipping apps.
