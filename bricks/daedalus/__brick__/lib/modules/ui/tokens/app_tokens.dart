import 'package:flutter/material.dart';

/// Design tokens for {{name}}, generated from surge.manifest.yaml brand.palette.
/// Read these via Theme.of(context).extension<AppTokens>(). Never hardcode a hex
/// in a widget.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.accent,
    required this.accentSoft,
    required this.panel,
    required this.surface,
    required this.onSurface,
  });

  final Color accent;
  final Color accentSoft;
  final Color panel;
  final Color surface;
  final Color onSurface;

  static const light = AppTokens(
    accent: Color({{accent_hex}}),
    accentSoft: Color({{accent_soft_hex}}),
    panel: Color({{panel_hex}}),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0E1B27),
  );

  static const dark = AppTokens(
    accent: Color({{accent_hex}}),
    accentSoft: Color({{accent_soft_hex}}),
    panel: Color({{panel_hex}}),
    surface: Color(0xFF0E1B27),
    onSurface: Color(0xFFF4F8FB),
  );

  @override
  AppTokens copyWith({
    Color? accent,
    Color? accentSoft,
    Color? panel,
    Color? surface,
    Color? onSurface,
  }) =>
      AppTokens(
        accent: accent ?? this.accent,
        accentSoft: accentSoft ?? this.accentSoft,
        panel: panel ?? this.panel,
        surface: surface ?? this.surface,
        onSurface: onSurface ?? this.onSurface,
      );

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
    );
  }
}

/// Builds light/dark ThemeData carrying the tokens above.
ThemeData buildTheme(Brightness b) {
  final tokens = b == Brightness.dark ? AppTokens.dark : AppTokens.light;
  final scheme = ColorScheme.fromSeed(seedColor: tokens.accent, brightness: b);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: '{{font_text}}',
    extensions: [tokens],
  );
}
