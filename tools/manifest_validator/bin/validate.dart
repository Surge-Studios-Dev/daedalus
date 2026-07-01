import 'dart:io';

import 'package:manifest_validator/manifest_validator.dart';
import 'package:yaml/yaml.dart';

/// CLI: `dart run manifest_validator [path]` (default surge.manifest.yaml).
/// Exit 0 = valid, 1 = invalid (errors on stderr), 2 = not found / unreadable.
void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : 'surge.manifest.yaml';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Manifest not found: $path');
    exit(2);
  }
  final doc = loadYaml(file.readAsStringSync());
  if (doc is! Map) {
    stderr.writeln('Manifest root must be a mapping.');
    exit(2);
  }
  final errors = validateManifest(doc);
  if (errors.isEmpty) {
    stdout.writeln('OK: $path is valid.');
    exit(0);
  }
  stderr.writeln('Invalid manifest ($path) - ${errors.length} problem(s):');
  for (final e in errors) {
    stderr.writeln('  - $e');
  }
  exit(1);
}
