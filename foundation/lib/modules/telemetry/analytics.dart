import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The standard Surge event taxonomy (identical across every app, so a
/// portfolio dashboard works with zero per-app wiring). Apps add domain events
/// on top; never rename these.
abstract final class Ev {
  static const appOpen = 'app_open';
  static const screenView = 'screen_view';
  static const signUp = 'sign_up';
  static const login = 'login';
  static const onboardingComplete = 'onboarding_complete';
  static const paywallView = 'paywall_view';
  static const trialStart = 'trial_start';
  static const purchase = 'purchase';
  static const restore = 'restore';
  static const cancelIntent = 'cancel_intent';
  static const gateBlocked = 'gate_blocked';
  static const crosspromoTap = 'crosspromo_tap';
}

/// Analytics sink. The default [DebugAnalytics] prints in debug and no-ops in
/// release. SEAM: swap for a FirebaseAnalytics-backed impl in bootstrap.
abstract interface class Analytics {
  void log(String event, [Map<String, Object?> params]);
  void screen(String name);
}

class DebugAnalytics implements Analytics {
  const DebugAnalytics();

  @override
  void log(String event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) debugPrint('[analytics] $event ${params.isEmpty ? '' : params}');
  }

  @override
  void screen(String name) => log(Ev.screenView, {'screen': name});
}

final analyticsProvider = Provider<Analytics>((ref) => const DebugAnalytics());
