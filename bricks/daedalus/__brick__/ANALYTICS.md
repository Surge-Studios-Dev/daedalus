# ANALYTICS.md · {{name}}

Single source of truth for what this app tracks, how, and where it lives.
**PostHog is the only dashboard.** RevenueCat and Crashlytics pipe into it so
daily review happens in one place. (Studio doctrine, proven on Ladle.)

## Stack
- **PostHog** — one project per app, prod + dev pair, so this app's analytics
  transfer with the repo on a client handoff. Keys via
  `--dart-define=POSTHOG_KEY=phc_...` (dev key in debug runs, prod in release
  builds); never committed. **Session/screen recordings are OFF and stay
  off** (no-PII rule).
- **RevenueCat** — subscription source of truth; enable its PostHog
  integration so `trial_started`, `subscription_*`, `billing_issue` events
  mirror in under the same distinct id.
- **Crashlytics** — crashes; `onFatalIssue` in `backend/` forwards fatal
  issues to PostHog as `crash_fatal_issue`.

## Identity model (wired by the foundation - do not re-implement)
- Pre-sign-in activity accrues to PostHog's anonymous id. Guests are never
  identified.
- On sign-in the auth controller calls `Analytics.identify(uid)` **and**
  `PurchaseService.setUser(uid)` together, in that order - subscription
  events must share the user's distinct id or monetization funnels fracture.
- Sign-out / account deletion calls `reset()` + `setUser(null)`.
- The settings "Share analytics" toggle (default ON) applies immediately and
  is honored before any cold-start event.

## Event taxonomy
The `Ev` base set is identical across every Surge app - never rename it:
`app_open · screen_view · sign_up · login · onboarding_complete ·
paywall_view · trial_start · purchase · restore · cancel_intent ·
gate_blocked · crosspromo_tap`.

Add domain events on top, snake_case, verbs for actions. **No PII ever**: no
user-entered text, titles, URLs, emails, or names in event names or
properties. Route every event through a typed module
(`lib/core/analytics.dart` with one method per event) - no raw
`analytics.log` calls with ad-hoc strings in feature code.

> Fill in this app's domain events here as features are built, one section
> per tab. Every paywall_view carries its gate `source`; keep gate ids bare.

## User properties (set on identify and on change)
`platform`, `app_version`, `os_version`, `signup_date`,
`entitlement_status: free|trial|active|lapsed` + app-specific cohort fields
(counts, mode toggles). Recompute count-type properties on cold start only.

## Standard dashboards (build at TestFlight time, from the studio checklist)
1. North Star (define this app's weekly-active-value metric)
2. Acquisition funnel: first `app_open` → `onboarding_complete` → first
   domain value → `paywall_view` → `trial_start` → `purchase`
3. D1/D7/D30 retention by signup week
4. Monetization funnel by gate `source`
5. Subscription health (cross-check RevenueCat's canonical numbers)
6. Core-loop quality (this app's key action rates)
7. Errors: `crash_fatal_issue` rate, error events by screen
8. Performance: cold start p95 (sample perf events at 10%)

Saved cohorts: subscribers · D7-retained · power users · lapsed 14d ·
onboarding drop-offs.

## Checklist before TestFlight
- [ ] Prod + dev PostHog projects exist (provision.sh creates them)
- [ ] Debug builds point at the dev project key
- [ ] RevenueCat → PostHog integration on; uid stitching verified end to end
- [ ] `onFatalIssue` deployed with POSTHOG_PROJECT_KEY env set
- [ ] Dashboards 1-8 + cohorts created
- [ ] Zero events fire with the settings toggle OFF
- [ ] No replays appear in PostHog (recordings off)
