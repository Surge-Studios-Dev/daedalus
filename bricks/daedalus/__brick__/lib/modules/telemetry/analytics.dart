import 'package:firebase_analytics/firebase_analytics.dart';

/// The standard Surge event taxonomy. Identical across every app, so the
/// portfolio dashboard works with zero per-app wiring. Never rename these;
/// add domain events on top.
class Telemetry {
  Telemetry(this._fa);
  final FirebaseAnalytics _fa;

  Future<void> appOpen() => _fa.logAppOpen();
  Future<void> screen(String name) => _fa.logScreenView(screenName: name);
  Future<void> signUp(String method) => _fa.logSignUp(signUpMethod: method);
  Future<void> login(String method) => _fa.logLogin(loginMethod: method);
  Future<void> onboardingComplete() => _e('onboarding_complete');
  Future<void> paywallView(String source) => _e('paywall_view', {'source': source});
  Future<void> trialStart() => _e('trial_start');
  Future<void> purchase(String product, double price) =>
      _e('purchase', {'product': product, 'price': price});
  Future<void> restore() => _e('restore');
  Future<void> cancelIntent() => _e('cancel_intent');
  Future<void> gateBlocked(String gate) => _e('gate_blocked', {'gate': gate});
  Future<void> crossPromoTap(String target) =>
      _e('crosspromo_tap', {'target': target});

  Future<void> _e(String name, [Map<String, Object>? params]) =>
      _fa.logEvent(name: name, parameters: params);
}
