import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surge_rating/surge_rating.dart';

import '../firebase_options.dart';
import '../modules/auth/auth_service.dart';
import '../modules/auth/firebase_auth_service.dart';
import '../modules/paywall/purchase_service.dart';
import '../modules/paywall/revenuecat_purchase_service.dart';
import '../modules/rating/rating.dart';
import '../modules/storage/key_value_store.dart';
import '../modules/storage/shared_prefs_store.dart';
import '../modules/telemetry/analytics.dart';
import '../modules/telemetry/analytics_consent.dart';
import '../modules/telemetry/crashlytics_error_reporter.dart';
import '../modules/telemetry/error_reporter.dart';
import '../modules/telemetry/firebase_analytics_service.dart';
import '../modules/telemetry/posthog_analytics_service.dart';
import 'app.dart';

/// Flip to true once `flutterfire configure` has generated firebase_options.dart
/// and Email/Password is enabled in the Firebase console. Until then the app
/// runs on the in-memory mock auth so it works out of the box.
const bool useFirebase = false;

/// Flip to true once the RevenueCat app + entitlement + products exist and the
/// API key is provided (below). Until then purchases run on the in-memory mock.
const bool useRevenueCat = false;

/// The single entitlement id that unlocks paid value (from the manifest).
const String entitlementId = '{{entitlement}}';

/// RevenueCat public SDK key, injected at build time:
/// `flutter run --dart-define=REVENUECAT_KEY=xxx`. Never commit the value.
const String _revenueCatKey = String.fromEnvironment('REVENUECAT_KEY');

/// PostHog project API key (per app, prod vs dev projects - see ANALYTICS.md),
/// injected at build time: `--dart-define=POSTHOG_KEY=phc_xxx`. When present,
/// PostHog becomes the analytics sink (the studio's only product dashboard);
/// otherwise DebugAnalytics / Firebase Analytics apply. Never commit the key.
const String _posthogKey = String.fromEnvironment('POSTHOG_KEY');
const String _posthogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://us.i.posthog.com',
);

/// One place for all startup wiring. The framework-heavy integrations are
/// selected here so the rest of the app stays backend-agnostic.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final overrides = <Override>[];

  // Persistence is always on: settings and the onboarding flag survive relaunch.
  final prefs = await SharedPreferences.getInstance();
  overrides.add(
    keyValueStoreProvider.overrideWithValue(SharedPrefsKeyValueStore(prefs)),
  );

  // Real store-review prompt on devices. Tests never run bootstrap, so they
  // keep the mock default.
  overrides.add(
    ratingServiceProvider.overrideWithValue(InAppReviewRatingService()),
  );

  if (_posthogKey.isNotEmpty) {
    // PostHog is the primary product-analytics sink (per-app project; see
    // ANALYTICS.md). Recordings stay off (no-PII rule). Consent is honored
    // BEFORE any cold-start event; the settings toggle flips it live.
    final config = PostHogConfig(_posthogKey)..host = _posthogHost;
    await Posthog().setup(config);
    if (prefs.getBool(AnalyticsConsent.key) == false) {
      await Posthog().disable();
    }
    overrides.add(
      analyticsProvider.overrideWithValue(PosthogAnalyticsService()),
    );
  }

  if (useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Route uncaught framework + isolate errors to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    overrides.addAll([
      authServiceProvider.overrideWithValue(FirebaseAuthService()),
      // PostHog is the only product dashboard when configured; Firebase
      // Analytics is the fallback sink, never a second one.
      if (_posthogKey.isEmpty)
        analyticsProvider.overrideWithValue(FirebaseAnalyticsService()),
      errorReporterProvider.overrideWithValue(CrashlyticsErrorReporter()),
    ]);
  }

  if (useRevenueCat) {
    await Purchases.configure(PurchasesConfiguration(_revenueCatKey));
    // Swap the mock purchases binding for the real RevenueCat one. Nothing
    // downstream changes — the app only depends on PurchaseService.
    final purchases = RevenueCatPurchaseService(entitlementId);
    await purchases.start();
    overrides.add(purchaseServiceProvider.overrideWithValue(purchases));
  }

  runApp(ProviderScope(overrides: overrides, child: const SurgeApp()));
}
