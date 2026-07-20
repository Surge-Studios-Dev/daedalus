/// Requirement-to-implementation coverage for a stamped Surge app, in the
/// ship_check mold: static checks, PASS/WARN/FAIL report, exit 1 on FAIL.
/// The ID discipline makes this nearly free - §6 blocks carry stable IDs,
/// code carries `/// ID` doc comments, §8 lines become test names verbatim
/// - so "every edge case is a test or has a written reason" stops being a
/// self-report. Waivers live in the spec (`- waived: reason` at the end of
/// a §8 case), where they are greppable, not in chat.
library;

import 'dart:io';

import 'package:spec_gen/spec_gen.dart' show reservedPrefixes;
import 'package:spec_gen/spec_parser.dart';

enum CheckStatus { pass, warn, fail }

class CheckResult {
  const CheckResult(this.name, this.status, this.detail);
  final String name;
  final CheckStatus status;
  final String detail;
}

class CoverageReport {
  const CoverageReport(this.checks, this.summary);
  final List<CheckResult> checks;

  /// One line: `coverage: 14/14 P0 screens · §8 41 tested / 2 waived / 0 missing`.
  final String summary;

  bool get failed => checks.any((c) => c.status == CheckStatus.fail);
}

final _docCommentId = RegExp(r'///\s*([A-Z]{2,4}-\d{2})\b');
final _testName = RegExp(r'''(?:testWidgets|test)\(\s*['"](.+?)['"]''');

List<File> _dartFilesUnder(Directory dir) => !dir.existsSync()
    ? const []
    : dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

/// Lowercase, drop `(§8...)` tags, collapse everything non-alphanumeric to
/// single spaces - so a test name matches the spec line it quotes even
/// across punctuation, quotes, and wrapping.
String normalize(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'\(§8[^)]*\)'), ' ')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();

/// True when some test name quotes this §8 case (or vice versa). The
/// shorter side must be >=10 normalized chars so trivial fragments never
/// count as coverage.
bool covers(Iterable<String> testNames, String item) {
  final i = normalize(item);
  for (final name in testNames) {
    final n = normalize(name);
    final shorter = n.length <= i.length ? n : i;
    if (shorter.length < 10) continue;
    if (i.contains(n) || n.contains(i)) return true;
  }
  return false;
}

