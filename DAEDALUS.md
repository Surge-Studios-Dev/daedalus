# DAEDALUS.md · Surge App Template ("base")

The launch-ready Flutter starter every Surge app is stamped from. Universal infrastructure (auth, nav, settings, paywall, telemetry, cross-promo) ships filled-in and working. Domain screens ship as wired stubs. One `surge.manifest.yaml` drives the app, its marketing page, and its store metadata. See `surge.manifest.schema.md` for that file.

> **Implementation status (current).** This document is the design contract; some
> of it is now built and some is still aspirational. What exists and is verified:
> the shared UI toolbox lives in the external **`packages/surge_ui`** package
> (Tier 2), not in-app `modules/ui`; the blank canvas is **`foundation/`** (Tier 1);
> the **`bricks/daedalus`** brick stamps the canvas + consumes `surge_ui` from the
> manifest (a stamped app analyzes clean). Deltas from the text below: the base
> ships **Riverpod without codegen**; **Firebase and RevenueCat are working mocks**
> marked `SEAM:` (uncomment the deps to wire them), not yet live; gating is
> **`ref.gate(context, gateId, onSuccess)`**. The growth rail is built and
> stamped: **`packages/surge_share`** (client), the brick backend's
> `sharing/` callables + `shareLink` unfurl endpoint, hosting deep-link
> templates, the foundation invite card, and the `notify/` ops triggers —
> all on mocks/placeholders until forge's share-links checklist is run.
> See `FRAMEWORK.md` for the tier model, token contract, and
> component-library conventions, and `SHARING.md` for the growth rail.

## What "launchable" means

- A freshly stamped app **runs on a simulator immediately**, with working auth, navigation, theming, the full settings stack, and a functioning paywall.
- It **ships to the stores after exactly two steps**: (1) run `scripts/forge.sh` to provision per-app config and secrets, (2) replace the `features/` stubs with real, differentiated functionality.
- It is **not shippable as bare stubs.** Apple rejects empty shells under the minimum-functionality rule (the same 4.3 family that threatens this whole model). The template is the plumbing, never the product. The 1 to 2 week clock is "from stamp to a real reviewable product"; the template buys back the week of plumbing.

## Stack (decided; inherited from Ladle, do not relitigate)

- Flutter stable, Dart 3.x. iOS is the polish target; Android must compile.
- State: **Riverpod** (`flutter_riverpod` + codegen). One Notifier per domain. Derived data is computed providers, never stored.
- Navigation: **go_router**. Tab stacks plus root-level presented routes (auth, paywall, settings, onboarding). Tapping the active tab pops to root.
- Models: **freezed** + json_serializable.
- Backend: **Firebase**. Auth, Firestore (offline persistence), Functions, Crashlytics, Analytics, Remote Config.
- Purchases: **RevenueCat** (`purchases_flutter`).
- Local-only state: `shared_preferences`.
- Type: a bundled variable font with `FontFeature.tabularFigures()` on every numeral. `lucide_icons`.

## Repo layout (brick-first, self-contained, internally modular)

```
my_app/
  surge.manifest.yaml        # single source of truth
  lib/
    main.dart
    app/                     # bootstrap, router, theme wiring
      bootstrap.dart
      router.dart
      app.dart
    modules/                 # UNIVERSAL. isolated so it can be lifted into
      auth/                  # versioned packages once propagation pain is real
      paywall/               # RevenueCat + gate()
      settings/              # account, contact, faq, legal, delete account
      telemetry/             # crashlytics + analytics + event taxonomy
      crosspromo/            # house-ads slot
      ui/
        tokens/
        components/
    features/                # PER-APP STUBS (the 20%)
      home/
      <feature>/
    core/                    # per-app pure Dart (tested)
    models/                  # per-app freezed
  assets/
  android/  ios/  web/
  scripts/
    forge.sh
  CLAUDE.md                  # generated per app from a base + the manifest
  MILESTONES.md
```

