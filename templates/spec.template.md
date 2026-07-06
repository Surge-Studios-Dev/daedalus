# {{APP NAME}} · Product Spec
**Version 0.1 · {{date}} · Status: draft**

<!--
This is the Surge spec template, modeled on Ladle's original-spec.md (the spec
that shipped). Generate the data-filled skeleton with:

    cd tools/spec_gen && dart run bin/spec_gen.dart path/to/surge.manifest.yaml

then write the TODO sections. The generator fills everything derivable from
the manifest (tabs, screens, gates, monetization, compliance); a human writes
product intent. Keep this file at design/spec.md in the app repo; it is the
source of truth the per-app CLAUDE.md points at.

Rules that made this format work:
- Every screen has a stable ID (LIB-01). If a screen isn't listed, it doesn't
  exist. IDs go in doc comments, commit messages, and test names.
- Phase tags on every feature: [P0] = must ship v1, [P1] = fast follow,
  [P2] = later surface area. Spec all phases now; build in order.
- Section 8 edge cases are acceptance criteria, not suggestions - each one
  becomes a test.
- Copy strings in quotes are final unless marked (draft).
-->

## 0. How to read this document

- Every screen appears in Section 6 with a unique ID. If it is not listed, it
  does not exist.
- Phase tags: **[P0]** launch build, **[P1]** fast follow, **[P2]** later.
- Color/type references use surge_ui token and style names, never raw hex.
- Section 8 is the QA checklist: every line is an acceptance criterion.
- This is a **living document with as-built deviations**: when implementation
  changes a decision, add a numbered footnote at the affected spot
  (`> **Deviation N (date):** what changed and why`) instead of rewriting
  history. The spec stays true without pretending it predicted everything.

## 1. Product overview

- **One-liner:** <!-- the tagline-grade sentence; what + for whom + the hook -->
- **Positioning rule:** <!-- ONE sentence that governs disputed design calls.
  Ladle's: "reads as a clean recipe keeper; the macro layer is invisible until
  opted in." Write the rule you'll quote in every review. -->
- **The core loop:** <!-- A -> B -> C -> state compounds. Design for this above
  all; if a screen doesn't serve the loop, question it. -->
- **The quality bar:** <!-- the ONE behavior that must be flawless because
  every incumbent fails it. Ladle's: grocery list never drifts from the plan. -->
- **Platforms:** iOS first, Flutter. Design at 393x852; verify 375x667 and
  430x932. Android follows with platform back gestures.

## 2. Design language

Provided by **surge_ui** (tokens, type scale, spacing, radii, components) and
themed from the manifest palette - do not respecify it here. This section
covers only what this app adds:

- **Domain tokens:** <!-- extra semantic colors beyond SurgeTokens, e.g.
  Ladle's macro.protein/carbs/fat. Each needs light+dark values and a usage
  rule. "None" is a fine answer. -->
- **Signature moment:** <!-- the ONE place motion shows off (Ladle: the import
  assemble). Everything else uses stock surge_ui motion. -->
- **New components:** <!-- anything not in surge_ui/catalog.json. Check the
  catalog first; if it's reusable, it goes INTO surge_ui, not the app. -->

## 3. Information architecture

### 3.1 Tab map
<!-- generated from navigation.tabs -->

### 3.2 Screen inventory
<!-- generated: the factory screens (SYS/ONB/AUTH/PAY/SET) pre-listed, one
root screen seeded per feature tab. Add every additional screen here WITH an
ID before speccing it in Section 6. -->

### 3.3 Deep links
<!-- {{slug}}://... scheme. Paywall links carry ?src={gateId}. Every push
notification deep-links. -->

## 4. Global behaviors

### 4.1 Free tier definition
<!-- What free includes, stated as a list. Write this BEFORE the gate table:
the free tier is the product most users experience. -->

### 4.2 Gating table
<!-- generated from monetization.gates. Standard behavior: gated features are
always visible, marked with the Plus-style chip, tap opens the paywall with
?src={gateId}, user returns to exactly where they were on dismiss. Never
disabled-gray, never hidden. Fill in the trigger point per gate. -->

### 4.3 Monetization mechanics
<!-- generated from monetization: model, products, trial. Add: meter mechanics
if any (Ladle's 5 imports/week), what happens at the limit, reset rules. -->

### 4.4 Offline & sync stance
<!-- Local-first? Which surfaces work offline? Conflict rules (last-write-wins
per field is the factory default). What queues, what requires network. -->

### 4.5 Error taxonomy
Factory standard copy applies (offline banner, server-error toast + retry,
auth-expired modal, purchase-fail inline). <!-- Add domain error classes only. -->

## 5. Copy & tone

Factory rules: sentence case everywhere; the verb on a button matches its
toast and menu item; numerals always; no em dashes in user-facing copy; empty
states invite action, never apologize; errors state what happened + next step.

- **Banned vocabulary:** <!-- domain-specific. Ladle banned diet-culture words.
  What words would betray this product's values? -->
- **Voice notes:** <!-- 2-3 lines max. -->

## 6. Screen-by-screen specification

Format per screen - keep this discipline:
**Purpose** (one line) · **Layout** (top->bottom) · **Interactions** (every
tappable element and what it does) · **States** (loading / empty / error /
edge) · **Navigation** (in and out).

<!-- generated: factory screens listed with "provided by foundation" notes
(customize copy only); each feature tab gets a seeded root-screen block with
the format headers ready to fill. Every screen in 3.2 gets a block here. -->

## 7. Notifications

<!-- generated if features.notifications. Table: ID / type / trigger / default
timing / copy / deep link. Factory rules: max 1 reminder-class per day, quiet
hours, transactional exempt, every push deep-links, no guilt or streak
language. Delete this section if notifications are off in v1. -->

## 8. Edge-case master list (QA checklist)

<!-- Every line here becomes a test. Group by feature area. The factory
already covers its own: auth state transitions, purchase restore/cancel,
onboarding re-entry, offline persistence. List the DOMAIN edges: the weird
inputs, the concurrent edits, the empty-then-full transitions, the deleted-
thing-still-referenced cases. Aim for 5+ per feature tab; if you can't name 5,
the feature isn't specced yet. -->

## 9. Brand

<!-- generated from manifest: name, tagline, palette, fonts, logo mode. Add:
app icon description, marketing screenshot plan (frame 1 = the signature
moment). -->

## 10. Intentionally out of scope (do not design)

<!-- The features you are deliberately NOT building, so nobody designs around
their future existence. Ladle: no social feed, no expiration tracking, no
gamification. Be specific; this list prevents scope creep better than any
process. -->

## 11. Open questions

<!-- Only questions that block a P0 decision. Everything else in this document
is decided once the status line says "final". -->
