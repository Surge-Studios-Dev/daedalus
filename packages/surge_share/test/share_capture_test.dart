import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surge_share/surge_share.dart';

void main() {
  // A 1x1 transparent PNG.
  const dataUri =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
      'AAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

  test('provider identity is memoized: precache and card share one key', () {
    final a = shareImageProvider(dataUri);
    final b = shareImageProvider(dataUri);
    expect(a, isNotNull);
    // MemoryImage compares by BYTES IDENTITY — a second decode would be a
    // different cache entry and re-decode inside the offscreen card (the
    // white-panel bug). Same instance = same cache key.
    expect(identical(a, b), isTrue);

    final http = shareImageProvider('https://cdn/x.jpg');
    expect(http, isA<NetworkImage>());
    expect(identical(http, shareImageProvider('https://cdn/x.jpg')), isTrue);
  });

  test('unusable sources return null instead of throwing', () {
    expect(shareImageProvider(''), isNull);
    expect(shareImageProvider('data:image/png;base64,%%%'), isNull);
    expect(shareImageProvider('data:image/png-no-comma'), isNull);
    expect(shareImageProvider('file:///nope.png'), isNull);
  });

  testWidgets('captureShareCardPng exports the forced theme offscreen', (
    tester,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final png = await tester.runAsync(() async {
      final future = captureShareCardPng(
        captured,
        const ColoredBox(
          color: Colors.orange,
          child: Center(child: Text('card', textDirection: TextDirection.ltr)),
        ),
        logicalSize: const Size(90, 90),
        pixelRatio: 1,
        exportTheme: ThemeData.light(),
      );
      // The harness waits on endOfFrame; drive frames until it completes.
      var done = false;
      unawaitedThen(future, () => done = true);
      while (!done) {
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      return future;
    });

    expect(png, isNotNull);
    // A base64 PNG signature: iVBORw0KGgo.
    expect(png, startsWith('iVBOR'));
    // The offscreen entry must be gone (one pump to rebuild the overlay).
    await tester.pump();
    expect(find.text('card'), findsNothing);
  });
}

void unawaitedThen(Future<Object?> future, void Function() then) {
  future.whenComplete(then);
}
