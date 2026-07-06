import 'package:flutter_test/flutter_test.dart';
import 'package:surge_core/surge_core.dart';

const today = '2026-06-10'; // a Wednesday

void main() {
  group('dates', () {
    test('iso round trip and addDays', () {
      expect(toIso(parseIso('2026-06-08')), '2026-06-08');
      expect(addDays('2026-06-08', 6), '2026-06-14');
      expect(addDays('2026-06-30', 1), '2026-07-01');
      expect(addDays('2026-01-01', -1), '2025-12-31');
    });

    test('parseIso tolerates a full ISO datetime (stray timestamp)', () {
      expect(toIso(parseIso('2026-06-18T11:56:20.339268')), '2026-06-18');
      expect(fmtDowFull('2026-06-18T11:56:20.339268'), 'Thursday');
    });

    test('weekDays yields 7 consecutive days across DST shifts', () {
      // US spring-forward week (Mar 8 2026)
      final days = weekDays('2026-03-08');
      expect(days.length, 7);
      expect(days.last, '2026-03-14');
      expect(days.toSet().length, 7);
    });

    test('day-of-week labels', () {
      expect(fmtDow('2026-06-08'), 'Mon');
      expect(fmtDow('2026-06-14'), 'Sun');
      expect(fmtDowFull('2026-06-10'), 'Wednesday');
      expect(fmtDayShort('2026-06-08'), 'Jun 8');
    });

    test('today / past', () {
      expect(isToday('2026-06-10', today: today), isTrue);
      expect(isPast('2026-06-09', today: today), isTrue);
      expect(isPast('2026-06-10', today: today), isFalse);
    });

    test('week range and labels', () {
      expect(fmtWeekRange('2026-06-08'), 'Jun 8–14');
      expect(fmtWeekRange('2026-06-29'), 'Jun 29–Jul 5');
      expect(
        weekLabel('2026-06-08', currentWeekStart: '2026-06-08'),
        'This week',
      );
      expect(
        weekLabel('2026-06-15', currentWeekStart: '2026-06-08'),
        'Next week',
      );
      expect(
        weekLabel('2026-06-01', currentWeekStart: '2026-06-08'),
        'Last week',
      );
      expect(
        weekLabel('2026-07-06', currentWeekStart: '2026-06-08'),
        'Jul 6–12',
      );
    });

    test('relative dates', () {
      expect(fmtRelDate('2026-06-10', today: today), 'Today');
      expect(fmtRelDate('2026-06-09', today: today), 'Yesterday');
      expect(fmtRelDate('2026-06-06', today: today), '4 days ago');
      expect(fmtRelDate('2026-05-20', today: today), 'May 20');
      expect(fmtRelDate(null, today: today), '');
    });

    test('weekStartOf honors the week-start setting (mid-data change)', () {
      expect(weekStartOf('2026-06-10'), '2026-06-08'); // Mon default
      expect(weekStartOf('2026-06-10', weekStartsOn: 'Sun'), '2026-06-07');
      expect(weekStartOf('2026-06-08'), '2026-06-08'); // already Monday
      expect(weekStartOf('2026-06-14', weekStartsOn: 'Sun'), '2026-06-14');
    });

    test('weekDocKeysFor covers both week-start alignments, deduped', () {
      // A midweek day maps to exactly two candidate docs.
      expect(weekDocKeysFor(['2026-06-10']), ['2026-06-08', '2026-06-07']);
      // A full Mon-start week needs the two flanking Sun-start docs too.
      final keys = weekDocKeysFor(weekDays('2026-06-08'));
      expect(keys.toSet(), {
        '2026-06-08', // Mon-start doc
        '2026-06-07', // Sun-start doc covering Mon..Sat
        '2026-06-14', // Sun-start doc covering the trailing Sunday
      });
    });
  });
}
