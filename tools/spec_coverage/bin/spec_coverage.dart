import 'dart:io';

import 'package:spec_coverage/spec_coverage.dart';

/// CLI: `dart run spec_coverage [appDir] [--spec=path] [--ids=COU-01,COU-02]`.
/// appDir defaults to the current directory; the spec defaults to
/// design/spec.md inside it. `--ids` scopes the run to the touched screen
/// IDs (Phase C2). Exits 1 if any check fails.
void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final appDir = (positional.isEmpty ? '.' : positional[0])
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/$'), '');

  String? flag(String name) {
    final v = args.firstWhere((a) => a.startsWith('--$name='), orElse: () => '');
    return v.isEmpty ? null : v.substring(name.length + 3);
  }

  final ids = flag('ids')
      ?.split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();

  final result = runCoverage(appDir, specPath: flag('spec'), onlyIds: ids);
  exit(report(result, stdout));
}
