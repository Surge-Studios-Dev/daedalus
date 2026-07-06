import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_ui/surge_ui.dart';

import '../telemetry/analytics.dart';
import 'referral_code_sheet.dart';
import 'share.dart';

/// SET-03 · Invite a friend card (the growth rail, SHARING.md). Inline on
/// the settings surface - an inline card beats a pushed screen for a loop
/// that should always be one glance away. Copy-link keeps the foundation
/// dependency-free; swap in the system share sheet (share_plus) per app if
/// wanted.
class InviteCard extends ConsumerWidget {
  const InviteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(referralStatusProvider);
    // Drain any banked credit whenever the status emits. Optimistic is
    // safe: the backend refuses while a subscription is active, and the
    // claimer's guards stop a rejected claim from looping.
    ref.listen(referralStatusProvider, (_, next) {
      final days = next.value?.creditDays ?? 0;
      ref.read(creditClaimerProvider).notify(days);
    });

    return SurgeCard(
      child: status.when(
        loading: () => const Center(child: SurgeSpinner()),
        error: (_, __) => Text(
          'Invites are unavailable right now.',
          style: SurgeText.subhead,
        ),
        data: (referral) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite a friend', style: SurgeText.headline),
            const SizedBox(height: 4),
            Text(
              'You both get free time when they join with your code.',
              style: SurgeText.subhead.copyWith(
                color: context.tokens.inkSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              referral.code,
              style: SurgeText.title2.copyWith(letterSpacing: 2).tnum,
            ),
            const SizedBox(height: 12),
            SurgeButton.primary(
              'Copy invite link',
              icon: Icons.link,
              full: true,
              onPressed: () async {
                ref.read(analyticsProvider).log(Ev.inviteView);
                await Clipboard.setData(
                  ClipboardData(text: referral.inviteLink),
                );
                if (context.mounted) {
                  showSurgeToast(context, message: 'Invite link copied');
                }
              },
            ),
            if (!referral.redeemedCode)
              SurgeButton.ghost(
                'Have a code?',
                full: true,
                onPressed: () => showReferralCodeSheet(context, ref),
              ),
          ],
        ),
      ),
    );
  }
}
