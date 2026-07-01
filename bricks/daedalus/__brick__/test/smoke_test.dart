import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{slug}}/app/app.dart';

/// Smoke test: a freshly stamped app boots and shows the sign-in screen (mock
/// auth, signed out). Proves the whole tree wires up. Grow this per feature.
void main() {
  testWidgets('app boots to the sign-in screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SurgeApp()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
