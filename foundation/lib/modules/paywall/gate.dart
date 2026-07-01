import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../telemetry/analytics.dart';
import 'entitlement.dart';

/// The one gating helper. Behaves identically whether the entitlement was
/// granted by a subscription or a one-time unlock: if unlocked, run [onSuccess];
/// otherwise log the block and present the paywall.
///
/// Gate ids are free-form strings so each app defines its own (mirroring the
/// manifest `monetization.gates` list). Usage:
///
/// ```dart
/// ref.gate(context, 'export', () => doExport());
/// ```
extension GateX on WidgetRef {
  void gate(BuildContext context, String gateId, VoidCallback onSuccess) {
    if (read(entitlementProvider)) {
      onSuccess();
    } else {
      read(analyticsProvider).log(Ev.gateBlocked, {'gate': gateId});
      GoRouter.of(context).push('/paywall?source=$gateId');
    }
  }
}
