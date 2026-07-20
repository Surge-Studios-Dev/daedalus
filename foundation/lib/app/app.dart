import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modules/settings/appearance_controller.dart';
import 'router.dart';
import 'theme.dart';

/// The app root. Themes come from lib/app/theme.dart (the one theme source,
/// shared with the proofing harnesses) and drive off the appearance setting;
/// navigation comes from [routerProvider].
///
/// SEAM: the stamped copy of theme.dart carries the manifest brand block
/// (pack, palette, fonts). The foundation renders the bare canvas pack on
/// purpose.
class SurgeApp extends ConsumerWidget {
  const SurgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(appearanceProvider);

    return MaterialApp.router(
      title: 'Surge Foundation',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
