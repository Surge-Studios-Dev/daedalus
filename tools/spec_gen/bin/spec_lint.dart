import 'dart:io';

import 'package:spec_gen/spec_lint.dart';
import 'package:yaml/yaml.dart';

/// CLI: `dart run spec_gen:spec_lint <spec.md> [--manifest=path]`.
/// Lints the written spec's TEXT before it is presented for approval
/// (RUNBOOK phase 2: draft -> lint -> fix -> re-lint until clean -> then
/// present). Without a manifest the tab-density and banned-vocabulary
/// checks are skipped. Exits 1 on unwaived findings.
void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  if (positional.isEmpty) {
    stderr.writeln(
      'usage: dart run spec_gen:spec_lint <spec.md> [--manifest=path]',
    );
    exit(2);
  }
  final specFile = File(positional[0]);
  if (!specFile.existsSync()) {
    stderr.writeln('Spec not found: ${positional[0]}');
    exit(2);
  }

  final manifestFlag = args.firstWhere(
    (a) => a.startsWith('--manifest='),
    orElse: () => '',
  );
  // Default: the app-root manifest relative to design/spec.md, then cwd.
  final candidates = manifestFlag.isNotEmpty
      ? [manifestFlag.substring('--manifest='.length)]
      : [
          '${specFile.parent.parent.path}/surge.manifest.yaml',
          '${specFile.parent.path}/surge.manifest.yaml',
          'surge.manifest.yaml',
        ];
  Map? manifest;
  for (final c in candidates) {
    final f = File(c);
    if (f.existsSync()) {
      final doc = loadYaml(f.readAsStringSync());
      if (doc is Map) manifest = doc;
      break;
    }
  }
  if (manifest == null) {
    stdout.writeln('note: no surge.manifest.yaml found - skipping the '
        'tab-density and banned-vocabulary checks (pass --manifest=path).');
  }

  final findings = lintSpec(specFile.readAsStringSync(), manifest: manifest);
  exit(reportLint(findings, stdout));
}
