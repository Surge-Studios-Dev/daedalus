import 'package:legal_gen/legal_gen.dart';
import 'package:test/test.dart';

Map _manifest({
  String model = 'subscription',
  String trialType = 'store_intro_offer',
  bool email = true,
  bool analytics = true,
  bool crash = true,
  bool tracking = false,
  Map<String, Object?> legalExtra = const {},
}) => {
  'identity': {'slug': 'tally', 'name': 'Tally'},
  'studio': {
    'name': 'Surge Studios LLC',
    'support_email': 'support@surgestudios.dev',
    'marketing_site': 'https://www.surgestudios.dev',
  },
  'monetization': {
    'model': model,
    'trial': {'type': trialType, 'duration_days': trialType == 'none' ? 0 : 7},
  },
  'legal': {
    'data_practices': {
      'collects_email': email,
      'analytics': analytics,
      'crash_reporting': crash,
      'tracking': tracking,
    },
    ...legalExtra,
  },
};

LegalConfig _cfg(Map m) => LegalConfig.fromManifest(m, lastUpdated: '2026-07-01');

void main() {
  test('privacy intro supplements the studio policy', () {
    final p = generatePrivacy(_cfg(_manifest()));
    expect(p.intro, contains('Surge Studios LLC'));
    expect(p.intro, contains('https://www.surgestudios.dev/privacy'));
  });

  test('collected data reflects data_practices flags', () {
    final on = generatePrivacy(_cfg(_manifest()));
    final collect = on.sections.first.body.join(' ');
    expect(collect, contains('email'));
    expect(collect, contains('analytics'));
    // content summary is interpolated (guards against a torn-off function ref)
    expect(collect, contains('the content you create in the app'));
    expect(collect, isNot(contains('Function')));

    final custom = generatePrivacy(
      _cfg(_manifest(legalExtra: {'content_summary': 'notes and folders'})),
    );
    expect(custom.sections.first.body.join(' '), contains('notes and folders'));

    final off = generatePrivacy(
      _cfg(_manifest(email: false, analytics: false, crash: false)),
    );
    final collectOff = off.sections.first.body.join(' ');
    expect(collectOff, isNot(contains('email')));
    expect(collectOff, isNot(contains('analytics')));
  });

  test('providers list depends on flags', () {
    final c = _cfg(_manifest());
    final providers = c.providers().join(' | ');
    expect(providers, contains('Firebase'));
    expect(providers, contains('Crashlytics'));
    expect(providers, contains('RevenueCat'));
    expect(providers, contains('Firebase Analytics'));

    final lean = _cfg(_manifest(model: 'none', analytics: false, crash: false));
    final leanProviders = lean.providers().join(' | ');
    expect(leanProviders, isNot(contains('Crashlytics')));
    expect(leanProviders, isNot(contains('RevenueCat')));
  });

  test('tracking off adds the cross-app promise; on removes it', () {
    final off = generatePrivacy(_cfg(_manifest(tracking: false)));
    final notDo = off.sections.firstWhere((s) => s.heading == 'What we do not do');
    expect(notDo.body.join(' '), contains('track you across'));

    final on = generatePrivacy(_cfg(_manifest(tracking: true)));
    final notDoOn = on.sections.firstWhere((s) => s.heading == 'What we do not do');
    expect(notDoOn.body.join(' '), isNot(contains('track you across')));
  });

  test('terms billing section matches the model', () {
    final sub = generateTerms(_cfg(_manifest(model: 'subscription')));
    expect(sub.sections.map((s) => s.heading), contains('Subscription and billing'));
    expect(sub.sections.firstWhere((s) => s.heading == 'Subscription and billing').body.join(' '),
        contains('free trial'));

    final once = generateTerms(
      _cfg(_manifest(model: 'one_time', trialType: 'app_gated')),
    );
    expect(once.sections.map((s) => s.heading), contains('Purchases and billing'));

    final free = generateTerms(_cfg(_manifest(model: 'none')));
    expect(
      free.sections.map((s) => s.heading),
      isNot(anyElement(contains('billing'))),
    );
  });

  test('domain disclaimer is included when provided', () {
    final t = generateTerms(
      _cfg(_manifest(legalExtra: {'domain_disclaimer': 'Not medical advice.'})),
    );
    final d = t.sections.firstWhere((s) => s.heading == 'Disclaimer');
    expect(d.body.first, 'Not medical advice.');
  });

  test('apple privacy manifest reflects tracking + collected types', () {
    final on = applePrivacyManifest(_cfg(_manifest()));
    expect(on, contains('<key>NSPrivacyTracking</key>'));
    expect(on, contains('<false/>')); // tracking off
    expect(on, contains('NSPrivacyCollectedDataTypeEmailAddress'));
    expect(on, contains('NSPrivacyCollectedDataTypeCrashData'));
    // required-reason API for shared_preferences / UserDefaults
    expect(on, contains('NSPrivacyAccessedAPICategoryUserDefaults'));
    expect(on, contains('CA92.1'));

    final tracked = applePrivacyManifest(_cfg(_manifest(tracking: true)));
    expect(tracked, contains('<key>NSPrivacyTracking</key>\n  <true/>'));
  });

  test('store labels reflect collected data and tracking', () {
    final labels = storePrivacyLabels(_cfg(_manifest()));
    expect(labels, contains('Tracking (ATT): **NO**'));
    expect(labels, contains('Data sold: **NO**'));
    expect(labels, contains('Email address'));
    expect(labels, contains('Crash logs'));
  });
}
