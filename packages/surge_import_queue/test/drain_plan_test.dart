import 'package:flutter_test/flutter_test.dart';
import 'package:surge_import_queue/surge_import_queue.dart';

void main() {
  group('planDrain', () {
    test(
      'fresh share outranks older queued entries for a limited allowance',
      () {
        // Regression: 2 stuck replays + 1 fresh share with 1 credit left used
        // to start the OLDEST stuck entry and silently skip the fresh share.
        final plan = planDrain(
          all: ['old-1', 'old-2', 'fresh'],
          fresh: ['fresh'],
          active: const {},
          allowed: 1,
        );
        expect(plan.start, ['fresh']);
        expect(plan.presentKey, 'fresh');
        expect(plan.freshBlocked, isFalse);
        expect(plan.leftQueued, 2);
      },
    );

    test('re-shared OLD inbox entry still wins the allowance', () {
      // inbox dedup keeps a re-shared payload at its old position; freshness
      // is decided by this drain's platform queue, not inbox order.
      final plan = planDrain(
        all: ['old-reshared', 'old-2'],
        fresh: ['old-reshared'],
        active: const {},
        allowed: 1,
      );
      expect(plan.start, ['old-reshared']);
      expect(plan.presentKey, 'old-reshared');
      expect(plan.freshBlocked, isFalse);
      expect(plan.leftQueued, 1);
    });

    test('at zero allowance a fresh share is blocked, not silent', () {
      final plan = planDrain(
        all: ['old-1', 'fresh'],
        fresh: ['fresh'],
        active: const {},
        allowed: 0,
      );
      expect(plan.start, isEmpty);
      expect(plan.presentKey, isNull);
      expect(plan.freshBlocked, isTrue);
      expect(plan.leftQueued, 2);
    });

    test('re-share of a payload already running reuses the job', () {
      final plan = planDrain(
        all: ['running', 'old-1'],
        fresh: ['running'],
        active: const {'running': 'job-1'},
        allowed: 0,
      );
      expect(plan.start, isEmpty);
      expect(plan.presentKey, 'running'); // UI surfaces the running job
      expect(plan.freshBlocked, isFalse); // it IS running - no warning
      expect(plan.leftQueued, 1);
    });

    test('full allowance starts everything, newest first after fresh', () {
      final plan = planDrain(
        all: ['old-1', 'old-2', 'fresh'],
        fresh: ['fresh'],
        active: const {},
        allowed: 3,
      );
      expect(plan.start, ['fresh', 'old-2', 'old-1']);
      expect(plan.leftQueued, 0);
      expect(plan.freshBlocked, isFalse);
    });

    test('background drain (no fresh) replays newest first, no warning', () {
      final plan = planDrain(
        all: ['old-1', 'old-2'],
        fresh: const [],
        active: const {},
        allowed: 1,
      );
      expect(plan.start, ['old-2']);
      expect(plan.presentKey, 'old-2');
      expect(plan.freshBlocked, isFalse);
      expect(plan.leftQueued, 1);
    });

    test('multiple fresh shares: the LAST shared payload gets the sheet', () {
      final plan = planDrain(
        all: ['fresh-a', 'fresh-b'],
        fresh: ['fresh-a', 'fresh-b'],
        active: const {},
        allowed: 2,
      );
      expect(plan.start, ['fresh-b', 'fresh-a']);
      expect(plan.presentKey, 'fresh-b');
    });

    test('empty inbox is a clean no-op', () {
      final plan = planDrain(
        all: const [],
        fresh: const [],
        active: const {},
        allowed: 5,
      );
      expect(plan.start, isEmpty);
      expect(plan.presentKey, isNull);
      expect(plan.freshBlocked, isFalse);
      expect(plan.leftQueued, 0);
    });
  });
}
