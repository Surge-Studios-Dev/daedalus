import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surge_foundation/modules/auth/oauth_buttons.dart';

/// Regression: the OAuth button row overflowed by 10px at the sign-in
/// screen's content width (345 = 393 - 2x24) under the test fallback font,
/// where every glyph renders at full point size (CI 2026-07-12: sign_in
/// light+dark board captures failed). The label must flex, not overflow -
/// the same guard covers large accessibility text scales on device.
void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 345, child: child),
          ),
        ),
      );

  testWidgets('apple + google buttons render at sign-in width without '
      'overflow', (tester) async {
    await tester.pumpWidget(
      host(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OAuthButton.apple(onPressed: () {}),
            const SizedBox(height: 12),
            OAuthButton.google(onPressed: () {}),
          ],
        ),
      ),
    );
    // An overflowing RenderFlex reports through FlutterError; pumpWidget
    // rethrows it as a test failure, so arriving here means no overflow.
    expect(find.byType(OAuthButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
