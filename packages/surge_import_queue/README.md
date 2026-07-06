# surge_import_queue

Share-sheet intake — a **Tier 3 System** (see
[`../../FRAMEWORK.md`](../../FRAMEWORK.md)), extracted from Ladle's share
pipeline. The pure-Dart half of "share a link INTO the app": a durable
inbox, an allowance-aware drain plan, and a coalescer for overlapping drain
triggers. The platform half (iOS share extension + app group, Android
ACTION_SEND, the method-channel contract) lives in
[`../../templates/share_extension/`](../../templates/share_extension/).

## Use it

```dart
import 'package:surge_import_queue/surge_import_queue.dart';

final inbox = ShareInbox(prefsStore); // seam: InMemoryInboxStore in tests
final coalescer = DrainCoalescer();

// On launch first-frame, every resume, native drainNow, and any listener
// that can raise the allowance (credits arriving, upgrade):
await coalescer.run(() async {
  final fresh = await channel.invokeMethod<List>('drainPendingImports');
  for (final value in fresh ?? const []) {
    await inbox.add('$value'); // durable BEFORE any work starts
  }

  final plan = planDrain(
    all: await inbox.all(),
    fresh: [...?fresh?.map((v) => '$v')],
    active: runningJobsByInboxKey,
    allowed: entitled ? pendingCount : allowance.totalLeft,
  );
  for (final value in plan.start) {
    startJob(value, inboxKey: value);
  }
  if (plan.freshBlocked) warnOutOfCredits(); // dialog, not a toast
});
```

## The rules the plan encodes

Each shipped as a production regression in Ladle:

- **Fresh shares outrank the queued backlog.** Oldest-first spending let
  stuck replays starve the link the user JUST shared into a silent no-op —
  the app opened and nothing happened.
- **Freshness comes from this drain's platform queue, not inbox order** —
  the inbox dedupes, so a re-shared old link keeps its position but still
  wins the allowance.
- **Running jobs are reused, never double-started**; a re-share of an
  in-flight link surfaces the running job's UI instead of warning.
- **A blocked fresh share warns loudly** (dialog with the paywall path);
  blocked background replays stay silent.
- **Replays never double-charge the meter** (`isMetered`/`markMetered`) and
  **permanent failures stop retrying** (`bumpFailures`) — the inbox's
  durability is the point, and both bugs came from it.
- **Overlapping drain triggers coalesce** (resume + native ping + credits
  listener): two concurrent drains both see an entry as not-yet-active and
  start it twice.

Pairs with `surge_meter` for the allowance and `surge_share` for
referral-earned banked credits.

## Status

v0.1.0 — plan, inbox, coalescer; behavior locked by the test port from
Ladle. Not yet wired: a foundation reference service (method channel +
lifecycle observer choreography) — copy Ladle's `PendingImportsService`
shape until one is promoted.
