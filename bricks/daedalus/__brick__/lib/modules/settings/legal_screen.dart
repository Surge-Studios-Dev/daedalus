import 'package:flutter/material.dart';
import 'package:surge_ui/surge_ui.dart';

/// SET-03 · Legal. Renders per-app legal text in-app (Privacy / Terms).
///
/// SEAM: load the real drafted markdown (forge.sh writes legal/privacy.md and
/// legal/terms.md from the manifest) and render it; these are placeholders so
/// the screens exist and are linkable from settings and the store listing.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.kind});

  /// 'privacy' or 'terms'.
  final String kind;

  bool get _isPrivacy => kind == 'privacy';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final title = _isPrivacy ? 'Privacy policy' : 'Terms of service';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(title, style: SurgeText.title2),
          const SizedBox(height: SurgeSpace.sm),
          Text(
            'DRAFT — replace with the reviewed document.',
            style: SurgeText.footnote.copyWith(color: t.inkTertiary),
          ),
          const SizedBox(height: SurgeSpace.lg),
          Text(
            _isPrivacy ? _privacyPlaceholder : _termsPlaceholder,
            style: SurgeText.body.copyWith(color: t.inkSecondary),
          ),
        ],
      ),
    );
  }
}

const _privacyPlaceholder =
    'We handle the minimum data needed to run the app: your account email, '
    'aggregate usage analytics, and crash diagnostics. You can delete your '
    'account and associated data in-app under Account.';

const _termsPlaceholder =
    'This app is provided as-is. Subscriptions and purchases are billed through '
    'the App Store or Google Play and managed there.';
