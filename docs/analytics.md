# Analytics: the monitoring platform

*Part of the [Daedalus wiki](README.md) · related: [Architecture](architecture.md),
[Provisioning](provisioning.md), [Future § Phase 5](future.md#phase-5--operate-layer) ·
doctrine source: Ladle's ANALYTICS.md*

**PostHog is the only dashboard.** Every stamped app gets detailed product
analytics as a *property of the factory*: one PostHog project per app (prod +
dev pair), RevenueCat and Crashlytics piped in, the identity law wired in
code, and a strict no-PII posture. Per-app projects are deliberate — a client
app built for a customer hands off cleanly: its PostHog project transfers
with the repo.

## How events flow

```mermaid
flowchart LR
    subgraph app["Stamped app"]
        ev["Ev taxonomy + domain events<br/>(typed module, no raw strings)"]
        obs["AnalyticsScreenObserver<br/>+ TabShell tab views"]
        toggle["Settings: Share analytics<br/>(default ON, honored pre-cold-start)"]
    end
    ev & obs --> seam{"Analytics seam"}
    toggle -.->|gates| seam
    seam -->|"POSTHOG_KEY set"| ph[("PostHog project<br/>(per app, prod+dev)")]
    seam -->|"else, useFirebase"| ga["Firebase Analytics<br/>(fallback only, never both)"]
    seam -->|tests/dev| dbg["DebugAnalytics"]

    rc["RevenueCat"] -->|"native integration:<br/>trial_started, subscription_*"| ph
    crash["Crashlytics"] -->|"backend onFatalIssue →<br/>crash_fatal_issue"| ph
    ph --> dash["8 standard dashboards +<br/>saved cohorts (per app)"]

    classDef truth fill:#1f4d3b,color:#fff
    class ph truth
```

## The identity law (wired, tested, not optional)

Subscription events must share the user's distinct id or every monetization
funnel fractures. The auth controller is the single place identity binds:

```mermaid
sequenceDiagram
    participant U as User
    participant AC as AuthController
    participant AN as Analytics
    participant PS as PurchaseService

    Note over U,PS: guests stay anonymous - no identify without an account
    U->>AC: sign in (any provider, or session restore)
    AC->>AN: identify(uid)         # 1st
    AC->>PS: setUser(uid)          # 2nd - RevenueCat logIn
    Note over AN,PS: same distinct id everywhere → funnels stay whole
    U->>AC: sign out / delete account
    AC->>AN: reset()
    AC->>PS: setUser(null)         # RevenueCat logOut
```

A foundation widget test pins this: swapping in a signed-in auth backend must
produce an `identify` call on a recording sink.

## What every stamp carries

| Piece | What it does |
|---|---|
| `Analytics.identify/reset` + `PurchaseService.setUser` | The identity law at the seam level — every impl must handle it |
| `PosthogAnalyticsService` | Bound when `--dart-define=POSTHOG_KEY` is set; recordings off, consent-gated |
| `AnalyticsScreenObserver` + named routes + TabShell logging | Screen views with zero per-screen wiring |
| Settings "Share analytics" toggle | The opt-out the privacy policy promises; applies live and pre-cold-start |
| `ANALYTICS.md` (stamped) | The per-app doctrine: taxonomy, no-PII rules, dashboards + cohorts checklist |
| `backend/onFatalIssue` | Crashlytics fatal issues → `crash_fatal_issue` in PostHog |
| provision.sh §5b | Creates the prod+dev project pair via the PostHog API |
| ship_check | Fails on hardcoded `phc_` keys; warns if ANALYTICS.md is missing |

## Surge HQ: the portfolio rollup

The cross-app view lives at studio level (`hq/` + `tools/hq_rollup`), never
inside apps. It answers the portfolio question directly: **total ad spend vs
total revenue vs net, per month**, with per-app breakdowns.

```mermaid
flowchart LR
    reg["hq/portfolio.yaml<br/>app registry (status:<br/>dev · live · transferred)"] --> R
    spend["hq/spend/YYYY-MM.csv<br/>manual ad-spend entries<br/>(app, channel, amount)"] --> R
    kpis["KPIs JSON: revenue, active<br/>users, trials per app-month<br/>(fixtures now → PostHog +<br/>RevenueCat APIs at Phase 4)"] --> R
    R["tools/hq_rollup"] --> html["hq/dashboard.html<br/>self-contained, offline,<br/>spend vs revenue vs net"]
```

Ad spend is manual CSV entry first (one row per app per channel per month) —
ad-network APIs are parked until paid UA actually starts. A transferred
client app keeps its registry row with `status: transferred` and simply drops
out of KPI pulls; its analytics left with the repo.

## The rules that keep the data trustworthy

- **The `Ev` base taxonomy is append-only** and identical in every app — the
  reason one dashboard template fits all of them.
- **No PII, ever**: no user text, titles, URLs, emails in names or props;
  typed event modules are the primary defense, ship_check's key scan and
  review are backstops. Recordings stay off.
- **Dev traffic never pollutes prod**: debug builds point at the dev project
  key.
- **RevenueCat owns canonical money numbers**; PostHog mirrors them for
  behavior joins; HQ reads both.

> **🔲 TODO (Phase 4):** first live run — PostHog org + keys, RevenueCat →
> PostHog integration flipped on, dashboards built from the stamped
> checklist, and the HQ KPI pull switched from fixtures to the live APIs.

> **🔲 TODO (parked):** ad-network spend APIs (Apple Search Ads / Meta /
> Google) replacing the manual CSVs, and alerting thresholds (crash-free
> floor, conversion drop) on the HQ rollup. See
> [Future systems](future.md#parking-lot).
