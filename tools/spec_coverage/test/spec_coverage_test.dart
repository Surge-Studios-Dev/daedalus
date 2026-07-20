import 'dart:io';

import 'package:spec_coverage/spec_coverage.dart';
import 'package:test/test.dart';

const _spec = '''
# Tally · Product Spec
**Version 0.1 · 2026-07-19 · Status: final**

## 3. Information architecture

### 3.2 Screen inventory

| ID | Screen | Phase | Source |
|---|---|---|---|
| SET-01 | Settings home | P0 | foundation |
| COU-01 | Counters home | P0 | you |
| COU-02 | Counter detail | P0 | you |
| INS-01 | Insights home | P1 | you |

## 6. Screen-by-screen specification

### Factory screens (provided - spec only the deltas)

- **SET-01 · Settings.** Provided.

### COU-01 · Counters home [P0]

- **Purpose:** every counter, one glance.

### COU-02 · Counter detail [P0]

- **Purpose:** one counter, full history.

### INS-01 · Insights home [P1]

- **Purpose:** trends over time.

## 8. Edge-case master list (QA checklist)

- **Counters:** rename to empty string keeps the previous name ·
  count past 1,000,000 stays formatted · delete while the widget shows
  it - waived: widget ships in P1 · concurrent edit on two devices keeps
  last write per field.
''';

/// A fixture app where everything is covered; individual tests break one
/// thing each.
Directory coveredApp() {
  final d = Directory.systemTemp.createTempSync('speccov');
  void put(String rel, String content) {
    final f = File('${d.path}/$rel');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  }

  put('design/spec.md', _spec);
  put('lib/features/counters/counters_home.dart',
      '/// COU-01 · Counters home\nclass CountersHome {}\n');
  put('lib/features/counters/counter_detail.dart',
      '/// COU-02 · Counter detail\nclass CounterDetail {}\n');
  put('test/goldens/screen_board.dart',
      "// board specs\nconst ids = ['COU-01', 'COU-02'];\n");
  put('test/counters_test.dart', '''
void main() {
  test('rename to empty string keeps the previous name (§8)', () {});
  test('count past 1,000,000 stays formatted (§8)', () {});
  test('concurrent edit on two devices keeps last write per field (§8)', () {});
}
''');
  return d;
}

CheckResult byName(CoverageReport r, String name) =>
    r.checks.firstWhere((c) => c.name == name);

void main() {
  test('a fully covered app passes; the summary counts are right', () {
    final d = coveredApp();
    final r = runCoverage(d.path);
    expect(r.failed, isFalse,
        reason: r.checks.map((c) => '${c.name}: ${c.detail}').join('\n'));
    expect(r.summary, 'coverage: 2/2 P0 screens · §8 3 tested / 1 waived / 0 missing');
    expect(report(r, StringBuffer()), 0);
    d.deleteSync(recursive: true);
  });

  test('a P0 screen with no /// ID doc comment in lib/ fails', () {
    final d = coveredApp();
    File('${d.path}/lib/features/counters/counter_detail.dart')
        .writeAsStringSync('class CounterDetail {}\n');
    final r = runCoverage(d.path);
    final c = byName(r, 'screens built');
    expect(c.status, CheckStatus.fail);
    expect(c.detail, contains('COU-02'));
    d.deleteSync(recursive: true);
  });

  test('a P0 screen missing from test/goldens/ fails', () {
    final d = coveredApp();
    File('${d.path}/test/goldens/screen_board.dart')
        .writeAsStringSync("const ids = ['COU-01'];\n");
    final r = runCoverage(d.path);
    expect(byName(r, 'screens on board').status, CheckStatus.fail);
    expect(byName(r, 'screens on board').detail, contains('COU-02'));
    d.deleteSync(recursive: true);
  });

  test('an untested, unwaived §8 case fails with its line number', () {
    final d = coveredApp();
    File('${d.path}/test/counters_test.dart').writeAsStringSync('''
void main() {
  test('rename to empty string keeps the previous name (§8)', () {});
  test('concurrent edit on two devices keeps last write per field (§8)', () {});
}
''');
    final r = runCoverage(d.path);
    final c = byName(r, '§8 coverage');
    expect(c.status, CheckStatus.fail);
    expect(c.detail, contains('count past 1,000,000'));
    expect(c.detail, contains('L'));
    d.deleteSync(recursive: true);
  });

  test('an /// ID in code that the spec never listed fails (orphan)', () {
    final d = coveredApp();
    File('${d.path}/lib/features/mystery.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('/// ZZZ-99 · Mystery screen\nclass M {}\n');
    final r = runCoverage(d.path);
    expect(byName(r, 'orphan ids').status, CheckStatus.fail);
    expect(byName(r, 'orphan ids').detail, contains('ZZZ-99'));
    d.deleteSync(recursive: true);
  });

  test('factory-reserved prefixes are never orphans', () {
    final d = coveredApp();
    File('${d.path}/lib/modules/settings/extra.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('/// SET-09 · Extra settings row\nclass E {}\n');
    final r = runCoverage(d.path);
    expect(byName(r, 'orphan ids').status, CheckStatus.pass);
    d.deleteSync(recursive: true);
  });

  test('a P1 screen already in code warns (built ahead of phase)', () {
    final d = coveredApp();
    File('${d.path}/lib/features/insights/insights_home.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('/// INS-01 · Insights home\nclass I {}\n');
    final r = runCoverage(d.path);
    final c = byName(r, 'phase order');
    expect(c.status, CheckStatus.warn);
    expect(c.detail, contains('INS-01 [P1]'));
    expect(r.failed, isFalse);
    d.deleteSync(recursive: true);
  });

  test('--ids scopes the screen checks to the touched IDs (Phase C2)', () {
    final d = coveredApp();
    // COU-02 loses its doc comment, but the scoped run only asks about COU-01.
    File('${d.path}/lib/features/counters/counter_detail.dart')
        .writeAsStringSync('class CounterDetail {}\n');
    final scoped = runCoverage(d.path, onlyIds: {'COU-01'});
    expect(byName(scoped, 'screens built').status, CheckStatus.pass);
    // No §8 case names COU-01 explicitly -> deferred to M6, not failed.
    expect(byName(scoped, '§8 coverage').status, CheckStatus.warn);
    d.deleteSync(recursive: true);
  });

  test('a missing spec is a fail, not a crash', () {
    final d = Directory.systemTemp.createTempSync('speccov');
    final r = runCoverage(d.path);
    expect(r.failed, isTrue);
    expect(r.summary, 'coverage: no spec');
    d.deleteSync(recursive: true);
  });
}
