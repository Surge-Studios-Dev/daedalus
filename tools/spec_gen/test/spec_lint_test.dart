import 'dart:io';

import 'package:spec_gen/spec_lint.dart';
import 'package:spec_gen/spec_parser.dart';
import 'package:test/test.dart';

Map lintManifest() => {
      'navigation': {
        'tabs': [
          {'id': 'counters', 'label': 'Counters', 'type': 'feature'},
          {'id': 'you', 'label': 'You', 'type': 'builtin'},
        ],
      },
      'brand': {
        'banned_vocabulary': ['guilt trip', 'streak-shame'],
      },
    };

/// A minimal spec that passes every check - each test breaks one thing.
String goodSpec() => '''
# Tally · Product Spec
**Version 0.1 · 2026-07-19 · Status: draft**

## 0. How to read this document

- Phase tags: **[P0]** launch build, **[P1]** fast follow.

## 1. Product overview

- **One-liner:** Count anything, see the streak.

## 2. Design language

Themed from the manifest palette: accent `#75D8FF` (hex lives here legally).

## 3. Information architecture

### 3.2 Screen inventory

| ID | Screen | Phase | Source |
|---|---|---|---|
| COU-01 | Counters home | P0 | you |

## 5. Copy & tone

- **Banned vocabulary:** guilt trip, streak-shame.
- **Voice notes:** plain, warm, short.

## 6. Screen-by-screen specification

### COU-01 · Counters home [P0]

- **Purpose:** every counter, one glance.
- **Layout:** list of counter cards.
- **Interactions:** tap opens detail; long-press reorders.
- **States:** loading skeleton / empty first-run invite / error banner.
- **Navigation:** in - tab; out - detail.

## 8. Edge-case master list (QA checklist)

- **Counters:** rename to empty string · 200+ counters · delete while
  widget shows it · concurrent edit on two devices · count past 1,000,000.

## 11. Open questions

### Open

### Resolved

## 12. Assumptions
''';

