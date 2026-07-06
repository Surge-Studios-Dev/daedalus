# surge_meter

The free-tier usage meter — a **Tier 3 System** (see
[`../../FRAMEWORK.md`](../../FRAMEWORK.md)), extracted from Ladle's import
meter. A periodic allowance ("5 free imports a week") with a DST-safe reset,
optional banked bonus credits (referral rewards from the growth rail), and an
at-limit state that feeds the upsell gate. Pairs with INTAKE pass 3's
"is the free tier metered?" answer.

## Use it

```dart
import 'package:surge_meter/surge_meter.dart';

// Seam pattern: InMemoryMeterStore out of the box; bind a
// SharedPreferences-backed MeterStore in bootstrap (snippet in
// meter_store.dart).
final meter = UsageMeter(cap: 5, store: prefsStore);

// Gate the metered action. Entitled users never reach the meter.
final allowance = MeterAllowance.of(meter.state, banked: referral.bankedCredits);
if (allowance.atLimit) return gate(context, 'imports', onSuccess);

// Charge the moment the metered work SUCCEEDS (server budget is spent by
// then), never on save. Periodic units first, then banked, server-decremented:
await consumeAllowance(
  meter,
  banked: referral.bankedCredits,
  spendBanked: shareService.consumeBankedCredits,
);
```

## The rules the meter encodes

Each one shipped as a bug fix or spec edge case in Ladle:

- **Charge on success, not on save** — review-then-discard still spent the
  backend budget. Failed work never consumes.
- **Stored counts only survive their own period** — a new week/month reads
  as a fresh meter, no scheduled reset needed. Week math is DST-safe and
  honors the Mon/Sun week-start setting (via `surge_core`).
- **Consumes await the initial store read** — an auto-started consume (share
  sheet, deep link) fired while the meter still holds its boot default would
  otherwise clobber the real weekly count.
- **Counts clamp to cap** — flows that legitimately bypass the at-limit gate
  (queued share imports finishing) can't push the count unbounded.
- **Banked credits drain last and are server-decremented** — they can't be
  forged or double-spent across devices; an offline banked spend falls back
  to a clamped no-op so earned work is never blocked.

## Status

v0.1.0 — meter, allowance choreography, store seam; behavior locked by the
test port from Ladle. Not yet wired: a foundation reference integration
(the gate + paywall touchpoint) and a surge_ui meter pill component.
