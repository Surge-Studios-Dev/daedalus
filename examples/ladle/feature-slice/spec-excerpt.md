# Spec excerpt — the sections this slice implements

Verbatim from Ladle's `/design/original-spec.md`. This is what "the spec
drives the code" means in practice: every behavior below has a line of
code and a test you can point at, and nothing in the code exists that
this text (plus §8) doesn't ask for.

## §4.3 Free import meter

> 5 imports per calendar week, resets Monday 00:00 device-local. Counts:
> link imports, photo scans, share-extension saves. Does NOT count:
> manual creates, edits, remixes of owned recipes. Meter UI
> (`meter.imports`) appears: always in IMP-01 footer; as a
> `banner.inline` atop LIB-01 when ≤2 remain ("2 free imports left this
> week · Upgrade for unlimited" with ghost "See Plus"). At 0: Add sheet
> import options show `chip.plus`, tap → PAY-01 (`src=gate_imports`).

## Gating table (the meter's row)

> | Unlimited imports | `gate_imports` | 6th import in a week | IMP-01
> meter at 0; primary action routes to PAY-01 |

## Later amendments that landed in this code

- **Charge on extraction success, not on Save** — reviewing-then-
  discarding still costs an attempt (the backend already spent the
  budget). Failed extractions do not consume.
- **Banked imports** (referral-earned, SHARING rail): never expire,
  drain only after the weekly 5, server-decremented so they can't be
  forged or double-spent across devices.
