import 'dart:io';

import 'package:spec_gen/spec_gen.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

Map subscriptionManifest() => {
      'identity': {
        'slug': 'tally',
        'name': 'Tally',
        'tagline': 'Count anything, see the streak.',
      },
      'brand': {
        'palette': {
          'accent': '#75D8FF',
          'accent_soft': '#2B89D8',
          'panel': '#0E1B27',
        },
        'logo_mode': 'wordmark',
        'fonts': {'display': 'Inter', 'text': 'Inter'},
      },
      'navigation': {
        'tabs': [
          {'id': 'counters', 'label': 'Counters', 'icon': 'hash', 'type': 'feature'},
          {'id': 'insights', 'label': 'Insights', 'icon': 'bar-chart', 'type': 'feature'},
          {'id': 'you', 'label': 'You', 'icon': 'user', 'type': 'builtin'},
        ],
        'primary_action': {'id': 'add', 'label': 'New', 'icon': 'plus'},
      },
      'auth': {
        'providers': ['email', 'apple', 'google'],
        'guest_mode': true,
      },
      'monetization': {
        'entitlement': 'pro',
        'model': 'subscription',
        'trial': {'type': 'store_intro_offer', 'duration_days': 7},
        'products': [
          {
            'id': 'pro_annual',
            'type': 'auto_renew_subscription',
            'period': 'P1Y',
            'reference_price': 19.99,
            'default': true,
          },
        ],
        'gates': ['unlimited_counters', 'export'],
      },
      'features': {'notifications': false},
    };

void main() {
  test('fills the derivable structure from a subscription manifest', () {
    final spec = generateSpec(subscriptionManifest(), date: '2026-07-01');

    expect(spec, contains('# Tally · Product Spec'));
    expect(spec, contains('Count anything, see the streak.'));
    // Tab map + primary action.
    expect(spec, contains('**Counters** (`counters`, icon `hash`)'));
    expect(spec, contains('builtin settings stack'));
    expect(spec, contains('Center action: **New**'));
    // Screen inventory: factory screens + seeded feature roots.
    expect(spec, contains('| SYS-01 |'));
    expect(spec, contains('| AUTH-02 | Sign up (email)'));
    expect(spec, contains('| PAY-01 |'));
    expect(spec, contains('| COU-01 | Counters home | P0 |'));
    expect(spec, contains('| INS-01 | Insights home | P0 |'));
    expect(spec, contains('### COU-01 · Counters home [P0]'));
    // Gates render as table rows wired to the paywall src pattern.
    expect(spec, contains('| `unlimited_counters` |'));
    expect(spec, contains('`tally://paywall?src={gateId}`'));
    // Monetization mechanics.
    expect(spec, contains('Model: **subscription** · entitlement `pro`'));
    expect(spec, contains('7-day store intro offer'));
    expect(spec, contains(r'ref $19.99, default'));
    // Notifications off -> explicit not-in-v1 wording.
    expect(spec, contains('Not in v1 (`features.notifications: false`)'));
    // Edge-case prompts per feature tab.
    expect(spec, contains('- **Counters:** **TODO**'));
    // §11 write-back structure + §12 assumptions log.
    expect(spec, contains('### Resolved'));
    expect(spec, contains('## 12. Assumptions'));
    expect(spec, contains('Decisions made without asking.'));
    // No unrendered placeholders, no torn-off closures.
    expect(spec, isNot(contains('{{')));
    expect(spec, isNot(contains('Closure')));
  });

  test('app_gated one_time manifest renders the in-app trial contract', () {
    final m = subscriptionManifest();
    m['monetization'] = {
      'entitlement': 'full',
      'model': 'one_time',
      'trial': {'type': 'app_gated', 'duration_days': 14},
      'products': [
        {'id': 'unlock', 'type': 'non_consumable', 'reference_price': 9.99},
      ],
      'gates': <String>[],
    };
    m['features'] = {'notifications': true};
    final spec = generateSpec(m, date: '2026-07-01');

    expect(spec, contains('14-day app-gated window enforced in-app'));
    expect(spec, contains('Remote Config key `trial_days`'));
    expect(spec, contains('no gates in the manifest'));
    // Notifications on -> the NTF table skeleton appears.
    expect(spec, contains('| NTF-01 |'));
    expect(spec, contains('max 1 reminder-class notification per day'));
  });

  test('tab prefixes are stable, deduped, and avoid reserved ones', () {
    final p = tabPrefixes([
      {'id': 'counters'},
      {'id': 'courses'}, // collides with COU -> extends to COUR
      {'id': 'payments'}, // collides with reserved PAY -> PAYM
    ]);
    expect(p['counters'], 'COU');
    expect(p['courses'], 'COUR');
    expect(p['payments'], 'PAYM');
    expect(reservedPrefixes.contains(p['payments']), isFalse);
  });

  test('section headers stay in sync with templates/spec.template.md', () {
    List<String> headers(String md) => md
        .split('\n')
        .where((l) => l.startsWith('## '))
        .map((l) => l.trim())
        .toList();

    final template =
        File('../../templates/spec.template.md').readAsStringSync();
    final generated = generateSpec(subscriptionManifest(), date: '2026-07-01');

    expect(
      headers(generated),
      headers(template),
      reason: 'templates/spec.template.md and spec_gen must present the same '
          'section structure - update both together.',
    );
  });

  test('generates from the real example manifest without error', () {
    final doc = loadYaml(
      File('../../surge.manifest.example.yaml').readAsStringSync(),
    ) as Map;
    final spec = generateSpec(doc, date: '2026-07-01');
    expect(spec, contains('# Tally · Product Spec'));
    expect(spec, contains('| COU-01 |'));
  });
}
