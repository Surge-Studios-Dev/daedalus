import 'package:flutter/material.dart';
import 'entitlement.dart';
import 'paywall_screen.dart';

typedef GateId = String;

/// Gate ids declared in the manifest (monetization.gates). Kept as strings
/// rather than named constants because ids like `import`/`export` are Dart
/// reserved words. Reference as `kGates` membership or pass the literal.
const Set<GateId> kGates = {
{{#gates}}  '{{gate}}',
{{/gates}}};

/// Runs [onSuccess] if the user holds `{{entitlement}}`, otherwise presents the
/// paywall. Identical for subscription, one-time, and hybrid apps. Gated UI
/// should stay visible (with a Plus affordance), never hidden or greyed.
Future<void> gate(BuildContext context, GateId id, VoidCallback onSuccess) async {
  if (await Entitlement.hasPro()) {
    onSuccess();
    return;
  }
  if (!context.mounted) return;
  await PaywallScreen.present(context, source: id);
}
