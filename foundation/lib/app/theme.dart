import 'package:flutter/material.dart';
import 'package:surge_ui/surge_ui.dart';

/// The foundation's ONE theme source. The app root and every proofing harness
/// (screen board, component goldens) build their theme here, so what the
/// proofs show is what ships - a harness that quietly falls back to pack
/// defaults renders a different app than the one users get (lesson from
/// Ember's first board: periwinkle pack defaults instead of the brand).
///
/// SEAM: the brick's templated copy stamps brand.theme_pack + brand.palette +
/// brand.fonts from surge.manifest.yaml here. The foundation deliberately
/// renders the unthemed canvas pack with no bundled font.

/// The manifest brand.fonts family (stamped per app). The foundation bundles
/// no fonts, so this stays null and Flutter uses the default family.
const String? appFontFamily = null;

final _pack = SurgeThemePacks.canvas;

SurgeTokens appTokens(Brightness brightness) => _pack.tokens(brightness);

ThemeData appTheme(Brightness brightness) => buildSurgeTheme(
      brightness,
      tokens: appTokens(brightness),
      fontFamily: appFontFamily,
    );
