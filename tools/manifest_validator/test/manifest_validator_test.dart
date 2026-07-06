import 'package:manifest_validator/manifest_validator.dart';
import 'package:test/test.dart';

Map _valid() => {
  'identity': {
    'slug': 'tally',
    'name': 'Tally',
    'bundle_id_ios': 'com.surgestudios.tally',
    'package_android': 'com.surgestudios.tally',
  },
  'navigation': {
    'tabs': [
      {'id': 'counters', 'label': 'Counters', 'icon': 'hash', 'type': 'feature'},
      {'id': 'you', 'label': 'You', 'icon': 'user', 'type': 'builtin'},
    ],
  },
  'auth': {'providers': ['email', 'apple', 'google']},
  'monetization': {
    'entitlement': 'pro',
    'model': 'subscription',
    'trial': {'type': 'store_intro_offer', 'duration_days': 7},
    'products': [
      {'id': 'pro_annual', 'type': 'auto_renew_subscription'},
    ],
  },
  'legal': {
    'privacy_url': 'https://x/privacy',
    'terms_url': 'https://x/terms',
  },
  'integrations': {'firebase_project': 'tally-prod'},
};

void main() {
  test('a complete manifest is valid', () {
    expect(validateManifest(_valid()), isEmpty);
  });

  test('flags a bad slug', () {
    final m = _valid();
    (m['identity'] as Map)['slug'] = 'Not Valid';
    expect(validateManifest(m), contains(contains('slug')));
  });

  test('requires 2-5 tabs with a builtin', () {
    final m = _valid();
    (m['navigation'] as Map)['tabs'] = [
      {'id': 'a', 'label': 'A', 'icon': 'home', 'type': 'feature'},
    ];
    final errors = validateManifest(m);
    expect(errors, contains(contains('2-5 entries')));
    expect(errors, contains(contains('builtin tab')));
  });

  test('flags trial/model inconsistency', () {
    final m = _valid();
    (m['monetization'] as Map)['model'] = 'one_time';
    // still store_intro_offer -> inconsistent for one_time
    expect(
      validateManifest(m),
      contains(contains('one_time model cannot use trial.type store_intro_offer')),
    );
  });

  test('requires at least one product and a valid product type', () {
    final m = _valid();
    (m['monetization'] as Map)['products'] = [
      {'id': 'x', 'type': 'bogus'},
    ];
    expect(validateManifest(m), contains(contains('auto_renew_subscription|non_consumable')));
  });

  test('sharing block is optional and a complete one is valid', () {
    final m = _valid();
    m['sharing'] = {
      'referrals': true,
      'reward': {'type': 'entitlement_days', 'per_referral': 7, 'cap': 90},
      'link_domain': 'go.tally.app',
      'content': ['counter'],
    };
    expect(validateManifest(m), isEmpty);
  });

  test('flags an incoherent reward', () {
    final m = _valid();
    m['sharing'] = {
      'reward': {'type': 'cash', 'per_referral': 0, 'cap': -1},
    };
    final errors = validateManifest(m);
    expect(errors, contains(contains('entitlement_days')));
    expect(errors, contains(contains('per_referral must be > 0')));
    expect(errors, contains(contains('cap must be >= per_referral')));
  });

  test('flags a reward on an opted-out app', () {
    final m = _valid();
    m['sharing'] = {
      'referrals': false,
      'reward': {'type': 'entitlement_days', 'per_referral': 7, 'cap': 90},
    };
    expect(validateManifest(m), contains(contains('referrals is false')));
  });

  test('flags a link_domain with a scheme and bad content ids', () {
    final m = _valid();
    m['sharing'] = {
      'link_domain': 'https://go.tally.app',
      'content': ['Counter Thing'],
    };
    final errors = validateManifest(m);
    expect(errors, contains(contains('bare domain')));
    expect(errors, contains(contains('snake_case')));
  });

  test('requires legal urls and firebase project', () {
    final m = _valid()
      ..remove('legal')
      ..remove('integrations');
    final errors = validateManifest(m);
    expect(errors, contains(contains('legal is required')));
    expect(errors, contains(contains('firebase_project')));
  });
}
