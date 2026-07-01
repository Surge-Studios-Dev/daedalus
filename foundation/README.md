# surge_foundation

The **blank Surge canvas** (Tier 1 in [`../FRAMEWORK.md`](../FRAMEWORK.md)): a
runnable app with the universal essentials wired but empty. It compiles, signs a
user in, navigates, themes light/dark, runs a full settings stack, and gates a
feature behind a paywall — and it does nothing useful yet. That is the point.
Fill `features/` with the app's real functionality.

## Run it

```bash
flutter pub get
flutter test          # 5 tests: auth redirect, shell, settings, gate
flutter run           # add platform folders first: `flutter create .`
```

> `flutter analyze` and `flutter test` work as-is. `flutter run`/`build` need
> the `android/ios/` folders — `flutter create .` (or forge.sh) generates them;
> they are intentionally not committed to keep the template lean.

## What's wired

| Area | State (`modules/`) | Screens |
|---|---|---|
| **Auth** | `auth/auth_controller.dart` — signedOut / guest / signedIn | sign in, sign up (email + Apple + Google + guest) |
| **Nav** | `app/router.dart` — auth-redirect + tab shell | `shell/tab_shell.dart` (Home + You) |
| **Paywall** | `paywall/entitlement.dart` + `gate.dart` | `paywall_screen.dart` (purchase, restore) |
| **Settings** | `settings/appearance_controller.dart` | settings, account (+ delete), legal, appearance |
| **Telemetry** | `telemetry/analytics.dart` — standard event taxonomy | — |

Stack: **Riverpod** (no codegen yet) + **go_router** + **surge_ui**. Every pixel
comes from `surge_ui` components and tokens — no hardcoded styling here.

## The seams (what to fill)

The framework-heavy integrations sit behind interfaces with a working **mock**
default, so the app runs today. Swap the binding, keep the shape.

**Auth is wired both ways already.** The app depends on `modules/auth/AuthService`;
`MockAuthService` is the default and `FirebaseAuthService` is a real
`firebase_auth` implementation. To go live:

1. `flutter create .` (adds the `android/ios` folders a fresh stamp omits).
2. `dart pub global activate flutterfire_cli && flutterfire configure`
   — generates the real `lib/firebase_options.dart` for your project.
3. In the Firebase console, enable **Email/Password** sign-in.
4. Set `useFirebase = true` in `app/bootstrap.dart`.

That's it — `bootstrap` initializes Firebase and overrides `authServiceProvider`
with `FirebaseAuthService`; nothing else in the app changes. (Apple/Google
sign-in are left as marked seams in `firebase_auth_service.dart` — they need
their own packages + platform entitlements.)

**Purchases are wired both ways too**, same shape as auth. The app depends on
`modules/paywall/PurchaseService`; `MockPurchaseService` is the default and
`RevenueCatPurchaseService` is a real `purchases_flutter` implementation, with
`entitlementProvider` derived from it. To go live: create the RevenueCat app +
`pro` entitlement + products, then set `useRevenueCat = true` in
`app/bootstrap.dart` and pass the key with `--dart-define=REVENUECAT_KEY=...`.

Other seams, same pattern:

- **Crashlytics** in `app/bootstrap.dart`.
- **shared_preferences** persistence for `appearance_controller.dart` and
  `onboarding_controller.dart`.
- **FirebaseAnalytics** impl behind the `Analytics` interface.
- Per-app **palette/font** into `buildSurgeTheme` in `app/app.dart` (from the
  manifest brand block).

## Compliance already present

In-app account deletion, Sign in with Apple alongside social login, restore
purchases, in-app Privacy + Terms screens. Verify against current store
guidelines before each submission.

## Relationship to the brick

This is the reference app the Daedalus brick will stamp from: `app/` + `modules/`
become `__brick__`, with manifest-driven values (tabs, providers, entitlement,
palette) templated in. Prove it here first, then templatize.
