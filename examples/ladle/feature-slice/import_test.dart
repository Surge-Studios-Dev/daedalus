import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladle/core/dates.dart';
import 'package:ladle/features/import/import_controller.dart';
import 'package:ladle/features/import/import_meter_state.dart';
import 'package:ladle/ui/components/import_meter.dart';
import 'package:ladle/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('import meter', () {
    test('counts up and clamps', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(importMeterProvider).left, 5);
      await container.read(importMeterProvider.notifier).consume();
      await container.read(importMeterProvider.notifier).consume();
      expect(container.read(importMeterProvider).used, 2);
      expect(container.read(importMeterProvider).left, 3);
      expect(container.read(importMeterProvider).atLimit, isFalse);
    });

    test('stored count from a previous week resets (Monday rule)', () async {
      final lastWeek = weekStartOf(
        toIso(DateTime.now().subtract(const Duration(days: 7))),
      );
      SharedPreferences.setMockInitialValues({
        'import.meter': '{"week":"$lastWeek","used":5}',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(importMeterProvider); // instantiate, starts async load
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(container.read(importMeterProvider).used, 0);
    });

    test('stored count from this week survives', () async {
      final thisWeek = weekStartOf(toIso(DateTime.now()));
      SharedPreferences.setMockInitialValues({
        'import.meter': '{"week":"$thisWeek","used":4}',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(importMeterProvider); // instantiate, starts async load
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(container.read(importMeterProvider).used, 4);
      expect(container.read(importMeterProvider).atLimit, isFalse);
      await container.read(importMeterProvider.notifier).consume();
      expect(container.read(importMeterProvider).atLimit, isTrue);
    });
  });

  group('import stages', () {
    test('stage list picked by source kind', () {
      expect(stagesVideo[1], 'Reading video & audio');
      expect(stagesWeb[1], 'Reading page');
      expect(stagesPhoto.first, 'Reading your photo');
    });
  });

  testWidgets('ImportMeter widget renders the spec copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ladleTheme(Brightness.light),
        home: const Scaffold(body: ImportMeter(used: 3, cap: 5)),
      ),
    );
    expect(find.text('2 of 5 free imports left this week'), findsOneWidget);
  });
}
