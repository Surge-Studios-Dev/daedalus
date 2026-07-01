import 'package:in_app_review/in_app_review.dart';

import 'rating_service.dart';

/// The real [RatingService], backed by the `in_app_review` plugin (StoreKit /
/// Play In-App Review).
class InAppReviewRatingService implements RatingService {
  final _review = InAppReview.instance;

  @override
  Future<bool> isAvailable() => _review.isAvailable();

  @override
  Future<void> requestReview() => _review.requestReview();

  @override
  Future<void> openStoreListing({String? appStoreId}) =>
      _review.openStoreListing(appStoreId: appStoreId);
}
