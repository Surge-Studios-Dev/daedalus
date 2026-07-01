# FRAMEWORK.md · Surge shared app framework

How the reusable layer of every Surge app is structured, so it can be
**stamped blank, filled by modular systems, and grown over time** without each
app re-deriving plumbing. This is the architecture decision record; the code
lives in [`packages/surge_ui/`](packages/surge_ui/) and (later) the brick.

## The four tiers

Everything in an app belongs to exactly one tier. The boundary between them is
what keeps the shared layers shareable.

| Tier | What it is | Where it lives | The rule that keeps it clean |
|---|---|---|---|
| **1. Foundation** | The blank canvas: an app that compiles and runs with the universal essentials wired but empty (auth sign in/up, tab shell + blank home + toolbar, settings stack, paywall/gate, theming). | generated per app (the brick's `__brick__/lib/app` + `modules/`) | wired + runs + does nothing |
| **2. Components** (`surge_ui`) | Stateless, presentational widgets: buttons, inputs, rows, cards, chips, sheets, empty/loading/error states. | `packages/surge_ui` | **token-only dependencies, zero domain logic, zero state management** |
| **3. Systems** | Drop-in *features*, not widgets: an onboarding flow, paywall variants, a list→detail→edit CRUD pattern, image picker, search-with-filters. Composed of Tier-2 components plus some state. | `packages/surge_*` (one package per system) | swappable and self-contained; plugs into the foundation through a documented seam |
| **4. Custom** | Per-app, differentiated code. | the app's `lib/features/` | free-form, with a promotion path back up to Tier 2/3 |

The value ladder: a component saves minutes; a **system** saves days. Tier 3 is
the highest-leverage tier and the least specified today — define each system
deliberately, do not let it emerge from copy-paste.

## The token contract (the thing everything depends on)

A shared component can only be shared if it depends on tokens guaranteed to
exist in *every* app. So the token layer is split:

- **`SurgeTokens`** — the **frozen, universal contract**. A fixed set of
  semantic tokens (bg / ink / line / accent / status + radii + spacing +
  shadows + type scale). Tier 2 and Tier 3 may reference **only** these.
  Values are theme- and manifest-driven; the *interface* does not change
  without a major version.
- **Per-app token extension** — domain colors (Ladle's `macroProtein`,
  `accentCompanion`, etc.) live in a separate `ThemeExtension` that the app
  owns. The shared library never references it.

This is the single most important boundary in the framework. Ladle's
[`ladle_tokens.dart`](../Ladle/app/lib/ui/tokens/ladle_tokens.dart) mixes both
kinds together; `SurgeTokens` is the universal subset extracted from it.

## Why the library is its own package (not brick source)

A component library that only exists as Mason template files (`__brick__`, full
of `{{mustache}}`) cannot be compiled, tested, rendered in a gallery, or
searched — so it cannot grow. Therefore:

- `surge_ui` is a **real, compilable Flutter package** with its own tests and
  gallery. It is the source of truth for discovery.
- Components depend on the token **interface**, not literal hex values, so the
  library is plain Dart. Only the token **values** file is per-app.

## Distribution: hybrid

- **Default:** apps depend on `surge_ui` (and each `surge_*` system) as a
  versioned package. The toolbox grows → apps pick it up on the next upgrade →
  a fix propagates once. Semver governs breaking changes.
- **Escape hatch:** an app that must fork can vendor a package's source. It
  keeps the "killable = delete a repo" property for the rare app that needs it.

Either way, discovery always happens against the canonical package + its
gallery.

## Discovery: two indexes

The library is only useful if the next build can *find* the right piece before
writing custom code.

1. **Gallery (human index)** — a Flutter app under `packages/surge_ui/gallery`
   (dependency-free today; can migrate to [Widgetbook](https://widgetbook.io)
   for knobs later). Every component has a demo, renders in light + dark via a
   theme toggle, and is the target for golden tests. Grows as components are
   added.
2. **Catalog (machine index)** — [`catalog.json`](packages/surge_ui/catalog.json),
   one entry per component: `name, category, tags, variants, since, summary,
   whenToUse, import`. This is what an agent (or future-you) searches to answer
   "is there already a component for X?" See
   [`CATALOG.md`](packages/surge_ui/CATALOG.md) for the convention.

Every component also carries a structured doc header (`{@component ...}`) so the
two indexes can eventually be generated from source.

## The fill workflow

```
stamp Foundation (blank, runs)
      │
      ▼
drop in Systems (Tier 3)  ── search catalog first ──┐
      │                                             │
      ▼                                             │
compose from Components (Tier 2) ───────────────────┤
      │                                             │
      ▼                                             │
write Custom (Tier 4) only in the gaps              │
      │                                             │
      └──── promote reusable custom back up ────────┘
```

## Promotion (Tier 4 → Tier 2/3)

Custom code earns its way into the shared library when it clears this bar:

- **Used, or clearly reusable, beyond one app** (a second real use case, or an
  obviously generic pattern).
- **Token-only dependencies** — no app-specific tokens, copy, or domain models.
- **Generalized API** — app specifics become parameters/variants.
- **Documented** — `{@component}` header + a `catalog.json` entry.
- **Demonstrated** — a Widgetbook use-case in light + dark.
- **Tested** — widget test and/or golden.
- **Versioned** — a changelog entry; breaking changes bump major.

If it clears the bar it lands in `surge_ui` (component) or a `surge_*` package
(system) and every app gets it on the next upgrade. If it does not, it stays in
the app.

## Naming

Neutral namespace, no per-app prefixes: `Surge*` types, `surge_*` files and
packages. (Ladle's `L`/`Ladle` prefixes are dropped on the way in.)
