import 'package:flutter/material.dart';

/// The universal type scale. Sizes/weights/line-heights are fixed; the font
/// family is not baked in here so the blank canvas renders with the platform
/// default and each app sets its family once via [ThemeData.fontFamily]
/// (see `buildSurgeTheme`). Colors are applied by the theme's `textTheme`, not
/// hardcoded, so styles inherit the right ink automatically.
abstract final class SurgeText {
  static TextStyle _s({
    required double size,
    required double height,
    required FontWeight weight,
    double spacing = 0,
  }) {
    return TextStyle(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: spacing,
    );
  }

  static final display = _s(
    size: 34,
    height: 40,
    weight: FontWeight.w700,
    spacing: -0.4,
  );
  static final title1 = _s(
    size: 28,
    height: 34,
    weight: FontWeight.w700,
    spacing: -0.3,
  );
  static final title2 = _s(
    size: 22,
    height: 28,
    weight: FontWeight.w600,
    spacing: -0.2,
  );
  static final headline = _s(size: 17, height: 22, weight: FontWeight.w600);
  static final body = _s(size: 16, height: 24, weight: FontWeight.w400);
  static final bodyStrong = _s(size: 16, height: 24, weight: FontWeight.w600);
  static final subhead = _s(size: 15, height: 20, weight: FontWeight.w400);
  static final footnote = _s(size: 13, height: 18, weight: FontWeight.w400);
  static final caption = _s(
    size: 12,
    height: 16,
    weight: FontWeight.w500,
    spacing: 0.1,
  );

  /// Uppercase eyebrow/label text. Flutter has no CSS text-transform: render
  /// the string with [String.toUpperCase] at the call site.
  static final micro = _s(
    size: 11,
    height: 14,
    weight: FontWeight.w600,
    spacing: 0.6,
  );
}

extension SurgeTextX on TextStyle {
  /// Tabular figures — use on every numeral that can change (quantities,
  /// timers, counters, prices) so digits do not jitter as they update.
  TextStyle get tnum => copyWith(
    fontFeatures: [...?fontFeatures, const FontFeature.tabularFigures()],
  );
}
