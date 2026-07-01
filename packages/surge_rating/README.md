# surge_rating

In-app rating prompt — a **Tier 3 System** (see [`../../FRAMEWORK.md`](../../FRAMEWORK.md)).
Depend on `RatingService`; the app asks for a review without touching the native
API. Same swap pattern as the rest: `MockRatingService` in dev/tests,
`InAppReviewRatingService` in a real build.

## Use it

```dart
import 'package:surge_rating/surge_rating.dart';

final rating = InAppReviewRatingService(); // or MockRatingService() in tests

// Call at a genuine good moment (right after a success), NOT on a schedule —
// the OS rate-limits the native prompt and ignores over-eager calls.
if (await rating.isAvailable()) {
  await rating.requestReview();
}

// A reliable "Rate us" menu action:
await rating.openStoreListing(appStoreId: '<your App Store id>');
```

Wrap it in a Riverpod provider and bind the real impl in `bootstrap`, exactly
like `AuthService` / `PurchaseService`.

## Status

v0.1.0 — interface + mock + `in_app_review` implementation. Mock covered by a
test; verify the native flow live on a device.
