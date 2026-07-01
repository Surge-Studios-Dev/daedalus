# Catalog convention

The library is only useful if the next build can *find* the right piece before
writing custom code. Two indexes make that possible, and both must stay in sync
with the components.

## 1. The `Catalog:` doc header (in source)

Every public component class carries a structured header as the first lines of
its doc comment:

```dart
/// Catalog:
/// name: SurgeButton
/// category: buttons
/// summary: The standard text button in five variants.
/// whenToUse: Any tappable action label. Primary for the main action, ...
/// variants: primary, secondary, destructive, ghost, small
/// tags: button, cta, action, submit
class SurgeButton extends StatelessWidget { ... }
```

Fields:

| Field | Meaning |
|---|---|
| `name` | the public class name |
| `category` | one of: buttons, inputs, rows, cards, feedback, layout, navigation, media |
| `summary` | one sentence — what it renders |
| `whenToUse` | one sentence — when to choose it over an alternative or custom code |
| `variants` | named constructors / style options (optional) |
| `tags` | free-text search keywords |

Plain `Catalog:` (not a `{@directive}`) so dartdoc does not treat it as a
directive. Regular prose can follow after a blank `///` line.

## 2. `catalog.json` (the searchable index)

[`catalog.json`](catalog.json) is the machine index — one entry per component
mirroring the header, plus `since`, `import`, and `file`. **Search this first**
when deciding whether something already exists:

```bash
# is there already a search input?
grep -i search catalog.json
```

`catalog.json` is **generated**, not hand-edited — regenerate it after adding or
changing a `Catalog:` header:

```bash
dart run tool/build_catalog.dart          # rewrite catalog.json
dart run tool/build_catalog.dart --check   # CI: fail if out of date
```

The generator reads the `Catalog:` headers, computes `import`/`file`, and
preserves each component's `since` from the existing file. So the header on the
component is the single source of truth; the index can't silently drift.

## 3. The gallery (visual index)

`gallery/` renders every component in light and dark. Each new component gets a
demo there so it is visually verifiable and golden-testable.

## Keeping them in sync

When you add or change a component, update **all three**: the `Catalog:` header,
the `catalog.json` entry, and a `gallery/` demo. The [CONTRIBUTING](CONTRIBUTING.md)
checklist enforces this.
