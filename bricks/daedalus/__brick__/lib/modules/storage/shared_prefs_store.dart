import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

/// The real [KeyValueStore], backed by shared_preferences. Construct with a
/// loaded [SharedPreferences] (bootstrap awaits `getInstance()` before first
/// frame) so reads stay synchronous.
class SharedPrefsKeyValueStore implements KeyValueStore {
  SharedPrefsKeyValueStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
}
