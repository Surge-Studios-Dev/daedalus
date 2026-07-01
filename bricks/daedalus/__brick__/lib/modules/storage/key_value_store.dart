import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The local key/value boundary the app depends on for small persisted state
/// (settings, flags, resume points). Swappable like the other backends:
/// [InMemoryKeyValueStore] in tests, `SharedPrefsKeyValueStore` in the real app
/// (bound in bootstrap after prefs load). Reads are synchronous so controllers
/// can seed their initial state in `build`.
abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  bool? getBool(String key);
  Future<void> setBool(String key, bool value);
}

/// In-memory store for dev and tests. Persists only for the process lifetime.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, Object>? seed]) {
    if (seed != null) _values.addAll(seed);
  }

  final _values = <String, Object>{};

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;
}

/// The active key/value store. Defaults to in-memory; bootstrap overrides it
/// with a shared_preferences-backed store so state survives relaunch.
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => InMemoryKeyValueStore(),
);
