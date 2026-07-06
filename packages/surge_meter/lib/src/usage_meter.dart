import 'dart:async';
import 'dart:convert';

import 'package:surge_core/surge_core.dart';

import 'meter_state.dart';
import 'meter_store.dart';

/// When the allowance resets: Monday-or-Sunday weekly (DST-safe via
/// surge_core's calendar arithmetic) or on the 1st of the month.
enum MeterPeriod { weekly, monthly }

/// The free-tier usage meter, extracted from Ladle's import meter.
///
/// Semantics that shipped (each guard below was a real bug or spec case):
///
/// - **Charge on success, not on save.** Call [consume] the moment the
///   metered work succeeds server-side; a review-then-discard still spent
///   the backend budget. Failed work never consumes.
/// - **The stored count only survives within its own period.** A new
///   period reads as a fresh meter; no cron needed.
/// - **Consumes await the initial store read.** An auto-started consume
///   (share-sheet / deep-link work that starts before the first frame) must
///   increment the real persisted count, not the default 0 the meter boots
///   with — otherwise it silently resets the week.
/// - **Counts clamp to cap.** Flows that bypass the at-limit gate (queued
///   share imports are allowed to finish) can't push the persisted count
///   unbounded past cap.
class UsageMeter {
  UsageMeter({
    required this.cap,
    required MeterStore store,
    this.period = MeterPeriod.weekly,
    this.weekStartsOn = 'Mon',
    this.storageKey = 'meter.usage',
    String Function()? today,
  }) : _store = store,
       _today = today ?? (() => toIso(DateTime.now())) {
    _loaded = _load();
  }

  final int cap;
  final MeterPeriod period;

  /// 'Mon' or 'Sun'; only read when [period] is weekly.
  final String weekStartsOn;

  /// Store key — give each meter in an app its own key.
  final String storageKey;

  final MeterStore _store;
  final String Function() _today;
  final _changes = StreamController<MeterState>.broadcast();

  late final Future<void> _loaded;
  MeterState _state = const MeterState();
  String _storedPeriod = '';

  /// Synchronous snapshot; defaults to a fresh meter until the initial
  /// store read lands (listen to [changes] to re-render when it does).
  MeterState get state => _state;

  Stream<MeterState> get changes => _changes.stream;

  /// Snapshot that is guaranteed to reflect persisted state.
  Future<MeterState> loadedState() async {
    await _loaded;
    return _state;
  }

  String _periodKey() => switch (period) {
    MeterPeriod.weekly => weekStartOf(_today(), weekStartsOn: weekStartsOn),
    MeterPeriod.monthly => _today().substring(0, 7),
  };

  Future<void> _load() async {
    final raw = await _store.read(storageKey);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _storedPeriod = json['period'] as String? ?? '';
    // stored count only survives within its own period
    if (_storedPeriod == _periodKey()) {
      _set(MeterState(used: json['used'] as int? ?? 0, cap: cap));
    }
  }

  void _set(MeterState next) {
    _state = next;
    _changes.add(next);
  }

  /// Charge one unit. Awaits the initial store read so the increment lands
  /// on the real persisted count; resets first if the period rolled over
  /// while the app stayed open.
  Future<void> consume() async {
    await _loaded;
    final key = _periodKey();
    final base = _storedPeriod == key ? _state.used : 0;
    final clamped = (base + 1).clamp(0, cap);
    _storedPeriod = key;
    _set(MeterState(used: clamped, cap: cap));
    await _persist(key, clamped);
  }

  /// Dev/QA helper: jump the meter so at-limit UI can be exercised without
  /// burning real work. Gate the call behind a debug flag in the app.
  Future<void> setUsed(int used) async {
    await _loaded;
    final key = _periodKey();
    final clamped = used.clamp(0, cap);
    _storedPeriod = key;
    _set(MeterState(used: clamped, cap: cap));
    await _persist(key, clamped);
  }

  Future<void> _persist(String key, int used) =>
      _store.write(storageKey, jsonEncode({'period': key, 'used': used}));

  void dispose() {
    _changes.close();
  }
}