The split is the whole point. `modules/` is universal and quarantined; `features/` is the per-app stub layer. Until you run 3+ live apps and feel "I fixed auth once and now have to fix it in five places," each stamped app stays a standalone repo: independently buildable, shippable, and **killable** (killing an app is deleting a repo, with no dependency graph to untangle). When that pain arrives, lifting `modules/` into Melos packages is a move, not a rewrite, because it already lives behind clean folder boundaries.

## The manifest

`surge.manifest.yaml` at the repo root is the single source of truth. It feeds four consumers: the app (flavor, theme, nav, auth, monetization, feature toggles), the Next.js portfolio and marketing page, the store listing metadata, and `forge.sh`. **Never hardcode anything the manifest can carry.** Schema and examples live in `surge.manifest.schema.md`.

## Filled in and functional

- **Auth** (`modules/auth`): email, Apple, Google sign-in/up; password reset; email verification; auth-state redirect routing; guest mode when `auth.guest_mode: true`. Sign in with Apple is always offered whenever any social provider is enabled.
- **Nav and shell** (`app/`): tabs built from `navigation.tabs`; presented-route scaffolding; theme (light/dark/system) with the appearance setting wired.
- **Settings stack** (`modules/settings`): Settings, Account (email, change password, sign out, **delete account**), Manage Subscription, Contact/Support, FAQ, Legal (Privacy + Terms rendered from per-app markdown), Notifications toggle, version/build.
- **Monetization** (`modules/paywall`): paywall, RevenueCat wiring, the `gate()` helper, restore purchases. Model-agnostic (see below).
- **Telemetry** (`modules/telemetry`): Crashlytics + Analytics with the standard event taxonomy.
- **Sharing + referrals** (the growth rail — `packages/surge_share`, contract in `SHARING.md`): the referral/invite loop is **default-on in every app** (invite link → both sides earn entitlement-credit days; needs zero domain knowledge because every app has the single entitlement); content sharing (self-hosted share links, branded unfurl cards) turns on when the manifest declares `sharing.content`. Word of mouth is the acquisition plan, so this is universal infrastructure, not a feature.
- **Ops notifications** (`backend/src/notify/`): Discord embeds for installs (auth-creation proxy), purchases (RevenueCat webhook; auth fails closed), and support requests (Firestore trigger). Best-effort, never throw; dormant until the functions `.env` webhook URLs are set — no manifest field.
- **Cross-promo** (`modules/crosspromo`): a house-ads slot, wired from app #1 so the portfolio becomes its own acquisition channel. Referrals rank ahead of it: they generate acquisition from app #1, while cross-promo only matters at 2+ live apps.
- **UI** (external `packages/surge_ui`): the token contract plus the generic component library (buttons, chips, inputs, rows, sheets, toasts, banners, stepper, segmented, toggle, progress, spinner) and loading/empty/error states. Apps depend on it; see `FRAMEWORK.md` and `packages/surge_ui/CATALOG.md`.
- **App identity**: launcher icon and splash generated from the `brand` block.

## Stubbed (per app)

- `features/<tab>`: a placeholder body, wired into nav and theme so the app runs and navigates. No domain logic.
- `core/`, `models/`: empty scaffolding.
- `primary_action`: stub.

The contract: a stamped app analyzes clean and runs. It simply does nothing useful yet.

## Monetization model (all apps monetized; structure varies)

Every app gates paid value behind a **single RevenueCat entitlement** (default id `pro`). `ref.gate(context, gateId, onSuccess)` checks that entitlement and behaves identically whether it was granted by a subscription or a one-time unlock. `monetization.model` selects the shape:

- **subscription**: auto-renewing products. Free trial is the store intro offer (`trial.type: store_intro_offer`; `duration_days` maps to the intro period).
- **one_time**: a non-consumable unlock. The "trial" is enforced in-app as a usage/time window (`trial.type: app_gated`; `duration_days` counted from first launch, stored locally and mirrored to Remote Config so it is tunable after launch without a release).
- **hybrid**: both offered on the paywall; the entitlement is still single.

