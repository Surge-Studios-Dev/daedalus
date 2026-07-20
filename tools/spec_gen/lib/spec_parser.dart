/// Shared parser for written specs (design/spec.md) - the structural
/// conventions spec_gen emits and the docs enforce: `## N.` sections,
/// `### XXX-01` screen blocks with phase tags, the §3.2 inventory table,
/// and §8 edge-case areas (`- **Area:** case · case` or one bullet per
/// case). Consumed by spec_lint (this package) and spec_coverage
/// (tools/spec_coverage). Regex-grade on purpose: it parses the
/// conventions, not arbitrary markdown.
library;

/// `### LIB-01 · Title` - the stable screen-ID convention.
final screenIdHeader = RegExp(r'^### ([A-Z]{2,4}-\d{2})\b');

/// A phase tag anywhere in a line: `[P0]` / `[P1]` / `[P2]`.
final phaseTag = RegExp(r'\[(P[0-2])\]');

/// An edge case ending `- waived: reason` (any dash) is waived - M6's
/// "written reason", living in the spec where it is greppable.
final waivedMark = RegExp(r'[-–—]\s*waived:\s*(.+?)\s*$');

/// `<!-- lint-waive: reason -->` on the line before a finding waives it.
final lintWaive = RegExp(r'<!--\s*lint-waive:\s*(.+?)\s*-->');

class SpecSection {
  const SpecSection(this.number, this.header, this.startLine, this.lines);

  /// Leading number of `## N. Title`, or -1 for unnumbered `##` headers.
  final int number;
  final String header;

  /// 1-indexed line of the `## ` header.
  final int startLine;

  /// Body lines up to (not including) the next `## ` header.
  final List<String> lines;
}

class ScreenBlock {
  const ScreenBlock(this.id, this.header, this.phase, this.startLine, this.lines);
  final String id;
  final String header;

  /// 'P0' | 'P1' | 'P2' | null when the header carries no tag.
  final String? phase;
  final int startLine;
  final List<String> lines;
}

class InventoryEntry {
  const InventoryEntry(this.id, this.screen, this.phase, this.source, this.line);
  final String id;
  final String screen;
  final String phase;
  final String source;
  final int line;
}

class EdgeCaseItem {
  const EdgeCaseItem(this.text, this.line, this.waiver);
  final String text;
  final int line;

  /// The written reason when the item ends `- waived: <reason>`.
  final String? waiver;
}

class EdgeCaseArea {
  const EdgeCaseArea(this.label, this.startLine, this.items);

  /// The bold prefix (`- **Today:** ...`), or '' for unlabeled bullets.
  final String label;
  final int startLine;
  final List<EdgeCaseItem> items;
}

class ParsedSpec {
  ParsedSpec.parse(String source) {
    rawLines = source.replaceAll('\r\n', '\n').split('\n');

    // Status from the version line ('**Version 0.1 · date · Status: draft**').
    var st = '';
    for (final l in rawLines.take(5)) {
      final m = RegExp(r'Status:\s*([A-Za-z]+)').firstMatch(l);
      if (m != null) {
        st = m.group(1)!.toLowerCase();
        break;
      }
    }
    status = st;

    // Sections.
    sections = [];
    SpecSection? open;
    var openBody = <String>[];
    void close() {
      final o = open;
      if (o != null) {
        sections.add(SpecSection(o.number, o.header, o.startLine, openBody));
      }
    }

    for (var i = 0; i < rawLines.length; i++) {
      final l = rawLines[i];
      if (l.startsWith('## ')) {
        close();
        final head = l.substring(3).trim();
        final num = RegExp(r'^(\d+)\.').firstMatch(head);
        open = SpecSection(
          num == null ? -1 : int.parse(num.group(1)!),
          head,
          i + 1,
          const [],
        );
        openBody = [];
      } else if (open != null) {
        openBody.add(l);
      }
    }
    close();

    screenBlocks = _parseScreenBlocks();
    inventory = _parseInventory();
    edgeAreas = _parseEdgeAreas();
  }

  late final List<String> rawLines;
  late final String status;
  late final List<SpecSection> sections;