/// Runs every check against [appDir]. [specPath] defaults to
/// `design/spec.md` inside it. [onlyIds] scopes the screen checks (and the
/// §8 check, to cases naming those IDs) - Phase C2's "run it scoped to the
/// touched IDs".
CoverageReport runCoverage(
  String appDir, {
  String? specPath,
  Set<String>? onlyIds,
}) {
  final checks = <CheckResult>[];
  final specFile = File(specPath ?? '$appDir/design/spec.md');
  if (!specFile.existsSync()) {
    return CoverageReport(
      [
        CheckResult('spec present', CheckStatus.fail,
            'no spec at ${specFile.path} - nothing to cover (spec_gen '
            'generates the skeleton)'),
      ],
      'coverage: no spec',
    );
  }
  final spec = ParsedSpec.parse(specFile.readAsStringSync());

  // The listed universe: §3.2 inventory ∪ §6 blocks ("if a screen isn't
  // listed, it doesn't exist" - checked in both directions below).
  final listed = {
    for (final r in spec.inventory) r.id,
    for (final b in spec.screenBlocks) b.id,
  };

  bool inScope(String id) => onlyIds == null || onlyIds.contains(id);
  final p0 = spec.screenBlocks
      .where((b) => b.phase == 'P0' && inScope(b.id))
      .toList();
  final ahead = spec.screenBlocks
      .where((b) => b.phase == 'P1' || b.phase == 'P2')
      .toList();

  // IDs carried by code (`/// LIB-01` doc comments anywhere under lib/).
  final libIds = <String>{};
  for (final f in _dartFilesUnder(Directory('$appDir/lib'))) {
    for (final m in _docCommentId.allMatches(f.readAsStringSync())) {
      libIds.add(m.group(1)!);
    }
  }

  // -- 1. Every P0 §6 screen is built (its ID is in lib/). -------------------
  final unbuilt = [
    for (final b in p0)
      if (!libIds.contains(b.id)) b.id,
  ];
  checks.add(
    unbuilt.isEmpty
        ? CheckResult('screens built', CheckStatus.pass,
            '${p0.length}/${p0.length} P0 §6 screens carry their /// ID in '
            'lib/')
        : CheckResult('screens built', CheckStatus.fail,
            'P0 §6 screens with no /// ID doc comment in lib/: '
            '${unbuilt.join(', ')}'),
  );

  // -- 2. Every P0 §6 screen is on the board (test/goldens/). ----------------
  final goldens = _dartFilesUnder(Directory('$appDir/test/goldens'))
      .map((f) => f.readAsStringSync())
      .join('\n');
  final unboarded = [
    for (final b in p0)
      if (!goldens.contains(b.id)) b.id,
  ];
  checks.add(
    goldens.isEmpty
        ? const CheckResult('screens on board', CheckStatus.fail,
            'no test/goldens/ - the screen board is the eyes; capture it '
            'before claiming coverage')
        : unboarded.isEmpty
            ? CheckResult('screens on board', CheckStatus.pass,
                '${p0.length}/${p0.length} P0 screens referenced under '
                'test/goldens/')
            : CheckResult('screens on board', CheckStatus.fail,
                'P0 screens missing from test/goldens/: '
                '${unboarded.join(', ')}'),
  );

  // -- 3. Every §8 case is a named test or carries a written waiver. ---------
  final names = <String>[];
  for (final f in _dartFilesUnder(Directory('$appDir/test'))) {
    for (final m in _testName.allMatches(f.readAsStringSync())) {
      names.add(m.group(1)!);
    }
  }
  final items = [
    for (final a in spec.edgeAreas)
      for (final it in a.items)
        if (onlyIds == null ||
            onlyIds.any((id) => it.text.contains(id)))
          it,
  ];
  var tested = 0, waived = 0;
  final untested = <EdgeCaseItem>[];
  for (final it in items) {
    if (it.waiver != null) {
      waived++;
    } else if (covers(names, it.text)) {
      tested++;
    } else {
      untested.add(it);
    }
  }
  if (onlyIds != null && items.isEmpty) {
    checks.add(const CheckResult('§8 coverage', CheckStatus.warn,
        'no §8 case names the scoped IDs - the full sweep still runs at '
        'M6'));
  } else {
    checks.add(
      untested.isEmpty
          ? CheckResult('§8 coverage', CheckStatus.pass,
              '$tested tested, $waived waived - waivers live in the spec, '
              'not chat')
          : CheckResult('§8 coverage', CheckStatus.fail,
              'untested §8 cases (name a test after the line or end it '
              '"- waived: reason"): ${untested.map((it) => 'L${it.line} '
                  '"${it.text.length > 60 ? '${it.text.substring(0, 57)}...' : it.text}"').join(' · ')}'),
    );
  }

  // -- 4. Reverse orphans: IDs in code that the spec never listed. -----------
  final orphans = libIds
      .where((id) =>
          !listed.contains(id) &&
          !reservedPrefixes.contains(id.split('-').first))
      .toList()
    ..sort();
  checks.add(
    orphans.isEmpty
        ? const CheckResult('orphan ids', CheckStatus.pass,
            'every /// ID in lib/ is listed in the spec')
        : CheckResult('orphan ids', CheckStatus.fail,
            'in code but not in §3.2/§6 - if a screen isn\'t listed, it '
            'doesn\'t exist: ${orphans.join(', ')}'),
  );

  // -- 5. Built ahead of phase (P1/P2 IDs already in code). ------------------
  final early = [
    for (final b in ahead)
      if (libIds.contains(b.id)) '${b.id} [${b.phase}]',
  ];
  checks.add(
    early.isEmpty
        ? const CheckResult('phase order', CheckStatus.pass,
            'no P1/P2 screens built ahead of phase')
        : CheckResult('phase order', CheckStatus.warn,
            'built ahead of phase (fine if deliberate - P0 ships first): '
            '${early.join(', ')}'),
  );

  final builtCount = p0.length - unbuilt.length;
  return CoverageReport(
    checks,
    'coverage: $builtCount/${p0.length} P0 screens · '
    '§8 $tested tested / $waived waived / ${untested.length} missing',
  );
}

/// Renders the report; returns the exit code (1 if any fail).
int report(CoverageReport r, StringSink out) {
  const labels = {
    CheckStatus.pass: 'PASS',
    CheckStatus.warn: 'WARN',
    CheckStatus.fail: 'FAIL',
  };
  for (final c in r.checks) {
    out.writeln('[${labels[c.status]}] ${c.name} - ${c.detail}');
  }
  out.writeln(r.summary);
  return r.failed ? 1 : 0;
}
