import 'package:posthog_flutter/posthog_flutter.dart';

import 'analytics.dart';

/// The PostHog-backed [Analytics] sink - the studio's primary product
/// analytics (PostHog is the only dashboard; see ANALYTICS.md). One PostHog
/// project per app (prod + dev), so a client app's analytics transfer with
/// the repo on handoff.
///
/// Selected in bootstrap when POSTHOG_KEY is provided via --dart-define.
/// Session/screen recordings stay OFF (no-PII rule); the opt-out toggle in
/// settings calls [setEnabled].
class PosthogAnalyticsService implements Analytics {
  @override
  void log(String event, [Map<String, Object?> params = const {}]) {
    Posthog().capture(
      eventName: event,
      properties: {
        for (final e in params.entries)
          if (e.value != null) e.key: e.value!,
      },
    );
  }

  @override
  void screen(String name) => Posthog().screen(screenName: name);

  @override
  void identify(String userId) => Posthog().identify(userId: userId);

  @override
  void reset() => Posthog().reset();

  /// The user-facing analytics opt-out (settings). Applies immediately.
  static Future<void> setEnabled(bool enabled) =>
      enabled ? Posthog().enable() : Posthog().disable();
}
