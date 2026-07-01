/// Generates the Fastlane store-metadata trees from a parsed
/// `surge.manifest.yaml`: `deliver` layout for the App Store
/// (fastlane/metadata/en-US/*.txt) and `supply` layout for Google Play
/// (fastlane/metadata/android/en-US/*.txt). Pure: returns relative-path ->
/// content plus limit warnings; the CLI does the writing.
///
/// Store character limits are enforced as warnings, not truncation - a
/// truncated keyword list or subtitle is a product decision, not a tool's.
library;

/// One store field's limit violation (or other advisory).
class StoreWarning {
  const StoreWarning(this.field, this.message);
  final String field;
  final String message;
  @override
  String toString() => '$field: $message';
}

/// Result of a generation: file map (relative paths, `/` separators) and
/// warnings to surface.
class StoreMetadata {
  const StoreMetadata(this.files, this.warnings);
  final Map<String, String> files;
  final List<StoreWarning> warnings;
}

String _s(Object? v, [String fallback = '']) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? fallback : s;
}

/// Builds both metadata trees. Limits (current store rules): iOS name 30,
/// subtitle 30, keywords 100 total, promotional text 170, description 4000;
/// Play title 30, short description 80, full description 4000.
StoreMetadata buildStoreMetadata(Map manifest) {
  final identity = (manifest['identity'] as Map?) ?? const {};
  final studio = (manifest['studio'] as Map?) ?? const {};
  final legal = (manifest['legal'] as Map?) ?? const {};
  final store = (manifest['store'] as Map?) ?? const {};

  final name = _s(identity['name'], 'App');
  final tagline = _s(identity['tagline']);
  final short = _s(store['short_description'], tagline);
  final full = _s(store['full_description'], short);
  final keywords = ((store['keywords'] as List?) ?? const [])
      .map((e) => '$e'.trim())
      .where((e) => e.isNotEmpty)
      .join(',');
  final site = _s(studio['marketing_site']);
  final privacyUrl = _s(legal['privacy_url']);
  final releaseNotes = 'Bug fixes and improvements.';

  final warnings = <StoreWarning>[];
  void limit(String field, String value, int max) {
    if (value.length > max) {
      warnings.add(
        StoreWarning(field, '${value.length} chars (limit $max) - shorten it'),
      );
    }
  }

  limit('ios name', name, 30);
  limit('ios subtitle', tagline, 30);
  limit('ios keywords', keywords, 100);
  limit('ios promotional_text', short, 170);
  limit('ios description', full, 4000);
  limit('play title', name, 30);
  limit('play short_description', short, 80);
  limit('play full_description', full, 4000);
  if (keywords.isEmpty) {
    warnings.add(
      const StoreWarning('ios keywords', 'store.keywords is empty - App '
          'Store search needs them'),
    );
  }
  if (privacyUrl.isEmpty) {
    warnings.add(
      const StoreWarning('privacy_url', 'legal.privacy_url is empty - both '
          'stores require it'),
    );
  }

  const ios = 'fastlane/metadata/en-US';
  const play = 'fastlane/metadata/android/en-US';
  final files = <String, String>{
    '$ios/name.txt': name,
    '$ios/subtitle.txt': tagline,
    '$ios/description.txt': full,
    '$ios/keywords.txt': keywords,
    '$ios/promotional_text.txt': short,
    '$ios/release_notes.txt': releaseNotes,
    '$ios/support_url.txt': site,
    '$ios/marketing_url.txt': site,
    '$ios/privacy_url.txt': privacyUrl,
    '$play/title.txt': name,
    '$play/short_description.txt': short,
    '$play/full_description.txt': full,
    '$play/changelogs/default.txt': releaseNotes,
  };

  return StoreMetadata(files, warnings);
}
