import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:surge_ui/surge_ui.dart';

import '../telemetry/analytics.dart';
import 'entitlement.dart';
import 'purchase_service.dart';

/// PAY-01 · Paywall. Model-agnostic: the button set is the same whether the app
/// sells a subscription or a one-time unlock. Restore is mandatory and always
/// present. Purchases go through PurchaseService (mock in dev, RevenueCat when
/// configured); the entitlement id is `{{entitlement}}`.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.source});

  /// Where the paywall was opened from (a gate id or 'settings'); logged.
  final String? source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    ref
        .read(analyticsProvider)
        .log(Ev.paywallView, {'source': widget.source ?? 'direct'});
  }

  void _close() {
    if (context.canPop()) context.pop();
  }

  Future<void> _purchase() async {
    ref.read(analyticsProvider).log(Ev.purchase, {'entitlement': '{{entitlement}}'});
    await ref.read(purchaseServiceProvider).purchase();
    if (mounted && ref.read(entitlementProvider)) _close();
  }

  Future<void> _restore() async {
    ref.read(analyticsProvider).log(Ev.restore);
    await ref.read(purchaseServiceProvider).restore();
    if (!mounted) return;
    if (ref.read(entitlementProvider)) {
      _close();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to restore yet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    const features = [
      'Everything unlocked',
      'No limits',
      'Support future updates',
    ];

    return Scaffold(
      appBar: AppBar(
        leading: SurgeIconButton(
          icon: Icons.close,
          semanticLabel: 'Close',
          onPressed: _close,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: SurgeSpace.lg),
              Text('Go Pro', style: SurgeText.display),
              const SizedBox(height: SurgeSpace.sm),
              Text(
                'Unlock the full app.',
                style: SurgeText.body.copyWith(color: t.inkSecondary),
              ),
              const SizedBox(height: SurgeSpace.xl),
              for (final f in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: SurgeSpace.md),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: t.accentBase, size: 22),
                      const SizedBox(width: SurgeSpace.md),
                      Expanded(child: Text(f, style: SurgeText.body)),
                    ],
                  ),
                ),
              const Spacer(),
              // SEAM: replace with the real product price from RevenueCat.
              SurgeButton.primary(
                {{#has_trial}}'Start {{trial_days}}-day free trial'{{/has_trial}}{{^has_trial}}'Unlock full access'{{/has_trial}},
                full: true,
                onPressed: _purchase,
              ),
              const SizedBox(height: SurgeSpace.sm),
              SurgeButton.ghost('Restore purchases', onPressed: _restore),
              const SizedBox(height: SurgeSpace.sm),
              Text(
                'Reference price shown for illustration. Billed via the store.',
                textAlign: TextAlign.center,
                style: SurgeText.caption.copyWith(color: t.inkTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
