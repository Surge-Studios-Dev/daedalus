import 'dart:io';
import 'package:mason/mason.dart';

/// After the static files render, generate the manifest-driven wiring:
///   1. lib/app/nav_config.dart  — the ordered tab list the shell + router read.
///   2. lib/features/<id>/<id>_screen.dart — one themed stub per feature tab.
///   3. lib/features/feature_registry.dart — id -> screen builder.
/// Then fetch packages and format. The stubs compile, are themed, and navigate;
/// they intentionally do nothing useful yet. Replace them with real,
/// differentiated functionality before submission (stub-only fails Apple 4.3).
Future<void> run(HookContext context) async {
  final tabs = (context.vars['tabs'] as List).cast<Map>();
  final features = tabs.where((t) => t['builtin'] != true).toList();

  // 1. nav_config.dart — every tab, in order, with a resolved Material icon.
  // Inner trailing comma so dart format renders one arg per line - keeps the
  // generated file clean under require_trailing_commas at any label length.
  final navEntries = tabs
      .map(
        (t) =>
            "  NavTab(id: '${t['id']}', label: '${t['label']}', "
            "icon: ${_icon(t['icon'] as String?)}, builtin: ${t['builtin'] == true},),",
      )
      .join('\n');
  File('lib/app/nav_config.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

/// One bottom-bar tab. Generated from navigation.tabs; do not edit by hand.
class NavTab {
  const NavTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.builtin,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Builtin tabs render the settings stack; feature tabs render their screen.
  final bool builtin;
}

const navTabs = <NavTab>[
$navEntries
];
''');

  // 2. one themed stub per feature tab.
  for (final t in features) {
    final id = t['id'] as String;
    final label = t['label'] as String;
    final cls = _pascal(id);
    Directory('lib/features/$id').createSync(recursive: true);
    File('lib/features/$id/${id}_screen.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:surge_ui/surge_ui.dart';

/// $id · $label (stub). A wired, themed placeholder — replace with the real
/// feature before submission.
class ${cls}Screen extends StatelessWidget {
  const ${cls}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      appBar: AppBar(title: const Text('$label')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dashboard_customize, size: 48, color: t.inkTertiary),
              const SizedBox(height: SurgeSpace.lg),
              Text('$label', style: SurgeText.title2),
              const SizedBox(height: SurgeSpace.sm),
              Text(
                'This tab is a wired stub. Build it out.',
                style: SurgeText.body.copyWith(color: t.inkSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''');
  }

  // 3. feature_registry.dart — id -> builder for the router.
  final imports = features
      .map((t) => "import '${t['id']}/${t['id']}_screen.dart';")
      .join('\n');
  final entries = features
      .map(
        (t) =>
            "  '${t['id']}': (c) => const ${_pascal(t['id'] as String)}Screen(),",
      )
      .join('\n');
  File('lib/features/feature_registry.dart').writeAsStringSync(
    "import 'package:flutter/material.dart';\n$imports\n\n"
    "/// Maps tab id -> screen builder, read by the router. Generated; do not\n"
    "/// edit by hand.\n"
    "final Map<String, WidgetBuilder> featureBuilders = {\n$entries\n};\n",
  );

  // runInShell so Windows resolves flutter.bat / dart.bat off PATH.
  // pub get failing is non-fatal (the app is fully generated; forge.sh runs
  // pub get again) but must be loud: in git-deps mode it means the pinned ref
  // is unreachable or doesn't contain the packages yet.
  // Format ONLY the files this hook generated. The rest of lib/ is a formatted
  // mirror of the foundation (or a rendered template); reformatting it under
  // the app's language version would diverge from the foundation and trip its
  // lints.
  final p = context.logger.progress('flutter pub get');
  final pub = await Process.run('flutter', ['pub', 'get'], runInShell: true);
  await Process.run(
    'dart',
    ['format', 'lib/app/nav_config.dart', 'lib/features'],
    runInShell: true,
  );
  if (pub.exitCode != 0) {
    p.fail('Generated ${context.vars['name']}, but flutter pub get failed:');
    context.logger.err(pub.stderr.toString().trim());
    context.logger.warn(
      'Fix the surge_* dependency source in pubspec.yaml (path vs git ref), '
      'then re-run flutter pub get.',
    );
  } else {
    p.complete('Generated ${context.vars['name']}. Next: scripts/forge.sh');
  }
}

/// Maps manifest (lucide-style) icon names to Material icons the base ships
/// with. Unknown names fall back to a neutral glyph — pick a closer one by hand.
String _icon(String? name) {
  const map = {
    'home': 'home',
    'hash': 'tag',
    'bar-chart': 'bar_chart',
    'book': 'menu_book',
    'book-open': 'menu_book',
    'calendar': 'calendar_today',
    'user': 'person',
    'users': 'group',
    'plus': 'add',
    'search': 'search',
    'settings': 'settings',
    'heart': 'favorite',
    'star': 'star',
    'list': 'list',
    'grid': 'grid_view',
    'bell': 'notifications',
    'camera': 'photo_camera',
    'map': 'map',
    'clock': 'schedule',
    'cart': 'shopping_cart',
    'bag': 'shopping_bag',
    'chart': 'bar_chart',
    'folder': 'folder',
    'file': 'description',
    'message': 'chat_bubble_outline',
  };
  return 'Icons.${map[name] ?? 'circle_outlined'}';
}

String _pascal(String s) => s
    .split(RegExp(r'[_\-\s]+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join();
