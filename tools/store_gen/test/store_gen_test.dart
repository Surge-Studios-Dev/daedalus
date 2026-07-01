import 'dart:io';

import 'package:store_gen/store_gen.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

Map manifest() => {
      'identity': {
        'name': 'Tally',
        // 30-char limit: subtitles carry no terminal period.
        'tagline': 'Count anything, see a streak',
      },
      'studio': {'marketing_site': 'https://surgestudios.dev'},
      'legal': {'privacy_url': 'https://surgestudios.dev/tally/privacy'},
      'store': {
        'keywords': ['counter', 'habit', 'streak', 'tracker'],
        'short_description': 'Count anything, see the streak.',
        'full_description': 'Make a counter for anything you want to track.',
      },
    };

void main() {
  test('maps the store block into deliver + supply trees', () {
    final r = buildStoreMetadata(manifest());

    expect(r.files['fastlane/metadata/en-US/name.txt'], 'Tally');
    expect(
      r.files['fastlane/metadata/en-US/keywords.txt'],
      'counter,habit,streak,tracker',
    );
    expect(
      r.files['fastlane/metadata/en-US/privacy_url.txt'],
      'https://surgestudios.dev/tally/privacy',
    );
    expect(r.files['fastlane/metadata/android/en-US/title.txt'], 'Tally');
    expect(
      r.files['fastlane/metadata/android/en-US/short_description.txt'],
      'Count anything, see the streak.',
    );
    expect(
      r.files['fastlane/metadata/android/en-US/changelogs/default.txt'],
      isNotEmpty,
    );
    // Within limits: no warnings.
    expect(r.warnings, isEmpty);
  });

  test('flags store character-limit violations instead of truncating', () {
    final m = manifest();
    (m['identity'] as Map)['tagline'] =
        'A tagline that is far, far too long for the thirty character subtitle slot';
    (m['store'] as Map)['keywords'] = List.generate(30, (i) => 'keyword$i');
    final r = buildStoreMetadata(m);

    expect(
      r.warnings.map((w) => w.field),
      containsAll(['ios subtitle', 'ios keywords']),
    );
    // Content is preserved verbatim - shortening is a product decision.
    expect(
      r.files['fastlane/metadata/en-US/subtitle.txt'],
      contains('far, far too long'),
    );
  });

  test('warns on missing keywords and privacy url', () {
    final m = manifest();
    (m['store'] as Map).remove('keywords');
    (m['legal'] as Map).remove('privacy_url');
    final r = buildStoreMetadata(m);
    expect(
      r.warnings.map((w) => w.field),
      containsAll(['ios keywords', 'privacy_url']),
    );
  });

  test('generates from the real example manifest', () {
    final doc = loadYaml(
      File('../../surge.manifest.example.yaml').readAsStringSync(),
    ) as Map;
    final r = buildStoreMetadata(doc);
    expect(r.files['fastlane/metadata/en-US/name.txt'], 'Tally');
    expect(r.warnings, isEmpty);
  });
}
