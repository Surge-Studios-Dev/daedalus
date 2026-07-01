import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_onboarding/surge_onboarding.dart';

import '../telemetry/analytics.dart';
import 'onboarding_controller.dart';

/// ONB-01 · First-run onboarding. Wraps the surge_onboarding System with this
/// app's pages and wires completion to app state (mark seen) + telemetry. The
/// router routes away once complete.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _pages = [
    OnboardingPage(
      icon: Icons.bolt,
      title: 'Welcome',
      body: 'This is your blank Surge app. Replace these pages with your pitch.',
    ),
    OnboardingPage(
      icon: Icons.widgets,
      title: 'Built to fill',
      body: 'Components, screens, and flows are ready. Add your feature and ship.',
    ),
    OnboardingPage(
      icon: Icons.lock_outline,
      title: 'Yours to keep',
      body: 'Sign-in, settings, and account deletion already work out of the box.',
    ),
  ];

  void _finish(WidgetRef ref) {
    ref.read(analyticsProvider).log(Ev.onboardingComplete);
    ref.read(onboardingCompleteProvider.notifier).markSeen();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OnboardingFlow(
      pages: _pages,
      onDone: () => _finish(ref),
      onSkip: () => _finish(ref),
    );
  }
}
