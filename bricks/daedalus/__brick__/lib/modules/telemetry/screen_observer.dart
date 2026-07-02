import 'package:flutter/widgets.dart';

import 'analytics.dart';

/// Fires [Analytics.screen] on route changes so screen-level views exist in
/// every sink with zero per-screen wiring. Routes need a `name:` on their
/// GoRoute to appear; unnamed routes are skipped, never guessed (a guessed
/// path could leak ids into analytics).
class AnalyticsScreenObserver extends NavigatorObserver {
  AnalyticsScreenObserver(this._analytics);

  final Analytics _analytics;

  void _send(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty) _analytics.screen(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _send(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _send(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _send(newRoute);
}
