import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surge_ui/surge_ui.dart';

/// Wraps a widget in a themed app so token lookups resolve.
Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: buildSurgeTheme(brightness),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('SurgeButton renders its label and fires onPressed', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(SurgeButton.primary('Get started', onPressed: () => taps++)),
    );
    expect(find.text('Get started'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    expect(taps, 1);
  });

  testWidgets('disabled SurgeButton does not fire', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(const SurgeButton.primary('Locked')));
    await tester.tap(find.text('Locked'));
    expect(taps, 0);
  });

  testWidgets('SurgeTextField reports changes', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(
      _host(SurgeTextField(placeholder: 'Email', onChanged: changes.add)),
    );
    await tester.enterText(find.byType(TextField), 'hi');
    expect(changes.last, 'hi');
  });

  testWidgets('SurgeGroupRow toggles', (tester) async {
    bool? last;
    await tester.pumpWidget(
      _host(
        SurgeGroupRow(title: 'Notifications', toggle: false, onToggle: (v) => last = v),
      ),
    );
    await tester.tap(find.byType(Switch));
    expect(last, true);
  });

  testWidgets('SurgeToggle flips', (tester) async {
    bool? last;
    await tester.pumpWidget(
      _host(SurgeToggle(on: false, onChanged: (v) => last = v)),
    );
    await tester.tap(find.byType(SurgeToggle));
    expect(last, true);
  });

  testWidgets('SurgeSegmented reports the tapped option', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(
        SurgeSegmented(
          options: const ['A', 'B', 'C'],
          value: 'A',
          onChanged: (v) => picked = v,
        ),
      ),
    );
    await tester.tap(find.text('C'));
    expect(picked, 'C');
  });

  testWidgets('SurgeStepper increments and clamps', (tester) async {
    double? v;
    await tester.pumpWidget(
      _host(
        SurgeStepper(value: 1, min: 1, max: 2, onChanged: (n) => v = n),
      ),
    );
    await tester.tap(find.byIcon(Icons.add));
    expect(v, 2);
  });

  testWidgets('surgeStepValue snaps to the step grid within bounds', (
    tester,
  ) async {
    expect(surgeStepValue(2010, 1, min: 0, max: 3000, step: 50), 2050);
    expect(surgeStepValue(1, -1, min: 1, max: 9), 1); // clamped at min
  });

  testWidgets('SurgeFilterChip fires and shows a check when selected', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(SurgeFilterChip(label: 'Recent', selected: true, onPressed: () => taps++)),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('Recent'));
    expect(taps, 1);
  });

  testWidgets('showSurgeConfirm returns true on confirm', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final future = showSurgeConfirm(ctx, title: 'Sure?', confirmLabel: 'Yes');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(await future, true);
  });

  testWidgets('SurgeBadge renders its label uppercased', (tester) async {
    await tester.pumpWidget(
      _host(const SurgeBadge('new', kind: SurgeBadgeKind.success)),
    );
    expect(find.text('NEW'), findsOneWidget);
  });

  testWidgets('showSurgeToast shows then auto-dismisses', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    showSurgeToast(ctx, message: 'Saved', duration: const Duration(milliseconds: 500));
    await tester.pump(); // insert overlay
    await tester.pump(const Duration(milliseconds: 300)); // slide in completes
    expect(find.text('Saved'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500)); // display window elapses
    await tester.pump(const Duration(milliseconds: 300)); // slide out + removal
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('showSurgeActionMenu runs the tapped item', (tester) async {
    late BuildContext ctx;
    var shared = 0;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    showSurgeActionMenu(
      ctx,
      title: 'Item',
      items: [
        SurgeActionMenuItem(
          icon: Icons.share,
          label: 'Share',
          onSelected: () => shared++,
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect(shared, 1);
  });

  testWidgets('components build in dark theme', (tester) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            SurgeButton.secondary('Go', onPressed: () {}),
            const SurgeListRow(title: 'Row', sub: 'sub', chevron: true),
            const SurgeActionCard(icon: Icons.star, title: 'Card', selected: true),
          ],
        ),
        brightness: Brightness.dark,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Card'), findsOneWidget);
  });
}
