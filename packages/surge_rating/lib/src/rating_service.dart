/// The app-review boundary. Depend on this instead of the native review API, so
/// it is a swappable implementation: [MockRatingService] in dev/tests,
/// `InAppReviewRatingService` in a real build.
abstract interface class RatingService {
  /// Whether the in-app review flow is available on this device/store.
  Future<bool> isAvailable();

  /// Ask the OS to show its native in-app review prompt. The OS decides whether
  /// to actually display it (rate-limited), so call it at a genuine good moment,
  /// not on a fixed schedule.
  Future<void> requestReview();

  /// Open the store listing (a reliable fallback / "rate us" menu action).
  Future<void> openStoreListing({String? appStoreId});
}

/// In-memory rating service for dev and tests. Records what was called.
class MockRatingService implements RatingService {
  bool reviewRequested = false;
  bool listingOpened = false;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => reviewRequested = true;

  @override
  Future<void> openStoreListing({String? appStoreId}) async =>
      listingOpened = true;
}
