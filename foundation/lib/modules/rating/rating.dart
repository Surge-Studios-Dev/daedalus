import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_rating/surge_rating.dart';

/// The app-review seam (Tier-3 surge_rating). Mock by default so tests and
/// dev builds never hit the OS prompt; bootstrap binds the real
/// InAppReviewRatingService in a device build.
final ratingServiceProvider = Provider<RatingService>(
  (_) => MockRatingService(),
);

/// "Rate this app": try the native in-app prompt, fall back to the store
/// listing. The OS silently rate-limits requestReview, so an explicit menu
/// action needs the fallback rather than appearing to do nothing. Call it
/// from genuine good moments too - never on a fixed schedule.
Future<void> rateApp(WidgetRef ref) async {
  final rating = ref.read(ratingServiceProvider);
  if (await rating.isAvailable()) {
    await rating.requestReview();
  } else {
    await rating.openStoreListing();
  }
}
