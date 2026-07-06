import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:surge_ui/surge_ui.dart';

/// Goldens for the most-used components, light + dark (pattern from
/// Ladle's M1 definition of done). Layout, ink, and token regressions
/// show up here before a human screenshot pass would catch them.
///
/// Seed (then commit test/goldens/images/):
///   flutter test --update-goldens test/goldens
/// Until seeded, these tests skip - a fresh stamp stays green, and the
/// suite arms itself the moment images exist. Re-run --update-goldens on
/// any INTENTIONAL visual change; a diff you didn't intend is the test
/// working. Failure diffs land in test/goldens/failures/.
///
/// Grow the cases with the app: every promoted component and every
/// domain widget with layout worth protecting earns an entry, and the
/// per-screen contact-sheet pattern (docs/testing.md) covers whole
/// screens.
void main() {
  final seeded =
      Directory('test/goldens/images').existsSync() &&
      Directory('test/goldens/images')
          .listSync()
          .whereType<File>()
          .any((f) => f.path.endsWith('.png'));
  final skip = !seeded && !autoUpdateGoldenFiles;

  setUpAll(() async {
    // Goldens render real type when the app's bundled font is loaded here
    // (see pubspec flutter/fonts); without one, flutter_test's Ahem blocks
    // still catch layout/color regressions, just not glyph-level ones.
    const fontFamily = 'AppFont';
    const fontPath = 'assets/fonts/AppFont.ttf';
    final fontFile = File(fontPath);
    if (fontFile.existsSync()) {
      final data = fontFile.readAsBytesSync();
      final loader = FontLoader(fontFamily)
        ..addFont(Future.value(data.buffer.asByteData()));
      await loader.load();
    }
  });

  Widget host(Brightness brightness, Widget child) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildSurgeTheme(brightness),
    home: Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  final cases = <String, Widget>{
    'button': SurgeButton.primary('Continue', onPressed: () {}),
    'button_secondary': SurgeButton.secondary('Not now', onPressed: () {}),
    'filter_chip': const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SurgeFilterChip(label: 'Selected', selected: true),
        SizedBox(width: 8),
        SurgeFilterChip(label: 'Unselected'),
      ],
    ),
    'list_row': const SizedBox(
      width: 360,
      child: SurgeListRow(
        title: 'A list row title',
        sub: 'Supporting line · detail',
        chevron: true,
      ),
    ),
    'toggle': const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SurgeToggle(on: true, onChanged: _noop),
        SizedBox(width: 12),
        SurgeToggle(on: false, onChanged: _noop),
      ],
    ),
    'banner': const SizedBox(
      width: 360,
      child: SurgeBanner(
        kind: SurgeBannerKind.accent,
        icon: Icons.auto_awesome,
        message: '2 free uses left this week',
        actionLabel: 'Upgrade',
      ),
    ),
    'empty_state': const SizedBox(
      width: 360,
      child: SurgeEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nothing here yet',
        sub: 'Things you add will show up here.',
        primaryLabel: 'Add one',
      ),
    ),
  };

  for (final MapEntry(key: name, value: widget) in cases.entries) {
    for (final brightness in Brightness.values) {
      final theme = brightness == Brightness.dark ? 'dark' : 'light';
      testWidgets('$name $theme', skip: skip, (tester) async {
        await tester.pumpWidget(
          host(brightness, RepaintBoundary(child: widget)),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(RepaintBoundary).last,
          matchesGoldenFile('images/${name}_$theme.png'),
        );
      });
    }
  }
}

void _noop(bool _) {}
