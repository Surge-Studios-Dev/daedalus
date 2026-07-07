import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';
import 'surge_theme_pack.dart';

/// Builds a [ThemeData] wired to a [SurgeTokens] set for one [brightness].
///
/// Apps call this twice (light + dark) and pass the results to `MaterialApp`.
/// Pass a [pack] to adopt a design personality (see [SurgeThemePacks]),
/// [tokens] for the fully-resolved set (wins over [pack] — used when the app
/// overrides the pack's accent from the manifest palette), and [fontFamily]
/// to set the app's bundled type family for the whole scale.
ThemeData buildSurgeTheme(
  Brightness brightness, {
  SurgeThemePack? pack,
  SurgeTokens? tokens,
  String? fontFamily,
}) {
  final t = tokens ?? (pack ?? SurgeThemePacks.canvas).tokens(brightness);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: t.bgBase,
    splashFactory: NoSplash.splashFactory,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: t.accentBase,
      onPrimary: t.accentOn,
      secondary: t.accentTint,
      onSecondary: t.accentBase,
      error: t.dangerBase,
      onError: t.accentOn,
      surface: t.bgBase,
      onSurface: t.inkPrimary,
      surfaceContainerHighest: t.bgInset,
      outline: t.lineStrong,
      outlineVariant: t.lineHairline,
    ),
    dividerColor: t.lineHairline,
    // M3 tints the AppBar with a primary overlay once content scrolls under it,
    // which reads as the top of the screen darkening on scroll. Flatten it.
    appBarTheme: AppBarTheme(
      backgroundColor: t.bgBase,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: TextTheme(
      displayMedium: SurgeText.display,
      titleLarge: SurgeText.title1,
      titleMedium: SurgeText.title2,
      titleSmall: SurgeText.headline,
      bodyMedium: SurgeText.body,
      bodySmall: SurgeText.footnote,
      labelSmall: SurgeText.caption,
    ).apply(bodyColor: t.inkPrimary, displayColor: t.inkPrimary),
    extensions: [t],
  );
}
