import 'dart:async';

/// Drains banked entitlement-credit days into store grants (SHARING.md
/// "money-shaped state"). Call [notify] whenever the live referral doc
/// emits; whenever it shows credit, one chunk is claimed. The server
/// refuses while a paid entitlement is active (credit stays banked — the
/// win-back case), so claiming optimistically is safe; the guards here
/// stop a rejected claim from looping on every doc emission.
class CreditClaimer {
  CreditClaimer({required this.claim, this.onGranted});

  /// Asks the server to claim one chunk; returns granted days (0 = refused
  /// or nothing banked). Bind to `ShareService.claimCredit`.
  final Future<int> Function() claim;

  /// Called with granted days > 0 — refresh the purchases SDK's customer
  /// info here so the entitlement surfaces now, not on the next refresh,
  /// then toast.
  final void Function(int grantedDays)? onGranted;

  bool _inFlight = false;
  int _attemptedForDays = -1;

  Future<void> notify(int bankedDays) async {
    if (bankedDays < 1 || _inFlight || bankedDays == _attemptedForDays) {
      return;
    }
    _inFlight = true;
    _attemptedForDays = bankedDays;
    try {
      final granted = await claim();
      if (granted > 0) onGranted?.call(granted);
    } catch (_) {
      // Unconfigured store key / offline: the credit stays banked; the next
      // boot (or the next doc emission at a different balance) retries.
    } finally {
      _inFlight = false;
    }
  }
}
