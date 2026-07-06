/// One drain's decisions, split from the side effects so the priority and
/// allowance rules are unit-testable.
class DrainPlan {
  const DrainPlan({
    required this.start,
    required this.presentKey,
    required this.freshBlocked,
    required this.leftQueued,
  });

  /// Inbox values to start, fresh shares first, then newest first.
  final List<String> start;

  /// Inbox value whose job the present-on-open UI should surface: the
  /// just-shared payload when it has a job, else the newest entry that does.
  final String? presentKey;

  /// A payload shared THIS drain could not start (out of allowance). The
  /// user is watching the app open; they need to be told what happened —
  /// a transient toast is too easy to miss.
  final bool freshBlocked;

  /// Queued entries the allowance left unstarted. They stay in the durable
  /// inbox and start on a later drain (allowance reset, credits arriving,
  /// or upgrade).
  final int leftQueued;
}

/// Spend the intake allowance on fresh shares first, then newest first.
///
/// [all] is the durable inbox in insertion order; [fresh] the values that
/// arrived from THIS drain's platform queue; [active] maps inbox values to
/// already-running job ids (reused, never double-started); [allowed] is how
/// many new jobs the remaining allowance permits (entitled users pass the
/// pending count).
///
/// Oldest-first spending is the trap here: a backlog of still-queued
/// entries (cold-start replays waiting on review) starves the link the
/// user JUST shared into a silent no-op — the app opens and nothing
/// imports. Freshness is decided by this drain's platform queue, not inbox
/// order, so a re-shared old entry still wins the allowance.
DrainPlan planDrain({
  required List<String> all,
  required List<String> fresh,
  required Map<String, String> active,
  required int allowed,
}) {
  final freshSet = fresh.toSet();
  final candidates = <String>[
    ...all.reversed.where(freshSet.contains),
    ...all.reversed.where((value) => !freshSet.contains(value)),
  ];
  final start = <String>[];
  var leftQueued = 0;
  for (final value in candidates) {
    if (active.containsKey(value)) continue;
    if (start.length >= allowed) {
      leftQueued++;
      continue;
    }
    start.add(value);
  }
  bool hasJob(String value) =>
      active.containsKey(value) || start.contains(value);
  String? presentKey;
  for (final value in fresh.reversed) {
    if (hasJob(value)) {
      presentKey = value;
      break;
    }
  }
  if (presentKey == null) {
    for (final value in all.reversed) {
      if (hasJob(value)) {
        presentKey = value;
        break;
      }
    }
  }
  return DrainPlan(
    start: start,
    presentKey: presentKey,
    freshBlocked: fresh.any((value) => !hasJob(value)),
    leftQueued: leftQueued,
  );
}
