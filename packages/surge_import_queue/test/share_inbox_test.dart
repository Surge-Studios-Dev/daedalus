import 'package:flutter_test/flutter_test.dart';
import 'package:surge_import_queue/surge_import_queue.dart';

void main() {
  group('ShareInbox', () {
    test('add dedupes; a re-share keeps its original position', () async {
      final inbox = ShareInbox(InMemoryInboxStore());
      await inbox.add('a');
      await inbox.add('b');
      await inbox.add('a'); // re-share
      expect(await inbox.all(), ['a', 'b']);
    });

    test('remove drops the entry and its metadata', () async {
      final store = InMemoryInboxStore();
      final inbox = ShareInbox(store);
      await inbox.add('a');
      await inbox.markMetered('a');
      await inbox.remove('a');
      expect(await inbox.all(), isEmpty);
      // Metadata must not leak: a future re-share of the same value is a
      // brand-new entry that has NOT been charged.
      expect(await inbox.isMetered('a'), isFalse);
    });

    test('metered flag survives a cold-start replay', () async {
      final store = InMemoryInboxStore();
      final a = ShareInbox(store);
      await a.add('url');
      await a.markMetered('url');

      final b = ShareInbox(store); // new launch, same store
      expect(await b.isMetered('url'), isTrue);
      expect(await b.isMetered('other'), isFalse);
    });

    test('bumpFailures counts across launches', () async {
      final store = InMemoryInboxStore();
      expect(await ShareInbox(store).bumpFailures('bad'), 1);
      expect(await ShareInbox(store).bumpFailures('bad'), 2);
      expect(await ShareInbox(store).bumpFailures('bad'), 3);
      expect(await ShareInbox(store).bumpFailures('fine'), 1);
    });

    test('corrupt metadata reads as empty instead of crashing the drain',
        () async {
      final store = InMemoryInboxStore();
      store.strings['intake.inbox.meta'] = 'not-json{';
      final inbox = ShareInbox(store);
      expect(await inbox.isMetered('a'), isFalse);
      expect(await inbox.bumpFailures('a'), 1);
    });

    test('keyPrefix isolates independent inboxes', () async {
      final store = InMemoryInboxStore();
      final imports = ShareInbox(store, keyPrefix: 'imports');
      final clips = ShareInbox(store, keyPrefix: 'clips');
      await imports.add('a');
      await clips.add('b');
      expect(await imports.all(), ['a']);
      expect(await clips.all(), ['b']);
    });
  });

  group('DrainCoalescer', () {
    test('overlapping triggers coalesce into exactly one re-run', () async {
      final coalescer = DrainCoalescer();
      final runs = <int>[];
      var n = 0;

      Future<void> slowDrain() async {
        final id = ++n;
        runs.add(id);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final first = coalescer.run(slowDrain);
      // Three triggers land mid-drain: resume + drainNow + credits listener.
      final b = coalescer.run(slowDrain);
      final c = coalescer.run(slowDrain);
      final d = coalescer.run(slowDrain);
      await Future.wait([first, b, c, d]);

      expect(runs, [1, 2]); // one run + one coalesced re-run, never four
    });

    test('a trigger after completion runs fresh', () async {
      final coalescer = DrainCoalescer();
      var runs = 0;
      Future<void> drain() async => runs++;
      await coalescer.run(drain);
      await coalescer.run(drain);
      expect(runs, 2);
    });
  });
}
