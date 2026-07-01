import 'package:flutter/material.dart';

import '../tokens/surge_text.dart';
import '../tokens/surge_tokens.dart';

/// Builds a [ThemeData] wired to a [SurgeTokens] set for one [brightness].
///
/// Apps call this twice (light + dark) and pass the results to `MaterialApp`.
/// Pass [tokens] to override the neutral defaults (from the manifest palette);
/// pass [fontFamily] to set the app's bundled type family for the whole scale.
ThemeData buildSurgeTheme(
  Brightness brightness, {
  SurgeTokens? tokens,
  String? fontFamily,
}) {
  final t =
      tokens ??
      (brightness == Brightness.dark ? SurgeTokens.dark : SurgeTokens.light);

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
