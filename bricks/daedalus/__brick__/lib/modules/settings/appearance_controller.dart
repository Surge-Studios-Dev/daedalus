import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/key_value_store.dart';

/// Light / dark / system appearance, persisted via [KeyValueStore] so the
/// choice survives relaunch (in-memory in tests, shared_preferences in the app).
class AppearanceController extends Notifier<ThemeMode> {
  static const _key = 'appearance';

  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  @override
  ThemeMode build() => _parse(_store.getString(_key));

  ThemeMode _parse(String? name) => switch (name) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  void set(ThemeMode mode) {
    state = mode;
    _store.setString(_key, mode.name);
  }

  /// Cycle system -> light -> dark -> system, for a single-tap settings row.
  void cycle() {
    set(
      switch (state) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      },
    );
  }

  String get label => switch (state) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

final appearanceProvider = NotifierProvider<AppearanceController, ThemeMode>(
  AppearanceController.new,
);