void main() {
  test('a clean spec produces zero findings', () {
    expect(lintSpec(goodSpec(), manifest: lintManifest()), isEmpty);
  });

  test('§6 block missing a format header is flagged', () {
    final spec = goodSpec()
        .replaceFirst('- **Interactions:** tap opens detail; long-press reorders.\n', '');
    final f = lintSpec(spec, manifest: lintManifest());
    expect(f, hasLength(1));
    expect(f.single.message, contains('COU-01'));
    expect(f.single.message, contains('missing format header(s): Interactions'));
  });

  test('States must cover loading + empty + error', () {
    final spec = goodSpec().replaceFirst(
      '- **States:** loading skeleton / empty first-run invite / error banner.',
      '- **States:** loading skeleton only.',
    );
    final f = lintSpec(spec, manifest: lintManifest());
    expect(f.single.message, contains('States does not cover: empty, error'));
  });

  test('a feature tab with <5 §8 cases is flagged; the count is right', () {
    final spec = goodSpec().replaceFirst(
      RegExp(r'- \*\*Counters:\*\*[^\n]*\n[^\n]*\n[^\n]*\n'),
      '- **Counters:** rename to empty string · 200+ counters.\n',
    );
    final f = lintSpec(spec, manifest: lintManifest());
    expect(f.single.message, contains('§8 Counters: 2 cases - need 5+'));
  });

  test('a feature tab with no §8 area at all is flagged', () {
    final m = lintManifest();
    ((m['navigation'] as Map)['tabs'] as List).insert(1, {
      'id': 'insights',
      'label': 'Insights',
      'type': 'feature',
    });
    final f = lintSpec(goodSpec(), manifest: m);
    expect(f.single.message, contains('no edge-case area for feature tab "Insights"'));
  });

  test('vague adjectives need a number in the sentence; fast follow is exempt', () {
    final spec = goodSpec().replaceFirst(
      '- **One-liner:** Count anything, see the streak.',
      '- **One-liner:** Counting that feels fast and robust.\n'
          '- **The core loop:** import completes in 3 s, fast on every device.',
    );
    final f = lintSpec(spec, manifest: lintManifest());
    // 'fast' and 'robust' on the numberless line; the 3 s line is fine, and
    // §0's 'fast follow' never fires.
    expect(f, hasLength(2));
    expect(f[0].message, contains('vague "fast"'));
    expect(f[1].message, contains('vague "robust"'));
  });

  test('leftover **TODO** in §1-6/§8 is flagged; guidance comments are not', () {
    final spec = goodSpec().replaceFirst(
      '- **Voice notes:** plain, warm, short.',
      '- **Voice notes:** **TODO** - 2-3 lines max\n'
          '<!-- a **TODO** inside a comment is guidance, not debt -->',
    );
    final f = lintSpec(spec, manifest: lintManifest());
    expect(f.single.message, contains('§5: leftover **TODO**'));
  });

  test('raw hex outside §2/§9 is flagged', () {
    final spec = goodSpec().replaceFirst(
      '- **Layout:** list of counter cards.',
      '- **Layout:** list of counter cards on #0E1B27.',
    );
    final f = lintSpec(spec, manifest: lintManifest());
    expect(f.single.message, contains('raw hex #0E1B27'));
  });

  test('banned vocabulary is flagged everywhere except its declaration', () {
    final spec = goodSpec().replaceFirst(
      '- **Purpose:** every counter, one glance.',
      '- **Purpose:** a gentle guilt trip toward your goals.',
    );
    final f = lintSpec(spec, manifest: lintManifest());
    expect(f.single.message, contains('banned vocabulary "guilt trip"'));
  });

  test('lint-waive on the preceding line waives the finding, visibly', () {
    final spec = goodSpec().replaceFirst(
      '- **One-liner:** Count anything, see the streak.',
      '<!-- lint-waive: brand voice, approved 2026-07-19 -->\n'
          '- **One-liner:** Counting that feels seamless.',
    );
    final f = lintSpec(spec, manifest: lintManifest());
    expect(f.single.waived, isTrue);
    expect(f.single.waiveReason, contains('brand voice'));
    final out = StringBuffer();
    expect(reportLint(f, out), 0);
    expect(out.toString(), contains('waived (brand voice'));
  });

  test('Status final with TODOs left anywhere is flagged', () {
    final spec = goodSpec()
        .replaceFirst('Status: draft', 'Status: final')
        .replaceFirst('## 12. Assumptions', '## 12. Assumptions\n\n**TODO** - migrate');
    final f = lintSpec(spec, manifest: lintManifest());
    expect(f.single.message, contains('Status reads "final" with 1 **TODO**'));
  });

  test('reportLint exits 1 on unwaived findings', () {
    final f = lintSpec(
      goodSpec().replaceFirst('error banner.', 'banner.'),
      manifest: lintManifest(),
    );
    final out = StringBuffer();
    expect(reportLint(f, out), 1);
    expect(out.toString(), contains('finding'));
  });

  test('parses the real Ember example: blocks, phases, §8 areas', () {
    final spec = ParsedSpec.parse(
      File('../../examples/ember.spec-sections.md').readAsStringSync(),
    );
    expect(spec.screenBlocks, hasLength(11));
    expect(spec.screenBlocks.first.id, 'WID-01');
    expect(spec.screenBlocks.first.phase, 'P0');
    expect(spec.screenBlocks.last.id, 'GRO-06');
    expect(spec.screenBlocks.last.phase, 'P1');
    final labels = spec.edgeAreas.map((a) => a.label).toList();
    expect(labels, ['Today', 'Groups', 'Widget (quality bar)', 'System']);
    final today = spec.edgeAreas.first;
    expect(today.items.length, greaterThanOrEqualTo(8));
  });
}
