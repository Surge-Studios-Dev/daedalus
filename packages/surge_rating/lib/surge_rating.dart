/// Surge rating — in-app review prompt (Tier 3 System).
///
/// Depend on [RatingService]; bind [MockRatingService] in dev/tests and
/// `InAppReviewRatingService` in a real build. Ask at a genuine good moment
/// (after a success), never on a fixed schedule — the OS rate-limits the prompt.
library;

export 'src/rating_service.dart';
export 'src/in_app_review_rating_service.dart';
