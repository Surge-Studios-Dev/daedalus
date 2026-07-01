import 'package:flutter_test/flutter_test.dart';
import 'package:surge_rating/surge_rating.dart';

void main() {
  test('MockRatingService records requestReview and openStoreListing', () async {
    final service = MockRatingService();
    expect(await service.isAvailable(), isTrue);
    expect(service.reviewRequested, isFalse);

    await service.requestReview();
    expect(service.reviewRequested, isTrue);

    await service.openStoreListing(appStoreId: '123');
    expect(service.listingOpened, isTrue);
  });
}
