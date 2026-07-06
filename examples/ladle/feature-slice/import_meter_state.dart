import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/dates.dart';
import '../../core/safe_state.dart';

/// Free import meter (spec §4.3): 5 per calendar week, resets Monday 00:00
/// device-local. Counts link/photo/share imports; not manual creates or
/// edits. Charged the moment extraction succeeds, NOT on Save, so
/// reviewing-then-discarding still costs an attempt (the backend already
/// spent the Gemini / video / oEmbed budget by that point). Failed
/// extractions do not consume.
class ImportMeterState {
  const ImportMeterState({this.used = 0, this.cap = 5});

  final int used;
  final int cap;

  int get left => (cap - used).clamp(0, cap);
  bool get atLimit => left <= 0;
}

class ImportMeterNotifier extends Notifier<ImportMeterState> {
  static const _key = 'import.meter';

  /// Held so [consume]/[setUsed] can await the initial prefs read before
  /// computing a new value - otherwise an auto-started share/deep-link
  /// import can fire while [build] still holds the default used:0 state
  /// and clobber the real persisted weekly count (spec §4.3).
  Future<void>? _loaded;

  @override
  ImportMeterState build() {
    _loaded = _load();
    return const ImportMeterState();
  }

  String get _currentWeek => weekStartOf(toIso(DateTime.now()));

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final week = json['week'] as String? ?? '';
    // stored count only survives within its own week
    final next = week == _currentWeek
        ? ImportMeterState(used: json['used'] as int? ?? 0)
        : const ImportMeterState();
    runOutsideBuild(() => state = next);
  }

  Future<void> consume() async {
    // Wait for the initial prefs read so we increment the real stored
    // count, not the default used:0 that build() seeds.
    await _loaded;
    // Clamp to cap so share/deep-link imports (which can run without an
    // at-limit gate) can't push the persisted count unbounded past cap.
    final clamped = (state.used + 1).clamp(0, state.cap);
    final next = ImportMeterState(used: clamped, cap: state.cap);
    runOutsideBuild(() => state = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({'week': _currentWeek, 'used': next.used}),
    );
  }

  /// Dev helper: jump the meter to a specific used count so the upsell
  /// banner can be QAed without 4 real imports. Only called from
  /// kDebugMode-gated UI.
  Future<void> setUsed(int used) async {
    final clamped = used.clamp(0, state.cap);
    final next = ImportMeterState(used: clamped, cap: state.cap);
    runOutsideBuild(() => state = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({'week': _currentWeek, 'used': next.used}),
    );
  }
}

final importMeterProvider =
    NotifierProvider<ImportMeterNotifier, ImportMeterState>(
      ImportMeterNotifier.new,
    );
