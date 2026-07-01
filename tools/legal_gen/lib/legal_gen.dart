/// Generates a Surge app's legal + compliance assets from its parsed
/// surge.manifest.yaml: a Privacy Policy and Terms of Service (as structured
/// [LegalDoc]s that render in-app and on the marketing site), an Apple privacy
/// manifest (PrivacyInfo.xcprivacy), and a store privacy-label checklist.
///
/// The copy generalizes Ladle's canonical, published legal text and supplements
/// the studio-level policy at the Surge site — per-app notices point back to it.
library;

export 'compliance.dart';

/// One legal section: a heading and one or more paragraphs.
class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final List<String> body;

  Map<String, Object?> toJson() => {'heading': heading, 'body': body};
}

/// A full legal document (privacy or terms).
class LegalDoc {
  const LegalDoc({
    required this.title,
    required this.eyebrow,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String eyebrow;
  final String intro;
  final List<LegalSection> sections;

  Map<String, Object?> toJson() => {
    'title': title,
    'eyebrow': eyebrow,
    'intro': intro,
    'sections': [for (final s in sections) s.toJson()],
  };

  String toMarkdown() {
    final b = StringBuffer()
      ..writeln('# $title')
      ..writeln()
      ..writeln('_${eyebrow}_')
      ..writeln()
      ..writeln(intro)
      ..writeln();
    for (final s in sections) {
      b
        ..writeln('## ${s.heading}')
        ..writeln();
      for (final p in s.body) {
        b
          ..writeln(p)
          ..writeln();
      }
    }
    return b.toString().trimRight() + '\n';
  }
}

/// Everything the generator needs, pulled from the manifest with sensible
/// studio defaults (matching the Surge baseline). App-specific nuance
/// (domain nouns, extra vendors, a domain disclaimer) comes from optional
/// `legal.*` fields; without them the copy stays generic but correct.
class LegalConfig {
  LegalConfig({
    required this.appName,
    required this.slug,
    required this.lastUpdated,
    required this.studioName,
    required this.studioSite,
    required this.supportEmail,
    required this.governingLaw,
    required this.collectsEmail,
    required this.analytics,
    required this.crashReporting,
    required this.tracking,
    required this.monetized,
    required this.subscription,
    required this.hasTrial,
    required this.contentSummary,
    required this.domainDisclaimer,
    required this.extraProviders,
    required this.ageMin,
  });

  final String appName;
  final String slug;
  final String lastUpdated;
  final String studioName;
  final String studioSite;
  final String supportEmail;
  final String governingLaw;
  final bool collectsEmail;
  final bool analytics;
  final bool crashReporting;
  final bool tracking;
  final bool monetized;
  final bool subscription;
  final bool hasTrial;

  /// e.g. "recipes, collections, meal plans, and grocery lists".
  final String contentSummary;

  /// Optional extra disclaimer (e.g. food/health, financial). Null to omit.
  final String? domainDisclaimer;

  /// Extra third-party processors, "Name (purpose)".
  final List<String> extraProviders;
  final String ageMin;

  static String _s(Object? v, String fallback) {
    final s = v?.toString();
    return (s == null || s.trim().isEmpty) ? fallback : s;
  }

  factory LegalConfig.fromManifest(Map m, {required String lastUpdated}) {
    final identity = (m['identity'] as Map?) ?? const {};
    final studio = (m['studio'] as Map?) ?? const {};
    final legal = (m['legal'] as Map?) ?? const {};
    final data = (legal['data_practices'] as Map?) ?? const {};
    final mon = (m['monetization'] as Map?) ?? const {};
    final store = (m['store'] as Map?) ?? const {};
    final model = _s(mon['model'], 'none');
    final trialType = _s((mon['trial'] as Map?)?['type'], 'none');

    return LegalConfig(
      appName: _s(identity['name'], 'the app'),
      slug: _s(identity['slug'], 'app'),
      lastUpdated: lastUpdated,
      studioName: _s(studio['name'], 'Surge Studios LLC'),
      studioSite: _s(studio['marketing_site'], 'https://www.surgestudios.dev'),
      supportEmail: _s(studio['support_email'], 'support@surgestudios.dev'),
      governingLaw: _s(legal['governing_law'], 'the State of Alabama'),
      collectsEmail: data['collects_email'] == true,
      analytics: data['analytics'] == true,
      crashReporting: data['crash_reporting'] == true,
      tracking: data['tracking'] == true,
      monetized: {'subscription', 'one_time', 'hybrid'}.contains(model),
      subscription: model == 'subscription' || model == 'hybrid',
      hasTrial: trialType != 'none',
      contentSummary: _s(legal['content_summary'], 'the content you create in the app'),
      domainDisclaimer: (legal['domain_disclaimer'] as String?)?.trim().isNotEmpty == true
          ? legal['domain_disclaimer'] as String
          : null,
      extraProviders: [
        for (final p in (legal['extra_providers'] as List?) ?? const []) '$p',
      ],
      ageMin: _s(store['age_rating'], '4+') == '4+'
          ? '18'
          : _s(store['age_rating'], '18').replaceAll('+', ''),
    );
  }

  /// The third-party processors this app uses, assembled from the flags.
  List<String> providers() {
    final firebaseParts = ['authentication', 'Cloud Firestore', 'Storage'];
    if (crashReporting) firebaseParts.add('Crashlytics');
    return [
      'Google Firebase (${firebaseParts.join(', ')})',
      if (analytics) 'Firebase Analytics (product analytics)',
      if (monetized) 'RevenueCat (subscriptions and purchases)',
      ...extraProviders,
    ];
  }
}

LegalDoc generatePrivacy(LegalConfig c) {
  final collect = <String>[
    if (c.collectsEmail)
      'Account details when you sign in (email, and optionally your name).',
    'The content you create: ${contentOf(c)}, stored under your authenticated account.',
    if (c.monetized) 'Subscription and purchase information.',
    if (c.crashReporting && c.analytics)
      'Device diagnostics, crash reports, and anonymous usage analytics.'
    else if (c.crashReporting)
      'Device diagnostics and crash reports.'
    else if (c.analytics)
      'Anonymous usage analytics.',
    if (c.tracking)
      'Advertising or cross-app identifiers, only if you allow tracking when the system prompt appears.',
  ];

  final notDo = <String>[
    'We do not sell your personal information.',
    'We do not run third-party ads or share your content with other users.',
    if (!c.tracking)
      "We do not track you across other companies' apps and websites.",
  ];

  return LegalDoc(
    title: 'Privacy policy',
    eyebrow: 'Last updated: ${c.lastUpdated}',
    intro:
        '${c.appName} is a ${c.studioName} product. This notice describes how '
        '${c.appName} handles your data. It is supplemented by the full '
        '${c.studioName} privacy policy at ${c.studioSite}/privacy.',
    sections: [
      LegalSection('What we collect', collect),
      const LegalSection('How we use it', [
        'We use your information to provide and sync the app across your devices, '
            'to operate features you use, to manage any subscription, to keep the '
            'service reliable and prevent abuse, and to improve the experience.',
      ]),
      LegalSection('Service providers', [
        '${c.appName} runs on trusted infrastructure: ${_sentence(c.providers())}.',
      ]),
      LegalSection('What we do not do', notDo),
      const LegalSection('Data sharing', [
        'We share data only with the service providers above, to comply with the '
            'law, to protect rights and safety, or in connection with a business '
            'transaction. ',
      ]),
      const LegalSection('Retention and deletion', [
        'We keep your data while your account is active. Use Delete account in '
            'the app to permanently remove your account and everything in it. '
            'This is irreversible.',
      ]),
      const LegalSection('Security', [
        'We use reasonable administrative, technical, and organizational '
            'safeguards, with encrypted transmission where appropriate. No method '
            'of storage or transmission is completely secure.',
      ]),
      LegalSection('Children', [
        '${c.appName} is intended for users ${c.ageMin} and older. We do not '
            'knowingly collect data from children.',
      ]),
      const LegalSection('Your rights', [
        'Depending on where you live, you may have rights to access, correct, '
            'delete, or restrict use of your personal information.',
      ]),
      LegalSection('Contact', [
        '${c.studioName}. For privacy questions, email ${c.supportEmail} or '
            'visit ${c.studioSite}/contact. The full policy lives at '
            '${c.studioSite}/privacy.',
      ]),
    ],
  );
}

LegalDoc generateTerms(LegalConfig c) {
  final billing = c.monetized
      ? (c.subscription
            ? LegalSection('Subscription and billing', [
                'Paid features are offered as a subscription billed through the '
                    'App Store or Google Play. Pricing, billing cycle, renewal, and '
                    'included features are shown at the time of purchase.',
                if (c.hasTrial)
                  'A free trial converts to a paid subscription unless cancelled at '
                      'least 24 hours before it ends. Manage or cancel from your '
                      'store account settings. Purchases are final except where the '
                      'platform or applicable law requires otherwise.'
                else
                  'Manage or cancel from your store account settings. Purchases are '
                      'final except where the platform or applicable law requires '
                      'otherwise.',
              ])
            : LegalSection('Purchases and billing', [
                'Paid features are unlocked by a one-time purchase billed through '
                    'the App Store or Google Play. What the purchase includes is '
                    'shown at the time of purchase, and purchases are final except '
                    'where the platform or applicable law requires otherwise.',
              ]))
      : null;

  return LegalDoc(
    title: 'Terms of service',
    eyebrow: 'Last updated: ${c.lastUpdated}',
    intro:
        '${c.appName} is a ${c.studioName} product. These terms summarize the '
        'agreement for using ${c.appName} and are supplemented by the full '
        '${c.studioName} Terms of Service at ${c.studioSite}/terms.',
    sections: [
      LegalSection('Acceptance and eligibility', [
        'By using ${c.appName} you agree to these terms. You must be able to '
            'enter a binding agreement and be at least ${c.ageMin} years old.',
      ]),
      const LegalSection('Accounts', [
        'Keep your account information accurate and your credentials secure; you '
            'are responsible for activity on your account. We may suspend or '
            'terminate accounts that violate these terms or create security risks.',
      ]),
      LegalSection('Your content', [
        'You own ${contentOf(c)} that you create. You grant us a limited, '
            'non-exclusive license to process it so we can provide and sync the '
            'app for you.',
      ]),
      if (billing != null) billing,
      const LegalSection('Acceptable use', [
        'Do not break the law, attempt unauthorized access, interfere with the '
            'service, upload malicious content, or reverse engineer the app.',
      ]),
      if (c.domainDisclaimer != null)
        LegalSection('Disclaimer', [c.domainDisclaimer!]),
      const LegalSection('Disclaimers and liability', [
        'The service is provided "as is" and "as available" without warranties '
            'of any kind. To the extent permitted by law, the studio is not liable '
            'for indirect damages or data loss, and total liability is limited to '
            'the amount you paid in the preceding 12 months.',
      ]),
      const LegalSection('Termination', [
        'You can delete your account at any time from within the app. We may '
            'suspend accounts that abuse the service.',
      ]),
      LegalSection('Governing law', [
        'These terms are governed by the laws of ${c.governingLaw}, except where '
            'conflicting requirements apply.',
      ]),
      LegalSection('Contact', [
        '${c.studioName}. Questions: ${c.supportEmail} or ${c.studioSite}/contact. '
            'The full terms live at ${c.studioSite}/terms.',
      ]),
    ],
  );
}

/// Content-summary phrase, lowercased for mid-sentence use.
String contentOf(LegalConfig c) => c.contentSummary;

String _sentence(List<String> items) {
  if (items.isEmpty) return 'trusted infrastructure';
  if (items.length == 1) return items.first;
  return '${items.take(items.length - 1).join(', ')}, and ${items.last}';
}
