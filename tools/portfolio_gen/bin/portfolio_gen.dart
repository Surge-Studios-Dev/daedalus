import 'dart:io';

import 'package:portfolio_gen/portfolio_gen.dart';
import 'package:yaml/yaml.dart';

/// CLI: `dart run portfolio_gen <manifest>` -> prints a PortfolioProject entry
/// to paste into Surge-Studios-Site/src/content/portfolio.ts. Fill the TODO
/// narrative fields before publishing.
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run portfolio_gen <manifest>');
    exit(2);
  }
  final file = File(args.first);
  if (!file.existsSync()) {
    stderr.writeln('Manifest not found: ${args.first}');
    exit(2);
  }
  final doc = loadYaml(file.readAsStringSync());
  if (doc is! Map) {
    stderr.writeln('Manifest root must be a mapping.');
    exit(2);
  }
  stdout.write(portfolioEntry(doc));
}
