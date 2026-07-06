/// Coalesces overlapping drain triggers into sequential runs.
///
/// Drains fire from several directions at once — app resume, the
/// extension's cross-process "queued" ping, a credits listener — and two
/// concurrent drains would both see an inbox entry as not-yet-active and
/// start it twice. A trigger that lands mid-drain schedules exactly one
/// re-run instead of interleaving.
class DrainCoalescer {
  bool _running = false;
  bool _again = false;

  Future<void> run(Future<void> Function() drain) async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      await drain();
    } finally {
      _running = false;
      if (_again) {
        _again = false;
        await run(drain);
      }
    }
  }
}
