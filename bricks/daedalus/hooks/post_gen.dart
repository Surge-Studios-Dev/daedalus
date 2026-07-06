import 'dart:io';
import 'package:mason/mason.dart';

/// After the static files render, generate the manifest-driven wiring:
///   1. lib/app/nav_config.dart — the ordered tab list the shell + router read.
///   2. lib/features/<id>/ — a WORKING pattern vertical per feature tab:
///      <id>_items.dart (model + CrudRepository seam + search + live list) and
///      <id>_screen.dart (searchable list -> editor sheet -> delete confirm).
///      Day one of feature work is reshaping working screens, not writing
///      them. They are still not a product: reshape into the real,
///      differentiated feature before submission (Apple 4.3).
///   3. lib/features/feature_registry.dart — id -> screen builder.
///   4. lib/dev/fixtures.dart — seeded repository overrides; the one seam the
///      screen board, widget tests, and store screenshots all share.
/// Then fetch packages and format.
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

  // 2. one working pattern vertical per feature tab.
  for (final t in features) {
    final id = t['id'] as String;
    final label = t['label'] as String;
    final icon = _icon(t['icon'] as String?);
    Directory('lib/features/$id').createSync(recursive: true);
    File('lib/features/$id/${id}_items.dart')
        .writeAsStringSync(_itemsFile(id, label));
    File('lib/features/$id/${id}_screen.dart')
        .writeAsStringSync(_screenFile(id, label, icon));
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

  // 4. lib/dev/fixtures.dart — the seed-data seam.
  Directory('lib/dev').createSync(recursive: true);
  File('lib/dev/fixtures.dart').writeAsStringSync(_fixturesFile(features));

  // Mason does not carry the exec bit; the merge-bar hook needs it.
  final hook = File('.claude/hooks/merge_bar.sh');
  if (hook.existsSync() && !Platform.isWindows) {
    await Process.run('chmod', ['+x', hook.path]);
  }

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
    ['format', 'lib/app/nav_config.dart', 'lib/features', 'lib/dev'],
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

/// The per-tab model + data seam + live queries.
String _itemsFile(String id, String label) {
  final cls = _pascal(id);
  final camel = _camel(id);
  return '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_crud/surge_crud.dart';

/// $id · $label item — a deliberately small starter shape. Rename the class
/// and grow the fields into the real domain model; everything else in this
/// file is the plumbing pattern (repository seam, search, sorted live list)
/// the real feature keeps.
class ${cls}Item {
  const ${cls}Item({
    required this.id,
    required this.name,
    this.note = '',
    required this.createdAt,
  });

  final String id;
  final String name;
  final String note;

  /// Milliseconds since epoch, kept primitive so the map converters stay
  /// trivial and Firestore-safe.
  final int createdAt;

  ${cls}Item copyWith({String? name, String? note}) => ${cls}Item(
    id: id,
    name: name ?? this.name,
    note: note ?? this.note,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'note': note,
    'createdAt': createdAt,
  };

  static ${cls}Item fromMap(String id, Map<String, dynamic> data) => ${cls}Item(
    id: id,
    name: (data['name'] ?? '') as String,
    note: (data['note'] ?? '') as String,
    createdAt: (data['createdAt'] ?? 0) as int,
  );
}

/// Data seam (FRAMEWORK Tier 3): in-memory by default so a fresh stamp runs
/// everywhere, tests included. Bootstrap overrides this with a
/// FirestoreCrudRepository at users/{uid}/$id when useFirebase flips on —
/// exactly the path firestore.rules isolates per user.
final ${camel}RepositoryProvider = Provider<CrudRepository<${cls}Item>>(
  (ref) => InMemoryCrudRepository<${cls}Item>(idOf: (i) => i.id),
);

final ${camel}SearchProvider = StateProvider<String>((ref) => '');

/// Live rows: newest first, filtered by the search box.
final ${camel}ItemsProvider = StreamProvider<List<${cls}Item>>((ref) {
  final repo = ref.watch(${camel}RepositoryProvider);
  final query = ref.watch(${camel}SearchProvider).trim().toLowerCase();
  return repo.watchAll().map((items) {
    final sorted = [...items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (query.isEmpty) return sorted;
    return sorted
        .where(
          (i) =>
              i.name.toLowerCase().contains(query) ||
              i.note.toLowerCase().contains(query),
        )
        .toList();
  });
});
''';
}

/// The per-tab pattern screen: searchable list -> editor sheet -> delete.
String _screenFile(String id, String label, String icon) {
  final cls = _pascal(id);
  final camel = _camel(id);
  final labelLower = label.toLowerCase();
  return '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_ui/surge_ui.dart';

import '${id}_items.dart';

/// $id · $label — a WORKING pattern screen (searchable list -> editor sheet
/// -> delete confirm) over the CrudRepository seam, generated so day one is
/// reshaping a running vertical instead of writing one. It is still not a
/// product: reshape it into the real $labelLower feature before submission.
class ${cls}Screen extends ConsumerWidget {
  const ${cls}Screen({super.key});

  Future<void> _edit(BuildContext context, ${cls}Item? item) {
    return showSurgeSheet(
      context,
      builder: (_) => _${cls}EditorSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(${camel}ItemsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('$label'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: SurgeSpace.sm),
            child: SurgeIconButton(
              icon: Icons.add,
              semanticLabel: 'Add',
              onPressed: () => _edit(context, null),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SurgeSearchField(
              placeholder: 'Search $labelLower',
              onChanged: (q) =>
                  ref.read(${camel}SearchProvider.notifier).state = q,
              onClear: () =>
                  ref.read(${camel}SearchProvider.notifier).state = '',
            ),
          ),
          Expanded(
            child: items.when(
              loading: () => const Center(child: SurgeSpinner()),
              error: (e, _) =>
                  Center(child: Text('\$e', style: SurgeText.footnote)),
              data: (rows) => rows.isEmpty
                  ? SurgeEmptyState(
                      icon: $icon,
                      title: 'Nothing here yet',
                      sub: 'A working list, editor, and delete over the data '
                          'seam. Reshape it into the real $labelLower '
                          'feature.',
                      primaryLabel: 'Add one',
                      onPrimary: () => _edit(context, null),
                    )
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final item = rows[i];
                        return SurgeListRow(
                          title: item.name,
                          sub: item.note.isEmpty ? null : item.note,
                          icon: $icon,
                          chevron: true,
                          onPressed: () => _edit(context, item),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _${cls}EditorSheet extends ConsumerStatefulWidget {
  const _${cls}EditorSheet({this.item});

  final ${cls}Item? item;

  @override
  ConsumerState<_${cls}EditorSheet> createState() =>
      _${cls}EditorSheetState();
}

class _${cls}EditorSheetState extends ConsumerState<_${cls}EditorSheet> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _note = TextEditingController(text: widget.item?.note ?? '');

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final existing = widget.item;
    final now = DateTime.now().millisecondsSinceEpoch;
    final item = existing == null
        ? ${cls}Item(
            id: 'i\$now',
            name: name,
            note: _note.text.trim(),
            createdAt: now,
          )
        : existing.copyWith(name: name, note: _note.text.trim());
    await ref.read(${camel}RepositoryProvider).upsert(item);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final item = widget.item;
    if (item == null) return;
    final ok = await showSurgeConfirm(
      context,
      title: 'Delete this?',
      body: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await ref.read(${camel}RepositoryProvider).delete(item.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SurgeSheet(
      title: widget.item == null ? 'New entry' : 'Edit entry',
      trailing: widget.item == null
          ? null
          : SurgeIconButton(
              icon: Icons.delete_outline,
              danger: true,
              semanticLabel: 'Delete',
              onPressed: _delete,
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurgeTextField(
            controller: _name,
            placeholder: 'Name',
            autofocus: true,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: SurgeSpace.md),
          SurgeTextField(
            controller: _note,
            placeholder: 'Notes (optional)',
            multiline: true,
            minLines: 2,
          ),
          const SizedBox(height: SurgeSpace.md),
        ],
      ),
      foot: SurgeButton.primary('Save', full: true, onPressed: _save),
    );
  }
}
''';
}

/// lib/dev/fixtures.dart — seeded repository overrides for every feature tab.
String _fixturesFile(List<Map> features) {
  final imports = features
      .map(
        (t) => "import '../features/${t['id']}/${t['id']}_items.dart';",
      )
      .join('\n');
  final overrides = features
      .map((t) {
        final id = t['id'] as String;
        final cls = _pascal(id);
        final camel = _camel(id);
        return '''
  ${camel}RepositoryProvider.overrideWithValue(
    InMemoryCrudRepository<${cls}Item>(
      idOf: (i) => i.id,
      seed: [
        const ${cls}Item(
          id: '$id-seed-1',
          name: 'First sample entry',
          note: 'Tap a row to open the editor.',
          createdAt: 1751500800000,
        ),
        const ${cls}Item(
          id: '$id-seed-2',
          name: 'Another sample entry',
          createdAt: 1751414400000,
        ),
        const ${cls}Item(
          id: '$id-seed-3',
          name: 'A third, older entry',
          note: 'Seed data lives in lib/dev/fixtures.dart.',
          createdAt: 1751328000000,
        ),
      ],
    ),
  ),''';
      })
      .join('\n');
  return '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_crud/surge_crud.dart';

$imports

/// Dev/demo seed data — ONE seam powering the screen board
/// (test/goldens/screen_board.dart), widget tests, and store screenshots.
/// Never import this from production code paths. Generated; grow it by hand
/// as the real models land (regeneration only happens on a fresh stamp).
List<Override> devSeedOverrides() => [
$overrides
];
''';
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

String _camel(String s) {
  final p = _pascal(s);
  return p.isEmpty ? p : p[0].toLowerCase() + p.substring(1);
}
