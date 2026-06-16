import 'dart:io';
import 'package:mason/mason.dart';

/// Scaffolds one wired stub per non-builtin tab (Mason can't loop directories
/// natively), then fetches packages and formats. The stubs compile and
/// navigate; they intentionally do nothing useful yet. Replace them with real,
/// differentiated functionality before submission, or Apple rejects the app
/// under the minimum-functionality rule.
Future<void> run(HookContext context) async {
  final tabs = (context.vars['tabs'] as List).cast<Map>();
  for (final t in tabs) {
    if (t['builtin'] == true) continue;
    final id = t['id'] as String;
    final label = t['label'] as String;
    final dir = Directory('lib/features/$id')..createSync(recursive: true);
    final cls = _pascal(id);
    File('${dir.path}/${id}_screen.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

/// $id stub. Replace with the real feature before submission.
class ${cls}Screen extends StatelessWidget {
  const ${cls}Screen({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: Text('$label'));
}
''');
  }

  // Generate the feature registry the router reads by tab id.
  final feats = tabs.where((t) => t['builtin'] != true).toList();
  final imports = feats
      .map((t) => "import '${t['id']}/${t['id']}_screen.dart';")
      .join('\n');
  final entries = feats
      .map((t) => "  '${t['id']}': (c) => const ${_pascal(t['id'] as String)}Screen(),")
      .join('\n');
  File('lib/features/feature_registry.dart').writeAsStringSync(
    "import 'package:flutter/material.dart';\n$imports\n\n"
    "/// Maps tab id -> screen builder. Generated; do not edit by hand.\n"
    "final Map<String, WidgetBuilder> featureBuilders = {\n$entries\n};\n",
  );

  final p = context.logger.progress('flutter pub get');
  await Process.run('flutter', ['pub', 'get']);
  await Process.run('dart', ['format', '.']);
  p.complete('Generated ${context.vars['name']}. Next: scripts/forge.sh');
}

String _pascal(String s) => s
    .split(RegExp(r'[_\-\s]+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join();
