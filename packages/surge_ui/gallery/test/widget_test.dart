import 'package:flutter_test/flutter_test.dart';
import 'package:surge_ui_gallery/main.dart';

void main() {
  testWidgets('gallery boots on the canvas pack and switches packs', (
    tester,
  ) async {
    // Bounded pumps throughout: the gallery page hosts forever-looping
    // animations (spinner, indeterminate bar, shimmer), so pumpAndSettle
    // never settles here.
    await tester.pumpWidget(const GalleryApp());
    expect(find.text('surge_ui · Canvas'), findsOneWidget);

    await tester.tap(find.byTooltip('Show menu'));
    // Discrete frames so the menu route's transition (and its IgnorePointer)
    // fully finishes before the item tap.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Soft depth').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('surge_ui · Soft depth'), findsOneWidget);
  });
}
