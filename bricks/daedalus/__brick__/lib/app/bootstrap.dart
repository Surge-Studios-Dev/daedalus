import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../modules/auth/auth_service.dart';
import '../modules/auth/firebase_auth_service.dart';
import '../modules/paywall/purchase_service.dart';
import '../modules/paywall/revenuecat_purchase_service.dart';
import '../modules/storage/key_value_store.dart';
import '../modules/storage/shared_prefs_store.dart';
import '../modules/telemetry/analytics.dart';
import '../modules/telemetry/crashlytics_error_reporter.dart';
import '../modules/telemetry/error_reporter.dart';
import '../modules/telemetry/firebase_analytics_service.dart';
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
