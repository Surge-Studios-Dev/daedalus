import 'legal_gen.dart';

/// One collected data type, in Apple + Play terms.
class _DataType {
  const _DataType({
    required this.appleType,
    required this.label,
    required this.linked,
    required this.applePurpose,
    required this.playCategory,
  });
  final String appleType; // NSPrivacyCollectedDataType* constant
  final String label; // human label for the checklist
  final bool linked; // linked to the user's identity
  final String applePurpose; // NSPrivacyCollectedDataTypePurpose* constant
  final String playCategory;
}

List<_DataType> _collected(LegalConfig c) => [
  if (c.collectsEmail)
    const _DataType(
      appleType: 'NSPrivacyCollectedDataTypeEmailAddress',
      label: 'Email address',
      linked: true,
      applePurpose: 'NSPrivacyCollectedDataTypePurposeAppFunctionality',
      playCategory: 'Personal info: Email address',
    ),
  if (c.monetized)
    const _DataType(
      appleType: 'NSPrivacyCollectedDataTypePurchaseHistory',
      label: 'Purchase history',
      linked: true,
      applePurpose: 'NSPrivacyCollectedDataTypePurposeAppFunctionality',
      playCategory: 'Financial info: Purchase history',
    ),
  if (c.analytics)
    const _DataType(
      appleType: 'NSPrivacyCollectedDataTypeProductInteraction',
      label: 'Product interaction (usage analytics)',
      linked: false,
      applePurpose: 'NSPrivacyCollectedDataTypePurposeAnalytics',
      playCategory: 'App activity: App interactions',
    ),
  if (c.crashReporting)
    const _DataType(
      appleType: 'NSPrivacyCollectedDataTypeCrashData',
      label: 'Crash data',
      linked: false,
      applePurpose: 'NSPrivacyCollectedDataTypePurposeAppFunctionality',
      playCategory: 'App info and performance: Crash logs',
    ),
];

/// Apple privacy manifest (PrivacyInfo.xcprivacy). Declares tracking, the data
/// types collected, and required-reason API usage. Required by App Store review.
/// The base uses shared_preferences (UserDefaults, reason CA92.1); add more
/// required-reason APIs as you wire integrations.
String applePrivacyManifest(LegalConfig c) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
      '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
    )
    ..writeln('<plist version="1.0">')
    ..writeln('<dict>')
    ..writeln('  <key>NSPrivacyTracking</key>')
    ..writeln('  <${c.tracking ? 'true' : 'false'}/>')
    ..writeln('  <key>NSPrivacyTrackingDomains</key>')
    ..writeln('  <array/>')
    ..writeln('  <key>NSPrivacyCollectedDataTypes</key>')
    ..writeln('  <array>');
  for (final d in _collected(c)) {
    b
      ..writeln('    <dict>')
      ..writeln('      <key>NSPrivacyCollectedDataType</key>')
      ..writeln('      <string>${d.appleType}</string>')
      ..writeln('      <key>NSPrivacyCollectedDataTypeLinked</key>')
      ..writeln('      <${d.linked ? 'true' : 'false'}/>')
      ..writeln('      <key>NSPrivacyCollectedDataTypeTracking</key>')
      ..writeln('      <${c.tracking ? 'true' : 'false'}/>')
      ..writeln('      <key>NSPrivacyCollectedDataTypePurposes</key>')
      ..writeln('      <array>')
      ..writeln('        <string>${d.applePurpose}</string>')
      ..writeln('      </array>')
      ..writeln('    </dict>');
  }
  b
    ..writeln('  </array>')
    ..writeln('  <key>NSPrivacyAccessedAPITypes</key>')
    ..writeln('  <array>')
    ..writeln('    <dict>')
    ..writeln('      <key>NSPrivacyAccessedAPIType</key>')
    ..writeln('      <string>NSPrivacyAccessedAPICategoryUserDefaults</string>')
    ..writeln('      <key>NSPrivacyAccessedAPITypeReasons</key>')
    ..writeln('      <array>')
    ..writeln('        <string>CA92.1</string>')
    ..writeln('      </array>')
    ..writeln('    </dict>')
    ..writeln('  </array>')
    ..writeln('</dict>')
    ..writeln('</plist>');
  return b.toString();
}

/// A human checklist for the App Store "App Privacy" and Play "Data safety"
/// forms, derived from data_practices. These forms are filled by hand in the
/// consoles; this is the exact answer key.
String storePrivacyLabels(LegalConfig c) {
  final types = _collected(c);
  final b = StringBuffer()
    ..writeln('# ${c.appName} - store privacy labels')
    ..writeln()
    ..writeln('Generated from surge.manifest.yaml. Use this to fill the App Store '
        '"App Privacy" and Google Play "Data safety" forms. Verify against '
        'current store requirements before each submission.')
    ..writeln()
    ..writeln('- Tracking (ATT): **${c.tracking ? 'YES' : 'NO'}**')
    ..writeln('- Data sold: **NO**')
    ..writeln('- Encrypted in transit: **YES**')
    ..writeln('- Account deletion in-app: **YES**')
    ..writeln()
    ..writeln('## Apple App Privacy')
    ..writeln();
  if (types.isEmpty) {
    b.writeln('- No data collected.');
  } else {
    b.writeln('| Data type | Linked to identity | Used for tracking | Purpose |');
    b.writeln('|---|---|---|---|');
    for (final d in types) {
      final purpose = d.applePurpose.contains('Analytics')
          ? 'Analytics'
          : 'App Functionality';
      b.writeln('| ${d.label} | ${d.linked ? 'Yes' : 'No'} | '
          '${c.tracking ? 'Yes' : 'No'} | $purpose |');
    }
  }
  b
    ..writeln()
    ..writeln('## Google Play Data Safety')
    ..writeln();
  if (types.isEmpty) {
    b.writeln('- No data collected.');
  } else {
    b.writeln('Data collected (not shared with third parties for their own use):');
    b.writeln();
    for (final d in types) {
      b.writeln('- ${d.playCategory}');
    }
  }
  return b.toString().trimRight() + '\n';
}
