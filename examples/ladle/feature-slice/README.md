# Feature slice — what "done" looks like

One complete vertical from Ladle (the shipped app this framework is
extracted from), copied verbatim: the **free import meter**, spec §4.3.
It's the smallest slice that shows every layer of the house style, end to
end, in ~270 lines. Read it before building your first feature; imitate
its shape, not its domain.

These files reference `package:ladle/...` and do not compile here — they
are a reference, not a library. The reusable logic inside them has since
been promoted (see "The promotion path" below).

## The map

| File | Layer | What to imitate |
|---|---|---|
| [`spec-excerpt.md`](spec-excerpt.md) | Spec | The feature starts as spec text with an ID and a gating row. Code implements exactly this; deviations get recorded, not improvised. |
| [`import_meter_state.dart`](import_meter_state.dart) | State | One `Notifier` per domain concern. Persistence inline (`SharedPreferences`, JSON blob keyed by period). The `_loaded` future is the part to study: `consume()` awaits the initial read so an auto-started share import can't clobber the persisted count — the doc comment says WHY and cites the spec section. Counts clamp to cap because gate-bypassing flows exist. |
| [`import_credits.dart`](import_credits.dart) | Derived state | `ImportCredits` is a **computed provider — derived data is never stored**. It composes the meter with referral-earned banked credits, and `consumeImportCredit` encodes the spend order (weekly first, then banked, server-decremented, graceful offline fallback). |
| [`import_meter.dart`](import_meter.dart) | Component | Token-only styling (`context.tokens`, no hex), type from the shared scale with `tnum` on numerals, spec component id in the doc comment (`meter.imports`), copy matching the spec verbatim. Presentational: state comes in as plain fields. |
| [`import_test.dart`](import_test.dart) | Tests | Written against the same spec text: count/clamp, the Monday reset rule (previous week resets, same week survives), and the widget rendering the exact spec copy. Prefs seeded per test; `ProviderContainer` + `addTearDown`. |

## House rules this slice demonstrates

- **Spec section → doc comment → test name** all reference each other;
  coverage is greppable against the spec.
- **Derived data is computed, never stored** (`ImportCredits`).
- **Screens/components never define one-off styling** — tokens and the
  shared text scale only.
- **Money-adjacent counters are defensive**: clamp at cap, await the
  first read, server-decrement anything a client could forge.
- **Copy is sentence case and matches the spec word for word** — the
  test asserts the literal string.

## The promotion path (FRAMEWORK.md in action)

This slice shipped app-specific, then earned its way into the shared
layer once the framework existed. In a new Surge app you would NOT copy
these files; you'd write a thin Riverpod binding over the promoted
packages and keep only the domain flavor:

- weekly reset + banked-credit spend order + the load race →
  **`surge_meter`** (`UsageMeter`, `MeterAllowance`, `consumeAllowance`)
- DST-safe week math (`weekStartOf`, `toIso`) → **`surge_core`**
- the dot-row meter component → still app-side (candidate for `surge_ui`
  once a second app needs it; see FRAMEWORK.md's promotion bar)

That is the intended lifecycle for everything in `features/`: ship it
app-flavored, and when a second app wants it, generalize it up.
