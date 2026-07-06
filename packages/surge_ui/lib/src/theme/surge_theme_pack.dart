import 'package:flutter/material.dart';

import '../tokens/surge_tokens.dart';

/// A complete design personality: full light + dark token sets (color,
/// shape, elevation, motion) plus a recommended type pairing. Packs exist
/// so ten stamped apps don't look like ten reskins of one template — the
/// manifest picks a pack (`brand.theme_pack`), the palette overrides the
/// accent within it, and INTAKE's reference-apps question steers which
/// pack fits the idea.
///
/// Adding a pack: full [SurgeTokens] for BOTH brightnesses (no partial
/// copyWith of another pack — personalities drift together otherwise), a
/// register entry in [SurgeThemePacks.all], and it must pass the contrast
/// smoke tests in `test/theme_pack_test.dart`.
@immutable
class SurgeThemePack {
  const SurgeThemePack({
    required this.id,
    required this.name,
    required this.description,
    required this.light,
    required this.dark,
    this.fontDisplay,
    this.fontText,
  });

  /// Stable manifest value (`brand.theme_pack`), snake_case.
  final String id;

  final String name;
  final String description;
  final SurgeTokens light;
  final SurgeTokens dark;

  /// Recommended type pairing. Advisory: the manifest `brand.fonts` block
  /// still decides what ships; forge prints a note when they disagree.
  final String? fontDisplay;
  final String? fontText;

  SurgeTokens tokens(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// The built-in pack registry.
abstract final class SurgeThemePacks {
  /// The neutral blank canvas — surge_ui's original defaults (slate + blue,
  /// 8/12/16/24 radii, brisk standard motion). The pack every app gets when
  /// the manifest names none.
  static const canvas = SurgeThemePack(
    id: 'canvas',
    name: 'Canvas',
    description: 'Neutral slate + blue. The unopinionated default; pick a '
        'personality pack (or design one) before shipping.',
    light: SurgeTokens.light,
    dark: SurgeTokens.dark,
  );

  /// Airy layered surfaces, generous radii, real (soft, ink-tinted)
  /// shadows, a dusty iris accent with substance, rounded grotesque type,
  /// unhurried motion. Calm consumer feel.
  static const softDepth = SurgeThemePack(
    id: 'soft_depth',
    name: 'Soft depth',
    description: 'Airy, layered, generously rounded; dusty iris accent and '
        'soft ink-tinted shadows. Calm consumer apps.',
    fontDisplay: 'Manrope',
    fontText: 'Manrope',
    light: SurgeTokens(
      bgBase: Color(0xFFFAFAFD),
      bgSubtle: Color(0xFFF1F2F8),
      bgInset: Color(0xFFE8EAF3),
      inkPrimary: Color(0xFF23283B),
      inkSecondary: Color(0xFF525A74),
      inkTertiary: Color(0xFF8188A2),
      inkDisabled: Color(0xFFC0C4D6),
      lineHairline: Color(0xFFE7E9F2),
      lineStrong: Color(0xFFD2D6E5),
      accentBase: Color(0xFF5F6FD1),
      accentPressed: Color(0xFF4C5AB4),
      accentTint: Color(0xFFEAEDFB),
      accentOn: Color(0xFFFFFFFF),
      successBase: Color(0xFF35906B),
      successTint: Color(0xFFE2F3EB),
      warningBase: Color(0xFFA97F24),
      warningTint: Color(0xFFF6EED8),
      dangerBase: Color(0xFFC2504E),
      dangerTint: Color(0xFFF9E7E7),
      inverseBg: Color(0xFF262B40),
      inverseInk: Color(0xFFF1F2F8),
      shadowFloat: [
        BoxShadow(
          offset: Offset(0, 6),
          blurRadius: 20,
          color: Color(0x141F2547),
        ),
      ],
      shadowLift: [
        BoxShadow(
          offset: Offset(0, 16),
          blurRadius: 40,
          color: Color(0x291F2547),
        ),
      ],
      radiusSm: 10,
      radiusMd: 16,
      radiusLg: 22,
      radiusXl: 28,
      motionFast: Duration(milliseconds: 160),
      motionBase: Duration(milliseconds: 300),
      motionSlow: Duration(milliseconds: 480),
      curveStandard: Curves.easeOutCubic,
      curveEmphasized: Curves.easeOutBack,
    ),
    dark: SurgeTokens(
      bgBase: Color(0xFF15161E),
      bgSubtle: Color(0xFF1B1D28),
      bgInset: Color(0xFF252838),
      inkPrimary: Color(0xFFEDEEF6),
      inkSecondary: Color(0xFFA6AAC4),
      inkTertiary: Color(0xFF6E7390),
      inkDisabled: Color(0xFF3E4257),
      lineHairline: Color(0xFF252839),
      lineStrong: Color(0xFF383C52),
      accentBase: Color(0xFF8A97E8),
      accentPressed: Color(0xFFA2ADEF),
      accentTint: Color(0xFF232741),
      accentOn: Color(0xFF14162A),
      successBase: Color(0xFF57BA8C),
      successTint: Color(0xFF152A20),
      warningBase: Color(0xFFD9AC55),
      warningTint: Color(0xFF2B2312),
      dangerBase: Color(0xFFE07A80),
      dangerTint: Color(0xFF2E181C),
      inverseBg: Color(0xFFEDEEF6),
      inverseInk: Color(0xFF1B1D28),
      shadowFloat: [
        BoxShadow(
          offset: Offset(0, 6),
          blurRadius: 20,
          color: Color(0x66000000),
        ),
      ],
      shadowLift: [
        BoxShadow(
          offset: Offset(0, 16),
          blurRadius: 40,
          color: Color(0x8C000000),
        ),
      ],
      radiusSm: 10,
      radiusMd: 16,
      radiusLg: 22,
      radiusXl: 28,
      motionFast: Duration(milliseconds: 160),
      motionBase: Duration(milliseconds: 300),
      motionSlow: Duration(milliseconds: 480),
      curveStandard: Curves.easeOutCubic,
      curveEmphasized: Curves.easeOutBack,
    ),
  );

  static const all = <String, SurgeThemePack>{
    'canvas': canvas,
    'soft_depth': softDepth,
  };

  /// Pack for a manifest id; unknown ids fall back to [canvas] so a stamped
  /// app never fails to theme (the validator catches the typo upstream).
  static SurgeThemePack byId(String? id) => all[id] ?? canvas;
}
