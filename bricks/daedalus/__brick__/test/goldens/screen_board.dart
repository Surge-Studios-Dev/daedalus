import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_board/golden_board.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:{{slug}}/app/nav_config.dart';
import 'package:{{slug}}/app/theme.dart';
import 'package:{{slug}}/dev/fixtures.dart';
import 'package:{{slug}}/features/feature_registry.dart';
import 'package:{{slug}}/modules/auth/sign_in_screen.dart';
import 'package:{{slug}}/modules/onboarding/onboarding_screen.dart';
import 'package:{{slug}}/modules/paywall/paywall_screen.dart';
import 'package:{{slug}}/modules/settings/settings_screen.dart';

/// {{name}} screen board — every screen as light/dark PNGs plus a browsable
/// contact sheet, headlessly. This is how an agent (or you) SEES the app
/// without booting a simulator: run it after any visual change and open
/// test/goldens/contact_sheet.html.
///
///   flutter test --update-goldens test/goldens/screen_board.dart
///
/// Deliberately NOT named *_test.dart: it is a dev tool, not a committed
/// test, and its output (screens/, contact_sheet.html) is gitignored.
/// Screens render with the seed data from lib/dev/fixtures.dart — grow both
/// together as real features land, and add per-screen entries here for
/// presented routes (sheets, editors) worth proofing.
void main() => screenBoard(
  [
    for (final tab in navTabs.where((t) => !t.builtin))
      ScreenSpec(
        id: tab.id,
        label: tab.label,
        build: () => Builder(
          builder: (context) => featureBuilders[tab.id]!(context),
        ),
      ),
    const ScreenSpec(id: 'sign_in', label: 'Sign in', build: SignInScreen.new),
    const ScreenSpec(
      id: 'settings',
      label: 'Settings',
      build: SettingsScreen.new,
    ),
    // The first impression and the money screen - the two surfaces where a
    // visual regression costs the most, on the board from day one.
    const ScreenSpec(
      id: 'onboarding',
      label: 'Onboarding',
      build: OnboardingScreen.new,
    ),
    const ScreenSpec(
      id: 'paywall',
      label: 'Paywall',
      build: PaywallScreen.new,
    ),
  ],
  title: '{{name}} screen board',
  // The board must render the SHIPPING theme (lib/app/theme.dart), not
  // pack defaults - a board in the wrong clothes proofs a different app
  // (Ember's first board rendered pack defaults and hid the brand).
  host: (brightness, child) => ProviderScope(
    overrides: devSeedOverrides(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(brightness),
      home: child,
    ),
  ),
  // Goldens render Ahem blocks for any unloaded family: load every bundled
  // brand font file (assets/fonts, added at M1) and MaterialIcons from the
  // Flutter SDK so type and icons on the board are real.
  fonts: [
    if (Directory('assets/fonts').existsSync())
      for (final f in Directory('assets/fonts')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.ttf') || f.path.endsWith('.otf')))
        BoardFont.asset(family: appFontFamily, path: f.path),
    if (Platform.environment['FLUTTER_ROOT'] case final root?)
      BoardFont.asset(
        family: 'MaterialIcons',
        path: '$root/bin/cache/artifacts/material_fonts/'
            'MaterialIcons-Regular.otf',
      ),
  ],
  beforeEach: () async => SharedPreferences.setMockInitialValues({}),
);
