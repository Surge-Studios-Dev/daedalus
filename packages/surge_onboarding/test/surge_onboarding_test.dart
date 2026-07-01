import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surge_onboarding/surge_onboarding.dart';
import 'package:surge_ui/surge_ui.dart';

const _pages = [
  OnboardingPage(icon: Icons.bolt, title: 'One', body: 'First page.'),
  OnboardingPage(icon: Icons.star, title: 'Two', body: 'Second page.'),
];

Widget _host(Widget child) =>
    MaterialApp(theme: buildSurgeTheme(Brightness.light), home: child);

void main() {
  testWidgets('advances through pages and fires onDone on the last', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(
      _host(OnboardingFlow(pages: _pages, onDone: () => done++)),
    );

    // First page: button says Next, onDone not yet called.
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Last page: button becomes Get started.
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    expect(done, 1);
  });

  testWidgets('shows Skip only when onSkip is provided and not on last page', (
    tester,
  ) async {
    var skipped = 0;
    await tester.pumpWidget(
      _host(
        OnboardingFlow(pages: _pages, onDone: () {}, onSkip: () => skipped++),
      ),
    );
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    expect(skipped, 1);
  });

  testWidgets('no Skip affordance without onSkip', (tester) async {
    await tester.pumpWidget(
      _host(OnboardingFlow(pages: _pages, onDone: () {})),
    );
    expect(find.text('Skip'), findsNothing);
  });
}
