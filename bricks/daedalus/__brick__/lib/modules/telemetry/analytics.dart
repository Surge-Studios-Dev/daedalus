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
/// release. SEAM: bootstrap binds PostHog (primary, when POSTHOG_KEY is set)
/// or Firebase Analytics (fallback under useFirebase).
abstract interface class Analytics {
  void log(String event, [Map<String, Object?> params]);
  void screen(String name);

  /// Tie subsequent events to the signed-in user. The Ladle law: call this at
  /// the SAME moment as [PurchaseService.setUser] (auth controller does both),
  /// or subscription events land on a different distinct id and every
  /// monetization funnel fractures.
  void identify(String userId);

  /// Drop the identity on sign-out / account deletion; the next events are
  /// anonymous again.
  void reset();
}

class DebugAnalytics implements Analytics {
  const DebugAnalytics();

  @override
  void log(String event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) debugPrint('[analytics] $event ${params.isEmpty ? '' : params}');
  }

  @override
  void screen(String name) => log(Ev.screenView, {'screen': name});

  @override
  void identify(String userId) => log('identify', {'user': userId});

  @override
  void reset() => log('reset');
}

final analyticsProvider = Provider<Analytics>((ref) => const DebugAnalytics());
