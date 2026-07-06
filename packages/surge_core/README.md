# surge_core

Shared **pure-Dart utilities** (see [`../../FRAMEWORK.md`](../../FRAMEWORK.md)),
extracted from Ladle's `core/` module. No Flutter imports, so anything can
depend on it: app core logic, Tier-3 systems, tests, tools.

Current contents: `dates.dart` — the DST-safe ISO-date helpers every
planner / streak / weekly-meter feature ends up needing.

## Use it

```dart
import 'package:surge_core/surge_core.dart';

final today = toIso(DateTime.now());          // "2026-06-10"
final week = weekStartOf(today);              // Monday of this week
final days = weekDays(week);                  // 7 consecutive ISO dates
fmtWeekRange(week);                           // "Jun 8–14"
fmtRelDate(savedAt, today: today);            // "Yesterday" / "3 days ago"
weekDocKeysFor(days);                         // Mon+Sun doc keys, deduped
```

Rules the module encodes (each one was a shipped bug or a spec edge case in
Ladle):

- **Calendar arithmetic only, never `Duration.inDays`.** A spring-forward day
  is 23 wall-clock hours; `Duration.inDays` floors it to 0 and week math
  collapses once a year.
- **"today" is injected, never read from the clock**, so logic stays
  testable and week boundaries follow the device's local calendar.
- **Week-start is a user setting (Mon/Sun), and data outlives the setting.**
  `weekDocKeysFor` returns every doc key that could hold a day's rows so
  readers and writers agree across a mid-data toggle.

## Status

v0.1.0 — dates only, tests ported from Ladle. Candidates for later
promotion once a second app needs them: fraction formatting, quantity
scaling (currently food-flavored in Ladle; generalize on the way in).
