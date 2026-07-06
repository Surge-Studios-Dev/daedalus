import 'meter_state.dart';
import 'usage_meter.dart';

/// The full allowance: the periodic free meter plus banked bonus credits
/// (referral rewards from the growth rail). Periodic units spend first;
/// banked credits never expire and only start draining once the period's
/// allowance is gone. Entitled (paid) users bypass all of this.
class MeterAllowance {
  const MeterAllowance({required this.periodLeft, required this.banked});

  MeterAllowance.of(MeterState meter, {int banked = 0})
    : this(periodLeft: meter.left, banked: banked);

  final int periodLeft;
  final int banked;

  int get totalLeft => periodLeft + banked;
  bool get atLimit => totalLeft <= 0;
}

/// Charge one unit against the full allowance: the periodic meter while it
/// lasts, then a banked credit via [spendBanked] (server-decremented so it
/// can't be forged or double-spent across devices). Falls back to the plain
/// periodic consume when the banked spend fails or races to empty — the
/// consume is a clamped no-op at cap, so the user's earned work is never
/// blocked by an offline banked ledger.
Future<void> consumeAllowance(
  UsageMeter meter, {
  int banked = 0,
  Future<bool> Function()? spendBanked,
}) async {
  final current = await meter.loadedState();
  if (current.left > 0) {
    await meter.consume();
    return;
  }
  if (banked > 0 && spendBanked != null) {
    try {
      final spent = await spendBanked();
      if (spent) return;
    } catch (_) {
      // Offline/transient: fall through to the clamped periodic consume.
    }
  }
  await meter.consume();
}
