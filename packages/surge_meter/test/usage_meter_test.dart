import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:surge_meter/surge_meter.dart';

void main() {
  group('UsageMeter', () {
    test('fresh meter is empty and not at limit', () async {
      final meter = UsageMeter(
        cap: 5,
        store: InMemoryMeterStore(),
        today: () => '2026-06-10',
      );
      final state = await meter.loadedState();
      expect(state.used, 0);
      expect(state.left, 5);
      expect(state.atLimit, isFalse);
    });

    test('consume increments and persists under the period key', () async {
      final store = InMemoryMeterStore();
      final meter = UsageMeter(cap: 5, store: store, today: () => '2026-06-10');
      await meter.consume();
      await meter.consume();
      expect(meter.state.used, 2);
      final raw = jsonDecode(store.values['meter.usage']!);
      expect(raw['period'], '2026-06-08'); // Monday of that week
      expect(raw['used'], 2);
    });

    test('persisted count survives a reload within its own week', () async {
      final store = InMemoryMeterStore();
      final a = UsageMeter(cap: 5, store: store, today: () => '2026-06-10');
      await a.consume();
      await a.consume();
      await a.consume();

      final b = UsageMeter(cap: 5, store: store, today: () => '2026-06-12');
      expect((await b.loadedState()).used, 3);
    });

    test('a new week reads as a fresh meter', () async {
      final store = InMemoryMeterStore();
      final a = UsageMeter(cap: 5, store: store, today: () => '2026-06-10');
      await a.setUsed(5);

      final b = UsageMeter(cap: 5, store: store, today: () => '2026-06-15');
      final state = await b.loadedState();
      expect(state.used, 0);
      expect(state.atLimit, isFalse);
    });

    test('counts clamp to cap (gate-bypassing flows cannot overrun)', () async {
      final store = InMemoryMeterStore();
      final meter = UsageMeter(cap: 2, store: store, today: () => '2026-06-10');
      await meter.consume();
      await meter.consume();
      await meter.consume(); // queued share import allowed to finish
      expect(meter.state.used, 2);
      expect(meter.state.atLimit, isTrue);
      expect(jsonDecode(store.values['meter.usage']!)['used'], 2);
    });

    test('consume before the initial read lands on the REAL stored count '
        '(auto-started share/deep-link race)', () async {
      final store = InMemoryMeterStore(
        readDelay: const Duration(milliseconds: 50),
      );
      store.values['meter.usage'] = jsonEncode({
        'period': '2026-06-08',
        'used': 4,
      });
      final meter = UsageMeter(cap: 5, store: store, today: () => '2026-06-10');
      // Fire immediately, while the meter still shows the boot default 0/5.
      await meter.consume();
      expect(meter.state.used, 5);
      expect(meter.state.atLimit, isTrue);
    });

    test('period rollover mid-session resets before charging', () async {
      var today = '2026-06-10';
      final store = InMemoryMeterStore();
      final meter = UsageMeter(cap: 5, store: store, today: () => today);
      await meter.setUsed(5);

      today = '2026-06-16'; // app stayed open across Monday 00:00
      await meter.consume();
      expect(meter.state.used, 1);
      expect(jsonDecode(store.values['meter.usage']!)['period'], '2026-06-15');
    });

    test('weekly reset honors the Sun week-start setting', () async {
      final store = InMemoryMeterStore();
      final meter = UsageMeter(
        cap: 5,
        store: store,
        weekStartsOn: 'Sun',
        today: () => '2026-06-10',
      );
      await meter.consume();
      expect(jsonDecode(store.values['meter.usage']!)['period'], '2026-06-07');
    });

    test('monthly period keys by calendar month', () async {
      final store = InMemoryMeterStore();
      final a = UsageMeter(
        cap: 10,
        store: store,
        period: MeterPeriod.monthly,
        today: () => '2026-06-30',
      );
      await a.consume();
      expect(jsonDecode(store.values['meter.usage']!)['period'], '2026-06');

      final b = UsageMeter(
        cap: 10,
        store: store,
        period: MeterPeriod.monthly,
        today: () => '2026-07-01',
      );
      expect((await b.loadedState()).used, 0);
    });

    test('setUsed clamps into range', () async {
      final meter = UsageMeter(
        cap: 5,
        store: InMemoryMeterStore(),
        today: () => '2026-06-10',
      );
      await meter.setUsed(99);
      expect(meter.state.used, 5);
      await meter.setUsed(-3);
      expect(meter.state.used, 0);
    });
  });

  group('MeterAllowance', () {
    test('totals and at-limit combine period + banked', () {
      const a = MeterAllowance(periodLeft: 0, banked: 2);
      expect(a.totalLeft, 2);
      expect(a.atLimit, isFalse);
      const b = MeterAllowance(periodLeft: 0, banked: 0);
      expect(b.atLimit, isTrue);
    });

    test('period allowance spends before banked credits', () async {
      final meter = UsageMeter(
        cap: 1,
        store: InMemoryMeterStore(),
        today: () => '2026-06-10',
      );
      var bankedSpends = 0;
      Future<bool> spendBanked() async {
        bankedSpends++;
        return true;
      }

      await consumeAllowance(meter, banked: 3, spendBanked: spendBanked);
      expect(meter.state.used, 1);
      expect(bankedSpends, 0); // week had one left; banked untouched

      await consumeAllowance(meter, banked: 3, spendBanked: spendBanked);
      expect(bankedSpends, 1); // week exhausted; banked drains
      expect(meter.state.used, 1); // meter not double-charged
    });

    test('failed banked spend falls back to the clamped consume', () async {
      final meter = UsageMeter(
        cap: 1,
        store: InMemoryMeterStore(),
        today: () => '2026-06-10',
      );
      await meter.setUsed(1);

      // Server says the banked ledger raced to empty.
      await consumeAllowance(meter, banked: 1, spendBanked: () async => false);
      expect(meter.state.used, 1); // clamped no-op, work not blocked

      // Offline: the spend throws; same graceful end state.
      await consumeAllowance(
        meter,
        banked: 1,
        spendBanked: () async => throw Exception('offline'),
      );
      expect(meter.state.used, 1);
    });
  });
}
