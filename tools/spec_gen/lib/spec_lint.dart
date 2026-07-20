/// Unit tests for English: interrogates a written spec's TEXT the way
/// P2-RUBBER interrogates the human - before the draft is presented.
/// Checks are convention-grade (see spec_parser.dart): §6 format headers,
/// §8 density per feature tab, vague adjectives with no number attached,
/// leftover TODOs, raw hex, and the manifest's banned vocabulary. A
/// finding is waived by `<!-- lint-waive: reason -->` on the preceding
/// line; waivers are reported, never silent.
library;

import 'spec_parser.dart';

class LintFinding {
  const LintFinding(this.line, this.message, {this.waiveReason});
  final int line;
  final String message;
  final String? waiveReason;
  bool get waived => waiveReason != null;
}

const _formatHeaders = ['Purpose', 'Layout', 'Interactions', 'States', 'Navigation'];
const _statesMustCover = ['loading', 'empty', 'error'];
const _vagueWords = [
  'fast', 'smooth', 'snappy', 'intuitive', 'robust', 'graceful', 'seamless',
  'properly', 'correctly',
];

/// Sections where the palette is *defined* - hex belongs there and only
/// there (§0: everywhere else uses token/style names).
const _hexHomes = {2, 9};

/// Sections a draft must clear of `**TODO**` before presenting.
const _todoSections = {1, 2, 3, 4, 5, 6, 8};

final _todoMark = RegExp(r'\*\*TODO\*\*');
final _rawHex = RegExp(r'#(?:[0-9a-fA-F]{8}|[0-9a-fA-F]{6})\b');
final _htmlComment = RegExp(r'<!--.*?-->', dotAll: true);

