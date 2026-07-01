import 'package:flutter/widgets.dart';

/// One onboarding slide. Data only — the flow renders it.
class OnboardingPage {
  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
