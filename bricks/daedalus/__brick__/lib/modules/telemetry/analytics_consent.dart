import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/key_value_store.dart';
import 'posthog_analytics_service.dart';

/// The user-facing analytics opt-out (settings, default ON), persisted via
/// [KeyValueStore]. Bootstrap reads the same key before wiring PostHog so a
/// prior opt-out is respected before any cold-start event fires; toggling
/// applies immediately via [PosthogAnalyticsService.setEnabled].
class AnalyticsConsent extends Notifier<bool> {
  static const key = 'analytics_enabled';

  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  @override
  bool build() => _store.getBool(key) ?? true;

  void toggle() {
    state = !state;
    _store.setBool(key, state);
    PosthogAnalyticsService.setEnabled(state);
  }
}

final analyticsConsentProvider =
    NotifierProvider<AnalyticsConsent, bool>(AnalyticsConsent.new);
