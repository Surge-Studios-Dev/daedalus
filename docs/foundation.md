# Foundation: the blank canvas

*Part of the [Daedalus wiki](README.md) · related:
[Architecture](architecture.md), [Brick](brick.md), [surge_ui](surge-ui.md)*

`foundation/` is Tier 1: a **runnable** app with every universal concern
already working on mock seams — sign-in/up, guest mode, onboarding, tab
shell, paywall + gates, settings stack, telemetry, persistence, ratings, and
a CRUD reference feature. It is the source of truth the
[brick](brick.md) mirrors. 11 widget tests keep it honest.

## Module map

```mermaid
flowchart TB
    subgraph lib["foundation/lib"]
        subgraph appd["app/"]
            boot["bootstrap.dart<br/>🎛️ ALL seam flips live here"]
            router["router.dart<br/>redirect state machine"]
            approot["app.dart — theme from tokens"]
        end
        subgraph modules["modules/ (universal — never fork per feature)"]
            auth["auth/ — service seam,<br/>controller, sign in/up screens"]
            onbm["onboarding/ — controller persists flag,<br/>screen wraps surge_onboarding"]
            pay["paywall/ — PurchaseService seam,<br/>entitlement, gate(), paywall screen"]
            set["settings/ — settings · account ·<br/>legal · appearance · rate-this-app"]
            tel["telemetry/ — Ev taxonomy,<br/>Analytics + ErrorReporter seams"]
            store["storage/ — KeyValueStore seam"]
            rat["rating/ — RatingService seam"]
            shell["shell/ — TabShell bottom bar"]
        end
        subgraph features["features/ (Tier 4 — the part you replace)"]
            home["home/ — blank wired canvas<br/>+ gate demo"]
            notes["notes/ — 📚 CRUD reference<br/>(foundation-only, not stamped)"]
        end
    end
    boot -->|overrides| auth & pay & tel & store & rat
    router --> shell
    features --> modules
```

## The routing state machine

`router.dart` redirects on two watched providers — auth state and the
persisted onboarding flag. Order matters: **sign-in → onboarding → app.**

```mermaid
stateDiagram-v2
    [*] --> SignedOut
    SignedOut --> SignIn : any route redirects to /signin
    SignIn --> SignUp : create account (email)
    SignUp --> SignIn : back
    SignIn --> Onboarding : signed in or guest, not yet onboarded
    SignIn --> Shell : signed in or guest, already onboarded
    Onboarding --> Shell : finish or skip - flag persisted to KeyValueStore
    state Shell {
        [*] --> Home
        Home --> You : tab
        You --> Home : tab
    }
    Shell --> Paywall : gate() while locked, source=gateId
    Paywall --> Shell : purchase or dismiss
    Shell --> Account : /account
    Shell --> Legal : /legal/privacy and /legal/terms
    Shell --> Notes : /notes (reference feature)
    Account --> SignedOut : sign out / delete account
```

Subtleties the tests pin down:

- **Guest is an app-level state**, not an auth account. The auth controller
  never knocks a guest back to `signedOut` when the backend reports no user.
- **Onboarding is persistence-driven**: seeding the key-value store with
  `onboarding_complete: true` skips onboarding with *no* controller override
  — proving the flag, not the controller, owns the flow.
- **Backend swaps drive the app**: binding a fake signed-in `AuthService`
  boots straight to Home; binding an unlocked `PurchaseService` makes
  `gate()` run its action instead of presenting the paywall.

## What each screen ships as

| Screen | State on day 0 | Customize |
|---|---|---|
| Sign in / up | Working (mock): email fields, Apple/Google buttons per manifest, guest mode | Copy + which buttons (manifest) |
| Onboarding | surge_onboarding data-driven flow, logs `Ev.onboardingComplete` | Page content (Tier 3 config) |
| Home | Blank wired canvas + gate demo (stamped apps: one themed stub per feature tab) | Replace entirely (Tier 4) |
| Paywall | Trial-aware CTA from manifest, purchase/restore against the seam | Headlines per gate (spec §6) |
| Settings | Account, subscription, appearance cycle, rate-this-app, support, legal, version | Add app rows as deltas |
| Account | Email display, sign out, delete-account with confirm dialogs | Usually nothing |
| Legal | Renders privacy/terms | Nothing (generated content) |
| Notes (foundation only) | `NTS-01` — the CrudRepository reference: add/delete over the seam, in-memory → per-user Firestore | Read it, copy the pattern, build your own |

## The notes reference feature (how Tier-3 data plumbing looks)

```mermaid
sequenceDiagram
    participant UI as NotesScreen
    participant P as notesProvider (Stream)
    participant R as CrudRepository~Note~
    participant B as bootstrap

    Note over R: default: InMemoryCrudRepository
    B->>R: useFirebase? override →<br/>FirestoreCrudRepository at users/{uid}/notes
    UI->>R: upsert(Note) / delete(id)
    R-->>P: watchAll() emits
    P-->>UI: newest-first list rebuilds
    Note over B,R: same path firestore.rules isolates —<br/>see Backend page
```

Guests stay on the in-memory repository until they create an account; the
override watches `userUidProvider` so the binding follows auth state.

## Commands

```bash
cd foundation
flutter analyze      # must be clean
flutter test         # 11 tests
flutter run          # boots to sign-in on mocks
```

> **🔲 TODO (Phase 5):** `features.remote_config` and `features.notifications`
> flags exist in the manifest but nothing in the foundation consumes them
> yet; the `app_gated` trial window is likewise unenforced (D5). See
> [Future systems](future.md#phase-5--operate-layer).
