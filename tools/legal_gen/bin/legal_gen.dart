import 'dart:convert';
import 'dart:io';

import 'package:legal_gen/legal_gen.dart';
import 'package:yaml/yaml.dart';

/// CLI: `dart run legal_gen <manifest> <outDir> [--date YYYY-MM-DD]`.
/// Writes privacy.md, terms.md, legal.json, PrivacyInfo.xcprivacy, and
/// store-privacy-labels.md into <outDir>.
void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  if (positional.length < 2) {
    stderr.writeln('usage: dart run legal_gen <manifest> <outDir> [--date YYYY-MM-DD]');
    exit(2);
  }
  final manifestPath = positional[0];
  final outDir = positional[1];

  final dateFlag = args.firstWhere(
    (a) => a.startsWith('--date='),
    orElse: () => '',
  );
  final date = dateFlag.isNotEmpty
      ? dateFlag.substring('--date='.length)
      : DateTime.now().toIso8601String().substring(0, 10);

  final file = File(manifestPath);
  if (!file.existsSync()) {
    stderr.writeln('Manifest not found: $manifestPath');
    exit(2);
  }
  final doc = loadYaml(file.readAsStringSync());
  if (doc is! Map) {
    stderr.writeln('Manifest root must be a mapping.');
    exit(2);
  }

  final config = LegalConfig.fromManifest(doc, lastUpdated: date);
  final privacy = generatePrivacy(config);
  final terms = generateTerms(config);

  Directory(outDir).createSync(recursive: true);
  void write(String name, String contents) =>
      File('$outDir/$name').writeAsStringSync(contents);

  write('privacy.md', privacy.toMarkdown());
  write('terms.md', terms.toMarkdown());
  write(
    'legal.json',
    '${const JsonEncoder.withIndent('  ').convert({
      'slug': config.slug,
      'appName': config.appName,
      'privacy': privacy.toJson(),
      'terms': terms.toJson(),
    })}\n',
  );
  write('PrivacyInfo.xcprivacy', applePrivacyManifest(config));
  write('store-privacy-labels.md', storePrivacyLabels(config));

  stdout.writeln('Wrote legal assets for ${config.appName} to $outDir/');
}
