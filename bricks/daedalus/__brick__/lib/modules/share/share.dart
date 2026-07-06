import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:surge_share/surge_share.dart';

import '../telemetry/analytics.dart';

/// The growth rail's seams (Tier-3 surge_share; contract in SHARING.md).
/// Mock by default so a fresh stamp exercises the whole referral loop with
/// no cloud, same as auth/purchases/storage.

/// Active share-link host. Pass the custom domain once provisioned via
/// --dart-define=SHARE_LINK_BASE; the app's *.web.app default host keeps
/// working forever, and BOTH must stay in the iOS entitlements / Android
/// intent filters (old links never die).
const kShareLinkBase = String.fromEnvironment(
  'SHARE_LINK_BASE',
  // The stamped backend's links.ts carries the real per-app default; this
  // fallback only feeds the mock.
  defaultValue: 'https://surge-foundation.web.app',
);

final shareLinksProvider = Provider<ShareLinks>(
  (_) => const ShareLinks(kShareLinkBase),
);

/// SEAM: bootstrap binds a Firebase-callables ShareBackend when useFirebase
/// flips - each method maps 1:1 onto the stamped backend/sharing callables
/// of the same name (createShare, getShare, attachShareCard,
/// attachShareImage, revokeShare, recordShareSave, getReferralStatus,
/// redeemReferral, claimEntitlementCredit).
final shareBackendProvider = Provider<ShareBackend>((_) => MockShareBackend());

final shareServiceProvider = Provider<ShareService>((ref) {
  final analytics = ref.watch(analyticsProvider);
  return ShareService(
    ref.watch(shareBackendProvider),
    onEvent: analytics.log,
  );
});

/// The caller's referral standing (code, invite link, banked credit).
/// Invalidate after a redeem so badges refresh.
final referralStatusProvider = FutureProvider<ReferralStatus>(
  (ref) => ref.watch(shareServiceProvider).referralStatus(),
);

/// Drains banked entitlement-credit days into store grants, one chunk per
/// claim. Call `notify(status.creditDays)` whenever the referral status
/// emits (the invite card does); claiming optimistically is safe - the
/// server refuses while a paid subscription is active and the guard stops
/// loops. SEAM: when RevenueCat is live, refresh customer info in onGranted
/// so the entitlement surfaces immediately, then toast.
final creditClaimerProvider = Provider<CreditClaimer>((ref) {
  return CreditClaimer(
    claim: () => ref.read(shareServiceProvider).claimCredit(),
  );
});
