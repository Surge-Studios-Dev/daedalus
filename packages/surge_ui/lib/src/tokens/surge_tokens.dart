import 'package:flutter/material.dart';

/// The universal, frozen token contract every Surge app provides and every
/// shared component depends on. Names are semantic (role, not value) so a
/// component reads `t.accentBase`, never a hex.
///
/// This is the subset of tokens guaranteed to exist in *every* app. App-specific
/// tokens (domain colors, brand flourishes) live in a separate [ThemeExtension]
/// the app owns; `surge_ui` never references those. Do not add fields here
/// without a major version bump — the whole library is built against this shape.
///
/// Values come from [SurgeTokens.light] / [SurgeTokens.dark] by default and are
/// overridden per app (from the manifest `brand.palette`) via [copyWith].
@immutable
class SurgeTokens extends ThemeExtension<SurgeTokens> {
  const SurgeTokens({
    required this.bgBase,
    required this.bgSubtle,
    required this.bgInset,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.inkDisabled,
    required this.lineHairline,
    required this.lineStrong,
    required this.accentBase,
    required this.accentPressed,
    required this.accentTint,
    required this.accentOn,
    required this.successBase,
    required this.successTint,
    required this.warningBase,
    required this.warningTint,
    required this.dangerBase,
    required this.dangerTint,
    required this.inverseBg,
    required this.inverseInk,
    required this.shadowFloat,
    required this.shadowLift,
  });

  /// Surfaces, back to front.
  final Color bgBase;
  final Color bgSubtle;
  final Color bgInset;

  /// Text / foreground, most to least prominent, plus the disabled ink.
  final Color inkPrimary;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color inkDisabled;

  /// Separators.
  final Color lineHairline;
  final Color lineStrong;

  /// Brand accent: fill, pressed fill, low-emphasis tint, and the ink that
  /// reads on top of [accentBase].
  final Color accentBase;
  final Color accentPressed;
  final Color accentTint;
  final Color accentOn;

  /// Status colors: a saturated base for icons/text and a soft tint for fills.
  final Color successBase;
  final Color successTint;
  final Color warningBase;
  final Color warningTint;
  final Color dangerBase;
  final Color dangerTint;

  /// Inverted surface/ink for snackbars, tooltips, and scrims.
  final Color inverseBg;
  final Color inverseInk;

  /// Elevation: [shadowFloat] for resting cards, [shadowLift] for sheets/menus.
  final List<BoxShadow> shadowFloat;
  final List<BoxShadow> shadowLift;

