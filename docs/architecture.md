# Architecture: tiers and seams

*Part of the [Daedalus wiki](README.md) · related:
[Foundation](foundation.md), [surge_ui](surge-ui.md), [Brick](brick.md) ·
decision record: [FRAMEWORK.md](../FRAMEWORK.md)*

Two ideas carry the whole framework: a **four-tier fill model** (what gets
built at which layer) and the **seam pattern** (how the app stays
backend-agnostic). Everything else is plumbing around them.

## The four tiers

```mermaid
flowchart TB
    subgraph T4["Tier 4 · Custom (per app)"]
        feat["lib/features/* — the product.<br/>Spec-first; the only tier that is new work."]
    end
    subgraph T3["Tier 3 · Systems (drop-in packages)"]
        onb["surge_onboarding<br/>data-driven first run"]
        crud["surge_crud<br/>CrudRepository&lt;T&gt;"]
        rate["surge_rating<br/>review prompts"]
        more["…future systems"]
    end
    subgraph T2["Tier 2 · Components"]
        ui["surge_ui — tokens, theme, 28 components,<br/>generated catalog. Zero domain logic."]
    end
    subgraph T1["Tier 1 · Foundation (the blank canvas)"]
        found["auth · nav shell · onboarding · paywall+gates ·<br/>settings · telemetry · storage — all on mock seams"]
    end

    T4 --> T3 --> T2
    T4 --> T2
    T1 --> T2
    T1 -->|integrates| T3
    feat -.->|"promotion path:<br/>reusable? → CONTRIBUTING bar"| ui

    classDef canvas fill:#0e1b27,color:#fff
    class found canvas
```

**Fill order for a new app:** the foundation arrives stamped (free), systems
drop in (cheap), custom features fill the gaps (the week), and anything
reusable gets promoted back into `surge_ui` or a new System so the next app
starts richer. The promotion bar lives in
[surge_ui/CONTRIBUTING.md](../packages/surge_ui/CONTRIBUTING.md).

## The seam pattern

The framework's spine. Every external dependency sits behind an interface
with a working mock as the Riverpod default; bootstrap swaps in the real
implementation behind one flag. Nothing downstream ever knows which is bound.

```mermaid
classDiagram
    class AuthService {
        <<interface>>
        currentUser
        authStateChanges()
        signInWithEmail() signInWithApple() signInWithGoogle()
        signOut() deleteAccount()
    }
    class MockAuthService {
        in-memory · provider default
    }
    class FirebaseAuthService {
        real · bound when useFirebase
    }
    AuthService <|.. MockAuthService
    AuthService <|.. FirebaseAuthService
    class App {
        watches authServiceProvider only
    }
    App --> AuthService : depends on the interface
```

```mermaid
sequenceDiagram
    participant main as main()
    participant boot as bootstrap()
    participant scope as ProviderScope
    participant app as SurgeApp

    main->>boot: bootstrap()
    boot->>boot: SharedPreferences → KeyValueStore override (always)
    boot->>boot: InAppReviewRatingService override (always)
    alt useFirebase == true
        boot->>boot: Firebase.initializeApp + Crashlytics hooks
        boot->>boot: override auth / analytics / errors / notes-Firestore
    end
    alt useRevenueCat == true
        boot->>boot: Purchases.configure + RevenueCat override
    end
    boot->>scope: ProviderScope(overrides)
    scope->>app: runApp — app code identical either way
```

### The seven seams

| Seam | Interface | Mock default | Real binding | Flip |
|---|---|---|---|---|
| Auth | `AuthService` | `MockAuthService` | `FirebaseAuthService` (email/Apple/Google) | `useFirebase` |
| Purchases | `PurchaseService` | in-memory unlock | `RevenueCatPurchaseService` | `useRevenueCat` |
| Storage | `KeyValueStore` | `InMemoryKeyValueStore` | `SharedPrefsKeyValueStore` | always on |
| Analytics | `Analytics` | `DebugAnalytics` (prints) | `FirebaseAnalyticsService` | `useFirebase` |
| Crash reporting | `ErrorReporter` | no-op/log | `CrashlyticsErrorReporter` | `useFirebase` |
| Data | `CrudRepository<T>` | `InMemoryCrudRepository` | `FirestoreCrudRepository` at `users/{uid}/…` | `useFirebase` |
| Ratings | `RatingService` | `MockRatingService` | `InAppReviewRatingService` | always in bootstrap |

**Proof, not promise:** the foundation's backend-swap tests override *only* a
service provider and assert the whole app follows — sign-in state, account
email, gate behavior. See `foundation/test/foundation_test.dart`.

**Streams must be auth-reactive (Ember lesson, 2026-07-08).** A uid-scoped
`watchAll()` reads the uid ONCE, when the stream is created — and the app
root's keep-alive providers (widget bridge, push topics, queue drain) touch
the data chain while the sign-in screen is still up. If a `StreamProvider`
over a repo doesn't also watch the uid/auth provider, the pre-auth
`Stream.value(const [])` is cached for the app's lifetime: **writes succeed
against Firestore while the UI shows an empty list forever.** On Ember this
presented as "creating a group does nothing" — the group was in Firestore
the whole time. The foundation's notes seam already shows the canonical
shape — `repoProvider.overrideWith((ref) { final uid =
ref.watch(userUidProvider); … })` — so the binding itself rebuilds on auth.
Ember's deviation was `overrideWithValue(Repo(() => currentUid))`: a lazy
uid *getter* looks reactive but the provider graph can't see it. Bind repos
with `overrideWith` + `ref.watch` of the uid, and have every
`StreamProvider` wrapping a uid-scoped `watchAll()` also watch the uid
provider (defense in depth). It never reproduces in a dev
loop where you're already signed in before the first frame — only on a
fresh sign-in session, which is exactly what every real user's first
session is.

## Package dependency graph

```mermaid
flowchart LR
    app["stamped app /<br/>foundation"] --> ui[surge_ui]
    app --> onb[surge_onboarding]
    app --> crud[surge_crud]
    app --> rate[surge_rating]
    app --> fb["firebase_core/auth/<br/>analytics/crashlytics"]
    app --> rc[purchases_flutter]
    app --> sp[shared_preferences]
    onb --> ui
    crud --> cf[cloud_firestore]
    rate --> iar[in_app_review]
    ui --> flutter([Flutter SDK only])

    classDef pkg fill:#1f4d3b,color:#fff
    class ui,onb,crud,rate pkg
```

Rules encoded in that graph: `surge_ui` depends on Flutter alone (tokens in,
widgets out — nothing else); Systems may depend on `surge_ui` and their one
backing plugin; the app is the only place seams get bound.

## Non-negotiable contracts

- **SurgeTokens is frozen**: bg/ink/line/accent/status/inverse/shadows. New
  fields = major version bump. Domain colors live in per-app ThemeExtensions,
  never in the shared contract. `context.tokens`, never a hex literal.
- **The `Ev` telemetry taxonomy is append-only**: `app_open, screen_view,
  sign_up, login, onboarding_complete, paywall_view, trial_start, purchase,
  restore, cancel_intent, gate_blocked, crosspromo_tap` — add domain events,
  never rename these.
- **Gating goes through `ref.gate(context, gateId, onSuccess)`** — it checks
  the entitlement and pushes `/paywall?source=gateId` when locked. No ad-hoc
  entitlement checks.

> **🔲 TODO (Phase 5):** `cross_promo` is in the taxonomy and the manifest
> (`features.cross_promo`) but the module is unbuilt — needs 2+ live apps to
> matter. See [Future systems](future.md#cross-promo-d6).