Restore purchases is mandatory and always present. Reference prices in the manifest are for marketing and docs only; real prices live in App Store Connect, Play Console, and RevenueCat.

## Telemetry taxonomy (identical across every app)

Standard events, so the portfolio dashboard works with zero per-app wiring: `app_open`, `screen_view{screen}`, `sign_up{method}`, `login{method}`, `onboarding_complete`, `paywall_view{source}`, `trial_start`, `purchase{product,price}`, `restore`, `cancel_intent`, `gate_blocked{gate}`, `crosspromo_tap{target}`, and the growth-rail set `share_create{type}`, `share_open{source}`, `share_save{type}`, `referral_redeem`, `reward_grant{days}`, `invite_view` (these make viral coefficient a portfolio metric). Apps add domain events on top. Never rename these.

## Conventions (inherited from Ladle)

- **snake_case filenames** (not take_off's PascalCase).
- Tokens via a single `ThemeExtension`; **never hardcode a hex in a widget.**
- Components live in `modules/ui/components`; screens compose components and never define one-off styling.
- Copy: sentence case; button verb = toast verb = menu verb; no dark-pattern or manipulative language; **no em dashes in user-facing copy.**
- Every screen widget carries its id in a doc comment.
- **Every awaited mutation in UI catches and surfaces failure** (toast or
  inline notice), and the success toast fires only after the await returns.
  A bare `await repo.upsert(...)` in a sheet dies silently in release when
  rules/network deny it - the user sees nothing and reports "the feature
  doesn't work" (Ember lesson, 2026-07-08). The same button also
  **busy-guards**: disabled + loading while the await is in flight, or a
  double-tap races two writes (Ember created the same group twice, 500ms
  apart, in prod).
- **"Offline" means a network error, nothing else.** Classify before
  claiming: SocketException/TimeoutException and Firebase codes
  network-request-failed/unavailable/retry-limit-exceeded are offline;
  everything else (permission-denied, unauthorized, config) surfaces as an
  error AND goes to the error reporter. A catch-all offline toast told a
  user on cellular they were offline while a missing IAM grant denied
  every upload (Ember lesson, 2026-07-08).
- Anything touching more than one file: present a plan before writing code. New packages must be justified against the stack above.

## Compliance baked in (the mandatory-boring set)

These get apps rejected, not features, so the base ships them working: in-app **account deletion**; **Sign in with Apple** alongside social logins; **restore purchases**; **Privacy + Terms** (URL and in-app screens); the **ATT prompt** when `data_practices.tracking` is true; a store-required support URL. Store requirements drift, so verify against current guidelines before each submission.

## Init step (`scripts/forge.sh` plus a manual checklist)

Automated: read the manifest; set bundle id / package and flavor; run `flutterfire configure` against the named Firebase project; generate launcher icon and splash; draft Privacy and Terms from the `legal` block; generate the per-app `CLAUDE.md` from the base plus the manifest.

Manual (the script prints this checklist): create App Store Connect and Play Console records; configure the RevenueCat app, entitlement, and products; set up signing (Fastlane match or Codemagic); paste secrets into CI (never the repo).

## Definition of done

- **Template**: a freshly stamped app analyzes clean, runs on iOS and Android, signs a user in three ways, shows a paywall that completes a sandbox purchase and a restore, deletes an account, and reports the standard events. The `packages/surge_ui/gallery` app renders every UI component in light and dark.
- **App from template**: stubs replaced with real functionality, manifest filled, init run, compliance checklist green.

## Out of scope (wire the seam, do not build it here)

Push campaigns, A/B infrastructure beyond Remote Config flags, ad-network SDKs beyond cross-promo, and any server-side analytics warehouse. The base provides the hooks; the build-out happens elsewhere.

---

## Changelog

Meaning changes only, newest first, one line each.

- 2026-07-20 — changelog + verification footer added (doc drift guard, spec-kit lesson 7).

*Verified against code: 2026-07-20*
