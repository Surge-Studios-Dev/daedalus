# surge_onboarding

A drop-in first-run onboarding flow — a **Tier 3 System** (see
[`../../FRAMEWORK.md`](../../FRAMEWORK.md)). It owns the *flow* (paging, progress
dots, next/done, optional skip); the host app owns *persistence* ("has the user
seen it?") and *routing* (where to go on done). Built entirely on `surge_ui`, so
it inherits the app's theme.

## Use it

```dart
import 'package:surge_onboarding/surge_onboarding.dart';

OnboardingFlow(
  pages: const [
    OnboardingPage(icon: Icons.bolt, title: 'Fast', body: 'Do the thing quickly.'),
    OnboardingPage(icon: Icons.lock, title: 'Private', body: 'Your data stays yours.'),
  ],
  onDone: () {
    ref.read(onboardingCompleteProvider.notifier).markSeen(); // host persistence
    context.go('/home');                                      // host routing
  },
  onSkip: () { /* same as done, minus the tour */ },
);
```

## Why it's a System, not a component

It composes several `surge_ui` components plus its own paging state into a
complete, swappable feature. It stays reusable by taking data (`pages`) and
callbacks (`onDone`, `onSkip`) instead of reaching into app state — the same
contract every Tier 3 package follows.

## Reference integration

`foundation/lib/modules/onboarding/` shows the canonical wiring: an in-memory
`onboardingCompleteProvider` (SEAM: persist with shared_preferences) and a
router redirect that presents `/onboarding` after login until it's complete.

## Status

v0.1.0 — flow widget + page model, covered by widget tests (paging, done, skip).
