import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modules/ui/tokens/app_tokens.dart';
import 'router.dart';

/// Root widget for {{name}}. Wires theme (light/dark/system) and the router.
/// SKELETON: hold themeMode in a Riverpod provider backed by shared_preferences
/// and the appearance setting; wired here as system for now.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '{{name}}',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: buildRouter(),
    );
  }
}
