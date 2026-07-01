import 'dart:io';

import 'package:store_gen/store_gen.dart';
import 'package:yaml/yaml.dart';

/// CLI: `dart run store_gen <manifest> [appDir]`.
/// Writes fastlane/metadata/... under appDir (default: the manifest's
/// directory). Existing files are overwritten - the manifest is the source
/// of truth for store copy; edit it there and regenerate.
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run store_gen <manifest> [appDir]');
    exit(2);
  }
  final manifestFile = File(args[0]);
  if (!manifestFile.existsSync()) {
    stderr.writeln('Manifest not found: ${args[0]}');
    exit(2);
  }
  final doc = loadYaml(manifestFile.readAsStringSync());
  if (doc is! Map) {
    stderr.writeln('Manifest root must be a mapping.');
    exit(2);
  }

  final appDir = args.length > 1 ? args[1] : manifestFile.parent.path;
  final result = buildStoreMetadata(doc);

  result.files.forEach((rel, content) {
    final f = File('$appDir/$rel');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync('$content\n');
  });
  stdout.writeln('Wrote ${result.files.length} metadata files under '
      '$appDir/fastlane/metadata.');
  if (result.warnings.isNotEmpty) {
    stdout.writeln('Warnings (${result.warnings.length}):');
    for (final w in result.warnings) {
      stdout.writeln('  - $w');
    }
  }
}
