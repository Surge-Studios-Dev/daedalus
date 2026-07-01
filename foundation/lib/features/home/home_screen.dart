import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_ui/surge_ui.dart';

import '../../modules/paywall/gate.dart';

/// HOME-01 · The blank home. A wired stub: it runs, it is themed, and it shows
/// how a feature calls the gate. Replace the body with the app's real content.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          SurgeIconButton(
            icon: Icons.workspace_premium,
            semanticLabel: 'Try a gated action',
            onPressed: () => ref.gate(context, 'demo', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unlocked action ran.')),
              );
            }),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dashboard_customize, size: 48, color: t.inkTertiary),
              const SizedBox(height: SurgeSpace.lg),
              Text(
                'Your feature goes here',
                style: SurgeText.title2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: SurgeSpace.sm),
              Text(
                'This is a blank, wired canvas. Build the home tab, then tap the '
                'crown to see gate() present the paywall.',
                style: SurgeText.body.copyWith(color: t.inkSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
