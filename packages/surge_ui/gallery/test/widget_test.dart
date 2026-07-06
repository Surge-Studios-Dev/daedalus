import 'package:flutter_test/flutter_test.dart';
import 'package:surge_ui_gallery/main.dart';

void main() {
  testWidgets('gallery boots on the canvas pack and switches packs', (
    tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());
    expect(find.text('surge_ui · Canvas'), findsOneWidget);

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Soft depth').last);
    await tester.pumpAndSettle();
    expect(find.text('surge_ui · Soft depth'), findsOneWidget);
  });
}
