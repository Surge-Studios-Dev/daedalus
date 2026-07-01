/// Generates a marketing-site portfolio entry (a `PortfolioProject`, matching
/// Surge-Studios-Site/src/content/portfolio.ts) seeded from an app's manifest.
/// Manifest-derivable fields (name, palette, logo mode, summary) are filled;
/// narrative fields come out as TODO placeholders for a human to write, because
/// they are marketing craft, not config.
library;

String _s(Object? v, String fallback) {
  final s = v?.toString();
  if (s == null || s.trim().isEmpty) return fallback;
  // Collapse whitespace/newlines so values sit safely in a TS string literal.
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// #RRGGBB -> "r, g, b" for rgba() strings.
String _rgb(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length != 6) return '0, 0, 0';
  final r = int.parse(h.substring(0, 2), radix: 16);
  final g = int.parse(h.substring(2, 4), radix: 16);
  final b = int.parse(h.substring(4, 6), radix: 16);
  return '$r, $g, $b';
}

/// Renders a `PortfolioProject` TS object literal from the manifest.
String portfolioEntry(Map manifest) {
  final identity = (manifest['identity'] as Map?) ?? const {};
  final brand = (manifest['brand'] as Map?) ?? const {};
  final palette = (brand['palette'] as Map?) ?? const {};
  final store = (manifest['store'] as Map?) ?? const {};

  final slug = _s(identity['slug'], 'app');
  final name = _s(identity['name'], 'App');
  final tagline = _s(identity['tagline'], '');
  final summary = _s(store['full_description'], tagline).trim();
  final accent = _s(palette['accent'], '#75d8ff');
  final accentSoft = _s(palette['accent_soft'], '#2b89d8');
  final panel = _s(palette['panel'], '#0e1b27');
  final logoMode = _s(brand['logo_mode'], 'wordmark');
  final accentRgb = _rgb(accent);
  final panelRgb = _rgb(panel);

  String esc(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');

  return '''
  {
    id: "$slug",
    name: "${esc(name)}",
    shortLabel: "${esc(name)}",
    category: "Studio Build",
    internal: false,
    heroAngle: "${esc(tagline.isEmpty ? '$name, built and shipped by Surge Studios.' : tagline)}",
    summary:
      "${esc(summary.isEmpty ? 'TODO: one-paragraph summary of $name.' : summary)}",
    // TODO: replace the placeholder narrative below with real copy.
    workDone: [
      "TODO: what Surge designed and built for $name.",
    ],
    standoutDecisions: [
      "TODO: a notable product or engineering decision.",
    ],
    outcomeHighlights: [
      "TODO: an outcome or result worth showing.",
    ],
    palette: {
      accent: "$accent",
      accentSoft: "$accentSoft",
      glow: "rgba($accentRgb, 0.24)",
      panel: "rgba($panelRgb, 0.72)",
      ring: "rgba($accentRgb, 0.34)",
    },
    logoMode: "$logoMode",
    media: [
      { id: "$slug-hero", kind: "mock", title: "Product hero", placeholderStyle: "mobile" },
      { id: "$slug-marketing", kind: "mock", title: "Landing page", placeholderStyle: "marketing" },
      { id: "$slug-detail", kind: "mock", title: "Key screen", placeholderStyle: "dashboard" },
    ],
  },
''';
}