/// Lints [source]. [manifest] (the parsed surge.manifest.yaml) enables the
/// feature-tab density and banned-vocabulary checks; without it those are
/// skipped. Returns every finding, waived ones included - the caller
/// decides that waived findings don't fail the run.
List<LintFinding> lintSpec(String source, {Map? manifest}) {
  final spec = ParsedSpec.parse(source);
  final findings = <LintFinding>[];
  void add(int line, String message) {
    findings.add(LintFinding(line, message,
        waiveReason: spec.lintWaiveReason(line)));
  }

  // Strip comment spans so guidance text never trips content checks
  // (works line-wise because the conventions keep comments on their own
  // lines; a multi-line comment is blanked line by line).
  final clean = List<String>.generate(spec.rawLines.length, (i) => spec.rawLines[i]);
  var inComment = false;
  for (var i = 0; i < clean.length; i++) {
    var l = clean[i].replaceAll(_htmlComment, '');
    if (inComment) {
      final end = l.indexOf('-->');
      if (end == -1) {
        l = '';
      } else {
        l = l.substring(end + 3);
        inComment = false;
      }
    }
    final open = l.indexOf('<!--');
    if (open != -1) {
      l = l.substring(0, open);
      inComment = true;
    }
    clean[i] = l;
  }

  // -- 1. §6 blocks carry the five format headers; States covers the trio. --
  for (final b in spec.screenBlocks) {
    final body = b.lines.join('\n');
    final missing = [
      for (final h in _formatHeaders)
        if (!body.contains('**$h:**')) h,
    ];
    if (missing.isNotEmpty) {
      add(b.startLine, '§6 ${b.id}: missing format header(s): '
          '${missing.join(', ')}');
    }
    if (missing.contains('States')) continue;
    final states = StringBuffer();
    var inStates = false;
    for (final l in b.lines) {
      if (l.contains('**States:**')) {
        inStates = true;
      } else if (inStates && RegExp(r'^- \*\*').hasMatch(l)) {
        break;
      }
      if (inStates) states.write(' ${l.toLowerCase()}');
    }
    final uncovered = [
      for (final s in _statesMustCover)
        if (!states.toString().contains(s)) s,
    ];
    if (uncovered.isNotEmpty) {
      add(b.startLine,
          '§6 ${b.id}: States does not cover: ${uncovered.join(', ')}');
    }
  }

  // -- 2. §8 density: 5+ cases per feature tab (the existing gate language,
  //       machine-checked). Needs the manifest for the tab list. ------------
  if (manifest != null) {
    final tabs = (((manifest['navigation'] as Map?)?['tabs'] as List?) ?? const [])
        .whereType<Map>()
        .where((t) => t['type'] == 'feature');
    final eight = spec.section(8);
    for (final t in tabs) {
      final label = '${t['label'] ?? t['id']}'.toLowerCase();
      final matching = spec.edgeAreas
          .where((a) => a.label.toLowerCase().startsWith(label))
          .toList();
      final count =
          matching.fold<int>(0, (sum, a) => sum + a.items.length);
      if (matching.isEmpty) {
        add(eight?.startLine ?? 1,
            '§8: no edge-case area for feature tab "${t['label']}" - '
            'need 5+ cases (if you can\'t name 5, the feature isn\'t '
            'specced yet)');
      } else if (count < 5) {
        add(matching.first.startLine,
            '§8 ${t['label']}: $count case${count == 1 ? '' : 's'} - need '
            '5+ per feature tab');
      }
    }
  }

  // -- 3. Vague adjectives with no number in the sentence. ------------------
  final vague = RegExp(
    '\\b(${_vagueWords.join('|')})\\b',
    caseSensitive: false,
  );
  for (final s in spec.sections) {
    if (s.number < 1) continue;
    for (var i = 0; i < s.lines.length; i++) {
      final line = clean[s.startLine + i]; // body line i is raw line startLine+1+i -> index startLine+i
      for (final m in vague.allMatches(line)) {
        final word = m.group(1)!.toLowerCase();
        if (word == 'fast' &&
            line.toLowerCase().contains('fast follow')) {
          continue;
        }
        final sentence = _sentenceAround(line, m.start, m.end);
        if (!RegExp(r'\d').hasMatch(sentence)) {
          add(s.startLine + 1 + i,
              'vague "$word" - no number shares the sentence (quantify it '
              'or cut it)');
        }
      }
    }
  }

  // -- 4. Leftover TODO markers in the sections a draft must finish. --------
  for (final s in spec.sections) {
    if (!_todoSections.contains(s.number)) continue;
    for (var i = 0; i < s.lines.length; i++) {
      if (_todoMark.hasMatch(clean[s.startLine + i])) {
        add(s.startLine + 1 + i, '§${s.number}: leftover **TODO**');
      }
    }
  }

  // -- 5. Raw hex outside the palette-definition sections (§0 rule). --------
  for (final s in spec.sections) {
    if (s.number < 0 || _hexHomes.contains(s.number)) continue;
    for (var i = 0; i < s.lines.length; i++) {
      final m = _rawHex.firstMatch(clean[s.startLine + i]);
      if (m != null) {
        add(s.startLine + 1 + i, 'raw hex ${m.group(0)} - use surge_ui '
            'token/style names (§0 rule)');
      }
    }
  }

  // -- 6. The manifest's banned vocabulary appearing in spec copy. ----------
  final banned = (((manifest?['brand'] as Map?)?['banned_vocabulary']
              as List?) ??
          const [])
      .map((e) => '$e')
      .where((w) => w.trim().isNotEmpty)
      .toList();
  for (final s in spec.sections) {
    if (s.number < 1) continue;
    for (var i = 0; i < s.lines.length; i++) {
      final line = clean[s.startLine + i];
      if (line.contains('**Banned vocabulary')) continue; // the declaration
      for (final w in banned) {
        if (RegExp('\\b${RegExp.escape(w)}\\b', caseSensitive: false)
            .hasMatch(line)) {
          add(s.startLine + 1 + i,
              'banned vocabulary "$w" (manifest brand block)');
        }
      }
    }
  }

  // -- 7. Status 'final' only with zero TODOs anywhere. ---------------------
  if (spec.status == 'final') {
    final todos =
        clean.fold<int>(0, (n, l) => n + _todoMark.allMatches(l).length);
    if (todos > 0) {
      add(2, 'Status reads "final" with $todos **TODO** marker'
          '${todos == 1 ? '' : 's'} left');
    }
  }

  findings.sort((a, b) => a.line - b.line);
  return findings;
}

String _sentenceAround(String line, int start, int end) {
  const stops = ['.', '!', '?', '·', ';'];
  var lo = 0;
  for (var i = start - 1; i >= 0; i--) {
    if (stops.contains(line[i])) {
      lo = i + 1;
      break;
    }
  }
  var hi = line.length;
  for (var i = end; i < line.length; i++) {
    if (stops.contains(line[i])) {
      hi = i;
      break;
    }
  }
  return line.substring(lo, hi);
}

/// Renders the report; returns the exit code (1 if any unwaived finding).
int reportLint(List<LintFinding> findings, StringSink out) {
  final active = findings.where((f) => !f.waived).toList();
  final waived = findings.where((f) => f.waived).toList();
  for (final f in active) {
    out.writeln('  line ${f.line}: ${f.message}');
  }
  for (final f in waived) {
    out.writeln('  line ${f.line}: waived (${f.waiveReason}) - ${f.message}');
  }
  out.writeln(active.isEmpty
      ? 'spec_lint: clean'
          '${waived.isEmpty ? '' : ' (${waived.length} waived)'}.'
      : 'spec_lint: ${active.length} finding${active.length == 1 ? '' : 's'}'
          '${waived.isEmpty ? '' : ' (+${waived.length} waived)'} - fix and '
          're-lint before presenting the draft.');
  return active.isEmpty ? 0 : 1;
}
