import 'dart:io';

import 'package:spec_gen/spec_gen.dart';
import 'package:yaml/yaml.dart';

/// CLI: `dart run spec_gen <manifest> [outFile] [--date=YYYY-MM-DD]`.
/// Default outFile is `design/spec.md` next to the manifest. Refuses to
/// overwrite an existing spec unless `--force` is passed - a written spec is
/// human work; regeneration destroys it.
void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  if (positional.isEmpty) {
    stderr.writeln(
      'usage: dart run spec_gen <manifest> [outFile] [--date=YYYY-MM-DD] [--force]',
    );
    exit(2);
  }
  final manifestFile = File(positional[0]);
  if (!manifestFile.existsSync()) {
    stderr.writeln('Manifest not found: ${positional[0]}');
    exit(2);
  }

  final dateFlag = args.firstWhere(
    (a) => a.startsWith('--date='),
    orElse: () => '',
  );
  final date = dateFlag.isNotEmpty
      ? dateFlag.substring('--date='.length)
      : DateTime.now().toIso8601String().substring(0, 10);

  final doc = loadYaml(manifestFile.readAsStringSync());
  if (doc is! Map) {
    stderr.writeln('Manifest root must be a mapping.');
    exit(2);
  }

  final out = File(
    positional.length > 1
        ? positional[1]
        : '${manifestFile.parent.path}${Platform.pathSeparator}design'
            '${Platform.pathSeparator}spec.md',
  );
  if (out.existsSync() && !args.contains('--force')) {
    stderr.writeln('${out.path} already exists. A written spec is human '
        'work; pass --force only if you really mean to overwrite it.');
    exit(1);
  }

  out.parent.createSync(recursive: true);
  out.writeAsStringSync(generateSpec(doc, date: date));
  stdout.writeln('Wrote ${out.path}. Next: write the TODO sections '
      '(Sections 1-6, 8, 10), then flip Status to final.');
}
