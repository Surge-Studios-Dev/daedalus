/// Surge meter — the free-tier usage meter (Tier 3 System).
///
/// A periodic allowance ("5 free imports a week") with a DST-safe reset,
/// optional banked bonus credits (referral rewards) that drain only after
/// the period allowance, and an at-limit state for the upsell gate.
///
/// Seam pattern: depend on [UsageMeter] + [MeterStore]; bind
/// [InMemoryMeterStore] in tests and a SharedPreferences-backed store in
/// bootstrap.
///
/// ```dart
/// final meter = UsageMeter(cap: 5, store: prefsStore);
/// if (meter.state.atLimit) return gate(context, 'imports', onSuccess);
/// await meter.consume(); // the moment the metered work succeeds
/// ```
library;

export 'src/meter_allowance.dart';
export 'src/meter_state.dart';
export 'src/meter_store.dart';
export 'src/usage_meter.dart';
