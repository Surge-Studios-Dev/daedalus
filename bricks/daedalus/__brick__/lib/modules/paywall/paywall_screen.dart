import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Paywall for {{name}}. Monetization model: {{mon_model}}; trial: {{trial_type}}.
///
/// SKELETON. The structure and flow are correct; verify the RevenueCat API
/// surface against your installed purchases_flutter version and wire Telemetry
/// (paywallView on present, trialStart / purchase / restore on action).
///
/// Model behaviour (selected at generation time from the manifest):
///  - subscription: shows auto-renew products; the free trial is the store
///    intro offer, surfaced by RevenueCat. No app-side trial logic.
///  - one_time: shows the non-consumable unlock; the trial window is enforced
///    by TrialWindow (see trial.dart), not the store.
///  - hybrid: shows both; the entitlement granted is still single.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key, required this.source});
  final String source;

  static Future<void> present(BuildContext context, {required String source}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PaywallScreen(source: source),
    );
  }

  Future<Offering?> _offering() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current; // configure "default" offering in RevenueCat
  }

  Future<void> _restore(BuildContext context) async {
    await Purchases.restorePurchases();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Unlock {{name}}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            // TODO: FutureBuilder<Offering?>(_offering) -> render package tiles.
            // On tap: Purchases.purchasePackage(pkg), then pop on success.
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {/* TODO purchase default package */},
              child: const Text('Continue'),
            ),
            TextButton(
              onPressed: () => _restore(context),
              child: const Text('Restore purchases'), // mandatory, keep visible
            ),
          ],
        ),
      ),
    );
  }
}
