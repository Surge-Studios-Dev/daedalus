import 'dart:io';

import 'package:ship_check/ship_check.dart';
import 'package:yaml/yaml.dart';

/// CLI: `dart run ship_check [appDir] [--manifest=path] [--run-tests]`.
/// appDir defaults to the current directory; the manifest defaults to
/// surge.manifest.yaml inside it. Exits 1 if any check fails.
Future<void> main(List<String> args) async {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final appDir = (positional.isEmpty ? '.' : positional[0])
      .replaceAll('\\', '/')
      .replaceAll(RegExp(r'/$'), '');

  final manifestFlag = args.firstWhere(
    (a) => a.startsWith('--manifest='),
    orElse: () => '',
  );
  final manifestPath = manifestFlag.isNotEmpty
      ? manifestFlag.substring('--manifest='.length)
      : '$appDir/surge.manifest.yaml';

  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('Manifest not found: $manifestPath');
    exit(2);
  }
  final doc = loadYaml(manifestFile.readAsStringSync());
  if (doc is! Map) {
    stderr.writeln('Manifest root must be a mapping.');
    exit(2);
  }

  final results = await runChecks(
    appDir,
    doc,
    runTests: args.contains('--run-tests'),
  );
  exit(report(results, stdout));
}
