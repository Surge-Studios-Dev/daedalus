/// Surge onboarding — a drop-in first-run flow (Tier 3 System).
///
/// ```dart
/// OnboardingFlow(
///   pages: const [OnboardingPage(icon: Icons.bolt, title: '...', body: '...')],
///   onDone: () { markSeen(); goHome(); },
/// );
/// ```
library;

export 'src/onboarding_page.dart';
export 'src/onboarding_flow.dart';
