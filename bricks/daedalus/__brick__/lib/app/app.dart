import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_ui/surge_ui.dart';

import '../modules/settings/appearance_controller.dart';
import 'router.dart';

/// The app root. Builds light/dark themes from surge_ui with this app's brand
/// palette (from surge.manifest.yaml) and drives them off the appearance
/// setting; navigation comes from [routerProvider].
class SurgeApp extends ConsumerWidget {
  const SurgeApp({super.key});

  // Design personality (brand.theme_pack) + brand accent (brand.palette)
  // from the manifest. The pack carries the whole look (shape, motion,
  // neutrals); the accent is tuned within it. Override more in _tokens as
  // the brand grows.
  static const _accent = Color({{accent_hex}});
  static final _pack = SurgeThemePacks.byId('{{theme_pack}}');

  SurgeTokens _tokens(Brightness brightness) {
    return _pack.tokens(brightness).copyWith(accentBase: _accent);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(appearanceProvider);

    return MaterialApp.router(
      title: '{{name}}',
      debugShowCheckedModeBanner: false,
      theme: buildSurgeTheme(Brightness.light, tokens: _tokens(Brightness.light)),
      darkTheme:
          buildSurgeTheme(Brightness.dark, tokens: _tokens(Brightness.dark)),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
