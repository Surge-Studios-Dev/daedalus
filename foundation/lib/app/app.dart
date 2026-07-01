import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_ui/surge_ui.dart';

import '../modules/settings/appearance_controller.dart';
import 'router.dart';

/// The app root. Builds light/dark themes from surge_ui and drives them off the
/// appearance setting; navigation comes from [routerProvider].
///
/// SEAM: pass per-app `tokens:` and `fontFamily:` into buildSurgeTheme from the
/// manifest brand block.
class SurgeApp extends ConsumerWidget {
  const SurgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(appearanceProvider);

    return MaterialApp.router(
      title: 'Surge Foundation',
      debugShowCheckedModeBanner: false,
      theme: buildSurgeTheme(Brightness.light),
      darkTheme: buildSurgeTheme(Brightness.dark),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
