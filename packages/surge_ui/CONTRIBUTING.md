# Contributing to surge_ui

Two ways code enters this package: a **new component** built here directly, and
a **promotion** — a pattern that proved itself in a shipping app and earns its
way in. Both end at the same checklist.

## The promotion bar (Tier 4 → Tier 2)

A pattern in an app's `lib/features/` is ready to promote when it clears **all**
of these. If it does not clear them, it stays in the app.

- [ ] **Reused or clearly reusable** — a second real use case, or an obviously
      generic pattern (not one screen's bespoke layout).
- [ ] **Token-only dependencies** — no app-specific tokens, copy, or domain
      models. App specifics become parameters/variants.
- [ ] **Domain-free** — no business logic, no Riverpod/providers, no network or
      storage. Presentational only. (Stateful for interaction like focus/press
      is fine.)
- [ ] **Generalized name** — `Surge*`, no app prefix.

## The definition-of-done checklist (new or promoted)

- [ ] Lives in `lib/src/components/<snake_case>.dart` and is exported from
      `lib/surge_ui.dart`.
- [ ] References colors/spacing/type only via `context.tokens`, `SurgeRadii`,
      `SurgeSpace`, `SurgeText` — **no hardcoded hex, no magic numbers** that
      should be tokens.
- [ ] Carries a `Catalog:` doc header (see [CATALOG.md](CATALOG.md)).
- [ ] Has a matching entry in [`catalog.json`](catalog.json).
- [ ] Has a demo in `gallery/lib/main.dart`, verified in **light and dark**.
- [ ] Has a widget test in `test/` (behavior) and/or a golden.
- [ ] `flutter analyze` is clean; `flutter test` is green.
- [ ] Adds a line to [CHANGELOG.md](CHANGELOG.md). Breaking API or a change to
      the `SurgeTokens` contract bumps the **major** version.

## The token contract is sacred

`SurgeTokens` is the interface the entire library — and every app — is built
against. Adding a field is a breaking change for the app side (every app must
supply it), so:

- Prefer composing from existing tokens over adding new ones.
- If a token is truly universal and missing, add it with a default in both
  `SurgeTokens.light` and `SurgeTokens.dark`, and bump major.
- If a color is app-specific (a domain/brand flourish), it does **not** belong
  here — it goes in the app's own `ThemeExtension`.

## Not sure if it belongs here?

Default to leaving it in the app. It is cheap to promote later once a second use
case appears; it is expensive to un-ship a too-specific component that three
apps now depend on.
