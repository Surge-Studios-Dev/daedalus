import 'package:flutter/material.dart';
import 'package:surge_ui/surge_ui.dart';

/// {{name}}'s ONE theme source. The app root and every proofing harness
/// (screen board, component goldens) build their theme here, so what the
/// proofs show is what ships - a harness that quietly falls back to pack
/// defaults renders a different app than the one users get (lesson from
/// Ember's first board: periwinkle pack defaults instead of the brand).
///
/// Personality: brand.theme_pack + brand.palette + brand.fonts from
/// surge.manifest.yaml. Tune here (M1: map the full manifest palette and
/// re-derive neutrals if the pack's temperature doesn't match the brand);
/// never restyle ad hoc downstream.

/// The manifest brand.fonts family. Fonts are NOT bundled by the stamp -
/// M1 adds the files under assets/fonts/ plus the pubspec flutter/fonts
/// block; until then Flutter falls back to the default family silently.
const appFontFamily = '{{font_text}}';

const _accent = Color({{accent_hex}});
final _pack = SurgeThemePacks.byId('{{theme_pack}}');

SurgeTokens appTokens(Brightness brightness) =>
    _pack.tokens(brightness).copyWith(accentBase: _accent);

ThemeData appTheme(Brightness brightness) => buildSurgeTheme(
      brightness,
      tokens: appTokens(brightness),
      fontFamily: appFontFamily,
    );