  /// Neutral light defaults — a blank-canvas palette (slate + blue accent).
  static const light = SurgeTokens(
    bgBase: Color(0xFFFFFFFF),
    bgSubtle: Color(0xFFF5F6F8),
    bgInset: Color(0xFFECEEF2),
    inkPrimary: Color(0xFF10131A),
    inkSecondary: Color(0xFF454B57),
    inkTertiary: Color(0xFF838A97),
    inkDisabled: Color(0xFFB9BEC8),
    lineHairline: Color(0xFFE6E8EC),
    lineStrong: Color(0xFFD2D6DD),
    accentBase: Color(0xFF2B7FFF),
    accentPressed: Color(0xFF1E63CC),
    accentTint: Color(0xFFE8F1FF),
    accentOn: Color(0xFFFFFFFF),
    successBase: Color(0xFF1F9D57),
    successTint: Color(0xFFE4F5EC),
    warningBase: Color(0xFFC68A12),
    warningTint: Color(0xFFF8EED2),
    dangerBase: Color(0xFFD2402F),
    dangerTint: Color(0xFFFBE7E4),
    inverseBg: Color(0xFF10131A),
    inverseInk: Color(0xFFF5F6F8),
    shadowFloat: [
      BoxShadow(offset: Offset(0, 2), blurRadius: 12, color: Color(0x14000000)),
    ],
    shadowLift: [
      BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x22000000)),
    ],
  );

  /// Neutral dark defaults.
  static const dark = SurgeTokens(
    bgBase: Color(0xFF0E1116),
    bgSubtle: Color(0xFF161A21),
    bgInset: Color(0xFF1F242D),
    inkPrimary: Color(0xFFF2F4F7),
    inkSecondary: Color(0xFFA7AEBB),
    inkTertiary: Color(0xFF6D7481),
    inkDisabled: Color(0xFF3D434D),
    lineHairline: Color(0xFF222831),
    lineStrong: Color(0xFF333A44),
    accentBase: Color(0xFF4C93FF),
    accentPressed: Color(0xFF6BA6FF),
    accentTint: Color(0xFF14243B),
    accentOn: Color(0xFFFFFFFF),
    successBase: Color(0xFF3FB477),
    successTint: Color(0xFF12241A),
    warningBase: Color(0xFFE0A93A),
    warningTint: Color(0xFF2A2210),
    dangerBase: Color(0xFFE56553),
    dangerTint: Color(0xFF2A1512),
    inverseBg: Color(0xFFF2F4F7),
    inverseInk: Color(0xFF10131A),
    shadowFloat: [
      BoxShadow(offset: Offset(0, 2), blurRadius: 12, color: Color(0x73000000)),
    ],
    shadowLift: [
      BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x8C000000)),
    ],
  );

  @override
  SurgeTokens copyWith({
    Color? bgBase,
    Color? bgSubtle,
    Color? bgInset,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? inkTertiary,
    Color? inkDisabled,
    Color? lineHairline,
    Color? lineStrong,
    Color? accentBase,
    Color? accentPressed,
    Color? accentTint,
    Color? accentOn,
    Color? successBase,
    Color? successTint,
    Color? warningBase,
    Color? warningTint,
    Color? dangerBase,
    Color? dangerTint,
    Color? inverseBg,
    Color? inverseInk,
    List<BoxShadow>? shadowFloat,
    List<BoxShadow>? shadowLift,
  }) {
    return SurgeTokens(
      bgBase: bgBase ?? this.bgBase,
      bgSubtle: bgSubtle ?? this.bgSubtle,
      bgInset: bgInset ?? this.bgInset,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkTertiary: inkTertiary ?? this.inkTertiary,
      inkDisabled: inkDisabled ?? this.inkDisabled,
      lineHairline: lineHairline ?? this.lineHairline,
      lineStrong: lineStrong ?? this.lineStrong,
      accentBase: accentBase ?? this.accentBase,
      accentPressed: accentPressed ?? this.accentPressed,
      accentTint: accentTint ?? this.accentTint,
      accentOn: accentOn ?? this.accentOn,
      successBase: successBase ?? this.successBase,
      successTint: successTint ?? this.successTint,
      warningBase: warningBase ?? this.warningBase,
      warningTint: warningTint ?? this.warningTint,
      dangerBase: dangerBase ?? this.dangerBase,
      dangerTint: dangerTint ?? this.dangerTint,
      inverseBg: inverseBg ?? this.inverseBg,
      inverseInk: inverseInk ?? this.inverseInk,
      shadowFloat: shadowFloat ?? this.shadowFloat,
      shadowLift: shadowLift ?? this.shadowLift,
    );
  }

  @override
  SurgeTokens lerp(SurgeTokens? other, double t) {
    if (other is! SurgeTokens) return this;
    return SurgeTokens(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgSubtle: Color.lerp(bgSubtle, other.bgSubtle, t)!,
      bgInset: Color.lerp(bgInset, other.bgInset, t)!,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkTertiary: Color.lerp(inkTertiary, other.inkTertiary, t)!,
      inkDisabled: Color.lerp(inkDisabled, other.inkDisabled, t)!,
      lineHairline: Color.lerp(lineHairline, other.lineHairline, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      accentBase: Color.lerp(accentBase, other.accentBase, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      accentOn: Color.lerp(accentOn, other.accentOn, t)!,
      successBase: Color.lerp(successBase, other.successBase, t)!,
      successTint: Color.lerp(successTint, other.successTint, t)!,
      warningBase: Color.lerp(warningBase, other.warningBase, t)!,
      warningTint: Color.lerp(warningTint, other.warningTint, t)!,
      dangerBase: Color.lerp(dangerBase, other.dangerBase, t)!,
      dangerTint: Color.lerp(dangerTint, other.dangerTint, t)!,
      inverseBg: Color.lerp(inverseBg, other.inverseBg, t)!,
      inverseInk: Color.lerp(inverseInk, other.inverseInk, t)!,
      shadowFloat: BoxShadow.lerpList(shadowFloat, other.shadowFloat, t)!,
      shadowLift: BoxShadow.lerpList(shadowLift, other.shadowLift, t)!,
    );
  }
}

/// Corner radii. Fixed scale, referenced by name everywhere.
abstract final class SurgeRadii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

/// Spacing scale (4pt grid). Use these instead of ad-hoc `SizedBox` numbers.
abstract final class SurgeSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Read the token set off the current theme: `context.tokens.accentBase`.
extension SurgeTokensX on BuildContext {
  SurgeTokens get tokens => Theme.of(this).extension<SurgeTokens>()!;
}