  /// §6 blocks whose `###` header carries a screen ID.
  late final List<ScreenBlock> screenBlocks;

  /// §3.2 table rows whose first cell is a screen ID.
  late final List<InventoryEntry> inventory;

  /// §8 areas with their (·-split or per-bullet) items.
  late final List<EdgeCaseArea> edgeAreas;

  SpecSection? section(int n) {
    for (final s in sections) {
      if (s.number == n) return s;
    }
    return null;
  }

  /// True when the line directly above [line] (1-indexed) carries a
  /// `<!-- lint-waive: ... -->` comment.
  bool isLintWaived(int line) => lintWaiveReason(line) != null;

  String? lintWaiveReason(int line) {
    if (line < 2 || line > rawLines.length) return null;
    return lintWaive.firstMatch(rawLines[line - 2])?.group(1);
  }

  List<ScreenBlock> _parseScreenBlocks() {
    final six = section(6);
    if (six == null) return const [];
    final blocks = <ScreenBlock>[];
    String? id;
    String header = '';
    String? phase;
    var start = 0;
    var body = <String>[];
    void close() {
      final theId = id;
      if (theId != null) {
        blocks.add(ScreenBlock(theId, header, phase, start, body));
      }
    }

    for (var i = 0; i < six.lines.length; i++) {
      final l = six.lines[i];
      if (l.startsWith('### ')) {
        close();
        final m = screenIdHeader.firstMatch(l);
        if (m == null) {
          id = null; // '### Factory screens ...' - not an ID block
        } else {
          id = m.group(1);
          header = l.substring(4).trim();
          phase = phaseTag.firstMatch(l)?.group(1);
          start = six.startLine + 1 + i;
          body = [];
        }
      } else if (id != null) {
        body.add(l);
      }
    }
    close();
    return blocks;
  }

  List<InventoryEntry> _parseInventory() {
    final three = section(3);
    if (three == null) return const [];
    final idCell = RegExp(r'^[A-Z]{2,4}-\d{2}$');
    final rows = <InventoryEntry>[];
    for (var i = 0; i < three.lines.length; i++) {
      final l = three.lines[i].trim();
      if (!l.startsWith('|')) continue;
      final cells = l
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (cells.length < 2 || !idCell.hasMatch(cells[0])) continue;
      rows.add(InventoryEntry(
        cells[0],
        cells.length > 1 ? cells[1] : '',
        cells.length > 2 ? cells[2] : '',
        cells.length > 3 ? cells[3] : '',
        three.startLine + 1 + i,
      ));
    }
    return rows;
  }

  List<EdgeCaseArea> _parseEdgeAreas() {
    final eight = section(8);
    if (eight == null) return const [];
    final areaStart = RegExp(r'^- \*\*(.+?):\*\*\s*(.*)$');
    final areas = <EdgeCaseArea>[];
    var open = false;
    var label = '';
    var start = 0;
    var content = StringBuffer();
    void close() {
      if (!open) return;
      open = false;
      final items = <EdgeCaseItem>[];
      for (final part in content.toString().split('·')) {
        final text = part.trim().replaceAll(RegExp(r'[.\s]+$'), '');
        if (text.isEmpty) continue;
        items.add(EdgeCaseItem(text, start, waivedMark.firstMatch(text)?.group(1)));
      }
      areas.add(EdgeCaseArea(label, start, items));
    }

    for (var i = 0; i < eight.lines.length; i++) {
      final l = eight.lines[i];
      final abs = eight.startLine + 1 + i;
      final m = areaStart.firstMatch(l);
      if (m != null) {
        // '- **Area:** case · case' style: one area, ·-separated items.
        close();
        open = true;
        label = m.group(1)!;
        start = abs;
        content = StringBuffer(m.group(2)!);
      } else if (l.startsWith('- ')) {
        // One-bullet-per-case style: each plain bullet is one unlabeled item.
        close();
        open = true;
        label = '';
        start = abs;
        content = StringBuffer(l.substring(2).trim());
      } else if (open && l.trim().isNotEmpty && !l.startsWith('#')) {
        content.write(' ${l.trim()}');
      } else if (l.trim().isEmpty) {
        close();
      }
    }
    close();
    return areas;
  }
}
