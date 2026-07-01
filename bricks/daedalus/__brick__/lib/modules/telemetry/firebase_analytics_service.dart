import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics.dart';

/// The real [Analytics] sink, backed by Firebase Analytics. Selected in
/// bootstrap under useFirebase; the app logs the standard [Ev] taxonomy the
/// same way regardless of sink.
class FirebaseAnalyticsService implements Analytics {
  final _analytics = FirebaseAnalytics.instance;

  @override
  void log(String event, [Map<String, Object?> params = const {}]) {
    final clean = <String, Object>{
      for (final e in params.entries)
        if (e.value != null) e.key: e.value!,
    };
    _analytics.logEvent(name: event, parameters: clean.isEmpty ? null : clean);
  }

  @override
  void screen(String name) => _analytics.logScreenView(screenName: name);
}
